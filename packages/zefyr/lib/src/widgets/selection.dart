// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/util.dart';

import 'controller.dart';
import 'editable_box.dart';
import 'scope.dart';

RenderEditableBox _getEditableBox(HitTestResult result) {
  for (var entry in result.path) {
    if (entry.target is RenderEditableBox) {
      return entry.target as RenderEditableBox;
    }
  }
  return null;
}

/// Selection overlay controls selection handles and other gestures.
class ZefyrSelectionOverlay extends StatefulWidget {
  const ZefyrSelectionOverlay({Key key, @required this.controls})
      : super(key: key);

  final TextSelectionControls controls;

  @override
  ZefyrSelectionOverlayState createState() => ZefyrSelectionOverlayState();
}

class ZefyrSelectionOverlayState extends State<ZefyrSelectionOverlay>
    implements TextSelectionDelegate {
  TextSelectionControls _controls;

  TextSelectionControls get controls => _controls;

  final ClipboardStatusNotifier _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  /// Global position of last TapDown event.
  Offset _lastTapDownPosition;

  /// Global position of last TapDown which is potentially a long press.
  Offset _longPressPosition;

  OverlayState _overlay;
  OverlayEntry _toolbar;
  AnimationController _toolbarController;

  ZefyrScope _scope;

  ZefyrScope get scope => _scope;
  TextSelection _selection;
  FocusOwner _focusOwner;

  bool _didCaretTap = false;

  /// Whether selection controls should be hidden.
  bool get shouldHideControls {
    if (!_scope.mode.canSelect) return true;
    final selection = _scope.selection;
    final isSelectionCollapsed = selection == null || selection.isCollapsed;
    if (_scope.mode.canEdit) {
      return isSelectionCollapsed || _scope.focusOwner != FocusOwner.editor;
    }
    return isSelectionCollapsed;
  }

  void showToolbar() {
    final toolbarOpacity = _toolbarController.view;
    _toolbar = OverlayEntry(
      builder: (context) => FadeTransition(
        opacity: toolbarOpacity,
        child: _SelectionToolbar(
          selectionOverlay: this,
          clipboardStatus: _clipboardStatus,
        ),
      ),
    );
    _overlay.insert(_toolbar);
    _toolbarController.forward(from: 0.0);
  }

  bool get isToolbarVisible => _toolbar != null;

  bool get isToolbarHidden => _toolbar == null;

  @override
  TextEditingValue get textEditingValue =>
      _scope.controller.plainTextEditingValue;

  @override
  set textEditingValue(TextEditingValue value) {
    final cursorPosition = value.selection.extentOffset;
    final oldText = _scope.controller.document.toPlainText();
    final newText = value.text;
    final diff = fastDiff(oldText, newText, cursorPosition);
    _scope.controller.replaceText(
        diff.start, diff.deleted.length, diff.inserted,
        selection: value.selection);
  }

  @override
  void bringIntoView(ui.TextPosition position) {
    // TODO: implement bringIntoView
  }

  @override
  void hideToolbar() {
    _didCaretTap = false; // reset double tap.
    _toolbar?.remove();
    _toolbar = null;
    _toolbarController?.stop();
  }

  static const Duration _kFadeDuration = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    _controls = widget.controls;
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(ZefyrSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controls = widget.controls;
    if (pasteEnabled && _controls?.canPaste(this) == true) {
      _clipboardStatus?.update();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ZefyrScope.of(context);
    if (_scope != scope) {
      _scope?.removeListener(_handleChange);
      _scope = scope;
      _scope.addListener(_handleChange);
      _selection = _scope.selection;
      _focusOwner = _scope.focusOwner;
    }

    final overlay = Overlay.of(context, debugRequiredFor: widget);
    if (_overlay != overlay) {
      hideToolbar();
      _overlay = overlay;
      _toolbarController?.dispose();
      _toolbarController = null;
    }
    _toolbarController ??= AnimationController(
      duration: _kFadeDuration,
      vsync: _overlay,
    );

    _toolbar?.markNeedsBuild();
  }

  @override
  void dispose() {
    _scope.removeListener(_handleChange);
    hideToolbar();
    _toolbarController.dispose();
    _toolbarController = null;
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      onLongPress: _handleLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SelectionHandleDriver(
            position: _SelectionHandlePosition.base,
            selectionOverlay: this,
          ),
          SelectionHandleDriver(
            position: _SelectionHandlePosition.extent,
            selectionOverlay: this,
          ),
        ],
      ),
    );
    return Container(child: overlay);
  }

  //
  // Private members
  //

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  void _handleChange() {
    if (_selection != _scope.selection || _focusOwner != _scope.focusOwner) {
      _updateToolbar();
    }
  }

  void _updateToolbar() {
    if (!mounted) {
      return;
    }

    final selection = _scope.selection;
    final focusOwner = _scope.focusOwner;
    setState(() {
      if (shouldHideControls && isToolbarVisible) {
        hideToolbar();
      } else {
        if (_selection != selection) {
          if (selection.isCollapsed && isToolbarVisible) {
            hideToolbar();
          }
          _toolbar?.markNeedsBuild();
          if (!selection.isCollapsed && isToolbarHidden) showToolbar();
        } else {
          if (!selection.isCollapsed && isToolbarHidden) {
            showToolbar();
          } else if (isToolbarVisible) {
            _toolbar?.markNeedsBuild();
          }
        }
      }
      _selection = selection;
      _focusOwner = focusOwner;
    });
  }

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
    final result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPoint);

    RenderEditableProxyBox box = _getEditableBox(result);
    box ??= _scope.renderContext.closestBoxForGlobalPoint(globalPoint);
    if (box == null) return null;

    final localPoint = box.globalToLocal(globalPoint);
    final position = box.getPositionForOffset(localPoint);
    final selection = TextSelection.collapsed(
      offset: position.offset,
      affinity: position.affinity,
    );
    if (_didCaretTap && _selection == selection) {
      _didCaretTap = false;
      if (isToolbarVisible) {
        hideToolbar();
      } else {
        showToolbar();
      }
    } else {
      _didCaretTap = true;
    }
    _scope.controller.updateSelection(selection, source: ChangeSource.local);
  }

  void _handleLongPress() {
    final globalPoint = _longPressPosition;
    _longPressPosition = null;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPoint);
    final box = _getEditableBox(result);
    if (box == null) {
      return;
    }
    final localPoint = box.globalToLocal(globalPoint);
    final position = box.getPositionForOffset(localPoint);
    final word = box.getWordBoundary(position);
    final selection = TextSelection(
      baseOffset: word.start,
      extentOffset: word.end,
    );
    _scope.controller.updateSelection(selection, source: ChangeSource.local);
  }

  @override
  bool get copyEnabled => _scope.mode.canSelect && !_selection.isCollapsed;

  @override
  bool get cutEnabled => _scope.mode.canEdit && !_selection.isCollapsed;

  @override
  bool get pasteEnabled => _scope.mode.canEdit;

  @override
  bool get selectAllEnabled => _scope.mode.canSelect;
}

enum _SelectionHandlePosition { base, extent }

class SelectionHandleDriver extends StatefulWidget {
  const SelectionHandleDriver({
    Key key,
    @required this.position,
    @required this.selectionOverlay,
  })  : assert(selectionOverlay != null),
        super(key: key);

  final _SelectionHandlePosition position;
  final ZefyrSelectionOverlayState selectionOverlay;

  @override
  _SelectionHandleDriverState createState() => _SelectionHandleDriverState();
}

class _SelectionHandleDriverState extends State<SelectionHandleDriver>
    with SingleTickerProviderStateMixin {
  ZefyrScope _scope;

  /// Current document selection.
  TextSelection get selection => _selection;
  TextSelection _selection;

  /// Returns `true` if this handle is located at the baseOffset of selection.
  bool get isBaseHandle => widget.position == _SelectionHandlePosition.base;

  /// Character offset of this handle in the document.
  ///
  /// For base handle this equals to [TextSelection.baseOffset] and for
  /// extent handle - [TextSelection.extentOffset].
  int get documentOffset =>
      isBaseHandle ? selection.baseOffset : selection.extentOffset;

  List<TextSelectionPoint> getEndpointsForSelection(RenderEditableBox block) {
    if (block == null) return null;

    final paintOffset = Offset.zero;
    final boxes = block.getEndpointsForSelection(selection);
    if (boxes.isEmpty) return null;
    final start = Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
    final end = Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
    return <TextSelectionPoint>[
      TextSelectionPoint(start, boxes.first.direction),
      TextSelectionPoint(end, boxes.last.direction),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ZefyrScope.of(context);
    if (_scope != scope) {
      _scope?.removeListener(_handleScopeChange);
      _scope = scope;
      _scope.addListener(_handleScopeChange);
    }
    _selection = _scope.selection;
  }

  @override
  void dispose() {
    _scope?.removeListener(_handleScopeChange);
    super.dispose();
  }

  //
  // Overridden members
  //

  @override
  Widget build(BuildContext context) {
    if (widget.selectionOverlay.shouldHideControls) {
      return Container();
    }
    final block = _scope.renderContext.boxForTextOffset(documentOffset);
    if (block == null) {
      // TODO: For some reason sometimes we get updates when render boxes
      //      are in process of rebuilding so we don't have access to them here.
      //      As a workaround we just return empty container. There is usually
      //      another rebuild right after this one which "fixes" the view.
      //      Example: when toolbar button is toggled changing style of current
      //      selection.
      return Container();
    }

    final endpoints = getEndpointsForSelection(block);
    if (endpoints == null || endpoints.isEmpty) return Container();

    Offset point;
    TextSelectionHandleType type;

    // we invert base / extend if the selection is from bottom to top
    var pos = widget.position;
    if (selection.baseOffset > selection.extentOffset) {
      pos = pos == _SelectionHandlePosition.base
          ? _SelectionHandlePosition.extent
          : _SelectionHandlePosition.base;
    }

    switch (pos) {
      case _SelectionHandlePosition.base:
        point = endpoints[0].point;
        type = _chooseType(endpoints[0], TextSelectionHandleType.left,
            TextSelectionHandleType.right);
        break;
      case _SelectionHandlePosition.extent:
        // [endpoints] will only contain 1 point for collapsed selections, in
        // which case we shouldn't be building the [end] handle.
        assert(endpoints.length == 2);
        point = endpoints[1].point;
        type = _chooseType(endpoints[1], TextSelectionHandleType.right,
            TextSelectionHandleType.left);
        break;
    }

    final viewport = block.size;
    point = Offset(
      point.dx.clamp(0.0, viewport.width),
      point.dy.clamp(0.0, viewport.height),
    );

    final handleAnchor = widget.selectionOverlay.controls.getHandleAnchor(
      type,
      block.preferredLineHeight,
    );
    final handleSize = widget.selectionOverlay.controls.getHandleSize(
      block.preferredLineHeight,
    );
    final handleRect = Rect.fromLTWH(
      // Put handleAnchor on top of point
      point.dx - handleAnchor.dx,
      point.dy - handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveDimension / 2),
    );
    final padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: block.layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: Container(
        alignment: Alignment.topLeft,
        width: interactiveRect.width,
        height: interactiveRect.height,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          dragStartBehavior: DragStartBehavior.start,
          onPanStart: _handleDragStart,
          onPanUpdate: _handleDragUpdate,
          child: Padding(
            padding: EdgeInsets.only(
              left: padding.left,
              top: padding.top,
              right: padding.right,
              bottom: padding.bottom,
            ),
            child: widget.selectionOverlay.controls.buildHandle(
              context,
              type,
              block.preferredLineHeight,
            ),
          ),
        ),
      ),
    );
  }

  //
  // Private members
  //

  TextSelectionHandleType _chooseType(
    TextSelectionPoint endpoint,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (selection.isCollapsed) return TextSelectionHandleType.collapsed;

    assert(endpoint.direction != null);
    switch (endpoint.direction) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
    return null;
  }

  Offset _dragPosition;
  RenderEditableBox _dragCurrentParagraph;

  void _handleScopeChange() {
    if (_selection != _scope.selection) {
      setState(() {
        _selection = _scope.selection;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragCurrentParagraph =
        _scope.renderContext.boxForTextOffset(documentOffset);
    _dragPosition = Platform.isAndroid
        ? details.globalPosition -
            Offset(
                0,
                widget.selectionOverlay.controls
                    .getHandleSize(_dragCurrentParagraph.preferredLineHeight)
                    .height)
        : details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final localPoint = _getLocalPointFromDragDetails(details);
    final position = _dragCurrentParagraph.getPositionForOffset(localPoint);
    final newSelection = selection.copyWith(
      baseOffset: isBaseHandle ? position.offset : selection.baseOffset,
      extentOffset: isBaseHandle ? selection.extentOffset : position.offset,
    );

    if (newSelection.baseOffset >= newSelection.extentOffset) {
      // Don't allow reversed or collapsed selection.
      return;
    }

    if (newSelection != _selection) {
      _scope.updateSelection(newSelection, source: ChangeSource.local);
    }
  }

  Offset _getLocalPointFromDragDetails(DragUpdateDetails details) {
    // Keep track of the handle size adjusted position (Android only)
    _dragPosition += details.delta;
    RenderEditableBox paragraph =
        _scope.renderContext.boxForGlobalPoint(_dragPosition);
    // When dragging outside a paragraph, user expects dragging to
    // capture horizontal component of movement
    if (paragraph == null) {
      paragraph = _dragCurrentParagraph;
      var effectiveGlobalPoint = paragraph.localToGlobal(Offset.zero);
      if (_dragPosition.dy > paragraph.localToGlobal(Offset.zero).dy) {
        effectiveGlobalPoint = Offset(
            _dragPosition.dx, effectiveGlobalPoint.dy + paragraph.size.height);
      }
      if (_dragPosition.dy < paragraph.localToGlobal(Offset.zero).dy) {
        effectiveGlobalPoint =
            Offset(_dragPosition.dx, effectiveGlobalPoint.dy);
      }
      return paragraph.globalToLocal(effectiveGlobalPoint);
    }
    _dragCurrentParagraph = paragraph;
    return paragraph.globalToLocal(_dragPosition);
  }
}

class _SelectionToolbar extends StatefulWidget {
  const _SelectionToolbar({
    Key key,
    @required this.selectionOverlay,
    @required this.clipboardStatus,
  }) : super(key: key);

  final ZefyrSelectionOverlayState selectionOverlay;
  final ClipboardStatusNotifier clipboardStatus;

  @override
  _SelectionToolbarState createState() => _SelectionToolbarState();
}

class _SelectionToolbarState extends State<_SelectionToolbar> {
  TextSelectionControls get controls => widget.selectionOverlay.controls;

  ZefyrScope get scope => widget.selectionOverlay.scope;

  TextSelection get selection =>
      widget.selectionOverlay.textEditingValue.selection;

  @override
  Widget build(BuildContext context) {
    return _buildToolbar(context);
  }

  Widget _buildToolbar(BuildContext context) {
    final base = selection.baseOffset;
    final block = scope.renderContext.boxForTextOffset(base);
    if (block == null) {
      return Container();
    }
    final boxes = block.getEndpointsForSelection(selection);
    if (boxes.isEmpty) {
      return Container();
    }

    // Find the horizontal midpoint, just above the selected text.
    var midpoint = Offset(
      (boxes.length == 1)
          ? (boxes[0].start + boxes[0].end) / 2.0
          : (boxes[0].start + boxes[1].start) / 2.0,
      boxes[0].bottom - block.preferredLineHeight,
    );
    List<TextSelectionPoint> endpoints;
    if (boxes.length == 1) {
      midpoint = Offset((boxes[0].start + boxes[0].end) / 2.0,
          boxes[0].bottom - block.preferredLineHeight);
      final start = Offset(boxes[0].start, block.preferredLineHeight);
      endpoints = <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      midpoint = Offset((boxes[0].start + boxes[1].start) / 2.0,
          boxes[0].bottom - block.preferredLineHeight);
      final start = Offset(boxes.first.start, boxes.first.bottom);
      final end = Offset(boxes.last.end, boxes.last.bottom);
      endpoints = <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }

    final editingRegion = Rect.fromPoints(
      block.localToGlobal(Offset.zero),
      block.localToGlobal(block.size.bottomRight(Offset.zero)),
    );

    final toolbar = controls.buildToolbar(
      context,
      editingRegion,
      block.preferredLineHeight,
      midpoint,
      endpoints,
      widget.selectionOverlay,
      widget.clipboardStatus,
    );
    return CompositedTransformFollower(
      link: block.layerLink,
      showWhenUnlinked: false,
      offset: -editingRegion.topLeft,
      child: toolbar,
    );
  }
}
