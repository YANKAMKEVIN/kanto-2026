# Série Johto — art des Pokémon de Johto (51 espèces)

> Chantier ouvert le 2026-11-04 (décision de Kevin : prendre de l'avance sur l'art de Johto, en
> commençant par les Pokémon). Branche `claude/art-pokemon-johto-e3b75a`. Script de la série :
> `tools/art/serie_johto_pokemon.py`. Mêmes règles que Kanto : artwork officiel pour le Pokédex et
> l'adversaire, dos de combat peints, Pokémon du monde peints simplifiés, cris PokeAPI ; une planche
> pilote validée par Kevin avant la production en masse des images peintes.

## 1. Inventaire au départ (`main` @ 81404c72)

Les 51 espèces de `data/pokemon/species/johto.json` (152 à 251, Pokédex 202) n'avaient **aucun**
asset définitif :

| Asset | Où le jeu le lit | État au départ |
|---|---|---|
| Artwork officiel (Pokédex, adversaire, évolution, carte de capture) | `assets/sprites/pokemon/official/NNN.png` via `PokedexArt` (`COUNT` = 151) | absent : Pokédex sans image, adversaire en silhouette numérotée |
| Vignette 128 (grille du Pokédex, équipe, ronds d'évolution, cartes de combat) | `official/atlas_128.png` + `crops.json` (`tools/build_pokedex_atlas.gd`) | atlas de 151 cases (13 × 12) |
| Dos de combat | `assets/sprites/pokemon/dos/dos_rb_NNN.png` (> `dos_ia` > `dos3d`) via `BattleArt` | silhouette provisoire `placeholder/<espèce>_back.png` (« 158 ») |
| Face provisoire | `placeholder/<espèce>_front.png` (`tools/gen_placeholder_battlers_johto.py`, JOH2) | silhouette : à retirer quand l'artwork est là |
| Pokémon du monde, compagnon | `assets/sprites/pokemon/painted/<espèce>_frames.tres` (`CharacterLook`, `"sprite": "pokemon/<espèce>"`) | aucun : Germignon, Héricendre, Kaiminus de la table d'Orme (`data/npcs/olivine_center_room.json`) tombent sur l'apparence générique (figurine humaine verte) |
| Icône d'équipe | pas d'icône à part : la vignette de l'atlas sert partout | — |
| Cri | `assets/audio/cries/<n>.ogg` via `CryCatalog` (`sfx.json` « cries.count » = 151) | absent |
| Points d'effets de combat | `data/battle/fx_anchors.json` (`tools/art/fx_anchors.py`) | absents (test sauté au-delà de 151) |
| Icônes du Sac : Roche Royale, Peau Métal, Écaille Draco, Améliorator | `assets/ui/items/<id>.webp` via `MenuArt.item_icon` | absentes (icône générique) |

Pokémon de Johto déjà demandés comme sprites du monde par les branches en cours (relevé du
2026-11-04) : `pokemon/suicune` et `pokemon/lugia` (JOH7, Tourbillon, `verb: observe`, face au
joueur) ; `pokemon/entei` et `pokemon/ho_oh` (JOH8, toit de la Tour Carillon, idem). Les Écrémeuh
de la ferme (Route 39) sont des marqueurs sans image : hors de cette série (à brancher par une
session de cartes si Kevin le veut).

## 2. Chaînes réellement utilisées sur Kanto, appliquées à Johto

| Asset | Chaîne de Kanto | Pour Johto |
|---|---|---|
| Artwork | PokeAPI `sprites/pokemon/other/official-artwork/NNN.png` (475 × 475), copié tel quel ; import Lossy 0,9 sans mipmaps | idem, fait (51) |
| Atlas et cadres | `godot -s res://tools/build_pokedex_atlas.gd` | atlas étendu à 13 × 20 cases (numéros 1 à 251, cases sans espèce vides) ; la liste des numéros vient des données d'espèces |
| Orientation de l'adversaire | `BattleArt.FACING_RIGHT` (relevé sur planche) | + 154, 155, 179, 233, 250 (Méganium, Héricendre, Wattouat, Porygon2, Ho-Oh) |
| Dos de combat | trois chaînes successives : 3D X/Y rendu Blender puis repeint sur Colab (`dos_t13.py`, modèles à télécharger à la main par Kevin, 20 espèces) ; dos IA Codex « corps entier » (`serie_dos.py`, 77) ; **dos RB Codex en cadrage B** (`serie_dos_rb.py`, 62, la chaîne en vigueur depuis la décision de Kevin du 2026-10-25) | **dos RB Codex** (gabarit `DOS_RB` de `serie_dos_rb.py`, sujet décrit sans nommer l'espèce, r1 avec l'artwork joint, r2 sans image, r3 « design original »). La voie 3D demande des téléchargements et Colab à la main : réservée aux refus |
| Pokémon du monde qui marche (compagnon, table) | planche 4 × 4 (1024 × 1536) Codex, ancres = héros `PERSO_P2_PEINT_r1` + planche validée proche (`serie13.py`) → `manifeste.json` « pokemon » → `preparer.py` → `painted/<id>_sheet.png` → `build_character_frames.gd` (`LOOKS`, `IDLE_FROM_WALK`) | idem pour les trois starters |
| Pokémon d'ambiance (posé, observé) | feuille 4 × 1 en boucle (`serie27.py`, Artikodin) → « pokemon_boucles » → `LOOPING_POKEMON` | idem pour Suicune, Lugia, Entei, Ho-Oh |
| Cri | PokeAPI `cries/pokemon/latest/N.ogg` → `tools/audio/prepare_sfx.py --batch` (mono, Vorbis q4, crête −3 dB, silence de fin retiré) | idem, fait (51) ; `sfx.json` « cries.count » = 251 |
| Icône d'objet | Codex (`menu_peint.py`), `.webp` | idem pour les quatre objets d'évolution |

## 3. Planche pilote (à valider par Kevin avant la masse)

Germignon, Héricendre, Kaiminus (dos RB, planche de marche), Suicune (dos RB, feuille d'ambiance),
Tyranocif (grand dos RB) et les quatre icônes d'objets. Les artworks et les cris (sources
officielles, mécaniques) n'attendent pas la validation.

Questions à Kevin avec la planche (défauts appliqués s'il ne répond pas) :
- **Compagnons de Johto** [D] : les trois starters seulement (comme A-10 pour Kanto au départ). Leurs
  évolutions et d'autres espèces plus tard, sur demande.

### Résultat de la pilote (2026-11-04)

Planche `serie-johto/planche-pilote.jpg`, captures `serie-johto/pilote-combat.jpg` (vrai combat,
Route 39) et `serie-johto/pilote-table-orme.jpg` (vraie table d'Orme). Relecture :
- dos RB de Germignon, Héricendre, Kaiminus, Suicune : fidèles, même main que les artworks ;
- dos RB de Tyranocif : fidèle mais plus sombre et plus « réaliste » que les autres (à surveiller
  sur les grandes espèces blindées : Steelix, Ymphect, Donphan) ;
- planches de marche : Germignon et Kaiminus du premier coup ; Héricendre en r3 (r2 sans ancre
  ressemblait à une musaraigne, r4 au museau trop court : écartés) ;
- Suicune d'ambiance (4 images, de face) : fidèle ;
- icônes : Roche Royale, Peau Métal, Écaille Draco, Améliorator (remplacent les aplats du JOH0).
Refus de Codex : le filtre n'est pas déterministe (dos de Germignon refusé 3 fois puis accepté au
4e essai, même prompt) ; le script relance la dernière révision, et `REVISIONS` /
`MARCHE_REVISIONS` reformulent le sujet.

## 4. Suivi

| Étape | État |
|---|---|
| Artworks 51 + atlas + cadres + orientation | fait |
| Cris 51 | fait |
| Planche pilote | faite, envoyée à Kevin (2026-11-04) |
| Dos RB 51 | après validation |
| Planches du monde (3 starters, 4 légendaires) | après validation |
| Icônes du Sac (4) | après validation |
| Points d'effets de combat | après les dos |
| Silhouettes provisoires de Johto retirées | à la fin |
