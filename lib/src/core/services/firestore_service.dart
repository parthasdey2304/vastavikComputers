import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---- User Profile ----

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<bool> doesUserProfileExist(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  // ---- Transactions / Payment History ----

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db.collection('transactions').doc(transaction.id).set(transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions(String uid) async {
    final snapshot = await _db
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data()))
        .toList();
  }

  // ---- Notes ----

  Future<void> saveNote(String uid, String noteId, Map<String, dynamic> noteData) async {
    await _db.collection('users').doc(uid).collection('notes').doc(noteId).set(noteData);
  }

  Future<List<Map<String, dynamic>>> getNotes(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).collection('notes').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _db.collection('users').doc(uid).collection('notes').doc(noteId).delete();
  }
}
