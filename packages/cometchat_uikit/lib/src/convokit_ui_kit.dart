/// Pure ConvoKit facade replacing the legacy CometChat SDK-backed UIKit facade.
///
/// Built entirely on ConvoKit Core ([ConvoKit], [EventHub], [MessageCoordinator],
/// [ConvoKitScope]) with zero CometChat SDK imports.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../shared_ui/src/cometchat_ui_kit/ui_kit_settings.dart';
import '../shared_ui/src/resources/sound_manager.dart';
import '../shared_ui/src/utils/timezone_utils/data/latest.dart';
import 'contracts/contracts.dart';
import 'core/convo_kit.dart';
import 'core/event_hub.dart';
import 'core/message_coordinator.dart';
import 'core/models/models.dart';

/// Facade for initializing and interacting with ConvoKit Core.
///
/// Supports both instance construction (`ConvoKitUIKit(appId: ..., region: ..., ...)`)
/// and static accessors (`ConvoKitUIKit.init(...)`, `ConvoKitUIKit.currentUser`, etc.)
/// backed by [ConvoKit] and [ConvoKitScope].
class ConvoKitUIKit {
  final String? appId;
  final String? region;
  final String? apiKey;
  final String? authKey;
  final bool autoLogin;

  ConvoKitUIKit({
    this.appId,
    this.region,
    this.apiKey,
    this.authKey,
    this.autoLogin = false,
    ConvoKit? kit,
  }) {
    if (kit != null) {
      ConvoKitUIKit.kit = kit;
    }
  }

  /// Active UIKit settings (used by date/time formatters and feature gates).
  static UIKitSettings? authenticationSettings;

  /// Host-supplied [ConvoKit] composition root and optional overrides.
  static ConvoKit? kit;
  static EventHub? _eventHub;
  static ChatSession? session;
  static ConversationRepository? conversationRepository;
  static UserRepository? userRepository;
  static GroupRepository? groupRepository;
  static MessageRepository? messageRepository;
  static ChatMediaProvider? mediaProvider;

  static ChatUser? _overrideLoggedInUser;
  static StreamSubscription<ChatEvent>? _eventSubscription;
  static final Map<String, void Function(ChatEvent event)> _eventListeners = {};
  static final Map<String, void Function(ChatMessage message)>
      _messageListeners = {};

  /// Local timezone metadata populated during [init].
  static String localTimeZoneIdentifier = '';
  static String localTimeZoneName = '';

  /// Whether the UIKit was initialized via [initFromSettings].
  static bool initializedFromSettings = false;

  /// Shared sound manager for UI feedback.
  static final SoundManager soundManager = SoundManager();

  /// Whether ConvoKit Core contracts/kit are configured.
  static bool get isConvoKitMode =>
      kit != null ||
      session != null ||
      conversationRepository != null ||
      messageRepository != null;

  /// Active [EventHub] bound to [kit], if initialized.
  static EventHub? get eventHub => _eventHub;

  /// Effective [ChatSession] from [session] or [kit].
  static ChatSession? get effectiveSession => session ?? kit?.session;

  /// Effective [ChatMediaProvider] from [mediaProvider] or [kit].
  static ChatMediaProvider? get effectiveMediaProvider =>
      mediaProvider ?? kit?.media;

  /// Effective [UserRepository] from [userRepository] or [kit].
  static UserRepository? get _users => userRepository ?? kit?.users;

  /// Effective [GroupRepository] from [groupRepository] or [kit].
  static GroupRepository? get _groups => groupRepository ?? kit?.groups;

  /// Effective [ConversationRepository] from [conversationRepository] or [kit].
  static ConversationRepository? get _conversations =>
      conversationRepository ?? kit?.conversations;

  /// Effective [MessageRepository] from [messageRepository] or [kit].
  static MessageRepository? get _messages => messageRepository ?? kit?.messages;

  /// Currently signed-in [ChatUser], reading from [effectiveSession] first
  /// and falling back to [_overrideLoggedInUser].
  static ChatUser? get currentUser =>
      effectiveSession?.currentUser ?? _overrideLoggedInUser;

  /// Alias for [currentUser] retained for compatibility with shared UI utilities.
  static ChatUser? get loggedInUser => currentUser;

  static set loggedInUser(ChatUser? user) {
    _overrideLoggedInUser = user;
  }

  /// Initializes ConvoKit Core and prepares timezone metadata and event routing.
  ///
  /// Flow: `ConvoKitUIKit.init()` -> `ConvoKit.init(...)` (when contracts are
  /// provided) -> `EventHub.attach(...)` / `ConvoKitScope`.
  static Future<void> init({
    UIKitSettings? uiKitSettings,
    ConvoKit? kit,
    String? appId,
    String? region,
    String? apiKey,
    String? authKey,
    bool autoLogin = false,
    Function(String successMessage)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    try {
      initializedFromSettings = false;
      authenticationSettings =
          uiKitSettings ??
          (UIKitSettingsBuilder()
                ..appId = appId
                ..region = region
                ..authKey = authKey)
              .build();

      _initializeTimeZoneDetails();

      if (kit != null) {
        ConvoKitUIKit.kit = ConvoKit.init(
          session: kit.session,
          users: kit.users,
          conversations: kit.conversations,
          messages: kit.messages,
          events: kit.events,
          capabilities: kit.capabilities,
          groups: kit.groups,
          media: kit.media,
        );
        session = ConvoKitUIKit.kit!.session;
        conversationRepository = ConvoKitUIKit.kit!.conversations;
        userRepository = ConvoKitUIKit.kit!.users;
        groupRepository = ConvoKitUIKit.kit!.groups;
        messageRepository = ConvoKitUIKit.kit!.messages;
        mediaProvider = ConvoKitUIKit.kit!.media;
        _attachEventHub(ConvoKitUIKit.kit!);
      } else if (ConvoKitUIKit.kit != null) {
        _attachEventHub(ConvoKitUIKit.kit!);
      }

      if (autoLogin && currentUser == null && _overrideLoggedInUser == null) {
        final restored = effectiveSession?.currentUser;
        if (restored != null) {
          _overrideLoggedInUser = restored;
        }
      }

      onSuccess?.call('ConvoKitUIKit initialized');
    } catch (e) {
      onError?.call(ChatError(ChatErrorCode.unknown, e.toString(), cause: e));
    }
  }

  /// Alias for [init] when booting from pre-built [UIKitSettings].
  static Future<void> initFromSettings({
    required UIKitSettings uiKitSettings,
    ConvoKit? kit,
    Function(String successMessage)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    initializedFromSettings = true;
    await init(
      uiKitSettings: uiKitSettings,
      kit: kit,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Disposes any [EventHub] and listener subscriptions held by the facade.
  static Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    _eventListeners.clear();
    _messageListeners.clear();
    _eventHub?.dispose();
    _eventHub = null;
    _overrideLoggedInUser = null;
    kit = null;
    session = null;
    conversationRepository = null;
    userRepository = null;
    groupRepository = null;
    messageRepository = null;
    mediaProvider = null;
    authenticationSettings = null;
    initializedFromSettings = false;
  }

  /// Signs in a user by [uid] using the configured [UserRepository] (or offline
  /// fallback when no repository is attached).
  static Future<ChatUser?> login(
    String uid, {
    Function(ChatUser user)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    return loginWithAuthKey(
      uid: uid,
      authKey: authenticationSettings?.authKey,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Signs in a user by [uid] (with optional [authKey]) against ConvoKit Core.
  static Future<ChatUser?> loginWithAuthKey({
    required String uid,
    String? authKey,
    Function(ChatUser user)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    if (uid.trim().isEmpty) {
      const error = ChatError(
        ChatErrorCode.validation,
        'User ID must not be empty.',
      );
      onError?.call(error);
      return null;
    }

    final repo = _users;
    if (repo != null) {
      final result = await repo.getUser(uid);
      return result.fold(
        onSuccess: (user) {
          _overrideLoggedInUser = user;
          onSuccess?.call(user);
          return user;
        },
        onFailure: (error) {
          onError?.call(error);
          return null;
        },
      );
    }

    final user = ChatUser(id: uid, name: uid, presence: UserPresence.online);
    _overrideLoggedInUser = user;
    onSuccess?.call(user);
    return user;
  }

  /// Signs in using an auth [token] (offline/Core-backed).
  static Future<ChatUser?> loginWithToken(
    String token, {
    String? uid,
    Function(ChatUser user)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    if (token.trim().isEmpty) {
      const error = ChatError(
        ChatErrorCode.validation,
        'Auth token must not be empty.',
      );
      onError?.call(error);
      return null;
    }
    final resolvedUid = uid ?? effectiveSession?.currentUser?.id ?? token;
    return loginWithAuthKey(
      uid: resolvedUid,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Compatibility alias for [loginWithToken].
  static Future<ChatUser?> loginWithAuthToken(
    String authToken, {
    Function(ChatUser user)? onSuccess,
    Function(ChatError e)? onError,
  }) => loginWithToken(authToken, onSuccess: onSuccess, onError: onError);

  /// Clears the active user and disconnects any managed [EventHub].
  static Future<void> logout({
    Function(String successMessage)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    try {
      _overrideLoggedInUser = null;
      if (kit != null) {
        await kit!.events.disconnect();
      }
      onSuccess?.call('Logged out');
    } catch (e) {
      onError?.call(ChatError(ChatErrorCode.unknown, e.toString(), cause: e));
    }
  }

  /// Returns the currently logged-in [ChatUser], if any.
  static Future<ChatUser?> getLoggedInUser({
    Function(ChatUser? user)? onSuccess,
    Function(ChatError e)? onError,
  }) async {
    final user = currentUser;
    onSuccess?.call(user);
    return user;
  }

  /// Registers a general [ChatEvent] listener keyed by [id].
  static void addListener(
    String id,
    void Function(ChatEvent event) listener,
  ) {
    _eventListeners[id] = listener;
    _ensureEventSubscription();
  }

  /// Removes a general [ChatEvent] listener keyed by [id].
  static void removeListener(String id) {
    _eventListeners.remove(id);
  }

  /// Registers a [ChatMessage] listener keyed by [id].
  static void addMessageListener(
    String id,
    void Function(ChatMessage message) listener,
  ) {
    _messageListeners[id] = listener;
    _ensureEventSubscription();
  }

  /// Removes a [ChatMessage] listener keyed by [id].
  static void removeMessageListener(String id) {
    _messageListeners.remove(id);
  }

  /// Fetches a user by [id] via [UserRepository].
  static Future<ChatResult<ChatUser>> getUser(String id) async {
    final repo = _users;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unsupported, 'UserRepository is not configured.'),
      );
    }
    return repo.getUser(id);
  }

  /// Fetches a group by [id] via [GroupRepository].
  static Future<ChatResult<ChatGroup>> getGroup(String id) async {
    final repo = _groups;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unsupported, 'GroupRepository is not configured.'),
      );
    }
    return repo.getGroup(id);
  }

  /// Lists groups via [GroupRepository].
  static Future<ChatResult<ChatPage<ChatGroup>>> getGroups({
    String? cursor,
    int limit = 30,
  }) async {
    final repo = _groups;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unsupported, 'GroupRepository is not configured.'),
      );
    }
    return repo.listGroups(cursor: cursor, limit: limit);
  }

  /// Marks a message (and optionally its conversation) as read.
  static Future<ChatResult<void>> markMessagesAsRead(
    String messageId, {
    String? conversationId,
  }) async {
    final msgRepo = _messages;
    if (msgRepo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    final res = await msgRepo.markAsRead(messageId);
    if (conversationId != null && _conversations != null) {
      await _conversations!.markAsRead(conversationId);
    }
    return res;
  }

  /// Marks a message as delivered.
  static Future<ChatResult<void>> markMessagesAsDelivered(
    String messageId,
  ) async {
    final msgRepo = _messages;
    if (msgRepo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    return msgRepo.markAsDelivered(messageId);
  }

  /// Fetches a page of conversations.
  static Future<ChatResult<ChatPage<ChatConversation>>> getConversationList({
    String? cursor,
    int limit = 30,
  }) => getConversations(cursor: cursor, limit: limit);

  /// Fetches a page of conversations via [ConversationRepository].
  static Future<ChatResult<ChatPage<ChatConversation>>> getConversations({
    String? cursor,
    int limit = 30,
  }) async {
    final repo = _conversations;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'ConversationRepository is not configured.',
        ),
      );
    }
    return repo.listConversations(cursor: cursor, limit: limit);
  }

  /// Fetches a single conversation by [id].
  static Future<ChatResult<ChatConversation>> getConversation(String id) async {
    final repo = _conversations;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'ConversationRepository is not configured.',
        ),
      );
    }
    return repo.getConversation(id);
  }

  /// Deletes a conversation by [conversationId].
  static Future<ChatResult<void>> deleteConversation(
    String conversationId,
  ) async {
    final repo = _conversations;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'ConversationRepository is not configured.',
        ),
      );
    }
    return repo.deleteConversation(conversationId);
  }

  /// Sends a text message via [MessageCoordinator] (or [MessageRepository]).
  static Future<ChatResult<ChatMessage>> sendTextMessage({
    required String conversationId,
    required String text,
    ChatUser? sender,
    ChatMessage? repliedTo,
    String? localId,
  }) async {
    final effectiveSender = sender ?? currentUser;
    if (effectiveSender == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unauthorized, 'No signed-in user.'),
      );
    }
    if (_eventHub != null && kit != null) {
      return _eventHub!.coordinator.sendTextMessage(
        conversationId: conversationId,
        text: text,
        sender: effectiveSender,
        repliedTo: repliedTo,
        localId: localId,
      );
    }
    final repo = _messages;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    final coordinator = kit != null ? MessageCoordinator(kit!) : null;
    if (coordinator != null) {
      return coordinator.sendTextMessage(
        conversationId: conversationId,
        text: text,
        sender: effectiveSender,
        repliedTo: repliedTo,
        localId: localId,
      );
    }
    final pending = TextMessage(
      localId: localId ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      sender: effectiveSender,
      createdAt: DateTime.now(),
      sendState: SendState.sending,
      deliveryState: DeliveryState.none,
      repliedTo: repliedTo,
      text: text,
    );
    return repo.sendMessage(pending);
  }

  /// Sends a media message via [MessageCoordinator] (or [MessageRepository]).
  static Future<ChatResult<ChatMessage>> sendMediaMessage({
    required String conversationId,
    required ChatAttachment attachment,
    ChatUser? sender,
    String? caption,
    ChatMessage? repliedTo,
    String? localId,
  }) async {
    final effectiveSender = sender ?? currentUser;
    if (effectiveSender == null) {
      return const ChatResult.failure(
        ChatError(ChatErrorCode.unauthorized, 'No signed-in user.'),
      );
    }
    if (_eventHub != null && kit != null) {
      return _eventHub!.coordinator.sendMediaMessage(
        conversationId: conversationId,
        attachment: attachment,
        sender: effectiveSender,
        caption: caption,
        repliedTo: repliedTo,
        localId: localId,
      );
    }
    final repo = _messages;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    final pending = MediaMessage(
      localId: localId ?? 'local_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: conversationId,
      sender: effectiveSender,
      createdAt: DateTime.now(),
      sendState: SendState.sending,
      deliveryState: DeliveryState.none,
      repliedTo: repliedTo,
      attachment: attachment,
      caption: caption,
    );
    return repo.sendMessage(pending);
  }

  /// Fetches messages for [conversationId] via [MessageRepository].
  static Future<ChatResult<ChatPage<ChatMessage>>> getMessages(
    String conversationId, {
    MessagePageRequest request = const MessagePageRequest(
      direction: MessagePageDirection.latest,
    ),
  }) async {
    final repo = _messages;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    return repo.fetchMessages(conversationId, request);
  }

  /// Edits a message. Message editing is deferred in ConvoKit v1 and returns
  /// [ChatErrorCode.unsupported].
  static Future<ChatResult<ChatMessage>> editMessage(
    ChatMessage message,
  ) async {
    return const ChatResult.failure(
      ChatError(
        ChatErrorCode.unsupported,
        'Message editing is not supported in ConvoKit v1.',
      ),
    );
  }

  /// Deletes a message by [messageId] via [MessageRepository].
  static Future<ChatResult<void>> deleteMessage(String messageId) async {
    final repo = _messages;
    if (repo == null) {
      return const ChatResult.failure(
        ChatError(
          ChatErrorCode.unsupported,
          'MessageRepository is not configured.',
        ),
      );
    }
    return repo.deleteMessage(messageId);
  }

  /// Requests media/storage permission on mobile platforms; returns `true` on
  /// web or desktop platforms where runtime storage permissions do not apply.
  static Future<bool> requestMediaPermission() async {
    if (kIsWeb) return true;
    try {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (_) {
      return true;
    }
  }

  static void _attachEventHub(ConvoKit activeKit) {
    if (_eventHub == null || _eventHub!.isDisposed) {
      _eventHub = EventHub()..attach(activeKit);
    } else if (!identical(_eventHub!.currentKit, activeKit)) {
      _eventHub!.reattach(activeKit);
    }
    _ensureEventSubscription();
  }

  static void _ensureEventSubscription() {
    final activeKit = kit;
    if (activeKit == null || _eventSubscription != null) return;
    _eventSubscription = activeKit.events.events.listen((event) {
      for (final listener in List<void Function(ChatEvent)>.of(
        _eventListeners.values,
      )) {
        listener(event);
      }
      if (event is MessageReceived) {
        for (final listener in List<void Function(ChatMessage)>.of(
          _messageListeners.values,
        )) {
          listener(event.message);
        }
      }
    });
  }

  static void _initializeTimeZoneDetails() {
    try {
      initializeTimeZones();
    } catch (_) {
      // Timezone initialization is best-effort.
    }
  }
}
