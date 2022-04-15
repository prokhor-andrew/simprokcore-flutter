import 'package:sample/storage/event.dart';
import 'package:sample/storage/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../state.dart';
import 'machine.dart';

class StorageLayer
    extends MachineLayerType<AppState, StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageLayer(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> machine() {
    return StorageMachine(_prefs);
  }

  @override
  StorageLayerState map(AppState state) {
    return StorageLayerState(state.number);
  }

  @override
  ReducerResult<AppState> reduce(AppState? state, StorageLayerEvent event) {
    return ReducerResult.set(AppState(event.number));
  }
}
