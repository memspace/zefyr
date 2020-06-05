// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/src/widgets/buttons.dart';
import 'package:zefyr/zefyr.dart';

import '../testing.dart';

void main() {
  group('$ZefyrButton', () {
    testWidgets('toggle style', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 5, extent: 10);
      await editor.tapButtonWithIcon(Icons.format_bold);

      LineNode line = editor.document.root.children.first;
      expect(line.childCount, 3);
      TextNode bold = line.children.elementAt(1);
      expect(bold.style.toJson(), NotusAttribute.bold.toJson());
      expect(bold.value, 'House');

      await editor.tapButtonWithIcon(Icons.format_bold);
      line = editor.document.root.children.first as LineNode;
      expect(line.childCount, 1);
    });

    testWidgets('toggle state for different styles of the same attribute',
        (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();

      await editor.tapButtonWithIcon(Icons.format_list_bulleted);
      expect(editor.document.root.children.first, isInstanceOf<BlockNode>());

      var ul = editor.findButtonWithIcon(Icons.format_list_bulleted);
      var ol = editor.findButtonWithIcon(Icons.format_list_numbered);
      expect(ul.isToggled, isTrue);
      expect(ol.isToggled, isFalse);
    });
  });

  group('$HeadingButton', () {
    testWidgets('toggle menu', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.format_size);

      expect(find.text('H1'), findsOneWidget);
      var h1 = editor.findButtonWithText('H1');
      expect(h1.action, ZefyrToolbarAction.headingLevel1);
      var h2 = editor.findButtonWithText('H2');
      expect(h2.action, ZefyrToolbarAction.headingLevel2);
      var h3 = editor.findButtonWithText('H3');
      expect(h3.action, ZefyrToolbarAction.headingLevel3);
    });

    testWidgets('toggle styles', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.format_size);
      await editor.tapButtonWithText('H3');
      LineNode line = editor.document.root.children.first;
      expect(line.style.containsSame(NotusAttribute.heading.level3), isTrue);
      await editor.tapButtonWithText('H2');
      expect(line.style.containsSame(NotusAttribute.heading.level2), isTrue);
    });

    testWidgets('close overlay', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.format_size);
      expect(find.text('H1'), findsOneWidget);
      await editor.tapButtonWithIcon(Icons.close);
      expect(find.text('H1'), findsNothing);
    });
  });

  group('$LinkButton', () {
    testWidgets('disabled when selection is collapsed', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.link);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('enabled and toggles menu with non-empty selection',
        (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 5, extent: 10);
      await editor.tapButtonWithIcon(Icons.link);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('auto cancels edit on selection update', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 5, extent: 10);
      await editor.tapButtonWithIcon(Icons.link);
      await tester
          .tap(find.widgetWithText(GestureDetector, 'Tap to edit link'));
      await tester.pumpAndSettle();
      expect(editor.focusNode.hasFocus, isFalse);
      await editor.updateSelection(base: 10, extent: 10);
      expect(find.byIcon(Icons.link_off), findsNothing);
    });

    testWidgets('editing link', (tester) async {
      final editor = EditorSandBox(tester: tester);
      await editor.pumpAndTap();
      await editor.updateSelection(base: 5, extent: 10);

      await editor.tapButtonWithIcon(Icons.link);
      await tester
          .tap(find.widgetWithText(GestureDetector, 'Tap to edit link'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'https://').first,
          'https://github.com');
      await tester.pumpAndSettle();
      expect(
          find.widgetWithText(TextField, 'https://github.com'), findsOneWidget);
      await editor.tapButtonWithIcon(Icons.check);
      expect(find.widgetWithText(ZefyrToolbarScaffold, 'https://github.com'),
          findsOneWidget);
      LineNode line = editor.document.root.children.first;
      expect(line.childCount, 3);
      TextNode link = line.children.elementAt(1);
      expect(link.value, 'House');
      expect(link.style.toJson(),
          NotusAttribute.link.fromString('https://github.com').toJson());

      // unlink
      await editor.updateSelection(base: 7, extent: 7);
      await editor.tapButtonWithIcon(Icons.link);
      await editor.tapButtonWithIcon(Icons.link_off);
      line = editor.document.root.children.first as LineNode;
      expect(line.childCount, 1);
    });
  });

  group('$ImageButton', () {
    testWidgets('toggle overlay', (tester) async {
      final editor = EditorSandBox(
        tester: tester,
        imageDelegate: _TestImageDelegate(),
      );
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);

      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      await editor.tapButtonWithIcon(Icons.close);
      expect(find.byIcon(Icons.photo_camera), findsNothing);
    });

    testWidgets('pick from camera', (tester) async {
      final editor = EditorSandBox(
        tester: tester,
        imageDelegate: _TestImageDelegate(),
      );
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_camera);
      expect(find.byType(ZefyrImage), findsOneWidget);
    });

    testWidgets('pick from gallery', (tester) async {
      final editor = EditorSandBox(
        tester: tester,
        imageDelegate: _TestImageDelegate(),
      );
      await editor.pumpAndTap();
      await editor.tapButtonWithIcon(Icons.photo);
      await editor.tapButtonWithIcon(Icons.photo_library);
      expect(find.byType(ZefyrImage), findsOneWidget);
    });
  });
}

class _TestImageDelegate implements ZefyrImageDelegate<String> {
  @override
  Widget buildImage(BuildContext context, String key) {
    return Image.file(File(key));
  }

  @override
  String get cameraSource => 'camera';

  @override
  String get gallerySource => 'gallery';

  @override
  Future<String> pickImage(String source) {
    return Future.value('file:///tmp/test.jpg');
  }
}
