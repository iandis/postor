part of 'postor.dart';

/// isolated synchronous file reading.
List<int> _isolatedReadFileBytes(_IsolatedReadFileBytesParams params) {
  final isCancelledFunc = params.isCancelledFunc;
  final List<int> fileBytes = [];
  if (isCancelledFunc()) return fileBytes;
  final file = params.file;
  final openRandomAccessFile = file.openSync();

  final fileLen = openRandomAccessFile.lengthSync();
  int count = 0;
  int byte = 0;

  while (byte != -1 && count < fileLen && !isCancelledFunc()) {
    byte = openRandomAccessFile.readByteSync();
    fileBytes.add(byte);
    count++;
  }

  openRandomAccessFile.closeSync();
  return fileBytes;
}

class _IsolatedReadFileBytesParams {
  const _IsolatedReadFileBytesParams({
    required this.file,
    required this.isCancelledFunc,
  });

  final File file;
  final bool Function() isCancelledFunc;
}