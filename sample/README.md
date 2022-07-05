# [simprokcore](https://github.com/simprok-dev/simprokcore-flutter) sample

## Introduction

This sample is created to showcase the main features of the framework. In order to demonstrate the simplicity of it comparing to the basic example, we are making the same [sample](https://github.com/simprok-dev/simprokmachine-flutter/tree/main/sample) as in ```simprokmachine```.


The sample is divided into 9 easy steps demonstrating the flow of the app development and API usage.


## Step 0 - Describe application's behavior

Let's assume we want to create a counter app that shows a number on the screen and logcat each time it is incremented. When we reopen the app we want to see the same number. So the state must be saved in persistent storage. 


## Step 1 - Code application's state and event

Here is our global state of the application.

```Dart
class AppState {
  int number;

  AppState(this.number);
}
```

Here are our events of the application.

```Dart
class AppEvent {
  final int? initialize;

  AppEvent.initialize(int value) : initialize = value;

  AppEvent.increment() : initialize = null;
}
```


## Step 2 - List down APIs

Here is our APIs we are going to use.

- ```Flutter widgets```
- ```SharedPreferences```
- ```log()```

Each API is going to be our layer.

## Step 3 - Code UI layer

- State:

```Dart
class UILayerState {
  final String text;

  UILayerState(this.text);
}

```

- Event:

```Dart
class UILayerEvent {}
```

- App widgets: 

```Dart
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
            MachineConsumer<UILayerState, UILayerEvent>(
              initial: (BuildContext context) => Text(
                "initial",
                style: Theme.of(context).textTheme.headline4,
              ),
              builder: (BuildContext context, UILayerState? msg,
                  Handler<UILayerEvent> callback) {
                return Text(
                  msg?.text ?? "loading",
                  style: Theme.of(context).textTheme.headline4,
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: MachineConsumer<UILayerState, UILayerEvent>(
        initial: (_) => const Text(""),
        builder: (BuildContext context, UILayerState? _,
                Handler<UILayerEvent> callback) =>
            FloatingActionButton(
          onPressed: () => callback(UILayerEvent()),
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
```

- Layer class:

```Dart
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
```

## Step 4 - Code storage layer

- State:

```Dart
class StorageLayerState {
  final int number;

  StorageLayerState(this.number);
}
```

- Event:

```Dart
class StorageLayerEvent {
  final int number;

  StorageLayerEvent(this.number);
}
```

- Machine hierarchy:

```Dart
class StorageMachine
    extends ChildMachine<StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageMachine(this._prefs);

  @override
  void process(StorageLayerState? input, Handler<StorageLayerEvent> callback) {
    const key = "storage";
    if (input != null) {
      // loaded
      _prefs.setInt(key, input.number);
    } else {
      // loading
      int number = _prefs.getInt(key) ?? 0;
      callback(StorageLayerEvent(number));
    }
  }
}
```

- Layer class:

```Dart
class StorageLayer extends MachineLayerType<AppState, AppEvent,
    StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageLayer(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> machine() {
    return StorageMachine(_prefs);
  }

  @override
  StorageLayerState mapState(AppState state) {
    return StorageLayerState(state.number);
  }

  @override
  AppEvent mapEvent(StorageLayerEvent event) {
    return AppEvent.initialize(event.number);
  }
}
```

## Step 6 - Code Logger layer

- State is going to be ```String```.

- Event is going to be ```VoidEvent``` as we don't send any events.

- Logger machine:

```Dart
class LoggerMachine extends ChildMachine<String, VoidEvent> {

  @override
  void process(String? input, Handler<VoidEvent> callback) {
    log(input ?? "loading");
  }
}
```

- Layer class:

```Dart
class LoggerLayer
    extends ConsumerLayerType<AppState, AppEvent, String, VoidEvent> {
  @override
  Machine<String, VoidEvent> machine() {
    return LoggerMachine();
  }

  @override
  String mapState(AppState state) {
    return "${state.number}";
  }
}
```
    
## Step 7 - Code main function
    
Now when we have all layers prepared we must connect them together. To do this, we need to call ```runRootCore()``` providing arguments. 

```Dart
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
```

## Step 8 - Enjoy yourself once again

Run the app and see how things are working.


![result](https://github.com/simprok-dev/simprokcore-flutter/blob/main/sample/images/results.gif)


## To sum up

As you can see this template is way simpler and more straightforward than using a ```simprokmachine``` for your architectural design.
