import '../../../../convokit_uikit_shared.dart';
import 'package:flutter/material.dart';

abstract class ConvoKitGroupMembersControllerProtocol
    extends CometChatSearchListControllerProtocol<ChatMember> {
  //default functions
  List<CometChatOption> defaultFunction(
    ChatGroup group,
    ChatMember member,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  );
}
