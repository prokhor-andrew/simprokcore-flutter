import 'package:sample/storage/event.dart';
import 'package:sample/storage/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import '../state.dart';
import 'machine.dart';

class StorageLayer extends MachineLayerType<AppState, AppEvent,
    StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageLayer(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> machine() {
    return StorageMachine(_prefs);
  }

  @override
  StorageLayerState mapState(AppState state) {
    return StorageLayerState(state.number);
  }

  @override
  AppEvent mapEvent(StorageLayerEvent event) {
    return AppEvent.initialize(event.number);
  }
}
