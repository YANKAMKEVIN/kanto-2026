# État du projet — note de passage

Mis à jour : 2026-09-26 (**jalon 4A validé par Kevin et fusionné dans `main`** ; interface de combat du 4B prête sur `jalon-04b-ui` ; plan du jalon 5 et dossier Route 1 sur `plan-jalon-05`).

## Fait
- Outillage : Godot 4.7.2, export Android vérifié sur le S24, GUT 9.7.1, scripts `tools/`.
- Conception synthétisée dans `docs/design/` (vision, Dossier 01 Master Map A+, référence UI, images de référence).
- Skills et agents du projet dans `.claude/`.
- **Jalon 1, étape architecture** : plan dans [`jalon-01.md`](jalon-01.md), fondations logiques testées (82 tests verts) :
  `game/world/grid.gd` (constantes, conversions), `grid_world.gd` (règles d'accès), `grid_mover.gd` (mouvement case par case), `game/systems/input/direction_input.gd` (clavier et joystick vers 4 directions).

- **Jalon 1, T1 à T6** : Bourg Palette jouable sur le S24 (carte 48×34, joueur, caméra, HUD : titre de zone, joystick, bouton courir). 173 tests verts. QA sur S24 : 60 fps, aucune collision traversée, aucun plantage (rapport : `build/qa/rapport-jalon-01.md`, non versionné).
- Retouches après QA (voir `jalon-01.md` §7) : transparence des feuillages et toits, bancs déplacés, haut de la Route 1.

- Jalon 1 commité (`37562e0`).
- **Jalon 2, étape architecture** : plan dans [`jalon-02.md`](jalon-02.md), fondations logiques testées (203 tests verts) :
  `Warp` et `WarpTable` (portes, tapis, escaliers), `CameraFraming` (pièces centrées), `ZoneAnnouncer` (quand afficher le titre de zone), `MapCatalog` (identifiant → scène), verrou de `GridMover` (entrées bloquées pendant une transition).

- **Jalon 2, T1 à T6 — portes et intérieurs (fin de la phase 2)** : départ dans la chambre, escalier, rez-de-chaussée, sortie avec titre à la première sortie seulement, maison du rival (un seul niveau), labo de Chen ; autoload `SceneRouter` avec fondu et préchargement des cartes voisines. 295 tests verts. QA sur S24 : tous les passages dans les deux sens, changement de carte < 100 ms, 60 fps, 20 allers-retours sans fuite, aucun plantage (rapport : `build/qa/jalon02/rapport-jalon-02.md`, non versionné). Retouches après QA : `jalon-02.md` §8.

- **Prologue** : conception complète de Kevin dans [`docs/design/dossier-02-prologue.md`](../design/dossier-02-prologue.md) (textes définitifs). Découpage : **3A** PNJ, interactions, dialogues, vie de Bourg Palette · **3B** événement de la Route 1 (Chen ramène le joueur au labo) · **4** starter et premier combat.
- **Jalon 3A, étape architecture** : plan dans [`jalon-03.md`](jalon-03.md), fondations logiques testées (356 tests verts) :
  `StoryFlags` (drapeaux de session), `Dialogue` / `DialogueVariant` / `DialoguePage` / `DialogueLibrary` (dialogues JSON de `data/dialogues/`, validés), `DialogueSession` (texte progressif, silences, avance), `Interaction` / `InteractionTable` / `InteractionFinder` (cible = case devant le joueur), `NpcSpec` / `NpcRoster` (PNJ et Pokémon du décor de `data/npcs/<carte>.json`).

- **Jalon 3A, T1 à T5 — PNJ, interactions, dialogues** : Maman (premier dialogue automatique, puis réplique « Tu sors ? »), rival dans sa chambre (carte de Kanto sur le lit), Maya et les trois starters observables au labo, Mme Aoki et 2 Roucool, Léo et son Rattata, Haru sur la plage ; table, carte et panneau examinables ; bouton contextuel unique Parler / Examiner / Observer (Prendre prévu) avec vibration ; boîte de dialogue sombre translucide sans portrait ; autoload `GameState` (drapeaux de session, sans sauvegarde) ; blocage des entrées par raisons. **513 tests verts.** QA sur S24 : 24 répliques identiques au dossier 02, 60 fps en dialogue, aucun plantage (rapport : `build/qa/jalon03/rapport-jalon-03.md`, non versionné). Retouches après QA : `jalon-03.md` §6 (Haru sur la plage, paillasse du labo, permission VIBRATE). **Validé par Kevin le 2026-09-26.**
- **Jalon 3B — l'événement de la Route 1 (validé par Kevin le 2026-09-26, fusionné dans `main`)** :
  - Plan [`jalon-03b.md`](jalon-03b.md) aligné sur le code réel du 3A (§8) et sur les décisions de Kevin (§7).
  - Fondations logiques : `EventTrigger`/`TriggerTable`, scènes scriptées en données (`Cutscene*`, `data/cutscenes/prologue.json`), `GridWorld.find_path`, pas scriptés, PNJ conditionnés par les drapeaux (`if`/`unless`), clé `turn` des dialogues.
  - T1 : hautes herbes sur (23..24, 0..2), Roucool et Rattata d'ambiance dans la prairie.
  - T2 : `CutsceneDirector` (blocage `cutscene`), déclencheur `Route1Grass` sur (23..24, 3), gel puis « ??? — Hé ! Attends ! ».
  - T3 : Prof. Chen arrive en courant et dit ses 4 répliques (didascalies : il regarde les herbes, silence d'1 s) ; PNJ mobiles.
  - T4 : le joueur suit Chen, fondu vers le labo, échange Rival / Prof. Chen, contrôle rendu. Chen et le rival au labo, chambre du rival vide, nouvelle réplique de Maya. Tant que `has_starter` n'est pas levé, les herbes affichent la pensée « Je ne devrais pas aller là sans Pokémon. » puis le joueur recule d'un pas.
  - Répliques d'attente au labo (décision de Kevin) : Prof. Chen « Un peu de patience. J'ai quelque chose à vous montrer. », Rival « Tu vois ? Je t'avais dit que j'étais prêt. ».
  - QA sur S24 (Mac) : tous les critères OK, 62 fps sur toute la scène, pensée aux herbes 10/10, aucun plantage (rapport : `build/qa/jalon03b/rapport-jalon-03b.md`, non versionné).
  - **675 tests verts**, import sans erreur ni warning. Captures headless (xvfb + opengl3, 2340×1080) relues dans le cloud — **le cloud peut donc aussi produire des captures** (`build/captures/jalon03b/`, non versionnées ; scénarios `route1_grass`, `route1_freeze`, `route1_full` de `tools/capture_play.gd`).
- **Correction des 3 erreurs « locked object » du fondu** (branche cloud `fix-screen-fade-tests`, fusionnée) : les tests n'affichent plus de SCRIPT ERROR.
- **Conception reçue** : `dossier-05-combat.md`, `dossier-06-progression.md`, références `combat-v1.webp`, `combat-capacites-v1.png` et `combat-capture-v1.webp`.
- **Jalon 4, fondations logiques** (branche `jalon-04-fondations`, issue de `plan-jalon-04`, fusionnée dans `jalon-04a` — pas dans `main`) : §2.1 et §2.2 du plan, sans scène ni UI, **670 tests verts** (513 au départ). Aléatoire injectable `GameRng` ; table des 18 types (`data/pokemon/types.json`) ; 9 espèces des trois lignées avec les **tables d'apprentissage de Rouge/Bleu**, évolutions, courbes d'XP (`data/pokemon/species/kanto.json`) ; 24 capacités modernes (`data/pokemon/moves/moves.json`) ; `PokemonData`, `Pokemon` (apprentissage à 4 capacités avec choix de l'oubli, XP et niveaux, évolution, sauvegarde préparée), `PokemonFactory`, `Party`, `Evolution` ; offre du labo et choix du rival (`data/pokemon/starters.json`, `StarterOffer`) ; moteur de combat pur (`Battle`, `DamageCalc`, `BattleAI`…), dresseurs (`data/trainers/rival.json`) et messages de combat (`data/battle/messages.json`, `BattleText`). Écarts avec le plan : `jalon-04.md` §12. Simulation du premier combat : `tools/simulate_first_battle.gd`. **Pas faits** (dépendent de T1 ou d'une décision) : `BattleLayout`, `GameState` (équipe, starter, aléatoire).
- **Jalon 4A, alignement et fin de T0** (branche `jalon-04a`) : plan aligné sur le code réel du 3B et sur les décisions de Kevin (`jalon-04.md` **§13** : le starter rejoint l'équipe après « On dirait que le choix est réciproque. », styles de saut `hop_style`, mise en scène « devant le joueur » dans le labo réel, sortie empêchée par un déclencheur sur le tapis). `Interaction.Kind.MEET`, alias `$nom` et étapes `hop` / `lean` / `despawn` (validation), drapeau `starter_chosen` partout, décision n° 15 (Électrik, accord au féminin `text_f`, `end_message` du rival, `base_exp` modernes). Répliques du jalon 4 reportées au dossier 02. **849 tests verts.** Questions ouvertes : `jalon-04.md` §13.10 (Q-A à Q-E).
- **Jalon 4A — le choix du starter (validé par Kevin sur S24 le 2026-09-26, fusionné dans `main`)** :
  - T1 : `GameState` (équipe, starter, `GameRng` à graine) ; `Npc` : surcharge d'interaction, élan, saut depuis la table avec un **style par Pokémon** (`hop_style` : Bulbizarre calme 0,90 s, Salamèche enthousiaste 0,62 s avec rebond, Carapuce vif et joueur 0,50 s avec deux rebonds et dandinement) ; `InteractionController` → `meet_requested` ; `CutsceneDirector` : alias, `hop`, `lean`, `despawn` ; discours de Prof. Chen (4 répliques) à la fin de `route1_grass`, puis `starter_offered`.
  - T2 : bouton **RENCONTRER** ; légende « CHOISIS TON PREMIER PARTENAIRE » sans rectangle (~3 s) ; fiche `StarterSheet` translucide à gauche (nom, pastilles de type, phrase, RETOUR / CHOISIR) ; `TYPE_COLORS` des 18 types.
  - T3 : `StarterChoice` ; scène `starter_chosen` (`data/cutscenes/starter.json`) : le starter descend et vient devant le joueur, « On dirait que le choix est réciproque. », **alors seulement** il rejoint l'équipe ; le rival prend le starter avantagé, « Alors ce sera toi. », son Pokémon saute près de lui, il commence à partir, « Attends. », il regarde son Pokémon puis celui du joueur, « On ne va quand même pas partir sans savoir ce qu'ils savent faire. » ; fin provisoire (le combat est le 4B). Sortie du labo empêchée pendant le choix (déclencheur `LabExit`, « Pas si vite. Tu n'as pas encore choisi ton partenaire. », recul d'un pas). Hautes herbes débloquées par `starter_chosen`. En revenant au labo, seul le starter restant est sur la table.
  - **949 tests verts** (832 après les fusions), 0 SCRIPT ERROR, 0 orphelin, import sans erreur ni warning. Captures headless relues (xvfb + opengl3, 2340×1080, `build/captures/jalon04a_t1..t3/`, non versionnées ; scénarios `starter_offer`, `hop_styles`, `starter_choice --starter=<espèce>`, `lab_exit` de `tools/capture_play.gd`, `starter_lab` de `tools/capture_hud.gd`).
  - **QA S24 (T4)** faite : `build/qa/jalon04a/rapport-jalon-04a.md` (non versionné). Réserves R1 (starter caché par la tête du joueur) et R2 (crénelage du dandinement de Carapuce).
  - **Décision n° 16 et R2 appliquées** (`jalon-04.md` §13.12) : le joueur ne bouge plus, son starter atterrit à côté de lui (case libre calculée sur la grille), le joueur se tourne vers lui ; Pokémon du rival à côté du rival, jamais derrière sa tête ; « Ça devrait être intéressant. » ; les deux Pokémon rentrent dans leur Poké Ball en fin de séquence ; répliques de Chen et du rival pendant le choix ; répliques de la décision n° 8 réservées à l'après-combat (`rival_battle_done`, 4B) et Maya accordée (`starter_female`) ; saut sans rotation (décalage horizontal, compression verticale). Captures Mac 2340×1080 des trois choix : `build/captures/jalon04a_fix/` (non versionnées).
  - **Pas fait dans le cloud** : APK (pas de SDK Android ici). `export_presets.cfg` n'exclut pas `data/` : à confirmer par `unzip -l` sur l'APK (`data/pokemon/*.json`, `data/cutscenes/starter.json`).

- **Jalon 4B, composants d'interface du combat** (branche cloud `jalon-04b-ui`, depuis `jalon-04a`, non fusionnée) : `game/ui/battle/` — barre de PV animée (vert → jaune → rouge), cartes d'information (nom seul, ♂/♀, Nv., PV chiffrés côté joueur seulement, pulsation sous 20 %), 6 pastilles d'équipe, grille des 4 actions (ATTAQUER dominant, actions indisponibles atténuées), 4 cartes de capacités (type, PP, Puissance / Statut, sélection ▶), bouton « ‹ », fiche en pression longue, bandeau des messages ; placement `BattleHudLayout`. Composants autonomes, **non câblés** (ni `BattleHud`, ni `BattleDirector`). Tokens et thème dans `UiTokens` / `build_ui_theme.gd` ; isolation vérifiée par `test_ui_theme.gd`. **1023 tests verts**, import propre. Captures headless 2340×1080 et 1920×1080 sur le labo : `tools/capture_battle_ui.gd` (`build/captures/jalon04b_ui/`, non versionnées). Questions pour Kevin : voir le rapport de la session (fiche fermée au relâchement, « PP » affiché, tailles tactiles 128 px, etc.).

## Organisation cloud / Mac (depuis le 2026-09-26)
- Dépôt privé `YANKAMKEVIN/kanto-2026`. Les sessions **cloud** installent Godot 4.7.2 via le hook SessionStart (`tools/cloud_setup.sh`) et font tourner `tools/test.sh`. Elles **codent et testent** sur une branche dédiée, qu'elles poussent ; **aucune fusion dans `main`** sans validation de Kevin sur le S24.
- Le **Mac** (S24 en USB) récupère la branche, fait les captures (Movie Maker a besoin d'un écran), `tools/deploy_s24.sh` et la QA (`qa-mobile`), puis fusionne après validation de Kevin.
- Une seule session à la fois sur une même branche.

## Prochaine étape
1. **Jalon 4B — le premier combat**, sur une branche `jalon-04b` créée depuis `main` puis fusion de `origin/jalon-04b-ui` (composants d'interface du combat, 1023 tests, captures relues ; réponses aux 9 questions de l'UI : valeurs appliquées acceptées). À faire : vue de combat dans le vrai labo recomposé (T6), câblage `BattleDirector` (T8), étape `battle` avant les deux `despawn` de la scène, drapeau `rival_battle_done` levé quelle que soit l'issue, répliques après victoire / défaite (décision n° 6), Chen après le combat (n° 7), **5 Poké Balls données par Chen** (dossier 07 §8), répliques d'après-combat de Chen et Maya (n° 8, accord lui/elle), **suppression des répliques répétées de fin de 4A**. QA S24 (T9) sur le Mac.
2. **Jalon 5** — plan `docs/tech/jalon-05.md` et `docs/design/dossier-07-route-1.md` sur `plan-jalon-05` ; ordre : 5A carte → 5B rencontre → 5C XP → **sauvegarde** → 5D capture.

## Décisions de Kevin sur le 4A (après correction, 2026-09-26)
Validé tel quel : recul d'un pas du joueur sans se retourner (effet « moonwalk » accepté en provisoire), starter de Bulbizarre en diagonale, léger chevauchement de la paillasse avec Salamèche.

## Questions pour Kevin (jalon 4A, archivées)
Q-A à Q-I : réponses de Kevin (décision n° 16, `jalon-04.md` §8) appliquées (§13.12). Suite aux captures de la décision n° 16 (Kevin, 2026-09-26) :
- **Corrigé** : le Pokémon du rival ne saute plus jamais par-dessus le joueur ni à travers un personnage. Le joueur recule d'un pas sans se retourner (sauf devant le tabouret), les atterrissages sont calculés sur la grille sans survoler personne (testé pour les trois choix).
- **Accepté provisoirement jusqu'au 4B** : fin provisoire du 4A, Chen redit « On dirait que le choix est réciproque. », le rival « On ne va quand même pas partir sans savoir ce qu'ils savent faire. ». **Le 4B doit supprimer ces répliques répétées** au profit des états narratifs définitifs (`jalon-04.md` §13.12).
- **Rentrée dans la Poké Ball** : fondu de 0,2 s provisoire (pas d'animation de Ball) ; le Pokémon du rival rentre aussi.
- Les regards du rival (Pokémon du joueur, puis le joueur ; son Pokémon puis celui du joueur) restent peu visibles : tous sont à sa droite.
- Avec Bulbizarre, le starter se pose en diagonale (11, 6), un peu au-dessus du joueur (10, 7) : la case à sa droite est cachée par la paillasse, celle de gauche obligerait le saut à passer sur le rival.
- Hors questions : « Électrique » reste écrit dans `ui-reference.md` et `dossier-06-progression.md` (documents de Kevin, non modifiés) ; `combat-capacites-v1.png.png` toujours à renommer.

## Vitesses de déplacement (Kevin, 2026-09-26)
Réglage « A » essayé et validé sur S24 : **marche 0,27 s/case (≈ 3,7 cases/s)**, **course 0,16 s/case (≈ 6 cases/s)**, au lieu de 0,22 et 0,12. Le **vélo** devra rester nettement le plus rapide (≈ 0,09 s/case prévu). Constantes dans `game/world/grid.gd` ; les tests de vitesse se calent sur ces constantes. Les scènes (Chen qui court, suivi) utilisent les mêmes vitesses.

## Décisions de Kevin (jalon 3B, 2026-09-26)
Décisions du §7 de `jalon-03b.md` appliquées ; après implémentation : recul d'un pas après la pensée (validé), répliques d'attente de Chen et du rival, orientation de Chen sur « Un peu de patience. » laissée telle quelle (polish), suivi en marchant (validé). Le drapeau du starter s'appelle `starter_chosen` (plan du jalon 4, Q26) : le blocage des herbes le lit depuis le 4A.

## Décisions de Kevin (jalon 3A, 2026-09-26)
Toutes les propositions de `jalon-03.md` §5 acceptées ; boîte de dialogue sombre translucide sans portrait (bible UI/UX §3, remplace la planche) ; bouton contextuel face à la cible ; panneau « BOURG PALETTE » provisoire ; « Rival » ; Haru sur la plage (se tourne vers le joueur puis vers la mer) ; nom du Pokémon observé affiché.

## Décisions de Kevin (jalon 2, 2026-09-25)
Les neuf propositions de l'architecte sont acceptées : on entre en marchant dans la porte, départ dans la chambre sans titre, titre de zone seulement en changeant de zone extérieure, chambre du rival à l'étage, pièces modestes centrées sur fond quasi noir, fondu d'environ 0,45 s, agencements du §4 validés (ajustables après S24), arrivée sur la case du passage en continuant à marcher, cartes géographiques chez le rival. Détails dans [`jalon-02.md`](jalon-02.md) §6.

## Storyboard d'ouverture (Kevin, 2026-09-25)
Référence `docs/design/reference/ouverture-storyboard-v1.webp`. Escalier = transition (pas de lieu jouable). Mère et son dialogue : jalon PNJ et dialogues. Révélation de Bourg Palette : cinématique de première sortie au jalon « ouverture ». Détails dans `jalon-02.md` §7.

## Références d'intérieurs (Kevin, 2026-09-25/26)
- Chambre : `docs/design/reference/chambre-joueur-v1.webp` ; rez-de-chaussée et sortie : `ouverture-storyboard-v1.webp` ; maison du rival (un seul niveau, **sans Évoli**) : `maison-rival-v1.webp` ; labo : `labo-chen-v1.png`. Plans correspondants : `jalon-02.md` §4.3, §4.4, §4.5, §4.7.

## Reportés (décision de Kevin)
- Écran de démarrage « GODOT » (~0,5 s) : à remplacer avec l'icône et l'identité du jeu.
- Incident de saisie vu une fois en QA (joueur reparti dans le mauvais sens), non reproduit : à surveiller.
- Cinématique de première sortie (révélation de Bourg Palette, « Le commencement de toute aventure ») : jalon « ouverture ».
- Rendu « vraie DA » des intérieurs d'après les références (lumière chaude, décor riche) : phase DA. Le bas de la douche du rival reste partiellement sous le bouton courir.
- Laissé tel quel (décision de Kevin) : un pas en trop si on lève le doigt à la toute fin du fondu.

- **Polish de l'animation des sauts** (accepté provisoirement par Kevin, 2026-09-26) : le tassement à l'atterrissage (compression verticale en nearest, quelques rangées de pixels sautées pendant 0,08 s) est à reprendre avec les vrais sprites, avec l'anticipation du saut, la trajectoire, le squash à l'atterrissage et le retour à l'idle.
- Orientations et animations fines des cinématiques (ex. Chen sur « Un peu de patience. ») : passe de polish des cinématiques.
- Pas en arrière du joueur dans la scène du starter : animation de recul dédiée à créer avec les vrais sprites (aujourd'hui marche vers le haut jouée en reculant, « moonwalk »).

## Décisions de Kevin (2026-09-25)
Les six propositions de l'architecte sont acceptées : porte du labo au sud avec parvis et portillon vers les jardins, carte 48×34, sous-titre « Kanto » (la phrase d'ouverture est réservée à la première sortie de la maison), course au bouton tenu, marche 0,22 s/case et course 0,12 s/case (à ajuster après l'essai sur S24), sortie Route 1 = bord de carte. Détails dans [`jalon-01.md`](jalon-01.md) §6.
