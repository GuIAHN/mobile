import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/notifications/push_notifications_service.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: GuiAutomotrizApp(),
    ),
  );

  // Firebase Messaging puede tardar o fallar en dispositivos sin Play
  // Services, con permisos restringidos o con políticas agresivas del
  // fabricante. La interfaz debe dibujar su primer frame antes de depender de
  // esos servicios para evitar que el usuario quede atrapado en una ventana
  // nativa vacía.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePushNotifications());
  });
}

Future<void> _initializePushNotifications() async {
  try {
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
  } catch (error, stackTrace) {
    debugPrint('[Startup] Firebase no pudo inicializarse: $error');
    debugPrintStack(stackTrace: stackTrace);
    return;
  }

  try {
    await PushNotificationsService.initializeApp();
  } catch (error, stackTrace) {
    debugPrint(
        '[Startup] Las notificaciones no pudieron inicializarse: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
