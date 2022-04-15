import 'package:sample/ui/state.dart';
import 'package:sample/ui/ui.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../state.dart';
import 'event.dart';

class UILayer
    extends WidgetMachineLayerType<AppState, UILayerState, UILayerEvent> {
  @override
  WidgetMachine<UILayerState, UILayerEvent> machine() {
    return BasicWidgetMachine<UILayerState, UILayerEvent>(child: const MyApp());
  }

  @override
  UILayerState map(AppState state) {
    return UILayerState("${state.number}");
  }

  @override
  ReducerResult<AppState> reduce(AppState? state, UILayerEvent event) {
    final number = state?.number;
    if (number == null) {
      return ReducerResult.skip();
    } else {
      return ReducerResult.set(AppState(number + 1));
    }
  }
}
