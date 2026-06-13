/// Entidad que describe un slide del onboarding.
/// No depende de ninguna capa de datos — es puramente de dominio.
class OnboardingSlide {
  final String tagline;
  final String title;
  final String description;
  final String imagePath;

  const OnboardingSlide({
    required this.tagline,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  /// Los 3 slides predefinidos del onboarding con el diseño moderno.
  static const List<OnboardingSlide> slides = [
    OnboardingSlide(
      tagline: 'MECÁNICA DE PRECISIÓN',
      title: 'Encuentra Repuestos',
      description:
          'Accede al inventario más completo de piezas originales y certificadas para mantener tu motor en máxima performance.',
      imagePath:
          'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=1200&q=80',
    ),
    OnboardingSlide(
      tagline: 'SIEMPRE CERCA DE TI',
      title: 'Talleres a tu Alcance',
      description:
          'Descubre los talleres más cercanos a tu ubicación, compara servicios y precios, y elige el ideal para tu vehículo.',
      imagePath:
          'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=1200&q=80',
    ),
    OnboardingSlide(
      tagline: 'EXPERTOS VERIFICADOS',
      title: 'Mecánicos de Confianza',
      description:
          'Conecta con mecánicos certificados, revisa sus reseñas y especialidades, y agenda tu cita en segundos.',
      imagePath:
          'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80',
    ),
  ];
}

