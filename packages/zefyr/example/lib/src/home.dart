import 'dart:convert';

import 'package:example/src/read_only_view.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zefyr/zefyr.dart';

import 'forms_decorated_field.dart';
import 'layout.dart';
import 'layout_expanded.dart';
import 'layout_scrollable.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ZefyrController _controller;
  final FocusNode _focusNode = FocusNode();

  Settings _settings;

  void _handleSettingsLoaded(Settings value) {
    setState(() {
      _settings = value;
      _loadFromAssets();
    });
  }

  @override
  void initState() {
    super.initState();
    Settings.load().then(_handleSettingsLoaded);
  }

  Future<void> _loadFromAssets() async {
    try {
      final result = await rootBundle.loadString('assets/welcome.note');
      final doc = NotusDocument.fromJson(jsonDecode(result));
      setState(() {
        _controller = ZefyrController(doc);
      });
    } catch (error) {
      final doc = NotusDocument()..insert(0, 'Empty asset');
      setState(() {
        _controller = ZefyrController(doc);
      });
    }
  }

  Future<void> _save() async {
    const fs = LocalFileSystem();
    final file = fs.directory(_settings.assetsPath).childFile('welcome.note');
    final data = jsonEncode(_controller.document);
    await file.writeAsString(data);
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null || _controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    return SettingsProvider(
      settings: _settings,
      child: PageLayout(
        appBar: AppBar(
          backgroundColor: Colors.grey.shade800,
          elevation: 0,
          centerTitle: false,
          title: Text(
            'Zefyr',
            style: GoogleFonts.fondamento(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, size: 16),
              onPressed: _showSettings,
            ),
            if (_settings.assetsPath.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.save, size: 16),
                onPressed: _save,
              )
          ],
        ),
        menuBar: Material(
          color: Colors.grey.shade800,
          child: _buildMenuBar(context),
        ),
        body: _buildWelcomeEditor(context),
      ),
    );
  }

  void _showSettings() async {
    final result = await showSettingsDialog(context, _settings);
    if (mounted && result != null) {
      setState(() {
        _settings = result;
      });
    }
  }

  Widget _buildMenuBar(BuildContext context) {
    final headerStyle = TextStyle(
        fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold);
    const itemStyle = TextStyle(color: Colors.white);
    return ListView(
      children: [
        ListTile(
          title: Text('BASIC EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: const Text('¶   Read only view', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _readOnlyView,
        ),
        ListTile(
          title: Text('LAYOUT EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: const Text('¶   Expandable', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _expanded,
        ),
        ListTile(
          title: const Text('¶   Custom scrollable', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _scrollable,
        ),
        ListTile(
          title: Text('FORMS AND FIELDS EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: const Text('¶   Decorated field', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _decoratedField,
        ),
      ],
    );
  }

  Widget _buildWelcomeEditor(BuildContext context) {
    return Column(
      children: [
        ZefyrToolbar.basic(controller: _controller),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16.0, right: 0.0),
            child: ZefyrEditor(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              // readOnly: true,
              // padding: EdgeInsets.only(left: 16, right: 16),
              onLaunchUrl: _launchUrl,
              maxContentWidth: 800,
            ),
          ),
        ),
      ],
    );
  }

  void _launchUrl(String url) async {
    final result = await canLaunch(url);
    if (result) {
      await launch(url);
    }
  }

  void _expanded() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: const ExpandedLayout(),
        ),
      ),
    );
  }

  void _readOnlyView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: const ReadOnlyView(),
        ),
      ),
    );
  }

  void _scrollable() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: const ScrollableLayout(),
        ),
      ),
    );
  }

  void _decoratedField() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => SettingsProvider(
          settings: _settings,
          child: const DecoratedFieldDemo(),
        ),
      ),
    );
  }
}
