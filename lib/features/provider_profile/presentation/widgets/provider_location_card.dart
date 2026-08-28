import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/guia_map.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart';
import '../../../home/presentation/widgets/spare_part_wizard/request_location_selection.dart';

typedef ProviderLocationPicker = Future<RequestLocationSelection?> Function(
  BuildContext context,
  RequestLocationSelection? current,
);

typedef ProviderLocationSaver = Future<Failure?> Function(
  double latitude,
  double longitude,
);

typedef ProviderLocationPreviewBuilder = Widget Function(
  BuildContext context,
  LatLng point,
);

/// Configures the exact public point of a workshop or spare-parts store.
class ProviderLocationCard extends ConsumerStatefulWidget {
  final User user;
  final ProviderLocationPicker? locationPicker;
  final ProviderLocationSaver? locationSaver;
  final ProviderLocationPreviewBuilder? previewBuilder;

  const ProviderLocationCard({
    super.key,
    required this.user,
    this.locationPicker,
    this.locationSaver,
    this.previewBuilder,
  });

  @override
  ConsumerState<ProviderLocationCard> createState() =>
      _ProviderLocationCardState();
}

class _ProviderLocationCardState extends ConsumerState<ProviderLocationCard> {
  static const _defaultCenter = LatLng(10.4806, -66.9036);

  RequestLocationSelection? _selection;
  String? _saveError;
  bool _isSaving = false;

  String get _businessLabel =>
      widget.user.role == UserRole.workshop ? 'taller' : 'tienda';

  @override
  void initState() {
    super.initState();
    _selection = _selectionFrom(widget.user);
  }

  @override
  void didUpdateWidget(covariant ProviderLocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedUser = oldWidget.user.id != widget.user.id;
    final changedLocation = oldWidget.user.latitude != widget.user.latitude ||
        oldWidget.user.longitude != widget.user.longitude;
    if (changedUser || (changedLocation && !_isSaving && _saveError == null)) {
      _selection = _selectionFrom(widget.user);
      _saveError = null;
    }
  }

  RequestLocationSelection? _selectionFrom(User user) {
    final latitude = user.latitude;
    final longitude = user.longitude;
    if (latitude == null || longitude == null) return null;
    return RequestLocationSelection(
      latitude: latitude,
      longitude: longitude,
      source: RequestLocationSource.profile,
    );
  }

  Future<void> _openPicker() async {
    if (_isSaving) return;
    final picker = widget.locationPicker ?? _showDefaultPicker;
    final selected = await picker(context, _selection);
    if (!mounted || selected == null) return;

    setState(() {
      _selection = selected;
      _saveError = null;
    });
    await _saveSelection();
  }

  Future<RequestLocationSelection?> _showDefaultPicker(
    BuildContext context,
    RequestLocationSelection? current,
  ) {
    final center = current == null
        ? _defaultCenter
        : LatLng(current.latitude, current.longitude);
    return RequestLocationPickerDialog.show(
      context,
      initialCenter: center,
      initialSelection: current,
    );
  }

  Future<void> _saveSelection() async {
    final selection = _selection;
    if (selection == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    Failure? failure;
    try {
      final saver = widget.locationSaver ?? _saveWithAuthNotifier;
      failure = await saver(selection.latitude, selection.longitude);
    } catch (_) {
      failure = const UnexpectedFailure(
        message: 'No pudimos guardar la ubicación. Inténtalo nuevamente.',
      );
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saveError = failure?.message;
    });

    if (failure == null) {
      context.showSnackBar(
        'Ubicación del $_businessLabel actualizada.',
        isSuccess: true,
      );
    }
  }

  Future<Failure?> _saveWithAuthNotifier(
    double latitude,
    double longitude,
  ) {
    return ref.read(authProvider.notifier).updateLocation(
          latitude: latitude,
          longitude: longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    final configured = selection != null && _saveError == null && !_isSaving;

    return Container(
      key: const Key('provider-location-card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LocationHeading(
            title: 'Punto de tu $_businessLabel',
            action: selection == null
                ? null
                : _LocationEditButton(
                    enabled: !_isSaving,
                    onPressed: _openPicker,
                  ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Text(
            selection == null
                ? 'Configura el punto exacto de tu $_businessLabel para aparecer en búsquedas cercanas.'
                : 'Este punto ayuda a tus clientes a encontrarte y calcula la cercanía en sus búsquedas.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (selection == null)
            _EmptyLocation(onConfigure: _openPicker)
          else ...[
            _buildPreview(selection),
            const SizedBox(height: AppSpacing.md),
            if (_isSaving)
              const _SavingLocation()
            else if (_saveError != null)
              _LocationSaveError(
                message: _saveError!,
                onRetry: _saveSelection,
                onChooseAnother: _openPicker,
              )
            else if (configured)
              const _ConfiguredLocation(),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(RequestLocationSelection selection) {
    final point = LatLng(selection.latitude, selection.longitude);
    final customBuilder = widget.previewBuilder;
    return KeyedSubtree(
      key: const Key('provider-location-preview'),
      child: customBuilder == null
          ? GuiaMap(
              point: point,
              height: 176,
              borderRadius: AppSpacing.radiusLg,
              interactive: false,
              mapKey: const Key('provider-location-map'),
            )
          : customBuilder(context, point),
    );
  }
}

class _LocationHeading extends StatelessWidget {
  final String title;
  final Widget? action;

  const _LocationHeading({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final overlineStyle = AppTypography.overline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AppSpacing.xs),
          child: AppLineIcon(
            AppIcons.location,
            size: AppIconSize.leading,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: action == null ? 0 : 112,
                    ),
                    child: Text(
                      'UBICACIÓN',
                      style: overlineStyle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(title, style: AppTypography.title),
                ],
              ),
              if (action != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: action!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationEditButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _LocationEditButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Cambiar ubicación del negocio',
      excludeSemantics: true,
      child: TextButton.icon(
        key: const Key('edit-provider-location'),
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabledText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        icon: const AppLineIcon(
          AppIcons.edit,
          size: AppIconSize.inline,
        ),
        label: Text(
          'Cambiar',
          style: AppTypography.label.copyWith(
            color: enabled ? AppColors.primary : AppColors.disabledText,
          ),
        ),
      ),
    );
  }
}

class _EmptyLocation extends StatelessWidget {
  final VoidCallback onConfigure;

  const _EmptyLocation({required this.onConfigure});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: 'La ubicación del negocio aún no está configurada.',
          excludeSemantics: true,
          child: Container(
            key: const Key('provider-location-empty'),
            constraints: const BoxConstraints(minHeight: 128),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLineIcon(
                  AppIcons.map,
                  size: AppIconSize.feature,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aún no has definido tu ubicación.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          key: const Key('configure-provider-location'),
          label: 'CONFIGURAR UBICACIÓN',
          leadingIcon: AppIcons.location,
          height: AppSpacing.buttonHeightLg,
          onPressed: onConfigure,
        ),
      ],
    );
  }
}

class _SavingLocation extends StatelessWidget {
  const _SavingLocation();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Guardando ubicación',
      excludeSemantics: true,
      child: Container(
        key: const Key('provider-location-saving'),
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(
              dimension: AppIconSize.action,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Guardando ubicación…',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguredLocation extends StatelessWidget {
  const _ConfiguredLocation();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Ubicación configurada',
      child: Container(
        key: const Key('provider-location-configured'),
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const AppLineIcon(
              AppIcons.selected,
              size: AppIconSize.action,
              color: AppColors.successInk,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ubicación configurada',
                style: AppTypography.label.copyWith(
                  color: AppColors.successInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSaveError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onChooseAnother;

  const _LocationSaveError({
    required this.message,
    required this.onRetry,
    required this.onChooseAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$message Puedes reintentar o elegir otro punto.',
      child: Container(
        key: const Key('provider-location-save-error'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLineIcon(
                  AppIcons.cloudError,
                  size: AppIconSize.action,
                  color: AppColors.errorInk,
                ),
                const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.buttonHeightMd,
              child: ElevatedButton.icon(
                key: const Key('retry-provider-location-save'),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull,
                    ),
                  ),
                ),
                icon: const AppLineIcon(
                  AppIcons.retry,
                  size: AppIconSize.action,
                ),
                label: const Text('Reintentar guardado'),
              ),
            ),
            TextButton(
              key: const Key('choose-another-provider-location'),
              onPressed: onChooseAnother,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorInk,
                minimumSize: const Size.fromHeight(
                  AppSpacing.buttonHeightMd,
                ),
              ),
              child: const Text('Elegir otro punto'),
            ),
          ],
        ),
      ),
    );
  }
}
