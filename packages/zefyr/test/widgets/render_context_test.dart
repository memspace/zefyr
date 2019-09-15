// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_box.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$ZefyrRenderContext', () {
    ZefyrRenderContext context;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      context = ZefyrRenderContext();
    });

    test('adds to dirty list first', () {
      var p = createParagraph(context);
      context.addBox(p);
      expect(context.dirty, isNotEmpty);
      expect(context.active, isEmpty);
      expect(context.dirty, contains(p));
    });

    test('removes from dirty list', () {
      var p = createParagraph(context);
      context.addBox(p);
      expect(context.dirty, isNotEmpty);
      context.removeBox(p);
      expect(context.dirty, isEmpty);
    });

    test('markDirty moves between active and dirty lists', () {
      var p = createParagraph(context);
      context.addBox(p);
      context.markDirty(p, false);
      expect(context.dirty, isEmpty);
      expect(context.active, isNotEmpty);
      context.markDirty(p, true);
      expect(context.dirty, isNotEmpty);
      expect(context.active, isEmpty);
    });

    test('finds paragraph for text offset', () {
      var p = createParagraph(context);
      context.addBox(p);
      expect(context.boxForTextOffset(0), isNull);
      context.markDirty(p, false);
      expect(context.boxForTextOffset(0), p);
    });

    testWidgets('notifyListeners is delayed to next frame', (tester) async {
      var focusNode = FocusNode();
      var controller = ZefyrController(NotusDocument());
      var widget = MaterialApp(
        home: ZefyrScaffold(
          child: ZefyrEditor(
            controller: controller,
            focusNode: focusNode,
          ),
        ),
      );
      await tester.pumpWidget(widget);
      controller.replaceText(0, 0, 'test');
      var result = await tester.pumpAndSettle();
      expect(result, 2);
    });
  });
}

RenderEditableProxyBox createParagraph(ZefyrRenderContext viewport) {
  final doc = NotusDocument();
  doc.insert(0, 'This House Is A Circus');
  final LineNode node = doc.root.children.first;
  final link = LayerLink();
  final showCursor = ValueNotifier<bool>(true);
  final selection = TextSelection.collapsed(offset: 0);
  final selectionColor = Colors.blue;
  return RenderEditableProxyBox(
    node: node,
    layerLink: link,
    renderContext: viewport,
    showCursor: showCursor,
    selection: selection,
    selectionColor: selectionColor,
    cursorColor: Color(0),
  );
}
