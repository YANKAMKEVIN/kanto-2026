# Dossier — La joueuse et la rivale (chantier « JR »)

> Demande de Kevin du 2026-10-29 : une **joueuse** (version fille du personnage joueur) et une **rivale**, « dans le même style que ce qu'on a déjà ». Chantier art à part des jalons, branche `claude/perso-fille-rivale-be83ae`. Prolonge l'option B du dossier 13 (A2), préparée mais non retenue en V1.

## ✅ Arbitrages validés par Kevin le 2026-10-30 (toutes les recommandations)

| # | Sujet | Décision |
|---|---|---|
| JR-1 | Joueuse | **S'ajoute** au héros : choix à l'ouverture (écran du dossier 13 §5.6, deux portraits, sans les mots « garçon » / « fille ») ; `player_look = &"heroine"`, sans migration |
| JR-2 | Rivale | **Choix libre** de l'apparence du rival quand Chen le ou la présente, indépendant du joueur ; garçon par défaut |
| JR-3 | Lien avec Chen | La rivale est **la petite-fille de Chen** ; la sœur reste sa sœur |
| JR-4 | Prénoms proposés | Joueuse **Leaf · Céleste · Kelly** ; rivale **Régine · Green · Iris** (même règles de prénom, `data/opening/names.json`) |
| JR-5 | Tenues | Codes couleur des homologues. Joueuse : chapeau ou casquette rouge et blanc, haut blanc, short ou jupe bleu marine, baskets rouges, sac jaune. Rivale : cheveux châtains (queue de cheval, mèche rebelle), gilet violet à capuche, haut noir, pendentif argenté, pantalon noir, baskets violettes, sac noir. Design original, pas de copie d'une héroïne officielle |
| JR-6 | Assets | Tout ce qu'ont les homologues. Joueuse : marche, course, attente, vélo + attente, pêche (lancer, attente), surf, lancer de dos (combat), portrait en pied, buste du menu, portrait de la carte. Rivale : marche, attente, portrait en pied |
| JR-7 | Accords | Joueuse : `{g:…\|…}` (dossier 13 §3.5). Rivale : second jeton d'accord (nom à fixer à l'intégration, par ex. `{gr:il\|elle}`). Relevé automatique + relecture, **formes féminines soumises à Kevin en un seul lot** |
| JR-8 | Sauvegarde | Nouveau champ `rival_look` → sauvegarde **v9**, migration = rival garçon ; **validé seul** (système risqué). Choix définitif à la nouvelle partie ; la partie en cours reste héros + Régis |
| JR-9 | Calendrier | Ici : planche de chara design, puis sprites. Intégration en code (écrans, jetons, v9, textes) **dans une branche dédiée après le J33**. Aucune fusion dans `main` sans accord de Kevin |

## Inventaire de l'existant (2026-10-29)

- **Héros** (`assets/sprites/characters/painted/`) : `heros_sheet` (marche 4 × 4), `heros_run_sheet`, `heros_idle_sheet`, `heros_bike_sheet` + `heros_bike_idle_sheet`, `heros_fish_cast_sheet`, `heros_fish_wait_sheet`, `heros_surf_sheet` (`player_surf_frames.tres`), `heros_lancer.png` (combat, `battle_stage.gd`), `heros_portrait.png` (introduction, `intro_stage.gd`) ; `assets/ui/menu/hero_bust.webp`, `assets/ui/map/player_portrait.png`. Animations : `player_frames.tres`.
- **Rival** : `rival_sheet` (marche 4 × 4), `rival_idle_sheet`, `rival_portrait.png` ; `rival_frames.tres`. Pas d'image de dresseur adverse en combat (aucun dresseur n'en a).
- **Production** : Codex (`tools/art/generer.sh`), ancre de style `PERSO_P2_PEINT_r1` ; découpe et assemblage par `tools/art/manifeste.json` et `tools/art/decouper_perso.py` ; SpriteFrames générés par `tools/build_character_frames.gd` (table `LOOKS`). Règles : cahier de l'art §4 (planche 4 × 4 par animation : lignes bas, gauche, droite, haut ; 128 px à 1:1, origine aux pieds).

## Suivi

- [x] Planche de chara design v1 (`reference/joueuse-planche-v1.webp`, `rivale-planche-v1.webp`, `joueuse-rivale-comparaison-v1.webp`) — **validée par Kevin le 2026-10-30**
- [x] Sprites peints (2026-10-30, à valider par Kevin sur `reference/joueuse-rivale-jeu-v1.webp`, homologue à gauche de chaque paire) :
  - 15 images Codex (`tools/art/joueuse_rivale/generer_jr.sh`, prompts `prompts_jr.py` : gabarit = asset validé de l'homologue, identité = planche validée), toutes acceptées au premier tour ;
  - découpe `tools/art/joueuse_rivale/preparer_jr.py` (mêmes réglages que l'homologue au manifeste) : `joueuse_{sheet,run_sheet,idle_sheet,bike_sheet,bike_idle_sheet,fish_cast_sheet,fish_wait_sheet,surf_sheet}.png`, `joueuse_lancer.png`, `joueuse_portrait.png`, `rivale_{sheet,idle_sheet}.png`, `rivale_portrait.png`, `assets/ui/menu/heroine_bust.webp` ;
  - apparences (`tools/build_character_frames.gd`) : `player_heroine` (28 animations, comme `player`), `player_heroine_surf`, `rival_heroine` ; test `tests/unit/test_joueuse_rivale_assets.gd` ;
  - écart noté : sur les sprites, le chapeau de la joueuse se lit comme une casquette à visière (le portrait garde le bord rond de la planche) ;
  - pas de portrait de carte : `assets/ui/map/player_portrait.png` n'est plus lu par le jeu (remplacé par `heros_portrait.png`).
- [ ] Intégration en code (branche dédiée, après le J33) : `Player.LOOK_SPRITE` lu depuis `player_look` (`hero` → `player`, `heroine` → `player_heroine`, surf, `heros_lancer` → `joueuse_lancer`, `hero_bust` → `heroine_bust`, portrait de l'introduction), `rival_look` (sauvegarde v9, validée seule) → `rival` / `rival_heroine` et `rival_portrait` / `rivale_portrait`, écrans de choix, prénoms, jetons d'accord et lot de textes
