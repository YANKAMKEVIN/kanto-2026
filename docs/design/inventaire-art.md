# Inventaire de l'art provisoire

> Établi le 2026-10-21 par la session de coordination, sur `main` @ `537c40f0` (J20 compris), à la
> demande de Kevin (« il y a encore beaucoup de pixel art, c'est normal ? »). Mesuré sur les fichiers
> eux-mêmes, pas sur les noms de dossiers : le J20 a rangé des aplats générés dans `painted/`.
> À refaire après chaque lot d'art ou chaque jalon de contenu (commandes en fin de fichier).

**Pourquoi il en reste** : stratégie d'accélération, levier 4 (décision de Kevin, 2026-10-19). Avant
le code, seulement la grille et une vue générale peinte ; le reste de l'art est reporté et produit
**par lots**, le jalon tourne avec le kit existant ou des provisoires (règle 3 de `CLAUDE.md`). La
cible reste celle du cahier d'art : 2D HD peinte, « ni pixel art ».

## Vue d'ensemble

| Famille | Fait (peint) | Provisoire | Lot proposé |
|---|---|---|---|
| Façades de bâtiments | 44 (dont les 10 de Céladopole et la fontaine, série 22 bis) | 0 | — |
| Intérieurs (enveloppes de carte) | toutes les cartes jusqu'au J19, 17 de Céladopole (série 22 bis), Casino et repaire en modules peints (série 22 bis, Q-2) | 0 | — |
| Dos de combat (ton Pokémon) | **81 / 126** espèces (93 fichiers dans `dos/`, `main` 2026-10-24) | **45 / 126** en pixel art 64 px (+ 25 espèces à venir au J32) | 2 (DAF.1) |
| Faces de combat (adversaire) | artwork officiel pour toutes les espèces | 3 en pixel (Saquedeneu, Rhinocorne, Kangourex) | 2 |
| Fonds de combat (CB.3) | 35 lieux | **6** lieux | 3 |
| Icônes du Sac | 45 (série 22 bis : 29 ajoutées) | 0 | — |
| Objets de décor | tous sauf 2 | 2 (Bourg Palette) | 4 |
| Personnages (PNJ, héros, rival…) | ≈ 100 apparences | aucun visible (fichiers pixel = repli) | — |
| Compagnons d'exploration | 27 / 27 espèces de `companions.json` (Évoli : série 22 bis) | aucun | — |

Ordre des lots **validé par Kevin le 2026-10-21** : **1** série 22 bis (Céladopole et repaire, fiche
`fiches-assets/serie-22bis-celadopole.md`) ; **2** dos de combat ; **3** fonds de combat manquants ;
**4** reliquats (icônes d'avant le J20, objets de Bourg Palette).

## 1. Céladopole et repaire Rocket (J20) : aplats générés — TOUS REMPLACÉS par la série 22 bis (Casino et repaire en modules)

Dessinés par `tools/art/placeholders_celadopole.py` (T16) et `tools/art/placeholders_repaire.py`
(T20) « aux dimensions finales » : remplacer = changer les images (mêmes identifiants, mêmes
dimensions, mêmes emprises), pas les cartes. Détail et cibles : fiche de la série 22 bis.

- **Façades (10)** : `bldg_grand_magasin_01`, `bldg_residence_01`, `bldg_escalier_service_01`,
  `bldg_casino_01`, `bldg_coin_lots_01`, `bldg_arene_celadopole_01`, `bldg_restaurant_01`,
  `bldg_hotel_01`, `bldg_maison_chef_01`, `bldg_maison_toit_01` (+ la fontaine `prop_fontaine_01`).
  Le Centre (`bldg_centre_01`) est le Centre peint des autres villes, réutilisé.
- **Intérieurs (25)**, `assets/world/interiors/placeholder/ph_*.png` : grand magasin (rez-de-chaussée,
  2e à 5e, toit, ascenseur), Résidence (rez-de-chaussée, 1er à 3e, toit, maison du toit), restaurant,
  maison du chef, hôtel, Arène ; Casino, mur coulissant du Casino ; repaire B1F à B4F, cabine du
  repaire, porte du bureau de Giovanni.
- **Casino et repaire (2026-10-21)** : construits **en modules** (`tools/build_game_corner.gd`,
  `tools/build_rocket_hideout.gd` sur `tools/cave_map_kit.gd` et `tools/module_walls.gd`) ; cabine
  du repaire = coque `int_rocket_hideout_elevator_coque`, mur coulissant et porte du bureau =
  `game_corner_wall.png`, `hideout_office_door.png`. Les `ph_celadon_game_corner`,
  `ph_game_corner_wall`, `ph_rocket_hideout_*` et `ph_hideout_office_door` sont **supprimés**.

## 2. Combat

- **Dos (fusionnés dans `main` le 2026-10-24, DAF.1 partie 1)** : `BattleArt.image(back)` lit d'abord
  `assets/sprites/pokemon/dos/` (1024², filtre linéaire ; priorité IA `dos_ia_NNN.png` > 3D
  `dos3d_NNN.png` > provisoire `placeholder/<espèce>_back.png` en pixel art 64 px, NEAREST ;
  `BattleArt.best_painted_back_path`, tests `test_painted_backs.gd`, `test_battle_art.gd`).
  **77 dos IA + 16 dos 3D** (93 fichiers) : 54 du lot 2 (`tools/art/serie_dos.py`, Chenipan refait en r8)
  + 23 IA et 16 3D venus de `battle_proto/`. **81 espèces sur 126 ont un dos peint** (Tentacool et
  Magicarpe, entrés dans les données depuis, le reçoivent). Planche de contact (hors dépôt)
  `build/art/SERIE_DOS_CONTACT.png`. Vérification : `tools/capture_dos_proto.gd -- --species=a,b`.
  **Restent 45 espèces en provisoire** (+ 25 numéros absents des données jusqu'au J32, 151 au total) :
  - **8 à faire par Kevin avec ChatGPT** : les 6 refusés par Codex, Kadabra (64), Tortank (9),
    Rondoudou (39), Staross (121), Léviator (130), Voltali (135), plus Ptéra (142) et Magmar (126)
    (`fiches-assets/dos-a-faire-chatgpt.md`, `serie_dos.py --ajouter IDENT fichier`) ;
  - **4 conditionnels non lancés** (adversaires surtout) : Ossatueur (105, jamais montré, repli
    artwork officiel), Rhinocorne (111), Saquedeneu (114), Kangourex (115) ;
  - **33 espèces ajoutées depuis le lot 2** (J21 à J25 et passe systèmes 2) : Mimitoss (48),
    Aéromite (49), Psykokwak (54), Akwakwak (55), Ptitard (60), Têtarte (61), Tartard (62),
    Machopeur (67), Tentacruel (73), Ponyta (77), Galopa (78), Ramoloss (79), Flagadoss (80),
    Canarticho (83), Doduo (84), Dodrio (85), Otaria (86), Lamantine (87), Tadmorv (88),
    Grotadmorv (89), Crustabri (91), Krabby (98), Krabboss (99), Électrode (101), Smogogo (110),
    Hypocéan (117), Poissoroy (119), Amonita (138), Amonistar (139), Kabuto (140), Kabutops (141),
    Ronflex (143), Artikodin (144) ;
  - **25 numéros pas encore dans les données** (J26 à J32) : 65, 68, 94, 103, 106 à 108, 112, 113,
    122 à 125, 127, 128, 131, 132, 137, 145 à 151.
  - méthode validée et passe Colab (reportée par Kevin le 2026-10-16) :
    `fiches-assets/serie-combat-dos-pilote.md` §7.
- **Fonds CB.3 manquants** (`data/battle/decors.json`, repli = carte floutée) : `viridian_forest`,
  `route_2`, `route_2_north`, `route_22`, `route_25`, `pewter_gym`. Ce sont les premières heures de
  jeu.
- **Faces** : artwork officiel (`official/NNN.png`) ; pixel seulement pour Saquedeneu (114),
  Rhinocorne (111) et Kangourex (115), adversaires du J20.

## 3. Icônes du Sac

16 icônes (`assets/ui/items/`) pour 45 objets. Sans icône :

- **J20 (série 22 bis)** : `great_ball`, `revive`, `poke_doll`, `x_attack`, `x_defend`, `x_speed`,
  `x_special`, `x_accuracy`, `dire_hit`, `fire_stone`, `water_stone`, `thunder_stone`, `leaf_stone`,
  `fresh_water`, `soda_pop`, `lemonade`, `tm13`, `tm21`, `lift_key`, `silph_scope` ;
- **d'avant** : `burn_heal`, `ice_heal`, `hm01`, `tm01`, `tm11`, `tm19`, `tm24`, `tm28`, `tm34`.

## 4. Reliquats

- Objets en pixel art : `breakfast` (`player_house_1f`) et `bed_items` (`rival_house`).
- `ss_anne_outer_deck` : seule carte sans sol peint détecté (construite autrement), à vérifier à l'œil.

## Commandes de mesure

Depuis la racine d'une copie à jour de `main` :

```bash
# Façades et intérieurs en aplats : peu de couleurs (< ~900 sur une vignette de 256 px) et
# fichiers des scripts placeholders_*.py ; regarder l'image avant de conclure.
# (façades de Céladopole : remplacées ; `placeholders_celadopole.py` ne doit plus être relancé)
grep -ohE 'bldg_[a-z0-9_]+' tools/art/placeholders_*.py | sort -u | grep -v 'bldg_\(grand_magasin\|residence\|escalier_service\|casino\|coin_lots\|arene_celadopole\|restaurant\|hotel\|maison_chef\|maison_toit\)_01'
# (les `ph_celadon_*` des 17 cartes remplacées restent sur disque comme références de taille de
# `serie22bis.py` : ne plus les compter ; ceux du Casino et du repaire sont supprimés : la liste
# ci-dessous doit être vide)
ls assets/world/interiors/placeholder/ | grep -v 'ph_celadon_\(dept\|mansion\|restaurant\|chief\|hotel\|gym\)'
# Dos de combat : largeur des images (64 = pixel art)
for f in assets/sprites/pokemon/placeholder/*_back.png; do sips -g pixelWidth "$f" | tail -1; done | sort | uniq -c
# Fonds de combat : clés "places" de data/battle/decors.json contre les cartes à combats
```
