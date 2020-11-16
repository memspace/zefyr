import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import '../rendering/editable_text_block.dart';
import 'cursor.dart';
import 'editable_text_line.dart';
import 'editor.dart';
import 'text_line.dart';
import 'theme.dart';

class EditableTextBlock extends StatelessWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing spacing;
  final CursorController cursorController;
  final TextSelection selection;
  final Color selectionColor;
  final bool enableInteractiveSelection;
  final bool hasFocus;
  final EdgeInsets contentPadding;
  final ZefyrEmbedBuilder embedBuilder;

  EditableTextBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    @required this.spacing,
    @required this.cursorController,
    @required this.selection,
    @required this.selectionColor,
    @required this.enableInteractiveSelection,
    @required this.hasFocus,
    this.contentPadding,
    @required this.embedBuilder,
  })  : assert(hasFocus != null),
        assert(embedBuilder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final theme = ZefyrTheme.of(context);
    return _EditableBlock(
      node: node,
      textDirection: textDirection,
      padding: spacing,
      contentPadding: contentPadding,
      decoration: _getDecorationForBlock(node, theme) ?? BoxDecoration(),
      children: _buildChildren(context),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final count = node.children.length;
    final leadingWidgets = _buildLeading(theme, node.children.toList());
    final children = <Widget>[];
    var index = 0;
    for (final line in node.children) {
      children.add(EditableTextLine(
        node: line,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: leadingWidgets == null ? null : leadingWidgets[index],
        indentWidth: _getIndentWidth(line),
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        body: TextLine(
          node: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
        ),
        cursorController: cursorController,
        selection: selection,
        selectionColor: selectionColor,
        enableInteractiveSelection: enableInteractiveSelection,
        hasFocus: hasFocus,
      ));
      index++;
    }
    return children.toList(growable: false);
  }

  List<Widget> _buildLeading(ZefyrThemeData theme, List<Node> children) {
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.numberList) {
      return _getNumberPointsForNumberList(theme, children);
    } else if (block == NotusAttribute.block.bulletList) {
      return _getBulletPointForBulletList(theme, children);
    } else if (block == NotusAttribute.block.code) {
      return _getNumberPointsForCodeBlock(theme, children);
    } else {
      return null;
    }
  }

  List<Widget> _getBulletPointForBulletList(
          ZefyrThemeData theme, List<Node> children) =>
      children
          .map((_) => _BulletPoint(
                style:
                    theme.paragraph.style.copyWith(fontWeight: FontWeight.bold),
                width: 32,
              ))
          .toList();

  List<Widget> _getNumberPointsForCodeBlock(
      ZefyrThemeData theme, List<Node> children) {
    final leadingWidgets = <Widget>[];
    children.forEach((element) {
      leadingWidgets.add(_NumberPoint(
        index: leadingWidgets.length,
        style: theme.code.style
            .copyWith(color: theme.code.style.color.withOpacity(0.4)),
        width: 32.0,
        padding: 16.0,
        withDot: false,
      ));
    });
    return leadingWidgets;
  }

  List<Widget> _getNumberPointsForNumberList(
      ZefyrThemeData theme, List<Node> children) {
    final leadingWidgets = <Widget>[];
    final levels = <int>[];
    final indexes = <int>[];
    children.forEach((element) {
      final currentLevel =
          (element as LineNode).style.get(NotusAttribute.indent)?.value ?? 0;
      var currentIndex = 0;

      if (leadingWidgets.isNotEmpty) {
        if (levels.last == currentLevel) {
          currentIndex = indexes.last + 1;
        } else if (levels.last > currentLevel) {
          final lastIndex =
              levels.lastIndexWhere((element) => element == currentLevel);
          if (lastIndex != -1) {
            currentIndex = indexes[lastIndex] + 1;
          }
        }
      }

      leadingWidgets.add(_NumberPoint(
        index: currentIndex,
        style: theme.paragraph.style,
        width: 32.0,
        padding: 8.0,
      ));
      levels.add(currentLevel);
      indexes.add(currentIndex);
    });
    return leadingWidgets;
  }

  double _getIndentWidth(LineNode line) {
    final block = node.style.get(NotusAttribute.block);

    if(block == NotusAttribute.block.quote){
      return 32.0;
    }

    final lineIndentation = line.style.get(NotusAttribute.indent);
    var extraIndent = 0;
    if (lineIndentation == NotusAttribute.indent.level1) {
      extraIndent = 16;
    } else if (lineIndentation == NotusAttribute.indent.level2) {
      extraIndent = 32;
    } else if (lineIndentation == NotusAttribute.indent.level3) {
      extraIndent = 48;
    }

    if (block == NotusAttribute.block.quote) {
      return extraIndent + 16.0;
    } else {
      return extraIndent + 32.0;
    }
  }

  VerticalSpacing _getSpacingForLine(
      LineNode node, int index, int count, ZefyrThemeData theme) {
    final heading = node.style.get(NotusAttribute.heading);

    var top = 0.0;
    var bottom = 0.0;

    if (heading == NotusAttribute.heading.level1) {
      top = theme.heading1.spacing.top;
      bottom = theme.heading1.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level2) {
      top = theme.heading2.spacing.top;
      bottom = theme.heading2.spacing.bottom;
    } else if (heading == NotusAttribute.heading.level3) {
      top = theme.heading3.spacing.top;
      bottom = theme.heading3.spacing.bottom;
    } else {
      final block = this.node.style.get(NotusAttribute.block);
      var lineSpacing;
      if (block == NotusAttribute.block.quote) {
        lineSpacing = theme.quote.lineSpacing;
      } else if (block == NotusAttribute.block.numberList ||
          block == NotusAttribute.block.bulletList) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.block.code ||
          block == NotusAttribute.block.code) {
        lineSpacing = theme.lists.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
    }

    // If this line is the top one in this block we ignore its top spacing
    // because the block itself already has it. Similarly with the last line
    // and its bottom spacing.
    if (index == 0) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top: top, bottom: bottom);
  }

  BoxDecoration _getDecorationForBlock(BlockNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.quote) {
      return theme.quote.decoration;
    } else if (style == NotusAttribute.block.code) {
      return theme.code.decoration;
    }
    return null;
  }
}

class _EditableBlock extends MultiChildRenderObjectWidget {
  final BlockNode node;
  final TextDirection textDirection;
  final VerticalSpacing padding;
  final Decoration decoration;
  final EdgeInsets contentPadding;

  _EditableBlock({
    Key key,
    @required this.node,
    @required this.textDirection,
    this.padding = const VerticalSpacing(),
    this.contentPadding,
    @required this.decoration,
    @required List<Widget> children,
  }) : super(key: key, children: children);

  EdgeInsets get _padding =>
      EdgeInsets.only(top: padding.top, bottom: padding.bottom);

  EdgeInsets get _contentPadding => contentPadding ?? EdgeInsets.zero;

  @override
  RenderEditableTextBlock createRenderObject(BuildContext context) {
    return RenderEditableTextBlock(
      node: node,
      textDirection: textDirection,
      padding: _padding,
      decoration: decoration,
      contentPadding: _contentPadding,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderEditableTextBlock renderObject) {
    renderObject.node = node;
    renderObject.textDirection = textDirection;
    renderObject.padding = _padding;
    renderObject.decoration = decoration;
    renderObject.contentPadding = _contentPadding;
  }
}

class _NumberPoint extends StatelessWidget {
  final int index;
  final TextStyle style;
  final double width;
  final bool withDot;
  final double padding;

  const _NumberPoint({
    Key key,
    @required this.index,
    @required this.style,
    @required this.width,
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentNumber = index + 1;
    return Container(
      alignment: AlignmentDirectional.topEnd,
      child: Text(withDot ? '$currentNumber.' : '$currentNumber', style: style),
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final TextStyle style;
  final double width;

  const _BulletPoint({
    Key key,
    @required this.style,
    @required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      child: Text('•', style: style),
      width: width,
      padding: EdgeInsetsDirectional.only(end: 13.0),
    );
  }
}
