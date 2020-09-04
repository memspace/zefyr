import 'package:example/src/full_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/src/zefyr_dev.dart';

class TextFieldScreen extends StatefulWidget {
  TextFieldScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _TextFieldScreenState createState() => _TextFieldScreenState();
}

class _TextFieldScreenState extends State<TextFieldScreen> {
  ZefyrController _controller = ZefyrController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final document = NotusDocument.fromDelta(Delta()
      ..insert(
          '👍 Here we go again\nHello world!\nHere we go again. This is a very long paragraph of text to test keyboard event handling.\nHello world!\nHere we go again\n')
      ..insert('This is ')
      ..insert('bold', {'b': true})
      ..insert(' text.\n'));
    _controller = ZefyrController(document);
  }

  Color _defaultSelectionColor(BuildContext context, Color primary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return primary.withOpacity(isDark ? 0.40 : 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectionTheme = TextSelectionTheme.of(context);

    TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Color cursorColor;
    Color selectionColor;
    Color autocorrectionTextRectColor;
    Radius cursorRadius;

    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        // forcePressEnabled = true;
        textSelectionControls = cupertinoTextSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        if (theme.useTextSelectionTheme) {
          cursorColor ??= selectionTheme.cursorColor ??
              CupertinoTheme.of(context).primaryColor;
          selectionColor = selectionTheme.selectionColor ??
              _defaultSelectionColor(
                  context, CupertinoTheme.of(context).primaryColor);
        } else {
          cursorColor ??= CupertinoTheme.of(context).primaryColor;
          selectionColor = theme.textSelectionColor;
        }
        cursorRadius ??= const Radius.circular(2.0);
        cursorOffset = Offset(
            iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        autocorrectionTextRectColor = selectionColor;
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        // forcePressEnabled = false;
        textSelectionControls = materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        if (theme.useTextSelectionTheme) {
          cursorColor ??=
              selectionTheme.cursorColor ?? theme.colorScheme.primary;
          selectionColor = selectionTheme.selectionColor ??
              _defaultSelectionColor(context, theme.colorScheme.primary);
        } else {
          cursorColor ??= theme.cursorColor;
          selectionColor = theme.textSelectionColor;
        }
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: ZefyrLogo(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 0),
          ),
          child: RawEditor(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            showCursor: true,
            selectionColor: selectionColor,
            showSelectionHandles: true,
            selectionControls: cupertinoTextSelectionControls,
            cursorStyle: CursorStyle(
              color: cursorColor,
              backgroundColor: Colors.grey,
              width: 2.0,
              radius: Radius.circular(1),
              opacityAnimates: true,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          setState(() {
            _controller.replaceText(32, 0, '👍');
          });
        },
      ),
    );
  }
}
