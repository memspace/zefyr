## 1.0.0-dev.2.0

* Improved block-level heuristics to not exit when adding empty lines in the middle of a block.

## 1.0.0-dev.1.0

This is the first dev version of the notus package for the upcoming 1.0.0 release.
The major version bump indicates that there are going to be breaking changes in this package.
Each such change will be documented in this changelog as well as in the upgrading guide.
This release introduces the first breaking change described below, but there is at least one
more breaking change planned in one of upcoming `1.0.0-dev.x.y` releases.

**Breaking change**: Handling of embeds changed from using a style attribute 
`NotusAttribute.embed` to actually placing embedded objects as data payload of insert operations.
This functionality relies on the `2.0.0` version of `quill_delta` package.

Breaking API changes include:

* `NotusAttribute.embed` is removed together with `EmbedAttribute`.

If your code relies on this attribute you can migrate your code to use the new `BlockEmbed` type.
Inserting an embed now means inserting an instance of `BlockEmbed` instead of formatting with
the embed style. For example,

```dart
void main() {
  // OLD:
  final doc = NotusDocument();
  doc.format(7, 0, NotusAttribute.embed.horizontalRule);
  // NEW:
  doc.insert(7, BlockEmbed.horizontalRule);
}
```

Non-breaking API changes:

* `NotusDocument.insert`, `NotusDocument.replace` as well as `Node.insert` changed the inserted
  data type from `String` to `Object` in order to support insertion of embeds.
  
Deprecated APIs:

* `NotusDocument.fromDelta` is deprecated and will be removed prior to stable `1.0.0` release.
  If you're relying on this method consider switching to `NotusDocument.fromJson`.

**Backward compatibility for existing documents**

Existing documents which use `NotusAttribute.embed` will automatically get converted to the new 
format upon loading into a `NotusDocument` instance, so no extra work is necessary to migrate your
existing data. The same applies to composing old-style change Deltas using `NotusDocument.compose`.

**New functionality**

It is now possible to embed any user-defined object as well as override the built-in embed types
(horizontal rule and image).


## 0.1.5

* Bumped minimum Dart SDK version to 2.2
* Upgraded dependencies and resolved analyzer errors

## 0.1.4

* Fixed insertion of embeds when selection is not empty (#115)

## 0.1.3

* Fixed handling of user input around embeds
* Added new heuristic rule to preserve block style on paste

## 0.1.2

* Upgraded dependency on quiver_hashcode to 2.0.0

## 0.1.1

* Added `meta` package to dependencies
* Fixed analysis warnings
* Added example

## 0.1.0

*  Initial release
