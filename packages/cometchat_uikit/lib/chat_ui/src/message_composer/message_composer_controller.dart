import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:flutter/foundation.dart';

/// Lightweight [ChangeNotifier] controller for [ConvoKitMessageComposer].
///
/// Replaces the legacy `MessageComposerBloc` with zero BLoC and zero legacy SDK dependencies. Holds only widget-local composer UI state
/// (draft text, reply target, inline audio recorder mode, typing indicator
/// debounce) and delegates all message sending and media uploads directly to
/// [MessageCoordinator] and [ConvoKit].
class MessageComposerController extends ChangeNotifier {
  MessageComposerController({
    String initialText = '',
    ChatMessage? initialReplyMessage,
    this.typingTimeout = const Duration(seconds: 3),
  }) : _text = initialText,
       _replyMessage = initialReplyMessage;

  final Duration typingTimeout;

  String _text;
  ChatMessage? _replyMessage;
  bool _isRecordingAudio = false;
  bool _isSending = false;
  bool _isTyping = false;
  ChatError? _lastError;
  Timer? _typingTimer;
  bool _disposed = false;

  String get text => _text;
  ChatMessage? get replyMessage => _replyMessage;
  bool get isRecordingAudio => _isRecordingAudio;
  bool get isSending => _isSending;
  bool get isTyping => _isTyping;
  ChatError? get lastError => _lastError;
  bool get hasText => _text.trim().isNotEmpty;

  /// Updates draft text and triggers typing signals when [kit.capabilities.typing]
  /// is enabled and [disableTypingEvents] is false.
  void updateText(
    String value, {
    ConvoKit? kit,
    String? conversationId,
    bool disableTypingEvents = false,
  }) {
    if (_text == value) return;
    _text = value;
    _safeNotify();

    if (disableTypingEvents ||
        kit == null ||
        !kit.capabilities.typing ||
        (conversationId ?? '').isEmpty) {
      return;
    }

    if (value.trim().isNotEmpty) {
      _startTyping(kit, conversationId!);
    } else {
      stopTyping(kit: kit, conversationId: conversationId);
    }
  }

  void _startTyping(ConvoKit kit, String conversationId) {
    if (!_isTyping) {
      _isTyping = true;
      unawaited(kit.messages.sendTyping(conversationId, true));
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(typingTimeout, () {
      stopTyping(kit: kit, conversationId: conversationId);
    });
  }

  /// Sends a stop-typing signal if currently typing and capabilities allow it.
  void stopTyping({ConvoKit? kit, String? conversationId}) {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (!_isTyping) return;
    _isTyping = false;
    if (kit != null &&
        kit.capabilities.typing &&
        (conversationId ?? '').isNotEmpty) {
      unawaited(kit.messages.sendTyping(conversationId!, false));
    }
  }

  void setReplyMessage(ChatMessage? message) {
    if (_replyMessage == message) return;
    _replyMessage = message;
    _safeNotify();
  }

  void clearReplyMessage() {
    if (_replyMessage == null) return;
    _replyMessage = null;
    _safeNotify();
  }

  void startAudioRecording() {
    if (_isRecordingAudio) return;
    _isRecordingAudio = true;
    _safeNotify();
  }

  void stopAudioRecording() {
    if (!_isRecordingAudio) return;
    _isRecordingAudio = false;
    _safeNotify();
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    _safeNotify();
  }

  /// Sends the current trimmed text via [MessageCoordinator.sendTextMessage].
  Future<ChatResult<ChatMessage>?> sendText({
    required ConvoKit kit,
    required MessageCoordinator coordinator,
    required String conversationId,
    String? overrideText,
  }) async {
    final trimmed = (overrideText ?? _text).trim();
    if (trimmed.isEmpty) return null;
    final sender = kit.session.currentUser;
    if (sender == null) {
      const error = ChatError(
        ChatErrorCode.unauthorized,
        'Cannot send message without a signed-in user',
      );
      _lastError = error;
      _safeNotify();
      return ChatResult.failure(error);
    }

    stopTyping(kit: kit, conversationId: conversationId);
    final repliedTo = _replyMessage;

    _isSending = true;
    _lastError = null;
    _text = '';
    _replyMessage = null;
    _safeNotify();

    final result = await coordinator.sendTextMessage(
      conversationId: conversationId,
      text: trimmed,
      sender: sender,
      repliedTo: repliedTo,
    );

    _isSending = false;
    result.fold(
      onSuccess: (_) {},
      onFailure: (error) {
        _lastError = error;
      },
    );
    _safeNotify();
    return result;
  }

  /// Sends a single local media file (e.g. from inline audio recording) via
  /// [MessageCoordinator.sendMediaMessage].
  Future<ChatResult<ChatMessage>> sendLocalMedia({
    required ConvoKit kit,
    required MessageCoordinator coordinator,
    required String conversationId,
    required String localPath,
    required AttachmentKind kind,
    String? name,
    String? mimeType,
    int? sizeBytes,
    String? caption,
  }) async {
    final sender = kit.session.currentUser;
    if (sender == null) {
      const error = ChatError(
        ChatErrorCode.unauthorized,
        'Cannot send media without a signed-in user',
      );
      _lastError = error;
      _safeNotify();
      return ChatResult.failure(error);
    }
    if (kit.media == null || !kit.capabilities.media) {
      const error = ChatError(
        ChatErrorCode.unsupported,
        'Media capability is not supported by this backend',
      );
      _lastError = error;
      _safeNotify();
      return ChatResult.failure(error);
    }

    stopTyping(kit: kit, conversationId: conversationId);
    final repliedTo = _replyMessage;
    _replyMessage = null;
    _isSending = true;
    _lastError = null;
    _safeNotify();

    final attachment = ChatAttachment(
      id: 'att_${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      localPath: localPath,
      state: AttachmentState.local,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      name: name,
    );

    final result = await coordinator.sendMediaMessage(
      conversationId: conversationId,
      attachment: attachment,
      sender: sender,
      caption: caption,
      repliedTo: repliedTo,
    );

    _isSending = false;
    result.fold(
      onSuccess: (_) {},
      onFailure: (error) {
        _lastError = error;
      },
    );
    _safeNotify();
    return result;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    _typingTimer = null;
    super.dispose();
  }
}
