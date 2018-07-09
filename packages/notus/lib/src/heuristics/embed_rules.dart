// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';

/// A heuristic rule for embed operations.
abstract class EmbedRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const EmbedRule();

  /// Applies heuristic rule to an embed operation on a [document] and returns
  /// resulting [Delta].
  Delta apply(Delta document, int index, EmbedAttribute embed);
}

/// Handles all operations which manipulate embeds.
class FormatEmbedsRule extends EmbedRule {
  const FormatEmbedsRule();

  @override
  Delta apply(Delta document, int index, EmbedAttribute embed) {
    final iter = new DeltaIterator(document);
    final previous = iter.skip(index);

    final target = iter.next();
    Delta result = new Delta()..retain(index);
    if (target.length == 1 && target.data == EmbedNode.kPlainTextPlaceholder) {
      assert(() {
        final style = NotusStyle.fromJson(target.attributes);
        return style.single.key == NotusAttribute.embed.key;
      }());

      // There is already embed here, simply update its style.
      return result..retain(1, embed.toJson());
    } else {
      // Target is not an embed, need to insert.
      // Embeds can be inserted only into an empty line.

      // Check if [index] is on an empty line already.
      final isNewlineBefore = previous == null || previous.data.endsWith('\n');
      final isNewlineAfter = target.data.startsWith('\n');
      final isOnEmptyLine = isNewlineBefore && isNewlineAfter;
      if (isOnEmptyLine) {
        return result..insert(EmbedNode.kPlainTextPlaceholder, embed.toJson());
      }
      // We are on a non-empty line, split it (preserving style if needed)
      // and insert our embed.
      final lineStyle = _getLineStyle(iter, target);
      if (!isNewlineBefore) {
        result..insert('\n', lineStyle);
      }
      result..insert(EmbedNode.kPlainTextPlaceholder, embed.toJson());
      if (!isNewlineAfter) {
        result..insert('\n');
      }
      return result;
    }
//
//    if (embed == NotusAttribute.embed.unset) {
//      // Convert into a delete operation.
//      return result..delete(1);
//    } else {
//      return result..retain(1, embed.toJson());
//    }
  }

  Map<String, dynamic> _getLineStyle(
      DeltaIterator iterator, Operation current) {
    if (current.data.indexOf('\n') >= 0) {
      return current.attributes;
    }
    // Continue looking for line-break.
    Map<String, dynamic> attributes;
    while (iterator.hasNext) {
      final op = iterator.next();
      int lf = op.data.indexOf('\n');
      if (lf >= 0) {
        attributes = op.attributes;
        break;
      }
    }
    return attributes;
  }
}
