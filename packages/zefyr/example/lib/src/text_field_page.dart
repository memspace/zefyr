import 'package:example/src/full_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ZefyrLogo(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          child: RawEditor(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            showCursor: true,
            cursorStyle: CursorStyle(
              color: Colors.blue,
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
            _controller.document
                .insert(_controller.document.length - 1, '\nMore text 👍');
          });
        },
      ),
    );
  }
}
