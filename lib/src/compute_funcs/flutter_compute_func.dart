// Copyright 2014 The Flutter Authors. All rights reserved.
// Licensed under the BSD 3-Clause "New" or "Revised" License.

import 'dart:async' show Completer, FutureOr, Zone;
import 'dart:isolate' show Isolate, ReceivePort, SendPort;

typedef _ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

Future<R> compute<Q,R>(_ComputeCallback<Q,R> callback, Q message) async {
  final ReceivePort resultPort = ReceivePort();
  final ReceivePort exitPort = ReceivePort();
  final ReceivePort errorPort = ReceivePort();
  final Isolate isolate = await Isolate.spawn<_IsolateConfiguration<Q, FutureOr<R>>>(
    _spawn,
    _IsolateConfiguration<Q, FutureOr<R>>(
      callback,
      message,
      resultPort.sendPort,
    ),
    errorsAreFatal: true,
    onExit: exitPort.sendPort,
    onError: errorPort.sendPort,
  );
  final Completer<R> result = Completer<R>();
  errorPort.listen((dynamic errorData) {
    assert(errorData is List<dynamic>);
    assert(errorData.length == 2);
    final Exception exception = Exception(errorData[0]);
    final StackTrace stack = StackTrace.fromString(errorData[1] as String);
    if (result.isCompleted) {
      Zone.current.handleUncaughtError(exception, stack);
    } else {
      result.completeError(exception, stack);
    }
  });
  exitPort.listen((dynamic exitData) {
    if (!result.isCompleted) {
      result.completeError(Exception('Isolate exited without result or error.'));
    }
  });
  resultPort.listen((dynamic resultData) {
    assert(resultData == null || resultData is R);
    if (!result.isCompleted) {
      result.complete(resultData as R);
    }
  });
  await result.future;
  resultPort.close();
  errorPort.close();
  isolate.kill();
  return result.future;
}

class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.resultPort,
  );
  final _ComputeCallback<Q, R> callback;
  final Q message;
  final SendPort resultPort;

  FutureOr<R> apply() => callback(message);
}

Future<void> _spawn<Q, R>(_IsolateConfiguration<Q, FutureOr<R>> configuration) async {
  final FutureOr<R> Function() resultFunc;
  resultFunc = () async {
      final FutureOr<R> applicationResult = await configuration.apply();
      return await applicationResult;
    };
  final R result = await resultFunc();
    
  configuration.resultPort.send(result);
}