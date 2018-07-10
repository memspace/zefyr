// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:notus/notus.dart';

abstract class RenderEditableBox implements RenderBox {
  ContainerNode get node;
  double get preferredLineHeight;
  LayerLink get layerLink;
  TextPosition getPositionForOffset(Offset offset);
  List<ui.TextBox> getEndpointsForSelection(TextSelection selection,
      {bool isLocal: false});
  TextSelection getLocalSelection(TextSelection selection);
  TextRange getWordBoundary(TextPosition position);
}
