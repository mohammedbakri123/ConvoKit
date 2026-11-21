import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import '../theme/blue_messenger_theme.dart';
import '../widgets/floating_island_widgets.dart';

/// Floating-island search screen powered by [CometChatSearch] and
/// [SearchFilterChip].
class BlueSearchScreen extends StatefulWidget {
  const BlueSearchScreen({
    super.key,
    required this.onUserSelected,
  });

  final ValueChanged<ChatUser> onUserSelected;

  @override
  State<BlueSearchScreen> createState() => _BlueSearchScreenState();
}

class _BlueSearchScreenState extends State<BlueSearchScreen> {
  String _activeScope = 'People';
  static const List<String> _scopes = ['People', 'Online', 'Groups'];

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);

    return Scaffold(
      backgroundColor: BlueMessengerColors.canvasBackground,
      appBar: AppBar(
        backgroundColor: BlueMessengerColors.canvasBackground,
        foregroundColor: BlueMessengerColors.deepBlue,
        title: const Text('Search Blue Messenger'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final scope in _scopes) ...[
                    SearchFilterChip(
                      label: scope,
                      icon: scope == 'People'
                          ? Icons.person_outline_rounded
                          : scope == 'Online'
                              ? Icons.circle
                              : Icons.groups_outlined,
                      isSelected: _activeScope == scope,
                      onTap: () => setState(() => _activeScope = scope),
                      colorPalette: palette,
                      spacing: spacing,
                      typography: typography,
                      selectedColor: BlueMessengerColors.activeChipFill,
                      unselectedColor: BlueMessengerColors.islandSurface,
                      selectedTextColor: BlueMessengerColors.deepBlue,
                      unselectedTextColor: BlueMessengerColors.textSecondary,
                      selectedIconColor: BlueMessengerColors.deepBlue,
                      unselectedIconColor: BlueMessengerColors.textSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: FloatingIslandCard(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 16),
              radius: 28,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: CometChatSearch(
                  onBack: () => Navigator.of(context).pop(),
                  onUserClicked: (user) {
                    Navigator.of(context).pop();
                    widget.onUserSelected(user);
                  },
                  searchStyle: CometChatSearchStyle(
                    backgroundColor: BlueMessengerColors.islandSurface,
                    searchBackgroundColor: BlueMessengerColors.chipFill,
                    searchBorderRadius: BorderRadius.circular(24),
                    searchTextColor: BlueMessengerColors.textPrimary,
                    searchPlaceHolderTextColor:
                        BlueMessengerColors.textSecondary,
                    searchBackIconColor: BlueMessengerColors.deepBlue,
                    searchClearIconColor: BlueMessengerColors.royalBlue,
                    sectionHeaderTextColor: BlueMessengerColors.deepBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
