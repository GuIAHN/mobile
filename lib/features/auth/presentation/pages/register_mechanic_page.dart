import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/venezuelan_phone_number.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';
import '../widgets/account_security_step.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/registration_step_feedback.dart';
import '../widgets/mechanic_profile_step.dart';
import '../widgets/mechanic_technical_step.dart';
import '../widgets/terms_acceptance_step.dart';
import '../widgets/workshop_specialties_step.dart';

class RegisterMechanicPage extends ConsumerStatefulWidget {
  const RegisterMechanicPage({super.key});

  @override
  ConsumerState<RegisterMechanicPage> createState() =>
      _RegisterMechanicPageState();
}

class _RegisterMechanicPageState extends ConsumerState<RegisterMechanicPage> {
  static const _totalSteps = 5;
  static const _completedStep = 6;

  int _paso = 1;
  final _scrollController = ScrollController();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String _cedulaTipo = 'V';

  final Set<String> _seleccionadas = {};

  // ===== Paso 3: Perfil técnico =====
  double _aniosExperiencia = 5;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
      final socialData = ref.read(socialRegistrationProvider);
      if (socialData != null) {
        _nombreCtrl.text = socialData.name;
        _emailCtrl.text = socialData.email;
        setState(() {});
      }
    });
    for (final c in [
      _nombreCtrl,
      _telefonoCtrl,
      _emailCtrl,
      _cedulaCtrl,
      _passwordCtrl,
      _confirmPasswordCtrl,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _cedulaCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() {});
    if (ref.read(authProvider).errorMessage != null) {
      ref.read(authProvider.notifier).clearError();
    }
  }

  // ===== Validación por paso =====
  bool get _passwordValida {
    return Validators.password(_passwordCtrl.text) == null;
  }

  bool get _pasoValido {
    final socialData = ref.read(socialRegistrationProvider);
    final isSocial = socialData != null;

    switch (_paso) {
      case 1:
        return Validators.required(_nombreCtrl.text) == null &&
            Validators.phone(_telefonoCtrl.text) == null &&
            Validators.email(_emailCtrl.text) == null &&
            Validators.required(_cedulaCtrl.text) == null;
      case 2:
        return isSocial ||
            (_passwordValida &&
                Validators.confirmPassword(
                        _confirmPasswordCtrl.text, _passwordCtrl.text) ==
                    null);
      case 3:
        return _seleccionadas.isNotEmpty;
      case 4:
        return true; // bio es opcional, el slider siempre tiene valor
      case 5:
        return _termsAccepted;
      default:
        return false;
    }
  }

  void _avanzar() {
    if (!_pasoValido) return;
    if (_paso < _totalSteps) {
      setState(() => _paso++);
      _scrollToTop();
    } else if (_paso == _totalSteps) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isLoading || !_termsAccepted) return;

    final sanitizedPhone = VenezuelanPhoneNumber.toApi(_telefonoCtrl.text)!;

    final socialData = ref.read(socialRegistrationProvider);

    await ref.read(authProvider.notifier).registerMechanic(
          email: _emailCtrl.text.trim(),
          password: socialData == null ? _passwordCtrl.text : null,
          name: _nombreCtrl.text.trim(),
          phone: sanitizedPhone,
          latitude: 10.4806,
          longitude: -66.9036,
          description:
              'Mecánico con ${_aniosExperiencia.round()} años de experiencia.',
          isWorkshop: false,
          identification: '$_cedulaTipo${_cedulaCtrl.text.trim()}',
          specialtyIds: _seleccionadas.toList(),
          idToken: socialData?.idToken,
          provider: socialData?.provider,
        );
  }

  void _retroceder() {
    if (_paso > 1 && _paso < _completedStep) {
      setState(() => _paso--);
      _scrollToTop();
    } else if (_paso == 1) {
      context.go(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isProviderRegistrationSucceeded) {
        setState(() => _paso = _completedStep);
        _scrollToTop();
      } else if (previous?.isLoading == true && next.errorMessage != null) {
        setState(() => _paso = _stepForServerError(next.errorMessage!));
        _scrollToTop();
      }
    });

    final authState = ref.watch(authProvider);
    final socialData = ref.watch(socialRegistrationProvider);
    final isSocial = socialData != null;
    final specialtiesAsync = ref.watch(specialtiesProvider);
    final specialties = specialtiesAsync.valueOrNull ?? [];

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
                      minHeight: viewportConstraints.maxHeight -
                          32, // account for vertical padding
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _appBar(),
                          if (_paso < _completedStep) ...[
                            const SizedBox(height: 16),
                            _indicadorPasos(),
                            const SizedBox(height: 16),
                            _tituloPaso(),
                            const SizedBox(height: 16),
                            ApiErrorMessage(
                              message: authState.errorMessage,
                              onClose: () =>
                                  ref.read(authProvider.notifier).clearError(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.06, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Container(
                                key: ValueKey(_paso),
                                child: switch (_paso) {
                                  1 => MechanicProfileStep(
                                      nombreController: _nombreCtrl,
                                      telefonoController: _telefonoCtrl,
                                      emailController: _emailCtrl,
                                      cedulaController: _cedulaCtrl,
                                      cedulaTipo: _cedulaTipo,
                                      onCedulaTipoChanged: (val) {
                                        setState(() {
                                          _cedulaTipo = val;
                                        });
                                      },
                                      isSocial: isSocial,
                                    ),
                                  2 => AccountSecurityStep(
                                      passwordController: _passwordCtrl,
                                      confirmPasswordController:
                                          _confirmPasswordCtrl,
                                      isSocial: isSocial,
                                      socialProvider: socialData?.provider,
                                    ),
                                  3 => WorkshopSpecialtiesStep(
                                      selectedSpecialtyIds: _seleccionadas,
                                      onSpecialtyToggled: (id) {
                                        setState(() {
                                          if (_seleccionadas.contains(id)) {
                                            _seleccionadas.remove(id);
                                          } else {
                                            _seleccionadas.add(id);
                                          }
                                        });
                                      },
                                      specialties: specialties,
                                      isLoading: specialtiesAsync.isLoading,
                                      loadError: specialtiesAsync.error,
                                      onRetry: () =>
                                          ref.invalidate(specialtiesProvider),
                                      cardTitle: 'Especialidades Seleccionadas',
                                      cardDescription:
                                          'Tu selección define los diagnósticos y consultas de mantenimiento que te asignará el sistema. Debes poseer maestría en las áreas marcadas.',
                                    ),
                                  4 => MechanicTechnicalStep(
                                      aniosExperiencia: _aniosExperiencia,
                                      onAniosExperienciaChanged: (v) =>
                                          setState(() => _aniosExperiencia = v),
                                    ),
                                  5 => TermsAcceptanceStep(
                                      audience: TermsAudience.serviceProvider,
                                      isAccepted: _termsAccepted,
                                      onAcceptedChanged: (accepted) => setState(
                                        () => _termsAccepted = accepted,
                                      ),
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡Solicitud\nRecibida!',
                                      description:
                                          'Nuestro equipo revisará tu perfil profesional en las próximas 24 horas.',
                                      buttonLabel: 'Finalizar Registro',
                                      buttonIcon: Icons.check_circle_outline,
                                      cards: const [
                                        CompletedStepCardItem(
                                          icon: Icons.timer_outlined,
                                          label: 'Revisión Estimada',
                                          title: 'Menos de 24 h',
                                        ),
                                        CompletedStepCardItem(
                                          icon: Icons.mail_outline,
                                          label: 'Notificación',
                                          title: 'Correo y Push',
                                        ),
                                      ],
                                      onFinish: () {
                                        ref
                                            .read(authProvider.notifier)
                                            .finishProviderRegistration();
                                        ref
                                            .read(socialRegistrationProvider
                                                .notifier)
                                            .clear();
                                        context.go(RouteNames.login);
                                      },
                                    ),
                                },
                              ),
                            ),
                          ),
                          if (_paso < _completedStep) ...[
                            const SizedBox(height: 32),
                            RegistrationStepFeedback(
                              message: _validationFeedback,
                            ),
                            _footer(),
                          ],
                        ],
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
          'Registro de Mecánico',
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
    String titulo = '';
    String subtitulo = '';

    switch (_paso) {
      case 1:
        titulo = 'Perfil del Mecánico';
        subtitulo = 'Paso 1 de 5: Información personal';
        break;
      case 2:
        titulo = 'Protege tu Cuenta';
        subtitulo = 'Crea una contraseña segura para tus futuros accesos.';
        break;
      case 3:
        titulo = 'Especialidades';
        subtitulo =
            'Selecciona las especialidades técnicas en las que estás certificado o tienes experiencia de nivel maestro.';
        break;
      case 4:
        titulo = 'Perfil Técnico';
        subtitulo = 'Paso 4 de 5: Detalles de experiencia';
        break;
      case 5:
        titulo = 'Términos y Condiciones';
        subtitulo =
            'Paso 5 de 5: Revisa y acepta el documento para registrarte.';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    final authState = ref.watch(authProvider);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _retroceder,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Text(
              'Atrás',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _PressableScale(
            onTap: _pasoValido && !authState.isLoading ? _avanzar : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: _pasoValido
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
                onPressed:
                    _pasoValido && !authState.isLoading ? _avanzar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD9DCE1),
                  disabledForegroundColor: const Color(0xFF9AA0A8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: authState.isLoading
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
                              _paso == _totalSteps ? 'FINALIZAR' : 'CONTINUAR',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String? get _validationFeedback {
    if (_pasoValido) return null;
    switch (_paso) {
      case 1:
        if (Validators.required(_nombreCtrl.text) != null) {
          return 'Ingresa tu nombre completo para continuar.';
        }
        if (Validators.phone(_telefonoCtrl.text) != null) {
          return 'Selecciona el prefijo y completa los 7 dígitos.';
        }
        if (Validators.email(_emailCtrl.text) != null) {
          return 'Ingresa un correo electrónico válido.';
        }
        return 'Ingresa tu número de cédula.';
      case 2:
        return Validators.password(_passwordCtrl.text) ??
            Validators.confirmPassword(
              _confirmPasswordCtrl.text,
              _passwordCtrl.text,
            );
      case 3:
        return 'Selecciona al menos una especialidad para continuar.';
      case 5:
        return 'Abre el documento y acepta los términos y condiciones para registrarte.';
    }
    return null;
  }

  int _stepForServerError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('contrase') || normalized.contains('password')) {
      return 2;
    }
    if (normalized.contains('correo') ||
        normalized.contains('email') ||
        normalized.contains('teléfono') ||
        normalized.contains('telefono') ||
        normalized.contains('phone') ||
        normalized.contains('cédula') ||
        normalized.contains('cedula') ||
        normalized.contains('identification')) {
      return 1;
    }
    return _paso;
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
