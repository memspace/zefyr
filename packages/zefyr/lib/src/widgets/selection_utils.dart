import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

/// Returns `true` if `node` intersects with `selection`.
///
/// The `fromParent` parameter controls whether `selection` is relative to the
/// entire document or to the direct parent of the `node`.
bool intersectsWithSelection(Node node, TextSelection selection,
    {bool fromParent = false}) {
  final base = fromParent ? node.offset : node.documentOffset;
  final extent = base + node.length - 1;
  return base <= selection.end && selection.start <= extent;
}

/// Returns part of `selection` contained by specified `node`.
///
/// The `fromParent` parameter controls whether `selection` is relative to the
/// entire document or to the direct parent of the `node`.
TextSelection localSelection(Node node, TextSelection selection,
    {bool fromParent = false}) {
  assert(intersectsWithSelection(node, selection, fromParent: fromParent));

  final offset = fromParent ? node.offset : node.documentOffset;
  final base = math.max(selection.start - offset, 0);
  final extent = math.min(selection.end - offset, node.length - 1);
  return selection.copyWith(baseOffset: base, extentOffset: extent);
}

// Returns true if the selection intersects with the range between base and extent
bool selectionIntersectsWith(int base, int extent, TextSelection selection) {
  return base <= selection.end && selection.start <= extent;
}

// Returns a value between base and extent no matter what!
int _selectionPointRestrict(int base, int extent, int point) {
  if (point < base) return base;
  if (point > extent) return extent;
  return point;
}

// Returns a selection that is trimmed if necessary to be between base and extent
TextSelection? selectionRestrict(
    int base, int extent, TextSelection selection) {
  if (!selectionIntersectsWith(base, extent, selection)) {
    return null;
  }

  final newBase =
      _selectionPointRestrict(base, extent, selection.baseOffset) - base;
  final newExtent =
      _selectionPointRestrict(base, extent, selection.extentOffset) - base;

  return selection.copyWith(baseOffset: newBase, extentOffset: newExtent);
}
