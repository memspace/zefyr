// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:quill_delta/quill_delta.dart';

import 'document/attributes.dart';
import 'document/block.dart';
import 'document/leaf.dart';
import 'document/line.dart';
import 'document/node.dart';
import 'heuristics.dart';

/// Source of a [NotusChange].
enum ChangeSource {
  /// Change originated from a local action. Typically triggered by user.
  local,

  /// Change originated from a remote action.
  remote,
}

/// Represents a change in a [NotusDocument].
class NotusChange {
  NotusChange(this.before, this.change, this.source);

  /// Document state before [change].
  final Delta before;

  /// Change delta applied to the document.
  final Delta change;

  /// The source of this change.
  final ChangeSource source;
}

/// A rich text document.
class NotusDocument {
  /// Creates new empty Notus document.
  NotusDocument()
      : _heuristics = NotusHeuristics.fallback,
        _delta = Delta()..insert('\n') {
    _loadDocument(_delta);
  }

  NotusDocument.fromJson(List data)
      : _heuristics = NotusHeuristics.fallback,
        _delta = Delta.fromJson(data) {
    _loadDocument(_delta);
  }

  NotusDocument.fromDelta(Delta delta)
      : assert(delta != null),
        _heuristics = NotusHeuristics.fallback,
        _delta = delta {
    _loadDocument(_delta);
  }

  final NotusHeuristics _heuristics;

  /// The root node of this document tree.
  RootNode get root => _root;
  final RootNode _root = RootNode();

  /// Length of this document.
  int get length => _root.length;

  /// Stream of [NotusChange]s applied to this document.
  Stream<NotusChange> get changes => _controller.stream;

  final StreamController<NotusChange> _controller =
      StreamController.broadcast();

  /// Returns contents of this document as [Delta].
  Delta toDelta() => Delta.from(_delta);
  Delta _delta;

  /// Returns plain text representation of this document.
  String toPlainText() => _delta.toList().map((op) => op.data).join();

  dynamic toJson() {
    return _delta.toJson();
  }

  /// Returns `true` if this document and associated stream of [changes]
  /// is closed.
  ///
  /// Modifying a closed document is not allowed.
  bool get isClosed => _controller.isClosed;

  /// Closes [changes] stream.
  void close() {
    _controller.close();
  }

  /// Inserts [text] in this document at specified [index].
  ///
  /// This method applies heuristic rules before modifying this document and
  /// produces a [NotusChange] with source set to [ChangeSource.local].
  ///
  /// Returns an instance of [Delta] actually composed into this document.
  Delta insert(int index, String text) {
    assert(index >= 0);
    assert(text.isNotEmpty);
    text = _sanitizeString(text);
    if (text.isEmpty) return Delta();
    final change = _heuristics.applyInsertRules(this, index, text);
    compose(change, ChangeSource.local);
    return change;
  }

  /// Deletes [length] of characters from this document starting at [index].
  ///
  /// This method applies heuristic rules before modifying this document and
  /// produces a [NotusChange] with source set to [ChangeSource.local].
  ///
  /// Returns an instance of [Delta] actually composed into this document.
  Delta delete(int index, int length) {
    assert(index >= 0 && length > 0);
    // TODO: need a heuristic rule to ensure last line-break.
    final change = _heuristics.applyDeleteRules(this, index, length);
    if (change.isNotEmpty) {
      // Delete rules are allowed to prevent the edit so it may be empty.
      compose(change, ChangeSource.local);
    }
    return change;
  }

  /// Replaces [length] of characters starting at [index] [text].
  ///
  /// This method applies heuristic rules before modifying this document and
  /// produces a [NotusChange] with source set to [ChangeSource.local].
  ///
  /// Returns an instance of [Delta] actually composed into this document.
  Delta replace(int index, int length, String text) {
    assert(index >= 0 && (text.isNotEmpty || length > 0),
        'With index $index, length $length and text "$text"');
    var delta = Delta();
    // We have to compose before applying delete rules
    // Otherwise delete would be operating on stale document snapshot.
    if (text.isNotEmpty) {
      delta = insert(index + length, text);
    }

    if (length > 0) {
      final deleteDelta = delete(index, length);
      delta = delta.compose(deleteDelta);
    }
    return delta;
  }

  /// Formats segment of this document with specified [attribute].
  ///
  /// Applies heuristic rules before modifying this document and
  /// produces a [NotusChange] with source set to [ChangeSource.local].
  ///
  /// Returns an instance of [Delta] actually composed into this document.
  /// The returned [Delta] may be empty in which case this document remains
  /// unchanged and no [NotusChange] is published to [changes] stream.
  Delta format(int index, int length, NotusAttribute attribute) {
    assert(index >= 0 && length >= 0 && attribute != null);

    var change = Delta();

    if (attribute is EmbedAttribute && length > 0) {
      // Must delete selected length of text before applying embed attribute
      // since inserting an embed in non-empty selection is essentially a
      // replace operation.
      change = delete(index, length);
      length = 0;
    }

    final formatChange =
        _heuristics.applyFormatRules(this, index, length, attribute);
    if (formatChange.isNotEmpty) {
      compose(formatChange, ChangeSource.local);
      change = change.compose(formatChange);
    }

    return change;
  }

  /// Returns style of specified text range.
  ///
  /// Only attributes applied to all characters within this range are
  /// included in the result. Inline and block level attributes are
  /// handled separately, e.g.:
  ///
  /// - block attribute X is included in the result only if it exists for
  ///   every line within this range (partially included lines are counted).
  /// - inline attribute X is included in the result only if it exists
  ///   for every character within this range (line-break characters excluded).
  NotusStyle collectStyle(int index, int length) {
    var result = lookupLine(index);
    LineNode line = result.node;
    return line.collectStyle(result.offset, length);
  }

  /// Returns [LineNode] located at specified character [offset].
  LookupResult lookupLine(int offset) {
    // TODO: prevent user from moving caret after last line-break.
    var result = _root.lookup(offset, inclusive: true);
    if (result.node is LineNode) return result;
    BlockNode block = result.node;
    return block.lookup(result.offset, inclusive: true);
  }

  /// Composes [change] into this document.
  ///
  /// Use this method with caution as it does not apply heuristic rules to the
  /// [change].
  ///
  /// It is callers responsibility to ensure that the [change] conforms to
  /// the document model semantics and can be composed with the current state
  /// of this document.
  ///
  /// In case the [change] is invalid, behavior of this method is unspecified.
  void compose(Delta change, ChangeSource source) {
    _checkMutable();
    change.trim();
    assert(change.isNotEmpty);

    var offset = 0;
    final before = toDelta();
    for (final op in change.toList()) {
      final attributes =
          op.attributes != null ? NotusStyle.fromJson(op.attributes) : null;
      if (op.isInsert) {
        _root.insert(offset, op.data, attributes);
      } else if (op.isDelete) {
        _root.delete(offset, op.length);
      } else if (op.attributes != null) {
        _root.retain(offset, op.length, attributes);
      }
      if (!op.isDelete) offset += op.length;
    }
    _delta = _delta.compose(change);

    if (_delta != _root.toDelta()) {
      throw StateError('Compose produced inconsistent results. '
          'This is likely due to a bug in the library. Tried to compose change $change from $source.');
    }
    _controller.add(NotusChange(before, change, source));
  }

  //
  // Overridden members
  //
  @override
  String toString() => _root.toString();

  //
  // Private members
  //

  void _checkMutable() {
    assert(!_controller.isClosed,
        'Cannot modify Notus document after it was closed.');
  }

  String _sanitizeString(String value) {
    if (value.contains(EmbedNode.kPlainTextPlaceholder)) {
      return value.replaceAll(EmbedNode.kPlainTextPlaceholder, '');
    } else {
      return value;
    }
  }

  /// Loads [document] delta into this document.
  void _loadDocument(Delta doc) {
    assert(doc.last.data.endsWith('\n'),
        'Invalid document delta. Document delta must always end with a line-break.');
    var offset = 0;
    for (final op in doc.toList()) {
      final style =
          op.attributes != null ? NotusStyle.fromJson(op.attributes) : null;
      if (op.isInsert) {
        _root.insert(offset, op.data, style);
      } else {
        throw ArgumentError.value(doc,
            'Document Delta can only contain insert operations but ${op.key} found.');
      }
      offset += op.length;
    }
    // Must remove last line if it's empty and with no styles.
    // TODO: find a way for DocumentRoot to not create extra line when composing initial delta.
    final node = _root.last;
    if (node is LineNode &&
        node.parent is! BlockNode &&
        node.style.isEmpty &&
        _root.childCount > 1) {
      _root.remove(node);
    }
  }
}
