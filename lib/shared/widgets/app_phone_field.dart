import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/venezuelan_phone_number.dart';

/// Campo móvil venezolano con selector de prefijo y siete dígitos locales.
class AppPhoneField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool required;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final AutovalidateMode autovalidateMode;

  const AppPhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.required = true,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends State<AppPhoneField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  final _subscriberController = TextEditingController();
  final _focusNode = FocusNode();

  String _prefix = VenezuelanPhoneNumber.mobilePrefixes.first;
  bool _selectorActive = false;
  bool _updatingExternalController = false;

  @override
  void initState() {
    super.initState();
    _readExternalController(clearInvalid: true);
    _subscriberController.addListener(_handleSubscriberChanged);
    widget.controller.addListener(_handleExternalControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppPhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleExternalControllerChanged);
      widget.controller.addListener(_handleExternalControllerChanged);
      _readExternalController(clearInvalid: true);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleExternalControllerChanged);
    _subscriberController.removeListener(_handleSubscriberChanged);
    _subscriberController.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() => setState(() {});

  void _handleSubscriberChanged() {
    final value = _subscriberController.text.isEmpty
        ? ''
        : '$_prefix${_subscriberController.text}';
    _setExternalValue(value);
    _fieldKey.currentState?.didChange(value);
  }

  void _handleExternalControllerChanged() {
    if (_updatingExternalController) return;
    _readExternalController(clearInvalid: false);
    _fieldKey.currentState?.didChange(widget.controller.text);
  }

  void _readExternalController({required bool clearInvalid}) {
    final raw = widget.controller.text;
    final local = VenezuelanPhoneNumber.toLocal(raw);
    if (local == null) {
      if (_subscriberController.text.isNotEmpty) {
        _subscriberController.text = '';
      }
      if (clearInvalid && raw.trim().isNotEmpty) {
        _setExternalValue('');
      }
      return;
    }

    _prefix = local.substring(0, 4);
    final subscriber = local.substring(4);
    if (_subscriberController.text != subscriber) {
      _subscriberController.text = subscriber;
      _subscriberController.selection = TextSelection.collapsed(
        offset: subscriber.length,
      );
    }
  }

  void _setExternalValue(String value) {
    if (widget.controller.text == value) return;
    _updatingExternalController = true;
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _updatingExternalController = false;
  }

  String? _validate(String? value) {
    if (!widget.required && (value == null || value.trim().isEmpty)) {
      return null;
    }
    return Validators.phone(value);
  }

  void _openPrefixSelector() {
    if (widget.enabled) setState(() => _selectorActive = true);
  }

  void _cancelPrefixSelection() {
    setState(() => _selectorActive = false);
  }

  void _selectPrefix(String selected) {
    setState(() {
      _selectorActive = false;
      _prefix = selected;
    });
    if (_subscriberController.text.isNotEmpty) {
      _handleSubscriberChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usesStackedLayout = MediaQuery.textScalerOf(context).scale(16) > 22;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          FormField<String>(
            key: _fieldKey,
            initialValue: widget.controller.text,
            enabled: widget.enabled,
            autovalidateMode: widget.autovalidateMode,
            validator: _validate,
            builder: (field) {
              final isFocused = _focusNode.hasFocus || _selectorActive;
              final borderColor = field.hasError
                  ? AppColors.error
                  : isFocused
                      ? AppColors.primary
                      : AppColors.border;
              final borderWidth = isFocused || field.hasError ? 1.5 : 1.0;
              final fillColor = widget.enabled
                  ? AppColors.surface
                  : AppColors.disabledBackground;

              final selector = _PrefixSelector(
                prefix: _prefix,
                enabled: widget.enabled,
                onOpened: _openPrefixSelector,
                onCanceled: _cancelPrefixSelection,
                onSelected: _selectPrefix,
              );
              final input = MergeSemantics(
                child: Semantics(
                  label: '${widget.label}. Siete dígitos restantes.',
                  child: TextField(
                    key: const Key('phone-subscriber-input'),
                    controller: _subscriberController,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: widget.textInputAction,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    onSubmitted: (_) => widget.onFieldSubmitted?.call(
                      widget.controller.text,
                    ),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: _subscriberController.text.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.disabledText,
                    ),
                    decoration: InputDecoration(
                      hintText: '1234567',
                      hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPlaceholder,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: usesStackedLayout
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              selector,
                              const Divider(height: 1, color: AppColors.border),
                              input,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              selector,
                              Container(
                                width: 1,
                                height: 28,
                                color: AppColors.border,
                              ),
                              Expanded(child: input),
                            ],
                          ),
                  ),
                  const SizedBox(height: 6),
                  if (field.hasError)
                    Semantics(
                      container: true,
                      liveRegion: true,
                      label: field.errorText,
                      child: ExcludeSemantics(
                        child: Text(
                          field.errorText!,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.errorInk,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      'Selecciona el prefijo y escribe los 7 dígitos restantes.',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrefixSelector extends StatelessWidget {
  final String prefix;
  final bool enabled;
  final VoidCallback onOpened;
  final VoidCallback onCanceled;
  final ValueChanged<String> onSelected;

  const _PrefixSelector({
    required this.prefix,
    required this.enabled,
    required this.onOpened,
    required this.onCanceled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.textPrimary : AppColors.disabledText;

    return Semantics(
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      label: 'Prefijo telefónico $prefix. Toca para cambiarlo.',
      child: PopupMenuButton<String>(
        enabled: enabled,
        tooltip: 'Seleccionar prefijo telefónico',
        initialValue: prefix,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 4),
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        constraints: const BoxConstraints(minWidth: 128, maxWidth: 144),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        onOpened: onOpened,
        onCanceled: onCanceled,
        onSelected: onSelected,
        itemBuilder: (context) {
          return VenezuelanPhoneNumber.mobilePrefixes.map((option) {
            final selected = option == prefix;
            return PopupMenuItem<String>(
              key: Key('phone-prefix-option-$option'),
              value: option,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: ConstrainedBox(
          key: const Key('phone-prefix-selector'),
          constraints: const BoxConstraints(minHeight: 52, minWidth: 112),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.disabledText,
                ),
                const SizedBox(width: 8),
                Text(
                  prefix,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.disabledText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
