import 'dart:async' show FutureOr, TimeoutException;
import 'dart:convert' show Encoding, utf8;
import 'dart:io' show File, SocketException;

import 'package:ctmanager/ctmanager.dart' show CTManager;
import 'package:http/http.dart' show BaseRequest, Client, MultipartFile, MultipartRequest, Response, StreamedResponse;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:retry/retry.dart' show RetryOptions;

import 'compute.dart';
import 'exceptions/postor_exception.dart';
import 'postor_file.dart';

part 'postor_isolates.dart';
part 'postor_impl.dart';

typedef ResponseTimeoutCallback = FutureOr<Response> Function();
typedef StreamedResponseTimeoutCallback = FutureOr<StreamedResponse> Function();

/// the base class of [Postor], a wrapper around http's [Client] which supports
/// cancelling any HTTP request based on its request url.
///
/// it is by default sets `Duration` of network timeout on every http request and
/// retries 3 times when fails.
abstract class Postor {
  /// initializes a new instance of `Postor`.
  /// * [baseUrl] specify the scheme (`http` or `https`) here, if not specified,
  /// it defaults to `https`.
  ///
  ///   example:
  ///   * `www.abcdef.com` will be parsed as `https://www.abcdef.com`
  ///   * whereas `http://www.abcdef.com` stays the same
  ///
  ///
  /// * [ctManager] defaults to using the singleton of [CTManager.I] if null.
  ///   this can be utilized to manage cancellation of http requests.
  /// * [defaultTimeout] defaults to 10 seconds if not set.
  /// * [retryPolicy] defauts to 3 times if not set.
  factory Postor(
    String baseUrl, {
    Map<String, String>? defaultHeaders,
    CTManager? ctManager,
    Duration? defaultTimeout,
    RetryOptions? retryPolicy,
  }) = _PostorImpl;

  String get baseUrl;

  Map<String, String>? get defaultHeaders;

  /// Creates an HTTP Client GET request with the given headers to the given URL and
  /// a default [timeLimit] of 10 seconds, and then closes it after completed/cancelled.
  ///
  /// throws [CancelledRequestException] when cancelled.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  });

  /// Creates an HTTP Client POST request with the given headers and body to the given URL and
  /// a default [timeLimit] of 10 seconds, and then closes it after completed/cancelled.
  ///
  /// [body] sets the body of the request.
  /// It can be a [String], a [List] or a [Map<String, String>].
  /// If it's a String, it's encoded using [encoding] and used as the body of the request.
  /// The content-type of the request will default to `"text/plain"`.
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding].
  /// The content-type of the request will be set to `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// throws [CancelledRequestException] when cancelled.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  });

  /// Creates an HTTP Client PUT request with the given headers and body to the given URL and
  /// a default [timeLimit] of 10 seconds, and then closes it after completed/cancelled.
  ///
  /// [body] sets the body of the request.
  /// It can be a [String], a [List] or a [Map<String, String>].
  /// If it's a String, it's encoded using [encoding] and used as the body of the request.
  /// The content-type of the request will default to `"text/plain"`.
  ///
  /// If [body] is a List, it's used as a list of bytes for the body of the request.
  ///
  /// If [body] is a Map, it's encoded as form fields using [encoding].
  /// The content-type of the request will be set to `"application/x-www-form-urlencoded"`; this cannot be overridden.
  ///
  /// [encoding] defaults to [utf8].
  ///
  /// throws [CancelledRequestException] when cancelled.
  ///
  /// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  });

  /// Creates an HTTP Client request with a default [timeLimit] of 10 seconds,
  /// and asynchronously returns the response, and then closes it after completed/cancelled.
  /// 
  /// [onCancel] an optional additional mechanism in the event of request cancellation
  /// 
  /// throws [CancelledRequestException] when cancelled.
  Future<StreamedResponse> send(
    BaseRequest request, {
    Duration? timeLimit,
    StreamedResponseTimeoutCallback? onTimeout,
    void Function()? onCancel,
    @visibleForTesting Client? testClient,
  });

  /// A shortcut to [send] with [MultipartRequest]. This is usually for uploading
  /// fields with files and/or images.
  ///
  /// * [method] defaults to `POST`.
  ///
  ///
  /// * [fields] when using http's [Client], this is basically the same as
  ///   ```dart
  ///   final postUri = Uri.parse('http://your-api.com/your_endpoint');
  ///   final request = http.MultipartRequest('POST', postUri)
  ///     ..fields['field1'] = field1
  ///     ..fields['field2'] = field2;
  ///
  ///   final streamedResponse = await request.send();
  ///   final response = await Response.fromStream(streamedResponse);
  ///   ```
  ///   but in a more _elegant way_, for example:
  ///   ```dart
  ///   final postor = Postor('my-api.com');
  ///   final fields = {
  ///     'field1': field1,
  ///     'field2': field2,
  ///   };
  ///   final response = await postor.multiPart(
  ///     '/my_endpoint',
  ///     fields: fields,
  ///   );
  ///   ```
  ///   note that we don't need to specify the `POST` method as it's
  ///   already the default value.
  ///
  ///
  /// * [files] specify the field name and both file path/file bytes and file name (optional) 
  ///   using [PFile] here, for example:
  ///   ```dart
  ///   final postor = Postor('my-api.com');
  ///   final files = {
  ///     'photo': PFileFromPath(photo_path),
  ///     // if using bytes
  ///     // 'photo': PFileFromBytes(photo_bytes)
  ///     'photo_small': PFileFromPath(photo_small_path, filename: 'photo_small.png'),
  ///   };
  ///   final response = await postor.multiPart(
  ///     '/upload_photos',
  ///     files: files,
  ///   );
  ///   ```
  ///   note: by default Postor will handle these files in an isolate,
  ///   so theoritically there should not be any UI blocking problem.
  /// 
  /// 
  /// * [timeLimit] an optional different timeout if needed
  /// 
  /// 
  /// * [onTimeout] an optional callback when [timeLimit] has exceeded
  /// 
  /// 
  /// final notes:
  ///   * both files/images processing and request can be cancelled via [cancel] or via [CTManager.cancel].
  ///   for example:
  ///   ```dart
  ///   // our target url is https://my-api.com/upload
  ///   final postor = Postor('https://my-api.com');
  ///   final files = {
  ///     'photo': PFileFromPath(photo_path, filename: 'photo.jpg'),
  ///     'photo_small': PFileFromPath(photo_small_path),
  ///   };
  ///
  ///   postor.multiPart(
  ///       '/upload',
  ///       files: files,
  ///   ).then((response) => print(response.body));
  ///
  ///   // lets cancel it after 1 second
  ///   postor.cancel('https://my-api.com/upload');
  ///   ```
  ///   for more info about CTManager: https://pub.dev/documentation/ctmanager/latest/
  ///
  ///
  ///   * throws [CancelledRequestException] when cancelled.
  ///
  Future<Response> multiPart(
    String endpoint, {
    String method = 'POST',
    Map<String, String>? fields,
    Map<String, PFile>? files,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  });

  /// cancels HTTP request of [url]
  void cancel(String url);

  /// cancels all HTTP requests
  void cancelAll();
}
