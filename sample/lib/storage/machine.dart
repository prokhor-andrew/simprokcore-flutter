import 'package:sample/storage/event.dart';
import 'package:sample/storage/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokmachine/simprokmachine.dart';

class StorageMachine
    extends ParentMachine<StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageMachine(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> child() {
    return ProcessMachine.create(
      object: _prefs,
      processor: (
        SharedPreferences prefs,
        StorageLayerState? state,
        Handler<StorageLayerEvent> callback,
      ) {
        const key = "storage";
        if (state != null) {
          // loaded
          prefs.setInt(key, state.number);
        } else {
          // loading
          int number = prefs.getInt(key) ?? 0;
          callback(StorageLayerEvent(number));
        }
      },
    );
  }
}
