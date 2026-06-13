import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_car.dart';

/// Notifier que gestiona la lista temporal de vehículos de usuario (UserCar) agregados en el registro.
class RegisterVehiclesNotifier extends StateNotifier<List<UserCar>> {
  RegisterVehiclesNotifier() : super([]);

  /// Agrega un nuevo vehículo temporal a la lista.
  void addUserCar({
    required String brand,
    required String model,
    required int year,
  }) {
    final newUserCar = UserCar(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generación simple de ID único local
      brand: brand,
      model: model,
      year: year,
    );
    state = [...state, newUserCar];
  }

  /// Elimina un vehículo por su índice.
  void removeUserCar(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  /// Limpia la lista.
  void clear() {
    state = [];
  }
}

/// Proveedor para la lista de vehículos del registro.
final registerVehiclesProvider =
    StateNotifierProvider<RegisterVehiclesNotifier, List<UserCar>>((ref) {
  return RegisterVehiclesNotifier();
});
