import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

/// Мэдэгдлийн төлөв — Firestore-оос realtime уншина
class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier._();

  static final NotificationNotifier instance = NotificationNotifier._();

  final NotificationService _service = NotificationService();
  Stream<List<AppNotification>>? _stream;
  List<AppNotification> _items = const [];
  String? _userUid;
  bool _listening = false;

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.read).length;

  void attach(String userUid) {
    if (!FirebaseService.isInitialized) return;
    if (_userUid == userUid && _listening) return;

    detach();
    _userUid = userUid;
    _listening = true;
    _stream = _service.watchUserNotifications(userUid);
    _stream!.listen(
      (items) {
        _items = items;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Notification stream error: $e');
      },
    );
  }

  void detach() {
    _userUid = null;
    _listening = false;
    _stream = null;
    _items = const [];
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0 || _items[index].read) return;

    _items = [
      for (var i = 0; i < _items.length; i++)
        if (i == index) _items[i].copyWith(read: true) else _items[i],
    ];
    notifyListeners();

    try {
      await _service.markAsRead(id);
    } catch (e) {
      debugPrint('markAsRead failed: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0 || _userUid == null) return;

    _items = [for (final n in _items) n.copyWith(read: true)];
    notifyListeners();

    try {
      await _service.markAllAsRead(_userUid!);
    } catch (e) {
      debugPrint('markAllAsRead failed: $e');
    }
  }

  Future<void> deleteAll() async {
    if (_items.isEmpty || _userUid == null) return;

    _items = [];
    notifyListeners();

    try {
      await _service.deleteAllForUser(_userUid!);
    } catch (e) {
      debugPrint('deleteAll failed: $e');
    }
  }
}
