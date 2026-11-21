# Fitxa de les botigues (Google Play i App Store)

Textos per a copiar i pegar en Play Console i App Store Connect, en valencià (idioma principal: **català**, que és com el llisten les dues botigues). Versió **1.0.0**.

> ⚠️ **Abans d'enviar-la a revisió** (vegeu [Bloquejos](#bloquejos)): un compte de prova per als revisors d'Apple.

## Dades generals

| Camp | Valor |
|---|---|
| Nom (Play, màx. 30) | `Observatori de l'Horta` |
| Nom (App Store, màx. 30) | `Observatori de l'Horta` |
| Nom davall de la icona | Android: `Observatori de l'Horta` · iOS: `Observatori` |
| Subtítol (App Store, màx. 30) | `Inventari ciutadà de l'Horta` |
| Identificador | Android `com.mamlabsfera.observatori_perlhorta` · iOS `com.mamlabsfera.observatoriPerlhorta` |
| Versió | `1.0.0` |
| Categoria | Play: **Educació** · App Store: primària **Educació**, secundària **Navegació** |
| Preu | Gratuïta, sense compres ni anuncis |
| Desenvolupador / venedor | Associació Per l'Horta (si el compte és seu) |
| Correu de contacte | `desarrollo@mediamapes.com` |
| Web | `https://<domini>` |
| Política de privacitat | `https://<domini>/legal#privacitat` |
| Esborrar el compte (Play: *Data deletion URL*) | `https://<domini>/compte` |
| URL d'assistència (App Store) | `https://<domini>/legal` |
| Copyright (App Store) | `2026 Associació Per l'Horta` |

`<domini>`: el domini definitiu de la web (encara no està triat; mentrestant, l'adreça de Vercel).

## Descripció curta (Play, màx. 80)

```
Mapa ciutadà de l'Horta de València: observa, aporta i revisa el seu estat.
```

## Text promocional (App Store, màx. 170)

```
Ajuda a cuidar l'Horta de València: localitza sèquies, alqueries, arbres o agressions al paisatge i aporta-ho a un inventari obert i compartit.
```

## Descripció (les dues botigues, màx. 4.000)

```
L'Observatori Ciutadà de l'Horta és l'inventari obert de l'Horta de València que fem entre totes i tots. És una iniciativa de l'Associació Per l'Horta.

Recorre l'horta amb el mapa a la mà, mira què hi ha i ajuda a mantindre'l al dia.

QUÈ POTS FER
• Explorar el mapa sobre l'ortofoto: més de 7.000 elements de l'inventari, amb la simbologia de l'Observatori (sèquies i elements de reg, camins, construccions, vegetació, agressions i usos del sòl).
• Aportar el que veus: tria què és, situa-ho al mapa (un punt, una línia o una parcel·la) i afig-hi fotos i una descripció.
• Apadrinar una partida i revisar-la al camp: comprova si cada element segueix igual, ha canviat o ha desaparegut.
• Treballar sense cobertura: descarrega el mapa d'una partida abans d'eixir i les teues revisions s'enviaran soles quan tornes a tindre connexió.
• Rebre avisos quan la coordinació valida o comenta les teues aportacions.
• Consultar la llegenda de tots els símbols.

COM FUNCIONA
Entres amb el teu correu, sense contrasenya. Tot el que aportes ho revisa la coordinació de l'Observatori abans de publicar-ho. Les aportacions validades passen a l'inventari públic, sense el teu nom ni el teu correu.

DADES OBERTES
Les dades de l'inventari es publiquen amb llicència CC BY 4.0 i les fotografies amb CC BY-SA 4.0. El codi de l'aplicació és lliure (AGPL-3.0).

També en mòbil i en tauleta.

L'inventari parteix del treball de camp de 2017-2018 i ara el posem al dia entre totes i tots.
```

## Novetats d'esta versió (màx. 500)

```
Primera versió de l'Observatori Ciutadà de l'Horta.
```

## Paraules clau (App Store, màx. 100, separades per comes)

```
horta,València,inventari,mapa,ciència ciutadana,sèquies,agricultura,patrimoni,paisatge,territori
```

## Classificació per edats

Totes les preguntes de violència, sexe, drogues, apostes, etc.: **No**. Altres respostes:

| Pregunta | Resposta |
|---|---|
| Contingut generat pels usuaris | **Sí**. Es modera: la coordinació revisa cada aportació (text i fotos) abans de publicar-la i pot rebutjar-la o retirar-la. |
| Els usuaris poden comunicar-se entre ells | No |
| Comparteix la ubicació de l'usuari amb altres | No (la ubicació d'una aportació és la de l'element, no la de la persona) |
| Compres | No |

Resultat esperat: **PEGI 3 / 4+**.

## Seguretat de les dades (Play) i privacitat de la app (App Store)

| Dada | Es recull | Per a què | Vinculada a la persona | Compartida amb tercers |
|---|---|---|---|---|
| Correu electrònic | Sí, obligatori | Compte (entrar) | Sí | No |
| Àlies (nom d'usuari) | Sí, obligatori | Compte | Sí | No |
| Ubicació precisa | Sí, opcional | Funcionament: situar una aportació | Sí (la de l'aportació) | No |
| Fotos | Sí, opcional | Funcionament: aportacions | Sí | No (es publiquen, sense autor, si es validen) |
| Altre contingut (descripcions) | Sí, opcional | Funcionament | Sí | No |
| Identificador d'usuari | Sí | Compte | Sí | No |

- Seguiment (tracking) / publicitat: **No**.
- Xifrat en trànsit: **Sí** (HTTPS).
- Es pot esborrar el compte: **Sí**, des de la app (perfil → «Esborra el compte») i des de la web (`/compte`), al moment. Les aportacions validades es queden en l'inventari obert sense vincle amb la persona; la resta s'esborra.
- Còpia de les dades: des de la web (`/compte` → «Descarrega les meues dades», JSON).
- Les fotos perden les metadades (també el GPS de la càmera) en pujar-se.

## Informació per als revisors d'Apple

```
L'app és l'Observatori Ciutadà de l'Horta, un inventari ciutadà del paisatge agrícola de València (Espanya), de l'associació sense ànim de lucre Per l'Horta. L'app està en català (valencià).

Entrada: amb el correu, sense contrasenya (enllaç o codi). Compte de prova: <correu> / <codi o instruccions>.

Contingut generat pels usuaris: tot es revisa per la coordinació abans de publicar-se.
La ubicació només es demana quan la persona toca «La meua posició» o situa una aportació.
Esborrar el compte: perfil (cercle amb la inicial, dalt a la dreta del mapa) → «Esborra el compte».
```

## Captures

| Botiga | Dispositiu | Mida | Carpeta |
|---|---|---|---|
| Google Play | Mòbil | 1080 × 1920 | [`captures/android-mobil/`](captures/android-mobil/): mapa, llegenda, aporta, partides, fitxa, revisió al camp |
| Google Play | Tauleta de 10" | 2560 × 1600 | [`captures/android-tauleta/`](captures/android-tauleta/): mapa, llegenda, aporta, partides, fitxa, avisos |
| App Store | iPhone 6,9" | 1320 × 2868 | les fa el flux `ios-captures` de Codemagic ([CODEMAGIC.md](../CODEMAGIC.md)) |
| App Store | iPad 13" | 2064 × 2752 | les fa el flux `ios-captures` de Codemagic |

A més, Play demana una **icona de 512 × 512** ([`icona-512.png`](icona-512.png)) i un **gràfic destacat de 1024 × 500** ([`grafic-destacat.png`](grafic-destacat.png)).

## Bloquejos

1. ~~Esborrar el compte des de la app~~: fet (app i web `/compte`).
2. **Compte de prova per a Apple.** El revisor ha de poder entrar, i l'entrada és amb un codi que arriba al correu. Cal un camí per al revisor (per exemple, un compte de prova que entra amb un codi fix) i posar-lo en «Informació per als revisors».
3. **Google Play, compte personal nou**: si el compte de desenvolupador és personal i s'ha creat després del 13/11/2023, abans de publicar cal una prova tancada amb 12 persones durant 14 dies. Amb un compte d'organització (Per l'Horta, amb número D-U-N-S) no cal.

Els gràfics de Play es tornen a generar amb `python docs/botigues/generar_grafics.py`.
