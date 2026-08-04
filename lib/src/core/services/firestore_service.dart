import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/subscription_model.dart';
import '../models/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

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
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<bool> doesUserProfileExist(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<int> getTotalUserCount() async {
    final snapshot = await _db.collection('users').count().get();
    return snapshot.count ?? 0;
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

  // ============================================================
  //  Phase 1: Courses, Parts, Subparts, Lessons
  // ============================================================

  // ---- Courses ----

  Stream<List<CourseModel>> streamCourses() {
    return _db
        .collection('courses')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(CourseModel.fromSnapshot).toList());
  }

  Future<void> saveCourse(CourseModel course) async {
    await _db.collection('courses').doc(course.id).set(
          course.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<String> createCourse(CourseModel course) async {
    final docRef = _db.collection('courses').doc();
    final count = await _db.collection('courses').count().get();
    await docRef.set(course.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> deleteCourse(String courseId) async {
    final courseRef = _db.collection('courses').doc(courseId);

    // Cascade delete: lessons -> subparts -> parts -> course
    final parts = await courseRef.collection('parts').get();
    for (final part in parts.docs) {
      final subparts = await part.reference.collection('subparts').get();
      for (final subpart in subparts.docs) {
        final lessons = await subpart.reference.collection('lessons').get();
        final batch = _db.batch();
        for (final lesson in lessons.docs) {
          batch.delete(lesson.reference);
        }
        await batch.commit();
        await subpart.reference.delete();
      }
      await part.reference.delete();
    }

    await courseRef.delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a course.
  Future<void> updateCourseOrder(String courseId, int order) async {
    await _db.collection('courses').doc(courseId).update({'order': order});
  }

  // ---- Parts (under a course) ----

  Stream<List<PartModel>> streamParts(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(PartModel.fromSnapshot).toList());
  }

  Future<String> createPart(String courseId, PartModel part) async {
    final colRef = _db.collection('courses').doc(courseId).collection('parts');
    final docRef = colRef.doc();
    final count = await colRef.count().get();
    await docRef.set(part.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> deletePart(String courseId, String partId) async {
    await _db.collection('courses').doc(courseId).collection('parts').doc(partId).delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a part.
  Future<void> updatePartOrder(String courseId, String partId, int order) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .update({'order': order});
  }

  // ---- Subparts (under a part) ----

  Stream<List<SubpartModel>> streamSubparts(String courseId, String partId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(SubpartModel.fromSnapshot).toList());
  }

  Future<String> createSubpart(String courseId, String partId, SubpartModel subpart) async {
    final colRef = _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts');
    final docRef = colRef.doc();
    final count = await colRef.count().get();
    await docRef.set(subpart.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> deleteSubpart(String courseId, String partId, String subpartId) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a subpart.
  Future<void> updateSubpartOrder(
      String courseId, String partId, String subpartId, int order) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .update({'order': order});
  }

  // ---- Lessons (under a subpart) ----

  Stream<List<LessonModel>> streamLessons(String courseId, String partId, String subpartId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .collection('lessons')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(LessonModel.fromSnapshot).toList());
  }

  Future<String> createLesson(
    String courseId,
    String partId,
    String subpartId,
    LessonModel lesson,
  ) async {
    final colRef = _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .collection('lessons');
    final docRef = colRef.doc();
    final count = await colRef.count().get();
    await docRef.set(lesson.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> deleteLesson(String courseId, String partId, String subpartId, String lessonId) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .collection('lessons')
        .doc(lessonId)
        .delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a lesson.
  Future<void> updateLessonOrder(String courseId, String partId,
      String subpartId, String lessonId, int order) async {
    await _db
        .collection('courses')
        .doc(courseId)
        .collection('parts')
        .doc(partId)
        .collection('subparts')
        .doc(subpartId)
        .collection('lessons')
        .doc(lessonId)
        .update({'order': order});
  }

  Future<int> getLessonCountForCourse(String courseId) async {
    // Aggregate via parts -> subparts -> lessons is expensive client-side;
    // for dashboard stats we read the 'lessonCount' field maintained by admin,
    // else approximate by counting first level parts/subparts.
    // Simple approach: count lessons at any depth via collectionGroup.
    final snap = await _db
        .collectionGroup('lessons')
        .where('courseId', isEqualTo: courseId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ============================================================
  //  Question Papers (MCQs and Coding Challenges)
  // ============================================================

  Stream<List<QuestionPaperModel>> streamQuestionPapers() {
    return _db
        .collection('questionPapers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(QuestionPaperModel.fromSnapshot).toList());
  }

  Future<String> createQuestionPaper(QuestionPaperModel paper) async {
    final docRef = _db.collection('questionPapers').doc();
    await docRef.set(paper.toMap());
    return docRef.id;
  }

  Future<void> updateQuestionPaper(String id, QuestionPaperModel paper) async {
    await _db.collection('questionPapers').doc(id).set(
          paper.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteQuestionPaper(String id) async {
    await _db.collection('questionPapers').doc(id).delete();
  }

  Future<int> getQuestionPaperCount() async {
    final snapshot = await _db.collection('questionPapers').count().get();
    return snapshot.count ?? 0;
  }

  // ---- PDF attachments (files live in Firebase Storage, metadata here) ----

  Stream<List<Map<String, dynamic>>> streamPaperAttachments(String paperId) {
    return _db
        .collection('questionPapers')
        .doc(paperId)
        .collection('attachments')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> addPaperAttachment(
    String paperId, {
    required String pdfUrl,
    required String fileName,
    required int sizeBytes,
  }) async {
    await _db
        .collection('questionPapers')
        .doc(paperId)
        .collection('attachments')
        .add({
      'pdfUrl': pdfUrl,
      'fileName': fileName,
      'sizeBytes': sizeBytes,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePaperAttachment(String paperId, String attachmentId) async {
    await _db
        .collection('questionPapers')
        .doc(paperId)
        .collection('attachments')
        .doc(attachmentId)
        .delete();
  }

  // ============================================================
  //  Banners
  // ============================================================

  Stream<List<BannerModel>> streamBanners() {
    return _db
        .collection('banners')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(BannerModel.fromSnapshot).toList());
  }

  Future<String> createBanner(BannerModel banner) async {
    final colRef = _db.collection('banners');
    final docRef = colRef.doc();
    final count = await colRef.count().get();
    await docRef.set(banner.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a banner.
  Future<void> updateBannerOrder(String bannerId, int order) async {
    await _db.collection('banners').doc(bannerId).update({'order': order});
  }

  Future<int> getBannerCount() async {
    final snapshot = await _db.collection('banners').count().get();
    return snapshot.count ?? 0;
  }

  // ============================================================
  //  Popular Topics (home screen, Img 3)
  // ============================================================

  Stream<List<PopularTopicModel>> streamPopularTopics() {
    return _db
        .collection('popularTopics')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(PopularTopicModel.fromSnapshot).toList());
  }

  Future<String> createPopularTopic(PopularTopicModel topic) async {
    final colRef = _db.collection('popularTopics');
    final docRef = colRef.doc();
    final count = await colRef.count().get();
    await docRef.set(topic.toMap()..['order'] = count.count ?? 0);
    return docRef.id;
  }

  Future<void> updatePopularTopic(String id, PopularTopicModel topic) async {
    await _db.collection('popularTopics').doc(id).set(
          topic.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deletePopularTopic(String id) async {
    await _db.collection('popularTopics').doc(id).delete();
  }

  /// Sets the display position (drag-and-drop reorder) of a popular topic.
  Future<void> updatePopularTopicOrder(String topicId, int order) async {
    await _db.collection('popularTopics').doc(topicId).update({'order': order});
  }

  // ============================================================
  //  Student course selection (Img 4)
  // ============================================================

  Future<void> selectCourse(String uid, String courseId, String courseName) async {
    await _db.collection('studentSelections').doc(uid).set({
      'courseId': courseId,
      'courseName': courseName,
      'selectedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getStudentSelection(String uid) async {
    final doc = await _db.collection('studentSelections').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Stream<Map<String, dynamic>?> streamStudentSelection(String uid) {
    return _db.collection('studentSelections').doc(uid).snapshots().map(
          (doc) => doc.exists ? doc.data() : null,
        );
  }

  /// Marks a part as visited for a specific course (Duolingo-style progress).
  ///
  /// Stored as `"courseId::partId"` entries so progress is tracked per course.
  /// Legacy plain part ids (old format) remain valid for reading.
  Future<void> markPartVisited(String uid, String courseId, String partId) async {
    final ref = _db.collection('studentSelections').doc(uid);
    final doc = await ref.get();
    final entry = '$courseId::$partId';
    if (!doc.exists) {
      await ref.set({
        'visitedParts': [entry],
        'selectedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final visited = (doc.data()?['visitedParts'] as List?) ?? [];
    if (!visited.contains(entry)) {
      await ref.update({
        'visitedParts': FieldValue.arrayUnion([entry]),
      });
    }
  }

  /// Returns the visited part ids for a course (prefix `"courseId::"`).
  static Set<String> visitedPartIdsForCourse(
      Map<String, dynamic>? selection, String courseId) {
    final list = (selection?['visitedParts'] as List?) ?? const [];
    final set = <String>{};
    for (final e in list) {
      final s = e.toString();
      final sep = s.indexOf('::');
      if (sep > 0 && s.substring(0, sep) == courseId) {
        set.add(s.substring(sep + 2));
      } else if (sep < 0) {
        set.add(s); // legacy plain part id
      }
    }
    return set;
  }

  /// Resets progress for a course (removes all `"courseId::"` visited entries).
  Future<void> restartCourse(String uid, String courseId) async {
    final ref = _db.collection('studentSelections').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return;
    final visited = (doc.data()?['visitedParts'] as List?) ?? [];
    final prefix = '$courseId::';
    final kept = visited.where((e) => !e.toString().startsWith(prefix)).toList();
    await ref.update({'visitedParts': kept});
  }
  // ============================================================
  //  Subscriptions (Phase 3 — UPI mandates)
  // ============================================================

  Future<void> createSubscription(SubscriptionModel sub) async {
    await _db.collection('subscriptions').doc(sub.id).set(sub.toMap());
  }

  Future<void> updateSubscription(String id, Map<String, dynamic> data) async {
    await _db
        .collection('subscriptions')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  Stream<SubscriptionModel> streamUserSubscription(String uid) {
    return _db
        .collection('subscriptions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? SubscriptionModel(id: '', uid: uid, planId: 'none')
            : SubscriptionModel.fromMap(snap.docs.first.data()));
  }

  /// Admin: stream every user's latest subscription status.
  Stream<List<SubscriptionModel>> streamAllSubscriptions() {
    return _db
        .collection('subscriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => SubscriptionModel.fromMap(doc.data())).toList());
  }

  /// Admin: stream all users (for subscription/payment insights).
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _db.collection('users').snapshots().map((snap) => snap.docs.map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        }).toList());
  }

  /// Admin: fetch transactions for a specific student (insights).
  Stream<List<TransactionModel>> streamUserTransactions(String uid) {
    return _db
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }

  /// Admin: stream all transactions across students.
  Stream<List<TransactionModel>> streamAllTransactions() {
    return _db
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }
}
