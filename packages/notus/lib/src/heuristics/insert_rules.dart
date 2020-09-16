// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';
import 'package:notus/src/document/embeds.dart';
import 'package:quill_delta/quill_delta.dart';

/// A heuristic rule for insert operations.
abstract class InsertRule {
  /// Constant constructor allows subclasses to declare constant constructors.
  const InsertRule();

  /// Applies heuristic rule to an insert operation on a [document] and returns
  /// resulting [Delta].
  Delta apply(Delta document, int index, Object data);
}

/// Fallback rule which simply inserts text as-is without any special handling.
class CatchAllInsertRule extends InsertRule {
  const CatchAllInsertRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    return Delta()
      ..retain(index)
      ..insert(data);
  }
}

/// Preserves line format when user splits the line into two.
///
/// This rule ignores scenarios when the line is split on its edge, meaning
/// a newline is inserted at the beginning or the end of a line.
class PreserveLineStyleOnSplitRule extends InsertRule {
  const PreserveLineStyleOnSplitRule();

  bool isEdgeLineSplit(Operation before, Operation after) {
    if (before == null) return true; // split at the beginning of a doc
    final textBefore = before.data is String ? before.data as String : '';
    final textAfter = after.data is String ? after.data as String : '';
    return textBefore.endsWith('\n') || textAfter.startsWith('\n');
  }

  @override
  Delta apply(Delta document, int index, Object data) {
    if (data is! String) return null;
    final text = data as String;
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    final before = iter.skip(index);
    final after = iter.next();
    if (isEdgeLineSplit(before, after)) return null;

    // This is not an edge line split, meaning that the cursor is somewhere in
    // the middle of the line's text. Which in turn means there is no embeds
    // around the cursor and it is safe to assume we have only text.
    final textAfter = after.data as String;

    final result = Delta()..retain(index);
    if (textAfter.contains('\n')) {
      // It is not allowed to combine line and inline styles in insert
      // operation containing newline together with other characters.
      // The only scenario we get such operation is when the text is plain.
      assert(after.isPlain);
      // No attributes to apply so we simply create a new line.
      result..insert('\n');
      return result;
    }
    // Continue looking for a newline.
    Map<String, dynamic> attributes;
    while (iter.hasNext) {
      final op = iter.next();
      if (op.data is! String) continue; // not interested in embeds.
      final opText = op.data as String;
      final lf = opText.indexOf('\n');
      if (lf != -1) {
        attributes = op.attributes;
        break;
      }
    }

    return result..insert('\n', attributes);
  }
}

/// Resets format for a newly inserted line when insert occurred at the end
/// of a line (right before a newline).
///
/// This handles scenarios when a new line is added when at the end of a
/// heading line. The newly added line should be a regular paragraph.
class ResetLineFormatOnNewLineRule extends InsertRule {
  const ResetLineFormatOnNewLineRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final text = data as String;
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    iter.skip(index);
    final target = iter.next();

    // We have an embed right after us, ignore (embeds handled by a different rule).
    if (target.data is! String) return null;

    final targetText = target.data as String;

    if (targetText.startsWith('\n')) {
      Map<String, dynamic> resetStyle;
      if (target.attributes != null &&
          target.attributes.containsKey(NotusAttribute.heading.key)) {
        resetStyle = NotusAttribute.heading.unset.toJson();
      }
      return Delta()
        ..retain(index)
        ..insert('\n', target.attributes)
        ..retain(1, resetStyle)
        ..trim();
    }
    return null;
  }
}

/// Heuristic rule to exit current block when user inserts two consecutive
/// newlines.
// TODO: update this rule to handle code blocks differently, at least allow 3 consecutive newlines before exiting.
class AutoExitBlockRule extends InsertRule {
  const AutoExitBlockRule();

  bool isEmptyLine(Operation before, Operation after) {
    final textBefore = before?.data is String ? before.data as String : '';
    final textAfter = after.data is String ? after.data as String : '';
    return (before == null || textBefore.endsWith('\n')) &&
        textAfter.startsWith('\n');
  }

  @override
  Delta apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final text = data as String;
    if (text != '\n') return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final isInBlock = target.isNotPlain &&
        target.attributes.containsKey(NotusAttribute.block.key);
    if (isEmptyLine(previous, target) && isInBlock) {
      // We reset block style even if this line is not the last one in it's
      // block which effectively splits the block into two.
      // TODO: For code blocks this should not split the block but allow inserting as many lines as needed.
      var attributes;
      if (target.attributes != null) {
        attributes = target.attributes;
      } else {
        attributes = <String, dynamic>{};
      }
      attributes.addAll(NotusAttribute.block.unset.toJson());
      return Delta()..retain(index)..retain(1, attributes);
    }
    return null;
  }
}

/// Preserves inline styles when user inserts text inside formatted segment.
class PreserveInlineStylesRule extends InsertRule {
  const PreserveInlineStylesRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    // There is no other text around embeds so no inline styles to preserve.
    if (data is! String) return null;

    final text = data as String;

    // This rule is only applicable to characters other than newline.
    if (text.contains('\n')) return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    // If there is a newline in previous chunk, there should be no inline
    // styles. Also if there is no previous operation we are at the beginning
    // of the document so no styles to inherit from.
    if (previous == null) return null;
    final previousText = previous.data is String ? previous.data as String : '';
    if (previousText.contains('\n')) return null;

    final attributes = previous.attributes;
    final hasLink =
        (attributes != null && attributes.containsKey(NotusAttribute.link.key));
    if (!hasLink) {
      return Delta()
        ..retain(index)
        ..insert(text, attributes);
    }
    // Special handling needed for inserts inside fragments with link attribute.
    // Link style should only be preserved if insert occurs inside the fragment.
    // Link style should NOT be preserved on the boundaries.
    var noLinkAttributes = previous.attributes;
    noLinkAttributes.remove(NotusAttribute.link.key);
    final noLinkResult = Delta()
      ..retain(index)
      ..insert(text, noLinkAttributes.isEmpty ? null : noLinkAttributes);
    final next = iter.next();
    if (next == null) {
      // Nothing after us, we are not inside link-styled fragment.
      return noLinkResult;
    }
    final nextAttributes = next.attributes ?? const <String, dynamic>{};
    if (!nextAttributes.containsKey(NotusAttribute.link.key)) {
      // Next fragment is not styled as link.
      return noLinkResult;
    }
    // We must make sure links are identical in previous and next operations.
    if (attributes[NotusAttribute.link.key] ==
        nextAttributes[NotusAttribute.link.key]) {
      return Delta()
        ..retain(index)
        ..insert(text, attributes);
    } else {
      return noLinkResult;
    }
  }
}

/// Applies link format to text segment (which looks like a link) when user
/// inserts space character after it.
class AutoFormatLinksRule extends InsertRule {
  const AutoFormatLinksRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    // This rule applies to a space inserted after a link, so we can ignore
    // everything else.
    final text = data as String;
    if (text != ' ') return null;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    // No previous operation means nothing to analyze.
    if (previous == null || previous.data is! String) return null;
    final previousText = previous.data as String;

    // Split text of previous operation in lines and words and take the last
    // word to test.
    final candidate = previousText.split('\n').last.split(' ').last;
    try {
      final link = Uri.parse(candidate);
      if (!['https', 'http'].contains(link.scheme)) {
        // TODO: might need a more robust way of validating links here.
        return null;
      }
      final attributes = previous.attributes ?? <String, dynamic>{};

      // Do nothing if already formatted as link.
      if (attributes.containsKey(NotusAttribute.link.key)) return null;

      attributes
          .addAll(NotusAttribute.link.fromString(link.toString()).toJson());
      return Delta()
        ..retain(index - candidate.length)
        ..retain(candidate.length, attributes)
        ..insert(text, previous.attributes);
    } on FormatException {
      return null; // Our candidate is not a link.
    }
  }
}

/// Forces text inserted on the same line with an embed (before or after it)
/// to be moved to a new line adjacent to the original line.
///
/// This rule assumes that a line is only allowed to have single embed child.
class ForceNewlineForInsertsAroundEmbedRule extends InsertRule {
  const ForceNewlineForInsertsAroundEmbedRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final text = data as String;

    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();
    final cursorBeforeEmbed = target.data is! String;
    final cursorAfterEmbed = previous != null && previous.data is! String;

    if (cursorBeforeEmbed || cursorAfterEmbed) {
      final delta = Delta()..retain(index);
      if (cursorBeforeEmbed && !text.endsWith('\n')) {
        return delta..insert(text)..insert('\n');
      }
      if (cursorAfterEmbed && !text.startsWith('\n')) {
        return delta..insert('\n')..insert(text);
      }
      return delta..insert(text);
    }
    return null;
  }
}

/// Preserves block style when user pastes text containing newlines.
/// This rule may also be activated for changes triggered by auto-correct.
class PreserveBlockStyleOnPasteRule extends InsertRule {
  const PreserveBlockStyleOnPasteRule();

  bool isEdgeLineSplit(Operation before, Operation after) {
    if (before == null) return true; // split at the beginning of a doc
    final textBefore = before.data is String ? before.data as String : '';
    final textAfter = after.data is String ? after.data as String : '';
    return textBefore.endsWith('\n') || textAfter.startsWith('\n');
  }

  @override
  Delta apply(Delta document, int index, Object data) {
    // Embeds are handled by a different rule.
    if (data is! String) return null;

    final text = data as String;
    if (!text.contains('\n') || text.length == 1) {
      // Only interested in text containing at least one newline and at least
      // one more character.
      return null;
    }

    final iter = DeltaIterator(document);
    iter.skip(index);

    // Look for next newline.
    Map<String, dynamic> lineStyle;
    while (iter.hasNext) {
      final op = iter.next();
      final opText = op.data is String ? op.data as String : '';
      final lf = opText.indexOf('\n');
      if (lf >= 0) {
        lineStyle = op.attributes;
        break;
      }
    }

    Map<String, dynamic> resetStyle;
    Map<String, dynamic> blockStyle;
    if (lineStyle != null) {
      if (lineStyle.containsKey(NotusAttribute.heading.key)) {
        resetStyle = NotusAttribute.heading.unset.toJson();
      }

      if (lineStyle.containsKey(NotusAttribute.block.key)) {
        blockStyle = <String, dynamic>{
          NotusAttribute.block.key: lineStyle[NotusAttribute.block.key]
        };
      }
    }

    final lines = text.split('\n');
    final result = Delta()..retain(index);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isNotEmpty) {
        result.insert(line);
      }
      if (i == 0) {
        result.insert('\n', lineStyle);
      } else if (i == lines.length - 1) {
        if (resetStyle != null) result.retain(1, resetStyle);
      } else {
        result.insert('\n', blockStyle);
      }
    }

    return result;
  }
}

/// Handles all format operations which manipulate embeds.
class InsertEmbedsRule extends InsertRule {
  const InsertEmbedsRule();

  @override
  Delta apply(Delta document, int index, Object data) {
    // We are only interested in embeddable objects.
    if (data is! EmbeddableObject) return null;

    final result = Delta()..retain(index);
    final iter = DeltaIterator(document);
    final previous = iter.skip(index);
    final target = iter.next();

    // Check if [index] is on an empty line already.
    final textBefore = previous?.data is String ? previous.data as String : '';
    final textAfter = target.data is String ? target.data as String : '';

    final isNewlineBefore = previous == null || textBefore.endsWith('\n');
    final isNewlineAfter = textAfter.startsWith('\n');
    final isOnEmptyLine = isNewlineBefore && isNewlineAfter;

    if (isOnEmptyLine) {
      return result..insert(data);
    }
    // We are on a non-empty line, split it (preserving style if needed)
    // and insert our embed.
    final lineStyle = _getLineStyle(iter, target);
    if (!isNewlineBefore) {
      result..insert('\n', lineStyle);
    }
    result..insert(data);
    if (!isNewlineAfter) {
      result..insert('\n');
    }
    return result;
  }

  Map<String, dynamic> _getLineStyle(
      DeltaIterator iterator, Operation current) {
    final currentText = current.data is String ? current.data as String : '';

    if (currentText.contains('\n')) {
      return current.attributes;
    }
    // Continue looking for a newline.
    Map<String, dynamic> attributes;
    while (iterator.hasNext) {
      final op = iterator.next();
      final opText = op.data is String ? op.data as String : '';
      final lf = opText.indexOf('\n');
      if (lf >= 0) {
        attributes = op.attributes;
        break;
      }
    }
    return attributes;
  }
}
