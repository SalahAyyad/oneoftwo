import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String question;
  final String answer1;
  final String answer2;
  final int answer1Votes;
  final int answer2Votes;
  final String authorId;
  final String authorUsername;
  final DateTime createdAt;

  const Question({
    required this.id,
    required this.question,
    required this.answer1,
    required this.answer2,
    required this.answer1Votes,
    required this.answer2Votes,
    required this.authorId,
    required this.authorUsername,
    required this.createdAt,
  });

  int get totalVotes => answer1Votes + answer2Votes;

  double get answer1Percentage =>
      totalVotes == 0 ? 0.5 : answer1Votes / totalVotes;

  double get answer2Percentage =>
      totalVotes == 0 ? 0.5 : answer2Votes / totalVotes;

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      question: data['question'] ?? '',
      answer1: data['answer1'] ?? '',
      answer2: data['answer2'] ?? '',
      answer1Votes: (data['answer1Votes'] ?? 0) as int,
      answer2Votes: (data['answer2Votes'] ?? 0) as int,
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? 'Anonymous',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'question': question,
        'answer1': answer1,
        'answer2': answer2,
        'answer1Votes': answer1Votes,
        'answer2Votes': answer2Votes,
        'authorId': authorId,
        'authorUsername': authorUsername,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
