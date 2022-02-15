import 'dart:convert';
import 'dart:io';

import 'package:example/src/realtime_edition.dart';
import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

class RealtimeTextState extends StatefulWidget {
  final RealtimeEdition rt;
  final RealtimeEdition other;
  RealtimeTextState(this.rt, this.other, {Key key}) : super(key: key);

  @override
  State<RealtimeTextState> createState() => _RealtimeTextStateState();
}

class _RealtimeTextStateState extends State<RealtimeTextState> {
  int count = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.rt.controller.addListener(() {
      setState(() {
        count = widget.rt.localChanges.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      TextButton(
          onPressed: (() {
            final changes = widget.rt.localChanges;
            widget.other.addRemoteChanges(changes);
            widget.rt.localChanges.clear();
            setState(() {
              count = 0;
            });
          }),
          child: const Text(":Push:")),
      Text("Changes: ${count}")
    ]);
  }
}

class RealtimeEditorPage extends StatefulWidget {
  const RealtimeEditorPage({Key key}) : super(key: key);

  @override
  RealtimeEditorPageState createState() => RealtimeEditorPageState();
}

class RealtimeEditorPageState extends State<RealtimeEditorPage> {
  /// Allows to control the editor and the document.
  ZefyrController _controllerA;
  ZefyrController _controllerB;
  RealtimeEdition _rtA;
  RealtimeEdition _rtB;
  FocusNode _focusNodeA;
  FocusNode _focusNodeB;

  @override
  void initState() {
    super.initState();
    _focusNodeA = FocusNode();
    _focusNodeB = FocusNode();
    _loadDocument().then((document) {
      setState(() {
        _controllerA = ZefyrController(document);
        _rtA = RealtimeEdition(_controllerA);
      });
    });
    _loadDocument().then((document) {
      setState(() {
        _controllerB = ZefyrController(document);
        _rtB = RealtimeEdition(_controllerB);
      });
    });
  }

  Widget makeEditor(
      RealtimeEdition rt1, RealtimeEdition rt2, FocusNode focusNode) {
    if (rt1 == null || rt2 == null)
      return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        ZefyrField(
          padding: const EdgeInsets.all(16),
          controller: rt1.controller,
          focusNode: focusNode,
        ),
        RealtimeTextState(rt1, rt2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorA = makeEditor(_rtA, _rtB, _focusNodeA);
    final editorB = makeEditor(_rtB, _rtA, _focusNodeB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor page'),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveDocument(context),
            ),
          )
        ],
      ),
      body: Column(children: [editorA, editorB]),
    );
  }

  /// Loads the document asynchronously from a file if it exists, otherwise
  /// returns default document.
  Future<NotusDocument> _loadDocument() async {
    final file = File(Directory.systemTemp.path + '/quick_start.json');
    if (await file.exists()) {
      final contents = await file.readAsString().then(
          (data) => Future.delayed(const Duration(seconds: 1), () => data));
      return NotusDocument.fromJson(jsonDecode(contents));
    }
    final delta = Delta()..insert('Zefyr Quick Start\n');
    return NotusDocument()..compose(delta, ChangeSource.local);
  }

  void _saveDocument(BuildContext context) {
    // Notus documents can be easily serialized to JSON by passing to
    // `jsonEncode` directly:
    final contents = jsonEncode(_controllerA.document);
    // For this example we save our document to a temporary file.
    final file = File(Directory.systemTemp.path + '/quick_start.json');
    // And show a snack bar on success.
    file.writeAsString(contents).then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved.')));
    });
  }
}
