import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:sample_app/sample_app_backend.dart';

/// Offline Create Group screen backed by [InMemoryChatBackend].
class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.onGroupCreated});

  final void Function(ChatGroup group)? onGroupCreated;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  GroupType _groupType = GroupType.public;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final group = SampleAppBackend.instance.backend.createGroup(
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        type: _groupType,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      widget.onGroupCreated?.call(group);
      if (mounted) {
        Navigator.pop(context, group);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Create Group',
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<GroupType>(
              segments: const [
                ButtonSegment(value: GroupType.public, label: Text('Public')),
                ButtonSegment(value: GroupType.private, label: Text('Private')),
                ButtonSegment(
                  value: GroupType.passwordProtected,
                  label: Text('Protected'),
                ),
              ],
              selected: {_groupType},
              onSelectionChanged: (set) {
                setState(() => _groupType = set.first);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
