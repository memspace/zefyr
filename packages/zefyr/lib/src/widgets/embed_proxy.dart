import 'package:flutter/widgets.dart';

import '../rendering/embed_proxy.dart';

class EmbedProxy extends SingleChildRenderObjectWidget {
  const EmbedProxy({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderEmbedProxy createRenderObject(BuildContext context) {
    return RenderEmbedProxy();
  }
}
