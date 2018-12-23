import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'code.dart';
import 'common.dart';
import 'image.dart';
import 'list.dart';
import 'paragraph.dart';
import 'quote.dart';
import 'theme.dart';

class _ZefyrViewAccess extends InheritedWidget {
  final ZefyrViewState state;

  _ZefyrViewAccess({Key key, @required this.state, Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_ZefyrViewAccess oldWidget) {
    return state != oldWidget.state;
  }
}

/// Non-scrollable read-only view of a Notus rich text document.
class ZefyrView extends StatefulWidget {
  final NotusDocument document;
  final ZefyrImageDelegate imageDelegate;

  const ZefyrView({Key key, this.document, this.imageDelegate})
      : super(key: key);

  static ZefyrViewState of(BuildContext context) {
    final _ZefyrViewAccess widget =
        context.inheritFromWidgetOfExactType(_ZefyrViewAccess);
    if (widget == null) return null;
    return widget.state;
  }

  @override
  ZefyrViewState createState() => ZefyrViewState();
}

class ZefyrViewState extends State<ZefyrView> {
  ZefyrThemeData _themeData;

  ZefyrImageDelegate get imageDelegate => widget.imageDelegate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentTheme = ZefyrTheme.of(context, nullOk: true);
    final fallbackTheme = ZefyrThemeData.fallback(context);
    _themeData = (parentTheme != null)
        ? fallbackTheme.merge(parentTheme)
        : fallbackTheme;
  }

  @override
  Widget build(BuildContext context) {
    return ZefyrTheme(
      data: _themeData,
      child: _ZefyrViewAccess(
        state: this,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    for (var node in widget.document.root.children) {
      result.add(_defaultChildBuilder(context, node));
    }
    return result;
  }

  Widget _defaultChildBuilder(BuildContext context, Node node) {
    if (node is LineNode) {
      if (node.hasEmbed) {
        return new RawZefyrLine(node: node);
      } else if (node.style.contains(NotusAttribute.heading)) {
        return new ZefyrHeading(node: node);
      }
      return new ZefyrParagraph(node: node);
    }

    final BlockNode block = node;
    final blockStyle = block.style.get(NotusAttribute.block);
    if (blockStyle == NotusAttribute.block.code) {
      return new ZefyrCode(node: node);
    } else if (blockStyle == NotusAttribute.block.bulletList) {
      return new ZefyrList(node: node);
    } else if (blockStyle == NotusAttribute.block.numberList) {
      return new ZefyrList(node: node);
    } else if (blockStyle == NotusAttribute.block.quote) {
      return new ZefyrQuote(node: node);
    }

    throw new UnimplementedError('Block format $blockStyle.');
  }
}
