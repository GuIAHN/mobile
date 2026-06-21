import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

extension WidgetRefAsyncError on WidgetRef {
  /// Escucha cambios en un proveedor `AsyncValue` y muestra un `SnackBar`
  /// si el estado cambia a error. Evita mostrar errores si el estado está cargando.
  void listenAsyncError(
    ProviderListenable<AsyncValue<dynamic>> provider,
    BuildContext context, {
    String? customMessage,
  }) {
    listen(provider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        String message = customMessage ?? 'Ha ocurrido un error inesperado.';

        if (error is NetworkException) {
          message = error.message ?? 'Sin conexión a internet. Verifica tu red.';
        } else if (error is NetworkFailure) {
          message = error.message;
        } else if (error is Exception) {
          message = error.toString().replaceAll('Exception: ', '');
        } else {
          message = error.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}
