import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../provider_profile/presentation/widgets/provider_specialties_card.dart';
import '../../../provider_profile/presentation/widgets/store_catalog_card.dart';
import '../../../vehicles/presentation/widgets/profile_garage.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_action_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/security_section.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      if (authState.errorMessage != null) {
        return SafeArea(
          child: ErrorView(
            message: authState.errorMessage!,
            onRetry: () => ref.read(authProvider.notifier).checkAuthStatus(),
          ),
        );
      }

      return const SafeArea(
        child: LoadingIndicator(message: 'Cargando tu perfil…'),
      );
    }

    final isConsumer =
        user.role == UserRole.consumer || user.role == UserRole.unknown;
    final isProfessionalProvider =
        user.role == UserRole.mechanic || user.role == UserRole.workshop;

    final sections = <Widget>[
      ProfileHeader(user: user),
      _AccountActionsSection(
        isConsumer: isConsumer,
        isProvider: user.role.isProvider,
        userId: user.id,
      ),
      if (isConsumer) const ProfileGarage(),
      if (isProfessionalProvider) const ProviderSpecialtiesCard(),
      if (user.role.isStore) const StoreCatalogCard(),
    ];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: 120,
          ),
          child: Column(
            children: [
              StaggeredEntrance(
                index: 0,
                child: Text(
                  'Perfil',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < sections.length; i++) ...[
                StaggeredEntrance(index: i + 1, child: sections[i]),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 4),
              _buildLogoutButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return PressableScale(
      onTap: () => _mostrarConfirmarLogout(context, ref),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          'CERRAR SESIÓN',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  void _mostrarConfirmarLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Text(
                '¿Cerrar Sesión?',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Deberás ingresar tus credenciales nuevamente para acceder a guIAutomotriz.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'CANCELAR',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cierra modal
                          ref.read(authProvider.notifier).logout().then((_) {
                            if (context.mounted) {
                              context.go(RouteNames.login);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'CERRAR SESIÓN',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountActionsSection extends StatelessWidget {
  final bool isConsumer;
  final bool isProvider;
  final String userId;

  const _AccountActionsSection({
    required this.isConsumer,
    required this.isProvider,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final reviewAction = isConsumer
        ? const _PendingReviewsSection()
        : isProvider
            ? _ReceivedReviewsSection(targetId: userId)
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MI CUENTA',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(child: SecuritySection()),
              if (reviewAction != null) ...[
                const SizedBox(width: 12),
                Expanded(child: reviewAction),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingReviewsSection extends StatelessWidget {
  const _PendingReviewsSection();

  @override
  Widget build(BuildContext context) {
    return ProfileActionCard(
      actionKey: const Key('open-pending-reviews'),
      semanticsLabel: 'Abrir reseñas pendientes',
      eyebrow: 'OPINIONES',
      title: 'Reseñas pendientes',
      subtitle: 'Valora las compras que recibiste.',
      onTap: () => context.push(RouteNames.pendingReviews),
    );
  }
}

class _ReceivedReviewsSection extends StatelessWidget {
  final String targetId;

  const _ReceivedReviewsSection({required this.targetId});

  @override
  Widget build(BuildContext context) {
    return ProfileActionCard(
      actionKey: const Key('open-received-reviews'),
      semanticsLabel: 'Abrir reseñas recibidas de clientes',
      eyebrow: 'REPUTACIÓN',
      title: 'Reseñas de clientes',
      subtitle: 'Consulta las opiniones que recibiste.',
      onTap: () => context.push(RouteNames.receivedReviewsPath(targetId)),
    );
  }
}
