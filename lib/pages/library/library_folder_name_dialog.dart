import 'package:flutter/material.dart';

import '../../utils/localization_extension.dart';

class LibraryFolderNameDialog extends StatefulWidget {
  const LibraryFolderNameDialog({
    super.key,
    required this.onSave,
    this.initialName,
    this.movingBooks = false,
  });

  final Future<void> Function(String name) onSave;
  final String? initialName;
  final bool movingBooks;

  @override
  State<LibraryFolderNameDialog> createState() =>
      _LibraryFolderNameDialogState();
}

class _LibraryFolderNameDialogState extends State<LibraryFolderNameDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _failed = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.onSave(_name.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error, stack) {
      debugPrint('Shelf folder save failed: $error\n$stack');
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.initialName == null
              ? l10n.libraryNewFolder
              : l10n.libraryRenameFolder,
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.movingBooks) ...[
                  Text(l10n.libraryFolderCreateHint),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  key: const ValueKey('library-folder-name'),
                  controller: _name,
                  autofocus: true,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.libraryFolderName,
                    hintText: l10n.libraryFolderNameHint,
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return l10n.libraryFolderNameRequired;
                    if (name.runes.length > 60) {
                      return l10n.libraryFolderNameTooLong;
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_failed) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.libraryFolderOperationFailed,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('library-folder-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
