import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Figma Санал хүсэлт
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _controller = TextEditingController();
  int _rating = 0;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Үнэлгээ сонгоно уу'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Санал бичнэ үү'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sent = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Санал хүсэлт илгээгдлээ. Баярлалаа!'),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _controller.clear();
    setState(() => _rating = 0);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: 'Санал хүсэлт',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Үнэлгээ',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                final filled = star <= _rating;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                  onPressed: _sent ? null : () => setState(() => _rating = star),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              'Санал хүсэлт',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: 'Таны санал, шүүмж, гомдол...',
                filled: true,
                fillColor: AppTheme.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Илгээх'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
