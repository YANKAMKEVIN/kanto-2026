# Kanto 2026

Remake 2D **personnel** de Pokémon Rouge/Bleu pour smartphone, « comme si Pokémon n'avait jamais quitté la 2D ». Godot 4.7 + GDScript, cible Android (Galaxy S24, paysage).

Kevin est le **directeur du jeu** : il conçoit (souvent avec ChatGPT), Claude implémente. Toute décision de game design non documentée → la lui poser, ne pas l'inventer.

## À lire avant de travailler

- `docs/design/vision.md` — constitution, DA, contrôles, plan en 13 phases. **Source de vérité du design.**
- `docs/design/roadmap.md` — **vue macro** du projet (phases J0→Ligue et post-game, ordre des jalons). Où va le jeu à long terme.
- `docs/design/ui-reference.md` + `docs/design/reference/da-2026-planche-v1.webp` — référence **UI** validée.
- `docs/design/ui-ux-bible-v0.1.md` — philosophie UI/UX (« le monde est la star ») ; ses contradictions avec la planche sont listées en fin de fichier.
- `docs/design/dossier-04-systeme-pokemon.md` — système Pokémon (jalons 4+) ; `dossier-05-combat.md` — combat ; `dossier-06-progression.md` — progression, arènes, rival, Ligue.
- `docs/design/reference/bourg-palette-aplus-v1.png` — benchmark graphique du **monde** (2D HD atmosphérique, golden hour).
- Monde peint validé (2026-10-06) : `reference/bourg-palette-vue-generale-v1.png` et `route-1-vue-generale-v1.png` (+ plans) — cibles de rendu de Bourg Palette et de la Route 1 ; règles dans les dossiers 01 et 07 (angles droits, « nature dense, objets rares », forêt serrée).
- `docs/design/reference/chambre-joueur-v1.webp` — référence de la **chambre du joueur** (agencement + rendu cible des intérieurs) ; autres intérieurs : `ouverture-storyboard-v1.webp`, `maison-rival-v1.webp`, `labo-chen-v1.png` ; combat : `combat-v1.webp`, `combat-capture-v1.webp`.
- `docs/design/dossier-08-menu-dresseur.md` — Menu Dresseur du **jalon 6** (tableau de bord, Équipe, Sac, Pokédex, Carte, Dresseur, Paramètres) ; maquettes `reference/menu-*-v1.jpg`.
- Jadielle (J7) : `reference/jadielle-vue-generale-v1.webp`, `jadielle-planche-v1.webp`, `centre-pokemon-v1.webp`, `boutique-jadielle-v1.webp`, `route-22-rival-02-v1.webp` (écarts avec le dossier 09 listés dans sa section « Références visuelles »).
- `docs/design/dossier-09-jadielle.md` — **jalon 7** (J7A : Jadielle, Centre, Boutique, économie, colis, activation du Pokédex, stockage ; J7B : Route 22, rival n°2) ; textes à valider au §19. Pas d'implémentation avant validation.
- `docs/design/dossier-10-foret-de-jade.md` — **jalon 9** (Forêt de Jade : poison seul, premières évolutions, premiers Dresseurs, 5 espèces) ; textes validés (2026-10-06) ; plan `docs/tech/jalon-09.md`. Étude d'ambiance : `reference/foret-jade-etude-ambiance-v1.png` (pas de level design). Vue générale peinte validée (2026-10-07) : `reference/foret-jade-vue-generale-v1.png` + plan `foret-jade-plan-v1.png` (la grille `tools/plans/viridian_forest.txt` fait foi).
- `docs/design/dossier-12-argenta.md` — **jalon 10** (Route 2 nord, Argenta, Musée, Arène de Pierre, premier badge) ; 20 arbitrages et textes validés par Kevin le 2026-10-07. Vue générale : `reference/argenta-vue-generale-v1.png` (DA) + `argenta-plan-v1.png` (géométrie, fait foi). **J10 terminé** (2026-10-10) ; plan `docs/tech/jalon-10.md`.
- `docs/design/dossier-13-ouverture.md` — chantier **OUV** (splash, écran titre, introduction de Chen, prénoms, passage à la chambre) ; **terminé le 2026-10-11** (OUV.0–OUV.3, plan `docs/tech/ouverture.md`) ; conception validée par Kevin le 2026-10-10 (14 arbitrages, option A, textes de Chen) ; références `reference/ouverture-titre-v1.webp`, `ouverture-chen-v1.webp`, `ouverture-prenom-v1.webp` ; plan `docs/tech/ouverture.md`.
- `docs/design/dossier-14-systemes-j11.md` — **jalon 11** (grande passe de systèmes : statuts complets, confusion, CT et CT34 Patience, évolution courte, compagnon) ; 8 décisions, arbitrages A-1 à A-14 et textes du §13 **validés par Kevin** (2026-10-10) ; plan `docs/tech/jalon-11.md` validé sur le principe. **J11 terminé le 2026-10-13** (11.0 → 11D validés et fusionnés dans `main` ; clôture et passation au J12 : `jalon-11.md` §8 « T22 »).
- `docs/design/dossier-15-route-3-mont-selenite.md` — **jalon 12** (Route 3, Centre, Mont Sélénite 3 niveaux, Team Rocket, fossiles, Pierre Lune, sas Route 4) ; **verrouillé** par Kevin le 2026-10-11 (textes validés). Grilles et vues générales validées (2026-10-11) : `reference/route-3-vue-generale-v1.png`, `mont-selenite-vue-generale-v1.png` + plans (la grille `tools/plans/` fait foi). **J12 terminé le 2026-10-14** (12.0 → 12D validés par Kevin, fusionné dans `main`) ; plan et clôture : `docs/tech/jalon-12.md` §10.
- `docs/design/dossier-16-azuria.md` — **jalon 13** (Route 4, Azuria, rival n° 3 obligatoire, Arène d'Ondine, Badge Cascade, CT11, Pont Pépite, recruteur Rocket, cambriolage en indices) ; arbitrages validés par Kevin le 2026-10-11 (passe `passes/j13-v2-alignement.md`) ; **J13 terminé le 2026-10-14** (13.0 → 13C validés par Kevin sur S21, fusionné dans `main`) ; plan `docs/tech/jalon-13.md`, équilibrage `docs/tech/jalon-13-equilibrage.md`.
- `docs/design/dossier-17-cap-azuria.md` — **jalon 14** (Route 25, Cap d'Azuria, Léo transformé en Mélofée et sa machine, Passe Bateau, poursuite du Rocket d'Azuria, CT28 Tunnel et combat « deux tours », barrage sud, Abra et fuite par Téléport, Cordon d'échange) ; **verrouillé** (recommandations E-1 à E-15 retenues le 2026-10-11, textes §15 validés le 2026-10-12) ; **J14 terminé le 2026-10-14** (14.0 sur planche et captures, 14A, 14B, 14C sur S21, validés par Kevin ; clôture et passation au J15 : `jalon-14.md` §9) ; plan `docs/tech/jalon-14.md`. Vue générale et intérieur validés (2026-10-11) : `reference/route-25-vue-generale-v1.png` + `route-25-plan-v1.png` (la grille `tools/plans/route_25.txt` fait foi), `reference/maison-leo-v1.png`.
- `docs/design/dossier-19-ss-anne-major-bob.md` — **jalon 16** (S.S. Anne en plusieurs cartes, rival n° 4 obligatoire, capitaine et CS01 Coupe hybride, arbuste de l'Arène, départ définitif confirmé, puzzle Rouge/Bleu strict, Major Bob, Badge Foudre, CT24) ; G-1 à G-10 tranchés par Kevin (passe `passes/j16-v2-alignement.md`), V3 consolidée le 2026-10-15 et relue (§0 prévaut) ; grilles validées (2026-10-15, `tools/plans/ss_anne_*.txt`, `carmin_arene.txt`, planche `reference/ss-anne-plans-v1.png`) ; plan `docs/tech/jalon-16.md` écrit ; **textes et vues générales en attente de Kevin**.
- `docs/design/dossier-*.md` — conception détaillée par zone (`dossier-02-prologue.md` : textes définitifs du prologue, découpage 3A / 3B / 4).
- `docs/design/cahier-art-monde-v0.1.md` — cahier des charges de l'art du monde et prototype de faisabilité de Jadielle (cible = références J7, pas de nivellement par le bas).
- `docs/tech/etat-projet.md` — **où en est le projet, prochaine étape, questions ouvertes.** À lire en début de session.
- `docs/tech/jalon-*.md` — plans techniques des jalons (tâches et critères d'acceptation).

## Règles de travail

1. **Validation S24 par sous-jalon** (5B, 5C…) : les tâches liées s'enchaînent, puis une seule session S24 + validation de Kevin à la fin du sous-jalon. Exception : un système risqué (sauvegarde, tout ce qui peut perdre des données) est validé seul. Jamais trois systèmes à la fois.
2. Une tâche n'est finie que si : `tools/test.sh` passe, le projet s'importe sans erreur, et (si c'est visible) une capture a été relue (headless ou Mac) ; la capture S24 vient à la validation du sous-jalon.
3. **Sur S24, on valide le fonctionnel** (ça marche, c'est lisible, c'est bien placé), pas le rendu final : les visuels sont provisoires jusqu'à la phase DA. Une remarque de rendu se note dans `docs/tech/etat-projet.md` (« Reportés »), sans la corriger tout de suite.
4. **Petites questions → valeur par défaut** : durées, positions, tailles, couleurs… reçoivent une valeur par défaut, notée dans le commit et dans `etat-projet.md`, et le travail continue. Seules les vraies décisions de game design bloquent et vont à Kevin.
5. **`docs/tech/etat-projet.md` est mis à jour dans le même commit que chaque tâche terminée** : chaque session repart de ce fichier.
6. Kevin prépare le dossier de conception du jalon suivant **pendant** le jalon en cours, pour que le code n'attende pas les décisions.
7. Données (Pokémon, attaques, objets, rencontres, dialogues) = fichiers de données, jamais codées en dur dans la logique.
8. Logique de jeu séparée de la présentation (testable sans scène).
9. Monde en **2D HD atmosphérique** (décors HD peints, personnages et Pokémon **peints simplifiés** dans la même main, y compris en combat et dans les menus, lumière dynamique) ; UI **non** pixel art (skill `ui-theme-2026`). Production de l'art : `docs/design/cahier-art-monde-v0.1.md`.
10. **Les maquettes et images de référence donnent la DA et la composition, jamais la vérité fonctionnelle.** Si une image contredit un dossier, `vision.md`, la bible UI/UX ou une décision validée, l'écrit gagne. On n'implémente jamais un élément simplement parce qu'il apparaît sur une maquette.

## Décisions techniques

| Sujet | Valeur |
|---|---|
| Résolution de référence | 1920×1080, stretch `canvas_items`, aspect `expand` (le S24 affiche ~2340×1080) |
| Rendu | `mobile`, filtre `linear` partout (décors, personnages et Pokémon peints), snap 2D au pixel |
| Grille | **case = 96 px** en unités monde = pixels de référence, caméra zoom 1 (≈ 11 cases de haut) ; décors HD dessinés à 1:1 |
| Personnages | **peints simplifiés** (décision de Kevin, 2026-10-03, après test en mouvement sur S24), 128 px de haut affichés à 1:1 (≈ 1,33 case), origine aux pieds ; enfant ≈ 108 px, petit Pokémon (Rattata) ≈ 56 px |
| Déplacement | Case par case (grille 96 px), marche/course |
| Couches physiques | 1 monde · 2 joueur · 3 pnj · 4 interactifs · 5 déclencheurs |
| Actions d'entrée | `move_up/down/left/right`, `interact`, `run`, `menu` (clavier pour tests desktop, tactile sur mobile) |
| Tests | GUT 9.7 (`addons/gut`), dossier `tests/` |
| Package Android | `dev.kevin.kanto2026` |

## Arborescence

```
game/          code et scènes (world/, player/, pokemon/, battle/, ui/, systems/, autoload/)
assets/        tiles/, sprites/, ui/, fonts/, audio/
data/          (à venir) données de jeu
tests/         unit/, integration/ (GUT)
tools/         test.sh, build_android.sh, deploy_s24.sh
docs/design/   conception (ignoré par Godot)
```

## Commandes

```bash
tools/test.sh                  # tests GUT headless (refuse d'abord toute mesure de temps réel : tools/check_test_timing.sh)
tools/build_android.sh         # APK debug → build/kanto2026-debug.apk
tools/deploy_s24.sh            # build + install + lancement + capture build/screenshot.png + logs (USB ou Wi-Fi)
tools/s24_serial.sh            # série adb du S24 (USB ou débogage sans fil)
godot --headless --path . --import   # réimport / détection d'erreurs de scripts
```

## Skills du projet (`.claude/skills/`)

`godot-conventions` · `godot-cli` · `android-deploy` · `ui-theme-2026` · `world-tiles`

## Agents (`.claude/agents/`)

`architecte-godot` (Opus) · `constructeur-monde` (Sonnet) · `ui-mobile` (Sonnet) · `qa-mobile` (Sonnet) — pour une tâche difficile, on peut forcer Opus à l'appel.

**Agents en parallèle** : chacun travaille dans sa propre copie (worktree) ; **jamais de `pkill` / `killall` sur Godot ou GUT** (d'autres agents font tourner leurs tests sur le même Mac) : arrêter seulement ses propres processus, par PID.

**Fable, ponctuellement et sur demande** (≈ 2,5 × le coût d'Opus, jamais par défaut) : seulement quand une erreur coûterait cher — conception de la **sauvegarde** (5C.5), **compagnon Pokémon** (J11), bug sur lequel Opus a déjà échoué. Haiku n'est pas utilisé pour le code, les données ni la QA (au mieux, des recherches dans le code).
