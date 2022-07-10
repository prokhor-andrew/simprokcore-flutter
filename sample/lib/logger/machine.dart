import 'dart:developer';

import 'package:simprokmachine/simprokmachine.dart';

import '../utils/void_event.dart';
import 'logger_input.dart';

class LoggerMachine extends ChildMachine<LoggerInput, VoidEvent> {
  int _state = 0;

  @override
  void process(LoggerInput? input, Handler<VoidEvent> callback) {
    if (input != null) {
      final int? init = input.initialize;
      if (init != null) {
        _state = init;
      } else {
        _state += 1;
      }
      log("$_state");
    } else {
      log("loading");
    }
  }
}
