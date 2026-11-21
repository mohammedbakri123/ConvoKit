import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';

/// Offline Transfer Ownership screen backed by [InMemoryChatBackend].
class TransferOwnershipScreen extends StatefulWidget {
  const TransferOwnershipScreen({super.key, required this.group});

  final ChatGroup group;

  @override
  State<TransferOwnershipScreen> createState() =>
      _TransferOwnershipScreenState();
}

class _TransferOwnershipScreenState extends State<TransferOwnershipScreen> {
  String? _selectedMemberId;

  void _transfer() {
    final uid = _selectedMemberId;
    if (uid == null) return;
    SampleAppBackend.instance.backend.transferGroupOwnership(
      widget.group.id,
      uid,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);
    final members = widget.group.members ?? const <ChatMember>[];

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Transfer Ownership',
          style: TextStyle(color: palette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _selectedMemberId == null ? null : _transfer,
            child: const Text('Transfer'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return RadioListTile<String>(
            value: member.user.id,
            groupValue: _selectedMemberId,
            title: Text(member.user.name),
            subtitle: Text(member.role.name),
            onChanged: (value) => setState(() => _selectedMemberId = value),
          );
        },
      ),
    );
  }
}
