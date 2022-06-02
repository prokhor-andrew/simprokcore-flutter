import 'package:flutter/material.dart';
import 'package:sample/state.dart';
import 'package:sample/storage/layer.dart';
import 'package:sample/ui/layer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokcore/simprokcore.dart';

import 'event.dart';
import 'logger/layer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runRootCore<AppState, AppEvent>(
    main: UILayer(),
    secondary: {
      StorageLayer(prefs),
      LoggerLayer(),
    },
    reducer: (AppState? state, AppEvent event) {
      final int? initialize = event.initialize;
      if (state != null) {
        if (initialize != null) {
          return ReducerResult<AppState>.skip();
        } else {
          return ReducerResult<AppState>.set(AppState(state.number + 1));
        }
      } else {
        if (initialize != null) {
          return ReducerResult<AppState>.set(AppState(initialize));
        } else {
          return ReducerResult<AppState>.skip();
        }
      }
    },
  );
}
