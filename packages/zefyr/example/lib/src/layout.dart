import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:flutter/material.dart';

/// Returns a boolean if we are on a medium or larger screen. Used to
/// build adaptive and responsive layouts.
bool isDisplayDesktop(BuildContext context) =>
    getWindowType(context) >= AdaptiveWindowType.medium;

/// Returns true if the window size is medium size. Used to build adaptive and responsive layouts.
bool isDisplaySmallDesktop(BuildContext context) {
  return getWindowType(context) == AdaptiveWindowType.medium;
}

class PageLayout extends StatefulWidget {
  final Widget appBar;
  final Widget menuBar;
  final Widget body;

  const PageLayout({Key key, this.appBar, this.menuBar, this.body})
      : super(key: key);

  @override
  _PageLayoutState createState() => _PageLayoutState();
}

class _PageLayoutState extends State<PageLayout> {
  @override
  Widget build(BuildContext context) {
    if (isDisplayDesktop(context) || isDisplaySmallDesktop(context)) {
      return _DesktopScaffold(
        appBar: widget.appBar,
        menuBar: widget.menuBar,
        body: widget.body,
      );
    }
    return _MobileScaffold(
        appBar: widget.appBar, menuBar: widget.menuBar, body: widget.body);
  }
}

class _DesktopScaffold extends StatelessWidget {
  final Widget appBar;
  final Widget menuBar;
  final Widget body;

  const _DesktopScaffold({Key key, this.appBar, this.menuBar, this.body})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade800),
            constraints: BoxConstraints(minWidth: 260, maxWidth: 260),
            child: Column(children: [
              appBar,
              Divider(
                height: 1,
                color: Colors.white,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              Expanded(child: menuBar),
            ]),
          ),
          Expanded(child: body)
        ],
      ),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  final Widget appBar;
  final Widget menuBar;
  final Widget body;

  const _MobileScaffold({Key key, this.appBar, this.menuBar, this.body})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: Drawer(child: menuBar),
      body: body,
    );
  }
}
