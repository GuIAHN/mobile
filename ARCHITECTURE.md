# Arquitectura del Proyecto

## Contexto

App móvil en **Flutter** que consume una **API REST externa** (NestJS + PostgreSQL).

> ⚠️ Esta app **NO contiene lógica de servidor ni base de datos**.
> Solo hace solicitudes HTTP a la API, gestiona estado y renderiza la UI.
> Toda la persistencia real vive en el backend; aquí solo se almacena el token (JWT) de forma segura.

## Stack

| Área         | Librería              |
|--------------|-----------------------|
| Estado       | `flutter_riverpod`    |
| HTTP         | `dio`                 |
| Navegación   | `go_router`           |
| Tokens       | `flutter_secure_storage` |
| Errores      | `dartz` (Either)      |
| Comparación  | `equatable`           |

## Arquitectura: Clean Architecture (feature-first)

Cada feature se divide en 3 capas:

```
presentation  ──►  domain  ◄──  data
```

### Regla de dependencias (NUNCA romper)
- `presentation` → puede usar `domain`.
- `data` → puede usar `domain`.
- `domain` → **no depende de nada** (ni Flutter, ni Dio, ni data).
- Una feature **NO importa** archivos de otra feature. Lo compartido va en `core/` o `shared/`.

### Responsabilidad de cada capa

| Capa            | Qué contiene | Conoce HTTP/JSON? | Conoce Flutter? |
|-----------------|--------------|-------------------|-----------------|
| `data/`         | Solicitudes a la API, models con `fromJson` | ✅ Sí | ❌ No |
| `domain/`       | Reglas de negocio, entities, contratos | ❌ No | ❌ No |
| `presentation/` | Pantallas, widgets, estado (providers) | ❌ No | ✅ Sí |

### Flujo de datos

```
Page → Provider → UseCase → Repository (contrato) → RepositoryImpl → RemoteDataSource → 🌐 API
```

## Estructura de carpetas

```
lib/
├── main.dart
├── app.dart
│
├── core/                  # Código transversal (implementado)
│   ├── config/            # env.dart, app_config.dart
│   ├── theme/             # colores, tipografía, espaciados ("CSS" global)
│   ├── network/           # dio_client, endpoints, interceptors
│   ├── error/             # failures, exceptions, error_mapper
│   ├── router/            # go_router
│   ├── storage/           # secure_storage (tokens)
│   └── utils/             # validators, formatters, extensions
│
├── shared/
│   └── widgets/           # Componentes reutilizables en TODA la app
│
└── features/              # Cada módulo de negocio (3 capas)
    └── <feature>/
        ├── data/
        │   ├── datasources/   # Llamadas HTTP a la API
        │   ├── models/        # fromJson / toJson
        │   └── repositories/  # Implementación del contrato
        ├── domain/
        │   ├── entities/      # Objetos de negocio limpios
        │   ├── repositories/  # Contratos (abstract)
        │   └── usecases/      # Casos de uso
        └── presentation/
            ├── pages/         # Pantallas completas
            ├── widgets/       # Componentes de esta feature
            └── providers/     # Estado (Riverpod)
```

## Convenciones

- **Archivos:** `snake_case.dart`
- **Clases:** `PascalCase`
- **Models vs Entities:** los `models` (data) tienen `fromJson`/`toJson` y conocen la API. Las `entities` (domain) son objetos limpios sin saber nada de JSON.
- **UI = Widgets.** No hay HTML/CSS. Los estilos globales viven en `core/theme/`.
- **Componente reutilizable en varias features** → `shared/widgets/`.
- **Componente de una sola feature** → `features/<feature>/presentation/widgets/`.

---

# Plantilla de una Feature (MOLDE OBLIGATORIO)

> Toda feature nueva debe seguir EXACTAMENTE estos archivos.
> Ejemplo con `vehicles`. Copiar y adaptar para cada módulo.

### `domain/entities/vehicle.dart`
```dart
import 'package:equatable/equatable.dart';

class Vehicle extends Equatable {
  final String id;
  final String brand;
  final String model;
  final int year;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  @override
  List<Object?> get props => [id, brand, model, year];
}
```

### `domain/repositories/vehicle_repository.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<Either<Failure, List<Vehicle>>> getVehicles();
}
```

### `domain/usecases/get_vehicles_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vehicle.dart';
import '../repositories/vehicle_repository.dart';

class GetVehiclesUseCase {
  final VehicleRepository repository;
  GetVehiclesUseCase(this.repository);

  Future<Either<Failure, List<Vehicle>>> call() => repository.getVehicles();
}
```

### `data/models/vehicle_model.dart`
```dart
import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
      };
}
```

### `data/datasources/vehicle_remote_datasource.dart`
```dart
import 'package:dio/dio.dart';
import '../models/vehicle_model.dart';

class VehicleRemoteDataSource {
  final Dio dio;
  VehicleRemoteDataSource(this.dio);

  Future<List<VehicleModel>> getVehicles() async {
    final response = await dio.get('/vehicles'); // 🌐 solicitud a la API
    return (response.data as List)
        .map((json) => VehicleModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

### `data/repositories/vehicle_repository_impl.dart`
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_datasource.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;
  VehicleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async {
    try {
      final vehicles = await remoteDataSource.getVehicles();
      return Right(vehicles);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
```

### `presentation/providers/vehicles_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicles_usecase.dart';

final vehiclesProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final usecase = ref.watch(getVehiclesUseCaseProvider);
  final result = await usecase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (vehicles) => vehicles,
  );
});
```

### `presentation/pages/vehicles_list_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/vehicle_card.dart';
import '../providers/vehicles_provider.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/error_view.dart';

class VehiclesListPage extends ConsumerWidget {
  const VehiclesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Vehículos')),
      body: state.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (vehicles) => ListView.builder(
          itemCount: vehicles.length,
          itemBuilder: (_, i) => VehicleCard(vehicle: vehicles[i]),
        ),
      ),
    );
  }
}
```