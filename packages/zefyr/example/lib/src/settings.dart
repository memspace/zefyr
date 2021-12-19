import 'dart:convert';

import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as pp;

/// Application settings
class Settings {
  /// Path to assets folder. If set then edits to any document within this
  /// application can be saved back to the assets folder.
  final String assetsPath;

  Settings({this.assetsPath});

  static Future<Settings> load() async {
    if (kIsWeb) {
      return Settings(assetsPath: '');
    }

    const fs = LocalFileSystem();
    final dir = await pp.getApplicationSupportDirectory();
    final file = fs.directory(dir.path).childFile('settings.json');
    if (await file.exists()) {
      final json = await file.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return Settings(assetsPath: data['assetsPath'] as String);
    }
    return Settings(assetsPath: '');
  }

  static Settings of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<SettingsProvider>();
    return widget.settings;
  }

  Future<void> save() async {
    if (kIsWeb) {
      return;
    }
    const fs = LocalFileSystem();
    final dir = await pp.getApplicationSupportDirectory();
    final file = fs.directory(dir.path).childFile('settings.json');
    final data = {'assetsPath': assetsPath};
    await file.writeAsString(jsonEncode(data));
  }
}

Future<Settings> showSettingsDialog(BuildContext context, Settings settings) {
  return showDialog<Settings>(
      context: context, builder: (ctx) => SettingsDialog(settings: settings));
}

class SettingsDialog extends StatefulWidget {
  final Settings settings;

  const SettingsDialog({Key key, @required this.settings}) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String _assetsPath = '';
  TextEditingController _assetsPathController;

  @override
  void initState() {
    super.initState();
    _assetsPath = widget.settings.assetsPath;
    _assetsPathController = TextEditingController(text: _assetsPath);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Container(
        constraints: const BoxConstraints(minWidth: 400),
        child: TextField(
          controller: _assetsPathController,
          decoration: const InputDecoration(
            labelText: 'Path to assets folder',
            helperText:
                'When set, allows to edit and save documents used in examples from within the app. Only useful if you are a developer of Zefyr package.',
            helperMaxLines: 3,
          ),
          onChanged: _assetsPathChanged,
        ),
      ),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    );
  }

  void _assetsPathChanged(String value) {
    setState(() {
      _assetsPath = value;
    });
  }

  Future<void> _save() async {
    final settings = Settings(assetsPath: _assetsPath);
    await settings.save();
    if (mounted) {
      Navigator.pop(context, settings);
    }
  }
}

class SettingsProvider extends InheritedWidget {
  final Settings settings;

  const SettingsProvider({Key key, this.settings, Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant SettingsProvider oldWidget) {
    return oldWidget.settings != settings;
  }
}
