import 'package:flutter/material.dart';
import 'package:convokit/convokit_uikit.dart';

///[CometChatLinkPreviewBubble] is a widget that is rendered as the content view for `LinkPreviewExtension`
/// ```dart
/// LinkPreviewBubble(
///   onTapUrl: (url) async {
///     // Open the URL in a browser when it is tapped
///     await launch(url);
///   },
///   links: [    // The links contained in the website metadata    {      'url': 'https://www.example.com',      'title': 'Example Website',      'description': 'A sample website to demonstrate link previews',      'image': 'https://www.example.com/image.png',    }  ],
///   child: Text('Link Preview'),
///   defaultImage: Image.asset('assets/images/default.png'),
///   style: LinkPreviewBubbleStyle(
///     backgroundColor: Colors.white,
///     titleStyle: TextStyle(
///       fontSize: 16,
///       fontWeight: FontWeight.bold,
///     ),
///   ),
/// );
///
/// ```
class CometChatLinkPreviewBubble extends StatelessWidget {
  const CometChatLinkPreviewBubble({
    super.key,
    required this.onTapUrl,
    required this.links,
    this.child,
    this.defaultImage,
    this.style,
    this.alignment,
  });

  ///[onTapUrl] opens the link in a browser
  final Future<void> Function(String url) onTapUrl;

  ///[links] returns links contained in the website metadata
  final List<dynamic> links;

  ///[child] some child component
  final Widget? child;

  ///[style] provides style to the link preview bubble
  final CometChatLinkPreviewBubbleStyle? style;

  ///[defaultImage] is shown unable to generate image from link
  final Widget? defaultImage;

  ///[alignment] provides alignment to the link preview bubble
  final BubbleAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    final style =
        ConvoKitThemeHelper.getTheme<CometChatLinkPreviewBubbleStyle>(
          context: context,
          defaultTheme: CometChatLinkPreviewBubbleStyle.of,
        ).merge(this.style);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);

    final Map<dynamic, dynamic>? firstLink =
        links.isNotEmpty && links[0] is Map
        ? links[0] as Map<dynamic, dynamic>
        : null;
    final String? linkImage = firstLink?["image"]?.toString();
    final String? linkUrl = firstLink?["url"]?.toString();
    final String? linkTitle = firstLink?["title"]?.toString();
    final String? linkDescription = firstLink?["description"]?.toString();
    final String? linkFavicon = firstLink?["favicon"]?.toString();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 232),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (firstLink != null &&
              (linkImage != null ||
                  linkUrl != null ||
                  linkTitle != null ||
                  linkFavicon != null))
            GestureDetector(
              onTap: () async {
                if (linkUrl != null) {
                  await onTapUrl(linkUrl);
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      style.backgroundColor ??
                      (alignment == BubbleAlignment.left
                          ? colorPalette.neutral400
                          : colorPalette.extendedPrimary900),
                  border: style.border,
                  borderRadius:
                      style.borderRadius ??
                      BorderRadius.only(
                        bottomLeft: Radius.circular(spacing.radius2 ?? 0),
                        bottomRight: Radius.circular(spacing.radius2 ?? 0),
                      ),
                ),
                child: Column(
                  children: [
                    if (linkImage != null && linkImage.isNotEmpty)
                      Container(
                        alignment: Alignment.topCenter,
                        constraints: const BoxConstraints(maxWidth: 232),
                        child: Image.network(
                          linkImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, object, stack) {
                            return defaultImage ??
                                const SizedBox(height: 0, width: 0);
                          },
                        ),
                      ),
                    if (linkTitle != null ||
                        linkUrl != null ||
                        linkDescription != null ||
                        linkFavicon != null)
                      Padding(
                        padding: EdgeInsets.all(spacing.padding2 ?? 0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: style.tileColor),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(0),
                            minVerticalPadding: 0.0,
                            minLeadingWidth: 0,
                            title: linkTitle != null
                                ? Text(
                                    linkTitle,
                                    style: TextStyle(
                                      fontSize: typography.body?.bold?.fontSize,
                                      fontWeight:
                                          typography.body?.bold?.fontWeight,
                                      color: (alignment == BubbleAlignment.left
                                          ? colorPalette.neutral900
                                          : colorPalette.white),
                                    ).merge(style.titleStyle),
                                  )
                                : null,
                            subtitle:
                                (linkDescription != null || linkUrl != null)
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (linkDescription != null)
                                        Text(
                                          linkDescription,
                                          style: TextStyle(
                                            fontSize: typography
                                                .caption1
                                                ?.regular
                                                ?.fontSize,
                                            fontWeight: typography
                                                .caption1
                                                ?.regular
                                                ?.fontWeight,
                                            color:
                                                (alignment ==
                                                    BubbleAlignment.left
                                                ? colorPalette.neutral900
                                                : colorPalette.white),
                                          ).merge(style.descriptionStyle),
                                        ),
                                      if (linkUrl != null)
                                        Text(
                                          linkUrl,
                                          style: TextStyle(
                                            fontSize: typography
                                                .caption1
                                                ?.regular
                                                ?.fontSize,
                                            fontWeight: typography
                                                .caption1
                                                ?.regular
                                                ?.fontWeight,
                                            color:
                                                (alignment ==
                                                    BubbleAlignment.left
                                                ? colorPalette.neutral900
                                                : colorPalette.white),
                                          ).merge(style.urlStyle),
                                        ),
                                    ],
                                  )
                                : null,
                            trailing:
                                (linkImage == null &&
                                    linkFavicon != null &&
                                    linkFavicon.isNotEmpty)
                                ? Image.network(
                                    linkFavicon,
                                    height: 36,
                                    width: 36,
                                    errorBuilder: (context, object, stack) {
                                      return defaultImage ??
                                          const SizedBox(height: 0, width: 0);
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          //-----child widget-----
          ?child,
        ],
      ),
    );
  }
}
