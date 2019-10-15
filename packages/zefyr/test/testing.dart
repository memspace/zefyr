// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/src/widgets/selection.dart';
import 'package:zefyr/zefyr.dart';

var delta = Delta()..insert('This House Is A Circus\n');

class EditorSandBox {
  final WidgetTester tester;
  final FocusNode focusNode;
  final NotusDocument document;
  final ZefyrController controller;
  final Widget widget;

  factory EditorSandBox({
    @required WidgetTester tester,
    FocusNode focusNode,
    NotusDocument document,
    ZefyrThemeData theme,
    bool autofocus = false,
    ZefyrImageDelegate imageDelegate,
  }) {
    focusNode ??= FocusNode();
    document ??= NotusDocument.fromDelta(delta);
    var controller = ZefyrController(document);

    Widget widget = _ZefyrSandbox(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      imageDelegate: imageDelegate,
    );

    if (theme != null) {
      widget = ZefyrTheme(data: theme, child: widget);
    }
    widget = MaterialApp(
      home: ZefyrScaffold(child: widget),
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

  Future<void> updateSelection({int base, int extent}) {
    controller.updateSelection(
      TextSelection(baseOffset: base, extentOffset: extent),
    );
    return tester.pumpAndSettle();
  }

  Future<void> disable() {
    _ZefyrSandboxState state = tester.state(find.byType(_ZefyrSandbox));
    state.disable();
    return tester.pumpAndSettle();
  }

  Future<void> pump() async {
    await tester.pumpWidget(widget);
  }

  Future<void> tap() async {
    await tester.tap(find.byType(ZefyrParagraph).first);
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
    await tester.tap(find.widgetWithIcon(ZefyrButton, icon));
    await tester.pumpAndSettle();
  }

  Future<void> tapButtonWithText(String text) async {
    await tester.tap(find.widgetWithText(ZefyrButton, text));
    await tester.pumpAndSettle();
  }

  RawZefyrButton findButtonWithIcon(IconData icon) {
    RawZefyrButton button =
        tester.widget(find.widgetWithIcon(RawZefyrButton, icon));
    return button;
  }

  RawZefyrButton findButtonWithText(String text) {
    RawZefyrButton button =
        tester.widget(find.widgetWithText(RawZefyrButton, text));
    return button;
  }

  Finder findSelectionHandle() {
    return find.descendant(
        of: find.byType(SelectionHandleDriver),
        matching: find.byType(GestureDetector));
  }
}

class _ZefyrSandbox extends StatefulWidget {
  const _ZefyrSandbox({
    Key key,
    this.controller,
    this.focusNode,
    this.autofocus,
    this.imageDelegate,
  }) : super(key: key);
  final ZefyrController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ZefyrImageDelegate imageDelegate;

  @override
  _ZefyrSandboxState createState() => _ZefyrSandboxState();
}

class _ZefyrSandboxState extends State<_ZefyrSandbox> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return ZefyrEditor(
      controller: widget.controller,
      focusNode: widget.focusNode,
      mode: _enabled ? ZefyrMode.edit : ZefyrMode.view,
      autofocus: widget.autofocus,
      imageDelegate: widget.imageDelegate,
    );
  }

  void disable() {
    setState(() {
      _enabled = false;
    });
  }
}
