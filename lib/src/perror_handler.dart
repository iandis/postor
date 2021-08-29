import '/error_handler.dart' show defaultErrorMessageHandler;

typedef _ErrorMessageHandlerCallback = String Function(
  Object error,
  StackTrace? stackTrace,
  String? otherErrorMessage,
);

_ErrorMessageHandlerCallback? _errorHandler;

/// Might be useful for reducing LOCs in methods that have try-catch.
///
/// For example:
/// ```dart
/// Future<void> getTest() async {
///   try {
///     final response = await postor.get('/test').get<List>();
///     print('response: $response');
///   } catch (error, stackTrace) {
///     catchIt(
///       error: error,
///       stackTrace: stackTrace,
///       otherErrorMessage: 'Failed to get response from /test',
///       onCatch: _onError,
///     );
///   }
/// }
///
/// void _onError(String errorMessage) {
///   print(errorMessage);
/// }
/// ```
///
/// Note: in order to use this, an error message handler has to be initialized first
/// using [initErrorMessages]
///
/// ```dart
/// void main() {
///   initErrorMessages((Object error, StackTrace? stackTrace, String? otherErrorMessage) {
///       if(error is TimeoutException) {
///           return 'Operation timeout'.
///       }else{
///           return 'An unknown error occurred.'
///       }
///   });
/// }
/// ```
/// Alternatively, there's [defaultErrorMessageHandler] that can be used.
/// ```dart
/// void main() {
///   initErrorMessages(defaultErrorMessageHandler);
/// }
/// ```
E catchIt<E>({
  required final Object error,
  required final E Function(String errorMessage) onCatch,
  final StackTrace? stackTrace,
  final String? otherErrorMessage,
}) {
  if (_errorHandler != null) {
    final errMessage = _errorHandler!(error, stackTrace, otherErrorMessage);
    return onCatch(errMessage);
  }
  throw AssertionError('No Error Message Handler found!');
}

/// Initializes error message handler. This should be called first before any [catchIt]
/// is called. Also this should be called only once.
///
/// [onError] is a function that must return a `String`
///
/// [otherErrorMessage] is an alternative message in case [error] was not handled by
/// the error message handler.
///
/// For example:
/// ```dart
/// void main() {
///   initErrorMessages((Object error, StackTrace? stackTrace, String? otherErrorMessage) {
///     if(error is SomeError) {
///       return 'SomeError thrown.';
///     }else{
///       return otherErrorMessage ?? 'An unknown error occurred'.
///     }
///   });
///
///   try{
///     throw SomeUnknownError();
///   }catch(e, st) {
///     catchIt(
///       error: error,
///       stackTrace: stackTrace,
///       otherErrorMessage: 'Unknown error.',
///       onCatch: _onError,
///     );
///   }
/// }
///
/// void _onError(String errorMessage) {
///   print(errorMessage);
/// }
/// ```
/// The above example will print "Unknown error."
void initErrorMessages(final _ErrorMessageHandlerCallback onError) {
  if (_errorHandler != null) {
    throw AssertionError('Error Message handler already exists!');
  }
  _errorHandler = onError;
}
