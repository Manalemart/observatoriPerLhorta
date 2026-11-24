import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';

// Versión en castellano de Legal.tsx. Es el mismo documento: si cambia uno, hay que cambiar el otro.

const TITULAR = "la Associació Per l'Horta";
const CORREU = <a href="mailto:perlhorta@perlhorta.info">perlhorta@perlhorta.info</a>;
const CORREU_DESENVOLUPAMENT = <a href="mailto:desarrollo@mediamapes.com">desarrollo@mediamapes.com</a>;

function Seccio({ id, titol, children }: { id: string; titol: string; children: ReactNode }) {
  return (
    <section id={id} className="legal-seccio">
      <h2>{titol}</h2>
      {children}
    </section>
  );
}

export function LegalEs() {
  return (
    <main className="pagina pagina-estreta legal" lang="es">
      <h1>Aviso legal y privacidad</h1>
      <p className="avis-esborrany" role="note">
        Borrador pendiente de revisión por {TITULAR}. No está vigente hasta que se publique la versión definitiva.
        En caso de duda, prevalece la versión en valenciano.
      </p>
      <nav aria-label="Secciones">
        <a href="#avis-legal">Aviso legal</a> · <a href="#privacitat">Privacidad</a> · <a href="#condicions">Condiciones de uso</a>
      </nav>

      <Seccio id="avis-legal" titol="Aviso legal">
        <p>
          El Observatori Ciutadà de l'Horta (Observatorio Ciudadano de la Huerta) es una iniciativa de {TITULAR},
          asociación sin ánimo de lucro con CIF G-97295737, inscrita en el Registro de Asociaciones de la Comunitat
          Valenciana y con domicilio en la calle Santa Teresa, 10, 46001 València. Contacto: {CORREU} · 722 172 079.
        </p>
        <p>
          El desarrollo técnico y tecnológico es de MAM — Mediambient i Mapes. Para cuestiones técnicas de la web o
          de la aplicación: {CORREU_DESENVOLUPAMENT}.
        </p>
        <p>
          El código fuente es libre, con licencia AGPL-3.0. Los datos del inventario se publican con licencia
          CC BY 4.0 y las fotografías aportadas, con CC BY-SA 4.0.
        </p>
        <p>
          La cartografía de fondo es del Instituto Geográfico Nacional, el Institut Cartogràfic Valencià y el SIGPAC
          (FEGA), cada una con sus condiciones. Las parcelas del inventario 2017-2018 proceden de la Dirección
          General del Catastro.
        </p>
      </Seccio>

      <Seccio id="privacitat" titol="Política de privacidad">
        <h3>Quién trata tus datos</h3>
        <p>
          El responsable es {TITULAR} (CIF G-97295737, calle Santa Teresa, 10, 46001 València; {CORREU}).
          MAM — Mediambient i Mapes mantiene la plataforma como encargado del tratamiento ({CORREU_DESENVOLUPAMENT}).
        </p>

        <h3>Dónde se alojan</h3>
        <ul>
          <li>La base de datos, las cuentas y las fotografías, en Supabase, en un centro de datos de Londres (Reino Unido).</li>
          <li>La web, en Vercel, que la sirve desde Londres.</li>
          <li>Los correos de acceso y de avisos se envían con Brevo, desde la Unión Europea.</li>
        </ul>
        <p>
          El Reino Unido tiene una decisión de adecuación de la Comisión Europea: su ley garantiza una protección de
          los datos equivalente a la de la Unión Europea. Supabase y Vercel actúan como subencargados del
          tratamiento, con contratos que incluyen las cláusulas contractuales tipo de la Comisión Europea.
        </p>

        <h3>Qué datos</h3>
        <ul>
          <li>Tu correo electrónico, para entrar sin contraseña.</li>
          <li>El alias que elijas.</li>
          <li>Tus aportaciones: la ubicación, el tipo de elemento, la descripción, las fotografías y la fecha.</li>
          <li>
            Tu ubicación GPS, solo cuando tú la pides para situar una aportación. No se registra en ningún otro
            momento.
          </li>
        </ul>

        <h3>Para qué</h3>
        <ul>
          <li>Gestionar tu cuenta e identificarte ante la coordinación.</li>
          <li>Revisar, validar y publicar las aportaciones.</li>
          <li>Avisarte cuando se valida o se rechaza una aportación tuya.</li>
        </ul>
        <p>La base legal es tu consentimiento, que das al crear la cuenta.</p>

        <h3>Quién los ve</h3>
        <ul>
          <li>
            <strong>Todo el mundo</strong> puede ver las aportaciones validadas, <strong>sin tu nombre ni tu
            correo</strong>.
          </li>
          <li>Las personas con partidas apadrinadas y la coordinación ven las aportaciones pendientes de sus zonas.</li>
          <li>La coordinación ve tu correo y tu alias, para poder asignarte partidas.</li>
        </ul>
        <p>No se ceden datos a terceros ni se usan para publicidad.</p>

        <h3>Fotografías</h3>
        <p>
          Cuando subes una foto, se eliminan los metadatos (también la ubicación GPS de la cámara). Evita que salgan
          personas o matrículas: si las hay, la coordinación puede rechazarla.
        </p>

        <h3>Cuánto tiempo</h3>
        <p>
          La cuenta se conserva mientras no la borres. Puedes borrarla cuando quieras, tú mismo, desde{' '}
          <Link to="/compte">Mi cuenta</Link> en la web o desde el perfil de la aplicación: se borran en el momento la
          cuenta, el alias, los avisos, las partidas apadrinadas y las aportaciones que aún no se han publicado, con
          sus fotos. Las aportaciones validadas forman parte de un inventario público y abierto: se conservan, pero
          sin ningún vínculo contigo.
        </p>
        <p>
          Las copias de seguridad de la base de datos caducan solas: los datos borrados pueden quedar en ellas, sin
          ningún uso, hasta que caducan (como máximo 30 días).
        </p>

        <h3>Tus derechos</h3>
        <p>
          Puedes acceder a tus datos y descargar una copia, cambiar el alias y borrar la cuenta tú mismo desde{' '}
          <Link to="/compte">Mi cuenta</Link>. También puedes ejercer cualquiera de estos derechos (acceso,
          rectificación, supresión, oposición, limitación y portabilidad) escribiendo a {CORREU}: te responderemos en
          un plazo máximo de un mes. Si no estás de acuerdo con la respuesta, puedes reclamar ante la Agencia
          Española de Protección de Datos (aepd.es).
        </p>

        <h3>Cookies</h3>
        <p>
          La web solo guarda en el navegador la sesión, para que no tengas que entrar cada vez, y el idioma que
          elijas. No usa cookies de analítica ni de publicidad.
        </p>
      </Seccio>

      <Seccio id="condicions" titol="Condiciones de uso">
        <ul>
          <li>Aporta información cierta, observada directamente y desde lugares de acceso público.</li>
          <li>No entres en propiedades privadas para hacer una aportación.</li>
          <li>
            Al enviar una aportación aceptas publicarla con licencia CC BY 4.0, y las fotografías con CC BY-SA 4.0.
            Debes ser el autor o la autora de las fotos.
          </li>
          <li>La coordinación puede rechazar o retirar aportaciones que no se ajusten a la finalidad del Observatorio.</li>
          <li>
            El inventario es orientativo: no tiene valor oficial ni sustituye ninguna información administrativa o
            catastral.
          </li>
        </ul>
      </Seccio>
    </main>
  );
}
