# QA de Johto sur l'A17 — 2026-11-06

Téléphone : Galaxy A17 (`R5GYB2R7W2Y`), Ne pas déranger actif. APK debug construit depuis `main` `268ffa4e`
(version 0.34.1). Séance de 01 h 01 à 01 h 57, soit 56 min : au-delà des 30 à 45 min prévues, pour finir les
cinq points prioritaires. Les jonctions entre jalons n'ont donc pas été jouées.

## Résultat

**Aucun blocage, aucun plantage, aucune perte de sauvegarde** sur les cinq points prioritaires.
Aucune `SCRIPT ERROR` ni `FATAL` dans les journaux filtrés sur le pid. Cadence : 48 à 50 i/s.

| Point | Résultat | Constat |
|---|---|---|
| Dante (2), combat complet | OK | Gagné en une trentaine de tours. Remplacement des K.O. (ENVOYER) correct ; Giovanni et Cenere enchaînent |
| Rival final, défaite | OK | Retour au Centre du Mont Argenté (soin de l'équipe non relevé) |
| Rival final, combat complet | OK | Gagné en 24 tours ; `johto_rival_final_done` sauvegardé ; Dante et Cenere restent, le rival repart ; l'échelle mène au 3F |
| Reprise pendant le combat du rival | OK | Appli tuée en plein combat, « Continuer » : sommet, un pas, le combat repart |
| Cenere à l'autel, défaite | OK | Retour au Centre d'Ébènelle, équipe soignée, `johto_stones_awakened` gardé |
| Cenere à l'autel, victoire | OK | Avec équipe relevée au niv. 85 (voir Méthode) |
| Retour de l'équipe après Cenere | OK | Écran des 6, VALIDER : 6 en équipe, 3 au Stockage, `johto_team_returned` posé, `storage_offline` et `johto_act1` levés |
| Épilogue et générique de Johto | OK | Scène jouée en avançant les textes, générique jusqu'au bout, `johto_chapter_done` atteint, retour au labo |
| Sortie du labo après le générique | OK | Orme et le rival partis ; sortie vers Bourg Palette libre : correctif du JOH9 confirmé |
| Celebi | OK | EXAMINER à l'autel, A-53, A-54, combat niv. 60. Fuite : il revient. Capture au 15e lancer, part au Stockage (équipe pleine) ; l'autel reprend ensuite son texte normal |
| Retour de Raikou, présence et combat | OK | B1F de la Tour Cendrée, OBSERVER, combat niv. 60, fuite : il reste, on peut le réaffronter |
| Retour de Raikou, capture | Non testé | Deux combats interrompus sans capture (mineur M1) ; 4 lancers, aucun n'a abouti |
| Scène du vol avec la joueuse | OK | Image du lit de la joueuse, rez-de-chaussée dans la pénombre, écriture du vol |
| Reprise après le vol, joueuse | OK | Appli tuée après l'écriture : matin, infirmière, équipe vide, `player_look` = `heroine` conservé |

## Anomalies

Aucun bloquant.

**M1, mineur : Hurlement interrompt la capture de Raikou.** Raikou connaît Hurlement (`roar`, niveau 21). Sur un
combat sauvage, l'attaque chasse le Pokémon du joueur et le combat s'arrête en `FLED` (`game/battle/battle.gd`,
`_force_out`). Sur trois combats : une fuite, un arrêt après « Raikou utilise Hurlement ! » vu à l'écran, un arrêt identique après quelques lancers, sans capture d'écran. Capture : [`raikou-hurlement.jpg`](qa-johto-a17/raikou-hurlement.jpg).
- Au retour, sans conséquence : `FLED` ne consomme pas la rencontre, Raikou reste. Les PV perdus restent perdus.
- Au repaire B3F (lu dans le code, pas joué) : `hideout_raikou` traite `FLED` comme une fuite. Raikou disparaît
  et reviendra après le chapitre. Pas de blocage, mais le joueur perd sa tentative sans l'avoir choisi.
- Entei a la même attaque (lu dans les données). Son retour n'a pas été joué.

**Q1, question de game design : aucun soin entre Dante et le rival.** La scène du sommet enchaîne Dante, Giovanni,
Cenere, une sauvegarde, puis le rival, sans rendre la main au joueur. Après Dante, Ho-Oh restait seul à 39 PV sur
242, et le rival a gagné aussitôt. Capture :
[`rival-sans-soin-apres-dante.jpg`](qa-johto-a17/rival-sans-soin-apres-dante.jpg). Le dossier JOH-10 ne prévoit ni
n'exclut un soin à cet endroit. La défaite n'est pas pénalisante pour l'histoire (Dante reste battu, le rival
attend), mais il faut remonter depuis le Centre. Ce résultat vient d'un jeu sans objets : il ne mesure pas la
difficulté.

**Décision de Kevin (2026-11-06) :** le rival attend. Il dit A-40, A-41, A-41b, le joueur se soigne avec son Sac
et lui parle pour lancer le combat, après confirmation (`docs/tech/jalon-joh9.md` §2.3).

## Méthode

- Départs de débogage `johto_mt_silver_summit`, `johto_den_cenere`, `johto_epilogue`, `johto_celebi`,
  `johto_olivine_night_autosave`.
- Trois départs locaux, non versés au dépôt :
  - `johto_mt_silver_rival` avec `autosave`, pour tester la reprise ;
  - `johto_den_cenere` au niv. 85, pour atteindre la victoire ;
  - `johto_celebi` déplacé au B1F de la Tour Cendrée, pour Raikou.
- Joueuse : `DebugStart` ne gère pas `player_look`. Il a été changé à la main dans `save.json`, puis la partie a
  été reprise par « Continuer ».
- Combats joués par une boucle naïve sur `adb` (toujours la même attaque, aucun objet). Elle a perdu contre Cenere
  au niv. 58 : cohérent avec la simulation du JOHP3 (naïf 11 à 83 %), **ce n'est pas une mesure de difficulté**.
- Drapeaux relus dans `save.json` quand le départ écrit la sauvegarde. Dante et le rival défaits sur le premier
  départ n'écrivaient pas : leur suite a été constatée à l'écran.

Vérification statique, hors téléphone : tous les drapeaux `johto_*` lus par une condition (données et cartes) sont
référencés ailleurs dans `data/` ou `game/`. Ce contrôle cherche un drapeau jamais posé ; il ne prouve pas l'ordre
de jeu.

## Non testé

- **Jonctions entre jalons** : JOH1 vers JOH2 et suivantes, Tour Radio vers l'arc des Pierres, retour à Rosalia et
  acte 2 après l'Antre, retour libre à Kanto au-delà de Bourg Palette.
- Capture de Raikou et disparition du sprite après capture ; retour d'Entei et de Ho-Oh.
- Défaite contre Dante et A-25.
- Remontée à pied depuis le Centre vers Cenere ou le sommet après une défaite : la reprise a été vue par la
  sauvegarde et les drapeaux, pas en marchant.
- Descente du sommet jusqu'au poste de la Route 28 (poste et porte vus le 2026-11-04).

## Environnement

- Le démon adb redémarre souvent (« daemon not running ») et le téléphone a affiché « Connecté pour rechargement
  uniquement » une fois : gestes et captures parfois perdus, sans effet sur le jeu.
- Au départ `johto_epilogue`, la porte du labo ne s'ouvre pas depuis la case d'arrivée : il faut un pas vers le sud
  avant de remonter. `tools/debug_start/README.md` dit seulement « entrer et monter d'un pas ».
- Téléphone rendu propre : `files/` sans sauvegarde ni départ, jeu arrêté, APK debug de `268ffa4e` laissé installé.
