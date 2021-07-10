// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:test/test.dart';
import 'package:notus/notus.dart';

void main() {
  group('$NotusStyle', () {
    test('get', () {
      var attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'ul'});
      var attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.ul);
    });

    test('get unset', () {
      var attrs = NotusStyle.fromJson(<String, dynamic>{'b': null});
      var attr = attrs.get(NotusAttribute.bold);
      expect(attr, NotusAttribute.bold.unset);
    });
  });
}
