/// Subscription plans offered via PhonePe (Phase 2/3).
class SubscriptionPlan {
  final String id;
  final String title;
  final int priceRupees;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final bool isMandate; // recurring monthly auto-debit (Phase 3)

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.priceRupees,
    required this.durationDays,
    required this.features,
    this.isPopular = false,
    this.isMandate = false,
  });

  String get priceLabel => '₹$priceRupees';
  String get durationLabel {
    if (durationDays % 365 == 0) return '${durationDays ~/ 365} year';
    if (durationDays % 30 == 0) return '${durationDays ~/ 30} month';
    return '$durationDays days';
  }

  static const List<SubscriptionPlan> all = [
    SubscriptionPlan(
      id: 'monthly',
      title: 'Monthly (Auto-Debit)',
      priceRupees: 99,
      durationDays: 30,
      isMandate: true,
      isPopular: true,
      features: [
        'All video lessons',
        'AI Chat access',
        'Practice MCQs',
        'Auto-debits ₹99 every month via UPI mandate',
        'Cancel anytime from your bank',
      ],
    ),
    SubscriptionPlan(
      id: 'yearly',
      title: 'Yearly',
      priceRupees: 999,
      durationDays: 365,
      features: [
        'Everything in Monthly',
        'Priority AI responses',
        'Past Year Papers (PYQ)',
        'Save 16% vs monthly',
      ],
    ),
  ];
}
