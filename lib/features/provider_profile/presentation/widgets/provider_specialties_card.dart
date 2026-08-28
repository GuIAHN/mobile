import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/count_pill.dart';
import '../../../../core/domain/entities/specialty.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/provider_profile_providers.dart';

class ProviderSpecialtiesCard extends ConsumerWidget {
  const ProviderSpecialtiesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialtiesAsync = ref.watch(providerSpecialtiesProvider);

    return Container(
      key: const Key('provider-specialties-card'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'ESPECIALIDADES',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.overline,
                ),
              ),
              specialtiesAsync.maybeWhen(
                data: (specialties) => specialties.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: CountPill(count: specialties.length),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
              const Spacer(),
              _EditSpecialtiesButton(
                enabled: specialtiesAsync.hasValue,
                onPressed: () => _openEditor(
                  context,
                  ref,
                  specialtiesAsync.value ?? const [],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Text(
            'Indica los servicios que ofreces para que los clientes puedan encontrarte.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          specialtiesAsync.when(
            loading: () => const _SpecialtiesLoading(),
            error: (error, _) => _SpecialtiesError(
              message: _friendlyError(error),
              onRetry: () => ref.invalidate(providerSpecialtiesProvider),
            ),
            data: (specialties) => specialties.isEmpty
                ? const _EmptySpecialties()
                : _SpecialtiesList(specialties: specialties),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    List<Specialty> current,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SpecialtiesEditor(initialSpecialties: current),
    );

    if (updated == true && context.mounted) {
      context.showSnackBar(
        'Especialidades actualizadas correctamente.',
        isSuccess: true,
      );
    }
  }
}

/// Acción secundaria de la sección, con un área táctil estable de 48 dp.
class _EditSpecialtiesButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _EditSpecialtiesButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Editar especialidades',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('edit-provider-specialties'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.buttonHeightMd,
              minWidth: AppSpacing.buttonHeightMd,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLineIcon(
                    AppIcons.edit,
                    size: AppIconSize.action,
                    color: enabled ? AppColors.primary : AppColors.textDisabled,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Editar',
                    style: AppTypography.label.copyWith(
                      color:
                          enabled ? AppColors.primary : AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialtiesList extends StatelessWidget {
  const _SpecialtiesList({required this.specialties});

  final List<Specialty> specialties;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${specialties.length} ${specialties.length == 1 ? 'especialidad configurada' : 'especialidades configuradas'}',
      child: Column(
        children: [
          for (var index = 0; index < specialties.length; index++) ...[
            _SpecialtyRow(specialty: specialties[index]),
            if (index < specialties.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.xl3 + AppSpacing.md,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _SpecialtyRow extends StatelessWidget {
  const _SpecialtyRow({required this.specialty});

  final Specialty specialty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Especialidad ${specialty.name}',
      excludeSemantics: true,
      child: ConstrainedBox(
        key: Key('provider-specialty-${specialty.id}'),
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: AppSpacing.xl3,
                child: AppLineIcon(
                  _specialtyIcon(specialty.name),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  specialty.name,
                  style:
                      AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySpecialties extends StatelessWidget {
  const _EmptySpecialties();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: AppSpacing.xl3,
            child: AppLineIcon(
              AppIcons.services,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no has agregado especialidades.',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Usa Editar para indicar los servicios que puedes atender.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtiesLoading extends StatelessWidget {
  const _SpecialtiesLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando especialidades',
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(
              bottom: index == 2 ? 0 : AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSpacing.xl3,
                  height: AppSpacing.xl3,
                  decoration: const BoxDecoration(
                    color: AppColors.grey100,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: 0.72,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: AppSpacing.md,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialtiesError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SpecialtiesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: AppSpacing.xl3,
                child: AppLineIcon(
                  AppIcons.connectivityError,
                  color: AppColors.errorInk,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.errorInk,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xl3 + AppSpacing.md,
            ),
            child: TextButton(
              key: const Key('retry-provider-specialties'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorInk,
                minimumSize: const Size(88, AppSpacing.buttonHeightMd),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtiesEditor extends ConsumerStatefulWidget {
  final List<Specialty> initialSpecialties;

  const _SpecialtiesEditor({required this.initialSpecialties});

  @override
  ConsumerState<_SpecialtiesEditor> createState() => _SpecialtiesEditorState();
}

class _SpecialtiesEditorState extends ConsumerState<_SpecialtiesEditor> {
  late final Set<String> _initialIds;
  late final Set<String> _selectedIds;
  final _searchController = TextEditingController();
  String _query = '';
  String? _saveError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialIds = widget.initialSpecialties.map((item) => item.id).toSet();
    _selectedIds = {..._initialIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _selectedIds.length != _initialIds.length ||
      !_selectedIds.containsAll(_initialIds);

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(specialtiesProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Container(
      height: screenHeight * 0.86,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(child: _buildSearchField()),
                ),
                ...catalogAsync.when(
                  loading: () => [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                  error: (error, _) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _SpecialtiesError(
                          message: _friendlyError(error),
                          onRetry: () => ref.invalidate(specialtiesProvider),
                        ),
                      ),
                    ),
                  ],
                  data: (catalog) {
                    final filtered = _filterCatalog(catalog);
                    if (filtered.isEmpty) {
                      return [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _query.isEmpty
                                    ? 'No hay especialidades disponibles.'
                                    : 'No encontramos especialidades con ese nombre.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm,
                              ),
                            ),
                          ),
                        ),
                      ];
                    }
                    return [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final specialty = filtered[index];
                            return _SpecialtyOption(
                              specialty: specialty,
                              selected: _selectedIds.contains(specialty.id),
                              enabled: !_isSaving,
                              onTap: () => _toggle(specialty.id),
                            );
                          },
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
          _buildFooter(catalogAsync.hasValue),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Editar especialidades',
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega o quita los servicios que ofreces.',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('close-specialties-editor'),
                tooltip: 'Cerrar',
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const AppLineIcon(
                  AppIcons.close,
                  size: AppIconSize.action,
                ),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUSCAR ESPECIALIDAD', style: AppTypography.overline),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('specialties-search-field'),
          controller: _searchController,
          enabled: !_isSaving,
          onChanged: (value) => setState(() => _query = value.trim()),
          textInputAction: TextInputAction.search,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Escribe el nombre del servicio',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textPlaceholder,
            ),
            prefixIcon: const AppLineIcon(
              AppIcons.search,
              size: AppIconSize.action,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.buttonHeightMd,
                      minHeight: AppSpacing.buttonHeightMd,
                    ),
                    icon: const AppLineIcon(
                      AppIcons.close,
                      size: AppIconSize.action,
                    ),
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool catalogReady) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_saveError != null) ...[
              Text(
                _saveError!,
                key: const Key('specialties-save-error'),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.errorInk,
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('save-provider-specialties'),
                onPressed:
                    catalogReady && _hasChanges && !_isSaving ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.disabledText,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _hasChanges ? 'GUARDAR CAMBIOS' : 'SIN CAMBIOS',
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Specialty> _filterCatalog(List<Specialty> catalog) {
    final normalizedQuery = _query.toLowerCase();
    if (normalizedQuery.isEmpty) return catalog;
    return catalog
        .where((item) => item.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }

  void _toggle(String id) {
    setState(() {
      _saveError = null;
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final ids = _selectedIds.toList(growable: false)..sort();
    final result =
        await ref.read(updateProviderSpecialtiesUseCaseProvider)(ids);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isSaving = false;
        _saveError = failure.message;
      }),
      (updatedSpecialties) {
        ref.read(providerSpecialtiesCacheProvider.notifier).state =
            updatedSpecialties;
        Navigator.pop(context, true);
      },
    );
  }
}

class _SpecialtyOption extends StatelessWidget {
  final Specialty specialty;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _SpecialtyOption({
    required this.specialty,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: specialty.name,
      child: Material(
        color: selected ? AppColors.primaryMuted : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          key: Key('specialty-option-${specialty.id}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.xl3,
                  child: AppLineIcon(
                    _specialtyIcon(specialty.name),
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    specialty.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppLineIcon(
                  selected ? AppIcons.selected : AppIcons.unselected,
                  size: AppIconSize.action,
                  color: selected ? AppColors.primary : AppColors.grey500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar las especialidades. Inténtalo nuevamente.';
}

IconData _specialtyIcon(String name) {
  final normalized = name
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  if (normalized.contains('freno') || normalized.contains('abs')) {
    return AppIcons.brakes;
  }
  if (normalized.contains('transmision') ||
      normalized.contains('caja') ||
      normalized.contains('cambio') ||
      normalized.contains('embrague') ||
      normalized.contains('cvt')) {
    return AppIcons.transmission;
  }
  if (normalized.contains('suspension') ||
      normalized.contains('direccion') ||
      normalized.contains('alineacion')) {
    return AppIcons.suspension;
  }
  if (normalized.contains('electric') ||
      normalized.contains('electron') ||
      normalized.contains('computadora') ||
      normalized.contains('encendido') ||
      normalized.contains('diagnostico') ||
      normalized.contains('escaneo')) {
    return AppIcons.electrical;
  }
  if (normalized.contains('latoneria') ||
      normalized.contains('pintura') ||
      normalized.contains('carroceria') ||
      normalized.contains('detallado') ||
      normalized.contains('estetica')) {
    return AppIcons.bodywork;
  }
  if (normalized.contains('climat') ||
      normalized.contains('aire acondicionado')) {
    return AppIcons.climate;
  }
  if (normalized.contains('inyeccion') || normalized.contains('combustible')) {
    return AppIcons.fuel;
  }
  if (normalized.contains('neumatic') ||
      normalized.contains('caucho') ||
      normalized.contains('rueda') ||
      normalized.contains('rin')) {
    return AppIcons.wheels;
  }
  if (normalized.contains('audio') || normalized.contains('multimedia')) {
    return AppIcons.audio;
  }
  if (normalized.contains('luz') || normalized.contains('iluminacion')) {
    return AppIcons.lighting;
  }
  if (normalized.contains('motor') ||
      normalized.contains('mecanica') ||
      normalized.contains('turbo')) {
    return AppIcons.engine;
  }
  return AppIcons.services;
}
