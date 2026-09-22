import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../domain/enums/user_role.dart';

/// Provider reactivo que expone el usuario autenticado actual (o null).
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider reactivo que expone el rol del usuario autenticado actual.
/// Si no está autenticado, devuelve [UserRole.unknown].
final currentRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role ?? UserRole.unknown;
});
