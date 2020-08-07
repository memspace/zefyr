// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:quill_delta/quill_delta.dart';
import 'package:notus/notus.dart';

class NotusMarkdownCodec extends Codec<Delta, String> {
  const NotusMarkdownCodec();

  @override
  Converter<String, Delta> get decoder => _NotusMarkdownDecoder();

  @override
  Converter<Delta, String> get encoder => _NotusMarkdownEncoder();
}

class _NotusMarkdownDecoder extends Converter<String, Delta> {
  final List<Map<String, dynamic>> _attributesByStyleLength = [
    null,
    {'i': true}, // _
    {'b': true}, // **
    {'i': true, 'b': true} // **_
  ];
  final RegExp _headingRegExp = RegExp(r'(#+) *(.+)');
  final RegExp _styleRegExp = RegExp(r'((?:\*|_){1,3})(.*?[^\1 ])\1');
  final RegExp _linkRegExp = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)');
  final RegExp _ulRegExp = RegExp(r'^( *)\* +(.*)');
  final RegExp _olRegExp = RegExp(r'^( *)\d+[\.)] +(.*)');
  final RegExp _bqRegExp = RegExp(r'^> *(.*)');
  final RegExp _codeRegExp = RegExp(r'^( *)```'); // TODO: inline code
  bool _inBlockStack = false;
//  final List<String> _blockStack = [];
//  int _olDepth = 0;

  @override
  Delta convert(String input) {
    final lines = input.split('\n');
    final delta = Delta();

    if(_allLinesEmpty(lines)) {
      Map<String, dynamic> style;
      _handleSpan(lines[0], delta, true, style);
    } else {
      for (var line in lines) {
        _handleLine(line, delta);
      }
    }

    return delta;
  }

  bool _allLinesEmpty(List<String> lines) {
    for (var line in lines) {
      if (line != '') {
        return false;
      }
    }

    return true;
  }

  void _handleLine(String line, Delta delta, [Map<String, dynamic> attributes, bool isBlock]) {
    if (_handleBlockQuote(line, delta, attributes)) {
      return;
    }
    if (_handleBlock(line, delta, attributes)) {
      return;
    }
    if (_handleHeading(line, delta, attributes)) {
      return;
    }

    if (line.isNotEmpty) {
      _handleSpan(line, delta, true, attributes, isBlock);
    }
  }

  /// Markdown supports headings and blocks within blocks (except for within code)
  /// but not blocks within headers, or ul within
  bool _handleBlock(String line, Delta delta,
      [Map<String, dynamic> attributes]) {
    var match;

    match = _codeRegExp.matchAsPrefix(line);
    if (match != null) {
      _inBlockStack = !_inBlockStack;
      return true;
    }
    if (_inBlockStack) {
      delta.insert(
          line + '\n',
          NotusAttribute.code
              .toJson()); // TODO: replace with?: {'quote': true})
      // Don't bother testing for code blocks within block stacks
      return true;
    }

    if (_handleOrderedList(line, delta, attributes) ||
        _handleUnorderedList(line, delta, attributes)) {
      return true;
    }

    return false;
  }

  /// all blocks are supported within bq
  bool _handleBlockQuote(String line, Delta delta,
      [Map<String, dynamic> attributes]) {
    var match = _bqRegExp.matchAsPrefix(line);
    if (match != null) {
      var span = match.group(1);
      var newAttributes = NotusAttribute.bq.toJson(); // NotusAttribute.bq.toJson();
      if (attributes != null) {
        newAttributes.addAll(attributes);
      }
      // all blocks are supported within bq
      _handleLine(span, delta, newAttributes, true);
      return true;
    }
    return false;
  }

  /// ol is supported within ol and bq, but not supported within ul
  bool _handleOrderedList(String line, Delta delta,
      [Map<String, dynamic> attributes]) {
    var match = _olRegExp.matchAsPrefix(line);
    if (match != null) {
// TODO: support nesting
//      var depth =  match.group(1).length / 3;
      var span = match.group(2);
      var newAttributes = NotusAttribute.ol.toJson();
      if (attributes != null) {
        newAttributes.addAll(attributes);
      }
      // There's probably no reason why you would have other block types on the same line
      _handleSpan(span, delta, true, newAttributes, true);
      return true;
    }
    return false;
  }

  bool _handleUnorderedList(String line, Delta delta,
      [Map<String, dynamic> attributes]) {
    var match = _ulRegExp.matchAsPrefix(line);
    if (match != null) {
//      var depth = match.group(1).length / 3;
      var span = match.group(2);
      var newAttributes = NotusAttribute.ul.toJson();
      if (attributes != null) {
        newAttributes.addAll(attributes);
      }
      // There's probably no reason why you would have other block types on the same line
      _handleSpan(span, delta, true, newAttributes, true);
      return true;
    }
    return false;
  }

  bool _handleHeading(String line, Delta delta, [Map<String, dynamic> attributes]) {
    var match = _headingRegExp.matchAsPrefix(line);
    if (match != null) {
      var level = match.group(1).length;
      var newAttributes = <String, dynamic>{
        'heading': level
      }; // NotusAttribute.heading.withValue(level).toJson();
      if (attributes != null) {
        newAttributes.addAll(attributes);
      }

      var span = match.group(2);
      // TODO: true or false?
      _handleSpan(span, delta, true, newAttributes, true);
//      delta.insert('\n', attribute.toJson());
      return true;
    }

    return false;
  }

  void _handleSpan(String span, Delta delta, bool addNewLine,
      Map<String, dynamic> outerStyle, [bool isBlock]) {
    var start = _handleStyles(span, delta, outerStyle);
    span = span.substring(start);

    if (span.isNotEmpty) {
      start = _handleLinks(span, delta, outerStyle);
      span = span.substring(start);
    }

    if (span.isNotEmpty) {
      if (addNewLine) {
        if(isBlock != null && isBlock){
          delta.insert(span);
          delta.insert('\n', outerStyle);
        } else {
          delta.insert('$span\n', outerStyle);
        }
      } else {
        delta.insert(span, outerStyle);
      }
    } else if (addNewLine) {
      delta.insert('\n', outerStyle);
    }
  }

  int _handleStyles(String span, Delta delta, Map<String, dynamic> outerStyle) {
    var start = 0;

    var matches = _styleRegExp.allMatches(span);
    matches.forEach((match) {
      if (match.start > start) {
        var validInlineStyles = _getValidInlineStyles(outerStyle);
        if (span.substring(match.start - 1, match.start) == '[') {
          var text = span.substring(start, match.start - 1);
          validInlineStyles != null ? delta.insert(text, validInlineStyles) : delta.insert(text);
          start = match.start -
              1 +
              _handleLinks(span.substring(match.start - 1), delta, validInlineStyles);
          return;
        } else {
          var text = span.substring(start, match.start);

          validInlineStyles != null ? delta.insert(text, validInlineStyles) : delta.insert(text);
        }
      }

      var text = match.group(2);
      var newStyle = Map<String, dynamic>.from(
          _attributesByStyleLength[match.group(1).length]);
      
      var validInlineStyles = _getValidInlineStyles(outerStyle);
      if (validInlineStyles != null) {
        newStyle.addAll(validInlineStyles);
      }

      _handleSpan(text, delta, false, newStyle);
      start = match.end;
    });

    return start;
  }

  Map<String, dynamic> _getValidInlineStyles(Map<String, dynamic> outerStyle) {
    Map<String, dynamic> leafStyles;

    if(outerStyle == null) {
      return null;
    }

    if(outerStyle.containsKey(NotusAttribute.bold.key)){
      leafStyles = {'b': true};
    }

    if(outerStyle.containsKey(NotusAttribute.italic.key)){
      leafStyles = {'i': true};
    }

    if(outerStyle.containsKey(NotusAttribute.link.key)){
      leafStyles = {NotusAttribute.link.key: outerStyle[NotusAttribute.link.key]};
    }

    return leafStyles;
  }

  int _handleLinks(String span, Delta delta, Map<String, dynamic> outerStyle) {
    var start = 0;

    var matches = _linkRegExp.allMatches(span);
    matches.forEach((match) {
      if (match.start > start) {
        var text = span.substring(start, match.start);
        delta.insert(text); //, outerStyle);
      }

      var text = match.group(1);
      var href = match.group(2);
      var newAttributes = <String, dynamic>{
        'a': href
      }; // NotusAttribute.link.fromString(href).toJson();

      var validInlineStyles = _getValidInlineStyles(outerStyle);
      if (validInlineStyles != null) {
        newAttributes.addAll(validInlineStyles);
      }

      _handleSpan(text, delta, false, newAttributes);
      start = match.end;
    });

    return start;
  }
}

class _NotusMarkdownEncoder extends Converter<Delta, String> {
  static const kBold = '**';
  static const kItalic = '_';
  static final kSimpleBlocks = <NotusAttribute, String>{
    NotusAttribute.bq: '> ',
    NotusAttribute.ul: '* ',
    NotusAttribute.ol: '1. ',
  };

  @override
  String convert(Delta input) {
    final iterator = DeltaIterator(input);
    final buffer = StringBuffer();
    final lineBuffer = StringBuffer();
    NotusAttribute<String> currentBlockStyle;
    var currentInlineStyle = NotusStyle();
    var currentBlockLines = <String>[];

    bool _allLinesEmpty(List<String> lines) {
      for (var line in lines) {
        if (line != '') {
          return false;
        }
      }

      return true;
    }

    void _handleBlock(NotusAttribute<String> blockStyle) {
      if (currentBlockLines.isEmpty) {
        return; // Empty block
      }

      if(_allLinesEmpty(currentBlockLines)){
        return;
      }

      if (blockStyle == null) {
        buffer.write(currentBlockLines.join('\n\n'));
        buffer.writeln();
      } else if (blockStyle == NotusAttribute.code) {
        _writeAttribute(buffer, blockStyle);
        buffer.write(currentBlockLines.join('\n'));
        _writeAttribute(buffer, blockStyle, close: true);
        buffer.writeln();
      } else {
        for (var line in currentBlockLines) {
          _writeBlockTag(buffer, blockStyle);
          buffer.write(line);
          buffer.writeln();
        }
      }
      buffer.writeln();
    }

    void _handleSpan(String text, Map<String, dynamic> attributes) {
      final style = NotusStyle.fromJson(attributes);
      currentInlineStyle =
          _writeInline(lineBuffer, text, style, currentInlineStyle);
    }

    void _handleLine(Map<String, dynamic> attributes) {
      final style = NotusStyle.fromJson(attributes);
      final lineBlock = style.get(NotusAttribute.block);
      if (lineBlock == currentBlockStyle) {
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));
      } else {
        _handleBlock(currentBlockStyle);
        currentBlockLines.clear();
        currentBlockLines.add(_writeLine(lineBuffer.toString(), style));

        currentBlockStyle = lineBlock;
      }
      lineBuffer.clear();
    }

    while (iterator.hasNext) {
      final op = iterator.next();
      final lf = op.data.indexOf('\n');
      if (lf == -1) {
        _handleSpan(op.data, op.attributes);
      } else {
        var span = StringBuffer();
        for (var i = 0; i < op.data.length; i++) {
          if (op.data.codeUnitAt(i) == 0x0A) {
            if (span.isNotEmpty) {
              // Write the span if it's not empty.
              _handleSpan(span.toString(), op.attributes);
            }
            // Close any open inline styles.
            _handleSpan('', null);
            _handleLine(op.attributes);
            span.clear();
          } else {
            span.writeCharCode(op.data.codeUnitAt(i));
          }
        }
        // Remaining span
        if (span.isNotEmpty) {
          _handleSpan(span.toString(), op.attributes);
        }
      }
    }
    _handleBlock(currentBlockStyle); // Close the last block
    return buffer.toString();
  }

  String _writeLine(String text, NotusStyle style) {
    var buffer = StringBuffer();
    if (style.contains(NotusAttribute.heading)) {
      _writeAttribute(buffer, style.get<int>(NotusAttribute.heading));
    }

    // Write the text itself
    buffer.write(text);
    return buffer.toString();
  }

  String _trimRight(StringBuffer buffer) {
    var text = buffer.toString();
    if (!text.endsWith(' ')) return '';
    final result = text.trimRight();
    buffer.clear();
    buffer.write(result);
    return ' ' * (text.length - result.length);
  }

  NotusStyle _writeInline(StringBuffer buffer, String text, NotusStyle style,
      NotusStyle currentStyle) {
    // First close any current styles if needed
    for (var value in currentStyle.values) {
      if (value.scope == NotusAttributeScope.line) continue;
      if (style.containsSame(value)) continue;
      final padding = _trimRight(buffer);
      _writeAttribute(buffer, value, close: true);
      if (padding.isNotEmpty) buffer.write(padding);
    }
    // Now open any new styles.
    for (var value in style.values.toList().reversed) {
      if (value.scope == NotusAttributeScope.line) continue;
      if (currentStyle.containsSame(value)) continue;
      final originalText = text;
      text = text.trimLeft();
      final padding = ' ' * (originalText.length - text.length);
      if (padding.isNotEmpty) buffer.write(padding);
      _writeAttribute(buffer, value);
    }
    // Write the text itself
    buffer.write(text);
    return style;
  }

  void _writeAttribute(StringBuffer buffer, NotusAttribute attribute,
      {bool close = false}) {
    if (attribute == NotusAttribute.bold) {
      _writeBoldTag(buffer);
    } else if (attribute == NotusAttribute.italic) {
      _writeItalicTag(buffer);
    } else if (attribute.key == NotusAttribute.link.key) {
      _writeLinkTag(buffer, attribute as NotusAttribute<String>, close: close);
    } else if (attribute.key == NotusAttribute.heading.key) {
      _writeHeadingTag(buffer, attribute as NotusAttribute<int>);
    } else if (attribute.key == NotusAttribute.block.key) {
      _writeBlockTag(buffer, attribute as NotusAttribute<String>, close: close);
    } else {
      throw ArgumentError('Cannot handle $attribute');
    }
  }

  void _writeBoldTag(StringBuffer buffer) {
    buffer.write(kBold);
  }

  void _writeItalicTag(StringBuffer buffer) {
    buffer.write(kItalic);
  }

  void _writeLinkTag(StringBuffer buffer, NotusAttribute<String> link,
      {bool close = false}) {
    if (close) {
      buffer.write('](${link.value})');
    } else {
      buffer.write('[');
    }
  }

  void _writeHeadingTag(StringBuffer buffer, NotusAttribute<int> heading) {
    var level = heading.value;
    buffer.write('#' * level + ' ');
  }

  void _writeBlockTag(StringBuffer buffer, NotusAttribute<String> block,
      {bool close = false}) {
    if (block == NotusAttribute.code) {
      if (close) {
        buffer.write('\n```');
      } else {
        buffer.write('```\n');
      }
    } else {
      if (close) return; // no close tag needed for simple blocks.

      final tag = kSimpleBlocks[block];
      buffer.write(tag);
    }
  }
}