import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/question.dart';

final userProfileProvider =
    FutureProvider.family<AppUser?, String>((ref, userId) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  return doc.exists ? AppUser.fromFirestore(doc) : null;
});

final userQuestionsProvider =
    StreamProvider.family<List<Question>, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('questions')
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Question.fromFirestore).toList());
});
