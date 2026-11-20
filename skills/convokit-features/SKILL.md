---
name: convokit-features
description: >
  Use when negotiating backend capabilities with ChatCapabilities, gating UI features, or handling unsupported capabilities.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Feature Capabilities

ConvoKit uses explicit capability negotiation via `ChatCapabilities`.

## Capability Invariant: Fail-Closed

The default constructor `ChatCapabilities()` has **all capabilities disabled (false)**.
Nothing is enabled implicitly. To enable features, explicitly set flags or use `ChatCapabilities.basic()`.

```dart
// Full-featured backend
final allFeatures = ChatCapabilities.basic();

// Constrained backend (text-only direct chat)
const minimal = ChatCapabilities(
  receipts: false,
  typing: false,
  media: false,
  groups: false,
  search: false,
);
```

## Capability Table

| Flag | Feature | When `false` (Unsupported) |
|------|---------|----------------------------|
| `receipts` | Delivered/read receipt ticks | UI completely hides ticks (including single sent tick) |
| `typing` | Typing indicator | UI hides "typing..." indicators, composer never emits typing |
| `media` | Attachment tray, file sending | Attach button is hidden; incoming media still renders |
| `mediaDelete` | Deleting uploaded media | Delete option hidden on media messages |
| `groups` | Group chats, member lists | Groups tab and group creation UI completely hidden |
| `search` | User search | Search input hidden; displays static list |
| `messageCatchUp` | Newer-page reconnect catch-up | Falls back to latest refresh + merge |
