# DAF.10b « Routes 13 à 21 » (2026-10-30, branche `claude/frosty-greider-c257d2`, depuis `main` @ `32f8a0f3`, `main` @ `d4836167` fusionné)

**À valider par Kevin (DA-6).** Lot du J33 (gel fonctionnel, art seul) ouvert par Kevin le 2026-10-30.
Ferme sur la branche RP-273 (sol des Routes 13, 14, 15, 17, 18), RP-274 (mer des Routes 19, 20, 21),
la part « postes des routes » de RP-272 (la part Parc Safari est passée par DAF.10a), RP-281 (fond de
la Route 22) et RP-282 (coins de forêt des Routes 4 et 24). Les Routes 12 sud et 16 ouest, du même
jalon et elles aussi en tuiles provisoires, sont repeintes avec elles.

**Sans Codex** (consigne de Kevin du 2026-10-30, via la coordination : « lance tout ce que tu peux
faire sans codex » ; Codex était à sa limite d'usage) : tout est fait avec le kit peint existant ou
dérivé de lui ; les éléments dérivés sont notés [D].

Gel du J33 respecté : **aucune collision, aucun déclencheur, aucune coordonnée ne bouge**.
`tools/dump_map_logic.gd` et `tools/dump_map_nodes.gd` identiques avant / après sur les 17 cartes
touchées (34 relevés : Routes 4, 12 sud, 13 à 22, 24, postes 15 (1F, 2F), 16, 18).

| Planche | Contenu |
|---|---|
| [synthese-telephone.jpg](synthese-telephone.jpg) | **à lire en premier, sur le téléphone** |
| [planche-1-routes.jpg](planche-1-routes.jpg) | Routes 12 sud à 18, vues d'ensemble avant / après |
| [planche-2-routes-joueur.jpg](planche-2-routes-joueur.jpg) | les mêmes à hauteur du joueur |
| [planche-3-mer.jpg](planche-3-mer.jpg) | Routes 19, 20, 21 (mer) |
| [planche-4-postes.jpg](planche-4-postes.jpg) | postes des Routes 15 (1F, 2F), 16, 18 |
| [planche-5-raccords.jpg](planche-5-raccords.jpg) | Route 4 et Route 24 (coins), Route 22 (fond) |
| [planche-6-images.jpg](planche-6-images.jpg) | images dérivées, à l'échelle du jeu × 0,5 |

## Ce qui est fait

- **Routes 12 sud, 13, 14, 15, 16 ouest, 17, 18** (`tools/build_daf10b_routes.gd`, kit côtier
  `coast_map_kit.gd` sur une copie traduite de la grille) : forêt serrée, herbe, chemins, hautes
  herbes peintes, mares et étang (mer de Bourg Palette, angles droits), rochers et paroi de la
  série 12, clôtures blanches à piquets (Route 13), barrières de bois de la Piste, bancs, ponton
  (planches du quai de la Route 12), maison du pêcheur, maison et poste de la Route 16 ouest
  (façade du poste de la Route 12), façade du **poste traversant** des Routes 15 et 18 [D].
- **Routes 19, 20, 21** : la mer de Bourg Palette de DAF.9 (même texture, même écume), rivage
  rocheux en modules, sable, rebords de la plage de la Route 19, roche et bouches des Îles Écume.
  Panneaux du J24 : image peinte (dessins provisoires retirés).
- **Postes** (`tools/build_daf10b_postes.gd`) : enveloppes [D] + meubles du kit (comptoir,
  bibliothèque, plantes, escaliers, banc), lumière `interior_warm`.
- **Raccords** (`tools/build_daf10b_raccords.gd`) : Routes 4 et 24, forêt plantée sur les cases de
  forêt qu'aucun arbre ne couvrait (sous-bois sombre visible en Surf ou sur l'écran large) ;
  Route 22, haut du fond peint fondu dans l'herbe (`top_fade` de `backdrop_fade.gdshader`, 0 par
  défaut : les autres usages ne changent pas).

## Images dérivées [D] (`tools/art/daf10b_derives.py`)

- `int_poste_traversant_coque` (12 × 10, postes 15 1F et 18), `int_poste_etage_coque` (12 × 10,
  poste 15 2F), `int_poste_16_coque` (14 × 10) : recomposées depuis les deux enveloppes validées
  des postes de la Route 12 (maison d'Argenta pour le mur du fond, le sol et le mur du bas ;
  ouverture du poste de la Forêt de Jade pour les passages nord du poste 16) ; passages latéraux
  du 1F = parquet prolongé et paillasson.
- `bldg_poste_traversant_01` (8 cases) : tiers ouest du poste est de Safrania, milieu du poste
  ouest répété, tiers est du poste ouest, agrandi × 1,4 ; ses passages latéraux tombent sur les
  portes (rangées 11 et 12), pied relevé de 0,8 case, la dernière rangée du bloc en forêt.

## À faire avec Codex (images vraiment neuves), si Kevin le souhaite

Prompts prêts (`tools/art/daf10b.py --prompts`, `tools/art/prompts/daf10b/`), non lancés :

1. ~~**Béton de la Piste Cyclable**~~ **fait le 2026-10-31** (image Codex, `ground_piste_01`, branché sur les Routes 16 ouest, 17, 18 ; relevés identiques ; `planche-codex-2026-10-31.jpg`) : la Piste (Routes 16 ouest, 17, 18) est en
   dalles du souterrain [D] ; la vue générale de la Route 17 montre du béton gris clair.
2. ~~**Jumelles**~~ **faites le 2026-10-31** (image Codex, `int_jumelles_01`, `build_daf10b_postes.gd`) : remplacées par deux petits meubles [D].
3. Enveloppes propres des postes (`INT_POSTE_*_COQUE`) et façade propre du poste traversant
   (`WORLD_BLDG_POSTE_TRAVERSANT_01`), d'après `reference/poste-15|16|18-v1.png`, si les
   recompositions [D] ne suffisent pas.

`daf10b.py --modules` les écrit dans `assets/` ; relancer ensuite `build_painted_props.gd -- --nouveaux`,
`--import`, puis les deux passes.

## Ordre des outils

`daf10b_derives.py`, `build_painted_props.gd -- --nouveaux`, `--import`, `build_daf10b_routes.gd`
(code 2 : masques écrits, importer puis relancer), `build_daf10b_postes.gd`,
`build_daf10b_raccords.gd`. Captures : `tools/capture_daf10b.sh` (avant / après),
`tools/capture_t2_audit.sh … "^route_(4|22|24)$"` ; planches : `tools/art/planches_daf10b.py`.

## Valeurs par défaut [D]

- Lumière `golden_hour` sur les routes du J22 et `interior_warm` sur leurs postes (aucune lumière
  avant ; ajoutées au plan `data/world/lighting.json`).
- Piste en dalles du souterrain ; jumelles en petits meubles (voir « À faire avec Codex »).
- `R` au contact de l'eau : rivage rocheux ; ailleurs : paroi (grands blocs) ou rochers.
- Poste de la Route 16 ouest : façade du poste de la Route 12 (nord-sud, comme lui) ; maison de la
  Route 16 ouest : `bldg_maison_lavanville_01`.
- Fin de clôture de 2 ou 3 cases : module long raccourci ; d'une case : poteau.
- Fondu du haut du fond de la Route 22 : 22 % de sa hauteur.
