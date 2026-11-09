# Despliegue

Guía para poner en marcha el Observatori en la nube: **GitHub** (código y CI), **Supabase** (base de datos, autenticación y ficheros) y **Vercel** (web). La app Flutter se compila contra el mismo Supabase.

Las cuentas, los proyectos y los pagos van a nombre de Per l'Horta o de MAM: decidirlo antes de empezar.

## 0 · Antes de empezar

- [ ] Dominio elegido y registrado (candidatos: `observatorihorta.cat` / `.org`).
- [ ] Textos legales revisados por Per l'Horta: `web/src/features/legal/Legal.tsx` (los `[huecos]` marcados).
- [ ] Per l'Horta confirma la licencia de los datos y fotos de 2017-2018.
- [ ] Las 10 fotos de 2018 revisadas (sin personas ni matrículas).
- [ ] Un proveedor de correo (SMTP): Resend, Brevo…, con el dominio verificado.

## 1 · GitHub

1. Crear el repositorio vacío (público encaja con AGPL-3.0; privado también sirve).
2. Subir el código:
   ```bash
   cd observatori
   git remote add origin git@github.com:<organitzacio>/observatori.git
   git push -u origin main
   ```
3. La CI (`.github/workflows/ci.yml`) corre sola en cada push: tests de la base de datos, lint y build de la web, y análisis y tests de la app.

## 2 · Supabase

1. **New project** en una región de la UE (Frankfurt o París: el RGPD y la latencia lo agradecen). Guardar la contraseña de la base de datos.
2. Enlazar y subir el esquema con el catálogo de variables:
   ```bash
   npx supabase@3.0.0 login
   npx supabase@3.0.0 link --project-ref <ref>
   npx supabase@3.0.0 db push --include-seed --dry-run   # revisar qué va a aplicar
   npx supabase@3.0.0 db push --include-seed
   ```
   `seed.sql` solo contiene el catálogo y se puede repetir: lo que ya existe no se toca.
3. **Authentication → URL Configuration**:
   - *Site URL*: `https://<domini>`
   - *Redirect URLs*: `https://<domini>/**` (y la URL de Vercel `https://<projecte>.vercel.app/**` mientras no esté el dominio). **Con `/**`**: sin comodín, el enlace mágico no vuelve a la página donde se pidió.
4. **Authentication → Emails → SMTP Settings**: los datos del proveedor de correo. Sin SMTP propio Supabase solo envía unos pocos correos por hora.
5. **Authentication → Emails → Templates → Magic Link**: asunto `Entra a l'Observatori Ciutadà de l'Horta` y el contenido de `supabase/templates/magic_link.html`. La plantilla trae el enlace (web) y el código (app): las dos cosas hacen falta.
6. **Authentication → Hooks → Customize Access Token**: activar con la función `public.custom_access_token_hook`.
7. **No usar `supabase config push`**: subiría también la configuración de desarrollo (`site_url` en localhost).

### Cargar el inventario de 2017-2018

Desde un PC con la BD legacy levantada (`observatori-revival`) y los ficheros de 2018:

```bash
cd etl
# .env con TARGET_DB_URL = cadena de conexión "Session pooler" del proyecto (Settings → Database),
# SUPABASE_URL = https://<ref>.supabase.co, SUPABASE_SERVICE_ROLE_KEY y SUPABASE_ANON_KEY (Settings → API)
npm run migrar
npm run verificar
```

`verificar` tiene que acabar sin `ERR`. Las 52 noticias entran sin publicar.

### Primera persona de coordinación

Entrar en la web con el correo que corresponda y, en el *SQL Editor* de Supabase:

```sql
update public.perfils p set rol = 'coordinador'
  from auth.users u where u.id = p.id and u.email = '<correu>';
```

Desde ahí, la coordinación asigna padrinatges desde la web. Más coordinadores: el mismo SQL.

## 3 · Vercel

1. **Add New → Project**, importar el repositorio de GitHub.
2. *Root Directory*: `web`. Vercel detecta Vite; `vercel.json` ya trae las reglas de rutas y las cabeceras de seguridad.
3. *Environment Variables*:
   - `VITE_SUPABASE_URL` = `https://<ref>.supabase.co`
   - `VITE_SUPABASE_ANON_KEY` = la clave pública (anon / publishable)
   - `VITE_AUTH_GOOGLE` = `true` solo si se configura Google en Supabase
4. *Domains*: añadir el dominio y apuntar el DNS como indique Vercel.
5. Cada push a `main` despliega; cada pull request tiene su vista previa.

## 4 · App Android

```bash
cd app
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_KEY=<clau pública>
```

Para Google Play hace falta firmar (`android/key.properties` y un keystore que **no** se sube al repo) y generar un `appbundle`. Identificador: `com.mamlabsfera.observatori_perlhorta`.

## 5 · Comprobar después de desplegar

- [ ] La web carga el mapa con los 7.104 elementos y las ortofotos del comparador.
- [ ] Entrar con un correo real: llega el correo en valenciano, el enlace vuelve a la web y el código funciona en la app.
- [ ] Aportar desde la web y desde la app, con foto; validarlo desde otra cuenta de coordinación.
- [ ] `/dades`: las descargas y la API (`https://<ref>.supabase.co/rest/v1/dades_obertes`).
- [ ] Un anónimo no ve pendientes ni autores (la CI lo comprueba en local; repetirlo una vez contra la nube).

## Costes de partida

| Servicio | Plan | Límite que vigilar |
|----------|------|--------------------|
| Supabase | Free | 500 MB de BD (ahora ~31 MB), 1 GB de ficheros, se pausa tras 7 días sin actividad |
| Vercel | Hobby | Uso no comercial; si Per l'Horta lo considera actividad de la entidad, el plan Pro |
| GitHub | Free | Minutos de Actions limitados en repos privados |

Con usuarios reales conviene Supabase Pro (unos 25 $/mes): sin pausas, copias de seguridad diarias y 8 GB de ficheros.
