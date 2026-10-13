abstract class ApiResult<T> {
  const ApiResult();
}

class Success<T> extends ApiResult<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends ApiResult<T> {
  final String message;
  final String? code;
  final dynamic exception;

  const Failure({
    required this.message,
    this.code,
    this.exception,
  });
}

class Loading<T> extends ApiResult<T> {
  const Loading();
}
