import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/profile_sub_page_scaffold.dart';

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// Figma Түгээмэл асуултууд
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _items = [
    _FaqItem(
      question: 'Санал гэж юу вэ?',
      answer:
          'Санал бол дуудлага худалдаанд оролцох эрх. Санал багц худалдан авч, нэг санал бүрт ₮1–₮5-аар үнэ нэмнэ.',
    ),
    _FaqItem(
      question: 'Яаж ялагч тодордог вэ?',
      answer:
          '«Ялагч тодрох» тооллого 0 болоход хамгийн сүүлд санал явуулсан хэрэглэгч ялагч болно. Санал бүр тооллогыг дахин эхлүүлнэ.',
    ),
    _FaqItem(
      question: '8 үе яаж ажилладаг вэ?',
      answer:
          'Дуудлага 8 үеэс бүрдэнэ. Үе бүр өөр хугацаатай. Үе дуусахад дараагийн үе рүү шилжинэ, ялагч тодрох хугацаа богиносно.',
    ),
    _FaqItem(
      question: 'Илгээсэн санал буцаагдах уу?',
      answer: 'Үгүй. Илгээсэн санал буцаагдахгүй. Санал багц худалдан авахад л шинээр нэмэгдэнэ.',
    ),
    _FaqItem(
      question: 'Ялагчид бараагаа хэрхэн хүлээн авах вэ?',
      answer:
          'Ялагч тодорсны дараа бид тантай холбогдож хүргэлт эсвэл авах цэгийн мэдээллийг өгнө.',
    ),
    _FaqItem(
      question: 'Данс цэнэглэлт хийх аргууд юу байна?',
      answer: 'QPay, Khan Bank, Golomt Bank, TDB зэрэг төлбөрийн сувгуудаар санал багц авах боломжтой.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filtered {
    if (_query.trim().isEmpty) return _items;
    final q = _query.toLowerCase();
    return _items
        .where(
          (i) =>
              i.question.toLowerCase().contains(q) ||
              i.answer.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return ProfileSubPageScaffold(
      title: 'Түгээмэл асуултууд',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                hintText: 'Хайх...',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppTheme.mutedForeground,
                ),
                filled: true,
                fillColor: AppTheme.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        16,
                      ),
                      iconColor: AppTheme.mutedForeground,
                      collapsedIconColor: AppTheme.mutedForeground,
                      title: Text(
                        item.question,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.answer,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
