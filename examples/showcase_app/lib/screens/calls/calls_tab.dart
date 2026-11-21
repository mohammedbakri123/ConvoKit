import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';
import '../../widgets/floating_glass_tab_bar.dart';

/// Calls tab surfacing the Phase-7 library Call UI status transparently using
/// one centered expressive status hero built strictly from [CometChatCard] and
/// two calm pill [ConvoKitActionBubble] status badges on a tonal
/// `surfaceContainerLow` container (zero glass on content).
///
/// Phase 7 removed `cometchat_calls_sdk` and `lib/call_ui/`, so zero call UI
/// screens exist in `convokit_uikit.dart`. Per the 100% library rule, no
/// custom call screens or fake call-log `ListView`s are invented here.
class CallsTab extends StatefulWidget {
  const CallsTab({
    super.key,
    this.headerActions,
  });

  /// Optional trailing actions rendered inside [CollapsingGlassHeader].
  final List<GlassHeaderAction>? headerActions;

  @override
  State<CallsTab> createState() => _CallsTabState();
}

class _CallsTabState extends State<CallsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final topClearance =
        CollapsingGlassHeader.topClearance(context) + ShowcaseTokens.spaceLg;
    final bottomClearance = FloatingGlassTabBar.bottomClearance(context);
    final pillRadius = BorderRadius.circular(ShowcaseTokens.radiusFullPill);

    return ColoredBox(
      color: palette.background1 ?? colorScheme.surface,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  key: const Key('calls_tab_scroll'),
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(
                    ShowcaseTokens.spaceLg,
                    topClearance,
                    ShowcaseTokens.spaceLg,
                    bottomClearance,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight -
                              topClearance -
                              bottomClearance)
                          .clamp(0.0, double.infinity),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Container(
                          key: const Key('calls_status_hero_card'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: ShowcaseTokens.spaceXl,
                            vertical: ShowcaseTokens.space2Xl,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              ShowcaseTokens.radiusHeroCard,
                            ),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              width: 0.8,
                            ),
                          ),
                          child: CometChatCard(
                            title: 'Voice & Video Call UI Unavailable',
                            titlePadding: const EdgeInsets.only(
                              bottom: ShowcaseTokens.spaceMd,
                            ),
                            avatarName: 'CK',
                            avatarWidth: 80,
                            avatarHeight: 80,
                            avatarMargin: const EdgeInsets.only(
                              bottom: ShowcaseTokens.spaceLg,
                            ),
                            cardStyle: CardStyle(
                              titleStyle: ShowcaseTypography.heroHeadline
                                  .copyWith(color: colorScheme.onSurface),
                              avatarStyle: ShowcaseTheme.avatarStyle(context),
                            ),
                            subtitleView: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ShowcaseTokens.spaceSm,
                              ),
                              child: Text(
                                'Phase 7 removed cometchat_calls_sdk and lib/call_ui/ from ConvoKit 0.1.0. Zero call UI screens exist in convokit_uikit.dart.',
                                textAlign: TextAlign.center,
                                style: ShowcaseTypography.bodyBase.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            bottomView: Padding(
                              padding: const EdgeInsets.only(
                                top: ShowcaseTokens.spaceXl,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ConvoKitActionBubble(
                                    text:
                                        'cometchat_calls_sdk removed (zero_calls_sdk_test: 4/4)',
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.only(
                                        right: ShowcaseTokens.spaceSm,
                                      ),
                                      child: ExcludeSemantics(
                                        child: Icon(
                                          Icons.verified_outlined,
                                          size: 16,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    style: ConvoKitActionBubbleStyle(
                                      backgroundColor:
                                          colorScheme.primaryContainer,
                                      borderRadius: pillRadius,
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                      ),
                                      textStyle: ShowcaseTypography.timestamp
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: ShowcaseTokens.spaceMd,
                                  ),
                                  ConvoKitActionBubble(
                                    text:
                                        'Library Gap #1: No call logs or call screens exported',
                                    leadingIcon: Padding(
                                      padding: const EdgeInsets.only(
                                        right: ShowcaseTokens.spaceSm,
                                      ),
                                      child: ExcludeSemantics(
                                        child: Icon(
                                          Icons.info_outline_rounded,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    style: ConvoKitActionBubbleStyle(
                                      backgroundColor:
                                          colorScheme.surfaceContainerHigh,
                                      borderRadius: pillRadius,
                                      border: Border.all(
                                        color: colorScheme.outlineVariant,
                                      ),
                                      textStyle: ShowcaseTypography.timestamp
                                          .copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CollapsingGlassHeader(
              title: 'Calls',
              scrollController: _scrollController,
              actions: widget.headerActions ?? const <GlassHeaderAction>[],
            ),
          ),
        ],
      ),
    );
  }
}
