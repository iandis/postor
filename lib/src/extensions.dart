import 'dart:async' show FutureOr;
import 'dart:convert' show jsonDecode;
import 'package:http/http.dart' show Response;
import 'postor_exceptions.dart' show PException, transformStatusCodeToException;

typedef _SyncAsyncJsonDecoderCallback = FutureOr<dynamic> Function(String source);

_SyncAsyncJsonDecoderCallback? _jsonDecoder;

extension GetResponseExtension on Future<Response> {
  /// returns a result of [T] if `response.statusCode` equals to [expectedStatusCode]
  ///
  /// throws [PException] otherwise
  ///
  /// this will also check if [defaultJsonDecoder] has been set,
  /// if true then this uses it instead of [jsonDecode]
  Future<T> get<T>([int expectedStatusCode = 200]) async {
    final response = await this;

    if (response.statusCode != expectedStatusCode) {
      throw transformStatusCodeToException(
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    if (_jsonDecoder != null) {
      final decoded = await _jsonDecoder!(response.body);
      return decoded as T;
    }
    return jsonDecode(response.body) as T;
  }
}

/// set default json decoder for [GetResponseExtension.get]
set defaultJsonDecoder(_SyncAsyncJsonDecoderCallback jsonDecoderCallback) {
  if (_jsonDecoder == null) {
    _jsonDecoder = jsonDecoderCallback;
  } else {
    throw AssertionError('Json Decoder already defined!');
  }
}
