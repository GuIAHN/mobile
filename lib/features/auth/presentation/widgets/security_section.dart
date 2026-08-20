import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';

/// Tarjeta "Seguridad" del perfil: por ahora solo aloja el cambio de
/// contraseña, deliberadamente separado del editor de datos básicos
/// (nombre/teléfono) en [ProfileHeader] para no mezclar una acción
/// sensible de seguridad con la edición de datos de contacto.
class SecuritySection extends StatelessWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          key: const Key('open-change-password'),
          onTap: () => _openChangePassword(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.celesteMuted,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.celesteInk,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cambiar contraseña',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Actualiza la contraseña de tu cuenta.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  String? _saveError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cambiar contraseña',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ingresa tu contraseña actual y la nueva contraseña.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Contraseña actual'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  key: const Key('current-password-field'),
                  controller: _currentPasswordController,
                  obscure: _obscureCurrent,
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
                  obscure: _obscureNew,
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
                  obscure: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (val) {
                    if (val != _newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                if (_saveError != null) ...[
                  Text(
                    _saveError!,
                    key: const Key('change-password-error'),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.errorInk,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        key: const Key('save-change-password'),
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                                ),
                              )
                            : Text(
                                'Guardar',
                                style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPasswordField({
    required Key key,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      enabled: !_isSaving,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      style: GoogleFonts.hankenGrotesk(
          fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorStyle: GoogleFonts.hankenGrotesk(fontSize: 12),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: AppColors.textSecondary,
            size: 20,
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

    result.fold(
      (failure) => setState(() {
        _isSaving = false;
        _saveError = failure.message;
      }),
      (_) {
        Navigator.pop(context);
        context.showSnackBar(
          'Contraseña actualizada correctamente.',
          isSuccess: true,
        );
      },
    );
  }
}
