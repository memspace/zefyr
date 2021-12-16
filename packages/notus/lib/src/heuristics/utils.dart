import 'dart:math' as math;

import 'package:quill_delta/quill_delta.dart';

/// Skips to the beginning of line containing position at specified [length]
/// and returns contents of the line skipped so far.
List<Operation> skipToLineAt(DeltaIterator iter, int length) {
  if (length == 0) {
    return List.empty(growable: false);
  }

  final prefix = <Operation>[];

  var skipped = 0;
  while (skipped < length && iter.hasNext) {
    final opLength = iter.peekLength();
    final skip = math.min(length - skipped, opLength);
    final op = iter.next(skip);
    if (op.data is! String) {
      prefix.add(op);
    } else {
      var text = op.data as String;
      var pos = text.lastIndexOf('\n');
      if (pos == -1) {
        prefix.add(op);
      } else {
        prefix.clear();
        prefix.add(Operation.insert(text.substring(pos + 1), op.attributes));
      }
    }
    skipped += op.length;
  }
  return prefix;
}
