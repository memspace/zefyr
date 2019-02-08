## Quick Start

Zefyr project is split in two main packages:

1. `zefyr` - Flutter package which provides the UI part
2. `notus` - platform-agnostic package which provides document model
   used by `zefyr` package.

### Installation

Add `zefyr` package as a dependency to your `pubspec.yaml`:

```yaml
dependencies:
  zefyr: [latest_version]
```

And run `flutter packages get` to install. This installs both `zefyr`
and `notus` packages.

### Usage

There are 4 main objects you would normally interact with in your code:

* `NotusDocument`, represents a rich text document and provides
  high-level methods for manipulating the document's state, like
  inserting, deleting and formatting of text.
  Read [documentation][data_and_docs] for more details on Notus
  document model and data format.
* `ZefyrEditor`, a Flutter widget responsible for rendering of rich text
  on the screen and reacting to user actions.
* `ZefyrController`, ties the above two objects together.
* `ZefyrScaffold`, allows embedding Zefyr toolbar into any custom layout.

`ZefyrEditor` depends on presence of `ZefyrScaffold` somewhere up the widget tree.

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
  ZefyrController _controller;
  FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    // Create an empty document or load existing if you have one.
    // Here we create an empty document:
    final document = new NotusDocument();
    _controller = new ZefyrController(document);
    _focusNode = new FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return ZefyrScaffold(
      child: ZefyrEditor(
        controller: _controller,
        focusNode: _focusNode,
      ),
    );
  }
}
```

In following sections you will learn more about document
model, Deltas, attributes and other aspects of the editor.

### Next

* [Data Format and Document Model][data_and_docs]

[data_and_docs]: /doc/data_and_document.md
