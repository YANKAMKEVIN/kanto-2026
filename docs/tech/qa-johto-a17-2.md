# QA de Johto sur l'A17, deuxième passe — 2026-11-06

Téléphone : Galaxy A17 (`R5GYB2R7W2Y`), Ne pas déranger actif. APK debug construit depuis `main` `137a2c5b`
(version 0.34.1). Séance de 14 h 09 à 15 h 10, soit environ 60 min, avec des départs de débogage.

## Résultat

**Aucun blocage, aucun plantage, aucune perte de sauvegarde** sur ce qui a été joué.
Trois jonctions ont été jouées sur onze. Les huit autres sont seulement relues dans les données.

| Priorité | Point | Résultat | Constat |
|---|---|---|---|
| 1 | Tour Radio vers arc des Pierres | OK | Bureau, Multi Exp, ascenseur, hall, scène de sortie, `johto_stones_quest` posé, ordre de mission et carte radio retirés, sortie à Doublonville |
| 1 | Retour à Rosalia et acte 2 | OK | Autel, écran des 6, `johto_team_returned`, `johto_act1` et `storage_offline` levés, sortie de l'Antre à pied, Corentin, vol, `johto_act2` |
| 1 | Reprise à Rosalia | OK | Appli tuée après le vol, « Continuer » : même case, drapeaux gardés |
| 1 | Acte 2 vers Tour Cendrée | OK | Doyen, `johto_burned_tower_open`, entrée de la tour |
| 1 | Retour à Kanto par la Route 28 | OK | 1F (2 rochers de Force, Surf), Route 28, poste, `johto_route28_open`, Route 22 ouest puis Route 22 |
| 1 | Kanto libre après le chapitre | OK | Vol de Bourg Palette à Jadielle, puis de Jadielle à Rosalia |
| 1 | JOH1 à JOH5, JOH6 à JOH9 | Non testé | Lecture statique seulement, voir plus bas |
| 2 | Capture de Raikou | OK | Master Ball ; sprite disparu ; `johto_raikou_caught` et `johto_raikou_return_done` |
| 2 | Hurlement retenu | OK | 1 Hurlement sur 18 tours de Raikou ; cohérent avec 1 sur 16, échantillon petit |
| 2 | Retour après Hurlement ou fuite | OK | Raikou reste après Hurlement, Entei et Ho-Oh restent après une fuite ; on les réaffronte |
| 2 | Retour d'Entei et de Ho-Oh | OK | Capture à la Master Ball, sprite disparu, drapeaux posés |
| 2 | Fuite au repaire d'Acajou | Non joué | État équivalent joué : `johto_raikou_done` sans capture, Raikou présent à la Tour Cendrée après le chapitre |
| 2 | Capture aux Hyper Balls | Non abouti | 18 lancers sur Raikou à pleine vie, sans capture, puis Master Ball |
| 3 | Rival du sommet | OK | Contrôle rendu, Hyper Potion par le Sac (40 à 223 PV, sauvegardée), parler, EN AVANT, combat lancé. Combat non joué jusqu'au bout (fait en première passe) |
| 3 | Défaite contre Dante | OK | Centre du Mont Argenté, équipe soignée, `johto_summit_reached` |
| 3 | A-25 | OK | « Encore toi. » puis « Ici, on ne redescend qu'une fois. » au retour au sommet |
| 4 | Musiques au journal | OK | Tableau plus bas ; aucune erreur de fichier |
| 5 | Cage brûlée, Entei, Ho-Oh | OK | Dante battu, cage disparue, Entei puis Ho-Oh, drapeaux posés. Équipe relevée au niv. 95 |
| 5 | Défaite contre Dante à la Tour | OK | Vue en plus : Centre de Rosalia, `johto_dante_lost_1` |
| 5 | Entrée de l'Antre | OK | Traversée dans le sens de la sortie, vers Ébènelle |
| 5 | Lanternes d'Ébènelle | Vu | Présentes sur la place de jour, de nuit non vues |
| 5 | Tapis du clan | Non testé | |
| 6 | Remontée à pied depuis le Centre | Non testé | A-25 vu en repartant du sommet, pas en marchant |
| 6 | Descente du sommet | Partiel | Jouée du 1F à la Route 22 ; 3F et 2F non joués |

## Anomalies

Aucun bloquant.

**M3, mineur : libellé « Exploration de Kanto » sur l'onglet Johto.** Sur la carte, onglet Johto, le bloc en bas à
gauche garde ce titre et le décompte de Kanto. Cause probable : le bloc n'est pas relié à la région affichée. Capture :
[`carte-johto-libelle-kanto.jpg`](qa-johto-a17-2/carte-johto-libelle-kanto.jpg).

**M4, mineur (lu, pas joué) : aucun objectif après le Doyen de fin de JOH8.** `data/story/objectives.json` s'arrête à
l'entrée `unless johto_act3`. Rien n'indique ensuite le Mont Argenté ni l'épilogue. Guidage seulement : le passage du
Lac Colère s'ouvre bien.

**M5, mineur : pièges dans les départs de débogage, pas dans le jeu.**
- Les départs de fin de Johto n'ont pas `rival_route22_final_won` : le rival de Kanto apparaît devant le poste de la
  Route 22 ouest. Dans une vraie partie il est déjà battu, puisque la Ligue est finie.
- `johto_blackthorn.json` n'a pas `johto_team_returned` : Corentin n'y pose pas `johto_act2`. Partir de
  `johto_den_return.json`.
- Aucun départ n'a `johto_radio_office_done` sans `johto_stones_quest` : la sortie de la Tour Radio ne se rejoue que
  depuis `johto_radio_tower_office.json`, en repassant par le bureau.

**Q2, question de game design (lu, pas joué) : l'ordre JOH6 puis JOH7 n'est pas imposé.** L'accès à la mer dépend de
`johto_act2` seul, et `johto_whirl_clue`, posé par le déserteur d'Acajou, n'est lu par rien dans JOH7. Le joueur peut
donc aller aux Îles Tourbillon et à la Tour Carillon avant le repaire d'Acajou. Rien ne bloque d'après la lecture, mais
les dossiers présentent les deux dans cet ordre. Reste à décider si c'est voulu.

Hors périmètre, pour mémoire : le combat au sommet utilise le décor `route_3_roche` (`data/battle/decors.json:841`).

## Jonctions relues dans les données

Lecture des 120 départs `johto_*` et de leurs 135 drapeaux : chacun a un endroit qui le pose dans le jeu, hors
`tools/` et `tests/`. Aucune condition Johto ne lit un drapeau jamais posé, aucun raccord ne mène à une carte absente.
Ce contrôle a été fait par un sous-agent, en lecture seule, et rien de cela n'a été joué.

| Jonction | Lecture | Condition principale |
|---|---|---|
| JOH1 vers JOH2 | OK | Garde d'Oliville : `johto_starter_chosen`, `johto_orme_left` |
| JOH2 vers JOH3 | OK | Pas de barrage au sud de Rosalia |
| JOH3 vers JOH4 | OK | Garde sud de Doublonville : `johto_azalea_clue` |
| JOH4 vers JOH5 | OK | Puits, Brace, `johto_radio_pass` |
| Arc, chaîne interne | OK | Route 36 à l'autel, de `johto_stones_quest` à `johto_stone_breath` |
| JOH6 vers JOH7 | Ordre libre | Voir Q2 |
| JOH7 vers JOH8 | OK | `johto_lugia_done`, Orme, `johto_bell_tower_clue`, Doyen |
| JOH8 vers JOH9 | OK | Doyen pose `johto_act3`, garde du Lac Colère |

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
- Filtre `SCRIPT ERROR`, `FATAL`, `ERROR` lu en fin de séquence : Ho-Oh, Tour Radio, descente, Kanto, Tour Carillon,
  rival, A-25. Résultat : rien. **Non filtré en fin de séquence** (journal vidé au départ suivant) : Raikou et Entei,
  Antre, défaite contre Dante au sommet. Aucun arrêt de l'appli n'y a été vu.

## Incident de séance

À 13 h 58, l'APK a été installé alors que quelqu'un tenait l'A17 : des touches étaient visibles à 13 h 47 et 13 h 51,
et il n'y avait aucune réservation. À 13 h 59, le journal et `getevent` ont montré des gestes sur l'écran réel. Le test
a été arrêté, puis repris à 14 h 09 avec l'accord de Kevin. Le premier combat d'Entei et le début de celui de Raikou
sont écartés de ce rapport. La partie écrasée (« Uk », 50 s de jeu) a été remise à la fin.

## Non testé

- Jonctions JOH1 à JOH5, JOH6 à JOH9 et chaîne interne de l'arc : pas jouées.
- Fuite ou Hurlement au repaire d'Acajou, en jeu.
- Capture d'un légendaire aux Balls ordinaires jusqu'au bout.
- Remontée à pied du Centre au sommet ; 2F et 3F en descente.
- Rival final jusqu'au bout sur cet APK (joué sur l'APK de `1c4a6f70`, avant les musiques).
- Tapis du clan, lanternes d'Ébènelle de nuit.

## À faire par Kevin

- **Écouter** : toutes les pistes, surtout les jointures de boucle ; les replis (Ice Path à Ébènelle et au Mont Argenté,
  Route 26 à la Route 28) ; le thème du rival aux trois arrivées du Mont Argenté.
- **Jouer** : une vraie partie de Johto d'un bout à l'autre, seule façon de valider les jonctions restantes et la
  difficulté.
- **Décider** : Q2, l'ordre entre JOH6 et JOH7.
