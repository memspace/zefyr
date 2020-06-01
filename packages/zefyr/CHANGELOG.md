## 0.11.0

* Updated to support Flutter 1.17.0

## 0.10.0

This release contains breaking changes.
The entire theming layer of ZefyrEditor has been rewritten. Most notable changes include:

* Removed `selectionColor` and `cursorColor` from `ZefyrThemeData`. Relying on the Flutter 
  `ThemeData.textSelectionColor` and `ThemeData.cursorColor` instead.
* All attribute styles moved to the new `AttributeTheme` class.
* `indentSize` renamed to `indentWidth`
* Purpose of `BlockTheme` changed to specify styles for particular block type (list, quote, code)
* Removed `HeadingTheme` and `StyleTheme`
* Added new `LineTheme` to describe styles of headings and paragraphs

Other changes in this release include:

* Added: Support for Dark Mode
* Changed: Minor tweaks to default theme
* Fixed: ZefyrField decoration when focused appeared as disabled
* Fixed: Caret color for iOS

## 0.9.1

* Added: Support for iOS keyboard appearance. See `ZefyrEditor.keyboardAppearance` and `ZefyrField.keyboardAppearance`
* Fixed: Preserve inline style when replacing formatted text from the first character (#201)
* Fixed: Toggling toolbar between two editors (#229)

## 0.9.0

* Feature: toggle inline styles (works for bold and italic)
* Updated to support Flutter 1.12.0
* Upgraded dependencies
* Fixed analyzer issues

## 0.8.0

* Updated to support Flutter 1.9.0 (#154)

## 0.7.0

This release contains breaking changes.

* Breaking change: `ZefyrEditor.enabled` field replaced by `ZefyrEditor.mode` which can take one of three default values:
    - `ZefyrMode.edit`: the same as `enabled: true`, all editing controls are available to the user
    - `ZefyrMode.select`: user can't modify text itself, but allowed to select it and optionally apply formatting.
    - `ZefyrMode.view`: the same as `enabled: false`, read-only.
* Added optional `selectionControls` field to `ZefyrEditor` and `ZefyrEditableText`. If not provided then by default uses platform-specific implementation.
* Added support for "selectAll" action in selection toolbar.
* Breaking change: removed `ZefyrDefaultImageDelegate` as well as dependency on `image_picker` plugin. Users are required to provide their own implementation. If image delegate is not provided then image toolbar button is disabled.
* Breaking change: added `ZefyrImageDelegate.cameraSource` and `ZefyrImageDelegate.gallerySource` fields. For users of `image_picker` plugin these should return `ImageSource.camera` and `ImageSource.gallery` respectively. See documentation on implementing image support for more details.

## 0.6.1

* Relaxed dependency constraint on `image_picker` library to allow latest version. Note that
  Zefyr 0.7 will stop depending on `image_picker` and introduce some breaking changes, which will
  be described here when 0.7 is released.

## 0.6.0

* Updated to support Flutter 1.7.8

## 0.5.0

* Updated to support Flutter 1.2
* Experimental: Added non-scrollable `ZefyrView` widget which allows previewing Notus documents inside layouts using their own scrollables like ListView.
* Breaking change: renamed `EditableRichText` to `ZefyrRichText`. User code is unlikely to be affected unless you've extended Zefyr with custom implementations of block widgets.
* Breaking change: renamed `RenderEditableParagraph` to `RenderZefyrParagraph`. User code is unlikely to be affected unless you've extended Zefyr with custom implementations of block widgets.
* Added `ZefyrScope` class - replaces previously used scope objects `ZefyrEditableTextScope` and `ZefyrEditorScope`. Unified all shared resources under one class.
* Breaking change: removed `ZefyrEditor.of` and `ZefyrEditableText.of` static methods. Use `ZefyrScope.of` instead.

## 0.4.0

* Breaking change: upgraded `image_picker` to `^0.5.0` and `url_launcher` to `^5.0.0` which requires migration to Android X. You must migrate your app in order to use this version. For details on how to migrate see:
  - https://flutter.io/docs/development/packages-and-plugins/androidx-compatibility
  - https://developer.android.com/jetpack/androidx/migrate

## 0.3.1

- Fixed autofocus not being triggered when set to `true` for the first time.
- Allow customizing cursor color via ZefyrTheme.

## 0.3.0

This version introduces new widget `ZefyrScaffold` which allows embedding Zefyr in custom layouts, like forms with multiple input fields.

It is now required to always wrap `ZefyrEditor` with an instance of this new widget. See examples and readme for more details.

There is also new `ZefyrField` widget which integrates Zefyr with material design decorations.

* Breaking change: `ZefyrEditor` requires an ancestor `ZefyrScaffold`.
* Upgraded to `url_launcher` version 4.0.0.
* Exposed `ZefyrEditor.physics` property to allow customization of `ScrollPhysics`.
* Added basic `ZefyrField` widget with material design decorations.

## 0.2.0

* Breaking change: `ZefyrImageDelegate.createImageProvider` replaced with `ZefyrImageDelegate.buildImage`.
* Fixed redundant updates on composing range for Android.
* Added TextCapitalization.sentences
* Added docs for embedding images.

## 0.1.2

* Fixed analysis warnings.
* UX: User taps on padding area around the editor and in empty space inside it now look for the nearest paragraph to move caret to.
* UX: Toggle selection toolbar on double tap instead of refreshing it.

## 0.1.1

* Fixed: Prevent sending excessive value updates to the native side
  which cause race conditions (#12).

## 0.1.0

*  Initial release.
