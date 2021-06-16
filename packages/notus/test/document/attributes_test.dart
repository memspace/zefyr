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
  });

  group('$NotusStyle inlines', () {
    test('valid bold', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'b': true});
      final attr = attrs.get(NotusAttribute.bold);
      expect(attr, NotusAttribute.bold);
    });

    test('valid italic', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'i': true});
      final attr = attrs.get(NotusAttribute.italic);
      expect(attr, NotusAttribute.italic);
    });

    test('valid strikethrough', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'s': true});
      final attr = attrs.get(NotusAttribute.strikethrough);
      expect(attr, NotusAttribute.strikethrough);
    });

    test('valid blue marker', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'bm': '330099DD'});
      final attr = attrs.get(NotusAttribute.blueMarker);
      expect(attr, NotusAttribute.blueMarker);
    });

    test('valid accent color', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'ac': 'FFFF5555'});
      final attr = attrs.get(NotusAttribute.accentColor);
      expect(attr, NotusAttribute.accentColor);
    });
  });

  group('$NotusStyle block', () {
    test('valid block bulletList', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'ul'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.ul);
    });

    test('valid block numberList', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'ol'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.ol);
    });

    test('valid block quote', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'quote'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.bq);
    });

    test('valid block code', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'code'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.code);
    });

    test('valid largeHeading code', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'lh'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.largeHeading);
    });

    test('valid middleHeading code', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'block': 'mh'});
      final attr = attrs.get(NotusAttribute.block);
      expect(attr, NotusAttribute.middleHeading);
    });

    test('throws exception when contain invalid block key', () {
      expect(() => NotusStyle.fromJson(<String, dynamic>{'is not a block': 'ul'}),
          throwsA(TypeMatcher<UnsupportedFormatException>()));
    });

    test('throws exception when contain invalid block value', () {
      expect(() => NotusStyle.fromJson(<String, dynamic>{'block': 'is not a value'}),
          throwsA(TypeMatcher<UnsupportedFormatException>()));
    });
  });

  group('$NotusStyle heading', () {
    test('valid heading 1', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'heading': 1});
      final attr = attrs.get(NotusAttribute.heading);
      expect(attr, NotusAttribute.heading.level1);
    });

    test('valid heading 2', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'heading': 2});
      final attr = attrs.get(NotusAttribute.heading);
      expect(attr, NotusAttribute.heading.level2);
    });

    test('valid heading 3', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'heading': 3});
      final attr = attrs.get(NotusAttribute.heading);
      expect(attr, NotusAttribute.heading.level3);
    });

    test('valid caption ', () {
      final attrs = NotusStyle.fromJson(<String, dynamic>{'heading': 5});
      final attr = attrs.get(NotusAttribute.heading);
      expect(attr, NotusAttribute.heading.caption);
    });

    test('throws exception when contain invalid heading key', () {
      expect(() => NotusStyle.fromJson(<String, dynamic>{'is not a heading key': 1}),
          throwsA(TypeMatcher<UnsupportedFormatException>()));
    });

    test('throws exception when contain invalid heading value', () {
      expect(() => NotusStyle.fromJson(<String, dynamic>{'heading': 6}),
          throwsA(TypeMatcher<UnsupportedFormatException>()));
    });

    test('throws exception when contain invalid heading value', () {
      expect(() => NotusStyle.fromJson(<String, dynamic>{'heading': 'is not a heading value'}),
          throwsA(TypeMatcher<UnsupportedFormatException>()));
    });
  });
}
