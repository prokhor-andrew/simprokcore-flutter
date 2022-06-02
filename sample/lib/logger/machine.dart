

import 'dart:developer';

import 'package:simprokmachine/simprokmachine.dart';
import '../utils/void_event.dart';


class LoggerMachine extends ChildMachine<String, VoidEvent> {

  @override
  void process(String? input, Handler<VoidEvent> callback) {
    log(input ?? "loading");
  }
}