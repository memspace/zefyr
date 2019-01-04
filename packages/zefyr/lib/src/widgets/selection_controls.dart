// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'cupertino/selection_controls.dart';
import 'editable_text.dart';
import 'material/selection_controls.dart';
import 'scope.dart';
import 'selection_toolbar.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;

abstract class ZefyrSelectionControls {
  Widget buildToolbar(BuildContext context, ZefyrScope scope);

  /// Whether the current selection of the document managed by the given
  /// [scope] can be removed and placed into the [Clipboard].
  ///
  /// Returns `false` if the document is managed by a read-only [ZefyrView].
  /// If provided [scope] represents an editable view like [ZefyrEditor]
  /// then returns `true` if the editable is enabled and current selection is
  /// collapsed.
  bool canCut(ZefyrScope scope) {
    return scope.isEditable &&
        scope.mode == ZefyrMode.edit &&
        !scope.selection.isCollapsed;
  }

  /// Whether the current selection of the document managed by the given
  /// [scope] can be copied to the [Clipboard].
  ///
  /// By default, false is returned when nothing is selected in the text field.
  bool canCopy(ZefyrScope scope) {
    return !scope.selection.isCollapsed;
  }

  /// Whether the current [Clipboard] content can be pasted into the document
  /// managed by the given [scope].
  bool canPaste(ZefyrScope scope) {
    // TODO: return false when clipboard is empty (prevented by async nature)
    return scope.isEditable && scope.mode == ZefyrMode.edit;
  }

  /// Whether the current selection of the document managed by the given
  /// [scope] can be extended to include the entire content of the document.
  bool canSelectAll(ZefyrScope scope) {
    return scope.isEditable &&
        scope.mode != ZefyrMode.view &&
        scope.controller.document.length > 1 &&
        scope.selection.isCollapsed;
  }

  /// Copy the current selection of the document managed by the given
  /// [scope] to the [Clipboard]. Then, remove the selected text from the
  /// document.
  void handleCut(ZefyrScope scope) {
    final String value = scope.controller.document.toPlainText();
    Clipboard.setData(ClipboardData(
      text: scope.selection.textInside(value),
    ));
    scope.controller.replaceText(
      scope.selection.start,
      scope.selection.end - scope.selection.start,
      '',
      selection: TextSelection.collapsed(offset: scope.selection.start),
    );
    // No need to explicitly hide selection toolbar here as it will be
    // hidden by the selection overlay as a reaction to this document change.
  }

  /// Copy the current selection of the document managed by the given
  /// [scope] to the [Clipboard]. Then, move the cursor to the end of the
  /// text (collapsing the selection in the process).
  void handleCopy(ZefyrScope scope) {
    final String value = scope.controller.document.toPlainText();
    Clipboard.setData(ClipboardData(
      text: scope.selection.textInside(value),
    ));
    scope.updateSelection(TextSelection.collapsed(offset: scope.selection.end),
        source: ChangeSource.local);
    // No need to explicitly hide selection toolbar here as it will be
    // hidden by the selection overlay as a reaction to this change.
  }

  /// Paste the current clipboard selection (obtained from [Clipboard]) into
  /// the document managed by the given [scope], replacing its current
  /// selection, if any.
  ///
  /// This function is asynchronous since interacting with the clipboard is
  /// asynchronous. Race conditions may exist with this API as currently
  /// implemented.
  Future<void> handlePaste(ZefyrScope scope) async {
    final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      final length = scope.selection.end - scope.selection.start;
      scope.controller.replaceText(scope.selection.start, length, data.text,
          selection: TextSelection.collapsed(
              offset: scope.selection.start + data.text.length));
    }
    // No need to explicitly hide selection toolbar here as it will be
    // hidden by the selection overlay as a reaction to this change.
  }

  /// Adjust the selection of the document managed by the given [scope] so
  /// that everything is selected.
  void handleSelectAll(ZefyrScope scope) {
    scope.controller.updateSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: scope.controller.document.length,
      ),
      source: ChangeSource.local,
    );
  }
}

class DefaultZefyrSelectionControls extends ZefyrSelectionControls {
  final double toolbarElevation;
  final Color toolbarColor;
  final Color textColor;

  DefaultZefyrSelectionControls({
    double toolbarElevation,
    Color toolbarColor,
    Color textColor,
  })  : toolbarElevation = toolbarElevation ?? 0.0,
        toolbarColor = toolbarColor ?? Colors.grey.shade900,
        textColor = textColor ?? Colors.white;

  @override
  Widget buildToolbar(BuildContext context, ZefyrScope scope) {
    return ZefyrTextSelectionToolbar(
      elevation: toolbarElevation,
      color: toolbarColor,
      textColor: textColor,
      handleCut: canCut(scope) ? () => handleCut(scope) : null,
      handleCopy: canCopy(scope) ? () => handleCopy(scope) : null,
      handlePaste: canPaste(scope) ? () => handlePaste(scope) : null,
      handleSelectAll:
          canSelectAll(scope) ? () => handleSelectAll(scope) : null,
    );
  }
}

class ZefyrSelectionControlsAdapter extends TextSelectionControls {
  ZefyrSelectionControlsAdapter(
      {ZefyrScope scope, ZefyrSelectionControls controls})
      : _scope = scope,
        _controls = controls;

  ZefyrScope _scope;
  set scope(ZefyrScope value) {
    assert(value != null);
    if (_scope != value) {
      _scope = value;
    }
  }

  ZefyrSelectionControls _controls;
  ZefyrSelectionControls get controls => _controls;
  set controls(ZefyrSelectionControls value) {
    assert(value != null);
    if (_controls != value) {
      _controls = value;
    }
  }

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight) {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS) {
      return CupertinoTextSelectionHandle(
        type: type,
        textLineHeight: textLineHeight,
      );
    } else {
      return MaterialTextSelectionHandle(type: type);
    }
  }

  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion,
      Offset position, TextSelectionDelegate delegate) {
    assert(debugCheckHasMediaQuery(context));
    return ConstrainedBox(
        constraints: BoxConstraints.tight(globalEditableRegion.size),
        child: CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            MediaQuery.of(context).size,
            globalEditableRegion,
            position,
          ),
          child: _controls.buildToolbar(context, _scope),
        ));
  }

  @override
  Size get handleSize => Size(MaterialTextSelectionHandle.kHandleSize,
      MaterialTextSelectionHandle.kHandleSize);
}

/// Centers the toolbar around the given position, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(
      this.screenSize, this.globalEditableRegion, this.position);

  /// The size of the screen at the time that the toolbar was last laid out.
  final Size screenSize;

  /// Size and position of the editing region at the time the toolbar was last
  /// laid out, in global coordinates.
  final Rect globalEditableRegion;

  /// Anchor position of the toolbar, relative to the top left of the
  /// [globalEditableRegion].
  final Offset position;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final Offset globalPosition = globalEditableRegion.topLeft + position;

    double x = globalPosition.dx - childSize.width / 2.0;
    double y = globalPosition.dy - childSize.height - 10.0;

    if (x < _kToolbarScreenPadding)
      x = _kToolbarScreenPadding;
    else if (x + childSize.width > screenSize.width - _kToolbarScreenPadding)
      x = screenSize.width - childSize.width - _kToolbarScreenPadding;

    if (y < _kToolbarScreenPadding)
      y = _kToolbarScreenPadding;
    else if (y + childSize.height > screenSize.height - _kToolbarScreenPadding)
      y = screenSize.height - childSize.height - _kToolbarScreenPadding;

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return position != oldDelegate.position;
  }
}
