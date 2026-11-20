import 'dart:async';

import '../models/models.dart';

/// Typing indicator registry according to API-DESIGN.md §8.5.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class TypingRegistry {
  final Map<String, Map<String, ChatUser>> _typingUsers = {};
  final Map<String, Map<String, Timer>> _timers = {};
  final _controller =
      StreamController<Map<String, List<ChatUser>>>.broadcast();

  Stream<Map<String, List<ChatUser>>> get stream => _controller.stream;

  List<ChatUser> getTypingUsers(String conversationId) {
    final map = _typingUsers[conversationId];
    return map != null ? map.values.toList() : const [];
  }

  void setTyping(String conversationId, ChatUser user, bool isTyping) {
    _timers[conversationId]?[user.id]?.cancel();

    if (isTyping) {
      final convMap = _typingUsers.putIfAbsent(conversationId, () => {});
      convMap[user.id] = user;

      final timerMap = _timers.putIfAbsent(conversationId, () => {});
      timerMap[user.id] = Timer(const Duration(seconds: 5), () {
        _expireTyping(conversationId, user.id);
      });
    } else {
      _typingUsers[conversationId]?.remove(user.id);
      _timers[conversationId]?.remove(user.id);
    }

    _notify();
  }

  void _expireTyping(String conversationId, String userId) {
    _typingUsers[conversationId]?.remove(userId);
    _timers[conversationId]?.remove(userId);
    _notify();
  }

  void _notify() {
    final snapshot = <String, List<ChatUser>>{};
    for (final entry in _typingUsers.entries) {
      snapshot[entry.key] = List.unmodifiable(entry.value.values);
    }
    _controller.add(snapshot);
  }

  void clear() {
    for (final timerMap in _timers.values) {
      for (final timer in timerMap.values) {
        timer.cancel();
      }
    }
    _timers.clear();
    _typingUsers.clear();
    _notify();
  }

  void dispose() {
    clear();
    _controller.close();
  }
}
