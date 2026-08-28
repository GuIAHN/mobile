import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/non_delivery_reason.dart';

class NonDeliveryResult {
  const NonDeliveryResult({required this.reason, this.note});

  final NonDeliveryReason reason;
  final String? note;

  String get reasonCode => reason.apiValue;
}

class NonDeliveryDialog extends StatefulWidget {
  const NonDeliveryDialog({super.key});

  static Future<NonDeliveryResult?> show(BuildContext context) {
    return showModalBottomSheet<NonDeliveryResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NonDeliveryDialog(),
    );
  }

  @override
  State<NonDeliveryDialog> createState() => _NonDeliveryDialogState();
}

class _NonDeliveryDialogState extends State<NonDeliveryDialog> {
  final _otherController = TextEditingController();
  NonDeliveryReason? _selected;
  String? _error;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == null) {
      setState(() => _error = 'Selecciona un motivo.');
      return;
    }
    if (_selected == NonDeliveryReason.other &&
        _otherController.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el motivo para continuar.');
      return;
    }
    Navigator.of(context).pop(NonDeliveryResult(
      reason: _selected!,
      note: _selected == NonDeliveryReason.other
          ? _otherController.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
              Text(
                'No entregaré este pedido',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'La compra se cancelará y el cliente verá el motivo. Esta acción no se puede deshacer.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<NonDeliveryReason>(
                groupValue: _selected,
                onChanged: (value) => setState(() {
                  _selected = value;
                  _error = null;
                }),
                child: Column(
                  children: NonDeliveryReason.values
                      .map((reason) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<NonDeliveryReason>(
                              value: reason,
                              title: Text(reason.label),
                              activeColor: AppColors.errorInk,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _selected == reason
                                      ? AppColors.errorInk
                                      : AppColors.border,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              if (_selected == NonDeliveryReason.other) ...[
                const SizedBox(height: 4),
                TextField(
                  key: const Key('non-delivery-other-reason'),
                  controller: _otherController,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 280,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Cuéntanos qué ocurrió',
                    hintText: 'Escribe el motivo',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  key: const Key('non-delivery-error'),
                  style: GoogleFonts.hankenGrotesk(
                    color: AppColors.errorInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flex(
                direction: textScale > 1.3 ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: textScale > 1.3 ? 0 : 1,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver'),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: textScale > 1.3 ? 0 : 12,
                    height: textScale > 1.3 ? 12 : 0,
                  ),
                  Expanded(
                    flex: textScale > 1.3 ? 0 : 1,
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        key: const Key('confirm-non-delivery'),
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Cancelar pedido'),
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
