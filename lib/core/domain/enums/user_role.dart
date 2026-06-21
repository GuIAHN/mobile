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
}
