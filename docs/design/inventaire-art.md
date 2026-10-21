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
| Façades de bâtiments | 33 | **10** (Céladopole, J20) | 1 |
| Intérieurs (enveloppes de carte) | toutes les cartes jusqu'au J19 | **25** (Céladopole et repaire, J20) | 1 |
| Dos de combat (ton Pokémon) | **0** | **88 / 88** en pixel art 64 px | 2 |
| Faces de combat (adversaire) | artwork officiel pour toutes les espèces | 3 en pixel (Saquedeneu, Rhinocorne, Kangourex) | 2 |
| Fonds de combat (CB.3) | 35 lieux | **6** lieux | 3 |
| Icônes du Sac | 16 | **29** objets sans icône | 1 (J20) et 4 |
| Objets de décor | tous sauf 2 | 2 (Bourg Palette) | 4 |
| Personnages (PNJ, héros, rival…) | ≈ 100 apparences | aucun visible (fichiers pixel = repli) | — |
| Compagnons d'exploration | 26 / 26 espèces de `companions.json` | Évoli (planche à faire, pas encore compagnon) | 1 |

Ordre des lots **validé par Kevin le 2026-10-21** : **1** série 22 bis (Céladopole et repaire, fiche
`fiches-assets/serie-22bis-celadopole.md`) ; **2** dos de combat ; **3** fonds de combat manquants ;
**4** reliquats (icônes d'avant le J20, objets de Bourg Palette).

## 1. Céladopole et repaire Rocket (J20) : aplats générés

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

## 2. Combat

- **Dos** : `BattleArt.image()` lit `assets/sprites/pokemon/placeholder/<espèce>_back.png`, tous en
  pixel art 64 px (NEAREST). Des dos peints existent en prototype dans
  `assets/sprites/pokemon/battle_proto/` et **ne sont branchés nulle part** :
  - « IA » (`dos_ia_NNN.png`, Codex) : 001, 004, 007, 012, 016, 025, 037, 038, 041, 045, 058, 059,
    071, 072, 081, 092, 093, 095, 097, 104, 129, 133, 134 ;
  - « 3D » (`dos3d_NNN.png`, rendu X/Y) : 001, 004, 007, 012, 016, 025, 041, 050, 051, 072, 081,
    093, 095, 096, 109, 129 ;
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
grep -ohE 'bldg_[a-z0-9_]+' tools/art/placeholders_*.py | sort -u
ls assets/world/interiors/placeholder/
# Dos de combat : largeur des images (64 = pixel art)
for f in assets/sprites/pokemon/placeholder/*_back.png; do sips -g pixelWidth "$f" | tail -1; done | sort | uniq -c
# Fonds de combat : clés "places" de data/battle/decors.json contre les cartes à combats
```
