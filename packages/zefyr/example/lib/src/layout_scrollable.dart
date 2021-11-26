import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

import 'scaffold.dart';

class ScrollableLayout extends StatefulWidget {
  @override
  _ScrollableLayoutState createState() => _ScrollableLayoutState();
}

class _ScrollableLayoutState extends State<ScrollableLayout> {
  final FocusNode _focusNode = FocusNode();

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      documentFilename: 'layout_scrollable.note',
      builder: _buildContent,
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
        child: ListView(
          controller: _scrollController,
          children: [
            ListTile(
              leading: Icon(
                Icons.warning_sharp,
                color: Colors.green,
              ),
              title: Text('Please review your document'),
              subtitle: Text(
                  'Below you can see Zefyr editor which is embedded into this ListView'),
            ),
            Divider(),
            ZefyrEditor(
              controller: controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              scrollable: false,
              autofocus: true,
              padding: EdgeInsets.symmetric(horizontal: 8),
            ),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.question_answer,
                color: Colors.blue,
              ),
              title: Text('Everything looks good?'),
              subtitle: Text('If yes then just hit the Submit button'),
              trailing: TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Theme.of(context).accentColor),
                ),
                onPressed: () =>
                    showDialog(context: context, builder: _buildThanks),
                child: Text(
                  'Submit',
                  style: Theme.of(context).accentTextTheme.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThanks(BuildContext context) {
    return AlertDialog(
      title: Text('Thanks'),
      content: Text('This is a demo so nothing really happens.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        )
      ],
    );
  }
}
