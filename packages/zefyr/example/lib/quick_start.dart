// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';

import 'src/editor_page.dart';

void main() {
  runApp(QuickStartApp());
}

class QuickStartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Start',
      home: HomePage(),
      routes: {
        '/editor': (context) => EditorPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Quick Start')),
      body: Center(
        child: FlatButton(
          child: Text('Open editor'),
          onPressed: () => navigator.pushNamed('/editor'),
        ),
      ),
    );
  }
}
