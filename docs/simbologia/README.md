# Simbología del mapa

La simbología de la web y de la app sale de la guía de diseño de Per l'Horta («Símbols finals»), que está en [`guia/`](guia/):

| PDF | Contenido |
|---|---|
| `0_paleta.pdf` | Paleta autorizada: `#84786d` `#574F46` `#009EE0` `#244c0b` `#348e00` `#9ED100` `#E2001A` `#422515` `#F9AC00` |
| `1_punts_reg_serveis.pdf` | Puntos: sistema de riego (gota azul) y abastecimientos y servicios (cuadrado marrón) |
| `2_punts_construccions_vegetacio_agressio.pdf` | Puntos: construcciones (casa naranja), vegetación (círculo verde), agresiones (triángulo rojo) |
| `3_linies.pdf` | Líneas: acequias, caminos y sendas, cerramientos |
| `4_parceles.pdf` | Parcelas cultivadas y sin cultivar: color y trama |

## Cómo se genera

```bash
python docs/simbologia/generar.py
```

Requiere PyMuPDF (`pip install pymupdf`). El script:

1. Recorta del PDF las 51 iconos de los puntos (son vectoriales y tienen el fondo transparente) y los guarda como PNG en `web/public/simbols/` y `app/assets/simbols/`.
2. Escribe las equivalencias y los estilos en `web/src/features/mapa/simbologia.json` y `app/assets/simbologia.json`. Son el mismo fichero: web y app nunca divergen.

Para cambiar una equivalencia o un estilo, se edita `generar.py` y se vuelve a ejecutar. Los JSON no se editan a mano.

## Equivalencias

Las reglas van por **nombre** de variable y categoría (los ids pueden cambiar entre bases de datos). Para cada elemento se busca, en este orden: la regla de su variable y categoría, la de su variable, y si no hay ninguna, el símbolo general de la familia de su tema.

Decisiones donde la guía y el catálogo no coinciden exactamente:

- **Infraestructura** es un solo tema en el catálogo, pero en el mapa se separa como en la guía: *Elements del sistema de reg* y *Sèquies* en azul (riego); *Abastiments i serveis*, *Contenidors*, *Tanques d'accés*, *Tancaments* y *Vials* en marrón (servicios).
- Torres de alta y de media tensión (categorías de *Abastiments i serveis*): triángulo rojo de agresión, como en la guía. El transformador, casa naranja.
- *Subestació* (construcciones): el cuadrado de servicios de la guía.
- *Alqueria*, *Barraca* y *Vil·la*: la casa sin dibujo. *Indústria*, *Nau* y *Magatzem*: nave. *Dipòsit*: «otros» de construcciones. *Ermita*: edificio religioso.
- Vegetación: *Figuera*, *Garrofera* y *Olivera* son árbol frutal; *Llidoner*, *Llorer*, *Om* y *Xop*, árbol no frutal; *Altra vegetació*, el círculo verde sin dibujo.
- *Via pecuària*: como camino (doble línea).
- *Tancaments / Altre*: línea marrón continua.

El color de cada tema (casillas, leyenda, fichas) es el de su familia en la guía; lo fija la migración `20261119000001_simbologia.sql` y `seed.sql`.

## Cómo se dibuja

- **Puntos.** Web: de lejos (zoom < 14), un círculo del color de la familia; de cerca, el icono. App: siempre el icono (la app solo muestra elementos desde zoom 13).
- **Agrupación.** Cuando varios puntos de la misma variable y categoría se pisan, se pinta un solo icono dentro de un círculo blanco, con el número de elementos en una pastilla del color de la familia. Al tocarlo, el mapa se acerca hasta separarlos. Categorías distintas nunca se agrupan; desde el zoom 18 no se agrupa. Web: `web/src/features/mapa/agrupacio.ts`; app: `app/lib/ui/capa_punts.dart`.
- **Parcelas.** Color de la guía al 75 % (para que se vea la ortofoto) con su contorno; las tramas de rayas y puntos en blanco encima.
- **Líneas.** Color, grosor y discontinuo de la guía. La decoración (flechas de las acequias, cuadrados de la pared de piedra, travesaños, zigzag, onda) se repite a lo largo del trazo. Las formas están dibujadas igual en la web (`web/src/features/mapa/simbologia.ts`) y en la app (`app/lib/ui/capa_simbologia.dart`).
- **Estado.** Lo de 2017-2018 sin revisar: icono más pálido y parcela con contorno discontinuo (de lejos, en la web, punto hueco). Lo no validado (solo lo ve quien tiene permiso): anillo o contorno negro.
- **Leyenda.** Web: en el panel, cada variable con su símbolo y, debajo, las categorías que tienen uno propio. App: botón de lista en la barra del mapa.
