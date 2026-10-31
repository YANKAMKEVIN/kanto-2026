# DAF.10a « Parmanie et Parc Safari » (2026-10-30, branche `claude/daf-10a-parmanie-0288a2`, depuis `claude/angry-curran-af1d7f`)

**Validé par Kevin le 2026-10-30 (« Oui je valide », planches 1 à 6), fusionné dans `main`.** Ferme RP-269 (P1, Parmanie), RP-270 (P1, Parc Safari) et
RP-271 (P1, Arène de Parmanie) ; traite la part « Parc Safari » de RP-272 (pavillon d'accueil, Porte, maisons de
repos, Maison Secrète) ; RP-157 et RP-279 (fonds de combat) **non traités** (voir « Reste »).

Gel fonctionnel du J33 respecté : **aucune collision, aucun déclencheur, aucune coordonnée ne bouge**.
`tools/dump_map_logic.gd` (grille) et `tools/dump_map_nodes.gd` donnent des sorties **identiques** avant / après sur les
**17 cartes** touchées (`tools/dump_daf10a.sh avant|apres`, liste dans `tools/daf10a_maps.txt` ; seul changement de
l'outil : `ForestFloor` ajouté aux racines graphiques ignorées).

| Planche | Contenu |
|---|---|
| [planche-1-parmanie.jpg](planche-1-parmanie.jpg) | Parmanie avant / après (vue d'ensemble) |
| [planche-2-arene.jpg](planche-2-arene.jpg) | Arène de Parmanie avant / après |
| [planche-3-parc.jpg](planche-3-parc.jpg) | Parc Safari, zones Centre et Nord |
| [planche-4-parc-est-ouest.jpg](planche-4-parc-est-ouest.jpg) | Parc Safari, zones Est et Ouest |
| [planche-5-interieurs.jpg](planche-5-interieurs.jpg) | Porte du Parc, maison de repos, Maison Secrète |
| [planche-6-facades.jpg](planche-6-facades.jpg) | les trois façades neuves à l'échelle |

## Sources de l'image

- **Neuf** (Codex CLI, sans dépense d'API ; prompts `tools/art/prompts/daf10a/`, retenus r1, aucun refus) : façade de
  l'**Arène de Parmanie** (12 × 7, toit violet, jardins zen de part et d'autre de la porte, porte recalée sur les
  cases 7 et 8) et **pavillon d'accueil du Parc Safari** (10 × 6, toit vert olive, charpente de bois).
- **Cabane de repos : image Codex le 2026-10-31** (`WORLD_BLDG_CABANE_SAFARI_01`, toit de chaume, rondins, porte en 2e colonne sans recalage, 384 × 312 ; relevés identiques sur les 4 cartes du Parc ; `../daf-10d/planche-codex-2026-10-31.jpg`). Avant : **dérivé d'un existant** [D] : **cabane de repos** du Parc (`bldg_cabane_safari_01`, 4 × 3, porte à la 2e colonne) =
  `bldg_maison_toit_01` réduite ×0,8 et recalée sur la porte. Codex a atteint sa limite d'usage (retour à 13 h 18) :
  une image dédiée reste possible, à l'identique (`tools/art/daf10a.py WORLD_BLDG_CABANE_SAFARI_01`, texte à rétablir
  dans `FACADES`).
- **Réutilisé** : Centre, Boutique, Salle de réunion (`bldg_fan_club_01`, 8 × 6), maisons (`bldg_maison_pecheur_01`),
  sol (herbe, chemin, sable, eau, hautes herbes jaunes), forêt serrée, clôtures, buissons taillés, nénuphars, roseaux,
  parquet et cloisons shoji du Dojo de Safrania, statue d'Arène, coque des maisons d'Argenta.
- **Dérivés** (`daf10a.py`) : `ground_parquet_dojo_indice_01` (parquet du Dojo assombri de 10 %, lames d'indice) et
  `int_safari_12x10_coque` (coque d'Argenta recoupée à 12 cases pour la Porte et la Maison Secrète).

## Outils

- `tools/art/daf10a.py` : prompts, génération, `--modules` (façades), `--cabane`, `--arene`, `--coque`.
- `tools/build_daf10a_parmanie.gd` : seconde passe de `fuchsia_city` (sol peint au masque : sable sur `y`, terre sur `=`
  et sur le sol d'enclos `g`, eau à rivage naturel sur `w f ~` ; façades en `WorldProp` à l'emprise déjà solide, portes
  libres ; clôtures découpées à la longueur de la rangée ; buissons taillés sur `x` ; décor d'enclos sans emprise ;
  forêt, décalcomanies, prairie du kit).
- `tools/build_daf10a_safari.gd` : quatre zones (herbes hautes peintes sur `h`, eau et îlot, forêt sur `T` et sur les
  bords `n`, cabanes de repos en `WorldProp`) ; `Daf10aGroundDecals` (nœud d'art, les zones n'ont pas de
  `GroundDecals`).
- `tools/build_daf10a_arene.gd` : Arène (parquet clair, murs en parquet sombre à bords droits, cloisons shoji,
  statues sur les cases `S`, lames d'indice sur les 36 `i`).
- `tools/build_daf10a_interieurs.gd` : six intérieurs du Parc (coque peinte + mobilier sans emprise).
- `tools/dump_daf10a.sh`, `tools/capture_daf10a.sh`, `tools/measure_daf10a_textures.gd`, `tools/art/planches_daf10a.py`.

Ordre : `daf10a.py --modules --cabane --arene --coque`, `--import`, `build_painted_props.gd -- --nouveaux`, `--import`, les
quatre `build_daf10a_*.gd` (code 2 : importer puis relancer).

## Valeurs par défaut [D]

- Lumière des cartes inchangée (profils existants).
- Parmanie : Salle de réunion = façade du Fan-club de Carmin (8 × 6, toit vert) ; trois maisons identiques
  (`bldg_maison_pecheur_01`, toit d'ardoise) au lieu des toits terre cuite de la vue générale.
- Enclos : sol de chemin (terre), clôtures de bois, une mangeoire, un tronc, une souche ou un buisson par enclos
  (placements fixes) ; Pokémon peints inchangés.
- Parc : sol d'herbe commun ; îlot du Centre en herbe avec trois buissons ; bords `n` en forêt.
- Arène : lames d'indice discrètes (parquet 10 % plus sombre, bords droits) ; bandes de mur sans couronnement ;
  pas de paillasson à la sortie (l'indice de sortie reste la brèche dans le mur).
- Porte du Parc : comptoirs = trois comptoirs de pension réduits ×0,67 empilés par côté.

## Reste (non traité)

- **RP-157 / RP-279 : fonds de combat** de l'Arène de Parmanie et du Parc Safari : non produits (limite d'usage de
  Codex) ; à reprendre dans DAF.2 bis (même méthode que DAF.2).
- Intérieurs de Parmanie (Centre, Boutique, Salle de réunion, maisons) : déjà peints à l'audit, inchangés.
- RP-272 pour les Routes 13 à 18 : DAF.10b.

## Budget de textures (RP-091, repère 64 Mo par carte)

Mesure du 2026-10-30 (`tools/measure_daf10a_textures.gd`, RVBA 8 bits, objets peints compris, personnages exclus) :
Parmanie 20,2 Mo ; Parmanie + Centre + Boutique + Salle + 3 maisons + Arène 42,7 Mo ; Arène 2,9 Mo ; zones du Parc
8,1 à 8,2 Mo ; Porte 5,3 Mo ; maison de repos 6,7 Mo ; Maison Secrète 5,2 Mo. Tout sous le repère de 64 Mo.
