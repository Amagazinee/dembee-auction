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

/// Үнийг ₮ форматаар харуулах
String formatPrice(int price) => '$price₮';
