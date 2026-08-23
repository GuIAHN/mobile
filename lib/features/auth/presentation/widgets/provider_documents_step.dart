import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';

class ProviderDocumentsStep extends StatelessWidget {
  const ProviderDocumentsStep({
    super.key,
    this.idPhoto,
    this.rifPhoto,
    this.mercantilRegistry,
    this.onIdPhotoChanged,
    this.onRifPhotoChanged,
    this.onMercantilRegistryChanged,
  });

  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  final XFile? idPhoto;
  final XFile? rifPhoto;
  final XFile? mercantilRegistry;
  final ValueChanged<XFile>? onIdPhotoChanged;
  final ValueChanged<XFile>? onRifPhotoChanged;
  final ValueChanged<XFile>? onMercantilRegistryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.tertiaryMuted),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.celesteInk,
                size: AppSpacing.iconMd,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Tus documentos se almacenan de forma privada y solo el equipo de verificación puede consultarlos.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (onIdPhotoChanged != null) ...[
          _DocumentCard(
            title: 'Documento de identidad',
            helper: 'Fotografía legible de tu cédula.',
            file: idPhoto,
            onChanged: onIdPhotoChanged!,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (onRifPhotoChanged != null) ...[
          _DocumentCard(
            title: 'RIF',
            helper: 'Fotografía completa y vigente del RIF.',
            file: rifPhoto,
            onChanged: onRifPhotoChanged!,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (onMercantilRegistryChanged != null)
          _DocumentCard(
            title: 'Registro mercantil',
            helper: 'Fotografía legible del registro del negocio.',
            file: mercantilRegistry,
            onChanged: onMercantilRegistryChanged!,
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Formatos de imagen admitidos. Máximo 5 MB por archivo.',
          style: AppTypography.meta.copyWith(color: AppColors.textMeta),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.helper,
    required this.file,
    required this.onChanged,
  });

  final String title;
  final String helper;
  final XFile? file;
  final ValueChanged<XFile> onChanged;

  Future<void> _pick(BuildContext context) async {
    final source = await ImageSourceSelectorSheet.show(
      context,
      title: 'Adjuntar $title',
    );
    if (source == null || !context.mounted) return;

    final selected = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
    );
    if (selected == null || !context.mounted) return;

    final length = await selected.length();
    if (!context.mounted) return;
    if (length > ProviderDocumentsStep.maxFileSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La imagen supera el máximo permitido de 5 MB.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = file != null;
    return Semantics(
      button: true,
      label: isSelected
          ? '$title seleccionado. Toca para reemplazarlo.'
          : '$title pendiente. Toca para adjuntarlo.',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.success : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.successLight
                        : AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_photo_alternate_outlined,
                    color:
                        isSelected ? AppColors.successInk : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isSelected ? file!.name : helper,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          color: isSelected
                              ? AppColors.successInk
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
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
