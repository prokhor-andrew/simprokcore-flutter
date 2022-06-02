//
//  simprokcore.dart
//  simprokcore
//
//  Created by Andrey Prokhorenko on 19.12.2021.
//  Copyright (c) 2022 simprok. All rights reserved.

library simprokcore;

import 'package:simprokmachine/simprokmachine.dart';

/// A type that represents a behavior of a layer's reducer.
class ReducerResult<T> {
  /// value
  final T? value;

  /// Returning this value from layer's `reducer` method ensures
  /// that the state *won't* be changed and emitted .
  ReducerResult.skip() : value = null;

  /// Returning this value from layer's `reducer` method ensures
  /// that the state *will* be changed and emitted.
  ReducerResult.set(T val) : value = val;
}

/// Starts the application flow.
/// [main] - main layer.
/// [secondary] - secondary layers.
void runRootCore<State, Event>({
  required WidgetMachineLayerType<State, Event, dynamic, dynamic> main,
  required Set<MachineLayerType<State, Event, dynamic, dynamic>> secondary,
  required BiMapper<State?, Event, ReducerResult<State>> reducer,
}) {
  final Machine<_StateAction<State, Event>, _StateAction<State, Event>>
      _reducer = _CoreReducerMachine<Event, State>(
    reducer: (State? state, Event event) => reducer(state, event),
  ).inward((_StateAction<State, Event> input) {
    if (input.event != null) {
      // will update
      return Ward.single(input.event!);
    } else {
      // did update
      return Ward.ignore();
    }
  }).outward(
    (State output) => Ward.single(_StateAction<State, Event>.didUpdate(output)),
  );

  final WidgetMachine<_StateAction<State, Event>, _StateAction<State, Event>>
      mainMachine = main._child();

  final Iterable<
          Machine<_StateAction<State, Event>, _StateAction<State, Event>>>
      secondaryMachines = secondary.map(
          (MachineLayerType<State, Event, dynamic, dynamic> e) => e._child());

  final Set<Machine<_StateAction<State, Event>, _StateAction<State, Event>>>
      machines = List<
          Machine<_StateAction<State, Event>, _StateAction<State, Event>>>.from(
    secondaryMachines,
  ).toSet();
  machines.add(_reducer);

  final WidgetMachine<_StateAction<State, Event>, _StateAction<State, Event>>
      root = mergeWidgetMachine(
    main: mainMachine,
    secondary: machines,
  ).redirect(
    (_StateAction<State, Event> output) =>
        Direction<_StateAction<State, Event>>.back(
      Ward<_StateAction<State, Event>>.single(output),
    ),
  );

  runRootMachine<_StateAction<State, Event>, _StateAction<State, Event>>(root);
}

/// A general abstract class that describes a type that represents a layer object.
/// Contains a machine that receives mapped layer state as input and emits output
/// that is reduced into application's state.
abstract class MachineLayerType<GlobalState, GlobalEvent, State, Event> {
  /// A machine that receives mapped state as input and emits output that
  /// is reduced into application's state.
  Machine<State, Event> machine();

  /// A mapper that maps application's state into layer state
  /// and sends it into machine as input.
  State mapState(GlobalState state);

  /// A reducer that receives machine's event as output
  /// and reduces it into application's state.
  GlobalEvent mapEvent(Event event);

  _PassDataStrategy strategy() {
    return _PassDataStrategy.both;
  }

  Machine<_StateAction<GlobalState, GlobalEvent>,
      _StateAction<GlobalState, GlobalEvent>> _child() {
    return _implementation(machine(), mapState, mapEvent, strategy());
  }
}

/// A class that describes a type that represents a layer object.
/// Contains a machine that receives mapped layer state as input and emits output
/// that is reduced into application's state.
class MachineLayerObject<GlobalState, GlobalEvent, State, Event>
    extends MachineLayerType<GlobalState, GlobalEvent, State, Event> {
  final Machine<State, Event> _machine;
  final Mapper<GlobalState, State> _stateMapper;
  final Mapper<Event, GlobalEvent> _eventMapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [stateMapper] - Triggered every time the global state is changed.
  /// [eventMapper] - Triggered every time the machine sends an output event.
  MachineLayerObject({
    required Machine<State, Event> machine,
    required Mapper<GlobalState, State> stateMapper,
    required Mapper<Event, GlobalEvent> eventMapper,
  })  : _machine = machine,
        _stateMapper = stateMapper,
        _eventMapper = eventMapper;

  /// from MachineLayerType
  @override
  Machine<State, Event> machine() {
    return _machine;
  }

  /// from MachineLayerType
  @override
  State mapState(GlobalState state) {
    return _stateMapper(state);
  }

  /// from MachineLayerType
  @override
  GlobalEvent mapEvent(Event event) {
    return _eventMapper(event);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
abstract class ConsumerLayerType<GlobalState, GlobalEvent, State, Event>
    extends MachineLayerType<GlobalState, GlobalEvent, State, Event> {
  @override
  GlobalEvent mapEvent(Event event) {
    throw UnimplementedError("This method must not be called");
  }

  @override
  _PassDataStrategy strategy() {
    return _PassDataStrategy.states;
  }
}

/// A class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
class ConsumerLayerObject<GlobalState, GlobalEvent, State, Output>
    extends ConsumerLayerType<GlobalState, GlobalEvent, State, Output> {
  final Machine<State, Output> _machine;
  final Mapper<GlobalState, State> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [mapper] - Triggered every time the global state is changed.
  ConsumerLayerObject({
    required Machine<State, Output> machine,
    required Mapper<GlobalState, State> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ConsumerLayerType
  @override
  Machine<State, Output> machine() {
    return _machine;
  }

  /// from ConsumerLayerType
  @override
  State mapState(GlobalState state) {
    return _mapper(state);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
abstract class ProducerLayerType<GlobalState, GlobalEvent, State, Event>
    extends MachineLayerType<GlobalState, GlobalEvent, State, Event> {
  /// from MachineLayerType
  @override
  State mapState(GlobalState state) {
    throw UnimplementedError("This method must not be called");
  }

  @override
  _PassDataStrategy strategy() {
    return _PassDataStrategy.events;
  }
}

/// A class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
class ProducerLayerObject<GlobalState, GlobalEvent, State, Event>
    extends ProducerLayerType<GlobalState, GlobalEvent, State, Event> {
  final Machine<State, Event> _machine;
  final Mapper<Event, GlobalEvent> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [reducer] - Triggered every time the machine sends an output event.
  ProducerLayerObject({
    required Machine<State, Event> machine,
    required Mapper<Event, GlobalEvent> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ProducerLayerType
  @override
  Machine<State, Event> machine() {
    return _machine;
  }

  /// from ProducerLayerType
  @override
  GlobalEvent mapEvent(Event event) {
    return _mapper(event);
  }
}

///
abstract class MapStateLayerType<GlobalState, GlobalEvent, State>
    extends MachineLayerType<GlobalState, GlobalEvent, State, GlobalEvent> {
  @override
  GlobalEvent mapEvent(GlobalEvent event) {
    return event;
  }
}

///
class MapStateLayerObject<GlobalState, GlobalEvent, State>
    extends MapStateLayerType<GlobalState, GlobalEvent, State> {
  final Machine<State, GlobalEvent> _machine;
  final Mapper<GlobalState, State> _mapper;

  MapStateLayerObject({
    required Machine<State, GlobalEvent> machine,
    required Mapper<GlobalState, State> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<State, GlobalEvent> machine() {
    return _machine;
  }

  @override
  State mapState(GlobalState state) {
    return _mapper(state);
  }
}

///
abstract class MapEventLayerType<GlobalState, GlobalEvent, Event>
    extends MachineLayerType<GlobalState, GlobalEvent, GlobalState, Event> {
  @override
  GlobalState mapState(GlobalState state) {
    return state;
  }
}

///
class MapEventLayerObject<GlobalState, GlobalEvent, Event>
    extends MapEventLayerType<GlobalState, GlobalEvent, Event> {
  final Machine<GlobalState, Event> _machine;
  final Mapper<Event, GlobalEvent> _mapper;

  MapEventLayerObject({
    required Machine<GlobalState, Event> machine,
    required Mapper<Event, GlobalEvent> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<GlobalState, Event> machine() {
    return _machine;
  }

  @override
  GlobalEvent mapEvent(Event event) {
    return _mapper(event);
  }
}

///
abstract class NoMapLayerType<GlobalState, GlobalEvent>
    extends MachineLayerType<GlobalState, GlobalEvent, GlobalState,
        GlobalEvent> {
  @override
  GlobalState mapState(GlobalState state) {
    return state;
  }

  @override
  GlobalEvent mapEvent(GlobalEvent event) {
    return event;
  }
}

///
class NoMapLayerObject<GlobalState, GlobalEvent>
    extends NoMapLayerType<GlobalState, GlobalEvent> {
  final Machine<GlobalState, GlobalEvent> _machine;

  NoMapLayerObject({required Machine<GlobalState, GlobalEvent> machine})
      : _machine = machine;

  @override
  Machine<GlobalState, GlobalEvent> machine() {
    return _machine;
  }
}

/// The same as MachineLayerType but for WidgetMachine.
abstract class WidgetMachineLayerType<GlobalState, GlobalEvent, State, Event> {
  /// The same as MachineLayerType.machine() but for WidgetMachine.
  /// return the same as MachineLayerType.machine() but for WidgetMachine.
  WidgetMachine<State, Event> machine();

  /// The same as MachineLayerType.map() but for WidgetMachine.
  /// [state] - The same as MachineLayerType.map() but for WidgetMachine.
  /// returns the same as MachineLayerType.map() but for WidgetMachine.
  State mapState(GlobalState state);

  /// The same as MachineLayerType.reduce() but for WidgetMachine.
  /// [event] - The same as MachineLayerType.mapEvent() but for WidgetMachine.
  /// returns the same as MachineLayerType.mapEvent() but for WidgetMachine.
  GlobalEvent mapEvent(Event event);

  WidgetMachine<_StateAction<GlobalState, GlobalEvent>,
      _StateAction<GlobalState, GlobalEvent>> _child() {
    return machine().outward((Event output) {
      return Ward<_StateAction<GlobalState, GlobalEvent>>.single(
        _StateAction<GlobalState, GlobalEvent>.willUpdate(mapEvent(output)),
      );
    }).inward((_StateAction<GlobalState, GlobalEvent> input) {
      final GlobalState? state = input.state;
      if (state != null) {
        return Ward<State>.single(mapState(state));
      } else {
        return Ward<State>.ignore();
      }
    });
  }
}

Machine<_StateAction<GlobalState, GlobalEvent>,
        _StateAction<GlobalState, GlobalEvent>>
    _implementation<GlobalState, GlobalEvent, State, Event>(
  Machine<State, Event> machine,
  Mapper<GlobalState, State> stateMapper,
  Mapper<Event, GlobalEvent> eventMapper,
  _PassDataStrategy strategy,
) {
  return machine.outward((Event output) {
    if (strategy == _PassDataStrategy.both ||
        strategy == _PassDataStrategy.events) {
      return Ward<_StateAction<GlobalState, GlobalEvent>>.single(
        _StateAction<GlobalState, GlobalEvent>.willUpdate(eventMapper(output)),
      );
    } else {
      return Ward<_StateAction<GlobalState, GlobalEvent>>.ignore();
    }
  }).inward((_StateAction<GlobalState, GlobalEvent> input) {
    final GlobalState? state = input.state;
    if (state != null) {
      if (strategy == _PassDataStrategy.both ||
          strategy == _PassDataStrategy.states) {
        return Ward<State>.single(stateMapper(state));
      } else {
        return Ward<State>.ignore();
      }
    } else {
      return Ward<State>.ignore();
    }
  });
}

/// The same as MachineLayerObject but for WidgetMachine.
class WidgetMachineLayerObject<GlobalState, GlobalEvent, State, Event>
    extends WidgetMachineLayerType<GlobalState, GlobalEvent, State, Event> {
  final WidgetMachine<State, Event> _machine;
  final Mapper<GlobalState, State> _stateMapper;
  final Mapper<Event, GlobalEvent> _eventMapper;

  /// [machine] - The same as MachineLayerObject() but for WidgetMachine.
  /// [stateMapper] - The same as MachineLayerObject() but for WidgetMachine.
  /// [eventMapper] - The same as MachineLayerObject() but for WidgetMachine.
  WidgetMachineLayerObject({
    required WidgetMachine<State, Event> machine,
    required Mapper<GlobalState, State> stateMapper,
    required Mapper<Event, GlobalEvent> eventMapper,
  })  : _machine = machine,
        _stateMapper = stateMapper,
        _eventMapper = eventMapper;

  /// from WidgetMachineLayerType
  @override
  WidgetMachine<State, Event> machine() {
    return _machine;
  }

  /// from WidgetMachineLayerType
  @override
  State mapState(GlobalState state) {
    return _stateMapper(state);
  }

  /// from WidgetMachineLayerType
  @override
  GlobalEvent mapEvent(Event event) {
    return _eventMapper(event);
  }
}

class _StateAction<State, Event> {
  final State? state;
  final Event? event;

  _StateAction.didUpdate(State _state)
      : state = _state,
        event = null;

  _StateAction.willUpdate(Event _event)
      : state = null,
        event = _event;
}

class _CoreReducerMachine<Event, State> extends ParentMachine<Event, State> {
  final Machine<Event, State> _machine;

  _CoreReducerMachine({
    required BiMapper<State?, Event, ReducerResult<State>> reducer,
  }) : _machine = _CoreClassicMachine<State?, Event, State>(
          initial: _CoreClassicResult<State?, State>.ignore(
            state: null,
          ),
          reducer: (State? state, Event event) {
            final State? result = reducer(state, event).value;
            if (result != null) {
              return _CoreClassicResult<State?, State>.single(
                state: result,
                output: result,
              );
            } else {
              return _CoreClassicResult<State?, State>.ignore(state: state);
            }
          },
        );

  @override
  Machine<Event, State> child() {
    return _machine;
  }
}

class _CoreClassicMachine<State, Input, Output>
    extends ChildMachine<Input, Output> {
  final BiMapper<State, Input, _CoreClassicResult<State, Output>> _reducer;
  _CoreClassicResult<State, Output> _state;

  _CoreClassicMachine({
    required _CoreClassicResult<State, Output> initial,
    required BiMapper<State, Input, _CoreClassicResult<State, Output>> reducer,
  })  : _state = initial,
        _reducer = reducer;

  @override
  void process(Input? input, Handler<Output> callback) {
    if (input != null) {
      _state = _reducer(_state.state, input);
    }

    for (var element in _state.outputs) {
      callback(element);
    }
  }
}

class _CoreClassicResult<State, Output> {
  final State state;
  final List<Output> outputs;

  _CoreClassicResult.single({
    required this.state,
    required Output output,
  }) : outputs = [output];

  _CoreClassicResult.ignore({
    required this.state,
  }) : outputs = [];
}

enum _PassDataStrategy { states, events, both }
