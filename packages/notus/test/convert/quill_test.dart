// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:notus/convert.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('$NotusQuillCodec.encode', () {
    test('Should return correct string', () {
      var result = notusQuill.encode(notus_doc);

      expect(jsonEncode(result.toJson()), quill_string);
    });
  });

  group('$NotusQuillCodec.decode', () {
    test('Should return correct string', () {
      var result = notusQuill.decode(quill_doc);

      expect(jsonEncode(result.toJson()), notus_string);
    });
  });

}

final notus_string =
    r'[{"insert":"Zefyr"},{"insert":"\n","attributes":{"heading":1}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"i":true}},{"insert":"\nZefyr is an "},{"insert":"early preview","attributes":{"b":true}},{"insert":" open source library.\nDocumentation"},{"insert":"\n","attributes":{"heading":3}},{"insert":"Quick Start"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Data format and Document Model"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Style attributes"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Heuristic rules"},{"insert":"\n","attributes":{"block":"ol"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"heading":2}},{"insert":"Zefyr’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nimport ‘package:flutter/material.dart’;"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"import ‘package:notus/notus.dart’;"},{"insert":"\n\n","attributes":{"block":"code"}},{"insert":"void main() {"},{"insert":"\n","attributes":{"block":"code"}},{"insert":" print(“Hello world!”);"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"}"},{"insert":"\n","attributes":{"block":"code"}}]';
final notus_doc = Delta.fromJson(json.decode(notus_string) as List);

final quill_string =
    r'[{"insert":"Zefyr"},{"insert":"\n","attributes":{"header":1}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"italic":true}},{"insert":"\nZefyr is an "},{"insert":"early preview","attributes":{"bold":true}},{"insert":" open source library.\nDocumentation"},{"insert":"\n","attributes":{"header":3}},{"insert":"Quick Start"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Data format and Document Model"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Style attributes"},{"insert":"\n","attributes":{"list":"bullet"}},{"insert":"Heuristic rules"},{"insert":"\n","attributes":{"list":"ordered"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"header":2}},{"insert":"Zefyr’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nimport ‘package:flutter/material.dart’;"},{"insert":"\n","attributes":{"code-block":true}},{"insert":"import ‘package:notus/notus.dart’;"},{"insert":"\n\n","attributes":{"code-block":true}},{"insert":"void main() {"},{"insert":"\n","attributes":{"code-block":true}},{"insert":" print(“Hello world!”);"},{"insert":"\n","attributes":{"code-block":true}},{"insert":"}"},{"insert":"\n","attributes":{"code-block":true}}]';
final quill_doc = Delta.fromJson(json.decode(notus_string) as List);