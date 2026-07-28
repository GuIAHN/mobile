import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/provider_detail_widgets.dart';
import '../../domain/entities/chat_conversation.dart';

class StoreContactSheet extends StatelessWidget {
  final ChatConversation details;
  final bool isPostPurchase;

  const StoreContactSheet({
    super.key,
    required this.details,
    this.isPostPurchase = true,
  });

  static Future<void> show(
    BuildContext context, {
    required ChatConversation details,
    bool isPostPurchase = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => StoreContactSheet(
        details: details,
        isPostPurchase: isPostPurchase,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = details.storePhone;
    final address = details.storeAddress;
    final lat = details.storeLat;
    final lng = details.storeLng;
    final storeName = details.participantName;

    final itemTitle = details.spareBrand != null && details.spareBrand!.isNotEmpty
        ? details.spareBrand!
        : (details.subcategoryName ?? 'Repuesto');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Badge de Estado / Celebración
            if (isPostPurchase) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '¡COMPRA REGISTRADA! 🎉',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.success,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Título principal
            Text(
              isPostPurchase
                  ? 'Contacta a la tienda para la entrega'
                  : 'Datos de contacto de $storeName',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Estás comprando: "$itemTitle"',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            // Acciones táctiles principales
            if (phone != null && phone.isNotEmpty) ...[
              _ContactActionTile(
                icon: Icons.chat_bubble_rounded,
                color: const Color(0xFF25D366),
                title: 'WhatsApp directo',
                subtitle: 'Escribir a $phone',
                onTap: () {
                  Navigator.pop(context);
                  ContactActions.whatsapp(context, phone);
                },
              ),
              const SizedBox(height: 10),
              _ContactActionTile(
                icon: Icons.phone_rounded,
                color: AppColors.success,
                title: 'Llamar por teléfono',
                subtitle: 'Llamar al $phone',
                onTap: () {
                  Navigator.pop(context);
                  ContactActions.call(context, phone);
                },
              ),
              const SizedBox(height: 10),
            ] else ...[
              _ContactActionTile(
                icon: Icons.chat_rounded,
                color: AppColors.primary,
                title: 'Chat de GuIA-HN',
                subtitle: 'Enviar mensaje a $storeName',
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El vendedor no tiene un teléfono público registrado. Escríbele directamente por este chat.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (address != null || (lat != null && lng != null)) ...[
              _ContactActionTile(
                icon: Icons.map_rounded,
                color: AppColors.primary,
                title: 'Ver en Google Maps',
                subtitle: address ?? 'Ver ubicación exacta en el mapa',
                onTap: () {
                  Navigator.pop(context);
                  ContactActions.openGoogleMaps(
                    context,
                    lat: lat,
                    lng: lng,
                    address: address,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],

            if (phone != null && phone.isNotEmpty)
              _ContactActionTile(
                icon: Icons.copy_rounded,
                color: AppColors.grey600,
                title: 'Copiar número de teléfono',
                subtitle: phone,
                onTap: () async {
                  Navigator.pop(context);
                  await Clipboard.setData(ClipboardData(text: phone));
                  HapticFeedback.mediumImpact();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teléfono copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // Botón Entendido / Cerrar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.grey50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
