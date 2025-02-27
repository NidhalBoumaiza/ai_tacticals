import 'package:equatable/equatable.dart';
import 'package:get/get.dart'; // Import GetX for translation access

abstract class Failure extends Equatable {
  // Define a getter for the message that will be overridden by subclasses
  String get message;

  @override
  List<Object?> get props => [message];
}

class OfflineFailure extends Failure {
  @override
  String get message => 'offline_failure_message'.tr; // Fetch translated message dynamically
}

class ServerFailure extends Failure {
  @override
  String get message => 'server_failure_message'.tr; // Fetch translated message dynamically
}

class EmptyCacheFailure extends Failure {
  @override
  String get message => 'empty_cache_failure_message'.tr; // Fetch translated message dynamically
}

class ServerMessageFailure extends Failure {
  final String customMessage;

  ServerMessageFailure(this.customMessage); // Accept a runtime message

  @override
  String get message => customMessage; // Use the provided custom message
}

class UnauthorizedFailure extends Failure {
  final String customMessage;

  UnauthorizedFailure(this.customMessage); // Accept a runtime message

  @override
  String get message => customMessage; // Use the provided custom message
}