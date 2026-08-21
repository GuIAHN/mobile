import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';
import 'profile_action_card.dart';

/// Tarjeta "Seguridad" del perfil: por ahora solo aloja el cambio de
/// contraseña, deliberadamente separado del editor de datos básicos
/// (nombre/teléfono) en [ProfileHeader] para no mezclar una acción
/// sensible de seguridad con la edición de datos de contacto.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileActionCard(
      actionKey: const Key('open-change-password'),
      semanticsLabel: 'Cambiar la contraseña de la cuenta',
      eyebrow: 'SEGURIDAD',
      title: 'Cambiar contraseña',
      subtitle: 'Actualiza la seguridad de tu cuenta.',
      onTap: () => _openChangePassword(context),
    );
  }

  void _openChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _ChangePasswordBottomSheet(),
    );
  }
}

class _ChangePasswordBottomSheet extends ConsumerStatefulWidget {
  const _ChangePasswordBottomSheet();

  @override
  ConsumerState<_ChangePasswordBottomSheet> createState() =>
      _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState
    extends ConsumerState<_ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _saveError;

  bool get _isFormValid {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    return current.isNotEmpty &&
        next.length >= 6 &&
        next != current &&
        confirmation == next;
  }

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onFormChanged);
    _newPasswordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!mounted) return;
    setState(() => _saveError = null);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_onFormChanged);
    _newPasswordController.removeListener(_onFormChanged);
    _confirmPasswordController.removeListener(_onFormChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Cambiar contraseña',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Ingresa tu contraseña actual y elige una nueva.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('Contraseña actual'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      key: const Key('current-password-field'),
                      controller: _currentPasswordController,
                      focusNode: _currentPasswordFocus,
                      obscure: _obscureCurrent,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _newPasswordFocus.requestFocus(),
                      onToggleObscure: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Ingresa tu contraseña actual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Nueva contraseña'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      key: const Key('new-password-field'),
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocus,
                      obscure: _obscureNew,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _confirmPasswordFocus.requestFocus(),
                      helperText: 'Usa al menos 6 caracteres.',
                      onToggleObscure: () =>
                          setState(() => _obscureNew = !_obscureNew),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Ingresa tu nueva contraseña';
                        }
                        if (val.length < 6) {
                          return 'Debe tener al menos 6 caracteres';
                        }
                        if (val == _currentPasswordController.text) {
                          return 'La nueva contraseña debe ser diferente a la actual';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildLabel('Confirmar nueva contraseña'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      key: const Key('confirm-password-field'),
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscure: _obscureConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) {
                        if (_isFormValid && !_isSaving) _save();
                      },
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Confirma tu nueva contraseña';
                        }
                        if (val != _newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_saveError != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          key: const Key('change-password-error'),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _saveError!,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.errorInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('save-change-password'),
                        onPressed: _isSaving || !_isFormValid ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.disabledBackground,
                          foregroundColor: AppColors.textOnPrimary,
                          disabledForegroundColor: AppColors.disabledText,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                  semanticsLabel: 'Actualizando contraseña',
                                ),
                              )
                            : Text(
                                'ACTUALIZAR CONTRASEÑA',
                                style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPasswordField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    required Iterable<String> autofillHints,
    required TextInputAction textInputAction,
    required ValueChanged<String> onFieldSubmitted,
    String? helperText,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      enabled: !_isSaving,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style:
          GoogleFonts.hankenGrotesk(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppColors.surface,
        helperText: helperText,
        helperStyle: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorInk),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.errorInk, width: 1.5),
        ),
        errorMaxLines: 2,
        errorStyle: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          color: AppColors.errorInk,
        ),
        suffixIcon: IconButton(
          onPressed: _isSaving ? null : onToggleObscure,
          tooltip: obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
            size: 20,
            semanticLabel:
                obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          ),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final result = await ref.read(changePasswordUseCaseProvider)(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _isSaving = false;
          _saveError = failure.message;
        });
      },
      (_) async {
        TextInput.finishAutofillContext();
        Navigator.pop(context);
        context.showSnackBar(
          'Contraseña actualizada. Inicia sesión nuevamente.',
          isSuccess: true,
        );
        await ref.read(passwordChangeSessionHandlerProvider)();
      },
    );
  }
}
