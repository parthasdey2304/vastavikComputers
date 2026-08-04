import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Derived premium state from the signed-in user's Firestore profile.
///
/// The `users/{uid}` doc carries:
///   isPremium, premiumUntil (Timestamp/ISO), currentPlan,
///   subscriptionId (mandate id), mandateId.
/// A mandate-based plan is considered active if the profile says premium
/// AND the mandate has not lapsed (premiumUntil in the future).
class PremiumStatus {
  final bool isPremium;
  final bool hasActiveMandate;
  final DateTime? premiumUntil;
  final String? planId;
  final String? subscriptionId;
  final String? mandateId;

  const PremiumStatus({
    required this.isPremium,
    this.hasActiveMandate = false,
    this.premiumUntil,
    this.planId,
    this.subscriptionId,
    this.mandateId,
  });
}

final premiumStatusProvider = Provider<PremiumStatus>((ref) {
  final profile = ref.watch(userProfileStreamProvider).value;
  if (profile == null) return const PremiumStatus(isPremium: false);

  final isPremium = profile['isPremium'] == true;
  final premiumUntilRaw = profile['premiumUntil'];
  DateTime? premiumUntil;
  if (premiumUntilRaw is String) {
    premiumUntil = DateTime.tryParse(premiumUntilRaw);
  } else if (premiumUntilRaw is Timestamp) {
    premiumUntil = premiumUntilRaw.toDate();
  }

  final subscriptionId = profile['subscriptionId']?.toString();
  final mandateId = profile['mandateId']?.toString();

  final mandateActive = isPremium && (premiumUntil == null || premiumUntil.isAfter(DateTime.now()));

  return PremiumStatus(
    isPremium: isPremium,
    hasActiveMandate: mandateActive && (mandateId != null || subscriptionId != null),
    premiumUntil: premiumUntil,
    planId: profile['currentPlan']?.toString(),
    subscriptionId: subscriptionId,
    mandateId: mandateId,
  );
});
