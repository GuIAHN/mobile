import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/home_providers.dart';

class MechanicDetailPage extends ConsumerWidget {
  final String mechanicId;

  const MechanicDetailPage({super.key, required this.mechanicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
        providerDetailProvider((id: mechanicId, type: ServiceType.mechanic)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => const _SkeletonLoader(),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (detail) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header Sliver ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: AppColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18),
                    color: AppColors.textPrimary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _HeaderBackground(
                  nombre: detail.nombre,
                  esTaller: detail.esTaller,
                  verified: detail.verified,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Rating & distancia
                  _StatsRow(
                    rating: detail.rating,
                    distanciaKm: detail.distanciaKm,
                    tarifa: detail.tarifa,
                  ),
                  const SizedBox(height: 24),

                  // Especialidades
                  if (detail.especialidades.isNotEmpty) ...[
                    const _SectionTitle(title: 'ESPECIALIDADES'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.especialidades
                          .map((e) => _SpecialtyChip(label: e))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Descripción
                  if (detail.descripcion != null &&
                      detail.descripcion!.isNotEmpty) ...[
                    const _SectionTitle(title: 'SOBRE EL MECÁNICO'),
                    const SizedBox(height: 12),
                    _DescriptionCard(text: detail.descripcion!),
                    const SizedBox(height: 24),
                  ],

                  // Contacto
                  const _SectionTitle(title: 'CONTACTO'),
                  const SizedBox(height: 12),
                  if (detail.telefono != null)
                    _ContactTile(
                      icon: Icons.phone_outlined,
                      label: detail.telefono!,
                      color: AppColors.success,
                    ),
                  if (detail.email != null)
                    _ContactTile(
                      icon: Icons.email_outlined,
                      label: detail.email!,
                      color: AppColors.primary,
                    ),
                  const SizedBox(height: 36),

                  // CTA
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Conectar con chat o WhatsApp
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SOLICITAR SERVICIO',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeaderBackground extends StatelessWidget {
  final String nombre;
  final bool esTaller;
  final bool verified;

  const _HeaderBackground(
      {required this.nombre,
      required this.esTaller,
      required this.verified});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          // Avatar circular
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            ),
            child: Icon(
              esTaller ? Icons.warehouse_rounded : Icons.build_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombre,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (verified) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified_rounded,
                    size: 18, color: Colors.white),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            esTaller ? 'Taller Mecánico' : 'Mecánico Independiente',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final double? rating;
  final double? distanciaKm;
  final double? tarifa;

  const _StatsRow({this.rating, this.distanciaKm, this.tarifa});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (rating != null) ...[
            Expanded(
              child: _StatItem(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: rating!.toStringAsFixed(1),
                label: 'Rating',
              ),
            ),
            _Divider(),
          ],
          if (distanciaKm != null) ...[
            Expanded(
              child: _StatItem(
                icon: Icons.near_me_rounded,
                iconColor: AppColors.primary,
                value: '${distanciaKm!.toStringAsFixed(1)} km',
                label: 'Distancia',
              ),
            ),
          ],
          if (tarifa != null) ...[
            _Divider(),
            Expanded(
              child: _StatItem(
                icon: Icons.attach_money_rounded,
                iconColor: AppColors.success,
                value: '\$${tarifa!.toStringAsFixed(0)}/h',
                label: 'Tarifa',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 36, color: AppColors.grey200, margin: const EdgeInsets.symmetric(horizontal: 8));
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatItem(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        Text(label,
            style: GoogleFonts.hankenGrotesk(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  const _SpecialtyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(99),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 13.5,
          height: 1.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ContactTile(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 220, color: AppColors.grey100),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: List.generate(
                4,
                (_) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el perfil',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
