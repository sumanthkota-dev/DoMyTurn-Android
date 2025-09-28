import 'dart:async';

class Lock {
  Completer<void>? _completer;

  Future<T> synchronized<T>(Future<T> Function() func) async {
    while (_completer != null) {
      await _completer!.future;
    }

    _completer = Completer<void>();
    try {
      return await func();
    } finally {
      _completer?.complete();
      _completer = null;
    }
  }
}
