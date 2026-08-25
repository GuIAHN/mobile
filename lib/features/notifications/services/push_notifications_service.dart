import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationTap {
  const NotificationTap({
    required this.type,
    required this.data,
    this.notificationId,
  });

  final String type;
  final Map<String, dynamic> data;
  final String? notificationId;

  factory NotificationTap.fromRemoteMessage(RemoteMessage message) {
    return NotificationTap.fromData(message.data);
  }

  factory NotificationTap.fromData(Map<String, dynamic> rawData) {
    final data = Map<String, dynamic>.from(rawData);
    final type = (data['tipo'] ?? data['type'])?.toString().trim() ?? '';
    final rawId =
        data['notificationId'] ?? data['notification_id'] ?? data['id'];
    final notificationId = rawId?.toString().trim();
    return NotificationTap(
      type: type,
      data: data,
      notificationId:
          notificationId?.isNotEmpty == true ? notificationId : null,
    );
  }

  factory NotificationTap.fromPayload(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return const NotificationTap(type: '', data: {});
    }
    return NotificationTap.fromData(Map<String, dynamic>.from(decoded));
  }
}

class PushNotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final StreamController<NotificationTap> _notificationTapController =
      StreamController<NotificationTap>.broadcast();
  static NotificationTap? _initialNotificationTap;
  static bool _initialized = false;

  // Canal de alta importancia (banner + sonido) para las notificaciones que
  // llegan con la app en background/cerrada. Debe existir en el sistema
  // *antes* de que llegue la primera notificación - Android ignora el
  // channelId de un mensaje FCM si el canal no fue creado por la app, y cae
  // de vuelta al canal "default" (importancia normal, sin sonido
  // garantizado). Referenciado también en AndroidManifest.xml vía
  // `com.google.firebase.messaging.default_notification_channel_id`, para
  // que FCM lo use sin que el backend tenga que especificar channelId.
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'Notificaciones importantes',
    description: 'Ofertas, mensajes y actualizaciones de cuenta.',
    importance: Importance.max,
    playSound: true,
  );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeApp() async {
    if (_initialized) return;
    _initialized = true;

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await requestPermission();

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_highImportanceChannel);

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _handleLocalNotificationResponse,
      );

      final localLaunch =
          await _localNotifications.getNotificationAppLaunchDetails();
      final localPayload = localLaunch?.didNotificationLaunchApp == true
          ? localLaunch?.notificationResponse?.payload
          : null;
      if (localPayload?.isNotEmpty == true) {
        _initialNotificationTap = _decodeLocalPayload(localPayload!);
      }
    }

    // Configurar la presentación de notificaciones en primer plano para iOS.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      // La app ya muestra el aviso navegable recibido por WebSocket. Evitar
      // un segundo banner de sistema para el mismo evento en foreground.
      alert: false,
      badge: true,
      sound: false,
    );

    // Foreground messages: no mostramos un banner de sistema aquí para no
    // duplicar con el toast interno (AppNotificationToast) que se dispara
    // vía el WebSocket cuando la app está abierta - ver
    // core/notifications/foreground_notification_toast_provider.dart.
    // Este listener solo queda para logging/debug.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    final initialRemoteMessage = await _messaging.getInitialMessage();
    if (initialRemoteMessage != null) {
      _initialNotificationTap =
          NotificationTap.fromRemoteMessage(initialRemoteMessage);
    }
  }

  static Stream<NotificationTap> get onNotificationTap =>
      _notificationTapController.stream;

  static NotificationTap? takeInitialNotificationTap() {
    final initial = _initialNotificationTap;
    _initialNotificationTap = null;
    return initial;
  }

  static void _handleRemoteMessageTap(RemoteMessage message) {
    _notificationTapController.add(NotificationTap.fromRemoteMessage(message));
  }

  static void _handleLocalNotificationResponse(
    NotificationResponse response,
  ) {
    final payload = response.payload;
    if (payload?.isEmpty != false) return;
    _notificationTapController.add(_decodeLocalPayload(payload!));
  }

  static NotificationTap _decodeLocalPayload(String payload) {
    try {
      return NotificationTap.fromPayload(payload);
    } catch (error) {
      debugPrint('Invalid local notification payload: $error');
      return const NotificationTap(type: '', data: {});
    }
  }

  static Future<void> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
}
