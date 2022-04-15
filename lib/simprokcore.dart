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
void runRootCore<State>({
  required WidgetMachineLayerType<State, dynamic, dynamic> main,
  required Set<MachineLayerType<State, dynamic, dynamic>> secondary,
}) {
  final Machine<_StateAction<State>, _StateAction<State>> reducer =
      _CoreReducerMachine<Mapper<State?, ReducerResult<State>>, State>(
    reducer: (state, event) => event(state),
  ).inward((_StateAction<State> input) {
    if (input.mapper != null) {
      // will update
      return Ward.single(input.mapper!);
    } else {
      // did update
      return Ward.ignore();
    }
  }).outward(
    (State output) => Ward.single(_StateAction<State>.didUpdate(output)),
  );

  final WidgetMachine<_StateAction<State>, _StateAction<State>> mainMachine =
      main._child();

  final Iterable<Machine<_StateAction<State>, _StateAction<State>>>
      secondaryMachines = secondary
          .map((MachineLayerType<State, dynamic, dynamic> e) => e._child());

  final Set<Machine<_StateAction<State>, _StateAction<State>>> machines =
      List<Machine<_StateAction<State>, _StateAction<State>>>.from(
    secondaryMachines,
  ).toSet();
  machines.add(reducer);

  final WidgetMachine<_StateAction<State>, _StateAction<State>> root =
      mergeWidgetMachine(
    main: mainMachine,
    secondary: machines,
  ).redirect(
    (_StateAction<State> output) => Direction<_StateAction<State>>.back(
      Ward<_StateAction<State>>.single(output),
    ),
  );

  runRootMachine<_StateAction<State>, _StateAction<State>>(root);
}

/// A general abstract class that describes a type that represents a layer object.
/// Contains a machine that receives mapped layer state as input and emits output
/// that is reduced into application's state.
abstract class MachineLayerType<GlobalState, State, Event> {
  /// A machine that receives mapped state as input and emits output that
  /// is reduced into application's state.
  Machine<State, Event> machine();

  /// A mapper that maps application's state into layer state
  /// and sends it into machine as input.
  State map(GlobalState state);

  /// A reducer that receives machine's event as output
  /// and reduces it into application's state.
  ReducerResult<GlobalState> reduce(GlobalState? state, Event event);

  Machine<_StateAction<GlobalState>, _StateAction<GlobalState>> _child() {
    return machine()
        .inward(_layerInward(_shouldIgnoreNewState(), map))
        .outward(_layerOutward(reduce));
  }

  bool _shouldIgnoreNewState() {
    return false;
  }
}

/// A class that describes a type that represents a layer object.
/// Contains a machine that receives mapped layer state as input and emits output
/// that is reduced into application's state.
class MachineLayerObject<GlobalState, State, Event>
    extends MachineLayerType<GlobalState, State, Event> {
  final Machine<State, Event> _machine;
  final Mapper<GlobalState, State> _mapper;
  final BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> _reducer;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [mapper] - Triggered every time the global state is changed.
  /// [reducer] - Triggered every time the machine sends an output event.
  MachineLayerObject({
    required Machine<State, Event> machine,
    required Mapper<GlobalState, State> mapper,
    required BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> reducer,
  })  : _machine = machine,
        _mapper = mapper,
        _reducer = reducer;

  /// from MachineLayerType
  @override
  Machine<State, Event> machine() {
    return _machine;
  }

  /// from MachineLayerType
  @override
  State map(GlobalState state) {
    return _mapper(state);
  }

  /// from MachineLayerType
  @override
  ReducerResult<GlobalState> reduce(GlobalState? state, Event event) {
    return _reducer(state, event);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
abstract class ConsumerLayerType<GlobalState, State, Output>
    extends MachineLayerType<GlobalState, State, Output> {
  @override
  ReducerResult<GlobalState> reduce(GlobalState? state, Output event) {
    return ReducerResult.skip();
  }
}

/// A class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
class ConsumerLayerObject<GlobalState, State, Output>
    extends ConsumerLayerType<GlobalState, State, Output> {
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
  State map(GlobalState state) {
    return _mapper(state);
  }
}

/// A general abstract class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
abstract class ProducerLayerType<GlobalState, Event, Input>
    extends MachineLayerType<GlobalState, Input, Event> {
  /// from MachineLayerType
  @override
  Input map(GlobalState state) {
    throw Exception("Must not be reached");
  }

  @override
  bool _shouldIgnoreNewState() {
    return true;
  }
}

/// A class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
class ProducerLayerObject<GlobalState, Event, Input>
    extends ProducerLayerType<GlobalState, Event, Input> {
  final Machine<Input, Event> _machine;
  final BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> _reducer;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [reducer] - Triggered every time the machine sends an output event.
  ProducerLayerObject({
    required Machine<Input, Event> machine,
    required BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> reducer,
  })  : _machine = machine,
        _reducer = reducer;

  /// from ProducerLayerType
  @override
  Machine<Input, Event> machine() {
    return _machine;
  }

  /// from ProducerLayerType
  @override
  ReducerResult<GlobalState> reduce(GlobalState? state, Event event) {
    return _reducer(state, event);
  }
}

/// The same as MachineLayerType but for WidgetMachine.
abstract class WidgetMachineLayerType<GlobalState, State, Event> {
  /// The same as MachineLayerType.machine() but for WidgetMachine.
  /// return the same as MachineLayerType.machine() but for WidgetMachine.
  WidgetMachine<State, Event> machine();

  /// The same as MachineLayerType.map() but for WidgetMachine.
  /// [state] - The same as MachineLayerType.map() but for WidgetMachine.
  /// returns the same as MachineLayerType.map() but for WidgetMachine.
  State map(GlobalState state);

  /// The same as MachineLayerType.reduce() but for WidgetMachine.
  /// [state] - The same as MachineLayerType.reduce() but for WidgetMachine.
  /// [event] - The same as MachineLayerType.reduce() but for WidgetMachine.
  /// returns the same as MachineLayerType.reduce() but for WidgetMachine.
  ReducerResult<GlobalState> reduce(GlobalState? state, Event event);

  WidgetMachine<_StateAction<GlobalState>, _StateAction<GlobalState>> _child() {
    return machine()
        .inward(_layerInward(false, map))
        .outward(_layerOutward(reduce));
  }
}

/// The same as MachineLayerObject but for WidgetMachine.
class WidgetMachineLayerObject<GlobalState, State, Event>
    extends WidgetMachineLayerType<GlobalState, State, Event> {
  final WidgetMachine<State, Event> _machine;
  final Mapper<GlobalState, State> _mapper;
  final BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> _reducer;

  /// [machine] - The same as MachineLayerObject() but for WidgetMachine.
  /// [mapper] - The same as MachineLayerObject() but for WidgetMachine.
  /// [reducer] - The same as MachineLayerObject() but for WidgetMachine.
  WidgetMachineLayerObject({
    required WidgetMachine<State, Event> machine,
    required Mapper<GlobalState, State> mapper,
    required BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> reducer,
  })  : _machine = machine,
        _mapper = mapper,
        _reducer = reducer;

  /// from WidgetMachineLayerType
  @override
  WidgetMachine<State, Event> machine() {
    return _machine;
  }

  /// from WidgetMachineLayerType
  @override
  State map(GlobalState state) {
    return _mapper(state);
  }

  /// from WidgetMachineLayerType
  @override
  ReducerResult<GlobalState> reduce(GlobalState? state, Event event) {
    return _reducer(state, event);
  }
}

class _StateAction<T> {
  final T? state;
  final Mapper<T?, ReducerResult<T>>? mapper;

  _StateAction.didUpdate(this.state) : mapper = null;

  _StateAction.willUpdate(this.mapper) : state = null;
}

Mapper<_StateAction<GlobalState>, Ward<State>> _layerInward<GlobalState, State>(
  bool shouldIgnore,
  Mapper<GlobalState, State> mapper,
) {
  return (_StateAction<GlobalState> input) {
    if (shouldIgnore) {
      return Ward.ignore();
    } else {
      if (input.state != null) {
        return Ward.single(mapper(input.state!));
      } else {
        return Ward.ignore();
      }
    }
  };
}

Mapper<Event, Ward<_StateAction<GlobalState>>>
    _layerOutward<GlobalState, State, Event>(
  BiMapper<GlobalState?, Event, ReducerResult<GlobalState>> reducer,
) {
  return (Event output) {
    return Ward.single(_StateAction.willUpdate(
      (GlobalState? currentState) => reducer(currentState, output),
    ));
  };
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

  _CoreClassicResult.values({
    required this.state,
    required this.outputs,
  });

  _CoreClassicResult.ignore({
    required this.state,
  }) : outputs = [];
}
