import 'package:sahala/core/service/firebase_messaging_service.dart';
import 'package:sahala/features/authentication/data/models/login_request_model.dart';
import 'package:sahala/features/authentication/domain/repositories/authentication_repository.dart';
import 'dart:io';
import 'package:sahala/core/service/app_logger.dart';

class LoginUseCase {
  final AuthenticationRepository repository;
  final FirebaseMessagingService messagingService;
  LoginUseCase(this.repository, this.messagingService);

  Future<dynamic> call(String phoneNumber) async {
    final int deviceType = Platform.isIOS ? 1 : 0;
    String? deviceToken;

    deviceToken = await messagingService.getToken();

    final body = LoginRequestModel(
      phoneNumber: phoneNumber,
      deviceType: deviceType,
      latitude: 0.0,
      longitude: 0.0,
      deviceToken: deviceToken,
    );

    await AppLogger.log('Submitting phone login request', category: 'AUTH');

    return await repository.login(body);
  }
}
