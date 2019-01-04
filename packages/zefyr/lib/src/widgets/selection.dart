// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/util.dart';

import 'controller.dart';
import 'editable_box.dart';
import 'editable_text.dart';
import 'scope.dart';
import 'selection_controls.dart';

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

  final ZefyrSelectionControls controls;

  @override
  _ZefyrSelectionOverlayState createState() =>
      new _ZefyrSelectionOverlayState();
}

class _ZefyrSelectionOverlayState extends State<ZefyrSelectionOverlay>
    implements TextSelectionDelegate {
  ZefyrSelectionControlsAdapter _controls;
  ZefyrSelectionControlsAdapter get controls => _controls;

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
    if (_scope.mode == ZefyrMode.view) return true;
    final selection = _scope.selection;
    final collapsedSelection = selection == null || selection.isCollapsed;
    if (_scope.mode == ZefyrMode.select) return collapsedSelection;
    return collapsedSelection || _scope.focusOwner != FocusOwner.editor;
  }

  void showToolbar() {
    final toolbarOpacity = _toolbarController.view;
    _toolbar = OverlayEntry(
      builder: (context) => FadeTransition(
            opacity: toolbarOpacity,
            child: _SelectionToolbar(selectionOverlay: this),
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

  static const Duration _kFadeDuration = const Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    _controls = ZefyrSelectionControlsAdapter(
      controls: widget.controls ?? DefaultZefyrSelectionControls(),
    );
  }

  @override
  void didUpdateWidget(ZefyrSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controls.controls = oldWidget.controls ?? DefaultZefyrSelectionControls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final editor = ZefyrScope.of(context);
    if (_scope != editor) {
      _scope?.removeListener(_handleChange);
      _scope = editor;
      _scope.addListener(_handleChange);
      _selection = _scope.selection;
      _focusOwner = _scope.focusOwner;
      _controls.scope = _scope;
    }
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    if (_overlay != overlay) {
      hideToolbar();
      _overlay = overlay;
      _toolbarController?.dispose();
      _toolbarController = null;
    }
    if (_toolbarController == null) {
      _toolbarController = AnimationController(
        duration: _kFadeDuration,
        vsync: _overlay,
      );
    }

    _toolbar?.markNeedsBuild();
  }

  @override
  void dispose() {
    _scope.removeListener(_handleChange);
    hideToolbar();
    _toolbarController.dispose();
    _toolbarController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlay = new GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      onTap: _handleTap,
      onTapCancel: _handleTapCancel,
      onLongPress: _handleLongPress,
      child: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new SelectionHandleDriver(
            position: _SelectionHandlePosition.base,
            selectionOverlay: this,
          ),
          new SelectionHandleDriver(
            position: _SelectionHandlePosition.extent,
            selectionOverlay: this,
          ),
        ],
      ),
    );
    return new Container(child: overlay);
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
    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPoint);

    RenderEditableProxyBox box = _getEditableBox(result);
    if (box == null) {
      box = _scope.renderContext.closestBoxForGlobalPoint(globalPoint);
    }
    if (box == null) return null;

    final localPoint = box.globalToLocal(globalPoint);
    final position = box.getPositionForOffset(localPoint);
    final selection = new TextSelection.collapsed(
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
    final word = box.getWordBoundary(position);
    final selection = new TextSelection(
      baseOffset: word.start,
      extentOffset: word.end,
    );
    _scope.controller.updateSelection(selection, source: ChangeSource.local);
  }
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
  final _ZefyrSelectionOverlayState selectionOverlay;

  @override
  _SelectionHandleDriverState createState() =>
      new _SelectionHandleDriverState();
}

class _SelectionHandleDriverState extends State<SelectionHandleDriver> {
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

  /// Position in pixels of this selection handle within its paragraph [block].
  Offset getPosition(RenderEditableBox block) {
    if (block == null) return null;

    final localSelection = block.getLocalSelection(selection);
    assert(localSelection != null);

    final boxes = block.getEndpointsForSelection(selection);
    assert(boxes.isNotEmpty, 'Got empty boxes for selection ${selection}');

    final box = isBaseHandle ? boxes.first : boxes.last;
    final dx = isBaseHandle ? box.start : box.end;
    return new Offset(dx, box.bottom);
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

  @override
  Widget build(BuildContext context) {
    if (widget.selectionOverlay.shouldHideControls) {
      return new Container();
    }
    final block = _scope.renderContext.boxForTextOffset(documentOffset);
    final position = getPosition(block);
    Widget handle;
    if (position == null) {
      handle = new Container();
    } else {
      final handleType = isBaseHandle
          ? TextSelectionHandleType.left
          : TextSelectionHandleType.right;
      handle = new Positioned(
        left: position.dx,
        top: position.dy,
        child: widget.selectionOverlay.controls.buildHandle(
          context,
          handleType,
          block.preferredLineHeight,
        ),
      );
      handle = new CompositedTransformFollower(
        link: block.layerLink,
        showWhenUnlinked: false,
        child: new Stack(
          overflow: Overflow.visible,
          children: <Widget>[handle],
        ),
      );
    }
    // Always return this gesture detector even if handle is an empty container
    // This way we prevent drag gesture from being canceled in case current
    // position is somewhere outside of any visible paragraph block.
    return new GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      child: handle,
    );
  }

  //
  // Private members
  //

  Offset _dragPosition;

  void _handleScopeChange() {
    if (_selection != _scope.selection) {
      setState(() {
        _selection = _scope.selection;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final globalPoint = _dragPosition;
    final paragraph = _scope.renderContext.boxForGlobalPoint(globalPoint);
    if (paragraph == null) {
      return;
    }

    final localPoint = paragraph.globalToLocal(globalPoint);
    final position = paragraph.getPositionForOffset(localPoint);
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
}

class _SelectionToolbar extends StatefulWidget {
  const _SelectionToolbar({
    Key key,
    @required this.selectionOverlay,
  }) : super(key: key);

  final _ZefyrSelectionOverlayState selectionOverlay;

  @override
  _SelectionToolbarState createState() => new _SelectionToolbarState();
}

class _SelectionToolbarState extends State<_SelectionToolbar> {
  ZefyrSelectionControlsAdapter get controls =>
      widget.selectionOverlay.controls;
  ZefyrScope get scope => widget.selectionOverlay.scope;
  TextSelection get selection =>
      widget.selectionOverlay.textEditingValue.selection;

  @override
  Widget build(BuildContext context) {
    final base = selection.baseOffset;
    final block = scope.renderContext.boxForTextOffset(base);
    if (block == null) {
      return Container();
    }
    final boxes = block.getEndpointsForSelection(selection);
    // Find the horizontal midpoint, just above the selected text.
    final Offset midpoint = new Offset(
      (boxes.length == 1)
          ? (boxes[0].start + boxes[0].end) / 2.0
          : (boxes[0].start + boxes[1].start) / 2.0,
      boxes[0].bottom - block.preferredLineHeight,
    );

    final Rect editingRegion = new Rect.fromPoints(
      block.localToGlobal(Offset.zero),
      block.localToGlobal(block.size.bottomRight(Offset.zero)),
    );
    final toolbar = controls.buildToolbar(
        context, editingRegion, midpoint, widget.selectionOverlay);
    return new CompositedTransformFollower(
      link: block.layerLink,
      showWhenUnlinked: false,
      offset: -editingRegion.topLeft,
      child: toolbar,
    );
  }
}
