export 'rendering/editor.dart';
export 'widgets/_controller.dart';
export 'widgets/_cursor.dart';
export 'widgets/_editor.dart';

/// RawEditor [RenderEditor]
///   - EditableRichText [RenderEditableParagraph] - LineNode, handles caret, background, padding, selection boxes, etc
///     - RichText [RenderParagraph]
///   - EditableBlock [RenderEditableBlock] - BlockNode, handles padding, decoration, background color for the block
///     - EditableRichText [RenderEditableRichText]
///       - RichText [RenderParagraph]
///     - EditableEmbed
///   - EditableEmbed [RenderEditableEmbed] - LineNode with EmbedNode segment
///
/// Interfaces:
///
/// - EditableWidget - common interface for EditableRichText and EditableBlock
/// - RenderEditableBox - common interface for RenderEditableParagraph, RenderEditableEmbed and RenderEditableBlock
///
/// RawEditor is a multi-child container widget and its children must be
/// instances of EditableWidget, so that in RenderEditor we are guaranteed
/// to have all child render objects of type RenderEditableBox
