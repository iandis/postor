import 'package:path/path.dart' show basename;

import 'pfile.dart';

// ignore_for_file: prefer_initializing_formals

/// a wrapper around Dart's [File] class which will
/// be used by Postor for processing files
class PFileFromPath implements PFile<String> {
  /// Creates a [PFile] object with its file path and
  /// its [filename] if specified.
  ///
  /// [filename] defaults to the [basename] of its [path]
  PFileFromPath(
    String path, {
    String? filename,
  })  : file = path,
        filename = filename ?? basename(path);
  @override
  final String file;
  @override
  final String filename;
}
