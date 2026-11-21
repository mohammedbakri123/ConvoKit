import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Types of operations that can be performed on the animated message list.
enum MessageOperationType {
  insert,
  insertAll,
  update,
  remove,
  set,
}

/// Represents an operation to be performed on the animated message list.
class MessageOperation {
  final MessageOperationType type;
  final ChatMessage? message;
  final ChatMessage? oldMessage;
  final List<ChatMessage>? messages;
  final List<ChatMessage>? oldMessages;
  final int? index;
  final bool animated;

  MessageOperation._({
    required this.type,
    this.message,
    this.oldMessage,
    this.messages,
    this.oldMessages,
    this.index,
    this.animated = true,
  });

  factory MessageOperation.insert(
    ChatMessage message,
    int index, {
    bool animated = true,
  }) {
    return MessageOperation._(
      type: MessageOperationType.insert,
      message: message,
      index: index,
      animated: animated,
    );
  }

  factory MessageOperation.insertAll(
    List<ChatMessage> messages,
    int index, {
    bool animated = true,
  }) {
    return MessageOperation._(
      type: MessageOperationType.insertAll,
      messages: messages,
      index: index,
      animated: animated,
    );
  }

  factory MessageOperation.update(
    ChatMessage oldMessage,
    ChatMessage newMessage,
    int index,
  ) {
    return MessageOperation._(
      type: MessageOperationType.update,
      oldMessage: oldMessage,
      message: newMessage,
      index: index,
    );
  }

  factory MessageOperation.remove(
    ChatMessage message,
    int index, {
    bool animated = true,
  }) {
    return MessageOperation._(
      type: MessageOperationType.remove,
      message: message,
      index: index,
      animated: animated,
    );
  }

  factory MessageOperation.set(
    List<ChatMessage> oldMessages,
    List<ChatMessage> newMessages, {
    bool animated = true,
  }) {
    return MessageOperation._(
      type: MessageOperationType.set,
      oldMessages: oldMessages,
      messages: newMessages,
      animated: animated,
    );
  }
}

/// Lightweight immutable state snapshot for [AnimatedMessageListBloc].
class AnimatedMessageListState {
  final List<ChatMessage> messages;

  const AnimatedMessageListState({this.messages = const []});
}

/// Pure-Dart / ChangeNotifier controller replacing the legacy BLoC for
/// [ConvoKitAnimatedMessageList] (zero `flutter_bloc`, zero SDK).
class AnimatedMessageListBloc extends ChangeNotifier {
  AnimatedMessageListState _state = const AnimatedMessageListState();
  final _operationsController = StreamController<MessageOperation>.broadcast();

  Future<bool> Function(
    String messageId, {
    Duration duration,
    double alignment,
  })? _scrollToMessageFn;
  Future<bool> Function(
    int index, {
    Duration duration,
    double alignment,
  })? _scrollToIndexFn;
  VoidCallback? _scrollToBottomFn;

  AnimatedMessageListState get state => _state;
  Stream<MessageOperation> get operationsStream => _operationsController.stream;

  void setMessages(List<ChatMessage> newMessages, {bool animated = true}) {
    final oldMessages = _state.messages;
    _state = AnimatedMessageListState(
      messages: List<ChatMessage>.unmodifiable(newMessages),
    );
    if (!_operationsController.isClosed) {
      _operationsController.add(
        MessageOperation.set(oldMessages, newMessages, animated: animated),
      );
    }
    notifyListeners();
  }

  void insertMessage(ChatMessage message, int index, {bool animated = true}) {
    final list = List<ChatMessage>.from(_state.messages);
    final safeIndex = index.clamp(0, list.length);
    list.insert(safeIndex, message);
    _state = AnimatedMessageListState(messages: List<ChatMessage>.unmodifiable(list));
    if (!_operationsController.isClosed) {
      _operationsController.add(
        MessageOperation.insert(message, safeIndex, animated: animated),
      );
    }
    notifyListeners();
  }

  void insertAllMessages(
    List<ChatMessage> messages,
    int index, {
    bool animated = true,
  }) {
    final list = List<ChatMessage>.from(_state.messages);
    final safeIndex = index.clamp(0, list.length);
    list.insertAll(safeIndex, messages);
    _state = AnimatedMessageListState(messages: List<ChatMessage>.unmodifiable(list));
    if (!_operationsController.isClosed) {
      _operationsController.add(
        MessageOperation.insertAll(messages, safeIndex, animated: animated),
      );
    }
    notifyListeners();
  }

  void removeMessage(int index, {bool animated = true}) {
    final list = List<ChatMessage>.from(_state.messages);
    if (index < 0 || index >= list.length) return;
    final removed = list.removeAt(index);
    _state = AnimatedMessageListState(messages: List<ChatMessage>.unmodifiable(list));
    if (!_operationsController.isClosed) {
      _operationsController.add(
        MessageOperation.remove(removed, index, animated: animated),
      );
    }
    notifyListeners();
  }

  void updateMessage(ChatMessage message, int index) {
    final list = List<ChatMessage>.from(_state.messages);
    if (index < 0 || index >= list.length) return;
    final old = list[index];
    list[index] = message;
    _state = AnimatedMessageListState(messages: List<ChatMessage>.unmodifiable(list));
    if (!_operationsController.isClosed) {
      _operationsController.add(
        MessageOperation.update(old, message, index),
      );
    }
    notifyListeners();
  }

  int? findMessageIndex(String messageId) {
    final idx = _state.messages.indexWhere(
      (m) => m.id == messageId || m.localId == messageId,
    );
    return idx == -1 ? null : idx;
  }

  Future<void> close() async {
    dispose();
  }

  void attachScrollMethods({
    Future<bool> Function(
      String messageId, {
      Duration duration,
      double alignment,
    })? scrollToMessage,
    Future<bool> Function(
      int index, {
      Duration duration,
      double alignment,
    })? scrollToIndex,
    VoidCallback? scrollToBottom,
  }) {
    _scrollToMessageFn = scrollToMessage;
    _scrollToIndexFn = scrollToIndex;
    _scrollToBottomFn = scrollToBottom;
  }

  void detachScrollMethods() {
    _scrollToMessageFn = null;
    _scrollToIndexFn = null;
    _scrollToBottomFn = null;
  }

  Future<bool> scrollToMessage(
    String messageId, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    double alignment = 0.0,
  }) async {
    return await _scrollToMessageFn?.call(
          messageId,
          duration: duration,
          alignment: alignment,
        ) ??
        false;
  }

  Future<bool> scrollToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    double alignment = 0.0,
  }) async {
    return await _scrollToIndexFn?.call(
          index,
          duration: duration,
          alignment: alignment,
        ) ??
        false;
  }

  void scrollToBottom() {
    _scrollToBottomFn?.call();
  }

  @override
  void dispose() {
    detachScrollMethods();
    _operationsController.close();
    super.dispose();
  }
}
