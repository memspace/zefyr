import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:zefyr/src/rendering/editor.dart';

class MentionSuggestionOverlay {
  final BuildContext context;
  final RenderEditor renderObject;
  final Widget debugRequiredFor;
  final Map<int, String> suggestions;
  final TextEditingValue textEditingValue;
  final Function(int, String) suggestionSelected;
  OverlayEntry overlayEntry;

  MentionSuggestionOverlay({
    @required this.textEditingValue,
    @required this.context,
    @required this.renderObject,
    @required this.debugRequiredFor,
    @required this.suggestions,
    this.suggestionSelected,
  });

  void showSuggestions() {
    overlayEntry = OverlayEntry(
        builder: (context) => _MentionSuggestionList(
              renderObject: renderObject,
              suggestions: suggestions,
              textEditingValue: textEditingValue,
              suggestionSelected: suggestionSelected,
            ));
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor)
        .insert(overlayEntry);
  }

  void hide() {
    overlayEntry.remove();
  }

  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild() {
    overlayEntry.markNeedsBuild();
  }
}

const double listMaxHeight = 200;

class _MentionSuggestionList extends StatelessWidget {
  final RenderEditor renderObject;
  final Map<int, String> suggestions;
  final TextEditingValue textEditingValue;
  final Function(int, String) suggestionSelected;

  const _MentionSuggestionList({
    Key key,
    @required this.renderObject,
    @required this.suggestions,
    @required this.textEditingValue,
    this.suggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final endpoints =
        renderObject.getEndpointsForSelection(textEditingValue.selection);
    final editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );
    final baseLineHeight =
        renderObject.preferredLineHeight(textEditingValue.selection.base);
    final listMaxWidth = editingRegion.width / 2;
    final screenHeight = MediaQuery.of(context).size.height;

    var positionFromTop = endpoints[0].point.dy + editingRegion.top;
    var positionFromRight = editingRegion.width - endpoints[0].point.dx;
    double positionFromLeft;

    if (positionFromTop + listMaxHeight > screenHeight) {
      positionFromTop = positionFromTop - listMaxHeight - baseLineHeight;
    }
    if (positionFromRight + listMaxWidth > editingRegion.width) {
      positionFromRight = null;
      positionFromLeft = endpoints[0].point.dx;
    }

    return Positioned(
      top: positionFromTop,
      right: positionFromRight,
      left: positionFromLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: listMaxWidth, maxHeight: listMaxHeight),
        child: _buildOverlayWidget(context),
      ),
    );
  }

  Widget _buildOverlayWidget(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: IntrinsicWidth(
          child: Column(
            children: suggestions.keys
                .map((key) => _buildListItem(context, key, suggestions[key]))
                .toList(),
            crossAxisAlignment: CrossAxisAlignment.stretch,
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int id, String text) {
    return InkWell(
      onTap: () => suggestionSelected?.call(id, text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
