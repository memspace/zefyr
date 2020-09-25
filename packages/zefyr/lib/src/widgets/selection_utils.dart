import 'package:flutter/rendering.dart';

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
TextSelection selectionRestrict(int base, int extent, TextSelection selection) {
  if (!selectionIntersectsWith(base, extent, selection)) {
    return null;
  }

  final newBase =
      _selectionPointRestrict(base, extent, selection.baseOffset) - base;
  final newExtent =
      _selectionPointRestrict(base, extent, selection.extentOffset) - base;

  return selection.copyWith(baseOffset: newBase, extentOffset: newExtent);
}
