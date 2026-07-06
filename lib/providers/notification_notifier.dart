import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

/// Мэдэгдлийн төлөв — mock өгөгдөл (удаа дараа Firestore/FCM)
class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier._();

  static final NotificationNotifier instance = NotificationNotifier._();

  List<AppNotification> _items = const [
    AppNotification(
      id: '1',
      kind: 'winner',
      title: '🏆 Ялагч тодорхойлогдлоо!',
      body: 'Apple Watch Ultra 2 — ялагч: Э.Болд***, үнэ: ₮22,400',
      timeAgo: '1м өмнө',
    ),
    AppNotification(
      id: '2',
      kind: 'winner',
      title: '🏆 Ялагч тодорхойлогдлоо!',
      body: 'DJI Mini 4 Pro Дрон — ялагч: Т.Баяр***, үнэ: ₮18,600',
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

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.read).length;

  void markAsRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].read) return;

    _items = [
      for (var i = 0; i < _items.length; i++)
        if (i == index) _items[i].copyWith(read: true) else _items[i],
    ];
    notifyListeners();
  }

  void markAllAsRead() {
    if (unreadCount == 0) return;

    _items = [for (final n in _items) n.copyWith(read: true)];
    notifyListeners();
  }

  void deleteAll() {
    if (_items.isEmpty) return;

    _items = [];
    notifyListeners();
  }
}
