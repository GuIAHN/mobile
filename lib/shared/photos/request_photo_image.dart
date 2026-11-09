import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/media_url.dart';

/// Shared network preview: resolves local server URLs on physical devices.
class RequestPhotoImage extends StatefulWidget {
  const RequestPhotoImage(
      {super.key, required this.url, this.fit = BoxFit.contain});
  final String url;
  final BoxFit fit;
  @override
  State<RequestPhotoImage> createState() => _RequestPhotoImageState();
}

class _RequestPhotoImageState extends State<RequestPhotoImage> {
  int _revision = 0;
  @override
  Widget build(BuildContext context) =>
      Image.network(resolveMediaUrl(widget.url) ?? widget.url,
          key: ValueKey((widget.url, _revision)),
          fit: widget.fit,
          frameBuilder: (context, child, frame, synchronous) =>
              synchronous || frame != null
                  ? child
                  : Center(
                      child: SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                              value: MediaQuery.disableAnimationsOf(context)
                                  ? 0.5
                                  : null,
                              color: AppColors.textSecondary,
                              semanticsLabel: 'Cargando foto',
                              strokeWidth: 2))),
          errorBuilder: (_, __, ___) => widget.fit == BoxFit.cover
              ? const Center(
                  child: AppLineIcon(AppIcons.cloudError,
                      color: AppColors.textSecondary))
              : Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const AppLineIcon(AppIcons.cloudError,
                      color: AppColors.textSecondary),
                  Text('No se pudo cargar la foto.',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.textPrimary),
                      textAlign: TextAlign.center),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          textStyle: AppTypography.label,
                          minimumSize: const Size(48, 48)),
                      onPressed: () async {
                        await NetworkImage(
                                resolveMediaUrl(widget.url) ?? widget.url)
                            .evict();
                        if (mounted) setState(() => _revision++);
                      },
                      child: const Text('Reintentar foto')),
                ])));
}
