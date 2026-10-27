import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import 'auth_provider.dart';

final questionsStreamProvider = StreamProvider<List<Question>>((ref) {
  return FirebaseFirestore.instance
      .collection('questions')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(Question.fromFirestore).toList());
});

class QuestionsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuestionsService(this._firestore, this._auth);

  Future<void> postQuestion({
    required String question,
    required String answer1,
    required String answer2,
    required String authorUsername,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('questions').add({
      'question': question,
      'answer1': answer1,
      'answer2': answer2,
      'answer1Votes': 0,
      'answer2Votes': 0,
      'authorId': uid,
      'authorUsername': authorUsername,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> vote({
    required String questionId,
    required int answer, // 1 or 2
  }) async {
    final uid = _auth.currentUser!.uid;
    final questionRef =
        _firestore.collection('questions').doc(questionId);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final userDoc = await tx.get(userRef);
      final voted = Map<String, dynamic>.from(
          (userDoc.data()?['votedQuestions'] as Map<String, dynamic>?) ?? {});
      if (voted.containsKey(questionId)) return; // already voted

      final voteField = answer == 1 ? 'answer1Votes' : 'answer2Votes';
      tx.update(questionRef, {voteField: FieldValue.increment(1)});
      tx.update(userRef, {'votedQuestions.$questionId': answer});
    });
  }
}

final questionsServiceProvider = Provider((ref) => QuestionsService(
      ref.watch(firestoreProvider),
      ref.watch(firebaseAuthProvider),
    ));
