import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class CbkLocationDisabledAd extends StatelessWidget {
  const CbkLocationDisabledAd({super.key});

  static const assetPath = 'assets/images/cbk_brake_pads_ad.jpeg';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label:
          'Publicidad CBK: pastillas de freno premium semi-metálicas. Seguridad, rendimiento y calidad.',
      child: ClipRRect(
        key: const Key('cbk-location-disabled-ad'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AspectRatio(
          aspectRatio: 1080 / 431,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
