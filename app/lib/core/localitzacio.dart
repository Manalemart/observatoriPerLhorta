/// Idioma actual de la app ('ca', 'es' o 'en'): per a DateFormat / NumberFormat i per als noms
/// del catàleg. El posa l'app en construir-se (MaterialApp.builder).
class Localitzacio {
  static String codi = 'ca';
}

/// El nom en l'idioma actual. El valencià (nom) és la clau i la reserva si falta la traducció.
String nomEnIdioma(String nom, String? es, String? en) => switch (Localitzacio.codi) {
      'es' => es ?? nom,
      'en' => en ?? nom,
      _ => nom,
    };
