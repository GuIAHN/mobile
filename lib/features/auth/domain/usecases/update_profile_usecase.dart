import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, User>> call({
    String? name,
    String? photo,
    String? phone,
    double? latitude,
    double? longitude,
  }) {
    return repository.updateProfile(
      name: name,
      photo: photo,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
