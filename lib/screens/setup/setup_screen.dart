import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
import '../../providers/auth_state_notifier.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

/// Firebase тохируулаагүй үед харуулах заавар дэлгэц
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isChecking = false;
  String? _statusMessage;

  Future<void> _retryFirebaseSetup() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    if (!FirebaseService.isConfigured) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'firebase_options.dart дээр YOUR_API_KEY харагдаж байна.\n'
            'flutterfire configure ажиллуулна уу.';
        _isChecking = false;
      });
      return;
    }

    try {
      await FirebaseService.initialize();
      AuthStateNotifier.instance?.attach();
      if (!mounted) return;

      setState(() => _statusMessage = 'Firebase амжилттай холбогдлоо.');
      context.go('/login');
    } on ConfigException catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformHint = FirebaseService.platformSetupHint;
    final runningOnWeb = kIsWeb;

    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо шаардлагатай')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.settings, size: 64, color: AppTheme.gold),
            const SizedBox(height: 24),
            Text(
              runningOnWeb
                  ? 'Firebase Web тохируулаагүй байна'
                  : 'Firebase Android тохируулаагүй байна',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Апп ажиллуулахын тулд дараах алхмуудыг хийнэ үү:\n\n'
              '1. Firebase Console → Authentication → Email/Password идэвхжүүлнэ\n'
              '2. Cloud Firestore үүсгэнэ\n'
              '3. Firestore Rules: firebase/firestore.rules → Console дээр Publish\n'
              '4. dart pub global activate flutterfire_cli\n'
              '5. flutterfire configure → ${runningOnWeb ? "Web" : "Android"} сонгоно\n'
              '6. q дарж хаагаад дахин: flutter run\n\n'
              '$platformHint\n\n'
              'Эмулятор алдаа: scripts\\windows-emulator-fix.ps1\n'
              'Дэлгэрэнгүй: SETUP.md',
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.contains('амжилттай')
                      ? AppTheme.secondary
                      : AppTheme.destructive,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _retryFirebaseSetup,
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('flutterfire configure хийсний дараа — дахин шалгах'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
