import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/enums/user_role.dart';
import '../../core/providers/current_user_provider.dart';

/// Widget condicional que renderiza su [child] únicamente si el usuario
/// tiene uno de los roles especificados en [allowedRoles].
/// En caso contrario, renderiza [fallback] (por defecto un widget vacío).
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);

    if (allowedRoles.contains(role)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
