# Série 22 — Céladopole, lot d'art 20.0a (jalon 20) : espèces, personnages, décors de combat

> Rédigée et générée le 2026-10-15 (T2 + T3, branche `j20-t2-t3-art` depuis `5c42a28e`). Plan :
> `docs/tech/jalon-20.md` §1.4, T2, T3 ; conception : `docs/design/dossier-23-celadopole.md` §3.2,
> §7.3, §11, §13, §15.1, §23 ; vue validée `reference/celadopole-vue-generale-v1.png`.
> **Tâches (A)** : rien n'est branché (ni manifeste, ni `data/battle/decors.json`, ni `BattleArt`,
> ni `build_character_frames.gd`) ; intégration au **T10**, après le T9. **À valider par Kevin** sur
> les planches de contact (§5).

## Numéro de série

**22**. Le lot avait d'abord pris 21 (vérifié le 2026-10-15 : 18 = J16, 19 = J17, 20 = J19, rien
au-delà) ; le J18 a poussé sa série 21 en premier sur `origin/jalon-18`, et le J20 a été renuméroté
en **22** le 2026-10-16 (libre sur toutes les branches à 0 h 30, décision du coordinateur) : fiche,
`tools/art/serie22.py`, `tools/art/prompts/serie22/`, planches `SERIE22_*`, sorties
`build/art/serie22/`. Les identifiants d'images ne portent pas le numéro. **À revérifier au push.**

## Périmètre de ce lot

Espèces (§15.1 du dossier), personnages nouveaux (§3.2, §7.3, §11.2, §13), fonds de combat CB.3
(§23). **Hors de ce lot** (reste du kit §1.4 du plan, à faire dans une série 22 bis avant le T15) :
façades, sols, intérieurs (grand magasin, Résidence, serre, Casino, repaire), flèches et disques
des dalles, cabines d'ascenseur, PNJ d'ambiance (employé de bureau, hôtesse, cuisinier, serveur,
réceptionniste, touriste), Tartard de décor, icônes du Sac. Ils gardent la règle « chaque élément
visible des vues validées a un asset ou est abandonné explicitement » (CA du T2), à appliquer à ce
moment-là.

## Outil

`tools/art/serie22.py` (modèle `serie20.py` du J19 ; `MODELE_MARCHE` de `serie12.py`, attente de
`serie17.py`, chaîne CB.3 de `combat_decors/preparer_decor.py`) : `--prompts`, `--refs`,
`--commandes`, `--generer`, `--tuiles`, `--decor`, `--detourer`, `--contact`, `--kit`. Prompts
versionnés : `tools/art/prompts/serie22/`, `tools/art/attente/prompts/<NOM>_ATTENTE.txt`,
`tools/art/combat_decors/prompts/COMBAT_DECOR_{URBAINE,SERRE,REPAIRE}_r1.txt` (+ tuiles). Sorties
non versionnées dans `build/art/` (sources) et `build/art/serie22/` (préparées).

## 1. Kit (T2)

### 1.1 Espèces

Face adverse et artwork du Pokédex = **artworks officiels**, déjà présents pour les 16 numéros
(`assets/sprites/pokemon/official/NNN.png`) : rien à produire. Dos de combat :

| Espèce | N° | Rôle J20 | Dos | Priorité | Identifiant |
|---|---|---|---|---|---|
| Évoli | 133 | don | **peint** (Codex) | 1 | `DOS_EVOLI` → `dos_ia_133.png` |
| Caninos | 058 | sauvage, Joueur D6 | **peint** | 1 | `DOS_CANINOS` → `dos_ia_058.png` |
| Goupix | 037 | sauvage, Joueur D6 | **peint** | 1 | `DOS_GOUPIX` → `dos_ia_037.png` |
| Empiflor | 071 | Erika ; Pierre Plante sur Boustiflor | **peint** | 1 | `DOS_EMPIFLOR` → `dos_ia_071.png` |
| Rafflesia | 045 | Erika ; Pierre Plante sur Ortide | **peint** | 1 | `DOS_RAFFLESIA` → `dos_ia_045.png` |
| Arcanin, Feunard | 059, 038 | Pierre Feu | peint | 2 | `DOS_ARCANIN`, `DOS_FEUNARD` |
| Aquali, Voltali, Pyroli | 134–136 | pierres sur Évoli | peint | 2 | `DOS_AQUALI`, `DOS_VOLTALI`, `DOS_PYROLI` |
| Osselait | 104 | Tour (capturable avec le Scope) | **peint** | 2 | `DOS_OSSELAIT` → `dos_ia_104.png` |
| Saquedeneu, Rhinocorne, Kangourex | 114, 111, 115 | adversaires seulement (Erika, Giovanni) | **provisoire pixel** (`gen_placeholder_battlers.gd`, T7) : jamais affiché de dos au J20 | — | — |
| Fantominus | 092 | Tour | **fait au J19** (`dos_ia_092.png`, série 20, `j19-t8-t9-art-cartes`) | — | — |
| Spectrum | 093 | Tour | **existant** (`battle_proto/dos_ia_093.png`, provisoire) | — | — |

- **Méthode** : la source validée des dos (rendu 3D X/Y repeint sur Colab, fiche
  `serie-combat-dos-pilote.md` §7) demande les modèles X/Y de ces espèces, **absents** de
  `~/dev/kanto-2026-modeles/` (téléchargement et notebook Colab = actions de Kevin). Repli appliqué,
  celui de Fantominus (J19) et d'Hypno (J17 T13) : **dos provisoire peint par Codex**, 1024 × 1024
  RGBA, sujet ≈ 85 % de la hauteur, bas à 120 px (format `dos_ia_NNN`). Remplaçable plus tard par
  la chaîne Colab sans rien changer au jeu (même nom de fichier).
- **Prompts** (`DOS_<ESPÈCE>_r{1,2,3}`) : r1 nom de l'espèce + jointes `official/NNN.png` (anatomie)
  et `battle_proto/dos_ia_025.png` (angle trois quarts dos, cadrage, famille de rendu) ; r2 **sans
  nom de licence**, mêmes jointes ; r3 sans nom ni image (règle de Kevin : jointes d'abord).
- **Compagnon d'Évoli** (planche 4 × 4 du monde, modèle `serie14_pokemon.py`) : **si budget**, non
  produit dans ce lot.

### 1.2 Personnages (marche 4 × 4 + attente 4 × 1, 128 px, lumière NE)

| Classe (dossier) | Décision | Identifiant → planche | Priorité |
|---|---|---|---|
| **Erika** | nouveau | `PNJ_ERIKA` → `erika` | 1 |
| **Giovanni** | nouveau | `PNJ_GIOVANNI` → `giovanni` | 1 |
| Rocket en civil (×2, ville) | nouveau (un modèle pour les deux, comme les Sbires) | `PNJ_ROCKET_CIVIL` → `rocket_civil` | 3 |
| Intello (D1, D3) | nouveau | `PNJ_INTELLO` → `intello` | 3 |
| Beauté (E3) | nouveau | `PNJ_BEAUTE` → `beaute` | 4 |
| Topdresseuse (E5) | nouveau | `PNJ_TOPDRESSEUSE` → `topdresseuse` | 4 |
| Joueur (D2, D6) | **réutilisé** : `parieur` (`gambler`, J17, série 19, « Joueurs D5, D6 » de la Route 11) | — | — |
| Jeune Dresseuse (E4) | **réutilisé** : `dresseuse` (`lass`) | — | — |
| Fillette (D4, D5, D7, E1, E2) | **réutilisé** : `fillette` (`lass_young`) | — | — |
| Sbires du repaire | **réutilisés** : `sbire_h`, `sbire_f` | — | — |

Tenues = **valeurs par défaut** (règle 4), écrites dans `PERSONNAGES` de `serie22.py` : Erika
(carré noir, bandeau rouge, kimono vert jade fleuri, obi moutarde, hakama rouge sombre) ; Giovanni
(cheveux plaqués, costume trois pièces brun orangé sombre, chemise et cravate noires, pastille rouge
sans lettre au revers, ni chapeau ni lunettes) ; Rocket en civil (costume noir, cravate rouge = le
détail rouge du §13.1, feutre noir, lunettes sombres, aucun R) ; Intello (grosses lunettes,
chemisette, stylos, nœud papillon) ; Beauté (robe d'été rose pâle) ; Topdresseuse (veste et jupe
bleu marine, queue de cheval auburn). Jointes de marche : héros `PERSO_P2_PEINT_r1` + une planche
adulte du jeu (`ondine`, `sbire_h`, `president_fan_club`, `chercheur`, `dresseuse`).

### 1.3 Décors de combat CB.3

| Décor (proposé) | Zone / places | Prompt | Jointes |
|---|---|---|---|
| `route_7_8_urbaine` | combats sauvages et Dresseurs des Routes 7 et 8 (une seule route urbaine, [D]) | `COMBAT_DECOR_URBAINE_r1` | `combat-v1`, planche CB, `REF_CE_AVENUE` |
| `celadon_gym_serre` | `celadon_gym` (Dresseuses, Erika) | `COMBAT_DECOR_SERRE_r1` | idem + `REF_CE_SERRE` |
| `rocket_hideout_repaire` | `celadon_game_corner` (Rocket de l'affiche) et `rocket_hideout_b1f…b4f` (Giovanni compris) | `COMBAT_DECOR_REPAIRE_r1` | `combat-v1`, planche CB |

Format des décors existants : composition ≈ 2,17 : 1, tuiles TL / TR (portions ≈ 1,17 : 1)
repeintes, recalées et cousues, 2340 × 1080, WebP 90 ; points A (67 %, 50–55 %) et B (31 %, 97 %),
zones calmes. Pas de calque de premier plan. Céladopole elle-même : aucun combat (ville). Souterrain :
aucun combat sauvage (dossier §4).

## 2. Génération (T3) — 2026-10-15

**45 appels Codex** en deux passes : 25 le 2026-10-15 (la limite d'usage est tombée sur les trois
derniers) et **20 le 2026-10-16** après le retour du quota (0 h 36). Toutes les images produites ont une vraie
transparence (dos, PNJ).

| Asset | Essais | Retenu | Remarques |
|---|---|---|---|
| Dos d'Évoli | r1 | **r1** | collerette crème vue de dos, queue à bout crème, très fidèle |
| Dos de Caninos | r1 **refusé** (modération en sortie), r2 | **r2** | rayures noires, crinière crème ; bon |
| Dos de Goupix | r1 | **r1** | six queues bouclées lisibles ; pelage un peu brun rosé (artwork : roux) |
| Dos de Rafflesia | r1 **refusé**, r2 | **r2** | presque de face sans visage (pétales, pieds) : lisible, peu « de dos » |
| Dos d'Empiflor | r1, r2 **refusés**, r3 (sans image) | **r3** | urne, liane, feuilles ; vert-jaune plus pâle que l'artwork, bord de la bouche visible |
| Dos d'Osselait | r2 (direct, sans nom) | **r2** | crâne blanc, os en main ; bon |
| Dos de Pyroli | r2, r3, r1 **refusés** (16/10) | — | **bloqué** : repli = Kevin colle `DOS_PYROLI_r3.txt` dans l'app ChatGPT |
| Dos de Voltali | r2, r3, r1 **refusés** (16/10) | — | **bloqué** : même repli (`DOS_VOLTALI_r3.txt`) |
| Dos d'Aquali | r2 **refusé**, r3 (sans image) | **r3** | collerette, oreilles-nageoires, queue de sirène ; fidèle |
| Dos d'Arcanin | r2 | **r2** | crinière et touffes crème, rayures noires ; bon |
| Dos de Feunard | r2 **refusé**, r3 (sans image) | **r3** | neuf queues crème à pointes orange ; corps plus hirsute que l'artwork |
| Rocket en civil marche + attente | r1, r1 | **r1** | costume et feutre noirs, lunettes, cravate rouge ; bras croisés à l'attente |
| Intello marche + attente | r1, r1 | **r1** | lunettes rondes, nœud papillon, carnet ; carnet ouvert à l'attente |
| Beauté marche + attente | r1, r1 | **r1** | robe rose pâle, sac blanc |
| Topdresseuse marche + attente | r1 ; attente r1 refusée puis r1 | **r1** | veste et jupe bleu marine, queue de cheval auburn |
| Compagnon d'Évoli | `POKE_EVOLI_NE_r1` **refusé** | — | à relancer sans image (règle de Kevin) ou repli ChatGPT |
| Erika marche + attente | r1, r1 | **r1** | fidèle à la tenue ; **allure très jeune** (chibi du jeu, sans signe d'âge) |
| Giovanni marche + attente | r1, r1 | **r1** | costume brique, pastille rouge, regard froid ; mains dans le dos à l'attente |
| Décor `celadon_gym_serre` | r1 + TL / TR | **r1** | recalage 0,891 / 0,901 ; verrière, haies, bassin à droite ; lumière **plus dorée** que « verte filtrée » |
| Décor `route_7_8_urbaine` | r1 + TL / TR | **r1** | 0,907 / 0,920 ; pavés, haies, réverbères, toits lointains, golden hour |
| Décor `rocket_hideout_repaire` | r1 + TL / TR | **r1** | 0,900 / 0,861 ; béton, piliers, porte d'acier, caisses, néons blancs ; aucun R |

**Refus de Codex** : 5 le 15/10 (Caninos r1, Empiflor r1 et r2, Rafflesia r1, Pyroli r2) et 10 le 16/10
(Aquali r2, Voltali r1–r3, Pyroli r1 et r3, Feunard r2, attente de la Topdresseuse une fois,
compagnon d'Évoli r1), tous en « modération en sortie » ; **Voltali et Pyroli refusés dans les trois
variantes** ; le nom de l'espèce suffit souvent à déclencher le refus (r1), parfois
l'image jointe (Empiflor). Ordre conseillé pour la suite : **r2 directement**, puis r3.

**Sorties préparées** (`build/art/serie22/`) : `dos_ia_133`, `_058`, `_037`, `_071`, `_045`, `_104`,
`_059`, `_038`, `_134` (1024²) ; `<pnj>_sheet.png` + `<pnj>_idle_sheet.png` pour `erika`, `giovanni`,
`rocket_civil`, `intello`, `beaute`, `topdresseuse` (128 px, `decouper_perso.py` / `decouper_attente.py`) ;
`route_7_8_urbaine_back`, `celadon_gym_serre_back`, `rocket_hideout_repaire_back` (`.png` et `.webp`,
2340 × 1080 ; 948 / 802 / 360 Ko).

## 3. Entrées proposées pour le T10 (non ajoutées)

- `tools/art/combat_decors/decors.json` : `entree_decor(...)` de `serie22.py` (composition, tuiles
  TL `[0, 0, w, h]` / TR, 2340 × 1080, qualité 90) pour les trois décors.
- `data/battle/decors.json` : `route_7_8_urbaine` (zones `route_7`, `route_8`),
  `celadon_gym_serre` (`celadon_gym`), `rocket_hideout_repaire` (`celadon_game_corner`,
  `rocket_hideout_*`) ; ancres communes `foe_feet [1559, 540]`, `player_feet [716, 972]`, horizon à
  mesurer sur le master.
- `battle_proto/dos_ia_NNN.png` pour les dos ; looks `erika` → `erika`, `giovanni` → `giovanni`
  dans `build_character_frames.gd` (en fin).

## 4. Reste à produire

1. **Dos de Voltali et de Pyroli** : refusés par Codex dans les trois variantes (avec nom, sans nom,
   sans image). Repli (mémoire « Codex refuse ») : Kevin colle `tools/art/prompts/serie22/DOS_VOLTALI_r3.txt`
   et `DOS_PYROLI_r3.txt` dans l'app ChatGPT ; sinon dos pixel provisoire (T7) en attendant.
2. **Compagnon d'Évoli** (si budget) : r1 refusé ; prochain essai sans images jointes, puis repli ChatGPT.
3. Reste du kit §1.4 (décors du monde, intérieurs, icônes) : série 22 bis, **en attente**.

Commandes : `python3 tools/art/serie22.py --commandes` (prompts déjà écrits).

## 5. Planches de contact — VALIDÉES par Kevin le 2026-10-16 (telles quelles)

- `build/art/SERIE22_CONTACT_COMBAT_v1.png` : chaque dos retenu face à l'artwork officiel de la même
  espèce, aux règles de `BattleLayout` (pieds, présence, loi de taille, tailles RB), sur le décor de
  sa zone ; écran 2340 × 1080 réduit de moitié.
- `build/art/SERIE22_CONTACT_PNJ_v1_1x.png` (et `_2x`) : les six PNJ nouveaux (4 directions de marche
  puis 4 d'attente) à l'échelle du jeu (1 case = 96 px) à côté du héros, d'Ondine et du Sbire.
- `build/art/SERIE22_CONTACT_DECORS_v1.png` : les trois décors avec Évoli de dos et de face.
- `build/art/J20_KIT_v1.png` : faces officielles des 16 espèces et nature du dos prévue ; PNJ
  réutilisés ; nouveaux.

## 6. Points à juger par Kevin — tranchés le 2026-10-16

> **Art validé tel quel** (« Je valide l'art de la série 22 »). Les quatre défauts sont **reportés
> à la phase DA** (règle 3), sans correction maintenant : air enfantin d'Erika et des PNJ adultes,
> dos d'Empiflor proche de Boustiflor, Rocket en civil trop « gangster », serre plus dorée que le
> vert filtré du dossier §23. Reste : dos de Voltali et de Pyroli (app ChatGPT, par Kevin).

1. **Erika paraît enfant** (même gabarit chibi que la Fillette) : acceptable, ou un r2 « jeune
   femme, plus élancée, visage plus adulte » ?
2. **Dos de Rafflesia** vu presque de face (sans visage) et **Empiflor** plus pâle que l'artwork :
   provisoires suffisants ?
3. **Serre** plus dorée que « verte filtrée » (dossier §23) : correction de teinte à la préparation
   (T10) ou r2 ?
4. **Giovanni** à 128 px comme tout adulte (le prompt le voulait un peu plus grand) : garder, ou
   découper à ≈ 136 px ?
5. **Feunard** plus hirsute que l'artwork ; **Topdresseuse** et Beauté au gabarit chibi des
   Dresseuses (même remarque qu'Erika).
6. **Un seul décor** pour les Routes 7 et 8, et le repaire partagé avec le Casino [D].
