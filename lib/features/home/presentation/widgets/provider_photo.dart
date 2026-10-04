import 'package:flutter/material.dart';

import '../../../../core/utils/media_url.dart';

bool showsProviderImage({
  required String? photoUrl,
}) {
  final normalizedPhoto = photoUrl?.trim();
  return normalizedPhoto != null && normalizedPhoto.isNotEmpty;
}

/// Resuelve la foto de un proveedor de forma consistente en listas y detalle.
///
/// Solo renderiza fotos reales recibidas desde la API. Si no existe una foto,
/// delega en [fallback] para no confundir contenido de demostración con datos
/// del proveedor.
class ProviderPhoto extends StatelessWidget {
  final String? photoUrl;
  final String providerName;
  final Widget fallback;
  final Widget? loadingFallback;
  final BoxFit fit;
  final Alignment alignment;
  final Key? networkKey;

  const ProviderPhoto({
    super.key,
    required this.photoUrl,
    required this.providerName,
    required this.fallback,
    this.loadingFallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.networkKey,
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

    return fallback;
  }
}
