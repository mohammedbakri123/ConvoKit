---
name: convokit-production
description: >
  Use when preparing ConvoKit apps for production deployment, release builds, and offline resilience.
license: "MIT"
compatibility: "flutter >=3.38.9; dart >=3.10.8; convokit 0.1.0"
allowed-tools: "executeBash, readFile, readCode, fileSearch, listDirectory, grepSearch"
metadata:
  author: "ConvoKit"
  version: "0.1.0"
  tags: "convokit flutter chat messaging contracts"
---

# ConvoKit Production Readiness

Production checklist and best practices.

## 1. Release-Safe Validation
ConvoKit validates providers and capabilities at construction time in release builds. Always verify in test suites that constructor constraints are met.

## 2. Error Handling Convention
Always inspect `ChatResult` return values. Never ignore failures:
```dart
final result = await kit.messages.sendMessage(msg);
if (result.isFailure) {
  logError(result.errorOrNull!);
}
```

## 3. Network Disconnects & Reconnects
ConvoKit handles reconnect recovery automatically via the `EventHub`. Ensure your `ChatEventSource` emits accurate `ConnectionStatus` changes (`connected`, `connecting`, `disconnected`).

## 4. Scope Cleanup
When logging a user out, update the session stream with `null` to trigger automatic store cleanup and disconnection:
```dart
sessionController.add(null);
```
