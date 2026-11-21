import 'package:flutter/material.dart';
import 'package:convokit/src/core/models/models.dart'
    show ChatUser, ChatGroup;
import 'cometchat_details_option.dart';

///[ConvoKitDetailsTemplate] is the section of options displayed in `ConvoKitDetails`
///
/// ```dart
///
/// ConvoKitDetailsTemplate(
///   id: "user-details",
///   options: (user, group, context, theme) {
///     return [
///       ConvoKitDetailsOption(
///         id: "user-details-name",
///         title: "Name",
///         customView: Text(user?.name ?? ""),
///       ),
///       ConvoKitDetailsOption(
///         id: "user-details-username",
///         title: "Username",
///         customView: Text(user?.name ?? ""),
///       ),
///     ];
///   },
///   title: "ChatUser Details",
///   titleStyle: TextStyle(
///     fontSize: 18,
///     fontWeight: FontWeight.bold,
///   ),
///   sectionSeparatorColor: Colors.grey[300],
///   hideSectionSeparator: false,
///   itemSeparatorColor: Colors.grey[200],
///   hideItemSeparator: false,
/// )
///
/// ```
class ConvoKitDetailsTemplate {
  ///[id] is unique identifier for every [ConvoKitDetailsTemplate]
  final String id;

  ///[options] is a function which returns list of [ConvoKitDetailsOption] for every [ConvoKitDetailsTemplate]
  final List<ConvoKitDetailsOption> Function(
    ChatUser? user,
    ChatGroup? group,
    BuildContext? context,
  )?
  options;

  ///[title] is the title of [ConvoKitDetailsTemplate]
  final String? title;

  ///[titleStyle] is the style of [title] of [ConvoKitDetailsTemplate]
  final TextStyle? titleStyle;

  ///[sectionSeparatorColor] is the color of section separator
  final Color? sectionSeparatorColor;

  ///[hideSectionSeparator] is a boolean which decides whether to hide section separator or not
  final bool? hideSectionSeparator;

  ///[itemSeparatorColor] is the color of item separator
  final Color? itemSeparatorColor;

  ///[hideItemSeparator] is a boolean which decides whether to hide item separator or not
  final bool? hideItemSeparator;

  ///[ConvoKitDetailsTemplate] constructor requires [id] and [options] while initializing.
  const ConvoKitDetailsTemplate({
    required this.id,
    this.options,
    this.title,
    this.titleStyle,
    this.sectionSeparatorColor,
    this.hideSectionSeparator,
    this.itemSeparatorColor,
    this.hideItemSeparator,
  });

  @override
  String toString() {
    return 'ConvoKitDetailsTemplate{id: $id, options: $options, title: $title, titleStyle: $titleStyle, sectionSeparatorColor: $sectionSeparatorColor, hideSectionSeparator: $hideSectionSeparator, itemSeparatorColor: $itemSeparatorColor, hideItemSeparator: $hideItemSeparator}';
  }
}
