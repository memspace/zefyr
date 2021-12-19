import 'dart:async';

import 'package:flutter/widgets.dart';

// The time it takes for the cursor to fade from fully opaque to fully
// transparent and vice versa. A full cursor blink, from transparent to opaque
// to transparent, is twice this duration.
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);

// The time the cursor is static in opacity before animating to become
// transparent.
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

/// Style properties of editing cursor.
class CursorStyle {
  /// The color to use when painting the cursor.
  ///
  /// Cannot be null.
  final Color color;

  /// The color to use when painting the background cursor aligned with the text
  /// while rendering the floating cursor.
  ///
  /// Cannot be null. By default it is the disabled grey color from
  /// CupertinoColors.
  final Color backgroundColor;

  /// How thick the cursor will be.
  ///
  /// Defaults to 1.0
  ///
  /// The cursor will draw under the text. The cursor width will extend
  /// to the right of the boundary between characters for left-to-right text
  /// and to the left for right-to-left text. This corresponds to extending
  /// downstream relative to the selected position. Negative values may be used
  /// to reverse this behavior.
  final double width;

  /// How tall the cursor will be.
  ///
  /// By default, the cursor height is set to the preferred line height of the
  /// text.
  final double? height;

  /// How rounded the corners of the cursor should be.
  ///
  /// By default, the cursor has no radius.
  final Radius? radius;

  /// The offset that is used, in pixels, when painting the cursor on screen.
  ///
  /// By default, the cursor position should be set to an offset of
  /// (-[cursorWidth] * 0.5, 0.0) on iOS platforms and (0, 0) on Android
  /// platforms. The origin from where the offset is applied to is the arbitrary
  /// location where the cursor ends up being rendered from by default.
  final Offset? offset;

  /// Whether the cursor will animate from fully transparent to fully opaque
  /// during each cursor blink.
  ///
  /// By default, the cursor opacity will animate on iOS platforms and will not
  /// animate on Android platforms.
  final bool opacityAnimates;

  /// If the cursor should be painted on top of the text or underneath it.
  ///
  /// By default, the cursor should be painted on top for iOS platforms and
  /// underneath for Android platforms.
  final bool paintAboveText;

  const CursorStyle({
    required this.color,
    required this.backgroundColor,
    this.width = 1.0,
    this.height,
    this.radius,
    this.offset,
    this.opacityAnimates = false,
    this.paintAboveText = false,
  });

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! CursorStyle) return false;
    return other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.width == width &&
        other.height == height &&
        other.radius == radius &&
        other.offset == offset &&
        other.opacityAnimates == opacityAnimates &&
        other.paintAboveText == paintAboveText;
  }

  @override
  int get hashCode => hashValues(color, backgroundColor, width, height, radius,
      offset, opacityAnimates, paintAboveText);
}

/// Controls cursor of an editable widget.
///
/// This class is a [ChangeNotifier] and allows to listen for updates on the
/// cursor [style].
class CursorController extends ChangeNotifier {
  CursorController({
    required this.showCursor,
    required CursorStyle style,
    required TickerProvider tickerProvider,
  })  : _style = style,
        _cursorBlink = ValueNotifier(false),
        _cursorColor = ValueNotifier(style.color) {
    _cursorBlinkOpacityController =
        AnimationController(vsync: tickerProvider, duration: _fadeDuration);
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
  }

  // This value is an eyeball estimation of the time it takes for the iOS cursor
  // to ease in and out.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  final ValueNotifier<bool> showCursor;

  Timer? _cursorTimer;
  bool _targetCursorVisibility = false;
  late AnimationController _cursorBlinkOpacityController;

  ValueNotifier<bool> get cursorBlink => _cursorBlink;
  final ValueNotifier<bool> _cursorBlink;

  ValueNotifier<Color> get cursorColor => _cursorColor;
  final ValueNotifier<Color> _cursorColor;

  final ValueNotifier<TextPosition?> _floatingCursorTextPosition =
      ValueNotifier(null);

  ValueNotifier<TextPosition?> get floatingCursorTextPosition =>
      _floatingCursorTextPosition;

  void setFloatingCursorTextPosition(TextPosition? position) =>
      _floatingCursorTextPosition.value = position;

  bool get isFloatingCursorActive => floatingCursorTextPosition.value != null;

  CursorStyle get style => _style;
  CursorStyle _style;

  set style(CursorStyle value) {
    if (_style == value) return;
    _style = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    stopCursorTimer();
    _cursorBlinkOpacityController.dispose();
    assert(_cursorTimer == null);
    super.dispose();
  }

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (style.opacityAnimates) {
      // If we want to show the cursor, we will animate the opacity to the value
      // of 1.0, and likewise if we want to make it disappear, to 0.0. An easing
      // curve is used for the animation to mimic the aesthetics of the native
      // iOS cursor.
      //
      // These values and curves have been obtained through eyeballing, so are
      // likely not exactly the same as the values for native iOS.
      _cursorBlinkOpacityController.animateTo(targetOpacity,
          curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController.value = targetOpacity;
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void startCursorTimer() {
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController.value = 1.0;

    if (style.opacityAnimates) {
      _cursorTimer =
          Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void stopCursorTimer({bool resetCharTicks = true}) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController.value = 0.0;

    if (style.opacityAnimates) {
      _cursorBlinkOpacityController.stop();
      _cursorBlinkOpacityController.value = 0.0;
    }
  }

  void startOrStopCursorTimerIfNeeded(bool hasFocus, TextSelection selection) {
    if (showCursor.value &&
        _cursorTimer == null &&
        hasFocus &&
        selection.isCollapsed) {
      startCursorTimer();
    } else if (_cursorTimer != null && (!hasFocus || !selection.isCollapsed)) {
      stopCursorTimer();
    }
  }

  void _onCursorColorTick() {
    _cursorColor.value =
        _style.color.withOpacity(_cursorBlinkOpacityController.value);
    cursorBlink.value =
        showCursor.value && _cursorBlinkOpacityController.value > 0;
  }
}
