import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/provider_detail_widgets.dart';
import '../../domain/entities/chat_conversation.dart';

/// Confirmación de compra y punto de acceso a los datos reales de la tienda.
///
/// La compra desbloquea la identidad y los medios de contacto. La hoja lo
/// explica primero y mantiene una sola acción principal para no competir con
/// las alternativas de llamada, mapa y copiado.
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
    final phone = details.storePhone?.trim() ?? '';
    final hasPhone = phone.isNotEmpty;
    final address = details.storeAddress?.trim();
    final hasLocation = (address != null && address.isNotEmpty) ||
        (details.storeLat != null && details.storeLng != null);
    final storeName = details.participantName;
    final itemTitle = details.spareBrand?.trim().isNotEmpty == true
        ? details.spareBrand!.trim()
        : (details.subcategoryName ?? 'Repuesto');
    final total = details.totalCost ?? details.price;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (isPostPurchase) ...[
                Semantics(
                  liveRegion: true,
                  label: 'Compra registrada correctamente',
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: AppLineIcon(
                        AppIcons.success,
                        size: AppIconSize.feature,
                        color: AppColors.successInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Compra registrada',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tu compra quedó guardada. Coordina ahora el pago y la entrega directamente con la tienda.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                Text(
                  'Datos de la tienda',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Elige cómo quieres contactar a $storeName.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl2),
              _PurchaseSummary(
                storeName: storeName,
                itemTitle: itemTitle,
                totalLabel: total == null ? null : details.formattedTotalCost,
              ),
              const SizedBox(height: AppSpacing.xl2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  key: const Key('store-contact-primary-action'),
                  onPressed: () {
                    Navigator.pop(context);
                    if (hasPhone) ContactActions.whatsapp(context, phone);
                  },
                  icon: const AppLineIcon(
                    AppIcons.message,
                    size: AppIconSize.action,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasPhone ? 'Escribir por WhatsApp' : 'Volver al chat',
                    style: AppTypography.label.copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              if (hasPhone) ...[
                const SizedBox(height: AppSpacing.md),
                _ContactActionTile(
                  icon: AppIcons.call,
                  title: 'Llamar a la tienda',
                  subtitle: phone,
                  onTap: () {
                    Navigator.pop(context);
                    ContactActions.call(context, phone);
                  },
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                const _ContactNotice(
                  message:
                      'La tienda no tiene un teléfono público. Puedes continuar la coordinación en este chat.',
                ),
              ],
              if (hasLocation) ...[
                const SizedBox(height: AppSpacing.md),
                _ContactActionTile(
                  icon: AppIcons.map,
                  title: 'Ver ubicación',
                  subtitle: address?.isNotEmpty == true
                      ? address!
                      : 'Abrir ubicación en Google Maps',
                  onTap: () {
                    Navigator.pop(context);
                    ContactActions.openGoogleMaps(
                      context,
                      lat: details.storeLat,
                      lng: details.storeLng,
                      address: address,
                    );
                  },
                ),
              ],
              if (hasPhone) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: phone));
                      HapticFeedback.mediumImpact();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Número copiado'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                    },
                    icon: const AppLineIcon(
                      AppIcons.receipt,
                      size: AppIconSize.inline,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      'Copiar número',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cerrar',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _PurchaseSummary extends StatelessWidget {
  final String storeName;
  final String itemTitle;
  final String? totalLabel;

  const _PurchaseSummary({
    required this.storeName,
    required this.itemTitle,
    required this.totalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppLineIcon(
              AppIcons.store,
              size: AppIconSize.leading,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(itemTitle, style: AppTypography.bodySm),
                if (totalLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Total: $totalLabel',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactNotice extends StatelessWidget {
  final String message;

  const _ContactNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: AppLineIcon(
              AppIcons.info,
              size: AppIconSize.inline,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTypography.bodySm)),
        ],
      ),
    );
  }
}

class _ContactActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AppLineIcon(
                icon,
                size: AppIconSize.leading,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const AppLineIcon(
                AppIcons.next,
                size: AppIconSize.inline,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
