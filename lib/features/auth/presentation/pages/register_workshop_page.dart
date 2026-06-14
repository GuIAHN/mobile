import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/workshop_info_step.dart';
import '../widgets/workshop_location_step.dart';
import '../widgets/workshop_specialties_step.dart';

class RegisterWorkshopPage extends ConsumerStatefulWidget {
  const RegisterWorkshopPage({super.key});

  @override
  ConsumerState<RegisterWorkshopPage> createState() => _RegisterWorkshopPageState();
}

class _RegisterWorkshopPageState extends ConsumerState<RegisterWorkshopPage> {
  int _paso = 1; // 1..4

  // ===== Paso 1: Información del taller =====
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  // ===== Paso 2: Especialidades =====
  final Set<int> _seleccionadas = {};

  // ===== Paso 3: Ubicación =====
  Offset _posicionPin = const Offset(0.5, 0.5);
  bool _ubicacionConfirmada = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nombreCtrl, _emailCtrl, _telefonoCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  // ===== Validación por paso =====
  bool get _pasoValido {
    switch (_paso) {
      case 1:
        return _nombreCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.trim().isNotEmpty &&
            RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(_emailCtrl.text.trim()) &&
            _telefonoCtrl.text.trim().isNotEmpty;
      case 2:
        return _seleccionadas.isNotEmpty;
      case 3:
        return _ubicacionConfirmada;
      default:
        return false;
    }
  }

  void _avanzar() {
    if (!_pasoValido) return;
    if (_paso < 4) {
      setState(() => _paso++);
    }
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
                          ],
                          const SizedBox(height: 24),
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
                                  1 => WorkshopInfoStep(
                                      nombreController: _nombreCtrl,
                                      emailController: _emailCtrl,
                                      telefonoController: _telefonoCtrl,
                                    ),
                                  2 => WorkshopSpecialtiesStep(
                                      selectedSpecialties: _seleccionadas,
                                      onSpecialtyToggled: (i) {
                                        setState(() {
                                          if (_seleccionadas.contains(i)) {
                                            _seleccionadas.remove(i);
                                          } else {
                                            _seleccionadas.add(i);
                                          }
                                        });
                                      },
                                    ),
                                  3 => WorkshopLocationStep(
                                      posicionPin: _posicionPin,
                                      onPinChanged: (p) => setState(() => _posicionPin = p),
                                      ubicacionConfirmada: _ubicacionConfirmada,
                                      onUbicacionConfirmadaChanged: (c) =>
                                          setState(() => _ubicacionConfirmada = c),
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡REGISTRO\nCOMPLETADO!',
                                      description: 'Tu solicitud ha sido recibida con éxito. Actualmente estamos verificando las credenciales de tu taller para garantizar la integridad de nuestra red profesional.',
                                      buttonLabel: 'Ir al Panel de Control',
                                      buttonIcon: Icons.grid_view,
                                      cards: const [
                                        CompletedStepCardItem(
                                          icon: Icons.verified_user_outlined,
                                          label: 'ESTADO',
                                          title: 'En Verificación',
                                          subtitle: 'Estimado: 2–4 horas hábiles',
                                        ),
                                        CompletedStepCardItem(
                                          icon: Icons.construction_outlined,
                                          label: 'ACCESO',
                                          title: 'Herramientas',
                                          subtitle: 'Modo lectura habilitado',
                                        ),
                                        CompletedStepCardItem(
                                          icon: Icons.mail_outline,
                                          label: 'NOTIFICACIÓN',
                                          title: 'Correo Enviado',
                                          subtitle: 'Revisa tu bandeja de entrada',
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
          'Registro de Taller',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
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

  Widget _footer() {
    return _PressableScale(
      onTap: _pasoValido ? _avanzar : null,
      child: SizedBox(
        width: double.infinity,
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
            onPressed: _pasoValido ? _avanzar : null,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CONTINUAR',
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
