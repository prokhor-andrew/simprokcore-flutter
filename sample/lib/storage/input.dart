class StorageLayerInput {
  final int? initialize;

  StorageLayerInput.initialize(int value) : initialize = value;

  StorageLayerInput.increment() : initialize = null;
}
