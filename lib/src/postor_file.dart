import 'dart:io' show File;

import 'package:path/path.dart' show basename;

/// a wrapper around HTTP's MurtipartFile
abstract class PFile<T extends Object> {
  T get file;
  String? get filename;
}

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

class PFileFromBytes implements PFile<List<int>> {
  /// Creates a [PFile] with its bytes and its [filename] if specified.
  PFileFromBytes(
    this.file, {
    this.filename,
  });

  @override
  final List<int> file;
  @override
  final String? filename;
}
