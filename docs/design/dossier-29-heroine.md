# Kanto 2026 — Dossier 29 : l'héroïne (choix de l'apparence)

> **Statut : proposition, à arbitrer par Kevin.** Rédigé le 2026-10-28, documents seuls.
> Reprend l'**option B** écartée au chantier OUV (`dossier-13-ouverture.md`, arbitrage A2 :
> option A en V1, « modèle de données prêt pour une héroïne »). Rien n'est codé ni produit avant
> la validation des arbitrages H-1 à H-12 (§6).

## 1. Intention

Proposer, comme Rouge Feu / Vert Feuille, de jouer un **héros** ou une **héroïne**. L'aventure,
les combats, le rival et les textes ne changent pas : seule l'apparence du joueur change, et les
répliques qui lui sont adressées s'accordent.

Hors périmètre : la personnalisation (tenues, couleurs, coiffures), une apparence différente pour le
rival, un changement d'apparence en cours de partie (sauf arbitrage H-6).

## 2. Ce qui existe déjà

| Élément | État sur `main` (2026-10-28) |
|---|---|
| Champ `GameState.player_look` | **créé et sauvegardé depuis la v5** (sauvegarde actuelle : v8), toujours `&"hero"`. Une valeur inconnue retombe sur `&"hero"` (test). **Aucune migration à prévoir.** |
| Résolution des apparences | `game/world/character_look.gd` (`CharacterLook.resolve`) : table de looks, déjà utilisée pour tous les personnages |
| Joueur dans le monde | `game/player/player.gd` : `LOOK_SPRITE` est encore une **constante** `&"player"` (le §3.6 du dossier 13 prévoyait de la lire depuis `player_look` : pas fait) |
| Autres usages du héros | **codés en dur** : `battle_stage.gd` (`heros_lancer.png`), `intro_stage.gd` (`heros_portrait.png`), `menu_art.gd` → `hero_bust.webp` (tableau de bord, carte Dresseur, écran Dresseur, carte du monde), `title_screen.gd` (buste) |
| Syntaxe d'accord `{g:…|…}` | **conçue** (dossier 13 §3.5), **pas codée** |
| Écran de choix | **conçu** (dossier 13 §5.6 : deux cartes avec les portraits en pied, aucune étiquette par défaut), **pas codé** |
| Introduction de Chen | écrite **sans accord adressé au joueur** (dossier 13 §8.3 : c'est voulu) |

## 3. Art à produire

Ancre de style : `PERSO_P2_PEINT_r1` (le héros validé), même main, même lumière neutre
(`fiches-assets/`, production Codex comme les séries précédentes). Mêmes dimensions que le héros :
128 px de haut affichés à 1:1, origine aux pieds.

| # | Asset de l'héroïne | Équivalent du héros | Animations |
|---|---|---|---|
| 1 | Feuille de marche | `heros_sheet.png` | `walk_*` ×4 directions |
| 2 | Feuille d'attente | `heros_idle_sheet.png` | `idle_*` ×4 |
| 3 | Feuille de course | `heros_run_sheet.png` | `run_*` ×4 |
| 4 | Feuille de Surf | `heros_surf_sheet.png` | sur la monture de Surf |
| 5 | Feuille de Vélo | *(absente aussi pour le héros : DAF.5, `heros_bike`)* | `bike_walk_*`, `bike_idle_*` |
| 6 | Feuilles de pêche | *(absentes aussi pour le héros : DAF.5, `heros_fish_*`)* | `fish_cast_*`, `fish_wait_*` |
| 7 | Lancer de dos (combat) | `heros_lancer.png` | pose fixe + entrée |
| 8 | Portrait en pied (introduction, écran de choix) | `heros_portrait.png` | — |
| 9 | Buste du menu (titre, tableau de bord, carte Dresseur, Carte) | `hero_bust.webp` | — |

Soit **9 images**, dont 6 feuilles animées. La phase DA **ne prévoit pas de repeindre le héros**
(il est déjà peint, décision du 2026-10-03) : l'héroïne ne sera donc pas peinte deux fois. Seuls le
Vélo et la pêche manquent encore pour le héros (DAF.5) : les produire **dans le même lot** pour les
deux apparences garde la cohérence.

**Risque principal** : la cohérence de l'héroïne en mouvement (le héros a demandé un test sur S24
avant validation). D'où un essai court (marche seule) avant le reste (§7, étape H.1).

## 4. Code

1. **Apparence lue partout** : `Player.LOOK_SPRITE` lu depuis `GameState.player_look` via
   `CharacterLook` ; une seule fonction `MenuArt.player_bust()` / `player_portrait()` / lancer de
   combat, résolue par apparence (`hero` → fichiers actuels, `heroine` → nouveaux). Test : aucune
   référence directe à `heros_*` ou `hero_bust` hors de cette résolution.
2. **Écran de choix** dans l'introduction de Chen (dossier 13 §5.6), à la place décidée en H-2.
   Le choix est appliqué au **commit** de l'introduction (dossier 13 §3.7), comme le prénom : rien
   n'est écrit sur le disque avant.
3. **Accord des textes** : jeton `{g:prêt|prête}` résolu à l'affichage d'après `player_look`,
   validé au chargement (deux formes exactement, sinon erreur). Un test vérifie que la liste fermée
   des répliques accordées (§5) est couverte, et qu'aucun jeton n'est mal formé.
4. **Sauvegarde** : inchangée (v8). Les anciennes parties restent `hero`.
5. **Tests** : apparence par défaut, choix appliqué au commit, rendu des deux formes, résolution
   des assets pour les deux apparences, partie v8 existante inchangée.

## 5. Textes à accorder

Relevé complet, réplique par réplique : `passes/j-heroine-releve-accords-v1.md` (relevé automatique
du 2026-10-28, **à relire** avant le lot de textes).

**Volume** : **51 répliques sûres + 7 douteuses**, dans **37 fichiers** (32 JSON, presque tous dans
`data/dialogues/` + `data/trainer/moments.json` ; 5 `.gd`). Les cinématiques, PNJ, Dresseurs,
Arènes et objets n'ont aucun accord sur le joueur (les cinématiques renvoient aux dialogues).

**Déjà neutres** : toute l'introduction de Chen (`{player}`, « Ta propre aventure »), les
notifications d'objets, les messages de combat, « Te voilà », « Encore toi », « l'enfant »
(Giovanni), « mon enfant » (Fuji).

**Familles à traiter** :
- **Participes et adjectifs** (« prêt », « venu », « fort », « perdu », « seul », « fatigué »…) :
  jeton `{g:prêt|prête}`.
- **Accord avec un complément placé avant** (« L'eau t'a emporté », « Il t'a attendu ») : même jeton.
- **Gabarits répétés** : « Reviens quand tu seras prêt » apparaît dans 4 fichiers. *Recommandation* :
  une seule tournure neutre (« Reviens quand tu te sentiras d'attaque ») plutôt que quatre jetons.
- **Vocatifs** (« petit », « gamin », « jeune ami », « petit visiteur » : Major Bob, Agatha, les
  Rocket, Armand) : voir H-11.
- **Titre « Champion de la Ligue »** (`moments.champion.title`, `league_oak_congrats`,
  `fighting_dojo_master`) : il devient « Championne » pour l'héroïne. Les « Champion » qui désignent
  d'autres personnages (Pierre, Ondine, Giovanni, le rival) ne bougent pas.
- **Textes codés en dur** (`PLAYER_FALLBACK` « Le Dresseur », `PLAYER_TITLE` « Dresseur Pokémon »,
  libellé « Dresseur » du menu, `TRAINER_CAPTION` « Dresseur d'origine ») : voir H-12.
- **Pluriel mixte** (`oak_after_battle`, « vous vous êtes bien débrouillés ») : **inchangé**, le
  masculin pluriel reste correct puisque le rival est un garçon.

Comme pour les textes de chaque jalon, les formes féminines te sont soumises **en un seul lot**,
avant H.0.

## 6. Arbitrages pour Kevin

| # | Question | Recommandation |
|---|---|---|
| **H-1** | Ajoute-t-on l'héroïne ? | **Oui**, si elle compte pour toi : le coût est faible côté code, l'essentiel est l'art (§3) |
| **H-2** | Où se fait le choix ? | **Dans l'introduction de Chen**, entre « Mais parlons un peu de toi. » et « Comment t'appelles-tu ? » (`data/opening/oak_intro.json`), comme Rouge Feu, sans nouvelle réplique : le portrait choisi reste à l'écran pendant la saisie du prénom |
| **H-3** | Étiquettes « garçon / fille » à l'écran ? | **Non** : deux portraits en pied suffisent (dossier 13 §5.6) |
| **H-4** | Prénoms proposés par défaut | **Une liste par apparence** dans `data/opening/names.json` : le héros garde « Red », « Sacha », « Kevin » ; pour l'héroïne, 3 pastilles à choisir par toi (par exemple « Leaf », l'héroïne de Rouge Feu). Le prénom par défaut des départs de débogage reste « Kevin » |
| **H-5** | Nombre d'apparences | **Deux** seulement. Le mécanisme en accepte plus, mais chaque apparence coûte un jeu complet de 9 images |
| **H-6** | Peut-on changer d'apparence en cours de partie ? | **Non** (fidèle à Rouge Feu). Variante possible plus tard : un miroir dans la chambre |
| **H-7** | Les répliques changent-elles au-delà de l'accord ? | **Non** : on accorde, on ne réécrit pas les scènes. Exception : les phrases où l'accord sonne faux sont **neutralisées** (une seule version pour les deux) plutôt que doublées |
| **H-8** | Le rival et sa sœur | **Inchangés** (le rival reste un garçon, « Il s'appelle… » reste au masculin) |
| **H-9** | Quand ? | **Avant le gel de la version candidate (J34)**, en parallèle de DAF.5 (Vélo et pêche des deux apparences ensemble). Sinon en 1.0.x : le modèle de données le permet sans migration |
| **H-11** | Vocatifs « petit », « gamin », « jeune ami », « petit visiteur » | **Accorder quand c'est naturel** (« petite », « gamine », « jeune amie ») ; « môme » ne change que d'article ; « petit visiteur » est **neutralisé** (une tournure sans genre, proposée dans le lot de textes) |
| **H-12** | « Dresseur » dans les menus et la carte Dresseur | **« Dresseuse » pour l'héroïne** partout où le mot désigne le joueur (titre de la carte, menu) ; « Dresseur d'origine » d'un Pokémon suit le genre de ce Dresseur (le joueur ou un échange). Les « Dresseurs » génériques des conseils restent tels quels |
| **H-10** | Validation | Comme d'habitude : planche de l'héroïne (essai de marche d'abord), puis une session S24 à la fin, avec les textes accordés **en un seul lot** |

## 7. Découpage proposé (après validation)

| Étape | Contenu | Validation |
|---|---|---|
| **H.0** | Code sans art : apparence lue partout, jeton `{g:…}`, textes accordés (§5), écran de choix caché tant que l'art manque | tests, aucune différence visible pour le héros |
| **H.1** | Essai d'art : marche de l'héroïne (feuille 1) + portrait (8), sur planche puis en mouvement sur S24 | **Kevin** (planche + vidéo) |
| **H.2** | Reste de l'art (feuilles 2 à 7, buste 9) ; Vélo et pêche avec le héros (DAF.5) | planche, **Kevin** |
| **H.3** | Écran de choix visible, QA S24 (nouvelle partie héroïne : introduction, chambre, combat, menus, Vélo, Surf, pêche) | **Kevin**, sous-jalon unique |

Estimation : **2 à 3 sessions** de travail, l'art en étant la plus grosse part ; le rythme dépend
surtout des validations de la planche.
