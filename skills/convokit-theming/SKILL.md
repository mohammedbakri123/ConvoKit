---
name: convokit-theming
description: >
  Use when customizing colors, fonts, spacing, dark mode, or themes in ConvoKit.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Theming & Styling

Customizing the visual appearance of ConvoKit components.

## Theme Architecture

ConvoKit uses a structured theme system:
- `ConvoKitTheme`: The root inherited theme containing color palette, typography, and spacing.
- `ConvoKitColorPalette`: Semantic colors (`primary`, `background1`, `textPrimary`, etc.).
- `ConvoKitTypography`: Standardized text styles.
- `ConvoKitSpacing`: Spacing scale.

## Applying a Theme

Wrap your UI in `ConvoKitTheme`:

```dart
ConvoKitTheme(
  data: ConvoKitThemeData(
    palette: ConvoKitColorPalette.light(
      primary: Colors.deepPurple,
      accent: Colors.amber,
    ),
  ),
  child: const ConversationsView(),
)
```

## Dark Mode Support

ConvoKit provides built-in dark palettes:

```dart
final palette = isDarkMode
    ? ConvoKitColorPalette.dark()
    : ConvoKitColorPalette.light();
```
