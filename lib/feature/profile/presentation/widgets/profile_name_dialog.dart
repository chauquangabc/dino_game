import 'package:flutter/material.dart';

import '../../data/profile_repository.dart';
import '../../domain/profile_catalog.dart';

class ProfileNameDialog extends StatefulWidget {
  const ProfileNameDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });
  final String initialName;
  final Future<void> Function(String) onSave;
  @override
  State<ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends State<ProfileNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);
  String? _error;
  bool _saving = false;
  Future<void> _save() async {
    if (_saving) return;
    final error = ProfileRepository.validateName(_controller.text);
    setState(() => _error = error);
    if (error != null) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      backgroundColor: const Color(0xffffe2aa),
      title: const Text('Edit name'),
      content: TextField(
        key: const ValueKey('profile-name-input'),
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        maxLength: ProfileCatalog.nameMaxLength,
        decoration: InputDecoration(errorText: _error),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
  );
}
