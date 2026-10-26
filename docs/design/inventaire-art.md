# Inventaire de l'art provisoire

> Refait le 2026-10-24 (lot **DAF.0** de la phase DA, `phase-da-cadrage.md` §3.2) sur
> `origin/main` @ `91770ba0`, plus une colonne par branche non fusionnée, mesurée en lecture seule
> (`git ls-tree`, `git show`). Version précédente : 2026-10-21 (`main` @ `537c40f0`).
> Mesuré sur les fichiers eux-mêmes, pas sur les noms de dossiers. À refaire après chaque lot d'art
> ou chaque fusion de jalon (commandes en fin de fichier).

**Pourquoi il en reste** : stratégie d'accélération, levier 4 (décision de Kevin, 2026-10-19). Avant
le code, seulement la grille et une vue générale peinte ; l'art est produit **par lots**, le jalon
tourne avec le kit existant ou des provisoires (règle 3 de `CLAUDE.md`). Cible : 2D HD peinte, « ni
pixel art ». Phase DA : `phase-da-cadrage.md` (option B, lots DAF.0 à DAF.8, gel à l'entrée du J34).

## 1. Vue d'ensemble, `main` @ `91770ba0`

| Famille | Fait (peint) | Provisoire sur `main` |
|---|---|---|
| Façades | 43 `bldg_*.png` distinctes (dont Céladopole, série 22 bis) | **0** (aucune vignette < 900 couleurs, 211 fichiers testés) |
| Intérieurs (enveloppes) | toutes les cartes de `main` (coques peintes ou modules) | **0** ; `interiors/placeholder/` ne contient plus que 17 `ph_celadon_*` (références de taille de `serie22bis.py`, non utilisées) |
| Dos de combat | **81 / 126** espèces peintes sur `main` depuis le 2026-10-25 (DAF.1 partie 1, §3) | **45 / 126** en pixel art 64 × 64 (`placeholder/<espèce>_back.png`), + 25 espèces à venir |
| Fonds de combat | 50 cartes à combats sur 66 ont un fond (23 décors, 22 images `.webp`) | **16 cartes sans fond** (§2) |
| Icônes du Sac | 45 (+ 23 sur `daf-5-icones`, DAF.5) | **≈ 23 objets sans icône** (§4) ; 0 après fusion du DAF.5 |
| Séries 23 et 25 | **23 intégrée** ; **25 intégrée** (DAF.5, 2e partie, 2026-10-26, §5) | — |
| Objets de décor | tous sauf 2 (peints sur `daf-5-icones`) | `breakfast` (`player_house_1f`), `bed_items` (`rival_house`) en pixel jusqu'à la fusion du DAF.5 |
| Personnages, compagnons | ≈ 100 apparences, 27 compagnons | aucun visible |

## 2. Fonds de combat (`data/battle/decors.json`, clé `places` par `map_id`)

Cartes à combats = cartes citées dans `data/encounters/*.json` (`maps`) ou ayant un PNJ `"trainer"`
(`data/npcs/`) : **66** sur `main`, dont **50 avec fond** et **16 sans** (repli : carte floutée).

| Cartes sans fond | Nature |
|---|---|
| `viridian_forest`, `route_2`, `route_2_north`, `route_22`, `route_25`, `pewter_gym` | **les 6 connus** : art à produire (DAF.2) |
| `route_19`, `route_20`, `route_21` | routes maritimes (J24) : le décor `sea_open` **existe et n'est référencé par aucune carte** |
| `seafoam_1f`, `seafoam_b1f` à `seafoam_b4f` | Îles Écume (J24) : le décor `seafoam_ice` **existe et n'est référencé par aucune carte** |
| `cinnabar_island` | pas de décor ; vérifier à l'œil (ville, pêche et Surf) |
| `pallet_town` | cartée par `route_1.json` (herbe/pêche) ; vérifier si un combat y est jouable |

→ **Écart avec le cadrage** : sur ces 16 cartes, **6 sont de l'art à produire, 6 se règlent par du
câblage** (`places` : `sea_open` → routes 19 à 21 ; `seafoam_ice` → 5 niveaux), 2 sont à vérifier à
l'œil (`cinnabar_island`, `pallet_town`). Aucune image de `decors` n'est manquante sur disque.

**Cartes à combats ajoutées par les branches, toutes sans fond** (fonds à ajouter ou à rattacher à
un décor existant) : J23 5 (`fuchsia_gym`, 4 cartes du Parc Safari) ; J26 10 (`silph_co_2f` à
`10f`, `11f`) ; J27 +2 (`saffron_gym`, `fighting_dojo`) ; J28 1 (`viridian_gym`) ; J29 5
(`route_22_west`, `route_23`, `victory_road_1f` à `3f`) ; J30 5 (`league_lorelei`, `bruno`,
`agatha`, `lance`, `champion`) ; J31 3 (`cerulean_cave_1f`, `2f`, `b1f`). Soit **≈ 30 cartes**
après fusion, regroupables en ≈ 8 à 10 décors (Sylphe, Dojo/Arène de Safrania, Arène de
Jadielle, Route 22/23, Route Victoire, salles de la Ligue, Grotte Azurée, Safari).

## 3. Dos de combat

| Source | Dos | Remarque |
|---|---|---|
| `main` (depuis le 2026-10-25, fusion de `art-dos-combat` mise à jour, DAF.1 partie 1) | **81 espèces à dos peint sur 126** dans `assets/sprites/pokemon/dos/` (93 fichiers : 77 `dos_ia_NNN` + 16 `dos3d_NNN` ; Tentacool et Magicarpe en profitent depuis leur entrée dans les données) ; **45 en pixel** 64 px (`placeholder/`) | `BattleArt.best_painted_back_path` : IA > 3D > provisoire ; tests `test_painted_backs.gd` ; contrôle visuel `tools/capture_dos_proto.gd -- --species=a,b` |
| Manquants | **70 espèces** sans dos peint : 45 dans les données + 25 pas encore (n° 65, 68, 94, 103, 106 à 108, 112, 113, 122 à 125, 127, 128, 131, 132, 137, 145 à 151) | voir le détail ci-dessous |

Détail des **45 espèces des données** sans dos peint (DAF.1, reste à produire ; cadrage A ou B en attente de Kevin, `fiches-assets/dos-cadrage-rb/README.md`) :
- **8 par Kevin dans ChatGPT** : les 6 refusés par Codex, Kadabra (64), Tortank (9), Rondoudou (39),
  Staross (121), Léviator (130), Voltali (135) (`fiches-assets/dos-a-faire-chatgpt.md`), plus Ptéra
  (142) et Magmar (126) (pas encore dans la fiche) ;
- **4 conditionnels** non lancés : Ossatueur (105, jamais montré : repli artwork officiel),
  Rhinocorne (111), Saquedeneu (114), Kangourex (115) ;
- **33 ajoutées depuis le lot 2** (Codex, `serie_dos.py`) : Mimitoss (48), Aéromite (49),
  Psykokwak (54), Akwakwak (55), Ptitard (60), Têtarte (61), Tartard (62), Machopeur (67),
  Tentacruel (73), Ponyta (77), Galopa (78), Ramoloss (79), Flagadoss (80), Canarticho (83),
  Doduo (84), Dodrio (85), Otaria (86), Lamantine (87), Tadmorv (88), Grotadmorv (89),
  Crustabri (91), Krabby (98), Krabboss (99), Électrode (101), Smogogo (110), Hypocéan (117),
  Poissoroy (119), Amonita (138), Amonistar (139), Kabuto (140), Kabutops (141), Ronflex (143),
  Artikodin (144).

**Espèces sans dos pixel sur `main`** : 151 − 125 = 26. **22** ont un dos pixel sur une branche
(union des `placeholder/*_back.png` : 147 espèces) ; **4** (J32) n'en ont nulle part. Par branche :
J23 Insécateur, Scarabrute, Tauros, Leveinard ; J26 Alakazam, Osselait, Lokhlass, Ossatueur ; J27
+ Kicklee, Tygnon, M. Mime ; J28 Rhinoféros, Tauros ; J29 + Noadkoko, Excelangue, Sulfura ; J30 +
Draco, Dracolosse, Ectoplasma, Lippoutou, Mackogneur ; J31 Métamorph, Mewtwo. Ces dos pixel sont des
**provisoires** (au J31, `tools/gen_placeholder_battlers.gd`) à repeindre.

→ **Écart avec le cadrage** : reste à produire **70 dos** (151 − 81), pas 35 à 50 ; la fourchette du
cadrage retranchait deux fois les dos IA/3D déjà comptés dans les 79 (la branche en compte 81).
Environ 26 de ces 70 sont des espèces sans dos pixel sur `main` (J23 à J32).

**Faces** : artwork officiel (`official/NNN.png`, 152 fichiers) ; pixel de repli pour Saquedeneu,
Rhinocorne, Kangourex (non remesuré ici).

## 4. Icônes du Sac

`assets/ui/items/` : 45 icônes pour **68 objets** de `data/items/*.json`. **23 sans icône** :
`bicycle`, `bike_voucher`, `card_key`, `full_heal`, `good_rod`, `old_rod`, `super_rod`, `hm02`,
`hm03`, `hm04`, `hyper_potion`, `max_potion`, `max_revive`, `old_amber`, `poke_flute`,
`secret_key`, `tm09`, `tm14`, `tm22`, `tm35`, `tm38`, `tm39`, `ultra_ball`.
→ **Écart avec le cadrage** (« Icônes du Sac 45 / 45 ») : des objets des J21 à J25 (Flûte, cannes,
Bicyclette, CS, Vieil Ambre, Clé Secrète…) n'ont pas d'icône ; une série d'une vingtaine
d'images est à ajouter au DAF.5 (à confirmer : certains objets clés peuvent n'avoir jamais besoin
d'icône dans le Sac).

## 5. Séries 23 et 25

- **Série 23 (Repos des esprits)** : **intégrée** (T7 du J21, 2026-10-16) : `fuji_sheet`,
  `fuji_priere_sheet`, `mr_fuji_frames.tres`, `osselait_sheet`, `ronflex_sheet`,
  `snorlax_frames.tres` présents sur `main`. Reste : l'icône `poke_flute.svg` (non trouvée dans
  `assets/ui/items/`).
- **Série 25 (deux chemins)** : **non intégrée**. Présent : `assets/ui/icons/bike.svg` (HUD),
  `bldg_velos_01` / `prop_velo_01` / râtelier. **Absents** de `assets/` : feuilles du héros à vélo
  et à la pêche (`heros_bike`, `heros_fish_*`), Motard, Ornithologue, Loubard, deux frères
  pêcheurs, Pokémon fixes (Kangourex, Ramoloss…), icônes des cannes et de la Bicyclette. Les 18
  images Codex sont des **images brutes hors dépôt** (`build/art/` d'une copie de travail) ; seules
  les planches `docs/design/reference/serie-25-contact-v1.png` et `-v2.png` sont versionnées.
  → DAF.5 doit d'abord **retrouver les originaux** (copie `j22-t7-art` ou re-générer avec
  `tools/art/serie25.py`) avant d'intégrer (`serie25.py --manifeste`).
  **Fait (DAF.5, 2e partie, 2026-10-26)** : originaux retrouvés dans `j22-t7b/build/art`, intégrés par
  `tools/art/daf5_reliquats.py` (vélo, pêche, 5 PNJ, Kangourex, Ramoloss) ; icônes déjà faites par la
  1re partie ; planche `fiches-assets/daf-5-reliquats/planche.png`.

## 6. Branches non fusionnées (lecture seule)

Colonnes mesurées en propre (différence avec le merge-base) ; toutes sont en retard sur `main` de
38 à 313 commits.

| Branche | @ | Commits propres | Art provisoire apporté | Fonds de combat |
|---|---|---|---|---|
| `jalon-23` | `cb0000a2` | 41 | aucune façade ni intérieur ; 16 fichiers `assets/sprites/pokemon` (espèces) ; 4 dos pixel | 5 cartes sans fond (Arène de Parmanie, Parc Safari ×4) |
| `jalon-26` | `e55afc53` | 40 | **15 façades** de Safrania en aplats (`placeholders_safrania.py`, 17 ids dont `bldg_boutique_01` et `bldg_centre_01` réutilisés) ; **14 intérieurs** de Sylphe SARL (`ph_silph_co_1f` à `11f`, cabine, 2 battants) ; 4 dos pixel | Sylphe : 10 cartes |
| `jalon-27` | `2cedd53b` | 48 | idem J26 ; +2 intérieurs (`ph_saffron_gym`, `ph_fighting_dojo`) ; dos pixel | +2 (Arène de Safrania, Dojo) |
| `jalon-28` | `0fb0f49a` | 13 | 1 intérieur (`ph_viridian_gym`, `placeholders_j28.py`) ; dalles et cases d'arrêt = celles du repaire ; Giovanni Champion, Rhinoféros : sprites provisoires ; 2 dos pixel | `viridian_gym` sans fond (plan : « repli par défaut ») |
| `jalon-29` | `bf675998` | 23 | aucune image ; Route 22 ouest : sol peint fait (Q29-4) ; reste le poste de la Route 23, le kit grotte en placeholder pour la Route Victoire (interrupteur, barrière, gardes) ; dos pixel | `route_22_west`, `route_23`, `victory_road_1f` à `3f` |
| `jalon-30` | `0e13587a` | 22 | aucune image ; 6 salles de la Ligue (cinq + Panthéon) en tuiles provisoires `InteriorTiles` ; sprites provisoires d'Olga, Aldo, Agatha, Peter ; 11 dos pixel | 5 salles de la Ligue |
| `jalon-31` | `84060036` | 20 | aucune image ; Grotte Azurée 3 niveaux en tuiles provisoires (kit grotte à niveaux) ; sprites provisoires de Métamorph et Mewtwo (`gen_placeholder_battlers.gd`) ; 4 dos pixel | 3 cartes de la Grotte Azurée |
| `art-dos-combat` | `6632ad41` | 6 | 81 dos peints (93 fichiers) ; base ancienne, d'où 88 dos pixel seulement (main en a 125) | 7 cartes sans fond (état de son merge-base) |

**Totaux à produire une fois tout fusionné** (voir `phase-da-cadrage.md` §1.3 mis à jour) :
façades **15** (Safrania), intérieurs **17** (14 Sylphe, Arène de Safrania, Dojo, Arène de
Jadielle), kits J29 à J31 (≈ 12 cartes : Route 22/23 ouest, 3 niveaux de la Route Victoire,
6 salles de la Ligue, 3 niveaux de la Grotte Azurée, sans aucune image peinte à ce jour), dos 70,
fonds ≈ 6 + 8 à 10 décors, icônes ≈ 23, série 25.

## 7. Reliquats

- Objets en pixel art : `breakfast` (`player_house_1f`) et `bed_items` (`rival_house`),
  `assets/tiles/placeholder/props/interior/`.
- `ss_anne_outer_deck` : carte sans sol peint détecté (construite autrement), à vérifier à l'œil.
  **Vérifié (DAF.5, 2026-10-26)** : pont peint par sa coque, rien à refaire.
- Chenipan d'ambiance de la Forêt de Jade (prompt prêt). **Fait (DAF.5, 2026-10-26)** : généré par
  Codex, `caterpie_frames.tres`.

## Commandes de mesure

Depuis la racine d'une copie à jour de `main`. Pour une branche, remplacer les chemins par
`git ls-tree -r --name-only origin/<branche> <dossier>` et `git show origin/<branche>:<fichier>`.

```bash
# Façades en aplats : scripts placeholders_*.py encore présents et leurs identifiants
ls tools/art/placeholders_*.py
grep -ohE 'bldg_[a-z0-9_]+' tools/art/placeholders_*.py | sort -u
# Intérieurs : la liste ne doit contenir que les 17 ph_celadon_* de référence
ls assets/world/interiors/placeholder/
# Contrôle de couleurs (PIL) : < 900 couleurs sur une vignette de 256 px = aplat probable
python3 -c "
import glob;from PIL import Image
for p in sorted(glob.glob('assets/world/buildings/bldg_*.png')+glob.glob('assets/world/interiors/*.png')):
    if any(s in p for s in ('_contact','_shadow','_mask')): continue
    im=Image.open(p).convert('RGBA');im.thumbnail((256,256))
    n=len(set(im.getdata()))
    if n<900: print(n,p)"
# Dos de combat : pixel (64 px) et peints (art-dos-combat : assets/sprites/pokemon/dos/)
ls assets/sprites/pokemon/placeholder/*_back.png | wc -l
# Fonds de combat : cartes à combats (encounters[].maps + PNJ "trainer") moins places de decors.json
python3 -c "
import json,glob
d=json.load(open('data/battle/decors.json'));places=set(d['places']);c=set()
for f in glob.glob('data/encounters/*.json'):
    for v in json.load(open(f)).values(): c|=set(v.get('maps',[]))
for f in glob.glob('data/npcs/*.json'):
    if '\"trainer\"' in open(f).read(): c.add(f.split('/')[-1][:-5])
print(len(c),sorted(c-places))
print('décors sans place:',sorted(set(d['decors'])-{e['decor'] for v in d['places'].values() for e in v}))"
# Icônes du Sac : identifiants de data/items/*.json sans assets/ui/items/<id>.*
# Séries 23 et 25 : ls assets/sprites/characters/painted | grep -E 'fuji|bike|motard'
```
