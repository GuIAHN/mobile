import 'service_type.dart';

/// Roles system mapping the backend user roles: CONSUMER, ADMIN, STORE, MECHANIC, WORKSHOP
enum UserRole {
  consumer('CONSUMER'),
  admin('ADMIN'),
  store('STORE'),
  mechanic('MECHANIC'),
  workshop('WORKSHOP'),
  unknown('UNKNOWN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? val) {
    if (val == null) return UserRole.unknown;
    final upper = val.toUpperCase().trim();
    return UserRole.values.firstWhere(
      (e) => e.value == upper || e.name.toUpperCase() == upper,
      orElse: () => UserRole.unknown,
    );
  }

  bool get isProvider =>
      this == UserRole.mechanic ||
      this == UserRole.workshop ||
      this == UserRole.store;

  bool get isConsumer => this == UserRole.consumer;

  bool get isAdmin => this == UserRole.admin;

  bool get isStore => this == UserRole.store;
  bool get isMechanic => this == UserRole.mechanic;
  bool get isWorkshop => this == UserRole.workshop;

  /// Tipos de servicio visibles en el CategorySelector del home según el rol.
  /// La STORE puede buscar mecánicos y talleres, pero no repuestos.
  /// El MECHANIC puede buscar repuestos y talleres, pero no otros mecánicos.
  /// El WORKSHOP puede buscar repuestos y mecánicos, pero no otros talleres.
  /// Consumidores pueden ver y buscar todo.
  List<ServiceType> get allowedServiceTypes {
    if (isStore) {
      return const [ServiceType.storeDashboard, ServiceType.mechanic, ServiceType.workshops];
    }
    if (isMechanic) {
      return const [ServiceType.spareParts, ServiceType.workshops];
    }
    if (isWorkshop) {
      return const [ServiceType.spareParts, ServiceType.mechanic];
    }
    return const [ServiceType.spareParts, ServiceType.workshops, ServiceType.mechanic];
  }

  /// Si el rol está autorizado para enviar solicitudes de cotización de repuestos.
  /// STORE es quien las recibe y cotiza, por ende no puede auto-solicitarse.
  bool get canRequestSpareParts => !isStore;
}

