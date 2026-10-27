import 'package:flutter_test/flutter_test.dart';

import 'package:rememebering/models/question.dart';

Question _question({required int votes1, required int votes2}) => Question(
      id: 'q1',
      question: 'Tea or coffee?',
      answer1: 'Tea',
      answer2: 'Coffee',
      answer1Votes: votes1,
      answer2Votes: votes2,
      authorId: 'u1',
      authorUsername: 'tester',
      createdAt: DateTime(2026),
    );

void main() {
  test('splits evenly when there are no votes', () {
    final q = _question(votes1: 0, votes2: 0);
    expect(q.totalVotes, 0);
    expect(q.answer1Percentage, 0.5);
    expect(q.answer2Percentage, 0.5);
  });

  test('computes vote percentages', () {
    final q = _question(votes1: 3, votes2: 1);
    expect(q.totalVotes, 4);
    expect(q.answer1Percentage, 0.75);
    expect(q.answer2Percentage, 0.25);
  });
}
