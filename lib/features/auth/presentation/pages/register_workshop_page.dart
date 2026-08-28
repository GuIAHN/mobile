import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/venezuelan_phone_number.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../../../../shared/widgets/registration_page_chrome.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../widgets/account_security_step.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/registration_step_feedback.dart';
import '../widgets/terms_acceptance_step.dart';
import '../widgets/provider_documents_step.dart';
import '../widgets/workshop_info_step.dart';
import '../widgets/workshop_location_step.dart';
import '../widgets/workshop_specialties_step.dart';

class RegisterWorkshopPage extends ConsumerStatefulWidget {
  const RegisterWorkshopPage({super.key});

  @override
  ConsumerState<RegisterWorkshopPage> createState() =>
      _RegisterWorkshopPageState();
}

class _RegisterWorkshopPageState extends ConsumerState<RegisterWorkshopPage> {
  static const _totalSteps = 6;
  static const _completedStep = 7;

  int _paso = 1;
  final _scrollController = ScrollController();

  // ===== Paso 1: Información del taller =====
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ===== Paso 2: Especialidades =====
  final Set<String> _seleccionadas = {};

  // ===== Paso 3: Ubicación =====
  LatLng _location = const LatLng(10.4806, -66.9036);
  bool _ubicacionConfirmada = false;
  bool _termsAccepted = false;
  XFile? _rifPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
    for (final c in [
      _nombreCtrl,
      _emailCtrl,
      _telefonoCtrl,
      _rifCtrl,
      _passwordCtrl,
      _confirmPasswordCtrl
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _rifCtrl.dispose();
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

  bool get _passwordValida {
    return Validators.password(_passwordCtrl.text) == null;
  }

  // ===== Validación por paso =====
  bool get _pasoValido {
    switch (_paso) {
      case 1:
        return Validators.required(_nombreCtrl.text) == null &&
            Validators.email(_emailCtrl.text) == null &&
            Validators.phone(_telefonoCtrl.text) == null &&
            Validators.rif(_rifCtrl.text) == null;
      case 2:
        return _passwordValida &&
            Validators.confirmPassword(
                    _confirmPasswordCtrl.text, _passwordCtrl.text) ==
                null;
      case 3:
        return _seleccionadas.isNotEmpty;
      case 4:
        return _ubicacionConfirmada;
      case 5:
        return _rifPhoto != null;
      case 6:
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

    String rif = _rifCtrl.text.trim();
    if (rif.toUpperCase().startsWith('J')) {
      rif = rif.substring(1);
    }

    await ref.read(authProvider.notifier).registerMechanic(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nombreCtrl.text.trim(),
          phone: sanitizedPhone,
          latitude: _location.latitude,
          longitude: _location.longitude,
          description: 'Taller mecánico especializado.',
          isWorkshop: true,
          identification: 'J$rif',
          specialtyIds: _seleccionadas.toList(),
          acceptedTerms: _termsAccepted,
          rifPhotoPath: _rifPhoto!.path,
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
                          const SizedBox(height: 24),
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
                                  1 => WorkshopInfoStep(
                                      nombreController: _nombreCtrl,
                                      emailController: _emailCtrl,
                                      telefonoController: _telefonoCtrl,
                                      rifController: _rifCtrl,
                                    ),
                                  2 => AccountSecurityStep(
                                      passwordController: _passwordCtrl,
                                      confirmPasswordController:
                                          _confirmPasswordCtrl,
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
                                    ),
                                  4 => WorkshopLocationStep(
                                      location: _location,
                                      onLocationChanged: (location) =>
                                          setState(() => _location = location),
                                      ubicacionConfirmada: _ubicacionConfirmada,
                                      onUbicacionConfirmadaChanged: (c) =>
                                          setState(
                                              () => _ubicacionConfirmada = c),
                                    ),
                                  5 => ProviderDocumentsStep(
                                      rifPhoto: _rifPhoto,
                                      onRifPhotoChanged: (file) =>
                                          setState(() => _rifPhoto = file),
                                    ),
                                  6 => TermsAcceptanceStep(
                                      audience: TermsAudience.serviceProvider,
                                      isAccepted: _termsAccepted,
                                      onAcceptedChanged: (accepted) => setState(
                                        () => _termsAccepted = accepted,
                                      ),
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡REGISTRO\nCOMPLETADO!',
                                      description:
                                          'Tu solicitud ha sido recibida con éxito. Actualmente estamos verificando las credenciales de tu taller para garantizar la integridad de nuestra red profesional.',
                                      buttonLabel: 'Finalizar Registro',
                                      buttonIcon: Icons.check_circle_outline,
                                      cards: const [
                                        CompletedStepCardItem(
                                          icon: Icons.verified_user_outlined,
                                          label: 'ESTADO',
                                          title: 'En Verificación',
                                          subtitle:
                                              'Estimado: 2–4 horas hábiles',
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
                                          subtitle:
                                              'Revisa tu bandeja de entrada',
                                        ),
                                      ],
                                      onFinish: () {
                                        ref
                                            .read(authProvider.notifier)
                                            .finishProviderRegistration();
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
    return RegistrationPageHeader(
      title: 'Registro de Taller',
      onBack: _retroceder,
      backTooltip: _paso == 1 ? 'Volver a elegir perfil' : 'Paso anterior',
    );
  }

  Widget _indicadorPasos() {
    return RegistrationStepProgress(
      currentStep: _paso,
      totalSteps: _totalSteps,
    );
  }

  Widget _footer() {
    final authState = ref.watch(authProvider);
    return PressableScale(
      onTap: _pasoValido && !authState.isLoading ? _avanzar : null,
      child: SizedBox(
        width: double.infinity,
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
                  : RegistrationActionLabel(
                      label: _paso == _totalSteps ? 'FINALIZAR' : 'CONTINUAR',
                      icon: Icons.chevron_right,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tituloPaso() {
    final (title, subtitle) = switch (_paso) {
      1 => (
          'Perfil del Taller',
          'Registra los datos públicos y fiscales de tu negocio.'
        ),
      2 => (
          'Protege tu Cuenta',
          'Crea una contraseña segura para administrar tu taller.'
        ),
      3 => (
          'Especialidades',
          'Selecciona las áreas de servicio que domina tu equipo.'
        ),
      4 => (
          'Ubicación',
          'Confirma el punto exacto donde tus clientes encontrarán el taller.'
        ),
      5 => (
          'RIF del Taller',
          'Adjunta el RIF vigente para verificar el negocio.'
        ),
      6 => (
          'Términos y Condiciones',
          'Revisa y acepta el documento para completar tu registro.'
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

  String? get _validationFeedback {
    if (_pasoValido) return null;
    switch (_paso) {
      case 1:
        if (Validators.required(_nombreCtrl.text) != null) {
          return 'Ingresa el nombre del taller para continuar.';
        }
        if (Validators.email(_emailCtrl.text) != null) {
          return 'Ingresa un correo electrónico válido.';
        }
        if (Validators.phone(_telefonoCtrl.text) != null) {
          return 'Selecciona el prefijo y completa los 7 dígitos.';
        }
        return 'Ingresa el RIF del taller.';
      case 2:
        return Validators.password(_passwordCtrl.text) ??
            Validators.confirmPassword(
              _confirmPasswordCtrl.text,
              _passwordCtrl.text,
            );
      case 3:
        return 'Selecciona al menos una especialidad para continuar.';
      case 4:
        return 'Confirma la ubicación exacta del taller para continuar.';
      case 5:
        return 'Adjunta el RIF para continuar.';
      case 6:
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
        normalized.contains('rif') ||
        normalized.contains('identification')) {
      return 1;
    }
    if (normalized.contains('document') ||
        normalized.contains('rifphoto') ||
        normalized.contains('image') ||
        normalized.contains('file')) {
      return 5;
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
