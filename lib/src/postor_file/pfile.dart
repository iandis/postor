/// a wrapper around HTTP's MurtipartFile
abstract class PFile<T extends Object> {
  T get file;
  String? get filename;
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
