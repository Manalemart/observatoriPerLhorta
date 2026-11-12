import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ca')];

  /// No description provided for @appTitol.
  ///
  /// In ca, this message translates to:
  /// **'Observatori de l\'Horta'**
  String get appTitol;

  /// No description provided for @comuCancelar.
  ///
  /// In ca, this message translates to:
  /// **'Cancel·la'**
  String get comuCancelar;

  /// No description provided for @comuTria.
  ///
  /// In ca, this message translates to:
  /// **'Tria…'**
  String get comuTria;

  /// No description provided for @comuError.
  ///
  /// In ca, this message translates to:
  /// **'Alguna cosa ha fallat. Torna-ho a provar.'**
  String get comuError;

  /// No description provided for @entradaTitol.
  ///
  /// In ca, this message translates to:
  /// **'Entra a l\'Observatori'**
  String get entradaTitol;

  /// No description provided for @entradaExplicacio.
  ///
  /// In ca, this message translates to:
  /// **'T\'enviarem un enllaç al correu, sense contrasenya.'**
  String get entradaExplicacio;

  /// No description provided for @entradaCorreu.
  ///
  /// In ca, this message translates to:
  /// **'Correu electrònic'**
  String get entradaCorreu;

  /// No description provided for @entradaEnviar.
  ///
  /// In ca, this message translates to:
  /// **'Envia\'m l\'enllaç'**
  String get entradaEnviar;

  /// No description provided for @entradaCodiEnviat.
  ///
  /// In ca, this message translates to:
  /// **'Hem enviat un enllaç a {email}. Obri\'l des d\'este mòbil i entraràs directament.'**
  String entradaCodiEnviat(String email);

  /// No description provided for @entradaCodi.
  ///
  /// In ca, this message translates to:
  /// **'Codi de 6 xifres'**
  String get entradaCodi;

  /// No description provided for @entradaVerificar.
  ///
  /// In ca, this message translates to:
  /// **'Entra'**
  String get entradaVerificar;

  /// No description provided for @entradaCodiErroni.
  ///
  /// In ca, this message translates to:
  /// **'El codi no és correcte o ha caducat.'**
  String get entradaCodiErroni;

  /// No description provided for @entradaAltreCorreu.
  ///
  /// In ca, this message translates to:
  /// **'Canvia el correu'**
  String get entradaAltreCorreu;

  /// No description provided for @aliesTitol.
  ///
  /// In ca, this message translates to:
  /// **'Benvinguda a l\'Observatori'**
  String get aliesTitol;

  /// No description provided for @aliesExplicacio.
  ///
  /// In ca, this message translates to:
  /// **'Tria un àlies. La coordinació l\'utilitzarà per a identificar-te.'**
  String get aliesExplicacio;

  /// No description provided for @aliesCamp.
  ///
  /// In ca, this message translates to:
  /// **'Àlies'**
  String get aliesCamp;

  /// No description provided for @aliesDesar.
  ///
  /// In ca, this message translates to:
  /// **'Guarda'**
  String get aliesDesar;

  /// No description provided for @mapaAcosta.
  ///
  /// In ca, this message translates to:
  /// **'Acosta el mapa per a veure els elements'**
  String get mapaAcosta;

  /// No description provided for @mapaSenseDades.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar els elements'**
  String get mapaSenseDades;

  /// No description provided for @mapaEixir.
  ///
  /// In ca, this message translates to:
  /// **'Ix'**
  String get mapaEixir;

  /// No description provided for @mapaAportacions.
  ///
  /// In ca, this message translates to:
  /// **'Les meues aportacions'**
  String get mapaAportacions;

  /// No description provided for @mapaFons.
  ///
  /// In ca, this message translates to:
  /// **'Mapa de fons'**
  String get mapaFons;

  /// No description provided for @fonsTopo.
  ///
  /// In ca, this message translates to:
  /// **'Topogràfic IGN'**
  String get fonsTopo;

  /// No description provided for @fonsPnoa.
  ///
  /// In ca, this message translates to:
  /// **'PNOA màxima actualitat'**
  String get fonsPnoa;

  /// No description provided for @mapaAportar.
  ///
  /// In ca, this message translates to:
  /// **'Aporta'**
  String get mapaAportar;

  /// No description provided for @mapaLaMeuaPosicio.
  ///
  /// In ca, this message translates to:
  /// **'La meua posició'**
  String get mapaLaMeuaPosicio;

  /// No description provided for @gpsNoDisponible.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut obtindre la posició. Comprova el GPS i els permisos.'**
  String get gpsNoDisponible;

  /// No description provided for @fitxaEstat.
  ///
  /// In ca, this message translates to:
  /// **'Estat'**
  String get fitxaEstat;

  /// No description provided for @estatPendent.
  ///
  /// In ca, this message translates to:
  /// **'Pendent de validar'**
  String get estatPendent;

  /// No description provided for @estatValidat.
  ///
  /// In ca, this message translates to:
  /// **'Validat'**
  String get estatValidat;

  /// No description provided for @estatRebutjat.
  ///
  /// In ca, this message translates to:
  /// **'Rebutjat'**
  String get estatRebutjat;

  /// No description provided for @aportarTitol.
  ///
  /// In ca, this message translates to:
  /// **'Nova aportació'**
  String get aportarTitol;

  /// No description provided for @aportarTema.
  ///
  /// In ca, this message translates to:
  /// **'Tema'**
  String get aportarTema;

  /// No description provided for @aportarVariable.
  ///
  /// In ca, this message translates to:
  /// **'Què és?'**
  String get aportarVariable;

  /// No description provided for @aportarCategoria.
  ///
  /// In ca, this message translates to:
  /// **'Categoria'**
  String get aportarCategoria;

  /// No description provided for @aportarQuin.
  ///
  /// In ca, this message translates to:
  /// **'Especifica quin'**
  String get aportarQuin;

  /// No description provided for @aportarDescripcio.
  ///
  /// In ca, this message translates to:
  /// **'Descripció (opcional)'**
  String get aportarDescripcio;

  /// No description provided for @aportarSenseCataleg.
  ///
  /// In ca, this message translates to:
  /// **'Cal connexió la primera vegada per a descarregar el catàleg.'**
  String get aportarSenseCataleg;

  /// No description provided for @aportarInstruccioPunt.
  ///
  /// In ca, this message translates to:
  /// **'Toca el mapa o usa la teua posició.'**
  String get aportarInstruccioPunt;

  /// No description provided for @aportarInstruccioLinia.
  ///
  /// In ca, this message translates to:
  /// **'Toca el mapa o usa la teua posició per a afegir cada punt.'**
  String get aportarInstruccioLinia;

  /// No description provided for @aportarInstruccioPoligon.
  ///
  /// In ca, this message translates to:
  /// **'Toca el mapa o usa la teua posició per a afegir cada vèrtex.'**
  String get aportarInstruccioPoligon;

  /// No description provided for @aportarInstruccioParcela.
  ///
  /// In ca, this message translates to:
  /// **'Toca la parcel·la o usa la teua posició.'**
  String get aportarInstruccioParcela;

  /// No description provided for @aportarUsarPosicio.
  ///
  /// In ca, this message translates to:
  /// **'Usa la meua posició'**
  String get aportarUsarPosicio;

  /// No description provided for @aportarDesfer.
  ///
  /// In ca, this message translates to:
  /// **'Desfés'**
  String get aportarDesfer;

  /// No description provided for @aportarVertexs.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, =1{1 punt} other{{count} punts}}'**
  String aportarVertexs(int count);

  /// No description provided for @aportarCercant.
  ///
  /// In ca, this message translates to:
  /// **'Buscant el recinte SIGPAC…'**
  String get aportarCercant;

  /// No description provided for @aportarRecinte.
  ///
  /// In ca, this message translates to:
  /// **'Recinte SIGPAC: {ref}'**
  String aportarRecinte(String ref);

  /// No description provided for @aportarSenseRecinte.
  ///
  /// In ca, this message translates to:
  /// **'Ací no hi ha cap recinte SIGPAC.'**
  String get aportarSenseRecinte;

  /// No description provided for @aportarRecinteOffline.
  ///
  /// In ca, this message translates to:
  /// **'Sense connexió: el recinte es buscarà en enviar-ho.'**
  String get aportarRecinteOffline;

  /// No description provided for @aportarFerFoto.
  ///
  /// In ca, this message translates to:
  /// **'Fes una foto'**
  String get aportarFerFoto;

  /// No description provided for @aportarGaleria.
  ///
  /// In ca, this message translates to:
  /// **'Galeria'**
  String get aportarGaleria;

  /// No description provided for @aportarFotos.
  ///
  /// In ca, this message translates to:
  /// **'{count, plural, =0{Sense fotos} =1{1 foto} other{{count} fotos}}'**
  String aportarFotos(int count);

  /// No description provided for @aportarLlicencia.
  ///
  /// In ca, this message translates to:
  /// **'En enviar-ho, acceptes publicar les dades amb llicència CC BY 4.0 i les fotos amb CC BY-SA 4.0. Evita que isquen persones o matrícules. Es revisarà abans de publicar-ho.'**
  String get aportarLlicencia;

  /// No description provided for @aportarGuardar.
  ///
  /// In ca, this message translates to:
  /// **'Guarda i envia'**
  String get aportarGuardar;

  /// No description provided for @aportarGuardat.
  ///
  /// In ca, this message translates to:
  /// **'Guardat. Si no hi ha connexió, s\'enviarà més tard.'**
  String get aportarGuardat;

  /// No description provided for @llistaPerEnviar.
  ///
  /// In ca, this message translates to:
  /// **'Per enviar'**
  String get llistaPerEnviar;

  /// No description provided for @llistaEnviades.
  ///
  /// In ca, this message translates to:
  /// **'Enviades'**
  String get llistaEnviades;

  /// No description provided for @llistaBuit.
  ///
  /// In ca, this message translates to:
  /// **'Encara no has fet cap aportació.'**
  String get llistaBuit;

  /// No description provided for @llistaSenseConnexio.
  ///
  /// In ca, this message translates to:
  /// **'Sense connexió: no es poden consultar les enviades.'**
  String get llistaSenseConnexio;

  /// No description provided for @llistaEnviarAra.
  ///
  /// In ca, this message translates to:
  /// **'Envia ara'**
  String get llistaEnviarAra;

  /// No description provided for @llistaEsperant.
  ///
  /// In ca, this message translates to:
  /// **'Esperant connexió'**
  String get llistaEsperant;

  /// No description provided for @llistaReintentar.
  ///
  /// In ca, this message translates to:
  /// **'Torna-ho a provar'**
  String get llistaReintentar;

  /// No description provided for @llistaEsborrar.
  ///
  /// In ca, this message translates to:
  /// **'Esborra'**
  String get llistaEsborrar;

  /// No description provided for @llistaMotiu.
  ///
  /// In ca, this message translates to:
  /// **'Motiu: {motiu}'**
  String llistaMotiu(String motiu);

  /// No description provided for @entradaEsperant.
  ///
  /// In ca, this message translates to:
  /// **'Esperant que obris l\'enllaç…'**
  String get entradaEsperant;

  /// No description provided for @entradaTincCodi.
  ///
  /// In ca, this message translates to:
  /// **'El correu porta un codi de 6 xifres'**
  String get entradaTincCodi;

  /// No description provided for @entradaNoArriba.
  ///
  /// In ca, this message translates to:
  /// **'No t\'arriba? Mira el correu brossa o torna-ho a provar d\'ací a uns minuts.'**
  String get entradaNoArriba;

  /// No description provided for @comuTornarAProvar.
  ///
  /// In ca, this message translates to:
  /// **'Torna-ho a provar'**
  String get comuTornarAProvar;

  /// No description provided for @partidesTitol.
  ///
  /// In ca, this message translates to:
  /// **'Les meues partides'**
  String get partidesTitol;

  /// No description provided for @partidesBuit.
  ///
  /// In ca, this message translates to:
  /// **'Encara no tens cap partida apadrinada. La coordinació te n\'assignarà.'**
  String get partidesBuit;

  /// No description provided for @partidesError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'han pogut carregar les teues partides.'**
  String get partidesError;

  /// No description provided for @partidesResum.
  ///
  /// In ca, this message translates to:
  /// **'{municipi} · {ha} ha · {validats} elements'**
  String partidesResum(String municipi, String ha, int validats);

  /// No description provided for @revisioTitol.
  ///
  /// In ca, this message translates to:
  /// **'Revisió de la partida'**
  String get revisioTitol;

  /// No description provided for @revisioErrorCarrega.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar la partida. Cal connexió.'**
  String get revisioErrorCarrega;

  /// No description provided for @revisioProgres.
  ///
  /// In ca, this message translates to:
  /// **'{fets} de {total} revisats'**
  String revisioProgres(int fets, int total);

  /// No description provided for @revisioNomesPerRevisar.
  ///
  /// In ca, this message translates to:
  /// **'Només el que falta revisar'**
  String get revisioNomesPerRevisar;

  /// No description provided for @revisioElMesProper.
  ///
  /// In ca, this message translates to:
  /// **'El més proper per revisar'**
  String get revisioElMesProper;

  /// No description provided for @revisioSenseSigpac.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut carregar el SIGPAC'**
  String get revisioSenseSigpac;

  /// No description provided for @revisioNumero.
  ///
  /// In ca, this message translates to:
  /// **'Núm. {n} · quadre {q}'**
  String revisioNumero(int n, String q);

  /// No description provided for @revisioEstatPerRevisar.
  ///
  /// In ca, this message translates to:
  /// **'Inventari 2017-2018 · per revisar'**
  String get revisioEstatPerRevisar;

  /// No description provided for @revisioEstatIgual.
  ///
  /// In ca, this message translates to:
  /// **'Revisat: continua igual'**
  String get revisioEstatIgual;

  /// No description provided for @revisioEstatCanviat.
  ///
  /// In ca, this message translates to:
  /// **'Ha canviat: pendent de l\'aportació nova'**
  String get revisioEstatCanviat;

  /// No description provided for @revisioEstatNou.
  ///
  /// In ca, this message translates to:
  /// **'Aportació nova: no entra en la revisió'**
  String get revisioEstatNou;

  /// No description provided for @revisioNomesPadri.
  ///
  /// In ca, this message translates to:
  /// **'Només el padrí o la padrina de la partida el revisa.'**
  String get revisioNomesPadri;

  /// No description provided for @revisioNoRevisable.
  ///
  /// In ca, this message translates to:
  /// **'Aquest element no és de l\'inventari de 2018 o encara no està validat.'**
  String get revisioNoRevisable;

  /// No description provided for @revisioNota.
  ///
  /// In ca, this message translates to:
  /// **'Nota (opcional)'**
  String get revisioNota;

  /// No description provided for @revisioIgual.
  ///
  /// In ca, this message translates to:
  /// **'Continua igual'**
  String get revisioIgual;

  /// No description provided for @revisioCanviat.
  ///
  /// In ca, this message translates to:
  /// **'Ha canviat'**
  String get revisioCanviat;

  /// No description provided for @revisioNoTrobat.
  ///
  /// In ca, this message translates to:
  /// **'No el trobe'**
  String get revisioNoTrobat;

  /// No description provided for @revisioConfirmarNoTrobat.
  ///
  /// In ca, this message translates to:
  /// **'Segur que ja no hi és? Es donarà de baixa: deixarà de veure\'s al mapa, però queda a l\'historial.'**
  String get revisioConfirmarNoTrobat;

  /// No description provided for @revisioFet.
  ///
  /// In ca, this message translates to:
  /// **'Revisió desada'**
  String get revisioFet;

  /// No description provided for @revisioError.
  ///
  /// In ca, this message translates to:
  /// **'No s\'ha pogut desar la revisió. Comprova la connexió.'**
  String get revisioError;

  /// No description provided for @revisioSubstitueix.
  ///
  /// In ca, this message translates to:
  /// **'Substitueix l\'element {n}'**
  String revisioSubstitueix(int n);

  /// No description provided for @revisioSubstitueixNota.
  ///
  /// In ca, this message translates to:
  /// **'Quan es valide, l\'antic quedarà a l\'historial.'**
  String get revisioSubstitueixNota;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return LCa();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
