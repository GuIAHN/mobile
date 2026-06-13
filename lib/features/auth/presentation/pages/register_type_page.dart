import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/circular_back_button.dart';

class RegisterTypePage extends StatefulWidget {
  const RegisterTypePage({super.key});

  @override
  State<RegisterTypePage> createState() => _RegisterTypePageState();
}

class _RegisterTypePageState extends State<RegisterTypePage> {
  String? _selectedRole;

  void _handleContinue() {
    if (_selectedRole == null) return;

    if (_selectedRole == 'user') {
      context.go(RouteNames.registerUser);
    } else if (_selectedRole == 'workshop') {
      context.go(RouteNames.registerWorkshop);
    } else if (_selectedRole == 'mechanic') {
      context.go(RouteNames.registerMechanic);
    } else if (_selectedRole == 'store') {
      context.go(RouteNames.registerStore);
    } else {
      _showComingSoonDialog();
    }
  }

  void _showComingSoonDialog() {
    String profileName = '';
    IconData profileIcon = Icons.info_outline;

    switch (_selectedRole) {
      case 'mechanic':
        profileName = 'Mecánico';
        profileIcon = Icons.build_rounded;
        break;
      case 'workshop':
        profileName = 'Taller';
        profileIcon = Icons.home_repair_service_rounded;
        break;
      case 'store':
        profileName = 'Tienda de Repuestos';
        profileIcon = Icons.storefront_rounded;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.loginSurface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.loginPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  profileIcon,
                  color: AppColors.loginPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Registro de $profileName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.loginOnSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '¡Próximamente disponible!\nActualmente estamos habilitando el registro paso a paso. El registro para este tipo de perfil se abrirá muy pronto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.loginOnSurfaceVar,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeightMd,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.loginPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'ENTENDIDO',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.loginBg,
      appBar: isWideScreen
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: AppColors.loginOnSurfaceVar,
                  onPressed: () => context.go(RouteNames.login),
                  tooltip: 'Volver a iniciar sesión',
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: isWideScreen ? 0 : AppSpacing.xl2,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isWideScreen) ...[
                    CircularBackButton(
                      onTap: () => context.go(RouteNames.login),
                      tooltip: 'Volver a iniciar sesión',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Encabezado
                  const Text(
                    'Elige tu perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.loginOnSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Selecciona la opción que mejor se adapte a ti para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.loginOnSurfaceVar,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Lista de opciones de tipo de usuario
                  _ProfileTypeCard(
                    role: 'user',
                    title: 'Usuario / Cliente',
                    description: 'Busco servicios para mis vehículos, mecánicos y repuestos.',
                    icon: Icons.directions_car_rounded,
                    isSelected: _selectedRole == 'user',
                    onTap: () => setState(() => _selectedRole = 'user'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  _ProfileTypeCard(
                    role: 'mechanic',
                    title: 'Mecánico Especializado',
                    description: 'Ofrezco mis servicios profesionales e independientes.',
                    icon: Icons.build_circle_rounded,
                    isSelected: _selectedRole == 'mechanic',
                    onTap: () => setState(() => _selectedRole = 'mechanic'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _ProfileTypeCard(
                    role: 'workshop',
                    title: 'Taller Mecánico / Centro de Servicio',
                    description: 'Gestiono un taller establecido y busco expandir mis clientes.',
                    icon: Icons.home_repair_service_rounded,
                    isSelected: _selectedRole == 'workshop',
                    onTap: () => setState(() => _selectedRole = 'workshop'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  _ProfileTypeCard(
                    role: 'store',
                    title: 'Tienda de Repuestos / Autorepuestos',
                    description: 'Vendo repuestos, piezas, lubricantes e insumos automotrices.',
                    icon: Icons.storefront_rounded,
                    isSelected: _selectedRole == 'store',
                    onTap: () => setState(() => _selectedRole = 'store'),
                  ),
                  const SizedBox(height: AppSpacing.xl3),

                  // Botón continuar
                  SizedBox(
                    height: AppSpacing.buttonHeightMd,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.loginPrimary,
                        disabledBackgroundColor: AppColors.loginOutlineVar,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.loginOnSurfaceVar.withValues(alpha: 0.5),
                        elevation: _selectedRole == null ? 0 : 3,
                        shadowColor: const Color(0x4DFF5C00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'CONTINUAR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: _selectedRole == null 
                                ? AppColors.loginOnSurfaceVar.withValues(alpha: 0.5)
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

class _ProfileTypeCard extends StatelessWidget {
  final String role;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileTypeCard({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.loginPrimary.withValues(alpha: 0.04) 
            : AppColors.loginSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isSelected ? AppColors.loginPrimary : AppColors.loginOutlineVar,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.loginPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 1),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.loginPrimary.withValues(alpha: 0.1) 
                        : AppColors.loginBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? AppColors.loginPrimary : AppColors.loginOnSurfaceVar,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.loginPrimary : AppColors.loginOnSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.loginOnSurfaceVar,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.loginPrimary,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
