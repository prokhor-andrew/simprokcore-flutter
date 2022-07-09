## 1.1.5


Removed reducer from core. Now it is just a union of layers where layer is a special machine that 
receives input and emits encapsulating all the possible merging behavior.
If reducer is needed - make it a new layer.
