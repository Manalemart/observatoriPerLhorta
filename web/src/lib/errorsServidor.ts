// Missatges d'error del servidor (els triggers els donen en valencià) en l'idioma de la web.
// Generat per a mantindre'l igual que app/lib/core/errors_servidor.dart: si s'afig un missatge
// en una migració, s'afig en els dos.
import { idiomaCurt } from './i18n';

const ERRORS: Record<string, [string, string]> = {
  "Cal haver entrat per a esborrar el compte": [
    "Hay que haber entrado para borrar la cuenta",
    "You must be signed in to delete the account"
  ],
  "Cal haver entrat": [
    "Hay que haber entrado",
    "You must be signed in"
  ],
  "Cal indicar el motiu del rebuig": [
    "Hay que indicar el motivo del rechazo",
    "Please give the reason for rejection"
  ],
  "Cal iniciar sessió": [
    "Hay que iniciar sesión",
    "You must sign in"
  ],
  "Com a màxim 3 fotos": [
    "Como máximo 3 fotos",
    "At most 3 photos"
  ],
  "Element inexistent": [
    "Elemento inexistente",
    "The feature does not exist"
  ],
  "L'element està fora de l'àmbit de l'Observatori": [
    "El elemento está fuera del ámbito del Observatorio",
    "The feature is outside the Observatory's area"
  ],
  "L'element ja està pendent": [
    "El elemento ya está pendiente",
    "The feature is already pending"
  ],
  "L'element substituït no existeix o ja està donat de baixa": [
    "El elemento sustituido no existe o ya está dado de baja",
    "The replaced feature does not exist or has already been retired"
  ],
  "La categoria no pertany a la variable": [
    "La categoría no pertenece a la variable",
    "The category does not belong to the variable"
  ],
  "La foto no s'ha pujat: ": [
    "La foto no se ha subido: ",
    "The photo was not uploaded: "
  ],
  "Les parcel·les han de dur la referència SIGPAC": [
    "Las parcelas deben llevar la referencia SIGPAC",
    "Plots must have a SIGPAC reference"
  ],
  "No pots validar ni rebutjar les teues pròpies aportacions": [
    "No puedes validar ni rechazar tus propias aportaciones",
    "You cannot validate or reject your own contributions"
  ],
  "No tens permís per a validar en esta partida": [
    "No tienes permiso para validar en esta partida",
    "You do not have permission to validate in this partida"
  ],
  "Només es confirmen elements validats": [
    "Solo se confirman elementos validados",
    "Only validated features can be confirmed"
  ],
  "Només es poden validar o rebutjar elements pendents": [
    "Solo se pueden validar o rechazar elementos pendientes",
    "Only pending features can be validated or rejected"
  ],
  "Només es revisen elements validats i vigents": [
    "Solo se revisan elementos validados y vigentes",
    "Only current, validated features can be reviewed"
  ],
  "Només la coordinació pot canviar el rol": [
    "Solo la coordinación puede cambiar el rol",
    "Only the coordinators can change roles"
  ],
  "Només la coordinació pot consultar els usuaris": [
    "Solo la coordinación puede consultar los usuarios",
    "Only the coordinators can look up users"
  ],
  "Només la coordinació pot reobrir elements": [
    "Solo la coordinación puede reabrir elementos",
    "Only the coordinators can reopen features"
  ],
  "Només revisa el padrí o la padrina de la partida": [
    "Solo revisa el padrino o la madrina de la partida",
    "Only the partida's sponsor can review it"
  ],
  "Resultat desconegut: ": [
    "Resultado desconocido: ",
    "Unknown result: "
  ],
  "Ruta de foto no vàlida: ": [
    "Ruta de foto no válida: ",
    "Invalid photo path: "
  ],
  "Token no vàlid": [
    "Token no válido",
    "Invalid token"
  ],
  "Has enviat moltes aportacions en poca estona. Espera una mica i torna-ho a provar.": [
    "Has enviado muchas aportaciones en poco tiempo. Espera un poco y vuelve a intentarlo.",
    "You have sent many contributions in a short time. Wait a little and try again."
  ],
  "Un element no pot tindre més de 5 fotos.": [
    "Un elemento no puede tener más de 5 fotos.",
    "A feature cannot have more than 5 photos."
  ],
  "No es pot corregir": [
    "No se puede corregir",
    "It cannot be corrected"
  ],
  "No es pot retirar": [
    "No se puede retirar",
    "It cannot be withdrawn"
  ],
  "Ací no hi ha cap recinte SIGPAC.": [
    "Aquí no hay ningún recinto SIGPAC.",
    "There is no SIGPAC plot here."
  ]
};

export function traduirErrorServidor(missatge: string): string {
  const l = idiomaCurt();
  if (l === 'ca') return missatge;
  const i = l === 'es' ? 0 : 1;
  const exacte = ERRORS[missatge];
  if (exacte) return exacte[i];
  const g = /^La geometria \((.*)\) no correspon a la variable \((.*)\)$/.exec(missatge);
  if (g) return (i === 0 ? 'La geometría ({0}) no corresponde a la variable ({1})' : 'The geometry ({0}) does not match the variable ({1})').replace('{0}', g[1]).replace('{1}', g[2]);
  for (const [ca, tr] of Object.entries(ERRORS)) {
    if (ca.endsWith(': ') && missatge.startsWith(ca)) return tr[i] + missatge.slice(ca.length);
  }
  return missatge;
}
