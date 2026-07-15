import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(String provider) async {
    final email = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final controller = TextEditingController(text: 'cega2005@gmail.com');
        return AlertDialog(
          title: Text('Simulador Login Social ($provider)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Ingresa un correo para simular el inicio de sesión social:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (email == null || email.isEmpty) return;

    final mockToken = 'mock-token:$email:Usuario Social';

    final result = await ref.read(authProvider.notifier).socialLogin(
          idToken: mockToken,
          provider: provider,
        );

    result.fold(
      (failure) {
        if (failure is SocialNotRegisteredFailure) {
          ref.read(socialRegistrationProvider.notifier).setData(
                idToken: mockToken,
                provider: provider,
                email: email,
                name: 'Usuario Social',
              );
          context.go(RouteNames.register);
        }
      },
      (user) {
        // Success handles automatically by listener redirect
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) context.go(RouteNames.home);
    });

    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.loginBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl2,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _EntranceFade(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHeader(),
                    const SizedBox(height: AppSpacing.xl3),
                    _LoginCard(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: state.isLoading,
                      errorMessage: state.errorMessage,
                      onClearError: () =>
                          ref.read(authProvider.notifier).clearError(),
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: _submit,
                      onGoogleLogin: () => _handleSocialLogin('GOOGLE'),
                      onAppleLogin: () => _handleSocialLogin('APPLE'),
                    ),
                    const SizedBox(height: AppSpacing.xl3),
                    _RegisterFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 3,
        color: AppColors.loginPrimary,
      ),
    );
  }
}

// ── Entrance Animation ───────────────────────────────────────────────────────
// Fade + slide de entrada (350ms ease), según sección 4 del design system.

class _EntranceFade extends StatefulWidget {
  final Widget child;
  const _EntranceFade({required this.child});

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ── Brand Header ──────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'guIAutomotriz HN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.loginOnSurface,
                letterSpacing: -0.3,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Inicia sesión para continuar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.loginOnSurfaceVar,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ── Login Card ────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onClearError;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleLogin;
  final VoidCallback onAppleLogin;

  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onClearError,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onGoogleLogin,
    required this.onAppleLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.loginSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.loginOutlineVar,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApiErrorMessage(
              message: errorMessage,
              onClose: onClearError,
            ),
            // Email
            _FieldLabel('CORREO ELECTRÓNICO'),
            const SizedBox(height: AppSpacing.xs),
            _LoginTextField(
              controller: emailController,
              hintText: 'nombre@taller.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresa tu correo';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                  return 'Correo inválido';
                }
                return null;
              },
              onChanged: (_) {
                if (errorMessage != null) onClearError();
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Contraseña
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FieldLabel('CONTRASEÑA'),
                GestureDetector(
                  onTap: () => context.push(RouteNames.forgotPassword),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.loginPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            _LoginTextField(
              controller: passwordController,
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              suffixIcon: IconButton(
                tooltip: obscurePassword
                    ? 'Mostrar contraseña'
                    : 'Ocultar contraseña',
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.loginOnSurfaceVar,
                ),
                onPressed: onToggleObscure,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
              onChanged: (_) {
                if (errorMessage != null) onClearError();
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Botón principal
            _LoginButton(isLoading: isLoading, onPressed: onSubmit),

            const SizedBox(height: AppSpacing.xl3),
            _DividerWithLabel('O continuar con'),
            const SizedBox(height: AppSpacing.xl3),

            // Botones sociales
            Row(
              children: [
                Expanded(
                  child: _SocialButton.google(
                    onPressed: onGoogleLogin,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SocialButton.apple(
                    onPressed: onAppleLogin,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.loginOnSurfaceVar,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Text Field ────────────────────────────────────────────────────────────────

class _LoginTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const _LoginTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
    this.onChanged,
  });

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textAlignVertical: TextAlignVertical.center,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        validator: widget.validator,
        autovalidateMode: AutovalidateMode.disabled,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.loginOnSurface,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: AppColors.loginOnSurfaceVar,
            fontSize: 16,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Icon(
              widget.prefixIcon,
              size: 20,
              color: AppColors.loginOnSurfaceVar,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: widget.controller.text.isEmpty
              ? AppColors.loginSurfaceHigh
                  .withValues(alpha: _focused ? 0.9 : 0.6)
              : AppColors.loginSurface.withValues(alpha: 0.9),
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: AppColors.loginOutlineVar,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: AppColors.loginOutlineVar,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: AppColors.loginPrimary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: AppColors.loginError.withValues(alpha: 0.8),
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: AppColors.loginError,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 15,
          ),
          errorStyle: const TextStyle(
            color: AppColors.loginErrorText,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

// ── Login Button ──────────────────────────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: AppSpacing.buttonHeightLg,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: isLoading
            ? null
            : [
                BoxShadow(
                  color: AppColors.loginPrimary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.loginPrimary,
          disabledBackgroundColor: const Color(0xFFD9DCE1),
          disabledForegroundColor: const Color(0xFF9AA0A8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loader'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  key: ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Icon(Icons.login_rounded, size: 18, color: Colors.white),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Divider con etiqueta ──────────────────────────────────────────────────────

class _DividerWithLabel extends StatelessWidget {
  final String label;
  const _DividerWithLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.loginOutlineVar, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.loginOnSurfaceVar,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.loginOutlineVar, thickness: 1),
        ),
      ],
    );
  }
}

// ── Social Button ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  factory _SocialButton.google({required VoidCallback onPressed}) =>
      _SocialButton(
        icon: const _GoogleIcon(),
        label: 'Google',
        onPressed: onPressed,
      );

  factory _SocialButton.apple({required VoidCallback onPressed}) =>
      _SocialButton(
        icon: const Icon(Icons.apple_rounded,
            size: 20, color: AppColors.loginOnSurface),
        label: 'Apple',
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.loginSurfaceHigh.withValues(alpha: 0.6),
          side: const BorderSide(color: AppColors.loginOutlineVar),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.loginOnSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.loginOnSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google Icon (sin assets externos) ────────────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    const segments = [
      [0xFFEA4335, -1.05],
      [0xFF4285F4, 0.52],
      [0xFFFBBC05, 2.09],
      [0xFF34A853, 3.66],
    ];
    for (final s in segments) {
      paint.color = Color(s[0] as int);
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), s[1] as double,
          1.57, true, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.65, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - r * 0.14, r * 0.95, r * 0.28),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Register Footer ───────────────────────────────────────────────────────────

class _RegisterFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿No tienes una cuenta? ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.loginOnSurfaceVar,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(RouteNames.register),
          child: const Text(
            'Regístrate gratis',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.loginPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
