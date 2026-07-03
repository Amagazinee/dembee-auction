/// Цагийн формат — countdown-д ашиглана
String formatDuration(Duration duration) {
  if (duration.isNegative) return '00:00:00';

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Тоог мянгатын тусгаарлагчтай
String formatNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return negative ? '-${buffer.toString()}' : buffer.toString();
}

/// Үнийг ₮ форматаар харуулах
String formatPrice(int price) => '${formatNumber(price)}₮';

/// Хэмнэлт — Figma "₮3.49сая хэмнэлт"
String formatSavings(int savings) {
  if (savings <= 0) return '';
  if (savings >= 1000000) {
    final millions = savings / 1000000;
    return '₮${millions.toStringAsFixed(2)}сая хэмнэлт';
  }
  return '${formatPrice(savings)} хэмнэлт';
}

/// Нэр масклах — "Б.Дорж***"
String maskName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '***';
  if (parts.length == 1) {
    final n = parts.first;
    if (n.length <= 2) return '$n***';
    return '${n.substring(0, n.length.clamp(0, 4))}***';
  }
  final first = parts.first;
  final last = parts.last;
  final initial = first.isNotEmpty ? first[0] : '';
  final lastPart = last.length > 1 ? last.substring(0, last.length.clamp(0, 4)) : last;
  return '$initial.$lastPart***';
}
