# Série 23 — Le Repos des esprits, lot d'art 21.0 (jalon 21)

> **À VALIDER par Kevin** (planche `build/art/J21_KIT_v1.png` et vues générales dans
> `docs/design/reference/`). Rédigée le 2026-10-15 (branche `j21-art`, depuis `docs/dossier-24-j21`).
> Conception : `docs/design/dossier-24-repos-des-esprits.md` §14.4, §19 ; plan
> `docs/tech/jalon-21.md` §2.16 (T6), T7 (génération, **sans intégration**) et T8 (vues, variante de
> Céladopole). Aucun code de jeu, **rien dans `assets/`, aucun manifeste, aucun `.tres`** : l'intégration
> (manifeste, `build_character_frames.gd` avec `mr_fuji` et l'animation `pray`, `BattleArt`, `FluteNotes`,
> `SpiritLight`) revient au plan technique après validation.

## Numéro de série

**23**, vérifié le 2026-10-15 :
- `git for-each-ref` (toutes les branches locales et `origin/*`) puis `git ls-tree` de
  `docs/design/fiches-assets/` et de `tools/art/` : fiches 01, 12 à 17, 19 (`origin/jalon-17`), 20
  (`origin/jalon-19`) ; scripts `serie06` à `serie20` ; `tools/art/prompts/serie18/` (J16) ;
  **aucune trace de 21 ni de 22** ;
- `git grep` « série 21 / série 22 » sur les branches `j20*`, `plan-j20`, `dossier-2*`, `j18` : rien ;
  le plan du J21 (§2.16) laisse 21 et 22 au J18 et au J20 (« prochain numéro libre », pas encore de
  fiche) : **23 est donc libre** et reste le défaut du plan ;
- **À revérifier au push** (« le second fusionné renumérote ») : si le J18 ou le J20 prend 23, renommer
  la fiche, `tools/art/serie23.py` et `tools/art/prompts/serie23/` (les identifiants d'images ne portent
  pas le numéro).

## Outil

`tools/art/serie23.py` (reprend `ADN`, `LUMIERE_NE`, `MODELE_MARCHE`, `_Planche` des séries 06 à 12 ;
mêmes conventions que `serie19.py` / `serie20.py`) :

| Option | Rôle |
|---|---|
| `--prompts` | écrit `tools/art/prompts/serie23/<NOM>_r1.txt` (sans Codex) |
| `--ancres` | copie dans `$ART` les ancres absentes (checkout principal et copies de travail) |
| `--commandes` | liste les appels `tools/art/generer.sh` avec leurs images jointes |
| `[NOM …]` | génère avec Codex ; **règle de Kevin** : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais), refus consignés dans `$ART/refus_serie23.log` |
| `--contact [sortie]` | planche de contact **à l'échelle du jeu** (1 case = 96 px, héros 128 px) → `build/art/J21_KIT_v1.png` |
| `--svg [sortie]` | icône vectorielle `poke_flute.svg` (128 × 128, style de `potion.svg`) |

Les **vues générales** (T8) utilisent `tools/art/plan_aplats_j21.py` (plans en aplats des trois
grilles) et `tools/art/prompts/CONCEPT_{TOUR_POKEMON_7F,ROUTE12,ROUTE16}_VUE_GENERALE_r1.txt`.

## Le kit (tableau de §2.16, élément par élément)

| Élément du plan | Décision | Fichier d'image (dans `build/art/`) | Prompt |
|---|---|---|---|
| Vue peinte du 7F | **neuve** | `CONCEPT_TOUR_POKEMON_7F_VUE_GENERALE_r1.png` | `prompts/CONCEPT_TOUR_POKEMON_7F_VUE_GENERALE_r1.txt` |
| Vue peinte de la Route 12 nord | **neuve** | `CONCEPT_ROUTE12_VUE_GENERALE_r1.png` | `…ROUTE12…_r1.txt` |
| Vue peinte de la Route 16 est | **neuve** | `CONCEPT_ROUTE16_VUE_GENERALE_r1.png` | `…ROUTE16…_r1.txt` |
| Variante « apaisée » du 6F | **rien à peindre** : texture de brume du J19, alpha réduit [D plan] | — | — |
| Planche M. Fuji (marche) | **neuve** | `PNJ_FUJI_NE_r1.png` (4 × 4) | `serie23/PNJ_FUJI_NE_r1.txt` |
| M. Fuji, prière agenouillée | **neuve** (animation `pray`) | `PNJ_FUJI_PRIERE_NE_r1.png` (1 × 4 poses) | `serie23/PNJ_FUJI_PRIERE_NE_r1.txt` |
| Pêcheur | **existe** (`pecheur_sheet.png`, `pecheur_idle_sheet.png`) | — | — |
| Sbires Rocket | **existent** (`rocket_grunt_m/f_frames.tres`) | — | — |
| Osselait, sprite de monde (≈ 56 px) | **neuf** | `POKE_OSSELAIT_NE_r1.png` (4 × 4) | `serie23/POKE_OSSELAIT_NE_r1.txt` |
| Ossatueur, Ronflex (face) | **existent** (`official/105.png`, `143.png`) | — | — |
| Ronflex (dos) | **neuf, provisoire IA** (voir « Dos ») | `DOS_RONFLEX_r1.png` | `serie23/DOS_RONFLEX_r1.txt` |
| Ronflex endormi (monde) | **existe** (`snorlax_frames.tres`, J17) | — | — |
| Ptitard, Tentacool (face) ; dos | **existent** / provisoire suffisant [D plan] | — | — |
| Icône de la Poké Flûte | **neuve** : planche peinte (modèle des planches du Sac) **et** SVG | `UI_OBJETS_J21_PLANCHE_r1.png`, `poke_flute.svg` | `serie23/UI_OBJETS_J21_PLANCHE_r1.txt` |
| Notes de musique | **neuves** : 4 notes peintes | `FX_NOTES_PLANCHE_NE_r1.png` | `serie23/FX_NOTES_PLANCHE_NE_r1.txt` |
| Halo `SpiritLight` | **neuf** (halo pâle) ; repli : halo `candle` décoloré [D plan] | `FX_HALO_SPIRIT_NE_r1.png` | `serie23/FX_HALO_SPIRIT_NE_r1.txt` |
| Fonds de combat | **existent** (`tour_pokemon`, `route_11_coast`, `route_24_pont`, `route_5_6_prairie`) | — | — |
| Intérieur du poste de la Route 12 | **réemploi** de la coque de maison [D plan] | — | — |

### Dos de Ronflex (pipeline des dos)

La chaîne validée (rendu 3D X/Y repeint par IA sur Colab) exige le **modèle 3D** de Ronflex : il n'est
pas dans `~/dev/kanto-2026-modeles/art-pokemon-pilote/modeles/` (Bulbizarre, Carapuce, Magicarpe,
Magnéti, Nosferapti, Onix… seulement) et Colab ne se lance pas depuis cette session. Le dos est donc un
**provisoire IA peint par Codex**, comme celui de Fantominus (série 20) : 1024 × 1024 RGBA, sujet ≈ 85 %
de la hauteur, bas à ≈ 120 px du bord, famille de rendu des artworks officiels, ancres `dos_ia_095`
et `dos_ia_093` pour l'angle (trois quarts dos, regard haut droite). Remplaçable par un vrai rendu X/Y
(`dos3d_143` puis `dos_ia_143`) si Kevin télécharge le modèle sur The Models Resource ; le nom de
fichier visé reste `dos_ia_143.png`.

### Icône de la Poké Flûte

Le skill `ui-theme-2026` ne décrit pas d'icône d'objet ; le jeu utilise deux familles : les SVG
d'origine (`assets/ui/icons/items/poke_ball.svg`, `potion.svg`) et les icônes **peintes** du Sac
(`assets/ui/items/*.webp`, chaîne `preparer_menu.py`, planches `UI_OBJETS_J*`). Le plan §2.16 vise
`assets/ui/icons/items/poke_flute.svg` ; je livre **les deux** : la planche peinte (alignée sur les
objets récents : Potion, Pierre Lune, CS05, fossiles) et un SVG de repli dans le style de `potion.svg`.
Kevin choisit ; l'autre est abandonnée.

## Essais, refus, choix

Génération du 2026-10-15/16 (Codex, aucun coût d'API). **Incident** : limite d'usage de l'abonnement
ChatGPT atteinte le soir du 15 (les premiers appels ont tous échoué, « usage limit », retour à 00:34) ;
relance séquentielle après la remise à zéro. Aucune image perdue.

| Image | Essais | Retenu | Remarque |
|---|---|---|---|
| Vue 7F | r1 | **r1** → `reference/tour-pokemon-7f-vue-generale-v1.png` (+ `-plan-v1`) | nef, 2 × 7 tombes, 4 bougies, autel, escalier, Fuji à genoux de dos, 3 Sbires en zigzag aux bons côtés. Tombes : 7 rangées au lieu de 8 (la grille fait foi). |
| Vue Route 12 | r1, r2 | **r2** → `route-12-vue-generale-v1.png` | r1 : 3 pêcheurs mal placés ; r2 (r1 jointe, corrections de positions) : 4 pêcheurs, reste identique. Ponton, poste sur l'eau (2 portes), îlot vide, chaussée de l'ouest. Le poste est un toit à quatre pans ; le tracé du ponton est fidèle mais pas au pixel : la grille fait foi. |
| Vue Route 16 | r1 | **r1** → `route-16-vue-generale-v1.png` | chemin, clôture, goulet de rochers (un peu moins resserré que 2 cases), clairière haute avec son grand arbre, façade du poste en chaumière à enseigne vierge, aucun personnage. |
| Fuji marche | r1 | **r1** | reconnaissable (cheveux blancs, lunettes rondes, veste vert sapin, chapelet) ; vrai alpha. |
| Fuji prière | r1 | **r1** | 4 poses : dos, dos (souffle), profil gauche, face yeux fermés. |
| Osselait | r1 (refusé 4 fois : filtre de sécurité, avec et sans pièce jointe) ; r2 (prompt sans le mot « crâne », « casque de céramique », sans artwork joint) | **r2** | refus consignés ; r2 accepté du 1er coup, très fidèle. |
| Dos de Ronflex | r1 (refusé 4 fois), r2 (reformulé, sans nom ni « projet », obtenu SANS pièce jointe au 4e essai), r3 (assis droit, sans plantes de pied : refusé 2 fois) | **r2**, 1254 × 1254 | pose discutable : jambes tendues vers le spectateur, plantes de pied visibles, on lit « couché sur le ventre » ; sujet à 100 % de la hauteur (à recadrer à 85 % / 1024 à la préparation). Prompt r3 prêt pour l'app ChatGPT. |
| Notes | r1 | **r1** | 4 notes bleu-turquoise nettes, vrai alpha. |
| Halo | r1 (rejeté : disque quasi opaque au bord franc et frangé) | **r2 procédural** (`--halo`, 512 px) | cœur blanc lilas, 0 % au bord, lisse. |
| Icône Flûte | r1 | **r1** + SVG | flûte bleue à anneaux dorés et ruban rose, bien lisible ; elle déborde la 1re colonne (la préparation doit recadrer sur la boîte visible). |

**Sorties** (non versionnées, `build/art/`) : sources ci-dessus, `J21_KIT_v1.png` (planche de contact à
l'échelle du jeu), plans `PLAN_*_v1.png`, `refus_serie23.log`. Versionnés : prompts, outils, et les
six références de `docs/design/reference/` (vues et plans : **à valider par Kevin**).

## Notes d'intégration (pour le plan, pas faites ici)

- Fuji : `build_character_frames.gd`, table `LOOKS` : `mr_fuji` ; marche = lignes de `PNJ_FUJI_NE`,
  animation `pray` = poses 1-2 (dos) de `PNJ_FUJI_PRIERE_NE` (2 images, boucle lente) ; poses 3-4
  (profil gauche, face) pour la scène où il se relève (§6.3) [D].
- Osselait : `pokemon/osselait` ≈ 56 px, `shadow.png`, comportement `static` dans la Maison des Pokémon.
- Dos : `assets/sprites/pokemon/battle_proto/dos_ia_143.png` ; `test_battle_art` exige déjà le dos de Ronflex.
- Notes : 4 sprites tirés au hasard par `FluteNotes`, 1,25 case ; halo : `SpiritLight`, mode additif.
- Aucune de ces entrées n'est ajoutée au manifeste tant que Kevin n'a pas validé `J21_KIT_v1.png`.
