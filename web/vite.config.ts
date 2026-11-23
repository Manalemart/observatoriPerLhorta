import { readFileSync } from 'node:fs';
import { defineConfig } from 'vite';
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

export default defineConfig({
  plugins: [react()],
  server: { port: 5173, strictPort: true },
  preview: { headers: capcaleres },
});
