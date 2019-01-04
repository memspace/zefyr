// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

class _TestControls extends ZefyrSelectionControls {
  @override
  Widget buildToolbar(BuildContext context, ZefyrScope scope) {
    return null;
  }
}

void main() {
  group('$ZefyrSelectionControls', () {
    final controls = _TestControls();
    ZefyrController controller;

    setUp(() {
      final delta = Delta()..insert('Selection controls\n');
      controller = ZefyrController(NotusDocument.fromDelta(delta));
    });

    test('cannot cut with view-only scope', () {
      var scope = ZefyrScope.view(imageDelegate: ZefyrDefaultImageDelegate());
      expect(controls.canCut(scope), isFalse);
    });

    test('cannot cut when in select-only mode', () {
      controller
          .updateSelection(TextSelection(baseOffset: 0, extentOffset: 10));
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canCut(scope), isFalse);
    });

    test('cannot cut when selection is collapsed in edit mode', () {
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canCut(scope), isFalse);
    });

    test('can cut with expanded selection in edit mode', () {
      controller
          .updateSelection(TextSelection(baseOffset: 0, extentOffset: 10));
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.edit,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canCut(scope), isTrue);
    });

    test('can copy with expanded selection only', () {
      controller
          .updateSelection(TextSelection(baseOffset: 0, extentOffset: 10));
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canCopy(scope), isTrue);
      controller.updateSelection(TextSelection.collapsed(offset: 0));
      expect(controls.canCopy(scope), isFalse);
    });

    test('cannot paste in view-only scope', () {
      var scope = ZefyrScope.view(imageDelegate: ZefyrDefaultImageDelegate());
      expect(controls.canPaste(scope), isFalse);
    });

    test('cannot paste when in select-only mode', () {
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canPaste(scope), isFalse);
    });

    test('can paste when in edit mode', () {
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.edit,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canPaste(scope), isTrue);
    });

    test('cannot select all in view-only scope', () {
      var scope = ZefyrScope.view(imageDelegate: ZefyrDefaultImageDelegate());
      expect(controls.canSelectAll(scope), isFalse);
    });

    test('cannot select all when in view-only mode', () {
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.view,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canSelectAll(scope), isFalse);
    });

    test('cannot select all when selection is not collapsed', () {
      controller
          .updateSelection(TextSelection(baseOffset: 0, extentOffset: 10));
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canSelectAll(scope), isFalse);
    });

    test('cannot select all when document is empty', () {
      controller.replaceText(0, 18, '');
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canSelectAll(scope), isFalse);
    });

    test('can select all', () {
      final scope = ZefyrScope.editable(
        mode: ZefyrMode.select,
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
        controller: controller,
      );
      expect(controls.canSelectAll(scope), isTrue);
    });
  });
}
