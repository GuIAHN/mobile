import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/notifications/services/push_notifications_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyAZdrAuvoxY2wcU8VgTYZvEoYXitmNu7tQ",
            appId: "1:396997122901:web:b39390817614589ed26ddc",
            messagingSenderId: "396997122901",
            projectId: "guia-hn-5a494",
          )
        : null,
  );
  await PushNotificationsService.initializeApp();

  runApp(
    const ProviderScope(
      child: GuiAutomotrizApp(),
    ),
  );
}
