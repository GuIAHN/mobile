import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

/// Hoja de selección inferior para elegir la fuente de imagen (Cámara o Galería).
/// Compartida para evitar duplicidad de código.
class ImageSourceSelectorSheet extends StatelessWidget {
  final String title;

  const ImageSourceSelectorSheet({
    super.key,
    this.title = 'Adjuntar fotografía',
  });

  /// Muestra la hoja de selección y retorna el [ImageSource] seleccionado o null.
  static Future<ImageSource?> show(
    BuildContext context, {
    String title = 'Adjuntar fotografía',
  }) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => ImageSourceSelectorSheet(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle gris centrado
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _OptionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Cámara',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galería',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableOption(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableOption extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableOption({required this.child, required this.onTap});

  @override
  State<_PressableOption> createState() => _PressableOptionState();
}

class _PressableOptionState extends State<_PressableOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
