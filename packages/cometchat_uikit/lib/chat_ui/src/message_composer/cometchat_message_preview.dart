import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// [ConvoKitMessagePreview] is a component that provides a bubble consisting of text
/// that can be appended to the message composer, message bubble or any other component as desired.
/// The appearance is similar to a quote block of markdown files.
class ConvoKitMessagePreview extends StatelessWidget {
  const ConvoKitMessagePreview({
    super.key,
    required this.messagePreviewTitle,
    required this.messagePreviewSubtitle,
    this.messagePreviewCloseButtonIcon,
    this.messagePreviewStyle,
    this.onCloseClick,
    this.hideCloseButton = false,
    this.message,
    this.stickerUrl,
    this.subtitleWidget,
  });

  /// [messagePreviewTitle] title shown in the preview bar (e.g. sender name or "Reply")
  final String messagePreviewTitle;

  /// [messagePreviewSubtitle] subtitle shown in the preview bar (message text or type label)
  final String messagePreviewSubtitle;

  /// [messagePreviewCloseButtonIcon] replaces the default close icon
  final Icon? messagePreviewCloseButtonIcon;

  /// [messagePreviewStyle] alters styling properties
  final ConvoKitMessagePreviewStyle? messagePreviewStyle;

  /// [onCloseClick] callback invoked when the close button is tapped
  final Function()? onCloseClick;

  /// [hideCloseButton] hides the close button when true
  final bool hideCloseButton;

  /// [message] message object used to show a media type icon for non-text messages
  final ChatMessage? message;

  /// [stickerUrl] URL of a sticker image to show as a thumbnail in the preview
  final String? stickerUrl;

  /// [subtitleWidget] optional custom widget for the subtitle area.
  /// When provided, takes precedence over [messagePreviewSubtitle] string.
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    ConvoKitSpacing spacing = ConvoKitThemeHelper.getSpacing(context);
    ConvoKitColorPalette colorPalette = ConvoKitThemeHelper.getColorPalette(
      context,
    );
    ConvoKitTypography typography = ConvoKitThemeHelper.getTypography(
      context,
    );
    ConvoKitMessagePreviewStyle style =
        ConvoKitThemeHelper.getTheme<ConvoKitMessagePreviewStyle>(
          context: context,
          defaultTheme: ConvoKitMessagePreviewStyle.of,
        ).merge(messagePreviewStyle);

    return ClipRRect(
      borderRadius:
          style.messagePreviewBorderRadius ??
          BorderRadius.all(Radius.circular(spacing.radius2 ?? 0)),
      child: Container(
        decoration: BoxDecoration(
          color: style.messagePreviewBackground,
          border:
              style.messagePreviewBorder ??
              Border(
                top: BorderSide.none,
                bottom: BorderSide.none,
                left: BorderSide(
                  color: colorPalette.borderHighlight ?? Colors.transparent,
                  width: 2,
                ),
                right: BorderSide.none,
              ),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.padding2 ?? 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: spacing.padding1 ?? 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      messagePreviewTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(
                                fontSize: typography.caption1?.medium?.fontSize,
                                fontWeight:
                                    typography.caption1?.medium?.fontWeight,
                                color: colorPalette.textHighlight,
                              )
                              .merge(style.messagePreviewTitleStyle)
                              .copyWith(color: style.messagePreviewTitleColor),
                    ),
                    if (hideCloseButton == false)
                      Semantics(
                        button: true,
                        label: Translations.of(context).close,
                        child: GestureDetector(
                          onTap: onCloseClick,
                          child:
                              messagePreviewCloseButtonIcon ??
                              Icon(
                                Icons.close,
                                size: 16,
                                color:
                                    style.closeIconColor ??
                                    colorPalette.iconSecondary,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (message != null)
                    Padding(
                      padding: EdgeInsets.only(right: spacing.padding1 ?? 0),
                      child: ComposerUtils.getReplyIcon(
                        message!,
                        context,
                        style.replyMessagePreviewCloseIconColor ??
                            colorPalette.iconSecondary,
                      ),
                    ),
                  if (stickerUrl != null && stickerUrl!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(right: spacing.padding1 ?? 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          spacing.radius1 ?? 4,
                        ),
                        child: Image.network(
                          stickerUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                      ),
                      child:
                          subtitleWidget ??
                          Text(
                            messagePreviewSubtitle,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(
                                      fontSize: typography
                                          .caption1
                                          ?.regular
                                          ?.fontSize,
                                      fontWeight: typography
                                          .caption1
                                          ?.regular
                                          ?.fontWeight,
                                      color: colorPalette.textSecondary,
                                    )
                                    .merge(style.messagePreviewSubtitleStyle)
                                    .copyWith(
                                      color: style.messagePreviewSubtitleColor,
                                    ),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class ConvoKitMessagePreviewStyle
    extends ThemeExtension<ConvoKitMessagePreviewStyle> {
  const ConvoKitMessagePreviewStyle({
    this.messagePreviewBackground,
    this.messagePreviewBorder,
    this.messagePreviewBorderRadius,
    this.messagePreviewTitleStyle,
    this.messagePreviewTitleColor,
    this.messagePreviewSubtitleStyle,
    this.messagePreviewSubtitleColor,
    this.closeIconColor,
    this.replyMessagePreviewCloseIconColor,
  });

  final Color? messagePreviewBackground;
  final BoxBorder? messagePreviewBorder;
  final BorderRadius? messagePreviewBorderRadius;
  final TextStyle? messagePreviewTitleStyle;
  final Color? messagePreviewTitleColor;
  final TextStyle? messagePreviewSubtitleStyle;
  final Color? messagePreviewSubtitleColor;
  final Color? closeIconColor;

  /// Color for the media type icon shown next to the subtitle for non-text messages
  final Color? replyMessagePreviewCloseIconColor;

  static ConvoKitMessagePreviewStyle of(BuildContext context) =>
      const ConvoKitMessagePreviewStyle();

  ConvoKitMessagePreviewStyle merge(ConvoKitMessagePreviewStyle? other) {
    if (other == null) return this;
    return ConvoKitMessagePreviewStyle(
      messagePreviewBackground:
          other.messagePreviewBackground ?? messagePreviewBackground,
      messagePreviewBorder: other.messagePreviewBorder ?? messagePreviewBorder,
      messagePreviewBorderRadius:
          other.messagePreviewBorderRadius ?? messagePreviewBorderRadius,
      messagePreviewTitleStyle:
          other.messagePreviewTitleStyle ?? messagePreviewTitleStyle,
      messagePreviewTitleColor:
          other.messagePreviewTitleColor ?? messagePreviewTitleColor,
      messagePreviewSubtitleStyle:
          other.messagePreviewSubtitleStyle ?? messagePreviewSubtitleStyle,
      messagePreviewSubtitleColor:
          other.messagePreviewSubtitleColor ?? messagePreviewSubtitleColor,
      closeIconColor: other.closeIconColor ?? closeIconColor,
      replyMessagePreviewCloseIconColor:
          other.replyMessagePreviewCloseIconColor ??
          replyMessagePreviewCloseIconColor,
    );
  }

  @override
  ConvoKitMessagePreviewStyle copyWith({
    Color? messagePreviewBackground,
    BoxBorder? messagePreviewBorder,
    BorderRadius? messagePreviewBorderRadius,
    TextStyle? messagePreviewTitleStyle,
    Color? messagePreviewTitleColor,
    TextStyle? messagePreviewSubtitleStyle,
    Color? messagePreviewSubtitleColor,
    Color? closeIconColor,
    Color? replyMessagePreviewCloseIconColor,
  }) {
    return ConvoKitMessagePreviewStyle(
      messagePreviewBackground:
          messagePreviewBackground ?? this.messagePreviewBackground,
      messagePreviewBorder: messagePreviewBorder ?? this.messagePreviewBorder,
      messagePreviewBorderRadius:
          messagePreviewBorderRadius ?? this.messagePreviewBorderRadius,
      messagePreviewTitleStyle:
          messagePreviewTitleStyle ?? this.messagePreviewTitleStyle,
      messagePreviewTitleColor:
          messagePreviewTitleColor ?? this.messagePreviewTitleColor,
      messagePreviewSubtitleStyle:
          messagePreviewSubtitleStyle ?? this.messagePreviewSubtitleStyle,
      messagePreviewSubtitleColor:
          messagePreviewSubtitleColor ?? this.messagePreviewSubtitleColor,
      closeIconColor: closeIconColor ?? this.closeIconColor,
      replyMessagePreviewCloseIconColor:
          replyMessagePreviewCloseIconColor ??
          this.replyMessagePreviewCloseIconColor,
    );
  }

  @override
  ConvoKitMessagePreviewStyle lerp(
    ThemeExtension<ConvoKitMessagePreviewStyle>? other,
    double t,
  ) {
    if (other is! ConvoKitMessagePreviewStyle) return this;
    return ConvoKitMessagePreviewStyle(
      messagePreviewBackground: Color.lerp(
        messagePreviewBackground,
        other.messagePreviewBackground,
        t,
      ),
      messagePreviewBorder: t < 0.5
          ? messagePreviewBorder
          : other.messagePreviewBorder,
      messagePreviewBorderRadius: BorderRadius.lerp(
        messagePreviewBorderRadius,
        other.messagePreviewBorderRadius,
        t,
      ),
      messagePreviewTitleStyle: TextStyle.lerp(
        messagePreviewTitleStyle,
        other.messagePreviewTitleStyle,
        t,
      ),
      messagePreviewTitleColor: Color.lerp(
        messagePreviewTitleColor,
        other.messagePreviewTitleColor,
        t,
      ),
      messagePreviewSubtitleStyle: TextStyle.lerp(
        messagePreviewSubtitleStyle,
        other.messagePreviewSubtitleStyle,
        t,
      ),
      messagePreviewSubtitleColor: Color.lerp(
        messagePreviewSubtitleColor,
        other.messagePreviewSubtitleColor,
        t,
      ),
      closeIconColor: Color.lerp(closeIconColor, other.closeIconColor, t),
      replyMessagePreviewCloseIconColor: Color.lerp(
        replyMessagePreviewCloseIconColor,
        other.replyMessagePreviewCloseIconColor,
        t,
      ),
    );
  }
}
