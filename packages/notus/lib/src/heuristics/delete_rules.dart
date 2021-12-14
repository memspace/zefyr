// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quill_delta/quill_delta.dart';

/// A heuristic rule for delete operations.
abstract class DeleteRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const DeleteRule();

  /// Applies heuristic rule to a delete operation on a [document] and returns
  /// resulting [Delta].
  Delta? apply(Delta document, int index, int length);
}

class EnsureLastLineBreakDeleteRule extends DeleteRule {
  @override
  Delta? apply(Delta document, int index, int length) {
    final iter = DeltaIterator(document);
    iter.skip(index + length);

    return Delta()
      ..retain(index)
      ..delete(iter.hasNext ? length : length - 1);
  }
}

/// Fallback rule for delete operations which simply deletes specified text
/// range without any special handling.
class CatchAllDeleteRule extends DeleteRule {
  const CatchAllDeleteRule();

  @override
  Delta? apply(Delta document, int index, int length) {
    final iter = DeltaIterator(document);
    iter.skip(index + length);

    return Delta()
      ..retain(index)
      ..delete(iter.hasNext ? length : length - 1);
  }
}

/// Preserves line format when user deletes the line's newline character
/// effectively merging it with the next line.
///
/// This rule makes sure to apply all style attributes of deleted newline
/// to the next available newline, which may reset any style attributes
/// already present there.
class PreserveLineStyleOnMergeRule extends DeleteRule {
  const PreserveLineStyleOnMergeRule();

  @override
  Delta? apply(Delta document, int index, int length) {
    final iter = DeltaIterator(document);
    iter.skip(index);
    final target = iter.next(1);
    if (target.data != '\n') return null;

    iter.skip(length - 1);

    if (!iter.hasNext) {
      // User attempts to delete the last newline character, prevent it.
      return Delta()
        ..retain(index)
        ..delete(length - 1);
    }

    final result = Delta()
      ..retain(index)
      ..delete(length);

    // Look for next newline to apply the attributes
    while (iter.hasNext) {
      final op = iter.next();
      final opText = op.data is String ? op.data as String : '';
      final lf = opText.indexOf('\n');
      if (lf == -1) {
        result.retain(op.length);
        continue;
      }
      var attributes = _unsetAttributes(op.attributes);
      if (target.isNotPlain) {
        attributes ??= <String, dynamic>{};
        attributes.addAll(target.attributes!);
      }
      result..retain(lf)..retain(1, attributes);
      break;
    }
    return result;
  }

  Map<String, dynamic>? _unsetAttributes(Map<String, dynamic>? attributes) {
    if (attributes == null) return null;
    return attributes.map<String, dynamic>(
        (String key, dynamic value) => MapEntry<String, dynamic>(key, null));
  }
}

/// Prevents user from merging a line containing an embed with other lines.
class EnsureEmbedLineRule extends DeleteRule {
  const EnsureEmbedLineRule();

  @override
  Delta? apply(Delta document, int index, int length) {
    final iter = DeltaIterator(document);

    // First, check if newline deleted after an embed.
    var op = iter.skip(index);
    var indexDelta = 0;
    var lengthDelta = 0;
    var remaining = length;
    var foundEmbed = false;
    var hasLineBreakBefore = false;
    if (op != null && op.data is! String) {
      foundEmbed = true;
      var candidate = iter.next(1);
      remaining--;
      if (candidate.data == '\n') {
        indexDelta += 1;
        lengthDelta -= 1;

        /// Check if it's an empty line
        candidate = iter.next(1);
        remaining--;
        if (candidate.data == '\n') {
          // Allow deleting empty line after an embed.
          lengthDelta += 1;
        }
      }
    } else {
      // If op is `null` it's beginning of the doc, e.g. implicit line break.
      final opText = op?.data as String?;
      hasLineBreakBefore = op == null || opText!.endsWith('\n');
    }

    // Second, check if newline deleted before an embed.
    op = iter.skip(remaining);
    final opText = op?.data is String ? op!.data as String : '';
    if (op != null && opText.endsWith('\n')) {
      final candidate = iter.next(1);
      // If there is a newline before deleted range we allow the operation
      // since it results in a correctly formatted line with a single embed in
      // it.
      if (candidate.data is! String && !hasLineBreakBefore) {
        foundEmbed = true;
        lengthDelta -= 1;
      }
    }

    if (foundEmbed) {
      return Delta()
        ..retain(index + indexDelta)
        ..delete(length + lengthDelta);
    }

    return null;
  }
}
