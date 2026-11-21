import 'dart:async';

import 'package:convokit/convokit.dart' show ConvoKitScope, GroupRepository;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../backend/studio_group_repository.dart';
import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';

/// Group members management screen mounting [ConvoKitGroupMembers] with tonal
/// role pill badges (`Owner`/`Admin`/`Member`), an extra-large rounded
/// [ConvoKitChangeScope] modal (radius 28) with full-pill Save/Cancel buttons
/// (`>=44px` height), and an "Add Members" flow mounting [ConvoKitUsers] in
/// [SelectionMode.multiple] wired to [GroupRepository.addMembers].
class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.group,
  });

  final ChatGroup group;

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  ConvoKitGroupMembersController? _membersController;

  void _openChangeScopeSheet(ChatMember member) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupsRepo = ConvoKitScope.maybeOf(context)?.groups;
    final changeScopeStyle = ShowcaseTheme.changeScopeStyle(context);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ShowcaseTokens.radiusSheet),
          ),
        ),
        barrierColor: colorScheme.scrim.withValues(alpha: 0.54),
        builder: (sheetContext) => Theme(
          data: theme.copyWith(
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                minimumSize: ShowcaseTokens.minTouchTargetSize,
                shape: const StadiumBorder(),
                textStyle: ShowcaseTypography.buttonLabel,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: ConvoKitChangeScope(
                group: widget.group,
                member: member,
                style: changeScopeStyle,
                onSave: (group, updatedMember, newScope, oldScope) async {
                  final role = newScope.toLowerCase() == 'admin'
                      ? GroupRole.admin
                      : GroupRole.member;
                  if (groupsRepo is StudioGroupRepository) {
                    groupsRepo.updateMemberRole(
                      group.id,
                      updatedMember.user.id,
                      role,
                    );
                  }
                  _membersController?.updateMemberRole(
                    updatedMember.user.id,
                    role,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddMembersPicker() {
    final groupsRepo = ConvoKitScope.maybeOf(context)?.groups;
    if (groupsRepo == null) return;
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + ShowcaseTokens.space2Xl;

    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (pickerContext) => ConvoKitUsers(
            title: 'Add Members',
            showBackButton: true,
            hideAppbar: false,
            onBack: () => Navigator.of(pickerContext).maybePop(),
            selectionMode: SelectionMode.multiple,
            activateSelection: ActivateSelection.onClick,
            usersStyle: ShowcaseTheme.usersStyle(pickerContext),
            listPadding: EdgeInsets.only(bottom: bottomPadding),
            onSelection: (selectedUsers, selectionContext) {
              unawaited(
                _addSelectedMembers(
                  groupsRepo: groupsRepo,
                  selectedUsers: selectedUsers,
                  selectionContext: selectionContext,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addSelectedMembers({
    required GroupRepository groupsRepo,
    required List<ChatUser>? selectedUsers,
    required BuildContext selectionContext,
  }) async {
    final users = selectedUsers ?? const <ChatUser>[];
    if (users.isEmpty) {
      if (selectionContext.mounted) {
        Navigator.of(selectionContext).pop();
      }
      return;
    }

    final userIds = users.map((u) => u.id).toList(growable: false);
    final result = await groupsRepo.addMembers(widget.group.id, userIds);

    if (selectionContext.mounted) {
      Navigator.of(selectionContext).pop();
    }
    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        unawaited(_membersController?.loadMembers());
      },
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding =
        MediaQuery.paddingOf(context).bottom + ShowcaseTokens.space2Xl;

    return ConvoKitGroupMembers(
      group: widget.group,
      showBackButton: true,
      onBack: () => Navigator.of(context).maybePop(),
      style: ShowcaseTheme.groupMembersStyle(context),
      listPadding: EdgeInsets.only(bottom: bottomPadding),
      stateCallBack: (controller) => _membersController = controller,
      trailingView: (ctx, member) => _RolePillBadge(role: member.role),
      appBarOptions: <Widget>[
        IconButton(
          key: const Key('group_members_add_button'),
          tooltip: 'Add members',
          constraints: const BoxConstraints(
            minWidth: ShowcaseTokens.minTouchTarget,
            minHeight: ShowcaseTokens.minTouchTarget,
          ),
          style: IconButton.styleFrom(
            minimumSize: ShowcaseTokens.minTouchTargetSize,
            tapTargetSize: MaterialTapTargetSize.padded,
            shape: const StadiumBorder(),
          ),
          onPressed: _openAddMembersPicker,
          icon: Icon(
            Icons.person_add_alt_1_outlined,
            color: colorScheme.primary,
          ),
        ),
      ],
      onItemTap: (member) {
        if (member.role != GroupRole.owner) {
          _openChangeScopeSheet(member);
        }
      },
    );
  }
}

/// Tonal M3 Expressive role pill badge for `owner`, `admin`, and `member`.
class _RolePillBadge extends StatelessWidget {
  const _RolePillBadge({required this.role});

  final GroupRole role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final String label;
    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide? borderSide;

    switch (role) {
      case GroupRole.owner:
        label = 'Owner';
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        borderSide = null;
      case GroupRole.admin:
        label = 'Admin';
        backgroundColor = colorScheme.primaryContainer;
        foregroundColor = colorScheme.onPrimaryContainer;
        borderSide = BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.28),
        );
      case GroupRole.member:
        label = 'Member';
        backgroundColor = colorScheme.surfaceContainerHigh;
        foregroundColor = colorScheme.onSurfaceVariant;
        borderSide = BorderSide(color: colorScheme.outlineVariant);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ShowcaseTokens.spaceMd,
        vertical: ShowcaseTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusFullPill),
        border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
      ),
      child: Text(
        label,
        style: ShowcaseTypography.sectionLabel.copyWith(
          color: foregroundColor,
        ),
      ),
    );
  }
}
