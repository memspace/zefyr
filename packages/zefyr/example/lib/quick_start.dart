// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';

import 'src/editor_page.dart';

void main() {
  runApp(const QuickStartApp());
}

class QuickStartApp extends StatelessWidget {
  const QuickStartApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Start',
      home: const HomePage(),
      routes: {
        '/editor': (context) => const EditorPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Start')),
      body: Center(
        child: TextButton(
          onPressed: () => navigator.pushNamed('/editor'),
          child: const Text('Open editor'),
        ),
      ),
    );
  }
}
