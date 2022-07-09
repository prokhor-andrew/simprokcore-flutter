//
//  simprokcore.dart
//  simprokcore
//
//  Created by Andrey Prokhorenko on 19.12.2021.
//  Copyright (c) 2022 simprok. All rights reserved.

library simprokcore;

import 'package:simprokmachine/simprokmachine.dart';

/// Starts the application flow.
/// [main] - main layer.
/// [secondary] - secondary layers.
void runRootCore<State, Event>({
  required WidgetMachineLayerType<Event, dynamic, dynamic> main,
  required Set<MachineLayerType<Event, dynamic, dynamic>> secondary,
}) {
  final WidgetMachine<Event, Event> mainMachine = main._child();

  final Iterable<Machine<Event, Event>> secondaryMachines = secondary
      .map((MachineLayerType<Event, dynamic, dynamic> e) => e._child());

  final Set<Machine<Event, Event>> machines = List<Machine<Event, Event>>.from(
    secondaryMachines,
  ).toSet();

  final WidgetMachine<Event, Event> root = mergeWidgetMachine(
    main: mainMachine,
    secondary: machines,
  ).redirect(
    (Event output) => Direction<Event>.back(Ward<Event>.single(output)),
  );

  runRootMachine<Event, Event>(root);
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

  Machine<Event, Event> _child() {
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

  WidgetMachine<Event, Event> _child() {
    return machine().outward((Output output) {
      return Ward<Event>.single(mapOutput(output));
    }).inward((Event event) {
      return Ward<Input>.single(mapInput(event));
    });
  }
}

Machine<Event, Event> _implementation<Event, Input, Output>(
  Machine<Input, Output> machine,
  Mapper<Event, Input> stateMapper,
  Mapper<Output, Event> eventMapper,
  _PassDataStrategy strategy,
) {
  return machine.outward((Output output) {
    if (strategy == _PassDataStrategy.both ||
        strategy == _PassDataStrategy.events) {
      return Ward<Event>.single(eventMapper(output));
    } else {
      return Ward<Event>.ignore();
    }
  }).inward((Event event) {
    if (strategy == _PassDataStrategy.both ||
        strategy == _PassDataStrategy.states) {
      return Ward<Input>.single(stateMapper(event));
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

enum _PassDataStrategy { states, events, both }
