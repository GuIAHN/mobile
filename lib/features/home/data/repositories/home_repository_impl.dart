import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home_item_model.dart';
import '../models/promo_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  // Datos mockeados de Promociones con URLs de Unsplash automotrices premium
  static const Map<ServiceType, List<PromoModel>> _mockPromos = {
    ServiceType.mechanic: [
      PromoModel(
        title: 'Mecánicos certificados',
        subtitle: 'Verificados y con garantía escrita',
        iconName: 'verified_outlined',
        gradientColors: [0xFFF25C05, 0xFFF5813A], // Naranja a naranja claro
        imageUrl: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Servicio a domicilio',
        subtitle: 'Tu mecánico certificado donde estés',
        iconName: 'home_repair_service_outlined',
        gradientColors: [0xFF2E7D4F, 0xFF6FCF97],
        imageUrl: 'https://images.unsplash.com/photo-1517524206127-48bbd363f3d7?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    ServiceType.spareParts: [
      PromoModel(
        title: 'Toyota Original',
        subtitle: 'Hasta 20% en piezas seleccionadas',
        iconName: 'local_offer_outlined',
        gradientColors: [0xFFF25C05, 0xFFBF4704],
        imageUrl: 'https://images.unsplash.com/photo-1507136566006-cfc505b114fc?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Bosch & Denso',
        subtitle: 'Componentes Premium · Envío nacional gratis',
        iconName: 'bolt_outlined',
        gradientColors: [0xFF3A86FF, 0xFF6FA8FF], // Azul de la marca
        imageUrl: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Combo Mantenimiento',
        subtitle: 'Filtros + aceite sintético desde \$25',
        iconName: 'oil_barrel_outlined',
        gradientColors: [0xFF1A1C1E, 0xFF6B7280], // Carbón / Gris
        imageUrl: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ),
    ],
    ServiceType.workshops: [
      PromoModel(
        title: 'Talleres aliados',
        subtitle: 'Diagnóstico por computadora gratis',
        iconName: 'handyman_outlined',
        gradientColors: [0xFFF25C05, 0xFFFDE8DA],
        imageUrl: 'https://images.unsplash.com/photo-1504222490345-c075b6008014?auto=format&fit=crop&w=600&q=80',
      ),
      PromoModel(
        title: 'Latonería y pintura',
        subtitle: 'Presupuesto digital en menos de 24h',
        iconName: 'format_paint_outlined',
        gradientColors: [0xFFE53935, 0xFFEF4444],
        imageUrl: 'https://images.unsplash.com/photo-1597762137435-fcb1a210c64d?auto=format&fit=crop&w=600&q=80',
      ),
    ],
  };

  // Datos mockeados de items (Mecánicos, Repuestos, Talleres)
  static const Map<ServiceType, List<HomeItemModel>> _mockItems = {
    ServiceType.mechanic: [
      HomeItemModel(
        name: 'Carlos Rodríguez',
        detail: 'Especialista en motor · Inyección electrónica',
        rating: 4.9,
        reviews: 214,
        distanceKm: 0.8,
        isOpen: true,
        iconName: 'build_outlined',
        type: ServiceType.mechanic,
      ),
      HomeItemModel(
        name: 'José Martínez',
        detail: 'Frenos, suspensión y alineación computarizada',
        rating: 4.7,
        reviews: 132,
        distanceKm: 1.4,
        isOpen: true,
        iconName: 'build_outlined',
        type: ServiceType.mechanic,
      ),
      HomeItemModel(
        name: 'Luis Hernández',
        detail: 'Electricidad automotriz y diagnóstico de ECU',
        rating: 4.5,
        reviews: 88,
        distanceKm: 2.1,
        isOpen: false,
        iconName: 'build_outlined',
        type: ServiceType.mechanic,
      ),
    ],
    ServiceType.spareParts: [
      HomeItemModel(
        name: 'Repuestos El Motor',
        detail: 'Distribuidor autorizado: Toyota · Chevrolet · Ford',
        rating: 4.8,
        reviews: 340,
        distanceKm: 0.5,
        isOpen: true,
        iconName: 'settings_outlined',
        type: ServiceType.spareParts,
      ),
      HomeItemModel(
        name: 'AutoPartes Centro',
        detail: 'Multimarca · Repuestos originales e importados',
        rating: 4.6,
        reviews: 198,
        distanceKm: 1.2,
        isOpen: true,
        iconName: 'settings_outlined',
        type: ServiceType.spareParts,
      ),
      HomeItemModel(
        name: 'La Casa del Filtro',
        detail: 'Filtros · Aceites · Lubricantes de alto rendimiento',
        rating: 4.4,
        reviews: 76,
        distanceKm: 1.9,
        isOpen: true,
        iconName: 'settings_outlined',
        type: ServiceType.spareParts,
      ),
      HomeItemModel(
        name: 'Frenos y Más',
        detail: 'Especialistas en pastillas, discos y fluidos',
        rating: 4.3,
        reviews: 54,
        distanceKm: 2.6,
        isOpen: false,
        iconName: 'settings_outlined',
        type: ServiceType.spareParts,
      ),
    ],
    ServiceType.workshops: [
      HomeItemModel(
        name: 'Taller Mecánico Express',
        detail: 'Servicio preventivo completo · Grúa 24h',
        rating: 4.7,
        reviews: 156,
        distanceKm: 0.9,
        isOpen: true,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
      ),
      HomeItemModel(
        name: 'AutoCenter Pro',
        detail: 'Diagnóstico computarizado y scanner OBD2',
        rating: 4.6,
        reviews: 121,
        distanceKm: 1.6,
        isOpen: true,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
      ),
      HomeItemModel(
        name: 'Latonería San Juan',
        detail: 'Latonería · Pintura al horno · Choques',
        rating: 4.5,
        reviews: 93,
        distanceKm: 3.0,
        isOpen: false,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
      ),
    ],
  };

  @override
  Future<Either<Failure, List<Promo>>> getPromos(ServiceType type) async {
    try {
      // Simula latencia de red de 200ms
      await Future.delayed(const Duration(milliseconds: 200));
      final promos = _mockPromos[type] ?? [];
      return Right(promos);
    } catch (e) {
      return const Left(UnexpectedFailure(message: 'Error al cargar promociones'));
    }
  }

  @override
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type) async {
    try {
      // Simula latencia de red de 200ms
      await Future.delayed(const Duration(milliseconds: 200));
      final items = _mockItems[type] ?? [];
      return Right(items);
    } catch (e) {
      return const Left(UnexpectedFailure(message: 'Error al cargar servicios'));
    }
  }
}
