import 'dart:async';
import 'package:convokit/convokit.dart' as ck;
import 'package:cometchat_sdk/cometchat_sdk.dart' hide CardMessage;

import '../../../../../shared_ui/src/cometchat_ui_kit/cometchat_ui_kit.dart';
import '../../../../../src/adapters/cometchat_conversation_adapter.dart';
import '../../../../../src/adapters/cometchat_message_adapter.dart';
import '../../../../../src/adapters/cometchat_sdk_adapter.dart';

/// Exception thrown when remote data source operations fail.
class MessageListRemoteDataSourceException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  const MessageListRemoteDataSourceException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() =>
      'MessageListRemoteDataSourceException(message: $message, code: $code)';
}

/// Result class containing both the MessagesRequest and fetched messages.
class GetMessagesResult {
  final MessagesRequest request;
  final List<BaseMessage> messages;

  const GetMessagesResult({required this.request, required this.messages});
}

/// Abstract interface for message list remote data source.
abstract class MessageListRemoteDataSource {
  Future<GetMessagesResult> getMessages({
    required String conversationWith,
    required String conversationType,
    int limit = 30,
    int? parentMessageId,
    List<String>? types,
    List<String>? categories,
    bool hideReplies = true,
    bool withParent = true,
  });

  Future<List<BaseMessage>> fetchPreviousMessages({
    required MessagesRequest request,
  });

  Future<List<BaseMessage>> fetchNextMessages({
    required MessagesRequest request,
  });

  Future<void> markAsRead(BaseMessage message);
  Future<void> markAsDelivered(BaseMessage message);
  Future<User?> getLoggedInUser();

  Future<Conversation> getConversation({
    required String conversationWith,
    required String conversationType,
  });

  Future<Conversation> markMessageAsUnread(BaseMessage message);
}

/// Implementation of [MessageListRemoteDataSource] using ConvoKit contracts with SDK fallback.
class MessageListRemoteDataSourceImpl implements MessageListRemoteDataSource {
  final ck.MessageRepository? _repository;

  MessageListRemoteDataSourceImpl({ck.MessageRepository? repository})
      : _repository = repository;

  ck.MessageRepository? get _convoKitRepository =>
      _repository ??
      CometChatUIKit.messageRepository ??
      CometChatUIKit.kit?.messages;

  static final CometChatMessageAdapter _messageAdapter =
      CometChatMessageAdapter();

  @override
  Future<GetMessagesResult> getMessages({
    required String conversationWith,
    required String conversationType,
    int limit = 30,
    int? parentMessageId,
    List<String>? types,
    List<String>? categories,
    bool hideReplies = true,
    bool withParent = true,
  }) async {
    try {
      final requestBuilder = MessagesRequestBuilder()..limit = limit;

      if (conversationType == 'user') {
        requestBuilder.uid = conversationWith;
      } else {
        requestBuilder.guid = conversationWith;
      }

      if (parentMessageId != null) {
        requestBuilder.parentMessageId = parentMessageId;
        requestBuilder.withParent = withParent;
      }

      if (types != null && types.isNotEmpty) {
        requestBuilder.types = types;
      }

      if (categories != null && categories.isNotEmpty) {
        requestBuilder.categories = categories;
      }

      requestBuilder.hideReplies = hideReplies;

      final request = requestBuilder.build();

      if (_convoKitRepository != null) {
        final convId = conversationType == 'group'
            ? 'group_$conversationWith'
            : conversationWith;
        final res = await _convoKitRepository!.fetchMessages(
          convId,
          ck.MessagePageRequest(
            limit: limit,
            direction: ck.MessagePageDirection.older,
          ),
        );
        final messages = res.fold(
          onFailure: (err) => <BaseMessage>[],
          onSuccess: (page) =>
              page.items.map(CometChatMessageAdapter.toSdkMessage).toList(),
        );
        return GetMessagesResult(request: request, messages: messages);
      }

      final messages = await _fetchPrevious(request);

      return GetMessagesResult(request: request, messages: messages);
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch messages',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message: 'Unexpected error while fetching messages: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<List<BaseMessage>> fetchPreviousMessages({
    required MessagesRequest request,
  }) async {
    try {
      if (_convoKitRepository != null) {
        final isGroup = request.guid != null && request.guid!.isNotEmpty;
        final convId =
            isGroup ? 'group_${request.guid}' : (request.uid ?? '');
        final res = await _convoKitRepository!.fetchMessages(
          convId,
          ck.MessagePageRequest(
            limit: request.limit ?? 30,
            cursor: (request.messageId != null && request.messageId! > 0)
                ? request.messageId.toString()
                : null,
            direction: ck.MessagePageDirection.older,
          ),
        );
        final messages = res.fold(
          onFailure: (err) => <BaseMessage>[],
          onSuccess: (page) =>
              page.items.map(CometChatMessageAdapter.toSdkMessage).toList(),
        );
        return messages;
      }
      final prev = await _fetchPrevious(request);
      return prev;
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch previous messages',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while fetching previous messages: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<List<BaseMessage>> fetchNextMessages({
    required MessagesRequest request,
  }) async {
    try {
      if (_convoKitRepository != null) {
        final isGroup = request.guid != null && request.guid!.isNotEmpty;
        final convId =
            isGroup ? 'group_${request.guid}' : (request.uid ?? '');
        final res = await _convoKitRepository!.fetchMessages(
          convId,
          ck.MessagePageRequest(
            limit: request.limit ?? 30,
            cursor: (request.messageId != null && request.messageId! > 0)
                ? request.messageId.toString()
                : null,
            direction: ck.MessagePageDirection.newer,
          ),
        );
        final messages = res.fold(
          onFailure: (err) => <BaseMessage>[],
          onSuccess: (page) =>
              page.items.map(CometChatMessageAdapter.toSdkMessage).toList(),
        );
        return messages;
      }
      final next = await _fetchNext(request);
      return next;
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to fetch next messages',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while fetching next messages: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> markAsRead(BaseMessage message) async {
    try {
      if (_convoKitRepository != null) {
        final res =
            await _convoKitRepository!.markAsRead(message.id.toString());
        res.fold(
          onFailure: (err) => throw MessageListRemoteDataSourceException(
            message: err.message,
            code: err.code.name,
          ),
          onSuccess: (_) {},
        );
        return;
      }
      return await _messageAdapter.markSdkAsRead(message);
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to mark message as read',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while marking message as read: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<void> markAsDelivered(BaseMessage message) async {
    try {
      if (_convoKitRepository != null) {
        final res =
            await _convoKitRepository!.markAsDelivered(message.id.toString());
        res.fold(
          onFailure: (err) => throw MessageListRemoteDataSourceException(
            message: err.message,
            code: err.code.name,
          ),
          onSuccess: (_) {},
        );
        return;
      }
      return await _messageAdapter.markSdkAsDelivered(message);
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to mark message as delivered',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while marking message as delivered: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<User?> getLoggedInUser() async {
    try {
      final session = CometChatUIKit.session ?? CometChatUIKit.kit?.session;
      if (session != null) {
        final u = session.currentUser;
        if (u != null) {
          return User(
            uid: u.id,
            name: u.name,
            avatar: u.avatarUrl,
          );
        }
      }
      return await CometChatSdkAdapter.getLoggedInUser();
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to get logged in user',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while getting logged in user: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<Conversation> getConversation({
    required String conversationWith,
    required String conversationType,
  }) async {
    try {
      final convRepo =
          CometChatUIKit.conversationRepository ??
          CometChatUIKit.kit?.conversations;
      if (convRepo != null) {
        final convId = conversationType == 'group'
            ? 'group_$conversationWith'
            : conversationWith;
        final res = await convRepo.getConversation(convId);
        final sdkConv = res.fold(
          onFailure: (err) => null,
          onSuccess: (c) => CometChatConversationAdapter.toSdkConversation(c),
        );
        if (sdkConv != null) return sdkConv;
      }
      final completer = Completer<Conversation>();
      await CometChatSdkAdapter.getConversation(
        conversationWith,
        conversationType,
        onSuccess: (Conversation conversation) {
          if (!completer.isCompleted) completer.complete(conversation);
        },
        onError: (CometChatException exception) {
          if (!completer.isCompleted) {
            completer.completeError(
              MessageListRemoteDataSourceException(
                message: exception.message ?? 'Failed to get conversation',
                code: exception.code,
                originalException: exception,
              ),
            );
          }
        },
      );
      return await completer.future;
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to get conversation',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message: 'Unexpected error while getting conversation: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  @override
  Future<Conversation> markMessageAsUnread(BaseMessage message) async {
    try {
      return await _messageAdapter.markSdkMessageAsUnread(message);
    } on CometChatException catch (e) {
      throw MessageListRemoteDataSourceException(
        message: e.message ?? 'Failed to mark message as unread',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      if (e is MessageListRemoteDataSourceException) rethrow;
      throw MessageListRemoteDataSourceException(
        message:
            'Unexpected error while marking message as unread: ${e.toString()}',
        originalException: e is Exception ? e : null,
      );
    }
  }

  Future<List<BaseMessage>> _fetchPrevious(MessagesRequest request) async {
    return _messageAdapter.fetchSdkPrevious(request);
  }

  Future<List<BaseMessage>> _fetchNext(MessagesRequest request) async {
    return _messageAdapter.fetchSdkNext(request);
  }
}
