import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';
import '../chat/chat_screen.dart';
import 'group_members_screen.dart';

/// Segments displayed in [PeopleGroupsScreen].
enum DirectorySegment {
  people,
  groups,
}

/// Directory screen reachable from the Chats header compose button.
///
/// Hosts a frosted Liquid Glass header (via [CollapsingGlassHeader]), an M3
/// Expressive full-pill [SegmentedButton] on `surfaceContainerHigh`, and an
/// [IndexedStack] mounting [ConvoKitUsers] (tap to open a direct [ChatScreen];
/// also supports [SelectionMode.multiple] for member picking) and
/// [ConvoKitGroups] (tap to open a group [ChatScreen]; trailing action opens
/// [GroupMembersScreen]).
class PeopleGroupsScreen extends StatefulWidget {
  const PeopleGroupsScreen({
    super.key,
    this.initialSegment = DirectorySegment.people,
    this.selectionMode,
    this.onSelection,
    this.title,
  });

  /// Initial segment selected when opened in directory browsing mode.
  final DirectorySegment initialSegment;

  /// Optional selection mode forwarded to [ConvoKitUsers] (e.g.
  /// [SelectionMode.multiple] for member picking).
  final SelectionMode? selectionMode;

  /// Callback invoked when [ConvoKitUsers] confirms a selection.
  final void Function(List<ChatUser>? users, BuildContext context)? onSelection;

  /// Optional screen title override.
  final String? title;

  @override
  State<PeopleGroupsScreen> createState() => _PeopleGroupsScreenState();
}

class _PeopleGroupsScreenState extends State<PeopleGroupsScreen> {
  late DirectorySegment _segment;

  bool get _isSelectionMode =>
      widget.selectionMode != null &&
      widget.selectionMode != SelectionMode.none;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
  }

  Future<String> _resolveDirectConversationId(
    BuildContext context,
    ChatUser user,
  ) async {
    final kit = ConvoKitScope.maybeOf(context);
    if (kit != null) {
      final result = await kit.conversations.listConversations(limit: 100);
      final existing = result.fold<String?>(
        onSuccess: (page) {
          for (final conv in page.items) {
            if (conv.peer?.id == user.id) {
              return conv.id;
            }
          }
          return null;
        },
        onFailure: (_) => null,
      );
      if (existing != null) return existing;
    }
    return 'conv_dm_${user.id}';
  }

  Future<String> _resolveGroupConversationId(
    BuildContext context,
    ChatGroup group,
  ) async {
    final kit = ConvoKitScope.maybeOf(context);
    if (kit != null) {
      final result = await kit.conversations.listConversations(limit: 100);
      final existing = result.fold<String?>(
        onSuccess: (page) {
          for (final conv in page.items) {
            if (conv.group?.id == group.id) {
              return conv.id;
            }
          }
          return null;
        },
        onFailure: (_) => null,
      );
      if (existing != null) return existing;
    }
    return 'conv_grp_${group.id}';
  }

  Future<void> _openDirectChat(BuildContext context, ChatUser user) async {
    final conversationId = await _resolveDirectConversationId(context, user);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          user: user,
        ),
      ),
    );
  }

  Future<void> _openGroupChat(BuildContext context, ChatGroup group) async {
    final conversationId = await _resolveGroupConversationId(context, group);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          group: group,
        ),
      ),
    );
  }

  void _openGroupMembers(BuildContext context, ChatGroup group) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupMembersScreen(group: group),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + ShowcaseTokens.space2Xl;
    final listPadding = EdgeInsets.only(bottom: bottomPadding);

    if (_isSelectionMode) {
      return ConvoKitUsers(
        title: widget.title ?? 'Select Members',
        showBackButton: true,
        hideAppbar: false,
        onBack: () => Navigator.of(context).maybePop(),
        selectionMode: widget.selectionMode,
        activateSelection: ActivateSelection.onClick,
        onSelection: widget.onSelection,
        usersStyle: ShowcaseTheme.usersStyle(context),
        listPadding: listPadding,
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1 ?? colorScheme.surface,
      body: Column(
        children: <Widget>[
          CollapsingGlassHeader(
            title: widget.title ?? 'People & Groups',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ShowcaseTokens.spaceLg,
              ShowcaseTokens.spaceXs,
              ShowcaseTokens.spaceLg,
              ShowcaseTokens.spaceMd,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<DirectorySegment>(
                key: const Key('people_groups_switcher'),
                showSelectedIcon: false,
                style: ButtonStyle(
                  shape: const WidgetStatePropertyAll<OutlinedBorder>(
                    StadiumBorder(),
                  ),
                  minimumSize: const WidgetStatePropertyAll<Size>(
                    ShowcaseTokens.minTouchTargetSize,
                  ),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  side: WidgetStatePropertyAll<BorderSide>(
                    BorderSide(color: colorScheme.outlineVariant),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primaryContainer;
                      }
                      return colorScheme.surfaceContainerHigh;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.onPrimaryContainer;
                      }
                      return colorScheme.onSurfaceVariant;
                    },
                  ),
                  textStyle: const WidgetStatePropertyAll<TextStyle>(
                    ShowcaseTypography.buttonLabel,
                  ),
                ),
                segments: const <ButtonSegment<DirectorySegment>>[
                  ButtonSegment<DirectorySegment>(
                    value: DirectorySegment.people,
                    label: Text('People'),
                    icon: ExcludeSemantics(
                      child: Icon(Icons.person_outline_rounded, size: 18),
                    ),
                  ),
                  ButtonSegment<DirectorySegment>(
                    value: DirectorySegment.groups,
                    label: Text('Groups'),
                    icon: ExcludeSemantics(
                      child: Icon(Icons.groups_outlined, size: 18),
                    ),
                  ),
                ],
                selected: <DirectorySegment>{_segment},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() => _segment = selection.first);
                },
              ),
            ),
          ),
          ExcludeSemantics(
            child: Container(
              height: 0.6,
              color: colorScheme.outlineVariant,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _segment == DirectorySegment.people ? 0 : 1,
              children: <Widget>[
                ConvoKitUsers(
                  hideAppbar: true,
                  showBackButton: false,
                  usersStyle: ShowcaseTheme.usersStyle(context),
                  listPadding: listPadding,
                  onItemTap: (ctx, user) =>
                      unawaited(_openDirectChat(ctx, user)),
                ),
                ConvoKitGroups(
                  hideAppbar: true,
                  showBackButton: false,
                  groupsStyle: ShowcaseTheme.groupsStyle(context),
                  listPadding: listPadding,
                  onItemTap: (ctx, group) =>
                      unawaited(_openGroupChat(ctx, group)),
                  trailingView: (ctx, group) => IconButton(
                    key: Key('group_members_action_${group.id}'),
                    tooltip: 'Group members',
                    constraints: const BoxConstraints(
                      minWidth: ShowcaseTokens.minTouchTarget,
                      minHeight: ShowcaseTokens.minTouchTarget,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: ShowcaseTokens.minTouchTargetSize,
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => _openGroupMembers(ctx, group),
                    icon: Icon(
                      Icons.group_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
