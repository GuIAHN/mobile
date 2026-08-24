import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/media_url.dart';

const workshopProfilePreviewAsset =
    'assets/images/providers/workshop_profile_preview.webp';

bool showsProviderImage({
  required String? photoUrl,
  required bool isWorkshop,
}) {
  final normalizedPhoto = photoUrl?.trim();
  return (normalizedPhoto != null && normalizedPhoto.isNotEmpty) ||
      (kDebugMode && isWorkshop);
}

/// Resuelve la foto de un proveedor de forma consistente en listas y detalle.
///
/// La foto recibida desde la API siempre tiene prioridad. La imagen local de
/// taller solo se muestra en builds de desarrollo para poder validar el diseño
/// antes de que el proveedor cargue una foto real.
class ProviderPhoto extends StatelessWidget {
  final String? photoUrl;
  final String providerName;
  final bool isWorkshop;
  final Widget fallback;
  final Widget? loadingFallback;
  final BoxFit fit;
  final Alignment alignment;
  final Key? networkKey;
  final Key? previewKey;

  const ProviderPhoto({
    super.key,
    required this.photoUrl,
    required this.providerName,
    required this.isWorkshop,
    required this.fallback,
    this.loadingFallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.networkKey,
    this.previewKey,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPhoto = resolveMediaUrl(photoUrl);
    if (normalizedPhoto != null && normalizedPhoto.isNotEmpty) {
      return Image.network(
        normalizedPhoto,
        key: networkKey,
        fit: fit,
        alignment: alignment,
        semanticLabel: 'Foto de $providerName',
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : (loadingFallback ?? fallback),
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    if (kDebugMode && isWorkshop) {
      return Image.asset(
        workshopProfilePreviewAsset,
        key: previewKey,
        fit: fit,
        alignment: alignment,
        semanticLabel: 'Vista previa de la foto de $providerName',
      );
    }

    return fallback;
  }
}
