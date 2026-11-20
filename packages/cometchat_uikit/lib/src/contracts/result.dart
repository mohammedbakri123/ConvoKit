/// Sealed `ChatResult<T>` and ChatError types according to API-DESIGN.md §3.
library;

/// Outcome of an operation. Expected operational failures are always returned
/// as [ChatFailure], never thrown.
sealed class ChatResult<T> {
  const ChatResult();

  const factory ChatResult.success(T value) = ChatSuccess<T>;
  const factory ChatResult.failure(ChatError error) = ChatFailure<T>;

  /// Convenience for `ChatResult<void>`: success with no value.
  static ChatResult<void> ok() => const ChatSuccess<void>(null);

  bool get isSuccess => this is ChatSuccess<T>;
  bool get isFailure => this is ChatFailure<T>;

  /// Branch on the outcome. The failure branch always carries the error.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(ChatError error) onFailure,
  }) {
    return switch (this) {
      ChatSuccess<T>(:final value) => onSuccess(value),
      ChatFailure<T>(:final error) => onFailure(error),
    };
  }

  /// Transform a success value; a failure passes through unchanged,
  /// preserving the original error.
  ChatResult<U> map<U>(U Function(T value) transform) {
    return switch (this) {
      ChatSuccess<T>(:final value) => ChatSuccess<U>(transform(value)),
      ChatFailure<T>(:final error) => ChatFailure<U>(error),
    };
  }
}

final class ChatSuccess<T> extends ChatResult<T> {
  final T value;
  const ChatSuccess(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSuccess<T> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ChatResult.success($value)';
}

final class ChatFailure<T> extends ChatResult<T> {
  final ChatError error;
  const ChatFailure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatFailure<T> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'ChatResult.failure($error)';
}

enum ChatErrorCode {
  network, // transport failure — retryable
  unauthorized, // session invalid — host should re-authenticate
  forbidden, // not allowed (e.g. not a member)
  notFound,
  validation, // bad input (e.g. empty message, oversize file)
  uploadFailed, // media upload failed — retryable, re-upload
  sendFailed, // message send failed — retryable, re-send same localId
  cancelled, // the caller cancelled — never an exception
  unsupported, // backend lacks the capability
  unknown, // outcome could not be determined (see outcomeUnknown)
}

class ChatError {
  final ChatErrorCode code;
  final String message; // human-readable, for logs/debug UI
  final Object? cause; // the underlying exception, if any
  /// True when the adapter cannot tell whether the backend persisted the
  /// operation (e.g. the response was lost after the send). Core treats
  /// this as failed-but-retryable: retry reuses the same localId and the
  /// backend dedupes.
  final bool outcomeUnknown;

  const ChatError(
    this.code,
    this.message, {
    this.cause,
    this.outcomeUnknown = false,
  });

  bool get isRetryable => switch (code) {
    ChatErrorCode.network ||
    ChatErrorCode.uploadFailed ||
    ChatErrorCode.sendFailed ||
    ChatErrorCode.unknown => true,
    _ => false,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          cause == other.cause &&
          outcomeUnknown == other.outcomeUnknown;

  @override
  int get hashCode => Object.hash(code, message, cause, outcomeUnknown);

  @override
  String toString() =>
      'ChatError($code, "$message", outcomeUnknown: $outcomeUnknown, cause: $cause)';
}
