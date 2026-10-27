import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/question_card.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final questionsAsync = ref.watch(userQuestionsProvider(userId));
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    final currentUser = currentUserAsync.valueOrNull;
    final isOwnProfile = currentUser?.uid == userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(profileAsync.valueOrNull?.username ?? '...'),
        actions: [
          if (isOwnProfile)
            TextButton(
              onPressed: () => _confirmSignOut(context, ref),
              child: const Text('Sign out',
                  style: TextStyle(color: AppTheme.accentPink)),
            ),
        ],
      ),
      body: questionsAsync.when(
        data: (questions) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                userId: userId,
                isOwnProfile: isOwnProfile,
                questions: questions,
                votedCount: isOwnProfile
                    ? (currentUser?.votedQuestions.length ?? 0)
                    : null,
              ),
            ),
            if (questions.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No questions yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => QuestionCard(
                      question: questions[i],
                      currentUser: currentUser,
                    ),
                    childCount: questions.length,
                  ),
                ),
              ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          // If error mentions 'index', a Firestore composite index is needed.
          // Firebase will print a link in the debug console to create it.
          return Center(
            child: Text('Error: $e',
                style: const TextStyle(color: Colors.redAccent)),
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
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
  }
}

class _ProfileHeader extends ConsumerWidget {
  final String userId;
  final bool isOwnProfile;
  final List<Question> questions;
  final int? votedCount;

  const _ProfileHeader({
    required this.userId,
    required this.isOwnProfile,
    required this.questions,
    this.votedCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final username = profileAsync.valueOrNull?.username ?? '...';
    final isFollowingAsync = ref.watch(isFollowingProvider(userId));
    final followersAsync = ref.watch(followersCountProvider(userId));
    final followingAsync = ref.watch(followingCountProvider(userId));

    final totalVotesReceived =
        questions.fold<int>(0, (sum, q) => sum + q.totalVotes);
    final totalQuestionsPosted = questions.length;
    final mostVotedQuestion = questions.isEmpty
        ? null
        : questions.reduce(
            (a, b) => a.totalVotes >= b.totalVotes ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '@$username',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          // Followers / Following counts
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FollowCount(
                  value: followersAsync.valueOrNull ?? 0,
                  label: 'Followers'),
              const SizedBox(width: 24),
              _FollowCount(
                  value: followingAsync.valueOrNull ?? 0,
                  label: 'Following'),
            ],
          ),
          const SizedBox(height: 14),
          // Follow / own profile label
          if (isOwnProfile)
            const Text('Your profile',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13))
          else
            _FollowButton(
              userId: userId,
              isFollowing: isFollowingAsync.valueOrNull ?? false,
            ),
          const SizedBox(height: 24),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(
                  value: '$totalQuestionsPosted',
                  label: 'Questions\nasked'),
              _divider(),
              _StatBox(
                  value: '$totalVotesReceived',
                  label: 'Votes\nreceived'),
              if (isOwnProfile && votedCount != null) ...[
                _divider(),
                _StatBox(
                    value: '$votedCount',
                    label: 'Questions\nvoted on'),
              ],
            ],
          ),
          if (mostVotedQuestion != null) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mostVotedQuestion.question,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mostVotedQuestion.totalVotes} votes',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'QUESTIONS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: AppTheme.divider,
      );
}

class _FollowCount extends StatelessWidget {
  final int value;
  final String label;

  const _FollowCount({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String userId;
  final bool isFollowing;

  const _FollowButton(
      {required this.userId, required this.isFollowing});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      if (widget.isFollowing) {
        await ref.read(followServiceProvider).unfollow(widget.userId);
      } else {
        await ref.read(followServiceProvider).follow(widget.userId);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = widget.isFollowing;
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          color: following
              ? Colors.transparent
              : AppTheme.accent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: following ? AppTheme.divider : AppTheme.accent,
            width: 1.5,
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent),
              )
            : Text(
                following ? 'Following' : 'Follow',
                style: TextStyle(
                  color: following
                      ? AppTheme.textSecondary
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
