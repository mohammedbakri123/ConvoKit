---
name: convokit-troubleshooting
description: >
  Use when diagnosing ConvoKit errors, constructor validation failures, or widget tree exceptions.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Troubleshooting & FAQs

Diagnosing and fixing common integration errors.

## `ArgumentError: groups provider and capabilities.groups disagree`
- **Cause**: `capabilities.groups` is `true`, but `groups` repository parameter was `null` (or vice-versa).
- **Fix**: Either provide a `GroupRepository` or set `capabilities.groups: false`.

## `ArgumentError: media provider and capabilities.media disagree`
- **Cause**: `capabilities.media` is `true`, but `media` provider was `null`.
- **Fix**: Provide a `ChatMediaProvider` or set `capabilities.media: false`.

## `StateError: No ConvoKitScope found in context`
- **Cause**: A widget (`ConversationsView`, `MessageListView`) attempted to access `ConvoKitScope.of(context)` without an ancestor scope.
- **Fix**: Wrap your application or feature module in `ConvoKitScope(kit: kit, child: ...)`.

## Receipt ticks are not appearing on sent messages
- **Cause**: `ChatCapabilities.receipts` is set to `false` (the default).
- **Fix**: Ensure your backend reports `receipts: true` in `ChatCapabilities`.
