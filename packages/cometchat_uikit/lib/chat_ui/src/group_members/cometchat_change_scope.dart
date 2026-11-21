import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// [ConvoKitChangeScope] is a stateful widget which allows changing the role
/// (scope) of a [ChatMember] in a [ChatGroup].
///
/// When rendered inside a [ConvoKitScope] with `capabilities.groups == false`
/// or `kit.groups == null`, renders [SizedBox.shrink] cleanly.
class ConvoKitChangeScope extends StatefulWidget {
  const ConvoKitChangeScope({
    super.key,
    required this.group,
    required this.member,
    this.onSave,
    this.style,
    this.padding,
  });

  final ChatGroup group;
  final ChatMember member;

  final Future<void> Function(
    ChatGroup group,
    ChatMember member,
    String newScope,
    String oldScope,
  )?
  onSave;

  final ConvoKitChangeScopeStyle? style;
  final EdgeInsetsGeometry? padding;

  @override
  State<ConvoKitChangeScope> createState() => _ConvoKitChangeScopeState();
}

class _ConvoKitChangeScopeState extends State<ConvoKitChangeScope> {
  List<String> scopes = ['Admin', 'Moderator', 'Participant'];
  late String? selectedScope;
  late String _initialScope;
  ConvoKit? _kit;

  late ConvoKitColorPalette colorPalette;
  late ConvoKitTypography typography;
  late ConvoKitSpacing spacing;
  late ConvoKitChangeScopeStyle style;

  static String _roleToScope(GroupRole role) {
    switch (role) {
      case GroupRole.owner:
        return GroupMemberScope.owner;
      case GroupRole.admin:
        return GroupMemberScope.admin;
      case GroupRole.member:
        return GroupMemberScope.participant;
    }
  }

  @override
  void initState() {
    _initialScope = _roleToScope(widget.member.role);
    selectedScope = _initialScope;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    try {
      _kit = ConvoKitScope.of(context);
    } on StateError {
      _kit = null;
    }
    colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    typography = ConvoKitThemeHelper.getTypography(context);
    spacing = ConvoKitThemeHelper.getSpacing(context);
    style = ConvoKitThemeHelper.getTheme<ConvoKitChangeScopeStyle>(
      context: context,
      defaultTheme: ConvoKitChangeScopeStyle.of,
    ).merge(widget.style);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (_kit != null && (!_kit!.capabilities.groups || _kit!.groups == null)) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius:
          style.borderRadius ??
          BorderRadius.only(
            topLeft: Radius.circular(spacing.radius5 ?? 0),
            topRight: Radius.circular(spacing.radius5 ?? 0),
          ),
      child: Container(
        padding:
            widget.padding ??
            EdgeInsets.fromLTRB(
              spacing.padding5 ?? 0,
              spacing.padding9 ?? 0,
              spacing.padding5 ?? 0,
              spacing.padding5 ?? 0,
            ),
        decoration: BoxDecoration(
          color: style.backgroundColor ?? colorPalette.background1,
          border: style.border,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(spacing.radius5 ?? 0),
            topRight: Radius.circular(spacing.radius5 ?? 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.padding4 ?? 0),
              decoration: BoxDecoration(
                color: style.iconBackgroundColor ?? Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                AssetConstants.changeScope96px,
                package: UIConstants.packageName,
                height: 48,
                width: 48,
                color: style.iconColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              Translations.of(context).changeScope,
              style: TextStyle(
                fontSize: typography.heading2?.medium?.fontSize,
                fontWeight: typography.heading2?.medium?.fontWeight,
                fontFamily: typography.heading2?.medium?.fontFamily,
                color: colorPalette.textPrimary,
              ).merge(style.titleTextStyle),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.padding10 ?? 0),
              child: Text(
                Translations.of(context).changeScopeSubtitle,
                style: TextStyle(
                  fontSize: typography.body?.regular?.fontSize,
                  fontWeight: typography.body?.regular?.fontWeight,
                  fontFamily: typography.body?.regular?.fontFamily,
                  color: colorPalette.textSecondary,
                ).merge(style.subtitleTextStyle),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border:
                    style.scopeSectionBorder ??
                    Border.all(
                      color: colorPalette.borderLight ?? Colors.transparent,
                      width: 1,
                    ),
                borderRadius: BorderRadius.circular(spacing.radius2 ?? 0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < scopes.length; i++)
                    _buildScopeTile(
                      i,
                      style,
                      colorPalette,
                      typography,
                      spacing,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: spacing.padding2 ?? 0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          style.cancelButtonBackgroundColor,
                        ),
                        side: WidgetStateProperty.all(
                          style.cancelButtonBorder ??
                              BorderSide(
                                color:
                                    colorPalette.borderDark ??
                                    Colors.transparent,
                                width: 1,
                              ),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            side:
                                style.cancelButtonBorder ??
                                BorderSide(
                                  color:
                                      colorPalette.borderDark ??
                                      Colors.transparent,
                                  width: 1,
                                ),
                            borderRadius:
                                style.cancelButtonBorderRadius ??
                                BorderRadius.all(
                                  Radius.circular(spacing.radius2 ?? 0),
                                ),
                          ),
                        ),
                      ),
                      child: Text(
                        Translations.of(context).cancel,
                        style: TextStyle(
                          fontSize: typography.button?.medium?.fontSize,
                          fontWeight: typography.button?.medium?.fontWeight,
                          fontFamily: typography.button?.medium?.fontFamily,
                          color: colorPalette.textPrimary,
                        ).merge(style.cancelButtonTextStyle),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (selectedScope != null) {
                        if (_initialScope == selectedScope) return;
                        if (widget.onSave != null) {
                          try {
                            await widget.onSave!(
                              widget.group,
                              widget.member,
                              selectedScope!,
                              _initialScope,
                            );
                          } catch (_) {}
                        }
                      }
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        style.saveButtonBackgroundColor ??
                            ((_initialScope == selectedScope)
                                ? colorPalette.neutral300
                                : colorPalette.buttonBackground),
                      ),
                      side: WidgetStateProperty.all(
                        style.saveButtonBorder ??
                            BorderSide(
                              color:
                                  ((_initialScope == selectedScope)
                                      ? colorPalette.neutral300
                                      : colorPalette.borderHighlight) ??
                                  Colors.transparent,
                              width: 1,
                            ),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          side:
                              style.saveButtonBorder ??
                              BorderSide(
                                color:
                                    colorPalette.borderDark ??
                                    Colors.transparent,
                                width: 1,
                              ),
                          borderRadius:
                              style.saveButtonBorderRadius ??
                              BorderRadius.all(
                                Radius.circular(spacing.radius2 ?? 0),
                              ),
                        ),
                      ),
                    ),
                    child: Text(
                      Translations.of(context).save,
                      style: TextStyle(
                        fontSize: typography.button?.medium?.fontSize,
                        fontWeight: typography.button?.medium?.fontWeight,
                        fontFamily: typography.button?.medium?.fontFamily,
                        color: colorPalette.white,
                      ).merge(style.saveButtonTextStyle),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTile(
    int index,
    ConvoKitChangeScopeStyle style,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  ) {
    final isSelected = scopes[index].toLowerCase() == selectedScope;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isSelected
            ? (style.selectedTileColor ?? colorPalette.borderLight)
            : (style.tileColor ?? colorPalette.background1),
        borderRadius: BorderRadius.only(
          topLeft: index == 0
              ? Radius.circular(spacing.radius2 ?? 0)
              : Radius.zero,
          topRight: index == 0
              ? Radius.circular(spacing.radius2 ?? 0)
              : Radius.zero,
          bottomLeft: index == scopes.length - 1
              ? Radius.circular(spacing.radius2 ?? 0)
              : Radius.zero,
          bottomRight: index == scopes.length - 1
              ? Radius.circular(spacing.radius2 ?? 0)
              : Radius.zero,
        ),
      ),
      child: ListTile(
        title: Text(
          scopes[index],
          style:
              TextStyle(
                color: isSelected
                    ? colorPalette.textPrimary
                    : colorPalette.textSecondary,
                fontSize: typography.body?.medium?.fontSize,
                fontWeight: typography.body?.medium?.fontWeight,
                fontFamily: typography.body?.medium?.fontFamily,
              ).merge(
                isSelected
                    ? style.selectedScopeTextStyle
                    : style.scopeTextStyle,
              ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.padding4 ?? 0),
        minVerticalPadding: 0,
        selected: isSelected,
        trailing: Transform.scale(
          scale: 1.2,
          origin: const Offset(-10, 0),
          child: Radio<String>(
            value: scopes[index].toLowerCase(),
            // ignore: deprecated_member_use
            groupValue: selectedScope,
            fillColor: WidgetStatePropertyAll(
              isSelected
                  ? (style.radioButtonSelectedColor ??
                        colorPalette.borderHighlight)
                  : (style.radioButtonColor ?? colorPalette.borderDefault),
            ),
            // ignore: deprecated_member_use
            onChanged: (String? value) {
              setState(() {
                selectedScope = value?.toLowerCase();
              });
            },
          ),
        ),
      ),
    );
  }
}
