import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

enum _RecoveryStep { email, reset, success }

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  _RecoveryStep _step = _RecoveryStep.email;
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;
  String? _statusMessage;
  Timer? _resendTimer;
  int _resendSeconds = 0;

  String get _email => _emailController.text.trim().toLowerCase();

  bool get _isEmailValid => _emailError(_emailController.text) == null;

  bool get _isResetValid {
    final next = _newPasswordController.text;
    return RegExp(r'^\d{6}$').hasMatch(_codeController.text) &&
        next.length >= 6 &&
        _confirmPasswordController.text == next;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _emailController,
      _codeController,
      _newPasswordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (!mounted) return;
    setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _scrollController.dispose();
    for (final controller in [
      _emailController,
      _codeController,
      _newPasswordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_onFormChanged);
      controller.dispose();
    }
    _emailFocus.dispose();
    _codeFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  static String? _emailError(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo electrónico';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Escribe un correo válido, por ejemplo nombre@correo.com';
    }
    return null;
  }

  static String? _codeError(String? value) {
    if (!RegExp(r'^\d{6}$').hasMatch(value ?? '')) {
      return 'Ingresa el código de 6 dígitos';
    }
    return null;
  }

  static String? _passwordError(String? value) {
    if ((value ?? '').length < 6) {
      return 'Usa al menos 6 caracteres';
    }
    return null;
  }

  String? _confirmationError(String? value) {
    if ((value ?? '').isEmpty) return 'Confirma tu nueva contraseña';
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _goBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading) return;
    if (_step == _RecoveryStep.reset) {
      _resendTimer?.cancel();
      setState(() {
        _step = _RecoveryStep.email;
        _errorMessage = null;
        _statusMessage = null;
        _resendSeconds = 0;
      });
      _scrollToTop();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.login);
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  Future<void> _requestCode({bool resend = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!resend && !(_emailFormKey.currentState?.validate() ?? false)) {
      _emailFocus.requestFocus();
      return;
    }
    if (_isLoading || !_isEmailValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (resend) _statusMessage = null;
    });

    final result = await ref.read(forgotPasswordUseCaseProvider)(email: _email);
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
      },
      (message) async {
        setState(() {
          _isLoading = false;
          _step = _RecoveryStep.reset;
          _statusMessage = resend
              ? 'Enviamos un código nuevo. Usa el más reciente.'
              : message;
        });
        _startResendCountdown();
        _scrollToTop();
      },
    );
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _resetPassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    if (_isLoading || !_isResetValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    final result = await ref.read(resetPasswordUseCaseProvider)(
      email: _email,
      code: _codeController.text,
      newPassword: _newPasswordController.text,
    );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.message;
        });
        _codeFocus.requestFocus();
      },
      (_) async {
        _resendTimer?.cancel();
        TextInput.finishAutofillContext();
        setState(() {
          _isLoading = false;
          _step = _RecoveryStep.success;
          _errorMessage = null;
        });
        _scrollToTop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return PopScope(
      canPop: !_isLoading && _step == _RecoveryStep.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLoading) _goBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              key: const Key('password-recovery-scroll'),
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RecoveryBackButton(onPressed: _goBack),
                        const SizedBox(height: AppSpacing.xl2),
                        AnimatedSwitcher(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: switch (_step) {
                              _RecoveryStep.email => _buildEmailStep(),
                              _RecoveryStep.reset => _buildResetStep(),
                              _RecoveryStep.success => _buildSuccessStep(),
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return AutofillGroup(
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RecoveryHeader(
              icon: Icons.key_rounded,
              eyebrow: 'PASO 1 DE 2',
              title: 'Recupera tu acceso',
              description:
                  'Escribe el correo de tu cuenta. Si está registrado, te enviaremos un código de verificación.',
              activeStep: 1,
            ),
            const SizedBox(height: AppSpacing.xl3),
            _RecoveryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FeedbackMessage.error(_errorMessage),
                  const _FieldLabel('Correo electrónico'),
                  const SizedBox(height: AppSpacing.sm),
                  _RecoveryField(
                    key: const Key('recovery-email-field'),
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hint: 'nombre@correo.com',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: _emailError,
                    enabled: !_isLoading,
                    onSubmitted: (_) {
                      if (_isEmailValid) _requestCode();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  _RecoveryPrimaryButton(
                    key: const Key('request-reset-code'),
                    label: 'ENVIAR CÓDIGO',
                    loadingLabel: 'Enviando código',
                    isLoading: _isLoading,
                    enabled: _isEmailValid,
                    onPressed: _requestCode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SecurityNote(
              text:
                  'Por seguridad, mostraremos el mismo mensaje aunque el correo no esté registrado.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetStep() {
    return AutofillGroup(
      child: Form(
        key: _resetFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RecoveryHeader(
              icon: Icons.mark_email_read_outlined,
              eyebrow: 'PASO 2 DE 2',
              title: 'Revisa tu correo',
              description:
                  'Ingresa el código recibido y crea una contraseña nueva.',
              activeStep: 2,
            ),
            const SizedBox(height: AppSpacing.xl3),
            _RecoveryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmailSummary(
                    email: _email,
                    enabled: !_isLoading,
                    onEdit: _goBack,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FeedbackMessage.success(_statusMessage),
                  _FeedbackMessage.error(_errorMessage),
                  const _FieldLabel('Código de verificación'),
                  const SizedBox(height: AppSpacing.sm),
                  _RecoveryField(
                    key: const Key('reset-code-field'),
                    controller: _codeController,
                    focusNode: _codeFocus,
                    hint: '000000',
                    icon: Icons.password_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: const [],
                    maxLength: 6,
                    validator: _codeError,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _newPasswordFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('Nueva contraseña'),
                  const SizedBox(height: AppSpacing.sm),
                  _RecoveryField(
                    key: const Key('reset-new-password-field'),
                    controller: _newPasswordController,
                    focusNode: _newPasswordFocus,
                    hint: 'Mínimo 6 caracteres',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureNewPassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _passwordError,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                    suffix: _PasswordToggle(
                      obscured: _obscureNewPassword,
                      enabled: !_isLoading,
                      onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _FieldLabel('Confirmar contraseña'),
                  const SizedBox(height: AppSpacing.sm),
                  _RecoveryField(
                    key: const Key('reset-confirm-password-field'),
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    hint: 'Repite la contraseña nueva',
                    icon: Icons.lock_reset_rounded,
                    obscure: _obscureConfirmation,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: _confirmationError,
                    enabled: !_isLoading,
                    onSubmitted: (_) {
                      if (_isResetValid) _resetPassword();
                    },
                    suffix: _PasswordToggle(
                      obscured: _obscureConfirmation,
                      enabled: !_isLoading,
                      onPressed: () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  _RecoveryPrimaryButton(
                    key: const Key('confirm-password-reset'),
                    label: 'CREAR NUEVA CONTRASEÑA',
                    loadingLabel: 'Actualizando contraseña',
                    isLoading: _isLoading,
                    enabled: _isResetValid,
                    onPressed: _resetPassword,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    key: const Key('resend-reset-code'),
                    onPressed: _isLoading || _resendSeconds > 0
                        ? null
                        : () => _requestCode(resend: true),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                    ),
                    child: Text(
                      _resendSeconds > 0
                          ? 'Reenviar código en ${_resendSeconds}s'
                          : 'Reenviar código',
                      style: _font(
                        14,
                        FontWeight.w700,
                        _resendSeconds > 0
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SecurityNote(
              text:
                  'El código vence en 15 minutos y solo puede usarse una vez.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      key: const Key('password-reset-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl4),
        Semantics(
          liveRegion: true,
          label: 'Contraseña actualizada correctamente',
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 44,
              color: AppColors.successInk,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Text(
          'Contraseña actualizada',
          textAlign: TextAlign.center,
          style: _font(28, FontWeight.w800, AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Ya puedes ingresar a tu cuenta con la contraseña nueva.',
          textAlign: TextAlign.center,
          style: _font(
            15,
            FontWeight.w400,
            AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl4),
        _RecoveryPrimaryButton(
          key: const Key('return-to-login'),
          label: 'VOLVER A INICIAR SESIÓN',
          loadingLabel: '',
          isLoading: false,
          enabled: true,
          onPressed: () => context.go(RouteNames.login),
        ),
      ],
    );
  }
}

TextStyle _font(
  double size,
  FontWeight weight,
  Color color, {
  double? letterSpacing,
  double? height,
}) =>
    GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );

class _RecoveryBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RecoveryBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.border),
        ),
        child: IconButton(
          key: const Key('recovery-back'),
          onPressed: onPressed,
          tooltip: 'Volver',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _RecoveryHeader extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final int activeStep;

  const _RecoveryHeader({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.activeStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 30, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          eyebrow,
          style: _font(
            11,
            FontWeight.w700,
            AppColors.textSecondary,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          textAlign: TextAlign.center,
          style: _font(28, FontWeight.w800, AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: _font(
            15,
            FontWeight.w400,
            AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          label: 'Paso $activeStep de 2',
          child: Row(
            children: List.generate(2, (index) {
              final completed = index < activeStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: completed ? AppColors.primary : AppColors.grey300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final Widget child;

  const _RecoveryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: _font(
        12,
        FontWeight.w700,
        AppColors.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _RecoveryField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? suffix;
  final String? Function(String?) validator;
  final ValueChanged<String>? onSubmitted;

  const _RecoveryField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.validator,
    required this.enabled,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.suffix,
    this.onSubmitted,
  });

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: !obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      inputFormatters: maxLength == 6
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ]
          : inputFormatters,
      maxLength: maxLength,
      buildCounter: maxLength == null
          ? null
          : (_, {required currentLength, required isFocused, maxLength}) =>
              null,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      cursorColor: AppColors.primary,
      style: _font(16, FontWeight.w600, AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _font(16, FontWeight.w400, AppColors.textPlaceholder),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: Icon(icon, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return AppColors.errorInk;
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: _border(AppColors.border, 1),
        enabledBorder: _border(AppColors.border, 1),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.errorInk, 1),
        focusedErrorBorder: _border(AppColors.errorInk, 1.5),
        errorMaxLines: 2,
        errorStyle: _font(
          12,
          FontWeight.w500,
          AppColors.errorInk,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  final bool obscured;
  final bool enabled;
  final VoidCallback onPressed;

  const _PasswordToggle({
    required this.obscured,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = obscured ? 'Mostrar contraseña' : 'Ocultar contraseña';
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.textSecondary,
        semanticLabel: label,
      ),
    );
  }
}

class _RecoveryPrimaryButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;

  const _RecoveryPrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.isLoading,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: enabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: AnimatedSwitcher(
          duration: MediaQuery.of(context).disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 200),
          child: isLoading
              ? Semantics(
                  label: loadingLabel,
                  child: const SizedBox(
                    key: ValueKey('recovery-loader'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('recovery-label'),
                  textAlign: TextAlign.center,
                  style: _font(
                    14,
                    FontWeight.w700,
                    enabled ? AppColors.textOnPrimary : AppColors.disabledText,
                    letterSpacing: 1.4,
                  ),
                ),
        ),
      ),
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  final String? message;
  final bool isError;

  const _FeedbackMessage.error(this.message) : isError = true;
  const _FeedbackMessage.success(this.message) : isError = false;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final foreground = isError ? AppColors.errorInk : AppColors.successInk;
    final background = isError ? AppColors.errorLight : AppColors.successLight;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message!,
                style: _font(13, FontWeight.w600, foreground, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailSummary extends StatelessWidget {
  final String email;
  final bool enabled;
  final VoidCallback onEdit;

  const _EmailSummary({
    required this.email,
    required this.enabled,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: _font(14, FontWeight.w600, AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: enabled ? onEdit : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 48),
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  final String text;

  const _SecurityNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 20,
          color: AppColors.celesteInk,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: _font(
              13,
              FontWeight.w500,
              AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
