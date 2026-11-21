import 'package:convokit/convokit.dart';
import 'package:diffutil_dart/diffutil.dart';

/// Diff delegate for comparing [ChatMessage] lists.
class MessageListDiff extends ListDiffDelegate<ChatMessage> {
  MessageListDiff(super.oldList, super.newList);

  @override
  bool areContentsTheSame(int oldItemPosition, int newItemPosition) {
    final oldMsg = oldList[oldItemPosition];
    final newMsg = newList[newItemPosition];
    return oldMsg == newMsg;
  }

  @override
  bool areItemsTheSame(int oldItemPosition, int newItemPosition) {
    final oldMsg = oldList[oldItemPosition];
    final newMsg = newList[newItemPosition];

    if (oldMsg.id != null && newMsg.id != null) {
      return oldMsg.id == newMsg.id;
    }

    if (oldMsg.localId.isNotEmpty && newMsg.localId.isNotEmpty) {
      return oldMsg.localId == newMsg.localId;
    }

    return false;
  }
}
