[![style: lint](https://img.shields.io/badge/style-lint-4BC0F5.svg)](https://pub.dev/packages/lint)

A wrapper around Dart's [http](https://pub.dev/packages/http) package, which supports Manageable Requests Cancellation, Request Policy (Timeout and Retry), Easier Multipart Requests, Error Handling, etc.

## Using

Using `Postor` is actually almost the same as using the http package. But, instead of defining the URL on every request, Postor gives us the ability to set the default base URL, so that we just need to define the endpoint(s). 

And one of the best ways to using it is to initialize its instance somewhere, whether as a singleton or as an instance in a class or something like that.

```dart
import 'dart:convert';

import 'package:postor/postor.dart';

class MyApi {
  // note: I'm not endorsing this url, so use this at your own risk!
  static const String baseUrl = 'https://fakestoreapi.com';
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
      id: map['id'],
      username: map['username'],
    );
  }
}
```
The method body of `getUsers` can actually be simplified to
```dart
// use the `get<T>(expectedStatusCode)` extension to parse the
// response body to T (e.g. List or Map).
// by using this, we also no longer need to check the status code for
// throwing exceptions based on the status code
// since the extension already handles it.
//
// note: by default the [expectedStatusCode] is set to 200.
// so if we expect other status code, we just need to set it.
// for example:
// final response = await postor.get(usersEndpoint).get<List>(201);  
final response = await postor.get(usersEndpoint).get<List>();
return response.map((u) => User.fromMap(u as Map<String, dynamic>)).toList();
```
Now based on the above example, we can add another method to `MyApi` class that can cancel the request made by `getUsers`.
```dart
  ...
  void cancelGetUsers() {
    // postor will use the base URL + endpoint + parameters as the
    // cancellation token
    postor.cancel(baseUrl + usersEndpoint);
    // or if we're on strong analyzer mode, 
    // which will suggest us to use string interpolation instead:
    // postor.cancel('$baseUrl$usersEndpoint');
  }
  ...
```
One thing to remember that we can only request one specific URL per execution. So besure to check it first before requesting the same URL again, otherwise it will throw an `AssertionError`.

Now how do we check that `getUsers` has completed or not? There are many possible ways to achieve this, but we'll talk about 2 possible solutions.
### example solution 1
```dart
final List<User> users = [];
final MyApi myApi = MyApi();

void main() {
  requestUsers();
  requestUsers();
}
// we can have a boolean variable that can be checked later by
// [requestUsers] method below
bool isGetUsersRunning = false;
Future<void> requestUsers() async {
  if(isGetUsersRunning) return;
  isGetUsersRunning = true;
  final usersList = await myApi.getUsers();
  users.addAll(usersList);
}
```
### example solution 2
```dart
// we can utilize CTManager 
// read more about it here: https://pub.dev/packages/ctmanager
import 'package:ctmanager/ctmanager.dart';

final List<User> users = [];
final MyApi myApi = MyApi();

void main() {
  requestUsers();
  requestUsers();
}

// instead of creating another variable, we just need to check
// whether the get users URL exists in CTManager or not.
Future<void> requestUsers() async {
  const getUsersURL = MyApi.baseUrl + MyApi.usersEndpoint;
  // since we didn't specify anything in Postor's `ctManager` 
  // parameter, our Postor in MyApi will use CTManager.I instead.
  if(CTManager.I.of<String, Response?>(getUsersURL) != null){
    // not null means it exists in our Postor's CTManager
    return;
  }
  final usersList = await myApi.getUsers();
  users.addAll(usersList);
}
```
Next, to create a Multipart Request, e.g. image(s) uploading, there is Postor's `multiPart` method.
```dart
import 'package:postor/postor.dart';

final postor = Postor('https://my-api.com');

void main() {
  postImageAndFields();
}

Future<void> postImageAndFields() async {
  final fields = {
    'name': 'my name',
    'age': '99',
  };
  final files = {
    'avatar': PFileFromPath('path_to_avatar_image', filename: 'avatar.png'),
    'avatar_small': PFileFromPath('path_to_avatar_small_image'),
    // for file bytes
    // 'avatar_bytes': PFileFromBytes(avatar_bytes),
  };
  final response = await postor.multiPart(
    '/upload',
    // we don't need to specify the method if it's POST,
    // since it's the default value.
    // method: 'POST',
    fields: fields,
    files: files,
  );
  print(response.statusCode);
  print(response.body);
}
```
And to cancel it, just call
```dart
postor.cancel('https://my-api.com/upload');
```
or with CTManager
```dart
CTManager.I.cancel('https://my-api.com/upload');
```
Note: Postor handles files processing in an isolate, and both file processing and multipart request are cancelable.

Lastly, there's a new yet experimental feature: `Postorized`. It enables centralization of error handling in the `main` method.
```dart
void main() {
  final mainClosure = () {
    requestUsers();
    requestUsers();
  };
  Postorized(mainClosure)
  // handle status code of 401
  .on<UnauthorizedException>((e, st) {
    // handle UnauthorizedException here
  })
  // or with its alias
  // .on<SC401>((e, st) {
  //
  // })
  .on<TimeoutException>((e, st) {
    // ...
  })
  .on<CancelledRequestException>((e, st) {
    // ...
  })
  .onElse((e, st) {
    // handle other exceptions/errors here
  })
  // or just do nothing
  // .onElse(doNothing)
  .run();
}
```
As a matter of style, we can also do similar with
```dart
void initErrorHandlers() {
  // handle status code of 401
  On<UnauthorizedException>((e, st) {
    // handle UnauthorizedException here
  });
  On<TimeoutException>((e, st) {
    // ...
  });
  On<CancelledRequestException>((e, st) {
    // ...
  });
  OnElse((e, st) {
    // handle other exceptions/errors here
  });
  // or just do nothing
  // OnElse(doNothing);
}
void main() {
  initErrorHandlers();
  Postorized(() {
    requestUsers();
    requestUsers();
  }).run();
}
```
Note that there is a limitation of using this: it cannot evaluate subtypes. So if `B` is a subtype of `A`, and `B` is thrown, even though `A` is registered using the `on<A>` it will be handled by `onElse` instead. However, if `onElse` is not registered, it will log the error and stack trace.