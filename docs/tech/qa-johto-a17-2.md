# QA de Johto sur l'A17, deuxième passe — 2026-11-06

Téléphone : Galaxy A17 (`R5GYB2R7W2Y`), Ne pas déranger actif. Deux séances, avec des départs de débogage :
- 14 h 09 à 15 h 10, APK de `main` `137a2c5b` ;
- 16 h 57 à 18 h 20, APK de cette branche, avec les correctifs ci-dessous.

## Résultat

**Un vrai blocage trouvé et corrigé : le joueur ne pouvait pas quitter la chambre du Centre d'Oliville** (B1 ci-dessous).
Aucun plantage, aucune perte de sauvegarde. Les onze jonctions ont été passées sur téléphone, mais par morceaux :
chaque jonction part d'un départ de débogage, personne n'a enchaîné Johto d'un bout à l'autre.

| Priorité | Point | Résultat | Constat |
|---|---|---|---|
| 1 | Tour Radio vers arc des Pierres | OK | Bureau, Multi Exp, ascenseur, hall, scène de sortie, `johto_stones_quest` posé, ordre de mission et carte radio retirés, sortie à Doublonville |
| 1 | Retour à Rosalia et acte 2 | OK | Autel, écran des 6, `johto_team_returned`, `johto_act1` et `storage_offline` levés, sortie de l'Antre à pied, Corentin, vol, `johto_act2` |
| 1 | Reprise à Rosalia | OK | Appli tuée après le vol, « Continuer » : même case, drapeaux gardés |
| 1 | Acte 2 vers Tour Cendrée | OK | Doyen, `johto_burned_tower_open`, entrée de la tour |
| 1 | Retour à Kanto par la Route 28 | OK | 1F (2 rochers de Force, Surf), Route 28, poste, `johto_route28_open`, Route 22 ouest puis Route 22 |
| 1 | Kanto libre après le chapitre | OK | Vol de Bourg Palette à Jadielle, puis de Jadielle à Rosalia |
| 1 | JOH1 vers JOH2 | **Bloquant, corrigé** | B1 ; puis réveil, Germignon, départ d'Orme, Oliville, Route 39 |
| 1 | JOH2 vers JOH3 | OK | Scène des Sbires à Rosalia, sortie vers la Route 37 |
| 1 | JOH3 vers JOH4 | OK | Garde sud de Doublonville : refuse sans `johto_azalea_clue`, laisse passer avec, Route 34 |
| 1 | JOH4 vers JOH5 | OK | Brace, papiers, `johto_radio_pass`, Fargas, `johto_slowpoke_well_cleared`, faux employé |
| 1 | Arc des Pierres | OK | Route 36, Alpha, Goulven, Goéland, Irisia, Corentin, vol vers Ébènelle, Aïeule, Antre, Ysolde. Non joué : voir « Non testé » |
| 1 | JOH6 vers JOH7 | OK depuis Q2 | Brace, générateur, Raikou, déserteur, `johto_whirl_clue` ; mer fermée puis ouverte, Route 40 |
| 1 | JOH7 vers JOH8 | OK | Orme, `johto_bell_tower_clue`, Vol, Doyen, garde refuse puis laisse passer, Bois de la Tour |
| 1 | JOH8 vers JOH9 | OK | Doyen, `johto_act3` ; Lac Colère refuse sans le drapeau, Sentier Argenté avec |
| 2 | Capture de Raikou | OK | Master Ball ; sprite disparu ; `johto_raikou_caught` et `johto_raikou_return_done` |
| 2 | Hurlement retenu | OK | 1 Hurlement sur 18 tours de Raikou ; cohérent avec 1 sur 16, échantillon petit |
| 2 | Retour après Hurlement ou fuite | OK | Raikou reste après Hurlement, Entei et Ho-Oh restent après une fuite ; on les réaffronte |
| 2 | Retour d'Entei et de Ho-Oh | OK | Capture à la Master Ball, sprite disparu, drapeaux posés |
| 2 | Fuite au repaire d'Acajou | OK | Raikou disparaît, `johto_raikou_done` et `johto_raikou_fled` posés : même état que son retour joué après le chapitre. Hurlement n'y est pas sorti : il suit le même chemin dans le code |
| 2 | Capture aux Hyper Balls | Non abouti | 18 lancers sur Raikou à pleine vie, sans capture, puis Master Ball |
| 3 | Rival du sommet | OK | Contrôle rendu, Hyper Potion par le Sac (40 à 223 PV, sauvegardée), parler, EN AVANT, combat lancé. Combat non joué jusqu'au bout (fait en première passe) |
| 3 | Défaite contre Dante | OK | Centre du Mont Argenté, équipe soignée, `johto_summit_reached` |
| 3 | A-25 | OK | « Encore toi. » puis « Ici, on ne redescend qu'une fois. » au retour au sommet |
| 4 | Musiques au journal | OK | Tableau plus bas ; aucune erreur de fichier |
| 5 | Cage brûlée, Entei, Ho-Oh | OK | Dante battu, cage disparue, Entei puis Ho-Oh, drapeaux posés. Équipe relevée au niv. 95 |
| 5 | Défaite contre Dante à la Tour | OK | Vue en plus : Centre de Rosalia, `johto_dante_lost_1` |
| 5 | Entrée de l'Antre | OK | Traversée dans le sens de la sortie, vers Ébènelle |
| 5 | Lanternes d'Ébènelle | Vu | Présentes sur la place de jour, de nuit non vues |
| 5 | Tapis du clan | Vu | Maison de l'Aïeule, aucune gêne de déplacement |
| 6 | Remontée à pied depuis le Centre | OK | Centre, Sentier, extérieur, 1F (Surf, 2 rochers), 2F, 3F, sommet, équipe niv. 95 |
| 6 | Descente du sommet | OK | 3F, 2F, 1F, puis Route 28 et Route 22 (première séance) |

## Anomalies

**B1, bloquant, corrigé : impossible de quitter la chambre du Centre d'Oliville.** L'escalier arrivait en (13, 7) dans
le Centre. Cette case a des murs à gauche, à droite et en bas, et le pas vers le haut déclenche l'escalier : le joueur
remontait sans fin. Personne n'avait vu le cas, les départs de JOH2 commençant dehors.
- Correctif : arrivée sur le palier (13, 6), `game/world/maps/olivine_center.tscn` et `tools/build_painted_interiors.gd`.
- Nouveau test `tests/integration/test_spawn_pockets.gd` : sur toutes les cartes, aucune arrivée n'ouvre sur une poche.
  Ce cas était le seul.

**M3, mineur, corrigé : libellé de la carte.** Le bloc affiche maintenant « Exploration de Johto » sur l'onglet Johto.

**M4, mineur, corrigé : objectifs de JOH9.** Deux objectifs ajoutés, textes [D] à relire par Kevin : « atteindre le
sommet du Mont Argenté. », vu dans le menu, et « rentrer à Bourg Palette, par la Route 28. ».

**M5, mineur, corrigé : pièges des départs de débogage.** 88 départs de Johto reçoivent `rival_route22_final_won`.
Nouveau départ `johto_radio_tower_exit`, joué. Le README signale `johto_blackthorn` et décrit le bureau actuel.

**M6, mineur, non corrigé : pas d'objectif pendant JOH7.** Entre le déserteur et Orme, aucun objectif ne s'affiche
(lu dans `objectives.json`). Le déserteur annonce les Îles Tourbillon dans son dialogue.

**Q2, ordre JOH6 puis JOH7 : décidé et corrigé.** L'accès à la mer dépendait de `johto_act2` seul. Décision de Kevin
du 2026-11-06 : JOH6 d'abord. La barrière `olivine_south_sea_block`, seul accès à la Route 40, s'efface maintenant
avec `johto_whirl_clue`, posé par le déserteur d'Acajou. Le marin garde son texte. Vu sur téléphone dans les deux sens.

Hors périmètre, pour mémoire : le combat au sommet utilise le décor `route_3_roche` (`data/battle/decors.json:841`).

## Lecture statique

Lecture des 120 départs `johto_*` et de leurs 135 drapeaux : chacun a un endroit qui le pose dans le jeu, hors
`tools/` et `tests/`. Aucune condition Johto ne lit un drapeau jamais posé, aucun raccord ne mène à une carte absente.
Ce contrôle n'a pas vu B1 : il suit les drapeaux, pas la marche.

Objets clés et CS : `team_confiscation.gd` laisse les objets clés et toutes les CS au Sac pendant l'acte 1. Risque
restant, non vérifié : au choix des 6, aucun membre compatible Surf ou Force.

## Musiques (journal `[audio] musique`)

Contrôle sur Mac : 32 pistes dans `tracks.json`, 32 fichiers `.ogg`, aucun manquant ; seul `johto_ending` ne boucle pas.

| Lieu ou combat | Piste lancée |
|---|---|
| Doublonville, Rosalia | `johto_goldenrod_city`, `johto_ecruteak_city` |
| Ébènelle, Mont Argenté | `johto_ice_path` |
| Antre et Sanctuaire | `johto_dragons_den` |
| Tour Radio, Tour Cendrée, Tour Carillon | `johto_radio_tower`, `johto_burned_tower`, `johto_bell_tower` |
| Route 28, Surf, Centres | `johto_route_26`, `johto_surf`, `johto_pokemon_center` |
| Sauvage, Dresseur | `johto_battle_wild`, `johto_battle_trainer` |
| Raikou, Entei | `johto_battle_suicune` |
| Ho-Oh | `johto_battle_ho_oh` |
| Dante à la Tour, Dante au sommet | `johto_battle_rocket`, `johto_battle_gym_leader` |
| Rival final | `johto_battle_champion` |
| Route 22, Jadielle (Kanto) | `road_to_cerulean`, `pewter_city` : conformes à `music_zones.json` |

Reprise de la piste de carte après un combat : vue à chaque combat (« reprise »).
**Boucles :** le journal n'écrit rien au retour de boucle. `johto_ice_path` (83 s) a tourné plus de deux fois sans
erreur, c'est tout ce que ce contrôle établit. Les autres pistes n'ont pas tourné assez longtemps. Non vus : thème du
rival (`johto_rival`), Lugia, Route 29, Écorcia, Oliville, Irisia, Acajou, générique.

## Méthode

- Départs utilisés : `johto_radio_tower_office`, `johto_route_28`, `johto_bell_tower_roof_autosave`.
- Départs locaux, non versés au dépôt :
  - `johto_celebi` déplacé à la Tour Cendrée puis sur le toit de la Tour Carillon, avec 99 Hyper Balls et 2 Master Ball ;
  - `johto_den_return`, `johto_mt_silver_rival` et `johto_route_28` avec `autosave` ;
  - sommet avec équipe faible (niv. 20), pour perdre ;
  - toit de la Tour Carillon au niv. 95, après une défaite au niv. 62 à 66 ;
  - fin de chapitre à Bourg Palette, avec villes découvertes.
- Drapeaux relus dans `save.json`, les scènes de jonction étant enchaînées dans une même partie.
- Combats joués par une boucle naïve sur `adb` : **ce n'est pas une mesure de difficulté**.
- Séance 2 : équipes relevées au niv. 70 ou 95 pour les combats lourds, sinon la boucle perdait (Brace au repaire,
  Dante à la Tour).
- Filtre `SCRIPT ERROR`, `FATAL`, `ERROR` lu en fin de la plupart des séquences, rien trouvé. **Pas lu** pour Raikou
  et Entei, Antre, défaite contre Dante au sommet, et plusieurs séquences de la séance 2, le journal étant vidé à
  chaque départ. Aucun arrêt de l'appli n'a été vu.

## Incident de séance

À 13 h 58, l'APK a été installé alors que quelqu'un tenait l'A17 : des touches étaient visibles à 13 h 47 et 13 h 51,
et il n'y avait aucune réservation. À 13 h 59, le journal et `getevent` ont montré des gestes sur l'écran réel. Le test
a été arrêté, puis repris à 14 h 09 avec l'accord de Kevin. Le premier combat d'Entei et le début de celui de Raikou
sont écartés de ce rapport. La partie écrasée (« Uk », 50 s de jeu) a été remise à la fin.

## Non testé

- Une partie complète : chaque jonction part d'un départ, avec drapeaux et équipe préparés.
- Routes 38, 35, 34, Bois aux Chênes, Puits B1F, Tour Radio 2F à 4F, Route 42, Acajou, Route 43, Îles Tourbillon,
  Tour Carillon 1F et 2F : pas traversés dans cette QA.
- Énigmes d'Alpha, Grotte des Marées et socle, combats des Gardiens.
- Hurlement au repaire d'Acajou, en jeu.
- Capture d'un légendaire aux Balls ordinaires jusqu'au bout.
- Rival final jusqu'au bout sur ces APK (joué sur l'APK de `1c4a6f70`, avant les musiques).
- Lanternes d'Ébènelle de nuit.

## À faire par Kevin

- **Écouter** : toutes les pistes, surtout les jointures de boucle ; les replis (Ice Path à Ébènelle et au Mont Argenté,
  Route 26 à la Route 28) ; le thème du rival aux trois arrivées du Mont Argenté.
- **Jouer** : une vraie partie de Johto d'un bout à l'autre, seule façon de valider l'enchaînement complet et la
  difficulté.
- **Relire** : les deux objectifs ajoutés (M4).
