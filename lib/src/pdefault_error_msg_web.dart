import 'dart:async';
import 'dart:developer' as dev show log;

import 'package:http/http.dart' show ClientException;
import 'postor_exceptions.dart' show PException, CancelledRequestException;

const _defaultOtherErrorMessage = 'An unknown error occurred.';
const _timeoutErrorMessage = 'Operation timeout.';
const _clientErrorMessage = 'Request error.';
const _requestCancelledMessage = 'Request was cancelled.';

/// A default error message handler for web.
///
/// This returns:
/// * "Operation timeout." on [TimeoutException]
/// * "Request error." on [ClientException]
/// * The message on [PException] or "Request was cancelled" on [CancelledRequestException]
/// * [otherErrorMessage] or "An unknown error occurred." on other exceptions
String defaultErrorMessageHandler(
    Object error, StackTrace? stackTrace, String? otherErrorMessage) {
  dev.log(
    '[Default Error Handler] caught an error:\n\n$error\n\ncaused by the following:',
    stackTrace: stackTrace,
  );
  if (error is TimeoutException) {
    return _timeoutErrorMessage;
  } else if (error is ClientException) {
    return _clientErrorMessage;
  } else if (error is PException) {
    if (error is! CancelledRequestException) {
      dev.log('[${error.runtimeType}] Response body: \n${error.message}');
    }
    return error.message ?? _requestCancelledMessage;
  } else {
    return otherErrorMessage ?? _defaultOtherErrorMessage;
  }
}
