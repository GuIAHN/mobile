import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_car.dart';

/// Vehicle draft containing modelId from backend catalog for persistence.
class UserCarDraft extends UserCar {
  final String modelId;

  const UserCarDraft({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
    required this.modelId,
  });
}

/// Notifier managing the temporary list of user vehicle drafts (UserCarDraft) added during registration.
class RegisterVehiclesNotifier extends StateNotifier<List<UserCarDraft>> {
  RegisterVehiclesNotifier() : super([]);

  /// Adds a new temporary vehicle draft to the list.
  void addUserCar({
    required String brand,
    required String model,
    required int year,
    required String modelId,
  }) {
    final newUserCar = UserCarDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple generation of a local unique ID
      brand: brand,
      model: model,
      year: year,
      modelId: modelId,
    );
    state = [...state, newUserCar];
  }

  /// Removes a vehicle draft by its index.
  void removeUserCar(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  /// Clears the list.
  void clear() {
    state = [];
  }
}

/// Provider for the list of registration vehicle drafts.
final registerVehiclesProvider =
    StateNotifierProvider<RegisterVehiclesNotifier, List<UserCarDraft>>((ref) {
  return RegisterVehiclesNotifier();
});
