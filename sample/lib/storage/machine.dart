import 'package:sample/storage/output.dart';
import 'package:sample/storage/input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokmachine/simprokmachine.dart';

class StorageMachine
    extends ChildMachine<StorageLayerInput, StorageLayerOutput> {
  final SharedPreferences _prefs;

  StorageMachine(this._prefs);

  @override
  void process(StorageLayerInput? input, Handler<StorageLayerOutput> callback) {
    const key = "storage";
    if (input != null) {
      // loaded
      final int? init = input.initialize;
      if (init != null) {
        _prefs.setInt(key, init);
      } else {

      }
    } else {
      // loading
      int number = _prefs.getInt(key) ?? 0;
      callback(StorageLayerOutput(number));
    }
  }
}
