// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:collection';

import 'package:quill_delta/quill_delta.dart';

import 'attributes.dart';
import 'line.dart';

/// An abstract node in a document tree.
///
/// Represents a segment of a Notus document with specified [offset]
/// and [length].
///
/// The [offset] property is relative to [parent]. See also [documentOffset]
/// which provides absolute offset of this node within the document.
///
/// The current parent node is exposed by the [parent] property. A node is
/// considered [mounted] when the [parent] property is not `null`.
abstract class Node extends LinkedListEntry<Node> {
  /// Current parent of this node. May be null if this node is not mounted.
  ContainerNode? get parent => _parent;
  ContainerNode? _parent;

  /// Returns `true` if this node is the first node in the [parent] list.
  bool get isFirst => list!.first == this;

  /// Returns `true` if this node is the last node in the [parent] list.
  bool get isLast => list!.last == this;

  /// Length of this node in characters.
  int get length;

  /// Returns `true` if this node is currently mounted, e.g. [parent] is not
  /// `null`.
  bool get mounted => _parent != null;

  /// Offset in characters of this node relative to [parent] node.
  ///
  /// To get offset of this node in the document see [documentOffset].
  int get offset {
    if (isFirst) return 0;
    var offset = 0;
    var node = this;
    do {
      node = node.previous!;
      offset += node.length;
    } while (!node.isFirst);
    return offset;
  }

  /// Offset in characters of this node in the document.
  int get documentOffset {
    final parentOffset = (_parent is! RootNode) ? _parent!.documentOffset : 0;
    return parentOffset + offset;
  }

  /// Returns `true` if this node contains character at specified [offset] in
  /// the document.
  bool containsOffset(int offset) {
    final o = documentOffset;
    return o <= offset && offset < o + length;
  }

  /// Optimize this node within [parent].
  ///
  /// Subclasses should override this method to perform necessary optimizations.
  void optimize();

  /// Returns [Delta] representation of this node.
  Delta toDelta();

  /// Returns plain-text representation of this node.
  String toPlainText();

  /// Insert [data] at specified character [index] with style [style].
  void insert(int index, Object data, NotusStyle? style);

  /// Format [length] characters of this node starting from [index] with
  /// specified style [style].
  void retain(int index, int length, NotusStyle? style);

  /// Delete [length] characters of this node starting from [index].
  void delete(int index, int length);

  @override
  void insertBefore(Node entry) {
    assert(entry._parent == null && _parent != null);
    entry._parent = _parent;
    super.insertBefore(entry);
  }

  @override
  void insertAfter(Node entry) {
    assert(entry._parent == null && _parent != null);
    entry._parent = _parent;
    super.insertAfter(entry);
  }

  @override
  void unlink() {
    assert(_parent != null);
    _parent = null;
    super.unlink();
  }
}

/// Result of a child lookup in a [ContainerNode].
class LookupResult {
  /// The child node if found, otherwise `null`.
  final Node? node;

  /// Starting offset within the child [node] which points at the same
  /// character in the document as the original offset passed to
  /// [ContainerNode.lookup] method.
  final int offset;

  LookupResult(this.node, this.offset);

  /// Returns `true` if there is no child node found, e.g. [node] is `null`.
  bool get isEmpty => node == null;

  /// Returns `true` [node] is not `null`.
  bool get isNotEmpty => node != null;
}

/// Container node can accommodate other nodes.
///
/// Delegates insert, retain and delete operations to children nodes. For each
/// operation container looks for a child at specified index position and
/// forwards operation to that child.
///
/// Most of the operation handling logic is implemented by [LineNode] and
/// [TextNode].
abstract class ContainerNode<T extends Node> extends Node {
  final LinkedList<Node> _children = LinkedList<Node>();

  /// List of children.
  LinkedList<Node> get children => _children;

  /// Returns total number of child nodes in this container.
  ///
  /// To get text length of this container see [length].
  int get childCount => _children.length;

  /// Returns the first child [Node].
  Node get first => _children.first;

  /// Returns the last child [Node].
  Node get last => _children.last;

  /// Returns an instance of default child for this container node.
  ///
  /// Always returns fresh instance.
  T get defaultChild;

  /// Returns `true` if this container has no child nodes.
  bool get isEmpty => _children.isEmpty;

  /// Returns `true` if this container has at least 1 child.
  bool get isNotEmpty => _children.isNotEmpty;

  /// Adds [node] to the end of this container children list.
  void add(T node) {
    assert(node._parent == null);
    node._parent = this;
    _children.add(node);
  }

  /// Adds [node] to the beginning of this container children list.
  void addFirst(T node) {
    assert(node._parent == null);
    node._parent = this;
    _children.addFirst(node);
  }

  /// Removes [node] from this container.
  void remove(T node) {
    assert(node._parent == this);
    node._parent = null;
    _children.remove(node);
  }

  /// Moves children of this node to [newParent].
  void moveChildren(ContainerNode newParent) {
    if (isEmpty) return;
    var toBeOptimized = newParent.isEmpty ? null : newParent.last;
    while (isNotEmpty) {
      var child = first;
      child.unlink();
      newParent.add(child);
    }

    /// In case [newParent] already had children we need to make sure
    /// combined list is optimized.
    if (toBeOptimized != null) toBeOptimized.optimize();
  }

  /// Looks up a child [Node] at specified character [offset] in this container.
  ///
  /// Returns [LookupResult]. The result may contain found node or `null` if
  /// no node is found at specified offset.
  ///
  /// [LookupResult.offset] is set to relative offset within returned child node
  /// which points at the same character position in the document as the
  /// original [offset].
  LookupResult lookup(int offset, {bool inclusive = false}) {
    assert(offset >= 0 && offset <= length);

    for (final node in children) {
      final length = node.length;
      if (offset < length || (inclusive && offset == length && (node.isLast))) {
        return LookupResult(node, offset);
      }
      offset -= length;
    }
    return LookupResult(null, 0);
  }

  //
  // Overridden members
  //

  @override
  String toPlainText() => children.map((child) => child.toPlainText()).join();

  /// Content length of this node's children. To get number of children in this
  /// node use [childCount].
  @override
  int get length => _children.fold(0, (current, node) => current + node.length);

  @override
  void insert(int index, Object data, NotusStyle? style) {
    assert(index == 0 || (index > 0 && index < length));

    if (isEmpty) {
      assert(index == 0);
      final node = defaultChild;
      add(node);
      node.insert(index, data, style);
    } else {
      final result = lookup(index);
      result.node!.insert(result.offset, data, style);
    }
  }

  @override
  void retain(int index, int length, NotusStyle? attributes) {
    assert(isNotEmpty);
    final res = lookup(index);
    res.node!.retain(res.offset, length, attributes);
  }

  @override
  void delete(int index, int length) {
    assert(isNotEmpty);
    final res = lookup(index);
    res.node!.delete(res.offset, length);
  }

  @override
  String toString() => _children.join('\n');
}

/// An interface for document nodes with style.
abstract class StyledNode implements Node {
  /// Style of this node.
  NotusStyle get style;
}

/// Mixin used by nodes that wish to implement [StyledNode] interface.
abstract class StyledNodeMixin implements StyledNode {
  @override
  NotusStyle get style => _style;
  NotusStyle _style = NotusStyle();

  /// Applies style [attribute] to this node.
  void applyAttribute(NotusAttribute attribute) {
    _style = _style.merge(attribute);
  }

  /// Applies new style [value] to this node. Provided [value] is merged
  /// into current style.
  void applyStyle(NotusStyle value) {
    _style = _style.mergeAll(value);
  }

  /// Clears style of this node.
  void clearStyle() {
    _style = NotusStyle();
  }
}

/// Root node of document tree.
class RootNode extends ContainerNode<ContainerNode<Node>> {
  @override
  ContainerNode<Node> get defaultChild => LineNode();

  @override
  void optimize() {/* no-op */}

  @override
  Delta toDelta() => children
      .map((child) => child.toDelta())
      .fold(Delta(), (a, b) => a.concat(b));
}
