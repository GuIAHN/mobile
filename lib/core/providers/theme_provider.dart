import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que controla el modo del tema (claro/oscuro) de la aplicación.
/// Por defecto se inicia en tema oscuro para combinar con la estética de marca.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
