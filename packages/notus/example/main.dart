// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:notus/notus.dart';

void main() {
  final doc = NotusDocument();
  // Modify this document with insert, delete and format operations
  doc.insert(
      0, 'Notus package provides rich text document model for Zefyr editor');
  doc.format(0, 5, NotusAttribute.bold); // Makes first word bold.
  doc.format(0, 0, NotusAttribute.h1); // Makes first line a heading.
  doc.delete(23, 10); // Deletes "rich text " segment.

  // Collects style attributes at 1 character in this document.
  doc.collectStyle(1, 0); // returned style would include "bold" and "h1".

  // Listen to all changes applied to this document.
  doc.changes.listen((change) {
    print(change);
  });

  // Dispose resources allocated by this document, e.g. closes "changes" stream.
  // After document is closed it cannot be modified.
  doc.close();
}
