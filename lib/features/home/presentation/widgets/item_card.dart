import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/service_type.dart';
import 'icon_mapper.dart';

class ItemCard extends StatefulWidget {
  final HomeItem item;

  const ItemCard({super.key, required this.item});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isFavorite = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // Obtener los colores correspondientes de acuerdo al tipo de servicio
    final Color accentColor;
    final Color softBgColor;

    switch (item.type) {
      case ServiceType.mechanic:
        accentColor = AppColors.primary;
        accentColor.withValues(alpha: 0.1);
        softBgColor = AppColors.primaryMuted;
        break;
      case ServiceType.spareParts:
        accentColor = AppColors.primary;
        softBgColor = AppColors.primaryMuted;
        break;
      case ServiceType.workshops:
        accentColor = AppColors.secondary;
        softBgColor = AppColors.grey200;
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Navegar o realizar acción al tocar la tarjeta
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
                item.type == ServiceType.workshops ? 14 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar con icono lider + indicador de estado
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: softBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      getIconData(item.iconName),
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  // Punto de estado (Abierto / Cerrado)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: item.isOpen
                            ? AppColors.success
                            : AppColors.textDisabled,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Información del Item
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Fila de tags (Rating, Distancia)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rating Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7), // Amarillo suave
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Color(0xFFF59E0B), // Amarillo
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.rating.toStringAsFixed(1),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFB5790F),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${item.reviews})',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC29A4D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Distancia Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.border, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.near_me_outlined,
                                size: 11,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.distanceKm.toStringAsFixed(1)} km',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botón de Favorito
              GestureDetector(
                onTap: () => setState(() => _isFavorite = !_isFavorite),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        _isFavorite ? AppColors.primaryMuted : AppColors.grey50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isFavorite
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: _isFavorite
                        ? AppColors.primary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
