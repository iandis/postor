// Copyright 2014 The Flutter Authors. All rights reserved.
// Licensed under the BSD 3-Clause "New" or "Revised" License.

import 'dart:async' show FutureOr;

typedef _ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

/// The dart:html implementation of [isolate.compute].
Future<R> compute<Q, R>(_ComputeCallback<Q, R> callback, Q message) async {
  // To avoid blocking the UI immediately for an expensive function call, we
  // pump a single frame to allow the framework to complete the current set
  // of work.
  await null;
  return callback(message);
}
