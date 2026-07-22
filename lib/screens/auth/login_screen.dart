import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_split_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!FirebaseService.isInitialized) {
      setState(() => _errorMessage = FirebaseService.firebaseNotReadyMessage);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) context.go('/home');
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Алдаа гарлаа: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!FirebaseService.isInitialized) {
      setState(() => _errorMessage = FirebaseService.firebaseNotReadyMessage);
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Нууц үг сэргээхийн тулд имэйлээ оруулна уу');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _successMessage = 'Сэргээх холбоос $email руу илгээгдлээ');
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = FirebaseService.isInitialized;

    return AuthSplitLayout(
      formTitle: 'Нэвтрэх',
      formChild: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!firebaseReady) ...[
              _FirebaseWarning(message: FirebaseService.firebaseNotReadyMessage),
              const SizedBox(height: 14),
            ],
            AuthTextField(
              controller: _emailController,
              hint: 'И-мэйл хаяг',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'И-мэйл оруулна уу';
                if (!v.contains('@')) return 'И-мэйл буруу байна';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: _passwordController,
              hint: 'Нууц үг',
              icon: Icons.lock_outline,
              obscureText: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) =>
                  v == null || v.length < 6 ? '6+ тэмдэгт' : null,
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
              onPressed: (_isLoading || !firebaseReady) ? null : _login,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Нэвтрэх'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: AppTheme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ЭСВЭЛ',
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 11,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppTheme.border)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/register'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.foreground,
                side: const BorderSide(color: AppTheme.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Шинэ бүртгэл үүсгэх'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (_isLoading || !firebaseReady) ? null : _resetPassword,
              child: Text(
                'Нууц үгээ мартсан уу?',
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirebaseWarning extends StatelessWidget {
  const _FirebaseWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive),
      ),
      child: Text(
        message,
        style: AppTheme.bodyStyle.copyWith(color: AppTheme.destructive),
      ),
    );
  }
}
