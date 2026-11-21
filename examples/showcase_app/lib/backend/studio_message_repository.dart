import 'dart:async';
import 'dart:math' as math;

import 'package:convokit/convokit.dart';

import 'studio_conversation_repository.dart';
import 'studio_event_source.dart';
import 'studio_session.dart';

/// In-memory [MessageRepository] for the offline Atelier Studio backend.
///
/// Supports directional cursor pagination via [MessagePageRequest], idempotent
/// `localId` sending with echo + delayed `delivered`/`read`
/// [MessageStatusChanged] events, message deletion, client receipt reporting,
/// typing signals, thread-reply lookup, pinned/saved collections, and in-memory
/// poll voting.
class StudioMessageRepository implements MessageRepository {
  StudioMessageRepository({
    required Map<String, List<ChatMessage>> initialMessages,
    required Map<String, List<ChatMessage>> initialPinnedMessages,
    required List<ChatMessage> initialSavedMessages,
    required StudioSession session,
    required StudioEventSource eventSource,
    required StudioConversationRepository conversationRepository,
    this.deliveredReceiptDelay = const Duration(milliseconds: 120),
    this.readReceiptDelay = const Duration(milliseconds: 300),
  }) : _session = session,
       _eventSource = eventSource,
       _conversationRepository = conversationRepository {
    reset(
      messagesByConversation: initialMessages,
      pinnedByConversation: initialPinnedMessages,
      savedMessages: initialSavedMessages,
    );
  }

  final StudioSession _session;
  final StudioEventSource _eventSource;
  final StudioConversationRepository _conversationRepository;

  /// Delay before a newly sent message transitions to [DeliveryState.delivered].
  final Duration deliveredReceiptDelay;

  /// Delay before a newly sent message transitions to [DeliveryState.read].
  final Duration readReceiptDelay;

  final Map<String, List<ChatMessage>> _messagesByConversation =
      <String, List<ChatMessage>>{};
  final Map<String, ChatMessage> _byLocalId = <String, ChatMessage>{};
  final Map<String, ChatMessage> _byServerId = <String, ChatMessage>{};
  final Map<String, List<ChatMessage>> _pinnedByConversation =
      <String, List<ChatMessage>>{};
  final List<ChatMessage> _savedMessages = <ChatMessage>[];
  final Set<Timer> _pendingTimers = <Timer>{};

  int _nextServerId = 1000;
  bool _isDisposed = false;

  /// Resets all messages, pinned messages, saved messages, and cancels any
  /// pending simulated receipt timers.
  void reset({
    required Map<String, List<ChatMessage>> messagesByConversation,
    required Map<String, List<ChatMessage>> pinnedByConversation,
    required List<ChatMessage> savedMessages,
  }) {
    _cancelPendingTimers();
    _messagesByConversation.clear();
    _byLocalId.clear();
    _byServerId.clear();
    _pinnedByConversation.clear();
    _savedMessages.clear();
    _nextServerId = 1000;

    for (final entry in messagesByConversation.entries) {
      final list = List<ChatMessage>.from(entry.value);
      _sortChronological(list);
      _messagesByConversation[entry.key] = list;
      for (final message in list) {
        _indexMessage(message);
      }
    }

    for (final entry in pinnedByConversation.entries) {
      _pinnedByConversation[entry.key] = List<ChatMessage>.from(entry.value);
    }

    _savedMessages.addAll(savedMessages);
  }

  /// Cancels all pending simulated delivery/read receipt timers.
  void dispose() {
    _isDisposed = true;
    _cancelPendingTimers();
  }

  @override
  Future<ChatResult<ChatPage<ChatMessage>>> fetchMessages(
    String conversationId,
    MessagePageRequest request,
  ) async {
    if (request.limit <= 0) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.validation, 'limit must be greater than 0.'),
      );
    }

    final list =
        _messagesByConversation[conversationId] ?? const <ChatMessage>[];
    final total = list.length;

    switch (request.direction) {
      case MessagePageDirection.latest:
        if (request.cursor != null) {
          return const ChatResult.failure(
            ChatError(
              ChatErrorCode.validation,
              'cursor must be null for MessagePageDirection.latest.',
            ),
          );
        }
        final start = math.max(0, total - request.limit);
        final items = List<ChatMessage>.unmodifiable(list.sublist(start, total));
        return ChatResult.success(
          ChatPage<ChatMessage>(
            items: items,
            olderCursor: start > 0 ? '$start' : null,
            newerCursor: null,
            newerCheckpoint: '$total',
          ),
        );

      case MessagePageDirection.older:
        final parsed = _parseCursor(request.cursor);
        if (parsed == null) {
          return ChatResult.failure(
            ChatError(
              ChatErrorCode.validation,
              'Invalid older cursor "${request.cursor}".',
            ),
          );
        }
        final end = parsed.clamp(0, total);
        final start = math.max(0, end - request.limit);
        final items = List<ChatMessage>.unmodifiable(list.sublist(start, end));
        return ChatResult.success(
          ChatPage<ChatMessage>(
            items: items,
            olderCursor: start > 0 ? '$start' : null,
            newerCursor: end < total ? '$end' : null,
          ),
        );

      case MessagePageDirection.newer:
        final parsed = _parseCursor(request.cursor);
        if (parsed == null) {
          return ChatResult.failure(
            ChatError(
              ChatErrorCode.validation,
              'Invalid newer cursor "${request.cursor}".',
            ),
          );
        }
        final start = parsed.clamp(0, total);
        final end = math.min(total, start + request.limit);
        final items = List<ChatMessage>.unmodifiable(list.sublist(start, end));
        return ChatResult.success(
          ChatPage<ChatMessage>(
            items: items,
            olderCursor: start > 0 ? '$start' : null,
            newerCursor: end < total ? '$end' : null,
            newerCheckpoint: '$end',
          ),
        );
    }
  }

  @override
  Future<ChatResult<ChatMessage>> sendMessage(ChatMessage message) async {
    if (message is TextMessage && message.text.trim().isEmpty) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.validation, 'Message text cannot be empty.'),
      );
    }

    // Idempotency by localId: return the already-persisted server message.
    final existing = _byLocalId[message.localId];
    if (existing != null) {
      return ChatResult.success(existing);
    }

    final serverId = 'msg_srv_${++_nextServerId}';
    final serverTime = DateTime.now().toUtc();
    final confirmed = message.copyWithSendState(
      SendState.sent,
      id: serverId,
      serverCreatedAt: serverTime,
    );

    final list = _messagesByConversation.putIfAbsent(
      confirmed.conversationId,
      () => <ChatMessage>[],
    );
    list.add(confirmed);
    _sortChronological(list);
    _indexMessage(confirmed);

    final isOwn = _session.currentUser?.id == confirmed.sender.id;
    _conversationRepository.syncLastMessage(
      confirmed,
      incrementUnread: !isOwn,
    );

    // Emit echo of the confirmed message.
    _eventSource.emitMessageReceived(confirmed, receivedAt: serverTime);

    // Simulate delayed delivered -> read receipts for outgoing messages.
    if (isOwn && !_isDisposed) {
      _scheduleReceiptTransition(
        conversationId: confirmed.conversationId,
        messageId: serverId,
        deliveryState: DeliveryState.delivered,
        delay: deliveredReceiptDelay,
      );
      _scheduleReceiptTransition(
        conversationId: confirmed.conversationId,
        messageId: serverId,
        deliveryState: DeliveryState.read,
        delay: readReceiptDelay,
      );
    }

    return ChatResult.success(confirmed);
  }

  @override
  Future<ChatResult<void>> deleteMessage(String messageId) async {
    final target = _findByIdOrLocalId(messageId);
    if (target == null) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Message "$messageId" not found.'),
      );
    }

    final list = _messagesByConversation[target.conversationId];
    list?.removeWhere(
      (m) =>
          (target.id != null && m.id == target.id) ||
          m.localId == target.localId,
    );
    _byLocalId.remove(target.localId);
    if (target.id != null) {
      _byServerId.remove(target.id);
    }

    _pinnedByConversation[target.conversationId]?.removeWhere(
      (m) =>
          (target.id != null && m.id == target.id) ||
          m.localId == target.localId,
    );
    _savedMessages.removeWhere(
      (m) =>
          (target.id != null && m.id == target.id) ||
          m.localId == target.localId,
    );

    final replacementLast = (list != null && list.isNotEmpty)
        ? list.last
        : null;
    _conversationRepository.syncAfterMessageDeleted(
      target.conversationId,
      replacementLast,
    );

    _eventSource.emitMessageDeleted(
      conversationId: target.conversationId,
      messageId: target.id ?? target.localId,
    );

    return ChatResult.ok();
  }

  @override
  Future<ChatResult<void>> markAsDelivered(String messageId) async {
    return _updateDeliveryState(messageId, DeliveryState.delivered);
  }

  @override
  Future<ChatResult<void>> markAsRead(String messageId) async {
    return _updateDeliveryState(messageId, DeliveryState.read);
  }

  @override
  Future<ChatResult<void>> sendTyping(
    String conversationId,
    bool isTyping,
  ) async {
    final currentUser = _session.currentUser;
    if (currentUser == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unauthorized, 'No signed-in user.'),
      );
    }
    _eventSource.emitTypingChanged(
      conversationId: conversationId,
      user: currentUser,
      isTyping: isTyping,
    );
    return ChatResult.ok();
  }

  /// Returns all thread replies in [conversationId] whose [ChatMessage.repliedTo]
  /// references [parentMessageId] (matching either server `id` or `localId`).
  List<ChatMessage> getThreadReplies(
    String conversationId,
    String parentMessageId,
  ) {
    final list =
        _messagesByConversation[conversationId] ?? const <ChatMessage>[];
    return List<ChatMessage>.unmodifiable(
      list.where((message) {
        final parent = message.repliedTo;
        if (parent == null) return false;
        return parent.id == parentMessageId ||
            parent.localId == parentMessageId;
      }),
    );
  }

  /// Returns pinned messages for [conversationId].
  List<ChatMessage> getPinnedMessages(String conversationId) {
    final list =
        _pinnedByConversation[conversationId] ?? const <ChatMessage>[];
    return List<ChatMessage>.unmodifiable(list);
  }

  /// Toggles pinned status of [message] in its conversation.
  bool togglePinMessage(ChatMessage message) {
    final list = _pinnedByConversation.putIfAbsent(
      message.conversationId,
      () => <ChatMessage>[],
    );
    final existingIdx = list.indexWhere(
      (m) =>
          (message.id != null && m.id == message.id) ||
          m.localId == message.localId,
    );
    if (existingIdx != -1) {
      list.removeAt(existingIdx);
      return false;
    }
    list.add(message);
    return true;
  }

  /// Returns all saved/bookmarked messages across conversations.
  List<ChatMessage> getSavedMessages() {
    return List<ChatMessage>.unmodifiable(_savedMessages);
  }

  /// Toggles saved/bookmarked status of [message].
  bool toggleSaveMessage(ChatMessage message) {
    final existingIdx = _savedMessages.indexWhere(
      (m) =>
          (message.id != null && m.id == message.id) ||
          m.localId == message.localId,
    );
    if (existingIdx != -1) {
      _savedMessages.removeAt(existingIdx);
      return false;
    }
    _savedMessages.add(message);
    return true;
  }

  /// Mutates a seeded or created poll [CustomMessage] in-memory when [voter]
  /// chooses [optionId], moving any prior vote by [voter] cleanly and emitting
  /// an updated [MessageReceived] event.
  ChatResult<CustomMessage> votePoll({
    required String pollMessageId,
    required String optionId,
    required ChatUser voter,
  }) {
    final target = _findByIdOrLocalId(pollMessageId);
    if (target == null || target is! CustomMessage) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.notFound,
          'Poll message "$pollMessageId" not found.',
        ),
      );
    }

    final rawOptions = target.data['options'];
    if (rawOptions is! Map) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.validation, 'Poll message has no options.'),
      );
    }

    final nextOptions = <String, dynamic>{};
    for (final entry in rawOptions.entries) {
      final key = entry.key.toString();
      final optMap = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      final rawVoters = optMap['voters'];
      final votersMap = rawVoters is Map
          ? Map<String, dynamic>.from(rawVoters)
          : <String, dynamic>{};
      votersMap.remove(voter.id);
      optMap['voters'] = votersMap;
      optMap['count'] = votersMap.length;
      nextOptions[key] = optMap;
    }

    if (!nextOptions.containsKey(optionId)) {
      return ChatResult.failure(
        ChatError(
          ChatErrorCode.validation,
          'Poll option "$optionId" does not exist.',
        ),
      );
    }

    final chosenOption = nextOptions[optionId] as Map<String, dynamic>;
    final chosenVoters = chosenOption['voters'] as Map<String, dynamic>;
    chosenVoters[voter.id] = <String, dynamic>{
      'name': voter.name,
      'avatar': voter.avatarUrl,
    };
    chosenOption['count'] = chosenVoters.length;

    var totalVotes = 0;
    for (final value in nextOptions.values) {
      final optMap = value as Map<String, dynamic>;
      totalVotes += optMap['count'] as int;
    }

    final nextData = Map<String, dynamic>.from(target.data)
      ..['options'] = nextOptions
      ..['total'] = totalVotes;

    final updated = CustomMessage(
      id: target.id,
      localId: target.localId,
      conversationId: target.conversationId,
      sender: target.sender,
      createdAt: target.createdAt,
      serverCreatedAt: target.serverCreatedAt,
      sendState: target.sendState,
      deliveryState: target.deliveryState,
      failure: target.failure,
      repliedTo: target.repliedTo,
      kind: target.kind,
      data: nextData,
    );

    _replaceStoredMessage(updated);
    _eventSource.emitMessageReceived(updated);
    return ChatResult.success(updated);
  }

  /// Injects a simulated incoming message from another teammate (useful for
  /// tests and offline demos).
  ChatMessage simulateIncomingMessage(ChatMessage message) {
    final serverId = message.id ?? 'msg_srv_${++_nextServerId}';
    final serverTime = message.serverCreatedAt ?? DateTime.now().toUtc();
    final confirmed = message.copyWithSendState(
      SendState.sent,
      id: serverId,
      serverCreatedAt: serverTime,
    );

    final list = _messagesByConversation.putIfAbsent(
      confirmed.conversationId,
      () => <ChatMessage>[],
    );
    list.add(confirmed);
    _sortChronological(list);
    _indexMessage(confirmed);

    final isOwn = _session.currentUser?.id == confirmed.sender.id;
    _conversationRepository.syncLastMessage(
      confirmed,
      incrementUnread: !isOwn,
    );
    _eventSource.emitMessageReceived(confirmed, receivedAt: serverTime);
    return confirmed;
  }

  ChatResult<void> _updateDeliveryState(
    String messageId,
    DeliveryState nextState,
  ) {
    final target = _findByIdOrLocalId(messageId);
    if (target == null) {
      return ChatResult.failure(
        ChatError(ChatErrorCode.notFound, 'Message "$messageId" not found.'),
      );
    }

    if (!_shouldAdvanceDeliveryState(target.deliveryState, nextState)) {
      return ChatResult.ok();
    }

    final updated = target.copyWithDeliveryState(nextState);
    _replaceStoredMessage(updated);
    return ChatResult.ok();
  }

  void _scheduleReceiptTransition({
    required String conversationId,
    required String messageId,
    required DeliveryState deliveryState,
    required Duration delay,
  }) {
    late final Timer timer;
    timer = Timer(delay, () {
      _pendingTimers.remove(timer);
      if (_isDisposed) return;

      final current = _findByIdOrLocalId(messageId);
      if (current == null) return;
      if (!_shouldAdvanceDeliveryState(current.deliveryState, deliveryState)) {
        return;
      }

      final updated = current.copyWithDeliveryState(deliveryState);
      _replaceStoredMessage(updated);
      _eventSource.emitMessageStatusChanged(
        conversationId: conversationId,
        messageId: messageId,
        deliveryState: deliveryState,
      );
    });
    _pendingTimers.add(timer);
  }

  bool _shouldAdvanceDeliveryState(DeliveryState current, DeliveryState next) {
    if (next == DeliveryState.none) return false;
    if (current == DeliveryState.read) return false;
    if (current == DeliveryState.delivered && next != DeliveryState.read) {
      return false;
    }
    return true;
  }

  ChatMessage? _findByIdOrLocalId(String id) {
    return _byServerId[id] ?? _byLocalId[id];
  }

  void _indexMessage(ChatMessage message) {
    _byLocalId[message.localId] = message;
    if (message.id != null) {
      _byServerId[message.id!] = message;
    }
  }

  void _replaceStoredMessage(ChatMessage updated) {
    final list = _messagesByConversation[updated.conversationId];
    if (list != null) {
      final index = list.indexWhere(
        (m) =>
            (updated.id != null && m.id == updated.id) ||
            m.localId == updated.localId,
      );
      if (index != -1) {
        list[index] = updated;
      }
    }
    _indexMessage(updated);
  }

  void _cancelPendingTimers() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();
  }

  int? _parseCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty) return null;
    final parsed = int.tryParse(cursor);
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  void _sortChronological(List<ChatMessage> list) {
    list.sort((a, b) {
      final aTime = a.serverCreatedAt ?? a.createdAt;
      final bTime = b.serverCreatedAt ?? b.createdAt;
      final cmp = aTime.compareTo(bTime);
      if (cmp != 0) return cmp;
      if (a.id != null && b.id != null) {
        final idCmp = a.id!.compareTo(b.id!);
        if (idCmp != 0) return idCmp;
      }
      return a.localId.compareTo(b.localId);
    });
  }
}
