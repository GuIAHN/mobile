import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'card_tokens.dart';

/// Un dato de metadata: texto con ícono opcional.
class MetaItem {
  final IconData? icon;
  final String text;

  /// Color propio (ej. celeste para señales de confianza). Si es null usa
  /// el color por defecto de [MetaLine].
  final Color? color;

  const MetaItem(this.text, {this.icon, this.color});
}

/// Línea de metadata separada por puntos medios: `★ 4.8 (124) · 1.2 km · Envío`.
///
/// Reemplaza las filas de chips rellenos que tenían las cards. Tres chips con
/// fondo y borde para "distancia / envío / rating" pesaban visualmente igual
/// que el precio y el título, aplanando la jerarquía. Como texto con
/// separadores la misma información se lee más rápido, ocupa una sola línea
/// y deja que el precio domine.
///
/// Usa [Wrap] para degradar a varias líneas en pantallas angostas o con
/// tamaño de fuente del sistema aumentado, en vez de desbordar.
class MetaLine extends StatelessWidget {
  final List<MetaItem> items;
  final Color color;
  final TextStyle? style;

  const MetaLine({
    super.key,
    required this.items,
    this.color = AppColors.textMeta,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.text.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final baseStyle = (style ?? CardTokens.meta);
    final children = <Widget>[];

    for (var i = 0; i < visible.length; i++) {
      final item = visible[i];
      final itemColor = item.color ?? color;

      if (i > 0) {
        children.add(Text('·', style: baseStyle.copyWith(color: AppColors.grey400)));
      }

      if (item.icon == null) {
        children.add(
          Text(
            item.text,
            style: baseStyle.copyWith(color: itemColor),
          ),
        );
      } else {
        children.add(
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(item.icon, size: 14, color: itemColor),
                  ),
                ),
                TextSpan(
                  text: item.text,
                  style: baseStyle.copyWith(color: itemColor),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
