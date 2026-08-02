// Transaction model for payment history
class TransactionModel {
  final String id;
  final String uid;
  final double amount;
  final String description;
  final String status; // success, failed, pending
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.amount,
    required this.description,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'amount': amount,
      'description': description,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
