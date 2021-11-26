// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

var delta = Delta()..insert('This House Is A Circus\n');

class EditorSandBox {
  final WidgetTester tester;
  final FocusNode focusNode;
  final NotusDocument document;
  final ZefyrController controller;
  final Widget widget;

  factory EditorSandBox({
    required WidgetTester tester,
    FocusNode? focusNode,
    NotusDocument? document,
    ZefyrThemeData? theme,
    bool autofocus = false,
  }) {
    focusNode ??= FocusNode();
    document ??= NotusDocument.fromDelta(delta);
    var controller = ZefyrController(document);

    Widget widget = _ZefyrSandbox(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
    );

    if (theme != null) {
      widget = ZefyrTheme(data: theme, child: widget);
    }
    widget = MaterialApp(
      home: widget,
    );

    return EditorSandBox._(tester, focusNode, document, controller, widget);
  }

  EditorSandBox._(
      this.tester, this.focusNode, this.document, this.controller, this.widget);

  TextSelection get selection => controller.selection;

  Future<void> unfocus() {
    focusNode.unfocus();
    return tester.pumpAndSettle();
  }

  Future<void> updateSelection({required int base, required int extent}) {
    controller.updateSelection(
      TextSelection(baseOffset: base, extentOffset: extent),
    );
    return tester.pumpAndSettle();
  }

  Future<void> disable() {
    final state =
        tester.state(find.byType(_ZefyrSandbox)) as _ZefyrSandboxState;
    state.disable();
    return tester.pumpAndSettle();
  }

  Future<void> pump() async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Future<void> tap() async {
    await tester.tap(find.byType(RawEditor).first);
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
  }

  Future<void> pumpAndTap() async {
    await pump();
    await tap();
  }

  Future<void> tapHideKeyboardButton() async {
    await tapButtonWithIcon(Icons.keyboard_hide);
  }

  Future<void> tapButtonWithIcon(IconData icon) async {
    await tester.tap(find.widgetWithIcon(RawMaterialButton, icon));
    await tester.pumpAndSettle();
  }

  Future<void> tapButtonWithText(String text) async {
    await tester.tap(find.widgetWithText(RawMaterialButton, text));
    await tester.pumpAndSettle();
  }

  RawMaterialButton findButtonWithIcon(IconData icon) {
    final button = tester.widget(find.widgetWithIcon(RawMaterialButton, icon))
        as RawMaterialButton;
    return button;
  }

  RawMaterialButton findButtonWithText(String text) {
    final button = tester.widget(find.widgetWithText(RawMaterialButton, text))
        as RawMaterialButton;
    return button;
  }
}

class _ZefyrSandbox extends StatefulWidget {
  const _ZefyrSandbox({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.autofocus = false,
  }) : super(key: key);
  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;

  @override
  _ZefyrSandboxState createState() => _ZefyrSandboxState();
}

class _ZefyrSandboxState extends State<_ZefyrSandbox> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return ZefyrField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: !_enabled,
      autofocus: widget.autofocus,
    );
  }

  void disable() {
    setState(() {
      _enabled = false;
    });
  }
}
