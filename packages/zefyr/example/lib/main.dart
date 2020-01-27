// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';

import 'src/form.dart';
import 'src/full_page.dart';
import 'src/view.dart';
import 'src/text_field_page.dart';

void main() {
  runApp(ZefyrApp());
}

class ZefyrApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zefyr Editor',
      home: HomePage(),
      routes: {
        "/fullPage": buildFullPage,
        "/form": buildFormPage,
        "/view": buildViewPage,
        "/textinput": buildTextFieldPage,
      },
    );
  }

  Widget buildFullPage(BuildContext context) {
    return FullPageEditorScreen();
  }

  Widget buildFormPage(BuildContext context) {
    return FormEmbeddedScreen();
  }

  Widget buildViewPage(BuildContext context) {
    return ViewScreen();
  }

  Widget buildTextFieldPage(BuildContext context) {
    return TextFieldScreen();
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(title: ZefyrLogo()),
      body: Column(
        children: <Widget>[
          Expanded(child: Container()),
          RaisedButton(
            onPressed: () => nav.pushNamed('/fullPage'),
            child: Text('Full page editor'),
          ),
          RaisedButton(
            onPressed: () => nav.pushNamed('/form'),
            child: Text('Embedded in a form'),
          ),
          RaisedButton(
            onPressed: () => nav.pushNamed('/view'),
            child: Text('Read-only embeddable view'),
          ),
          RaisedButton(
            onPressed: () => nav.pushNamed('/textinput'),
            child: Text('basic text input'),
          ),
          Expanded(child: Container()),
        ],
      ),
    );
  }
}
