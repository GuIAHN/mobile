import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_user_page.dart';

void main() {
  group('registrationStepForError', () {
    test('keeps the final step for network and server errors', () {
      expect(
        registrationStepForError(
          currentStep: 3,
          message: 'Sin conexión a internet.',
        ),
        3,
      );
      expect(
        registrationStepForError(
          currentStep: 3,
          message: 'El sistema está en mantenimiento.',
        ),
        3,
      );
    });

    test('routes actionable field errors to their corresponding step', () {
      expect(
        registrationStepForError(
          currentStep: 3,
          message: 'El correo electrónico no tiene un formato válido.',
        ),
        1,
      );
      expect(
        registrationStepForError(
          currentStep: 3,
          message: 'La contraseña no cumple los requisitos.',
        ),
        2,
      );
      expect(
        registrationStepForError(
          currentStep: 1,
          message: 'acceptedTerms must be true',
        ),
        3,
      );
    });
  });
}
