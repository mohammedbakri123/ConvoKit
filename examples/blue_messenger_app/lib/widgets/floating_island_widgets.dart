import 'package:flutter/material.dart';

import '../theme/blue_messenger_theme.dart';

/// Rounded, softly shadowed floating card container used across Blue Messenger
/// to wrap library components in a modern floating-island aesthetic.
class FloatingIslandCard extends StatelessWidget {
  const FloatingIslandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    this.radius = 24,
    this.color = BlueMessengerColors.islandSurface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BlueIslandDecorations.island(color: color, radius: radius),
      child: child,
    );
  }
}

/// Floating search pill hovering above content lists; tapping opens
/// [CometChatSearch].
class FloatingSearchPill extends StatelessWidget {
  const FloatingSearchPill({
    super.key,
    required this.onTap,
    this.placeholder = 'Search messages, contacts, or groups...',
    this.trailing,
  });

  final VoidCallback onTap;
  final String placeholder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        decoration: BlueIslandDecorations.floatingPill(radius: 28),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            key: const Key('blue_floating_search_pill'),
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: BlueMessengerColors.chipFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: BlueMessengerColors.deepBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: BlueMessengerColors.textSecondary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destination metadata for [FloatingIslandNavBar].
class FloatingNavDestination {
  const FloatingNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;
}

/// Detached floating pill bottom navigation bar hovering above the screen edge
/// with soft shadows, rounded corners, and an animated blue pill indicator.
class FloatingIslandNavBar extends StatelessWidget {
  const FloatingIslandNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<FloatingNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          key: const Key('blue_floating_island_nav'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BlueIslandDecorations.floatingPill(radius: 34),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List<Widget>.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = index == selectedIndex;
              return Expanded(
                child: InkWell(
                  key: Key('blue_nav_tab_${item.label.toLowerCase()}'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => onDestinationSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BlueMessengerColors.activeChipFill
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? BlueMessengerColors.deepBlue
                                  : BlueMessengerColors.textSecondary,
                            ),
                            if (item.badgeCount > 0)
                              Positioned(
                                right: -8,
                                top: -5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BlueMessengerColors.royalBlue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? BlueMessengerColors.deepBlue
                                : BlueMessengerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
