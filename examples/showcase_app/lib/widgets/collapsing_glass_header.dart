import 'dart:ui' show lerpDouble;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../theme/showcase_tokens.dart';
import 'glass_surface.dart';

/// Action descriptor rendered inside [CollapsingGlassHeader]'s trailing
/// concentric glass capsule.
class GlassHeaderAction {
  const GlassHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.key,
    this.semanticLabel,
  });

  /// Material vector icon displayed inside the button.
  final IconData icon;

  /// Explicit tooltip shown on hover/long-press and used as default semantics.
  final String tooltip;

  /// Callback invoked when the action is tapped.
  final VoidCallback onPressed;

  /// Optional widget key (e.g., `Key('showcase_theme_toggle')`).
  final Key? key;

  /// Optional explicit semantic label; defaults to [tooltip].
  final String? semanticLabel;
}

/// Scroll-linked collapsing Liquid Glass header.
///
/// Transitions smoothly from [ShowcaseTypography.displayTitle] (`34pt w800`) at
/// scroll offset `0` to [ShowcaseTypography.compactTitle] (`17pt w600`) inside
/// a `.regular` [GlassSurface] bar with a subtle bottom fade past
/// [collapseThreshold] (`44px`).
///
/// Trailing [actions] are grouped inside a shared concentric glass capsule with
/// `>=44x44` touch targets, `>=8px` spacing, and explicit tooltips/semantics.
/// When the header bar collapses into glass, the action capsule drops its inner
/// blur so glass is never stacked on top of glass.
class CollapsingGlassHeader extends StatefulWidget {
  const CollapsingGlassHeader({
    super.key,
    required this.title,
    this.scrollController,
    this.scrollOffset,
    this.actions = const <GlassHeaderAction>[],
    this.leading,
  });

  /// Scroll distance in logical pixels over which the header collapses.
  static const double collapseThreshold = 44.0;

  /// Header body height (excluding top safe-area inset) when expanded.
  static const double expandedHeight = 76.0;

  /// Header body height (excluding top safe-area inset) when collapsed.
  static const double compactHeight = 56.0;

  /// Height of the subtle bottom edge fade rendered below the collapsed glass bar.
  static const double bottomFadeHeight = 12.0;

  /// Recommended top list clearance so scrollable content starts cleanly below
  /// the expanded header.
  static double topClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).top + expandedHeight;
  }

  /// Title text rendered in display or compact typography.
  final String title;

  /// Optional [ScrollController] driving the collapse progress.
  final ScrollController? scrollController;

  /// Optional explicit scroll offset override (useful for custom scroll drivers
  /// or deterministic tests).
  final double? scrollOffset;

  /// Trailing icon actions grouped into a shared concentric glass capsule.
  final List<GlassHeaderAction> actions;

  /// Optional leading control (e.g., back button on pushed routes).
  final Widget? leading;

  @override
  State<CollapsingGlassHeader> createState() => _CollapsingGlassHeaderState();
}

class _CollapsingGlassHeaderState extends State<CollapsingGlassHeader> {
  double _offset = 0.0;

  @override
  void initState() {
    super.initState();
    _offset = _readOffset();
    widget.scrollController?.addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant CollapsingGlassHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_handleScroll);
      widget.scrollController?.addListener(_handleScroll);
    }
    final nextOffset = _readOffset();
    if (nextOffset != _offset) {
      _offset = nextOffset;
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_handleScroll);
    super.dispose();
  }

  double _readOffset() {
    if (widget.scrollOffset != null) {
      return widget.scrollOffset!.clamp(0.0, double.infinity);
    }
    final controller = widget.scrollController;
    if (controller != null &&
        controller.hasClients &&
        controller.positions.length == 1) {
      return controller.offset.clamp(0.0, double.infinity);
    }
    return 0.0;
  }

  void _handleScroll() {
    final next = _readOffset();
    if ((next - _offset).abs() < 0.5) {
      return;
    }
    if (mounted) {
      setState(() => _offset = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentOffset = _readOffset();
    final progress =
        (currentOffset / CollapsingGlassHeader.collapseThreshold).clamp(
          0.0,
          1.0,
        );
    final isGlassBarVisible = progress > 0.01;
    final barHeight = lerpDouble(
      CollapsingGlassHeader.expandedHeight,
      CollapsingGlassHeader.compactHeight,
      progress,
    )!;

    final expandedTitleColor = isDark
        ? colorScheme.onSurface
        : (palette.textHighlight ?? colorScheme.secondary);
    final compactTitleColor = colorScheme.onSurface;

    final titleStyle = TextStyle.lerp(
      ShowcaseTypography.displayTitle.copyWith(color: expandedTitleColor),
      ShowcaseTypography.compactTitle.copyWith(color: compactTitleColor),
      progress,
    )!;

    final iconColor = isDark
        ? colorScheme.primary
        : (palette.iconHighlight ?? colorScheme.secondary);

    final Widget headerContent = SafeArea(
      bottom: false,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShowcaseTokens.spaceLg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.leading != null) ...<Widget>[
                widget.leading!,
                const SizedBox(width: ShowcaseTokens.minControlGap),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ),
              if (widget.actions.isNotEmpty) ...<Widget>[
                const SizedBox(width: ShowcaseTokens.spaceSm),
                _TrailingActionCapsule(
                  actions: widget.actions,
                  iconColor: iconColor,
                  useGlassBlur: !isGlassBarVisible,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final borderColor = palette.borderLight ?? colorScheme.outlineVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            if (isGlassBarVisible)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: progress,
                    child: GlassSurface(
                      borderRadius: BorderRadius.zero,
                      showBorder: false,
                      showShadow: false,
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor,
                          width: ShowcaseTokens.glassBorderWidth,
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            headerContent,
          ],
        ),
        if (isGlassBarVisible)
          IgnorePointer(
            child: SizedBox(
              height: CollapsingGlassHeader.bottomFadeHeight,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colorScheme.surface.withValues(alpha: 0.16 * progress),
                      colorScheme.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrailingActionCapsule extends StatelessWidget {
  const _TrailingActionCapsule({
    required this.actions,
    required this.iconColor,
    required this.useGlassBlur,
  });

  final List<GlassHeaderAction> actions;
  final Color iconColor;
  final bool useGlassBlur;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final capsuleRadius = BorderRadius.circular(ShowcaseTokens.radiusFullPill);

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: ShowcaseTokens.minControlGap),
          _GlassActionIconButton(
            action: actions[i],
            iconColor: iconColor,
          ),
        ],
      ],
    );

    // Avoid stacking glass on top of glass once the parent header bar itself
    // transitions into a frosted GlassSurface.
    return GlassSurface(
      key: const Key('collapsing_header_action_capsule'),
      borderRadius: capsuleRadius,
      padding: const EdgeInsets.all(ShowcaseTokens.spaceXs),
      blurSigma: useGlassBlur ? ShowcaseTokens.glassBlurSigma : 0,
      showShadow: useGlassBlur,
      showBorder: useGlassBlur,
      fillColor: useGlassBlur
          ? null
          : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
      child: row,
    );
  }
}

class _GlassActionIconButton extends StatelessWidget {
  const _GlassActionIconButton({
    required this.action,
    required this.iconColor,
  });

  final GlassHeaderAction action;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.tooltip,
      onTap: action.onPressed,
      excludeSemantics: true,
      child: IconButton(
        key: action.key,
        tooltip: action.tooltip,
        onPressed: action.onPressed,
        constraints: const BoxConstraints(
          minWidth: ShowcaseTokens.minTouchTarget,
          minHeight: ShowcaseTokens.minTouchTarget,
        ),
        style: IconButton.styleFrom(
          minimumSize: ShowcaseTokens.minTouchTargetSize,
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: const StadiumBorder(),
        ),
        icon: Icon(action.icon, color: iconColor),
      ),
    );
  }
}
