// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zefyr/zefyr.dart';

import 'videoPlayer.dart';

/// Custom image delegate used by this example to load image from application
/// assets.
class CustomVideoDelegate implements ZefyrVideoDelegate<ImageSource> {
  @override
  ImageSource get cameraSource => ImageSource.camera;

  @override
  ImageSource get gallerySource => ImageSource.gallery;

  /*@override
  DataSourceType get asset => DataSourceType.asset;

  @override
  DataSourceType get network => DataSourceType.network;

  @override
  DataSourceType get file => DataSourceType.file;*/

  @override
  Future<String> pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.getVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return file.path.toString();
  }

  @override
  Widget buildVideo(BuildContext context, String key) {
    // We use custom "asset" scheme to distinguish asset images from other files.
    if (key.startsWith('asset://')) {
      final asset = key.replaceFirst('asset://', '');
      return VideoApp(video: asset);
    } else {
      return VideoApp();
    }
  }
}
