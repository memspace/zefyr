import 'package:notus/notus.dart';
import 'package:notus/src/document.dart';
import 'package:quill_delta/quill_delta.dart';

///
/// record users operation or api change(Collaborative editing)
/// used for redo or undo function
///
class NotusHistory {
  final NotusHistoryStack stack = NotusHistoryStack.empty();

  /// used for disable redo or undo function
  bool ignoreChange;

  int lastRecorded;

  ///Collaborative editing's conditions should be true
  final bool userOnly;

  ///max operation count for undo
  final int maxStack;

  ///record delay
  final int interval;

  NotusHistory(
      {this.ignoreChange = false,
      this.interval = 400,
      this.maxStack = 100,
      this.userOnly = false,
      this.lastRecorded = 0});

  void handleDocChange(NotusChange event) {
    if (ignoreChange) return;
    if (!userOnly || event.source == ChangeSource.local) {
      record(event.change, event.before);
    } else {
      transform(event.change);
    }
  }

  void clear() {
    stack.clear();
  }

  void record(Delta change, Delta before) {
    if (change.isEmpty) return;
    stack.redo.clear();
    Delta undoDelta = change.invert(before);
    final timeStamp = DateTime.now().millisecondsSinceEpoch;

    if (lastRecorded + interval > timeStamp && stack.undo.isNotEmpty) {
      final lastDelta = stack.undo.removeLast();
      undoDelta = undoDelta.compose(lastDelta);
    } else {
      lastRecorded = timeStamp;
    }

    if (undoDelta.isEmpty) return;
    stack.undo.add(undoDelta);

    if (stack.undo.length > maxStack) {
      stack.undo.removeAt(0);
    }
  }

  ///
  ///It will override pre local undo delta,replaced by remote change
  ///
  void transform(Delta delta) {
    transformStack(this.stack.undo, delta);
    transformStack(this.stack.redo, delta);
  }

  void transformStack(List<Delta> stack, Delta delta) {
    for (int i = stack.length - 1; i >= 0; i -= 1) {
      final oldDelta = stack[i];
      stack[i] = delta.transform(oldDelta, true);
      delta = oldDelta.transform(delta, false);
      if (stack[i].length == 0) {
        stack.removeAt(i);
      }
    }
  }

  void _change(NotusDocument doc, List<Delta> source, List<Delta> dest) {
    if (source.length == 0) return;
    Delta delta = source.removeLast();
    Delta base = doc.toDelta();
    Delta inverseDelta = delta.invert(base);
    dest.add(inverseDelta);
    this.lastRecorded = 0;
    this.ignoreChange = true;
    doc.compose(delta, ChangeSource.local, history: true);
    this.ignoreChange = false;
  }

  void undo(NotusDocument doc) {
    _change(doc, stack.undo, stack.redo);
  }

  void redo(NotusDocument doc) {
    _change(doc, stack.redo, stack.undo);
  }
}

class NotusHistoryStack {
  final List<Delta> undo;
  final List<Delta> redo;

  NotusHistoryStack.empty()
      : undo = [],
        redo = [];

  void clear() {
    undo.clear();
    redo.clear();
  }
}
