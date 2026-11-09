import { useEffect, type ReactNode } from 'react';
import { useLocation } from 'react-router-dom';

// ⚠️ BORRADOR. Lo tienen que revisar Per l'Horta y su asesoría antes de abrir la web.
// Los datos entre [corchetes] están por completar. Texto legal: va aquí y no en
// locales/ porque, si llega el castellano, se traduce como documento, no frase a frase.
const PENDENT = (s: string) => <mark className="pendent">[{s}]</mark>;

const TITULAR = "Per l'Horta";
const CORREU = PENDENT('correu de contacte');

function Seccio({ id, titol, children }: { id: string; titol: string; children: ReactNode }) {
  return (
    <section id={id} className="legal-seccio">
      <h2>{titol}</h2>
      {children}
    </section>
  );
}

export function Legal() {
  const { hash } = useLocation();
  useEffect(() => {
    if (hash) document.getElementById(hash.slice(1))?.scrollIntoView();
  }, [hash]);

  return (
    <main className="pagina pagina-estreta legal">
      <h1>Avís legal i privacitat</h1>
      <p className="avis-esborrany" role="note">
        Esborrany pendent de revisió per {TITULAR}. No és vigent fins que es publique la versió definitiva.
      </p>
      <nav aria-label="Seccions">
        <a href="#avis-legal">Avís legal</a> · <a href="#privacitat">Privacitat</a> · <a href="#condicions">Condicions d'ús</a>
      </nav>

      <Seccio id="avis-legal" titol="Avís legal">
        <p>
          L'Observatori Ciutadà de l'Horta és una iniciativa de {TITULAR}, amb NIF {PENDENT('NIF')} i domicili a{' '}
          {PENDENT('adreça')}. Contacte: {CORREU}.
        </p>
        <p>El desenvolupament tècnic i tecnològic és de MAM — Mediambient i Mapes.</p>
        <p>
          El codi font és lliure, amb llicència AGPL-3.0. Les dades de l'inventari es publiquen amb llicència
          CC BY 4.0 i les fotografies aportades, amb CC BY-SA 4.0.
        </p>
        <p>
          La cartografia de fons és de l'Instituto Geográfico Nacional, l'Institut Cartogràfic Valencià
          i el SIGPAC (FEGA), cadascuna amb les seues condicions. Les parcel·les de l'inventari
          2017-2018 provenen de la Direcció General del Cadastre.
        </p>
      </Seccio>

      <Seccio id="privacitat" titol="Política de privacitat">
        <h3>Qui tracta les teues dades</h3>
        <p>
          El responsable és {TITULAR} ({CORREU}). MAM — Mediambient i Mapes manté la plataforma com a encarregat
          del tractament. Les dades s'allotgen en {PENDENT('Supabase, regió de la Unió Europea')} i la web, en{' '}
          {PENDENT('Vercel')}.
        </p>

        <h3>Quines dades</h3>
        <ul>
          <li>El teu correu electrònic, per a entrar sense contrasenya.</li>
          <li>L'àlies que tries.</li>
          <li>
            Les teues aportacions: la ubicació, el tipus d'element, la descripció, les fotografies i la data.
          </li>
          <li>
            La teua ubicació GPS, només quan tu la demanes per a situar una aportació. No es registra en cap altre
            moment.
          </li>
        </ul>

        <h3>Per a què</h3>
        <ul>
          <li>Gestionar el teu compte i identificar-te davant la coordinació.</li>
          <li>Revisar, validar i publicar les aportacions.</li>
          <li>Avisar-te quan es valida o es rebutja una aportació teua.</li>
        </ul>
        <p>La base legal és el teu consentiment, que dones en crear el compte.</p>

        <h3>Qui les veu</h3>
        <ul>
          <li>
            <strong>Tothom</strong> pot veure les aportacions validades, <strong>sense el teu nom ni el teu
            correu</strong>.
          </li>
          <li>Les persones amb partides apadrinades i la coordinació veuen les aportacions pendents de les seues zones.</li>
          <li>La coordinació veu el teu correu i el teu àlies, per a poder assignar-te partides.</li>
        </ul>
        <p>No es cedeixen dades a tercers ni s'usen per a publicitat.</p>

        <h3>Fotografies</h3>
        <p>
          Quan puges una foto, s'eliminen les metadades (també la ubicació GPS de la càmera). Evita que isquen
          persones o matrícules: si n'hi ha, la coordinació pot rebutjar-la.
        </p>

        <h3>Quant de temps</h3>
        <p>
          El compte es conserva mentre no demanes esborrar-lo. Les aportacions validades formen part d'un inventari
          públic i obert: si esborres el compte, es conserven sense cap vincle amb tu.
        </p>

        <h3>Els teus drets</h3>
        <p>
          Pots accedir a les teues dades, rectificar-les, demanar que s'esborren, oposar-te al tractament, limitar-lo
          o demanar-ne una còpia escrivint a {CORREU}. Si no estàs d'acord amb la resposta, pots reclamar davant
          l'Agència Espanyola de Protecció de Dades (aepd.es).
        </p>

        <h3>Galetes</h3>
        <p>
          La web només guarda en el navegador la sessió, perquè no hages d'entrar cada vegada. No usa galetes
          d'analítica ni de publicitat.
        </p>
      </Seccio>

      <Seccio id="condicions" titol="Condicions d'ús">
        <ul>
          <li>Aporta informació certa, observada directament i des de llocs d'accés públic.</li>
          <li>No entres en propietats privades per a fer una aportació.</li>
          <li>
            En enviar una aportació acceptes publicar-la amb llicència CC BY 4.0, i les fotografies amb CC BY-SA 4.0.
            Has de ser l'autor o l'autora de les fotos.
          </li>
          <li>
            La coordinació pot rebutjar o retirar aportacions que no s'ajusten a la finalitat de l'Observatori.
          </li>
          <li>
            L'inventari és orientatiu: no té valor oficial ni substitueix cap informació administrativa o
            cadastral.
          </li>
        </ul>
      </Seccio>
    </main>
  );
}
