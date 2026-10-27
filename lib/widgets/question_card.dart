import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../models/question.dart';
import '../providers/questions_provider.dart';
import '../screens/profile/profile_screen.dart';
import '../theme/app_theme.dart';
import 'send_question_sheet.dart';

class QuestionCard extends ConsumerStatefulWidget {
  final Question question;
  final AppUser? currentUser;
  final VoidCallback? onSeen;
  final String? sentByUsername;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentUser,
    this.onSeen,
    this.sentByUsername,
  });

  @override
  ConsumerState<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<QuestionCard>
    with SingleTickerProviderStateMixin {
  bool _voting = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    if (_hasVoted) _animController.value = 1.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSeen?.call();
    });
  }

  @override
  void didUpdateWidget(QuestionCard old) {
    super.didUpdateWidget(old);
    final wasVoted =
        old.currentUser?.votedFor(old.question.id) != null;
    if (!wasVoted && _hasVoted) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int? get _userVote => widget.currentUser?.votedFor(widget.question.id);
  bool get _hasVoted => _userVote != null;

  Future<void> _vote(int answer) async {
    if (_hasVoted || _voting) return;
    setState(() => _voting = true);
    try {
      await ref.read(questionsServiceProvider).vote(
            questionId: widget.question.id,
            answer: answer,
          );
    } finally {
      if (mounted) {
        setState(() => _voting = false);
      }
    }
  }

  void _share() {
    showSendQuestionSheet(context, ref, widget.question, widget.currentUser);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.sentByUsername != null)
              _SentByTag(username: widget.sentByUsername!),
            if (widget.sentByUsername != null) const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 16),
            Text(
              widget.question.question,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            _hasVoted ? _buildResults() : _buildAnswerButtons(),
            const SizedBox(height: 14),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProfileScreen(userId: widget.question.authorId),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                child: Text(
                  widget.question.authorUsername.isNotEmpty
                      ? widget.question.authorUsername[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '@${widget.question.authorUsername}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _share,
          child: const Icon(Icons.ios_share_rounded,
              color: AppTheme.textSecondary, size: 18),
        ),
      ],
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            text: widget.question.answer1,
            color: AppTheme.accent,
            onTap: _voting ? null : () => _vote(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnswerButton(
            text: widget.question.answer2,
            color: AppTheme.accentPink,
            onTap: _voting ? null : () => _vote(2),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final q = widget.question;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _ResultBar(
            text: q.answer1,
            percentage: q.answer1Percentage,
            color: AppTheme.accent,
            isSelected: _userVote == 1,
          ),
          const SizedBox(height: 10),
          _ResultBar(
            text: q.answer2,
            percentage: q.answer2Percentage,
            color: AppTheme.accentPink,
            isSelected: _userVote == 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final total = widget.question.totalVotes;
    return Text(
      total == 0
          ? 'Be the first to vote'
          : '$total ${total == 1 ? 'vote' : 'votes'}',
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _ResultBar extends StatelessWidget {
  final String text;
  final double percentage;
  final Color color;
  final bool isSelected;

  const _ResultBar({
    required this.text,
    required this.percentage,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percentage * 100).round();
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Animated fill bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              child: Container(
                color: color.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Label + percentage
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle_rounded,
                        color: color, size: 16),
                  ),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SentByTag extends StatelessWidget {
  final String username;
  const _SentByTag({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentPink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: AppTheme.accentPink.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.send_rounded,
              size: 11, color: AppTheme.accentPink),
          const SizedBox(width: 4),
          Text(
            'from @$username',
            style: const TextStyle(
              color: AppTheme.accentPink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
