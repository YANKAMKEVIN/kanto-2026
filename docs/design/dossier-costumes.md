# Dossier — Les costumes du Dresseur (chantier « CO »)

> Idée de Kevin du 2026-10-30 : à chaque badge, le joueur débloque une **apparence** qu'il peut porter, volontairement **hors de l'univers Pokémon** (Mario, Luffy, Iron Man…). Une partie du menu, accessible dès le début, montre les costumes encore verrouillés en **silhouette**.
>
> **Documents seuls.** Code et art **après le J33** et après l'intégration de la joueuse et de la rivale (chantier JR, `dossier-joueuse-rivale.md` sur la branche `claude/perso-fille-rivale-be83ae`), dont ce chantier réutilise le système d'apparence (`player_look`).

## Décidé par Kevin (2026-10-30)

- **Un costume par badge**, avec une version pour le joueur et une version pour la joueuse (la version portée suit `player_look`).
- **Liste des huit** (§1) ; Mario et Harry Potter remplacés le 2026-10-30 (filtre de Codex).
- **Silhouettes visibles dès le début** du jeu, non sélectionnables tant que le badge manque.
- **Les PNJ ne réagissent pas** aux costumes.
- **Codex** produit l'art (abonnement déjà payé, à utiliser).
- **Costumes du post-game** : prévus, **non affichés** pour l'instant ; conçus avec le Chapitre Johto (`roadmap.md` phase 10).

## 1. Les huit costumes

| Badge | Arène | Joueur | Joueuse |
|---|---|---|---|
| Roche | Pierre (Argenta) | Tanjiro (Demon Slayer) | Nezuko |
| Cascade | Ondine (Azuria) | Luffy (chapeau de paille) | Nami |
| Foudre | Major Bob (Carmin-sur-Mer) | Iron Man (version adoucie : armure rouge et or) | Iron Woman (idem) |
| Prisme | Erika (Céladopole) | Link (Zelda) | Zelda en tenue d'aventure |
| Âme | Koga (Parmanie) | Naruto | Sakura |
| Marais | Morgane (Safrania) | Deku (My Hero Academia) | Ochaco |
| Volcan | Auguste (Cramois'Île) | Son Goku | Combattante saiyan |
| Terre | Giovanni (Jadielle) | Batman (version adoucie : justicier masqué à cape) | Batgirl (idem) |

## 2. ✅ Arbitrages validés par Kevin le 2026-10-30 (toutes les recommandations, en gras)

| # | Sujet | Options | Recommandation |
|---|---|---|---|
| CO-1 | Où dans le menu | (a) 7ᵉ carte « GARDE-ROBE » sur le tableau de bord ; (b) section de l'écran DRESSEUR, à côté des badges | **(b)** : le dossier 08 §1 limite le tableau de bord à six cartes, et l'écran Dresseur montre déjà le portrait et les badges. Le portrait du Dresseur s'y habille en direct |
| CO-2 | Silhouettes et règle « aucun spoiler » (dossier 08, règle 2 et §6 : un badge inconnu ne montre ni nom ni apparence) | Exception assumée | **Silhouette noire seule**, sans nom du costume ni du badge ; toucher → « Se débloque avec un nouveau badge. » Les silhouettes restent une exception écrite à la règle 2 |
| CO-3 | Lien costume ↔ badge | (a) par badge précis (thème de l'arène) ; (b) par nombre de badges (1er, 2e…) | **(a)** : chaque costume reste lié à son arène, même si l'ordre Koga / Morgane varie |
| CO-4 | Annonce du déblocage | (a) aucune ; (b) une notification après la séquence du badge | **(b)** : une ligne discrète après la remise du badge et de la CT, « Nouveau costume : … », sans ouvrir de menu |
| CO-5 | Couverture | Tout ce qu'a le personnage, ou seulement marche et course | **Tout** : marche, course, attente, vélo et attente, pêche (lancer, attente), surf, lancer de dos en combat, buste du menu. Pas de portrait d'introduction (l'introduction précède tout badge) |
| CO-6 | Tenue d'origine | — | **Toujours sélectionnable**, en première position |
| CO-7 | Quand changer | Partout dans le menu, ou seulement à un endroit (miroir de la chambre, Centre) | **Partout depuis le menu**, instantané et gratuit ; pas en combat |
| CO-8 | Scènes scriptées | Costume visible aussi dans les cinématiques, ou tenue d'origine forcée | **Costume visible partout** (le joueur reste le même acteur) ; exception au cas par cas si une scène casse |
| CO-9 | Sauvegarde | Nouveau champ `player_costume` | **Dans la v9 du chantier JR** (une seule migration) : `player_costume` vide = tenue d'origine ; valeur inconnue ou badge absent → tenue d'origine. Les costumes débloqués **se déduisent des badges**, rien d'autre n'est enregistré |
| CO-10 | Nom affiché dans le jeu | (a) nom du personnage (« Mario ») ; (b) nom descriptif (« Plombier moustachu ») | **(a)** : jeu diffusé au seul cercle restreint de Kevin ; noms en données, faciles à changer |
| CO-11 | Rival | Le rival ou la rivale porte-t-il des costumes ? | **Non** |

## 3. Production

- **Art** : Codex, même méthode que la joueuse (`tools/art/joueuse_rivale/`) : gabarit = asset validé du héros ou de la joueuse (pose, cadrage, 128 px, origine aux pieds), identité = une planche de chara design par costume, validée par Kevin avant les sprites. Style **peint simplifié**, dans la même main que le monde. Environ 15 images par version, soit ≈ 240 images pour les 16 versions. Ordre proposé : une planche des 16 costumes, puis les sprites badge par badge.
- **Risque** : Codex peut refuser ou déformer un personnage de licence copié à l'identique. Repli : décrire la tenue (« salopette bleue, chemise et casquette rouges, moustache ») plutôt que nommer le personnage.
- **Code** : `Player.LOOK_SPRITE` du chantier JR devient une résolution `player_look` × `player_costume` (par ex. `player_heroine_co_peach`) ; liste des costumes en données (`data/costumes.json` : identifiant, badge, apparences joueur et joueuse, nom affiché) ; écran dans le menu Dresseur ; notification après le badge ; tests (déblocage, sauvegarde, valeur inconnue, couverture des apparences).

## 4. Calendrier

1. ~~Arbitrages CO-1 à CO-11~~ : validés le 2026-10-30.
2. Planche des 16 costumes (Codex), validée par Kevin.
3. Sprites, badge par badge.
4. Code, dans la branche du chantier JR ou juste après : sauvegarde v9 (validée seule, avec `rival_look`), puis l'écran et les apparences, validés sur S24.

## Suivi

- [x] Idée et liste des huit costumes (Kevin, 2026-10-30)
- [x] Arbitrages CO-1 à CO-11 — **validés par Kevin le 2026-10-30** (« Okay », toutes les recommandations)
- [x] Planche de chara design — **validée par Kevin le 2026-10-30** (« Oui, je valide ») ; — premier tour Codex (2026-10-30, `tools/art/costumes/`, une planche par badge, garçon à gauche, fille à droite) : **passés au premier essai** Luffy/Nami, Naruto/Sakura, Goku/combattante saiyan ; **Link/Zelda** passé sans les noms ; **Iron Man/Iron Woman** et **Batman/Batgirl** passés seulement en version adoucie (sans nom ni logo), moins reconnaissables ; **Mario/Peach** et **Harry Potter/Hermione** bloqués 4 fois par le filtre de Codex (à la sortie : ressemblance avec une licence), avec et sans images jointes, avec et sans noms. Le filtre laisse passer les mangas et Zelda, bloque Nintendo/Mario, Marvel, DC et Warner. **Décision de Kevin (2026-10-30)** : Mario/Peach → **Tanjiro/Nezuko**, Harry Potter/Hermione → **Deku/Ochaco** ; Iron Man et Batman gardés en versions adoucies. Planche complète des 8 : `reference/costumes-planches-v1.webp` (ordre des badges, garçon à gauche) ; planches en pleine taille, ancres des sprites : `reference/costumes/costume-<badge>-v1.webp`
- [ ] Sprites — **les 8 badges faits** (2026-10-31) : Prisme, Roche, Cascade et Foudre **validés par Kevin** (2026-10-30), Âme, Marais, Volcan et Terre **à valider** ; montage de l'ensemble à l'échelle du jeu `reference/costumes/costumes-jeu-v1.webp` (Prisme seul : `costumes-prisme-jeu-v1.webp` ; marche du héros et de la joueuse en tête de ligne pour l'échelle) ; planches dans `assets/sprites/characters/painted/costumes/<badge>_<joueur|joueuse>_*` (marche, course avec profil, attente, vélo et arrêt, pêche lancer et attente, surf, lancer de dos, buste) ; entrées du catalogue à verser en code : `tools/art/costumes/catalogue_co.json`. Méthode (`tools/art/costumes/` : `prompts_sprites_co.py`, `generer_sprites_co.sh`, `relancer_co.sh`, `lot_co.sh`, `preparer_co.py`, `montage_co.py`, révisions retenues dans `retenus.json`) : gabarit = image brute validée du héros ou de la joueuse (chantier JR), identité = moitié de la planche du costume. **Filtre de Codex** : seul Link a posé problème (refusé 6 fois sur 11 avec le bouclier à blason) → **Link adouci** [D] : bouclier rond en bois, uni, sans blason (`ADOUCI_SPRITES`), identité = sa propre planche de marche ; l'**attente du Link** n'est jamais passée : [D] tirée de la marche (colonne « passage », `retenus.json` : `tiree`). Les 7 autres badges sont passés presque tous au 1ᵉʳ essai, Iron Man et Batman compris. Découpe : `tools/art/decouper_perso.py` sépare désormais aussi deux lignes de poses qui se touchent (cheveux de Sakura et de la combattante saiyan), sans changer les planches déjà découpées. **Quota d'images de Codex** : limite sur 24 h (forfait Plus), atteinte deux fois ; `relancer_co.sh` s'arrête proprement (code 3) et `lot_co.sh` reprend les poses manquantes. Prochaine étape : validation de Kevin, puis intégration en code après le J33 et le chantier JR.
- [ ] Intégration en code (après le J33 et JR)
