import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/image_source_selector_sheet.dart';
import 'request_photos_controller.dart';
import 'request_photo_image.dart';

class RequestPhotosEditor extends StatefulWidget {
  const RequestPhotosEditor({super.key, required this.controller});
  final RequestPhotosController controller;

  @override
  State<RequestPhotosEditor> createState() => _RequestPhotosEditorState();
}

class _RequestPhotosEditorState extends State<RequestPhotosEditor> {
  bool _picking = false;
  String? _error;

  Future<void> _pick() async {
    if (_picking || !widget.controller.canAdd) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final source = await ImageSourceSelectorSheet.show(context);
      if (source == null || !mounted) return;
      final picker = ImagePicker();
      final files = source == ImageSource.camera
          ? [
              await picker.pickImage(
                  source: source,
                  maxWidth: 2048,
                  maxHeight: 2048,
                  imageQuality: 86)
            ].whereType<XFile>().toList()
          : await picker.pickMultiImage(
              maxWidth: 2048, maxHeight: 2048, imageQuality: 86);
      if (!mounted) return;
      final remaining = 5 - widget.controller.photos.length;
      if (files.length > remaining) {
        _error =
            'Solo se agregaron las primeras $remaining fotos. El máximo es cinco.';
      }
      for (final file in files.take(remaining)) {
        // add reserves a slot before yielding, and catches upload failures.
        widget.controller.add(file);
      }
    } catch (_) {
      _error =
          'No pudimos abrir las fotos. Revisa los permisos de cámara o galería e inténtalo de nuevo.';
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FOTOS DEL REPUESTO · ${widget.controller.photos.length}/5',
              style: AppTypography.overline),
          const SizedBox(height: 8),
          Text(
              'Opcional. Hasta cinco fotos JPEG, PNG o WebP de 5 MB. La primera será la portada.',
              style: AppTypography.bodySm),
          const SizedBox(height: 12),
          for (final (index, photo) in widget.controller.photos.indexed)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                              width: 72,
                              height: 72,
                              child: photo.file != null && !kIsWeb
                                  ? Image.file(File(photo.file!.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const AppLineIcon(AppIcons.catalog))
                                  : RequestPhotoImage(
                                      url: photo.file?.path ?? photo.url!,
                                      fit: BoxFit.cover))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                index == 0
                                    ? 'Foto 1 · Portada'
                                    : 'Foto ${index + 1}',
                                style: AppTypography.label),
                            if (photo.uploading)
                              LinearProgressIndicator(
                                  value: MediaQuery.disableAnimationsOf(context)
                                      ? 0.5
                                      : null,
                                  semanticsLabel: 'Cargando foto'),
                            Text(
                                photo.uploading
                                    ? 'Cargando…'
                                    : photo.error ?? 'Lista',
                                style: AppTypography.bodySm.copyWith(
                                    color: photo.error != null
                                        ? AppColors.errorInk
                                        : AppColors.textSecondary)),
                            if (photo.error != null)
                              FilledButton(
                                  onPressed: () =>
                                      widget.controller.retry(photo),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      textStyle: AppTypography.label,
                                      minimumSize: const Size(48, 48)),
                                  child: const Text('Reintentar foto')),
                          ])),
                      IconButton(
                          tooltip: 'Eliminar foto ${index + 1}',
                          constraints:
                              const BoxConstraints(minWidth: 48, minHeight: 48),
                          onPressed: () => widget.controller.remove(photo),
                          icon: const AppLineIcon(AppIcons.close,
                              color: AppColors.textPrimary)),
                    ])),
          if (widget.controller.canAdd)
            Center(
              child: FilledButton.icon(
                  onPressed: _picking ? null : _pick,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      textStyle: AppTypography.label,
                      minimumSize: const Size(48, 48),
                      shape: const StadiumBorder()),
                  icon: const AppLineIcon(AppIcons.catalog,
                      size: AppIconSize.action),
                  label: Text(_picking ? 'Abriendo fotos…' : 'Agregar fotos')),
            ),
          if (_error != null)
            Semantics(
                liveRegion: true,
                child: Text(_error!,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.errorInk))),
        ]),
      );
}
