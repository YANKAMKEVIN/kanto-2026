# Refonte de l'écran Pokédex — plan technique

> Sous-jalon hors numérotation, branche **`pokedex-refonte`** (tirée de `origin/jalon-07` à `df815f9`). Objectif jouable sur le téléphone : **le Pokédex ressemble à la maquette `menu-pokedex-v1.jpg`** (trois colonnes, grand portrait vedette, grille d'artworks, silhouettes des espèces inconnues), **sans rien perdre de ce que le J6 fait déjà** (filtres, recherche, types, habitats, fiche à quatre onglets, liens vers la Carte, anti-spoiler).
>
> Sources : dossier 08 §4 et §10 (ligne `menu-pokedex-v1.jpg`), règles transverses 2, 7, 8, 9 ; décisions de Kevin des 2026-10-05/06 (rappelées en §1) ; `CLAUDE.md` règles 7, 8, 10 ; skill `ui-theme-2026`. **La maquette donne la DA et la composition, jamais la vérité fonctionnelle** : l'écrit gagne.
>
> **Aucun changement de règle de jeu, de données de jeu ni de sauvegarde.** C'est une refonte de présentation : `Pokedex`, `PokedexEntry`, `PokedexLibrary`, `PokedexQuery`, `PokedexUpdates`, `MenuDirector` et le câblage de `Boot` restent tels quels (seuls deux champs de vue s'ajoutent, §3 T1).
>
> **Une seule validation sur téléphone**, à la fin (T5).

---

## 0. État des lieux (code réel à `df815f9`)

Capture de l'écran actuel (Mac, 2340 × 1080, `tools/capture_menu.gd --only=dex_grid,dex_sheet_caught,dex_evolution`) : `build/captures/pokedex_refonte_avant/` (hors dépôt).

### 0.1 Ce qui existe et marche (J6, validé)

| Couche | Fichiers | Rôle |
|---|---|---|
| Logique | `game/pokemon/pokedex.gd`, `pokedex_entry.gd` | vu / capturé, compteurs, cartes, dates, notes ; sauvegardé |
| Données | `game/pokemon/pokedex_library.gd` (+ `pokedex_species_data.gd`, `pokedex_note_data.gd`, `pokedex_notes.gd`), `data/pokedex/kanto.json` | taille, poids, description, notes ; `size: 151` ; le **numéro** vient de `data/pokemon/species/kanto.json` (`dex`) |
| Requêtes | `game/systems/menu/pokedex_query.gd` | `grid(...)` → `PokedexGridView`, `sheet(...)` → `PokedexSheetView` (anti-spoiler : une case inconnue n'a ni espèce ni nom) |
| Mises à jour | `game/systems/menu/pokedex_updates.gd` | toasts « Pokédex mis à jour », etc. |
| Vues | `game/systems/menu/views/pokedex_grid_view.gd`, `pokedex_slot_view.gd`, `pokedex_sheet_view.gd`, `pokedex_habitat_view.gd`, `evolution_stage_view.gd` | contrats figés au T14 du J6 : **on ne fait qu'ajouter des champs** |
| Directeur | `game/systems/menu/menu_director.gd` (`set_pokedex_filter`, `open_species`, `_emit_pokedex`) | à l'arrivée, la grille **et** la fiche de l'espèce choisie (route, sinon première connue) |
| Écran | `game/ui/menu/pokedex/pokedex_screen.gd` (en-tête RETOUR + titre + compteur + 4 filtres ; panneau grille avec recherche, Type, Zone ; panneau fiche à droite qui apparaît quand une case est touchée), `pokedex_slot.gd` (case 180 × 208, pool de 151, texte dessiné d'un trait), `pokedex_sheet.gd` (vignette 160 + numéro, nom, compteurs, types ; onglets Aperçu · Habitat · Évolution · Observations), `pokedex_habitat_map.gd` | présentation seulement |
| Hôte | `game/ui/menu/trainer_menu.gd` (`show_pokedex`, `show_pokedex_sheet`, `pokedex_back`), en-tête commun × + pastille de zone, écrans placés sous l'en-tête (`MENU_BODY_TOP` = 192 px) | |
| Style | `game/ui/theme/ui_tokens.gd` (bloc `DEX_*`, l. 772-829), `ui_theme.tres` **généré** par `tools/build_ui_theme.gd` (variations `DexCell`, `DexCellSelected`, `DexCellUnknown`, `DexName`, `DexTab`, `DexPanel`…) | |
| Tests | `tests/unit/test_pokedex*.gd` (5 fichiers), `test_evolution_reveal.gd` ; `tests/integration/test_pokedex_screen.gd`, `test_menu_pokedex_screen.gd`, `test_menu_pokedex.gd`, `test_trainer_menu.gd` (Pokédex) | |
| Captures | `tools/capture_menu.gd` (scénarios `dex_*`), `tools/capture_pokedex_t16.gd` | |

### 0.2 Comment les images sont choisies aujourd'hui

Par **identifiant d'espèce**, chemin codé en constante dans chaque écran : `SPRITE_PATH := "res://assets/sprites/pokemon/placeholder/%s_front.png"` (`pokedex_slot.gd`, `pokedex_sheet.gd`, et aussi `lead_pokemon_card.gd`, `zone_panel.gd`, `moment_row.gd`, `team_slot_card.gd`, `party_target_card.gd`). Ce sont les **sprites de combat provisoires** (pixel art 64 px, affichés ×2 en `NEAREST`), **18 espèces seulement** : une espèce vue sans sprite (Reptincel dans la capture) a une case vide, la fiche une Poké Ball estompée. Une case inconnue n'a aucune image (« ??? »).

### 0.3 Ce qui change / ce qui reste

- **Change (présentation)** : la composition (trois colonnes permanentes, en-tête dans la rangée du ×), la case (artwork + numéro, silhouette pour l'inconnu), le grand portrait central, la page Aperçu de droite, la source des images (artworks officiels par **numéro**), deux variations de thème et le bloc `DEX_*` des jetons.
- **Réutilisé tel quel** : tout le §0.1 sauf les trois scripts d'écran (`pokedex_screen.gd`, `pokedex_slot.gd`, `pokedex_sheet.gd`) ; `pokedex_habitat_map.gd` réutilisé (taille ajustée) ; signaux de l'écran (`filter_changed`, `species_opened`, `route_requested`, `back_requested`) **inchangés** → `Boot` et `MenuDirector` ne bougent pas.
- **Hors périmètre** : les sprites des autres écrans (Équipe, tableau de bord, Carte, Stockage, Sac, combat) restent les sprites provisoires (question Q-2) ; aucune donnée d'espèce ajoutée (les 24 espèces actuelles ; les autres numéros restent « inconnus » tant que leurs données n'existent pas).

---

## 1. Écarts maquette ↔ dossier 08 ↔ décisions de Kevin

Décisions de Kevin (2026-10-05/06), qui **s'ajoutent au dossier 08** :
- **D1** Images = artworks officiels HD de PokeAPI (475 × 475, PNG transparent) pour les 151.
- **D2** **Silhouettes** pour les espèces inconnues (remplace le « sans silhouette » du dossier 08 §4), générées depuis l'artwork, aucune information au-delà de la forme.
- **D3** Pas de statistiques de base, pas de talents.
- **D4** Pokémon gris foncé peu lisibles sur case sombre ; morphologies longues trop petites dans une case carrée.
- **D5** Conformité à la maquette pour la DA et la composition.

| # | Élément | Maquette | Dossier 08 / décision | **Tranché** |
|---|---|---|---|---|
| E1 | Images des Pokémon | artworks HD | §règle 10 : sprites peints, « pas d'illustrations HD des 151 au J6 » | **D1** pour le **Pokédex seulement** (Q-2 pour les autres écrans). Le dossier 08 (règle 10, §4) est à mettre à jour par Kevin. |
| E2 | Espèce inconnue | silhouette + numéro | §4 : « numéro et ???, sans silhouette » | **D2** : silhouette + numéro ; plus de « ??? » dans la case (la silhouette dit déjà « inconnu »). Toujours **ni toucher, ni nom, ni fiche**. |
| E3 | Statistiques de base, talents | présents | exclus | **Exclus (D3)**. La place libérée à droite reçoit Taille · Poids et les aperçus d'Habitat et d'Évolution (E9). |
| E4 | Chaîne d'évolution avec niveaux (N. 16, N. 36) | présente | jamais de condition | **Exclu** : noms seulement, `???` pour l'inconnu (`EvolutionReveal`, inchangé). |
| E5 | « 27 / 151 », heure, argent dans l'en-tête | présents | interdits (règles 2 et 5) | **Exclus**. À leur place : « X vus · Y capturés · 151 espèces » (texte de `PokedexQuery`, inchangé). |
| E6 | Sélecteur de région « Kanto ▾ », tri « Numéro » | présents | non prévus (règles 8, 9) | **Exclus** (une seule région, un seul ordre). Leur place, en tête du panneau grille, reçoit les boutons **Type** et **Zone** existants. |
| E7 | Étoile (favori) sur le portrait | présente | favoris = individus (Équipe, Stockage), pas espèces | **Exclue**. |
| E8 | ♂ après le nom | présent | le sexe est celui d'un individu | **Exclu**. |
| E9 | Panneau droit, onglet Aperçu | Types, Talents, Stats, Habitat, Évolution | Aperçu : types, taille, poids, description à la capture | **Aperçu à droite** = Types + Taille · Poids (à la capture) puis **aperçu Habitat** (petite carte, « Zones observées : N », touche → onglet Habitat) et **aperçu Évolution** (ronds + noms). La **description** va sous le portrait (centre), comme la maquette. Onglets Habitat, Évolution, Observations = pages complètes actuelles. |
| E10 | « Vu Oui / Capturé Oui » | deux cartes | « vu N fois · capturé N fois » | Deux petites cartes sous le portrait : « Vu · 3 fois », « Capturé · 1 fois » (icône œil / Poké Ball **et** texte). Espèce seulement vue : la carte Capturé est **absente** (texte vide = absent). |
| E11 | Taille et poids | sous la description (centre) | à la capture | **À droite** dans l'Aperçu (E9) : en 1080 de haut, le centre ne peut pas tenir nom + portrait ~420 px + cartes + description + taille/poids (calcul §2.2). Défaut, règle 4. |
| E12 | Nom dans la case | absent (numéro + image) | §4 : « vu : sprite, nom » | **Comme la maquette** : numéro + image ; capturé = petite Poké Ball (symbole, règle 7). Le nom est sur le portrait au toucher. Défaut, règle 4 (à rétablir sur simple demande). |
| E13 | Taille de case | ~108 px | `ui-theme-2026` : cible tactile ≥ 128 px | **128 × 128** (la règle tactile gagne) : 4 colonnes à 1920 de large. |
| E14 | Fiche | toujours visible (3 colonnes) | J6 : la fiche s'ouvre au toucher, RETOUR la referme d'abord | **Toujours visible** (le directeur ouvre déjà une fiche à l'arrivée). RETOUR / retour Android **quittent le Pokédex** directement ; `close_sheet()` renvoie toujours faux (`TrainerMenu.pokedex_back()` inchangé). Pokédex sans aucune espèce connue (drapeau de débogage seulement) : centre et droite affichent une phrase vide « Aucune espèce enregistrée. » (`draft`). |
| E15 | Décor peint derrière le portrait | scène de village | — | **Halo radial + ombre au sol** sur le panneau (le monde flouté du menu est déjà derrière). Un décor par habitat relève de la phase DA (Q-4). |
| E16 | Recherche | dans l'en-tête | « recherche par nom » | Dans la rangée d'en-tête, comme la maquette. |
| E17 | Filtres | Tous · Vus · Capturés (pastilles) | TOUS · VUS · CAPTURÉS · HABITATS | Quatre pastilles (HABITATS gardé), casse de la maquette (« Tous », « Vus »…) ; libellés venant toujours de la vue. |
| E18 | Bouton retour | « ‹ » rond dans l'en-tête | — | Le × du menu reste à sa place ; « ‹ » (RETOUR, 128 px) juste à sa droite dans la même rangée. |
| E19 | Faute « Salaméche » | — | — | Sans objet (noms venant des données). |
| E20 | « Grand sprite vivant » | statique | §4 : vivant | Respiration discrète du portrait (échelle 1,00 ↔ 1,015, 2,4 s, `Tween`), coupée par « réduction des animations » ; fondu 150 ms au changement d'espèce. Défaut, règle 4. |
| E21 | Silhouettes dans la chaîne d'évolution | silhouette du stade inconnu (Dracaufeu sombre) | « → ??? » | **Pas de silhouette** dans l'Évolution (elle révélerait la forme **et** le lien de parenté) : rond vide + `???`, comme aujourd'hui. Question Q-1. |

---

## 2. Intégration des 151 artworks

### 2.1 Emplacement et convention

- **`assets/sprites/pokemon/official/NNN.png`** (001 à 151), les PNG PokeAPI **tels quels** (aucun recadrage ni redimensionnement des sources). C'est le chemin déjà utilisé par `art/pokemon-pilote` (9 fichiers **identiques à l'octet**, vérifié par md5 sur 004 et 095) : pas de doublon, pas de conflit de contenu.
- **Nommage par numéro, jamais par espèce** : une case inconnue n'a que son numéro (`PokedexSlotView.number`) ; la silhouette se trouve **sans connaître l'espèce** → l'anti-spoiler des vues reste intact.
- **Règle 7 (données)** : le lien espèce ↔ numéro existe déjà (`dex` dans `data/pokemon/species/kanto.json`). Le lien numéro ↔ fichier est une **convention de chemin**, pas du contenu : elle vit en **un seul endroit**, `PokedexArt` (§3 T1), comme `BattleStage.sprite_path` pour les sprites de combat. **Aucun nouveau fichier de données.** Les 151 images existent avant les données des 127 espèces manquantes : dès qu'une espèce est ajoutée à `kanto.json`, son image est là.
- **Provenance** : PokeAPI (`sprites.other.official-artwork`), artworks © Nintendo / Game Freak / The Pokémon Company ; projet personnel, APK non distribué. Le dépôt GitHub est privé ; +21 Mo de PNG dans git (fichiers < 300 Ko, LFS inutile). À noter dans `etat-projet.md`.

### 2.2 Taille d'affichage réelle et taille retenue

Le S24 (2340 × 1080, stretch `canvas_items`, aspect `expand`) affiche la référence **à l'échelle 1** en hauteur : 1 px de référence = 1 px physique.

Budget vertical : rangée d'en-tête (× / ‹ / titre / filtres / recherche) 48 + 128 + 16 → panneaux de **840 px** de haut (1080 − 192 − 48). Colonne centrale : marge 24 · numéro + nom + types ~120 · **portrait ~420** · cartes Vu / Capturé 88 · description 3 lignes ~120 · espacements ~48 → ~840. Largeur à 1920 : grille 588 (4 × 128 + 3 × 12 + 40), centre ~520, droite ~680 ; à 2340 le surplus va au panneau droit.

| Usage | Taille affichée | Source retenue |
|---|---|---|
| Grand portrait (centre) | ~420 px (boîte carrée) | **475 px, les sources telles quelles** : réduction × 0,88 en `linear`, nette ; descendre à 384 obligerait à agrandir (× 1,1, flou). **Pas de mipmaps** (réduction ≥ 0,5). |
| Case de la grille | ~112 px d'image dans 128 px | **vignette 128 px** dans un atlas (ci-dessous) |
| Ronds d'Évolution (onglet et aperçu) | 100 à 120 px | même vignette 128 px |

**Ne pas utiliser les 475 px dans la grille** : 151 textures 475² RGBA décompressées = ~136 Mo de mémoire vidéo (~180 Mo avec mipmaps) et 151 chargements. D'où l'**atlas des vignettes** : `assets/sprites/pokemon/official/atlas_128.png`, généré par un outil, 13 colonnes × 12 rangées de cases 128 + 4 px de marge transparente (anti-bavure du filtre linéaire) = **1716 × 1584**, case n = (n − 1) % 13, (n − 1) / 13 → un seul chargement, ~10,9 Mo de mémoire vidéo, tracés regroupés.

### 2.3 Poids dans l'APK (mesuré avec `cwebp` sur les 151 sources, ce que Godot embarque)

| Option | Taille |
|---|---|
| Sources PNG (dépôt) | 21 Mo |
| 475 px, WebP **sans perte** (import Godot « Lossless ») | ~13 Mo (+ ~4 Mo avec mipmaps) |
| **475 px, WebP avec perte q 0,9** (import « Lossy ») | **~4,1 Mo** |
| 384 px, avec perte q 0,9 | ~3,3 Mo (gain faible, portrait agrandi : rejeté) |
| Vignettes 128 px sans perte (151 fichiers) | ~1,8 Mo (atlas : du même ordre) |

**Recommandation** : portraits 475 px importés en **Lossy, qualité 0,9, mipmaps désactivés** (~4 Mo) + atlas 128 px **Lossless, sans mipmaps** (~2 Mo) → **≈ 6 Mo** dans l'APK (aujourd'hui 60 Mo en debug), contre ~17 Mo en Lossless avec mipmaps (réglage actuel des 9 fichiers de `art/pokemon-pilote`). Les sources PNG ne partent pas dans l'APK (seuls les `.ctex` importés). Critère de contrôle (T5) : capture 2340 de 3 portraits (Salamèche, Onix, Minidraco) en Lossy à côté du Lossless ; si des artefacts se voient à 1:1 sur les aplats ou les bords, repli en Lossless (+9 Mo), noté dans `etat-projet.md`.

Import (`.import` commités) : `compress/mode=1` (Lossy), `compress/lossy_quality=0.9`, `mipmaps/generate=false`, `process/fix_alpha_border=true`, filtre = défaut du projet (`linear`). Un test garde ces réglages (§3 T1) pour qu'un réimport ne fasse pas regonfler l'APK. **Pour `art/pokemon-pilote`** : à sa fusion, garder les `.import` de cette branche-ci pour `official/NNN.png` (même contenu PNG) ; si le combat a besoin d'autres réglages, il les justifiera alors.

### 2.4 Silhouettes : **shader** (recommandé), pas d'images précalculées

`game/ui/menu/pokedex/pokedex_silhouette.gdshader` :

```glsl
shader_type canvas_item;
uniform vec4 tint : source_color;
void fragment() {
	COLOR = vec4(tint.rgb, tint.a * texture(TEXTURE, UV).a);
}
```

Appliqué (un **seul** `ShaderMaterial` partagé, `PokedexArt.silhouette_material()`) au `TextureRect` de la case inconnue, sur la **même vignette de l'atlas**. Pourquoi le shader :
- **zéro octet** de plus dans l'APK et en mémoire vidéo (une planche de silhouettes = +11 Mo de mémoire, +1 outil à maintenir) ;
- **aucune fuite au-delà de la forme** : la sortie ne lit que l'alpha (couleurs, traits, yeux jamais tracés) ; les parties translucides (gaz de Fantominus) restent de la forme ;
- teinte réglable par jeton (`UiTokens.DEX_SILHOUETTE`, défaut `Color(0.05, 0.07, 0.10, 0.88)`, plus sombre que la case, sur le halo) et par le contraste renforcé des Paramètres.
Coût : un changement de matériau entre cases connues et inconnues casse le regroupement des tracés (≤ ~40 cases visibles → ≤ ~40 tracés), négligeable. Le shader ne s'applique **jamais** au portrait ni à l'Évolution (E21).

### 2.5 Recadrage, taille relative, halo (décision D4)

Mesures sur les 151 sources (boîte englobante de l'alpha, couverture, luminance moyenne des pixels opaques) :
- **Toutes** les sources ont déjà leur plus grand côté à 431 px dans 475 (marge PokeAPI de 22 px) : le recadrage ne gagne que **~10 %**, uniformément. L'outil d'atlas recadre quand même à la boîte englobante (+ 2 px) avant de réduire à 124 px de grand côté (centré dans la case de 128).
- Abo (023) : couverture 0,51, **plus** que Salamèche (0,35) ; Onix (095) 0,37 ; Minidraco (147) 0,24 ; Racaillou (074) 0,15 (large et plat). Les « petits » de la planche s'expliquent surtout par **une couleur sombre sur une case sombre** (luminance d'Abo 0,47, Onix 0,48, Tadmorv 0,51 ; médiane des 151 : 0,59 ; les plus sombres : Lippoutou 0,38, Spectrum 0,40, Nosferapti 0,41) et, pour Minidraco et Racaillou, par une forme fine ou plate.
- **Remède retenu (défaut, règle 4)** : un **halo radial clair universel** derrière chaque image (cases, portrait, ronds d'Évolution) — une seule `GradientTexture2D` radiale construite en code depuis les jetons (`DEX_HALO_CENTER` défaut `Color(1, 1, 1, 0.16)` → transparent ; case inconnue : moitié), **aucune donnée par espèce** ; la case passe aussi à un fond un peu plus clair que le panneau (`DEX_CELL_BG`, comme la maquette). Pas de cas particulier codé pour 074/075/088/089/095.
- **Pas de facteur d'échelle par espèce** pour l'instant : l'artwork remplit déjà la case au maximum sans le couper. Si la planche de contrôle (T5, scénario `dex_planche` : les 151 « vus ») montre encore Minidraco / Racaillou trop petits, on ajoutera une **surcharge par numéro** dans `data/pokedex/art.json` (`{ "147": { "scale": 1.15 } }`, image rognée par la case) — seulement sur décision de Kevin.

---

## 3. Découpage

Ordre : **T1** (fondations) → **T2 ∥ T3** (en parallèle, deux worktrees) → **T4** (relecture architecte + captures) → **T5** (QA téléphone, validation de Kevin). Chaque tâche : `tools/test.sh` vert, import propre, captures relues, `etat-projet.md` à jour dans le même commit.

### T1 — Fondations images (architecte)

Fichiers :
- `assets/sprites/pokemon/official/001.png` … `151.png` + `.import` (Lossy 0,9, sans mipmaps) ;
- `tools/build_pokedex_atlas.gd` (`extends SceneTree`) : lit les 151 PNG (`Image.load_from_file`), `get_used_rect()` + 2 px, réduit au grand côté 124 (`INTERPOLATE_LANCZOS`), centre dans la case 128, `blit_rect` dans l'atlas, `save_png` ; refuse un numéro manquant ; constantes lues dans `PokedexArt` (`load("res://game/ui/menu/pokedex/pokedex_art.gd")`) — **une seule source** pour la disposition ;
- `assets/sprites/pokemon/official/atlas_128.png` + `.import` (Lossless, sans mipmaps) ;
- `game/ui/menu/pokedex/pokedex_art.gd` — `class_name PokedexArt extends RefCounted`, statique : `const COUNT := 151`, `ATLAS_COLUMNS := 13`, `THUMB := 128`, `THUMB_PAD := 4`, `PORTRAIT_DIR` ; `portrait_path(number: int) -> String` ("" hors 1..COUNT) ; `has_portrait(number) -> bool` ; `thumbnail(number: int) -> AtlasTexture` (cache, null hors bornes) ; `thumb_region(number) -> Rect2` ; `silhouette_material() -> ShaderMaterial` (partagé) ; `halo_texture() -> Texture2D` (partagée) ;
- `game/ui/menu/pokedex/pokedex_silhouette.gdshader` ;
- jetons `DEX_SILHOUETTE`, `DEX_HALO_CENTER`, `DEX_HALO_UNKNOWN_ALPHA` dans le bloc `DEX_*` de `ui_tokens.gd` ;
- **vues** (ajout de champs seulement) : `EvolutionStageView.number: int` (0 si stade inconnu : anti-spoiler) rempli par `EvolutionReveal` depuis `SpeciesData.dex`. `PokedexSlotView` et `PokedexSheetView` portent déjà `number`.

Tests GUT :
- `tests/unit/test_pokedex_art.gd` (nouveau) : chemins de 1, 4, 151 ; 0, 152, −1 → "" / null ; les 151 portraits existent ; région de 1 = (2, 2, 128, 128) au pas de 132 (2 px de marge de chaque côté), région de 151 dans l'atlas ; atlas de 1716 × 1584 ; **chaque case de l'atlas a de l'alpha** (`get_image().get_region(...).get_used_rect()` non vide) et **rien ne déborde dans les marges** ; le cache rend la même `AtlasTexture` ; `silhouette_material()` partagé, shader chargé ; **réglages d'import** des 151 `.import` (Lossy, qualité 0,9, mipmaps faux) et de l'atlas (Lossless, mipmaps faux) lus par `ConfigFile`.
- `test_evolution_reveal.gd` (+2) : `number` rempli pour un stade connu, **0** pour un stade inconnu.
- `test_pokedex_query.gd` (+1) : une case inconnue a son `number` et **toujours** `species_id` vide.

Critères : import propre ; tests verts ; APK debug reconstruit et **taille notée** (attendu ≈ +6 Mo) ; aucun écran modifié.

### T2 — La case de la grille (ui-mobile) — parallèle à T3

Fichiers : `game/ui/menu/pokedex/pokedex_slot.gd` ; sous-bloc `DEX_CELL_*` de `ui_tokens.gd` (taille **128 × 128**, image 112, numéro 22 en haut à gauche, Poké Ball 24 en haut à droite, fond `DEX_CELL_BG`) ; variations `DexCell`, `DexCellSelected` (liseré `ACCENT` 3 px + lueur, comme la maquette), `DexCellUnknown` dans `tools/build_ui_theme.gd`, puis `ui_theme.tres` **régénéré** (jamais édité à la main).

- Case connue : halo + `PokedexArt.thumbnail(number)` + numéro ; capturée : Poké Ball (symbole) ; seulement vue : rien de plus. Plus de nom ni de « Vu / Capturé » dans la case (E12).
- Case inconnue : halo atténué + **même vignette avec `silhouette_material()`** + numéro estompé ; `MOUSE_FILTER_IGNORE` (le doigt traverse et fait défiler) ; jamais d'espèce, de nom, de toucher.
- `SPRITE_PATH` (placeholder) supprimé de ce fichier. Pool de 151 inchangé ; `set_view` ne charge rien (l'atlas est déjà en mémoire après le premier appel).
- API conservée : `set_view`, `get_view`, `has_image`, `get_image`, `get_texts` (renvoie désormais le numéro, et le nom pour une case connue pour les tests, même s'il n'est pas dessiné — à documenter), plus `has_silhouette() -> bool`.

Tests : `tests/integration/test_pokedex_screen.gd` mis à jour (cases) : une case inconnue `has_silhouette()` vrai, `has_image()` faux, matériau = celui de `PokedexArt`, région = `thumb_region(number)`, aucun nom, ignorée par la souris ; une case vue : image sans matériau, pas de Poké Ball ; capturée : Poké Ball ; **le pool reste ≤ 151** après dix changements de filtre ; une case = 128 × 128 (≥ `TOUCH_MIN`).

Critères : capture `dex_grid` (2340 et 1920) relue : silhouettes lisibles mais muettes (aucune couleur ni trait), artworks nets, Racaillou / Onix / Tadmorv lisibles sur le halo (scénario `dex_planche`, T4).

### T3 — Composition trois colonnes et portrait (ui-mobile) — parallèle à T2

Fichiers :
- `game/ui/menu/menu_screen.gd` : `var covers_header: bool = false` (l'écran occupe aussi la rangée du ×) ;
- `game/ui/menu/trainer_menu.gd` : dans `_select`, la pastille de zone est cachée quand `screen.covers_header` (≈ 3 lignes) ;
- `game/ui/menu/pokedex/pokedex_screen.gd` : `covers_header = true`, l'écran remonte de `MENU_BODY_TOP − SAFE_MARGIN` et laisse `MENU_CLOSE_SIZE + GAP` à gauche pour le × ; rangée d'en-tête : ‹ RETOUR · Poké Ball + titre + compteur · 4 pastilles · recherche ; corps : grille (en tête : Type, Zone) | centre | droite, **permanents** ; `close_sheet()` → faux (E14) ;
- `game/ui/menu/pokedex/pokedex_portrait.gd` (nouveau, `class_name PokedexPortrait extends Control`) : numéro, nom (`DexName`), types (à la capture), halo + ombre au sol + portrait 475 (`PokedexArt.portrait_path`, chargé à l'affichage), respiration (`speed_scale`, coupée par la réduction des animations), fondu au changement, cartes Vu / Capturé, description (à la capture) ou l'encouragement actuel ;
- `game/ui/menu/pokedex/pokedex_sheet.gd` : devient le panneau droit (onglets + pages) ; Aperçu = Types + Taille · Poids, aperçu Habitat (petite carte, « Zones observées : N », touche → onglet Habitat), aperçu Évolution ; ronds d'Évolution en vignettes `PokedexArt.thumbnail(stage.number)` + halo, rond vide si inconnu ; `SPRITE_PATH` supprimé ;
- sous-bloc de mise en page `DEX_*` (largeurs, portrait 420, gaps) dans `ui_tokens.gd` ; variations de panneau / pastilles dans `tools/build_ui_theme.gd` ;
- `tools/capture_menu.gd` : scénarios `dex_*` mis à jour, `dex_planche` ajouté (vues fabriquées : les 151 cases « vues » dont 023, 074, 075, 088, 089, 095, 147 ; puis la même grille toute inconnue).

Le texte « Zones observées : N » est **ajouté à la vue** par l'architecte au début de T3 (`PokedexSheetView.habitat_count_text`, `PokedexQuery`, test) : jamais un texte construit dans l'écran.

Tests : `test_pokedex_screen.gd` (composition) : à 1920 et 2340 de large, les trois panneaux visibles, **aucun chevauchement** avec le ×, aucun texte tronqué dans l'en-tête ; une espèce seulement vue → ni types, ni taille, ni poids, ni description, ni carte Capturé, **ni « ??? »** ; capturée → tout ; jamais de statistiques ni de talents (aucun libellé « PV », « Attaque », « Talent ») ; l'onglet ouvert reste ouvert au changement d'espèce ; RETOUR émet `back_requested` directement ; la pastille de zone est cachée sur le Pokédex et revient sur le tableau de bord ; portrait chargé depuis `official/004.png` pour Salamèche ; respiration absente avec `speed_scale = 0`. `test_menu_pokedex_screen.gd`, `test_trainer_menu.gd` (Pokédex) ajustés (plus de « fiche fermée d'abord »). `test_menu_pokedex.gd` inchangé (directeur).

Critères : capture `dex_sheet_caught`, `dex_sheet_seen`, `dex_habitat`, `dex_evolution`, `dex_notes`, `dex_search_empty` relues à 2340 et 1920 ; comparaison côte à côte avec la maquette (composition, lumière, place du portrait).

### T4 — Relecture et planche de contrôle (architecte)

Fusion T2 + T3 sur `pokedex-refonte`, relecture (`godot-conventions`, couplages, aucune couleur ou taille en dur, aucune logique dans l'écran, aucun chemin d'image hors de `PokedexArt`), `tools/test.sh`, captures `dex_planche`, mise au point des jetons (halo, silhouette, teinte de case). Si Minidraco / Racaillou restent trop petits → question à Kevin avec la capture (§2.5), sans coder de surcharge.

### T5 — QA téléphone et validation (qa-mobile, puis Kevin)

APK (`tools/deploy_s24.sh`), départ de débogage avec le Pokédex débloqué **et** la vraie partie de Kevin si l'activation est fusionnée : ouverture du Pokédex (mesure du temps jusqu'à l'image stable, attendu < 300 ms ; premier chargement de l'atlas mesuré à part), défilement de la grille de 151 cases à 60 fps (`[perf]`), changement d'espèce (portrait sans saccade), filtres, recherche au clavier Android, retour Android, lien Habitat → Carte → retour. Taille de l'APK avant / après. Captures S24 : grille, fiche capturée, fiche vue, onglets. Contrôle Lossy vs Lossless des portraits (§2.3). **Validation de Kevin** : fonctionnel, lisible, bien placé (règle 3) ; remarques de rendu → « Reportés ».

### Tâches parallélisables

- **T2 ∥ T3** : fichiers disjoints sauf `ui_tokens.gd` (sous-blocs distincts, `DEX_CELL_*` pour T2, mise en page pour T3) et `tools/build_ui_theme.gd` (variations `DexCell*` pour T2, panneaux / pastilles pour T3) ; `ui_theme.tres` est **régénéré** après fusion, jamais fusionné à la main.
- T1 est un préalable court (les deux ont besoin de `PokedexArt`) ; pour ne pas attendre, T2 et T3 peuvent démarrer sur la **signature** de `PokedexArt` donnée ci-dessus.

---

## 4. Risques de conflit avec le J7 en cours et stratégie de fusion

Le J7 restant (T20 : Chen et validation du J7A ; 7B.2 : rival n° 2) touche `boot.gd`, scènes, données de dialogues et cinématiques, combat, `debug_start/`. **Aucun fichier de l'écran Pokédex.** Fichiers communs possibles :

| Fichier | J7 | Refonte | Risque | Parade |
|---|---|---|---|---|
| `docs/tech/etat-projet.md` | à chaque tâche | à chaque tâche | **certain** | une section dédiée « Refonte du Pokédex (`pokedex-refonte`) » en tête ; à la fusion, garder les deux |
| `game/ui/theme/ui_tokens.gd` | possible (nouveaux jetons en fin de fichier) | bloc `DEX_*` (l. 772-829) seulement | faible | ne rien déplacer hors du bloc `DEX_*` |
| `tools/build_ui_theme.gd` / `ui_theme.tres` | possible | variations `Dex*` | moyen sur le `.tres` | fusionner le script, puis **régénérer** `ui_theme.tres` ; jamais de résolution à la main du `.tres` |
| `game/ui/menu/trainer_menu.gd` / `menu_screen.gd` | Boutique et Stockage déjà fusionnés ; rien de prévu | ~5 lignes (`covers_header`) | faible | modification minimale, isolée dans `_select` |
| `tools/capture_menu.gd` | scénarios Boutique / Stockage | scénarios `dex_*` | faible | ne toucher qu'à la fonction des scénarios Pokédex |
| `evolution_reveal.gd`, `evolution_stage_view.gd` | non | un champ | très faible | — |
| Tests `test_trainer_menu.gd` | possible | partie Pokédex | faible | — |
| `assets/sprites/pokemon/official/*` | non (mais `art/pokemon-pilote`) | 151 + atlas | `.import` des 9 pilotes | garder les `.import` de cette branche (§2.3) |

Stratégie :
1. Avant **chaque** tâche : `git fetch` puis `git merge origin/jalon-07` dans `pokedex-refonte` (jamais de rebase d'une branche partagée).
2. **Ne pas fusionner la refonte dans `jalon-07` pendant la QA du J7A (T20)** : la validation du J7A se fait sur l'écran que Kevin connaît. Défaut : fusion de `pokedex-refonte` **après la validation du J7** (dans `main`, ou dans `jalon-07` entre le J7A et le J7B si Kevin le préfère — Q-5), dans un **worktree d'intégration**, puis `tools/test.sh` complet et import.
3. La validation téléphone de la refonte (T5) se fait sur la branche elle-même (APK de `pokedex-refonte`), indépendamment du J7.

---

## 5. Questions pour Kevin

Vraies décisions :
- **Q-1 — Silhouettes dans la chaîne d'Évolution ?** La maquette montre le stade inconnu en silhouette. Cela révèle la forme **et** le lien de parenté (« Salamèche → [forme de Reptincel] »), au-delà de la grille où la silhouette n'est liée à rien. *Défaut : non, rond vide et « ??? » (dossier 08 §4).*
- **Q-2 — Les artworks officiels ailleurs que dans le Pokédex ?** (Équipe, Pokémon de tête du tableau de bord, Carte « Pokémon observés », Stockage, choix du Pokémon du Sac.) Le dossier 08 règle 10 dit « sprites peints, une seule main ». *Défaut : Pokédex seulement ; le reste garde les sprites provisoires jusqu'à la phase DA.* Le dossier 08 (règle 10 et §4) est à mettre à jour avec D1 et D2.
- **Q-3 — Minidraco, Racaillou (formes fines ou plates)** : après halo et recadrage, s'ils paraissent encore petits sur la planche de contrôle, accepte-t-on un agrandissement par espèce qui **rogne** légèrement l'image dans la case ? *Défaut : non, l'image entière, au maximum de la case.*
- **Q-4 — Décor derrière le grand portrait** (la maquette met une scène peinte) : un décor par habitat est-il voulu à terme ? *Défaut : halo et ombre au sol maintenant ; décor = phase DA.*
- **Q-5 — Moment de la fusion** : après la validation du J7 complet, ou entre le J7A et le J7B ? *Défaut : après le J7.*

Petites questions, valeurs par défaut appliquées (règle 4) :
- Case de la grille sans nom ni « Vu / Capturé » écrit, Poké Ball pour « capturé » (E12) ; 128 × 128 (E13).
- Taille et poids dans l'Aperçu de droite, description sous le portrait (E9, E11).
- RETOUR quitte le Pokédex directement, la fiche est toujours visible (E14).
- Respiration du portrait 1,5 %, 2,4 s ; fondu 150 ms (E20).
- Teinte de silhouette `Color(0.05, 0.07, 0.10, 0.88)`, halo blanc 16 % au centre.
- Portraits en Lossy 0,9 sans mipmaps, atlas 128 Lossless (§2.3) ; repli Lossless si artefacts visibles sur le téléphone.
- « Aucune espèce enregistrée. » (Pokédex vide, débogage seulement) — texte `draft`.
