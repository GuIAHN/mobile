/// Validadores de formulario reutilizables para la app guIAutomotriz.
/// Devuelven `null` si es válido o un mensaje de error si no.
abstract class Validators {
  Validators._();

  // ── Email ─────────────────────────────────────────────────────────────────
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

  // ── Contraseña ────────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña.';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  // ── Texto requerido ───────────────────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido.';
    }
    return null;
  }

  // ── Número ────────────────────────────────────────────────────────────────
  static String? positiveInt(String? value, {String fieldName = 'Valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido.';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) {
      return '$fieldName debe ser un número positivo.';
    }
    return null;
  }

  // ── Año de vehículo ───────────────────────────────────────────────────────
  static String? vehicleYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El año es requerido.';
    }
    final year = int.tryParse(value.trim());
    if (year == null) return 'Ingresa un año válido.';
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'El año debe estar entre 1900 y ${currentYear + 1}.';
    }
    return null;
  }

  // ── Placa / Matrícula ─────────────────────────────────────────────────────
  static String? licensePlate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La placa es requerida.';
    }
    if (value.trim().length < 5 || value.trim().length > 10) {
      return 'La placa debe tener entre 5 y 10 caracteres.';
    }
    return null;
  }

  // ── Teléfono ─────────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido.';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Ingresa un número de teléfono válido.';
    }
    return null;
  }
}
