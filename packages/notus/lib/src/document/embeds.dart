import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:quiver/core.dart';

const _dataEquality = DeepCollectionEquality();

/// An object which can be embedded into a Notus document.
///
/// See also:
///
/// * [SpanEmbed] which represents an inline embed.
/// * [BlockEmbed] which represents a block embed.
class EmbeddableObject {
  /// Key of the "type" attribute in the data map. This key is reserved.
  static const kTypeKey = '_type';

  /// Key of the "inline" attribute in the data map. This key is reserved.
  static const kInlineKey = '_inline';

  EmbeddableObject(
    this.type, {
    required this.inline,
    Map<String, dynamic> data = const {},
  })  : assert(!data.containsKey(kTypeKey),
            'The "$kTypeKey" key is reserved in $EmbeddableObject data and cannot be used.'),
        assert(!data.containsKey(kInlineKey),
            'The "$kInlineKey" key is reserved in $EmbeddableObject data and cannot be used.'),
        _data = Map.from(data);

  /// The type of this object.
  final String type;

  /// If set to `true` then this object can be embedded inline with regular
  /// text, otherwise it occupies an entire line.
  final bool inline;

  /// The data payload of this object.
  Map<String, dynamic> get data => UnmodifiableMapView(_data);
  final Map<String, dynamic> _data;

  static EmbeddableObject fromJson(Map<String, dynamic> json) {
    final type = json[kTypeKey] as String;
    final inline = json[kInlineKey] as bool;
    final data = Map<String, dynamic>.from(json);
    data.remove(kTypeKey);
    data.remove(kInlineKey);
    if (inline) {
      return SpanEmbed(type, data: data);
    }
    return BlockEmbed(type, data: data);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! EmbeddableObject) return false;
    return other.type == type &&
        other.inline == inline &&
        _dataEquality.equals(other._data, _data);
  }

  @override
  int get hashCode {
    if (_data.isEmpty) return hash2(type, inline);

    final dataHash = hashObjects(
      _data.entries.map((e) => hash2(e.key, e.value)),
    );
    return hash3(type, inline, dataHash);
  }

  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(_data);
    json[kTypeKey] = type;
    json[kInlineKey] = inline;
    return json;
  }
}

/// An object which can be embedded on the same line (inline) with regular text.
///
/// Span embeds are not currently supported by Notus document model and this
/// class exists to establish the contract for future work.
// TODO: document model currently only supports BlockEmbeds and need to be updated to support SpanEmbeds.
class SpanEmbed extends EmbeddableObject {
  SpanEmbed(
    String type, {
    Map<String, dynamic> data = const {},
  }) : super(type, inline: true, data: data);
}

/// An object which occupies an entire line in a document and cannot co-exist
/// inline with regular text.
///
/// Examples of block embeds include horizontal rule, an image or a map view.
///
/// There are two built-en embed types supported by Notus documents, however
/// the document model itself does not make any assumptions about the types
/// of embedded objects and allows users to define their own types.
///
/// It is also allowed to re-define the built-in embed types (horizontal rule
/// and image) entirely. However if used with Zefyr editor this change may
/// require extending Zefyr to recognize the new data attached to those embed
/// types. See documentation on working with embeds in Zefyr for more details.
class BlockEmbed extends EmbeddableObject {
  /// Creates a new block embed of specified [type] and containing [data].
  BlockEmbed(
    String type, {
    Map<String, dynamic> data = const {},
  }) : super(type, inline: false, data: data);

  static final BlockEmbed horizontalRule = BlockEmbed('hr');
  static BlockEmbed image(String source) =>
      BlockEmbed('image', data: {'source': source});
}
