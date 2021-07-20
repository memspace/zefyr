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
  final EdgeInsets? contentPadding;
  final ZefyrEmbedBuilder embedBuilder;

  EditableTextBlock({
    Key? key,
    required this.node,
    required this.textDirection,
    required this.spacing,
    required this.cursorController,
    required this.selection,
    required this.selectionColor,
    required this.enableInteractiveSelection,
    required this.hasFocus,
    required this.embedBuilder,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));

    final theme = ZefyrTheme.of(context)!;
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
    final theme = ZefyrTheme.of(context)!;
    final count = node.children.length;
    final children = <Widget>[];
    var index = 0;
    for (final line in node.children) {
      index++;
      children.add(EditableTextLine(
        node: line as LineNode,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: _buildLeading(context, line, index, count),
        indentWidth: _getIndentWidth(),
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
    }
    return children.toList(growable: false);
  }

  Widget? _buildLeading(
      BuildContext context, LineNode node, int index, int count) {
    final theme = ZefyrTheme.of(context)!;
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.numberList) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.paragraph.style,
        width: 32.0,
        padding: 8.0,
      );
    } else if (block == NotusAttribute.block.bulletList) {
      return _BulletPoint(
        style: theme.paragraph.style.copyWith(fontWeight: FontWeight.bold),
        width: 32,
      );
    } else if (block == NotusAttribute.block.code) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.code.style
            .copyWith(color: theme.code.style.color?.withOpacity(0.4)),
        width: 32.0,
        padding: 16.0,
        withDot: false,
      );
    } else {
      return null;
    }
  }

  double _getIndentWidth() {
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      return 16.0;
    } else if (block == NotusAttribute.block.code) {
      return 32.0;
    } else {
      return 32.0;
    }
  }

  VerticalSpacing _getSpacingForLine(
      LineNode node, int index, int count, ZefyrThemeData theme) {
    final heading = node.style.get(NotusAttribute.heading);

    double? top;
    double? bottom;

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
      VerticalSpacing? lineSpacing;
      if (block == NotusAttribute.block.quote) {
        lineSpacing = theme.quote.lineSpacing;
      } else if (block == NotusAttribute.block.numberList ||
          block == NotusAttribute.block.bulletList) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.block.code ||
          block == NotusAttribute.block.code) {
        lineSpacing = theme.lists.lineSpacing;
      }
      top = lineSpacing?.top;
      bottom = lineSpacing?.bottom;
    }

    // If this line is the top one in this block we ignore its top spacing
    // because the block itself already has it. Similarly with the last line
    // and its bottom spacing.
    if (index == 1) {
      top = 0.0;
    }

    if (index == count) {
      bottom = 0.0;
    }

    return VerticalSpacing(top: top ?? 0, bottom: bottom ?? 0);
  }

  BoxDecoration? _getDecorationForBlock(BlockNode node, ZefyrThemeData theme) {
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
  final EdgeInsets? contentPadding;

  _EditableBlock({
    Key? key,
    required this.node,
    required this.textDirection,
    required this.decoration,
    required List<Widget> children,
    this.contentPadding,
    this.padding = const VerticalSpacing(),
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
  final int count;
  final double width;
  final bool withDot;
  final double padding;
  final TextStyle style;

  const _NumberPoint({
    Key? key,
    required this.index,
    required this.count,
    required this.width,
    required this.style,
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: padding),
      child: Text(withDot ? '$index.' : '$index', style: style),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final double width;
  final TextStyle style;

  const _BulletPoint({
    Key? key,
    required this.width,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.topEnd,
      width: width,
      padding: EdgeInsetsDirectional.only(end: 13.0),
      child: Text('•', style: style),
    );
  }
}
