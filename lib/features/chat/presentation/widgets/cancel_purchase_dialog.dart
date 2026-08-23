import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class CancelPurchaseResult {
  final String? reason;

  const CancelPurchaseResult({this.reason});
}

class CancelPurchaseDialog extends StatefulWidget {
  const CancelPurchaseDialog({super.key});

  static Future<CancelPurchaseResult?> show(BuildContext context) {
    return showModalBottomSheet<CancelPurchaseResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CancelPurchaseDialog(),
    );
  }

  @override
  State<CancelPurchaseDialog> createState() => _CancelPurchaseDialogState();
}

class _CancelPurchaseDialogState extends State<CancelPurchaseDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_rounded,
                      color: AppColors.errorInk,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancelar compra',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'La compra quedará cancelada y la tienda ya no podrá marcarla como entregada.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _reasonController,
                maxLength: 280,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ej. Ya no necesito el repuesto',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final value = _reasonController.text.trim();
                          Navigator.of(context).pop(
                            CancelPurchaseResult(
                              reason: value.isEmpty ? null : value,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sí, cancelar'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
