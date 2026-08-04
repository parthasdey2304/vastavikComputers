/**
 * Vastavik Computers — PhonePe Subscription (UPI Mandate) Functions.
 *
 * 1. phonePeCreateMandate
 *    HTTPS endpoint. Creates a recurring UPI mandate via PhonePe
 *    `/pg/v1/subscriptions`, persists a `subscriptions/{id}` doc as
 *    `pending`, and returns the redirect URL the client must open.
 *
 * 2. phonePeSubscriptionWebhook
 *    PhonePe calls this after the user approves/rejects the mandate.
 *    Verifies the checksum, marks the subscription `active` (or `failed`),
 *    stores the mandateId, sets `nextBillingDate`, and grants premium.
 *
 * 3. processMonthlyBilling
 *    Scheduled (daily) cron. Finds active subscriptions whose
 *    `nextBillingDate` has passed, charges the mandate via PhonePe
 *    `/pg/v1/charge`, records a `transactions` doc, and advances
 *    `nextBillingDate` by one month. Stops charging after `endDate`.
 *
 * 4. expireSubscriptions
 *    Scheduled (daily). Downgrades users whose `premiumUntil` passed.
 *
 * DEPLOY:
 *   cd functions && npm install && cd ..
 *   firebase functions:config:set phonepesaltkey="..." phonepesaltindex="1"
 *   firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

const SALT_KEY = (process.env.PHONEPE_SALT_KEY || '').trim() || 'YOUR_PHONEPE_SALT_KEY';
const SALT_INDEX = (process.env.PHONEPE_SALT_INDEX || '').trim() || '1';
const MERCHANT_ID = (process.env.PHONEPE_MERCHANT_ID || '').trim() || 'YOUR_PHONEPE_MERCHANT_ID';
const PHONEPE_BASE = (process.env.PHONEPE_BASE || '').trim() || 'https://api.phonepe.com/apis/hermes';
const IS_SANDBOX = (process.env.PHONEPE_SANDBOX || '').trim() === 'true';
const BASE_URL = IS_SANDBOX ? 'https://api-preprod.phonepe.com/apis/pg-sandbox' : PHONEPE_BASE;

const PAYMENT_URL_FRAGMENT = process.env.PAYMENT_SUCCESS_FRAGMENT || 'payment-success';
const PAYMENT_FAILURE_FRAGMENT = process.env.PAYMENT_FAILURE_FRAGMENT || 'payment-failure';

function sign(payload, path) {
  const digest = crypto.createHash('sha256').update(payload + path + SALT_KEY).digest('hex');
  return digest + '###' + SALT_INDEX;
}

function monthsFromNow(months) {
  const d = new Date();
  d.setMonth(d.getMonth() + months);
  return d;
}

function isoDate(d) {
  return d.toISOString().substring(0, 10);
}

const MONTHLY_PRICE_PAISE = 9900; // ₹99 / month

// ---------------------------------------------------------------------------
// 1. Create mandate
// ---------------------------------------------------------------------------
exports.phonePeCreateMandate = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }

    const uid = (req.body && req.body.uid) || '';
    const planId = (req.body && req.body.planId) || 'monthly';
    const mobile = (req.body && req.body.mobile) || null;

    if (!uid) { res.status(400).send('Missing uid'); return; }
    if (MERCHANT_ID === 'YOUR_PHONEPE_MERCHANT_ID' || SALT_KEY === 'YOUR_PHONEPE_SALT_KEY') {
      res.status(503).send({ success: false, message: 'PhonePe not configured' });
      return;
    }

    const merchantSubscriptionId = 'MS' + Date.now() + Math.floor(Math.random() * 1000);
    const endDate = isoDate(monthsFromNow(12));

    const payload = {
      merchantId: MERCHANT_ID,
      merchantUserId: uid,
      merchantSubscriptionId,
      amount: MONTHLY_PRICE_PAISE,
      recurringPaymentDetail: { interval: 'MONTH', frequency: 1, endDate },
      paymentInstrument: { type: 'UPI_MANDATE', isUpiIntentMode: true, isUpiCollectMode: false },
      authFlow: 'OTP',
      returnUrl: 'vastavikcomputers://subscription-status',
      redirectMode: 'REDIRECT',
      callbackUrl: `https://${process.env.GCLOUD_PROJECT || 'vastavik-computers'}.web.app/${PAYMENT_URL_FRAGMENT}`,
      ...(mobile ? { mobileNumber: mobile } : {}),
    };

    const base64 = Buffer.from(JSON.stringify(payload)).toString('base64');

    const pp = await fetch(`${BASE_URL}/pg/v1/subscriptions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-VERIFY': sign(base64, '/pg/v1/subscriptions') },
      body: JSON.stringify({ request: base64 }),
    });
    const ppData = await pp.json();

    // Persist regardless of PhonePe outcome so admin sees attempts.
    const subRef = db.collection('subscriptions').doc(merchantSubscriptionId);
    await subRef.set({
      id: merchantSubscriptionId,
      uid,
      planId,
      planTitle: 'Premium',
      amountRupees: MONTHLY_PRICE_PAISE / 100,
      status: ppData && ppData.success ? 'pending' : 'failed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(ppData && ppData.data && ppData.data.mandateId ? { mandateId: ppData.data.mandateId } : {}),
    });

    const redirectUrl = ppData && ppData.data && ppData.data.redirectUrl;
    if (ppData && ppData.success && redirectUrl) {
      res.status(200).send({ success: true, merchantSubscriptionId, redirectUrl });
    } else {
      res.status(200).send({
        success: false,
        merchantSubscriptionId,
        message: (ppData && ppData.message) || 'PhonePe rejected the mandate',
      });
    }
  } catch (err) {
    console.error('phonePeCreateMandate error', err);
    res.status(500).send({ success: false, message: 'Internal error' });
  }
});

// ---------------------------------------------------------------------------
// 2. Subscription webhook
// ---------------------------------------------------------------------------
exports.phonePeSubscriptionWebhook = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }

    const xVerify = req.get('X-VERIFY') || '';
    const base64Response = req.body && req.body.response;
    if (!base64Response || !xVerify) { res.status(400).send('Bad request'); return; }

    const cooked = base64Response + SALT_KEY;
    const expected = crypto.createHash('sha256').update(cooked).digest('hex') + '###' + SALT_INDEX;
    if (expected !== xVerify) { res.status(401).send('Invalid checksum'); return; }

    const decoded = JSON.parse(Buffer.from(base64Response, 'base64').toString('utf8'));
    const data = decoded.data || {};
    const subId = data.merchantSubscriptionId;
    const state = data.state || '';
    const mandateId = data.mandateId || data.subscriptionId || null;

    if (!subId) { res.status(400).send('Missing merchantSubscriptionId'); return; }

    const subRef = db.collection('subscriptions').doc(subId);
    const subSnap = await subRef.get();
    const sub = subSnap.exists ? subSnap.data() : null;
    const uid = sub ? sub.uid : null;

    const active = decoded.success === true && ['ACTIVE', 'COMPLETED'].includes(state);

    await subRef.set({
      status: active ? 'active' : 'failed',
      ...(mandateId ? { mandateId } : {}),
      nextBillingDate: active ? admin.firestore.Timestamp.fromDate(monthsFromNow(1)) : admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (active && uid) {
      await db.collection('users').doc(uid).set({
        isPremium: true,
        premiumUntil: admin.firestore.Timestamp.fromDate(monthsFromNow(1)),
        currentPlan: 'monthly',
        subscriptionId: subId,
        mandateId: mandateId || '',
      }, { merge: true });
    }

    res.status(200).send('OK');
  } catch (err) {
    console.error('phonePeSubscriptionWebhook error', err);
    res.status(500).send('Internal error');
  }
});

// ---------------------------------------------------------------------------
// 3. Monthly billing cron
// ---------------------------------------------------------------------------
exports.processMonthlyBilling = functions.pubsub
  .schedule('every day 06:00')
  .timeZone('Asia/Kolkata')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const dueSnap = await db
      .collection('subscriptions')
      .where('status', '==', 'active')
      .where('nextBillingDate', '<=', now)
      .get();

    if (dueSnap.empty) {
      console.log('processMonthlyBilling: no due subscriptions');
      return null;
    }

    for (const docSnap of dueSnap.docs) {
      const sub = docSnap.data();
      const mandateId = sub.mandateId;
      const uid = sub.uid;

      if (!mandateId || !uid) {
        await docSnap.ref.update({ status: 'failed', reason: 'missing mandate' });
        continue;
      }

      const merchantChargeId = 'MC' + Date.now() + Math.floor(Math.random() * 1000);
      const amount = Number(sub.amountRupees || 99) * 100;
      const chargePayload = {
        merchantId: MERCHANT_ID,
        merchantSubscriptionId: docSnap.id,
        merchantChargeId,
        amount,
        paymentInstrument: { type: 'UPI_MANDATE', mandateId },
      };
      const base64 = Buffer.from(JSON.stringify(chargePayload)).toString('base64');

      try {
        const resp = await fetch(`${BASE_URL}/pg/v1/charge`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-VERIFY': sign(base64, '/pg/v1/charge') },
          body: JSON.stringify({ request: base64 }),
        });
        const data = await resp.json();

        const charged = data && data.success === true && (data.data && data.data.state === 'CHARGED');

        await db.collection('transactions').doc(merchantChargeId).set({
          id: merchantChargeId,
          uid,
          amount: amount / 100,
          description: 'Monthly premium auto-debit (UPI mandate)',
          status: charged ? 'success' : 'failed',
          subscriptionId: docSnap.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          phonePeResponse: data,
        }, { merge: true });

        if (charged) {
          const next = new Date();
          next.setMonth(next.getMonth() + 1);
          await docSnap.ref.update({
            nextBillingDate: admin.firestore.Timestamp.fromDate(next),
            lastChargedAt: admin.firestore.Timestamp.now(),
          });
          // Grant premium for the next month.
          await db.collection('users').doc(uid).set({
            isPremium: true,
            premiumUntil: admin.firestore.Timestamp.fromDate(next),
          }, { merge: true });
        } else {
          await docSnap.ref.update({
            lastAttemptAt: admin.firestore.Timestamp.now(),
            lastChargeStatus: 'failed',
          });
        }
      } catch (err) {
        console.error('charge failed for', docSnap.id, err);
      }
    }

    console.log('processMonthlyBilling: processed', dueSnap.size, 'subscription(s)');
    return null;
  });

// ---------------------------------------------------------------------------
// 4. Expire subscriptions (existing)
// ---------------------------------------------------------------------------
exports.expireSubscriptions = functions.pubsub
  .schedule('every day 00:05')
  .timeZone('Asia/Kolkata')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const expiredSnap = await db
      .collection('users')
      .where('isPremium', '==', true)
      .where('premiumUntil', '<', now)
      .get();

    if (expiredSnap.empty) { console.log('expireSubscriptions: nothing to expire'); return null; }

    const batch = db.batch();
    expiredSnap.forEach((docSnap) => {
      batch.update(docSnap.ref, { isPremium: false, expiredAt: now });
    });
    await batch.commit();
    console.log(`expireSubscriptions: downgraded ${expiredSnap.size} user(s)`);
    return null;
  });
