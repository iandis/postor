import 'dart:async';
import 'dart:convert' show json;

import 'package:postor/error_handler.dart';
import 'package:postor/postor.dart';
// read more about CTManager here: https://pub.dev/packages/ctmanager
import 'package:ctmanager/ctmanager.dart';

final List<User> users = [];
final MyApi myApi = MyApi();

void initErrorMessageHandler() {
  initErrorMessages(defaultErrorMessageHandler);
}

void main() {
  initErrorMessageHandler();
}

// instead of creating another variable, we just need to check
// whether the get users URL exists in CTManager or not.
Future<void> requestUsers() async {
  const getUsersURL = MyApi.baseUrl + MyApi.usersEndpoint;
  // since we didn't specify anything in Postor's `ctManager`
  // parameter, our Postor in MyApi will use CTManager.I instead.
  if (CTManager.I.hasTokenOf(getUsersURL)) {
    print('getUsers already running!');
    return;
  }
  final usersList = await myApi.getUsers();
  users.addAll(usersList);
  // ignore: avoid_print
  print(users);
}

class MyApi {
  static const String baseUrl = 'https://your-fake-api.com';
  static const String usersEndpoint = '/users';

  // this creates a new instance of Postor with the default
  // Request Policies of 10 seconds Timeout and 3 times Retry Attempts
  final Postor postor = Postor(baseUrl);
  // we can also initiate Postor with our own Request Policies
  // final Postor postor = Postor(
  //    baseUrl,
  //    defaultTimeout: const Duration(seconds: 1),
  //    retryPolicy: const RetryOptions(maxAttempts: 10),
  // );

  Future<List<User>> getUsers() async {
    final response = await postor.get(usersEndpoint);
    if (response.statusCode != 200) {
      throw transformStatusCodeToException(
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    final rawUsersList = json.decode(response.body) as List;

    return rawUsersList.map((user) {
      return User.fromMap(user as Map<String, dynamic>);
    }).toList();

    // or
    //
    // final response = await postor.get(usersEndpoint).get<List>();
    // return response.map((u) => User.fromMap(u as Map<String, dynamic>)).toList();
  }

  void cancelGetUsers() {
    // postor will use the base URL + endpoint + parameters as the
    // cancellation token
    postor.cancel(baseUrl + usersEndpoint);
    // or if we're on strong analyzer mode,
    // which will suggest us to use string interpolation instead:
    // postor.cancel('$baseUrl$usersEndpoint');
  }
}

class User {
  const User({
    required this.id,
    required this.username,
  });

  final int id;
  final String username;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      username: map['username'] as String,
    );
  }

  @override
  String toString() => 'User(id: $id, username: $username)';
}
