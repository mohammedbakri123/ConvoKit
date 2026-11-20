import 'dart:async';

import '../../contracts/pagination.dart';
import '../../contracts/result.dart';
import '../models/models.dart';

/// Per-conversation message store according to API-DESIGN.md §5.6, §6.3, §8.5.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class MessageStore {
  final String conversationId;
  final List<ChatMessage> _messages = [];
  final _controller = StreamController<List<ChatMessage>>.broadcast();

  String? olderCursor;
  String? newerCursor;
  String? newerCheckpoint;

  bool get hasOlder => olderCursor != null;
  bool get hasNewer => newerCursor != null;

  bool recoveryIncomplete = false;
  bool get hasPossibleGap => recoveryIncomplete;
  final _gapController = StreamController<bool>.broadcast();

  MessageStore(this.conversationId);

  Stream<List<ChatMessage>> get stream => _controller.stream;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Stream<bool> get gapStream => _gapController.stream;

  void addOrReconcile(ChatMessage message) {
    // 1. Check localId match
    final localIdx = _messages.indexWhere((m) => m.localId == message.localId);
    if (localIdx != -1) {
      final existing = _messages[localIdx];
      // Reconcile pending message with confirmed or retried message
      if (existing.sendState != SendState.sent &&
          message.sendState == SendState.sent) {
        _messages[localIdx] = message;
      } else if (existing.sendState == SendState.sent &&
          message.sendState == SendState.sent) {
        if (existing.id == null && message.id != null) {
          _messages[localIdx] = message;
        }
      } else {
        _messages[localIdx] = message;
      }
      _sortMessages();
      _controller.add(List.unmodifiable(_messages));
      return;
    }

    // 2. Dedupe on server id if present
    if (message.id != null) {
      final idIdx =
          _messages.indexWhere((m) => m.id != null && m.id == message.id);
      if (idIdx != -1) {
        // Already known server message — ignore duplicate
        return;
      }
    }

    // 3. New message
    _messages.add(message);
    _sortMessages();
    _controller.add(List.unmodifiable(_messages));
  }

  void mergePage(ChatPage<ChatMessage> page, MessagePageDirection direction) {
    switch (direction) {
      case MessagePageDirection.latest:
        olderCursor = page.olderCursor;
        newerCursor = page.newerCursor;
        newerCheckpoint = page.newerCheckpoint;
      case MessagePageDirection.older:
        olderCursor = page.olderCursor;
      case MessagePageDirection.newer:
        newerCursor = page.newerCursor;
        if (page.newerCheckpoint != null) {
          newerCheckpoint = page.newerCheckpoint;
        }
    }

    for (final item in page.items) {
      final localIdx = _messages.indexWhere((m) => m.localId == item.localId);
      if (localIdx != -1) {
        if (_messages[localIdx].sendState != SendState.sent &&
            item.sendState == SendState.sent) {
          _messages[localIdx] = item;
        }
        continue;
      }

      if (item.id != null) {
        final idIdx =
            _messages.indexWhere((m) => m.id != null && m.id == item.id);
        if (idIdx != -1) {
          continue;
        }
      }

      _messages.add(item);
    }

    _sortMessages();
    _controller.add(List.unmodifiable(_messages));
  }

  void applyStatusChange(
    String messageId,
    DeliveryState newDeliveryState, {
    String? currentUserId,
  }) {
    final idx = _messages.indexWhere(
      (m) => m.id == messageId || m.localId == messageId,
    );
    if (idx == -1) {
      return; // Unknown message id: ignored
    }

    final msg = _messages[idx];

    // Applies only to messages with sendState == sent
    if (msg.sendState != SendState.sent) {
      return;
    }

    // Applies only to messages WE sent
    if (currentUserId != null && msg.sender.id != currentUserId) {
      return;
    }

    // Monotonic forward-only delivery transitions: none -> delivered -> read
    if (newDeliveryState == DeliveryState.none) {
      return;
    }
    if (msg.deliveryState == DeliveryState.read) {
      return;
    }
    if (msg.deliveryState == DeliveryState.delivered &&
        newDeliveryState != DeliveryState.read) {
      return;
    }

    _messages[idx] = msg.copyWithDeliveryState(newDeliveryState);
    _controller.add(List.unmodifiable(_messages));
  }

  void removeMessage(String messageId) {
    final before = _messages.length;
    _messages.removeWhere((m) => m.id == messageId || m.localId == messageId);
    if (_messages.length != before) {
      _controller.add(List.unmodifiable(_messages));
    }
  }

  void markFailed(String localId, ChatError error) {
    final idx = _messages.indexWhere((m) => m.localId == localId);
    if (idx != -1) {
      _messages[idx] =
          _messages[idx].copyWithSendState(SendState.failed, failure: error);
      _sortMessages();
      _controller.add(List.unmodifiable(_messages));
    }
  }

  void setGapFlag(bool gap) {
    if (recoveryIncomplete != gap) {
      recoveryIncomplete = gap;
      _gapController.add(gap);
    }
  }

  void clearPending() {
    final before = _messages.length;
    _messages.removeWhere((m) => m.sendState != SendState.sent);
    if (_messages.length != before) {
      _controller.add(List.unmodifiable(_messages));
    }
  }

  void clear() {
    _messages.clear();
    olderCursor = null;
    newerCursor = null;
    newerCheckpoint = null;
    setGapFlag(false);
    _controller.add(const []);
  }

  void _sortMessages() {
    _messages.sort((a, b) {
      final aPending = a.sendState != SendState.sent;
      final bPending = b.sendState != SendState.sent;

      if (!aPending && bPending) return -1;
      if (aPending && !bPending) return 1;

      if (aPending && bPending) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        if (cmp != 0) return cmp;
        return a.localId.compareTo(b.localId);
      }

      // Both sent
      final aTime = a.serverCreatedAt ?? a.createdAt;
      final bTime = b.serverCreatedAt ?? b.createdAt;
      final timeCmp = aTime.compareTo(bTime);
      if (timeCmp != 0) return timeCmp;

      if (a.id != null && b.id != null) {
        final idCmp = a.id!.compareTo(b.id!);
        if (idCmp != 0) return idCmp;
      }
      return a.localId.compareTo(b.localId);
    });
  }

  void dispose() {
    clear();
    _controller.close();
    _gapController.close();
  }
}
