import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/shelf_model.dart';

class ShelvesProvider with ChangeNotifier {
  final User? user;
  final DatabaseReference db = FirebaseDatabase.instance.ref();
  Map<String, ShelfModel> shelves = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _subs = {};

  ShelvesProvider(this.user) {
    if (user != null) {
      _listenUserShelves();
    }
  }

  void _listenUserShelves() {
    final ref = db.child('users/${user!.uid}/shelves');
    ref.onValue.listen((event) {
      final val = event.snapshot.value;
      if (val == null) return;
      final map = Map<String, dynamic>.from(val as Map);
      for (var shelfId in map.keys) {
        if (!_subs.containsKey(shelfId)) _subscribeShelf(shelfId);
      }
    });
  }

  Future<void> attachShelfById(String shelfId) async {
    await db.child('users/${user!.uid}/shelves/$shelfId').set(true);
    _subscribeShelf(shelfId);
  }

  void _subscribeShelf(String shelfId) {
    final ref = db.child('shelves/$shelfId');
    final sub = ref.onValue.listen((event) {
      if (event.snapshot.value == null) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      shelves[shelfId] = ShelfModel.fromMap(shelfId, data);
      notifyListeners();
    });
    _subs[shelfId] = sub;
  }

  Future<String> createImprovShelf({String? ownerUid}) async {
    final id = const Uuid().v4().substring(0, 8);
    final shelfRef = db.child('shelves/$id');
    final data =
    ShelfModel.improvised(id, ownerUid ?? user?.uid ?? 'unknown').toMap();
    await shelfRef.set(data);
    await db.child('users/${user?.uid}/shelves/$id').set(true);
    return id;
  }

  Future<void> toggleLight(String shelfId, int index, bool value) async {
    await db.child('shelves/$shelfId/lights/$index').set(value ? 1 : 0);
  }

  Future<void> enableAutoIrrigation(String shelfId, bool enable) async {
    await db.child('shelves/$shelfId/auto').set(enable);
  }

  Future<void> togglePump(String shelfId, int pumpIndex, bool value) async {
    await db.child('shelves/$shelfId/pumps/$pumpIndex').set(value ? 1 : 0);
    if (value && user != null) {
      final scoreRef = db.child('users/${user!.uid}/score');
      await scoreRef.runTransaction((Object? data) {
        final current = (data is num) ? data.toDouble() : 0.0;
        return Transaction.success(current + 5.0);
      });
    }
  }

  /// 🗑️ Удаление стеллажа (и отписка от обновлений)
  Future<void> removeShelf(String shelfId) async {
    try {
      // Удаляем из локальной карты и уведомляем слушателей
      shelves.remove(shelfId);
      notifyListeners();

      // Отписываем слушателя Firebase, если есть
      if (_subs.containsKey(shelfId)) {
        await _subs[shelfId]?.cancel();
        _subs.remove(shelfId);
      }

      // Удаляем связь пользователя с этим стеллажом
      if (user != null) {
        await db.child('users/${user!.uid}/shelves/$shelfId').remove();
      }

      // ❗ Удалять сам стеллаж из базы полностью
      // только если он не используется другими пользователями
      await db.child('shelves/$shelfId').remove();
    } catch (e) {
      debugPrint('Ошибка при удалении стеллажа: $e');
    }
  }

  @override
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
