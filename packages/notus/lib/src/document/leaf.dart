// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:quill_delta/quill_delta.dart';

import 'attributes.dart';
import 'embeds.dart';
import 'line.dart';
import 'node.dart';

/// A leaf node in Notus document tree.
abstract class LeafNode extends Node
    with StyledNodeMixin
    implements StyledNode {
  /// Creates a new [LeafNode] with specified [data].
  LeafNode._(Object data) : _value = data;

  factory LeafNode(Object data) {
    LeafNode node;
    if (data is EmbeddableObject) {
      node = EmbedNode(data);
    } else {
      final text = data as String;
      assert(text.isNotEmpty);
      node = TextNode(text);
    }
    return node;
  }

  /// Contents of this node, either a String if this is a [TextNode] or an
  /// [EmbeddableObject] if this is an [EmbedNode].
  Object get value => _value;
  Object _value;

  /// Splits this leaf node at [index] and returns new node.
  ///
  /// If this is the last node in its list and [index] equals this node's
  /// length then this method returns `null` as there is nothing left to split.
  /// If there is another leaf node after this one and [index] equals this
  /// node's length then the next leaf node is returned.
  ///
  /// If [index] equals to `0` then this node itself is returned unchanged.
  ///
  /// In case a new node is actually split from this one, it inherits this
  /// node's style.
  LeafNode? splitAt(int index) {
    assert(index >= 0 && index <= length);
    if (index == 0) return this;
    if (index == length && isLast) return null;
    if (index == length && !isLast) return next as LeafNode;

    if (this is TextNode) {
      final text = _value as String;
      _value = text.substring(0, index);
      final split = LeafNode(text.substring(index));
      split.applyStyle(style);
      insertAfter(split);
      return split;
    } else {
      // This is an EmbedNode which cannot be split and has length of 1.
      // Technically this branch is unreachable because we've already checked
      // edge scenarios when index is either at 0 (start) or 1 (end) of this
      // node above, e.g. for embed nodes:
      //   * calling splitAt(0) returns the embed node itself;
      //   * calling splitAt(1) depends on whether this node is the last one:
      //     - if last then `null` is returned as there is nothing to split
      //     - otherwise next node is returned
      throw StateError('Unreachable.');
    }
  }

  /// Cuts a leaf node from [index] to the end of this node and returns new node
  /// in detached state (e.g. [mounted] returns `false`).
  ///
  /// Splitting logic is identical to one described in [splitAt], meaning this
  /// method may return `null`.
  LeafNode? cutAt(int index) {
    assert(index >= 0 && index <= length);
    final cut = splitAt(index);
    cut?.unlink();
    return cut;
  }

  /// Isolates a new leaf node starting at [index] with specified [length].
  ///
  /// Splitting logic is identical to one described in [splitAt], with one
  /// exception that it is required for [index] to always be less than this
  /// node's length. As a result this method always returns a [LeafNode]
  /// instance. Returned node may still be the same as this node
  /// if provided [index] is `0`.
  LeafNode isolate(int index, int length) {
    assert(
        index >= 0 && index < this.length && (index + length <= this.length),
        'Index or length is out of bounds. Index: $index, length: $length. '
        'Actual node length: ${this.length}.');
    // Since `index < this.length` (guarded by assert) below line
    // always returns a new node.
    final target = splitAt(index)!;
    target.splitAt(length);
    return target;
  }

  /// Formats this node and optimizes it with adjacent leaf nodes if needed.
  void formatAndOptimize(NotusStyle? style) {
    if (style != null && style.isNotEmpty) {
      applyStyle(style);
    }
    optimize();
  }

  @override
  void applyStyle(NotusStyle value) {
    assert(value.isInline || value.isEmpty,
        'Style cannot be applied to this leaf node: $value');
    super.applyStyle(value);
  }

  @override
  LineNode get parent => super.parent as LineNode;

  @override
  int get length {
    if (_value is String) {
      return (_value as String).length;
    }
    return 1; // embed objects have length of 1.
  }

  @override
  Delta toDelta() {
    final data = _value is EmbeddableObject
        ? (_value as EmbeddableObject).toJson()
        : _value;
    return Delta()..insert(data, style.toJson());
  }

  @override
  void insert(int index, Object data, NotusStyle? style) {
    assert(index >= 0 && (index <= length),
        'Index out of bounds. Must be between 0 and $length, but got $index.');
    final node = LeafNode(data);
    if (index == length) {
      insertAfter(node);
    } else {
      splitAt(index)!.insertBefore(node);
    }
    node.formatAndOptimize(style);
  }

  @override
  void retain(int index, int length, NotusStyle? style) {
    if (style == null) return;

    final local = math.min(this.length - index, length);
    final node = isolate(index, local);

    final remaining = length - local;
    if (remaining > 0) {
      assert(node.next != null);
      node.next!.retain(0, remaining, style);
    }
    // Optimize at the very end
    node.formatAndOptimize(style);
  }

  @override
  void delete(int index, int length) {
    assert(index < this.length);

    final local = math.min(this.length - index, length);
    final target = isolate(index, local);
    // Memorize siblings before un-linking.
    final needsOptimize = target.previous;
    final actualNext = target.next;
    target.unlink();

    final remaining = length - local;
    if (remaining > 0) {
      assert(actualNext != null);
      actualNext!.delete(0, remaining);
    }

    if (needsOptimize != null) needsOptimize.optimize();
  }

  @override
  String toString() {
    final keys = style.keys.toList(growable: false)..sort();
    final styleKeys = keys.join();
    return '⟨$value⟩$styleKeys';
  }

  /// Optimizes this text node by merging it with adjacent nodes if they share
  /// the same style.
  @override
  void optimize() {
    if (this is EmbedNode) {
      // Embed nodes cannot be merged with text nor other embeds (in fact,
      // there could be no two adjacent embeds on the same line since an
      // embed occupies an entire line).
      return;
    }

    // This is a text node and it can only be merged with other text nodes.

    var node = this as TextNode;
    if (!node.isFirst && node.previous is TextNode) {
      var mergeWith = node.previous as TextNode;
      if (mergeWith.style == node.style) {
        final combinedValue = mergeWith.value + node.value;
        mergeWith._value = combinedValue;
        node.unlink();
        node = mergeWith;
      }
    }
    if (!node.isLast && node.next is TextNode) {
      var mergeWith = node.next as TextNode;
      if (mergeWith.style == node.style) {
        final combinedValue = node.value + mergeWith.value;
        node._value = combinedValue;
        mergeWith.unlink();
      }
    }
  }
}

/// A span of formatted text within a line in a Notus document.
///
/// TextNode is a leaf node of a document tree.
///
/// Parent of a text node is always a [LineNode], and as a consequence text
/// node's [value] cannot contain any line-break characters.
///
/// See also:
///
///   * [EmbedNode], a leaf node representing an embeddable object.
///   * [LineNode], a node representing a line of text.
///   * [BlockNode], a node representing a group of lines.
class TextNode extends LeafNode {
  TextNode([String text = ''])
      : assert(!text.contains('\n')),
        super._(text);

  @override
  String get value => _value as String;

  @override
  String toPlainText() => value;
}

/// An embed node inside of a line in a Notus document.
///
/// Embed node is a leaf node similar to [TextNode]. It represents an
/// arbitrary piece of non-textual content embedded into a document, such as,
/// image, horizontal rule, video, or any other object with defined structure,
/// like a tweet, for instance.
///
/// Embed node's length is always `1` character and it is represented with
/// unicode object replacement character in the document text.
///
/// Any inline style can be applied to an embed, however this does not
/// necessarily mean the embed will look according to that style. For instance,
/// applying "bold" style to an image gives no effect, while adding a "link" to
/// an image actually makes the image react to user's action.
class EmbedNode extends LeafNode {
  static final kObjectReplacementCharacter = '\uFFFC';

  EmbedNode(EmbeddableObject object) : super._(object);

  @override
  EmbeddableObject get value => super.value as EmbeddableObject;

  // Embed nodes are represented as unicode object replacement character in
  // plain text.
  @override
  String toPlainText() => kObjectReplacementCharacter;
}
