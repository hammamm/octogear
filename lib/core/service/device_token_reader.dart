import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads a device messaging token without registering it for delivery.
///
/// This is intentionally limited to best-effort token capture during a new
/// account registration. It does not request notification permission, listen
/// for token refreshes, persist a token, or send a notification.
abstract interface class DeviceTokenReader {
  Future<String?> read();
}

class FirebaseDeviceTokenReader implements DeviceTokenReader {
  FirebaseDeviceTokenReader({FirebaseMessaging? messaging})
    : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  @override
  Future<String?> read() async {
    try {
      final token = await (_messaging ?? FirebaseMessaging.instance).getToken();
      final normalized = token?.trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } catch (_) {
      // A token is optional at account creation. Firebase availability must
      // never prevent a user from completing registration.
      return null;
    }
  }
}

final deviceTokenReaderProvider = Provider<DeviceTokenReader>((ref) {
  return FirebaseDeviceTokenReader();
});
