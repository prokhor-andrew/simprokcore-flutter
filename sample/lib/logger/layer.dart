import 'dart:developer';

import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../state.dart';
import '../utils/void_event.dart';

class LoggerLayer extends ConsumerLayerType<AppState, String, VoidEvent> {
  @override
  Machine<String, VoidEvent> machine() {
    return BasicMachine<String, VoidEvent>(
        processor: (String? event, _) => log(event ?? "loading"));
  }

  @override
  String map(AppState state) {
    return "${state.number}";
  }
}
