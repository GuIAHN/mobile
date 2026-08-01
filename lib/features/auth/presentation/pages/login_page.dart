import 'dart:io' show Platform;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';

// ── Tokens de pantalla ───────────────────────────────────────────────────────
// Alias locales sobre AppColors para que el resto del archivo se lea como el
// sistema de diseño (DESIGN_SYSTEM.md §1) y no como una lista de hex sueltos.

const Color _bg = AppColors.background; //        #F5F6FA — fondo de pantalla
const Color _surface = AppColors.loginSurface; // #FFFFFF — campos y superficies
const Color _ink = AppColors.loginOnSurface; //   #1A1C1E — texto principal
const Color _muted = AppColors.loginOnSurfaceVar; // #6C757D — labels y placeholders
const Color _line = AppColors.grey300; //         #DEE2E6 — borde de campos
const Color _hairline = AppColors.loginOutlineVar; // #E9ECEF — divisores
const Color _brand = AppColors.loginPrimary; //   #F25C05 — acento y CTA

/// Hanken Grotesk es la fuente única del sistema de diseño (§2). El textTheme
/// global aún no la aplica, así que cada estilo de esta pantalla la pide.
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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  /// Hasta el primer envío no se valida en caliente: mostrar errores mientras
  /// el usuario todavía está escribiendo su correo es ruido, no ayuda.
  bool _submitted = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS ? '1062705330448-6nego3r9aaijmelviu38b7f5g09lb4te.apps.googleusercontent.com' : null,
    serverClientId: '1062705330448-1n5l9ahrjltarem41a5uiim4dc81hj63.apps.googleusercontent.com',
    scopes: ['email'],
  );

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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  static String? _emailError(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Escribe un correo válido, por ejemplo nombre@correo.com';
    }
    return null;
  }

  static String? _passwordError(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  void _clearApiError(String _) {
    if (ref.read(authProvider).errorMessage != null) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    String? email;
    String? name;
    String? idToken;

    if (provider == 'GOOGLE') {
      try {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return; // Usuario canceló el selector

        final googleAuth = await googleUser.authentication;
        idToken = googleAuth.idToken;
        email = googleUser.email;
        name = googleUser.displayName;

        if (idToken == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo obtener el token de Google.')),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
          );
        }
        return;
      }
    } else if (provider == 'APPLE') {
      try {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        if (appleCredential.identityToken == null) {
          return;
        }

        idToken = appleCredential.identityToken;
        email = appleCredential.email;
        name = appleCredential.givenName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim()
            : null;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al iniciar sesión con Apple: $e')),
          );
        }
        return;
      }
    }

    if (idToken == null) return;

    final result = await ref.read(authProvider.notifier).socialLogin(
          idToken: idToken,
          provider: provider,
        );

    result.fold(
      (failure) {
        if (failure is SocialNotRegisteredFailure) {
          ref.read(socialRegistrationProvider.notifier).setData(
                idToken: idToken!,
                provider: provider,
                email: email!,
                name: name ?? 'Usuario Social',
              );
          context.go(RouteNames.register);
        }
      },
      (user) {
        // El éxito lo maneja el listener de redirección.
      },
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_submitted) setState(() => _submitted = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.lightImpact();
      // Foco al primer campo inválido para que lector de pantalla y teclado
      // aterricen donde está el problema (WCAG focus-management).
      if (_emailError(_emailController.text) != null) {
        _emailFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }

    HapticFeedback.selectionClick();
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
    final autovalidate = _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
              vertical: AppSpacing.xl3,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _EntranceFade(child: _BrandHeader()),
                      const SizedBox(height: AppSpacing.xl4),
                      _EntranceFade(
                        delayMs: 70,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              liveRegion: true,
                              child: ApiErrorMessage(
                                message: state.errorMessage,
                                onClose: () => ref
                                    .read(authProvider.notifier)
                                    .clearError(),
                              ),
                            ),
                            const _FieldLabel('Correo electrónico'),
                            const SizedBox(height: AppSpacing.sm),
                            _LoginField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hint: 'nombre@correo.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              autovalidateMode: autovalidate,
                              validator: _emailError,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              onChanged: _clearApiError,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _FieldLabel('Contraseña'),
                                GestureDetector(
                                  onTap: () => context.push(RouteNames.forgotPassword),
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: _font(12, FontWeight.w700, _brand),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _LoginField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hint: 'Tu contraseña',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              autovalidateMode: autovalidate,
                              validator: _passwordError,
                              onSubmitted: (_) => _submit(),
                              onChanged: _clearApiError,
                              suffix: _ObscureToggle(
                                obscured: _obscurePassword,
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl2),
                            _PrimaryCta(
                              isLoading: state.isLoading,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl3),
                      _EntranceFade(
                        delayMs: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _LabeledDivider('O continuar con'),
                            const SizedBox(height: AppSpacing.xl),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton.google(
                                    onPressed: () => _handleSocialLogin('GOOGLE'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _SocialButton.apple(
                                    onPressed: () => _handleSocialLogin('APPLE'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl3),
                            const _RegisterFooter(),
                          ],
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
    );
  }
}

// ── Entrada escalonada ───────────────────────────────────────────────────────
// Fade + slide de 350ms (DESIGN_SYSTEM §4) con stagger de 70ms entre bloques.
// Con "reducir movimiento" activo se salta a estado final sin animar.

class _EntranceFade extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _EntranceFade({required this.child, this.delayMs = 0});

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.04),
    end: Offset.zero,
  ).animate(_fade);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      return;
    }
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

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

// ── Feedback de presión ──────────────────────────────────────────────────────
// Escala 0.97 al presionar (DESIGN_SYSTEM §4). Usa Listener en vez de
// GestureDetector para no competir por el gesto con el botón que envuelve.

class _PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const _PressScale({required this.child, this.enabled = true});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _release(PointerEvent _) {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final active = widget.enabled && _pressed && !reduceMotion;

    return Listener(
      onPointerDown: widget.enabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: AnimatedScale(
        scale: active ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Encabezado de marca ──────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Image.asset(
          'assets/images/logo.png',
          width: 320,
          fit: BoxFit.contain,
          semanticLabel: 'guIAutomotriz HN',
          errorBuilder: (_, __, ___) => Text(
            'guIAutomotriz HN',
            style: _font(24, FontWeight.w800, _ink, letterSpacing: -0.3),
          ),
        ),
      ],
    );
  }
}

// ── Label de campo ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: _font(12, FontWeight.w700, _muted, letterSpacing: 1.5),
    );
  }
}

// ── Campo de texto ───────────────────────────────────────────────────────────
// Superficie blanca sobre el fondo neutro, borde 1px y radio 14. El foco solo
// cambia color y grosor del borde: nada que altere el layout.

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final AutovalidateMode autovalidateMode;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.suffix,
    this.validator,
    this.onSubmitted,
    this.onChanged,
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
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      textAlignVertical: TextAlignVertical.center,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      cursorColor: _brand,
      style: _font(16, FontWeight.w400, _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _font(16, FontWeight.w400, _muted),
        filled: true,
        fillColor: _surface,
        prefixIcon: Icon(icon, size: 20),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return AppColors.loginError;
          if (states.contains(WidgetState.focused)) return _brand;
          return _muted;
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
        border: _border(_line, 1),
        enabledBorder: _border(_line, 1),
        focusedBorder: _border(_brand, 1.5),
        errorBorder: _border(AppColors.loginError, 1),
        focusedErrorBorder: _border(AppColors.loginError, 1.5),
        errorMaxLines: 2,
        errorStyle: _font(12, FontWeight.w500, AppColors.loginErrorText,
            height: 1.35),
      ),
    );
  }
}

// ── Toggle de visibilidad de contraseña ──────────────────────────────────────

class _ObscureToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const _ObscureToggle({required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = obscured ? 'Mostrar contraseña' : 'Ocultar contraseña';
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      splashRadius: 22,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: _muted,
        semanticLabel: label,
      ),
    );
  }
}

// ── CTA principal ────────────────────────────────────────────────────────────

class _PrimaryCta extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryCta({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      enabled: !isLoading,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: _brand.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD9DCE1),
            disabledForegroundColor: const Color(0xFF9AA0A8),
            elevation: 0,
            minimumSize: const Size.fromHeight(AppSpacing.buttonHeightLg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
              vertical: AppSpacing.md,
            ),
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
                      semanticsLabel: 'Iniciando sesión',
                    ),
                  )
                : Text(
                    'INICIAR SESIÓN',
                    key: const ValueKey('label'),
                    style: _font(15, FontWeight.w700, Colors.white,
                        letterSpacing: 2),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Divisor con etiqueta ─────────────────────────────────────────────────────

class _LabeledDivider extends StatelessWidget {
  final String label;
  const _LabeledDivider(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _hairline, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: _font(11, FontWeight.w600, _muted, letterSpacing: 1.5),
          ),
        ),
        const Expanded(child: Divider(color: _hairline, thickness: 1)),
      ],
    );
  }
}

// ── Botón social ─────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final String semanticLabel;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  factory _SocialButton.google({required VoidCallback onPressed}) =>
      _SocialButton(
        icon: const _GoogleMark(size: 20),
        label: 'Google',
        semanticLabel: 'Continuar con Google',
        onPressed: onPressed,
      );

  factory _SocialButton.apple({required VoidCallback onPressed}) =>
      _SocialButton(
        icon: const Icon(Icons.apple_rounded, size: 22, color: _ink),
        label: 'Apple',
        semanticLabel: 'Continuar con Apple',
        onPressed: onPressed,
      );

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _surface,
            side: const BorderSide(color: _line),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: _font(14.5, FontWeight.w600, _ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Logotipo de Google ───────────────────────────────────────────────────────
// Anillo de cuatro segmentos + barra, con los ángulos y proporciones tomados
// del SVG oficial (viewBox 48×48, centro 24,24, radio exterior 22, interior 13)
// para no deformar la marca.

class _GoogleMark extends StatelessWidget {
  final double size;
  const _GoogleMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  // Radianes: 0 = 3 en punto, sentido horario (eje Y hacia abajo).
  static const _segments = <List<Object>>[
    [0xFFEA4335, -2.67558, 1.83958], // rojo    -153.3° → -47.9°
    [0xFF4285F4, -0.83600, 1.68941], // azul     -47.9° →  48.9°
    [0xFF34A853, 0.85347, 1.82212], //  verde     48.9° → 153.3°
    [0xFFFBBC05, 2.67558, 0.93206], //  amarillo 153.3° → 206.7°
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Grosor del anillo: (22 - 13) / 22 del radio, centrado en 17.5 / 22.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.40909
      ..strokeCap = StrokeCap.butt;
    final ring = Rect.fromCircle(center: center, radius: r * 0.79545);

    for (final s in _segments) {
      paint.color = Color(s[0] as int);
      canvas.drawArc(ring, s[1] as double, s[2] as double, false, paint);
    }

    // Barra azul horizontal: del centro hacia la derecha, y de -4 a +4.51.
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - r * 0.18182,
        center.dx + r * 0.94182,
        center.dy + r * 0.20500,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Link de texto con área táctil de 44px ────────────────────────────────────

class _TextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final EdgeInsets padding;

  const _TextLink({
    required this.label,
    required this.onTap,
    this.fontSize = 13.5,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: padding,
          child: Text(
            label,
            style: _font(fontSize, FontWeight.w700, _brand),
          ),
        ),
      ),
    );
  }
}

// ── Pie de registro ──────────────────────────────────────────────────────────

class _RegisterFooter extends StatelessWidget {
  const _RegisterFooter();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(RouteNames.register),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: _font(14, FontWeight.w400, _muted),
            children: [
              const TextSpan(text: '¿No tienes una cuenta? '),
              TextSpan(
                text: 'Regístrate gratis',
                style: _font(14, FontWeight.w700, _brand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Simulador de login social (desarrollo) ───────────────────────────────────

class _SocialSimulatorDialog extends StatefulWidget {
  final String provider;
  const _SocialSimulatorDialog({required this.provider});

  @override
  State<_SocialSimulatorDialog> createState() => _SocialSimulatorDialogState();
}

class _SocialSimulatorDialogState extends State<_SocialSimulatorDialog> {
  final _controller = TextEditingController(text: 'cega2005@gmail.com');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Login social (${widget.provider})',
              style: _font(18, FontWeight.w800, _ink),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Simulador de desarrollo: indica el correo con el que quieres continuar.',
              style: _font(13.5, FontWeight.w400, _muted, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _FieldLabel('Correo electrónico'),
            const SizedBox(height: AppSpacing.sm),
            _LoginField(
              controller: _controller,
              hint: 'nombre@correo.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _line),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: _font(14.5, FontWeight.w600, _muted),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Continuar',
                      style: _font(14.5, FontWeight.w700, Colors.white),
                    ),
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
