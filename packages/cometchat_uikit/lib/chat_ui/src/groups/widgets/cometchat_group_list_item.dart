import 'package:flutter/material.dart';
import '../../../../convokit_uikit.dart';

/// [CometChatGroupListItem] displays a single [ChatGroup] list item.
class CometChatGroupListItem extends StatelessWidget {
  const CometChatGroupListItem({
    super.key,
    required this.group,
    required this.onItemClick,
    this.onItemLongClick,
    this.onSelectionToggle,
    this.isSelected = false,
    this.selectionMode = SelectionMode.none,
    this.hideGroupTypeIcon = false,
    this.style,
    this.avatarStyle,
    this.statusIndicatorStyle,
    this.avatarHeight,
    this.avatarWidth,
    this.avatarPadding,
    this.avatarMargin,
    this.statusIndicatorHeight,
    this.statusIndicatorWidth,
    this.statusIndicatorBorderRadius,
    this.leadingView,
    this.titleView,
    this.subtitleView,
    this.trailingView,
    this.colorPalette,
    this.spacing,
    this.typography,
    this.privateGroupIcon,
    this.protectedGroupIcon,
    this.privateGroupIconBackground,
    this.protectedGroupIconBackground,
  });

  final ChatGroup group;
  final Function(ChatGroup) onItemClick;
  final Function(ChatGroup)? onItemLongClick;
  final VoidCallback? onSelectionToggle;
  final bool isSelected;
  final SelectionMode selectionMode;
  final bool hideGroupTypeIcon;
  final CometChatGroupListItemStyle? style;
  final ConvoKitAvatarStyle? avatarStyle;
  final ConvoKitStatusIndicatorStyle? statusIndicatorStyle;
  final double? avatarHeight;
  final double? avatarWidth;
  final EdgeInsetsGeometry? avatarPadding;
  final EdgeInsetsGeometry? avatarMargin;
  final double? statusIndicatorHeight;
  final double? statusIndicatorWidth;
  final BorderRadiusGeometry? statusIndicatorBorderRadius;
  final Widget? Function(ChatGroup)? leadingView;
  final Widget? Function(ChatGroup)? titleView;
  final Widget? Function(ChatGroup)? subtitleView;
  final Widget? Function(ChatGroup)? trailingView;
  final ConvoKitColorPalette? colorPalette;
  final ConvoKitSpacing? spacing;
  final ConvoKitTypography? typography;
  final Widget? privateGroupIcon;
  final Widget? protectedGroupIcon;
  final Color? privateGroupIconBackground;
  final Color? protectedGroupIconBackground;

  @override
  Widget build(BuildContext context) {
    final effectiveColorPalette =
        colorPalette ?? ConvoKitThemeHelper.getColorPalette(context);
    final effectiveSpacing =
        spacing ?? ConvoKitThemeHelper.getSpacing(context);
    final effectiveTypography =
        typography ?? ConvoKitThemeHelper.getTypography(context);
    final effectiveStyle =
        style ?? CometChatGroupListItemStyle.fromTheme(context);

    final backgroundColor = isSelected
        ? (effectiveStyle.selectedBackgroundColor ??
              effectiveColorPalette.background4)
        : (effectiveStyle.backgroundColor ?? effectiveColorPalette.background1);

    return Semantics(
      label: _buildAccessibilityLabel(context),
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onItemClick(group),
        onLongPress: onItemLongClick != null
            ? () => onItemLongClick!(group)
            : null,
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.symmetric(
            horizontal: effectiveSpacing.padding4 ?? 16,
            vertical: effectiveSpacing.padding3 ?? 12,
          ),
          child: Row(
            children: [
              if (selectionMode != SelectionMode.none)
                _buildSelectionCheckbox(
                  effectiveStyle,
                  effectiveColorPalette,
                  effectiveSpacing,
                ),
              _buildLeadingView(
                context,
                effectiveStyle,
                effectiveColorPalette,
                effectiveSpacing,
                effectiveTypography,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitleView(
                      context,
                      effectiveStyle,
                      effectiveColorPalette,
                      effectiveTypography,
                    ),
                    const SizedBox(height: 2),
                    _buildSubtitleView(
                      context,
                      effectiveStyle,
                      effectiveColorPalette,
                      effectiveTypography,
                    ),
                  ],
                ),
              ),
              _buildTrailingView(
                context,
                effectiveStyle,
                effectiveColorPalette,
                effectiveTypography,
                effectiveSpacing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildAccessibilityLabel(BuildContext context) {
    final parts = <String>[group.name];

    final memberCount = group.memberCount;
    if (memberCount > 0) {
      parts.add('$memberCount ${memberCount == 1 ? 'member' : 'members'}');
    }

    switch (group.type) {
      case GroupType.private:
        parts.add('private group');
      case GroupType.passwordProtected:
        parts.add('password protected group');
      case GroupType.public:
        parts.add('public group');
    }

    if (isSelected) parts.add('selected');

    return parts.join(', ');
  }

  Widget _buildSelectionCheckbox(
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
    ConvoKitSpacing effectiveSpacing,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        left: effectiveSpacing.padding3 ?? 12,
        right: effectiveSpacing.padding2 ?? 8,
      ),
      child: SizedBox(
        width: 20,
        height: 20,
        child: Checkbox(
          value: isSelected,
          onChanged: (value) => onSelectionToggle?.call(),
          checkColor: effectiveStyle.checkBoxCheckColor,
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return effectiveStyle.checkBoxCheckedBackgroundColor ??
                  effectiveColorPalette.primary;
            }
            return effectiveStyle.checkBoxBackgroundColor ?? Colors.transparent;
          }),
          shape: RoundedRectangleBorder(
            borderRadius:
                effectiveStyle.checkBoxBorderRadius ??
                BorderRadius.circular(effectiveSpacing.radius1 ?? 4),
          ),
          side: BorderSide(
            color:
                effectiveStyle.checkBoxStrokeColor ??
                effectiveColorPalette.borderDefault ??
                Colors.grey,
            width: effectiveStyle.checkBoxStrokeWidth ?? 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingView(
    BuildContext context,
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
    ConvoKitSpacing effectiveSpacing,
    ConvoKitTypography effectiveTypography,
  ) {
    if (leadingView != null) {
      final customView = leadingView!(group);
      if (customView != null) {
        return Padding(
          padding: EdgeInsets.only(right: effectiveSpacing.padding3 ?? 12),
          child: customView,
        );
      }
    }

    final effectiveAvatarStyle =
        (avatarStyle ??
                effectiveStyle.avatarStyle ??
                const ConvoKitAvatarStyle())
            .copyWith(
              placeHolderTextStyle: TextStyle(
                fontSize: effectiveTypography.heading2?.bold?.fontSize,
                fontWeight: effectiveTypography.heading2?.bold?.fontWeight,
                fontFamily: effectiveTypography.heading2?.bold?.fontFamily,
              ),
            );

    return Padding(
      padding: EdgeInsets.only(right: effectiveSpacing.padding3 ?? 12),
      child: Stack(
        children: [
          ConvoKitAvatar(
            image: group.avatarUrl,
            name: group.name,
            height: avatarHeight ?? 48,
            width: avatarWidth ?? 48,
            padding: avatarPadding,
            margin: avatarMargin,
            style: effectiveAvatarStyle,
          ),
          if (_shouldShowStatusIndicator())
            Positioned(
              right: 0,
              bottom: 0,
              child: ConvoKitStatusIndicator(
                height: statusIndicatorHeight ?? 14,
                width: statusIndicatorWidth ?? 14,
                backgroundImage: _getStatusIndicatorIcon(effectiveColorPalette),
                style: ConvoKitStatusIndicatorStyle(
                  borderRadius:
                      statusIndicatorBorderRadius ??
                      statusIndicatorStyle?.borderRadius ??
                      effectiveStyle.statusIndicatorStyle?.borderRadius,
                  border:
                      statusIndicatorStyle?.border ??
                      effectiveStyle.statusIndicatorStyle?.border ??
                      Border.all(
                        width: effectiveSpacing.spacing ?? 0,
                        color:
                            effectiveColorPalette.background1 ??
                            Colors.transparent,
                      ),
                  backgroundColor: _getStatusIndicatorBackgroundColor(
                    effectiveStyle,
                    effectiveColorPalette,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleView(
    BuildContext context,
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
    ConvoKitTypography effectiveTypography,
  ) {
    if (titleView != null) {
      final customView = titleView!(group);
      if (customView != null) {
        return customView;
      }
    }

    return Text(
      group.name,
      style:
          (effectiveStyle.titleTextStyle ??
                  effectiveTypography.heading4?.medium)
              ?.copyWith(
                color:
                    effectiveStyle.titleTextColor ??
                    effectiveColorPalette.textPrimary,
              ),
      maxLines: scaledMaxLines(context),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitleView(
    BuildContext context,
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
    ConvoKitTypography effectiveTypography,
  ) {
    if (subtitleView != null) {
      final customView = subtitleView!(group);
      if (customView != null) {
        return customView;
      }
    }

    final memberCount = group.memberCount;
    final memberText =
        '$memberCount ${memberCount == 1 ? Translations.of(context).member : Translations.of(context).members}';

    return Text(
      memberText,
      style:
          (effectiveStyle.subtitleTextStyle ??
                  effectiveTypography.body?.regular)
              ?.copyWith(
                color:
                    effectiveStyle.subtitleTextColor ??
                    effectiveColorPalette.textSecondary,
              ),
      maxLines: scaledMaxLines(context),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTrailingView(
    BuildContext context,
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
    ConvoKitTypography effectiveTypography,
    ConvoKitSpacing effectiveSpacing,
  ) {
    if (trailingView != null) {
      final customView = trailingView!(group);
      if (customView != null) {
        return Padding(
          padding: EdgeInsets.only(left: effectiveSpacing.padding2 ?? 8),
          child: customView,
        );
      }
    }

    return const SizedBox.shrink();
  }

  bool _shouldShowStatusIndicator() {
    if (hideGroupTypeIcon) return false;
    return group.type == GroupType.private ||
        group.type == GroupType.passwordProtected;
  }

  Color? _getStatusIndicatorBackgroundColor(
    CometChatGroupListItemStyle effectiveStyle,
    ConvoKitColorPalette effectiveColorPalette,
  ) {
    final fromStatusStyle =
        statusIndicatorStyle?.backgroundColor ??
        effectiveStyle.statusIndicatorStyle?.backgroundColor;
    if (group.type == GroupType.passwordProtected) {
      return protectedGroupIconBackground ??
          effectiveStyle.protectedGroupIconBackground ??
          fromStatusStyle ??
          effectiveColorPalette.success ??
          Colors.green;
    } else if (group.type == GroupType.private) {
      return privateGroupIconBackground ??
          effectiveStyle.privateGroupIconBackground ??
          fromStatusStyle ??
          effectiveColorPalette.warning ??
          Colors.yellow;
    }
    return fromStatusStyle;
  }

  Widget? _getStatusIndicatorIcon(ConvoKitColorPalette effectiveColorPalette) {
    if (group.type == GroupType.private) {
      if (privateGroupIcon != null) {
        return privateGroupIcon;
      }
      return Icon(
        Icons.shield,
        color: effectiveColorPalette.background1 ?? Colors.white,
        size: 7,
      );
    } else if (group.type == GroupType.passwordProtected) {
      if (protectedGroupIcon != null) {
        return protectedGroupIcon;
      }
      return Icon(
        Icons.lock,
        color: effectiveColorPalette.background1 ?? Colors.white,
        size: 7,
      );
    }
    return null;
  }
}

/// Style configuration for [CometChatGroupListItem].
@immutable
class CometChatGroupListItemStyle {
  const CometChatGroupListItemStyle({
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.titleTextStyle,
    this.titleTextColor,
    this.subtitleTextStyle,
    this.subtitleTextColor,
    this.avatarStyle,
    this.statusIndicatorStyle,
    this.checkBoxBackgroundColor,
    this.checkBoxCheckedBackgroundColor,
    this.checkBoxBorderRadius,
    this.checkBoxStrokeColor,
    this.checkBoxStrokeWidth,
    this.checkBoxCheckColor,
    this.privateGroupIconBackground,
    this.protectedGroupIconBackground,
  });

  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final TextStyle? titleTextStyle;
  final Color? titleTextColor;
  final TextStyle? subtitleTextStyle;
  final Color? subtitleTextColor;
  final ConvoKitAvatarStyle? avatarStyle;
  final ConvoKitStatusIndicatorStyle? statusIndicatorStyle;
  final Color? checkBoxBackgroundColor;
  final Color? checkBoxCheckedBackgroundColor;
  final BorderRadius? checkBoxBorderRadius;
  final Color? checkBoxStrokeColor;
  final double? checkBoxStrokeWidth;
  final Color? checkBoxCheckColor;
  final Color? privateGroupIconBackground;
  final Color? protectedGroupIconBackground;

  factory CometChatGroupListItemStyle.fromTheme(BuildContext context) {
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);

    return CometChatGroupListItemStyle(
      backgroundColor: colorPalette.background1,
      selectedBackgroundColor: colorPalette.background4,
      titleTextStyle: typography.heading4?.medium,
      titleTextColor: colorPalette.textPrimary,
      subtitleTextStyle: typography.body?.regular,
      subtitleTextColor: colorPalette.textSecondary,
      checkBoxCheckedBackgroundColor: colorPalette.primary,
      checkBoxStrokeColor: colorPalette.borderDefault,
    );
  }

  CometChatGroupListItemStyle copyWith({
    Color? backgroundColor,
    Color? selectedBackgroundColor,
    TextStyle? titleTextStyle,
    Color? titleTextColor,
    TextStyle? subtitleTextStyle,
    Color? subtitleTextColor,
    ConvoKitAvatarStyle? avatarStyle,
    ConvoKitStatusIndicatorStyle? statusIndicatorStyle,
    Color? checkBoxBackgroundColor,
    Color? checkBoxCheckedBackgroundColor,
    BorderRadius? checkBoxBorderRadius,
    Color? checkBoxStrokeColor,
    double? checkBoxStrokeWidth,
    Color? checkBoxCheckColor,
    Color? privateGroupIconBackground,
    Color? protectedGroupIconBackground,
  }) {
    return CometChatGroupListItemStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      titleTextColor: titleTextColor ?? this.titleTextColor,
      subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
      subtitleTextColor: subtitleTextColor ?? this.subtitleTextColor,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      statusIndicatorStyle: statusIndicatorStyle ?? this.statusIndicatorStyle,
      checkBoxBackgroundColor:
          checkBoxBackgroundColor ?? this.checkBoxBackgroundColor,
      checkBoxCheckedBackgroundColor:
          checkBoxCheckedBackgroundColor ?? this.checkBoxCheckedBackgroundColor,
      checkBoxBorderRadius: checkBoxBorderRadius ?? this.checkBoxBorderRadius,
      checkBoxStrokeColor: checkBoxStrokeColor ?? this.checkBoxStrokeColor,
      checkBoxStrokeWidth: checkBoxStrokeWidth ?? this.checkBoxStrokeWidth,
      checkBoxCheckColor: checkBoxCheckColor ?? this.checkBoxCheckColor,
      privateGroupIconBackground:
          privateGroupIconBackground ?? this.privateGroupIconBackground,
      protectedGroupIconBackground:
          protectedGroupIconBackground ?? this.protectedGroupIconBackground,
    );
  }

  CometChatGroupListItemStyle merge(CometChatGroupListItemStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      selectedBackgroundColor: other.selectedBackgroundColor,
      titleTextStyle: other.titleTextStyle,
      titleTextColor: other.titleTextColor,
      subtitleTextStyle: other.subtitleTextStyle,
      subtitleTextColor: other.subtitleTextColor,
      avatarStyle: other.avatarStyle,
      statusIndicatorStyle: other.statusIndicatorStyle,
      checkBoxBackgroundColor: other.checkBoxBackgroundColor,
      checkBoxCheckedBackgroundColor: other.checkBoxCheckedBackgroundColor,
      checkBoxBorderRadius: other.checkBoxBorderRadius,
      checkBoxStrokeColor: other.checkBoxStrokeColor,
      checkBoxStrokeWidth: other.checkBoxStrokeWidth,
      checkBoxCheckColor: other.checkBoxCheckColor,
      privateGroupIconBackground: other.privateGroupIconBackground,
      protectedGroupIconBackground: other.protectedGroupIconBackground,
    );
  }

  static CometChatGroupListItemStyle of(BuildContext context) {
    return CometChatGroupListItemStyle.fromTheme(context);
  }
}
