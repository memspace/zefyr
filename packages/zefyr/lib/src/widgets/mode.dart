import 'package:meta/meta.dart';
import 'package:quiver_hashcode/hashcode.dart';

/// Controls level of interactions allowed by Zefyr editor.
///
// TODO: consider extending with following:
//       - linkTapBehavior: none|launch
//       - allowedStyles: ['bold', 'italic', 'image', ... ]
class ZefyrMode {
  /// Editing mode provides full access to all editing features: keyboard,
  /// editor toolbar with formatting tools, selection controls and selection
  /// toolbar with clipboard tools.
  ///
  /// Tapping on links in edit mode shows selection toolbar with contextual
  /// actions instead of launching the link in a web browser.
  static const edit =
      ZefyrMode(canEdit: true, canSelect: true, canFormat: true);

  /// Select-only mode allows users to select a range of text and have access
  /// to selection toolbar including clipboard tools, any custom actions
  /// registered by current text selection controls implementation.
  ///
  /// Tapping on links in select-only mode launches the link in a web browser.
  static const select =
      ZefyrMode(canEdit: false, canSelect: true, canFormat: true);

  /// View-only mode disables almost all user interactions except the ability
  /// to launch links in a web browser when tapped.
  static const view =
      ZefyrMode(canEdit: false, canSelect: false, canFormat: false);

  /// Returns `true` if user is allowed to change text in a document.
  final bool canEdit;

  /// Returns `true` if user is allowed to select a range of text in a document.
  final bool canSelect;

  /// Returns `true` if user is allowed to change formatting styles in a
  /// document.
  final bool canFormat;

  /// Creates new mode which describes allowed interactions in Zefyr editor.
  const ZefyrMode({
    @required this.canEdit,
    @required this.canSelect,
    @required this.canFormat,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ZefyrMode) return false;
    final ZefyrMode that = other;
    return canEdit == that.canEdit &&
        canSelect == that.canSelect &&
        canFormat == that.canFormat;
  }

  @override
  int get hashCode => hash3(canEdit, canSelect, canFormat);

  @override
  String toString() {
    return 'ZefyrMode(canEdit: $canEdit, canSelect: $canSelect, canFormat: $canFormat)';
  }
}
