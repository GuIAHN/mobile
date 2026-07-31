import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/notifications/services/push_notifications_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await PushNotificationsService.initializeApp();

  runApp(
    const ProviderScope(
      child: GuiAutomotrizApp(),
    ),
  );
}
