// Valencià (principal) i castellà. L'idioma: el que s'haja triat en la web (es recorda en
// el navegador); si no, el del navegador (castellà si és «es»; per a tot la resta, valencià).
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ca from '../locales/ca-valencia.json';
import es from '../locales/es.json';

export const IDIOMES = ['ca-ES-valencia', 'es'] as const;
export type Idioma = (typeof IDIOMES)[number];

const CLAU = 'observatori.idioma';

function inicial(): Idioma {
  try {
    const desat = localStorage.getItem(CLAU);
    if (desat && (IDIOMES as readonly string[]).includes(desat)) return desat as Idioma;
  } catch { /* sense emmagatzematge */ }
  const nav = (navigator.languages?.[0] ?? navigator.language ?? '').toLowerCase();
  return nav.startsWith('es') ? 'es' : 'ca-ES-valencia';
}

void i18n.use(initReactI18next).init({
  lng: inicial(),
  fallbackLng: 'ca-ES-valencia',
  resources: { 'ca-ES-valencia': { translation: ca }, es: { translation: es } },
  interpolation: { escapeValue: false },
});

const posarLang = (l: string) => {
  document.documentElement.lang = l === 'es' ? 'es' : 'ca-ES-valencia';
  document.title = i18n.t('app.titol');
};
posarLang(i18n.language);
i18n.on('languageChanged', (l) => {
  posarLang(l);
  try { localStorage.setItem(CLAU, l); } catch { /* sense emmagatzematge */ }
});

export default i18n;
