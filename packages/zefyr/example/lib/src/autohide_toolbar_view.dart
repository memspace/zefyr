import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'scaffold.dart';

class AutoHideToolbarView extends StatefulWidget {
  @override
  _AutoHideToolbarViewState createState() => _AutoHideToolbarViewState();
}

class _AutoHideToolbarViewState extends State<AutoHideToolbarView> {
  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final _controller1 = ZefyrController();
  final _controller2 = ZefyrController();
  final _controller3 = ZefyrController();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'basics_read_only_view.note',
      builder: _buildContent,
      showToolbar: false,
    );
  }

  Widget _buildContent(BuildContext context, ZefyrController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            ListTile(title: Text('Editor 1')),
            AutoHideToolbar(controller: _controller1, focusNode: _focusNode1),
            ZefyrEditor(
              controller: _controller1,
              focusNode: _focusNode1,
              expands: false,
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            ListTile(title: Text('Editor 2')),
            AutoHideToolbar(controller: _controller2, focusNode: _focusNode2),
            ZefyrEditor(
              controller: _controller2,
              focusNode: _focusNode2,
              expands: false,
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            ListTile(title: Text('Editor 3')),
            AutoHideToolbar(controller: _controller3, focusNode: _focusNode3),
            ZefyrEditor(
              controller: _controller3,
              focusNode: _focusNode3,
              expands: false,
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
      ),
    );
  }
}
