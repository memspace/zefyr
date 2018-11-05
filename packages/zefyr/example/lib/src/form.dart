import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'full_page.dart';

class FormEmbeddedScreen extends StatefulWidget {
  @override
  _FormEmbeddedScreenState createState() => _FormEmbeddedScreenState();
}

class _FormEmbeddedScreenState extends State<FormEmbeddedScreen> {
  final ZefyrController _controller = ZefyrController(NotusDocument());
  final FocusNode _focusNode = new FocusNode();

  @override
  Widget build(BuildContext context) {
    final form = ListView(
      children: <Widget>[
        TextField(decoration: InputDecoration(labelText: 'Name')),
        TextField(decoration: InputDecoration(labelText: 'Email')),
        Container(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            'Description',
            style: TextStyle(color: Colors.black54, fontSize: 16.0),
          ),
          alignment: Alignment.centerLeft,
        ),
        buildEditor(),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        elevation: 1.0,
        backgroundColor: Colors.grey.shade200,
        brightness: Brightness.light,
        title: ZefyrLogo(),
      ),
      body: ZefyrScaffold(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: form,
        ),
      ),
    );
  }

  Widget buildEditor() {
    final theme = new ZefyrThemeData(
      toolbarTheme: ZefyrToolbarTheme.fallback(context).copyWith(
        color: Colors.grey.shade800,
        toggleColor: Colors.grey.shade900,
        iconColor: Colors.white,
        disabledIconColor: Colors.grey.shade500,
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      constraints: BoxConstraints.tightFor(height: 300.0),
      decoration:
          BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
      child: ZefyrTheme(
        data: theme,
        child: ZefyrEditor(
          padding: EdgeInsets.all(8.0),
          controller: _controller,
          focusNode: _focusNode,
          autofocus: false,
          imageDelegate: new CustomImageDelegate(),
          physics: ClampingScrollPhysics(),
        ),
      ),
    );
  }
}
