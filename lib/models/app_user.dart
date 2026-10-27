import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String username;
  final String email;
  final Map<String, int> votedQuestions; // questionId -> 1 or 2

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.votedQuestions = const {},
  });

  int? votedFor(String questionId) => votedQuestions[questionId];

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final voted = (data['votedQuestions'] as Map<String, dynamic>?) ?? {};
    return AppUser(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      votedQuestions: voted.map((k, v) => MapEntry(k, v as int)),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'email': email,
        'votedQuestions': votedQuestions,
      };
}
