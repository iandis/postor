import 'dart:async';
import 'dart:developer' as dev show log;
import 'dart:io' show SocketException;

import 'postor_exceptions.dart' show PException, CancelledRequestException;

const _defaultOtherErrorMessage = 'An unknown error occurred.';
const _timeoutErrorMessage = 'Operation timeout.';
const _socketErrorMessage = 'No connection.';
const _requestCancelledMessage = 'Request was cancelled.';

/// A default error message handler for other platform besides web.
/// 
/// This returns:
/// * "Operation timeout." on [TimeoutException]
/// * "No connection." on [SocketException]
/// * The message on [PException] or "Request was cancelled" on [CancelledRequestException]
/// * [otherErrorMessage] or "An unknown error occurred." on other exceptions 
String defaultErrorMessageHandler(Object error, StackTrace? stackTrace, String? otherErrorMessage) {
  dev.log(
    '[Default Error Handler] caught an error:\n\n$error\n\ncaused by the following:',
    stackTrace: stackTrace,
  );
  if (error is TimeoutException) {
    return _timeoutErrorMessage;
  } else if (error is SocketException) {
    return _socketErrorMessage;
  } else if (error is PException) {
    if (error is! CancelledRequestException) {
      dev.log('[${error.runtimeType}] Response body: \n${error.message}');
    }
    return error.message ?? _requestCancelledMessage;
  } else {
    return otherErrorMessage ?? _defaultOtherErrorMessage;
  }
}
