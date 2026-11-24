// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get appTitol => 'Observatorio de la Huerta';

  @override
  String get comuCancelar => 'Cancela';

  @override
  String get comuTria => 'Elige…';

  @override
  String get comuError => 'Algo ha fallado. Vuelve a intentarlo.';

  @override
  String get entradaTitol => 'Entra en el Observatorio';

  @override
  String get entradaExplicacio =>
      'Te enviaremos un enlace al correo, sin contraseña.';

  @override
  String get entradaCorreu => 'Correo electrónico';

  @override
  String get entradaEnviar => 'Envíame el enlace';

  @override
  String entradaCodiEnviat(String email) {
    return 'Hemos enviado un enlace a $email. Ábrelo desde este dispositivo y entrarás directamente.';
  }

  @override
  String get entradaCodi => 'Código del correo';

  @override
  String get entradaVerificar => 'Entra';

  @override
  String get entradaCodiErroni => 'El código no es correcto o ha caducado.';

  @override
  String get entradaAltreCorreu => 'Cambia el correo';

  @override
  String get aliesTitol => 'Bienvenida al Observatorio';

  @override
  String get aliesExplicacio =>
      'Elige un alias. La coordinación lo usará para identificarte.';

  @override
  String get aliesCamp => 'Alias';

  @override
  String get aliesDesar => 'Guarda';

  @override
  String get mapaAcosta => 'Acerca el mapa para ver los elementos';

  @override
  String get mapaSenseDades => 'No se han podido cargar los elementos';

  @override
  String get mapaEixir => 'Sal';

  @override
  String get mapaAportacions => 'Mis aportaciones';

  @override
  String get mapaFons => 'Mapa de fondo';

  @override
  String get fonsTopo => 'Topográfico IGN';

  @override
  String get fonsPnoa => 'PNOA máxima actualidad';

  @override
  String get mapaAportar => 'Aporta';

  @override
  String get mapaLaMeuaPosicio => 'Mi posición';

  @override
  String get gpsNoDisponible =>
      'No se ha podido obtener la posición. Comprueba el GPS y los permisos.';

  @override
  String get fitxaEstat => 'Estado';

  @override
  String get estatPendent => 'Pendiente de validar';

  @override
  String get estatValidat => 'Validado';

  @override
  String get estatRebutjat => 'Rechazado';

  @override
  String get aportarTitol => 'Nueva aportación';

  @override
  String get aportarTema => 'Tema';

  @override
  String get aportarVariable => '¿Qué es?';

  @override
  String get aportarCategoria => 'Categoría';

  @override
  String get aportarQuin => 'Especifica cuál';

  @override
  String get aportarDescripcio => 'Descripción (opcional)';

  @override
  String get aportarSenseCataleg =>
      'Hace falta conexión la primera vez para descargar el catálogo.';

  @override
  String get aportarInstruccioPunt => 'Toca el mapa o usa tu posición.';

  @override
  String get aportarInstruccioLinia =>
      'Toca el mapa o usa tu posición para añadir cada punto.';

  @override
  String get aportarInstruccioPoligon =>
      'Toca el mapa o usa tu posición para añadir cada vértice.';

  @override
  String get aportarInstruccioParcela => 'Toca la parcela o usa tu posición.';

  @override
  String get aportarUsarPosicio => 'Usa mi posición';

  @override
  String get aportarDesfer => 'Deshaz';

  @override
  String aportarVertexs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get aportarCercant => 'Buscando el recinto SIGPAC…';

  @override
  String aportarRecinte(String ref) {
    return 'Recinto SIGPAC: $ref';
  }

  @override
  String get aportarSenseRecinte => 'Aquí no hay ningún recinto SIGPAC.';

  @override
  String get aportarRecinteOffline =>
      'Sin conexión: el recinto se buscará al enviarlo.';

  @override
  String get aportarFerFoto => 'Haz una foto';

  @override
  String get aportarGaleria => 'Galería';

  @override
  String aportarFotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
      zero: 'Sin fotos',
    );
    return '$_temp0';
  }

  @override
  String get aportarLlicencia =>
      'Al enviarlo, aceptas publicar los datos con licencia CC BY 4.0 y las fotos con CC BY-SA 4.0. Evita que salgan personas o matrículas. Se revisará antes de publicarlo.';

  @override
  String get aportarGuardar => 'Guarda y envía';

  @override
  String get aportarGuardat =>
      'Guardado. Si no hay conexión, se enviará más tarde.';

  @override
  String get llistaPerEnviar => 'Por enviar';

  @override
  String get llistaEnviades => 'Enviadas';

  @override
  String get llistaBuit => 'Aún no has hecho ninguna aportación.';

  @override
  String get llistaSenseConnexio =>
      'Sin conexión: no se pueden consultar las enviadas.';

  @override
  String get llistaEnviarAra => 'Envía ahora';

  @override
  String get llistaEsperant => 'Esperando conexión';

  @override
  String get llistaReintentar => 'Vuelve a intentarlo';

  @override
  String get llistaEsborrar => 'Borra';

  @override
  String llistaMotiu(String motiu) {
    return 'Motivo: $motiu';
  }

  @override
  String llistaRevisio(String resultat) {
    return 'Revisión: $resultat';
  }

  @override
  String get entradaEsperant => 'Esperando a que abras el enlace…';

  @override
  String get entradaTincCodi => 'El correo trae un código numérico';

  @override
  String get entradaNoArriba =>
      '¿No te llega? Mira el correo no deseado o vuelve a intentarlo dentro de unos minutos.';

  @override
  String get comuTornarAProvar => 'Vuelve a intentarlo';

  @override
  String get partidesTitol => 'Mis partidas';

  @override
  String get partidesBuit =>
      'Aún no tienes ninguna partida apadrinada. La coordinación te asignará una.';

  @override
  String get partidesError => 'No se han podido cargar tus partidas.';

  @override
  String partidesResum(String municipi, String ha, int validats) {
    return '$municipi · $ha ha · $validats elementos';
  }

  @override
  String get revisioTitol => 'Revisión de la partida';

  @override
  String get revisioErrorCarrega =>
      'No se ha podido cargar la partida. Hace falta conexión.';

  @override
  String revisioProgres(int fets, int total) {
    return '$fets de $total revisados';
  }

  @override
  String get revisioNomesPerRevisar => 'Solo lo que falta revisar';

  @override
  String get revisioElMesProper => 'El más cercano por revisar';

  @override
  String get revisioSenseSigpac => 'No se ha podido cargar el SIGPAC';

  @override
  String revisioNumero(int n, String q) {
    return 'N.º $n · cuadro $q';
  }

  @override
  String get revisioEstatPerRevisar => 'Inventario 2017-2018 · por revisar';

  @override
  String get revisioEstatIgual => 'Revisado: sigue igual';

  @override
  String get revisioEstatCanviat =>
      'Ha cambiado: pendiente de la aportación nueva';

  @override
  String get revisioEstatNou => 'Aportación nueva: no entra en la revisión';

  @override
  String get revisioNomesPadri =>
      'Solo el padrino o la madrina de la partida lo revisa.';

  @override
  String get revisioNoRevisable =>
      'Este elemento no es del inventario de 2018 o aún no está validado.';

  @override
  String get revisioNota => 'Nota (opcional)';

  @override
  String get revisioIgual => 'Sigue igual';

  @override
  String get revisioCanviat => 'Ha cambiado';

  @override
  String get revisioNoTrobat => 'No lo encuentro';

  @override
  String get revisioConfirmarNoTrobat =>
      '¿Seguro que ya no está? Se dará de baja: dejará de verse en el mapa, pero queda en el historial.';

  @override
  String get revisioFet => 'Revisión guardada';

  @override
  String get revisioError =>
      'No se ha podido guardar la revisión. Comprueba la conexión.';

  @override
  String revisioSubstitueix(int n) {
    return 'Sustituye al elemento $n';
  }

  @override
  String get revisioSubstitueixNota =>
      'Cuando se valide, el antiguo quedará en el historial.';

  @override
  String get entradaMassaPeticions =>
      'Se han enviado demasiados enlaces en poco tiempo. Espera una hora y vuelve a intentarlo, o usa el último enlace que te ha llegado.';

  @override
  String get paquetPreparar => 'Preparar para el campo';

  @override
  String paquetPreparat(String mida, String data) {
    return 'En el dispositivo · $mida · $data';
  }

  @override
  String paquetBaixant(int percent) {
    return 'Descargando el mapa… $percent %';
  }

  @override
  String paquetConfirmar(int teseles, String mida) {
    return 'Se descargarán unas $teseles imágenes de ortofoto (unos $mida) para trabajar sin cobertura. Mejor con wifi.';
  }

  @override
  String get paquetBaixar => 'Descargar';

  @override
  String get paquetActualitzar => 'Actualizar';

  @override
  String get paquetEsborrar => 'Borrar del dispositivo';

  @override
  String get paquetConfirmarEsborrar =>
      'Se borrará el mapa de esta partida del dispositivo. Las revisiones pendientes de enviar no se pierden.';

  @override
  String paquetIncomplet(int n) {
    return 'Han faltado $n imágenes. Vuelve a intentarlo para completarlo.';
  }

  @override
  String get paquetError => 'No se ha podido preparar. Hace falta conexión.';

  @override
  String get paquetErrorServidor =>
      'No se ha podido preparar: el servidor ha dado un error. Vuelve a intentarlo más tarde.';

  @override
  String get partidesSenseXarxa =>
      'Sin conexión: se muestra la última lista guardada.';

  @override
  String revisioSenseXarxa(String data) {
    return 'Sin conexión · datos del $data';
  }

  @override
  String get revisioGuardadaMobil =>
      'Guardado en el dispositivo. Se enviará cuando haya cobertura.';

  @override
  String get revisioPendentEnviar => 'Pendiente de enviar';

  @override
  String revisioRebutjada(String motiu) {
    return 'No se ha podido registrar: $motiu';
  }

  @override
  String get revisioFotoOpcional => 'Foto de cómo está hoy (opcional)';

  @override
  String get revisioTreureFoto => 'Quita la foto';

  @override
  String get revisioLlicenciaFotos =>
      'Las fotos se publican con CC BY-SA 4.0. Evita que salgan personas o matrículas.';

  @override
  String get llegendaTitol => 'Leyenda';

  @override
  String get llegendaExplicacio =>
      'Los símbolos de la guía del Observatorio. De cerca, lo que es del inventario de 2017-2018 y aún no se ha revisado se ve más pálido.';

  @override
  String get avisosTitol => 'Avisos';

  @override
  String get avisosBuit => 'No tienes ningún aviso.';

  @override
  String get avisosSenseConnexio =>
      'Sin conexión: no se pueden consultar los avisos.';

  @override
  String get avisosSenseConnexioUltims =>
      'Sin conexión: se muestran los últimos avisos cargados.';

  @override
  String get avisosMarcarTots => 'Marca todo como leído';

  @override
  String get avisValidat => 'Validada';

  @override
  String get avisRebutjat => 'Rechazada';

  @override
  String get avisReobert => 'Vuelve a estar pendiente';

  @override
  String get avisNovaAportacio => 'Aportación nueva en tu partida';

  @override
  String get avisRevisat => 'Revisado por otra persona';

  @override
  String get avisValidarAWeb =>
      'Para validar: desde el panel de validación de la web.';

  @override
  String get avisNoTrobat => 'No se ha encontrado: dado de baja';

  @override
  String get avisosResumCorreu => 'Resumen diario por correo';

  @override
  String get avisosResumCorreuDetall =>
      'Un correo al día con los avisos nuevos que no hayas leído';

  @override
  String get avisosResumError =>
      'No se ha podido guardar. Vuelve a intentarlo con conexión.';

  @override
  String get navMapa => 'Mapa';

  @override
  String get navPartides => 'Partidas';

  @override
  String get navAvisos => 'Avisos';

  @override
  String get navLesMeues => 'Las mías';

  @override
  String get perfilTitol => 'Mi perfil';

  @override
  String get perfilLlicencies => 'Licencias';

  @override
  String revisioSubstitueixNom(String nom) {
    return 'Sustituye a «$nom»';
  }

  @override
  String get fitxaPerRevisar => 'Inventario 2018 · por revisar';

  @override
  String fitxaRevisat(String data) {
    return 'Revisado el $data';
  }

  @override
  String fitxaAportat(String data) {
    return 'Aportado el $data';
  }

  @override
  String get fitxaEsEncara => '¿Sigue así?';

  @override
  String get fitxaEsEncaraPadri =>
      'Si estás delante, confírmalo o cuenta qué ha cambiado.';

  @override
  String get fitxaSiIgual => 'Sí, igual';

  @override
  String get fitxaHaCanviatPregunta => '¿Ha cambiado?';

  @override
  String get fitxaAvisansDetall =>
      'Haz una aportación nueva con cómo está hoy. La validará el padrino o la madrina de la partida.';

  @override
  String get fitxaObrirPartida => 'Abre la revisión de la partida';

  @override
  String get comuContinua => 'Continúa';

  @override
  String get comuEnrere => 'Atrás';

  @override
  String aportarPas(int n) {
    return 'Paso $n de 3';
  }

  @override
  String get aportarPasQue => '¿Qué has visto?';

  @override
  String get aportarPasOn => '¿Dónde está?';

  @override
  String get aportarPasDetalls => 'Foto y detalles';

  @override
  String get aportarFotosTitol => 'Fotos (opcionales)';

  @override
  String get compteEsborrarTitol => 'Borra la cuenta';

  @override
  String get compteEsborraEs => 'Si borras la cuenta, se borra para siempre:';

  @override
  String get compteEsborraCompte =>
      'la cuenta: el correo, el alias y las sesiones abiertas;';

  @override
  String get compteEsborraPendents =>
      'las aportaciones que aún no se han publicado (pendientes o rechazadas), con sus fotos;';

  @override
  String get compteEsborraAvisos =>
      'los avisos, el resumen por correo y las partidas que apadrinas;';

  @override
  String get compteEsborraDispositiu =>
      'lo que hay guardado en este dispositivo: aportaciones y revisiones sin enviar y los mapas descargados.';

  @override
  String get compteEsQueda =>
      'Las aportaciones ya validadas forman parte del inventario público y abierto (CC BY 4.0, y las fotos CC BY-SA 4.0): se quedan, pero sin ningún vínculo contigo.';

  @override
  String get compteDadesWeb =>
      'Si antes quieres una copia de tus datos, elige «Descarga mis datos» en el perfil.';

  @override
  String get compteIrreversible => 'No se puede deshacer.';

  @override
  String compteEscriu(String paraula) {
    return 'Para confirmarlo, escribe $paraula';
  }

  @override
  String get compteEsborrarBoto => 'Borra mi cuenta';

  @override
  String get compteEsborrant => 'Borrando…';

  @override
  String get compteEsborrarError =>
      'No se ha podido borrar la cuenta. Comprueba la conexión y vuelve a intentarlo, o escribe a perlhorta@perlhorta.info.';

  @override
  String get compteEsborrat =>
      'Se ha borrado la cuenta. Gracias por haber participado en el Observatorio.';

  @override
  String get entradaContrasenya => 'Contraseña';

  @override
  String get entradaEntrar => 'Entra';

  @override
  String get entradaContrasenyaErronia =>
      'El correo o la contraseña no son correctos.';

  @override
  String get entradaExplicacioRevisio =>
      'Cuenta de revisión: entra con la contraseña.';

  @override
  String get cercadorTitol => 'Busca un lugar';

  @override
  String get cercadorEtiqueta => 'Municipio o partida';

  @override
  String get cercadorAjuda =>
      'Escribe el nombre de un municipio o de una partida.';

  @override
  String get cercadorCap => 'Ningún municipio ni partida con ese nombre.';

  @override
  String get cercadorError => 'No se ha podido buscar. Comprueba la conexión.';

  @override
  String get cercadorMunicipi => 'Municipio';

  @override
  String cercadorPartida(String municipi) {
    return 'Partida · $municipi';
  }

  @override
  String get filtresTitol => 'Filtros';

  @override
  String get filtresTot => 'Muéstralo todo';

  @override
  String get filtresTemes => 'Temas';

  @override
  String get filtresEpoca => 'Época';

  @override
  String get filtresEpocaTot => 'Todo';

  @override
  String get filtresEpoca2018 => 'De 2018';

  @override
  String get filtresEpocaNoves => 'Nuevas';

  @override
  String get filtresEpocaNota =>
      '«De 2018»: lo que viene del inventario de 2017-2018 y aún no se ha revisado. «Nuevas»: las aportaciones y lo que ya se ha revisado.';

  @override
  String get aliesCanviarTitol => 'Cambia el alias';

  @override
  String get dadesBoto => 'Descarga mis datos';

  @override
  String get dadesPreparant => 'Preparando tus datos…';

  @override
  String get dadesAssumpte =>
      'Mis datos del Observatorio Ciudadano de la Huerta';

  @override
  String get dadesError =>
      'No se han podido descargar los datos. Comprueba la conexión.';

  @override
  String get fitxaCompartir => 'Comparte';

  @override
  String fitxaCompartirText(String nom) {
    return '$nom, en el Observatorio Ciudadano de la Huerta';
  }

  @override
  String get guiaPerfil => 'Cómo funciona';

  @override
  String get guiaSalta => 'Salta';

  @override
  String get guiaSeguent => 'Siguiente';

  @override
  String get guiaComenca => 'Empieza';

  @override
  String guiaPagina(int n, int total) {
    return 'Página $n de $total';
  }

  @override
  String get guiaMapaTitol => 'Bienvenida al Observatorio';

  @override
  String get guiaMapaText =>
      'El inventario abierto de la Huerta de Valencia, hecho entre todas y todos. En el mapa hay más de 7.000 elementos: acequias, alquerías, árboles, caminos… Acércate y toca uno para ver su ficha.';

  @override
  String get guiaAportaTitol => 'Aporta lo que ves';

  @override
  String get guiaAportaText =>
      'Con «Aporta» eliges qué es, lo sitúas en el mapa (un punto, una línea o una parcela) y añades fotos. La coordinación lo revisa antes de publicarlo.';

  @override
  String get guiaPartidaTitol => 'Revisa una partida';

  @override
  String get guiaPartidaText =>
      'Si apadrinas una partida, en «Partidas» puedes descargar su mapa y revisarla en el campo, aunque no haya cobertura: lo que revises se envía solo al volver la conexión.';

  @override
  String get guiaObertTitol => 'Datos abiertos';

  @override
  String get guiaObertText =>
      'Lo que se valida pasa al inventario público, sin tu nombre ni tu correo. Cuando revisen tus aportaciones, te avisamos en «Avisos».';

  @override
  String get llistaAccions => 'Acciones';

  @override
  String get llistaCorregir => 'Corrige la descripción';

  @override
  String get llistaCorregirRebutjada =>
      'La coordinación la rechazó. Al corregirla, vuelve a revisión.';

  @override
  String get llistaCorregida => 'Descripción corregida.';

  @override
  String get llistaCorregidaRevisio => 'Corregida: vuelve a revisión.';

  @override
  String get llistaRetirar => 'Retira';

  @override
  String get llistaRetirarTitol => '¿Retirar la aportación?';

  @override
  String llistaRetirarText(String titol) {
    return 'Se borrará «$titol», con sus fotos. No se puede deshacer.';
  }

  @override
  String get llistaRetirada => 'Aportación retirada.';

  @override
  String get llistaErrorAccio =>
      'No se ha podido hacer. Comprueba la conexión y vuelve a intentarlo.';

  @override
  String get avisosPush => 'Avisos en el móvil';

  @override
  String get avisosPushDetall =>
      'Cuando validan o revisan tus aportaciones, o hay nuevas en tus partidas';

  @override
  String get perfilIdioma => 'Idioma';

  @override
  String get idiomaSistema => 'El del dispositivo';

  @override
  String get idiomaCa => 'Valencià';

  @override
  String get idiomaEs => 'Castellano';

  @override
  String get idiomaEn => 'English';
}
