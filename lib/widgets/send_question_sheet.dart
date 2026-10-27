import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/question.dart';
import '../providers/follow_provider.dart';
import '../providers/shared_questions_provider.dart';
import '../theme/app_theme.dart';

Future<void> showSendQuestionSheet(
  BuildContext context,
  WidgetRef ref,
  Question question,
  AppUser? currentUser,
) async {
  if (currentUser == null) return;
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SendSheet(
      question: question,
      currentUser: currentUser,
    ),
  );
}

class _SendSheet extends ConsumerWidget {
  final Question question;
  final AppUser currentUser;

  const _SendSheet({required this.question, required this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingAsync =
        ref.watch(myFollowingProvider(currentUser.uid));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Send to',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"${question.question}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          followingAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Follow people to send them questions',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppTheme.divider, height: 1),
                  itemBuilder: (ctx, i) => _UserTile(
                    user: users[i],
                    question: question,
                    currentUser: currentUser,
                  ),
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  final AppUser user;
  final Question question;
  final AppUser currentUser;

  const _UserTile({
    required this.user,
    required this.question,
    required this.currentUser,
  });

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _sent = false;
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(shareQuestionServiceProvider).sendQuestion(
            questionId: widget.question.id,
            toUserId: widget.user.uid,
            fromUsername: widget.currentUser.username,
          );
      if (mounted) setState(() => _sent = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
        child: Text(
          widget.user.username.isNotEmpty
              ? widget.user.username[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        '@${widget.user.username}',
        style: const TextStyle(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      ),
      trailing: _sent
          ? const Icon(Icons.check_circle_rounded,
              color: AppTheme.accent)
          : TextButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.accent),
                    )
                  : const Text('Send',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w700)),
            ),
    );
  }
}
