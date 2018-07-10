## Data Format and Document Model

Zefyr documents are based on Quill.js [Delta][] format. Deltas are
simple and expressive format of describing rich text data, and is also
suitable for [Operational transformations][ot]. The format is
essentially JSON, and is human readable.

> Official implementation of Delta format is written in
> [JavaScript][github-delta] but it was ported to Dart and is available
> on [Pub][pub-delta]. Examples in this document use Dart syntax.

[Delta]: https://quilljs.com/docs/delta/
[ot]: https://en.wikipedia.org/wiki/Operational_transformation
[github-delta]: https://github.com/quilljs/delta
[pub-delta]: https://pub.dartlang.com/packages/quill_delta

### Deltas quick start

All Deltas consist of three operations: `insert`, `delete` and `retain`. The
example below describes the string "Karl the Fog" where "Karl" is bolded
and "Fog" is italic:

```dart
var delta = new Delta();
delta
  ..insert('Karl', {'bold': true})
  ..insert(' the ')
  ..insert('Fog', {'italic': true});
print(json.encode(delta));
// Prints:
// [
//   {"insert":"Karl","attributes":{"bold":true}},
//   {"insert":" the "},
//   {"insert":"Fog","attributes":{"italic":true}}
// ]
```

Above delta is usually also called "document delta" because it consists
of only `insert` operations.

Below example describes a *change* where "Fog" gets also styled as bold:

```dart
var delta = new Delta();
delta..retain(9)..retain(3, {'bold': true});
print(json.encode(delta));
// Prints:
// [{"retain":9},{"retain":3,"attributes":{"bold":true}}]
```

A simple way to visualize a change is as if it moves an imaginary cursor
and applies modifications on the way. So with the above example, the
first `retain` operation moves the cursor forward 9 characters. Then,
second operation moves cursor additional 3 characters forward but also
applies bold style to each character it passes.

The Delta library provides a way of composing such changes into documents
or transforming against each other. E.g.:

```dart
var doc = new Delta();
doc
  ..insert('Karl', {'bold': true})
  ..insert(' the ')
  ..insert('Fog', {'italic': true});
var change = new Delta();
change..retain(9)..retain(3, {'bold': true});
var updatedDoc = doc.compose(change);
print(json.encode(updatedDoc));
// Prints:
//  [
//    {"insert":"Karl","attributes":{"bold":true}},
//    {"insert":" the "},
//    {"insert":"Fog","attributes":{"italic":true,"bold":true}}
//  ]
```

These are the basics of Deltas. Read [official documentation][delta-docs]
for more details.

[delta-docs]: https://quilljs.com/docs/delta/

### Document model

Zefyr documents are represented as a tree of nodes. There are 3 main types of
nodes:

* `Text` - a leaf node which represents a segment of styled text within
  a document.
* `Line` - represents an individual line of text within a document.
  Line nodes are containers for leaf nodes.
* `Block` - represents a group of adjacent lines which share the same
  style. Examples of blocks include lists, quotes or code blocks.

Given above description, here is ASCII-style visualization of a Zefyr
document tree:

```
root
 ╠═ block
 ║   ╠═ line
 ║   ║   ╠═ text
 ║   ║   ╚═ text
 ║   ╚═ line
 ║       ╚═ text
 ╠═ line
 ║   ╚═ text
 ╚═ block
     ╚═ line
         ╠═ text
         ╚═ text
```

It is currently not allowed to nest blocks inside other blocks but this
may change in the future. More node types are likely to be added as well.
For example, another leaf node for embedded content, like images.

All manipulations of Zefyr documents are designed strictly to match
semantics of underlying Delta format. As a result the model itself is
fairly simple and predictable.

To learn more about consequences of this design read about
[attributes][] and [heuristics][].

[heuristics]: /doc/heuristics.md
[attributes]: /doc/attributes.md

### Next

* [Attributes](/doc/attributes.md)

### Previous

* [Usage](/doc/usage.md)
