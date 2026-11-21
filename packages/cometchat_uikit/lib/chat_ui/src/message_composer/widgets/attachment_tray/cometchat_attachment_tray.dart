import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The composer strip that shows staged attachment tiles, rendered directly
/// above the input row. Driven by an [AttachmentTrayController]; rebuilds as
/// upload/send events arrive and renders nothing while empty.
class ConvoKitAttachmentTray extends StatelessWidget {
  @Deprecated(
    'Has no effect. The tray has no add button. Will be removed in 7.0.0.',
  )
  final VoidCallback? onAdd;

  @Deprecated(
    'Has no effect. The tray has no send button; the composer calls onAttachmentTraySend. Will be removed in 7.0.0.',
  )
  final VoidCallback? onSend;

  const ConvoKitAttachmentTray({
    super.key,
    required this.controller,
    this.style,
    this.attachmentErrorAlertStyle,
    this.attachmentErrorSnackBarBuilder,
    this.onAttachmentErrorTap,
    this.onRetryTile,
    this.onAdd,
    this.onSend,
  });

  final AttachmentTrayController controller;
  final ConvoKitAttachmentTrayStyle? style;
  final CometChatAttachmentErrorAlertStyle? attachmentErrorAlertStyle;
  final SnackBar Function(BuildContext context, AttachmentTile tile)?
  attachmentErrorSnackBarBuilder;
  final void Function(BuildContext context, AttachmentTile tile)?
  onAttachmentErrorTap;

  /// Optional override invoked when tapping a failed or send-failed tile.
  final void Function(AttachmentTile tile)? onRetryTile;

  void _showError(BuildContext context, AttachmentTile tile) {
    if (onAttachmentErrorTap != null) {
      onAttachmentErrorTap!(context, tile);
      return;
    }
    if (attachmentErrorSnackBarBuilder != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(attachmentErrorSnackBarBuilder!(context, tile));
      return;
    }
    CometChatAttachmentErrorSnackBar.show(
      context,
      tile: tile,
      style: attachmentErrorAlertStyle,
    );
  }

  void _openPreview(BuildContext context, AttachmentTile tapped) {
    final mediaTiles = controller.tiles
        .where((t) => t.isImage || t.isVideo)
        .toList();
    final items = <ChatAttachment>[];
    var start = 0;
    for (final t in mediaTiles) {
      final url = (t.thumbUrl != null && t.thumbUrl!.isNotEmpty)
          ? t.thumbUrl!
          : (t.attachment?.url ?? '');
      if (url.isEmpty) continue;
      if (t.fileId == tapped.fileId) start = items.length;
      items.add(
        t.attachment ??
            ChatAttachment(
              id: t.fileId,
              kind: t.kind,
              localPath: t.localPath ?? url,
              state: AttachmentState.local,
              mimeType: t.mimeType,
              sizeBytes: t.size,
              name: t.name,
            ),
      );
    }
    if (items.isEmpty) return;
    // Open full-screen image/video dialog preview without legacy SDK types.
    final initial = items[start.clamp(0, items.length - 1)];
    final previewSource = initial.localPath ?? initial.url ?? '';
    if (previewSource.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: initial.kind == AttachmentKind.image &&
                      (previewSource.startsWith('http://') ||
                          previewSource.startsWith('https://'))
                  ? Image.network(
                      previewSource,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        initial.name ?? previewSource,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tiles = controller.tiles;
        if (tiles.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
          child: SizedBox(
            height: 78,
            child: _HorizontalWheelScroller(
              builder: (context, scrollController) => ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: tiles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = tiles[i];
                  final previewable = t.isImage || t.isVideo;
                  final retryable =
                      t.status == AttachmentTileStatus.failed ||
                      t.status == AttachmentTileStatus.sendFailed;
                  return ConvoKitAttachmentTile(
                    tile: t,
                    onCancelOrRemove: () => controller.cancelOrRemove(t.fileId),
                    onTap: previewable ? () => _openPreview(context, t) : null,
                    onErrorInteract: t.status == AttachmentTileStatus.rejected
                        ? () => _showError(context, t)
                        : null,
                    onRetry: retryable
                        ? () {
                            if (onRetryTile != null) {
                              onRetryTile!(t);
                            } else {
                              controller.retry(t.fileId);
                            }
                          }
                        : null,
                    style: style,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalWheelScroller extends StatefulWidget {
  const _HorizontalWheelScroller({required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<_HorizontalWheelScroller> createState() =>
      _HorizontalWheelScrollerState();
}

class _HorizontalWheelScrollerState extends State<_HorizontalWheelScroller> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;
    final target = (_controller.offset + delta).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: ScrollConfiguration(
        behavior: _MouseDragScrollBehavior(),
        child: widget.builder(context, _controller),
      ),
    );
  }
}

class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}
