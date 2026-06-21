import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/mechanic_profile_step.dart';
import '../widgets/mechanic_technical_step.dart';
import '../widgets/workshop_specialties_step.dart';

class RegisterMechanicPage extends ConsumerStatefulWidget {
  const RegisterMechanicPage({super.key});

  @override
  ConsumerState<RegisterMechanicPage> createState() => _RegisterMechanicPageState();
}

class _RegisterMechanicPageState extends ConsumerState<RegisterMechanicPage> {
  int _paso = 1; // 1..4

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
    for (final c in [
      _nombreCtrl,
      _telefonoCtrl,
      _emailCtrl,
      _cedulaCtrl,
      _passwordCtrl,
      _confirmPasswordCtrl,
    ]) {
      c.addListener(() => setState(() {}));
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
    super.dispose();
  }

  // ===== Validación por paso =====
  bool get _passwordValida {
    final p = _passwordCtrl.text;
    return p.length >= 8 &&
        p.contains(RegExp(r'[0-9]')) &&
        p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  }

  bool get _pasoValido {
    switch (_paso) {
      case 1:
        return _nombreCtrl.text.trim().isNotEmpty &&
            _telefonoCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.contains('@') &&
            _cedulaCtrl.text.trim().isNotEmpty &&
            _passwordValida &&
            _confirmPasswordCtrl.text == _passwordCtrl.text;
      case 2:
        return _seleccionadas.isNotEmpty;
      case 3:
        return true; // bio es opcional, el slider siempre tiene valor
      default:
        return false;
    }
  }

  void _avanzar() {
    if (!_pasoValido) return;
    if (_paso < 3) {
      setState(() => _paso++);
    } else if (_paso == 3) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isLoading) return;

    String sanitizedPhone = _telefonoCtrl.text.trim();
    if (sanitizedPhone.isNotEmpty) {
      final clean = sanitizedPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      sanitizedPhone = clean.startsWith('0') ? clean.substring(1) : clean;
    }

    await ref.read(authProvider.notifier).registerMechanic(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      name: _nombreCtrl.text.trim(),
      phone: sanitizedPhone,
      latitude: 14.0818,
      longitude: -87.2068,
      description: 'Mecánico con ${_aniosExperiencia.round()} años de experiencia.',
      isWorkshop: false,
      identification: '$_cedulaTipo${_cedulaCtrl.text.trim()}',
      specialtyIds: _seleccionadas.toList(),
    );
  }

  void _retroceder() {
    if (_paso > 1 && _paso < 4) {
      setState(() => _paso--);
    } else if (_paso == 1) {
      context.go(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        setState(() => _paso = 4);
      }
    });

    final authState = ref.watch(authProvider);
    ref.listenAsyncError(specialtiesProvider, context);
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight - 32, // account for vertical padding
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _appBar(),
                          if (_paso < 4) ...[
                            const SizedBox(height: 16),
                            _indicadorPasos(),
                            const SizedBox(height: 16),
                            _tituloPaso(),
                            const SizedBox(height: 16),
                            ApiErrorMessage(
                              message: authState.errorMessage,
                              onClose: () => ref.read(authProvider.notifier).clearError(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) => FadeTransition(
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
                                      passwordController: _passwordCtrl,
                                      confirmPasswordController: _confirmPasswordCtrl,
                                      passwordValida: _passwordValida,
                                      cedulaTipo: _cedulaTipo,
                                      onCedulaTipoChanged: (val) {
                                        setState(() {
                                          _cedulaTipo = val;
                                        });
                                      },
                                    ),
                                  2 => WorkshopSpecialtiesStep(
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
                                       cardTitle: 'Especialidades Seleccionadas',
                                       cardDescription:
                                           'Tu selección define los diagnósticos y consultas de mantenimiento que te asignará el sistema. Debes poseer maestría en las áreas marcadas.',
                                     ),
                                  3 => MechanicTechnicalStep(
                                      aniosExperiencia: _aniosExperiencia,
                                      onAniosExperienciaChanged: (v) =>
                                          setState(() => _aniosExperiencia = v),
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡Solicitud\nRecibida!',
                                      description: 'Nuestro equipo revisará tu perfil profesional en las próximas 24 horas.',
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
                                        context.go(RouteNames.login);
                                      },
                                    ),
                                },
                              ),
                            ),
                          ),
                          if (_paso < 4) ...[
                            const SizedBox(height: 32),
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
        GestureDetector(
          onTap: _retroceder,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Registro de Mecánico',
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
          'PASO $_paso DE 4',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: List.generate(4, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 5,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: i < _paso ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
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
        subtitulo = 'Paso 1 de 4: Información personal';
        break;
      case 2:
        titulo = 'Especialidades';
        subtitulo =
            'Selecciona las especialidades técnicas en las que estás certificado o tienes experiencia de nivel maestro.';
        break;
      case 3:
        titulo = 'Perfil Técnico';
        subtitulo = 'Paso 3 de 4: Detalles de experiencia';
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
            onTap: _pasoValido ? _avanzar : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: _pasoValido
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
                onPressed: _pasoValido && !authState.isLoading ? _avanzar : null,
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
                              _paso == 3 ? 'FINALIZAR' : 'CONTINUAR',
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
