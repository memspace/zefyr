// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:quill_delta/quill_delta.dart';

import 'attributes.dart';
import 'line.dart';
import 'node.dart';

/// A leaf node in Notus document tree.
abstract class LeafNode extends Node
    with StyledNodeMixin
    implements StyledNode {
  /// Creates a new [LeafNode] with specified [value].
  LeafNode._([String value = ''])
      : assert(value != null && !value.contains('\n')),
        _value = value;

  factory LeafNode([String value = '']) {
    LeafNode node;
    if (value == kZeroWidthSpace) {
      // Zero-width space is reserved for embed nodes.
      node = EmbedNode();
    } else {
      assert(
          !value.contains(kZeroWidthSpace),
          'Zero-width space is reserved for embed leaf nodes and cannot be used '
          'inside regular text nodes.');
      node = TextNode(value);
    }
    return node;
  }

  /// Plain-text value of this node.
  String get value => _value;
  String _value;

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
  LeafNode splitAt(int index) {
    assert(index >= 0 && index <= length);
    if (index == 0) return this;
    if (index == length && isLast) return null;
    if (index == length && !isLast) return next as LeafNode;

    final text = _value;
    _value = text.substring(0, index);
    final split = LeafNode(text.substring(index));
    split.applyStyle(style);
    insertAfter(split);
    return split;
  }

  /// Cuts a leaf node from [index] to the end of this node and returns new node
  /// in detached state (e.g. [mounted] returns `false`).
  ///
  /// Splitting logic is identical to one described in [splitAt], meaning this
  /// method may return `null`.
  LeafNode cutAt(int index) {
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
  /// instance. Note that returned node may still be the same as this node
  /// if provided [index] is `0`.
  LeafNode isolate(int index, int length) {
    assert(
        index >= 0 && index < this.length && (index + length <= this.length),
        'Index or length is out of bounds. Index: $index, length: $length. '
        'Actual node length: ${this.length}.');
    // Since `index < this.length` (guarded by assert) below line
    // always returns a new node.
    final target = splitAt(index);
    target.splitAt(length);
    return target;
  }

  /// Formats this node and optimizes it with adjacent leaf nodes if needed.
  void formatAndOptimize(NotusStyle style) {
    if (style != null && style.isNotEmpty) {
      applyStyle(style);
    }
    optimize();
  }

  @override
  void applyStyle(NotusStyle value) {
    assert(value != null && (value.isInline || value.isEmpty),
        'Style cannot be applied to this leaf node: $value');
    assert(() {
      if (value.contains(NotusAttribute.embed)) {
        if (value.get(NotusAttribute.embed) == NotusAttribute.embed.unset) {
          throw 'Unsetting embed attribute is not allowed. '
              'This operation means that the embed itself must be deleted from the document. '
              'Make sure there is FormatEmbedsRule in your heuristics registry, '
              'which is responsible for handling this scenario.';
        }
        if (this is! EmbedNode) {
          throw 'Embed style can only be applied to an EmbedNode.';
        }
      }
      return true;
    }());

    super.applyStyle(value);
  }

  @override
  LineNode get parent => super.parent as LineNode;

  @override
  int get length => _value.length;

  @override
  Delta toDelta() {
    return Delta()..insert(_value, style.toJson());
  }

  @override
  String toPlainText() => _value;

  @override
  void insert(int index, String value, NotusStyle style) {
    assert(index >= 0 && (index <= length), 'Index: $index, Length: $length.');
    assert(value.isNotEmpty);
    final node = LeafNode(value);
    if (index == length) {
      insertAfter(node);
    } else {
      splitAt(index).insertBefore(node);
    }
    node.formatAndOptimize(style);
  }

  @override
  void retain(int index, int length, NotusStyle style) {
    if (style == null) return;

    final local = math.min(this.length - index, length);
    final node = isolate(index, local);

    final remaining = length - local;
    if (remaining > 0) {
      assert(node.next != null);
      node.next.retain(0, remaining, style);
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
      actualNext.delete(0, remaining);
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
    var node = this;
    if (!node.isFirst) {
      LeafNode mergeWith = node.previous;
      if (mergeWith.style == node.style) {
        mergeWith._value += node.value;
        node.unlink();
        node = mergeWith;
      }
    }
    if (!node.isLast) {
      LeafNode mergeWith = node.next;
      if (mergeWith.style == node.style) {
        node._value += mergeWith._value;
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
///   * [LineNode], a node representing a line of text.
///   * [BlockNode], a node representing a group of lines.
class TextNode extends LeafNode {
  TextNode([String content = '']) : super._(content);
}

final kZeroWidthSpace = String.fromCharCode(0x200b);

/// An embed node inside of a line in a Notus document.
///
/// Embed node is a leaf node similar to [TextNode]. It represents an
/// arbitrary piece of non-text content embedded into a document, such as,
/// image, horizontal rule, video, or any other object with defined structure,
/// like tweet, for instance.
///
/// Embed node's length is always `1` character and it is represented with
/// zero-width space in the document text.
///
/// Any inline style can be applied to an embed, however this does not
/// necessarily mean the embed will look according to that style. For instance,
/// applying "bold" style to an image gives no effect, while adding a "link" to
/// an image actually makes the image react to user's action.
class EmbedNode extends LeafNode {
  static final kPlainTextPlaceholder = String.fromCharCode(0x200b);

  EmbedNode() : super._(kPlainTextPlaceholder);
}
