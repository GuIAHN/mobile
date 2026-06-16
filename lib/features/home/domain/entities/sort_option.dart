/// Opciones de ordenamiento para la lista de servicios.
enum SortOption {
  cercania,
  rating,
  populares,
}

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.cercania:
        return 'Más cercanos';
      case SortOption.rating:
        return 'Mejor valorados';
      case SortOption.populares:
        return 'Más populares';
    }
  }
}
