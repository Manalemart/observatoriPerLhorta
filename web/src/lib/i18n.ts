// Fase 1: solo valenciano. Para añadir un idioma basta otro fichero en locales/.
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ca from '../locales/ca-valencia.json';

void i18n.use(initReactI18next).init({
  lng: 'ca-ES-valencia',
  fallbackLng: 'ca-ES-valencia',
  resources: { 'ca-ES-valencia': { translation: ca } },
  interpolation: { escapeValue: false },
});

export default i18n;
