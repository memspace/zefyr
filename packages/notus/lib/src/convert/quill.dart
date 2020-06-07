// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';

class NotusQuillCodec extends Codec<Delta, Delta> {
  const NotusQuillCodec();

  @override
  Converter<Delta, Delta> get decoder => _NotusQuillDecoder();

  @override
  Converter<Delta, Delta> get encoder => _NotusQuillEncoder();
}

class _NotusQuillEncoder extends Converter<Delta, Delta> {
  @override
  Delta convert(Delta input) {
    final result = Delta();

    for (final op in input.toList()) {
      if (!op.isInsert) continue;

      final attributes = <String, dynamic>{};
      op.attributes?.forEach((String key, dynamic value) {
        switch (key) {
          case 'b':
            attributes['bold'] = value;
            break;
          case 'i':
            attributes['italic'] = value;
            break;
          case 'heading':
            attributes['header'] = value;
            break;
          case 'block':
            if (value == 'ul') {
              attributes['list'] = 'bullet';
            } else if (value == 'ol') {
              attributes['list'] = 'ordered';
            } else if (value == 'code') {
              attributes['code-block'] = true;
            } else if (value == 'quote') {
              attributes['blockquote'] = true;
            } else {
              attributes[key] = value;
            }
            break;
          case 'a':
            attributes['link'] = value;
            break;
          default:
            attributes[key] = value;
        }
      });
      result.insert(op.data, attributes.isEmpty ? null : attributes);
    }
    return result;
  }
}

class _NotusQuillDecoder extends Converter<Delta, Delta> {
  @override
  Delta convert(Delta input) {
    final result = Delta();

    for (final op in input.toList()) {
      if (!op.isInsert) continue;

      final attributes = <String, dynamic>{};
      op.attributes?.forEach((String key, dynamic value) {
        switch (key) {
          case 'bold':
            attributes['b'] = value;
            break;
          case 'italic':
            attributes['i'] = value;
            break;
          case 'header':
            attributes['heading'] = value;
            break;
          case 'list':
            if (value == 'bullet') {
              attributes['block'] = 'ul';
            } else if (value == 'ordered') {
              attributes['block'] = 'ol';
            } else {
              attributes[key] = value;
            }
            break;
          case 'link':
            attributes['a'] = value;
            break;
          case 'code-block':
            if (value == true) {
              attributes['block'] = 'code';
            }
            break;
          case 'blockquote':
            if (value == true) {
              attributes['block'] = 'quote';
            }
            break;
          default:
            attributes[key] = value;
        }
      });
      result.insert(op.data, attributes.isEmpty ? null : attributes);
    }
    return result;
  }
}
