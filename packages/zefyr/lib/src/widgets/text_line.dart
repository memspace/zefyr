import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_text_line.dart';
import 'editor.dart';
import 'embed_proxy.dart';
import 'keyboard_listener.dart';
import 'link.dart';
import 'rich_text_proxy.dart';
import 'theme.dart';

/// Line of text in Zefyr editor.
///
/// This widget allows to render non-editable line of rich text, but can be
/// wrapped with [EditableTextLine] which adds editing features.
class TextLine extends StatefulWidget {
  /// Line of text represented by this widget.
  final LineNode node;
  final bool readOnly;
  final ZefyrController controller;
  final ZefyrEmbedBuilder embedBuilder;
  final ValueChanged<String?>? onLaunchUrl;
  final LinkActionPicker linkActionPicker;

  const TextLine({
    Key? key,
    required this.node,
    required this.readOnly,
    required this.controller,
    required this.embedBuilder,
    required this.onLaunchUrl,
    required this.linkActionPicker,
  }) : super(key: key);

  @override
  State<TextLine> createState() => _TextLineState();
}

class _TextLineState extends State<TextLine> {
  bool _metaOrControlPressed = false;

  UniqueKey _richTextKey = UniqueKey();

  final _linkRecognizers = <Node, GestureRecognizer>{};

  ZefyrPressedKeys? _pressedKeys;

  void _pressedKeysChanged() {
    final newValue = _pressedKeys!.metaPressed || _pressedKeys!.controlPressed;
    if (_metaOrControlPressed != newValue) {
      setState(() {
        _metaOrControlPressed = newValue;
        _richTextKey = UniqueKey();
      });
    }
  }

  bool get isDesktop => {
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows
      }.contains(defaultTargetPlatform);

  bool get canLaunchLinks {
    if (widget.onLaunchUrl == null) return false;
    // In readOnly mode users can launch links by simply tapping (clicking) on them
    if (widget.readOnly) return true;

    // In editing mode it depends on the platform:

    // Desktop platforms (macos, linux, windows): only allow Meta(Control)+Click combinations
    if (isDesktop) {
      return _metaOrControlPressed;
    }
    // Mobile platforms (ios, android): always allow but we install a
    // long-press handler instead of a tap one. LongPress is followed by a
    // context menu with actions.
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pressedKeys == null) {
      _pressedKeys = ZefyrPressedKeys.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    } else {
      _pressedKeys!.removeListener(_pressedKeysChanged);
      _pressedKeys = ZefyrPressedKeys.of(context);
      _pressedKeys!.addListener(_pressedKeysChanged);
    }
  }

  @override
  void didUpdateWidget(covariant TextLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readOnly != widget.readOnly) {
      _richTextKey = UniqueKey();
      _linkRecognizers.forEach((key, value) {
        value.dispose();
      });
      _linkRecognizers.clear();
    }
  }

  @override
  void dispose() {
    _pressedKeys?.removeListener(_pressedKeysChanged);
    _linkRecognizers.forEach((key, value) => value.dispose());
    _linkRecognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    if (widget.node.hasEmbed) {
      final embed = widget.node.children.single as EmbedNode;
      return EmbedProxy(child: widget.embedBuilder(context, embed));
    }
    final text = buildText(context, widget.node);
    final textAlign = getTextAlign(widget.node);
    final strutStyle =
        StrutStyle.fromTextStyle(text.style!, forceStrutHeight: true);
    return RichTextProxy(
      textStyle: text.style!,
      textAlign: textAlign,
      strutStyle: strutStyle,
      locale: Localizations.maybeLocaleOf(context),
      child: RichText(
        key: _richTextKey,
        text: text,
        textAlign: textAlign,
        strutStyle: strutStyle,
        textScaleFactor: MediaQuery.textScaleFactorOf(context),
      ),
    );
  }

  TextAlign getTextAlign(LineNode node) {
    final alignment = node.style.get(NotusAttribute.alignment);
    if (alignment == NotusAttribute.center) {
      return TextAlign.center;
    } else if (alignment == NotusAttribute.right) {
      return TextAlign.right;
    } else if (alignment == NotusAttribute.justify) {
      return TextAlign.justify;
    }
    return TextAlign.left;
  }

  TextSpan buildText(BuildContext context, LineNode node) {
    final theme = ZefyrTheme.of(context)!;
    final children = node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return TextSpan(
      style: _getParagraphTextStyle(node.style, theme),
      children: children,
    );
  }

  TextSpan _segmentToTextSpan(Node segment, ZefyrThemeData theme) {
    final text = segment as TextNode;
    final attrs = text.style;
    final isLink = attrs.contains(NotusAttribute.link);
    return TextSpan(
      text: text.value,
      style: _getInlineTextStyle(attrs, widget.node.style, theme),
      recognizer: isLink && canLaunchLinks ? _getRecognizer(segment) : null,
      mouseCursor: isLink && canLaunchLinks ? SystemMouseCursors.click : null,
    );
  }

  GestureRecognizer _getRecognizer(Node segment) {
    if (_linkRecognizers.containsKey(segment)) {
      return _linkRecognizers[segment]!;
    }

    if (isDesktop || widget.readOnly) {
      _linkRecognizers[segment] = TapGestureRecognizer()
        ..onTap = () => _tapLink(segment);
    } else {
      _linkRecognizers[segment] = LongPressGestureRecognizer()
        ..onLongPress = () => _longPressLink(segment);
    }
    return _linkRecognizers[segment]!;
  }

  void _tapLink(Node segment) {
    final link = (segment as StyledNode).style.get(NotusAttribute.link)!.value;
    widget.onLaunchUrl!(link);
  }

  void _longPressLink(Node segment) async {
    final link = (segment as StyledNode).style.get(NotusAttribute.link)!.value!;
    final action = await widget.linkActionPicker(segment);
    switch (action) {
      case LinkMenuAction.launch:
        widget.onLaunchUrl!(link);
        break;
      case LinkMenuAction.copy:
        // ignore: unawaited_futures
        Clipboard.setData(ClipboardData(text: link));
        break;
      case LinkMenuAction.remove:
        final range = _getLinkRange(segment);
        widget.controller.formatText(
            range.start, range.end - range.start, NotusAttribute.link.unset);
        break;
      case LinkMenuAction.none:
        break;
    }
  }

  TextRange _getLinkRange(Node segment) {
    int start = segment.documentOffset;
    int length = segment.length;
    var prev = segment.previous as StyledNode?;
    final linkAttr = (segment as StyledNode).style.get(NotusAttribute.link)!;
    while (prev != null) {
      if (prev.style.containsSame(linkAttr)) {
        start = prev.documentOffset;
        length += prev.length;
        prev = prev.previous as StyledNode?;
      } else {
        break;
      }
    }

    var next = segment.next as StyledNode?;
    while (next != null) {
      if (next.style.containsSame(linkAttr)) {
        length += next.length;
        next = next.next as StyledNode?;
      } else {
        break;
      }
    }
    return TextRange(start: start, end: start + length);
  }

  TextStyle _getParagraphTextStyle(NotusStyle style, ZefyrThemeData theme) {
    var textStyle = const TextStyle();
    final heading = widget.node.style.get(NotusAttribute.heading);
    if (heading == NotusAttribute.heading.level1) {
      textStyle = textStyle.merge(theme.heading1.style);
    } else if (heading == NotusAttribute.heading.level2) {
      textStyle = textStyle.merge(theme.heading2.style);
    } else if (heading == NotusAttribute.heading.level3) {
      textStyle = textStyle.merge(theme.heading3.style);
    } else {
      textStyle = textStyle.merge(theme.paragraph.style);
    }

    final block = style.get(NotusAttribute.block);
    if (block == NotusAttribute.block.quote) {
      textStyle = textStyle.merge(theme.quote.style);
    } else if (block == NotusAttribute.block.code) {
      textStyle = textStyle.merge(theme.code.style);
    } else if (block != null) {
      // lists
      textStyle = textStyle.merge(theme.lists.style);
    }

    return textStyle;
  }

  TextStyle _getInlineTextStyle(
      NotusStyle nodeStyle, NotusStyle lineStyle, ZefyrThemeData theme) {
    var result = const TextStyle();
    if (nodeStyle.containsSame(NotusAttribute.bold)) {
      result = _mergeTextStyleWithDecoration(result, theme.bold);
    }
    if (nodeStyle.containsSame(NotusAttribute.italic)) {
      result = _mergeTextStyleWithDecoration(result, theme.italic);
    }
    if (nodeStyle.contains(NotusAttribute.link)) {
      result = _mergeTextStyleWithDecoration(result, theme.link);
    }
    if (nodeStyle.contains(NotusAttribute.underline)) {
      result = _mergeTextStyleWithDecoration(result, theme.underline);
    }
    if (nodeStyle.contains(NotusAttribute.strikethrough)) {
      result = _mergeTextStyleWithDecoration(result, theme.strikethrough);
    }
    if (nodeStyle.contains(NotusAttribute.inlineCode)) {
      result = _mergeTextStyleWithDecoration(
          result, theme.inlineCode.styleFor(lineStyle));
    }
    return result;
  }

  TextStyle _mergeTextStyleWithDecoration(TextStyle a, TextStyle? b) {
    var decorations = <TextDecoration>[];
    if (a.decoration != null) {
      decorations.add(a.decoration!);
    }
    if (b?.decoration != null) {
      decorations.add(b!.decoration!);
    }
    return a.merge(b).apply(decoration: TextDecoration.combine(decorations));
  }
}
