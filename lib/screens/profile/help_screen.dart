import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

/// Figma Тусламж дэлгэц
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _call() async {
    final uri = Uri.parse('tel:77001122');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email() async {
    final uri = Uri.parse('mailto:support@dembee.mn');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: 'Тусламж',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SupportContactCard(
            icon: Icons.phone_outlined,
            title: 'Утсаар холбогдох',
            value: '7700-1122',
            subtitle: 'Даваа-Баасан · 09:00–18:00',
            actionLabel: 'Залгах',
            onAction: _call,
          ),
          SupportContactCard(
            icon: Icons.email_outlined,
            title: 'И-мэйлээр холбогдох',
            value: 'support@dembee.mn',
            subtitle: '24 цагийн дотор хариулна',
            actionLabel: 'Бичих',
            onAction: _email,
          ),
          SupportContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'Чат дэмжлэг',
            value: 'Шууд чат',
            subtitle: 'Ажлын цагаар боломжтой',
            actionLabel: 'Нээх',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Чат дэмжлэг удахгүй нээгдэнэ'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
