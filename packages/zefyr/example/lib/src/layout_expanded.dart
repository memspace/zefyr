import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'scaffold.dart';

class ExpandedLayout extends StatefulWidget {
  @override
  _ExpandedLayoutState createState() => _ExpandedLayoutState();
}

class _ExpandedLayoutState extends State<ExpandedLayout> {
  final FocusNode _focusNode = FocusNode();

  bool _expands = true;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'layout_expanded.note',
      builder: _buildContent,
      actions: [
        IconButton(
          onPressed: _toggleExpands,
          icon: Icon(
            _expands ? Icons.unfold_less : Icons.expand,
            color: Colors.grey.shade800,
            size: 18,
          ),
        )
      ],
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
        child: ZefyrEditor(
          controller: controller,
          focusNode: _focusNode,
          autofocus: true,
          expands: _expands,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  void _toggleExpands() {
    setState(() {
      _expands = !_expands;
    });
  }
}
