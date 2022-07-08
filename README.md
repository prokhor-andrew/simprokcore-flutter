# simprokcore


## Problem

As you know, [simprokmachine](https://github.com/simprok-dev/simprokmachine-flutter) automates all the communication between your applcation's components. But what are those components? There is still a necessity of coming up with an architecture every time the app is created or expanded.

## Solution

```simprokcore``` is a template that removes all headache of designing your application's architecture by providing a simple API that encourages you to separate an application's logic properly. 

## Architecture

The architecture we encourage using is a state machine with multiple subscribers called "layers". 

![architecture](https://github.com/simprok-dev/simprokcore-flutter/blob/main/images/architecture.drawio.png)

The storage machine of the application's state stands as a single source of truth and all other layers update their state according to it. 

## How to use

- Code global state type.
- Code your layers:
  - Code layer's state type.
  - Code layer's event type.
  - Code layer's mapper from global state to layer state.
  - Code layer's global state reducer.
  - Code layer's machine hierarchy.
  - Unite everything above in a class that inherits from ```MachineLayerType```.
- Call ```runRootCore()``` method in your ```main.dart```.
 

## Example 

Check out this [sample](https://github.com/simprok-dev/simprokcore-flutter/tree/main/sample) with a small counter app for a better understanding of the framework's main functions as well as [wiki](https://github.com/simprok-dev/simprokcore-flutter/wiki) for API reference. 

## Usage tips

- Separate layers based on the APIs and libraries usage. 
- Divide the global state into sub states for each feature. 
- Do not overload the global state with the behavior that should not be shared between layers.
- Before coding your layer's machine hierarchy - focus on the mapper and the reducer. 


## Benefits

- All the benefits of [simprokmachine](https://github.com/simprok-dev/simprokmachine-flutter#killer-features)'s package. 
- Lack of necessity to spend time designing your application's architecture.
- Fixed development algorithm.
- Layers depend on the state storage, but the storage never depends on anything as well as layers never depend on each other's implementation.
- Layers are fully interchangeable. You can easily add, remove, or replace any layer from one place of your application.   
- Cross-platform. [Kotlin](https://github.com/simprok-dev/simprokcore-kotlin) and [iOS](https://github.com/simprok-dev/simprokcore-ios) supported.

## Installation

Add the line into pubspec.yaml:

```
dependencies:
    simprokcore: ^1.1.4
```

Now in your Dart code, you can use:


```Dart
import 'package:simprokcore/simprokcore.dart';
```
