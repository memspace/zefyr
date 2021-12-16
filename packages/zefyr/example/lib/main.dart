// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';

import 'src/home.dart';

void main() {
  runApp(const ZefyrApp());
}

class ZefyrApp extends StatelessWidget {
  const ZefyrApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zefyr - rich-text editor for Flutter',
      home: HomePage(),
    );
  }
}
