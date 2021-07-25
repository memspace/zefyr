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
      var doc = NotusDocument();
      controller = ZefyrController(doc);
    });

    test('dispose', () {
      controller.dispose();
      expect(controller.document.isClosed, isTrue);
    });

    test('selection', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.updateSelection(TextSelection.collapsed(offset: 0));
      expect(notified, isTrue);
      expect(controller.selection, TextSelection.collapsed(offset: 0));
      // expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('compose', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = TextSelection.collapsed(offset: 5);
      var change = Delta()..insert('Words');
      controller.compose(change, selection: selection);
      expect(notified, isTrue);
      expect(controller.selection, selection);
      expect(controller.document.toDelta(), Delta()..insert('Words\n'));
      // expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('compose and transform position', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = TextSelection.collapsed(offset: 5);
      var change = Delta()..insert('Words');
      controller.compose(change, selection: selection);
      var change2 = Delta()..insert('More ');
      controller.compose(change2);
      expect(notified, isTrue);
      var expectedSelection = TextSelection.collapsed(offset: 10);
      expect(controller.selection, expectedSelection);
      expect(controller.document.toDelta(), Delta()..insert('More Words\n'));
      // expect(controller.lastChangeSource, ChangeSource.remote);
    });

    test('replaceText', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = TextSelection.collapsed(offset: 5);
      controller.replaceText(0, 0, 'Words', selection: selection);
      expect(notified, isTrue);
      expect(controller.selection, selection);
      expect(controller.document.toDelta(), Delta()..insert('Words\n'));
      // expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('formatText', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.replaceText(0, 0, 'Words');
      controller.formatText(0, 5, NotusAttribute.bold);
      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        Delta()..insert('Words', NotusAttribute.bold.toJson())..insert('\n'),
      );
      // expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('formatText with toggled style enabled', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.replaceText(0, 0, 'Words');
      controller.formatText(2, 0, NotusAttribute.bold);
      // Test that doing nothing does reset the toggledStyle.
      controller.replaceText(2, 0, '');
      controller.replaceText(2, 0, 'n');
      controller.formatText(3, 0, NotusAttribute.bold);
      controller.replaceText(3, 0, 'B');
      expect(notified, isTrue);

      expect(
        controller.document.toDelta(),
        Delta()
          ..insert('Won')
          ..insert('B', NotusAttribute.bold.toJson())
          ..insert('rds')
          ..insert('\n'),
      );
      // expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('insert text with toggled style unset', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.replaceText(0, 0, 'Words');
      controller.formatText(1, 0, NotusAttribute.bold);
      controller.replaceText(1, 0, 'B');
      controller.formatText(2, 0, NotusAttribute.bold.unset);
      controller.replaceText(2, 0, 'u');

      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        Delta()
          ..insert('W')
          ..insert('B', NotusAttribute.bold.toJson())
          ..insert('uords')
          ..insert('\n'),
      );
      // expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('formatSelection', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      var selection = TextSelection(baseOffset: 0, extentOffset: 5);
      controller.replaceText(0, 0, 'Words', selection: selection);
      controller.formatSelection(NotusAttribute.bold);
      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        Delta()..insert('Words', NotusAttribute.bold.toJson())..insert('\n'),
      );
      // expect(controller.lastChangeSource, ChangeSource.local);
    });

    test('getSelectionStyle', () {
      var selection = TextSelection.collapsed(offset: 3);
      controller.replaceText(0, 0, 'Words', selection: selection);
      controller.formatText(0, 5, NotusAttribute.bold);
      var result = controller.getSelectionStyle();
      expect(result.values, [NotusAttribute.bold]);
    });

    test('getSelectionStyle with toggled style', () {
      var selection = TextSelection.collapsed(offset: 3);
      controller.replaceText(0, 0, 'Words', selection: selection);
      controller.formatText(3, 0, NotusAttribute.bold);

      var result = controller.getSelectionStyle();
      expect(result.values, [NotusAttribute.bold]);
    });

    test('preserve inline format when replacing text from the first character',
        () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });
      controller.formatText(0, 0, NotusAttribute.bold);
      controller.replaceText(0, 0, 'Word');
      expect(notified, isTrue);
      expect(
        controller.document.toDelta(),
        Delta()..insert('Word', NotusAttribute.bold.toJson())..insert('\n'),
      );
      // expect(controller.lastChangeSource, ChangeSource.local);
    });
    
    test('addNewlineAtLast', () {
      controller.replaceText(0, 0, 'words');
      controller.addNewlineAtLast();
      expect(
        controller.document.toDelta(),
        Delta()..insert('words')..insert('\n')..insert('\n'),
      );
    });

    test('updateSelectionAtLast', () {
      controller.replaceText(0, 0, 'words');
      controller.updateSelectionAtLast();
      expect(controller.selection, TextSelection.collapsed(offset: 5));
    });

    test('isEndNewline true', () {
      controller.replaceText(0, 0, 'words\n');
      expect(controller.isEndNewline(), isTrue);
    });

    test('isEndNewline false', () {
      controller.replaceText(0, 0, 'words');
      expect(controller.isEndNewline(), isFalse);
    });

    test('increaseIndent', () {
      controller.replaceText(0, 0, 'words');
      controller.increaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent.value, 1);
    });

    test('increaseIndent max: 5', () {
      controller.replaceText(0, 0, 'words');
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      controller.increaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent.value, 5);
    });

    test('decreaseIndent', () {
      controller.replaceText(0, 0, 'words');
      controller.formatText(0, 0, NotusAttribute.indent.fromInt(3));
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent.value, 2);
    });

    test('decreaseIndent min: null', () {
      controller.replaceText(0, 0, 'words');
      controller.decreaseIndentAtSelection();
      controller.decreaseIndentAtSelection();
      controller.decreaseIndentAtSelection();
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent?.value, null);
    });

    test('increaseIndent Block', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.bulletList);
      controller.increaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      final block = controller.getSelectionStyle().get(NotusAttribute.block);
      print(controller.document.toJson());
      expect(indent.value, 1);
      expect(block.value, 'ul');
    });

    test('decreaseIndent Block', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.bulletList);
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      final block = controller.getSelectionStyle().get(NotusAttribute.block);
      print(controller.document.toJson());
      expect(indent?.value, null);
      expect(block.value, 'ul');
    });

    test('indent middleHeading', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.middleHeading);
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent?.value, null);
    });

    test('indent largeHeading', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.largeHeading);
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent?.value, null);
    });

    test('indent quote', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.quote);
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent?.value, null);
    });

    test('indent code', () {
      controller.replaceText(0, 0, 'words');
      controller.formatSelection(NotusAttribute.block.code);
      controller.decreaseIndentAtSelection();
      final indent = controller.getSelectionStyle().get(NotusAttribute.indent);
      expect(indent?.value, null);
    });
  });
}
