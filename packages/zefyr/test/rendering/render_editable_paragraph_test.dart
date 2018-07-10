// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_paragraph.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$RenderEditableParagraph', () {
    final doc = new NotusDocument();
    doc.insert(0, 'This House Is A Circus');
    final text = new TextSpan(text: 'This House Is A Circus');
    final link = new LayerLink();
    final showCursor = new ValueNotifier<bool>(true);
    final selection = new TextSelection.collapsed(offset: 0);
    final selectionColor = Colors.blue;
    ZefyrRenderContext viewport;

    RenderEditableParagraph p;
    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      viewport = new ZefyrRenderContext();
      p = new RenderEditableParagraph(
        text,
        node: doc.root.children.first,
        layerLink: link,
        renderContext: viewport,
        showCursor: showCursor,
        selection: selection,
        selectionColor: selectionColor,
        textDirection: TextDirection.ltr,
      );
    });

    test('it registers with viewport', () {
      var owner = new PipelineOwner();
      expect(viewport.active, isNot(contains(p)));
      p.attach(owner);
      expect(viewport.dirty, contains(p));
      p.layout(new BoxConstraints());
      expect(viewport.active, contains(p));
    });
  });
}
