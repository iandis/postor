import 'dart:io' show File;

import 'package:path/path.dart' show basename;

import 'pfile.dart';

/// a wrapper around Dart's [File] class which will
/// be used by Postor for processing files
class PFileFromPath implements PFile<File> {
  /// Creates a [File] object with its [filename] if specified.
  ///
  /// [filename] defaults to the [basename] of its [path]
  PFileFromPath(
    String path, {
    String? filename,
  })  : file = File(path),
        filename = filename ?? basename(path);
  @override
  final File file;
  @override
  final String filename;
}
