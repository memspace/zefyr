import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ZefyrPressedKeys extends ChangeNotifier {
  static ZefyrPressedKeys of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_ZefyrPressedKeysAccess>();
    return widget!.pressedKeys;
  }

  bool _metaPressed = false;
  bool _controlPressed = false;

  /// Whether meta key is currently pressed.
  bool get metaPressed => _metaPressed;

  /// Whether control key is currently pressed.
  bool get controlPressed => _controlPressed;

  void _updatePressedKeys(Set<LogicalKeyboardKey> pressedKeys) {
    final meta = pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
    final control = pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
    if (_metaPressed != meta || _controlPressed != control) {
      _metaPressed = meta;
      _controlPressed = control;
      notifyListeners();
    }
  }
}

class ZefyrKeyboardListener extends StatefulWidget {
  final Widget child;
  const ZefyrKeyboardListener({Key? key, required this.child})
      : super(key: key);

  @override
  ZefyrKeyboardListenerState createState() => ZefyrKeyboardListenerState();
}

class ZefyrKeyboardListenerState extends State<ZefyrKeyboardListener> {
  final ZefyrPressedKeys _pressedKeys = ZefyrPressedKeys();

  bool _keyEvent(KeyEvent event) {
    _pressedKeys
        ._updatePressedKeys(HardwareKeyboard.instance.logicalKeysPressed);
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_keyEvent);
    _pressedKeys
        ._updatePressedKeys(HardwareKeyboard.instance.logicalKeysPressed);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyEvent);
    _pressedKeys.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ZefyrPressedKeysAccess(
      pressedKeys: _pressedKeys,
      child: widget.child,
    );
  }
}

class _ZefyrPressedKeysAccess extends InheritedWidget {
  final ZefyrPressedKeys pressedKeys;
  const _ZefyrPressedKeysAccess({
    Key? key,
    required this.pressedKeys,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant _ZefyrPressedKeysAccess oldWidget) {
    return oldWidget.pressedKeys != pressedKeys;
  }
}
