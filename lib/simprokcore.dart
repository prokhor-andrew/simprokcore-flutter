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
  required WidgetMachineLayerType<Event, dynamic, dynamic> main,
  required Set<MachineLayerType<Event, dynamic, dynamic>> secondary,
  required BiMapper<State?, Event, ReducerResult<State>> reducer,
}) {
  _CoreClassicMachine<State?, Event, Event> classic = _CoreClassicMachine(
      initial: _CoreClassicResult<State?, Event>.ignore(state: null),
      reducer: (State? state, Event event) {
        final ReducerResult<State> result = reducer(state, event);
        final State? newState = result.value;
        if (newState == null) {
          // skip
          return _CoreClassicResult<State?, Event>.ignore(state: state);
        } else {
          return _CoreClassicResult<State?, Event>.single(
            state: newState,
            output: event,
          );
        }
      });

  final Machine<_StateAction<Event>, _StateAction<Event>> _reducer =
      classic.outward((Event event) {
    return Ward<_StateAction<Event>>.single(
      _StateAction<Event>.didUpdate(event),
    );
  }).inward((_StateAction<Event> stateAction) {
    if (stateAction.didUpdate) {
      return Ward<Event>.ignore();
    } else {
      return Ward<Event>.single(stateAction.event);
    }
  });

  final WidgetMachine<_StateAction<Event>, _StateAction<Event>> mainMachine =
      main._child();

  final Iterable<Machine<_StateAction<Event>, _StateAction<Event>>>
      secondaryMachines = secondary
          .map((MachineLayerType<Event, dynamic, dynamic> e) => e._child());

  final Set<Machine<_StateAction<Event>, _StateAction<Event>>> machines =
      List<Machine<_StateAction<Event>, _StateAction<Event>>>.from(
    secondaryMachines,
  ).toSet();
  machines.add(_reducer);

  final WidgetMachine<_StateAction<Event>, _StateAction<Event>> root =
      mergeWidgetMachine(
    main: mainMachine,
    secondary: machines,
  ).redirect(
    (_StateAction<Event> output) => Direction<_StateAction<Event>>.back(
      Ward<_StateAction<Event>>.single(output),
    ),
  );

  runRootMachine<_StateAction<Event>, _StateAction<Event>>(root);
}

/// A general abstract class that describes a type that represents a layer object.
/// Contains a machine that receives mapped input and emits output
/// that is reduced into application's state.
abstract class MachineLayerType<Event, Input, Output> {
  /// A machine that receives mapped input and emits output that
  /// is reduced into application's state.
  Machine<Input, Output> machine();

  /// A mapper that maps application's event into layer input
  /// and sends it into machine.
  Input mapInput(Event event);

  /// A mapper that receives machine's output and maps it into application's event.
  Event mapOutput(Output output);

  _PassDataStrategy strategy() {
    return _PassDataStrategy.both;
  }

  Machine<_StateAction<Event>, _StateAction<Event>> _child() {
    return _implementation(machine(), mapInput, mapOutput, strategy());
  }
}

/// A class that describes a type that represents a layer object.
/// Contains a machine that receives event as input and emits output
/// that is reduced into application's state.
class MachineLayerObject<Event, Input, Output>
    extends MachineLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Event, Input> _stateMapper;
  final Mapper<Output, Event> _eventMapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [stateMapper] - Triggered every time the global state is changed.
  /// [eventMapper] - Triggered every time the machine sends an output event.
  MachineLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Event, Input> stateMapper,
    required Mapper<Output, Event> eventMapper,
  })  : _machine = machine,
        _stateMapper = stateMapper,
        _eventMapper = eventMapper;

  /// from MachineLayerType
  @override
  Machine<Input, Output> machine() {
    return _machine;
  }

  /// from MachineLayerType
  @override
  Input mapInput(Event event) {
    return _stateMapper(event);
  }

  /// from MachineLayerType
  @override
  Event mapOutput(Output output) {
    return _eventMapper(output);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
abstract class ConsumerLayerType<Event, Input, Output>
    extends MachineLayerType<Event, Input, Output> {
  @override
  Event mapOutput(Output output) {
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
class ConsumerLayerObject<Event, Input, Output>
    extends ConsumerLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Event, Input> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [mapper] - Triggered every time the global state is changed.
  ConsumerLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Event, Input> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ConsumerLayerType
  @override
  Machine<Input, Output> machine() {
    return _machine;
  }

  /// from ConsumerLayerType
  @override
  Input mapInput(Event event) {
    return _mapper(event);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
abstract class ProducerLayerType<Event, Input, Output>
    extends MachineLayerType<Event, Input, Output> {
  /// from MachineLayerType
  @override
  Input mapInput(Event event) {
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
class ProducerLayerObject<Event, Input, Output>
    extends ProducerLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Output, Event> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [reducer] - Triggered every time the machine sends an output event.
  ProducerLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Output, Event> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ProducerLayerType
  @override
  Machine<Input, Output> machine() {
    return _machine;
  }

  /// from ProducerLayerType
  @override
  Event mapOutput(Output output) {
    return _mapper(output);
  }
}

///
abstract class MapInputLayerType<Event, Input>
    extends MachineLayerType<Event, Input, Event> {
  @override
  Event mapOutput(Event output) {
    return output;
  }
}

///
class MapStateLayerObject<Event, Input>
    extends MapInputLayerType<Event, Input> {
  final Machine<Input, Event> _machine;
  final Mapper<Event, Input> _mapper;

  MapStateLayerObject({
    required Machine<Input, Event> machine,
    required Mapper<Event, Input> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<Input, Event> machine() {
    return _machine;
  }

  @override
  Input mapInput(Event event) {
    return _mapper(event);
  }
}

///
abstract class MapOutputLayerType<Event, Output>
    extends MachineLayerType<Event, Event, Output> {
  @override
  Event mapInput(Event event) {
    return event;
  }
}

///
class MapOutputLayerObject<Event, Output>
    extends MapOutputLayerType<Event, Output> {
  final Machine<Event, Output> _machine;
  final Mapper<Output, Event> _mapper;

  MapOutputLayerObject({
    required Machine<Event, Output> machine,
    required Mapper<Output, Event> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<Event, Output> machine() {
    return _machine;
  }

  @override
  Event mapOutput(Output output) {
    return _mapper(output);
  }
}

///
abstract class NoMapLayerType<Event>
    extends MachineLayerType<Event, Event, Event> {
  @override
  Event mapInput(Event event) {
    return event;
  }

  @override
  Event mapOutput(Event output) {
    return output;
  }
}

///
class NoMapLayerObject<Event> extends NoMapLayerType<Event> {
  final Machine<Event, Event> _machine;

  NoMapLayerObject({required Machine<Event, Event> machine})
      : _machine = machine;

  @override
  Machine<Event, Event> machine() {
    return _machine;
  }
}

/// The same as MachineLayerType but for WidgetMachine.
abstract class WidgetMachineLayerType<Event, Input, Output> {
  /// The same as MachineLayerType.machine() but for WidgetMachine.
  /// return the same as MachineLayerType.machine() but for WidgetMachine.
  WidgetMachine<Input, Output> machine();

  /// The same as MachineLayerType.map() but for WidgetMachine.
  /// [state] - The same as MachineLayerType.map() but for WidgetMachine.
  /// returns the same as MachineLayerType.map() but for WidgetMachine.

  Input mapInput(Event event);

  /// The same as MachineLayerType.reduce() but for WidgetMachine.
  /// [event] - The same as MachineLayerType.mapEvent() but for WidgetMachine.
  /// returns the same as MachineLayerType.mapEvent() but for WidgetMachine.
  Event mapOutput(Output output);

  WidgetMachine<_StateAction<Event>, _StateAction<Event>> _child() {
    return machine().outward((Output output) {
      return Ward<_StateAction<Event>>.single(
        _StateAction<Event>.willUpdate(mapOutput(output)),
      );
    }).inward((_StateAction<Event> input) {
      final Event event = input.event;
      if (input.didUpdate) {
        return Ward<Input>.single(mapInput(event));
      } else {
        return Ward<Input>.ignore();
      }
    });
  }
}

Machine<_StateAction<Event>, _StateAction<Event>>
    _implementation<Event, Input, Output>(
  Machine<Input, Output> machine,
  Mapper<Event, Input> stateMapper,
  Mapper<Output, Event> eventMapper,
  _PassDataStrategy strategy,
) {
  return machine.outward((Output output) {
    if (strategy == _PassDataStrategy.both ||
        strategy == _PassDataStrategy.events) {
      return Ward<_StateAction<Event>>.single(
        _StateAction<Event>.willUpdate(eventMapper(output)),
      );
    } else {
      return Ward<_StateAction<Event>>.ignore();
    }
  }).inward((_StateAction<Event> input) {
    final Event event = input.event;
    if (input.didUpdate) {
      if (strategy == _PassDataStrategy.both ||
          strategy == _PassDataStrategy.states) {
        return Ward<Input>.single(stateMapper(event));
      } else {
        return Ward<Input>.ignore();
      }
    } else {
      return Ward<Input>.ignore();
    }
  });
}

/// The same as MachineLayerObject but for WidgetMachine.
class WidgetMachineLayerObject<Event, Input, Output>
    extends WidgetMachineLayerType<Event, Input, Output> {
  final WidgetMachine<Input, Output> _machine;
  final Mapper<Event, Input> _stateMapper;
  final Mapper<Output, Event> _eventMapper;

  /// [machine] - The same as MachineLayerObject() but for WidgetMachine.
  /// [stateMapper] - The same as MachineLayerObject() but for WidgetMachine.
  /// [eventMapper] - The same as MachineLayerObject() but for WidgetMachine.
  WidgetMachineLayerObject({
    required WidgetMachine<Input, Output> machine,
    required Mapper<Event, Input> stateMapper,
    required Mapper<Output, Event> eventMapper,
  })  : _machine = machine,
        _stateMapper = stateMapper,
        _eventMapper = eventMapper;

  /// from WidgetMachineLayerType
  @override
  WidgetMachine<Input, Output> machine() {
    return _machine;
  }

  /// from WidgetMachineLayerType
  @override
  Input mapInput(Event event) {
    return _stateMapper(event);
  }

  /// from WidgetMachineLayerType
  @override
  Event mapOutput(Output output) {
    return _eventMapper(output);
  }
}

class _StateAction<Event> {
  final Event event;
  final bool didUpdate;

  _StateAction.didUpdate(Event _event)
      : didUpdate = true,
        event = _event;

  _StateAction.willUpdate(Event _event)
      : didUpdate = false,
        event = _event;
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
