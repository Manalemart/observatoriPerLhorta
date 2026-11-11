import { useEffect, useState } from 'react';

export type Tema = 'clar' | 'fosc';

const CLAU = 'observatori-tema';
const CONSULTA = '(prefers-color-scheme: dark)';

const temaSistema = (): Tema => (window.matchMedia(CONSULTA).matches ? 'fosc' : 'clar');

function temaGuardat(): Tema | null {
  try {
    const t = localStorage.getItem(CLAU);
    return t === 'clar' || t === 'fosc' ? t : null;
  } catch {
    return null; // navegación privada o almacenamiento bloqueado
  }
}

/**
 * Tema claro u oscuro. Sin elección guardada sigue al sistema (y a sus cambios);
 * el botón guarda la elección en este navegador. index.html la aplica antes de pintar.
 */
export function useTema() {
  const [triat, setTriat] = useState<Tema | null>(temaGuardat);
  const [sistema, setSistema] = useState<Tema>(temaSistema);

  useEffect(() => {
    const consulta = window.matchMedia(CONSULTA);
    const canvi = () => setSistema(temaSistema());
    consulta.addEventListener('change', canvi);
    return () => consulta.removeEventListener('change', canvi);
  }, []);

  const tema = triat ?? sistema;

  useEffect(() => {
    const arrel = document.documentElement;
    if (triat) arrel.dataset.tema = triat;
    else delete arrel.dataset.tema;
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', tema === 'fosc' ? '#1e1c19' : '#ffffff');
  }, [triat, tema]);

  const canviar = () => {
    const nou: Tema = tema === 'fosc' ? 'clar' : 'fosc';
    setTriat(nou);
    try {
      localStorage.setItem(CLAU, nou);
    } catch {
      // sin almacenamiento: vale para esta visita
    }
  };

  return { tema, canviar };
}
