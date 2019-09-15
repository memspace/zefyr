// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter_test/flutter_test.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

void main() {
  group('getPositionDelta', () {
    test('actual has more characters inserted than user', () {
      final user = Delta()
        ..retain(7)
        ..insert('a');
      final actual = Delta()
        ..retain(7)
        ..insert('\na');
      final result = getPositionDelta(user, actual);
      expect(result, 1);
    });

    test('actual has less characters inserted than user', () {
      final user = Delta()
        ..retain(7)
        ..insert('abc');
      final actual = Delta()
        ..retain(7)
        ..insert('ab');
      final result = getPositionDelta(user, actual);
      expect(result, -1);
    });

    test('actual has less characters deleted than user', () {
      final user = Delta()
        ..retain(7)
        ..delete(3);
      final actual = Delta()
        ..retain(7)
        ..delete(2);
      final result = getPositionDelta(user, actual);
      expect(result, 1);
    });
  });
}
