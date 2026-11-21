import 'package:convokit/src/core/models/models.dart';
import '../../presentation/views/misc/receipt/cometchat_receipt.dart';

/// Utility class to determine receipt status from a [ChatMessage].
class MessageReceiptUtils {
  static ReceiptStatus getReceiptStatus(ChatMessage message) {
    return switch (message.sendState) {
      SendState.failed => ReceiptStatus.error,
      SendState.sending => ReceiptStatus.waiting,
      SendState.sent => switch (message.deliveryState) {
        DeliveryState.read => ReceiptStatus.read,
        DeliveryState.delivered => ReceiptStatus.delivered,
        DeliveryState.none => ReceiptStatus.sent,
      },
    };
  }
}
