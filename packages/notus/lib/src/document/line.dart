// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:notus/src/document/embeds.dart';
import 'package:quill_delta/quill_delta.dart';

import 'attributes.dart';
import 'block.dart';
import 'leaf.dart';
import 'node.dart';

/// A line of rich text in a Notus document.
///
/// LineNode serves as a container for [LeafNode]s, like [TextNode] and
/// [EmbedNode].
///
/// When a line contains an embed, it fully occupies the line, no other embeds
/// or text nodes are allowed.
class LineNode extends ContainerNode<LeafNode>
    with StyledNodeMixin
    implements StyledNode {
  /// Returns `true` if this line contains an embedded object.
  bool get hasEmbed {
    if (childCount == 1) {
      return children.single is EmbedNode;
    }
    assert(children.every((child) => child is TextNode));
    return false;
  }

  /// Returns next [LineNode] or `null` if this is the last line in the document.
  LineNode? get nextLine {
    if (isLast) {
      if (parent is BlockNode) {
        if (parent!.isLast) return null;
        var line = (parent!.next is BlockNode)
            ? (parent!.next as BlockNode).first as LineNode
            : parent!.next as LineNode;
        return line;
      }
      return null;
    }
    final line =
        (next is BlockNode) ? (next as BlockNode).first : next as LineNode?;
    return line;
  }

  /// Creates new empty [LineNode] with the same style.
  ///
  /// Returned line node is detached.
  LineNode clone() {
    final node = LineNode();
    node.applyStyle(style);
    return node;
  }

  /// Splits this line into two at specified character [index].
  ///
  /// This is an equivalent of inserting a line-break character at [index].
  LineNode splitAt(int index) {
    assert(index == 0 || (index > 0 && index < length),
        'Index is out of bounds. Index: $index. Actual node length: ${length}.');

    final line = clone();
    insertAfter(line);
    if (index == length - 1) return line;

    final split = lookup(index);
    final splitNode = split.node;
    assert(splitNode != null, 'No node found, please file an issue');
    while (!splitNode!.isLast) {
      // above check implied there is a last
      final child = last!;
      child.unlink();
      line.addFirst(child);
    }
    // Implies LookupResult.node is necessarily a LeafNode
    final child = splitNode as LeafNode;
    final cutResult = child.cutAt(split.offset);
    if (cutResult == null) return line;
    line.addFirst(cutResult);
    return line;
  }

  /// Unwraps this line from it's parent [BlockNode].
  ///
  /// This method asserts if current [parent] of this line is not a [BlockNode].
  void unwrap() {
    assert(parent is BlockNode);
    var block = parent as BlockNode;
    block.unwrapLine(this);
  }

  /// Wraps this line with new parent [block].
  ///
  /// This line can not be in a [BlockNode] when this method is called.
  void wrap(BlockNode block) {
    assert(parent is! BlockNode);
    insertAfter(block);
    unlink();
    block.add(this);
  }

  /// Returns style for specified text range.
  ///
  /// Only attributes applied to all characters within this range are
  /// included in the result. Inline and line level attributes are
  /// handled separately, e.g.:
  ///
  /// - line attribute X is included in the result only if it exists for
  ///   every line within this range (partially included lines are counted).
  /// - inline attribute X is included in the result only if it exists
  ///   for every character within this range (line-break characters excluded).
  NotusStyle collectStyle(int offset, int length) {
    final local = math.min(this.length - offset, length);

    var result = NotusStyle();
    final excluded = <NotusAttribute>{};

    void _handle(NotusStyle style) {
      if (result.isEmpty) {
        excluded.addAll(style.values);
      } else {
        for (var attr in result.values) {
          if (!style.contains(attr)) {
            excluded.add(attr);
          }
        }
      }
      final remaining = style.removeAll(excluded);
      result = result.removeAll(excluded);
      result = result.mergeAll(remaining);
    }

    final data = lookup(offset, inclusive: true);
    var node = data.node as LeafNode?;
    if (node != null) {
      result = result.mergeAll(node.style);
      var pos = node.length - data.offset;
      while (!node!.isLast && pos < local) {
        node = node.next as LeafNode;
        _handle(node.style);
        pos += node.length;
      }
    }

    result = result.mergeAll(style);
    if (parent is BlockNode) {
      final block = parent as BlockNode;
      result = result.mergeAll(block.style);
    }

    final remaining = length - local;
    if (remaining > 0) {
      assert(nextLine != null);
      final rest = nextLine!.collectStyle(0, remaining);
      _handle(rest);
    }

    return result;
  }

  @override
  LeafNode get defaultChild => TextNode();

  // TODO: should be able to cache length and invalidate on any child-related operation
  @override
  int get length => super.length + 1;

  @override
  Delta toDelta() {
    final delta = children
        .map<Delta>((child) => child.toDelta())
        .fold<Delta>(Delta(), (a, b) => a.concat(b));
    var attributes = style;
    if (parent is BlockNode) {
      final block = parent as BlockNode;
      attributes = attributes.mergeAll(block.style);
    }
    delta.insert('\n', attributes.toJson());
    return delta;
  }

  @override
  String toPlainText() => super.toPlainText() + '\n';

  @override
  String toString() {
    final body = children.join(' → ');
    final styleString = style.isNotEmpty ? ' $style' : '';
    return '¶ $body ⏎$styleString';
  }

  @override
  void optimize() {
    // No-op, line merging is done in insert/delete operations
  }

  @override
  void insert(int index, Object data, NotusStyle? style) {
    if (data is EmbeddableObject) {
      // We do not check whether this line already has any children here as
      // inserting an embed into a line with other text is acceptable from the
      // Delta format perspective.
      // We rely on heuristic rules to ensure that embeds occupy an entire line.
      _insertSafe(index, data, style);
      return;
    }

    assert(data is String);

    final text = data as String;
    final lf = text.indexOf('\n');
    if (lf == -1) {
      _insertSafe(index, text, style);
      // No need to update line or block format since those attributes can only
      // be attached to `\n` character and we already know it's not present.
      return;
    }

    final substring = text.substring(0, lf);
    _insertSafe(index, substring, style);
    if (substring.isNotEmpty) index += substring.length;

    final nextLine = splitAt(index); // Next line inherits our format.

    // Reset our format and unwrap from a block if needed.
    clearStyle();
    if (parent is BlockNode) unwrap();

    // Now we can apply new format and re-layout.
    _formatAndOptimize(style);

    // Continue with remaining part.
    final remaining = text.substring(lf + 1);
    nextLine.insert(0, remaining, style);
  }

  @override
  void retain(int index, int length, NotusStyle? style) {
    if (style == null) return;
    final thisLength = this.length;

    final local = math.min(thisLength - index, length);
    // If index is at newline character then this is a line/block style update.
    final isLineFormat = (index + local == thisLength) && local == 1;

    if (isLineFormat) {
      assert(
          style.values.every((attr) => attr.scope == NotusAttributeScope.line),
          'It is not allowed to apply inline attributes to line itself.');
      _formatAndOptimize(style);
    } else {
      // Otherwise forward to children as it's an inline format update.
      assert(index + local != thisLength,
          'It is not allowed to apply inline attributes to line itself.');
      assert(style.values
          .every((attr) => attr.scope == NotusAttributeScope.inline));
      super.retain(index, local, style);
    }

    final remaining = length - local;
    if (remaining > 0) {
      assert(nextLine != null);
      nextLine!.retain(0, remaining, style);
    }
  }

  @override
  void delete(int index, int length) {
    final local = math.min(this.length - index, length);
    final isLFDeleted = (index + local == this.length);
    if (isLFDeleted) {
      // Our newline character deleted with all style information.
      clearStyle();
      if (local > 1) {
        // Exclude newline character from delete range for children.
        super.delete(index, local - 1);
      }
    } else {
      super.delete(index, local);
    }

    final remaining = length - local;
    if (remaining > 0) {
      assert(nextLine != null);
      nextLine!.delete(0, remaining);
    }
    if (isLFDeleted && isNotEmpty) {
      // Since we lost our line-break and still have child text nodes those must
      // migrate to the next line.

      // nextLine might have been unmounted since last assert so we need to
      // check again we still have a line after us.
      assert(nextLine != null);

      // Move remaining children in this line to the next line so that all
      // attributes of nextLine are preserved.
      nextLine!.moveChildren(this); // TODO: avoid double move
      moveChildren(nextLine!);
    }

    if (isLFDeleted) {
      // Now we can remove this line.
      final block = parent!; // remember reference before un-linking.
      unlink();
      block.optimize();
    }
  }

  /// Formats this line and optimizes layout afterwards.
  void _formatAndOptimize(NotusStyle? newStyle) {
    if (newStyle == null || newStyle.isEmpty) return;

    applyStyle(newStyle);
    if (!newStyle.contains(NotusAttribute.block)) {
      return;
    } // no block-level changes

    final blockStyle = newStyle.get(NotusAttribute.block)!;
    if (parent is BlockNode) {
      final parentStyle = (parent as BlockNode).style.get(NotusAttribute.block);
      if (blockStyle == NotusAttribute.block.unset) {
        unwrap();
      } else if (blockStyle != parentStyle) {
        unwrap();
        final block = BlockNode();
        block.applyAttribute(blockStyle);
        wrap(block);
        block.optimize();
      } // else the same style, no-op.
    } else if (blockStyle != NotusAttribute.block.unset) {
      // Only wrap with a new block if this is not an unset
      final block = BlockNode();
      block.applyAttribute(blockStyle);
      wrap(block);
      block.optimize();
    }
  }

  void _insertSafe(int index, Object data, NotusStyle? style) {
    assert(index == 0 || (index > 0 && index < length));

    if (data is String) {
      assert(data.contains('\n') == false);
      if (data.isEmpty) return;
    }

    if (isEmpty) {
      final child = LeafNode(data);
      add(child);
      child.formatAndOptimize(style);
    } else {
      final result = lookup(index, inclusive: true);
      result.node?.insert(result.offset, data, style);
    }
  }
}
