// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class LCa extends L {
  LCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitol => 'Observatori de l\'Horta';

  @override
  String get comuCancelar => 'Cancel·la';

  @override
  String get comuTria => 'Tria…';

  @override
  String get comuError => 'Alguna cosa ha fallat. Torna-ho a provar.';

  @override
  String get entradaTitol => 'Entra a l\'Observatori';

  @override
  String get entradaExplicacio =>
      'T\'enviarem un codi al correu, sense contrasenya.';

  @override
  String get entradaCorreu => 'Correu electrònic';

  @override
  String get entradaEnviar => 'Envia\'m el codi';

  @override
  String entradaCodiEnviat(String email) {
    return 'Hem enviat un codi a $email.';
  }

  @override
  String get entradaCodi => 'Codi de 6 xifres';

  @override
  String get entradaVerificar => 'Entra';

  @override
  String get entradaCodiErroni => 'El codi no és correcte o ha caducat.';

  @override
  String get entradaAltreCorreu => 'Canvia el correu';

  @override
  String get aliesTitol => 'Benvinguda a l\'Observatori';

  @override
  String get aliesExplicacio =>
      'Tria un àlies. La coordinació l\'utilitzarà per a identificar-te.';

  @override
  String get aliesCamp => 'Àlies';

  @override
  String get aliesDesar => 'Guarda';

  @override
  String get mapaAcosta => 'Acosta el mapa per a veure els elements';

  @override
  String get mapaSenseDades => 'No s\'han pogut carregar els elements';

  @override
  String get mapaEixir => 'Ix';

  @override
  String get mapaAportacions => 'Les meues aportacions';

  @override
  String get mapaFons => 'Mapa de fons';

  @override
  String get fonsTopo => 'Topogràfic IGN';

  @override
  String get fonsPnoa => 'PNOA màxima actualitat';

  @override
  String get fonsOsm => 'OpenStreetMap';

  @override
  String get mapaAportar => 'Aporta';

  @override
  String get mapaLaMeuaPosicio => 'La meua posició';

  @override
  String get gpsNoDisponible =>
      'No s\'ha pogut obtindre la posició. Comprova el GPS i els permisos.';

  @override
  String get fitxaEstat => 'Estat';

  @override
  String get estatPendent => 'Pendent de validar';

  @override
  String get estatValidat => 'Validat';

  @override
  String get estatRebutjat => 'Rebutjat';

  @override
  String get aportarTitol => 'Nova aportació';

  @override
  String get aportarTema => 'Tema';

  @override
  String get aportarVariable => 'Què és?';

  @override
  String get aportarCategoria => 'Categoria';

  @override
  String get aportarQuin => 'Especifica quin';

  @override
  String get aportarDescripcio => 'Descripció (opcional)';

  @override
  String get aportarSenseCataleg =>
      'Cal connexió la primera vegada per a descarregar el catàleg.';

  @override
  String get aportarInstruccioPunt => 'Toca el mapa o usa la teua posició.';

  @override
  String get aportarInstruccioLinia =>
      'Toca el mapa o usa la teua posició per a afegir cada punt.';

  @override
  String get aportarInstruccioPoligon =>
      'Toca el mapa o usa la teua posició per a afegir cada vèrtex.';

  @override
  String get aportarInstruccioParcela =>
      'Toca la parcel·la o usa la teua posició.';

  @override
  String get aportarUsarPosicio => 'Usa la meua posició';

  @override
  String get aportarDesfer => 'Desfés';

  @override
  String aportarVertexs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count punts',
      one: '1 punt',
    );
    return '$_temp0';
  }

  @override
  String get aportarCercant => 'Buscant el recinte SIGPAC…';

  @override
  String aportarRecinte(String ref) {
    return 'Recinte SIGPAC: $ref';
  }

  @override
  String get aportarSenseRecinte => 'Ací no hi ha cap recinte SIGPAC.';

  @override
  String get aportarRecinteOffline =>
      'Sense connexió: el recinte es buscarà en enviar-ho.';

  @override
  String get aportarFerFoto => 'Fes una foto';

  @override
  String get aportarGaleria => 'Galeria';

  @override
  String aportarFotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
      zero: 'Sense fotos',
    );
    return '$_temp0';
  }

  @override
  String get aportarLlicencia =>
      'En enviar-ho, acceptes publicar les dades amb llicència CC BY 4.0 i les fotos amb CC BY-SA 4.0. Evita que isquen persones o matrícules. Es revisarà abans de publicar-ho.';

  @override
  String get aportarGuardar => 'Guarda i envia';

  @override
  String get aportarGuardat =>
      'Guardat. Si no hi ha connexió, s\'enviarà més tard.';

  @override
  String get llistaPerEnviar => 'Per enviar';

  @override
  String get llistaEnviades => 'Enviades';

  @override
  String get llistaBuit => 'Encara no has fet cap aportació.';

  @override
  String get llistaSenseConnexio =>
      'Sense connexió: no es poden consultar les enviades.';

  @override
  String get llistaEnviarAra => 'Envia ara';

  @override
  String get llistaEsperant => 'Esperant connexió';

  @override
  String get llistaReintentar => 'Torna-ho a provar';

  @override
  String get llistaEsborrar => 'Esborra';

  @override
  String llistaMotiu(String motiu) {
    return 'Motiu: $motiu';
  }
}
