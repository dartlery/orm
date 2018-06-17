import 'a_nested_exception.dart';

class ItemNotFoundException extends ANestedException {
  final String message;
  ItemNotFoundException(
      [this.message = "", Exception innerException, StackTrace innerStackTrace])
      : super(innerException, innerStackTrace);
  @override
  String toString() => message;
}
