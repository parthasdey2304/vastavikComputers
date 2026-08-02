import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/transaction_model.dart';
import '../../../../core/services/firestore_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _firestoreService = FirestoreService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final txns = await _firestoreService.getTransactions(uid);
      if (mounted) {
        setState(() {
          _transactions = txns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Payment History', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text('No transactions yet.', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: txn.status == 'success' ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                          child: Icon(
                            txn.status == 'success' ? Icons.check_circle : Icons.cancel,
                            color: txn.status == 'success' ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(txn.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${txn.timestamp.day}/${txn.timestamp.month}/${txn.timestamp.year}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                        trailing: Text(
                          '₹${txn.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: txn.status == 'success' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
