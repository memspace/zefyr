// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'full_page.dart';

enum _Options { darkTheme }

class FormEmbeddedScreen extends StatefulWidget {
  @override
  _FormEmbeddedScreenState createState() => _FormEmbeddedScreenState();
}

class _FormEmbeddedScreenState extends State<FormEmbeddedScreen> {
  final ZefyrController _controller = ZefyrController(NotusDocument());
  final FocusNode _focusNode = FocusNode();

  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    final form = ListView(
      children: <Widget>[
        TextField(
          decoration: InputDecoration(labelText: 'Name'),
          maxLines: 5,
        ),
        buildEditor(),
        TextField(
          decoration: InputDecoration(labelText: 'Details'),
          maxLines: 3,
        ),
      ],
    );

    final result = Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: ZefyrLogo(),
        actions: [
          PopupMenuButton<_Options>(
            itemBuilder: buildPopupMenu,
            onSelected: handlePopupItemSelected,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: form,
      ),
    );

    if (_darkTheme) {
      return Theme(data: ThemeData.dark(), child: result);
    }
    return Theme(data: ThemeData(primarySwatch: Colors.cyan), child: result);
  }

  Widget buildEditor() {
    return ZefyrField(
      // height: 200.0,
      // decoration: InputDecoration(labelText: 'Description'),
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      // physics: ClampingScrollPhysics(),
    );
  }

  void handlePopupItemSelected(value) {
    if (!mounted) return;
    setState(() {
      if (value == _Options.darkTheme) {
        _darkTheme = !_darkTheme;
      }
    });
  }

  List<PopupMenuEntry<_Options>> buildPopupMenu(BuildContext context) {
    return [
      CheckedPopupMenuItem(
        value: _Options.darkTheme,
        checked: _darkTheme,
        child: Text('Dark theme'),
      ),
    ];
  }
}
