import { useMemo } from 'react';
import { dibuixGlif, MIDA_GLIF, type Glif, type Simbol } from './simbologia';

const AMPLE = 30;
const ALT = 14;

const DASH: Record<string, string | undefined> = {
  discontinua: '6 4', puntejada: '0.1 4', punt_ratlla: '8 3 0.1 3',
};

/** Tram de línia amb glif repetit (com el pinta el mapa), en una imatge per a la llegenda. */
function useGlif(glif: Glif | undefined, color: string) {
  return useMemo(() => {
    if (!glif || glif === 'fletxa') return null;
    const [w, h] = MIDA_GLIF[glif];
    const r = 2;
    const canvas = document.createElement('canvas');
    canvas.width = AMPLE * r;
    canvas.height = ALT * r;
    const c = canvas.getContext('2d');
    if (!c) return null;
    c.scale(r, r);
    c.translate(0, (ALT - h) / 2);
    for (let x = 0; x < AMPLE; x += w) {
      c.save();
      c.translate(x, 0);
      dibuixGlif(c, glif, color, w, h);
      c.restore();
    }
    return canvas.toDataURL();
  }, [glif, color]);
}

/** El símbol de la guia en petit: icona, tram de línia o mostra de parcel·la. */
export function MostraSimbol({ simbol }: { simbol: Simbol }) {
  const glif = useGlif(simbol.tipus === 'linia' ? simbol.glif : undefined, simbol.color);

  if (simbol.tipus === 'punt') {
    return <img className="mostra-simbol" src={`/simbols/${simbol.icona}.png`} alt="" aria-hidden="true" />;
  }
  if (simbol.tipus === 'parcela') {
    const trama = simbol.trama === 'ratlles'
      ? 'repeating-linear-gradient(-45deg, transparent 0 3px, #fff 3px 4.5px)'
      : simbol.trama === 'punts'
        ? 'radial-gradient(circle, #fff 1.2px, transparent 1.6px) 0 0 / 6px 6px'
        : undefined;
    return (
      <span
        className="mostra-simbol mostra-parcela"
        style={{ background: trama ? `${trama}, ${simbol.color}` : simbol.color, borderColor: simbol.contorn }}
        aria-hidden="true"
      />
    );
  }
  if (glif) return <img className="mostra-simbol mostra-linia" src={glif} alt="" aria-hidden="true" />;
  const m = ALT / 2;
  return (
    <svg className="mostra-simbol mostra-linia" width={AMPLE} height={ALT} viewBox={`0 0 ${AMPLE} ${ALT}`} aria-hidden="true">
      {simbol.patro === 'doble' ? (
        <>
          <line x1="0" y1={m - 2} x2={AMPLE} y2={m - 2} stroke={simbol.color} strokeWidth="1.2" />
          <line x1="0" y1={m + 2} x2={AMPLE} y2={m + 2} stroke={simbol.color} strokeWidth="1.2" />
        </>
      ) : (
        <line
          x1="0" y1={m} x2={AMPLE} y2={m} stroke={simbol.color} strokeWidth={Math.min(simbol.amplada, 2.5)}
          strokeDasharray={DASH[simbol.patro]} strokeLinecap={simbol.patro === 'puntejada' ? 'round' : 'butt'}
        />
      )}
      {simbol.glif === 'fletxa' && <path d={`M${AMPLE - 9} ${m - 4} L${AMPLE - 2} ${m} L${AMPLE - 9} ${m + 4} Z`} fill={simbol.color} />}
    </svg>
  );
}
