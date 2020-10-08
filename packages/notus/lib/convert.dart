// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides codecs to convert Notus documents to other formats.
library notus.convert;

import 'src/convert/markdown.dart';
import 'src/convert/quill.dart';

export 'src/convert/markdown.dart';
export 'src/convert/quill.dart';

/// Markdown codec for Notus documents.
const NotusMarkdownCodec notusMarkdown = NotusMarkdownCodec();
const NotusQuillCodec notusQuill = NotusQuillCodec();
