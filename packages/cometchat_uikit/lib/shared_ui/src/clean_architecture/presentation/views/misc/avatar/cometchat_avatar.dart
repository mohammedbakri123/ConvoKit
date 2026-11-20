import 'package:flutter/material.dart';
import '../../../../../../convokit_uikit_shared.dart';

///[ConvoKitAvatar] is a widget that gives a container for avatar images
/// ```dart
///        ConvoKitAvatar(
///        image: 'https://example.com/image.jpg',
///        name: 'John Doe',
///        cometchatAvatarStyle: ConvoKitAvatarStyle(),
///        width: 50,
///        height: 50,
///        padding: EdgeInsets.all(0),
///        );
/// ```
class ConvoKitAvatar extends StatefulWidget {
  const ConvoKitAvatar({
    super.key,
    this.image,
    this.name,
    this.style,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.colorPalette,
    this.spacing,
    this.typography,
  });

  ///[image] sets the image url  for the avatar ,  will be preferred over name
  final String? image;

  ///[name] only visible when [image] tag is not passed
  final String? name;

  ///[style] contains properties that affects the appearance of this widget
  final ConvoKitAvatarStyle? style;

  ///[width] provides width to the widget
  final double? width;

  ///[height] provides height to the widget
  final double? height;

  /// [padding] provides padding to the widget
  final EdgeInsetsGeometry? padding;

  /// [padding] provides margin to the widget
  final EdgeInsetsGeometry? margin;

  /// [colorPalette] optional pre-cached color palette to avoid expensive lookups during keyboard animation
  final ConvoKitColorPalette? colorPalette;

  /// [spacing] optional pre-cached spacing to avoid expensive lookups during keyboard animation
  final ConvoKitSpacing? spacing;

  /// [typography] optional pre-cached typography to avoid expensive lookups during keyboard animation
  final ConvoKitTypography? typography;

  @override
  State<ConvoKitAvatar> createState() => _ConvoKitAvatarState();
}

class _ConvoKitAvatarState extends State<ConvoKitAvatar> {
  // Cached theme values to avoid expensive lookups during rebuilds
  ConvoKitAvatarStyle? _avatarStyle;
  ConvoKitTypography? _typography;
  ConvoKitColorPalette? _colorPalette;
  ConvoKitSpacing? _spacing;
  double _cachedAvatarSize = 40; // Default fallback
  double _cachedTextSize = 16; // Default fallback
  bool _themeInitialized = false;
  Brightness? _cachedBrightness;

  // Helper to safely extract initials (handles emojis & multi-byte chars)
  String _getInitials(String name) {
    List<String> parts = name.trim().split(RegExp(r'\s+'));

    String getFirstCharacter(String input) {
      Runes runes = input.runes;
      return runes.isNotEmpty ? String.fromCharCode(runes.first) : "";
    }

    if (parts.length >= 2) {
      return (getFirstCharacter(parts[0]) + getFirstCharacter(parts[1]))
          .toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      Runes runes = parts[0].runes;
      if (runes.length >= 2) {
        return String.fromCharCodes(runes.take(2)).toUpperCase();
      } else {
        return getFirstCharacter(parts[0]).toUpperCase();
      }
    } else {
      return "";
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize theme once to avoid expensive lookups during keyboard animation
    final currentBrightness = ConvoKitThemeHelper.getBrightness(context);
    final brightnessChanged =
        _cachedBrightness != null && _cachedBrightness != currentBrightness;
    if (!_themeInitialized || brightnessChanged) {
      _cachedBrightness = currentBrightness;
      _avatarStyle = ConvoKitThemeHelper.getTheme<ConvoKitAvatarStyle>(
        context: context,
        defaultTheme: ConvoKitAvatarStyle.of,
      ).merge(widget.style);
      // Use passed values OR fallback to lookup (for standalone usage)
      _typography =
          widget.typography ?? ConvoKitThemeHelper.getTypography(context);
      _colorPalette =
          widget.colorPalette ?? ConvoKitThemeHelper.getColorPalette(context);
      _spacing = widget.spacing ?? ConvoKitThemeHelper.getSpacing(context);
      // Cache screen size ONCE to avoid MediaQuery rebuilds during keyboard animation
      final screenSize = MediaQuery.sizeOf(context);
      final screenWidth = screenSize.width;
      final screenHeight = screenSize.height;
      _cachedAvatarSize =
          (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.1;
      _cachedTextSize = _cachedAvatarSize * 0.2;
      _themeInitialized = true;
    }
  }

  @override
  void didUpdateWidget(ConvoKitAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update style if it changed
    if (widget.style != oldWidget.style) {
      _avatarStyle = ConvoKitThemeHelper.getTheme<ConvoKitAvatarStyle>(
        context: context,
        defaultTheme: ConvoKitAvatarStyle.of,
      ).merge(widget.style);
    }
    // Update cached theme values if they changed
    if (widget.colorPalette != oldWidget.colorPalette &&
        widget.colorPalette != null) {
      _colorPalette = widget.colorPalette;
    }
    if (widget.spacing != oldWidget.spacing && widget.spacing != null) {
      _spacing = widget.spacing;
    }
    if (widget.typography != oldWidget.typography &&
        widget.typography != null) {
      _typography = widget.typography;
    }
  }

  @override
  Widget build(BuildContext context) {
    String url = "";
    String text = "AB";

    final avatarStyle = _avatarStyle!;
    final typography = _typography!;
    final colorPalette = _colorPalette!;
    final spacing = _spacing!;

    // Use cached sizes to avoid MediaQuery rebuilds during keyboard animation
    final avatarSize = _cachedAvatarSize;
    final textSize = _cachedTextSize;

    // Check if Text should be visible or image
    if (widget.image != null && widget.image!.isNotEmpty) {
      url = widget.image!;
    }
    if (widget.name != null && widget.name!.trim().isNotEmpty) {
      text = _getInitials(widget.name ?? "");
    }

    return Container(
      margin: widget.margin,
      padding: widget.padding,
      width: widget.width ?? avatarSize,
      height: widget.height ?? avatarSize,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius:
            avatarStyle.borderRadius ??
            BorderRadius.all(Radius.circular(spacing.radiusMax ?? 0)),
        border: avatarStyle.border,
        color: avatarStyle.backgroundColor ?? colorPalette.extendedPrimary500,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(spacing.radiusMax ?? 0)),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, object, stackTrace) {
                  return Center(
                    child: Text(
                      text,
                      style:
                          TextStyle(
                                color:
                                    avatarStyle.placeHolderTextColor ??
                                    colorPalette.buttonIconColor,
                                fontSize: typography.heading2?.bold?.fontSize,
                                fontWeight:
                                    typography.heading2?.bold?.fontWeight,
                                fontFamily:
                                    typography.heading2?.bold?.fontFamily,
                              )
                              .merge(avatarStyle.placeHolderTextStyle)
                              .copyWith(
                                color: avatarStyle.placeHolderTextColor,
                              ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  text,
                  style:
                      TextStyle(
                            color:
                                avatarStyle.placeHolderTextColor ??
                                colorPalette.buttonIconColor,
                            fontSize: textSize,
                            fontWeight: typography.heading2?.bold?.fontWeight,
                            fontFamily: typography.heading2?.bold?.fontFamily,
                          )
                          .merge(avatarStyle.placeHolderTextStyle)
                          .copyWith(color: avatarStyle.placeHolderTextColor),
                ),
              ),
      ),
    );
  }
}
