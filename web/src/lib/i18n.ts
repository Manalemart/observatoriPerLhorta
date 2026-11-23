// Valencià (principal), castellà i anglés. L'idioma: el que s'haja triat en la web (es recorda
// en el navegador); si no, el del navegador: valencià si és català o valencià, castellà si és
// castellà i anglés per a la resta. Els noms del catàleg també es tradueixen (vegeu cataleg.ts).
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ca from '../locales/ca-valencia.json';
import es from '../locales/es.json';
import en from '../locales/en.json';

export const IDIOMES = ['ca-ES-valencia', 'es', 'en'] as const;
export type Idioma = (typeof IDIOMES)[number];

const CLAU = 'observatori.idioma';

function inicial(): Idioma {
  try {
    const desat = localStorage.getItem(CLAU);
    if (desat && (IDIOMES as readonly string[]).includes(desat)) return desat as Idioma;
  } catch { /* sense emmagatzematge */ }
  const nav = (navigator.languages?.[0] ?? navigator.language ?? '').toLowerCase();
  if (nav.startsWith('ca') || nav.startsWith('va')) return 'ca-ES-valencia';
  return nav.startsWith('es') ? 'es' : 'en';
}

void i18n.use(initReactI18next).init({
  lng: inicial(),
  fallbackLng: 'ca-ES-valencia',
  resources: { 'ca-ES-valencia': { translation: ca }, es: { translation: es }, en: { translation: en } },
  interpolation: { escapeValue: false },
});

const posarLang = (l: string) => {
  document.documentElement.lang = l === 'es' || l === 'en' ? l : 'ca-ES-valencia';
  document.title = i18n.t('app.titol');
};
posarLang(i18n.language);
i18n.on('languageChanged', (l) => {
  posarLang(l);
  try { localStorage.setItem(CLAU, l); } catch { /* sense emmagatzematge */ }
});

export default i18n;

/** Idioma curt de la web: 'ca', 'es' o 'en' (per a triar el nom del catàleg, les dates…). */
export function idiomaCurt(l: string = i18n.language): 'ca' | 'es' | 'en' {
  return l === 'es' || l === 'en' ? l : 'ca';
}
