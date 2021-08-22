/// the base class for all Exceptions thrown by Postor;
/// such as [CancelledRequestException] and all HTTP Status Code Exceptions.
///
/// Here are the status codes that Postor possibly throws:
/// - 400 Bad Request => [BadRequestException] or `SC400`
/// - 401 Unauthorized => [UnauthorizedException] or `SC401`
/// - 403 Forbidden => [ForbiddenException] or `SC403`
/// - 404 Not Found => [NotFound404Exception] or `SC404`
/// - 405 Method Not Allowed => [MethodNotAllowedException] or `SC405`
/// - 406 Not Acceptable => [NotAcceptableException] or `SC406`
/// - 408 RequestTimeoutException => [RequestTimeoutException] or `SC408`
/// - 409 Conflict => [RequestConflictException] or `SC409`
/// - 413 Payload Too Large => [PayloadTooLargeException] or `SC413`
/// - 415 Unsupported Media Type => [UnsupportedMediaTypeException] or `SC415`
/// - 429 Too Many Requests => [TooManyRequestsException] or `SC429`
/// - 431 Request Header Fields Too Large => [RequestHeadersTooLargeException] or `SC431`
/// - all 5xx Server Errors => [ProblemWithServerException] or `SC5XX`
///
/// For more info about HTTP Status Codes, head on to https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
abstract class PException implements Exception {
  const PException([this.message]);

  final String? message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CancelledRequestException && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class CancelledRequestException extends PException {
  const CancelledRequestException([String? message]) : super(message);
}

typedef SC400 = BadRequestException;
typedef SC401 = UnauthorizedException;
typedef SC403 = ForbiddenException;
typedef SC404 = NotFound404Exception;
typedef SC405 = MethodNotAllowedException;
typedef SC406 = NotAcceptableException;
typedef SC408 = RequestTimeoutException;
typedef SC409 = RequestConflictException;
typedef SC413 = PayloadTooLargeException;
typedef SC415 = UnsupportedMediaTypeException;
typedef SC429 = TooManyRequestsException;
typedef SC431 = RequestHeadersTooLargeException;
typedef SC5XX = ProblemWithServerException;

class UnknownHttpException extends PException {
  const UnknownHttpException([String? responseBody]) : super(responseBody);
}

/// 400 Bad Request
///
/// The server could not understand the request due to invalid syntax.
class BadRequestException extends PException {
  const BadRequestException([String? responseBody]) : super(responseBody);
}

/// 401 Unauthorized
///
/// Although the HTTP standard specifies "unauthorized", semantically this response means "unauthenticated".
/// That is, the client must authenticate itself to get the requested response.
class UnauthorizedException extends PException {
  const UnauthorizedException([String? responseBody]) : super(responseBody);
}

/// 403 Forbidden
///
/// The client does not have access rights to the content;
/// that is, it is unauthorized, so the server is refusing to give the requested resource.
/// Unlike 401, the client's identity is known to the server.
class ForbiddenException extends PException {
  const ForbiddenException([String? responseBody]) : super(responseBody);
}

/// 404 Not Found
///
/// The server can not find the requested resource.
/// In the browser, this means the URL is not recognized.
/// In an API, this can also mean that the endpoint is valid but the resource itself does not exist.
/// Servers may also send this response instead of 403 to hide the existence of a resource from an unauthorized client.
/// This response code is probably the most famous one due to its frequent occurrence on the web.
class NotFound404Exception extends PException {
  const NotFound404Exception([String? responseBody]) : super(responseBody);
}

/// 405 Method Not Allowed
///
/// The request method is known by the server
/// but is not supported by the target resource.
///
/// For example, an API may forbid DELETE-ing a resource.
class MethodNotAllowedException extends PException {
  const MethodNotAllowedException([String? responseBody]) : super(responseBody);
}

/// 406 Not Acceptable
///
/// This response is sent when the web server,
/// after performing server-driven content negotiation,
/// doesn't find any content that conforms to the criteria given by the user agent.
class NotAcceptableException extends PException {
  const NotAcceptableException([String? responseBody]) : super(responseBody);
}

/// 408 Request Timeout
///
/// This response is sent on an idle connection by some servers,
/// even without any previous request by the client.
/// It means that the server would like to shut down this unused connection.
/// This response is used much more since some browsers,
/// like Chrome, Firefox 27+, or IE9, use HTTP pre-connection mechanisms to speed up surfing.
/// Also note that some servers merely shut down the connection without sending this message.
class RequestTimeoutException extends PException {
  const RequestTimeoutException([String? responseBody]) : super(responseBody);
}

/// 409 Conflict
///
/// This response is sent when a request conflicts with the current state of the server.
class RequestConflictException extends PException {
  const RequestConflictException([String? responseBody]) : super(responseBody);
}

/// 413 Payload Too Large
///
/// Request entity is larger than limits defined by server;
/// the server might close the connection or return an Retry-After header field.
class PayloadTooLargeException extends PException {
  const PayloadTooLargeException([String? responseBody]) : super(responseBody);
}

/// 415 Unsupported Media Type
///
/// The media format of the requested data is not supported by the server,
/// so the server is rejecting the request.
class UnsupportedMediaTypeException extends PException {
  const UnsupportedMediaTypeException([String? responseBody])
      : super(responseBody);
}

/// 429 Too Many Requests
class TooManyRequestsException extends PException {
  const TooManyRequestsException([String? responseBody]) : super(responseBody);
}

/// 431 Request Header Fields Too Large
///
/// The server is unwilling to process the request because its header fields are too large.
/// The request may be resubmitted after reducing the size of the request header fields.
class RequestHeadersTooLargeException extends PException {
  const RequestHeadersTooLargeException([String? responseBody])
      : super(responseBody);
}

/// 5xx Server Errors
class ProblemWithServerException extends PException {
  const ProblemWithServerException([String? responseBody])
      : super(responseBody);
}

/// an HTTP error code transformer
///
/// refer to [PException] to see what status codes are covered here
PException transformStatusCodeToException({
  required int statusCode,
  String? responseBody,
}) {
  switch (statusCode) {
    case 400:
      return BadRequestException(responseBody);
    case 401:
      return UnauthorizedException(responseBody);
    case 403:
      return ForbiddenException(responseBody);
    case 404:
      return NotFound404Exception(responseBody);
    case 405:
      return MethodNotAllowedException(responseBody);
    case 406:
      return NotAcceptableException(responseBody);
    case 408:
      return RequestTimeoutException(responseBody);
    case 409:
      return RequestConflictException(responseBody);
    case 413:
      return PayloadTooLargeException(responseBody);
    case 415:
      return UnsupportedMediaTypeException(responseBody);
    case 429:
      return TooManyRequestsException(responseBody);
    case 431:
      return RequestHeadersTooLargeException(responseBody);
  }

  if (statusCode >= 500) {
    return ProblemWithServerException(responseBody);
  }
  return UnknownHttpException(responseBody);
}
