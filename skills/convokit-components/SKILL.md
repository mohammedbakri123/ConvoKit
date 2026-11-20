---
name: convokit-components
description: >
  Use when working with atomic ConvoKit widgets: ConvoKitAvatar, ConvoKitBadge, ConvoKitDate, ConvoKitReceipt, ConvoKitStatusIndicator, ConvoKitListItem.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Atomic UI Components

Shared widgets available from `package:convokit/convokit_uikit.dart`.

## Available Components

- **`ConvoKitAvatar`**: Renders user/group avatar image with automatic fallback to monogram initials.
- **`ConvoKitBadge`**: Unread count badge with overflow handling (`99+`).
- **`ConvoKitDate`**: Relative and absolute date formatting for chat lists and message timestamps.
- **`ConvoKitReceipt`**: Sent, delivered, and read receipt status tick icons.
- **`ConvoKitStatusIndicator`**: Online, offline, and away presence indicators.
- **`ConvoKitListItem`**: Standardized list row tile with avatar, title, subtitle, date, and badge slots.
- **`ConvoKitConfirmDialog`**: Standard alert dialog for destructive actions (e.g. delete chat).
- **`ConvoKitShimmerEffect`**: Loading placeholder animations.
