# État du projet — note de passage

Mis à jour : 2026-09-26 (jalon 3B validé par Kevin et fusionné dans `main` ; jalon 4 planifié, fondations en cours dans le cloud).

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

## Organisation cloud / Mac (depuis le 2026-09-26)
- Dépôt privé `YANKAMKEVIN/kanto-2026`. Les sessions **cloud** installent Godot 4.7.2 via le hook SessionStart (`tools/cloud_setup.sh`) et font tourner `tools/test.sh`. Elles **codent et testent** sur une branche dédiée, qu'elles poussent ; **aucune fusion dans `main`** sans validation de Kevin sur le S24.
- Le **Mac** (S24 en USB) récupère la branche, fait les captures (Movie Maker a besoin d'un écran), `tools/deploy_s24.sh` et la QA (`qa-mobile`), puis fusionne après validation de Kevin.
- Une seule session à la fois sur une même branche.

## Prochaine étape
1. **Jalon 4 — starter et premier combat** : plan [`jalon-04.md`](jalon-04.md) sur la branche `plan-jalon-04` ; **décisions de Kevin en tête du §8** (starter qui descend de la table, sortie empêchée par Prof. Chen, tables d'apprentissage de Rouge/Bleu, évolutions prévues dans le modèle, nom seul en combat, répliques après victoire / défaite, Chen après le combat, répliques d'attente, combat dans le vrai labo recomposé). Découpage 4A (choix du starter) puis 4B (premier combat).
   - En cours dans le cloud : **fondations logiques** (données Pokémon, capacités, types, moteur de combat pur) sur `jalon-04-fondations`.
   - Ensuite : scènes du 4A (branche depuis `main` + fondations), QA S24 sur le Mac, validation, puis 4B.
2. **Plan du jalon 5** (Route 1 et premières rencontres sauvages) : éventuellement préparé dans le cloud (`plan-jalon-05`).

## Vitesses de déplacement (Kevin, 2026-09-26)
Réglage « A » essayé et validé sur S24 : **marche 0,27 s/case (≈ 3,7 cases/s)**, **course 0,16 s/case (≈ 6 cases/s)**, au lieu de 0,22 et 0,12. Le **vélo** devra rester nettement le plus rapide (≈ 0,09 s/case prévu). Constantes dans `game/world/grid.gd` ; les tests de vitesse se calent sur ces constantes. Les scènes (Chen qui court, suivi) utilisent les mêmes vitesses.

## Décisions de Kevin (jalon 3B, 2026-09-26)
Décisions du §7 de `jalon-03b.md` appliquées ; après implémentation : recul d'un pas après la pensée (validé), répliques d'attente de Chen et du rival, orientation de Chen sur « Un peu de patience. » laissée telle quelle (polish), suivi en marchant (validé). Le drapeau du starter s'appellera `starter_chosen` (plan du jalon 4, Q26) : le blocage des herbes, qui lit aujourd'hui `has_starter`, sera aligné au jalon 4.

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

- Orientations et animations fines des cinématiques (ex. Chen sur « Un peu de patience. ») : passe de polish des cinématiques.

## Décisions de Kevin (2026-09-25)
Les six propositions de l'architecte sont acceptées : porte du labo au sud avec parvis et portillon vers les jardins, carte 48×34, sous-titre « Kanto » (la phrase d'ouverture est réservée à la première sortie de la maison), course au bouton tenu, marche 0,22 s/case et course 0,12 s/case (à ajuster après l'essai sur S24), sortie Route 1 = bord de carte. Détails dans [`jalon-01.md`](jalon-01.md) §6.
