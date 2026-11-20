/// Pagination and recovery contracts according to API-DESIGN.md §5.
library;

enum MessagePageDirection { latest, older, newer }

class MessagePageRequest {
  /// latest: cursor must be null — returns the newest page.
  /// older:  cursor is the `olderCursor` of the currently oldest page.
  /// newer:  cursor is the `newerCursor` of the currently newest page, or
  ///         the stored `newerCheckpoint` when starting catch-up.
  final MessagePageDirection direction;
  final String? cursor;
  final int limit;

  const MessagePageRequest({
    required this.direction,
    this.cursor,
    this.limit = 30,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagePageRequest &&
          runtimeType == other.runtimeType &&
          direction == other.direction &&
          cursor == other.cursor &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(direction, cursor, limit);

  @override
  String toString() =>
      'MessagePageRequest(direction: $direction, cursor: $cursor, limit: $limit)';
}

class ChatPage<T> {
  final List<T> items;

  /// Opaque cursor for the page *older* than this one, or null at the start.
  final String? olderCursor;

  /// Opaque cursor for the page *newer* than this one, or null when there
  /// is currently no newer page. Transient: advances as newer pages load.
  final String? newerCursor;

  /// Durable resume token for newer-message catch-up, established by a
  /// `latest` fetch. Present even when `hasNewer` is false: it anchors
  /// "the end of history as of this fetch", so catch-up after a
  /// disconnection starts from the right place even if nothing was newer
  /// at fetch time. Null means the backend cannot provide this guarantee.
  final String? newerCheckpoint;

  const ChatPage({
    required this.items,
    this.olderCursor,
    this.newerCursor,
    this.newerCheckpoint,
  });

  bool get hasOlder => olderCursor != null;
  bool get hasNewer => newerCursor != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatPage<T> &&
          runtimeType == other.runtimeType &&
          olderCursor == other.olderCursor &&
          newerCursor == other.newerCursor &&
          newerCheckpoint == other.newerCheckpoint &&
          _listEquals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(olderCursor, newerCursor, newerCheckpoint, Object.hashAll(items));

  @override
  String toString() =>
      'ChatPage(items: ${items.length}, olderCursor: $olderCursor, newerCursor: $newerCursor, newerCheckpoint: $newerCheckpoint)';

  static bool _listEquals<E>(List<E> a, List<E> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
