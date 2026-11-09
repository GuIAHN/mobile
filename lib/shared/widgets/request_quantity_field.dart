import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_typography.dart';

class RequestQuantityField extends StatefulWidget {
  const RequestQuantityField({super.key, required this.controller});

  final TextEditingController controller;

  static int? value(String text) {
    if (!RegExp(r'^\d{1,3}$').hasMatch(text)) return null;
    final quantity = int.tryParse(text);
    return quantity != null && quantity >= 1 && quantity <= 999
        ? quantity
        : null;
  }

  @override
  State<RequestQuantityField> createState() => _RequestQuantityFieldState();
}

class _RequestQuantityFieldState extends State<RequestQuantityField> {
  final _focusNode = FocusNode();
  late String _lastText;
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_onQuantityChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant RequestQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onQuantityChanged);
      widget.controller.addListener(_onQuantityChanged);
      _lastText = widget.controller.text;
    }
  }

  void _onQuantityChanged() {
    if (_lastText == widget.controller.text) return;
    _lastText = widget.controller.text;
    _fieldKey.currentState?.didChange(_lastText);
    setState(() {});
  }

  void _onFocusChanged() => setState(() {});

  void _step(int delta) {
    final current = RequestQuantityField.value(widget.controller.text);
    final next = current == null ? 1 : (current + delta).clamp(1, 999);
    final text = '$next';
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQuantityChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quantity = RequestQuantityField.value(widget.controller.text);
    return FormField<String>(
      key: _fieldKey,
      initialValue: widget.controller.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (_) =>
          RequestQuantityField.value(widget.controller.text) == null
              ? 'Ingresa una cantidad entre 1 y 999.'
              : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CANTIDAD DE REPUESTOS', style: AppTypography.overline),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final numberStyle = AppTypography.h1
                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
            final measure = TextPainter(
              text: TextSpan(text: '999', style: numberStyle),
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: TextDirection.ltr,
            )..layout();
            final numberWidth = measure.width + 16;
            measure.dispose();
            final width = math.min(
                constraints.maxWidth, math.max(208.0, numberWidth + 122));
            final stacked = numberWidth > width - 122;
            final decrease = _QuantityButton(
              label: 'Disminuir cantidad',
              icon: AppIcons.decrease,
              onPressed:
                  quantity != null && quantity > 1 ? () => _step(-1) : null,
            );
            final increase = _QuantityButton(
              label: 'Aumentar cantidad',
              icon: AppIcons.increase,
              onPressed:
                  quantity == null || quantity < 999 ? () => _step(1) : null,
            );
            final number = Semantics(
              container: true,
              label: 'Cantidad de repuestos',
              child: TextField(
                key: const Key('request-quantity'),
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onTap: () {
                  widget.controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: widget.controller.text.length);
                },
                onTapOutside: (_) => _focusNode.unfocus(),
                style: numberStyle,
                decoration: const InputDecoration(
                  hintText: '1',
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  constraints: BoxConstraints(minHeight: 48),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            );
            return Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: width,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: field.hasError
                            ? AppColors.errorInk
                            : _focusNode.hasFocus
                                ? AppColors.borderFocus
                                : AppColors.border,
                        width: _focusNode.hasFocus || field.hasError ? 1.5 : 1,
                      ),
                    ),
                    // At the largest text sizes, give all three digits a full row.
                    child: stacked
                        ? Column(children: [
                            number,
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [decrease, increase],
                            ),
                          ])
                        : Row(children: [
                            decrease,
                            const SizedBox(width: 8),
                            Expanded(child: number),
                            const SizedBox(width: 8),
                            increase,
                          ]),
                  ),
                  Text(quantity == 1 ? 'unidad' : 'unidades',
                      style: AppTypography.bodySm),
                ],
              ),
            );
          }),
          if (field.hasError) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(field.errorText!,
                  style:
                      AppTypography.bodySm.copyWith(color: AppColors.errorInk)),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Todas las cotizaciones cubrirán esta cantidad. No podrás cambiarla después de publicar.',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          maximumSize: const Size.square(48),
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: AppLineIcon(icon, size: AppIconSize.action),
      );
}
