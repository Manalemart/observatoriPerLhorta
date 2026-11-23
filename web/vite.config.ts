import { readFileSync } from 'node:fs';
import { defineConfig, loadEnv, type Plugin } from 'vite';
import react from '@vitejs/plugin-react';

// Les capçaleres de seguretat de vercel.json també en `vite preview`, per a provar la
// Content-Security-Policy amb la build abans de publicar-la. En local, Supabase és
// 127.0.0.1:64321: s'hi afig a la CSP només ací.
const vercel = JSON.parse(readFileSync(new URL('./vercel.json', import.meta.url), 'utf-8'));
const capcaleres: Record<string, string> = Object.fromEntries(
  vercel.headers[0].headers.map((h: { key: string; value: string }) => [h.key, h.value]),
);
const local = 'http://127.0.0.1:64321 ws://127.0.0.1:64321';
capcaleres['Content-Security-Policy'] = capcaleres['Content-Security-Policy']
  .replace('connect-src ', `connect-src ${local} `)
  .replace('img-src ', `img-src ${local} `);

// En `vite preview` no hi ha les funcions de Vercel: /api/geo/<capa> es servix ací igual que
// web/api/geo/[capa].ts (la mateixa RPC de Supabase), per a provar la build sencera en local.
const CAPES: Record<string, string> = { elements: 'elements_publics', partides: 'partides_geojson', municipis: 'municipis_geojson' };
function apiGeoLocal(): Plugin {
  return {
    name: 'api-geo-local',
    configurePreviewServer(server) {
      const env = loadEnv('production', process.cwd(), 'VITE_');
      server.middlewares.use('/api/geo', async (req, res) => {
        const rpc = CAPES[(req.url ?? '').split('?')[0].replace(/^\//, '')];
        if (!rpc) { res.statusCode = 404; res.end(); return; }
        const r = await fetch(`${env.VITE_SUPABASE_URL}/rest/v1/rpc/${rpc}`, {
          headers: { apikey: env.VITE_SUPABASE_ANON_KEY, Authorization: `Bearer ${env.VITE_SUPABASE_ANON_KEY}` },
        });
        res.statusCode = r.status;
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.end(await r.text());
      });
    },
  };
}

export default defineConfig({
  plugins: [react(), apiGeoLocal()],
  server: { port: 5173, strictPort: true },
  preview: { headers: capcaleres },
});
