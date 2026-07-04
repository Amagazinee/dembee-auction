import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/app_exception.dart';
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

    try {
      await FirebaseService.initialize();
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
    final isReady =
        FirebaseService.isConfigured && FirebaseService.isInitialized;

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
                  : 'Firebase тохируулаагүй байна',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Апп ажиллуулахын тулд дараах алхмуудыг хийнэ үү:\n\n'
              '1. Firebase Console дээр төсөл үүсгэнэ\n'
              '2. Authentication → Sign-in method → Email/Password идэвхжүүлнэ\n'
              '3. Cloud Firestore үүсгэнэ\n'
              '4. Firestore Rules: firebase/firestore.rules агуулгыг Console → Firestore → Rules дээр тавина\n'
              '5. Терминалд: dart pub global activate flutterfire_cli\n'
              '6. Терминалд: flutterfire configure\n'
              '   → Android болон Web (Chrome ашиглавал заавал) сонгоно\n'
              '7. Аппыг бүрэн дахин ажиллуулна: flutter run\n'
              '   (q дарж хаагаад дахин эхлүүлнэ — hot reload хангалтгүй)\n\n'
              '$platformHint\n\n'
              'Дэлгэрэнгүй: SETUP.md файлыг уншина уу.',
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: isReady ? AppTheme.secondary : AppTheme.destructive,
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
