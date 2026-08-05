import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/submit_screen.dart';
import 'services/submit_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.backgroundDeep,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PortraitSubmitApp());
}

class PortraitSubmitApp extends StatelessWidget {
  const PortraitSubmitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portrait',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SubmitScreen(submitService: SubmitService()),
    );
  }
}
