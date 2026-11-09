import 'package:flutter/material.dart';

const colorMarca = Color(0xFF4A7016);

ThemeData temaApp(Brightness brillo) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: colorMarca, brightness: brillo),
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );

/// Convierte '#rrggbb' (temes.color) en Color.
Color colorDesDeHex(String? hex) {
  final net = (hex ?? '#888888').replaceFirst('#', '');
  return Color(int.parse('FF$net', radix: 16));
}
