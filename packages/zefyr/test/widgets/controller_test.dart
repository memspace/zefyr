// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$ZefyrController', () {
    ZefyrController controller;

    setUp(() {
      var doc = new NotusDocument();
      controller = new ZefyrController(doc);
    });

    test('dispose', () {
      controller.dispose();
      expect(controller.document.isClosed, isTrue);
    });

    test('selection', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateSelection(new TextSelection.collapsed(offset: 0));
      expect(notified, isTrue);
      expect(controller.selection, new TextSelection.collapsed(offset: 0));
      expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('compose', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = new TextSelection.collapsed(offset: 5);
      var change = new Delta()..insert('Words');
      controller.compose(change, selection: selection);
      expect(notified, isTrue);
      expect(controller.selection, selection);
      expect(controller.document.toDelta(), new Delta()..insert('Words\n'));
      expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('compose and transform position', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = new TextSelection.collapsed(offset: 5);
      var change = new Delta()..insert('Words');
      controller.compose(change, selection: selection);
      var change2 = new Delta()..insert('More ');
      controller.compose(change2);
      expect(notified, isTrue);
      var expectedSelection = new TextSelection.collapsed(offset: 10);
      expect(controller.selection, expectedSelection);
      expect(
          controller.document.toDelta(), new Delta()..insert('More Words\n'));
      expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('replaceText', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = new TextSelection.collapsed(offset: 5);
      controller.replaceText(0, 0, 'Words', selection: selection);
      expect(notified, isTrue);
      expect(controller.selection, selection);
      expect(controller.document.toDelta(), new Delta()..insert('Words\n'));
      expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('formatText', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.replaceText(0, 0, 'Words');
      controller.formatText(0, 5, NotusAttribute.bold);
      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        new Delta()
          ..insert('Words', NotusAttribute.bold.toJson())
          ..insert('\n'),
      );
      expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('formatSelection', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = new TextSelection(baseOffset: 0, extentOffset: 5);
      controller.replaceText(0, 0, 'Words', selection: selection);
      controller.formatSelection(NotusAttribute.bold);
      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        new Delta()
          ..insert('Words', NotusAttribute.bold.toJson())
          ..insert('\n'),
      );
      expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('getSelectionStyle', () {
      var selection = new TextSelection.collapsed(offset: 3);
      controller.replaceText(0, 0, 'Words', selection: selection);
      controller.formatText(0, 5, NotusAttribute.bold);
      var result = controller.getSelectionStyle();
      expect(result.values, [NotusAttribute.bold]);
    });
  });
}
