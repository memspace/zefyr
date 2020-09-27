import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zefyr/zefyr.dart';

import 'forms_decorated_field.dart';
import 'layout.dart';
import 'layout_expanded.dart';
import 'layout_scrollable.dart';
import 'settings.dart';

class HomePage extends StatefulWidget {
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
    });
  }

  @override
  void initState() {
    super.initState();
    Settings.load().then(_handleSettingsLoaded);

    final json =
        r'[{"insert":"Building a rich text editor"},{"insert":"\n","attributes":{"heading":1}},{"insert":{"_type":"hr","_inline":false}},{"insert":"\n"},{"insert":"https://github.com/memspace/zefyr","attributes":{"a":"https://github.com/memspace/zefyr"}},{"insert":"\nZefyr is the first rich text editor created for Flutter framework.\nHere we go again. This is a very long paragraph of text to test keyboard event handling."},{"insert":"\n","attributes":{"block":"quote"}},{"insert":"Hello world!"},{"insert":"\n","attributes":{"block":"quote"}},{"insert":"So many features"},{"insert":"\n","attributes":{"heading":2}},{"insert":"Example of numbered list:\nMarkdown semantics"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Modern and light look"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"One more thing"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"And this one is just superb and amazing and awesome"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"I can go on"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"With so many posibilitities around"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Here we go again. This is a very long paragraph of text to test keyboard event handling."},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"And a couple more"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Finally the tenth item"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Whoohooo"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"This is bold text. And the code:\nvoid main() {"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"  print(\"Hello world!\"); // with a very long comment to see soft wrapping"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"}"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"Above we have a block of code.\n"}]';
    final document = NotusDocument.fromJson(jsonDecode(json));
    _controller = ZefyrController(document);
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Scaffold(body: Center(child: Text('Loading...')));
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
              icon: Icon(Icons.settings, size: 16),
              onPressed: _showSettings,
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
    final itemStyle = TextStyle(color: Colors.white);
    return ListView(
      children: [
        ListTile(
          title: Text('LAYOUT EXAMPLES', style: headerStyle),
          // dense: true,
          visualDensity: VisualDensity.compact,
        ),
        ListTile(
          title: Text('¶   Expandable', style: itemStyle),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: _expanded,
        ),
        ListTile(
          title: Text('¶   Custom scrollable', style: itemStyle),
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
          title: Text('¶   Decorated field', style: itemStyle),
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
        EditorToolbar.basic(controller: _controller),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: ZefyrEditor(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              // readOnly: true,
              // padding: EdgeInsets.only(left: 16, right: 16),
              onLaunchUrl: _launchUrl,
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
          child: ExpandedLayout(),
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
          child: ScrollableLayout(),
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
          child: DecoratedFieldDemo(),
        ),
      ),
    );
  }
}
