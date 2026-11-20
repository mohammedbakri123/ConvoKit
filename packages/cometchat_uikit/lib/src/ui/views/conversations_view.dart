/// ConversationsView widget according to API-DESIGN.md §12.
library;

import 'package:flutter/material.dart';

import '../../contracts/result.dart';
import '../../core/models/conversation.dart';
import '../../core/models/message.dart';
import '../convo_kit_scope.dart';

class ConversationsView extends StatefulWidget {
  final dynamic style;
  final void Function(ChatConversation conversation)? onConversationTap;
  final Widget Function(BuildContext context, ChatConversation conversation)?
  listItemBuilder;
  final WidgetBuilder? emptyBuilder;
  final Widget Function(BuildContext context, ChatError error)? errorBuilder;

  const ConversationsView({
    super.key,
    this.style,
    this.onConversationTap,
    this.listItemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  @override
  State<ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<ConversationsView> {
  List<ChatConversation>? _conversations;
  ChatError? _error;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final kit = ConvoKitScope.of(context);
      final result = await kit.conversations.listConversations();
      if (!mounted) return;
      result.fold(
        onSuccess: (page) {
          setState(() {
            _conversations = page.items;
            _isLoading = false;
          });
        },
        onFailure: (err) {
          setState(() {
            _error = err;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ChatError(ChatErrorCode.unknown, e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Material(
        child:
            widget.errorBuilder?.call(context, _error!) ??
            Center(child: Text(_error!.message)),
      );
    }
    final items = _conversations ?? const [];
    if (items.isEmpty) {
      return Material(
        child:
            widget.emptyBuilder?.call(context) ??
            const Center(child: Text('No conversations')),
      );
    }

    return Material(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final conversation = items[index];
          if (widget.listItemBuilder != null) {
            return widget.listItemBuilder!(context, conversation);
          }
          final title = conversation.peer?.name ??
              conversation.group?.name ??
              conversation.id;
          final subtitle = switch (conversation.lastMessage) {
            TextMessage t => t.text,
            MediaMessage _ => 'Media',
            CustomMessage c => c.kind,
            _ => '',
          };
          return ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: conversation.unreadCount > 0
                ? CircleAvatar(
                    radius: 10,
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  )
                : null,
            onTap: () => widget.onConversationTap?.call(conversation),
          );
        },
      ),
    );
  }
}
