# [simprokcore](https://github.com/simprok-dev/simprokcore-flutter) sample

## Introduction

This sample is created to showcase the main features of the framework. In order to demonstrate the simplicity of it comparing to the basic example, we are making the same [sample](https://github.com/simprok-dev/simprokmachine-flutter/tree/main/sample) as in ```simprokmachine```.


The sample is divided into 9 easy steps demonstrating the flow of the app development and API usage.


## Step 0 - Describe application's behavior

Let's assume we want to create a counter app that shows a number on the screen and logcat each time it is incremented. When we reopen the app we want to see the same number. So the state must be saved in persistent storage. 


## Step 1 - Code application's state

Here is our global state of the application.

```Dart
class AppState {
  int number;

  AppState(this.number);
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
class UILayer extends WidgetMachineLayerType<AppState, UILayerState, UILayerEvent> {
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
class StorageMachine extends ParentMachine<StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageMachine(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> child() {
    return ProcessMachine.create(
      object: _prefs,
      processor: (
        SharedPreferences prefs,
        StorageLayerState? state,
        Handler<StorageLayerEvent> callback,
      ) {
        const key = "storage";
        if (state != null) {
          // loaded
          prefs.setInt(key, state.number);
        } else {
          // loading
          int number = prefs.getInt(key) ?? 0;
          callback(StorageLayerEvent(number));
        }
      },
    );
  }
}
```

- Layer class:

```Dart
class StorageLayer extends MachineLayerType<AppState, StorageLayerState, StorageLayerEvent> {
  final SharedPreferences _prefs;

  StorageLayer(this._prefs);

  @override
  Machine<StorageLayerState, StorageLayerEvent> machine() {
    return StorageMachine(_prefs);
  }

  @override
  StorageLayerState map(AppState state) {
    return StorageLayerState(state.number);
  }

  @override
  ReducerResult<AppState> reduce(AppState? state, StorageLayerEvent event) {
    return ReducerResult.set(AppState(event.number));
  }
}
```

## Step 6 - Code Logger layer

- State is going to be ```String```.

- Event is going to be ```VoidEvent``` as we don't send any events.

- Machine hierarchy not needed, as we can use ```BasicMachine``` class.

- Layer class:

```Dart
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
```
    
## Step 7 - Code main function
    
Now when we have all layers prepared we must connect them together. To do this, we need to call ```runRootCore()``` providing arguments. 

```Dart
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
```

## Step 8 - Enjoy yourself once again

Run the app and see how things are working.


![result](https://github.com/simprok-dev/simprokcore-flutter/blob/main/sample/images/results.gif)


## To sum up

As you can see this template is way simpler and more straightforward than using a ```simprokmachine``` for your architectural design.
