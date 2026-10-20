import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/provider_detail.dart';
import 'provider_photo.dart';

/// Identidad del mecánico dentro de su ficha, con acceso a la foto original.
class MechanicProfileHeader extends StatelessWidget {
  final ProviderDetail detail;
  final String heroTag;

  const MechanicProfileHeader(
      {super.key, required this.detail, required this.heroTag});

  Future<void> _openPhoto(BuildContext context) => showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Cerrar foto',
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => _MechanicPhotoViewer(detail: detail),
      );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = showsProviderImage(photoUrl: detail.photo);
    final portrait = SizedBox(
      key: const Key('mechanic-profile-photo'),
      width: 96,
      height: 128,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: ColoredBox(
          color: AppColors.background,
          child: HeroMode(
            enabled: !MediaQuery.disableAnimationsOf(context),
            child: Hero(
              tag: heroTag,
              child: ProviderPhoto(
                photoUrl: detail.photo,
                providerName: detail.nombre,
                fit: BoxFit.contain,
                frameBuilder: (_, child, frame, __) => frame == null
                    ? const _PhotoPlaceholder(loading: true)
                    : child,
                loadingFallback: const _PhotoPlaceholder(loading: true),
                fallback: const _PhotoPlaceholder(),
              ),
            ),
          ),
        ),
      ),
    );
    final photo = hasPhoto
        ? Semantics(
            button: true,
            label: 'Ver foto completa de ${detail.nombre}',
            child: Tooltip(
              message: 'Ver foto completa',
              child: Stack(
                children: [
                  portrait,
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(onTap: () => _openPhoto(context)),
                    ),
                  ),
                ],
              ),
            ),
          )
        : portrait;
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(detail.nombre, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const AppLineIcon(AppIcons.mechanic,
                size: AppIconSize.inline, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Mecánico', style: AppTypography.bodySm)),
            if (detail.verified)
              Semantics(
                label: 'Perfil verificado',
                child: const AppLineIcon(AppIcons.verified,
                    color: AppColors.celesteInk),
              ),
          ],
        ),
      ],
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
          constraints.maxWidth < 240) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [photo, const SizedBox(height: AppSpacing.md), identity],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          photo,
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: identity)
        ],
      );
    });
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final bool loading;
  final bool fullScreen;

  const _PhotoPlaceholder({this.loading = false, this.fullScreen = false});

  @override
  Widget build(BuildContext context) => Center(
        child: loading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                  semanticsLabel: 'Cargando foto',
                ))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLineIcon(AppIcons.account,
                      size: AppIconSize.feature,
                      color: AppColors.textSecondary),
                  if (fullScreen) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('No se pudo cargar la foto',
                        style: AppTypography.body, textAlign: TextAlign.center),
                  ],
                ],
              ),
      );
}

class _MechanicPhotoViewer extends StatefulWidget {
  final ProviderDetail detail;

  const _MechanicPhotoViewer({required this.detail});

  @override
  State<_MechanicPhotoViewer> createState() => _MechanicPhotoViewerState();
}

class _MechanicPhotoViewerState extends State<_MechanicPhotoViewer> {
  final _transform = TransformationController();
  final _viewportKey = GlobalKey();
  int _viewportRevision = 0;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final size = _viewportKey.currentContext!.size!;
    final center = Offset(size.width / 2, size.height / 2);
    final sceneCenter = _transform.toScene(center);
    final scale =
        (_transform.value.getMaxScaleOnAxis() * factor).clamp(1.0, 4.0);
    _applyTransform(Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        (center.dx - sceneCenter.dx * scale)
            .clamp(size.width * (1 - scale), 0.0),
        (center.dy - sceneCenter.dy * scale)
            .clamp(size.height * (1 - scale), 0.0),
        0,
      ));
  }

  void _applyTransform(Matrix4 value) {
    // Remounting stops InteractiveViewer's inertia before applying the button
    // action, so a released pinch cannot overwrite zoom or reset afterward.
    setState(() => _viewportRevision++);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _transform.value = value;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: AppColors.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Foto de ${widget.detail.nombre}',
                            style: AppTypography.title)),
                    IconButton(
                      tooltip: 'Cerrar foto',
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () => Navigator.pop(context),
                      icon: const AppLineIcon(AppIcons.close,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: LayoutBuilder(
                      key: _viewportKey,
                      builder: (context, constraints) => InteractiveViewer(
                            key: ValueKey(_viewportRevision),
                            transformationController: _transform,
                            minScale: 1,
                            maxScale: 4,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              child: ProviderPhoto(
                                photoUrl: widget.detail.photo,
                                providerName: widget.detail.nombre,
                                fit: BoxFit.contain,
                                frameBuilder: (_, child, frame, __) =>
                                    frame == null
                                        ? const _PhotoPlaceholder(loading: true)
                                        : child,
                                loadingFallback:
                                    const _PhotoPlaceholder(loading: true),
                                fallback:
                                    const _PhotoPlaceholder(fullScreen: true),
                              ),
                            ),
                          )),
                ),
                const SizedBox(height: AppSpacing.md),
                ValueListenableBuilder<Matrix4>(
                  valueListenable: _transform,
                  builder: (context, value, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Alejar foto',
                        color: AppColors.textPrimary,
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: value.getMaxScaleOnAxis() > 1
                            ? () => _zoom(1 / 1.5)
                            : null,
                        icon: const AppLineIcon(AppIcons.zoomOut),
                      ),
                      Flexible(
                          child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: () => _applyTransform(Matrix4.identity()),
                        child: Text('Restablecer', style: AppTypography.label),
                      )),
                      IconButton(
                        tooltip: 'Acercar foto',
                        color: AppColors.textPrimary,
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                        onPressed: value.getMaxScaleOnAxis() < 4
                            ? () => _zoom(1.5)
                            : null,
                        icon: const AppLineIcon(AppIcons.zoomIn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
