// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrDefaultImageDelegate', () {
    const MethodChannel channel =
        const MethodChannel('plugins.flutter.io/image_picker');

    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return '/tmp/test.jpg';
      });
      log.clear();
    });

    test('pick image', () async {
      final delegate = new ZefyrDefaultImageDelegate();
      final result = await delegate.pickImage(ImageSource.gallery);
      expect(result, 'file:///tmp/test.jpg');
    });
  });

  group('$ZefyrImage', () {
    const MethodChannel channel =
        const MethodChannel('plugins.flutter.io/image_picker');

    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return '/tmp/test.jpg';
      });
      log.clear();
    });

    testWidgets('embed image', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_camera);
      LineNode line = editor.document.root.children.last;
      expect(line.hasEmbed, isTrue);
      EmbedNode embed = line.children.single;
      expect(embed.style.value(NotusAttribute.embed), <String, dynamic>{
        'type': 'image',
        'source': 'file:///tmp/test.jpg',
      });
      expect(find.byType(ZefyrImage), findsOneWidget);
    });

    testWidgets('tap on left side of image puts caret before it',
        (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_camera);
      await editor.updateSelection(base: 0, extent: 0);

      await tester.tapAt(tester.getTopLeft(find.byType(ZefyrImage)));
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.isCollapsed, isTrue);
      expect(editor.selection.extentOffset, embed.documentOffset);
    });

    testWidgets('tap right side of image puts caret after it',
        (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_camera);
      await editor.updateSelection(base: 0, extent: 0);

      final img = find.byType(ZefyrImage);
      final offset = tester.getBottomRight(img) - new Offset(1.0, 1.0);
      await tester.tapAt(offset);
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.isCollapsed, isTrue);
      expect(editor.selection.extentOffset, embed.documentOffset + 1);
    });

    testWidgets('selects on long press', (tester) async {
      final editor = new EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_camera);
      await editor.updateSelection(base: 0, extent: 0);

      final img = find.byType(ZefyrImage);
      await tester.longPress(img);
      LineNode line = editor.document.root.children.last;
      EmbedNode embed = line.children.single;
      expect(editor.selection.baseOffset, embed.documentOffset);
      expect(editor.selection.extentOffset, embed.documentOffset + 1);
      expect(find.text('Paste'), findsOneWidget);
    });
  });
}
