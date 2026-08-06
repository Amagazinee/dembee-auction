import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_split_layout.dart';

/// Имэйлийн холбоосоор ирсэн хэрэглэгч шинэ нууц үг тохируулна
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.oobCode,
    this.authService,
  });

  final String? oobCode;
  final AuthService? authService;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final AuthService _authService = widget.authService ?? AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!FirebaseService.isInitialized) {
      setState(() => _errorMessage = FirebaseService.firebaseNotReadyMessage);
      return;
    }

    final oobCode = widget.oobCode;
    if (oobCode == null || oobCode.isEmpty) {
      setState(() => _errorMessage = 'Холбоос хүчингүй эсвэл хугацаа дууссан байна');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.confirmPasswordReset(
        oobCode: oobCode,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _successMessage = 'Нууц үг амжилттай шинэчлэгдлээ. Одоо нэвтэрнэ үү.';
      });
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = widget.oobCode?.isNotEmpty == true;

    return AuthSplitLayout(
      formTitle: 'Шинэ нууц үг',
      formChild: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasCode
                  ? 'Имэйлийн холбоосоор ирсэн тул шинэ нууц үгээ оруулна уу.'
                  : 'Нууц үг сэргээх холбоос хүчингүй байна. Дахин имэйл илгээнэ үү.',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AuthTextField(
              controller: _passwordController,
              hint: 'Шинэ нууц үг',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? '6+ тэмдэгт' : null,
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _confirmController,
              hint: 'Нууц үг давтах',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Нууц үг таарахгүй байна';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.destructive),
                textAlign: TextAlign.center,
              ),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                _successMessage!,
                style: const TextStyle(color: AppTheme.secondary),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_isLoading || !hasCode) ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Нууц үг хадгалах'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                _successMessage != null ? 'Нэвтрэх' : 'Нэвтрэх хуудас руу буцах',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
