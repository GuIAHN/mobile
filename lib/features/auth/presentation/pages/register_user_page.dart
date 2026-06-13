import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

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
    final p = _passwordController.text;
    return p.length >= 8 &&
        p.contains(RegExp(r'[0-9]')) &&
        p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  }

  void _validarFormulario() {
    final nombreValido = _nameController.text.trim().isNotEmpty;
    final correoValido = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$')
        .hasMatch(_emailController.text.trim());
    final passValido = _passwordValida;
    final confirmValido = _passwordController.text == _confirmPasswordController.text;

    final valido = nombreValido && correoValido && passValido && confirmValido;
    if (valido != _formularioValido) {
      setState(() => _formularioValido = valido);
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
    
    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          role: 'user', // Rol de usuario convencional aprobado
          phone: _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        ref.read(authProvider.notifier).logout().then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Registro completado. Por favor inicia sesión.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
            context.go(RouteNames.login);
          }
        });
      }
      if (next.hasError && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== Back =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                      onPressed: () => context.go(RouteNames.register),
                      tooltip: 'Volver a elegir perfil',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== Título =====
                  Text(
                    'Registro de Usuario',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu cuenta para gestionar tus vehículos, mecánicos y más.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ===== Card del formulario =====
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1.0 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'NOMBRE COMPLETO',
                              controller: _nameController,
                              hint: 'Tu nombre y apellido',
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                if (v.trim().split(' ').length < 2) {
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
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'El correo es obligatorio';
                                }
                                if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$')
                                    .hasMatch(v.trim())) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                            ),
                            AppTextField(
                              label: 'TELÉFONO (OPCIONAL)',
                              controller: _phoneController,
                              hint: '0414 000 0000',
                              prefixIcon: Icons.smartphone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v != null && v.isNotEmpty && v.length < 8) {
                                  return 'Número de teléfono inválido';
                                }
                                return null;
                              },
                            ),
                            AppTextField(
                              label: 'CONTRASEÑA',
                              controller: _passwordController,
                              hint: '••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.length < 8) {
                                  return 'Mínimo 8 caracteres';
                                }
                                if (!v.contains(RegExp(r'[0-9]')) ||
                                    !v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
                                  return 'Debe contener número y símbolo especial';
                                }
                                return null;
                              },
                            ),
                            AppTextField(
                              label: 'CONFIRMAR CONTRASEÑA',
                              controller: _confirmPasswordController,
                              hint: '••••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: (v) => (v != _passwordController.text)
                                  ? 'Las contraseñas no coinciden'
                                  : null,
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
                            const SizedBox(height: 24),

                            // ===== Botón Registrarse =====
                            _RegisterButton(
                              isLoading: state.isLoading,
                              isValid: _formularioValido,
                              onPressed: (_formularioValido && !state.isLoading)
                                  ? _submit
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ===== Link a login =====
                  Row(
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
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final bool isValid;
  final VoidCallback? onPressed;

  const _RegisterButton({
    required this.isLoading,
    required this.isValid,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: (isValid && !isLoading)
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
          onPressed: onPressed,
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
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loader'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'REGISTRARSE',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.person_add, size: 20),
                    ],
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
