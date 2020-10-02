import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'scaffold.dart';

class ReadOnlyView extends StatefulWidget {
  @override
  _ReadOnlyViewState createState() => _ReadOnlyViewState();
}

class _ReadOnlyViewState extends State<ReadOnlyView> {
  final FocusNode _focusNode = FocusNode();

  bool _edit = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'basics_read_only_view.note',
      builder: _buildContent,
      showToolbar: _edit == true,
      floatingActionButton: FloatingActionButton.extended(
          label: Text(_edit == true ? 'Done' : 'Edit'),
          onPressed: _toggleEdit,
          icon: Icon(_edit == true ? Icons.check : Icons.edit)),
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
          expands: true,
          readOnly: !_edit,
          showCursor: _edit,
          padding: EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _edit = !_edit;
    });
  }
}
