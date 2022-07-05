## 1.1.3


Changed concept. Now application's state is private to its reducer and 
layers now receive and map into application's event.
ReducerResult.Skip() leaves the same state but never emits event.
ReducerResult.Set() changes state and emits triggering event.
