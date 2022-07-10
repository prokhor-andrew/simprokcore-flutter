import 'package:flutter/material.dart';
import 'package:sample/ui/output.dart';
import 'package:sample/ui/input.dart';
import 'package:simprokmachine/simprokmachine.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Counter app'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MachineConsumer<UiState, UILayerOutput>(
              initial: (BuildContext context) => Text(
                "initial",
                style: Theme.of(context).textTheme.headline4,
              ),
              builder: (context, msg, callback) {
                return Text(
                  msg?.number.toString() ?? "loading",
                  style: Theme.of(context).textTheme.headline4,
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: MachineConsumer<UiState, UILayerOutput>(
          initial: (_) => const Text(""),
          builder: (context, input, callback) {
            return FloatingActionButton(
              onPressed: () => callback(UILayerOutput()),
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            );
          }),
    );
  }
}

class BasicWidgetMachine extends ChildWidgetMachine<UiState, UILayerOutput> {
  @override
  Widget child() {
    return const MyApp();
  }
}

class UiWidgetMachine extends ParentWidgetMachine<UILayerInput, UILayerOutput> {
  @override
  WidgetMachine<UILayerInput, UILayerOutput> child() {
    final WidgetMachine<UiData, UiData> uiMachine =
        BasicWidgetMachine().outward((UILayerOutput output) {
      return Ward<UiData>.single(UiData.fromUi(output));
    }).inward((UiData input) {
      final UiState? toUiData = input.toUiData;
      if (toUiData != null) {
        return Ward<UiState>.single(toUiData);
      } else {
        return Ward<UiState>.ignore();
      }
    });

    final Machine<UiData, UiData> reducer =
        UiReducerMachine().outward((UiState state) {
      return Ward<UiData>.single(UiData.toUi(state));
    }).inward((UiData data) {
      final UILayerInput? input = data.toReducerData;
      if (input != null) {
        return Ward<UILayerInput>.single(input);
      } else {
        return Ward<UILayerInput>.ignore();
      }
    });

    return uiMachine.mergeWith({reducer}).outward((UiData output) {
      final UILayerOutput? fromUi = output.fromUiData;
      if (fromUi != null) {
        return Ward<UILayerOutput>.single(fromUi);
      } else {
        return Ward<UILayerOutput>.ignore();
      }
    }).inward((UILayerInput input) {
      return Ward<UiData>.single(UiData.toReducer(input));
    });
  }
}

class UiState {
  final int number;

  UiState(this.number);
}

class UiReducerMachine extends ChildMachine<UILayerInput, UiState> {
  int state = 0;

  @override
  void process(UILayerInput? input, Handler<UiState> callback) {
    if (input != null) {
      final int? init = input.initialize;
      if (init != null) {
        state = init;
      } else {
        state += 1;
      }
      callback(UiState(state));
    } else {}
  }
}

class UiData {
  final UILayerInput? toReducerData;
  final UiState? toUiData;
  final UILayerOutput? fromUiData;

  UiData.toUi(UiState _toUiData)
      : toUiData = _toUiData,
        fromUiData = null,
        toReducerData = null;

  UiData.fromUi(UILayerOutput _fromUiData)
      : fromUiData = _fromUiData,
        toUiData = null,
        toReducerData = null;

  UiData.toReducer(UILayerInput _toReducerData)
      : fromUiData = null,
        toUiData = null,
        toReducerData = _toReducerData;
}
