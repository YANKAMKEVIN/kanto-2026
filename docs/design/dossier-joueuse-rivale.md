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

- [ ] Planche de chara design v1 produite (`reference/joueuse-planche-v1.webp`, `rivale-planche-v1.webp`, `joueuse-rivale-comparaison-v1.webp`) — à valider par Kevin
- [ ] Sprites peints de la joueuse et de la rivale
- [ ] Intégration en code (branche dédiée, après le J33)
