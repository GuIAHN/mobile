import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';

class RegisterUserPage extends ConsumerStatefulWidget {
  const RegisterUserPage({super.key});

  @override
  ConsumerState<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends ConsumerState<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _formularioValido = false;

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
      _passwordController,
      _confirmPasswordController
    ]) {
      controller.addListener(_validarFormulario);
    }
  }

  bool get _passwordValida {
    return Validators.password(_passwordController.text) == null;
  }

  void _validarFormulario() {
    final socialData = ref.read(socialRegistrationProvider);
    final isSocial = socialData != null;

    final nombreValido = Validators.required(_nameController.text, fieldName: 'Nombre') == null &&
        _nameController.text.trim().split(' ').length >= 2;
    final correoValido = Validators.email(_emailController.text) == null;
    final passValido = isSocial || _passwordValida;
    final confirmValido = isSocial || Validators.confirmPassword(_confirmPasswordController.text, _passwordController.text) == null;

    final valido = nombreValido && correoValido && passValido && confirmValido;
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    String? sanitizedPhone;
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isNotEmpty) {
      final clean = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      sanitizedPhone = clean.startsWith('0') ? clean.substring(1) : clean;
    }

    final socialData = ref.read(socialRegistrationProvider);

    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: socialData == null ? _passwordController.text : null,
          name: _nameController.text.trim(),
          role: 'CONSUMER',
          phone: sanitizedPhone,
          idToken: socialData?.idToken,
          provider: socialData?.provider,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        if (mounted) {
          context.go(RouteNames.registerVehicles);
        }
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                              onClose: () => ref.read(authProvider.notifier).clearError(),
                            ),
                            AppTextField(
                              label: 'NOMBRE COMPLETO',
                              controller: _nameController,
                              hint: 'Tu nombre y apellido',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              enabled: !isSocial,
                              validator: (v) {
                                final err = Validators.required(v, fieldName: 'El nombre');
                                if (err != null) return err;
                                if (v!.trim().split(' ').length < 2) {
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
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !isSocial,
                              validator: Validators.email,
                            ),
                            AppTextField(
                              label: 'TELÉFONO (OPCIONAL)',
                              controller: _phoneController,
                              hint: '414 123 4567',
                              helperText: 'Ingresa el número de teléfono móvil',
                              prefixIcon: Icons.smartphone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: isSocial ? TextInputAction.done : TextInputAction.next,
                              onFieldSubmitted: isSocial
                                  ? (_) {
                                      if (_formularioValido && !state.isLoading) {
                                        _submit();
                                      }
                                    }
                                  : null,
                              validator: (v) {
                                if (v != null && v.isNotEmpty) {
                                  return Validators.phone(v);
                                }
                                return null;
                              },
                            ),
                            if (!isSocial) ...[
                              AppTextField(
                                label: 'CONTRASEÑA',
                                controller: _passwordController,
                                hint: '••••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validator: Validators.password,
                              ),
                              AppTextField(
                                label: 'CONFIRMAR CONTRASEÑA',
                                controller: _confirmPasswordController,
                                hint: '••••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                                onFieldSubmitted: (_) {
                                  if (_formularioValido && !state.isLoading) {
                                    _submit();
                                  }
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mín. 8 caracteres con al menos un número y un símbolo especial.',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11.5,
                                  color: _passwordController.text.isEmpty
                                      ? AppColors.textSecondary
                                      : (_passwordValida ? AppColors.success : AppColors.primary),
                                ),
                              ),
                            ],
                            const Spacer(),
                            const SizedBox(height: 32),
                            _loginLink(),
                            const SizedBox(height: 16),
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
        GestureDetector(
          onTap: () => context.go(RouteNames.register),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Registro de Usuario',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.help_outline,
          color: AppColors.textSecondary,
          size: 20,
          ),
      ],
    );
  }

  Widget _indicadorPasos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PASO 1 DE 2',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: List.generate(2, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 5,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: i < 1 ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _tituloPaso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crea tu Cuenta',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Paso 1 de 2: Registra tus datos básicos.',
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
      onTap: enabled ? _submit : null,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: enabled ? _submit : null,
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
                          'REGISTRARSE',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.person_add_outlined, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
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
