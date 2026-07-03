import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Профайл'),
      ),
      body: FutureBuilder(
        future: authService.getCurrentUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return ErrorDisplayWidget(message: 'Алдаа: ${snapshot.error}');
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const ErrorDisplayWidget(message: 'Профайл олдсонгүй');
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileTile(label: 'Нэр', value: profile.name),
              _ProfileTile(label: 'Имэйл', value: profile.email),
              _ProfileTile(label: 'Утас', value: profile.phone),
              _ProfileTile(
                label: 'Миний санал',
                value: '${profile.bidBalance} үлдэгдсэн',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/topup'),
                child: const Text('Санал багц авах'),
              ),
              const SizedBox(height: 32),
              const Text(
                'Миний ялсан',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Удахгүй нэмэгдэнэ...',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Миний санал',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Удахгүй нэмэгдэнэ...',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
