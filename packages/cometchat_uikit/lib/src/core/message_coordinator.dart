import 'dart:async';
import 'dart:typed_data';

import '../contracts/contracts.dart';
import 'convo_kit.dart';
import 'models/models.dart';
import 'stores/message_store.dart';

/// Coordinates message sending, optimistic updates, retries, reconciliation,
/// and pagination for ConvoKit according to API-DESIGN.md §5, §6, §7.
///
/// Plain Dart — no Flutter widgets, no flutter_bloc.
class MessageCoordinator {
  final ConvoKit kit;
  final Map<String, MessageStore> _stores = {};
  Map<String, MessageStore> get stores => Map.unmodifiable(_stores);
  final Map<String, CancellationToken> _activeUploads = {};
  int _sequence = 0;

  MessageCoordinator(this.kit);

  MessageStore getStore(String conversationId) {
    return _stores.putIfAbsent(
      conversationId,
      () => MessageStore(conversationId),
    );
  }

  String generateLocalId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final seq = ++_sequence;
    return 'local_${now}_$seq';
  }

  /// Optimistic text message send according to §6.2.
  Future<ChatResult<ChatMessage>> sendTextMessage({
    required String conversationId,
    required String text,
    required ChatUser sender,
    ChatMessage? repliedTo,
    String? localId,
  }) async {
    final effectiveLocalId = localId ?? generateLocalId();
    final store = getStore(conversationId);

    final pending = TextMessage(
      localId: effectiveLocalId,
      conversationId: conversationId,
      sender: sender,
      createdAt: DateTime.now(),
      sendState: SendState.sending,
      deliveryState: DeliveryState.none,
      repliedTo: repliedTo,
      text: text,
    );

    // 1. Appears instantly in UI as sending
    store.addOrReconcile(pending);

    // 2. Call repository
    try {
      final result = await kit.messages.sendMessage(pending);
      return result.fold(
        onSuccess: (confirmed) {
          // 4. Success -> reconcile
          store.addOrReconcile(confirmed);
          return ChatResult.success(confirmed);
        },
        onFailure: (error) {
          // 5. Failure (including outcomeUnknown) -> mark failed with error
          final failedMsg = pending.copyWithSendState(
            SendState.failed,
            failure: error,
          );
          store.addOrReconcile(failedMsg);
          return ChatResult.failure(error);
        },
      );
    } catch (e) {
      final error = ChatError(ChatErrorCode.network, e.toString());
      final failedMsg = pending.copyWithSendState(
        SendState.failed,
        failure: error,
      );
      store.addOrReconcile(failedMsg);
      return ChatResult.failure(error);
    }
  }

  /// Optimistic media message send according to §6.2, §6.5, §7.
  Future<ChatResult<ChatMessage>> sendMediaMessage({
    required String conversationId,
    required ChatAttachment attachment,
    required ChatUser sender,
    String? caption,
    ChatMessage? repliedTo,
    String? localId,
  }) async {
    final effectiveLocalId = localId ?? generateLocalId();
    final store = getStore(conversationId);

    ChatAttachment currentAttachment = attachment;

    var pending = MediaMessage(
      localId: effectiveLocalId,
      conversationId: conversationId,
      sender: sender,
      createdAt: DateTime.now(),
      sendState: SendState.sending,
      deliveryState: DeliveryState.none,
      repliedTo: repliedTo,
      attachment: currentAttachment,
      caption: caption,
    );

    // 1. Appears instantly
    store.addOrReconcile(pending);

    // 2. Upload if needed
    if (currentAttachment.state != AttachmentState.uploaded) {
      final mediaProvider = kit.media;
      if (mediaProvider == null) {
        final error = const ChatError(
          ChatErrorCode.unsupported,
          'Media capability not supported',
        );
        final failed = pending.copyWithSendState(
          SendState.failed,
          failure: error,
        );
        store.addOrReconcile(failed);
        return ChatResult.failure(error);
      }

      final cancelToken = CancellationToken();
      _activeUploads[effectiveLocalId] = cancelToken;

      final uploadReq = currentAttachment.localPath != null
          ? UploadRequest.file(
              currentAttachment.localPath!,
              kind: currentAttachment.kind,
              mimeType: currentAttachment.mimeType,
              name: currentAttachment.name,
            )
          : UploadRequest.bytes(
              // In case bytes were provided
              Uint8List(0),
              kind: currentAttachment.kind,
              mimeType: currentAttachment.mimeType,
              name: currentAttachment.name,
            );

      final uploadResult = await mediaProvider.upload(
        uploadReq,
        cancel: cancelToken,
      );

      _activeUploads.remove(effectiveLocalId);

      if (uploadResult.isFailure) {
        final uploadError = (uploadResult as ChatFailure<UploadedMedia>).error;

        // Cancelled upload -> delete pending message entirely (§2.2, §6.5)
        if (uploadError.code == ChatErrorCode.cancelled) {
          store.removeMessage(effectiveLocalId);
          return ChatResult.failure(uploadError);
        }

        // Upload failed -> attachment state failed, message sendState failed
        final failedAttachment = ChatAttachment(
          id: currentAttachment.id,
          kind: currentAttachment.kind,
          localPath: currentAttachment.localPath,
          state: AttachmentState.failed,
          uploadFailure: uploadError,
          mimeType: currentAttachment.mimeType,
          sizeBytes: currentAttachment.sizeBytes,
          name: currentAttachment.name,
        );

        final failedMsg = MediaMessage(
          localId: effectiveLocalId,
          conversationId: conversationId,
          sender: sender,
          createdAt: pending.createdAt,
          sendState: SendState.failed,
          deliveryState: DeliveryState.none,
          repliedTo: repliedTo,
          attachment: failedAttachment,
          caption: caption,
          failure: uploadError,
        );

        store.addOrReconcile(failedMsg);
        return ChatResult.failure(uploadError);
      }

      final uploaded = (uploadResult as ChatSuccess<UploadedMedia>).value;
      currentAttachment = ChatAttachment(
        id: currentAttachment.id,
        remoteId: uploaded.id,
        kind: currentAttachment.kind,
        localPath: currentAttachment.localPath,
        url: uploaded.url,
        thumbnailUrl: uploaded.thumbnailUrl,
        state: AttachmentState.uploaded,
        mimeType: uploaded.mimeType ?? currentAttachment.mimeType,
        sizeBytes: uploaded.sizeBytes ?? currentAttachment.sizeBytes,
        name: uploaded.name ?? currentAttachment.name,
      );

      pending = MediaMessage(
        localId: effectiveLocalId,
        conversationId: conversationId,
        sender: sender,
        createdAt: pending.createdAt,
        sendState: SendState.sending,
        deliveryState: DeliveryState.none,
        repliedTo: repliedTo,
        attachment: currentAttachment,
        caption: caption,
      );
      store.addOrReconcile(pending);
    }

    // 3. Send message
    try {
      final sendResult = await kit.messages.sendMessage(pending);
      return sendResult.fold(
        onSuccess: (confirmed) {
          store.addOrReconcile(confirmed);
          return ChatResult.success(confirmed);
        },
        onFailure: (error) {
          final failedMsg = MediaMessage(
            localId: effectiveLocalId,
            conversationId: conversationId,
            sender: sender,
            createdAt: pending.createdAt,
            sendState: SendState.failed,
            deliveryState: DeliveryState.none,
            repliedTo: repliedTo,
            attachment: currentAttachment,
            caption: caption,
            failure: error,
          );
          store.addOrReconcile(failedMsg);
          return ChatResult.failure(error);
        },
      );
    } catch (e) {
      final error = ChatError(ChatErrorCode.network, e.toString());
      final failedMsg = MediaMessage(
        localId: effectiveLocalId,
        conversationId: conversationId,
        sender: sender,
        createdAt: pending.createdAt,
        sendState: SendState.failed,
        deliveryState: DeliveryState.none,
        repliedTo: repliedTo,
        attachment: currentAttachment,
        caption: caption,
        failure: error,
      );
      store.addOrReconcile(failedMsg);
      return ChatResult.failure(error);
    }
  }

  /// Retries a failed message with the SAME stored pending message object (same localId).
  Future<ChatResult<ChatMessage>> retryFailed(
    String localId, {
    required String conversationId,
  }) async {
    final store = getStore(conversationId);
    final msgIdx = store.messages.indexWhere((m) => m.localId == localId);
    if (msgIdx == -1) {
      return ChatResult.failure(
        const ChatError(ChatErrorCode.notFound, 'Message not found for retry'),
      );
    }

    final failedMsg = store.messages[msgIdx];
    if (failedMsg.sendState != SendState.failed) {
      return ChatResult.success(failedMsg);
    }

    if (failedMsg is MediaMessage) {
      // If upload failed, re-upload then send; if upload succeeded, send only (§6.5)
      return sendMediaMessage(
        conversationId: conversationId,
        attachment: failedMsg.attachment,
        sender: failedMsg.sender,
        caption: failedMsg.caption,
        repliedTo: failedMsg.repliedTo,
        localId: failedMsg.localId,
      );
    } else if (failedMsg is TextMessage) {
      return sendTextMessage(
        conversationId: conversationId,
        text: failedMsg.text,
        sender: failedMsg.sender,
        repliedTo: failedMsg.repliedTo,
        localId: failedMsg.localId,
      );
    }

    return ChatResult.failure(
      const ChatError(ChatErrorCode.unsupported, 'Unsupported message type for retry'),
    );
  }

  void cancelUpload(String localId) {
    _activeUploads[localId]?.cancel();
  }

  void cancelAllUploads() {
    for (final token in _activeUploads.values) {
      token.cancel();
    }
    _activeUploads.clear();
  }

  void discardAllPending() {
    cancelAllUploads();
    for (final store in _stores.values) {
      store.clearPending();
    }
  }

  /// Directional pagination for older history (§5.2).
  Future<ChatResult<ChatPage<ChatMessage>>> fetchOlder(
    String conversationId, {
    int limit = 30,
  }) async {
    final store = getStore(conversationId);
    final req = MessagePageRequest(
      direction: MessagePageDirection.older,
      cursor: store.olderCursor,
      limit: limit,
    );

    final result = await kit.messages.fetchMessages(conversationId, req);
    if (result.isSuccess) {
      final page = (result as ChatSuccess<ChatPage<ChatMessage>>).value;
      store.mergePage(page, MessagePageDirection.older);
    }
    return result;
  }

  /// Initial or latest page fetch (§5.2).
  Future<ChatResult<ChatPage<ChatMessage>>> fetchLatest(
    String conversationId, {
    int limit = 30,
  }) async {
    final store = getStore(conversationId);
    final req = MessagePageRequest(
      direction: MessagePageDirection.latest,
      cursor: null,
      limit: limit,
    );

    final result = await kit.messages.fetchMessages(conversationId, req);
    if (result.isSuccess) {
      final page = (result as ChatSuccess<ChatPage<ChatMessage>>).value;
      store.mergePage(page, MessagePageDirection.latest);
    }
    return result;
  }

  /// Refreshes a conversation: if catch-up gap banner was shown, re-runs catch-up
  /// with fresh 10-page budget from stored checkpoint; otherwise fetches latest.
  Future<ChatResult<void>> refresh(String conversationId) async {
    final store = getStore(conversationId);

    if (store.hasPossibleGap &&
        kit.capabilities.messageCatchUp &&
        store.newerCheckpoint != null) {
      // Re-run catch up from stored checkpoint with fresh 10-page budget (§5.5)
      var currentCursor = store.newerCheckpoint;
      var pagesFetched = 0;
      var hasMoreNewer = true;

      while (pagesFetched < 10 && hasMoreNewer) {
        final req = MessagePageRequest(
          direction: MessagePageDirection.newer,
          cursor: currentCursor,
        );
        final pageRes = await kit.messages.fetchMessages(conversationId, req);
        if (pageRes.isFailure) {
          return ChatResult.failure(
            (pageRes as ChatFailure<ChatPage<ChatMessage>>).error,
          );
        }

        final page = (pageRes as ChatSuccess<ChatPage<ChatMessage>>).value;
        store.mergePage(page, MessagePageDirection.newer);
        pagesFetched++;
        currentCursor = page.newerCursor;
        hasMoreNewer = page.hasNewer;
      }

      if (!hasMoreNewer) {
        // Recovery complete! Gap banner clears.
        store.setGapFlag(false);
      } else {
        store.setGapFlag(true);
      }
      return ChatResult.ok();
    } else {
      final res = await fetchLatest(conversationId);
      return res.fold(
        onSuccess: (_) => ChatResult.ok(),
        onFailure: (err) => ChatResult.failure(err),
      );
    }
  }

  void clearAll() {
    cancelAllUploads();
    for (final store in _stores.values) {
      store.clear();
    }
    _stores.clear();
  }
}
