import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../theme/showcase_tokens.dart';
import 'glass_surface.dart';

/// Descriptor for a destination mounted inside [FloatingGlassTabBar].
class FloatingGlassTabItem {
  const FloatingGlassTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.semanticLabel,
  });

  /// Visible text label rendered beneath the icon.
  final String label;

  /// Vector icon rendered when this destination is inactive.
  final IconData icon;

  /// Vector icon rendered when this destination is selected.
  final IconData activeIcon;

  /// Optional accessibility label override; defaults to [label].
  final String? semanticLabel;
}

/// iOS 26 Liquid Glass inset floating tab capsule hosting 2–5 destinations.
///
/// Renders exclusively on the navigation layer using [GlassSurface], with:
/// - Inset margin `EdgeInsets.fromLTRB(20, 0, 20, 18)` + `SafeArea(top: false)`
/// - `>=44x44` touch targets (`minHeight: 48`, `minWidth: 56`)
/// - `>=8px` spacing between adjacent destinations
/// - Concentric active pill (`radiusNavActivePill` inside `radiusNavCapsule`)
/// - Reduced-motion-safe animation via [ShowcaseMotion.effectiveDuration].
class FloatingGlassTabBar extends StatelessWidget {
  const FloatingGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  }) : assert(
         items.length >= 2 && items.length <= 5,
         'FloatingGlassTabBar supports between 2 and 5 destinations.',
       ),
       assert(
         currentIndex >= 0 && currentIndex < items.length,
         'currentIndex must be within the range of items.',
       );

  /// Outer inset margin around the floating capsule.
  static const EdgeInsets capsuleMargin = EdgeInsets.fromLTRB(20, 0, 20, 18);

  /// Minimum touch target constraints per tab item (`>=44x44`).
  static const BoxConstraints itemConstraints = BoxConstraints(
    minWidth: 56,
    minHeight: 48,
  );

  /// Recommended bottom list clearance so scrollable content can scroll fully
  /// past the floating glass tab capsule.
  static double bottomClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom +
        capsuleMargin.bottom +
        itemConstraints.minHeight +
        (ShowcaseTokens.spaceSm * 2) +
        ShowcaseTokens.spaceMd;
  }

  /// Navigation destinations (`Chats`, `Updates`, `Calls`, `Settings`).
  final List<FloatingGlassTabItem> items;

  /// Index of the currently selected destination.
  final int currentIndex;

  /// Callback invoked when the user selects a destination.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final duration = ShowcaseMotion.effectiveDuration(
      context,
      ShowcaseMotion.enterDuration,
    );

    final activePillColor = colorScheme.primaryContainer;
    final activeForeground = colorScheme.onPrimaryContainer;
    final inactiveForeground =
        palette.textSecondary ?? colorScheme.onSurfaceVariant;
    final activePillRadius = BorderRadius.circular(
      ShowcaseTokens.radiusNavActivePill,
    );

    return SafeArea(
      top: false,
      child: GlassSurface(
        margin: capsuleMargin,
        padding: const EdgeInsets.all(ShowcaseTokens.spaceSm),
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusNavCapsule),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemCount = items.length;
            const gap = ShowcaseTokens.minControlGap;
            final totalGaps = gap * (itemCount - 1);
            final slotWidth =
                ((constraints.maxWidth - totalGaps) / itemCount).clamp(
                  itemConstraints.minWidth,
                  double.infinity,
                );
            final activeLeft = currentIndex * (slotWidth + gap);

            return Stack(
              children: <Widget>[
                AnimatedPositioned(
                  key: const Key('floating_glass_tab_active_pill'),
                  duration: duration,
                  curve: ShowcaseMotion.enterCurve,
                  left: activeLeft,
                  top: 0,
                  bottom: 0,
                  width: slotWidth,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: activePillColor,
                        borderRadius: activePillRadius,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    for (var i = 0; i < itemCount; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(
                        child: _FloatingGlassTabButton(
                          item: items[i],
                          isSelected: i == currentIndex,
                          activeForeground: activeForeground,
                          inactiveForeground: inactiveForeground,
                          borderRadius: activePillRadius,
                          duration: duration,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FloatingGlassTabButton extends StatelessWidget {
  const _FloatingGlassTabButton({
    required this.item,
    required this.isSelected,
    required this.activeForeground,
    required this.inactiveForeground,
    required this.borderRadius,
    required this.duration,
    required this.onTap,
  });

  final FloatingGlassTabItem item;
  final bool isSelected;
  final Color activeForeground;
  final Color inactiveForeground;
  final BorderRadius borderRadius;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? activeForeground : inactiveForeground;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.semanticLabel ?? item.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('floating_glass_tab_${item.label.toLowerCase()}'),
          borderRadius: borderRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: FloatingGlassTabBar.itemConstraints,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ShowcaseTokens.spaceXs,
                vertical: ShowcaseTokens.spaceXs,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 22,
                    color: foreground,
                  ),
                  const SizedBox(height: 2),
                  ExcludeSemantics(
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      curve: ShowcaseMotion.enterCurve,
                      style: ShowcaseTypography.timestamp.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: foreground,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
