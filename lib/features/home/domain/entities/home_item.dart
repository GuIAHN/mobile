import 'package:equatable/equatable.dart';
import '../../../../core/domain/enums/service_type.dart';

class HomeItem extends Equatable {
  /// ID del proveedor en el backend (null en mocks de spareParts)
  final String? id;
  final String name;
  final String detail;
  final double rating;
  final int reviews;

  /// Distance returned by the backend. `null` means it was not provided.
  final double? distanceKm;

  /// Current availability returned by the backend. `null` means unknown.
  final bool? isOpen;
  final String iconName;
  final ServiceType type;
  final List<int>? gradientColors;

  /// Especialidades del mecánico / taller (vacío en mocks)
  final List<String> especialidades;

  /// Tarifa por hora (solo mecánicos, null en mocks y talleres)
  final double? tarifa;

  /// Indicates if the store has delivery
  final bool hasDelivery;

  /// Foto de perfil del usuario/proveedor
  final String? photo;

  const HomeItem({
    this.id,
    required this.name,
    required this.detail,
    required this.rating,
    required this.reviews,
    required this.distanceKm,
    required this.isOpen,
    required this.iconName,
    required this.type,
    this.gradientColors,
    this.especialidades = const [],
    this.tarifa,
    this.hasDelivery = false,
    this.photo,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        detail,
        rating,
        reviews,
        distanceKm,
        isOpen,
        iconName,
        type,
        gradientColors,
        especialidades,
        tarifa,
        hasDelivery,
        photo,
      ];
}
