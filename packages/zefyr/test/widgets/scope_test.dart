// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zefyr/zefyr.dart';

void main() {
  group('$ZefyrScope', () {
    ZefyrScope scope;

    setUp(() {
      WidgetsFlutterBinding.ensureInitialized();
      final doc = NotusDocument();
      scope = ZefyrScope.editable(
        controller: ZefyrController(doc),
        imageDelegate: ZefyrDefaultImageDelegate(),
        focusNode: FocusNode(),
        focusScope: FocusScopeNode(),
      );
    });

    test('it notifies on image delegate update', () {
      bool notified = false;
      scope.addListener(() {
        notified = true;
      });
      final delegate = ZefyrDefaultImageDelegate();
      scope.imageDelegate = delegate;
      expect(notified, isTrue);
      notified = false;
      scope.imageDelegate = delegate;
      expect(notified, isFalse);
    });

    test('it notifies on controller update', () {
      bool notified = false;
      scope.addListener(() {
        notified = true;
      });
      final controller = ZefyrController(NotusDocument());
      scope.controller = controller;
      expect(notified, isTrue);
      notified = false;
      scope.controller = controller;
      expect(notified, isFalse);
    });

    test('it notifies on focus node update', () {
      bool notified = false;
      scope.addListener(() {
        notified = true;
      });
      final focusNode = FocusNode();
      scope.focusNode = focusNode;
      expect(notified, isTrue);
      notified = false;
      scope.focusNode = focusNode;
      expect(notified, isFalse);
    });

    test('it notifies on selection changes but not text changes', () {
      bool notified = false;
      scope.addListener(() {
        notified = true;
      });

      scope.controller.replaceText(0, 0, 'Hello');
      expect(notified, isFalse);
      scope.controller.updateSelection(TextSelection.collapsed(offset: 4));
      expect(notified, isTrue);
    });
  });
}
