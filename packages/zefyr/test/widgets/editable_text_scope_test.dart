// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/editable_box.dart';
import 'package:zefyr/src/widgets/render_context.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$ZefyrEditableTextScope', () {
    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
    });

    test('updateShouldNotify for rendering context changes', () {
      var context = new ZefyrRenderContext();
      var paragraph1 = createParagraph(context);
      var paragraph2 = createParagraph(context);
      context.addBox(paragraph1);
      context.markDirty(paragraph1, false);
      var widget1 = createScope(renderingContext: context);
      var widget2 = createScope(renderingContext: context);

      expect(widget2.updateShouldNotify(widget1), isFalse);
      context.addBox(paragraph2);
      context.markDirty(paragraph2, false);
      widget2 = createScope(renderingContext: context);
      expect(widget2.updateShouldNotify(widget1), isTrue);
    });

    test('updateShouldNotify for selection changes', () {
      var context = new ZefyrRenderContext();
      var selection = new TextSelection.collapsed(offset: 0);
      var widget1 =
          createScope(renderingContext: context, selection: selection);
      var widget2 =
          createScope(renderingContext: context, selection: selection);

      expect(widget2.updateShouldNotify(widget1), isFalse);
      selection = new TextSelection.collapsed(offset: 1);
      widget2 = createScope(renderingContext: context, selection: selection);
      expect(widget2.updateShouldNotify(widget1), isTrue);
    });

    test('updateShouldNotify for showCursor changes', () {
      var context = new ZefyrRenderContext();
      var showCursor = new ValueNotifier<bool>(true);
      var widget1 =
          createScope(renderingContext: context, showCursor: showCursor);
      var widget2 =
          createScope(renderingContext: context, showCursor: showCursor);

      expect(widget2.updateShouldNotify(widget1), isFalse);
      showCursor = new ValueNotifier<bool>(true);
      widget2 = createScope(renderingContext: context, showCursor: showCursor);
      expect(widget2.updateShouldNotify(widget1), isTrue);
    });

    test('updateShouldNotify for imageDelegate changes', () {
      var context = new ZefyrRenderContext();
      var delegate = new ZefyrDefaultImageDelegate();
      var widget1 =
          createScope(renderingContext: context, imageDelegate: delegate);
      var widget2 =
          createScope(renderingContext: context, imageDelegate: delegate);

      expect(widget2.updateShouldNotify(widget1), isFalse);
      delegate = new ZefyrDefaultImageDelegate();
      widget2 = createScope(renderingContext: context, imageDelegate: delegate);
      expect(widget2.updateShouldNotify(widget1), isTrue);
    });
  });
}

ZefyrEditableTextScope createScope({
  @required ZefyrRenderContext renderingContext,
  TextSelection selection,
  ValueNotifier<bool> showCursor,
  ZefyrImageDelegate imageDelegate,
}) {
  return ZefyrEditableTextScope(
    renderContext: renderingContext,
    selection: selection,
    showCursor: showCursor,
    imageDelegate: imageDelegate,
    child: null,
  );
}

RenderEditableProxyBox createParagraph(ZefyrRenderContext context) {
  final doc = new NotusDocument();
  doc.insert(0, 'This House Is A Circus');
  final link = new LayerLink();
  final showCursor = new ValueNotifier<bool>(true);
  final selection = new TextSelection.collapsed(offset: 0);
  final selectionColor = Colors.blue;
  return new RenderEditableProxyBox(
    node: doc.root.children.first,
    layerLink: link,
    renderContext: context,
    showCursor: showCursor,
    selection: selection,
    selectionColor: selectionColor,
    cursorColor: Color(0),
  );
}
