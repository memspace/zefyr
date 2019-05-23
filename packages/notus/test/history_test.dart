// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

NotusDocument _initDoc({String text, int interval = 0}) {
  NotusDocument doc;
  if (text == null) {
    doc = NotusDocument();
  } else {
    doc = NotusDocument.fromDelta(new Delta()..insert(text));
  }
  doc.history = NotusHistory(interval: interval);
  return doc;
}

void main() {
  group("undo&redo", () {
    test("limits undo stack size", () {
      final doc = _initDoc();
      doc.history = NotusHistory(maxStack: 2, interval: 0);
      doc.insert(0, "a");
      doc.insert(0, "b");
      doc.insert(0, "c");
      expect(doc.history.stack.undo.length, 2);
    });

    test('user change', () {
      const origin = "origin\n";
      const change = "change\n";

      final doc = _initDoc(text: origin);
      doc.replace(0, origin.length, change);
    });

    test("merge changes", () {
      final doc = _initDoc(text: "The lazy fox\n", interval: 400);
      expect(doc.history.stack.undo.length, 0);
      doc.compose(
          new Delta()
            ..retain(12)
            ..insert("e"),
          ChangeSource.local);
      expect(doc.history.stack.undo.length, 1);
      doc.compose(
          new Delta()
            ..retain(13)
            ..insert("f"),
          ChangeSource.local);
      expect(doc.history.stack.undo.length, 1);
      doc.history.undo(doc);
      expect(doc.history.stack.undo.length, 0);
    });

    test("donot merge changes", () {
      final doc = _initDoc(text: "The lazy fox\n", interval: 100);
      expect(doc.history.stack.undo.length, 0);
      doc.compose(
          new Delta()
            ..retain(12)
            ..insert("e"),
          ChangeSource.local);
      expect(doc.history.stack.undo.length, 1);
      doc.history.lastRecorded = 0;
      doc.compose(
          new Delta()
            ..retain(13)
            ..insert("f"),
          ChangeSource.local);
      expect(doc.history.stack.undo.length, 2);
    });

    test("multi undos", () {
      final String original = "The lazy fox\n";
      final doc = _initDoc(text: original, interval: 100);
      expect(doc.history.stack.undo.length, 0);
      doc.compose(
          new Delta()
            ..retain(12)
            ..insert("e"),
          ChangeSource.local);
      final contents = doc.toPlainText();
      sleep(Duration(milliseconds: 100));
      doc.compose(
          new Delta()
            ..retain(13)
            ..insert("s"),
          ChangeSource.local);

      doc.history.undo(doc);
      expect(doc.toPlainText(), contents);

      doc.history.undo(doc);
      expect(doc.toPlainText(), original);
    });

    test("transform api change", () {
      final String original = "The lazy fox\n";
      final doc = _initDoc(text: original, interval: 100);
      doc.history = NotusHistory(userOnly: true);

      doc.compose(
          new Delta()
            ..retain(12)
            ..insert("es"),
          ChangeSource.local);

      doc.history.lastRecorded = 0;

      doc.compose(
          new Delta()
            ..retain(14)
            ..insert("!"),
          ChangeSource.local);

      doc.history.undo(doc);

      doc.compose(
          new Delta()
            ..retain(4)
            ..delete(5),
          ChangeSource.remote);

      expect(doc.toPlainText(), "The foxes\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "The fox\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "The foxes\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "The foxes!\n");
    });

    test("transform preserve intention", () {
      final String original = "The lazy fox\n";
      final doc = _initDoc(text: original, interval: 100);
      doc.history = NotusHistory(userOnly: true);

      final url = "https://www.google.com";

      doc.compose(
          new Delta()..insert(url, NotusAttribute.link.withValue(url).toJson()),
          ChangeSource.local);

      doc.history.lastRecorded = 0;

      doc.compose(
          new Delta()
            ..retain(0)
            ..delete(url.length)
            ..insert("Google", NotusAttribute.link.withValue(url).toJson()),
          ChangeSource.remote);

      doc.history.lastRecorded = 0;

      doc.compose(
          new Delta()
            ..retain(doc.length - 1)
            ..insert("!"),
          ChangeSource.local);

      doc.history.lastRecorded = 0;

      expect(
          doc.toDelta(),
          Delta()
            ..insert("Google", NotusAttribute.link.withValue(url).toJson())
            ..insert("The lazy fox!\n"));

      doc.history.undo(doc);
      expect(
          doc.toDelta(),
          Delta()
            ..insert("Google", NotusAttribute.link.withValue(url).toJson())
            ..insert("The lazy fox\n"));

      doc.history.undo(doc);
      expect(
          doc.toDelta(),
          Delta()
            ..insert("Google", NotusAttribute.link.withValue(url).toJson())
            ..insert("The lazy fox\n"));

    });

    test("ignore remote changes", () {
      final doc = _initDoc(text: "\n");
      doc.history = NotusHistory(userOnly: true,interval: 0);

      doc.compose(
          new Delta()..retain(0)..insert('a'),
          ChangeSource.local);

      doc.compose(
          new Delta()..retain(1)..insert('b'),
          ChangeSource.remote);

      doc.compose(
          new Delta()..retain(2)..insert('c'),
          ChangeSource.local);

      doc.compose(
          new Delta()..retain(3)..insert('d'),
          ChangeSource.remote);

      expect(doc.toPlainText(), "abcd\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "abd\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "bd\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "abd\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "abcd\n");
    });

    test("correctly transform against remote changes", () {
      final doc = _initDoc(text: "b\n");
      doc.history = NotusHistory(userOnly: true,interval: 0);

      doc.compose(
          new Delta()..retain(1)..insert('d'),
          ChangeSource.local);

      doc.compose(
          new Delta()..retain(0)..insert('a'),
          ChangeSource.local);

      doc.compose(
          new Delta()..retain(2)..insert('c'),
          ChangeSource.remote);

      expect(doc.toPlainText(), "abcd\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "bcd\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "bc\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "bcd\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "abcd\n");
    });

    test("correctly transform against remote changes breaking up an insert", () {
      final doc = _initDoc(text: "\n");
      doc.history = NotusHistory(userOnly: true,interval: 0);

      doc.compose(
          new Delta()..retain(0)..insert('ABC'),
          ChangeSource.local);

      doc.compose(
          new Delta()..retain(3)..insert('4'),
          ChangeSource.remote);

      doc.compose(
          new Delta()..retain(2)..insert('3'),
          ChangeSource.remote);

      doc.compose(
          new Delta()..retain(1)..insert('2'),
          ChangeSource.remote);

      doc.compose(
          new Delta()..retain(0)..insert('1'),
          ChangeSource.remote);

      expect(doc.toPlainText(), "1A2B3C4\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "1234\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "1A2B3C4\n");

      doc.history.undo(doc);
      expect(doc.toPlainText(), "1234\n");

      doc.history.redo(doc);
      expect(doc.toPlainText(), "1A2B3C4\n");
    });

  });
}
