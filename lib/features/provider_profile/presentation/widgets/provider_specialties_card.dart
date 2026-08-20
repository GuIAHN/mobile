import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/count_pill.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/provider_profile_providers.dart';

class ProviderSpecialtiesCard extends ConsumerWidget {
  const ProviderSpecialtiesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialtiesAsync = ref.watch(providerSpecialtiesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
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
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            'Indica los servicios que ofreces para que los clientes puedan encontrarte.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          specialtiesAsync.when(
            loading: () => const _SpecialtiesLoading(),
            error: (error, _) => _SpecialtiesError(
              message: _friendlyError(error),
              onRetry: () => ref.invalidate(providerSpecialtiesProvider),
            ),
            data: (specialties) => specialties.isEmpty
                ? const _EmptySpecialties()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .map(
                            (specialty) => _SpecialtyChip(specialty: specialty))
                        .toList(growable: false),
                  ),
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

/// Botón "Editar" discreto: solo texto + ícono sobre fondo transparente,
/// sin pill relleno, para no competir visualmente con los chips de
/// especialidad y quedar en línea con [_EditProfileButton] del header de
/// perfil.
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
          borderRadius: BorderRadius.circular(99),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: enabled ? AppColors.primary : AppColors.textDisabled,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Editar',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.primary
                          : AppColors.textDisabled,
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

class _SpecialtyChip extends StatelessWidget {
  final Specialty specialty;

  const _SpecialtyChip({required this.specialty});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Especialidad ${specialty.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                specialty.name,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
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
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aún no has agregado especialidades.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
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
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [92.0, 126.0, 108.0]
            .map(
              (width) => Container(
                width: width,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            )
            .toList(growable: false),
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
          Text(
            message,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.35,
              color: AppColors.errorInk,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('retry-provider-specialties'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorInk,
              minimumSize: const Size(88, 48),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Reintentar'),
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
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
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
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega o quita los servicios que ofreces.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      key: const Key('specialties-search-field'),
      controller: _searchController,
      enabled: !_isSaving,
      onChanged: (value) => setState(() => _query = value.trim()),
      textInputAction: TextInputAction.search,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar especialidad',
        hintStyle: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          color: AppColors.textPlaceholder,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
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
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
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
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  height: 1.35,
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
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: Key('specialty-option-${specialty.id}'),
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.grey50,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.build_circle_outlined,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    specialty.name,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.grey400,
                  size: 24,
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
