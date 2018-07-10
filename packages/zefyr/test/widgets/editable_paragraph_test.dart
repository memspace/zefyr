// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_paragraph.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$EditableParagraph', () {
    final doc = new NotusDocument();
    doc.insert(0, 'This House Is A Circus');
    final text = new TextSpan(text: 'This House Is A Circus');
    final link = new LayerLink();
    final showCursor = new ValueNotifier<bool>(true);
    final selection = new TextSelection.collapsed(offset: 0);
    final selectionColor = Colors.blue;
    ZefyrRenderContext viewport;

    Widget widget;
    setUp(() {
      viewport = new ZefyrRenderContext();
      widget = new Directionality(
        textDirection: TextDirection.ltr,
        child: new EditableParagraph(
            node: doc.root.children.first,
            text: text,
            layerLink: link,
            renderContext: viewport,
            showCursor: showCursor,
            selection: selection,
            selectionColor: selectionColor),
      );
    });

    testWidgets('initialize', (tester) async {
      await tester.pumpWidget(widget);
      EditableParagraph result =
          tester.firstWidget(find.byType(EditableParagraph));
      expect(result, isNotNull);
      expect(result.text.text, 'This House Is A Circus');
    });
  });
}
