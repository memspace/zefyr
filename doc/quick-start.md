## Quick Start

Zefyr project consists of two packages:

1. [zefyr](https://pub.dev/packages/zefyr) - Flutter package which provides all necessary UI widgets
2. [notus](https://pub.dev/packages/notus) - package containing document model used by `zefyr` package. `notus` package is platform-agnostic and can be used outside of Flutter apps (web or server-side Dart projects).

### Installation

Before installing Zefyr make sure that you installed [Flutter](https://flutter.dev/docs/get-started/install)
and created a [project](https://flutter.dev/docs/get-started/test-drive).

Add `zefyr` package as a dependency to `pubspec.yaml` of your project:

```yaml
dependencies:
  zefyr: [latest_version]
```

And run `flutter packages get`, this installs both `zefyr` and `notus` packages.

### Usage

We start by creating a `StatefulWidget` that will be responsible for handling
all the state and interactions with Zefyr. In this example we'll assume
that there is dedicated editor page in our app:

```dart
import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

class EditorPage extends StatefulWidget {
  @override
  EditorPageState createState() => EditorPageState();
}

class EditorPageState extends State<EditorPage> {
  /// Allows to control the editor and the document.
  ZefyrController _controller;

  /// Zefyr editor like any other input field requires a focus node.
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Here we must load the document and pass it to Zefyr controller.
    final document = _loadDocument();
    _controller = new ZefyrController(document);
    _focusNode = new FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    // Note that the editor requires special `ZefyrScaffold` widget to be
    // present somewhere up the widget tree.
    return Scaffold(
      appBar: AppBar(title: Text("Editor page")),
      body: ZefyrScaffold(
        child: ZefyrEditor(
          padding: EdgeInsets.all(16),
          controller: _controller,
          focusNode: _focusNode,
        ),
      ),
    );
  }

  /// Loads the document to be edited in Zefyr.
  NotusDocument _loadDocument() {
    // For simplicity we hardcode a simple document with one line of text
    // saying "Zefyr Quick Start".
    final Delta delta = Delta()..insert("Zefyr Quick Start\n");
    // Note that delta must always end with newline.
    return NotusDocument.fromDelta(delta);
  }
}
```

In the above example we created a page with an AppBar and Zefyr editor in its
body. We also initialize our editor with a simple one-line document. Here is how
it might look when we run the app and navigate to editor page:

<img src="https://github.com/memspace/zefyr/raw/gitbook/assets/quick-start-screen-01.png" width="375">

At this point we can already edit the document and apply styles, however if
we navigate back from this page our changes will be lost. Let's fix this and
add a button which saves the document to device's file system.

First we need a function to save the document:

```dart
class EditorPageState extends State<EditorPage> {

  // ... add after _loadDocument()

  void _saveDocument(BuildContext context) {
    // Notus documents can be easily serialized to JSON by passing to
    // `jsonEncode` directly:
    final contents = jsonEncode(_controller.document);
    // For this example we save our document to a temporary file.
    final file = File(Directory.systemTemp.path + "/quick_start.json");
    // And show a snack bar on success.
    file.writeAsString(contents).then((_) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("Saved.")));
    });
  }
}
```

> Notice that we pass `BuildContext` to `_saveDocument`. This is required
> to get access to our page's `Scaffold` state, so that we can show a `SnackBar`.

Now we just need to add a button to the AppBar, so we need to modify `build`
method as follows:

```dart
class EditorPageState extends State<EditorPage> {

  // ... replace build() method with following

  @override
  Widget build(BuildContext context) {
    // Note that the editor requires special `ZefyrScaffold` widget to be
    // present somewhere up the widget tree.
    return Scaffold(
      appBar: AppBar(
        title: Text("Editor page"),
        // <<< begin change
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.save),
              onPressed: () => _saveDocument(context),
            ),
          )
        ],
        // end change >>>
      ),
      body: ZefyrScaffold(
        child: ZefyrEditor(
          padding: EdgeInsets.all(16),
          controller: _controller,
          focusNode: _focusNode,
        ),
      ),
    );
  }
}
```

We have to use `Builder` here for our icon button because we need access to
build context within the scope of this page's Scaffold. Everything else here
should be straightforward.

Now we can reload our app, hit "Save" button and see the snack bar.

<img src="https://github.com/memspace/zefyr/raw/gitbook/assets/quick-start-screen-02.png" width="375">

Since we now have this document saved to a file, let's update our
`_loadDocument` method to load saved file if it exists.
