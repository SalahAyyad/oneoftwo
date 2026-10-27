import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../providers/questions_provider.dart';
import '../../providers/shared_questions_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/question_card.dart';
import '../../widgets/shared_question_card.dart';
import '../create/create_question_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';


class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsStreamProvider);
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuestionFeed'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search users',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'My profile',
            onPressed: () {
              final uid = currentUserAsync.valueOrNull?.uid;
              if (uid != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: uid)),
                );
              }
            },
          ),
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: const Text('Sign out?',
                      style: TextStyle(color: AppTheme.textPrimary)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out',
                          style: TextStyle(color: AppTheme.accentPink)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authServiceProvider).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              }
            },
            child: const Text('Sign out',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
      body: questionsAsync.when(
        data: (questions) {
          final currentUser = currentUserAsync.valueOrNull;
          final sharedAsync = ref.watch(incomingSharedProvider);
          final shared = sharedAsync.valueOrNull ?? [];
          final unseenShared =
              shared.where((s) => !s.seen).toList();

          if (questions.isEmpty && unseenShared.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline_rounded,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No questions yet',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to ask something!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: unseenShared.length + questions.length,
            itemBuilder: (context, i) {
              if (i < unseenShared.length) {
                return SharedQuestionCard(
                  shared: unseenShared[i],
                  currentUser: currentUser,
                );
              }
              return QuestionCard(
                question: questions[i - unseenShared.length],
                currentUser: currentUser,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentUser = currentUserAsync.valueOrNull;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateQuestionScreen(
                authorUsername: currentUser?.username ?? 'Anonymous',
              ),
            ),
          );
        },
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ask',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
