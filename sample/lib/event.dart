class AppEvent {
  final int? initialize;

  AppEvent.initialize(int value) : initialize = value;

  AppEvent.increment() : initialize = null;
}
