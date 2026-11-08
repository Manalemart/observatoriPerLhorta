import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

if (!url || !anonKey) {
  throw new Error('Falten VITE_SUPABASE_URL i VITE_SUPABASE_ANON_KEY (vegeu web/.env.example)');
}

export const supabase = createClient(url, anonKey);
