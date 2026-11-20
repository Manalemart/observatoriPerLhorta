"""Gràfics de la fitxa de Google Play, a partir de la marca de la app.

- icona-512.png: la icona de la app (la d'iOS, 1024, sense transparència) a 512 × 512.
- grafic-destacat.png: 1024 × 500, la marca en blanc sobre el verd de la app, amb el lema
  i una captura del mapa a la dreta.

Ús (des de l'arrel del repo):  python docs/botigues/generar_grafics.py
Requereix PyMuPDF (pip install pymupdf).
"""
from pathlib import Path

import pymupdf

ARREL = Path(__file__).resolve().parents[2]
APP = ARREL / 'app'
EIXIDA = Path(__file__).resolve().parent

VERD = (0x2C / 255, 0x7A / 255, 0x00 / 255)
LIMA = (0x9E / 255, 0xD1 / 255, 0x00 / 255)


def icona():
    font = pymupdf.Pixmap(str(APP / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'))
    if font.alpha:
        font = pymupdf.Pixmap(font, 0)
    pymupdf.Pixmap(font, 512, 512, None).save(str(EIXIDA / 'icona-512.png'))


def grafic():
    doc = pymupdf.open()
    pagina = doc.new_page(width=1024, height=500)
    pagina.draw_rect(pagina.rect, color=None, fill=VERD)
    # Franja lima a baix, com la línia de les capçaleres de la app
    pagina.draw_rect(pymupdf.Rect(0, 488, 1024, 500), color=None, fill=LIMA)

    # A la dreta, el mapa del mòbil, retallat i amb vora blanca
    mapa = EIXIDA / 'captures/android-mobil/01_mapa.png'
    caixa = pymupdf.Rect(640, 40, 640 + 300, 40 + 534)
    pagina.draw_rect(caixa + (-6, -6, 6, 6), color=None, fill=(1, 1, 1), radius=0.06)
    pagina.insert_image(caixa, filename=str(mapa), keep_proportion=False)

    # A l'esquerra, la marca i el lema
    pagina.insert_image(pymupdf.Rect(48, 110, 48 + 520, 110 + 208), filename=str(APP / 'assets/marca_blanca.png'))
    pagina.insert_font(fontname='mont', fontfile=str(APP / 'assets/fonts/Montserrat-700.ttf'))
    pagina.insert_text((64, 370), "Observa, aporta i revisa", fontname='mont', fontsize=30, color=(1, 1, 1))
    pagina.insert_text((64, 410), "l'estat de l'Horta de València", fontname='mont', fontsize=30, color=(1, 1, 1))

    pix = pagina.get_pixmap(matrix=pymupdf.Matrix(1, 1), alpha=False, clip=pymupdf.Rect(0, 0, 1024, 500))
    pix.save(str(EIXIDA / 'grafic-destacat.png'))


icona()
grafic()
print('Fet: icona-512.png i grafic-destacat.png')
