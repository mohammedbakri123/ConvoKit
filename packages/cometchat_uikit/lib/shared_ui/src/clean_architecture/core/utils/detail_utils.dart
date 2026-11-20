import "package:cometchat_sdk/cometchat_sdk.dart" hide CardMessage;
import 'package:flutter/material.dart';

// Import all necessary dependencies
import '../constants/ui_kit_constants.dart';
import '../constants/asset_constants.dart';
import '../../data/models/cometchat_group_member_option.dart';
import '../../data/models/cometchat_details_option.dart';
import '../../data/models/cometchat_details_template.dart';
import '../../../../l10n/translations.dart';

///[DetailUtils] is a Utility class that provides
///the default options and templates available in `ConvoKitDetails`
///which allows users to block and unblock other users
///group members to view, add, ban other members
class DetailUtils {
  static List<CometChatGroupMemberOption> getDefaultGroupMemberOptions({
    User? loggedInUser,
    Group? group,
    GroupMember? member,
    required BuildContext context,
    bool? hideKickMemberOption,
    bool? hideBanMemberOption,
    bool? hideScopeChangeOption,
  }) {
    return [
      if (hideScopeChangeOption != true) getScopeChangeOption(context),
      if (hideBanMemberOption != true) getBanOption(context),
      if (hideKickMemberOption != true) getKickOption(context),
    ].where((option) {
      final result = validateGroupMemberOptions(
        loggedInUserScope: loggedInUser?.uid == group?.owner
            ? GroupMemberScope.owner
            : group?.scope ?? GroupMemberScope.participant,
        memberScope: member?.uid == group?.owner
            ? GroupMemberScope.owner
            : member?.scope ?? GroupMemberScope.participant,
        optionId: option.id,
      );
      if (option.id == GroupMemberOptionConstants.changeScope) {
        return result.isNotEmpty;
      } else {
        return result;
      }
    }).toList();
  }

  static CometChatGroupMemberOption getKickOption(BuildContext context) {
    return CometChatGroupMemberOption(
      id: GroupMemberOptionConstants.kick,
      title: Translations.of(context).kick,
      icon: AssetConstants.cancel,
      packageName: UIConstants.packageName,
      // backgroundColor: theme?.palette.getError() ?? Colors.red,
    );
  }

  static CometChatGroupMemberOption getBanOption(BuildContext context) {
    return CometChatGroupMemberOption(
      id: GroupMemberOptionConstants.ban,
      title: Translations.of(context).ban,
      icon: AssetConstants.block,
      packageName: UIConstants.packageName,
      // backgroundColor: theme?.palette.getOption() ?? const Color(0xffFFC900),
    );
  }

  static CometChatGroupMemberOption getScopeChangeOption(BuildContext context) {
    return CometChatGroupMemberOption(
      id: GroupMemberOptionConstants.changeScope,
      title: Translations.of(context).changeScope,
      packageName: UIConstants.packageName,
      icon: AssetConstants.changeScope96px,
    );
  }

  static ConvoKitDetailsOption getViewMemberOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.viewMembers,
      title: Translations.of(context).viewMembers,
      packageName: UIConstants.packageName,
      tail: const Icon(Icons.navigate_next),
      titleStyle: _getPrimaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getBannedMemberOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.bannedMembers,
      title: Translations.of(context).bannedMembers,
      packageName: UIConstants.packageName,
      tail: const Icon(Icons.navigate_next),
      titleStyle: _getPrimaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getAddMembersOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.addMembers,
      title: Translations.of(context).addMembers,
      packageName: UIConstants.packageName,
      tail: const Icon(Icons.navigate_next),
      titleStyle: _getPrimaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getLeaveGroupOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.leave,
      title: Translations.of(context).leaveGroup,
      packageName: UIConstants.packageName,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getDeleteGroupOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.delete,
      title: Translations.of(context).deleteAndExit,
      packageName: UIConstants.packageName,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getBlockUserOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: UserOptionConstants.blockUser,
      title: Translations.of(context).blockUser,
      packageName: UIConstants.packageName,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getUnBlockUserOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: UserOptionConstants.unblockUser,
      title: Translations.of(context).unblockUser,
      packageName: UIConstants.packageName,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getViewProfileOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: UserOptionConstants.viewProfile,
      title: Translations.of(context).viewProfile,
      packageName: UIConstants.packageName,
      titleStyle: _getPrimaryOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getLeaveOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.leave,
      title: Translations.of(context).leaveGroup,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsOption getDeleteOption(BuildContext context) {
    return ConvoKitDetailsOption(
      id: GroupOptionConstants.delete,
      title: Translations.of(context).deleteAndExit,
      packageName: UIConstants.packageName,
      titleStyle: _getSecondaryGroupOptionTextStyle(),
    );
  }

  static ConvoKitDetailsTemplate? getPrimaryDetailsTemplate(
    BuildContext context,
    User? loggedInUser,
    User? user,
    Group? group,
  ) {
    return ConvoKitDetailsTemplate(
      id: DetailsTemplateConstants.primaryActions,
      hideItemSeparator: true,
      hideSectionSeparator: false,
      options: (user, group, context) => user != null
          ? []
          : [
                  getViewMemberOption(context!),
                  getAddMembersOption(context),
                  getBannedMemberOption(context),
                ]
                .where(
                  (option) => validateDetailOptions(
                    loggedInUserScope: loggedInUser?.uid == group?.owner
                        ? GroupMemberScope.owner
                        : group?.scope ?? GroupMemberScope.participant,
                    optionId: option.id,
                  ),
                )
                .toList(),
    );
  }

  static ConvoKitDetailsTemplate? getSecondaryDetailsTemplate(
    BuildContext context,
    User? loggedInUser,
    User? user,
    Group? group,
  ) {
    if (user != null) {
      return ConvoKitDetailsTemplate(
        id: DetailsTemplateConstants.secondaryActions,
        title: Translations.of(context).privacyAndSecurity,
        hideItemSeparator: true,
        hideSectionSeparator: false,
        options: (user, group, context) =>
            [getBlockUserOption(context!), getUnBlockUserOption(context)]
                .where(
                  (option) =>
                      validateUserOptions(loggedInUser, user, option.id),
                )
                .toList(),
      );
    } else if (group != null) {
      return ConvoKitDetailsTemplate(
        id: DetailsTemplateConstants.secondaryActions,
        title: Translations.of(context).more,
        hideItemSeparator: true,
        hideSectionSeparator: false,
        options: (user, group, context) =>
            [getLeaveGroupOption(context!), getDeleteGroupOption(context)]
                .where(
                  (option) => validateDetailOptions(
                    loggedInUserScope: loggedInUser?.uid == group?.owner
                        ? GroupMemberScope.owner
                        : group?.scope ?? GroupMemberScope.participant,
                    optionId: option.id,
                  ),
                )
                .toList(),
      );
    }
    return null;
  }

  static List<ConvoKitDetailsTemplate> getDefaultDetailsTemplates(
    BuildContext context,
    User? loggedInUser, {
    User? user,
    Group? group,
  }) {
    if (user != null || group != null) {
      ConvoKitDetailsTemplate? primaryTemplate = getPrimaryDetailsTemplate(
        context,
        loggedInUser,
        user,
        group,
      );
      ConvoKitDetailsTemplate? secondaryTemplate = getSecondaryDetailsTemplate(
        context,
        loggedInUser,
        user,
        group,
      );
      return [?primaryTemplate, ?secondaryTemplate];
    } else {
      return [];
    }
  }

  static TextStyle _getPrimaryGroupOptionTextStyle() {
    return const TextStyle(color: Color(0xff000000));
  }

  static TextStyle _getSecondaryGroupOptionTextStyle() {
    return const TextStyle(color: Color(0xffFF3B30));
  }

  static TextStyle _getPrimaryOptionTextStyle() {
    return const TextStyle(color: Color(0xff3399FF));
  }

  static dynamic validateDetailOptions({
    required String loggedInUserScope,
    required String optionId,
  }) {
    return _allowedDetailOptions[loggedInUserScope]?[optionId];
  }

  static dynamic validateGroupMemberOptions({
    required String loggedInUserScope,
    String memberScope = GroupMemberScope.participant,
    required String optionId,
  }) {
    return _allowedGroupMemberOptions[loggedInUserScope +
        memberScope]?[optionId];
  }

  static final Map<String, Map<String, dynamic>> _allowedDetailOptions = {
    GroupMemberScope.participant: {
      GroupOptionConstants.addMembers: false, //Details
      GroupOptionConstants.delete: false, //Details
      GroupOptionConstants.leave: true, //Details
      GroupOptionConstants.bannedMembers: false, //Details
      GroupOptionConstants.viewMembers: true, //Details
    },
    GroupMemberScope.moderator: {
      GroupOptionConstants.addMembers: false,
      GroupOptionConstants.delete: false,
      GroupOptionConstants.leave: true,
      GroupOptionConstants.bannedMembers: true,
      GroupOptionConstants.viewMembers: true,
    },
    GroupMemberScope.admin: {
      GroupOptionConstants.addMembers: true,
      GroupOptionConstants.delete: true,
      GroupOptionConstants.leave: true,
      GroupOptionConstants.bannedMembers: true,
      GroupOptionConstants.viewMembers: true,
    },
    GroupMemberScope.owner: {
      GroupOptionConstants.addMembers: true,
      GroupOptionConstants.delete: true,
      GroupOptionConstants.leave: true,
      GroupOptionConstants.bannedMembers: true,
      GroupOptionConstants.viewMembers: true,
    },
  };

  static final Map<String, Map<String, dynamic>> _allowedGroupMemberOptions = {
    GroupMemberScope.participant + GroupMemberScope.participant: {
      GroupMemberOptionConstants.kick: false, //GroupMembers
      GroupMemberOptionConstants.ban: false, //GroupMembers
      GroupMemberOptionConstants.unban: false, //Banned Members
      GroupMemberOptionConstants.changeScope: <String>[], //GroupMembers
    },
    GroupMemberScope.participant + GroupMemberScope.moderator: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: false,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.participant + GroupMemberScope.admin: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: false,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.participant + GroupMemberScope.owner: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: false,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.moderator + GroupMemberScope.participant: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: [
        GroupMemberScope.participant,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.moderator + GroupMemberScope.moderator: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.moderator + GroupMemberScope.admin: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.moderator + GroupMemberScope.owner: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.admin + GroupMemberScope.participant: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.admin + GroupMemberScope.moderator: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.admin + GroupMemberScope.admin: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.admin + GroupMemberScope.owner: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
    GroupMemberScope.owner + GroupMemberScope.participant: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.owner + GroupMemberScope.moderator: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.owner + GroupMemberScope.admin: {
      GroupMemberOptionConstants.kick: true,
      GroupMemberOptionConstants.ban: true,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[
        GroupMemberScope.participant,
        GroupMemberScope.admin,
        GroupMemberScope.moderator,
      ],
    },
    GroupMemberScope.owner + GroupMemberScope.owner: {
      GroupMemberOptionConstants.kick: false,
      GroupMemberOptionConstants.ban: false,
      GroupMemberOptionConstants.unban: true,
      GroupMemberOptionConstants.changeScope: <String>[],
    },
  };

  static bool validateUserOptions(User? loggedInUser, User? user, String id) {
    if (user?.uid == loggedInUser?.uid && id == UserOptionConstants.blockUser) {
      return false;
    } else if ((user?.blockedByMe == true) &&
        id == UserOptionConstants.blockUser) {
      return false;
    } else if ((user?.blockedByMe == false || user?.blockedByMe == null) &&
        id == UserOptionConstants.unblockUser) {
      return false;
    }

    return true;
  }
}
