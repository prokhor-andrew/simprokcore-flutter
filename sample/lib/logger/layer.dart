import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import '../state.dart';
import '../utils/void_event.dart';
import 'machine.dart';

class LoggerLayer
    extends ConsumerLayerType<AppState, AppEvent, String, VoidEvent> {
  @override
  Machine<String, VoidEvent> machine() {
    return LoggerMachine();
  }

  @override
  String mapState(AppState state) {
    return "${state.number}";
  }
}
