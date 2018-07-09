import 'document/attributes.dart';

abstract class NotusEmbed {
  NotusAttribute get attribute;
}

class HorizontalRuleEmbed implements NotusEmbed {
  const HorizontalRuleEmbed();

  @override
  NotusAttribute<Map<String, dynamic>> get attribute =>
      NotusAttribute.embed.horizontalRule;
}

class ImageEmbed implements NotusEmbed {
  const ImageEmbed(this.source) : assert(source != null);
  final String source;

  @override
  NotusAttribute get attribute => NotusAttribute.embed.image(source);
}
