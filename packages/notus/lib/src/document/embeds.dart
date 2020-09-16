import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:quiver_hashcode/hashcode.dart';

const _dataEquality = DeepCollectionEquality();

/// An object which can be embedded into a Notus document.
class EmbeddableObject {
  EmbeddableObject(
    this.type, {
    Map<String, dynamic> data = const {},
  })  : assert(!data.containsKey('type'),
            'The "type" key is reserved in $EmbeddableObject data and cannot be used.'),
        _data = Map.from(data);

  /// The type of this object.
  final String type;

  /// The data payload of this object.
  Map<String, dynamic> get data => UnmodifiableMapView(_data);
  final Map<String, dynamic> _data;

  static EmbeddableObject fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json);
    data.remove('type');
    return EmbeddableObject(type, data: data);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! EmbeddableObject) return false;
    final typedOther = other as EmbeddableObject;
    return typedOther.type == type &&
        _dataEquality.equals(typedOther._data, _data);
  }

  @override
  int get hashCode {
    if (_data.isEmpty) return type.hashCode;

    final dataHash = hashObjects(
      _data.entries.map((e) => hash2(e.key, e.value)),
    );
    return hash2(type, dataHash);
  }

  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(_data);
    json['type'] = type;
    return json;
  }
}
