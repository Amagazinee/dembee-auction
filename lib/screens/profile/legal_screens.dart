import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

class _TextSection {
  const _TextSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// Figma текст хуудас — нөхцөл, бодлого гэх мэт
class TextPageScreen extends StatelessWidget {
  const TextPageScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<_TextSection> sections;

  @override
  Widget build(BuildContext context) {
    return ProfileSubPageScaffold(
      title: title,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 28),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: AppTheme.headingStyle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                section.body,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 14,
                  color: AppTheme.mutedForeground,
                  height: 1.6,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Figma Нууцлалын бодлого
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    _TextSection(
      title: '1. Мэдээлэл цуглуулах',
      body:
          'Бид таны нэр, и-мэйл хаяг, утасны дугаар болон үйл ажиллагааны мэдээллийг цуглуулна. Энэхүү мэдээлэл нь үйлчилгээ үзүүлэх зорилгоор ашиглагдана.',
    ),
    _TextSection(
      title: '2. Мэдээлэл хамгаалах',
      body:
          'Таны хувийн мэдээллийг SSL шифрлэлтээр хамгаалж, зөвхөн зөвшөөрөлтэй ажилтнуудад нэвтрэх боломж олгоно.',
    ),
    _TextSection(
      title: '3. Гуравдагч этгээд',
      body:
          'Бид таны хувийн мэдээллийг гуравдагч этгээдэд зарах, дамжуулах үйлдлийг хийхгүй. Зөвхөн хуулийн шаардлагын дагуу холбогдох байгууллагад өгч болно.',
    ),
    _TextSection(
      title: '4. Cookie ашиглалт',
      body:
          'Вэб сайтын үйл ажиллагааг сайжруулах зорилгоор cookie файлуудыг ашигладаг. Та browser-ийн тохиргооноос идэвхгүй болгох боломжтой.',
    ),
    _TextSection(
      title: '5. Холбогдох',
      body:
          'Нууцлалтай холбоотой асуудлаар privacy@dembee.mn хаягаар холбогдоно уу.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TextPageScreen(
      title: 'Нууцлалын бодлого',
      sections: _sections,
    );
  }
}

/// Figma Үйлчилгээний нөхцөл
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _sections = [
    _TextSection(
      title: '1. Ерөнхий нөхцөл',
      body:
          'ДЭМБЭЭ платформыг ашигласнаар та энэхүү үйлчилгээний нөхцөлийг зөвшөөрсөнд тооцогдоно. 18 нас хүрсэн иргэд ашиглах боломжтой.',
    ),
    _TextSection(
      title: '2. Санал хэрэглэх',
      body:
          'Санал бол буцаан олгогдохгүй виртуал нэгж юм. Санал илгээснээр дуудлаганд оролцсон гэж тооцогдоно. Санал буцаан авах боломжгүй.',
    ),
    _TextSection(
      title: '3. Ялалт болон хүргэлт',
      body:
          'Ялагч нь 24 цагийн дотор холбоо барина. Хоёр дахь оролдлого амжилтгүй болсон тохиолдолд ялалтыг хүчингүй болгож дараагийн оролцогчид шилжүүлэх эрхтэй.',
    ),
    _TextSection(
      title: '4. Хориглох зүйлс',
      body:
          'Бот, автомат систем ашиглах, данс хуваалцах, системийн эмзэг байдлыг ашиглах үйлдлийг хатуу хориглоно. Зөрчсөн тохиолдолд данс хааж болно.',
    ),
    _TextSection(
      title: '5. Нөхцөл өөрчлөлт',
      body:
          'ДЭМБЭЭ нь үйлчилгээний нөхцөлийг урьдчилан мэдэгдэлгүйгээр өөрчлөх эрхтэй. Өөрчлөлтийг и-мэйлээр мэдэгдэнэ.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const TextPageScreen(
      title: 'Үйлчилгээний нөхцөл',
      sections: _sections,
    );
  }
}
