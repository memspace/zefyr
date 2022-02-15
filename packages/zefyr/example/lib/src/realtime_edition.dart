import 'dart:async';
import 'package:quill_delta/quill_delta.dart';

import 'package:zefyr/zefyr.dart';

class RealtimeEdition {
  StreamSubscription<NotusChange> controllerSub;
  final ZefyrController controller;
  final List<Delta> localChanges = [];

  RealtimeEdition(this.controller) {
    controllerSub = controller.document.changes.listen(_onLocalChanges);
  }

  void dispose() {
    controllerSub.cancel();
  }

  // called when new remote changes are received
  void addRemoteChanges(List<Delta> changes) {
    for (final change in changes) {
      _onReceiveRemoteChanges(change);
    }
  }

  // when our local controller send us changes
  void _onLocalChanges(NotusChange change) {
    final delta = change.change;
    if (change.source == ChangeSource.local) {
      localChanges.add(delta);
    }
  }

  void _onReceiveRemoteChanges(Delta remoteChange) {
    final rebased = <Delta>[];
    Delta rebasedRemoteChange = remoteChange;

    // rebase our local change on the remote change
    // rebase the remote change on our local change
    for (final localChange in localChanges) {
      rebased.add(remoteChange.transform(localChange, true));
      rebasedRemoteChange = localChange.transform(rebasedRemoteChange, false);
    }
    localChanges.clear();
    localChanges.addAll(rebased);

    // apply the rebased remote change locally
    controller.compose(rebasedRemoteChange, source: ChangeSource.remote);
  }
}
