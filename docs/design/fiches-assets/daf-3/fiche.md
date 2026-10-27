# DAF.3 « Safrania et Sylphe » et DAF.4 « Fin du jeu » (part déjà dans `main`)

> Lot de la phase DA (`docs/design/phase-da-cadrage.md` §3, DA-1 à DA-9), fait le 2026-10-27 sur la
> branche `claude/daf-3-4-9713b9` (depuis `main` @ `fa64b302`). **Non fusionné : planches à valider
> par Kevin.** Outils : `tools/art/daf3.py` (prompts, génération Codex, préparation),
> `tools/capture_daf3.sh` (captures 2340 × 1080), `tools/art/planches_daf3.py` (planches).
> Prompts versionnés : `tools/art/prompts/daf3/`.

## Planches à relire

| Planche | Contenu |
|---|---|
| [synthese-telephone.jpg](synthese-telephone.jpg) | **à lire en premier, sur le téléphone** : six lieux, avant / après |
| [planche-1-safrania.jpg](planche-1-safrania.jpg) | Safrania en jeu, six vues avant / après |
| [planche-2-facades.jpg](planche-2-facades.jpg) | les 15 façades côte à côte (1/2 échelle) |
| [planche-3-sylphe.jpg](planche-3-sylphe.jpg) | Sylphe 1F, 3F, 7F, 11F et cabine, avant / après |
| [planche-4-kit-sylphe.jpg](planche-4-kit-sylphe.jpg) | le kit de la Sylphe à l'échelle du jeu |
| [planche-5-arene-dojo.jpg](planche-5-arene-dojo.jpg) | Arène de Morgane et Dojo, avant / après |
| [planche-6-fonds-combat.jpg](planche-6-fonds-combat.jpg) | les quatre fonds de combat dédiés |
| [../daf-4/planche-1-arene-jadielle.jpg](../daf-4/planche-1-arene-jadielle.jpg) | Arène de Jadielle, avant / après (DAF.4) |

## Ce qui est fait

1. **15 façades de Safrania** (Codex, une génération chacune, aucun refus) : remplacement **à
   l'identique** des provisoires de `placeholders_safrania.py` (mêmes identifiants, dimensions,
   emprises ; cartes et collisions inchangées). Aucune vue générale peinte de Safrania n'existe (T5 du
   J26 non fait) : la cible est le poste peint du J20 (`bldg_poste_safrania_01`, même ville), les
   façades de Céladopole et « centre économique et technologique » (`vision.md`). Le **poste est est
   le miroir du poste ouest** [D] (même bâtiment, porte de l'autre côté).
2. **Sylphe SARL en modules** (et non 14 images) : méthode du repaire Rocket (série 22 bis, Q-2) sur
   `tools/cave_map_kit.gd` et `tools/module_walls.gd` : moquette et masse peintes, cloisons
   `relief_mur_sylphe_01` à `_05`, mobilier `M` d'une case selon sa tache (plante seule, armoires de
   serveurs en colonne, bureaux en blocs), escaliers, porte d'ascenseur, tapis de téléporteur et
   seuils de porte électronique au sol, battants des portes électroniques peints, cabine en coque
   peinte (384 × 384). La grille fait foi : la collision reste `blocked_cells`.
   **Mémoire (RP-143)** : textures de la Sylphe entière (11 étages + cabine, comptées une fois)
   **4,6 Mo** ; 7F seul 3,8 Mo (mesure `tools/measure_daf3_textures.gd`, RVBA sans mipmaps) ; au Mac, le
   compteur du moteur passe de 41,8 Mo à 7,1 Mo sur le 7F seul. Avant : une enveloppe de
   ≈ 17 Mo par étage, 161 Mo mesurés au 7F avec ses voisines. Budget de 64 Mo tenu. Autres mesures : Arène de Morgane 3,5 Mo, Dojo 3,5 Mo, Arène de Jadielle 3,6 Mo,
   Safrania 41,1 Mo (inchangé : les façades gardent la taille des provisoires).
3. **Arène de Morgane et Dojo** en modules (même kit) : dalles lavande et murs à médaillon pour
   l'Arène, parquet blond et murs à colombages pour le Dojo ; les tapis de téléporteur de la Sylphe
   resservent dans l'Arène.
4. **Arène de Jadielle** (DAF.4) en modules : dalles de grès ocre, murs de pierre brun-gris ; les
   flèches et disques d'arrêt du repaire au sol (même moteur de dalles, plus lisibles qu'avant).
5. **Fonds de combat dédiés** (recette CB.3, composition puis deux tuiles agrandies) :
   `silph_co_bureaux` (étages 2F à 11F), `saffron_gym_psy`, `fighting_dojo_salle`,
   `viridian_gym_sol` ; ils remplacent les décors [D] du registre (repaire, Arène de Carmin, Arène
   d'Argenta).

Enveloppes provisoires retirées (`ph_silph_co_*`, `ph_silph_door_*`, `ph_saffron_gym`,
`ph_fighting_dojo`, `ph_viridian_gym`) ; les trois scripts de provisoires sont marqués obsolètes.

## Valeurs par défaut [D] (règle 4)

- Poste est = miroir du poste ouest.
- Frontière du sol peint au pied des murs : le sol un peu assombri (au lieu de l'ardoise des grottes).
- Mobilier de la Sylphe choisi par la forme de la tache `M` (1 case = plante, colonne = serveurs,
  le reste = bureaux) ; les grilles RB ne disent pas quel meuble est où.
- Paillasson de la Sylphe réutilisé aux sorties de l'Arène de Morgane, du Dojo et de l'Arène de
  Jadielle.
- Lignes d'horizon des quatre fonds (`data/battle/decors.json`, « pour mémoire ») estimées à l'œil.

## Points à regarder (pour Kevin)

- **Taches sombres au pied de certains murs** (Arène de Morgane surtout) : c'est la transition
  « bruitée » du sol peint des grottes (shader commun `ground_blend`), la même que dans le repaire.
  La rendre nette toucherait toutes les grottes : laissée telle quelle, à arbitrer (P3).
- **Bureaux de la Sylphe** à l'échelle réelle (1 case = un poste de travail avec son fauteuil) : la
  moquette se voit entre deux bureaux ; ils restent bien lisibles comme obstacles.
- **Murs minces verticaux** (couloirs de l'Arène de Morgane, labyrinthe de l'Arène de Jadielle) :
  rendus comme à la Tour et au repaire (bords latéraux et masse sombre au milieu).
- **Porte de l'Arène de Morgane** : peinte une demi-case trop à droite par Codex ; recalée à la
  préparation (`RECALAGES` de `daf3.py` : 2 × 24 px de mur retirés à gauche, 2 × 24 px ajoutés entre
  les fenêtres de droite, d'où une travée de droite un peu plus large). Les autres portes tombent sur
  leur case (contrôle tracé sur les images).

## Hors de ce lot

- **J29 (Route Victoire, Route 23) et J31 (Grotte Azurée)** : pas encore dans `origin/main` au
  2026-10-27 ; leur kit se fera à leur arrivée. **J30** (salles de la Ligue) : hors périmètre.
- Sprites des Karatékas du Dojo et du Médium Nestor (RP-147), dos provisoires : lots DAF.1 et DAF.5.
- Vue générale peinte de Safrania (T5 du J26) : jamais exigée par le code, toujours absente.
