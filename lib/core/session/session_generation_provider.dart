import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cambia cada vez que la identidad autenticada cruza un límite de sesión.
/// Los datos privados observan este valor para descartar su generación previa
/// sin acoplarse directamente al almacenamiento seguro ni al flujo de login.
final sessionGenerationProvider = StateProvider<int>((ref) => 0);
