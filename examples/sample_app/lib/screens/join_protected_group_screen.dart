import 'package:convokit/convokit.dart';
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';

/// Offline Join Protected Group screen using [GroupRepository.joinGroup].
class JoinProtectedGroupScreen extends StatefulWidget {
  const JoinProtectedGroupScreen({
    super.key,
    required this.group,
    this.onGroupJoined,
  });

  final ChatGroup group;
  final void Function(ChatGroup group)? onGroupJoined;

  @override
  State<JoinProtectedGroupScreen> createState() =>
      _JoinProtectedGroupScreenState();
}

class _JoinProtectedGroupScreenState extends State<JoinProtectedGroupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final groupsRepo = ConvoKitScope.of(context).groups;
    if (groupsRepo == null) return;

    setState(() => _isLoading = true);
    final res = await groupsRepo.joinGroup(widget.group.id);
    if (!mounted) return;
    setState(() => _isLoading = false);

    res.fold(
      onSuccess: (_) {
        widget.onGroupJoined?.call(widget.group);
        Navigator.pop(context, widget.group);
      },
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
          widget.group.name,
          style: TextStyle(color: palette.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Group Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinGroup,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}
