-- ═══════════════════════════════════════════════════════════════════════════
-- Noms del catàleg en castellà i anglés (temes, variables i categories).
--
-- El nom de sempre (nom) és el valencià i continua sent la clau: la simbologia, les
-- exportacions i les regles van per ell. nom_es i nom_en són per a mostrar; si falten
-- (un tema o una categoria nous), la web i la app mostren el valencià.
-- Les traduccions van per nom (els ids poden canviar entre bases de dades).
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.temes add column if not exists nom_es text, add column if not exists nom_en text;
alter table public.variables add column if not exists nom_es text, add column if not exists nom_en text;
alter table public.categories add column if not exists nom_es text, add column if not exists nom_en text;

update public.temes t set nom_es = v.es, nom_en = v.en
from (values
  ('Agressions', 'Agresiones', 'Threats'),
  ('Construccions', 'Construcciones', 'Buildings'),
  ('Infraestructura', 'Infraestructura', 'Infrastructure'),
  ('Ús del sòl', 'Uso del suelo', 'Land use'),
  ('Vegetació', 'Vegetación', 'Vegetation')
) v(ca, es, en)
where t.nom = v.ca;

update public.variables t set nom_es = v.es, nom_en = v.en
from (values
  ('Abocament (sòlid ó liquid)', 'Vertido (sólido o líquido)', 'Dumping (solid or liquid)'),
  ('Altres agressions (text lliure)', 'Otras agresiones (texto libre)', 'Other threats (free text)'),
  ('Aparcament', 'Aparcamiento', 'Parking'),
  ('Tanques publicitaries', 'Vallas publicitarias', 'Billboards'),
  ('Torre de tensió', 'Torre eléctrica', 'Power pylon'),
  ('Alqueria', 'Alquería', 'Alqueria (farmhouse)'),
  ('Altre (text lliure)', 'Otro (texto libre)', 'Other (free text)'),
  ('Barraca', 'Barraca', 'Barraca (thatched cottage)'),
  ('Caseta de ferramentes', 'Caseta de herramientas', 'Tool shed'),
  ('Castell', 'Castillo', 'Castle'),
  ('Cebera', 'Cebollero (secadero de cebollas)', 'Onion drying shed'),
  ('Cementeri', 'Cementerio', 'Cemetery'),
  ('Dipòsit', 'Depósito', 'Tank'),
  ('Ermita', 'Ermita', 'Hermitage'),
  ('Indústria', 'Industria', 'Industry'),
  ('Magatzem', 'Almacén', 'Warehouse'),
  ('Molí', 'Molino', 'Mill'),
  ('Motor', 'Motor (casa de bombeo)', 'Pump house'),
  ('Nau', 'Nave', 'Shed'),
  ('Subestació', 'Subestación', 'Substation'),
  ('Transformador', 'Transformador', 'Transformer'),
  ('Vil·la', 'Villa', 'Villa'),
  ('Xemeneia ó fumeral', 'Chimenea', 'Chimney'),
  ('Abastiments i serveis', 'Abastecimientos y servicios', 'Supplies and services'),
  ('Contenidors (punt de replega de residus)', 'Contenedores (punto de recogida de residuos)', 'Bins (waste collection point)'),
  ('Elements del sistema de reg', 'Elementos del sistema de riego', 'Irrigation system features'),
  ('Sèquies', 'Acequias', 'Irrigation channels (sèquies)'),
  ('Tancaments', 'Cerramientos', 'Fences and walls'),
  ('Tanques d''accés als camins', 'Vallas de acceso a los caminos', 'Path access gates'),
  ('Vials', 'Viales', 'Roads and paths'),
  ('Parcel·les sense cultivar', 'Parcelas sin cultivar', 'Uncultivated plots'),
  ('Parcel·les cultivades', 'Parcelas cultivadas', 'Cultivated plots'),
  ('Altra vegetació (text lliure)', 'Otra vegetación (texto libre)', 'Other vegetation (free text)'),
  ('Barreja d''epècies', 'Mezcla de especies', 'Mixed species'),
  ('Canyar', 'Cañaveral', 'Reed bed'),
  ('Figuera', 'Higuera', 'Fig tree'),
  ('Garrofera', 'Algarrobo', 'Carob tree'),
  ('Llidoner', 'Almez', 'Nettle tree'),
  ('Llorer', 'Laurel', 'Bay laurel'),
  ('Olivera', 'Olivo', 'Olive tree'),
  ('Om', 'Olmo', 'Elm'),
  ('Xop', 'Chopo', 'Poplar')
) v(ca, es, en)
where t.nom = v.ca;

update public.categories t set nom_es = v.es, nom_en = v.en
from (values
  ('Sense categoria', 'Sin categoría', 'No category'),
  ('Sense Categoria', 'Sin categoría', 'No category'),
  ('Ben conservat', 'Bien conservado', 'Well preserved'),
  ('En construcció', 'En construcción', 'Under construction'),
  ('Mal conservat', 'Mal conservado', 'Poorly preserved'),
  ('Runa', 'Ruina', 'Ruin'),
  ('Altre  abastiment i servei (text lliure)', 'Otro abastecimiento o servicio (texto libre)', 'Other supply or service (free text)'),
  ('Contenidor', 'Contenedor', 'Bin'),
  ('Depuradora', 'Depuradora', 'Wastewater treatment plant'),
  ('Dipòsit d''aigua elevat', 'Depósito de agua elevado', 'Water tower'),
  ('Ecoparc', 'Ecoparque', 'Recycling centre'),
  ('Estació de bombeig', 'Estación de bombeo', 'Pumping station'),
  ('Potabilitzadora', 'Potabilizadora', 'Drinking water treatment plant'),
  ('Torre d''alta tensió', 'Torre de alta tensión', 'High-voltage pylon'),
  ('Torre de mitja o baixa tensió', 'Torre de media o baja tensión', 'Medium or low-voltage pole'),
  ('Transformador', 'Transformador', 'Transformer'),
  ('Dipòsit de gas', 'Depósito de gas', 'Gas tank'),
  ('Tanca', 'Valla', 'Fence'),
  ('Aljup', 'Aljibe', 'Cistern'),
  ('Almenara ó Aliviadero', 'Almenara o aliviadero', 'Overflow sluice'),
  ('Altre element de reg (text lliure)', 'Otro elemento de riego (texto libre)', 'Other irrigation feature (free text)'),
  ('Anell (canals principals)', 'Anillo (canales principales)', 'Ring (main channels)'),
  ('Assut', 'Azud', 'Weir'),
  ('Atandador', 'Atandador (compuerta de riego)', 'Irrigation gate'),
  ('Bassa', 'Balsa', 'Pond'),
  ('Canaleta', 'Canaleta', 'Small channel'),
  ('Fila (angle)', 'Fila (ángulo)', 'Fila (angled branch)'),
  ('Font ó ullal', 'Fuente o manantial', 'Spring'),
  ('Gola', 'Gola (desembocadura)', 'Outlet'),
  ('Mina ó canat', 'Mina o qanat', 'Underground conduit (qanat)'),
  ('Nòria ó sènia', 'Noria', 'Water wheel (noria)'),
  ('Partidor', 'Partidor', 'Flow divider'),
  ('Pou', 'Pozo', 'Well'),
  ('Roll (perpendicular)', 'Roll (perpendicular)', 'Roll (perpendicular branch)'),
  ('Sifó (canó)', 'Sifón', 'Siphon'),
  ('Caixer d''obra', 'Cauce de obra', 'Masonry channel'),
  ('Caixer de terra', 'Cauce de tierra', 'Earth channel'),
  ('Mixt (obra i terra)', 'Mixto (obra y tierra)', 'Mixed (masonry and earth)'),
  ('Soterrada', 'Soterrada', 'Underground'),
  ('Altre (text lliure)', 'Otro (texto libre)', 'Other (free text)'),
  ('Bardissa', 'Seto', 'Hedge'),
  ('Malla metàl·lica', 'Malla metálica', 'Wire mesh'),
  ('Matalassos, fustes, enderrocs', 'Colchones, maderas, escombros', 'Mattresses, planks, rubble'),
  ('Mixt (part d''obra i part metàl·lica)', 'Mixto (parte de obra y parte metálica)', 'Mixed (part masonry, part metal)'),
  ('Mur d''obra', 'Muro de obra', 'Masonry wall'),
  ('Paretó de pedra', 'Murete de piedra', 'Dry stone wall'),
  ('Camí', 'Camino', 'Track'),
  ('Senda', 'Senda', 'Footpath'),
  ('Via pecuària', 'Vía pecuaria', 'Drove road'),
  ('Agrari', 'Agrario', 'Agricultural'),
  ('No Agrari', 'No agrario', 'Non-agricultural'),
  ('Abandonat', 'Abandonado', 'Abandoned'),
  ('Guaret', 'Barbecho', 'Fallow'),
  ('Per determinar', 'Por determinar', 'To be determined'),
  ('Fruiters', 'Frutales', 'Fruit trees'),
  ('Hortícola Diversificat', 'Hortícola diversificado', 'Mixed vegetables'),
  ('Hortícola Intensiu', 'Hortícola intensivo', 'Intensive vegetables'),
  ('Ornamental', 'Ornamental', 'Ornamental'),
  ('Aillat', 'Aislado', 'Single'),
  ('En grup', 'En grupo', 'In a group')
) v(ca, es, en)
where t.nom = v.ca;
