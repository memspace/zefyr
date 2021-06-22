// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A box in which a single widget can be scrolled.
/// Very similar to [SingleChildScrollView] expect it takes a [ViewportBuilder]
/// instead of [Widget] child as parameter
class ZefyrSingleChildScrollView extends StatelessWidget {
  /// Creates a box in which a single widget can be scrolled.
  const ZefyrSingleChildScrollView({
    Key? key,
    this.padding,
    bool? primary,
    this.controller,
    this.physics,
    this.dragStartBehavior = DragStartBehavior.start,
    this.clipBehavior = Clip.hardEdge,
    required this.viewportBuilder,
    this.restorationId,
  })  : assert(
            !(controller != null && primary == true),
            'Primary ScrollViews obtain their ScrollController via inheritance from a PrimaryScrollController widget. '
            'You cannot both set primary to true and pass an explicit controller.'),
        primary = primary ?? controller == null,
        super(key: key);

  /// The amount of space by which to inset the child.
  final EdgeInsetsGeometry? padding;

  final ScrollPhysics? physics;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController? controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// When true, the scroll view is used for default [ScrollAction]s. If a
  /// ScrollAction is not handled by an otherwise focused part of the application,
  /// the ScrollAction will be evaluated using this scroll view, for example,
  /// when executing [Shortcuts] key events like page up and down.
  ///
  /// On iOS, this identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is vertical and [controller] is
  /// not specified.
  final bool primary;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// {@macro flutter.widgets.scrollable.restorationId}
  final String? restorationId;

  final ViewportBuilder viewportBuilder;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
        context, Axis.vertical, false);
  }

  @override
  Widget build(BuildContext context) {
    final scrollController =
        primary ? PrimaryScrollController.of(context) : controller;
    final scrollable = Scrollable(
      dragStartBehavior: dragStartBehavior,
      axisDirection: AxisDirection.down,
      physics: physics,
      controller: scrollController,
      restorationId: restorationId,
      viewportBuilder: (BuildContext context, ViewportOffset offset) {
        var contents = viewportBuilder(context, offset);
        if (padding != null)
          contents = Padding(padding: padding!, child: contents);
        return _SingleChildViewport(
            offset: offset,
            clipBehavior: clipBehavior,
            child: contents);
      },
    );
    return primary && scrollController != null
        ? PrimaryScrollController.none(child: scrollable)
        : scrollable;
  }
}

class _SingleChildViewport extends SingleChildRenderObjectWidget {
  const _SingleChildViewport({
    Key? key,
    required this.offset,
    Widget? child,
    required this.clipBehavior,
  }) : super(key: key, child: child);

  final ViewportOffset offset;
  final Clip clipBehavior;

  @override
  _RenderSingleChildViewport createRenderObject(BuildContext context) {
    return _RenderSingleChildViewport(
      offset: offset,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderSingleChildViewport renderObject) {
    // Order dependency: The offset setter reads the axis direction.
    renderObject
      ..offset = offset
      ..clipBehavior = clipBehavior;
  }
}

class _RenderSingleChildViewport extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>
    implements RenderAbstractViewport {
  _RenderSingleChildViewport({
    required ViewportOffset offset,
    double cacheExtent = RenderAbstractViewport.defaultCacheExtent,
    RenderBox? child,
    required Clip clipBehavior,
  })  :_offset = offset,
        _cacheExtent = cacheExtent,
        _clipBehavior = clipBehavior {
    this.child = child;
  }

  Axis get axis => axisDirectionToAxis(AxisDirection.down);

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;

  set offset(ViewportOffset value) {
    if (value == _offset) return;
    if (attached) _offset.removeListener(_hasScrolled);
    _offset = value;
    if (attached) _offset.addListener(_hasScrolled);
    markNeedsLayout();
  }

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  double get cacheExtent => _cacheExtent;
  double _cacheExtent;

  set cacheExtent(double value) {
    if (value == _cacheExtent) return;
    _cacheExtent = value;
    markNeedsLayout();
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  void _hasScrolled() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    // We don't actually use the offset argument in BoxParentData, so let's
    // avoid allocating it at all.
    if (child.parentData is! ParentData) child.parentData = ParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  double get _viewportExtent {
    assert(hasSize);
    switch (axis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  double get _minScrollExtent {
    assert(hasSize);
    return 0.0;
  }

  double get _maxScrollExtent {
    assert(hasSize);
    if (child == null) return 0.0;
    switch (axis) {
      case Axis.horizontal:
        return math.max(0.0, child!.size.width - size.width);
      case Axis.vertical:
        return math.max(0.0, child!.size.height - size.height);
    }
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    switch (axis) {
      case Axis.horizontal:
        return constraints.heightConstraints();
      case Axis.vertical:
        return constraints.widthConstraints();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) return child!.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) return child!.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) return child!.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) return child!.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  // We don't override computeDistanceToActualBaseline(), because we
  // want the default behavior (returning null). Otherwise, as you
  // scroll, it would shift in its parent if the parent was baseline-aligned,
  // which makes no sense.

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child == null) {
      return constraints.smallest;
    }
    final childSize = child!.getDryLayout(_getInnerConstraints(constraints));
    return constraints.constrain(childSize);
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child!.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child!.size);
    }

    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(_minScrollExtent, _maxScrollExtent);
  }

  Offset get _paintOffset => _paintOffsetForPosition(offset.pixels);

  Offset _paintOffsetForPosition(double position) {
    return Offset(0.0, -position);
  }

  bool _shouldClipAtPaintOffset(Offset paintOffset) {
    assert(child != null);
    return paintOffset.dx < 0 ||
        paintOffset.dy < 0 ||
        paintOffset.dx + child!.size.width > size.width ||
        paintOffset.dy + child!.size.height > size.height;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final paintOffset = _paintOffset;

      void paintContents(PaintingContext context, Offset offset) {
        context.paintChild(child!, offset + paintOffset);
      }

      if (_shouldClipAtPaintOffset(paintOffset) && clipBehavior != Clip.none) {
        _clipRectLayer = context.pushClipRect(
            needsCompositing, offset, Offset.zero & size, paintContents,
            clipBehavior: clipBehavior, oldLayer: _clipRectLayer);
      } else {
        _clipRectLayer = null;
        paintContents(context, offset);
      }
    }
  }

  ClipRectLayer? _clipRectLayer;

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final paintOffset = _paintOffset;
    transform.translate(paintOffset.dx, paintOffset.dy);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject? child) {
    if (child != null && _shouldClipAtPaintOffset(_paintOffset)) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      return result.addWithPaintOffset(
        offset: _paintOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          assert(transformed == position + -_paintOffset);
          return child!.hitTest(result, position: transformed!);
        },
      );
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect? rect}) {
    rect ??= target.paintBounds;
    if (target is! RenderBox) {
      return RevealedOffset(offset: offset.pixels, rect: rect);
    }

    final targetBox = target;
    final transform = targetBox.getTransformTo(child);
    final bounds = MatrixUtils.transformRect(transform, rect);

    final double leadingScrollOffset;
    final double targetMainAxisExtent;
    final double mainAxisExtent;

    mainAxisExtent = size.height;
    leadingScrollOffset = bounds.top;
    targetMainAxisExtent = bounds.height;

    final targetOffset = leadingScrollOffset -
        (mainAxisExtent - targetMainAxisExtent) * alignment;
    final targetRect = bounds.shift(_paintOffsetForPosition(targetOffset));
    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }

    final newRect = RenderViewportBase.showInViewport(
      descendant: descendant,
      viewport: this,
      offset: offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }

  @override
  Rect describeSemanticsClip(RenderObject child) {
    switch (axis) {
      case Axis.vertical:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - cacheExtent,
          semanticBounds.right,
          semanticBounds.bottom + cacheExtent,
        );
      case Axis.horizontal:
        return Rect.fromLTRB(
          semanticBounds.left - cacheExtent,
          semanticBounds.top,
          semanticBounds.right + cacheExtent,
          semanticBounds.bottom,
        );
    }
  }
}
