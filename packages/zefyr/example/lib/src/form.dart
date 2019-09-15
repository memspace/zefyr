// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'full_page.dart';
import 'images.dart';

class FormEmbeddedScreen extends StatefulWidget {
  @override
  _FormEmbeddedScreenState createState() => _FormEmbeddedScreenState();
}

class _FormEmbeddedScreenState extends State<FormEmbeddedScreen> {
  final ZefyrController _controller = ZefyrController(NotusDocument());
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final form = ListView(
      children: <Widget>[
        TextField(decoration: InputDecoration(labelText: 'Name')),
        buildEditor(),
        TextField(decoration: InputDecoration(labelText: 'Email')),
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
    final theme = ZefyrThemeData(
      toolbarTheme: ZefyrToolbarTheme.fallback(context).copyWith(
        color: Colors.grey.shade800,
        toggleColor: Colors.grey.shade900,
        iconColor: Colors.white,
        disabledIconColor: Colors.grey.shade500,
      ),
    );

    return ZefyrTheme(
      data: theme,
      child: ZefyrField(
        height: 200.0,
        decoration: InputDecoration(labelText: 'Description'),
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        imageDelegate: CustomImageDelegate(),
        physics: ClampingScrollPhysics(),
      ),
    );
  }
}
