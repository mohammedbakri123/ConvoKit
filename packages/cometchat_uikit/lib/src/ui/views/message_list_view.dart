/// MessageListView widget according to API-DESIGN.md §5.5, §12.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/convo_kit.dart';
import '../../core/event_hub.dart';
import '../../core/message_coordinator.dart';
import '../../core/message_list_controller.dart';
import '../../core/models/models.dart';
import '../../core/stores/stores.dart';
import '../convo_kit_scope.dart';

class MessageListView extends StatefulWidget {
  final String conversationId;
  final MessageListController? controller;
  final dynamic style;
  final void Function(ChatMessage message)? onMessageTap;
  final void Function(ChatMessage message)? onMessageLongPress;
  final Widget Function(BuildContext context, ChatMessage message)?
  messageBuilder;

  const MessageListView({
    super.key,
    required this.conversationId,
    this.controller,
    this.style,
    this.onMessageTap,
    this.onMessageLongPress,
    this.messageBuilder,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  EventHub? _hub;
  MessageStore? _store;
  MessageCoordinator? _coordinator;

  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<bool>? _gapSub;

  List<ChatMessage> _messages = const [];
  bool _hasPossibleGap = false;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initWiring();
  }

  void _initWiring() {
    final hub = ConvoKitScope.hubOf(context);
    if (_hub != hub) {
      _cleanup();
      _hub = hub;
      _coordinator = hub.coordinator;
      _store = hub.getMessageStore(widget.conversationId);

      hub.registerVisibleConversation(widget.conversationId);
      widget.controller?.attach(
        store: _store!,
        coordinator: _coordinator!,
        conversationId: widget.conversationId,
      );

      _messagesSub = _store!.stream.listen((msgs) {
        if (!mounted) return;
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
      });

      _gapSub = _store!.gapStream.listen((gap) {
        if (!mounted) return;
        setState(() {
          _hasPossibleGap = gap;
        });
      });

      _messages = _store!.messages;
      _hasPossibleGap = _store!.hasPossibleGap;

      if (_messages.isEmpty) {
        _coordinator!.fetchLatest(widget.conversationId).then((_) {
          if (!mounted) return;
          setState(() {
            _messages = _store!.messages;
            _isLoading = false;
          });
        });
      } else {
        _isLoading = false;
      }
    }
  }

  void _cleanup() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _gapSub?.cancel();
    _gapSub = null;
    if (_hub != null) {
      _hub!.unregisterVisibleConversation(widget.conversationId);
      widget.controller?.detach();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = ConvoKitScope.of(context);
    final coordinator = _coordinator ?? _hub?.coordinator;

    return Material(
      child: Column(
        children: [
          if (_hasPossibleGap && coordinator != null)
            _buildGapBanner(context, coordinator),
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('No messages'))
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageItem(
                        context,
                        message,
                        kit,
                        coordinator,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapBanner(BuildContext context, MessageCoordinator coordinator) {
    return Container(
      key: const Key('gap_banner'),
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Some messages may be missing',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
          TextButton(
            key: const Key('gap_banner_refresh'),
            onPressed: () => coordinator.refresh(widget.conversationId),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message,
    ConvoKit kit,
    MessageCoordinator? coordinator,
  ) {
    if (widget.messageBuilder != null) {
      return widget.messageBuilder!(context, message);
    }

    final isMe = message.sender.id == kit.session.currentUser?.id;
    final showReceipts = kit.capabilities.receipts;

    Widget? indicator;
    if (isMe) {
      if (message.sendState == SendState.sending) {
        indicator = const SizedBox(
          key: Key('indicator_sending'),
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      } else if (message.sendState == SendState.failed) {
        indicator = Row(
          key: const Key('indicator_failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 16, color: Colors.red),
            const SizedBox(width: 4),
            IconButton(
              key: Key('retry_${message.localId}'),
              icon: const Icon(Icons.refresh, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                coordinator?.retryFailed(
                  message.localId,
                  conversationId: widget.conversationId,
                );
              },
            ),
          ],
        );
      } else if (message.sendState == SendState.sent && showReceipts) {
        // Only render receipt ticks if capabilities.receipts == true
        if (message.deliveryState == DeliveryState.read) {
          indicator = const Icon(
            Icons.done_all,
            key: Key('receipt_read'),
            size: 16,
            color: Colors.blue,
          );
        } else if (message.deliveryState == DeliveryState.delivered) {
          indicator = const Icon(
            Icons.done_all,
            key: Key('receipt_delivered'),
            size: 16,
            color: Colors.grey,
          );
        } else {
          indicator = const Icon(
            Icons.check,
            key: Key('receipt_sent'),
            size: 16,
            color: Colors.grey,
          );
        }
      }
    }

    final content = switch (message) {
      TextMessage t => Text(t.text),
      MediaMessage m => Text(m.caption ?? m.attachment.name ?? 'Media'),
      CustomMessage c => Text(c.kind),
    };

    return InkWell(
      onTap: () => widget.onMessageTap?.call(message),
      onLongPress: () => widget.onMessageLongPress?.call(message),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  if (indicator != null) ...[
                    const SizedBox(width: 6),
                    indicator,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
