import 'package:dio/dio.dart';

abstract class AppNetworkError implements Exception {
  final String message;
  final int? statusCode;

  const AppNetworkError(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class NetworkError extends AppNetworkError {
  const NetworkError(super.message, {super.statusCode});
}

class TimeoutError extends AppNetworkError {
  const TimeoutError(super.message);
}

class ApiError extends AppNetworkError {
  const ApiError(super.message, {super.statusCode});
}

class ParsingError extends AppNetworkError {
  const ParsingError(super.message);
}

class UnknownError extends AppNetworkError {
  const UnknownError(super.message);
}

class NetworkErrorMapper {
  static AppNetworkError fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutError('Connection timed out');
      case DioExceptionType.badResponse:
        return ApiError(
          error.response?.statusMessage ?? 'API returned an error',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const NetworkError('Request cancelled');
      case DioExceptionType.connectionError:
        return const NetworkError('No internet connection');
      case DioExceptionType.badCertificate:
        return const NetworkError('Bad certificate');
      case DioExceptionType.unknown:
      default:
        return UnknownError(error.message ?? 'An unknown error occurred');
    }
  }

  static AppNetworkError fromError(Object error) {
    if (error is DioException) {
      return fromDioException(error);
    }
    if (error is FormatException || error is TypeError) {
      return ParsingError(error.toString());
    }
    return UnknownError(error.toString());
  }
}
