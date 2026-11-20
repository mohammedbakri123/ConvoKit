import '../../../../convokit_uikit_shared.dart';
import 'package:flutter/material.dart';

abstract class ConvoKitGroupMembersControllerProtocol
    extends CometChatSearchListControllerProtocol<GroupMember> {
  //default functions
  List<CometChatOption> defaultFunction(
    Group group,
    GroupMember member,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  );
}
