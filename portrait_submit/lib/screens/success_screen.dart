import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/submission.dart';
import '../services/submit_service.dart';
import '../theme/app_theme.dart';
import 'submit_screen.dart';

/// Дэлгэц 2: амжилттай илгээлээ.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.backgroundDeep,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.85, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          width: 160,
                          height: 200,
                          child: Image.file(
                            File(submission.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Илгээгдлээ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      submission.fullName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Овог, нэр, цээж зураг амжилттай хадгалагдлаа.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        height: 1.45,
                        color: AppTheme.muted,
                      ),
                    ),
                    const Spacer(flex: 3),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => SubmitScreen(
                              submitService: SubmitService(),
                            ),
                          ),
                        );
                      },
                      child: const Text('Шинээр илгээх'),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
