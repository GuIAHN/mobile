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
import '../../../catalog/domain/entities/category.dart';
import '../../../vehicles/domain/entities/brand.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../providers/social_registration_state.dart';
import '../../domain/entities/store_coverage_config.dart';
import '../widgets/account_security_step.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/registration_step_feedback.dart';
import '../widgets/store_catalog_helper.dart';
import '../widgets/store_catalog_step.dart';
import '../widgets/store_profile_step.dart';
import '../widgets/store_summary_step.dart';
import '../widgets/terms_acceptance_step.dart';
import '../widgets/provider_documents_step.dart';
import '../widgets/workshop_location_step.dart';

class RegisterStorePage extends ConsumerStatefulWidget {
  const RegisterStorePage({super.key});

  @override
  ConsumerState<RegisterStorePage> createState() => _RegisterStorePageState();
}

class _RegisterStorePageState extends ConsumerState<RegisterStorePage> {
  static const _totalSteps = 7;
  static const _completedStep = 8;

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

  // ===== Pasos 3 y 4: Catálogo, marcas y tipos de repuesto =====
  final List<LineaCatalogo> _catalogo = [];
  bool _servesAllBrands = false;

  // ===== Paso 5: Ubicación =====
  LatLng _location = const LatLng(10.4806, -66.9036);
  bool _ubicacionConfirmada = false;
  bool _termsAccepted = false;
  XFile? _rifPhoto;

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

  void _toggleSubcategory(Category parentCategory, Category subcategory) {
    setState(() {
      final index = _catalogo.indexWhere(
        (line) => line.category.id == subcategory.id,
      );
      if (index >= 0) {
        _catalogo.removeAt(index);
        return;
      }
      final general = _catalogo.firstOrNull;
      _catalogo.add(
        LineaCatalogo(
          category: subcategory,
          parentCategory: parentCategory,
          brands: Set.of(general?.brands ?? {}),
          sparePartsTypes: Set.of(general?.sparePartsTypes ?? {}),
        ),
      );
    });
  }

  void _updateCatalogCoverage(
    Set<Brand> brands,
    Set<String> sparePartsTypes,
    bool servesAllBrands,
  ) {
    setState(() {
      _servesAllBrands = servesAllBrands;
      for (final line in _catalogo) {
        line.brands = Set.of(brands);
        line.sparePartsTypes = Set.of(sparePartsTypes);
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
            Validators.rif(_rifCtrl.text) == null;
      case 2:
        return isSocial ||
            (_passwordValida &&
                Validators.confirmPassword(
                        _confirmPasswordCtrl.text, _passwordCtrl.text) ==
                    null);
      case 3:
        return _catalogo.isNotEmpty;
      case 4:
        return _catalogo.isNotEmpty &&
            _catalogo.first.brands.isNotEmpty &&
            _catalogo.first.sparePartsTypes.isNotEmpty;
      case 5:
        return _ubicacionConfirmada;
      case 6:
        return _rifPhoto != null;
      case 7:
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

    final generalConfig = _catalogo.first;
    final coverage = StoreCoverageConfig(
      servesAllBrands: _servesAllBrands,
      brandIds: generalConfig.brands.map((brand) => brand.id).toList(),
      sparePartsTypes: generalConfig.sparePartsTypes.toList(),
      subcategoryIds: _catalogo.map((line) => line.category.id).toList(),
    );

    final sanitizedPhone = VenezuelanPhoneNumber.toApi(_telefonoCtrl.text)!;

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
          coverage: coverage,
          hasDelivery: _hasDelivery,
          idToken: socialData?.idToken,
          provider: socialData?.provider,
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
    final socialData = ref.watch(socialRegistrationProvider);
    final isSocial = socialData != null;
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  sliver: SliverList.list(
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
                      KeyedSubtree(
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
                              confirmPasswordController: _confirmPasswordCtrl,
                              isSocial: isSocial,
                              socialProvider: socialData?.provider,
                            ),
                          3 => StoreCatalogStep(
                              catalogo: _catalogo,
                              onSubcategoryToggled: _toggleSubcategory,
                            ),
                          4 => StoreSummaryStep(
                              catalogo: _catalogo,
                              servesAllBrands: _servesAllBrands,
                              onChanged: _updateCatalogCoverage,
                            ),
                          5 => WorkshopLocationStep(
                              location: _location,
                              onLocationChanged: (location) =>
                                  setState(() => _location = location),
                              ubicacionConfirmada: _ubicacionConfirmada,
                              onUbicacionConfirmadaChanged: (c) =>
                                  setState(() => _ubicacionConfirmada = c),
                              helperText:
                                  'Usa tu ubicación actual o mueve el mapa para marcar la tienda.',
                            ),
                          6 => ProviderDocumentsStep(
                              rifPhoto: _rifPhoto,
                              onRifPhotoChanged: (file) =>
                                  setState(() => _rifPhoto = file),
                            ),
                          7 => TermsAcceptanceStep(
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
                                      '${_catalogo.length} ${_catalogo.length == 1 ? 'subcategoría' : 'subcategorías'}',
                                ),
                              ],
                              onFinish: () {
                                ref
                                    .read(authProvider.notifier)
                                    .finishProviderRegistration();
                                ref
                                    .read(socialRegistrationProvider.notifier)
                                    .clear();
                                context.go(RouteNames.login);
                              },
                            ),
                        },
                      ),
                    ],
                  ),
                ),
                if (_paso < _completedStep)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      16 + bottomSafeInset,
                    ),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 32),
                          RegistrationStepFeedback(
                            message: _validationFeedback,
                          ),
                          _footer(),
                        ],
                      ),
                    ),
                  ),
                if (_paso >= _completedStep)
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 16 + bottomSafeInset),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return RegistrationPageHeader(
      title: 'Registro de Tienda',
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

  Widget _tituloPaso() {
    String titulo = '';
    String subtitulo = '';

    switch (_paso) {
      case 1:
        titulo = 'Perfil de la Tienda';
        subtitulo = 'Paso 1 de 7: Información básica';
        break;
      case 2:
        titulo = 'Protege tu Cuenta';
        subtitulo = 'Crea una contraseña segura para administrar tu tienda.';
        break;
      case 3:
        titulo = 'Tu Catálogo';
        subtitulo = 'Elige las categorías y repuestos que ofreces.';
        break;
      case 4:
        titulo = 'Marcas y Tipos';
        subtitulo = 'Elige las marcas y tipos que vendes.';
        break;
      case 5:
        titulo = 'Ubicación';
        subtitulo = 'Paso 5 de 7: Confirma la dirección física de la tienda.';
        break;
      case 6:
        titulo = 'RIF de la Tienda';
        subtitulo = 'Paso 6 de 7: Adjunta el RIF de la tienda.';
        break;
      case 7:
        titulo = 'Términos y Condiciones';
        subtitulo =
            'Paso 7 de 7: Revisa y acepta el documento para registrarte.';
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
          child: PressableScale(
            onTap: _pasoValido && !authState.isLoading ? _avanzar : null,
            child: ElevatedButton(
              key: const Key('register-store-continue'),
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
          return 'Selecciona el prefijo y completa los 7 dígitos.';
        }
        return 'Ingresa el RIF de la tienda.';
      case 2:
        return Validators.password(_passwordCtrl.text) ??
            Validators.confirmPassword(
              _confirmPasswordCtrl.text,
              _passwordCtrl.text,
            );
      case 3:
        return 'Selecciona al menos un repuesto para continuar.';
      case 4:
        return 'Selecciona al menos una marca y un tipo de repuesto para continuar.';
      case 5:
        return 'Confirma la ubicación exacta de la tienda para continuar.';
      case 6:
        return 'Adjunta el RIF para continuar.';
      case 7:
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
    if (normalized.contains('document') ||
        normalized.contains('rifphoto') ||
        normalized.contains('image') ||
        normalized.contains('file')) {
      return 6;
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
