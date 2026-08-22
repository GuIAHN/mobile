import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/api_error_message.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';
import '../../domain/entities/store_category_config.dart';
import '../widgets/account_security_step.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/registration_step_feedback.dart';
import '../widgets/store_catalog_helper.dart';
import '../widgets/store_catalog_step.dart';
import '../widgets/store_profile_step.dart';
import '../widgets/store_summary_step.dart';
import '../widgets/terms_acceptance_step.dart';
import '../widgets/workshop_location_step.dart';

class RegisterStorePage extends ConsumerStatefulWidget {
  const RegisterStorePage({super.key});

  @override
  ConsumerState<RegisterStorePage> createState() => _RegisterStorePageState();
}

class _RegisterStorePageState extends ConsumerState<RegisterStorePage> {
  static const _totalSteps = 6;
  static const _completedStep = 7;

  int _paso = 1;
  final _scrollController = ScrollController();

  // ===== Paso 1: Perfil de la tienda =====
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _hasDelivery = false;

  // ===== Paso 2: Catálogo =====
  final List<LineaCatalogo> _catalogo = [];

  // ===== Paso 4: Ubicación =====
  LatLng _location = const LatLng(10.4806, -66.9036);
  bool _ubicacionConfirmada = false;
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

  LineaCatalogo? _buscarLinea(String categoryId) {
    for (final l in _catalogo) {
      if (l.category.id == categoryId) return l;
    }
    return null;
  }

  /* ───────── Bottom sheet de marcas por categoría ───────── */
  Future<void> _abrirSheetMarcas(Category category) async {
    final existente = _buscarLinea(category.id);

    final resultado = await showModalBottomSheet<ResultadoSheet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetMarcas(
        category: category,
        seleccionInicial: existente?.brands ?? {},
        typesInicial: existente?.sparePartsTypes ?? {'ORIGINAL'},
        existia: existente != null,
      ),
    );

    if (resultado == null) return;

    setState(() {
      if (resultado.eliminar ||
          resultado.brands.isEmpty ||
          resultado.sparePartsTypes.isEmpty) {
        _catalogo.removeWhere((l) => l.category.id == category.id);
      } else if (existente != null) {
        existente.brands = resultado.brands;
        existente.sparePartsTypes = resultado.sparePartsTypes;
      } else {
        _catalogo.add(LineaCatalogo(
          category: category,
          brands: resultado.brands,
          sparePartsTypes: resultado.sparePartsTypes,
        ));
      }
    });
  }

  bool get _passwordValida {
    return Validators.password(_passwordCtrl.text) == null;
  }

  // ===== Validación por paso =====
  bool get _pasoValido {
    final socialData = ref.read(socialRegistrationProvider);
    final isSocial = socialData != null;

    switch (_paso) {
      case 1:
        return Validators.required(_nombreCtrl.text) == null &&
            Validators.email(_emailCtrl.text) == null &&
            Validators.phone(_telefonoCtrl.text) == null &&
            Validators.required(_rifCtrl.text) == null;
      case 2:
        return isSocial ||
            (_passwordValida &&
                Validators.confirmPassword(
                        _confirmPasswordCtrl.text, _passwordCtrl.text) ==
                    null);
      case 3:
      case 4:
        return _catalogo.isNotEmpty;
      case 5:
        return _ubicacionConfirmada;
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

    final catalogConfigs = _catalogo.map((l) {
      return StoreCategoryConfig(
        categoryId: l.category.id,
        servesAllBrands: false,
        brandIds: l.brands.map((b) => b.id).toList(),
        sparePartsTypes: l.sparePartsTypes.toList(),
      );
    }).toList();

    String sanitizedPhone = _telefonoCtrl.text.trim();
    if (sanitizedPhone.isNotEmpty) {
      final clean = sanitizedPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      sanitizedPhone = clean.startsWith('0') ? clean.substring(1) : clean;
    }

    String rif = _rifCtrl.text.trim();
    if (rif.toUpperCase().startsWith('J')) {
      rif = rif.substring(1);
    }

    final socialData = ref.read(socialRegistrationProvider);

    await ref.read(authProvider.notifier).registerStore(
          email: _emailCtrl.text.trim(),
          password: socialData == null ? _passwordCtrl.text : null,
          name: _nombreCtrl.text.trim(),
          phone: sanitizedPhone,
          latitude: _location.latitude,
          longitude: _location.longitude,
          address: 'Dirección física de la tienda.',
          rif: 'J$rif',
          catalog: catalogConfigs,
          hasDelivery: _hasDelivery,
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

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
                                  1 => StoreProfileStep(
                                      nombreController: _nombreCtrl,
                                      emailController: _emailCtrl,
                                      telefonoController: _telefonoCtrl,
                                      rifController: _rifCtrl,
                                      hasDelivery: _hasDelivery,
                                      onHasDeliveryChanged: (v) =>
                                          setState(() => _hasDelivery = v),
                                      isSocial: isSocial,
                                    ),
                                  2 => AccountSecurityStep(
                                      passwordController: _passwordCtrl,
                                      confirmPasswordController:
                                          _confirmPasswordCtrl,
                                      isSocial: isSocial,
                                      socialProvider: socialData?.provider,
                                    ),
                                  3 => StoreCatalogStep(
                                      catalogo: _catalogo,
                                      categories: categories,
                                      onAbrirSheetMarcas: _abrirSheetMarcas,
                                      isLoading: categoriesAsync.isLoading,
                                      loadError: categoriesAsync.error,
                                      onRetry: () =>
                                          ref.invalidate(categoriesProvider),
                                    ),
                                  4 => StoreSummaryStep(
                                      catalogo: _catalogo,
                                      onAbrirSheetMarcas: _abrirSheetMarcas,
                                    ),
                                  5 => WorkshopLocationStep(
                                      location: _location,
                                      onLocationChanged: (location) =>
                                          setState(() => _location = location),
                                      ubicacionConfirmada: _ubicacionConfirmada,
                                      onUbicacionConfirmadaChanged: (c) =>
                                          setState(
                                              () => _ubicacionConfirmada = c),
                                      searchHint:
                                          'Buscar dirección de la tienda...',
                                      helperText:
                                          'Toca el mapa para ajustar la ubicación exacta de la tienda',
                                    ),
                                  6 => TermsAcceptanceStep(
                                      audience: TermsAudience.serviceProvider,
                                      isAccepted: _termsAccepted,
                                      onAcceptedChanged: (accepted) => setState(
                                        () => _termsAccepted = accepted,
                                      ),
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡Solicitud\nRecibida!',
                                      description:
                                          'Hemos recibido la solicitud para registrar ${_nombreCtrl.text} de forma exitosa.',
                                      buttonLabel: 'Finalizar Registro',
                                      buttonIcon: Icons.check_circle_outline,
                                      cards: [
                                        const CompletedStepCardItem(
                                          icon: Icons.timer_outlined,
                                          label: 'Aprobación Estimada',
                                          title: 'Entre 24 y 48 horas',
                                        ),
                                        CompletedStepCardItem(
                                          icon: Icons.storefront_outlined,
                                          label: 'Catálogo de Repuestos',
                                          title:
                                              '${_catalogo.length} ${_catalogo.length == 1 ? 'categoría' : 'categorías'}',
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
          'Registro de Tienda',
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
        titulo = 'Perfil de la Tienda';
        subtitulo = 'Paso 1 de 6: Información básica';
        break;
      case 2:
        titulo = 'Protege tu Cuenta';
        subtitulo = 'Crea una contraseña segura para administrar tu tienda.';
        break;
      case 3:
        titulo = 'Catálogo';
        subtitulo =
            'Selecciona las categorías de repuestos que manejas y asócialas a sus marcas.';
        break;
      case 4:
        titulo = 'Catálogo Seleccionado';
        subtitulo =
            'Paso 4 de 6: Revisa las categorías registradas. Toca una tarjeta para modificar sus marcas.';
        break;
      case 5:
        titulo = 'Ubicación';
        subtitulo = 'Paso 5 de 6: Confirma la dirección física de la tienda.';
        break;
      case 6:
        titulo = 'Términos y Condiciones';
        subtitulo =
            'Paso 6 de 6: Revisa y acepta el documento para registrarte.';
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
                child: Row(
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
                    const SizedBox(width: 6),
                    if (authState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.chevron_right, size: 18),
                  ],
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
          return 'Ingresa el nombre de la tienda para continuar.';
        }
        if (Validators.email(_emailCtrl.text) != null) {
          return 'Ingresa un correo electrónico válido.';
        }
        if (Validators.phone(_telefonoCtrl.text) != null) {
          return 'Revisa el teléfono. Usa entre 7 y 15 dígitos.';
        }
        return 'Ingresa el RIF de la tienda.';
      case 2:
        return Validators.password(_passwordCtrl.text) ??
            Validators.confirmPassword(
              _confirmPasswordCtrl.text,
              _passwordCtrl.text,
            );
      case 3:
        return 'Agrega al menos una categoría y sus marcas al catálogo.';
      case 4:
        return 'El catálogo quedó vacío. Vuelve atrás y agrega una categoría.';
      case 5:
        return 'Confirma la ubicación exacta de la tienda para continuar.';
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
        normalized.contains('rif')) {
      return 1;
    }
    if (normalized.contains('categor')) return 3;
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
