/// ConversationsView widget placeholder according to API-DESIGN.md §12.
library;

import 'package:flutter/widgets.dart';

import '../../contracts/result.dart';
import '../../core/models/conversation.dart';

class ConversationsView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
