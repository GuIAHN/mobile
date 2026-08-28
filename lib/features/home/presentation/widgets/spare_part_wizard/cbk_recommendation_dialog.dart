part of 'spare_part_wizard_page.dart';

class _CbkRecommendationSheet extends StatelessWidget {
  const _CbkRecommendationSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 104,
                height: 44,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Image.asset(
                  'assets/images/logo_cbk.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'CBK',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Quieres priorizar pastillas CBK?',
                textAlign: TextAlign.center,
                style: AppTypography.h2,
              ),
              const SizedBox(height: 12),
              Text(
                'Te recomendamos CBK, una de las marcas más reconocidas con más de 25 años en el mercado y calidad OEM (Fabricante de Equipamiento Original), lo que garantiza la misma seguridad y calidad con la que tu auto salió de fábrica; ¿deseas realizar la búsqueda con pastillas CBK principalmente?',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Text(
                    'BUSCAR CBK PRIMERO',
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'MANTENER MI BÚSQUEDA',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
