import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/config/secrets.dart';
import '../../../../core/models/subscription_plan.dart';
import '../../../../core/models/subscription_model.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/phonepe_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

final _phonePeServiceProvider = Provider<PhonePeService>((ref) => PhonePeService());

/// Phase 2/3 monetization screen. Shows plan cards, collects payment via
/// PhonePe (one-time for yearly, UPI mandate for monthly auto-debit),
/// records transaction/subscription in Firestore, and refreshes premium.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  SubscriptionPlan? _selectedPlan;
  bool _processing = false;
  String? _error;

  Future<void> _startCheckout(SubscriptionPlan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Please log in first.');
      return;
    }
    setState(() {
      _selectedPlan = plan;
      _processing = true;
      _error = null;
    });

    final service = ref.read(_phonePeServiceProvider);
    final fs = ref.read(firestoreServiceProvider);
    final txnId = PhonePeService.newTransactionId();

    if (plan.isMandate) {
      // ---- Monthly auto-debit (Phase 3) ----
      final subId = PhonePeService.newSubscriptionId();
      final result = await service.createSubscription(
        merchantSubscriptionId: subId,
        merchantUserId: user.uid,
        amountRupees: plan.priceRupees.toDouble(),
        intervalMonths: 1,
        totalMonths: 12,
        callbackUrl: Secrets.phonePeVerifyUrl,
        redirectUrl: 'vastavikcomputers://subscription-status',
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _processing = false;
          _error = result.message;
        });
        return;
      }

      // Record the pending subscription so the webhook can activate it.
      await fs.createSubscription(
        SubscriptionModel(
          id: subId,
          uid: user.uid,
          planId: plan.id,
          planTitle: plan.title,
          amountRupees: plan.priceRupees.toDouble(),
          status: 'pending',
        ),
      );

      final payUrl = result.providerReferenceId;
      if (payUrl == null || payUrl.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Could not load PhonePe mandate approval page.';
        });
        return;
      }

      final completed = await _openWebViewCheckout(payUrl, subId);

      if (!mounted) return;
      if (completed) {
        await fs.updateUserProfile(user.uid, {
          'isPremium': true,
          'currentPlan': plan.id,
          'subscriptionId': subId,
        });
        if (!mounted) return;
        _showSuccessDialog(plan);
      } else {
        setState(() {
          _processing = false;
          _error = 'Mandate approval cancelled or failed. Try again.';
        });
      }
      return;
    }

    // ---- One-time payment (yearly) ----
    final result = await service.createPayment(
      merchantTransactionId: txnId,
      merchantUserId: user.uid,
      amountRupees: plan.priceRupees.toDouble(),
      callbackUrl: Secrets.phonePeVerifyUrl,
      redirectUrl: 'vastavikcomputers://payment-success?txn=$txnId',
    );

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _processing = false;
        _error = result.message;
      });
      return;
    }

    // 2. Record pending transaction so we can reconcile later
    await fs.addTransaction(
      TransactionModel(
        id: txnId,
        uid: user.uid,
        amount: plan.priceRupees.toDouble(),
        description: '${plan.title} subscription (${plan.durationLabel})',
        status: 'pending',
      ),
    );

    if (!mounted) return;

    // 3. Open PhonePe pay page inside app WebView
    final payUrl = result.providerReferenceId;
    if (payUrl == null || payUrl.isEmpty) {
      setState(() {
        _processing = false;
        _error = 'Could not load PhonePe checkout page.';
      });
      return;
    }

    final completed = await _openWebViewCheckout(payUrl, txnId);

    if (!mounted) return;
    if (completed) {
      // 4. Verify & activate premium (optimistic for sandbox; server validates via webhook)
      await fs.updateUserProfile(user.uid, {
        'isPremium': true,
        'currentPlan': plan.id,
      });
      await fs.addTransaction(
        TransactionModel(
          id: txnId,
          uid: user.uid,
          amount: plan.priceRupees.toDouble(),
          description: '${plan.title} subscription (${plan.durationLabel})',
          status: 'success',
        ),
      );
      if (!mounted) return;
      _showSuccessDialog(plan);
    } else {
      setState(() {
        _processing = false;
        _error = 'Payment cancelled or failed. Try again.';
      });
    }
  }

  Future<bool> _openWebViewCheckout(String url, String txnId) async {
    if (kIsWeb) {
      // Web has no in-app WebView — open PhonePe in a new tab.
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // After returning, assume success (server webhook reconciles truth).
      return true;
    }
    return await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => _PhonePeWebViewScreen(
              initialUrl: url,
              successUrlFragment: 'payment-success',
              failureUrlFragment: 'payment-failure',
            ),
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 12),
            Text('Payment Successful!', textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          'You are now on the ${plan.title} plan. Enjoy all premium lessons!',
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(
          'Go Premium',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock everything.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Choose a plan that fits your preparation. Pay securely via PhonePe UPI, cards & netbanking.',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 14),
                ),
                SizedBox(height: 24),
                ...SubscriptionPlan.all.map(
                  (p) => _PlanCard(
                    plan: p,
                    selected: _selectedPlan?.id == p.id,
                    onSelect: () => setState(() => _selectedPlan = p),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed:
                        _processing || _selectedPlan == null ? null : () => _startCheckout(_selectedPlan!),
                    icon: _processing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.lock_open),
                    label: Text(
                      _processing
                          ? 'Processing…'
                          : (_selectedPlan == null
                              ? 'Select a plan above'
                              : 'Pay ${_selectedPlan!.priceLabel} with PhonePe'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/payment-history'),
                    icon: Icon(Icons.receipt_long, size: 18),
                    label: Text('View payment history'),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'Secured by PhonePe. Your payment info never touches our servers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onSelect;

  const _PlanCard({required this.plan, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final highlight = selected || plan.isPopular;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlight ? AppTheme.primary : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            if (highlight)
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                if (plan.isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.priceLabel,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(width: 6),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ ${plan.durationLabel}',
                    style: TextStyle(color: context.appTextSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.accent, size: 18),
                    SizedBox(width: 8),
                    Expanded(child: Text(f, style: TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PhonePeWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String successUrlFragment;
  final String failureUrlFragment;

  const _PhonePeWebViewScreen({
    required this.initialUrl,
    required this.successUrlFragment,
    required this.failureUrlFragment,
  });

  @override
  State<_PhonePeWebViewScreen> createState() => _PhonePeWebViewScreenState();
}

class _PhonePeWebViewScreenState extends State<_PhonePeWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.contains(widget.successUrlFragment)) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (url.contains(widget.failureUrlFragment)) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('PhonePe Checkout', style: TextStyle(color: context.appTextPrimary)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}
