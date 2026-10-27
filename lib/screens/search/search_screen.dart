import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/follow_provider.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';

final _userSearchProvider =
    FutureProvider.family<List<AppUser>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final lower = query.trim().toLowerCase();
  final end = lower.substring(0, lower.length - 1) +
      String.fromCharCode(lower.codeUnitAt(lower.length - 1) + 1);
  final docs = await FirebaseFirestore.instance
      .collection('users')
      .where('usernameLower', isGreaterThanOrEqualTo: lower)
      .where('usernameLower', isLessThan: end)
      .limit(20)
      .get();
  return docs.docs.map(AppUser.fromFirestore).toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = ref.watch(authStateProvider).valueOrNull?.uid;
    final resultsAsync = ref.watch(_userSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted && v == _controller.text) {
                setState(() => _query = v.trim());
              }
            });
          },
        ),
        leading: const BackButton(),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Text('Type a username to search',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          : resultsAsync.when(
              data: (users) {
                final filtered =
                    users.where((u) => u.uid != currentUid).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No users found',
                        style:
                            TextStyle(color: AppTheme.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppTheme.divider, height: 1),
                  itemBuilder: (_, i) => _UserSearchTile(
                    user: filtered[i],
                    currentUid: currentUid,
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                  child: Text('Error searching',
                      style:
                          TextStyle(color: AppTheme.textSecondary))),
            ),
    );
  }
}

class _UserSearchTile extends ConsumerWidget {
  final AppUser user;
  final String? currentUid;

  const _UserSearchTile({required this.user, this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(user.uid));
    final isFollowing = isFollowingAsync.valueOrNull ?? false;

    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: user.uid)),
      ),
      leading: CircleAvatar(
        backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
        child: Text(
          user.username.isNotEmpty
              ? user.username[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text('@${user.username}',
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600)),
      trailing: currentUid == null
          ? null
          : _FollowToggle(
              userId: user.uid, isFollowing: isFollowing),
    );
  }
}

class _FollowToggle extends ConsumerStatefulWidget {
  final String userId;
  final bool isFollowing;

  const _FollowToggle(
      {required this.userId, required this.isFollowing});

  @override
  ConsumerState<_FollowToggle> createState() => _FollowToggleState();
}

class _FollowToggleState extends ConsumerState<_FollowToggle> {
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
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isFollowing ? Colors.transparent : AppTheme.accent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isFollowing ? AppTheme.divider : AppTheme.accent,
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.accent))
            : Text(
                widget.isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: widget.isFollowing
                      ? AppTheme.textSecondary
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}
