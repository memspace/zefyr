import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

import 'controller.dart';
import 'editable_box.dart';
import 'editable_text.dart';

abstract class ZefyrGesturesDelegate<S> {
  void onPress(RenderEditableBox renderNode, NotusStyle style, Offset offset);
  void onLongPress(RenderEditableBox renderNode, NotusStyle style, Offset offset);
}

RenderEditableBox _getEditableBox(HitTestResult result) {
  for (var entry in result.path) {
    if (entry.target is RenderEditableBox) {
      return entry.target;
    }
  }
  return null;
}

class GesturesOverlay extends StatefulWidget {
  final ZefyrController controller;
  final TextSelectionControls controls;
  final OverlayState overlay;
  final ZefyrGesturesDelegate gesturesDelegate;

  GesturesOverlay({
    Key key,
    this.controller,
    this.controls,
    this.overlay,
    this.gesturesDelegate,
  }) : super(key: key);

  @override
  _GesturesState createState() => new _GesturesState();
}

class _GesturesState extends State<GesturesOverlay> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = new GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      onLongPress: _handleLongPress,
    );
    return new Container(child: overlay);
  }

  /// Global position of last TapDown event.
  Offset _lastTapDownPosition;

  /// Global position of last TapDown which is potentially a long press.
  Offset _longPressPosition;

  void _handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  void _handleTapCancel() {
    // longPress arrives after tapCancel, so remember the tap position.
    _longPressPosition = _lastTapDownPosition;
    _lastTapDownPosition = null;
  }

  void _handleTap() {
    assert(_lastTapDownPosition != null);
    final globalPoint = _lastTapDownPosition;
    _lastTapDownPosition = null;
    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPoint);

    RenderEditableProxyBox box = _getEditableBox(result);
    if (box == null) {
      final editable = ZefyrEditableText.of(context);
      box = editable.renderContext.closestBoxForGlobalPoint(globalPoint);
    }
    if (box == null) return null;

    final localPoint = box.globalToLocal(globalPoint);
    final position = box.getPositionForOffset(localPoint);

    final selection = new TextSelection.collapsed(
      offset: position.offset,
      affinity: position.affinity,
    );

    widget.controller.updateSelection(selection, source: ChangeSource.local);
    widget.gesturesDelegate.onPress(box.child, widget.controller.getSelectionStyle(), globalPoint);
  }

  void _handleLongPress() {
    final Offset globalPoint = _longPressPosition;
    _longPressPosition = null;
    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPoint);
    final box = _getEditableBox(result);
    if (box == null) {
      return;
    }
    final localPoint = box.globalToLocal(globalPoint);
    final position = box.getPositionForOffset(localPoint);
    final selection = new TextSelection.collapsed(
      offset: position.offset,
      affinity: position.affinity,
    );

    widget.controller.updateSelection(selection, source: ChangeSource.local);
    widget.gesturesDelegate.onLongPress(box, widget.controller.getSelectionStyle(), globalPoint);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(GesturesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}

