import 'dart:async' show runZonedGuarded;
import 'dart:developer' as dev show log;

typedef ErrorHandlerCallback<E extends Object> = void Function(E error, StackTrace stackTrace);

final Map<Type, dynamic> _handlers = {};

ErrorHandlerCallback<Object>? _onElse;

void doNothing(Object e, StackTrace st) {/* do nothing */}

@Deprecated(
  'This is kind of useless, as other libraries like [Catcher] has more functionalities than this. '
  "If you want to handle error locally, use [catchIt] instead",
)
class Postorized {
  @Deprecated(
    'This is kind of useless, as other libraries like [Catcher] has more functionalities than this. '
    "If you want to handle error locally, use [catchIt] instead",
  )
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
    dev.log('[Postorized] Caught an unhandled error: \n$exception\n$stackTrace');
  }
}

@Deprecated(
  'This is useless since [Postorized] is deprecated',
)
class On<T extends Object> {
  @Deprecated(
    'This is useless since [Postorized] is deprecated',
  )
  On(ErrorHandlerCallback<T> handle) {
    if (_handlers.containsKey(T)) {
      throw AssertionError('$T handler already exists!');
    }
    _handlers[T] = handle;
  }
}

@Deprecated(
  'This is useless since [Postorized] is deprecated',
)
class OnElse {
  @Deprecated(
    'This is useless since [Postorized] is deprecated',
  )
  OnElse(ErrorHandlerCallback handle) {
    if (_onElse != null) {
      throw AssertionError("Don't re-assign [onElse]!");
    }
    _onElse = handle;
  }
}
