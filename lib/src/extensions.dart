import 'dart:convert' show json;
import 'package:http/http.dart' show Response;
import 'postor_exceptions.dart' show transformStatusCodeToException;

extension GetResponse on Future<Response> {
  Future<T> get<T>([int expectedStatusCode = 200]) async {
    final response = await this;

    if (response.statusCode != expectedStatusCode) {
      throw transformStatusCodeToException(
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    return json.decode(response.body) as T;
  }
}
