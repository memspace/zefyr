import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextRange Function(Node node) inputtingTextRange;
  final LookupResult lookupResult;

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
    @required this.inputtingTextRange,
    @required this.lookupResult,
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
    final children = <Widget>[];
    var index = 0;
    for (final line in node.children) {
      index++;
      children.add(EditableTextLine(
        node: line,
        textDirection: textDirection,
        spacing: _getSpacingForLine(line, index, count, theme),
        leading: _buildLeading(context, line, index, count),
        bottom: _buildBottom(context, line),
        indentWidth: _getIndentWidth(),
        devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        body: TextLine(
          node: line,
          textDirection: textDirection,
          embedBuilder: embedBuilder,
          inputtingTextRange: inputtingTextRange(line),
          lookupResult: lookupResult,
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

  Widget _buildLeading(
      BuildContext context, LineNode node, int index, int count) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.numberList) {
      return _NumberPoint(
        index: index,
        count: count,
        style: theme.paragraph.style,
        width: 25.0,
        padding: 8.0,
      );
    } else if (block == NotusAttribute.block.bulletList) {
      return _BulletPoint(
        style: theme.paragraph.style.copyWith(fontWeight: FontWeight.bold),
        width: 24,
      );
    } else if (block == NotusAttribute.largeHeading) {
      return Row(
        children: [
          Container(
            height: 120, // NOTE: 最大で3行まで装飾がつくようにしている
            width: 8,
            color: Color(0xFF0099DD),
          ),
        ],
      );
    } else {
      return null;
    }
  }

  Widget _buildBottom(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context);
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.middleHeading) {
      return Divider(
        height: theme.paragraph.style.fontSize * theme.paragraph.style.height,
        thickness: 1,
        color: Color(0xFF0099DD),
      );
    }
    return null;
  }

  double _getIndentWidth() {
    final block = node.style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      return 16.0;
    } else if (block == NotusAttribute.block.code) {
      return 0;
    } else if (block == NotusAttribute.block.bulletList) {
      return 28.0;
    } else if (block == NotusAttribute.block.numberList) {
      return 28.0;
    } else if (block == NotusAttribute.middleHeading) {
      return 0;
    } else {
      return 16.0;
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
    } else if (heading == NotusAttribute.heading.caption) {
      top = theme.caption.spacing.top;
      bottom = theme.caption.spacing.bottom;
    } else {
      final block = this.node.style.get(NotusAttribute.block);
      var lineSpacing;
      if (block == NotusAttribute.block.quote) {
        lineSpacing = theme.quote.lineSpacing;
      } else if (block == NotusAttribute.block.numberList ||
          block == NotusAttribute.block.bulletList) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.block.code) {
        lineSpacing = theme.lists.lineSpacing;
      } else if (block == NotusAttribute.largeHeading) {
        lineSpacing = theme.largeHeading.lineSpacing;
      } else if (block == NotusAttribute.middleHeading) {
        lineSpacing = theme.middleHeading.lineSpacing;
      }
      top = lineSpacing.top;
      bottom = lineSpacing.bottom;
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

    return VerticalSpacing(top: top, bottom: bottom);
  }

  BoxDecoration _getDecorationForBlock(BlockNode node, ZefyrThemeData theme) {
    final style = node.style.get(NotusAttribute.block);
    if (style == NotusAttribute.block.quote) {
      return theme.quote.decoration;
    } else if (style == NotusAttribute.block.code) {
      return theme.code.decoration;
    } else if (style == NotusAttribute.largeHeading) {
      return theme.largeHeading.decoration;
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
  final int count;
  final TextStyle style;
  final double width;
  final bool withDot;
  final double padding;

  const _NumberPoint({
    Key key,
    @required this.index,
    @required this.count,
    @required this.style,
    @required this.width,
    this.withDot = true,
    this.padding = 0.0,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.only(right: 4),
      child: Text(
        withDot ? '$index.' : '$index',
        textAlign: TextAlign.right,
        style: GoogleFonts.notoSans(
          color: style.color,
          fontSize: style.fontSize,
        ),
      ),
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
      padding: EdgeInsets.only(top: 7),
      alignment: AlignmentDirectional.topCenter,
      width: width,
      child: Container(
        height: 6,
        width: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
      ),
    );
  }
}
