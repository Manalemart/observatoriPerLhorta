// Tema triat amb el botó de la capçalera: s'aplica abans de pintar per a no parpellejar.
// Fitxer a banda (no <script> en línia) perquè la Content-Security-Policy no admet scripts en línia.
try {
  var t = localStorage.getItem('observatori-tema');
  if (t === 'clar' || t === 'fosc') document.documentElement.dataset.tema = t;
} catch (e) { /* sense emmagatzematge: es queda el del sistema */ }
