import 'package:sample/logger/logger_input.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import '../utils/void_event.dart';
import 'machine.dart';

class LoggerLayer extends ConsumerLayerType<AppEvent, LoggerInput, VoidEvent> {

  @override
  Machine<LoggerInput, VoidEvent> machine() {
    return LoggerMachine();
  }

  @override
  LoggerInput mapInput(AppEvent event) {
    final int? initialize = event.initialize;
    if (initialize != null) {
      return LoggerInput.initialize(initialize);
    } else {
      return LoggerInput.increment();
    }
  }
}
