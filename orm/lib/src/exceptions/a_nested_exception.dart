abstract class ANestedException implements Exception {
  final Exception innerException;
  final StackTrace innerStackTrace;

  ANestedException(this.innerException, this.innerStackTrace);
}
