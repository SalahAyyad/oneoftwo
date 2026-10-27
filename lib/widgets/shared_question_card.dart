import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/shared_question.dart';
import '../providers/shared_questions_provider.dart';
import 'question_card.dart';

class SharedQuestionCard extends ConsumerWidget {
  final SharedQuestion shared;
  final AppUser? currentUser;

  const SharedQuestionCard({
    super.key,
    required this.shared,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionByIdProvider(shared.questionId));

    return questionAsync.when(
      data: (question) {
        if (question == null) return const SizedBox.shrink();
        return QuestionCard(
          question: question,
          currentUser: currentUser,
          sentByUsername: shared.fromUsername,
          onSeen: () =>
              ref.read(shareQuestionServiceProvider).markSeen(shared.id),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
