import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

/// Firebase тохируулаагүй үед харуулах заавар дэлгэц
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Firebase тохируулаагүй байна',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Апп ажиллуулахын тулд дараах алхмуудыг хийнэ үү:\n\n'
              '1. Firebase Console дээр төсөл үүсгэнэ\n'
              '2. Authentication (Email) идэвхжүүлнэ\n'
              '3. Cloud Firestore үүсгэнэ\n'
              '4. Firestore Rules: firebase/firestore.rules агуулгыг Console → Firestore → Rules дээр тавина\n'
              '5. Терминалд: dart pub global activate flutterfire_cli\n'
              '6. Терминалд: flutterfire configure\n'
              '7. Аппыг дахин ажиллуулна: flutter run\n\n'
              'Дэлгэрэнгүй: SETUP.md файлыг уншина уу.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Firebase тохируулсан — үргэлжлүүлэх'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
