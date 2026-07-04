class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.read = false,
  });

  final String id;
  final String kind; // winner | new_auction | topup | phase
  final String title;
  final String body;
  final String timeAgo;
  final bool read;

  AppNotification copyWith({
    String? id,
    String? kind,
    String? title,
    String? body,
    String? timeAgo,
    bool? read,
  }) {
    return AppNotification(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      timeAgo: timeAgo ?? this.timeAgo,
      read: read ?? this.read,
    );
  }
}
