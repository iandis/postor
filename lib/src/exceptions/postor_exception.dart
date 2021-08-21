
abstract class PException implements Exception {
  const PException([this.message]);
  
  final String? message;
}

class CancelledRequestException extends PException {
  const CancelledRequestException([String? message]) : super(message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is CancelledRequestException &&
      other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
