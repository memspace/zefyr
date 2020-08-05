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
    final state =
        tester.state(find.byType(_ZefyrSandbox)) as _ZefyrSandboxState;
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
    final button = tester.widget(find.widgetWithIcon(RawZefyrButton, icon))
        as RawZefyrButton;
    return button;
  }

  RawZefyrButton findButtonWithText(String text) {
    final button = tester.widget(find.widgetWithText(RawZefyrButton, text))
        as RawZefyrButton;
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
    @required this.controller,
    @required this.focusNode,
    this.autofocus = false,
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

class MultiEditorSandbox {
  final WidgetTester tester;
  final Key firstEditorKey;
  final Key secondEditorKey;
  final FocusNode firstFocusNode;
  final FocusNode secondFocusNode;
  final Widget widget;

  factory MultiEditorSandbox({@required WidgetTester tester}) {
    final firstEditorKey = UniqueKey();
    final secondEditorKey = UniqueKey();
    final firstFocusNode = FocusNode();
    final secondFocusNode = FocusNode();
    Widget first = _ZefyrSandbox(
      key: firstEditorKey,
      controller: ZefyrController(NotusDocument.fromDelta(delta)),
      focusNode: firstFocusNode,
    );
    Widget second = _ZefyrSandbox(
      key: secondEditorKey,
      controller: ZefyrController(NotusDocument.fromDelta(delta)),
      focusNode: secondFocusNode,
    );

    Widget widget = MaterialApp(
      home: Scaffold(
        body: ZefyrScaffold(
          child: Column(
            children: <Widget>[
              SizedBox(height: 100, child: first),
              SizedBox(height: 10),
              SizedBox(height: 100, child: second),
            ],
          ),
        ),
      ),
    );

    return MultiEditorSandbox._(
      tester: tester,
      widget: widget,
      firstEditorKey: firstEditorKey,
      secondEditorKey: secondEditorKey,
      firstFocusNode: firstFocusNode,
      secondFocusNode: secondFocusNode,
    );
  }

  MultiEditorSandbox._({
    @required this.tester,
    @required this.widget,
    @required this.firstEditorKey,
    @required this.secondEditorKey,
    @required this.firstFocusNode,
    @required this.secondFocusNode,
  });

  Future<void> pump() async {
    await tester.pumpWidget(widget);
  }

  Future<void> tapFirstEditor() async {
    await tester.tap(find.byKey(firstEditorKey).first);
    await tester.pumpAndSettle();
  }

  Future<void> tapSecondEditor() async {
    await tester.tap(find.byKey(secondEditorKey).first);
    await tester.pumpAndSettle();
  }

  ZefyrEditor findFirstEditor() {
    return tester.widget(find.descendant(
      of: find.byKey(firstEditorKey),
      matching: find.byType(ZefyrEditor),
    ));
  }

  ZefyrEditor findSecondEditor() {
    return tester.widget(find.descendant(
      of: find.byKey(secondEditorKey),
      matching: find.byType(ZefyrEditor),
    ));
  }

  Future<void> tapButtonWithIcon(IconData icon) async {
    await tester.tap(find.widgetWithIcon(ZefyrButton, icon));
    await tester.pumpAndSettle();
  }
}
