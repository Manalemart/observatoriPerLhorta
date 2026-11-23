// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitol => 'Horta Observatory';

  @override
  String get comuCancelar => 'Cancel';

  @override
  String get comuTria => 'Choose…';

  @override
  String get comuError => 'Something went wrong. Please try again.';

  @override
  String get entradaTitol => 'Sign in to the Observatory';

  @override
  String get entradaExplicacio =>
      'We will email you a link, no password needed.';

  @override
  String get entradaCorreu => 'Email';

  @override
  String get entradaEnviar => 'Send me the link';

  @override
  String entradaCodiEnviat(String email) {
    return 'We have sent a link to $email. Open it on this device and you will be signed in.';
  }

  @override
  String get entradaCodi => 'Code from the email';

  @override
  String get entradaVerificar => 'Sign in';

  @override
  String get entradaCodiErroni => 'The code is wrong or has expired.';

  @override
  String get entradaAltreCorreu => 'Change email';

  @override
  String get aliesTitol => 'Welcome to the Observatory';

  @override
  String get aliesExplicacio =>
      'Choose a nickname. The coordinators will use it to identify you.';

  @override
  String get aliesCamp => 'Nickname';

  @override
  String get aliesDesar => 'Save';

  @override
  String get mapaAcosta => 'Zoom in to see the features';

  @override
  String get mapaSenseDades => 'The features could not be loaded';

  @override
  String get mapaEixir => 'Sign out';

  @override
  String get mapaAportacions => 'My contributions';

  @override
  String get mapaFons => 'Base map';

  @override
  String get fonsTopo => 'IGN topographic';

  @override
  String get fonsPnoa => 'PNOA latest imagery';

  @override
  String get mapaAportar => 'Add';

  @override
  String get mapaLaMeuaPosicio => 'My location';

  @override
  String get gpsNoDisponible =>
      'Your location could not be found. Check the GPS and permissions.';

  @override
  String get fitxaEstat => 'Status';

  @override
  String get estatPendent => 'Awaiting validation';

  @override
  String get estatValidat => 'Validated';

  @override
  String get estatRebutjat => 'Rejected';

  @override
  String get aportarTitol => 'New contribution';

  @override
  String get aportarTema => 'Theme';

  @override
  String get aportarVariable => 'What is it?';

  @override
  String get aportarCategoria => 'Category';

  @override
  String get aportarQuin => 'Specify which';

  @override
  String get aportarDescripcio => 'Description (optional)';

  @override
  String get aportarSenseCataleg =>
      'A connection is needed the first time to download the catalogue.';

  @override
  String get aportarInstruccioPunt => 'Tap the map or use your location.';

  @override
  String get aportarInstruccioLinia =>
      'Tap the map or use your location to add each point.';

  @override
  String get aportarInstruccioPoligon =>
      'Tap the map or use your location to add each corner.';

  @override
  String get aportarInstruccioParcela => 'Tap the plot or use your location.';

  @override
  String get aportarUsarPosicio => 'Use my location';

  @override
  String get aportarDesfer => 'Undo';

  @override
  String aportarVertexs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
    );
    return '$_temp0';
  }

  @override
  String get aportarCercant => 'Looking up the SIGPAC plot…';

  @override
  String aportarRecinte(String ref) {
    return 'SIGPAC plot: $ref';
  }

  @override
  String get aportarSenseRecinte => 'There is no SIGPAC plot here.';

  @override
  String get aportarRecinteOffline =>
      'No connection: the plot will be looked up when it is sent.';

  @override
  String get aportarFerFoto => 'Take a photo';

  @override
  String get aportarGaleria => 'Gallery';

  @override
  String aportarFotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
      zero: 'No photos',
    );
    return '$_temp0';
  }

  @override
  String get aportarLlicencia =>
      'By sending it, you agree to publish the data under a CC BY 4.0 licence and the photos under CC BY-SA 4.0. Avoid showing people or number plates. It will be reviewed before publication.';

  @override
  String get aportarGuardar => 'Save and send';

  @override
  String get aportarGuardat =>
      'Saved. If there is no connection, it will be sent later.';

  @override
  String get llistaPerEnviar => 'To send';

  @override
  String get llistaEnviades => 'Sent';

  @override
  String get llistaBuit => 'You haven\'t made any contributions yet.';

  @override
  String get llistaSenseConnexio =>
      'No connection: sent contributions cannot be shown.';

  @override
  String get llistaEnviarAra => 'Send now';

  @override
  String get llistaEsperant => 'Waiting for connection';

  @override
  String get llistaReintentar => 'Try again';

  @override
  String get llistaEsborrar => 'Delete';

  @override
  String llistaMotiu(String motiu) {
    return 'Reason: $motiu';
  }

  @override
  String llistaRevisio(String resultat) {
    return 'Review: $resultat';
  }

  @override
  String get entradaEsperant => 'Waiting for you to open the link…';

  @override
  String get entradaTincCodi => 'The email has a numeric code';

  @override
  String get entradaNoArriba =>
      'Not arriving? Check your spam folder or try again in a few minutes.';

  @override
  String get comuTornarAProvar => 'Try again';

  @override
  String get partidesTitol => 'My partides';

  @override
  String get partidesBuit =>
      'You don\'t sponsor any partida yet. The coordinators will assign you one.';

  @override
  String get partidesError => 'Your partides could not be loaded.';

  @override
  String partidesResum(String municipi, String ha, int validats) {
    return '$municipi · $ha ha · $validats features';
  }

  @override
  String get revisioTitol => 'Partida review';

  @override
  String get revisioErrorCarrega =>
      'The partida could not be loaded. A connection is needed.';

  @override
  String revisioProgres(int fets, int total) {
    return '$fets of $total reviewed';
  }

  @override
  String get revisioNomesPerRevisar => 'Only what still needs review';

  @override
  String get revisioElMesProper => 'Nearest one to review';

  @override
  String get revisioSenseSigpac => 'SIGPAC could not be loaded';

  @override
  String revisioNumero(int n, String q) {
    return 'No. $n · square $q';
  }

  @override
  String get revisioEstatPerRevisar => '2017-2018 inventory · to review';

  @override
  String get revisioEstatIgual => 'Reviewed: unchanged';

  @override
  String get revisioEstatCanviat => 'Changed: new contribution pending';

  @override
  String get revisioEstatNou => 'New contribution: not part of the review';

  @override
  String get revisioNomesPadri => 'Only the partida\'s sponsor reviews it.';

  @override
  String get revisioNoRevisable =>
      'This feature is not from the 2018 inventory or is not validated yet.';

  @override
  String get revisioNota => 'Note (optional)';

  @override
  String get revisioIgual => 'Unchanged';

  @override
  String get revisioCanviat => 'It has changed';

  @override
  String get revisioNoTrobat => 'I can\'t find it';

  @override
  String get revisioConfirmarNoTrobat =>
      'Are you sure it is gone? It will be retired: it will no longer show on the map, but it stays in the history.';

  @override
  String get revisioFet => 'Review saved';

  @override
  String get revisioError =>
      'The review could not be saved. Check your connection.';

  @override
  String revisioSubstitueix(int n) {
    return 'Replaces feature $n';
  }

  @override
  String get revisioSubstitueixNota =>
      'Once validated, the old one will stay in the history.';

  @override
  String get entradaMassaPeticions =>
      'Too many links have been sent in a short time. Wait an hour and try again, or use the last link you received.';

  @override
  String get paquetPreparar => 'Prepare for the field';

  @override
  String paquetPreparat(String mida, String data) {
    return 'On this device · $mida · $data';
  }

  @override
  String paquetBaixant(int percent) {
    return 'Downloading the map… $percent %';
  }

  @override
  String paquetConfirmar(int teseles, String mida) {
    return 'About $teseles orthophoto images (about $mida) will be downloaded so you can work without signal. Wi-Fi is best.';
  }

  @override
  String get paquetBaixar => 'Download';

  @override
  String get paquetActualitzar => 'Update';

  @override
  String get paquetEsborrar => 'Remove from this device';

  @override
  String get paquetConfirmarEsborrar =>
      'This partida\'s map will be removed from the device. Reviews waiting to be sent are not lost.';

  @override
  String paquetIncomplet(int n) {
    return '$n images are missing. Try again to complete it.';
  }

  @override
  String get paquetError => 'It could not be prepared. A connection is needed.';

  @override
  String get paquetErrorServidor =>
      'It could not be prepared: the server returned an error. Please try again later.';

  @override
  String get partidesSenseXarxa =>
      'No connection: showing the last saved list.';

  @override
  String revisioSenseXarxa(String data) {
    return 'No connection · data from $data';
  }

  @override
  String get revisioGuardadaMobil =>
      'Saved on this device. It will be sent when there is signal.';

  @override
  String get revisioPendentEnviar => 'Waiting to be sent';

  @override
  String revisioRebutjada(String motiu) {
    return 'It could not be recorded: $motiu';
  }

  @override
  String get revisioFotoOpcional => 'Photo of how it looks today (optional)';

  @override
  String get revisioTreureFoto => 'Remove the photo';

  @override
  String get revisioLlicenciaFotos =>
      'Photos are published under CC BY-SA 4.0. Avoid showing people or number plates.';

  @override
  String get llegendaTitol => 'Legend';

  @override
  String get llegendaExplicacio =>
      'The symbols from the Observatory\'s guide. Up close, features from the 2017-2018 inventory that have not been reviewed yet look paler.';

  @override
  String get avisosTitol => 'Notifications';

  @override
  String get avisosBuit => 'You have no notifications.';

  @override
  String get avisosSenseConnexio =>
      'No connection: notifications cannot be shown.';

  @override
  String get avisosSenseConnexioUltims =>
      'No connection: showing the last notifications loaded.';

  @override
  String get avisosMarcarTots => 'Mark all as read';

  @override
  String get avisValidat => 'Validated';

  @override
  String get avisRebutjat => 'Rejected';

  @override
  String get avisReobert => 'Pending again';

  @override
  String get avisNovaAportacio => 'New contribution in your partida';

  @override
  String get avisRevisat => 'Reviewed by someone else';

  @override
  String get avisValidarAWeb =>
      'To validate: from the validation panel on the website.';

  @override
  String get avisNoTrobat => 'Not found: retired';

  @override
  String get avisosResumCorreu => 'Daily email digest';

  @override
  String get avisosResumCorreuDetall =>
      'One email a day with the new notifications you haven\'t read';

  @override
  String get avisosResumError =>
      'It could not be saved. Try again with a connection.';

  @override
  String get navMapa => 'Map';

  @override
  String get navPartides => 'Partides';

  @override
  String get navAvisos => 'Notifications';

  @override
  String get navLesMeues => 'Mine';

  @override
  String get perfilTitol => 'My profile';

  @override
  String get perfilLlicencies => 'Licences';

  @override
  String revisioSubstitueixNom(String nom) {
    return 'Replaces «$nom»';
  }

  @override
  String get fitxaPerRevisar => '2018 inventory · to review';

  @override
  String fitxaRevisat(String data) {
    return 'Reviewed on $data';
  }

  @override
  String fitxaAportat(String data) {
    return 'Added on $data';
  }

  @override
  String get fitxaEsEncara => 'Is it still like this?';

  @override
  String get fitxaEsEncaraPadri =>
      'If you are there, confirm it or tell us what has changed.';

  @override
  String get fitxaSiIgual => 'Yes, unchanged';

  @override
  String get fitxaHaCanviatPregunta => 'Has it changed?';

  @override
  String get fitxaAvisansDetall =>
      'Make a new contribution showing how it is today. The partida\'s sponsor will validate it.';

  @override
  String get fitxaObrirPartida => 'Open the partida review';

  @override
  String get comuContinua => 'Continue';

  @override
  String get comuEnrere => 'Back';

  @override
  String aportarPas(int n) {
    return 'Step $n of 3';
  }

  @override
  String get aportarPasQue => 'What have you seen?';

  @override
  String get aportarPasOn => 'Where is it?';

  @override
  String get aportarPasDetalls => 'Photo and details';

  @override
  String get aportarFotosTitol => 'Photos (optional)';

  @override
  String get compteEsborrarTitol => 'Delete the account';

  @override
  String get compteEsborraEs =>
      'If you delete your account, the following is deleted for good:';

  @override
  String get compteEsborraCompte =>
      'the account: your email, nickname and open sessions;';

  @override
  String get compteEsborraPendents =>
      'contributions not yet published (pending or rejected), with their photos;';

  @override
  String get compteEsborraAvisos =>
      'notifications, the email digest and the partides you sponsor;';

  @override
  String get compteEsborraDispositiu =>
      'what is saved on this device: unsent contributions and reviews and downloaded maps.';

  @override
  String get compteEsQueda =>
      'Contributions that have already been validated are part of the public, open inventory (CC BY 4.0, photos CC BY-SA 4.0): they stay, but with no link to you.';

  @override
  String get compteDadesWeb =>
      'If you want a copy of your data first, choose «Download my data» in your profile.';

  @override
  String get compteIrreversible => 'This cannot be undone.';

  @override
  String compteEscriu(String paraula) {
    return 'To confirm, type $paraula';
  }

  @override
  String get compteEsborrarBoto => 'Delete my account';

  @override
  String get compteEsborrant => 'Deleting…';

  @override
  String get compteEsborrarError =>
      'The account could not be deleted. Check your connection and try again, or write to perlhorta@perlhorta.info.';

  @override
  String get compteEsborrat =>
      'Your account has been deleted. Thank you for taking part in the Observatory.';

  @override
  String get entradaContrasenya => 'Password';

  @override
  String get entradaEntrar => 'Sign in';

  @override
  String get entradaContrasenyaErronia => 'The email or password is incorrect.';

  @override
  String get entradaExplicacioRevisio =>
      'Review account: sign in with the password.';

  @override
  String get cercadorTitol => 'Search for a place';

  @override
  String get cercadorEtiqueta => 'Municipality or partida';

  @override
  String get cercadorAjuda => 'Type the name of a municipality or a partida.';

  @override
  String get cercadorCap => 'No municipality or partida with that name.';

  @override
  String get cercadorError => 'The search failed. Check your connection.';

  @override
  String get cercadorMunicipi => 'Municipality';

  @override
  String cercadorPartida(String municipi) {
    return 'Partida · $municipi';
  }

  @override
  String get filtresTitol => 'Filters';

  @override
  String get filtresTot => 'Show everything';

  @override
  String get filtresTemes => 'Themes';

  @override
  String get filtresEpoca => 'Period';

  @override
  String get filtresEpocaTot => 'All';

  @override
  String get filtresEpoca2018 => 'From 2018';

  @override
  String get filtresEpocaNoves => 'New';

  @override
  String get filtresEpocaNota =>
      '«From 2018»: what comes from the 2017-2018 inventory and has not been reviewed yet. «New»: contributions and what has already been reviewed.';

  @override
  String get aliesCanviarTitol => 'Change nickname';

  @override
  String get dadesBoto => 'Download my data';

  @override
  String get dadesPreparant => 'Preparing your data…';

  @override
  String get dadesAssumpte =>
      'My data from the Citizen Observatory of the Horta';

  @override
  String get dadesError =>
      'Your data could not be downloaded. Check your connection.';

  @override
  String get fitxaCompartir => 'Share';

  @override
  String fitxaCompartirText(String nom) {
    return '$nom, on the Citizen Observatory of the Horta';
  }

  @override
  String get guiaPerfil => 'How it works';

  @override
  String get guiaSalta => 'Skip';

  @override
  String get guiaSeguent => 'Next';

  @override
  String get guiaComenca => 'Get started';

  @override
  String guiaPagina(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String get guiaMapaTitol => 'Welcome to the Observatory';

  @override
  String get guiaMapaText =>
      'The open inventory of the Horta de València, built by everyone. The map has more than 7,000 features: irrigation channels, farmhouses, trees, paths… Zoom in and tap one to see its card.';

  @override
  String get guiaAportaTitol => 'Add what you see';

  @override
  String get guiaAportaText =>
      'With «Add» you choose what it is, place it on the map (a point, a line or a plot) and add photos. The coordinators review it before it is published.';

  @override
  String get guiaPartidaTitol => 'Review a partida';

  @override
  String get guiaPartidaText =>
      'If you sponsor a partida, in «Partides» you can download its map and review it in the field, even without signal: what you review is sent automatically when the connection comes back.';

  @override
  String get guiaObertTitol => 'Open data';

  @override
  String get guiaObertText =>
      'What is validated goes into the public inventory, without your name or your email. When your contributions are reviewed, we let you know in «Notifications».';

  @override
  String get llistaAccions => 'Actions';

  @override
  String get llistaCorregir => 'Edit the description';

  @override
  String get llistaCorregirRebutjada =>
      'The coordinators rejected it. Once corrected, it goes back to review.';

  @override
  String get llistaCorregida => 'Description updated.';

  @override
  String get llistaCorregidaRevisio => 'Corrected: back to review.';

  @override
  String get llistaRetirar => 'Withdraw';

  @override
  String get llistaRetirarTitol => 'Withdraw the contribution?';

  @override
  String llistaRetirarText(String titol) {
    return '«$titol» will be deleted, with its photos. This cannot be undone.';
  }

  @override
  String get llistaRetirada => 'Contribution withdrawn.';

  @override
  String get llistaErrorAccio =>
      'It could not be done. Check your connection and try again.';

  @override
  String get perfilIdioma => 'Language';

  @override
  String get idiomaSistema => 'Device language';

  @override
  String get idiomaCa => 'Valencià';

  @override
  String get idiomaEs => 'Castellano';

  @override
  String get idiomaEn => 'English';
}
