import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/venezuelan_phone_number.dart';
import '../../../../shared/widgets/app_phone_field.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';
import '../widgets/account_security_step.dart';
import '../widgets/registration_step_feedback.dart';
import '../widgets/terms_acceptance_step.dart';

class RegisterUserPage extends ConsumerStatefulWidget {
  const RegisterUserPage({super.key});

  @override
  ConsumerState<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends ConsumerState<RegisterUserPage> {
  static const _totalSteps = 3;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _paso = 1;
  final _scrollController = ScrollController();
  bool _formularioValido = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
      final socialData = ref.read(socialRegistrationProvider);
      if (socialData != null) {
        _nameController.text = socialData.name;
        _emailController.text = socialData.email;
        _validarFormulario();
      }
    });
    for (final controller in [
      _nameController,
      _emailController,
      _phoneController,
      _passwordController,
      _confirmPasswordController
    ]) {
      controller.addListener(_validarFormulario);
    }
  }

  bool get _passwordValida {
    return Validators.password(_passwordController.text) == null;
  }

  bool get _datosValidos {
    final nombreValido =
        Validators.required(_nameController.text, fieldName: 'Nombre') ==
                null &&
            _nameController.text.trim().split(RegExp(r'\s+')).length >= 2;
    final correoValido = Validators.email(_emailController.text) == null;
    final phone = _phoneController.text.trim();
    final telefonoValido = phone.isEmpty || Validators.phone(phone) == null;
    return nombreValido && correoValido && telefonoValido;
  }

  bool get _seguridadValida {
    final isSocial = ref.read(socialRegistrationProvider) != null;
    return isSocial ||
        (_passwordValida &&
            Validators.confirmPassword(_confirmPasswordController.text,
                    _passwordController.text) ==
                null);
  }

  void _validarFormulario() {
    final valido = switch (_paso) {
      1 => _datosValidos,
      2 => _seguridadValida,
      3 => _termsAccepted,
      _ => false,
    };
    if (valido != _formularioValido) {
      setState(() => _formularioValido = valido);
    }

    // Si hay un error mostrado y el usuario empieza a escribir, limpiarlo
    if (ref.read(authProvider).errorMessage != null) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _avanzar() {
    if (!_formularioValido) return;
    if (_paso < _totalSteps) {
      setState(() => _paso++);
      _validarFormulario();
      _scrollToTop();
      return;
    }
    _submit();
  }

  void _retroceder() {
    if (_paso > 1) {
      setState(() => _paso--);
      _validarFormulario();
      _scrollToTop();
    } else {
      context.go(RouteNames.register);
    }
  }

  Future<void> _submit() async {
    if (!_datosValidos || !_seguridadValida || !_termsAccepted) return;

    final sanitizedPhone = VenezuelanPhoneNumber.toApi(_phoneController.text);

    final socialData = ref.read(socialRegistrationProvider);

    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: socialData == null ? _passwordController.text : null,
          name: _nameController.text.trim(),
          role: 'CONSUMER',
          phone: sanitizedPhone,
          idToken: socialData?.idToken,
          provider: socialData?.provider,
          acceptedTerms: _termsAccepted,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        if (mounted) {
          context.go(RouteNames.registerVehicles);
        }
      } else if (previous?.isLoading == true && next.errorMessage != null) {
        final message = next.errorMessage!.toLowerCase();
        final securityError =
            message.contains('contrase') || message.contains('password');
        setState(() => _paso = securityError ? 2 : 1);
        _validarFormulario();
        _scrollToTop();
      }
    });

    final state = ref.watch(authProvider);
    final socialData = ref.watch(socialRegistrationProvider);
    final isSocial = socialData != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: LayoutBuilder(
              builder: (context, viewportConstraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _appBar(),
                            const SizedBox(height: 16),
                            _indicadorPasos(),
                            const SizedBox(height: 24),
                            _tituloPaso(),
                            const SizedBox(height: 24),
                            ApiErrorMessage(
                              message: state.errorMessage,
                              onClose: () =>
                                  ref.read(authProvider.notifier).clearError(),
                            ),
                            AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 300),
                              child: switch (_paso) {
                                1 => Column(
                                    key: const ValueKey('personal-data'),
                                    children: [
                                      AppTextField(
                                        label: 'NOMBRE COMPLETO',
                                        controller: _nameController,
                                        hint: 'Tu nombre y apellido',
                                        prefixIcon: Icons.person_outline,
                                        textInputAction: TextInputAction.next,
                                        enabled: !isSocial,
                                        validator: (v) {
                                          final err = Validators.required(v,
                                              fieldName: 'El nombre');
                                          if (err != null) return err;
                                          if (v!
                                                  .trim()
                                                  .split(RegExp(r'\s+'))
                                                  .length <
                                              2) {
                                            return 'Ingresa nombre y apellido';
                                          }
                                          return null;
                                        },
                                      ),
                                      AppTextField(
                                        label: 'CORREO ELECTRÓNICO',
                                        controller: _emailController,
                                        hint: 'ejemplo@correo.com',
                                        prefixIcon: Icons.mail_outline,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        enabled: !isSocial,
                                        validator: Validators.email,
                                      ),
                                      AppPhoneField(
                                        label: 'TELÉFONO (OPCIONAL)',
                                        controller: _phoneController,
                                        required: false,
                                        textInputAction: TextInputAction.done,
                                      ),
                                    ],
                                  ),
                                2 => AccountSecurityStep(
                                    key: const ValueKey('account-security'),
                                    passwordController: _passwordController,
                                    confirmPasswordController:
                                        _confirmPasswordController,
                                    isSocial: isSocial,
                                    socialProvider: socialData?.provider,
                                  ),
                                _ => TermsAcceptanceStep(
                                    key: const ValueKey('terms-acceptance'),
                                    audience: TermsAudience.consumer,
                                    isAccepted: _termsAccepted,
                                    onAcceptedChanged: (accepted) {
                                      setState(() {
                                        _termsAccepted = accepted;
                                        _formularioValido = accepted;
                                      });
                                    },
                                  ),
                              },
                            ),
                            const Spacer(),
                            const SizedBox(height: 32),
                            _loginLink(),
                            const SizedBox(height: 16),
                            RegistrationStepFeedback(
                              message: _validationFeedback,
                            ),
                            _footer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _retroceder,
          tooltip: _paso == 1 ? 'Volver a elegir perfil' : 'Paso anterior',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        Text(
          'Registro de Usuario',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _indicadorPasos() {
    return Row(
      children: [
        Text(
          'PASO $_paso DE $_totalSteps',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: List.generate(_totalSteps, (i) {
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: i < _paso ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _tituloPaso() {
    final (title, subtitle) = switch (_paso) {
      1 => ('Crea tu Cuenta', 'Paso 1 de 3: Registra tus datos básicos.'),
      2 => ('Protege tu Cuenta', 'Paso 2 de 3: Define cómo iniciarás sesión.'),
      3 => (
          'Términos y Condiciones',
          'Paso 3 de 3: Revisa y acepta el documento para registrarte.'
        ),
      _ => ('', ''),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes una cuenta? ',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(RouteNames.login),
          child: Text(
            'Inicia sesión',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    final state = ref.watch(authProvider);
    final enabled = _formularioValido && !state.isLoading;

    return _PressableScale(
      onTap: enabled ? _avanzar : null,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: enabled ? _avanzar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD9DCE1),
              disabledForegroundColor: const Color(0xFF9AA0A8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _paso < _totalSteps ? 'CONTINUAR' : 'CREAR CUENTA',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _paso < _totalSteps
                              ? Icons.chevron_right
                              : Icons.person_add_outlined,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String? get _validationFeedback {
    if (_formularioValido) return null;
    if (_paso == 1) {
      if (Validators.required(_nameController.text) != null ||
          _nameController.text.trim().split(RegExp(r'\s+')).length < 2) {
        return 'Ingresa tu nombre y apellido para continuar.';
      }
      if (Validators.email(_emailController.text) != null) {
        return 'Ingresa un correo electrónico válido.';
      }
      return 'Revisa el teléfono o déjalo vacío si prefieres agregarlo después.';
    }
    if (_paso == 2) {
      return Validators.password(_passwordController.text) ??
          Validators.confirmPassword(
            _confirmPasswordController.text,
            _passwordController.text,
          );
    }
    return 'Abre el documento y acepta los términos y condiciones para crear tu cuenta.';
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(0);
        return;
      }
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
