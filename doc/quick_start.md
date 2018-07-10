## Quick Start

### Installation

Add `zefyr` package as a dependency to your `pubspec.yaml`:

```yaml
dependencies:
  zefyr: ^0.1.0
```

And run `flutter packages get` to install.

### Usage

There are 3 main objects you would normally interact with in your code:

* `ZefyrDocument`, represents a rich text document and provides
  high-level methods for manipulating the document's state, like
  inserting, deleting and formatting of text.
  Read [documentation][data_and_docs] for more details on Zefyr's
  document model and data format.
* `ZefyrEditor`, a Flutter widget responsible for rendering of rich text
  on the screen and reacting to user actions.
* `ZefyrController`, ties the above two objects together.

Normally you would need to place `ZefyrEditor` inside of a
`StatefulWidget`. Shown below is a minimal setup required to use the
editor:

```dart
import 'package:flutter/material.dart';
import 'package:zefyr/zefyr.dart';

class MyWidget extends StatefulWidget {
  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<MyWidget> {
  final ZefyrController _controller;
  final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Create an empty document or load existing if you have one.
    // Here we create an empty document:
    final document = new ZefyrDocument();
    _controller = new ZefyrController(document);
    _focusNode = new FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return ZefyrEditor(
      controller: _controller,
      focusNode: _focusNode,
    );
  }
}
```

In following sections you will learn more about document
model, Deltas, attributes and other aspects of the editor.

### Next

* [Data Format and Document Model][data_and_docs]

[data_and_docs]: /doc/data_and_document.md
