import 'package:equatable/equatable.dart';

/// A general server-related exception with a message.
class ServerException extends Equatable implements Exception {
  final String message;

  ServerException(this.message);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when the cache is empty.
class EmptyCacheException extends Equatable implements Exception {
  final String message;

  EmptyCacheException(this.message);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when there’s no internet connection.
class OfflineException extends Equatable implements Exception {
  final String message;

  OfflineException(this.message);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for server-specific error messages.
class ServerMessageException extends Equatable implements Exception {
  final String message;

  ServerMessageException(this.message);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown for unauthorized access.
class UnauthorizedException extends Equatable implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Unauthorized access']);

  @override
  List<Object?> get props => [message];
}

/// An exception thrown when an API call times out.
class TimeoutException extends Equatable implements Exception {
  final String message;

  const TimeoutException([this.message = 'Request timed out']);

  @override
  List<Object?> get props => [message];
}