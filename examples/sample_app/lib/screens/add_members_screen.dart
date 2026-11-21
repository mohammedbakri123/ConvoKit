import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// Offline Add Members screen using [GroupRepository.addMembers] via [ConvoKitScope].
class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({super.key, required this.group});

  final ChatGroup group;

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final Set<String> _selectedIds = {};
  List<ChatUser> _users = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  Future<void> _loadUsers() async {
    final kit = ConvoKitScope.of(context);
    final res = await kit.users.listUsers(limit: 50);
    if (!mounted) return;
    res.fold(
      onSuccess: (page) => setState(() {
        _users = page.items;
        _isLoading = false;
      }),
      onFailure: (_) => setState(() => _isLoading = false),
    );
  }

  Future<void> _addSelected() async {
    if (_selectedIds.isEmpty) return;
    final groupsRepo = ConvoKitScope.of(context).groups;
    if (groupsRepo == null) return;

    setState(() => _isSaving = true);
    final res = await groupsRepo.addMembers(
      widget.group.id,
      _selectedIds.toList(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    res.fold(
      onSuccess: (_) => Navigator.pop(context, true),
      onFailure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ConvoKitThemeHelper.getColorPalette(context);

    return Scaffold(
      backgroundColor: palette.background1,
      appBar: AppBar(
        backgroundColor: palette.background1,
        title: Text(
          'Add Members',
          style: TextStyle(color: palette.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: (_selectedIds.isEmpty || _isSaving)
                ? null
                : _addSelected,
            child: const Text('Add'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final selected = _selectedIds.contains(user.id);
                return CheckboxListTile(
                  value: selected,
                  title: Text(user.name),
                  subtitle: Text(user.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedIds.add(user.id);
                      } else {
                        _selectedIds.remove(user.id);
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}
