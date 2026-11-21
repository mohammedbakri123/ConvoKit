/// ConvoKitScope StatefulWidget according to API-DESIGN.md §11.2.
library;

import 'package:flutter/widgets.dart';

import '../core/convo_kit.dart';
import '../core/event_hub.dart';

class ConvoKitScope extends StatefulWidget {
  final ConvoKit kit;
  final Widget child;

  /// Host-supplied signed-out UI. Rendered instead of `child` when the
  /// session has no current user. If null, `child` renders regardless.
  final Widget Function(BuildContext context)? signedOutBuilder;

  const ConvoKitScope({
    super.key,
    required this.kit,
    required this.child,
    this.signedOutBuilder,
  });

  static ConvoKit? maybeOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_ConvoKitInherited>();
    return inherited?.kit;
  }

  static ConvoKit of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_ConvoKitInherited>();
    if (inherited == null) {
      throw StateError(
        'ConvoKitScope.of() called with a context that does not contain a ConvoKitScope.',
      );
    }
    return inherited.kit;
  }

  /// Internal accessor for EventHub in descendants.
  static EventHub hubOf(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<_ConvoKitInherited>();
    if (inherited == null) {
      throw StateError(
        'ConvoKitScope.hubOf() called with a context that does not contain a ConvoKitScope.',
      );
    }
    return inherited.hub;
  }

  @override
  State<ConvoKitScope> createState() => _ConvoKitScopeState();
}

class _ConvoKitScopeState extends State<ConvoKitScope> {
  /// Created once in initState. Survives rebuilds.
  late final EventHub _hub;

  @override
  void initState() {
    super.initState();
    _hub = EventHub();
    _hub.attach(widget.kit);
  }

  @override
  void didUpdateWidget(ConvoKitScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Kit identity change (identical() comparison): full reattach —
    // teardown, clear stores, attach new kit, connect if signed in.
    if (!identical(widget.kit, oldWidget.kit)) {
      _hub.reattach(widget.kit);
    }
  }

  @override
  void dispose() {
    _hub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Internal inherited provider — exposes kit (+ hub, internally) to descendants.
    // Nesting scopes is unsupported and debug-asserted: one scope per subtree.
    assert(
      context.findAncestorWidgetOfExactType<ConvoKitScope>() == null,
      'Nesting ConvoKitScope widgets is unsupported. Only one ConvoKitScope per app subtree.',
    );

    final hasUser = widget.kit.session.currentUser != null;
    final effectiveChild = (!hasUser && widget.signedOutBuilder != null)
        ? widget.signedOutBuilder!(context)
        : widget.child;

    return _ConvoKitInherited(
      kit: widget.kit,
      hub: _hub,
      child: effectiveChild,
    );
  }
}

class _ConvoKitInherited extends InheritedWidget {
  final ConvoKit kit;
  final EventHub hub;

  const _ConvoKitInherited({
    required this.kit,
    required this.hub,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ConvoKitInherited oldWidget) =>
      !identical(kit, oldWidget.kit) || !identical(hub, oldWidget.hub);
}
