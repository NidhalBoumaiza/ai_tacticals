import 'package:equatable/equatable.dart';
import 'package:get/get.dart'; // Import GetX for translation access

abstract class Failure extends Equatable {
  String get message;

  @override
  List<Object?> get props => [message];
}

class OfflineFailure extends Failure {
  @override
  String get message => 'offline_failure_message'.tr;
}

class ServerFailure extends Failure {
  @override
  String get message => 'server_failure_message'.tr;
}

class EmptyCacheFailure extends Failure {
  @override
  String get message => 'empty_cache_failure_message'.tr;
}

class ServerMessageFailure extends Failure {
  final String customMessage;

  ServerMessageFailure(this.customMessage);

  @override
  String get message => customMessage;
}

class UnauthorizedFailure extends Failure {
  @override
  String get message => 'unauthorized_failure_message'.tr;
}

class TimeoutFailure extends Failure {
  @override
  String get message => 'timeout_failure_message'.tr; // Add this to your translations
}