import 'dart:async';

import 'package:convokit/convokit.dart' show ChatCapabilities, ConvoKitScope;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../../backend/studio_backend.dart';
import '../../backend/studio_seed_data.dart';
import '../../theme/showcase_theme.dart';
import '../../theme/showcase_tokens.dart';
import '../../widgets/collapsing_glass_header.dart';
import '../../widgets/floating_glass_tab_bar.dart';
import '../updates/saved_messages_screen.dart';

/// Settings tab following "one hero moment per screen; the rest stays calm":
/// - Scroll-driven [CollapsingGlassHeader] + top/bottom clearance for both
///   glass bars.
/// - One tonal **Nadia Haddad Profile Hero Card** (`radius: 24`, `64px`
///   [ConvoKitAvatar], ringed [ConvoKitStatusIndicator] + `'Online'` text
///   label, `22pt w700` name, role pill, quick Light/Dark pill switch).
/// - Calm grouped `surfaceContainerLow` rounded cards (`radius: 20`,
///   concentric `16` inner rows, zero glass) for Appearance & Shortcuts,
///   Atomic Components Showcase (fresh relative `DateTime.now()`), Demo Data
///   ([ConvoKitConfirmDialog] with full-pill buttons), and Library Info &
///   Capabilities.
class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    this.backend,
    this.onResetDemoData,
    this.headerActions,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final StudioBackend? backend;
  final VoidCallback? onResetDemoData;

  /// Optional trailing actions rendered inside [CollapsingGlassHeader].
  final List<GlassHeaderAction>? headerActions;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final ScrollController _scrollController = ScrollController();

  bool _showShimmerPreview = false;
  String _lastSwipeAction = 'Swipe left on this row to reveal actions';

  bool get _isDark => widget.themeMode == ThemeMode.dark;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSavedMessages(BuildContext context) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SavedMessagesScreen(backend: widget.backend),
        ),
      ),
    );
  }

  void _showResetConfirmDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    ConvoKitConfirmDialog(
      context: context,
      title: const Text('Reset Demo Data?'),
      messageText: const Text(
        'This restores all Atelier Studio conversations, messages, groups, and saved bookmarks back to their initial offline snapshot.',
      ),
      confirmButtonText: 'Reset',
      cancelButtonText: 'Cancel',
      style: ConvoKitConfirmDialogStyle(
        backgroundColor: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusSheet),
        border: BorderSide(color: colorScheme.outlineVariant),
        titleTextColor: colorScheme.onSurface,
        titleTextStyle: ShowcaseTypography.compactTitle.copyWith(
          color: colorScheme.onSurface,
        ),
        messageTextColor: colorScheme.onSurfaceVariant,
        messageTextStyle: ShowcaseTypography.rowSubtitle.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        confirmButtonBackground: colorScheme.error,
        confirmButtonTextColor: colorScheme.onError,
        confirmButtonTextStyle: ShowcaseTypography.buttonLabel.copyWith(
          color: colorScheme.onError,
        ),
        cancelButtonBackground: colorScheme.surfaceContainerHigh,
        cancelButtonTextColor: colorScheme.onSurface,
        cancelButtonTextStyle: ShowcaseTypography.buttonLabel.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      onConfirm: (dialogContext) {
        Navigator.of(dialogContext).pop();
        if (widget.onResetDemoData != null) {
          widget.onResetDemoData!();
        } else {
          widget.backend?.reset();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Atelier Studio demo data restored.'),
            ),
          );
        }
      },
      onCancel: (dialogContext) {
        Navigator.of(dialogContext).pop();
      },
    ).show();
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceXl,
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceSm,
      ),
      child: SectionSeparator(
        text: label,
        height: 28,
        dividerColor: colorScheme.outlineVariant,
        textStyle: ShowcaseTypography.sectionLabel.copyWith(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(
    BuildContext context, {
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.all(ShowcaseTokens.spaceSm),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ShowcaseTokens.spaceLg),
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusCard),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildConcentricRow({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ShowcaseTokens.radiusNestedCard),
      child: child,
    );
  }

  Widget _buildProfileHeroCard(
    BuildContext context, {
    required ChatUser currentUser,
    required String role,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final pillRadius = BorderRadius.circular(ShowcaseTokens.radiusFullPill);

    return Container(
      key: const Key('settings_profile_hero_card'),
      margin: const EdgeInsets.fromLTRB(
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceXs,
        ShowcaseTokens.spaceLg,
        ShowcaseTokens.spaceSm,
      ),
      padding: const EdgeInsets.all(ShowcaseTokens.spaceXl),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusHeroCard),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ConvoKitAvatar(
                      name: currentUser.name,
                      image: currentUser.avatarUrl,
                      width: 64,
                      height: 64,
                      style: ShowcaseTheme.avatarStyle(context),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: ConvoKitStatusIndicator(
                        width: 16,
                        height: 16,
                        style: ShowcaseTheme.statusIndicatorStyle(
                          context,
                          ringColor: colorScheme.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ShowcaseTokens.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      currentUser.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: ShowcaseTokens.spaceSm),
                    Wrap(
                      spacing: ShowcaseTokens.spaceSm,
                      runSpacing: ShowcaseTokens.spaceXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ShowcaseTokens.spaceMd,
                            vertical: ShowcaseTokens.spaceXs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: pillRadius,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '$role · Atelier Studio',
                            style: ShowcaseTypography.timestamp.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ConvoKitStatusIndicator(
                              width: 10,
                              height: 10,
                              style: ShowcaseTheme.statusIndicatorStyle(
                                context,
                                ringColor: colorScheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(width: ShowcaseTokens.spaceXs),
                            Text(
                              'Online',
                              style: ShowcaseTypography.timestamp.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ShowcaseTokens.spaceLg),
          FilledButton.tonalIcon(
            key: const Key('settings_hero_theme_pill'),
            onPressed: () {
              widget.onThemeModeChanged(
                _isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: ShowcaseTokens.minTouchTargetSize,
              shape: const StadiumBorder(),
              backgroundColor: colorScheme.surfaceContainerLowest,
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(
                horizontal: ShowcaseTokens.spaceLg,
                vertical: ShowcaseTokens.spaceSm,
              ),
            ),
            icon: ExcludeSemantics(
              child: Icon(
                _isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
            ),
            label: Text(
              _isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final kit = ConvoKitScope.maybeOf(context);
    final currentUser =
        widget.backend?.session.currentUser ??
        kit?.session.currentUser ??
        StudioSeedData.create().currentUser;
    final role =
        widget.backend?.seedSnapshot.userRoles[currentUser.id] ??
        'Design Director';
    final capabilities = kit?.capabilities ?? ChatCapabilities.basic();
    final savedCount =
        widget.backend?.messages.getSavedMessages().length ??
        StudioSeedData.create().savedMessages.length;

    final collapsedHeaderHeight =
        MediaQuery.paddingOf(context).top + CollapsingGlassHeader.compactHeight;
    const topClearance =
        (CollapsingGlassHeader.expandedHeight -
            CollapsingGlassHeader.compactHeight) +
        ShowcaseTokens.spaceSm;
    final bottomClearance = FloatingGlassTabBar.bottomClearance(context);
    final now = DateTime.now();

    final rowStyle = ListItemStyle(
      background: colorScheme.surfaceContainerLow,
      titleStyle: ShowcaseTypography.rowTitle.copyWith(
        color: colorScheme.onSurface,
      ),
      separatorColor: colorScheme.outlineVariant,
    );

    final avatarStyle = ShowcaseTheme.avatarStyle(context);

    final receiptStyle = CometChatMessageReceiptStyle(
      sentIconColor: colorScheme.onSurfaceVariant,
      deliveredIconColor: colorScheme.onSurfaceVariant,
      readIconColor: ShowcaseTokens.readReceiptBlue,
      errorIconColor: colorScheme.error,
      waitIconColor: palette.iconTertiary,
    );

    return ColoredBox(
      color: palette.background1 ?? colorScheme.surface,
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: collapsedHeaderHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                key: const Key('settings_tab_scroll'),
                controller: _scrollController,
                clipBehavior: Clip.none,
                padding: EdgeInsets.only(
                  top: topClearance,
                  bottom: bottomClearance,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. One Expressive Hero Moment: Profile Hero Card
                  _buildProfileHeroCard(
                    context,
                    currentUser: currentUser,
                    role: role,
                  ),

                  // 2. Appearance & Shortcuts
                  _buildSectionHeader(context, 'APPEARANCE & SHORTCUTS'),
                  _buildGroupedCard(
                    context,
                    children: <Widget>[
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_theme_row',
                          avatarName: _isDark ? 'DK' : 'LT',
                          avatarStyle: avatarStyle,
                          title: 'Dark Mode',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            _isDark
                                ? 'Dark ConvoKitColorPalette active'
                                : 'Light ConvoKitColorPalette active',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Switch(
                            key: const Key('settings_theme_switch'),
                            value: _isDark,
                            activeThumbColor: colorScheme.primary,
                            onChanged: (dark) => widget.onThemeModeChanged(
                              dark ? ThemeMode.dark : ThemeMode.light,
                            ),
                          ),
                        ),
                      ),
                      _buildConcentricRow(
                        child: InkWell(
                          key: const Key('settings_saved_messages_row'),
                          borderRadius: BorderRadius.circular(
                            ShowcaseTokens.radiusNestedCard,
                          ),
                          onTap: () => _openSavedMessages(context),
                          child: ConvoKitListItem(
                            id: 'settings_saved_messages_item',
                            avatarName: 'SM',
                            avatarStyle: avatarStyle,
                            title: 'Saved Messages',
                            style: rowStyle,
                            hideSeparator: true,
                            subtitleView: Text(
                              'Opens ConvoKitSavedMessages',
                              style: ShowcaseTypography.rowSubtitle.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            tailView: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ConvoKitBadge(
                                  count: savedCount,
                                  style: ConvoKitBadgeStyle(
                                    backgroundColor: colorScheme.primary,
                                    textColor: colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: ShowcaseTokens.spaceSm),
                                ExcludeSemantics(
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. Atomic Components Showcase
                  _buildSectionHeader(context, 'ATOMIC COMPONENTS SHOWCASE'),
                  _buildGroupedCard(
                    context,
                    children: <Widget>[
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_atomic_badges',
                          avatarName: 'BG',
                          avatarStyle: avatarStyle,
                          title: 'ConvoKitBadge',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            'Single, double, and overflow (999+) counts',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ConvoKitBadge(
                                count: 3,
                                style: ConvoKitBadgeStyle(
                                  backgroundColor: colorScheme.primary,
                                  textColor: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceSm),
                              ConvoKitBadge(
                                count: 24,
                                style: ConvoKitBadgeStyle(
                                  backgroundColor: colorScheme.primary,
                                  textColor: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceSm),
                              ConvoKitBadge(
                                count: 1200,
                                style: ConvoKitBadgeStyle(
                                  backgroundColor: colorScheme.primary,
                                  textColor: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_atomic_date',
                          avatarName: 'DT',
                          avatarStyle: avatarStyle,
                          title: 'ConvoKitDate',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            'Formatted timestamp and relative date tokens',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              ConvoKitDate(
                                date: now,
                                pattern: DateTimePattern.timeFormat,
                                style: ConvoKitDateStyle(
                                  textColor: colorScheme.onSurface,
                                  textStyle: ShowcaseTypography.timestamp
                                      .copyWith(color: colorScheme.onSurface),
                                ),
                              ),
                              ConvoKitDate(
                                date: now,
                                pattern: DateTimePattern.dayDateFormat,
                                style: ConvoKitDateStyle(
                                  textColor: colorScheme.onSurfaceVariant,
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
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_atomic_receipts',
                          avatarName: 'RC',
                          avatarStyle: avatarStyle,
                          title: 'ConvoKitReceipt',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            'Waiting · Sent · Delivered · Read · Error',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ConvoKitReceipt(
                                status: ReceiptStatus.waiting,
                                size: 16,
                                style: receiptStyle,
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceXs),
                              ConvoKitReceipt(
                                status: ReceiptStatus.sent,
                                size: 16,
                                style: receiptStyle,
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceXs),
                              ConvoKitReceipt(
                                status: ReceiptStatus.delivered,
                                size: 16,
                                style: receiptStyle,
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceXs),
                              ConvoKitReceipt(
                                status: ReceiptStatus.read,
                                size: 16,
                                style: receiptStyle,
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceXs),
                              ConvoKitReceipt(
                                status: ReceiptStatus.error,
                                size: 16,
                                style: receiptStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_atomic_shimmer',
                          avatarName: 'SH',
                          avatarStyle: avatarStyle,
                          title: 'ConvoKitShimmerEffect',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            'Toggle skeleton loading shimmer preview',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Switch(
                            key: const Key('settings_shimmer_toggle'),
                            value: _showShimmerPreview,
                            activeThumbColor: colorScheme.primary,
                            onChanged: (value) {
                              setState(() => _showShimmerPreview = value);
                            },
                          ),
                        ),
                      ),
                      if (_showShimmerPreview)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ShowcaseTokens.spaceMd,
                            vertical: ShowcaseTokens.spaceSm,
                          ),
                          child: ConvoKitShimmerEffect(
                            colorPalette: palette,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  ShowcaseTokens.radiusNestedCard,
                                ),
                              ),
                            ),
                          ),
                        ),
                      _buildConcentricRow(
                        child: SwipeTile(
                          id: 'settings_swipe_demo',
                          menuItems: <CometChatOption>[
                            CometChatOption(
                              id: 'pin',
                              title: 'Pin',
                              backgroundColor: colorScheme.primary,
                              iconWidget: ExcludeSemantics(
                                child: Icon(
                                  Icons.push_pin_outlined,
                                  size: 18,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              onClick: () {
                                setState(
                                  () => _lastSwipeAction = 'Tapped Pin action',
                                );
                              },
                            ),
                            CometChatOption(
                              id: 'mute',
                              title: 'Mute',
                              backgroundColor: ShowcaseTokens.warningAmber,
                              iconWidget: ExcludeSemantics(
                                child: Icon(
                                  Icons.notifications_off_outlined,
                                  size: 18,
                                  color: colorScheme.surfaceContainerLowest,
                                ),
                              ),
                              onClick: () {
                                setState(
                                  () => _lastSwipeAction = 'Tapped Mute action',
                                );
                              },
                            ),
                          ],
                          child: ConvoKitListItem(
                            id: 'settings_swipe_tile_item',
                            avatarName: 'SW',
                            avatarStyle: avatarStyle,
                            title: 'SwipeTile Demo',
                            style: rowStyle,
                            hideSeparator: true,
                            subtitleView: Text(
                              _lastSwipeAction,
                              style: ShowcaseTypography.rowSubtitle.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            tailView: ExcludeSemantics(
                              child: Icon(
                                Icons.swipe_left_outlined,
                                size: 20,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 4. Demo Data Controls
                  _buildSectionHeader(context, 'DEMO DATA'),
                  _buildGroupedCard(
                    context,
                    children: <Widget>[
                      _buildConcentricRow(
                        child: InkWell(
                          key: const Key('settings_reset_demo_button'),
                          borderRadius: BorderRadius.circular(
                            ShowcaseTokens.radiusNestedCard,
                          ),
                          onTap: () => _showResetConfirmDialog(context),
                          child: ConvoKitListItem(
                            id: 'settings_reset_demo_item',
                            avatarName: 'RS',
                            avatarStyle: ConvoKitAvatarStyle(
                              backgroundColor: colorScheme.error,
                              placeHolderTextColor: colorScheme.onError,
                            ),
                            title: 'Reset Demo Data',
                            style: rowStyle,
                            hideSeparator: true,
                            subtitleView: Text(
                              'Opens ConvoKitConfirmDialog to restore Atelier Studio seed',
                              style: ShowcaseTypography.rowSubtitle.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            tailView: ExcludeSemantics(
                              child: Icon(
                                Icons.restart_alt_rounded,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 5. Library Info & Capabilities
                  _buildSectionHeader(context, 'LIBRARY INFO & CAPABILITIES'),
                  _buildGroupedCard(
                    context,
                    children: <Widget>[
                      _buildConcentricRow(
                        child: ConvoKitListItem(
                          id: 'settings_library_version',
                          avatarName: 'CK',
                          avatarStyle: avatarStyle,
                          title: 'convokit 0.1.0',
                          style: rowStyle,
                          hideSeparator: false,
                          subtitleView: Text(
                            'Zero CometChat SDK / BLoC dependencies (Phase 7)',
                            style: ShowcaseTypography.rowSubtitle.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          tailView: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ConvoKitStatusIndicator(
                                width: 10,
                                height: 10,
                                style: ShowcaseTheme.statusIndicatorStyle(
                                  context,
                                  ringColor: colorScheme.surfaceContainerLow,
                                ),
                              ),
                              const SizedBox(width: ShowcaseTokens.spaceXs),
                              Text(
                                'Ready',
                                style: ShowcaseTypography.timestamp.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ShowcaseTokens.spaceMd,
                          ShowcaseTokens.spaceMd,
                          ShowcaseTokens.spaceMd,
                          ShowcaseTokens.spaceSm,
                        ),
                        child: Wrap(
                          spacing: ShowcaseTokens.spaceSm,
                          runSpacing: ShowcaseTokens.spaceSm,
                          children: <Widget>[
                            _CapabilityPill(
                              label: 'receipts: ${capabilities.receipts}',
                            ),
                            _CapabilityPill(
                              label: 'typing: ${capabilities.typing}',
                            ),
                            _CapabilityPill(
                              label: 'media: ${capabilities.media}',
                            ),
                            _CapabilityPill(
                              label: 'mediaDelete: ${capabilities.mediaDelete}',
                            ),
                            _CapabilityPill(
                              label: 'groups: ${capabilities.groups}',
                            ),
                            _CapabilityPill(
                              label: 'search: ${capabilities.search}',
                            ),
                            _CapabilityPill(
                              label:
                                  'messageCatchUp: ${capabilities.messageCatchUp}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CollapsingGlassHeader(
                title: 'Settings',
                scrollController: _scrollController,
                actions: widget.headerActions ?? const <GlassHeaderAction>[],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConvoKitActionBubble(
      text: label,
      style: ConvoKitActionBubbleStyle(
        backgroundColor: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(ShowcaseTokens.radiusFullPill),
        border: Border.all(color: colorScheme.outlineVariant),
        textStyle: ShowcaseTypography.timestamp.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
