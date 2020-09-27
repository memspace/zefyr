import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'scaffold.dart';

class DecoratedFieldDemo extends StatefulWidget {
  @override
  _DecoratedFieldDemoState createState() => _DecoratedFieldDemoState();
}

class _DecoratedFieldDemoState extends State<DecoratedFieldDemo> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'decorated_field.note',
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, ZefyrController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          TextField(
            decoration: InputDecoration(labelText: 'Title'),
          ),
          ZefyrField(
            controller: controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Detailed description, but not too detailed',
            ),
            minHeight: 150.0,
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Final thoughts'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
