# Série 22 bis — Céladopole et repaire Rocket : façades, intérieurs, icônes (reste du kit du J20)

> Cadrage rédigé le 2026-10-21 par la session de coordination, sur `main` @ `537c40f0` (J20
> terminé), à la demande de Kevin. Suite de `serie-22-celadopole.md` (espèces, personnages, fonds de
> combat, déjà intégrés au T10 du J20). Plan : `docs/tech/jalon-20.md` §1.4 (kit), §2.1 (cartes),
> §10.3 (passation : « Art, lot série 22 bis ») ; conception : `docs/design/dossier-23-celadopole.md`
> §2, §7, §8, §21 ; inventaire : `docs/design/inventaire-art.md`.
> **Reste à faire par la session d'art** : outil `tools/art/serie22bis.py` et prompts versionnés
> `tools/art/prompts/serie22bis/` (modèles `serie21.py`, `serie22.py`), génération, planche de
> contact, validation de Kevin, intégration. Rien n'est généré ni branché par cette fiche.

## Numéro

**22 bis**, nom déjà employé par le plan et la passation du J20 (`jalon-20.md` §1.4, §10.3, fiche
22, en-tête de `placeholders_celadopole.py`). Numéros pris sur les branches le 2026-10-21 : 01, 12 à
25, 27, 28. Fichiers : `serie-22bis-celadopole.md`, `tools/art/serie22bis.py`,
`tools/art/prompts/serie22bis/`, sorties `build/art/serie22bis/`. Les identifiants d'images ne
portent pas le numéro.

## Règle de remplacement (tient tout le lot)

Les provisoires du J20 ont été dessinés **aux dimensions finales** : chaque asset de ce lot garde
**le même identifiant, les mêmes dimensions en pixels et la même emprise** que son provisoire. Les
cartes, collisions, portes, warps et tests ne bougent pas ; l'intégration remplace des fichiers, puis
`assets/world/catalogue.json` (ombres, contact) et le bloc « Série 22 bis provisoire » de
`game/world/props/painted_prop_rules.gd` passent en valeurs définitives. Toute dérogation (emprise ou
taille différente) se décide avant la génération et se note ici.

## DA, géométrie, lumière

- **DA et composition** : `reference/celadopole-vue-generale-v1.png` (validée), seule vue peinte du
  lot. **Géométrie, qui fait foi** : `tools/plans/celadopole.txt` et les grilles d'intérieur
  `tools/plans/celadopole_*.txt`, `casino.txt`, `repaire_*.txt`.
- **Intérieurs : aucune vue peinte**, et pas de planche d'ambiance (Q-1, Kevin, 2026-10-21) : les coques peintes existantes servent d'ancre de
  style (`int_centre_coque`, `int_boutique_coque`, `int_maison_argenta_coque`,
  `int_ss_anne_restaurant_coque`, `int_arene_azuria_coque`) ; contenu d'après le dossier 23 et les
  grilles.
- **Prompts** : ADN visuel v1 (cahier d'art §1.3), **lumière NE**, golden hour pour les façades
  (profil de la carte `golden_hour`), lumière neutre pour les intérieurs (`interior_warm` fait le
  reste). « Ni pixel art » : pas de contour noir, pas d'aplats, matières lisibles à 1:1.
- **Règle de Kevin pour Codex** (séries 19 à 22) : avec les images jointes (2 essais), puis sans
  pièce jointe (2 essais) ; refus consignés dans `$ART/refus_serie22bis.log`.

## A. Façades (10 images) et fontaine

Taille en jeu = image du provisoire (1 case = 96 px ; hauteur = profondeur × 96 + rebord de toit).
Portes = colonnes centrales du bas (2 cases), sauf la maison du chef et la maison du toit (1 case).

| Fiche → asset | Emprise (cases) et porte | Taille | Description (d'après la vue validée) |
|---|---|---|---|
| `WORLD_BLDG_GRAND_MAGASIN_01` → `bldg_grand_magasin_01` | H (4..17, 7..15), 14 × 9 ; porte (10..11, 15) | 1344 × 888 | pierre crème, **trois niveaux** de fenêtres, rez-de-chaussée de vitrines à auvents verts, **toit-terrasse** visible (parasols, plantes en bac, édicule) ; le plus haut de la ville |
| `WORLD_BLDG_RESIDENCE_01` → `bldg_residence_01` | R (24..35, 7..14), 12 × 8 ; porte (29..30, 14) | 1152 × 792 | maison bourgeoise en pierre miel, toit mansardé ardoise gris-bleu à lucarnes, cheminées, jardinières fleuries, perron |
| `WORLD_BLDG_ESCALIER_SERVICE_01` → `bldg_escalier_service_01` | U (29..32, 1..4), 4 × 4 ; porte (30..31, 4), au nord de la Résidence | 384 × 408 | petite tourelle de pierre au même appareil que la Résidence, toit d'ardoise, porte de service sobre ; **sans enseigne** (le provisoire écrit « SERVICE ») |
| `WORLD_BLDG_CASINO_01` → `bldg_casino_01` | K (34..45, 26..32), 12 × 7 ; porte (39..40, 32) | 1152 × 696 | toit magenta, façade violette, bandeau de **néons** magenta et or, portes vitrées dorées, cordons ; seul bâtiment aux néons (les halos `neon` du jeu font la lumière : rien de lumineux peint au-delà des tubes) |
| `WORLD_BLDG_COIN_LOTS_01` → `bldg_coin_lots_01` | L (48..55, 26..32), 8 × 7 ; **aucune porte** | 768 × 696 | ancien Coin à lots fermé : béton gris, vitrine **éteinte** en bandeau sombre, volets ; ne doit pas inviter à entrer (Coin à lots retiré, dossier 23 n° 6) |
| `WORLD_BLDG_ARENE_CELADOPOLE_01` → `bldg_arene_celadopole_01` | Z (5..16, 28..34), 12 × 7 ; porte (10..11, 34) | 1152 × 696 | **serre** élégante : charpente blanche, verrière vert d'eau, palmiers et feuillage visibles à travers, portes vitrées en arc ; l'enclos de haies est fait par la carte |
| `WORLD_BLDG_RESTAURANT_01` → `bldg_restaurant_01` | Q (34..41, 36..42), 8 × 7 ; porte (37..38, 42) | 768 × 696 | toit de tuiles orange, **store rayé** crème et orange au-dessus de la devanture, jardinières |
| `WORLD_BLDG_HOTEL_01` → `bldg_hotel_01` | I (46..55, 36..42), 10 × 7 ; porte (50..51, 42) | 960 × 696 | toit d'ardoise bleu à lucarnes, murs crème, volets bleus ; lit comme un hôtel (marquise ou plaque discrète, pas d'enseigne lumineuse) |
| `WORLD_BLDG_MAISON_CHEF_01` → `bldg_maison_chef_01` | M (24..30, 37..42), 7 × 6 ; porte (27, 42) | 672 × 600 | maison de ville, toit de tuiles terre cuite, murs crème, deux fenêtres, jardinières |
| `WORLD_BLDG_MAISON_TOIT_01` → `bldg_maison_toit_01` | 5 × 4 sur la terrasse du toit de la Résidence (`celadon_mansion_roof`) ; porte 1 case | 480 × 408 | petite maison de toit, même ardoise et même pierre que la Résidence, pots de fleurs |
| `WORLD_PROP_FONTAINE_01` → `prop_fontaine_01` | F (place de la fontaine, x 24..33, y 26..32), 2 cases | 192 × 186 | vasque de pierre claire, jet d'eau ; [D] image fixe, sans animation |

**Hors lot (réutilisés)** : Centre (`bldg_centre_01`), pavés, massifs, haies, arbres, bancs, étang
et quai (série 22 et kits antérieurs), comme le prévoit le plan §1.4.

## B. Intérieurs (25 images)

Chaque provisoire `ph_<carte>.png` est une **enveloppe complète** (sol, murs, mobilier cuit dans
l'image, d'après la grille). Pour garder la règle de remplacement, la cible est une **coque peinte
par carte** à la même taille, mobilier compris (modèle `int_ss_anne_pont_principal_coque`, 2496 ×
1248, la plus grande déjà faite).

| Carte | Grille | Taille (cases → px) | Contenu |
|---|---|---|---|
| `celadon_dept_gf` … `celadon_dept_5f` (5) | `celadopole_magasin_{rdc,2e,3e,4e,5e}.txt` | 20 × 13 → 1920 × 1248 | **une coque commune** + un accent de couleur par étage (sarcelle, rose, violet, ambre, bleu, repris du provisoire) ; comptoirs, rayonnages, tableau des étages, escaliers, porte d'ascenseur |
| `celadon_dept_roof` | `celadopole_magasin_toit.txt` | 20 × 11 → 1920 × 1056 | toit-terrasse : dallage, bacs plantés, parasols, **distributeurs** de boissons, garde-corps (cohérent avec la façade) |
| `celadon_dept_elevator` | `celadopole_magasin_ascenseur.txt` | 6 × 6 → 576 × 576 | cabine métal clair, **panneau d'étages** |
| `celadon_mansion_gf` … `_3f` (4) | `celadopole_residence_{rdc,1er,2e,3e}.txt` | 16 × 11 → 1536 × 1056 | hall et paliers bourgeois, boiseries, tapis, escaliers ; une coque commune déclinée |
| `celadon_mansion_roof` | `celadopole_residence_toit.txt` | 16 × 10 → 1536 × 960 | toit d'ardoise praticable, terrasse, accès à la maison du toit |
| `celadon_mansion_roof_house` | `celadopole_residence_maison_toit.txt` | 10 × 8 → 960 × 768 | petite pièce chaleureuse ; lieu du don d'Évoli (dossier 23 n° 14) |
| `celadon_restaurant` | `celadopole_restaurant.txt` | 15 × 10 → 1440 × 960 | salle, tables nappées, comptoir, cuisine ouverte |
| `celadon_chief_house` | `celadopole_maison_chef.txt` | 15 × 10 → 1440 × 960 | intérieur de maison (famille de `int_maison_argenta_coque`) |
| `celadon_hotel` | `celadopole_hotel.txt` | 15 × 10 → 1440 × 960 | réception, banquette, plantes |
| `celadon_gym` | `celadopole_arene.txt` | 17 × 16 → 1632 × 1536 | **serre** : haies, bassin, verrière, lumière `greenhouse` (vert filtré, sans ombre portée) ; cohérente avec le fond de combat `celadon_gym_serre` (série 22) |
| `celadon_game_corner` | `casino.txt` | 20 × 18 → 1920 × 1728 | machines en décor (aucun jeton), affiche, escalier du mur coulissant ; halos `neon` du jeu |
| `rocket_hideout_b1f` … `_b3f` (3) | `repaire_b1f..b3f.txt` | 30 × 28 → 2880 × 2688 | béton, murs, caisses, conduites, consoles, escaliers ; **flèches peintes** des dalles tournantes et **disques d'arrêt** (59 trajets RB) |
| `rocket_hideout_b4f` | `repaire_b4f.txt` | 30 × 24 → 2880 × 2304 | idem + bureau de Giovanni |
| `rocket_hideout_elevator` | `repaire_ascenseur.txt` | 6 × 8 → 576 × 768 | cabine du repaire, plus froide que celle du magasin |
| `game_corner_wall` | — | 96 × 96 | pan de mur coulissant posé sur l'escalier (17, 4) |
| `hideout_office_door` | — | 192 × 96 | porte du bureau de Giovanni (24..25, 11) du B4F |

**Point technique (Q-2, validé par Kevin le 2026-10-21)** : une coque de 30 × 28 cases ne
se génère pas d'un bloc (la série 21 a écarté les coques de plus de 20 × 18 : image générée à 1 024²
puis étirée ×1,9, floue). Décision : **repaire et Casino en modules** (sol, murs, caisses,
consoles, flèches ×4 directions, disque d'arrêt, escaliers) sur `cave_map_kit.gd`, comme la Tour
(série 21) ; c'est la seule dérogation à la règle de remplacement (outils
`tools/build_rocket_hideout.gd` et `tools/build_game_corner.gd` à adapter, dalles inchangées).
Les autres cartes restent en coque.

## C. Icônes du Sac (20) et planche d'Évoli

- **Icônes** (`assets/ui/items/<id>.webp`, 256 × 256, même format que les 16 existantes) : `great_ball`,
  `revive`, `poke_doll`, `x_attack`, `x_defend`, `x_speed`, `x_special`, `x_accuracy`, `dire_hit`,
  `fire_stone`, `water_stone`, `thunder_stone`, `leaf_stone`, `fresh_water`, `soda_pop`,
  `lemonade`, `tm13`, `tm21`, `lift_key`, `silph_scope`. Les 9 icônes manquantes d'avant le J20
  (`burn_heal`, `ice_heal`, `hm01`, `tm01`, `tm11`, `tm19`, `tm24`, `tm28`, `tm34`) peuvent partir
  dans la même passe (même gabarit) : **Q-3**.
- **Planche d'exploration d'Évoli** (marche 4 × 4 + attente, modèle des 26 compagnons de
  `data/pokemon/companions.json`) : le compagnon Évoli en dépend (`jalon-20.md` T22).
- **Dos de Voltali et Pyroli** : refusés par Codex au J20 (`DOS_PYROLI_r3.txt` prêt). Ils relèvent du
  **lot des dos de combat** (inventaire, lot 2) plutôt que de ce lot ; à y déplacer si Kevin
  confirme (**Q-4**).

## Questions pour Kevin

- **Q-1 — TRANCHÉE par Kevin (2026-10-21)** : intérieurs générés directement d'après les grilles
  et les coques existantes ; **pas de planche d'ambiance** à valider avant.
- **Q-2 — TRANCHÉE par Kevin (2026-10-21)** : repaire et Casino **en modules** (point technique du §B).
- **Q-3** : les 9 icônes d'avant le J20 dans la même passe ?
- **Q-4** : Voltali et Pyroli vers le lot des dos ?

## Contrôles d'acceptation

- Chaque asset remplace son provisoire **à l'identique** (nom, dimensions, emprise), sauf dérogation
  notée ici ; aucune carte ni grille modifiée hors dérogation.
- « Chaque élément visible de la vue validée a un asset ou est abandonné par écrit » (CA du T2 du J20).
- Planche de contact relue par Kevin avant l'intégration ; capture S24 de Céladopole, d'un étage du
  magasin, de l'Arène, du Casino et du B2F du repaire à l'intégration.
- Le contrôle de l'inventaire (`inventaire-art.md`, commandes) ne signale plus aucune façade ni
  intérieur de Céladopole.
