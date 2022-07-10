import 'package:sample/ui/input.dart';
import 'package:sample/ui/ui.dart';
import 'package:simprokcore/simprokcore.dart';
import 'package:simprokmachine/simprokmachine.dart';

import '../event.dart';
import 'output.dart';

class UILayer
    extends WidgetMachineLayerType<AppEvent, UILayerInput, UILayerOutput> {
  @override
  WidgetMachine<UILayerInput, UILayerOutput> machine() {
    return UiWidgetMachine();
  }

  @override
  UILayerInput mapInput(AppEvent event) {
    final int? init = event.initialize;
    if (init != null) {
      return UILayerInput.initialize(init);
    } else {
      return UILayerInput.increment();
    }
  }

  @override
  AppEvent mapOutput(UILayerOutput output) {
    return AppEvent.increment();
  }
}
