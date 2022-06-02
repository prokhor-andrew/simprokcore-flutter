import 'package:sample/storage/event.dart';
import 'package:sample/storage/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokmachine/simprokmachine.dart';

class StorageMachine
    extends ChildMachine<StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageMachine(this._prefs);

  @override
  void process(StorageLayerState? input, Handler<StorageLayerEvent> callback) {
    const key = "storage";
    if (input != null) {
      // loaded
      _prefs.setInt(key, input.number);
    } else {
      // loading
      int number = _prefs.getInt(key) ?? 0;
      callback(StorageLayerEvent(number));
    }
  }
}
