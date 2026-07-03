import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dembee_logo.dart';

/// Figma Auth — зүүн hero + баруун form
class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.formTitle,
    required this.formChild,
  });

  final String formTitle;
  final Widget formChild;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: wide
              ? Row(
                  children: [
                    Expanded(child: _HeroSection(compact: false)),
                    Expanded(
                      child: _FormSection(
                        title: formTitle,
                        child: formChild,
                        showBorder: true,
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroSection(compact: true),
                      _FormSection(
                        title: formTitle,
                        child: formChild,
                        showBorder: false,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 32 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DembeeLogo(size: 40, textSize: 22),
          SizedBox(height: compact ? 32 : 64),
          Text(
            'Монголын Хамгийн Том\nДуудлага Худалдаа',
            style: AppTheme.headingStyle.copyWith(
              fontSize: compact ? 28 : 36,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Онлайн дуудлага худалдаа',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
          SizedBox(height: compact ? 32 : 80),
          const _StatRow(label: 'Нийт хэрэглэгч', value: '12,400+'),
          const Divider(color: AppTheme.border, height: 32),
          const _StatRow(label: 'Дуусгасан дуудлага', value: '3,200+'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.mutedForeground),
        ),
        Text(
          value,
          style: AppTheme.monoStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.child,
    this.showBorder = true,
  });

  final String title;
  final Widget child;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: showBorder
          ? const BoxDecoration(
              border: Border(left: BorderSide(color: AppTheme.border)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.headingStyle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

/// Figma input field
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTheme.bodyStyle,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.mutedForeground),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
