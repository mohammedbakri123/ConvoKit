/// Feature capabilities according to API-DESIGN.md §9.
library;

class ChatCapabilities {
  final bool receipts;
  final bool typing;
  final bool media;
  final bool mediaDelete;
  final bool groups;
  final bool search; // v1: user search only
  final bool messageCatchUp; // newer-page catch-up after reconnect

  /// No capabilities. The default. Nothing is assumed.
  const ChatCapabilities({
    this.receipts = false,
    this.typing = false,
    this.media = false,
    this.mediaDelete = false,
    this.groups = false,
    this.search = false,
    this.messageCatchUp = false,
  });

  /// A full-featured backend: everything v1 supports.
  factory ChatCapabilities.basic() => const ChatCapabilities(
    receipts: true,
    typing: true,
    media: true,
    mediaDelete: true,
    groups: true,
    search: true,
    messageCatchUp: true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCapabilities &&
          runtimeType == other.runtimeType &&
          receipts == other.receipts &&
          typing == other.typing &&
          media == other.media &&
          mediaDelete == other.mediaDelete &&
          groups == other.groups &&
          search == other.search &&
          messageCatchUp == other.messageCatchUp;

  @override
  int get hashCode => Object.hash(
    receipts,
    typing,
    media,
    mediaDelete,
    groups,
    search,
    messageCatchUp,
  );

  @override
  String toString() =>
      'ChatCapabilities(receipts: $receipts, typing: $typing, media: $media, groups: $groups, search: $search, messageCatchUp: $messageCatchUp)';
}
