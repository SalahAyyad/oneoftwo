import 'package:cloud_firestore/cloud_firestore.dart';

class SharedQuestion {
  final String id;
  final String questionId;
  final String fromUserId;
  final String fromUsername;
  final String toUserId;
  final bool seen;
  final DateTime createdAt;

  const SharedQuestion({
    required this.id,
    required this.questionId,
    required this.fromUserId,
    required this.fromUsername,
    required this.toUserId,
    required this.seen,
    required this.createdAt,
  });

  factory SharedQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedQuestion(
      id: doc.id,
      questionId: data['questionId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUsername: data['fromUsername'] ?? '',
      toUserId: data['toUserId'] ?? '',
      seen: data['seen'] ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
