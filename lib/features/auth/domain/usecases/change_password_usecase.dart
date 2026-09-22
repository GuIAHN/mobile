import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case to change the current user's password. Kept independent of
/// [AuthNotifier]/[AuthState] so it does not toggle the global auth loading
/// flag (which other widgets, like the profile header, read to disable
/// unrelated actions such as the avatar picker).
class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
