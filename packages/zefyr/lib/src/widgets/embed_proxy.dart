import 'package:flutter/widgets.dart';

import '../rendering/embed_proxy.dart';

class EmbedProxy extends SingleChildRenderObjectWidget {
  EmbedProxy({
    required Widget child,
  }) : super(child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) {
    return RenderEmbedProxy();
  }
}
