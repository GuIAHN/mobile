import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/registration_completed_step.dart';
import '../widgets/store_catalog_helper.dart';
import '../widgets/store_catalog_step.dart';
import '../widgets/store_profile_step.dart';
import '../widgets/store_summary_step.dart';
import '../widgets/workshop_location_step.dart';

class RegisterStorePage extends ConsumerStatefulWidget {
  const RegisterStorePage({super.key});

  @override
  ConsumerState<RegisterStorePage> createState() => _RegisterStorePageState();
}

class _RegisterStorePageState extends ConsumerState<RegisterStorePage> {
  int _paso = 1; // 1..4

  // ===== Paso 1: Perfil de la tienda =====
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _rifCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // ===== Paso 2: Catálogo =====
  final List<LineaCatalogo> _catalogo = [];

  // ===== Paso 4: Ubicación =====
  Offset _posicionPin = const Offset(0.5, 0.5);
  bool _ubicacionConfirmada = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nombreCtrl, _emailCtrl, _telefonoCtrl, _rifCtrl, _passwordCtrl, _confirmPasswordCtrl]) {
      c.addListener(() => setState(() {}));
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
    super.dispose();
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
        existia: existente != null,
      ),
    );

    if (resultado == null) return;

    setState(() {
      if (resultado.eliminar || resultado.brands.isEmpty) {
        _catalogo.removeWhere((l) => l.category.id == category.id);
      } else if (existente != null) {
        existente.brands = resultado.brands;
      } else {
        _catalogo.add(LineaCatalogo(
          category: category,
          brands: resultado.brands,
        ));
      }
    });
  }

  bool get _passwordValida {
    final p = _passwordCtrl.text;
    return p.length >= 8 &&
        p.contains(RegExp(r'[0-9]')) &&
        p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  }

  // ===== Validación por paso =====
  bool get _pasoValido {
    switch (_paso) {
      case 1:
        return _nombreCtrl.text.trim().isNotEmpty &&
            _emailCtrl.text.trim().isNotEmpty &&
            RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$').hasMatch(_emailCtrl.text.trim()) &&
            _telefonoCtrl.text.trim().isNotEmpty &&
            _rifCtrl.text.trim().isNotEmpty &&
            _passwordValida &&
            _confirmPasswordCtrl.text == _passwordCtrl.text;
      case 2:
      case 3:
        return _catalogo.isNotEmpty;
      case 4:
        return _ubicacionConfirmada;
      default:
        return false;
    }
  }

  void _avanzar() {
    if (!_pasoValido) return;
    if (_paso < 4) {
      setState(() => _paso++);
    } else if (_paso == 4) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final authState = ref.read(authProvider);
    if (authState.isLoading) return;

    final latitude = 14.0818 + (_posicionPin.dy - 0.5) * 0.1;
    final longitude = -87.2068 + (_posicionPin.dx - 0.5) * 0.1;

    final catalogConfigs = _catalogo.map((l) {
      return StoreCategoryConfig(
        categoryId: l.category.id,
        minPrice: 1.0,
        servesAllBrands: false,
        brandIds: l.brands.map((b) => b.id).toList(),
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

    await ref.read(authProvider.notifier).registerStore(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      name: _nombreCtrl.text.trim(),
      phone: sanitizedPhone,
      latitude: latitude,
      longitude: longitude,
      address: 'Dirección física de la tienda.',
      rif: 'J$rif',
      catalog: catalogConfigs,
    );
  }

  void _retroceder() {
    if (_paso > 1 && _paso < 5) {
      setState(() => _paso--);
    } else if (_paso == 1) {
      context.go(RouteNames.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.isAuthenticated) {
        setState(() => _paso = 5);
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

    final authState = ref.watch(authProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _appBar(),
                          if (_paso < 5) ...[
                            const SizedBox(height: 16),
                            _indicadorPasos(),
                            const SizedBox(height: 16),
                            _tituloPaso(),
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
                                  1 => StoreProfileStep(
                                       nombreController: _nombreCtrl,
                                       emailController: _emailCtrl,
                                       telefonoController: _telefonoCtrl,
                                       rifController: _rifCtrl,
                                       passwordController: _passwordCtrl,
                                       confirmPasswordController: _confirmPasswordCtrl,
                                     ),
                                  2 => StoreCatalogStep(
                                       catalogo: _catalogo,
                                       categories: categories,
                                       onAbrirSheetMarcas: _abrirSheetMarcas,
                                     ),
                                  3 => StoreSummaryStep(
                                      catalogo: _catalogo,
                                      onAbrirSheetMarcas: _abrirSheetMarcas,
                                    ),
                                  4 => WorkshopLocationStep(
                                      posicionPin: _posicionPin,
                                      onPinChanged: (p) => setState(() => _posicionPin = p),
                                      ubicacionConfirmada: _ubicacionConfirmada,
                                      onUbicacionConfirmadaChanged: (c) =>
                                          setState(() => _ubicacionConfirmada = c),
                                      searchHint: 'Buscar dirección de la tienda...',
                                      helperText: 'Toca el mapa para ajustar la ubicación exacta de la tienda',
                                    ),
                                  _ => RegistrationCompletedStep(
                                      title: '¡Solicitud\nRecibida!',
                                      description: 'Hemos recibido la solicitud para registrar ${_nombreCtrl.text} de forma exitosa.',
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
                                          title: '${_catalogo.length} ${_catalogo.length == 1 ? 'categoría' : 'categorías'}',
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
                          if (_paso < 5) ...[
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
          'Registro de Tienda',
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
        titulo = 'Perfil de la Tienda';
        subtitulo = 'Paso 1 de 4: Información básica';
        break;
      case 2:
        titulo = 'Catálogo';
        subtitulo = 'Selecciona las categorías de repuestos que manejas y asócialas a sus marcas.';
        break;
      case 3:
        titulo = 'Catálogo Seleccionado';
        subtitulo = 'Paso 3 de 4: Revisa las categorías registradas. Toca una tarjeta para modificar sus marcas.';
        break;
      case 4:
        titulo = 'Ubicación';
        subtitulo = 'Paso 4 de 4: Confirma la dirección física de la tienda.';
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
                      _paso == 4 ? 'FINALIZAR' : 'CONTINUAR',
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
