abstract class Failure {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}
