import 'package:flutter_window_close/flutter_window_close.dart';

mixin Cleanable {
  void registerToClean() {
    ResourceCleaner.instance.add(this);
  }

  Future<void> clean();
}

class ResourceCleaner {
  // instance
  static final ResourceCleaner instance = ResourceCleaner._internal();

  // factory
  factory ResourceCleaner() => instance;

  // constructor
  ResourceCleaner._internal();

  final List<Cleanable> _cleanables = [];

  void add(Cleanable cleanable) {
    _cleanables.add(cleanable);
  }

  void init() {
    _cleanables.clear();
    FlutterWindowClose.setWindowShouldCloseHandler(() async {
      print("cleaning resources: ${_cleanables.length} items");
      for (final cleanable in _cleanables) {
        await cleanable.clean();
      }
      return true;
    });
  }
}
