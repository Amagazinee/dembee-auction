import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Figma "ЯАЖ АЖИЛЛАДАГ?"
class HowItWorksPanel extends StatelessWidget {
  const HowItWorksPanel({super.key});

  static const _bullets = [
    'Санал багц худалдан авч санал аваарай',
    'Санал бүр үнийг ₮1–₮5-аар нэмнэ',
    'Санал бүр «Ялагч тодорхойлох» хугацааг дахин эхлүүлнэ',
    'Хугацаа 0 болоход сүүлийн санал ялагч болно',
    'Үе дуусвал дараагийн үе рүү шилжинэ',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ЯАЖ АЖИЛЛАДАГ?',
            style: AppTheme.headingStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 10),
          ..._bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: AppTheme.bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
