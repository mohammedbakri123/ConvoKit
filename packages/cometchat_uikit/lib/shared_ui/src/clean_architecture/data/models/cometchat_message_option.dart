import 'package:flutter/material.dart';
import "package:cometchat_sdk/cometchat_sdk.dart" hide CardMessage;
import '../../../../convokit_uikit_shared.dart'
    show
        ConvoKitMessageListControllerProtocol,
        ConvoKitMessageOptionSheetStyle,
        CometChatAttachmentOptionSheetStyle;
import 'action_item.dart';

///Model class for message options
///
///```dart
/// CometChatMessageOption(
///  id: 'id',
///  title: 'title',
///  icon: Icon(Icons.favorite),
///  messageOptionSheetStyle: ConvoKitMessageOptionSheetStyle(
///  backgroundColor: Colors.white,
///  ),
///  onClick: (BaseMessage baseMessage,
///      ConvoKitMessageListController state) {}
///  )
/// ```

class CometChatMessageOption {
  ///[CometChatMessageOption] constructor requires [id] and [title] while initializing.
  CometChatMessageOption({
    required this.id,
    required this.title,
    this.icon,
    this.onItemClick,
    this.messageOptionSheetStyle,
  });

  ///[id] of the option
  String id;

  ///[title] of the option
  String title;

  ///[icon] of the option
  Widget? icon;

  ///[onItemClick] of the option
  Function(BaseMessage message, ConvoKitMessageListControllerProtocol state)?
  onItemClick;

  ///[messageOptionSheetStyle] is a [ConvoKitMessageOptionSheetStyle] that can be used to style message option sheet
  final ConvoKitMessageOptionSheetStyle? messageOptionSheetStyle;

  ///[toActionItem] converts [CometChatMessageOption] to [ActionItem]
  ActionItem toActionItem() {
    return ActionItem(
      id: id,
      title: title,
      icon: icon,
      onItemClick: onItemClick,
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: messageOptionSheetStyle?.titleTextStyle,
        iconColor: messageOptionSheetStyle?.iconColor,
        backgroundColor: messageOptionSheetStyle?.backgroundColor,
        border: messageOptionSheetStyle?.border,
        borderRadius: messageOptionSheetStyle?.borderRadius,
        titleColor: messageOptionSheetStyle?.titleColor,
      ),
    );
  }

  ///[toActionItemFromFunction] takes a function as parameter and converts [CometChatMessageOption] to [ActionItem] with the function `onClick` as onItemClick
  ActionItem toActionItemFromFunction(
    Function(BaseMessage message, ConvoKitMessageListControllerProtocol state)?
    passedFunction,
  ) {
    return ActionItem(
      id: id,
      title: title,
      icon: icon,
      onItemClick: passedFunction,
      style: CometChatAttachmentOptionSheetStyle(
        titleTextStyle: messageOptionSheetStyle?.titleTextStyle,
        iconColor: messageOptionSheetStyle?.iconColor,
        backgroundColor: messageOptionSheetStyle?.backgroundColor,
        border: messageOptionSheetStyle?.border,
        borderRadius: messageOptionSheetStyle?.borderRadius,
        titleColor: messageOptionSheetStyle?.titleColor,
      ),
    );
  }
}
