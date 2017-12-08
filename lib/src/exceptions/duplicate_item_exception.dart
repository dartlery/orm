import 'a_nested_exception.dart';

class DuplicateItemException extends ANestedException {
  final String message;
  DuplicateItemException(
      [this.message = "", Exception innerException, StackTrace innerStackTrace])
      : super(innerException, innerStackTrace);
  @override
  String toString() => message;
}
