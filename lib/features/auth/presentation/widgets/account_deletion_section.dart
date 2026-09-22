import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class AccountDeletionSection extends ConsumerStatefulWidget {
  const AccountDeletionSection({super.key, required this.user});

  final User user;

  @override
  ConsumerState<AccountDeletionSection> createState() =>
      _AccountDeletionSectionState();
}

class _AccountDeletionSectionState
    extends ConsumerState<AccountDeletionSection> {
  bool _isRestoring = false;
  String? _restoreError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PRIVACIDAD', style: AppTypography.overline),
        const SizedBox(height: AppSpacing.md),
        if (widget.user.isPendingDeletion)
          _buildPendingCard(context)
        else
          _buildDeletionAction(context),
      ],
    );
  }

  Widget _buildDeletionAction(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Eliminar cuenta',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          key: const Key('request-account-deletion'),
          onTap: () => _openDeletionSheet(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(color: AppColors.error.withValues(alpha: .35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const AppLineIcon(
                  AppIcons.error,
                  color: AppColors.errorInk,
                  semanticLabel: 'Acción irreversible',
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eliminar cuenta',
                        style: AppTypography.title.copyWith(
                          color: AppColors.errorInk,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Programa la eliminación de tu cuenta y tus datos.',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const AppLineIcon(
                  AppIcons.next,
                  size: AppIconSize.action,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context) {
    final purgeAt = widget.user.deletionScheduledAt;
    final dateText = purgeAt == null
        ? 'La fecha exacta no está disponible.'
        : 'Tus datos se eliminarán el '
            '${MaterialLocalizations.of(context).formatMediumDate(purgeAt.toLocal())}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.warning.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLineIcon(
                AppIcons.warning,
                color: AppColors.warningInk,
                semanticLabel: 'Cuenta pendiente de eliminación',
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuenta programada para eliminación',
                      style: AppTypography.title.copyWith(
                        color: AppColors.warningInk,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$dateText Puedes restaurarla durante este período.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.warningInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_restoreError != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Error al restaurar la cuenta',
              liveRegion: true,
              excludeSemantics: true,
              child: Text(
                _restoreError!,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.errorInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('restore-account'),
              onPressed: _isRestoring ? null : _restoreAccount,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.buttonHeightMd),
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.disabledBackground,
                disabledForegroundColor: AppColors.disabledText,
                shape: const StadiumBorder(),
              ),
              child: _isRestoring
                  ? const SizedBox.square(
                      key: Key('account-restoration-progress'),
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                        semanticsLabel: 'Restaurando cuenta',
                      ),
                    )
                  : Text(
                      'RESTAURAR CUENTA',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textOnPrimary,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeletionSheet(BuildContext context) async {
    final deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeletionConfirmationSheet(user: widget.user),
    );
    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta programada para eliminación.')),
      );
    }
  }

  Future<void> _restoreAccount() async {
    setState(() {
      _isRestoring = true;
      _restoreError = null;
    });
    final failure = await ref.read(authProvider.notifier).restoreAccount();
    if (!mounted) return;
    setState(() {
      _isRestoring = false;
      _restoreError = failure?.message;
    });
  }
}

class _DeletionConfirmationSheet extends ConsumerStatefulWidget {
  const _DeletionConfirmationSheet({required this.user});

  final User user;

  @override
  ConsumerState<_DeletionConfirmationSheet> createState() =>
      _DeletionConfirmationSheetState();
}

class _DeletionConfirmationSheetState
    extends ConsumerState<_DeletionConfirmationSheet> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;

  bool get _canSubmit {
    final hasPassword = !widget.user.requiresDeletionPassword ||
        _passwordController.text.isNotEmpty;
    return !_isSubmitting &&
        hasPassword &&
        _confirmationController.text == 'DELETE';
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onInputChanged);
    _confirmationController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (!mounted) return;
    setState(() => _error = null);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onInputChanged);
    _confirmationController.removeListener(_onInputChanged);
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                AppSpacing.xl,
                AppSpacing.xl2,
                AppSpacing.xl2,
              ),
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
                  const SizedBox(height: AppSpacing.xl),
                  Text('Eliminar cuenta', style: AppTypography.h1),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tu cuenta quedará programada para eliminación. '
                    'Podrás restaurarla durante el período informado antes '
                    'de que tus datos se eliminen definitivamente.',
                    style: AppTypography.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  if (widget.user.requiresDeletionPassword) ...[
                    Text('CONTRASEÑA ACTUAL', style: AppTypography.overline),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const Key('delete-account-password-field'),
                      controller: _passwordController,
                      enabled: !_isSubmitting,
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.next,
                      style: AppTypography.body,
                      decoration: _inputDecoration(
                        hintText: 'Ingresa tu contraseña',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                          icon: AppLineIcon(
                            _obscurePassword
                                ? AppIcons.showPassword
                                : AppIcons.hidePassword,
                            size: AppIconSize.action,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  Text('ESCRIBE DELETE', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('delete-account-confirmation-field'),
                    controller: _confirmationController,
                    enabled: !_isSubmitting,
                    autocorrect: false,
                    enableSuggestions: false,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_canSubmit) _submit();
                    },
                    style: AppTypography.body,
                    decoration: _inputDecoration(
                      hintText: 'DELETE',
                      helperText: 'La confirmación debe coincidir exactamente.',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      label: 'Error al eliminar la cuenta',
                      liveRegion: true,
                      excludeSemantics: true,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          _error!,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.errorInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl2),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('confirm-account-deletion'),
                      onPressed: _canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppSpacing.buttonHeightMd),
                        elevation: 0,
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor: AppColors.disabledBackground,
                        disabledForegroundColor: AppColors.disabledText,
                        shape: const StadiumBorder(),
                      ),
                      child: _isSubmitting
                          ? const SizedBox.square(
                              key: Key('account-deletion-progress'),
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                                semanticsLabel: 'Programando eliminación',
                              ),
                            )
                          : Text(
                              'ELIMINAR CUENTA',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textOnPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppSpacing.buttonHeightMd),
                        side: const BorderSide(color: AppColors.border),
                        shape: const StadiumBorder(),
                      ),
                      child: Text('CANCELAR', style: AppTypography.label),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return InputDecoration(
      hintText: hintText,
      helperText: helperText,
      helperMaxLines: 2,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textPlaceholder),
      helperStyle: AppTypography.meta,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final failure =
        await ref.read(authProvider.notifier).requestAccountDeletion(
              password: widget.user.requiresDeletionPassword
                  ? _passwordController.text
                  : null,
            );
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _error = failure.message;
    });
  }
}
