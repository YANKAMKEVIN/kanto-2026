# J29 — porte de la Ligue Pokémon (hall du Plateau Indigo)

> **À valider par Kevin** (sur le téléphone). Rédigée et intégrée le 2026-10-23 sur `jalon-29`,
> à la suite de la QA A17 (`~/dev/qa-nuit2/j29/notes.md`, capture 56) : dans le hall
> (`indigo_plateau_lobby`), le warp `ToLeague` (12, 3) (« Ligue Pokémon — À venir », arrivée
> `league_door` (12, 4)) donnait sur le mur du fond nu de la coque du Centre, alors que l'hôte dit
> « Au-delà de cette porte… ».

## Numérotation

Pas de numéro de série : les numéros 25 (trois fiches sur d'autres branches), 27 et 28 sont pris,
26 n'apparaît nulle part mais n'est pas réservé explicitement. Cette fiche est rattachée au J29 :
fiche `j29-porte-ligue.md`, outil `tools/art/j29_porte_ligue.py`, prompts
`tools/art/prompts/j29/`. Aucun identifiant d'image ne porte de numéro.

## Outil

`tools/art/j29_porte_ligue.py` (reprend `ADN` et `LUMIERE_NE` de `serie06.py` et les fonctions de
`tools/art/preparer.py`) :

| Option | Rôle |
|---|---|
| `--prompts` | écrit `tools/art/prompts/j29/INT_PORTE_LIGUE_01_NE_r{1,2,3}.txt` |
| `--refs` | recadre le mur du fond de la coque (colonnes 9 à 14) → `REF_J29_MUR` (× 2) |
| `--commandes` | liste les appels `tools/art/generer.sh` et leurs images jointes |
| `--controle` | planche de contrôle : chaque essai posé sur la coque à l'échelle du jeu |
| `--integrer` | entrée du manifeste (`objets`), image et contact dans `assets/`, catalogue à jour |

**Essais** (règle des refus) : r1 avec l'extrait du mur et les ancres ; r2 avec les ancres du
dépôt (`int_porte_labo_01`, gabarit d'une porte posée dans un mur ; `int_centre_comptoir`, même
Centre) ; r3 sans image.

## INT_PORTE_LIGUE_01 → `int_porte_ligue_01`

- **Rôle** : porte de la Ligue, posée **dans le mur du fond** du hall au-dessus du warp (12, 3),
  à la place de la plante nord-est (déjà retirée du hall). Comme `int_porte_labo_01` (série 12,
  INT_MUSEE_PLANCHE : « porte posée dans le mur ») : **`traversable`**, sans emprise (les rangées
  du mur sont déjà bloquées par la pièce), `align` centre, calque des entités, sans ombre.
- **Intention** : la porte la plus solennelle du jeu, sobre et lisible : portail de pierre claire
  crème à linteau surbaissé fileté d'or, double porte fermée en bois carmin laqué à panneaux bordés
  d'or, deux poignées de laiton, écusson doré en blason à aile (ni cercle partagé, ni lettre).
  Valeurs de la coque du Centre (crème, bois brun, rouge vif) ; lumière neutre, aucun halo.
- **Format** : 1,6 case de large (axe `w`) ; préparée **154 × 169**. Entrée du manifeste :
  `{"id": "int_porte_ligue_01", "source": "INT_PORTE_LIGUE_01_NE_r3.png", "sortie": "assets/world/interiors/int_porte_ligue_01.png", "axe": "w", "cases": 1.6, "ombre": false, "contact": 0.2}`.
- **Pose** (`tools/build_painted_interiors.gd`, `_indigo_plateau_lobby`) :
  `[&"int_porte_ligue_01", Vector2i(12, 2), 2.3, "LeagueDoor"]` : pied au milieu de la case 12,
  à 2,3 cases (bas des lambris peints du mur du fond). La porte couvre le pilier de bois peint à
  droite de la fenêtre est ; elle effleure le cadre de la fenêtre sans la masquer.

## Essais, choix

Génération du 2026-10-23, trois appels en parallèle, **aucun refus ni limite d'usage**.

| Essai | Jointes | Résultat |
|---|---|---|
| r1 | `REF_J29_MUR` + ancres | portail massif presque carré, rouge vif ; à 1,6 case, vantaux plus bas que le héros (≈ 95 px contre 128) |
| r2 | ancres | même dessin, rouge plus sombre ; encore plus trapu (154 × 141) |
| **r3** | aucune | **retenu** : proportions de porte (154 × 169), vantaux à la hauteur du héros (≈ 127 px), carmin profond et or, écusson discret ; détourage propre |

Les trois sources sont en vraie transparence (RGBA, 1254²). Aucun texte, aucun emblème de balle.

**Sorties** (non versionnées) : sources `build/art/INT_PORTE_LIGUE_01_NE_r{1,2,3}.png`, extrait
`build/art/REF_J29_MUR.png`, planche `build/art/J29_PORTE_LIGUE_CONTROLE_v1.png`, capture Mac du
hall `build/cap/j29_hall_porte_ligue.png` (`tools/capture_interior.gd`, arrivée `league_door`,
tourné vers le haut). **Versionnées** : `assets/world/interiors/int_porte_ligue_01.png` et
`_contact.png` (avec leurs `.import`), `game/world/props/painted/int_porte_ligue_01.tscn`
(`build_painted_props.gd --nouveaux`), `game/world/maps/indigo_plateau_lobby.tscn`
(`build_painted_interiors.gd --rooms=indigo_plateau_lobby`).

## Lecture de la capture

La porte se lit comme une porte, centrée sur la colonne 12, entre la fenêtre est et le mur
latéral ; elle ne chevauche ni le marchand (13, 5) ni le héros. **Écart connu** : la coque peint le
bas du mur du fond vers 2,25 cases, alors que la pièce bloque trois rangées ; la case du warp
(12, 3) est donc à environ une case sous le seuil peint (même décalage que le comptoir et
l'infirmière). En montant de (12, 4) sur (12, 3), le héros déclenche le warp juste sous la porte.

## Tests

`tests/integration/test_j29_maps.gd` : `test_indigo_plateau_lobby_league_door_is_drawn_above_its_warp`
(nœud `LeagueDoor` = `int_porte_ligue_01`, sans emprise, centré sur la colonne 12, pied dans la
rangée 2, pas plus large que les colonnes 11 à 13 ; warp (12, 3) et arrivée (12, 4) atteints depuis
l'entrée, PNJ comptés comme obstacles ; aucun PNJ sur (12, 4)). `tests/unit/test_painted_props.gd` :
`int_porte_ligue_01` ajoutée aux objets traversables.
