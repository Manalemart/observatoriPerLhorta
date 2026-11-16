"""Genera la icona i les imatges de la pantalla d'inici d'iOS.

- Icona: el símbol de l'Observatori, vectorial des del PDF del manual d'identitat
  (pàgina índex 3), sobre fons blanc i sense transparència, amb marge.
- Pantalla d'inici: copia les imatges de la pantalla d'inici d'Android
  (mdpi/xhdpi/xxhdpi = @1x/@2x/@3x), perquè les dues plataformes isquen iguals.

Ús (des de app/):  python ios/eines/generar_recursos.py [ruta/al/manual.pdf]
Requereix PyMuPDF (pip install pymupdf).
"""
import json
import shutil
import sys
from pathlib import Path

import pymupdf

APP = Path(__file__).resolve().parents[2]
PDF = Path(sys.argv[1] if len(sys.argv) > 1 else 'C:/Users/Manel/Downloads/Lobservatori_Manual_dIdentitat_Corporativa.pdf')
PAGINA = 3
SIMBOL = pymupdf.Rect(525.1, 56.6, 634.5, 173.5)
ALT_SIMBOL = 0.68  # part de l'alçada de la icona que ocupa el símbol

ASSETS = APP / 'ios/Runner/Assets.xcassets'
RES = APP / 'android/app/src/main/res'


def icona_mestra() -> pymupdf.Document:
    font = pymupdf.open(PDF)
    doc = pymupdf.open()
    pagina = doc.new_page(width=1024, height=1024)
    alt = 1024 * ALT_SIMBOL
    ample = alt * SIMBOL.width / SIMBOL.height
    desti = pymupdf.Rect((1024 - ample) / 2, (1024 - alt) / 2, (1024 + ample) / 2, (1024 + alt) / 2)
    pagina.show_pdf_page(desti, font, PAGINA, clip=SIMBOL)
    return doc


def icones():
    carpeta = ASSETS / 'AppIcon.appiconset'
    pagina = icona_mestra()[0]
    for imatge in json.loads((carpeta / 'Contents.json').read_text())['images']:
        costat = round(float(imatge['size'].split('x')[0]) * int(imatge['scale'][0]))
        pix = pagina.get_pixmap(matrix=pymupdf.Matrix(costat / 1024, costat / 1024), alpha=False)
        assert pix.width == costat, (imatge, pix.width)
        pix.save(carpeta / imatge['filename'])


def conjunt(nom: str, android: str, fosc: bool = False):
    carpeta = ASSETS / f'{nom}.imageset'
    if carpeta.exists():
        shutil.rmtree(carpeta)
    carpeta.mkdir()
    imatges = []
    for escala, dpi in (('1x', 'mdpi'), ('2x', 'xhdpi'), ('3x', 'xxhdpi')):
        sufix = '' if escala == '1x' else f'@{escala}'
        shutil.copy(RES / f'drawable-{dpi}/{android}.png', carpeta / f'{nom}{sufix}.png')
        imatges.append({'idiom': 'universal', 'filename': f'{nom}{sufix}.png', 'scale': escala})
        if fosc:
            shutil.copy(RES / f'drawable-night-{dpi}/{android}.png', carpeta / f'{nom}Fosc{sufix}.png')
            imatges.append({
                'idiom': 'universal', 'filename': f'{nom}Fosc{sufix}.png', 'scale': escala,
                'appearances': [{'appearance': 'luminosity', 'value': 'dark'}],
            })
    (carpeta / 'Contents.json').write_text(json.dumps({'images': imatges, 'info': {'version': 1, 'author': 'xcode'}}, indent=2) + '\n')


if __name__ == '__main__':
    icones()
    conjunt('LaunchImage', 'splash_simbol')
    conjunt('LaunchMarca', 'splash_marca', fosc=True)
    print('Fet')
