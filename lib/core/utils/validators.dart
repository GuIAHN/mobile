import 'venezuelan_phone_number.dart';

/// Validadores de formulario reutilizables para la app guIAutomotriz.
/// Devuelven `null` si el valor es válido o un mensaje de error si no.
abstract class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido.';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (!value.contains(RegExp(r'[0-9]')) ||
        !value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
      return 'Debe contener al menos un número y un símbolo especial.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != original) return 'Las contraseñas no coinciden.';
    return null;
  }

  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido.';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido.';
    }
    if (VenezuelanPhoneNumber.toLocal(value) == null) {
      return 'Selecciona un prefijo y completa los 7 dígitos.';
    }
    return null;
  }
}
