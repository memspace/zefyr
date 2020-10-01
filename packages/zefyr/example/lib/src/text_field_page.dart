import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zefyr/zefyr.dart';

class TextFieldScreen extends StatefulWidget {
  TextFieldScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _TextFieldScreenState createState() => _TextFieldScreenState();
}

class _TextFieldScreenState extends State<TextFieldScreen> {
  ZefyrController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final json =
        r'[{"insert":"Building a rich text editor"},{"insert":"\n","attributes":{"heading":1}},{"insert":{"_type":"hr","_inline":false}},{"insert":"\n"},{"insert":"https://github.com/memspace/zefyr","attributes":{"a":"https://github.com/memspace/zefyr"}},{"insert":"\nZefyr is the first rich text editor created for Flutter framework.\nHere we go again. This is a very long paragraph of text to test keyboard event handling."},{"insert":"\n","attributes":{"block":"quote"}},{"insert":"Hello world!"},{"insert":"\n","attributes":{"block":"quote"}},{"insert":"So many features"},{"insert":"\n","attributes":{"heading":2}},{"insert":"Example of numbered list:\nMarkdown semantics"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Modern and light look"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"One more thing"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"And this one is just superb and amazing and awesome"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"I can go on"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"With so many posibilitities around"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Here we go again. This is a very long paragraph of text to test keyboard event handling."},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"And a couple more"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Finally the tenth item"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Whoohooo"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"This is bold text. And the code:\nvoid main() {"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"  print(\"Hello world!\"); // with a very long comment to see soft wrapping"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"}"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"Above we have a block of code.\n"}]';
    final document = NotusDocument.fromJson(jsonDecode(json));
    _controller = ZefyrController(document);
    _controller.addListener(_print);
  }

  @override
  void didUpdateWidget(covariant TextFieldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.addListener(_print);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_print);
  }

  void _print() {
    // print(jsonEncode(_controller.document));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZefyrToolbar.basic(controller: _controller),
      body: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 0),
          ),
          child: ZefyrField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            // readOnly: true,
            padding: EdgeInsets.only(left: 16, right: 16),
            onLaunchUrl: _launchUrl,
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final result = await canLaunch(url);
    if (result) {
      await launch(url);
    }
  }
}
