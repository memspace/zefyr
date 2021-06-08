// 対応してない規格があった場合に投げる
class UnsupportedFormatException implements Exception {
  final String message;
  const UnsupportedFormatException(this.message);

  @override
  String toString() => message;
}
