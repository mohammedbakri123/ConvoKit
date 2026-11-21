import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart';
import '../../presentation/theme/theme/cometchat_theme_helper.dart';

class StatusIndicatorUtils {
  StatusIndicatorUtils({this.icon, this.statusIndicatorColor});

  static StatusIndicatorUtils getStatusIndicatorFromParams({
    required BuildContext context,
    bool? isSelected,
    ChatUser? user,
    ChatGroup? group,
    ChatMember? groupMember,
    Widget? protectedGroupIcon,
    Widget? privateGroupIcon,
    Color? onlineStatusIndicatorColor,
    Color? privateGroupIconBackground,
    Color? protectedGroupIconBackground,
    bool? usersStatusVisibility,
    bool? groupTypeVisibility,
    Widget? selectIcon,
    Color? selectIconTint,
  }) {
    Color? backgroundColor;
    Widget? icon;
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    if (isSelected == true) {
      icon =
          selectIcon ??
          Icon(Icons.check, color: selectIconTint ?? Colors.white, size: 12);
    } else if (user != null && usersStatusVisibility == true) {
      backgroundColor = user.presence == UserPresence.online
          ? onlineStatusIndicatorColor
          : null;
    } else if (group != null && groupTypeVisibility == true) {
      if (group.type == GroupType.passwordProtected) {
        backgroundColor = protectedGroupIconBackground ?? colorPalette.success;
        icon =
            protectedGroupIcon ??
            Icon(Icons.lock, color: colorPalette.background1, size: 7);
      } else if (group.type == GroupType.private) {
        backgroundColor = privateGroupIconBackground ?? colorPalette.warning;
        icon =
            privateGroupIcon ??
            Icon(Icons.shield, color: colorPalette.background1, size: 7);
      }
    } else if (groupMember != null && usersStatusVisibility == true) {
      backgroundColor = groupMember.user.presence == UserPresence.online
          ? onlineStatusIndicatorColor
          : null;
    }
    return StatusIndicatorUtils(
      icon: icon,
      statusIndicatorColor: backgroundColor,
    );
  }

  Widget? icon;
  Color? statusIndicatorColor;
}
