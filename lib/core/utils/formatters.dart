/// Ялагч тодорхойлох тооллого — MM.SS.mmm
String formatWinCountdownMs(Duration duration) {
  if (duration.isNegative) return '00.000';
  final totalMs = duration.inMilliseconds;
  final minutes = totalMs ~/ 60000;
  final seconds = (totalMs % 60000) ~/ 1000;
  final millis = totalMs % 1000;
  return '${minutes.toString().padLeft(2, '0')}.'
      '${seconds.toString().padLeft(2, '0')}.'
      '${millis.toString().padLeft(3, '0')}';
}

/// Үе хаагдах тооллого — өдөр : цаг : мин : сек
String formatPhaseCountdown(Duration duration) {
  if (duration.isNegative) {
    return '00 : 00 : 00 : 00';
  }
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return '${days.toString().padLeft(2, '0')} : '
      '${hours.toString().padLeft(2, '0')} : '
      '${minutes.toString().padLeft(2, '0')} : '
      '${seconds.toString().padLeft(2, '0')}';
}

/// Саналын цаг — цаг:мин:сек.долио
String formatBidClock(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  final cs = (dt.millisecond ~/ 10).toString().padLeft(2, '0');
  return '$h:$m:$s.$cs';
}

/// Үеийн цагийн хүрээ — 21:30:00-22:10:00
String formatPhaseTimeRange(DateTime start, Duration duration) {
  final end = start.add(duration);
  String t(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }
  return '${t(start)}-${t(end)}';
}

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

/// Огноо — 2026-03-15
String formatDate(DateTime dt) {
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '${dt.year}-$m-$d';
}

/// Огноо цаг — 2026-03-15 14:30
String formatDateTime(DateTime dt) {
  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

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

/// Тооллогын сүүлийн 5 секунд улаанаар харуулах
bool isUrgentCountdown(Duration remaining) {
  return !remaining.isNegative && remaining.inSeconds <= 5;
}

/// Дуудлага эхлэх цаг — 2026 оны 7 сарын 15 өдөр 14:30
String formatScheduledStart(DateTime dt) {
  return '${dt.year} оны ${dt.month} сарын ${dt.day} өдөр '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Хэзээнээс хойш — 5м өмнө
String formatTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.isNegative || diff.inSeconds < 60) return 'одоо';
  if (diff.inMinutes < 60) return '${diff.inMinutes}м өмнө';
  if (diff.inHours < 24) return '${diff.inHours}ц өмнө';
  if (diff.inDays < 7) return '${diff.inDays}ө өмнө';
  return formatDate(dt);
}
