import 'package:flutter/material.dart';
import 'package:sample/state.dart';
import 'package:sample/storage/layer.dart';
import 'package:sample/ui/layer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simprokcore/simprokcore.dart';

import 'logger/layer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runRootCore<AppState>(
    main: UILayer(),
    secondary: {
      StorageLayer(prefs),
      LoggerLayer(),
    },
  );
}
