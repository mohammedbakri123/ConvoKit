import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';

/// Configuration for status indicator display.
class StatusIndicatorConfig {
  final bool show;
  final Color? color;
  final Widget? icon;

  const StatusIndicatorConfig({required this.show, this.color, this.icon});
}

/// Utility class for determining status indicator configuration.
class StatusIndicatorHelper {
  static StatusIndicatorConfig getStatusIndicator({
    required ChatConversation conversation,
    required bool hideUserStatus,
    required bool hideGroupType,
    UserPresence? presenceOverride,
  }) {
    if (conversation.peer != null) {
      return _getUserStatusIndicator(
        conversation.peer!,
        hideUserStatus,
        presenceOverride: presenceOverride,
      );
    }
    if (conversation.group != null) {
      return _getGroupStatusIndicator(conversation.group!, hideGroupType);
    }
    return const StatusIndicatorConfig(show: false);
  }

  static StatusIndicatorConfig _getUserStatusIndicator(
    ChatUser user,
    bool hideUserStatus, {
    UserPresence? presenceOverride,
  }) {
    if (hideUserStatus) {
      return const StatusIndicatorConfig(show: false);
    }

    final effectivePresence = presenceOverride ?? user.presence;
    final isOnline = effectivePresence == UserPresence.online;
    return StatusIndicatorConfig(
      show: isOnline,
      color: isOnline ? Colors.green : null,
      icon: null,
    );
  }

  static StatusIndicatorConfig _getGroupStatusIndicator(
    ChatGroup group,
    bool hideGroupType,
  ) {
    if (hideGroupType) {
      return const StatusIndicatorConfig(show: false);
    }

    if (group.type == GroupType.private) {
      return const StatusIndicatorConfig(
        show: true,
        icon: Icon(Icons.lock, size: 12, color: Colors.white),
      );
    }

    return const StatusIndicatorConfig(show: false);
  }
}
