/// Firestore `subscriptions/{subId}` model for PhonePe UPI mandates.
///
/// A mandate is a recurring-payment agreement. `processMonthlyBilling`
/// (Cloud Function) charges it monthly until [endDate].
class SubscriptionModel {
  final String id; // merchantSubscriptionId
  final String uid;
  final String planId; // 'monthly' | 'yearly'
  final String planTitle;
  final double amountRupees;
  final String status; // pending | active | paused | cancelled | failed
  final String? mandateId; // PhonePe mandate reference
  final DateTime? nextBillingDate;
  final DateTime? endDate;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.uid,
    required this.planId,
    this.planTitle = 'Premium',
    this.amountRupees = 99,
    this.status = 'pending',
    this.mandateId,
    this.nextBillingDate,
    this.endDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isActive => status == 'active';

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'planId': planId,
        'planTitle': planTitle,
        'amountRupees': amountRupees,
        'status': status,
        if (mandateId != null) 'mandateId': mandateId,
        if (nextBillingDate != null)
          'nextBillingDate': nextBillingDate!.toIso8601String(),
        if (endDate != null) 'endDate': endDate!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      planId: map['planId'] ?? 'monthly',
      planTitle: map['planTitle'] ?? 'Premium',
      amountRupees: (map['amountRupees'] ?? 99).toDouble(),
      status: map['status'] ?? 'pending',
      mandateId: map['mandateId']?.toString(),
      nextBillingDate: map['nextBillingDate'] != null
          ? DateTime.tryParse(map['nextBillingDate'].toString())
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
