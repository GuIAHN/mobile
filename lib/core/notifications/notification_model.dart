import 'package:equatable/equatable.dart';
import 'notification_type.dart';

/// Modelo inmutable de una notificación activa en el sistema AppNotification.
class NotificationModel extends Equatable {
  /// Identificador único generado al crear la notificación.
  final String id;

  /// Tipo semántico (error, success, info, warning).
  final NotificationType type;

  /// Título en negrita (opcional). Si se omite, solo se muestra [message].
  final String? title;

  /// Mensaje descriptivo de la notificación.
  final String message;

  /// Tiempo hasta que la notificación se autodescarte.
  final Duration duration;

  /// Si el usuario puede descartar manualmente la notificación con "×".
  final bool isDismissible;

  /// Id de la notificación persistida, cuando proviene del backend.
  final String? sourceId;

  /// Ruta interna que debe abrirse al tocar el aviso.
  final String? destinationPath;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    this.title,
    required this.duration,
    this.isDismissible = true,
    this.sourceId,
    this.destinationPath,
  });

  /// Crea un [NotificationModel] con un id basado en timestamp.
  factory NotificationModel.create({
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    bool isDismissible = true,
    String? sourceId,
    String? destinationPath,
  }) {
    return NotificationModel(
      id: '${type.name}_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      message: message,
      title: title,
      duration: duration ?? type.defaultDuration,
      isDismissible: isDismissible,
      sourceId: sourceId,
      destinationPath: destinationPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        message,
        title,
        duration,
        isDismissible,
        sourceId,
        destinationPath,
      ];
}
