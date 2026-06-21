import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';
import '../notifications/notification_provider.dart';

extension WidgetRefAsyncError on WidgetRef {
  /// Escucha cambios en un proveedor `AsyncValue` y muestra un toast de error
  /// via [NotificationService] si el estado cambia a error.
  ///
  /// La API pública no ha cambiado — todos los callers existentes continúan
  /// funcionando sin ninguna modificación.
  void listenAsyncError(
    ProviderListenable<AsyncValue<dynamic>> provider,
    // ignore: avoid_unused_parameters
    // BuildContext se mantiene por compatibilidad de API, aunque ya no se usa
    // ignore: avoid_positional_boolean_parameters
    Object context, {
    String? customMessage,
  }) {
    listen(provider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        String message = customMessage ?? 'Ha ocurrido un error inesperado.';

        if (error is NetworkException) {
          message = error.message;
        } else if (error is NetworkFailure) {
          message = error.message;
        } else if (error is Failure) {
          message = error.message;
        } else if (error is Exception) {
          message = error.toString().replaceAll('Exception: ', '');
        } else {
          message = error.toString();
        }

        NotificationService.error(this, message);
      }
    });
  }
}

