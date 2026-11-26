import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';

// English version of Legal.tsx. It is the same document: if one changes, the others must too
// (Legal.tsx, LegalEs.tsx).

const TITULAR = "the Associació Per l'Horta";
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

export function LegalEn() {
  return (
    <main className="pagina pagina-estreta legal" lang="en">
      <h1>Legal notice and privacy</h1>
      <p>In case of doubt, the Valencian version prevails.</p>
      <nav aria-label="Sections">
        <a href="#avis-legal">Legal notice</a> · <a href="#privacitat">Privacy</a> · <a href="#condicions">Terms of use</a>
      </nav>

      <Seccio id="avis-legal" titol="Legal notice">
        <p>
          The Observatori Ciutadà de l'Horta (Citizen Observatory of the Horta) is an initiative of {TITULAR}, a
          non-profit association with tax ID (CIF) G-97295737, registered in the Register of Associations of the
          Valencian Community, with its registered office at Carrer de Santa Teresa, 10, 46001 València (Spain).
          Contact: {CORREU} · +34 722 172 079.
        </p>
        <p>
          The technical development is by MAM — Mediambient i Mapes. For technical questions about the website or the
          app: {CORREU_DESENVOLUPAMENT}.
        </p>
        <p>
          The source code is free software, licensed under AGPL-3.0. The inventory data is published under a CC BY 4.0
          licence and the contributed photos under CC BY-SA 4.0.
        </p>
        <p>
          The base maps come from the Instituto Geográfico Nacional, the Institut Cartogràfic Valencià and SIGPAC
          (FEGA), each under its own terms. The plots of the 2017-2018 inventory come from the Spanish Directorate
          General for Cadastre.
        </p>
      </Seccio>

      <Seccio id="privacitat" titol="Privacy policy">
        <h3>Who processes your data</h3>
        <p>
          The controller is {TITULAR} (CIF G-97295737, Carrer de Santa Teresa, 10, 46001 València; {CORREU}).
          MAM — Mediambient i Mapes maintains the platform as processor ({CORREU_DESENVOLUPAMENT}).
        </p>

        <h3>Where it is hosted</h3>
        <ul>
          <li>The database, accounts and photos, on Supabase, in a data centre in London (United Kingdom).</li>
          <li>The website, on Vercel, served from London.</li>
          <li>Sign-in and notification emails are sent with Brevo, from the European Union.</li>
        </ul>
        <p>
          The United Kingdom has an adequacy decision from the European Commission: its law guarantees a level of data
          protection equivalent to that of the European Union. Supabase and Vercel act as sub-processors, under
          contracts that include the European Commission's standard contractual clauses.
        </p>

        <h3>What data</h3>
        <ul>
          <li>Your email address, to sign in without a password.</li>
          <li>The nickname you choose.</li>
          <li>Your contributions: location, type of feature, description, photos and date.</li>
          <li>
            Your GPS location, only when you ask for it to place a contribution. It is not recorded at any other time.
          </li>
        </ul>

        <h3>What for</h3>
        <ul>
          <li>Managing your account and identifying you to the coordinators.</li>
          <li>Reviewing, validating and publishing contributions.</li>
          <li>Notifying you when one of your contributions is validated or rejected.</li>
        </ul>
        <p>The legal basis is your consent, which you give when you create the account.</p>

        <h3>Who can see it</h3>
        <ul>
          <li>
            <strong>Everyone</strong> can see validated contributions, <strong>without your name or your
            email</strong>.
          </li>
          <li>People who sponsor partides and the coordinators see pending contributions in their areas.</li>
          <li>The coordinators see your email and your nickname, so they can assign you partides.</li>
        </ul>
        <p>No data is passed on to third parties or used for advertising.</p>

        <h3>Photos</h3>
        <p>
          When you upload a photo, its metadata is removed (including the camera's GPS location). Avoid showing people
          or number plates: if there are any, the coordinators may reject it.
        </p>

        <h3>How long</h3>
        <p>
          Your account is kept until you delete it. You can delete it yourself at any time from{' '}
          <Link to="/compte">My account</Link> on the website or from the profile in the app: the account, nickname,
          notifications, sponsored partides and unpublished contributions, with their photos, are deleted
          immediately. Validated contributions are part of a public, open inventory: they are kept, but with no link to
          you.
        </p>
        <p>
          Database backups expire automatically: deleted data may remain in them, unused, until they expire (30 days at
          most).
        </p>

        <h3>Your rights</h3>
        <p>
          You can access your data and download a copy, change your nickname and delete your account yourself from{' '}
          <Link to="/compte">My account</Link>. You can also exercise any of these rights (access, rectification,
          erasure, objection, restriction and portability) by writing to {CORREU}: we will reply within one month at the
          latest. If you disagree with the reply, you can complain to the Spanish Data Protection Agency (aepd.es).
        </p>

        <h3>Cookies</h3>
        <p>
          The website only stores your session in the browser, so you don't have to sign in every time, and the
          language you choose. It uses no analytics or advertising cookies.
        </p>
      </Seccio>

      <Seccio id="condicions" titol="Terms of use">
        <ul>
          <li>Contribute accurate information, observed directly and from publicly accessible places.</li>
          <li>Do not enter private property to make a contribution.</li>
          <li>
            By sending a contribution you agree to publish it under a CC BY 4.0 licence, and the photos under
            CC BY-SA 4.0. You must be the author of the photos.
          </li>
          <li>The coordinators may reject or remove contributions that do not fit the Observatory's purpose.</li>
          <li>
            The inventory is for guidance only: it has no official value and does not replace any administrative or
            cadastral information.
          </li>
        </ul>
      </Seccio>
    </main>
  );
}
