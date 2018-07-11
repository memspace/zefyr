// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_rich_text.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$RenderEditableParagraph', () {
    final doc = new NotusDocument();
    doc.insert(0, 'This House Is A Circus');
    final text = new TextSpan(text: 'This House Is A Circus');

    ZefyrRenderContext renderContext;
    RenderEditableParagraph p;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      renderContext = new ZefyrRenderContext();
      p = new RenderEditableParagraph(
        text,
        node: doc.root.children.first,
        textDirection: TextDirection.ltr,
      );
    });

    test('it registers with viewport', () {
      var owner = new PipelineOwner();
      expect(renderContext.active, isNot(contains(p)));
      p.attach(owner);
      expect(renderContext.dirty, contains(p));
      p.layout(new BoxConstraints());
      expect(renderContext.active, contains(p));
    }, skip: 'TODO: move to RenderEditableProxyBox');
  });
}
