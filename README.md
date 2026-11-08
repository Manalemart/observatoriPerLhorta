# Observatori Ciutadà de l'Horta

Plataforma de ciencia ciudadana para inventariar y vigilar el estado de l'Horta de València.
Promueve **Per l'Horta** · desarrollo técnico y tecnológico **MAM — Mediambient i Mapes**.

Es la nueva versión del observatorio de 2017-2018 (Drupal 7 + PostGIS), rehecha sobre
Supabase, una web React y una app Flutter. La documentación del proyecto está en Obsidian
(`MAM/Desarrollo Apps/OBSERVATORI`).

## Estructura

| Carpeta | Contenido |
|---------|-----------|
| `supabase/` | Migraciones SQL (esquema, lógica, RLS), seed del catálogo y tests pgTAP |
| `web/` | Web pública y panel de validación — React + Vite + MapLibre *(pendiente)* |
| `app/` | App de campo — Flutter *(pendiente)* |
| `etl/` | Migración de los datos de 2017-2018 *(pendiente)* |
| `docs/` | Documentación técnica que acompaña al código |

## Desarrollo local

Requisitos: Docker Desktop y Node 20+.

```bash
npx supabase start -x studio,imgproxy,logflare,vector,supavisor,edge-runtime,realtime,postgres-meta,mailpit
npx supabase db reset     # aplica migraciones + seed
npx supabase test db      # tests pgTAP
```

Los puertos locales se han movido a **643xx** (API 64321, BD 64322) porque los 543xx
están reservados por Hyper-V en la máquina de desarrollo.

## Licencias

- Código: [AGPL-3.0](LICENSE)
- Datos: [CC BY 4.0](DATA_LICENSE.md) — «Observatori Ciutadà de l'Horta — Per l'Horta»
- Fotos aportadas: CC BY-SA 4.0
