import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convokit/convokit.dart';

import 'in_memory_chat_backend.dart';

/// Riverpod provider delivering ConvoKit configured with InMemoryChatBackend.
final kitProvider = Provider<ConvoKit>((ref) {
  final fake = InMemoryChatBackend();
  return ConvoKit(
    session: fake.session,
    users: fake.users,
    conversations: fake.conversations,
    messages: fake.messages,
    groups: fake.groups,
    media: fake.media,
    events: fake.events,
    capabilities: ChatCapabilities.basic(),
  );
});

void main() {
  runApp(const ProviderScope(child: CleanConsumerApp()));
}

/// Root application widget powered by Riverpod (zero BLoC imports).
class CleanConsumerApp extends ConsumerWidget {
  const CleanConsumerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = ref.watch(kitProvider);
    return ConvoKitScope(
      kit: kit,
      child: MaterialApp(
        title: 'ConvoKit Clean Consumer',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: const ConversationsScreen(),
      ),
    );
  }
}

/// Screen rendering conversations list via ConvoKit ConversationsView.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: ConversationsView(
        onConversationTap: (conversation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
      ),
    );
  }
}

/// Screen rendering message list for a conversation via MessageListView.
class ChatScreen extends StatelessWidget {
  final ChatConversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final title = conversation.peer?.name ?? conversation.id;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: MessageListView(conversationId: conversation.id),
    );
  }
}
