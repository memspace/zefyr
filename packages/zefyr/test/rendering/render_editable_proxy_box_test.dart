// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_box.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/src/widgets/rich_text.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$RenderEditableProxyBox', () {
    final doc = NotusDocument();
    doc.insert(0, 'This House Is A Circus');
    final text = TextSpan(text: 'This House Is A Circus');

    ZefyrRenderContext renderContext;
    RenderEditableProxyBox p;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      renderContext = ZefyrRenderContext();
      final rt = RenderZefyrParagraph(
        text,
        node: doc.root.children.first as LineNode,
        textDirection: TextDirection.ltr,
      );
      p = RenderEditableProxyBox(
        child: rt,
        node: doc.root.children.first as LineNode,
        layerLink: LayerLink(),
        renderContext: renderContext,
        showCursor: ValueNotifier<bool>(true),
        selection: TextSelection.collapsed(offset: 0),
        selectionColor: Color(0),
        cursorColor: Color(0),
      );
    });

    test('it registers with render context', () {
      var owner = PipelineOwner();
      expect(renderContext.active, isNot(contains(p)));
      p.attach(owner);
      expect(renderContext.dirty, contains(p));
      p.layout(BoxConstraints());
      expect(renderContext.active, contains(p));

      p.detach();
      expect(renderContext.active, isNot(contains(p)));
      p.attach(owner);
      expect(renderContext.active, contains(p));

      p.markNeedsLayout();
      p.detach();
      expect(renderContext.active, isNot(contains(p)));

      p.layout(BoxConstraints());
      expect(renderContext.active, contains(p));
    });
  });
}
