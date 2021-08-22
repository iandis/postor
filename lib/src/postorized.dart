import 'dart:async' show runZonedGuarded;
import 'dart:developer' as dev show log;

import 'package:meta/meta.dart' show experimental;

typedef ErrorHandlerCallback<E extends Object> = void Function(
    E error, StackTrace stackTrace);

final Map<Type, dynamic> _handlers = {};

ErrorHandlerCallback<Object>? _onElse;

void doNothing(Object e, StackTrace st) {/* do nothing */}

@experimental
class Postorized {
  Postorized(void Function() zonedCallback) : _zonedCallback = zonedCallback;

  final void Function() _zonedCallback;

  void run() {
    return runZonedGuarded(
      _zonedCallback,
      _handleError,
    );
  }

  Postorized on<T extends Object>(ErrorHandlerCallback<T> handle) {
    On<T>(handle);
    return this;
  }

  Postorized onElse(ErrorHandlerCallback handle) {
    OnElse(handle);
    return this;
  }

  void _handleError(Object exception, StackTrace stackTrace) {
    final handler = _handlers[exception.runtimeType];
    if (handler != null) {
      // ignore: void_checks
      return handler(exception, stackTrace);
    } else if (_onElse != null) {
      return _onElse!(exception, stackTrace);
    }
    dev.log(
        '[Postorized] Caught an unhandled error: \n$exception\n$stackTrace');
  }
}

class On<T extends Object> {
  On(ErrorHandlerCallback<T> handle) {
    if (_handlers.containsKey(T)) {
      throw AssertionError('$T handler already exists!');
    }
    _handlers[T] = handle;
  }
}

class OnElse {
  OnElse(ErrorHandlerCallback handle) {
    if (_onElse != null) {
      throw AssertionError("Don't re-assign [onElse]!");
    }
    _onElse = handle;
  }
}
