import 'dart:async';

import '../models/models.dart';

/// User presence registry according to API-DESIGN.md §8.5.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class PresenceRegistry {
  final Map<String, UserPresence> _presence = {};
  final _controller = StreamController<Map<String, UserPresence>>.broadcast();

  Stream<Map<String, UserPresence>> get stream => _controller.stream;

  UserPresence getPresence(String userId) =>
      _presence[userId] ?? UserPresence.unknown;

  void setPresence(String userId, UserPresence presence) {
    _presence[userId] = presence;
    _controller.add(Map.unmodifiable(_presence));
  }

  void clear() {
    _presence.clear();
    _controller.add(const {});
  }

  void dispose() {
    clear();
    _controller.close();
  }
}
