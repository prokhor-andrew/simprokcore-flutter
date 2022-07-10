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
void runRootCore<Event>({
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
  Ward<Input> mapInput(Event event);

  /// A mapper that receives machine's output and maps it into application's event.
  Ward<Event> mapOutput(Output output);

  Machine<Event, Event> _child() {
    return _implementation(machine(), mapInput, mapOutput);
  }
}

/// A class that describes a type that represents a layer object.
/// Contains a machine that receives event as input and emits output
/// that is reduced into application's state.
class MachineLayerObject<Event, Input, Output>
    extends MachineLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Event, Ward<Input>> _stateMapper;
  final Mapper<Output, Ward<Event>> _eventMapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [stateMapper] - Triggered every time the global state is changed.
  /// [eventMapper] - Triggered every time the machine sends an output event.
  MachineLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Event, Ward<Input>> stateMapper,
    required Mapper<Output, Ward<Event>> eventMapper,
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
  Ward<Input> mapInput(Event event) {
    return _stateMapper(event);
  }

  /// from MachineLayerType
  @override
  Ward<Event> mapOutput(Output output) {
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
  Ward<Event> mapOutput(Output output) {
    return Ward<Event>.ignore();
  }
}

/// A class that describes a type that represents a
/// layer object that does not produce events.
/// Contains a machine that receives mapped layer state as input and *does not*
/// emit output that is reduced into application's state.
class ConsumerLayerObject<Event, Input, Output>
    extends ConsumerLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Event, Ward<Input>> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [mapper] - Triggered every time the global state is changed.
  ConsumerLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Event, Ward<Input>> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ConsumerLayerType
  @override
  Machine<Input, Output> machine() {
    return _machine;
  }

  /// from ConsumerLayerType
  @override
  Ward<Input> mapInput(Event event) {
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
  Ward<Input> mapInput(Event event) {
    return Ward<Input>.ignore();
  }
}

/// A class that describes a type that represents a
/// layer object that does not consume state.
/// Contains a machine that *does not* receive mapped layer state as input
/// and emits output that is reduced into application's state.
class ProducerLayerObject<Event, Input, Output>
    extends ProducerLayerType<Event, Input, Output> {
  final Machine<Input, Output> _machine;
  final Mapper<Output, Ward<Event>> _mapper;

  /// [machine] - Layer's machine that receives the result of mapper
  /// method and emits event objects that are sent into reducer method.
  /// [reducer] - Triggered every time the machine sends an output event.
  ProducerLayerObject({
    required Machine<Input, Output> machine,
    required Mapper<Output, Ward<Event>> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  /// from ProducerLayerType
  @override
  Machine<Input, Output> machine() {
    return _machine;
  }

  /// from ProducerLayerType
  @override
  Ward<Event> mapOutput(Output output) {
    return _mapper(output);
  }
}

///
abstract class MapInputLayerType<Event, Input>
    extends MachineLayerType<Event, Input, Event> {
  @override
  Ward<Event> mapOutput(Event output) {
    return Ward<Event>.single(output);
  }
}

///
class MapStateLayerObject<Event, Input>
    extends MapInputLayerType<Event, Input> {
  final Machine<Input, Event> _machine;
  final Mapper<Event, Ward<Input>> _mapper;

  MapStateLayerObject({
    required Machine<Input, Event> machine,
    required Mapper<Event, Ward<Input>> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<Input, Event> machine() {
    return _machine;
  }

  @override
  Ward<Input> mapInput(Event event) {
    return _mapper(event);
  }
}

///
abstract class MapOutputLayerType<Event, Output>
    extends MachineLayerType<Event, Event, Output> {
  @override
  Ward<Event> mapInput(Event event) {
    return Ward<Event>.single(event);
  }
}

///
class MapOutputLayerObject<Event, Output>
    extends MapOutputLayerType<Event, Output> {
  final Machine<Event, Output> _machine;
  final Mapper<Output, Ward<Event>> _mapper;

  MapOutputLayerObject({
    required Machine<Event, Output> machine,
    required Mapper<Output, Ward<Event>> mapper,
  })  : _machine = machine,
        _mapper = mapper;

  @override
  Machine<Event, Output> machine() {
    return _machine;
  }

  @override
  Ward<Event> mapOutput(Output output) {
    return _mapper(output);
  }
}

///
abstract class NoMapLayerType<Event>
    extends MachineLayerType<Event, Event, Event> {
  @override
  Ward<Event> mapInput(Event event) {
    return Ward<Event>.single(event);
  }

  @override
  Ward<Event> mapOutput(Event output) {
    return Ward<Event>.single(output);
  }
}

///
class NoMapLayerObject<Event> extends NoMapLayerType<Event> {
  final Machine<Event, Event> _machine;

  NoMapLayerObject({
    required Machine<Event, Event> machine,
  }) : _machine = machine;

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
  Mapper<Event, Ward<Input>> stateMapper,
  Mapper<Output, Ward<Event>> eventMapper,
) {
  return machine.outward((Output output) {
    return eventMapper(output);
  }).inward((Event event) {
    return stateMapper(event);
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
