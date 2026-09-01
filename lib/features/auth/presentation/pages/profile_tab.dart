import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/layout/bottom_navigation_insets.dart';
import '../../../provider_profile/presentation/widgets/provider_location_card.dart';
import '../../../provider_profile/presentation/widgets/provider_specialties_card.dart';
import '../../../provider_profile/presentation/widgets/store_catalog_card.dart';
import '../../../vehicles/presentation/widgets/profile_garage.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_action_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/security_section.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  static const double _maxPageWidth = 768;

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
    final isPlaceProvider = user.role.isWorkshop || user.role.isStore;
    final pendingReviewCount = isConsumer
        ? ref.watch(pendingReviewsProvider).valueOrNull?.length ?? 0
        : 0;

    final sections = <Widget>[
      ProfileHeader(user: user),
      _AccountActionsSection(
        isConsumer: isConsumer,
        isProvider: user.role.isProvider,
        userId: user.id,
        pendingReviewCount: pendingReviewCount,
      ),
      if (isPlaceProvider) ProviderLocationCard(user: user),
      if (isConsumer) const ProfileGarage(),
      if (isProfessionalProvider) const ProviderSpecialtiesCard(),
      if (user.role.isStore) const StoreCatalogCard(),
    ];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const Key('profile-scroll-view'),
        physics: const BouncingScrollPhysics(),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxPageWidth),
            child: Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl2,
                right: AppSpacing.xl2,
                top: AppSpacing.xl2,
                bottom: bottomNavigationContentInset(context) + AppSpacing.lg,
              ),
              child: Column(
                key: const Key('profile-content'),
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    StaggeredEntrance(index: i, child: sections[i]),
                    const SizedBox(height: AppSpacing.xl2),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _buildLogoutButton(context, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Cerrar sesión',
      excludeSemantics: true,
      child: PressableScale(
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
      ),
    );
  }

  void _mostrarConfirmarLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
                vertical: AppSpacing.xl3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.xl2),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Text(
                    '¿Cerrar Sesión?',
                    textAlign: TextAlign.center,
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
                  _LogoutSheetActions(
                    onCancel: () => Navigator.pop(context),
                    onLogout: () {
                      Navigator.pop(context);
                      ref.read(authProvider.notifier).logout().then((_) {
                        if (context.mounted) {
                          context.go(RouteNames.login);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoutSheetActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  const _LogoutSheetActions({
    required this.onCancel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cancelButton = OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      child: Text(
        'CANCELAR',
        textAlign: TextAlign.center,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
    final logoutButton = ElevatedButton(
      onPressed: onLogout,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 0,
      ),
      child: Text(
        'CERRAR SESIÓN',
        textAlign: TextAlign.center,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledLabel = MediaQuery.textScalerOf(context).scale(13);
        final stackButtons = constraints.maxWidth < 360 || scaledLabel >= 18;

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cancelButton,
              const SizedBox(height: AppSpacing.md),
              logoutButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: logoutButton),
          ],
        );
      },
    );
  }
}

class _AccountActionsSection extends StatelessWidget {
  final bool isConsumer;
  final bool isProvider;
  final String userId;
  final int pendingReviewCount;

  const _AccountActionsSection({
    required this.isConsumer,
    required this.isProvider,
    required this.userId,
    required this.pendingReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final reviewAction = isConsumer
        ? _PendingReviewsSection(count: pendingReviewCount)
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
        LayoutBuilder(
          builder: (context, constraints) {
            if (reviewAction == null) return const SecuritySection();

            final scaledBody = MediaQuery.textScalerOf(context).scale(13);
            // 152 dp keeps the shortcuts compact but readable at the normal
            // text scale. With the page gutters and 16 dp gap this preserves
            // one row from ~368 dp-wide phones upwards; narrower phones or
            // enlarged system text still receive the stacked layout.
            const minimumCardWidth = 152.0;
            final stackCards =
                constraints.maxWidth < minimumCardWidth * 2 + AppSpacing.md ||
                    scaledBody >= 18;
            if (stackCards) {
              return Column(
                key: const Key('profile-account-actions-column'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SecuritySection(),
                  const SizedBox(height: AppSpacing.md),
                  reviewAction,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                key: const Key('profile-account-actions-row'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: SecuritySection()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: reviewAction),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PendingReviewsSection extends StatelessWidget {
  final int count;

  const _PendingReviewsSection({required this.count});

  @override
  Widget build(BuildContext context) {
    return ProfileActionCard(
      actionKey: const Key('open-pending-reviews'),
      semanticsLabel: count == 0
          ? 'Abrir reseñas pendientes'
          : 'Abrir reseñas pendientes, $count pendiente${count == 1 ? '' : 's'}',
      eyebrow: 'OPINIONES',
      title: 'Reseñas pendientes',
      subtitle: 'Valora las compras que recibiste.',
      icon: Icons.rate_review_outlined,
      badgeCount: count,
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
      icon: Icons.star_outline_rounded,
      onTap: () => context.push(RouteNames.receivedReviewsPath(targetId)),
    );
  }
}
