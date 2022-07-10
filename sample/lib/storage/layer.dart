import 'package:sample/storage/output.dart';
import 'package:sample/storage/input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import 'machine.dart';

class StorageLayer extends MachineLayerType<AppEvent, StorageLayerInput, StorageLayerOutput> {
  final SharedPreferences _prefs;

  StorageLayer(this._prefs);

  @override
  Machine<StorageLayerInput, StorageLayerOutput> machine() {
    return StorageMachine(_prefs);
  }

  @override
  StorageLayerInput mapInput(AppEvent event) {
    final int? init = event.initialize;
    if (init != null) {
      return StorageLayerInput.initialize(init);
    } else {
      return StorageLayerInput.increment();
    }
  }

  @override
  AppEvent mapOutput(StorageLayerOutput output) {
    return AppEvent.initialize(output.number);
  }
}
