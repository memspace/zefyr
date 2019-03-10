## 0.5.0

* Updated to support Flutter 1.2
* Experimental: Added non-scrollable `ZefyrView` widget which allows previewing Notus documents
  inside layouts using their own scrollables like ListView.
* Breaking change: renamed `EditableRichText` to `ZefyrRichText`. User code is unlikely to be
  affected unless you've extended Zefyr with custom implementations of block widgets.
* Breaking change: renamed `RenderEditableParagraph` to `RenderZefyrParagraph`. User code is
  unlikely to be affected unless you've extended Zefyr with custom implementations of block widgets.
* Added `ZefyrScope` class - replaces previously used scope objects `ZefyrEditableTextScope` and
  `ZefyrEditorScope`. Unified all shared resources under one class.
* Breaking change: removed `ZefyrEditor.of` and `ZefyrEditableText.of` static methods.
  Use `ZefyrScope.of` instead.

## 0.4.0

* Breaking change: upgraded `image_picker` to `^0.5.0` and `url_launcher` to `^5.0.0` which
  requires migration to Android X. You must migrate your app in order to use this version.
  For details on how to migrate see:
  - https://flutter.io/docs/development/packages-and-plugins/androidx-compatibility
  - https://developer.android.com/jetpack/androidx/migrate

## 0.3.1

- Fixed autofocus not being triggered when set to `true` for the first time.
- Allow customizing cursor color via ZefyrTheme.

## 0.3.0

This version introduces new widget `ZefyrScaffold` which allows embedding Zefyr in custom
layouts, like forms with multiple input fields.

It is now required to always wrap `ZefyrEditor` with an instance of this new widget. See examples
and readme for more details.

There is also new `ZefyrField` widget which integrates Zefyr with material design decorations.

* Breaking change: `ZefyrEditor` requires an ancestor `ZefyrScaffold`.
* Upgraded to `url_launcher` version 4.0.0.
* Exposed `ZefyrEditor.physics` property to allow customization of `ScrollPhysics`.
* Added basic `ZefyrField` widget with material design decorations.

## 0.2.0

* Breaking change: `ZefyrImageDelegate.createImageProvider` replaced with
  `ZefyrImageDelegate.buildImage`.
* Fixed redundant updates on composing range for Android.
* Added TextCapitalization.sentences
* Added docs for embedding images.

## 0.1.2

* Fixed analysis warnings.
* UX: User taps on padding area around the editor and in empty space inside it now look for the nearest
  paragraph to move caret to.
* UX: Toggle selection toolbar on double tap instead of refreshing it.

## 0.1.1

* Fixed: Prevent sending excessive value updates to the native side
  which cause race conditions (#12).

## 0.1.0

*  Initial release.
