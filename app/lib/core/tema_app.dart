import 'package:flutter/material.dart';

/// Identidad del Observatori (manual de 2017), los mismos tokens que la web (web/src/index.css).
/// El verde del manual (#348E00) no llega a 4,5:1 sobre blanco: texto y botones van con #2C7A00.
/// El lima nunca es texto sobre claro; en oscuro es el color de acento (con texto oscuro encima).
class Marca {
  static const verd = Color(0xFF2C7A00);
  static const verdFosc = Color(0xFF215C00);
  static const lima = Color(0xFF9ED100);
  static const limaSuau = Color(0xFFEAF5CC);
  static const limaSuauFosc = Color(0xFF2F3A1A);
  static const marro = Color(0xFF574F46);
  static const text = Color(0xFF3B352F);
  static const sobreLima = Color(0xFF1E1C19);
}

/// Para compatibilidad con código anterior
const colorMarca = Marca.verd;

const _clar = ColorScheme(
  brightness: Brightness.light,
  primary: Marca.verd,
  onPrimary: Colors.white,
  primaryContainer: Marca.limaSuau,
  onPrimaryContainer: Marca.verdFosc,
  secondary: Marca.marro,
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFF3F1EA),
  onSecondaryContainer: Marca.text,
  tertiary: Marca.lima,
  onTertiary: Marca.sobreLima,
  tertiaryContainer: Marca.limaSuau,
  onTertiaryContainer: Marca.verdFosc,
  error: Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF8C1D18),
  surface: Colors.white,
  onSurface: Marca.text,
  onSurfaceVariant: Marca.marro,
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF7F5EF),
  surfaceContainer: Color(0xFFF3F1EA),
  surfaceContainerHigh: Color(0xFFEDEAE2),
  surfaceContainerHighest: Color(0xFFE4E0D6),
  outline: Color(0xFF8A8174),
  outlineVariant: Color(0xFFE4E0D6),
  inverseSurface: Color(0xFF3B352F),
  onInverseSurface: Color(0xFFF1EEE8),
  inversePrimary: Marca.lima,
  shadow: Colors.black,
  scrim: Colors.black,
);

const _fosc = ColorScheme(
  brightness: Brightness.dark,
  primary: Marca.lima,
  onPrimary: Marca.sobreLima,
  primaryContainer: Marca.limaSuauFosc,
  onPrimaryContainer: Color(0xFFD8F08A),
  secondary: Color(0xFFCFC8BD),
  onSecondary: Marca.sobreLima,
  secondaryContainer: Color(0xFF2A2723),
  onSecondaryContainer: Color(0xFFF1EEE8),
  tertiary: Marca.lima,
  onTertiary: Marca.sobreLima,
  tertiaryContainer: Marca.limaSuauFosc,
  onTertiaryContainer: Color(0xFFD8F08A),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  surface: Color(0xFF1E1C19),
  onSurface: Color(0xFFF1EEE8),
  onSurfaceVariant: Color(0xFFCFC8BD),
  surfaceContainerLowest: Color(0xFF171512),
  surfaceContainerLow: Color(0xFF23201C),
  surfaceContainer: Color(0xFF2A2723),
  surfaceContainerHigh: Color(0xFF322E29),
  surfaceContainerHighest: Color(0xFF3A3631),
  outline: Color(0xFF8F877B),
  outlineVariant: Color(0xFF45403A),
  inverseSurface: Color(0xFFF1EEE8),
  onInverseSurface: Color(0xFF3B352F),
  inversePrimary: Marca.verd,
  shadow: Colors.black,
  scrim: Colors.black,
);

const fontMarca = 'Montserrat';
const fontProsa = 'SourceSerif4';

ThemeData temaApp(Brightness brillo) {
  final c = brillo == Brightness.light ? _clar : _fosc;
  final base = ThemeData(colorScheme: c, useMaterial3: true, fontFamily: fontMarca);
  final tt = base.textTheme;
  const pindola = StadiumBorder();
  const alt = Size(64, 52);
  const etiquetaBoto = TextStyle(fontFamily: fontMarca, fontSize: 15, fontWeight: FontWeight.w700);
  final radi = BorderRadius.circular(14);
  return base.copyWith(
    scaffoldBackgroundColor: c.surface,
    textTheme: tt.copyWith(
      headlineSmall: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.onSurface,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: fontMarca,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: c.onSurfaceVariant,
      ),
      // La vora lima de la capçalera de la web
      shape: const Border(bottom: BorderSide(color: Marca.lima, width: 4)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.primaryContainer,
      minWidth: 88,
      selectedIconTheme: IconThemeData(color: c.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: c.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(fontFamily: fontMarca, fontSize: 12, fontWeight: FontWeight.w800, color: c.onSurface),
      unselectedLabelTextStyle: TextStyle(fontFamily: fontMarca, fontSize: 12, fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.primaryContainer,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: fontMarca,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: alt, shape: pindola, textStyle: etiquetaBoto, padding: const EdgeInsets.symmetric(horizontal: 24)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: alt,
        shape: pindola,
        textStyle: etiquetaBoto,
        foregroundColor: c.primary,
        side: BorderSide(color: c.primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 44), textStyle: etiquetaBoto, shape: pindola),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.surface,
      foregroundColor: c.onSurface,
      extendedTextStyle: etiquetaBoto,
      shape: const StadiumBorder(),
      elevation: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: radi, borderSide: BorderSide(color: c.outline, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: radi, borderSide: BorderSide(color: c.outline, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: radi, borderSide: BorderSide(color: c.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      color: c.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.outlineVariant)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.outlineVariant,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(backgroundColor: c.surface, surfaceTintColor: Colors.transparent),
    dividerTheme: DividerThemeData(color: c.outlineVariant, space: 1),
    listTileTheme: ListTileThemeData(
      titleTextStyle: TextStyle(fontFamily: fontMarca, fontSize: 15, fontWeight: FontWeight.w700, color: c.onSurface),
      subtitleTextStyle: TextStyle(fontFamily: fontMarca, fontSize: 13, color: c.onSurfaceVariant, height: 1.35),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
  );
}

/// Texto explicativo (la serif de la web).
TextStyle estilProsa(BuildContext context) => TextStyle(
      fontFamily: fontProsa,
      fontSize: 16,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface,
    );

/// Título de pantalla en mayúsculas, como los encabezados de la web.
class TitolBarra extends StatelessWidget {
  const TitolBarra(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase());
}

/// Etiqueta de sección (los h2 de la web): mayúsculas, pequeña y espaciada.
class EtiquetaSeccio extends StatelessWidget {
  const EtiquetaSeccio(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 8)});
  final String text;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Convierte '#rrggbb' (temes.color) en Color.
Color colorDesDeHex(String? hex) {
  final net = (hex ?? '#888888').replaceFirst('#', '');
  return Color(int.parse('FF$net', radix: 16));
}
