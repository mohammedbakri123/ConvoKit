import 'dart:math' as math;

import 'package:convokit/convokit.dart';

import 'studio_event_source.dart';

/// In-memory [ConversationRepository] kept in sync with sent and received
/// studio messages.
class StudioConversationRepository implements ConversationRepository {
  StudioConversationRepository({
    required List<ChatConversation> initialConversations,
    required StudioEventSource eventSource,
  }) : _eventSource = eventSource {
    reset(initialConversations);
  }

  final StudioEventSource _eventSource;
  final List<ChatConversation> _conversations = <ChatConversation>[];

  /// Replaces the in-memory conversation list and sorts newest first.
  void reset(List<ChatConversation> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
    _sortByUpdatedAtDesc();
  }

  /// Syncs a conversation's [lastMessage], [updatedAt], and optional unread
  /// count increment after a message is sent or received, emitting
  /// [ConversationUpdated].
  void syncLastMessage(
    ChatMessage message, {
    required bool incrementUnread,
  }) {
    final index = _conversations.indexWhere(
      (c) => c.id == message.conversationId,
    );
    if (index == -1) return;

    final existing = _conversations[index];
    final nextUnread = incrementUnread
        ? existing.unreadCount + 1
        : existing.unreadCount;
    final updatedAt = message.serverCreatedAt ?? message.createdAt;
    final updated = _copyConversation(
      existing,
      lastMessage: message,
      unreadCount: nextUnread,
      updatedAt: updatedAt,
    );
    _conversations[index] = updated;
    _sortByUpdatedAtDesc();
    _eventSource.emitConversationUpdated(updated);
  }

  /// Syncs a conversation's [lastMessage] after a message deletion.
  void syncAfterMessageDeleted(
    String conversationId,
    ChatMessage? replacementLastMessage,
  ) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    final existing = _conversations[index];
    final updated = _copyConversation(
      existing,
      lastMessage: replacementLastMessage,
      clearLastMessage: replacementLastMessage == null,
      updatedAt:
          replacementLastMessage?.serverCreatedAt ??
          replacementLastMessage?.createdAt ??
          existing.updatedAt,
    );
    _conversations[index] = updated;
    _sortByUpdatedAtDesc();
    _eventSource.emitConversationUpdated(updated);
  }

  /// Syncs group metadata changes (e.g., member count) into any matching group
  /// conversation.
  void syncGroup(ChatGroup group) {
    final index = _conversations.indexWhere((c) => c.group?.id == group.id);
    if (index == -1) return;

    final existing = _conversations[index];
    final updated = ChatConversation.group(
      id: existing.id,
      group: group,
      lastMessage: existing.lastMessage,
      unreadCount: existing.unreadCount,
      updatedAt: existing.updatedAt,
    );
    _conversations[index] = updated;
    _eventSource.emitConversationUpdated(updated);
  }

  @override
  Future<ChatResult<ChatPage<ChatConversation>>> listConversations({
    String? cursor,
    int limit = 30,
  }) async {
    if (limit <= 0) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.validation, 'limit must be greater than 0.'),
      );
    }

    var offset = 0;
    if (cursor != null && cursor.isNotEmpty) {
      final parsed = int.tryParse(cursor);
      if (parsed == null || parsed < 0) {
        return ChatResult.failure(
          ChatError(ChatErrorCode.validation, 'Invalid cursor "$cursor".'),
        );
      }
      offset = parsed;
    }

    if (offset >= _conversations.length) {
      return const ChatResult.success(
        ChatPage<ChatConversation>(items: <ChatConversation>[]),
      );
    }

    final end = math.min(offset + limit, _conversations.length);
    final slice = List<ChatConversation>.unmodifiable(
      _conversations.sublist(offset, end),
    );
    final nextCursor = end < _conversations.length ? '$end' : null;
    return ChatResult.success(
      ChatPage<ChatConversation>(
        items: slice,
        olderCursor: nextCursor,
      ),
    );
  }

  @override
  Future<ChatResult<ChatConversation>> getConversation(String id) async {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Conversation "$id" not found.'),
      );
    }
    return ChatResult.success(_conversations[index]);
  }

  @override
  Future<ChatResult<void>> markAsRead(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.notFound,
          'Conversation "$conversationId" not found.',
        ),
      );
    }

    final existing = _conversations[index];
    if (existing.unreadCount != 0) {
      final updated = _copyConversation(existing, unreadCount: 0);
      _conversations[index] = updated;
      _eventSource.emitConversationUpdated(updated);
    }
    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> deleteConversation(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.notFound,
          'Conversation "$conversationId" not found.',
        ),
      );
    }
    _conversations.removeAt(index);
    return ChatResult.ok();
  }

  void _sortByUpdatedAtDesc() {
    _conversations.sort((a, b) {
      final cmp = b.updatedAt.compareTo(a.updatedAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
  }

  ChatConversation _copyConversation(
    ChatConversation existing, {
    ChatMessage? lastMessage,
    bool clearLastMessage = false,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    final resolvedLastMessage = clearLastMessage
        ? null
        : (lastMessage ?? existing.lastMessage);
    final resolvedUnread = unreadCount ?? existing.unreadCount;
    final resolvedUpdatedAt = updatedAt ?? existing.updatedAt;

    if (existing.peer != null) {
      return ChatConversation.direct(
        id: existing.id,
        peer: existing.peer!,
        lastMessage: resolvedLastMessage,
        unreadCount: resolvedUnread,
        updatedAt: resolvedUpdatedAt,
      );
    }
    return ChatConversation.group(
      id: existing.id,
      group: existing.group!,
      lastMessage: resolvedLastMessage,
      unreadCount: resolvedUnread,
      updatedAt: resolvedUpdatedAt,
    );
  }
}
