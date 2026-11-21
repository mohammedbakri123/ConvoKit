/// Property tests for [MessageReceiptUtils] and [ChatError] retryability.
library;

import 'package:convokit/convokit_uikit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MessageReceiptUtils maps SendState and DeliveryState consistently', () {
    const sender = ChatUser(id: 'u1', name: 'Alice');
    final sending = TextMessage(
      localId: 'm1',
      conversationId: 'c1',
      sender: sender,
      createdAt: DateTime(2026),
      sendState: SendState.sending,
      text: 'hi',
    );
    final read = TextMessage(
      id: 'm2',
      localId: 'm2',
      conversationId: 'c1',
      sender: sender,
      createdAt: DateTime(2026),
      sendState: SendState.sent,
      deliveryState: DeliveryState.read,
      text: 'hi',
    );
    expect(MessageReceiptUtils.getReceiptStatus(sending), ReceiptStatus.waiting);
    expect(MessageReceiptUtils.getReceiptStatus(read), ReceiptStatus.read);
  });

  test('ChatError.isRetryable classifies transient vs terminal codes', () {
    expect(const ChatError(ChatErrorCode.network, 'net').isRetryable, isTrue);
    expect(const ChatError(ChatErrorCode.sendFailed, 'send').isRetryable, isTrue);
    expect(const ChatError(ChatErrorCode.forbidden, 'no').isRetryable, isFalse);
  });
}
