import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Store category configuration in the spare parts catalog.
class StoreCategoryConfig {
  final String categoryId;
  final double minPrice;
  final bool servesAllBrands;
  final List<String> brandIds;

  const StoreCategoryConfig({
    required this.categoryId,
    this.minPrice = 1.0,
    this.servesAllBrands = false,
    required this.brandIds,
  });
}

/// Authentication repository contract (pure domain).
/// The implementation resides in the data layer.
abstract class AuthRepository {
  /// Logs in with [email] and [password].
  /// Returns the authenticated [User] or a [Failure].
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Registers a new user with their respective role.
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  });

  /// Registers a mechanic or workshop.
  Future<Either<Failure, User>> registerMechanic({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String description,
    required bool isWorkshop,
    required String identification,
    required List<String> specialtyIds,
  });

  /// Registers a store and configures its initial catalog.
  Future<Either<Failure, User>> registerStore({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required List<StoreCategoryConfig> catalog,
  });

  /// Closes the current session and clears stored tokens.
  Future<Either<Failure, void>> logout();

  /// Returns the currently authenticated user (by stored token).
  Future<Either<Failure, User>> getCurrentUser();
}

