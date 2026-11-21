import 'dart:async';

import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

import 'message_composer_auxiliary_buttons.dart';
import 'message_composer_secondary_buttons.dart';
import 'message_composer_send_button.dart';

/// [ConvoKitMessageComposer] composes and sends text and media messages
/// directly through [MessageCoordinator] and [ConvoKit.media] via
/// [ConvoKitScope].
///
/// - Text send -> [MessageCoordinator.sendTextMessage]
/// - Media upload + send -> two-step flow via [AttachmentTrayController]
///   (`ChatMediaProvider.upload` -> [MessageCoordinator.sendMediaMessage])
/// - Typing events -> [MessageRepository.sendTyping] gated on `capabilities.typing`
/// - Attachment & voice recording buttons hidden when `kit.media == null || !capabilities.media`
class ConvoKitMessageComposer extends StatefulWidget {
  @Deprecated(
    'Has no effect. The Flutter composer has no AI button; add your own through auxiliaryButtonView. Will be removed in 7.0.0.',
  )
  final Widget? aiIcon;

  @Deprecated(
    'Has no effect. The Flutter composer has no AI button; add your own through auxiliaryButtonView. Will be removed in 7.0.0.',
  )
  final String? aiIconURL;

  @Deprecated(
    'Has no effect. The Flutter composer has no AI button; add your own through auxiliaryButtonView. Will be removed in 7.0.0.',
  )
  final String? aiIconPackageName;

  const ConvoKitMessageComposer({
    super.key,
    this.conversationId,
    this.user,
    this.group,
    this.controller,
    this.messageComposerStyle,
    this.placeholderText,
    this.disableTypingEvents = false,
    this.disableSoundForMessages = false,
    this.parentMessageId = 0,
    this.customSoundForMessage,
    this.customSoundForMessagePackage,
    this.auxiliaryButtonView,
    this.headerView,
    this.footerView,
    this.secondaryButtonView,
    this.sendButtonView,
    this.attachmentOptions,
    this.richTextToolbarActions,
    this.text,
    this.onChange,
    this.maxLine,
    this.auxiliaryButtonsAlignment,
    this.attachmentIconURL,
    this.stateCallBack,
    this.attachmentIcon,
    this.onError,
    this.onSendButtonTap,
    this.hideVoiceRecordingButton,
    this.useInlineAudioRecorder = true,
    this.voiceRecordingIcon,
    this.textFormatters,
    this.disableMentions,
    this.textEditingController,
    this.padding,
    this.messageInputPadding,
    this.recorderStartButtonIcon,
    this.recorderPauseButtonIcon,
    this.recorderDeleteButtonIcon,
    this.recorderStopButtonIcon,
    this.recorderSendButtonIcon,
    this.hideSendButton,
    this.hideAttachmentButton,
    this.hideStickersButton,
    this.stickerIcon,
    this.stickerActiveIcon,
    this.hideAudioAttachmentOption,
    this.hideFileAttachmentOption,
    this.hideImageAttachmentOption,
    this.hideVideoAttachmentOption,
    this.hidePollsOption,
    this.hideCollaborativeDocumentOption,
    this.hideCollaborativeWhiteboardOption,
    this.hideTakePhotoOption,
    this.sendButtonIcon,
    this.disableMentionAll = false,
    this.mentionAllLabel,
    this.mentionAllLabelId,
    this.enableRichTextFormatting = true,
    this.showRichTextFormattingOptions = true,
    this.hideRichTextFormattingOptions = const {},
    this.richTextToolbarView,
    this.onRichTextFormatApplied,
    this.hideBottomSafeArea = false,
    this.resizeToAvoidBottomInset = true,
    this.layout = CometChatComposerLayout.singleLine,
    this.onKeyboardDiagnostics,
    this.enableMultipleAttachments = true,
    this.attachmentTrayController,
    this.onAttachmentTrayAdd,
    this.onAttachmentTraySend,
    this.onAttachmentTap,
    this.replyMessage,
    this.onClearReply,
    this.disableImagePaste = false,
    this.disableDragAndDrop = false,
    this.attachmentErrorAlertStyle,
    this.attachmentErrorSnackBarBuilder,
    this.onAttachmentErrorTap,
    this.aiIcon,
    this.aiIconURL,
    this.aiIconPackageName,
  }) : assert(
         conversationId != null || user != null || group != null,
         'One of conversationId, user, or group should be passed',
       );

  final String? conversationId;
  final ChatUser? user;
  final ChatGroup? group;
  final MessageComposerController? controller;
  final bool enableMultipleAttachments;
  final AttachmentTrayController? attachmentTrayController;
  final VoidCallback? onAttachmentTrayAdd;
  final VoidCallback? onAttachmentTraySend;
  final VoidCallback? onAttachmentTap;
  final ChatMessage? replyMessage;
  final VoidCallback? onClearReply;
  final bool disableImagePaste;
  final bool disableDragAndDrop;
  final CometChatAttachmentErrorAlertStyle? attachmentErrorAlertStyle;
  final SnackBar Function(BuildContext context, AttachmentTile tile)?
  attachmentErrorSnackBarBuilder;
  final void Function(BuildContext context, AttachmentTile tile)?
  onAttachmentErrorTap;
  final ConvoKitMessageComposerStyle? messageComposerStyle;
  final ComposerWidgetBuilder? auxiliaryButtonView;
  final ComposerWidgetBuilder? secondaryButtonView;
  final Widget? sendButtonView;
  final String? text;
  final String? placeholderText;
  final void Function(String text)? onChange;
  final int? maxLine;
  final AuxiliaryButtonsAlignment? auxiliaryButtonsAlignment;
  final String? attachmentIconURL;
  final Widget? attachmentIcon;
  final bool? hideVoiceRecordingButton;
  final bool useInlineAudioRecorder;
  final Widget? voiceRecordingIcon;
  final int parentMessageId;
  final bool? disableMentions;
  final TextEditingController? textEditingController;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? messageInputPadding;
  final String? customSoundForMessage;
  final String? customSoundForMessagePackage;
  final bool disableSoundForMessages;
  final bool disableTypingEvents;
  final ComposerWidgetBuilder? headerView;
  final ComposerWidgetBuilder? footerView;
  final ComposerActionsBuilder? attachmentOptions;
  final ComposerActionsBuilder? richTextToolbarActions;
  final void Function(MessageComposerController controller)? stateCallBack;
  final OnError? onError;
  final void Function(
    BuildContext context,
    ChatMessage message,
    PreviewMessageMode? previewMessageMode,
  )?
  onSendButtonTap;
  final List<CometChatTextFormatter>? textFormatters;
  final Widget? recorderStartButtonIcon;
  final Widget? recorderPauseButtonIcon;
  final Widget? recorderDeleteButtonIcon;
  final Widget? recorderStopButtonIcon;
  final Widget? recorderSendButtonIcon;
  final bool? hideSendButton;
  final bool? hideAttachmentButton;
  final bool? hideStickersButton;
  final Widget? stickerIcon;
  final Widget? stickerActiveIcon;
  final bool? hideImageAttachmentOption;
  final bool? hideVideoAttachmentOption;
  final bool? hideAudioAttachmentOption;
  final bool? hideFileAttachmentOption;
  final bool? hidePollsOption;
  final bool? hideCollaborativeDocumentOption;
  final bool? hideCollaborativeWhiteboardOption;
  final bool? hideTakePhotoOption;
  final Widget? sendButtonIcon;
  final bool disableMentionAll;
  final String? mentionAllLabel;
  final String? mentionAllLabelId;
  final bool enableRichTextFormatting;
  final bool showRichTextFormattingOptions;
  final Set<FormatType> hideRichTextFormattingOptions;
  final Widget Function(BuildContext context, TextEditingController controller)?
  richTextToolbarView;
  final void Function(FormatType formatType)? onRichTextFormatApplied;
  final bool hideBottomSafeArea;
  final bool resizeToAvoidBottomInset;
  final CometChatComposerLayout layout;
  final CometChatKeyboardDiagnosticsCallback? onKeyboardDiagnostics;

  String get resolvedConversationId =>
      conversationId ?? group?.id ?? user?.id ?? '';

  @override
  State<ConvoKitMessageComposer> createState() =>
      _ConvoKitMessageComposerState();
}

class _ConvoKitMessageComposerState extends State<ConvoKitMessageComposer> {
  MessageComposerController? _ownedController;
  TextEditingController? _ownedTextController;
  AttachmentTrayController? _ownedTrayController;

  MessageComposerController get _controller =>
      widget.controller ?? _ownedController!;
  TextEditingController get _textController =>
      widget.textEditingController ?? _ownedTextController!;
  AttachmentTrayController? get _trayController =>
      widget.attachmentTrayController ?? _ownedTrayController;

  ConvoKit? _kit;
  EventHub? _hub;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = MessageComposerController(
        initialText: widget.text ?? '',
        initialReplyMessage: widget.replyMessage,
      );
    } else if (widget.replyMessage != null) {
      widget.controller!.setReplyMessage(widget.replyMessage);
    }

    if (widget.textEditingController == null) {
      _ownedTextController = TextEditingController(text: widget.text ?? '');
    } else if (widget.text != null && widget.textEditingController!.text.isEmpty) {
      widget.textEditingController!.text = widget.text!;
    }

    if (widget.enableMultipleAttachments &&
        widget.attachmentTrayController == null) {
      _ownedTrayController = AttachmentTrayController(
        conversationId: widget.resolvedConversationId,
      );
    }

    _textController.addListener(_onTextChanged);
    widget.stateCallBack?.call(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _kit = ConvoKitScope.of(context);
    _hub = ConvoKitScope.hubOf(context);
    _syncTrayBindings();
  }

  @override
  void didUpdateWidget(covariant ConvoKitMessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolvedConversationId != widget.resolvedConversationId) {
      _controller.stopTyping(
        kit: _kit,
        conversationId: oldWidget.resolvedConversationId,
      );
      unawaited(_trayController?.clear());
      _syncTrayBindings();
    }
    if (oldWidget.replyMessage != widget.replyMessage) {
      _controller.setReplyMessage(widget.replyMessage);
    }
  }

  void _syncTrayBindings() {
    final tray = _trayController;
    if (tray == null) return;
    tray.conversationId = widget.resolvedConversationId;
    tray.mediaProvider = _kit?.media;
  }

  void _onTextChanged() {
    final value = _textController.text;
    widget.onChange?.call(value);
    _trayController?.setCaption(value);
    _controller.updateText(
      value,
      kit: _kit,
      conversationId: widget.resolvedConversationId,
      disableTypingEvents: widget.disableTypingEvents,
    );
  }

  Future<void> _handleSend() async {
    final kit = _kit;
    final hub = _hub;
    if (kit == null || hub == null) return;

    final conversationId = widget.resolvedConversationId;
    final tray = _trayController;

    // 1. If the attachment tray has staged files, send them via the two-step flow.
    if (tray != null && tray.tiles.isNotEmpty) {
      if (!tray.canSend) return;
      if (widget.onAttachmentTraySend != null) {
        widget.onAttachmentTraySend!.call();
        return;
      }
      final sender = kit.session.currentUser;
      if (sender == null) return;

      tray.setCaption(_textController.text);
      _textController.clear();
      _controller.stopTyping(kit: kit, conversationId: conversationId);
      final repliedTo = _controller.replyMessage;
      _controller.clearReplyMessage();

      final results = await tray.sendAll(
        coordinator: hub.coordinator,
        conversationId: conversationId,
        sender: sender,
        repliedTo: repliedTo,
      );
      for (final res in results) {
        res.fold(
          onSuccess: (msg) {
            widget.onSendButtonTap?.call(context, msg, null);
          },
          onFailure: (err) {
            widget.onError?.call(Exception(err.message));
          },
        );
      }
      return;
    }

    // 2. Otherwise send text message via MessageCoordinator.sendTextMessage.
    final rawText = _textController.text;
    if (rawText.trim().isEmpty) return;

    _textController.clear();
    final result = await _controller.sendText(
      kit: kit,
      coordinator: hub.coordinator,
      conversationId: conversationId,
      overrideText: rawText,
    );
    result?.fold(
      onSuccess: (msg) {
        widget.onSendButtonTap?.call(context, msg, null);
      },
      onFailure: (err) {
        widget.onError?.call(Exception(err.message));
      },
    );
  }

  Future<void> _handleAudioSubmit(String filePath, {List<int>? fileBytes}) async {
    final kit = _kit;
    final hub = _hub;
    _controller.stopAudioRecording();
    if (kit == null || hub == null) return;

    final result = await _controller.sendLocalMedia(
      kit: kit,
      coordinator: hub.coordinator,
      conversationId: widget.resolvedConversationId,
      localPath: filePath,
      kind: AttachmentKind.audio,
      name: filePath.split('/').last,
      mimeType: 'audio/m4a',
    );
    result.fold(
      onSuccess: (msg) {
        widget.onSendButtonTap?.call(context, msg, null);
      },
      onFailure: (err) {
        widget.onError?.call(Exception(err.message));
      },
    );
  }

  void _handleAttachmentTap() {
    if (widget.onAttachmentTap != null) {
      widget.onAttachmentTap!.call();
      return;
    }
    final actions = widget.attachmentOptions?.call(
      context,
      widget.user,
      widget.group,
      const {},
    );
    if (actions == null || actions.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final action in actions)
              ListTile(
                leading: action.icon,
                title: Text(action.title),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  action.onItemClick?.call(
                    context,
                    widget.user,
                    widget.group,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.stopTyping(
      kit: _kit,
      conversationId: widget.resolvedConversationId,
    );
    _textController.removeListener(_onTextChanged);
    _ownedTextController?.dispose();
    _ownedController?.dispose();
    _ownedTrayController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kit = _kit ?? ConvoKitScope.of(context);
    final hub = _hub ?? ConvoKitScope.hubOf(context);
    final colorPalette = ConvoKitThemeHelper.getColorPalette(context);
    final spacing = ConvoKitThemeHelper.getSpacing(context);
    final typography = ConvoKitThemeHelper.getTypography(context);
    final style = ConvoKitThemeHelper.getTheme<ConvoKitMessageComposerStyle>(
      context: context,
      defaultTheme: ConvoKitMessageComposerStyle.of,
    ).merge(widget.messageComposerStyle);

    // Gate attachment & voice recording affordances on kit.media && capabilities.media.
    final mediaSupported = kit.media != null && kit.capabilities.media;
    final hideAttachment =
        (widget.hideAttachmentButton ?? false) || !mediaSupported;
    final hideVoice =
        (widget.hideVoiceRecordingButton ?? false) || !mediaSupported;

    final listenables = <Listenable>[
      _controller,
      _textController,
      ?_trayController,
    ];

    Widget content = ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final tray = _trayController;
        final hasTrayTiles = tray != null && tray.tiles.isNotEmpty;
        final canSend = hasTrayTiles
            ? tray.canSend
            : _textController.text.trim().isNotEmpty;

        if (_controller.isRecordingAudio && widget.useInlineAudioRecorder) {
          return CometChatInlineAudioRecorder(
            style: style.inlineAudioRecorderStyle,
            onSubmit: _handleAudioSubmit,
            onCancel: _controller.stopAudioRecording,
            deleteIcon: widget.recorderDeleteButtonIcon,
            sendIcon: widget.recorderSendButtonIcon,
            recordIcon: widget.recorderStartButtonIcon,
            pauseIcon: widget.recorderPauseButtonIcon,
            stopIcon: widget.recorderStopButtonIcon,
          );
        }

        final header = widget.headerView?.call(
          context,
          widget.user,
          widget.group,
          const {},
        );
        final footer = widget.footerView?.call(
          context,
          widget.user,
          widget.group,
          const {},
        );
        final customSecondary = widget.secondaryButtonView?.call(
          context,
          widget.user,
          widget.group,
          const {},
        );
        final customAuxiliary = widget.auxiliaryButtonView?.call(
          context,
          widget.user,
          widget.group,
          const {},
        );

        final reply = _controller.replyMessage;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            if (reply != null)
              Padding(
                padding: EdgeInsets.only(bottom: spacing.padding1 ?? 4),
                child: ConvoKitMessagePreview(
                  message: reply,
                  messagePreviewTitle: reply.sender.name,
                  messagePreviewSubtitle: switch (reply) {
                    TextMessage t => t.text,
                    MediaMessage m => m.caption ?? m.attachment.name ?? m.attachment.kind.name,
                    CustomMessage c => c.kind,
                  },
                  onCloseClick: () {
                    _controller.clearReplyMessage();
                    widget.onClearReply?.call();
                  },
                ),
              ),
            if (tray != null && mediaSupported)
              ConvoKitAttachmentTray(
                controller: tray,
                style: style.attachmentTrayStyle,
                attachmentErrorAlertStyle: widget.attachmentErrorAlertStyle,
                attachmentErrorSnackBarBuilder:
                    widget.attachmentErrorSnackBarBuilder,
                onAttachmentErrorTap: widget.onAttachmentErrorTap,
                onRetryTile: (tile) {
                  final sender = kit.session.currentUser;
                  unawaited(
                    tray.retry(
                      tile.fileId,
                      coordinator: hub.coordinator,
                      sender: sender,
                      repliedTo: _controller.replyMessage,
                    ),
                  );
                },
              ),
            Container(
              padding:
                  widget.messageInputPadding ??
                  EdgeInsets.symmetric(
                    horizontal: spacing.padding2 ?? 8,
                    vertical: spacing.padding1 ?? 4,
                  ),
              decoration: BoxDecoration(
                color: style.filledColor ?? colorPalette.background2,
                borderRadius: style.borderRadius ?? BorderRadius.circular(spacing.radius2 ?? 8),
                border:
                    style.border ??
                    Border.all(
                      color: colorPalette.borderDefault ?? Colors.transparent,
                    ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!hideAttachment || customSecondary != null)
                    MessageComposerSecondaryButtons(
                      onAttachmentTap: _handleAttachmentTap,
                      hideAttachmentButton: hideAttachment,
                      customSecondaryButtonView: customSecondary,
                      attachmentIcon: widget.attachmentIcon,
                      attachmentIconURL: widget.attachmentIconURL,
                      secondaryButtonIconColor: style.secondaryButtonIconColor,
                      colorPalette: colorPalette,
                      spacing: spacing,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: widget.maxLine ?? 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      style:
                          style.textStyle ??
                          TextStyle(
                            color: style.textColor ?? colorPalette.textPrimary,
                            fontSize: typography.body?.regular?.fontSize ?? 14,
                          ),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText:
                            widget.placeholderText ??
                            Translations.of(context).enterYourMessageHere,
                        hintStyle:
                            style.placeHolderTextStyle ??
                            TextStyle(color: style.placeHolderTextColor ?? colorPalette.textTertiary),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: spacing.padding2 ?? 8,
                          vertical: spacing.padding2 ?? 8,
                        ),
                      ),
                    ),
                  ),
                  if (!hideVoice || customAuxiliary != null)
                    MessageComposerAuxiliaryButtons(
                      onVoiceRecordingTap: _controller.startAudioRecording,
                      hideVoiceRecordingButton: hideVoice,
                      customAuxiliaryButtonView: customAuxiliary,
                      voiceRecordingIcon: widget.voiceRecordingIcon,
                      auxiliaryButtonIconColor: style.auxiliaryButtonIconColor,
                      colorPalette: colorPalette,
                      spacing: spacing,
                    ),
                  MessageComposerSendButton(
                    onPressed: canSend ? _handleSend : () {},
                    isDisabled: !canSend,
                    hideSendButton: widget.hideSendButton ?? false,
                    customSendButtonView: widget.sendButtonView,
                    sendButtonIcon: widget.sendButtonIcon,
                    sendButtonIconColor: style.sendButtonIconColor,
                    colorPalette: colorPalette,
                    spacing: spacing,
                  ),
                ],
              ),
            ),
            ?footer,
          ],
        );
      },
    );

    content = Container(
      color: style.backgroundColor ?? colorPalette.background1,
      padding:
          widget.padding ??
          EdgeInsets.all(spacing.padding2 ?? 8),
      child: content,
    );

    if (!widget.hideBottomSafeArea) {
      content = SafeArea(top: false, child: content);
    }

    return content;
  }
}
