import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:sample_app/in_memory_chat_backend.dart';
import 'package:sample_app/utils/app_uikit_settings.dart';

/// Shared offline ConvoKit backend and composition root for the sample app.
///
/// Wires [InMemoryChatBackend] into [ConvoKit.init] and [ConvoKitUIKit.init]
/// so every screen works 100% offline with zero network calls or credentials.
class SampleAppBackend {
  SampleAppBackend._() {
    backend = InMemoryChatBackend();
    kit = ConvoKit.init(
      session: backend.session,
      users: backend.users,
      conversations: backend.conversations,
      messages: backend.messages,
      events: backend.events,
      groups: backend.groups,
      media: backend.media,
      capabilities: const ChatCapabilities(
        receipts: true,
        typing: true,
        media: true,
        mediaDelete: true,
        groups: true,
        search: true,
        messageCatchUp: true,
      ),
    );
  }

  static final SampleAppBackend instance = SampleAppBackend._();

  late final InMemoryChatBackend backend;
  late final ConvoKit kit;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await ConvoKitUIKit.init(
      uiKitSettings: buildAppUIKitSettings(),
      kit: kit,
      autoLogin: true,
    );
    _initialized = true;
  }

  Future<ChatUser> loginAs(String uid) async {
    await ensureInitialized();
    final user = backend.loginAs(uid);
    ConvoKitUIKit.loggedInUser = user;
    return user;
  }

  Future<void> logout() async {
    backend.updateUser(null);
    await ConvoKitUIKit.logout();
  }
}
