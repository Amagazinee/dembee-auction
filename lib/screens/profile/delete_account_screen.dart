import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Бүртгэл бүрмөсөн устгах
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();

  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Баталгаажуулалтыг сонгоно уу')),
      );
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нууц үгээ оруулна уу')),
      );
      return;
    }

    setState(() => _deleting = true);
    try {
      await _authService.deleteAccount(password: password);
      if (!mounted) return;
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүртгэл амжилттай устгагдлаа'),
          backgroundColor: AppTheme.secondary,
        ),
      );
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: 'Бүртгэл устгах',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.destructive.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Анхааруулга',
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 14,
                      color: AppTheme.destructive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Бүртгэл устгасны дараа сэргээх боломжгүй. '
                    'Үлдсэн санал, түүх устахгүй ч дансанд нэвтрэх боломжгүй болно.',
                    style: AppTheme.bodyStyle.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              title: Text(
                'Би бүртгэлээ бүрмөсөн устгахыг зөвшөөрч байна',
                style: AppTheme.bodyStyle.copyWith(fontSize: 13),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: AppTheme.bodyStyle,
              decoration: const InputDecoration(
                labelText: 'Нууц үг (баталгаажуулах)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _deleting ? null : _delete,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.destructive,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(_deleting ? 'Устгаж байна...' : 'Бүртгэл устгах'),
            ),
          ],
        ),
      ),
    );
  }
}
