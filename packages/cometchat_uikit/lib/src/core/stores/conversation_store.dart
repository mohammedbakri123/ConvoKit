import 'dart:async';

import '../models/models.dart';

/// Conversation store according to API-DESIGN.md §8.5.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class ConversationStore {
  final List<ChatConversation> _conversations = [];
  final _controller = StreamController<List<ChatConversation>>.broadcast();

  Stream<List<ChatConversation>> get stream => _controller.stream;
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  void setConversations(List<ChatConversation> list) {
    _conversations.clear();
    _conversations.addAll(list);
    _sort();
    _controller.add(List.unmodifiable(_conversations));
  }

  void updateConversation(ChatConversation updated) {
    final idx = _conversations.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _conversations[idx] = updated;
    } else {
      _conversations.add(updated);
    }
    _sort();
    _controller.add(List.unmodifiable(_conversations));
  }

  void updateUnreadCount(String conversationId, int unreadCount) {
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final old = _conversations[idx];
      final updated = old.peer != null
          ? ChatConversation.direct(
              id: old.id,
              peer: old.peer!,
              lastMessage: old.lastMessage,
              unreadCount: unreadCount,
              updatedAt: old.updatedAt,
            )
          : ChatConversation.group(
              id: old.id,
              group: old.group!,
              lastMessage: old.lastMessage,
              unreadCount: unreadCount,
              updatedAt: old.updatedAt,
            );
      _conversations[idx] = updated;
      _controller.add(List.unmodifiable(_conversations));
    }
  }

  void removeConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    _controller.add(List.unmodifiable(_conversations));
  }

  void _sort() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void clear() {
    _conversations.clear();
    _controller.add(const []);
  }

  void dispose() {
    clear();
    _controller.close();
  }
}
