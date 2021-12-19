import 'dart:convert';

import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zefyr/zefyr.dart';

import 'settings.dart';

typedef DemoContentBuilder = Widget Function(
    BuildContext context, ZefyrController controller);

// Common scaffold for all examples.
class DemoScaffold extends StatefulWidget {
  /// Filename of the document to load into the editor.
  final String documentFilename;
  final DemoContentBuilder builder;
  final List<Widget> actions;
  final Widget floatingActionButton;
  final bool showToolbar;

  const DemoScaffold({
    Key key,
    @required this.documentFilename,
    @required this.builder,
    this.actions,
    this.showToolbar = true,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  _DemoScaffoldState createState() => _DemoScaffoldState();
}

class _DemoScaffoldState extends State<DemoScaffold> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  ZefyrController _controller;

  bool _loading = false;
  bool _canSave = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && !_loading) {
      _loading = true;
      final settings = Settings.of(context);
      if (settings.assetsPath.isEmpty) {
        _loadFromAssets();
      } else {
        _loadFromPath(settings.assetsPath);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadFromAssets() async {
    try {
      final result =
          await rootBundle.loadString('assets/${widget.documentFilename}');
      final doc = NotusDocument.fromJson(jsonDecode(result));
      setState(() {
        _controller = ZefyrController(doc);
        _loading = false;
      });
    } catch (error) {
      final doc = NotusDocument()..insert(0, 'Empty asset');
      setState(() {
        _controller = ZefyrController(doc);
        _loading = false;
      });
    }
  }

  Future<void> _loadFromPath(String assetsPath) async {
    const fs = LocalFileSystem();
    final file = fs.directory(assetsPath).childFile(widget.documentFilename);
    if (await file.exists()) {
      final data = await file.readAsString();
      final doc = NotusDocument.fromJson(jsonDecode(data));
      setState(() {
        _controller = ZefyrController(doc);
        _loading = false;
        _canSave = true;
      });
    } else {
      final doc = NotusDocument()..insert(0, 'Empty asset');
      setState(() {
        _controller = ZefyrController(doc);
        _loading = false;
        _canSave = true;
      });
    }
  }

  Future<void> _save() async {
    final settings = Settings.of(context);
    const fs = LocalFileSystem();
    final file =
        fs.directory(settings.assetsPath).childFile(widget.documentFilename);
    final data = jsonEncode(_controller.document);
    await file.writeAsString(data);
    _scaffoldMessengerKey.currentState
        .showSnackBar(const SnackBar(content: Text('Saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.actions ?? <Widget>[];
    if (_canSave) {
      actions.add(IconButton(
        onPressed: _save,
        icon: Icon(
          Icons.save,
          color: Colors.grey.shade800,
          size: 18,
        ),
      ));
    }
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).canvasColor,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: Colors.grey.shade800,
              size: 18,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: _loading || widget.showToolbar == false
              ? null
              : ZefyrToolbar.basic(controller: _controller),
          actions: actions,
        ),
        floatingActionButton: widget.floatingActionButton,
        body: _loading
            ? const Center(child: Text('Loading...'))
            : widget.builder(context, _controller),
      ),
    );
  }
}
