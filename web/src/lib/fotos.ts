import { supabase } from './supabase';

const COSTAT_MAX = 1600;
const QUALITAT = 0.8;

/** Redimensiona y recodifica en JPEG: pesa menos y elimina EXIF y GPS. */
export async function comprimir(fitxer: File): Promise<Blob> {
  const imatge = await createImageBitmap(fitxer, { imageOrientation: 'from-image' });
  const escala = Math.min(1, COSTAT_MAX / Math.max(imatge.width, imatge.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(imatge.width * escala);
  canvas.height = Math.round(imatge.height * escala);
  canvas.getContext('2d')!.drawImage(imatge, 0, 0, canvas.width, canvas.height);
  imatge.close();
  return new Promise((resol, rebutja) => {
    canvas.toBlob((b) => (b ? resol(b) : rebutja(new Error('toBlob'))), 'image/jpeg', QUALITAT);
  });
}

export async function pujarFoto(fitxer: File, uid: string, elementId: string): Promise<void> {
  const blob = await comprimir(fitxer);
  const storagePath = `${uid}/${elementId}/${crypto.randomUUID()}.jpg`;
  const pujada = await supabase.storage.from('fotos').upload(storagePath, blob, { contentType: 'image/jpeg' });
  if (pujada.error) throw pujada.error;
  const fila = await supabase.from('element_fotos').insert({ element_id: elementId, storage_path: storagePath, autor_id: uid });
  if (fila.error) throw fila.error;
}

/** remove() no da error si no puede borrar: devuelve menos objetos de los pedidos. */
export async function esborrarFotos(storagePaths: string[]): Promise<void> {
  if (!storagePaths.length) return;
  const { data, error } = await supabase.storage.from('fotos').remove(storagePaths);
  if (error) throw error;
  if (data.length !== storagePaths.length) throw new Error("No s'han esborrat totes les fotos");
}
