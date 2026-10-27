import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../models/shared_question.dart';
import 'auth_provider.dart';

// Single question by ID (for shared question cards)
final questionByIdProvider =
    FutureProvider.family<Question?, String>((ref, questionId) async {
  final doc = await FirebaseFirestore.instance
      .collection('questions')
      .doc(questionId)
      .get();
  return doc.exists ? Question.fromFirestore(doc) : null;
});

// Incoming shared questions for the current user
final incomingSharedProvider =
    StreamProvider<List<SharedQuestion>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('sharedQuestions')
          .where('toUserId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .snapshots()
          .map((s) =>
              s.docs.map(SharedQuestion.fromFirestore).toList());
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});

class ShareQuestionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ShareQuestionService(this._firestore, this._auth);

  Future<void> sendQuestion({
    required String questionId,
    required String toUserId,
    required String fromUsername,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('sharedQuestions').add({
      'questionId': questionId,
      'fromUserId': uid,
      'fromUsername': fromUsername,
      'toUserId': toUserId,
      'seen': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markSeen(String sharedId) async {
    await _firestore
        .collection('sharedQuestions')
        .doc(sharedId)
        .update({'seen': true});
  }
}

final shareQuestionServiceProvider = Provider((ref) => ShareQuestionService(
      ref.watch(firestoreProvider),
      ref.watch(firebaseAuthProvider),
    ));
