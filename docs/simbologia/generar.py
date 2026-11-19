"""Genera la simbologia del mapa (web i app) a partir de la guia de disseny.

Font: els PDF de guia/ (Per l'Horta, «Símbols finals»). Les icones dels punts es retallen
tal qual dels PDF (són vectorials, fons transparent); les línies i les parcel·les són estils
(color, trama, decoració) que dibuixen la web i l'app amb les mateixes dades.

Ix:
  web/public/simbols/<icona>.png         icones dels punts
  web/src/features/mapa/simbologia.json  equivalències i estils
  app/assets/simbols/<icona>.png
  app/assets/simbologia.json

Ús (des de l'arrel del repositori):  python docs/simbologia/generar.py
Cal PyMuPDF (pip install pymupdf).
"""

import json
import os

import pymupdf

ARREL = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GUIA = os.path.join(ARREL, 'docs', 'simbologia', 'guia')
DPI = 144  # ~120 px d'alt: nítid a 3x per a una icona de 36-40 px

# Caixes (x, y, amplada, alçada) en punts de la pàgina girada, tal com es veu el PDF
ICONES = {
    '1_punts_reg_serveis.pdf': {
        'reg': (421, 32, 50, 62),
        'assut': (309, 132, 51, 62), 'noria': (309, 201, 51, 62), 'font': (309, 271, 51, 62),
        'mina': (309, 341, 51, 61), 'aliviadero': (309, 410, 51, 62), 'gola': (308, 480, 51, 62),
        'partidor': (309, 550, 51, 61), 'anell': (309, 623, 51, 61), 'sifo': (309, 689, 51, 62),
        'canaleta': (309, 759, 51, 61),
        'roll': (618, 135, 51, 62), 'fila': (619, 209, 51, 62), 'aljub': (618, 284, 51, 61),
        'bassa': (621, 358, 51, 62), 'pou': (621, 432, 51, 62), 'atandador': (621, 507, 51, 61),
        'reg_altre': (624, 581, 51, 62),
        'serveis': (951, 35, 56, 56), 'gas': (951, 130, 56, 56), 'aigua_elevat': (951, 200, 56, 56),
        'bombeig': (951, 269, 56, 56), 'depuradora': (951, 339, 56, 56),
        'potabilitzadora': (951, 409, 56, 56), 'subestacio': (951, 548, 56, 56),
        'contenidor': (951, 617, 56, 56), 'ecoparc': (951, 687, 56, 56), 'tanca_cami': (951, 757, 56, 56),
    },
    '2_punts_construccions_vegetacio_agressio.pdf': {
        'construccio': (296, 33, 62, 62), 'moli': (236, 185, 62, 62), 'religios': (236, 263, 61, 62),
        'castell': (236, 341, 61, 62), 'nau': (236, 419, 61, 62), 'xemeneia': (236, 498, 61, 61),
        'cementeri': (236, 576, 61, 62), 'cebera': (236, 654, 61, 63), 'transformador': (236, 732, 61, 62),
        'motor': (434, 581, 64, 62), 'caseta': (436, 655, 61, 62), 'construccio_altre': (431, 732, 61, 62),
        'vegetacio': (703, 33, 62, 62), 'frutal': (729, 126, 48, 69), 'no_frutal': (727, 204, 47, 69),
        'canyar': (712, 294, 62, 62), 'barreja': (721, 399, 47, 68),
        'agressio': (1007, 39, 63, 53), 'aparcament': (1001, 131, 64, 54),
        'tanca_publicitaria': (1001, 188, 64, 54), 'abocador': (1001, 245, 64, 54),
        'torre_tensio': (999, 302, 65, 54), 'agressio_altre': (1001, 362, 64, 55),
    },
}

# Famílies de punts (guia: punts) i el seu color web i de contorn
FAMILIES = {
    'reg': {'nom': 'Sistema de reg', 'color': '#009EE0', 'contorn': '#574F46', 'icona': 'reg'},
    'serveis': {'nom': 'Abastiments i serveis', 'color': '#574F46', 'contorn': '#000000', 'icona': 'serveis'},
    'construccions': {'nom': 'Construccions', 'color': '#F9AC00', 'contorn': '#574F46', 'icona': 'construccio'},
    'vegetacio': {'nom': 'Vegetació', 'color': '#348E00', 'contorn': '#574F46', 'icona': 'vegetacio'},
    'agressions': {'nom': 'Agressions', 'color': '#E2001A', 'contorn': '#574F46', 'icona': 'agressio'},
}

# Si no hi ha res més concret: la família del tema
FAMILIA_TEMA = {
    'Agressions': 'agressions', 'Construccions': 'construccions', 'Infraestructura': 'serveis',
    'Vegetació': 'vegetacio', 'Ús del sòl': 'construccions',
}

# Punts: (variable, categoria o None per a totes, icona, família)
PUNTS = [
    ('Abocament (sòlid ó liquid)', None, 'abocador', 'agressions'),
    ('Altres agressions (text lliure)', None, 'agressio_altre', 'agressions'),
    ('Aparcament', None, 'aparcament', 'agressions'),
    ('Tanques publicitaries', None, 'tanca_publicitaria', 'agressions'),
    ('Torre de tensió', None, 'torre_tensio', 'agressions'),

    ('Alqueria', None, 'construccio', 'construccions'),
    ('Barraca', None, 'construccio', 'construccions'),
    ('Vil·la', None, 'construccio', 'construccions'),
    ('Altre (text lliure)', None, 'construccio_altre', 'construccions'),
    ('Caseta de ferramentes', None, 'caseta', 'construccions'),
    ('Castell', None, 'castell', 'construccions'),
    ('Cebera', None, 'cebera', 'construccions'),
    ('Cementeri', None, 'cementeri', 'construccions'),
    ('Dipòsit', None, 'construccio_altre', 'construccions'),
    ('Ermita', None, 'religios', 'construccions'),
    ('Indústria', None, 'nau', 'construccions'),
    ('Nau', None, 'nau', 'construccions'),
    ('Magatzem', None, 'nau', 'construccions'),
    ('Molí', None, 'moli', 'construccions'),
    ('Motor', None, 'motor', 'construccions'),
    ('Subestació', None, 'subestacio', 'serveis'),
    ('Transformador', None, 'transformador', 'construccions'),
    ('Xemeneia ó fumeral', None, 'xemeneia', 'construccions'),

    ('Abastiments i serveis', None, 'serveis', 'serveis'),
    ('Abastiments i serveis', 'Contenidor', 'contenidor', 'serveis'),
    ('Abastiments i serveis', 'Depuradora', 'depuradora', 'serveis'),
    ('Abastiments i serveis', "Dipòsit d'aigua elevat", 'aigua_elevat', 'serveis'),
    ('Abastiments i serveis', 'Dipòsit de gas', 'gas', 'serveis'),
    ('Abastiments i serveis', 'Ecoparc', 'ecoparc', 'serveis'),
    ('Abastiments i serveis', 'Estació de bombeig', 'bombeig', 'serveis'),
    ('Abastiments i serveis', 'Potabilitzadora', 'potabilitzadora', 'serveis'),
    ('Abastiments i serveis', 'Tanca', 'tanca_cami', 'serveis'),
    ('Abastiments i serveis', "Torre d'alta tensió", 'torre_tensio', 'agressions'),
    ('Abastiments i serveis', 'Torre de mitja o baixa tensió', 'torre_tensio', 'agressions'),
    ('Abastiments i serveis', 'Transformador', 'transformador', 'construccions'),
    ('Contenidors (punt de replega de residus)', None, 'contenidor', 'serveis'),
    ("Tanques d'accés als camins", None, 'tanca_cami', 'serveis'),

    ('Elements del sistema de reg', None, 'reg', 'reg'),
    ('Elements del sistema de reg', 'Aljup', 'aljub', 'reg'),
    ('Elements del sistema de reg', 'Almenara ó Aliviadero', 'aliviadero', 'reg'),
    ('Elements del sistema de reg', 'Altre element de reg (text lliure)', 'reg_altre', 'reg'),
    ('Elements del sistema de reg', 'Anell (canals principals)', 'anell', 'reg'),
    ('Elements del sistema de reg', 'Assut', 'assut', 'reg'),
    ('Elements del sistema de reg', 'Atandador', 'atandador', 'reg'),
    ('Elements del sistema de reg', 'Bassa', 'bassa', 'reg'),
    ('Elements del sistema de reg', 'Canaleta', 'canaleta', 'reg'),
    ('Elements del sistema de reg', 'Fila (angle)', 'fila', 'reg'),
    ('Elements del sistema de reg', 'Font ó ullal', 'font', 'reg'),
    ('Elements del sistema de reg', 'Gola', 'gola', 'reg'),
    ('Elements del sistema de reg', 'Mina ó canat', 'mina', 'reg'),
    ('Elements del sistema de reg', 'Nòria ó sènia', 'noria', 'reg'),
    ('Elements del sistema de reg', 'Partidor', 'partidor', 'reg'),
    ('Elements del sistema de reg', 'Pou', 'pou', 'reg'),
    ('Elements del sistema de reg', 'Roll (perpendicular)', 'roll', 'reg'),
    ('Elements del sistema de reg', 'Sifó (canó)', 'sifo', 'reg'),

    ('Altra vegetació (text lliure)', None, 'vegetacio', 'vegetacio'),
    ("Barreja d'epècies", None, 'barreja', 'vegetacio'),
    ('Canyar', None, 'canyar', 'vegetacio'),
    ('Figuera', None, 'frutal', 'vegetacio'),
    ('Garrofera', None, 'frutal', 'vegetacio'),
    ('Olivera', None, 'frutal', 'vegetacio'),
    ('Llidoner', None, 'no_frutal', 'vegetacio'),
    ('Llorer', None, 'no_frutal', 'vegetacio'),
    ('Om', None, 'no_frutal', 'vegetacio'),
    ('Xop', None, 'no_frutal', 'vegetacio'),
]

# Línies. patro: continua | discontinua | puntejada | punt_ratlla | doble | cap (només decoració)
# glif (decoració al llarg de la línia): fletxa | quadrat | travesser | mur | x | ziga | ona
ESTILS_LINIA = {
    'sequia_obra': {'nom': "Sèquia d'obra", 'color': '#009EE0', 'amplada': 2.5, 'patro': 'continua', 'glif': 'fletxa'},
    'sequia_terra': {'nom': 'Sèquia de terra', 'color': '#009EE0', 'amplada': 2, 'patro': 'puntejada', 'glif': 'fletxa'},
    'sequia_mixta': {'nom': 'Sèquia mixta', 'color': '#009EE0', 'amplada': 2, 'patro': 'punt_ratlla', 'glif': 'fletxa'},
    'sequia_soterrada': {'nom': 'Sèquia soterrada', 'color': '#009EE0', 'amplada': 2, 'patro': 'discontinua', 'glif': 'fletxa'},
    'cami': {'nom': 'Camí', 'color': '#574F46', 'amplada': 4, 'patro': 'doble'},
    'senda': {'nom': 'Senda', 'color': '#574F46', 'amplada': 2, 'patro': 'discontinua'},
    'paret_pedra': {'nom': 'Paret de pedra', 'color': '#574F46', 'amplada': 1, 'patro': 'cap', 'glif': 'quadrat'},
    'mur': {'nom': "Mur d'obra", 'color': '#574F46', 'amplada': 1.5, 'patro': 'continua', 'glif': 'mur'},
    'malla': {'nom': 'Malla metàl·lica', 'color': '#574F46', 'amplada': 1, 'patro': 'continua', 'glif': 'travesser'},
    'tanca_mixta': {'nom': 'Mixt (obra i metàl·lica)', 'color': '#574F46', 'amplada': 1.5, 'patro': 'cap', 'glif': 'ziga'},
    'somiers': {'nom': 'Somiers, fustes', 'color': '#574F46', 'amplada': 1, 'patro': 'continua', 'glif': 'x'},
    'tanca': {'nom': 'Tancament', 'color': '#574F46', 'amplada': 1.5, 'patro': 'continua'},
    'tanca_vegetal': {'nom': 'Tanca vegetal', 'color': '#348E00', 'amplada': 1.5, 'patro': 'cap', 'glif': 'ona'},
}

LINIES = [
    ('Sèquies', None, 'sequia_obra'),
    ('Sèquies', "Caixer d'obra", 'sequia_obra'),
    ('Sèquies', 'Caixer de terra', 'sequia_terra'),
    ('Sèquies', 'Mixt (obra i terra)', 'sequia_mixta'),
    ('Sèquies', 'Soterrada', 'sequia_soterrada'),
    ('Vials', None, 'cami'),
    ('Vials', 'Camí', 'cami'),
    ('Vials', 'Senda', 'senda'),
    ('Vials', 'Via pecuària', 'cami'),
    ('Tancaments', None, 'tanca'),
    ('Tancaments', 'Paretó de pedra', 'paret_pedra'),
    ('Tancaments', "Mur d'obra", 'mur'),
    ('Tancaments', 'Malla metàl·lica', 'malla'),
    ('Tancaments', "Mixt (part d'obra i part metàl·lica)", 'tanca_mixta'),
    ('Tancaments', 'Matalassos, fustes, enderrocs', 'somiers'),
    ('Tancaments', 'Bardissa', 'tanca_vegetal'),
]

# Parcel·les. trama: null | ratlles | punts (en blanc sobre el color)
ESTILS_PARCELA = {
    'horticola_intensiu': {'nom': 'Hortícola intensiu', 'color': '#244c0b', 'contorn': '#574F46', 'trama': None},
    'horticola_diversificat': {'nom': 'Hortícola diversificat', 'color': '#244c0b', 'contorn': '#574F46', 'trama': 'ratlles'},
    'fruiters': {'nom': 'Fruiters', 'color': '#9ED100', 'contorn': '#574F46', 'trama': 'punts'},
    'ornamental': {'nom': 'Ornamental', 'color': '#9ED100', 'contorn': '#574F46', 'trama': None},
    'abandonat': {'nom': 'Abandonat', 'color': '#F9AC00', 'contorn': '#574F46', 'trama': None},
    'guaret': {'nom': 'Guaret', 'color': '#F9AC00', 'contorn': '#574F46', 'trama': 'ratlles'},
    'per_determinar': {'nom': 'Per determinar', 'color': '#84786d', 'contorn': '#000000', 'trama': None},
    'agrari': {'nom': 'Altres usos agraris', 'color': '#422515', 'contorn': '#574F46', 'trama': 'punts'},
    'no_agrari': {'nom': 'Altres usos no agraris', 'color': '#422515', 'contorn': '#574F46', 'trama': None},
}

PARCELES = [
    ('Parcel·les cultivades', None, 'horticola_intensiu'),
    ('Parcel·les cultivades', 'Hortícola Intensiu', 'horticola_intensiu'),
    ('Parcel·les cultivades', 'Hortícola Diversificat', 'horticola_diversificat'),
    ('Parcel·les cultivades', 'Fruiters', 'fruiters'),
    ('Parcel·les cultivades', 'Ornamental', 'ornamental'),
    ('Parcel·les sense cultivar', None, 'per_determinar'),
    ('Parcel·les sense cultivar', 'Abandonat', 'abandonat'),
    ('Parcel·les sense cultivar', 'Guaret', 'guaret'),
    ('Parcel·les sense cultivar', 'Per determinar', 'per_determinar'),
    ('Parcel·les sense cultivar', 'Agrari', 'agrari'),
    ('Parcel·les sense cultivar', 'No Agrari', 'no_agrari'),
]

# Color de cada tema (pastilles i llegenda): el de la seua família a la guia
COLORS_TEMA = {
    'Agressions': '#E2001A', 'Construccions': '#F9AC00', 'Infraestructura': '#009EE0',
    'Ús del sòl': '#9ED100', 'Vegetació': '#348E00',
}

PALETA = ['#84786d', '#574F46', '#009EE0', '#244c0b', '#348e00', '#9ED100', '#E2001A', '#422515', '#F9AC00']


def regla(variable, categoria, **valors):
    r = {'variable': variable}
    if categoria is not None:
        r['categoria'] = categoria
    r.update(valors)
    return r


def main():
    dirs = [os.path.join(ARREL, 'web', 'public', 'simbols'), os.path.join(ARREL, 'app', 'assets', 'simbols')]
    for d in dirs:
        os.makedirs(d, exist_ok=True)
    mides = {}
    for pdf, icones in ICONES.items():
        pagina = pymupdf.open(os.path.join(GUIA, pdf))[0]
        for nom, (x, y, w, h) in icones.items():
            caixa = pymupdf.Rect(x - 1, y - 1, x + w + 2, y + h + 2)
            pm = pagina.get_pixmap(dpi=DPI, clip=caixa, alpha=True)
            for d in dirs:
                pm.save(os.path.join(d, f'{nom}.png'))
            mides[nom] = [pm.width, pm.height]

    usades = {i for (_, _, i, _) in PUNTS} | {f['icona'] for f in FAMILIES.values()}
    falten = usades - set(mides)
    assert not falten, f'icones sense retallar: {falten}'

    dades = {
        'font': 'docs/simbologia/guia (Per l\'Horta, símbols finals). Generat per docs/simbologia/generar.py',
        'paleta': PALETA,
        'colorsTema': COLORS_TEMA,
        'familiaTema': FAMILIA_TEMA,
        'families': FAMILIES,
        'icones': mides,
        'punts': [regla(v, c, icona=i, familia=f) for (v, c, i, f) in PUNTS],
        'estilsLinia': ESTILS_LINIA,
        'linies': [regla(v, c, estil=e) for (v, c, e) in LINIES],
        'estilsParcela': ESTILS_PARCELA,
        'parceles': [regla(v, c, estil=e) for (v, c, e) in PARCELES],
    }
    text = json.dumps(dades, ensure_ascii=False, indent=1) + '\n'
    for desti in (os.path.join(ARREL, 'web', 'src', 'features', 'mapa', 'simbologia.json'),
                  os.path.join(ARREL, 'app', 'assets', 'simbologia.json')):
        with open(desti, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
    print(f'{len(mides)} icones, {len(PUNTS)} punts, {len(LINIES)} línies, {len(PARCELES)} parcel·les')


if __name__ == '__main__':
    main()
