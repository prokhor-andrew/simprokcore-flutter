import 'package:sample/ui/state.dart';
import 'package:sample/ui/ui.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import '../state.dart';
import 'event.dart';

class UILayer extends WidgetMachineLayerType<AppState, AppEvent, UILayerState,
    UILayerEvent> {
  @override
  WidgetMachine<UILayerState, UILayerEvent> machine() {
    return BasicWidgetMachine();
  }

  @override
  UILayerState mapState(AppState state) {
    return UILayerState("${state.number}");
  }

  @override
  AppEvent mapEvent(UILayerEvent event) {
    return AppEvent.increment();
  }
}
