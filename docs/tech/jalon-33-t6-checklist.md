# J33 T6 — ce que Kevin joue au doigt

> Passe humaine de T6 (`jalon-33.md` §2 T6) sur l'**A17** (S24 indisponible ; A17 partagé,
> à réserver auprès du coordinateur). Les parcours headless 01 à 09 jouent déjà les
> enchaînements ; ici : d'abord les tronçons **qu'aucun test ne joue**, puis ce qu'une machine
> ne voit pas (lisibilité, caméra, son, toucher).
>
> Lancer : `tools/deploy_s24.sh --debug-start <nom>` (APK debug, série de l'A17).
> Sans `--debug-start` : vraie partie.
> Anomalie → une ligne dans `docs/tech/registre-anomalies.md` (ID, P, build, étapes, état).

## 0. D'abord : jamais joués par une machine

| # | Tronçon | `--debug-start` | Regarder |
|---|---|---|---|
| 0.1 | Route 3, Mont Sélénite 1F à B2F, Route 4 | `route_3` | fossiles, Rockets, sortie vers la Route 4 |
| 0.2 | Route 5, souterrain, Route 6, passerelle du S.S. Anne | `route_5` | le Passe Bateau ouvre la passerelle |
| 0.3 | Routes 7 et 8, souterrain, Céladopole | `route_7` | postes, herbes, Dresseurs |
| 0.4 | Route 11, Cave Taupiqueur, Route 12 nord et son poste | partie réelle | Ronflex de la Route 12 réveillé avec la Flûte |
| 0.5 | Routes 13 à 15 jusqu'à Parmanie ; Parc Safari (Dent d'Or, CS03, CS04) | partie réelle | sortie du Safari à temps, gardien |
| 0.6 | Routes 19 et 20, Îles Écume 1F à B3F (rochers dans les trous, courants) | partie réelle | courants calmés après les deux rochers |
| 0.7 | Retour à pied du B4F ouest du repaire jusqu'à l'ascenseur | `rocket_hideout_key` | aucune dalle ne piège le retour |
| 0.8 | Sylphe 6F, 8F à 10F (portes à carte, téléporteurs) | `silph_1f` | aucun téléporteur sans issue |
| 0.9 | Route Victoire 2F et 3F (deux interrupteurs, rocher dans le trou du 3F) | `victory_road_2f` | rocher qui tombe au 2F, sortie est vers le Plateau |

## 1. Parcours 01 — Début (couvert : 01 et 07)

Nouvelle partie, sans `--debug-start`. Ouverture, chambre, Maman, maison du rival, scène de
Chen dans les herbes, starter (fiche, CHOISIR), rival, Route 1, arrivée à Jadielle (scène du
Rattata), colis, Pokédex, Route 2, Forêt de Jade, Argenta, Pierre.
**Regarder** : textes jamais coupés, caméra aux bords des cartes, toucher pendant les scènes.

## 2. Parcours 02 — Progression (couvert : 02 et 08)

| Tronçon | `--debug-start` | Regarder |
|---|---|---|
| Pont Pépite, recruteur (OUI/NON), Route 25, Léo | `nugget_bridge` | Pépite avant le combat ; machine de Léo |
| Poubelles de Carmin | `vermilion_gym_map` | « Mauvais interrupteur » : tout se referme |
| Route 9, Route 10, Grotte Sombre | `route_9` | voile lisible ; Marcel quitte le passage étroit |
| Casino, repaire B1F à B4F, Clé, ascenseur | `game_corner` | dalles du B3F lisibles ; panneau d'étages |
| Tour 3F à 5F, zone purifiée | `tower_scope` | soin de la zone ; Exorciste inévitable du 4F |
| Route 16 (Ronflex), Piste Cyclable, Route 17 | `snorlax_16_qa` | descente seule sur la pente |
| Boisson au garde, Sylphe 1F à 5F, Carte | `saffron_gate` | Q1 tranchée : chemin par le 9F gardé |

## 3. Parcours 03 — Donjons (couvert : 03 et 09)

| Tronçon | `--debug-start` | Regarder |
|---|---|---|
| Arène de Safrania (téléporteurs), Morgane | `saffron_gym` | on ne se perd pas ; fondus courts |
| Manoir 1F à B1F (statues, trou), Clé Secrète | `j25_manoir` | interrupteur remis sur ARRÊT en rentrant |
| Porte de l'Arène, six questions, Auguste | `j25_arene` | une mauvaise réponse fait combattre |
| Arène de Jadielle à pied (dalles) | `viridian_gym` | dalles tournantes lisibles |
| Route 23 (contrôles, Surf), Route Victoire 1F (Force) | `route_23_all` | rocher sur l'interrupteur, barrière |

## 4. Parcours 04 à 06 (couverts en entier)

- 04 Ligue `league_lorelei`, 05 post-game `cerulean_cave_locked`, Grotte Azurée
  `cerulean_cave_1f` (09) : au doigt, Panthéon et générique lisibles, Surf dans la grotte.
- 06 collection `evolution_qa` : écrans du Stockage et du Pokédex.

## 5. QA téléphone (`jalon-33.md` §5)

30 minutes d'affilée ; appli en arrière-plan pendant un combat ; fermeture forcée pendant une
sauvegarde ; FPS par zone (A17 : 50 à 54 i/s, son plafond).

## Questions pour Kevin

- **Q1 — Carte Magnétique (Sylphe 5F).** Les deux accès à pied du couloir sud, (8, 16) et le
  couloir est (28, 4), font une case de large et un Dresseur s'y tient (il ne s'écarte pas
  après sa défaite). Le seul chemin est : ascenseur → 9F → téléporteur (17, 15) → 5F (9, 15).
  Le parcours 08 le joue et il marche. Est-ce voulu (fidèle à RB) ou faut-il qu'un des deux
  s'écarte comme Marcel dans la Grotte Sombre ? **Décision de Kevin (2026-11-01) : « garde »** : tel quel, aucun Dresseur ne s'écarte.
