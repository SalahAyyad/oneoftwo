import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/questions_provider.dart';
import '../../theme/app_theme.dart';

class CreateQuestionScreen extends ConsumerStatefulWidget {
  final String authorUsername;

  const CreateQuestionScreen({super.key, required this.authorUsername});

  @override
  ConsumerState<CreateQuestionScreen> createState() =>
      _CreateQuestionScreenState();
}

class _CreateQuestionScreenState
    extends ConsumerState<CreateQuestionScreen> {
  final _questionController = TextEditingController();
  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final question = _questionController.text.trim();
    final answer1 = _answer1Controller.text.trim();
    final answer2 = _answer2Controller.text.trim();

    if (question.isEmpty || answer1.isEmpty || answer2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(questionsServiceProvider).postQuestion(
            question: question,
            answer1: answer1,
            answer2: answer2,
            authorUsername: widget.authorUsername,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Question'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _post,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR QUESTION',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _questionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Would you rather...',
                counterStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'ANSWER OPTIONS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            _AnswerField(
              controller: _answer1Controller,
              label: 'Option A',
              color: AppTheme.accent,
            ),
            const SizedBox(height: 12),
            _AnswerField(
              controller: _answer2Controller,
              label: 'Option B',
              color: AppTheme.accentPink,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _AnswerField({
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 100,
      decoration: InputDecoration(
        hintText: label,
        counterStyle: const TextStyle(color: AppTheme.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              label[7], // 'A' or 'B'
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
