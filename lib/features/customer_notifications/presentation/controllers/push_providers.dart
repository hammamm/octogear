import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../data/data_sources/push_remote_data_source.dart';
import '../../data/repositories/firebase_push_repository.dart';
import '../../domain/repositories/push_repository.dart';
import 'push_delivery_controller.dart';

final pushRepositoryProvider = Provider<PushRepository?>((ref) {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.android ||
      Firebase.apps.isEmpty) {
    return null;
  }
  return FirebasePushRepository(
    FirebaseMessaging.instance,
    PushRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(appStorageProvider),
  );
});

final pushDeliveryProvider = Provider<PushDeliveryController?>((ref) {
  final repository = ref.watch(pushRepositoryProvider);
  if (repository == null) return null;
  final controller = PushDeliveryController(repository)..initialize();
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});
