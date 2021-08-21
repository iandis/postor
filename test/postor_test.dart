import 'dart:async' show TimeoutException;

import 'package:ctmanager/ctmanager.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:postor/http.dart';
import 'package:postor/postor.dart';
import 'package:test/test.dart';

import 'postor_test.mocks.dart';

@GenerateMocks([Client, BaseRequest, MultipartRequest, MultipartFile])
void main() {
  group('Tests for Postor:\n', () {
    final ctManager = CTManager();
    const fakeBaseUrl = 'fake.com';
    const fakeEndpoint = '/fake';
    const fakeEndpointForTimeout = '/timeout';
    final fakeUri = Uri.https(fakeBaseUrl, fakeEndpoint);
    const fakeRequestBody = {
      'fake': true,
    };
    final fakeMultipartRequest = MockMultipartRequest('POST', fakeUri)
      ..fields['fakeField1'] = 'true'
      ..fields['fakeField2'] = 'true'
      ..files.add(MockMultipartFile.fromBytes('file', [0]));
    final fakeMultipartRequestForTimeout = MockMultipartRequest('POST', fakeUri)
      ..fields['timeout1'] = 'true'
      ..fields['timeout2'] = 'true'
      ..files.add(MockMultipartFile.fromBytes('file_timeout', [1]));
    final postor = Postor(fakeBaseUrl, ctManager: ctManager);
    final mockClient = MockClient();
    bool firstRun = true;

    setUp(() {
      if (firstRun) {
        firstRun = false;
      } else {
        verify(mockClient.close()).called(1);
      }
    });

    setUpAll(() {
      // normal get
      when(mockClient.get(
        Uri.https(fakeBaseUrl, fakeEndpoint),
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 3),
          () => Response('fakeGet', 200),
        ),
      );
      // timeout get
      when(mockClient.get(
        Uri.https(fakeBaseUrl, fakeEndpointForTimeout),
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 11),
          () => Response('fakeGet', 200),
        ),
      );
      // normal post
      when(mockClient.post(
        Uri.https(fakeBaseUrl, fakeEndpoint),
        body: fakeRequestBody,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 3),
          () => Response('fakePost', 200),
        ),
      );
      // timeout post
      when(mockClient.post(
        Uri.https(fakeBaseUrl, fakeEndpointForTimeout),
        body: fakeRequestBody,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 11),
          () => Response('fakePost', 200),
        ),
      );
      // normal put
      when(mockClient.put(
        Uri.https(fakeBaseUrl, fakeEndpoint),
        body: fakeRequestBody,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 3),
          () => Response('fakePut', 200),
        ),
      );
      // timeout put
      when(mockClient.put(
        Uri.https(fakeBaseUrl, fakeEndpointForTimeout),
        body: fakeRequestBody,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 11),
          () => Response('fakePut', 200),
        ),
      );
      // normal send
      when(mockClient.send(
        fakeMultipartRequest,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 3),
          () => StreamedResponse(
            Stream.fromIterable([
              [0]
            ]),
            201,
          ),
        ),
      );
      // timeout send
      when(mockClient.send(
        fakeMultipartRequestForTimeout,
      )).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 11),
          () => StreamedResponse(
            Stream.fromIterable([
              [0]
            ]),
            201,
          ),
        ),
      );
    });

    // tests for normal operations
    test(
        '[NORMAL]\n'
        'Given an http request of GET\n'
        'when Postor runs normally for 3 seconds\n'
        'then it returns an instance of [Response]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.get(fakeEndpoint, testClient: mockClient).then((response) {
            expect(response, isA<Response>());
            expect(response.body, equals('fakeGet'));
            expect(response.statusCode, equals(200));
          }).then((_) => CTManager.I.noTokenOf(fakeUri.toString())),
          completion(isTrue),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[NORMAL]\n'
        'Given an http request of POST\n'
        'when Postor runs normally for 3 seconds\n'
        'then it returns an instance of [Response]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.post(
            fakeEndpoint,
            testClient: mockClient,
            body: {'fake': true},
          ).then((response) {
            expect(response, isA<Response>());
            expect(response.body, equals('fakePost'));
            expect(response.statusCode, equals(200));
          }).then((_) => CTManager.I.noTokenOf(fakeUri.toString())),
          completion(isTrue),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[NORMAL]\n'
        'Given an http request of PUT\n'
        'when Postor runs normally for 3 seconds\n'
        'then it returns an instance of [Response]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.put(
            fakeEndpoint,
            testClient: mockClient,
            body: {'fake': true},
          ).then((response) {
            expect(response, isA<Response>());
            expect(response.body, equals('fakePut'));
            expect(response.statusCode, equals(200));
          }).then((_) => CTManager.I.noTokenOf(fakeUri.toString())),
          completion(isTrue),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[NORMAL]\n'
        'Given an http request of SEND\n'
        'when Postor runs normally for 3 seconds\n'
        'then it returns an instance of [StreamedResponse]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor
              .send(
            MockMultipartRequest('POST', fakeUri)
              ..fields['fakeField1'] = 'true'
              ..fields['fakeField2'] = 'true'
              ..files.add(MockMultipartFile.fromBytes('file', [0])),
            testClient: mockClient,
          )
              .then((response) {
            expect(response, isA<StreamedResponse>());
            expect(response.stream, isA<ByteStream>());
            expect(response.statusCode, equals(201));
          }).then(
            (_) => CTManager.I.noTokenOf(fakeUri.toString()),
          ),
          completion(isTrue),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    // test(
    //     '[NORMAL]\n'
    //     'Given a Postor request of [multiPart]\n'
    //     'when running normally for 3 seconds\n'
    //     'then it returns an instance of [Response]\n'
    //     'and its token has been removed.\n', () {
    //   fakeAsync((async) {
    //     expectLater(
    //       postor
    //           .multiPart(
    //         fakeEndpoint,
    //         fields: {
    //           'fakeField1': 'true',
    //           'fakeField2': 'true',
    //         },
    //         files: {
    //           'file': PFileFromBytes([0]),
    //         },
    //         testClient: mockClient,
    //       )
    //           .then((response) {
    //         expect(response, isA<Response>());
    //         expect(response.body, equals(String.fromCharCode(0)));
    //         expect(response.statusCode, equals(201));
    //       }).then(
    //         (_) => CTManager.I.noTokenOf(fakeUri.toString()),
    //       ),
    //       completion(isTrue),
    //     );
    //     async.elapse(const Duration(seconds: 3));
    //   });
    // });

    // tests for cancelled operations
    test(
        '[CANCELLED]\n'
        'Given an http request of GET\n'
        'when Postor runs for 3 seconds\n'
        'and gets cancelled after 1 seconds\n'
        'then it throws [CancelledRequestException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.get(
            fakeEndpoint,
            testClient: mockClient,
          ),
          throwsA(isA<CancelledRequestException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        Future.delayed(
          const Duration(seconds: 1),
          () => postor.cancel(fakeUri.toString()),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[CANCELLED]\n'
        'Given an http request of POST\n'
        'when Postor runs for 3 seconds\n'
        'and gets cancelled after 1 seconds\n'
        'then it throws [CancelledRequestException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.post(
            fakeEndpoint,
            testClient: mockClient,
            body: {'fake': true},
          ),
          throwsA(isA<CancelledRequestException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        Future.delayed(
          const Duration(seconds: 1),
          () => postor.cancel(fakeUri.toString()),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[CANCELLED]\n'
        'Given an http request of PUT\n'
        'when Postor runs for 3 seconds\n'
        'and gets cancelled after 1 seconds\n'
        'then it throws [CancelledRequestException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.put(
            fakeEndpoint,
            testClient: mockClient,
            body: {'fake': true},
          ),
          throwsA(isA<CancelledRequestException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        Future.delayed(
          const Duration(seconds: 1),
          () => postor.cancel(fakeUri.toString()),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    test(
        '[CANCELLED]\n'
        'Given an http request of SEND\n'
        'when Postor runs for 3 seconds\n'
        'and gets cancelled after 1 seconds\n'
        'then it throws [CancelledRequestException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.send(
            fakeMultipartRequest,
            testClient: mockClient,
          ),
          throwsA(isA<CancelledRequestException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        Future.delayed(
          const Duration(seconds: 1),
          () => postor.cancel(fakeUri.toString()),
        );
        async.elapse(const Duration(seconds: 3));
      });
    });

    // test(
    //     '[CANCELLED]\n'
    //     'Given a Postor request of [multiPart]\n'
    //     'when running for 3 seconds\n'
    //     'and gets cancelled after 1 seconds\n'
    //     'then it throws [CancelledRequestException]\n'
    //     'and its token has been removed.\n', () {
    //   fakeAsync((async) {
    //     expectLater(
    //       postor.multiPart(
    //         fakeEndpoint,
    //         fields: {
    //           'fakeField1': 'true',
    //           'fakeField2': 'true',
    //         },
    //         files: {
    //           'file': PFileFromBytes([0]),
    //         },
    //         testClient: mockClient,
    //       ),
    //       throwsA(isA<CancelledRequestException>()),
    //     ).then((_) {
    //       expect(
    //         CTManager.I.noTokenOf(fakeUri.toString()),
    //         isTrue,
    //       );
    //     });
    //     Future.delayed(
    //       const Duration(seconds: 1),
    //       () => postor.cancel(fakeUri.toString()),
    //     );
    //     async.elapse(const Duration(seconds: 3));
    //   });
    // });

    // tests for timeout operations
    test(
        '[TIMEOUT]\n'
        'Given an http request of GET\n'
        'when Postor runs for more than 30 seconds\n'
        'then it throws [TimeoutException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.get(
            fakeEndpointForTimeout,
            testClient: mockClient,
          ),
          throwsA(isA<TimeoutException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        async.elapse(const Duration(seconds: 33));
      });
    });

    test(
        '[TIMEOUT]\n'
        'Given an http request of POST\n'
        'when Postor runs for more than 30 seconds\n'
        'then it throws [TimeoutException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.post(
            fakeEndpointForTimeout,
            testClient: mockClient,
            body: {'fake': true},
          ),
          throwsA(isA<TimeoutException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        async.elapse(const Duration(seconds: 33));
      });
    });

    test(
        '[TIMEOUT]\n'
        'Given an http request of PUT\n'
        'when Postor runs for more than 30 seconds\n'
        'then it throws [TimeoutException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.put(
            fakeEndpointForTimeout,
            testClient: mockClient,
            body: {'fake': true},
          ),
          throwsA(isA<TimeoutException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        async.elapse(const Duration(seconds: 33));
      });
    });

    test(
        '[TIMEOUT]\n'
        'Given an http request of SEND\n'
        'when Postor runs for more than 30 seconds\n'
        'then it throws [TimeoutException]\n'
        'and its token has been removed.\n', () {
      fakeAsync((async) {
        expectLater(
          postor.send(
            fakeMultipartRequestForTimeout,
            testClient: mockClient,
          ),
          throwsA(isA<TimeoutException>()),
        ).then((_) {
          expect(
            CTManager.I.noTokenOf(fakeUri.toString()),
            isTrue,
          );
        });
        async.elapse(const Duration(seconds: 33));
      });
    });

    // test(
    //     '[TIMEOUT]\n'
    //     'Given a Postor request of [multiPart]\n'
    //     'when running for more than 30 seconds\n'
    //     'then it throws [TimeoutException]\n'
    //     'and its token has been removed.\n', () {
    //   fakeAsync((async) {
    //     expectLater(
    //       postor.multiPart(
    //         fakeEndpoint,
    //         fields: {
    //           'timeout1': 'true',
    //           'timeout2': 'true',
    //         },
    //         files: {
    //           'file_timeout': PFileFromBytes([1]),
    //         },
    //         testClient: mockClient,
    //       ),
    //       throwsA(isA<TimeoutException>()),
    //     ).then((_) {
    //       expect(
    //         CTManager.I.noTokenOf(fakeUri.toString()),
    //         isTrue,
    //       );
    //     });
    //     async.elapse(const Duration(seconds: 33));
    //   });
    // });
  });
}
