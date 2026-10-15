# Série 24 — Tour Pokémon, étages 2F à 6F : complément de la série 21 du J18 (jalon 19)

> **Complément de la série 21 du J18.** Le kit de l'intérieur de la Tour est produit par le J18
> (`origin/jalon-18` à `bcb611c8`, fiche `serie-21-j18.md`, outil `tools/art/serie21.py`) sous
> les noms du plan du J19 : `ground_dalles_tour_01` (sol), `relief_mur_tour_01..05` (murs),
> `relief_escalier_tour_01` (escalier montant pris dans le mur), `int_tombe_tour_01..03`
> (tombes A nue, B bouquet, C offrande), `int_bougeoir_tour_01` (bougeoir), comptoir et banc.
> **Le J19 les réutilise.** Cette série ne produit que ce que le J18 n'a pas.
>
> Rédigée le 2026-10-16 (branche `j19-t-art-etages`, partie de `jalon-19` à `41265377`).
> Conception : `dossier-22-tour-pokemon.md` §4.1, §9, §11, §12.4 bis, §12.5 ; DA :
> `reference/tour-pokemon-vue-generale-v1.png` ; géométrie (fait foi) :
> `tools/plans/pokemon_tower_{2f..6f}.txt`. **Aucune intégration** : elle attend la validation du
> kit du J18 (voir « Intégration prévue »).

## Numéro de série

**24**, vérifié le 2026-10-16 :
- `git fetch --all`, puis `git ls-tree` de `docs/design/fiches-assets/` et `tools/art/` sur les
  **323 références** locales et distantes (`git for-each-ref refs/heads refs/remotes`) : fiches et
  scripts jusqu'à 20, plus **21** (`serie-21-celadopole.md`, `serie21.py` sur `j20-t2-t3-art`,
  J20) et **21** (`serie-21-j18.md` sur `j18-t1-kit` / `origin/jalon-18`, J18) : **collision
  21 entre le J18 et le J20, à régler par eux** ;
- `git grep` « série 2N » dans `docs/` et `tools/` sur toutes les références : **22** est
  explicitement laissé au J18 ou au J20 par `docs/tech/jalon-21.md` §2.16 (« 21 et 22 leur sont
  laissés ») ; **23 = J21** (`serie-23-repos-des-esprits.md`, `serie23.py` sur `j21-art`,
  `jalon-21`) ;
- copies de travail (`.claude/worktrees/*`, y compris non commitées) : rien au-delà de 23 ;
- **24 est le premier numéro libre et non réservé.** À revérifier au push (fiche,
  `tools/art/serie24.py`, `tools/art/prompts/serie24/` ; les identifiants d'images ne portent pas
  le numéro).

## Outil

`tools/art/serie24.py` (reprend `ADN` et `LUMIERE_NE` de `serie06.py`, `VALEURS_TOUR` et
`INTERDITS` **mot pour mot** de `serie21.py` du J18, et les fonctions de `tools/art/preparer.py`) :

| Option | Rôle |
|---|---|
| `--prompts` | écrit les prompts versionnés `tools/art/prompts/serie24/<NOM>_r{1,2,3}.txt` |
| `--refs` | recadre `REF_TE_ESCALIER` (2F, escalier ouest) et `REF_TE_ZONE` (5F) de la vue validée, × 3 |
| `--commandes` | liste les appels `tools/art/generer.sh` avec leurs images jointes |
| `--preparer` | prépare les essais retenus (`RETENUS`) → `build/art/serie24/` (rien dans `assets/`) |
| `--controle` | planche de contrôle : le 5F recomposé à l'échelle du jeu → `build/art/SERIE24_CONTROLE_v1.png` |

**Essais** (règle des refus) : r1 avec la référence recadrée et les ancres ; r2 ancres du dépôt
seulement ; r3 sans image. Si la planche de murs du J18 (`WORLD_RELIEF_MUR_TOUR_PLANCHE_NE_r1.png`,
avec `relief_escalier_tour_01`) existe déjà dans `j18-t1-kit/build/art` au moment de `--prompts`,
r1 la joint comme ancre de cohérence de l'escalier.

**Planche de contrôle** : reprend les règles de `tools/build_pokemon_tower.gd` (faces au sud des
`#` ouverts, couronnements au nord, côtés, tombes `T`, bougeoirs `S`, escaliers, dalle `Z`) et le
héros (`heros_idle_sheet`, 128 px). Les assets du J18 sont pris dans
`j18-t1-kit/assets/world/` dès qu'ils y sont préparés ; sinon l'art provisoire actuel du dépôt
(souterrain du J15) tient leur place. La planche indique la source de chaque rôle.

## Les deux assets

### 1. WORLD_PROP_ESCALIER_TOUR_DESCEND_01 → `prop_escalier_tour_descend_01`

- **Rôle** : cases `V` des grilles 3F à 6F (2F : la descente est la paire T12 vers le
  rez-de-chaussée du J18). Warp `STEP_ON` sans direction ; posé **au sol** (calque `decals`, sans
  emprise), comme les escaliers actuels.
- **Intention** : pendant **descendant** de `relief_escalier_tour_01` (même pierre de taille gris
  perle violacé, mêmes marches) ; une **trémie carrée** ouverte dans le sol, rebord de pierre sur
  trois côtés, cinq marches qui descendent vers le haut de l'image dans une ombre gris-violet douce
  (jamais noire, jamais de lumière au fond).
- **Format** : **1 case** (96 × ≤ 96), tenu dans la case ; objet détouré ; ni ombre portée ni
  contact (au sol). Entrée de manifeste proposée :
  `{"id": "prop_escalier_tour_descend_01", "source": "WORLD_PROP_ESCALIER_TOUR_DESCEND_01_NE_rN.png", "sortie": "assets/world/props/prop_escalier_tour_descend_01.png", "axe": "w", "cases": 1, "ombre": false, "contact": null}`.
- **Écart de gabarit assumé** : l'escalier **montant** du J18 est pris dans un **mur** (1 × 2,
  gabarit de la face) ; les `U` et `V` des étages sont des cases de **sol** au bord d'un mur latéral
  (ex. 5F : `V` (3, 9), `U` (18, 9)). Le montant du J18 convient aux `U` adossés à un mur nord ; pour
  les `U` contre un mur latéral, il faudra soit le poser réduit à 1 case, soit un module montant
  « au sol » (à décider à l'intégration, sur capture).

### 2. WORLD_GROUND_DALLE_PURIFIEE_01 → `ground_dalle_purifiee_01`

- **Rôle** : zone purifiée du 5F, cases `Z` (10..11, 8..9) ; remplace le `Polygon2D`
  (`ZONE_COLOR`) de `build_pokemon_tower.gd`.
- **Intention** (§9, §11) : quatre grandes dalles de pierre **claire nacrée** (blanc cassé, lavande
  et bleu très pâles), joints fins en croix, mince liseré gris perle sur le pourtour ; **aucun effet
  lumineux peint** : le halo blanc fixe est la source `purified` du voile et le profil du jeu.
- **Format** : 2 × 2 cases, **192 × 192 opaque** (texture 1024 réduite), posée au sol sous les
  personnages. Entrée proposée : image simple (comme les sols), `taille` 192, sans raccord.

### Non produit : stèle à bougie (`S`)

Par défaut (consigne du 2026-10-16), les stèles `S` des alcôves utilisent **`int_bougeoir_tour_01`**
du J18 (socle de pierre carré + photophore, flamme peinte sans halo, 1 case × ≈ 1,2) et la source
`candle` du voile. Une stèle-niche propre au J19 ne sera produite que si le bougeoir ne tient pas
ce rôle sur la capture des étages.

## Essais, refus, choix

Génération du 2026-10-16. **Aucun refus de Codex** : les deux appels r1 ont produit une image
du premier coup. **Incident** : un premier lot (alors périmètre complet : sol, murs, planche de
repères, dalle) a échoué à 00:03 sur la **limite d'usage** de Codex (« usage limit », reprise à
00:34), sans aucune image : ce n'est pas un refus. Le périmètre ayant été réduit entre-temps
(consigne du coordinateur : sol, murs, tombes et escalier montant viennent du J18), ces quatre
prompts ont été retirés avant tout appel ; rien n'a été généré en double.

| Asset | Essais | Retenu | Pourquoi |
|---|---|---|---|
| Escalier descendant | r1 (`REF_TE_ESCALIER` + escalier descendant et mur du souterrain) | **r1** | trémie de pierre gris perle violacé, rebord bas sur trois côtés, rampes, cinq marches qui s'enfoncent vers le haut dans un gris-violet doux (pas de noir, pas de lumière au fond) ; vraie transparence, détourage propre (vérifié sur fond vert). Préparé : **96 × 83** (1 case de large, tenu dans la case). La planche du J18 n'existait pas encore : r1 ne la joint pas. |
| Dalle purifiée | r1 (`REF_TE_ZONE` + dalles du souterrain) | **r1** | quatre dalles nacrées blanc-lavande, joints en croix, liseré gris perle sur le pourtour, aucun halo ni étincelle. Préparée : **192 × 192** opaque. |

**Sorties** (non versionnées) : sources `build/art/WORLD_PROP_ESCALIER_TOUR_DESCEND_01_NE_r1.png`
et `build/art/WORLD_GROUND_DALLE_PURIFIEE_01_NE_r1.png` (1254², Codex) ; préparées
`build/art/serie24/prop_escalier_tour_descend_01.png` et `ground_dalle_purifiee_01.png` ;
journal `build/art/serie24/journal/`.

**Planche de contrôle** (relue) : `build/art/SERIE24_CONTROLE_v1.png`, 5F recomposé d'après
`pokemon_tower_5f.txt` à 1 case = 96 px, héros à 128 px sur l'arrivée (4, 9) à côté de l'escalier
descendant (3, 9), dalle sur (10..11, 8..9). Le kit du J18 n'étant pas encore préparé, sol, murs,
tombes, bougeoirs et escalier montant y sont l'art provisoire actuel (souterrain) ; relancer
`--controle` une fois le T6 du J18 passé.

## Écarts à juger par Kevin

1. **Dalle purifiée très claire** sur le sol provisoire beige : à revoir sur le sol gris perle du
   J18 et sous le voile du 5F (la source `purified` l'éclaircit encore) ; la marbrure diagonale
   lavande pourrait être adoucie à la préparation (flou léger) si elle se lit comme un reflet.
2. **Escalier descendant un peu plus « muret » que trémie** : les rampes latérales montent
   au-dessus du sol (≈ 0,35 case) ; lisible comme une descente, cohérent avec les murets de
   l'escalier du souterrain. Un r2 « rebord à fleur du sol » reste possible.
3. **Gabarit des escaliers montants** (J18 : pris dans un mur nord, 1 × 2) face aux `U` des étages
   posés contre un mur latéral : voir la fiche, § 1.

## Intégration prévue (non faite)

L'intégration attend la validation du kit du J18 (T6 du J18 : manifeste, `preparer.py`,
`build_painted_props.gd -- --nouveaux`). Elle ne se réduit **pas** à remplacer des identifiants :
les assets doivent d'abord exister en scènes `res://game/world/props/<id>.tscn`
(`cave_map_kit.gd` les charge par `scene(id)`). Étapes, au plan du J19 :
1. ajouter les deux entrées au manifeste (escalier dans `objets`, dalle dans `sols` ou en image
   simple), lancer `preparer.py` puis `build_painted_props.gd -- --nouveaux` et l'import ;
2. dans `tools/build_pokemon_tower.gd` : `GROUND_DALLES` → `ground_dalles_tour_01` ;
   `WALL_FACES` / `WALL_CAP` / `WALL_SIDE` → `relief_mur_tour_01/02`, `_03`, `_04` (les
   gabarits du J18 diffèrent : faces 2 × 2 au lieu de 2 × 1, couronnement ≈ 0,4 ; revoir
   `_place_walls` et `SIDE_WIDTH`) ; tombes → `int_tombe_tour_01..03` à 1:1 (supprimer
   `TOMB_SCALE` / `TOMB_TINT`) ; stèles → `int_bougeoir_tour_01` ; `STAIRS_UP` →
   `relief_escalier_tour_01` (voir l'écart ci-dessus), `STAIRS_DOWN` →
   `prop_escalier_tour_descend_01` avec `STAIRS_SCALE` = 1 ; `_place_zone` : un `Sprite2D` de
   `ground_dalle_purifiee_01` au coin haut gauche des cases `Z` au lieu du `Polygon2D` ;
3. régénérer les cinq cartes, importer, `tools/test.sh`, capture.
