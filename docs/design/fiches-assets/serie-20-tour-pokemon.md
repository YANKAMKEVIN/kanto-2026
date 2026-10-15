# Série 20 — Tour Pokémon, lot d'art 19.0 (jalon 19)

> **VALIDÉE par Kevin le 2026-10-15** (planche `build/art/SERIE20_CONTROLE_v1.png` : SPECTRE r1, dos IA de Fantominus r1 provisoire, décor `tour_pokemon` r1, panneau du Scope r1).

> Rédigée le 2026-10-15 (branche `docs/dossier-j19`, à jour de `main` à `f9d4ab7`). Conception :
> `docs/design/dossier-22-tour-pokemon.md` §6.2 (silhouette SPECTRE), §10 (panneau), §11
> (ambiance), §12.1 et §12.4 (lot 19.0), §12.5 (vue validée). Référence de DA :
> `reference/tour-pokemon-vue-generale-v1.png` (essai 4). Aucun code de jeu, aucune intégration
> Godot : l'intégration (manifeste, `data/battle/decors.json`, `BattleArt`) revient au plan
> technique `docs/tech/jalon-19.md`.
>
> **Hors de cette série** : la planche **Exorciste** (marche et pose de prière), produite par le
> J18 et mutualisée (`tools/art/prompts/j18/PNJ_EXORCISTE_NE_r1.txt` sur `docs/dossier-j18`) ; les
> 5 vues peintes des étages et le décor de la zone purifiée (kit de cartes, plan du J19).

## Numéro de série

**20**, vérifié le 2026-10-15 :
- `git fetch --all`, puis `git ls-tree` de `docs/design/fiches-assets/` et `tools/art/` sur les
  **281 références** (`git for-each-ref refs/heads refs/remotes`) : fiches 01, 12 à 17 et scripts
  `serie06` à `serie17` ; rien au-delà de 17 ;
- `git grep` des mentions « série NN » sur toutes les branches : **18 réservée par le J16**
  (`docs/tech/jalon-16.md`, « série 18 pour le J16 ») et **19 réservée par le J17**
  (`docs/tech/jalon-17.md` T11, `serie-19-chemins.md`, `serie19.py`) ;
- copies de travail non poussées (`j17-*`, `doc-j18`, `j20-conception`, `j21-conception`,
  `integ-j17`) : aucune fiche ni script au-delà de 17 ; le J18 a seulement
  `tools/art/prompts/j18/` (Exorciste, Pokémaniac), **sans numéro réservé**.
- **À revérifier au push** : si le J18 prend 20 entre-temps, renommer la fiche,
  `tools/art/serie20.py` et `tools/art/prompts/serie20/` (les identifiants d'images ne portent pas
  le numéro).

## Outil

`tools/art/serie20.py` (autonome, reprend `ADN` et `LUMIERE_NE` de `serie06.py` et la chaîne
CB.3 de `tools/art/combat_decors/preparer_decor.py`) :

| Option | Rôle |
|---|---|
| `--prompts` | écrit les prompts versionnés (r1 à r3 par asset ; décor et tuile dans `combat_decors/prompts/`) |
| `--refs` | recadre `REF_TP_SALLE` (2F : stèles, fleurs, bougies) et `REF_TP_6F` de la vue validée, × 3 |
| `--commandes` | liste les appels `tools/art/generer.sh` avec leurs images jointes |
| `--tuiles ESSAI` | découpe les deux portions qui se chevauchent (TL / TR, ≈ 1,17 : 1) d'une composition de décor |
| `--decor ESSAI` | recale les tuiles, coud, réduit à 2340 × 1080 → `build/art/serie20/tour_pokemon_back.{png,webp}` (n'écrit **pas** dans `assets/`) |
| `--detourer` | recadre et met au format les essais retenus (`RETENUS`) → `build/art/serie20/` |
| `--controle` | planche de contrôle à l'échelle du jeu → `build/art/SERIE20_CONTROLE_v1.png` |

La planche reprend `BattleLayout` (`game/battle/battle_layout.gd`) : pieds de l'adversaire
(0,36 ; 0,50) et du joueur (−0,42 ; 0,90) en hauteurs d'écran, présence 0,27 / 0,31, loi de
taille (exposant 0,4, bornes 0,73–1,73), boîtes maximales.

## Les quatre assets

### 1. SPECTRE_COMBAT → `spectre_face.png` (face adverse)

- **Intention** (§6.2, §11) : une présence de brume violette **indistincte** ; ni yeux, ni visage,
  ni forme d'espèce, **ni silhouette humaine** (écart de l'essai 4 de la vue : spectre
  encapuchonné), sans contour noir ; calme, triste, jamais effrayante.
- **Format** : celui des faces adverses (artwork officiel 475 × 475 RGBA, cadre utile ≈ 431 px,
  bas du sujet à 22 px du bord) ; master 1024 × 1024 gardé (`spectre_face_1024.png`). Le jeu
  recadre sur l'alpha et pose le bas-centre sur les pieds de l'adversaire.
- **Prompt** : `tools/art/prompts/serie20/SPECTRE_COMBAT_r{1,2,3}.txt`. r1 : vue générale jointe
  pour la **couleur** de la brume seulement (consigne explicite de ne pas reprendre la silhouette
  encapuchonnée) ; r2 : sans image ; r3 (non lancé) : « nappe de brume en lobes, plus large en haut ».
- **Taille en jeu** [D] : affichée à la taille de Fantominus (1,3 m) sur la planche. **À trancher
  au plan** : une taille fixe pour tout SPECTRE (recommandé : elle ne trahit pas l'espèce cachée,
  Osselait 0,4 m ou Ossatueur 1,0 m) plutôt que la taille de l'espèce réelle.

### 2. DOS_FANTOMINUS → `dos_ia_092.png` (dos provisoire IA)

- **Règle appliquée** : la source validée des dos (rendu 3D X/Y repeint par IA sur Colab) est
  **impossible pour Fantominus** : son modèle manque sur The Models Resource
  (`provenance-modeles-3d.md` §1 : « manquent Fantominus (n° 092) et Hypnomade (n° 097) »). Le dos
  est donc un **provisoire IA peint par Codex**, au format de `dos_ia_093` (1024 × 1024 RGBA, sujet
  ≈ 85 % de la hauteur, bas à ≈ 120 px du bord) et dans la famille de rendu des artworks officiels
  (trait fin et doux). Colab n'a pas été lancé ; aucun prompt Colab n'est utile sans modèle 3D.
- **Prompt** : `DOS_FANTOMINUS_r{1,2,3}.txt`. r1 : nom de l'espèce + jointes `official/092.png`
  (anatomie, couleurs) et `battle_proto/dos_ia_093.png` (angle, cadrage, famille de rendu) ;
  r2 (non lancé) : sans nom de licence ; r3 (non lancé) : sans image.
- **Note** : vu de dos, Fantominus n'est qu'une sphère sombre dans son aura de gaz : aucune
  orientation lisible (pas de visage à cacher), ce qui est fidèle à l'espèce.

### 3. COMBAT_DECOR_TOUR_POKEMON → décor CB.3 `tour_pokemon`

- **Intention** (§11, §12.4) : dalles de pierre gris violacé, stèles basses sans inscription,
  fleurs fanées et fraîches, offrandes, bougies (stèles importantes, niches), brume légère ; calme
  et solennel, sans horreur ; un seul décor pour tous les étages (2F–7F).
- **Format** : exactement celui des décors CB.3 existants : composition Codex ≈ 1848 × 851 (2,17 : 1),
  deux tuiles repeintes plus grandes (`COMBAT_DECOR_TUILE_TOUR_r1.txt`, prompt de tuile adapté :
  stèles, bougies, dalles, brume), recalées et cousues par `preparer_decor.master`, réduites à
  **2340 × 1080**, WebP qualité 90. Points A (67 %, 50 %) et B (31 %, 97 %), zones calmes haut
  gauche et bas droite, 9 % latéraux sans rien d'important (prompt calqué sur
  `COMBAT_DECOR_CHAMBRE_r1`). **Pas de calque de premier plan** : comme tous les intérieurs
  (seule la Route 1 en a un) ; pas de variante locale (le dossier prévoit un décor unique).
- **Jointes** : `combat-v1.webp`, `combat-decors-planche-v1.webp`, `REF_TP_SALLE`.
- **Déclaration proposée** pour `data/battle/decors.json` (au plan, pas ici) — ligne de sol aux
  ancres communes, horizon mesuré sur le master (base des stèles) :

```json
"tour_pokemon": {
	"zone": "pokemon_tower",
	"variant": "salle",
	"back": "res://assets/battle/decors/tour_pokemon_back.webp",
	"size": [2340, 1080],
	"foe_feet": [1559, 540],
	"player_feet": [716, 972],
	"horizon": 335
}
```

  et dans `tools/art/combat_decors/decors.json` : composition `COMBAT_DECOR_TOUR_POKEMON_r1.png`,
  tuiles `_TL` portion `[0, 0, 999, 851]` et `_TR` portion `[849, 0, 1848, 851]`. Places : les
  cartes `pokemon_tower_2f` à `_7f` (décor par défaut, sans `cells`).

### 4. WORLD_PROP_PANNEAU_SCOPE_01 → `prop_panneau_scope_01.png`

- **Intention** (§10, K-16) : panneau publicitaire moderne de Sylphe SARL pour le Scope, sur le
  parvis de la Tour, case **(42, 11)** de `tools/plans/lavanville.txt` (J18) ; **aucun texte
  lisible** (le texte vient du jeu), aucun logo-lettre ; lumière NE.
- **Format** : objet du monde, fond transparent, `axe h`, **`cases 2`** comme `prop_panneau_01`
  (171 × 192) → 192 px de haut ; `ombre` oui, `contact` 0,1 (valeurs de `prop_panneau_01`, [D]).
- **Prompt** : `WORLD_PROP_PANNEAU_SCOPE_01_NE_r{1,2,3}.txt` (ADN v1 + LUMIÈRE NE). r1 : jointe la
  source du panneau de bois (`WORLD_PROP_PANNEAU_01_NE_r1.png`, checkout principal) pour la vue,
  l'échelle et la facture.
- **Entrée de manifeste proposée** (au plan) :
  `{"id": "prop_panneau_scope_01", "source": "WORLD_PROP_PANNEAU_SCOPE_01_NE_r1.png", "sortie": "assets/world/props/prop_panneau_scope_01.png", "axe": "h", "cases": 2, "ombre": true, "contact": 0.1}`.

## Essais, refus, choix (génération du 2026-10-15)

**Aucun refus de Codex** : les 7 appels ont produit une image du premier coup, y compris le dos
de Fantominus **avec** son nom et ses images d'ancrage jointes (r1). Toutes les images détourées
ont une vraie transparence (vérifiée sur fond clair et fond vert).

| Asset | Essais | Retenu | Pourquoi |
|---|---|---|---|
| Silhouette SPECTRE | r1 (vue jointe), r2 (sans image) | **r1** | masse de brume asymétrique, traîne en bas (pieds lisibles), aucun œil, visage, capuche ni forme d'espèce. r2 rejeté : boule ronde hérissée de volutes, trop proche d'une sphère (évoque Fantominus). |
| Dos de Fantominus | r1 | **r1** | sphère noir violacé, aura de gaz lavande, trait fin des artworks ; pas de visage (de dos). |
| Décor `tour_pokemon` | r1 + tuiles TL / TR | **r1** | recalage 0,933 / 0,882, couture invisible, master 2510 × 1156 réduit à 2340 × 1080 (583 Ko en WebP 90). Six stèles basses, fleurs, offrandes, bougies (deux niches, deux stèles) ; sol de dalles dégagé, calme ; aucun personnage malgré l'Exorciste visible dans `REF_TP_SALLE`. |
| Panneau du Scope | r1 | **r1** | cadre métal clair, auvent, deux lampes, socle de béton ; affiche « lunettes-scope » bleu-violet, bande du bas unie, **aucun texte**. 168 × 192 px à 2 cases. |

**Sorties** (non versionnées, `build/art/`) : sources `SPECTRE_COMBAT_r1.png`, `_r2.png`,
`DOS_FANTOMINUS_r1.png`, `COMBAT_DECOR_TOUR_POKEMON_r1.png` (+ `_cropTL/TR`, `_TL`, `_TR`),
`WORLD_PROP_PANNEAU_SCOPE_01_NE_r1.png` ; préparées dans `build/art/serie20/` :
`spectre_face.png` (475 × 475), `spectre_face_1024.png`, `dos_ia_092.png` (1024 × 1024),
`tour_pokemon_back.png` / `.webp` (2340 × 1080), `prop_panneau_scope_01.png` (168 × 192) ;
planche `build/art/SERIE20_CONTROLE_v1.png`.

**Planche de contrôle** (relue) : SPECTRE et dos de Fantominus sur le décor, puis la face
existante de Spectrum (093) et `dos_ia_093` sur le même décor, aux règles de `BattleLayout` ;
panneau à côté de `prop_panneau_01` sur une grille de 96 px. Les gabarits sont cohérents (le
SPECTRE à 1,3 m est un peu plus petit que Spectrum à 1,6 m, comme attendu).

## Écarts restants (à juger par Kevin)

1. **Brume du décor presque absente** : le prompt la demandait légère et Codex l'a réduite à un
   voile sur les côtés. Proposition : la porter dans Godot (calque de brume animé, §11 « une brume
   qui glisse ») plutôt que de la peindre, ce qui la rend vivante ; sinon un `_r2` « nappe lilas au
   ras du sol, au fond ».
2. **Lumière du décor un peu chaude au centre** (halo de bougie doré sur les dalles autour du
   point A) : dans l'esprit des décors de combat, qui portent leur ambiance ; à baisser au besoin
   par une correction de teinte à la préparation.
3. **Facture du SPECTRE** : brume vaporeuse, plus « volumétrique » que les masses douces du
   décor ; lisible et conforme aux interdits. Un `_r3` (prompt prêt : nappe en lobes) reste
   possible si Kevin la veut plus peinte.
4. **Taille du SPECTRE en jeu** : à fixer au plan (taille constante recommandée, voir §1).
5. **Dos de Fantominus** : provisoire IA hors de la chaîne validée (pas de modèle 3D X/Y) ; aucune
   orientation lisible (sphère) ; l'aura est plus pâle (lavande) que le gaz de l'artwork officiel.
   Remplacement possible le jour où un modèle 3D de Fantominus existe.
6. **Panneau vu de face** plutôt qu'en trois quarts de dessus : comme `prop_panneau_01`, donc
   cohérent avec le monde ; à vérifier sur la capture de Lavanville.
7. **Numéro 20** à revérifier au push (J18).
