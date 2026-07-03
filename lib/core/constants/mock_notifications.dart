import '../../models/notification_model.dart';

class MockNotifications {
  MockNotifications._();

  static const List<AppNotification> items = [
    AppNotification(
      id: '1',
      kind: 'winner',
      title: '🏆 Ялагч тодорлоо!',
      body:
          'Apple Watch Ultra 2 — ялагч: Э.Болд***, үнэ: ₮22,400',
      timeAgo: '1м өмнө',
    ),
    AppNotification(
      id: '2',
      kind: 'winner',
      title: '🏆 Ялагч тодорлоо!',
      body:
          'DJI Mini 4 Pro Дрон — ялагч: Т.Баяр***, үнэ: ₮18,600',
      timeAgo: '1м өмнө',
    ),
    AppNotification(
      id: '3',
      kind: 'new_auction',
      title: '🆕 Шинэ дуудлага нэмэгдлээ',
      body:
          'iPhone 15 Pro Max 256GB дуудлага худалдаанд орлоо. Одоо оролцох!',
      timeAgo: '1м өмнө',
    ),
  ];

  static int get unreadCount => items.where((n) => !n.read).length;
}
