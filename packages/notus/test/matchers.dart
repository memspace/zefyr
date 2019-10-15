// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

const isAssertionError = TypeMatcher<AssertionError>();

// ignore: deprecated_member_use
const Matcher throwsAssertionError = Throws(isAssertionError);
