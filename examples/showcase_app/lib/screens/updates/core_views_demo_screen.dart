import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart' show ConvoKitThemeHelper;
import 'package:flutter/material.dart';

import '../../backend/studio_seed_data.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';

/// Demonstrates the lightweight Core UI views exported from
/// `package:convokit/convokit.dart` ([ConversationsView] and
/// [MessageListView]) running live against the same [ConvoKitScope].
///
/// Renders side-by-side on wide screens (`>= 600px`) and stacked on compact
/// screens, with an option to push a full-screen [MessageListView].
class CoreViewsDemoScreen extends StatefulWidget {
  const CoreViewsDemoScreen({
    super.key,
    this.initialConversationId = StudioSeedData.designSystemsConvId,
  });

  /// Conversation initially displayed in [MessageListView].
  final String initialConversationId;

  @override
  State<CoreViewsDemoScreen> createState() => _CoreViewsDemoScreenState();
}

class _CoreViewsDemoScreenState extends State<CoreViewsDemoScreen> {
  late String _selectedConversationId;
  String _selectedTitle = 'Design Systems';

  @override
  void initState() {
    super.initState();
    _selectedConversationId = widget.initialConversationId;
  }

  void _selectConversation(ChatConversation conversation) {
    final title =
        conversation.peer?.name ?? conversation.group?.name ?? conversation.id;
    setState(() {
      _selectedConversationId = conversation.id;
      _selectedTitle = title;
    });
  }

  void _pushFullMessageList(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _FullCoreMessageListPage(
            conversationId: _selectedConversationId,
            title: _selectedTitle,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
      constraints: const BoxConstraints(
        minWidth: ShowcaseTokens.minTouchTarget,
        minHeight: ShowcaseTokens.minTouchTarget,
      ),
      style: IconButton.styleFrom(
        minimumSize: ShowcaseTokens.minTouchTargetSize,
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: const StadiumBorder(),
      ),
      icon: Icon(
        Icons.arrow_back_rounded,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildPaneHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ShowcaseTokens.spaceLg,
        vertical: ShowcaseTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: ShowcaseTypography.sectionLabel.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: ShowcaseTokens.spaceXs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShowcaseTypography.timestamp.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: ShowcaseTokens.minControlGap),
            trailing,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    final conversationsPane = Column(
      children: <Widget>[
        _buildPaneHeader(
          context,
          title: 'CONVERSATIONSVIEW',
          subtitle: 'package:convokit/convokit.dart',
        ),
        Expanded(
          child: ConversationsView(
            onConversationTap: _selectConversation,
          ),
        ),
      ],
    );

    final messageListPane = Column(
      children: <Widget>[
        _buildPaneHeader(
          context,
          title: 'MESSAGELISTVIEW',
          subtitle: _selectedTitle,
          trailing: FilledButton.tonalIcon(
            key: const Key('core_views_push_messages_button'),
            onPressed: () => _pushFullMessageList(context),
            style: FilledButton.styleFrom(
              minimumSize: ShowcaseTokens.minTouchTargetSize,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                horizontal: ShowcaseTokens.spaceLg,
                vertical: ShowcaseTokens.spaceSm,
              ),
            ),
            icon: const ExcludeSemantics(
              child: Icon(Icons.open_in_full_rounded, size: 16),
            ),
            label: const Text('Full Screen'),
          ),
        ),
        Expanded(
          child: MessageListView(
            key: ValueKey<String>(_selectedConversationId),
            conversationId: _selectedConversationId,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: palette.background1 ?? colorScheme.surface,
      body: Column(
        children: <Widget>[
          CollapsingGlassHeader(
            title: 'Core Views Demo',
            scrollOffset: CollapsingGlassHeader.collapseThreshold,
            leading: _buildBackButton(context),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 600) {
                    return Row(
                      children: <Widget>[
                        Expanded(flex: 2, child: conversationsPane),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        Expanded(flex: 3, child: messageListPane),
                      ],
                    );
                  }
                  return Column(
                    children: <Widget>[
                      Expanded(flex: 2, child: conversationsPane),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      Expanded(flex: 3, child: messageListPane),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullCoreMessageListPage extends StatelessWidget {
  const _FullCoreMessageListPage({
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1 ?? colorScheme.surface,
      body: Column(
        children: <Widget>[
          CollapsingGlassHeader(
            title: title,
            scrollOffset: CollapsingGlassHeader.collapseThreshold,
            leading: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              constraints: const BoxConstraints(
                minWidth: ShowcaseTokens.minTouchTarget,
                minHeight: ShowcaseTokens.minTouchTarget,
              ),
              style: IconButton.styleFrom(
                minimumSize: ShowcaseTokens.minTouchTargetSize,
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: const StadiumBorder(),
              ),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: MessageListView(conversationId: conversationId),
            ),
          ),
        ],
      ),
    );
  }
}
