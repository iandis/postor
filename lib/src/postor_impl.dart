part of 'postor.dart';

class _PostorImpl implements Postor {
  _PostorImpl(
    String baseUrl, {
    this.defaultHeaders,
    CTManager? ctManager,
    Duration? defaultTimeout,
    RetryOptions? retryPolicy,
  })  : assert(baseUrl.isNotEmpty),
        _ctManager = ctManager ?? CTManager.I,
        _defaultTimeout = defaultTimeout ?? const Duration(seconds: 10),
        _retryPolicy = retryPolicy ?? const RetryOptions(maxAttempts: 3) {
    final baseUri = Uri.parse(baseUrl);
    final baseUrlScheme = baseUri.scheme;
    assert(
      baseUrlScheme.isEmpty || baseUrlScheme == 'http' || baseUrlScheme == 'https',
      'Cannot parse scheme of $baseUrlScheme',
    );
    if (baseUrlScheme == 'http') {
      _isHttps = false;
    } else {
      _isHttps = true;
    }
    if (baseUri.hasAuthority) {
      this.baseUrl = baseUri.host;
    } else {
      this.baseUrl = baseUrl;
    }
  }

  @override
  late final String baseUrl;

  @override
  final Map<String, String>? defaultHeaders;

  final CTManager _ctManager;
  final Duration _defaultTimeout;
  final RetryOptions _retryPolicy;

  late final bool _isHttps;

  @override
  void cancel(String url) => _ctManager.cancel(url);

  @override
  void cancelAll() => _ctManager.cancelAll();

  @override
  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  }) async {
    final client = testClient ?? Client();
    final Uri url = _parseBaseUrlAndParameters(
      endpoint: endpoint,
      parameters: parameters,
    );
    final request = () {
      return client.get(url, headers: _concatHeaders(headers)).timeout(timeLimit ?? _defaultTimeout, onTimeout: onTimeout);
    };
    final requestWithRetryTimeout = () {
      return _retryPolicy
          .retry(request, retryIf: (e) => e is SocketException || e is TimeoutException)
          .whenComplete(client.close);
    };
    final onCancelFunc = () {
      throw CancelledRequestException(url.toString());
    };
    final response = await _ctManager.run(
      token: url.toString(),
      operation: requestWithRetryTimeout(),
      onCancel: onCancelFunc,
    );
    return response!;
  }

  @override
  Future<Response> post(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  }) async {
    final client = testClient ?? Client();
    final Uri url = _parseBaseUrlAndParameters(
      endpoint: endpoint,
      parameters: parameters,
    );
    final request = () {
      return client
          .post(url, headers: _concatHeaders(headers), body: body, encoding: encoding)
          .timeout(timeLimit ?? _defaultTimeout, onTimeout: onTimeout);
    };
    final requestWithRetryTimeout = () {
      return _retryPolicy
          .retry(request, retryIf: (e) => e is SocketException || e is TimeoutException)
          .whenComplete(client.close);
    };
    final onCancelFunc = () {
      throw CancelledRequestException(url.toString());
    };
    final response = await _ctManager.run(
      token: url.toString(),
      operation: requestWithRetryTimeout(),
      onCancel: onCancelFunc,
    );
    return response!;
  }

  @override
  Future<Response> put(
    String endpoint, {
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  }) async {
    final client = testClient ?? Client();
    final Uri url = _parseBaseUrlAndParameters(
      endpoint: endpoint,
      parameters: parameters,
    );
    final request = () {
      return client
          .put(url, headers: _concatHeaders(headers), body: body, encoding: encoding)
          .timeout(timeLimit ?? _defaultTimeout, onTimeout: onTimeout);
    };
    final requestWithRetryTimeout = () {
      return _retryPolicy
          .retry(request, retryIf: (e) => e is SocketException || e is TimeoutException)
          .whenComplete(client.close);
    };
    final onCancelFunc = () {
      throw CancelledRequestException(url.toString());
    };
    final response = await _ctManager.run(
      token: url.toString(),
      operation: requestWithRetryTimeout(),
      onCancel: onCancelFunc,
    );
    return response!;
  }

  @override
  Future<StreamedResponse> send(
    BaseRequest request, {
    Duration? timeLimit,
    StreamedResponseTimeoutCallback? onTimeout,
    void Function()? onCancel,
    @visibleForTesting Client? testClient,
  }) async {
    final client = testClient ?? Client();
    final requestFunc = () {
      return client.send(request).timeout(
            timeLimit ?? _defaultTimeout,
            onTimeout: onTimeout,
          );
    };
    final requestWithRetryTimeout = () {
      return _retryPolicy
          .retry(requestFunc, retryIf: (e) => e is SocketException || e is TimeoutException)
          .whenComplete(client.close);
    };
    final onCancelFunc = () {
      if (onCancel != null) onCancel();
      throw CancelledRequestException(request.url.toString());
    };
    final streamedResponse = await _ctManager.run(
      token: request.url.toString(),
      operation: requestWithRetryTimeout(),
      onCancel: onCancelFunc,
    );
    return streamedResponse!;
  }

  @override
  Future<Response> multiPart(
    String endpoint, {
    String method = 'POST',
    Map<String, String>? fields,
    Map<String, PFile>? files,
    Duration? timeLimit,
    ResponseTimeoutCallback? onTimeout,
    @visibleForTesting Client? testClient,
  }) {
    final client = testClient ?? Client();
    // this is used later to iterate over the processes
    final List<Future<void> Function()> processList = [];

    final Uri url = _parseBaseUrlAndParameters(endpoint: endpoint);
    final String operationToken = url.toString();

    bool isCancelled = false;
    final isCancelledFunc = () => isCancelled;

    final multiPartRequest = MultipartRequest(method, url);
    if (fields != null && fields.isNotEmpty && !isCancelled) {
      processList.add(() async => multiPartRequest.fields.addAll(fields));
    }
    final List<MultipartFile> multiPartFiles = [];
    if (files != null && files.isNotEmpty && !isCancelled) {
      // for each files we want to add the file processing process
      // to the [processList]
      files.forEach(
        (field, pFile) => processList.add(
          () async {
            if (isCancelled) return;
            final readFileFunc = () async {
              if (pFile is PFileFromPath) {
                final params = _IsolatedReadFileBytesParams(
                  file: pFile.file,
                  isCancelledFunc: isCancelledFunc,
                );
                return compute(_isolatedReadFileBytes, params);
              } else if (pFile is PFileFromBytes) {
                return pFile.file;
              }
              throw ArgumentError(
                'Postor was not able to handle this PFile: $pFile. '
                'It should be either a [PFileFromPath] or [PFileFromBytes]',
              );
            };

            return readFileFunc().then((fileBytes) {
              if (isCancelled) return;
              multiPartFiles.add(
                MultipartFile.fromBytes(
                  field,
                  fileBytes,
                  filename: pFile.filename,
                ),
              );
            });
          },
        ),
      );
      processList.add(() async => multiPartRequest.files.addAll(multiPartFiles));
    }
    final request = () {
      return client.send(multiPartRequest).then(Response.fromStream).timeout(timeLimit ?? _defaultTimeout, onTimeout: onTimeout);
    };
    final requestWithRetryTimeout = () {
      return _retryPolicy
          .retry(request, retryIf: (e) => e is SocketException || e is TimeoutException)
          .whenComplete(client.close);
    };
    final void Function() onCancelFunc = () => isCancelled = true;
    final beginProcessList = () async {
      while (processList.isNotEmpty) {
        final process = processList.removeAt(0);
        if (isCancelled) {
          // make sure to clear all resources before exiting the process
          multiPartFiles.clear();
          processList.clear();
          throw CancelledRequestException(url.toString());
        }
        await _ctManager.run(
          token: operationToken,
          operation: process(),
          onCancel: onCancelFunc,
        );
      }
      // make sure to clear all resources
      multiPartFiles.clear();
      processList.clear();
      if (!isCancelled) {
        final response = await _ctManager.run(
          token: operationToken,
          operation: requestWithRetryTimeout(),
          onCancel: onCancelFunc,
        );
        return response!;
      } else {
        throw CancelledRequestException(url.toString());
      }
    };

    return beginProcessList();
  }

  Uri _parseBaseUrlAndParameters({
    required String endpoint,
    Map<String, dynamic>? parameters,
  }) {
    if (_isHttps) {
      return Uri.https(baseUrl, endpoint, parameters);
    }
    return Uri.http(baseUrl, endpoint, parameters);
  }

  Map<String, String>? _concatHeaders(Map<String, String>? headers) {
    if (headers != null && defaultHeaders != null) {
      return {
        ...defaultHeaders!,
        ...headers,
      };
    }
    if (headers != null && defaultHeaders == null) {
      return headers;
    }
    return defaultHeaders;
  }
}
