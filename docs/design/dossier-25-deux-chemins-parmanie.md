# Dossier 25 — Les deux chemins vers Parmanie (jalon 22)

> Consolidé par Claude le 2026-10-16 à partir de la V2 de ChatGPT (`passes/j22-v2-chatgpt.md`) et de
> la passe d'alignement (`passes/j22-v2-alignement.md`). **Les 7 décisions de la V2 et les
> arbitrages M-1 à M-24 sont validés par Kevin** (« Je suis toutes tes recommandations M-1 à M-24 »,
> 2026-10-16). Les **textes du §16 sont à valider** en un seul lot.
>
> Faits Rouge/Bleu : désassemblage `pret/pokered` (`af51989`), version **Rouge** pour les rencontres
> (convention à confirmer en 22.0, M-23). Marqueurs : **[V]** validé par Kevin, **[D]** valeur par
> défaut (règle 4 de `CLAUDE.md`), **RB** Rouge/Bleu, **G3+** génération ultérieure, **K26**
> adaptation de Kanto 2026.
>
> Branche : `docs/dossier-25-j22`. Dossiers voisins : 18 (J15, Carmin, Fan Club, pêcheur), 16 (J13,
> Azuria, Boutique de Vélos), 19 (J16, Coupe), 20 (J17, Route 11), 21 (J18, Lavanville), 23 (J20,
> Céladopole), 24 (J21, Flûte, Ronflex, Routes 12 nord et 16 est). Jalon suivant : **J23** (Parc
> Safari, CS, Arène de Koga).

## Décisions de Kevin

### Les 7 décisions de la V2 [V]

1. Routes 12 à 18 complètes et Parmanie accessible.
2. Deux itinéraires indépendants : Routes 12–15 (à pied) et Routes 16–18 (Piste Cyclable).
3. Pêche fonctionnelle dès le J22, selon les cannes obtenues.
4. Bicyclette utilisable et Piste Cyclable fonctionnelle.
5. Difficulté modérée, nombreux Dresseurs facultatifs.
6. Parmanie accessible avec ses bâtiments principaux ; Parc Safari et Arène de Koga réservés au J23.
7. Arrivée libre, sans événement narratif forcé.

### Arbitrages M-1 à M-24 [V]

| # | Décision |
|---|---|
| M-1 | Dossier **25**, ce fichier, branche `docs/dossier-25-j22`. Le prompt Safrania est reporté. |
| M-2 | Le **code des cartes** attend une branche d'intégration réunissant J15 → J21. Le lot 22.0 (données, logique pure, grilles, vues peintes, art) commence dès maintenant. |
| M-3 | **Ronflex « est » au croisement de la Route 12** (RB) : il ferme à la fois la Route 11 et la Route 12 sud. Revient sur L-2 du J21 ; drapeaux `snorlax_route_12_*` [D]. Demande transmise à la session du J21 le 2026-10-16. |
| M-4 | Bon de Commande : le président du Fan Club le donne après qu'on a **écouté son histoire** (RB). |
| M-5 | La Boutique de Vélos d'Azuria échange le Bon contre la Bicyclette. |
| M-6 | Monter à vélo : Sac → UTILISER **et** bouton rond « Vélo » dans le HUD une fois la Bicyclette obtenue. |
| M-7 | Le compagnon **rentre dans sa Ball** à vélo et ressort à la descente. |
| M-8 | Pêche sur les cases d'eau **marquées « pêchable »** : nouvelles cartes **et** cartes déjà livrées (Carmin, Azuria, Routes 6, 11, 24, 25). |
| M-9 | La **meilleure canne** est utilisée d'office (Action face à l'eau) ; Sac → UTILISER pour une canne précise. |
| M-10 | Canne et Super Canne : tables **globales** ; Méga Canne : table **par carte**, avec une table par défaut. |
| M-11 | Une touche lance un combat sauvage ordinaire, fond `route_12_ponton`. |
| M-12 | **Métamorph absent** du J22 ; ses créneaux sont redistribués. |
| M-13 | Pente de la Route 17 avec **paliers** sans pente ; la dérive s'arrête quand un Dresseur voit le joueur. |
| M-14 | **40 Dresseurs** (RB : 56), équipes RB, chaque classe gardée. |
| M-15 | Au plus **un** combat inévitable par route, jamais deux de suite. |
| M-16 | Objets sans mécanique **remplacés** (§11) ; Hyper Potion et Hyper Ball créées par données. |
| M-17 | Assistant du poste de la Route 15 : présent, **sans cadeau**. |
| M-18 | Route 16 : **arbre coupable**, voie haute ouverte (objet caché, vue sur la Piste), **porte de la maison de Vol réservée au J23**. |
| M-19 | Maison du Gardien : **porte réservée au J23**. |
| M-20 | Enclos de Parmanie : **Kangourex et Ramoloss** peints dans le monde, panneaux pour les autres. |
| M-21 | Classes nouvelles : **Pêcheur, Motard, Ornithologue, Loubard** (nom de la classe Cue Ball à confirmer au §16). |
| M-22 | Aucun objectif nouveau au tableau de bord. |
| M-23 | Version des rencontres : convention des jalons précédents, vérifiée en 22.0. |
| M-24 | Découpage **22.0 · 22A · 22B · 22C**, trois validations S24 (§18). |

## 1. Intention

Après la gravité de Lavanville, Kanto **s'ouvre**. Le joueur choisit sa route : le **chemin des
pêcheurs**, long et paisible, qui longe l'eau entre les clôtures et les herbes ; ou la **Piste
Cyclable**, une descente grisante au milieu des Motards. Les deux mènent à Parmanie, ville ouverte sur
la nature, où l'on devine le Parc Safari et l'Arène de Koga sans encore y entrer.

Deux plaisirs nouveaux, sans tutoriel : **pêcher** (un geste, une attente, une surprise) et **rouler**
(aller deux fois plus vite, sentir la pente). Aucun objectif ne pousse le joueur : il revient sur ses
pas quand il veut.

## 2. Périmètre

| Dedans | Hors du J22 |
|---|---|
| Route 12 sud, Routes 13, 14, 15 et poste de la Route 15 | Parc Safari, Arène de Koga, Badge Âme (**J23**) |
| Poste de la Route 16 (deux voies), Route 16 ouest, arbre coupable, voie haute | Maison de Vol, CS02 Vol, voyage rapide (**J23**) |
| Route 17 (Piste Cyclable), Route 18 et son poste | Maison du Gardien, Dents d'Or, CS04 Force (**J23**) |
| Parmanie : extérieur, Centre, Boutique, maison de la Super Canne, Salle de réunion, maison du grand-père, enclos | Surf, Route 19, îlot de la CT16 (Route 12) |
| Bon de Commande (Carmin), Bicyclette (Azuria), mode vélo, pente | Métamorph et Morphing |
| Trois cannes, pêche, tables d'eau | Multi Exp, vitamines, PP Plus, Élixirs, Repousse |
| 40 Dresseurs, 12 espèces nouvelles | Safrania (jalon à venir) ; re-combats de Dresseurs |

## 3. Contrat d'entrée

Le J22 **suppose livrés** (rien n'est encore réuni dans une même branche, M-2) :

| Origine | Élément utilisé par le J22 |
|---|---|
| J13 (`main`) | Boutique de Vélos d'Azuria et son vendeur `cerulean_bike_clerk` |
| J15 | Fan Club de Carmin (président), maison du pêcheur de Carmin ; drapeaux prévus `got_bike_voucher` (F-8), `got_old_rod` (V-4) |
| J16 | Coupe : `field_moves.gd` (CS → Badge Cascade → Pokémon compatible), buisson `InteractPoint` + drapeau |
| J17 | Route 11 et son raccord est |
| J18 | Lavanville, bord sud |
| J20 | Céladopole, sortie ouest |
| J21 | Poké Flûte (objet clé utilisable, `key_use`), deux Ronflex (`*_woken`, `*_caught`, `*_done`), Route 12 nord jusqu'au croisement, Route 16 est (Ronflex, façade du poste, voie haute, arbre) |
| Système | Drapeaux génériques, `beaten_<id>`, `got_<carte>_item_N`, `got_<carte>_hidden_N`, rebords, eau (`is_water`), étiquettes `coming_soon` |

**À ne pas toucher** : postes de garde de Safrania (Routes 5 à 8), Tour Pokémon, règles de la Flûte.
Aucun drapeau du J22 n'est lu par un poste de Safrania.

## 4. Géographie

```
                 LAVANVILLE
                     │
 CÉLADOPOLE ── R16 est (Ronflex J21) ── poste 16 ┐   R12 nord (J21)
     │                                   │       │        │
     │                      voie haute ──┘       │   [RONFLEX au croisement] ── R11 ── CARMIN
     │                      (arbre, maison Vol J23)        │
     │                 voie basse = PISTE                 R12 sud (Méga Canne)
     │                          │                          │
     │                        R17 (pente, paliers)        R13 (clôtures)
     │                          │                          │
     │                    R18 ouest ── poste 18 ── R18 est R14
     │                                               │     │
     │                                            PARMANIE ── R15 (poste)
```

| Carte | Grille [D] | Raccords |
|---|---|---|
| Route 12 sud | 30 × 70 | N croisement (J21, Ronflex) · S/O Route 13 |
| Route 13 | 90 × 27 | E Route 12 sud · O Route 14 |
| Route 14 | 30 × 81 | E Route 13 · O Route 15 |
| Route 15 | 90 × 27 | E Route 14 · O Parmanie ; poste au milieu |
| Route 16 ouest | prolonge la grille du J21 (60 × 27 au total) | E poste 16 (voie basse et voie haute) · S Route 17 (voie basse) |
| Route 17 | 30 × 150 | N Route 16 ouest · S Route 18 ouest |
| Route 18 | 75 × 27 | N Route 17 · E Parmanie ; poste au milieu |
| Parmanie | 60 × 54 | O Route 18 · E Route 15 · S mer (bord fermé) · N entrée du Parc Safari (J23) |

Les grilles `tools/plans/*.txt` du lot 22.0 **feront foi**. Règles du monde : angles droits, « nature
dense, objets rares » (dossiers 01 et 07).

## 5. Le Ronflex de la Route 12 [M-3]

- Le Ronflex « est » du J21 est placé **sur la carte de la Route 12, au croisement** (RB : Route 12,
  case (10, 62)). Le croisement est réduit à **2 cases de large** [D] pour que ses 2 × 2 cases le
  ferment dans les deux sens.
- **Avant la Flûte** : depuis Lavanville, la Route 12 nord est un cul-de-sac avec Ronflex en vue ;
  depuis Carmin, la Route 11 bute sur lui. La Route 12 sud n'est accessible par aucun côté.
- **Après** `snorlax_route_12_done` : boucle Carmin ↔ Route 11 ↔ Route 12 ↔ Lavanville, et accès sud.
- Réveil, combat et issues : **inchangés** (dossier 24 §9, L-11, L-12).
- **Fait par la session du J21** (confirmé par Kevin, `origin/jalon-21` `925ec9f3`, 2026-10-16) :
  grille `tools/plans/route_12.txt` (39 × 102) ; tronc nord x 25..26 ; **Ronflex `ronflex_12`** 2 × 2
  en (25..26, 93..94), `unless snorlax_route_12_done` ; bras ouest rangées 93..94, raccord
  (0, 93..94) ↔ Route 11 (75, 14..15) ; tronc sud x 25..26 de la rangée 95 au bord ; **bord sud
  `warp_sud` (25..26, 101)** `coming_soon=route_12_sud`, arrivée `from_route_12_sud` (25..26, 100) ;
  cases `face_ronflex` nord, ouest et sud ; panneau du ponton en (24, 95). Contrôle
  `tools/art/plan_check_j21.py`. Retrait du Ronflex de la Route 11 (J17) : T9 de `jalon-21.md`. Vue
  peinte `reference/route-12-vue-generale-v1.png` refaite.
- **Raccord du J22** : la Route 12 sud commence au bord `warp_sud` (25..26, 101) ; son arrivée nord
  est sur 2 cases de large, alignée sur x 25..26.

## 6. La Bicyclette [V décision 4, M-4 à M-7]

### 6.1 Obtention

1. **Fan Club de Carmin** : le président demande si l'on veut écouter l'histoire de son Ponyta.
   OUI → deux bulles d'histoire → il remet le **Bon de Commande** (`got_bike_voucher`). NON → il
   attend la prochaine fois. Remise **unique et idempotente**. Disponible dès la première visite pour
   les nouvelles parties ; une partie plus avancée le reçoit à la visite suivante (règle F-8 du J15).
2. **Boutique de Vélos d'Azuria** : avec le Bon, le vendeur l'échange contre la **Bicyclette**
   (`got_bicycle`) ; le Bon quitte le Sac. Sans le Bon : réplique existante (« Pour regarder. »).
   La Bicyclette n'est **jamais** donnée automatiquement.

### 6.2 Objets

| Objet | Catégorie | Description (Sac) |
|---|---|---|
| Bon de Commande | Objet clé, non utilisable | T-6 |
| Bicyclette | Objet clé, **utilisable** (`key_use`) | T-7 |

### 6.3 Règles

| Règle | Valeur | Origine |
|---|---|---|
| Monter / descendre | Sac → UTILISER, ou **bouton rond « Vélo »** du HUD (visible dès `got_bicycle`) | RB + K26 |
| Vitesse | **0,12 s par case** [D] (marche 0,27 ; course 0,16) ; la Course n'agit pas à vélo | RB (× 2) |
| Lieux permis | Extérieurs et grottes | RB |
| Intérieurs | Interdit (T-3) ; entrer dans un bâtiment fait **descendre** automatiquement | RB |
| Rebords | Sautés à vélo | RB |
| Compagnon | Rentre dans sa Ball en montant, ressort en descendant (sans cinématique) | K26 |
| Combat | Le joueur reste en selle après un combat hors de la Piste [D] | RB |
| Musique | Thème du vélo, si produit (intention) | RB |
| Sauvegarde | `riding_bicycle` enregistré : on recharge en selle | RB |

### 6.4 La Piste Cyclable [M-13]

- **Tronçons de Piste** : voie basse de la Route 16 ouest, **Route 17**, partie ouest de la Route 18
  (jusqu'au poste). Sur ces tronçons, **on ne peut pas descendre du vélo** (T-4).
- **Postes 16 et 18** : à pied à l'intérieur (règle des intérieurs). Le garde côté Piste vérifie la
  Bicyclette : sans elle, refus (T-1, le joueur recule d'une case) ; avec elle, T-2 la première fois
  [D], et le joueur **sort en selle** côté Piste. En sortant côté ville, il reste à pied.
- **Pente (Route 17 seulement)** : sans appui et sans Dresseur qui le voit, le joueur avance **d'une
  case vers le bas** au rythme du vélo. Gauche, droite et **remonter** restent libres. Aucune dérive
  pendant un dialogue, un combat ou une cinématique.
- **Paliers** [D : 3] : bandes horizontales sans pente (bancs, panneau, herbes), où le joueur
  s'arrête naturellement. Les Dresseurs de la Piste se tiennent **en retrait** des voies.
- **Aucun chrono**, aucun mini-jeu, aucun compteur.

## 7. La pêche [V décision 3, M-8 à M-11]

### 7.1 Les trois cannes (RB)

| Canne | Donneur | Lieu | Drapeau |
|---|---|---|---|
| Canne | Le pêcheur de Carmin, à la visite suivante (V-4 du J15) | Carmin | `got_old_rod` |
| Super Canne | Son frère | Parmanie, maison de la Super Canne | `got_good_rod` |
| Méga Canne | Son autre frère | Route 12 sud, maison de la Méga Canne | `got_super_rod` |

Toutes les remises sont idempotentes. Sur le chemin est, la Méga Canne arrive **avant** la Super
Canne (comme RB) : chacune garde sa table.

### 7.2 Où

- Cases d'eau marquées **« pêchable »** dans les grilles (berges, pontons, quais) : nouvelles cartes
  et cartes déjà livrées (Carmin, Azuria, Routes 6, 11, 24, 25) [M-8].
- Le joueur se tient sur une case praticable, **face** à la case d'eau pêchable.

### 7.3 Déroulé (RB, sans mini-jeu)

1. Action face à l'eau, avec au moins une canne : la **meilleure** est utilisée [M-9]. (Sans canne :
   rien, comme aujourd'hui.)
2. Le compagnon rentre dans sa Ball (cinématique courte) ; pose « lancer » du joueur, T-12.
3. Attente de **1 à 2 secondes** [D], bulle « ! » existante.
4. Touche → T-13 → **combat sauvage ordinaire**, fond `route_12_ponton` [M-11] ; sinon T-14.
5. Ailleurs (pas d'eau pêchable devant), via le Sac : T-15.

### 7.4 Tables (terrain `water_rod`)

| Canne | Portée | Chance de touche | Contenu (RB) |
|---|---|---|---|
| Canne | Globale | **100 %** | Magicarpe N5 |
| Super Canne | Globale | **50 %** | Poissirène N10 (50 %), Ptitard N10 (50 %) |
| Méga Canne | Par carte | **75 %** [D] | Routes 12, 13, 18 et **défaut** (RB Groupe 7) : Tentacool N5, Krabby N15, Poissirène N15, Magicarpe N15 (25 % chacun) · Parmanie (RB Groupe 10) : Poissoroy N23, Krabby N15, Poissirène N15, Magicarpe N15 |

Aucune espèce sans données, capacités et dos de combat ne peut sortir d'une table (test dédié).

## 8. Les routes

### 8.1 Route 12 sud

- Suite de la Route 12 du J21 au sud du croisement (Ronflex). Ponton et **berges pêchables**,
  **maison de la Méga Canne**, herbes hautes au sud, virage vers la Route 13.
- Dresseurs : Pêcheur, Jeune Dresseur, Rockeur (§9.1).
- Objets : Pépite (à la place du Fer, M-16) ; Hyper Potion cachée.

### 8.2 Route 13

- Labyrinthe ouvert de **clôtures** blanches (plusieurs passages, aucun cul-de-sac obligatoire),
  herbes hautes, berge pêchable au nord.
- Dresseurs : 7 (§9.2). Objets cachés : Super Bonbon (PP Plus), Hyper Potion (Calcium).

### 8.3 Route 14

- Couloir nord-sud bordé d'arbres, herbes hautes, Ornithologues et Motards sur les côtés.
- Dresseurs : 7 (§9.3).

### 8.4 Route 15 et son poste

- Plaine ouest-est, **poste** au milieu (deux portes, à pied), CT20 au bout d'un détour.
- **Poste, 2F** (modèle de poste du J21) : assistant du Prof. Chen **sans cadeau** (T-40), jumelles
  (T-41).
- Dresseurs : 7 (§9.4).

### 8.5 Route 16 ouest et son poste [M-18]

- **Poste 16** : deux voies. **Voie basse** : garde de la Piste (§6.4) → Route 16 ouest, voie basse
  (Piste) → Route 17. **Voie haute** : passage à pied → partie haute de la Route 16 ouest.
- **Arbre** de la voie haute (cases du J21) : devient **coupable** (`cut_route_16_tree`). Derrière,
  la voie haute est (J21) rejoint la porte haute du poste.
- **Voie haute ouest** : herbes, vue sur la Piste en contrebas, **1 objet caché** (Hyper Potion [D]),
  **maison de Vol** dont la porte est réservée au J23 (`coming_soon`).
- Dresseurs : 5 sur la voie basse (§9.5).

### 8.6 Route 17 — la Piste Cyclable [M-13]

- Longue descente nord-sud, voies parallèles séparées par des barrières basses, **3 paliers** [D]
  (bancs, panneau, herbes), **mer à l'ouest** (décor). Pas de pêche sur la Piste [D] (on ne peut pas
  descendre du vélo).
- Dresseurs : 8, en retrait (§9.6). Objets cachés : 5 (§11).

### 8.7 Route 18 et son poste

- **Ouest** (Piste, en selle) : sortie de la Route 17, 3 Ornithologues, berge pêchable [D : depuis
  la partie est seulement].
- **Poste 18** (à pied) : garde de la Piste côté ouest.
- **Est** (à pied) : jusqu'à Parmanie. Un joueur arrivé par l'est peut aller jusqu'au poste ; le
  garde le refuse sans Bicyclette.

### 8.8 Rencontres (herbes, RB version Rouge, Métamorph retiré)

| Lieu | Taux [D] | Créneaux (niveaux RB) |
|---|---|---|
| Route 12 sud | RB | Mystherbe 22–26, Roucool 23–27, Aéromite 24–26, Boustiflor 28–30 |
| Route 13 | RB | Mystherbe 22–26, Roucool 25–27, Aéromite 24–26, Boustiflor 28–30 (créneau de Métamorph → Roucool) |
| Route 14 | RB | Mystherbe 22–26, Roucool 26, Aéromite 24–26, Boustiflor 30, Chétiflor 24 (Métamorph → Aéromite) |
| Route 15 | RB | Mystherbe 22–26, Roucool 23, Aéromite 26–28, Boustiflor 30, Chétiflor 24 (Métamorph ×2 → Roucool, Aéromite) |
| Route 16 ouest | RB | Piafabec 20–22, Rattata 18–22, Doduo 18–22, Rattatac 23–25 |
| Route 17 | RB | Piafabec 20–22, Rattatac 25–29, Doduo 24–28, Rapasdepic 25–27 |
| Route 18 | RB | Piafabec 20–22, Rattatac 25–29, Doduo 24–28, Rapasdepic 25–29 |

Pondérations : celles de RB (`data/wild/probabilities.asm`), adaptées au format `slots` existant.

## 9. Dresseurs [V décision 5, M-14, M-15, M-21]

40 Dresseurs (RB : 56). Équipes et niveaux **RB**, IA `random` sauf mention, argent
`prize_per_level` par classe [D]. Portée de vue = RB × 1,5. **(I)** = inévitable (au plus un par
route). Les répliques sont au §16.4.

### 9.1 Route 12 sud (3)

| Id | Classe | Équipe |
|---|---|---|
| `route_12_fisher_5` | Pêcheur | Magicarpe 24, Magicarpe 24 |
| `route_12_youngster` | Jeune Dresseur | Nidoran♂ 29, Nidorino 29 |
| `route_12_rocker` | Rockeur | Voltorbe 29, Électrode 29 (I) |

### 9.2 Route 13 (7)

| Id | Classe | Équipe |
|---|---|---|
| `route_13_bird_1` | Ornithologue | Roucool 29, Roucoups 29 |
| `route_13_lass_1` | Jeune Dresseuse | Ptitard 30, Ptitard 30 |
| `route_13_lass_2` | Jeune Dresseuse | Roucool 27, Miaouss 27, Roucool 27, Roucoups 27 |
| `route_13_lass_3` | Jeune Dresseuse | Poissirène 28, Ptitard 28, Hypotrempe 28 (I) |
| `route_13_beauty` | Beauté | Mélofée 29, Miaouss 29 |
| `route_13_biker` | Motard | Smogo 28, Smogo 28, Smogo 28 |
| `route_13_bird_2` | Ornithologue | Roucool 26, Roucoups 26, Piafabec 26, Rapasdepic 26 |

### 9.3 Route 14 (7)

| Id | Classe | Équipe |
|---|---|---|
| `route_14_bird_1` | Ornithologue | Canarticho 33 |
| `route_14_bird_2` | Ornithologue | Piafabec 29, Rapasdepic 29 |
| `route_14_bird_3` | Ornithologue | Roucool 28, Doduo 28, Roucoups 28 (I) |
| `route_14_bird_4` | Ornithologue | Roucoups 29, Rapasdepic 29 |
| `route_14_biker_1` | Motard | Smogo 29, Tadmorv 29 |
| `route_14_biker_2` | Motard | Smogo 29, Grotadmorv 29 |
| `route_14_biker_3` | Motard | Tadmorv 28, Tadmorv 28, Smogo 28 |

### 9.4 Route 15 (7)

| Id | Classe | Équipe |
|---|---|---|
| `route_15_lass_1` | Jeune Dresseuse | Boustiflor 28, Mystherbe 28, Mystherbe 28 |
| `route_15_lass_2` | Jeune Dresseuse | Mélofée 33 |
| `route_15_lass_3` | Jeune Dresseuse | Chétiflor 29, Mystherbe 29, Saquedeneu 29 |
| `route_15_beauty_1` | Beauté | Bulbizarre 29, Herbizarre 29 |
| `route_15_beauty_2` | Beauté | Roucoups 29, Grodoudou 29 |
| `route_15_bird` | Ornithologue | Dodrio 28, Doduo 28, Doduo 28 (I) |
| `route_15_biker` | Motard | Smogo 28, Tadmorv 28, Smogogo 28 |

### 9.5 Route 16 ouest, voie basse (5)

| Id | Classe | Équipe |
|---|---|---|
| `route_16_biker_1` | Motard | Tadmorv 29, Smogo 29 |
| `route_16_cueball_1` | Loubard | Machoc 28, Férosinge 28, Machoc 28 |
| `route_16_cueball_2` | Loubard | Férosinge 29, Machoc 29 |
| `route_16_biker_2` | Motard | Smogogo 33 (I) |
| `route_16_cueball_3` | Loubard | Machoc 33 |

### 9.6 Route 17 (8)

| Id | Classe | Équipe |
|---|---|---|
| `route_17_cueball_1` | Loubard | Férosinge 29, Colossinge 29 |
| `route_17_cueball_2` | Loubard | Machoc 29, Machopeur 29 |
| `route_17_biker_1` | Motard | Smogogo 28, Smogo 28, Smogogo 28 |
| `route_17_biker_2` | Motard | Grotadmorv 33 (I) |
| `route_17_biker_3` | Motard | Voltorbe 29, Voltorbe 29 |
| `route_17_cueball_3` | Loubard | Machopeur 33 |
| `route_17_biker_4` | Motard | Smogogo 29, Grotadmorv 29 |
| `route_17_cueball_4` | Loubard | Colossinge 29, Machopeur 29 |

### 9.7 Route 18 ouest (3)

| Id | Classe | Équipe |
|---|---|---|
| `route_18_bird_1` | Ornithologue | Piafabec 29, Rapasdepic 29 |
| `route_18_bird_2` | Ornithologue | Dodrio 34 (I) |
| `route_18_bird_3` | Ornithologue | Piafabec 26, Piafabec 26, Rapasdepic 26, Piafabec 26 |

**Capacités** : apprises au niveau (jeux RB), réglées à la main seulement si le moteur l'exige.
**Équilibrage** : niveaux RB gardés ; la simulation de 22.0 vérifie qu'une équipe de niveau 30–34
traverse chaque chemin sans soin forcé. Si un seuil est dépassé, on retire un Pokémon, jamais un
niveau [D].

## 10. Parmanie [V décision 6, M-19, M-20]

### 10.1 Plan

Ville basse, verte et ouverte : allées, arbres, étang [D, pêchable], **enclos** au nord-est, entrée
du Parc Safari au nord, Arène au sud-ouest, mer au sud (bord fermé). Panneau d'entrée à l'est et à
l'ouest.

### 10.2 Bâtiments

| Bâtiment | État au J22 | Contenu |
|---|---|---|
| Centre Pokémon | Ouvert | Modèle existant ; 1 PNJ (T-50) |
| Boutique | Ouverte | Hyper Ball, Super Ball, Super Potion, Hyper Potion, Total Soin (si l'objet existe, sinon Antidote) [D] ; 1 PNJ (T-51) |
| Maison de la Super Canne | Ouverte | Le frère du pêcheur (T-30 à T-33) |
| Salle de réunion | Ouverte | Club du Parc Safari : président et membre (T-52, T-53) ; annonce le Safari sans l'ouvrir |
| Maison du grand-père | Ouverte | Un vieil homme et ses souvenirs de pêche [D] (T-54) |
| Arène de Koga | **Porte réservée au J23** | Façade, panneau (T-55) |
| Parc Safari | **Porte réservée au J23** | Bâtiment d'entrée, panneau (T-56) |
| Maison du Gardien | **Porte réservée au J23** | Façade seulement |

Fermeture des portes réservées : mécanisme `coming_soon` existant [D].

### 10.3 Habitants et enclos

- 4 PNJ extérieurs [D] : un garçon qui parle du Safari (T-57), un joueur (T-58), un pêcheur assis
  (T-59), une femme près des enclos (T-60).
- **Enclos** [M-20] : **Kangourex** et **Ramoloss** peints dans le monde, avec une courte routine ;
  examen → T-61, T-62. Les autres enclos ont un **panneau** : Leveinard, Lokhlass, Voltorbe, fossile
  (T-63 à T-66). Ces Pokémon sont **décor** : ni combat, ni Pokédex « vu ».

## 11. Objets [M-16]

| Lieu | Objet (RB → K26) | Type | Drapeau [D] |
|---|---|---|---|
| Route 12 sud | Fer → **Pépite** | Visible | `got_route_12_item_1` |
| Route 12 sud | Hyper Potion | Caché | `got_route_12_hidden_1` |
| Route 13 | PP Plus → **Super Bonbon** | Caché | `got_route_13_hidden_1` |
| Route 13 | Calcium → **Hyper Potion** | Caché | `got_route_13_hidden_2` |
| Route 15 | **CT20** (Frénésie si sa règle tient dans le moteur, sinon une CT existante, choisie en 22.0) | Visible | `got_route_15_item_1` |
| Route 16, voie haute | Hyper Potion (K26) | Caché | `got_route_16_hidden_1` |
| Route 17 | Super Bonbon | Caché | `got_route_17_hidden_1` |
| Route 17 | Guérison | Caché | `got_route_17_hidden_2` |
| Route 17 | PP Plus → **Pépite** | Caché | `got_route_17_hidden_3` |
| Route 17 | Rappel Max → **Guérison** | Caché | `got_route_17_hidden_4` |
| Route 17 | Max Élixir → **Pépite** | Caché | `got_route_17_hidden_5` |

Objets **créés par données** (aucune mécanique nouvelle) : **Hyper Potion** (soigne 200 PV, RB),
**Hyper Ball** (bonus de capture × 2, RB), Bon de Commande, Bicyclette, Canne, Super Canne, Méga
Canne. Les objets cachés de la Route 17 se ramassent **à vélo** (Action face à la case, la dérive
s'interrompt).

## 12. Espèces et capacités

### 12.1 Espèces à créer (12)

| Pour | Espèces |
|---|---|
| Pêche et herbes | Magicarpe (129), Krabby (098), Poissoroy (119), Aéromite (049), Doduo (084) |
| Dresseurs | Dodrio (085), Canarticho (083), Tadmorv (088), Grotadmorv (089), Smogogo (110), Électrode (101), Machopeur (067) |

Évolutions entre elles et vers l'existant : Magicarpe → Léviator (20, J19), Doduo → Dodrio (31),
Tadmorv → Grotadmorv (38), Smogo → Smogogo (35), Voltorbe → Électrode (30), Machoc → Machopeur (28),
Krabby → Krabboss (28, **hors J22** : évolution coupée tant que Krabboss n'existe pas [D]), Poissirène
→ Poissoroy (33), Aéromite : déjà évolution de Mimitoss (absent, sans effet).

### 12.2 Espèces venues d'autres jalons (fusion)

Ptitard, Tentacool, Ronflex (J21, `j21-t5-donnees`) ; Saquedeneu, Kangourex (J20) ; Léviator (J19).

### 12.3 Capacités

Les capacités apprises par ces espèces jusqu'au niveau 35 qui manquent dans les données sont créées
en 22.0 **si leur effet existe déjà dans le moteur** ; sinon remplacées par la plus proche du même
type et de la même catégorie [D], liste soumise avec le plan. Magicarpe : Trempette (aucun effet) et
Charge.

## 13. Données, drapeaux et sauvegarde

Tout passe par le magasin de drapeaux existant : **sauvegarde v7 inchangée**.

| Drapeau | Posé par |
|---|---|
| `got_bike_voucher` | Président du Fan Club (après l'histoire) |
| `got_bicycle` | Vendeur d'Azuria (échange) |
| `riding_bicycle` | Montée / descente ; remis à faux en entrant dans un intérieur |
| `got_old_rod`, `got_good_rod`, `got_super_rod` | Les trois pêcheurs |
| `snorlax_route_12_woken` / `_caught` / `_done` | J21 (M-3) |
| `cut_route_16_tree` | Coupe |
| `cycling_gate_16_greeted`, `cycling_gate_18_greeted` | Première réplique T-2 [D] |
| `beaten_<id>`, `lost_<id>` | Dresseurs (§9) |
| `got_<carte>_item_N`, `got_<carte>_hidden_N` | Objets (§11) |

Fichiers de données nouveaux [D] : `data/trainers/route_12_sud.json` … `route_18.json`,
`data/encounters/route_12_sud.json` … `parmanie.json`, `data/encounters/water_rod.json` (tables
globales et défaut), `data/items/items_j22.json`, `data/pokemon/species/kanto_j22.json`,
`data/dialogues/*.json` par carte.

## 14. Tableau de bord, Pokédex, Carte

- **Tableau de bord** : aucun objectif nouveau [M-22].
- **Pokédex** : espèces vues et capturées comme d'habitude (y compris à la pêche) ; les Pokémon des
  enclos ne comptent pas.
- **Carte** : zones Routes 12 à 18 et Parmanie ajoutées (`zones.json`, Parmanie existe déjà sans
  carte) ; Parc Safari non affiché avant le J23 [D].

## 15. Art et assets (lot 22.0)

| Poste | Contenu |
|---|---|
| Joueur | **Planche « vélo »** (4 directions, arrêt + pédalage) ; **planche « pêche »** (4 directions, lancer + attente) |
| PNJ | Pêcheur, Motard, Ornithologue, Loubard ; les trois frères pêcheurs (Pêcheur décliné [D]) ; président du club du Safari ; vieil homme |
| Pokémon du monde | Kangourex, Ramoloss (enclos, routine courte) |
| Dos de combat | 12 espèces nouvelles (chaîne X/Y repeinte ; Magicarpe a déjà un prototype) |
| Fonds de combat CB.3 | `route_12_ponton` (eau, sert aussi à la pêche), `route_13_15_prairie`, `route_16_18_piste`, `parmanie_ville` |
| Vues générales peintes | Route 12 sud, Routes 13 à 18, Parmanie (avec plans), puis intérieurs : postes 15, 16, 18 (modèle commun), maisons des cannes, Salle de réunion, maison du grand-père |
| HUD | Bouton rond « Vélo » (thème 2026, skill `ui-theme-2026`) |

DA : 2D HD peinte, vue de dessus orthogonale, quatre directions ; ni pixel art, ni isométrie, ni
minicarte.

## 16. Lot de textes — À VALIDER

> Rédigés par Claude le 2026-10-16. Ton : sobre, chaleureux. Bulles de 2 lignes d'environ 40
> caractères ; « / » sépare les bulles. `{player}`, `{pokemon}`, `{n}` sont des jetons. Le joueur est
> tutoyé. Aucun tutoriel : les PNJ parlent comme des personnes, pas comme un manuel.

### 16.1 Vélo et Piste

1. *(garde, sans vélo)* « Désolé ! La Piste Cyclable / est réservée aux vélos. »
2. *(garde, avec vélo, première fois)* « La Piste descend jusqu'à Parmanie. / Bonne route, et gare aux Motards ! »
3. *(vélo en intérieur)* « Ce n'est pas le moment de pédaler ! »
4. *(descendre sur la Piste)* « Pas de marche à pied / sur la Piste Cyclable ! »
5. *(monter / descendre, si un message est jugé utile [D : aucun message, l'animation suffit])* —
6. *(Bon de Commande, Sac)* « Un bon à échanger contre une Bicyclette à la boutique d'Azuria. »
7. *(Bicyclette, Sac)* « Une bicyclette pliante. Elle va deux fois plus vite que la marche. »
8. *(président, question)* « Tu es venu écouter l'histoire / de mon Ponyta ? » OUI / NON
9. *(président, OUI)* « Il galopait plus vite que le vent ! / Et sa crinière, quelle merveille… » / « Ah, tu m'as fait plaisir ! / Tiens, prends ça. Je n'en ai pas l'usage. »
10. *(système)* « {player} reçoit un Bon de Commande ! »
11. *(président, NON)* « Oh… Une autre fois, alors. »
12. *(président, ensuite)* « Mon Ponyta te passe le bonjour ! »
13. *(vendeur d'Azuria, avec le Bon)* « Oh ! Un Bon de Commande ! / Il vient du président du Fan Club ? » / « Alors elle est à toi. / Prends-en soin ! »
14. *(système)* « {player} échange le Bon contre une Bicyclette ! »
15. *(vendeur, ensuite)* « Alors, cette Bicyclette ? / Elle roule bien, hein ? »
16. *(panneau, Route 17)* « PISTE CYCLABLE / Céladopole ↕ Parmanie »
17. *(panneau, palier)* « Halte ! Reprends ton souffle. / La descente continue plus bas. »

### 16.2 Pêche

1. *(pêcheur de Carmin, remise)* « Ah, te voilà ! J'avais promis. / Voici ma vieille Canne. »
2. *(système)* « {player} reçoit la Canne ! »
3. *(pêcheur de Carmin)* « La pêche, c'est de la patience. / Et un peu de chance ! »
4. *(pêcheur de Carmin, ensuite)* « Alors, ça mord ? »
5. *(Canne, Sac)* « Une vieille canne à pêche. Avec elle, on pêche près des berges. »
6. *(Super Canne, Sac)* « Une bonne canne à pêche. Les Pokémon y mordent plus volontiers. »
7. *(Méga Canne, Sac)* « La meilleure canne à pêche. Elle attire des Pokémon rares. »
8. *(lancer)* « {player} lance sa ligne… »
9. *(touche)* « Oh ! Ça mord ! »
10. *(rien)* « Rien ne mord… »
11. *(pas d'eau pêchable)* « On ne peut pas pêcher ici. »

### 16.3 Les frères pêcheurs

1. *(Méga Canne, Route 12 sud)* « Je suis le cadet d'une famille / de pêcheurs. Tu pêches, toi ? » / « Prends ma Méga Canne. / Elle fait mordre les plus rares. »
2. *(système)* « {player} reçoit la Méga Canne ! »
3. *(ensuite)* « Mes frères pêchent à Carmin / et à Parmanie. Tu les as vus ? »
4. *(Super Canne, Parmanie)* « Mon frère de Carmin t'a appris ? / Alors prends ma Super Canne ! »
5. *(système)* « {player} reçoit la Super Canne ! »
6. *(ensuite)* « Ici, on pêche même dans l'étang. / Essaie, tu verras ! »

### 16.4 Dresseurs

| Classe | Avant | Défaite | Après |
|---|---|---|---|
| Pêcheur (12) | « Chut ! Tu vas faire fuir les poissons ! » | « Ils mordent, mais pas assez fort… » | « Rien de tel qu'une journée au bord de l'eau. » |
| Jeune Dresseur (12) | « Mon Nidorino est presque prêt. / Je vais te le prouver ! » | « Presque prêt… pas tout à fait. » | « Un jour, il évoluera encore. Tu verras ! » |
| Rockeur (12) | « Ma musique fait des étincelles. / Et mes Pokémon aussi ! » | « Court-circuit ! » | « Je retourne répéter. » |
| Ornithologue (13-1) | « Mes oiseaux connaissent le vent / mieux que personne ! » | « Ils ont perdu le cap… » | « Les oiseaux reviennent toujours. » |
| Jeune Dresseuse (13-1) | « Mes Ptitard adorent nager. / Et se battre ! » | « Ils sont tout mouillés… » | « Je vais les sécher au soleil. » |
| Jeune Dresseuse (13-2) | « Tu tournes en rond dans ces clôtures ? / Moi aussi ! Combattons ! » | « Je suis encore plus perdue… » | « La sortie ? Par là, je crois… » |
| Jeune Dresseuse (13-3) | « Tous mes Pokémon viennent de l'eau. / Tu sauras t'y prendre ? » | « Tu t'y prends très bien. » | « Je retourne au bord de l'eau. » |
| Beauté (13) | « Un combat ? Volontiers. / Mais sans abîmer mes Pokémon ! » | « Oh ! Quelle force ! » | « Il faudra que je m'entraîne aussi. » |
| Motard (13) | « Hé, toi ! T'as rien à faire / sur notre route ! » | « Ouais, bon… T'es pas mauvais. » | « Va voir sur la Piste si on y est. » |
| Ornithologue (13-2) | « Quatre oiseaux, quatre vents ! » | « Tous au tapis… » | « Je vais devoir les reposer. » |
| Ornithologue (14-1) | « Mon Canarticho ne quitte jamais / son poireau. Ni le combat ! » | « Il a perdu son poireau… » | « Il en trouvera un autre. » |
| Ornithologue (14-2 à 14-4) | « Le ciel est à nous ! » | « Atterrissage forcé ! » | « On reprendra de l'altitude. » |
| Motard (14-1 à 14-3) | « Tu sens cette odeur ? / C'est mon équipe ! » | « Pfff… Ça sent la défaite. » | « La prochaine fois, on t'enfume. » |
| Jeune Dresseuse (15-1, 15-3) | « Mes plantes ont poussé / tout l'été pour ce combat ! » | « Elles ont fané… » | « Je vais les arroser. » |
| Jeune Dresseuse (15-2) | « Mon Mélofée est le plus mignon. / Et le plus fort ! » | « Le plus mignon, en tout cas. » | « Il dort déjà… » |
| Beauté (15-1) | « J'ai gardé mes premiers Pokémon. / Ils ont grandi avec moi. » | « Ils ont fait de leur mieux. » | « Je ne les échangerai jamais. » |
| Beauté (15-2) | « Grodoudou chante si bien… / Tu veux l'entendre ? » | « Fin du concert ! » | « Il chantera encore ce soir. » |
| Ornithologue (15) | « Trois têtes valent mieux qu'une ! » | « Elles n'étaient pas d'accord… » | « Les Doduo courent plus qu'ils ne volent. » |
| Motard (15) | « On roule, on fume, on gagne ! » | « On roule, on fume, on perd… » | « Bon. On roule. » |
| Motard (16-1, 16-2) | « La Piste, c'est notre territoire ! » | « Hé ! Doucement ! » | « D'accord, d'accord. Passe. » |
| Loubard (16, 17) | « Tu cherches la bagarre ? / Tu l'as trouvée ! » | « Aïe… Ça cogne ! » | « Toi, t'as de la poigne. » |
| Motard (16-2, inévitable) | « Personne ne passe sans m'affronter ! » | « Bon. Toi, tu passes. » | « Roule, et ne te retourne pas. » |
| Motard (17) | « T'as vu cette descente ? / On la dévale tous les jours ! » | « Sortie de route ! » | « Fais gaffe dans les virages. » |
| Ornithologue (18) | « Du haut de la Piste, / on voit les oiseaux de mer. » | « Ils se sont envolés… » | « Parmanie est juste à l'est. » |

**Nom de la classe Cue Ball** : « Loubard » [D] (à confirmer ; autres possibilités : « Costaud »,
« Casseur »).

### 16.5 Postes et routes

1. *(panneau, Route 12 sud)* « ROUTE 12 / Nord : Lavanville »
2. *(panneau, Route 13)* « ROUTE 13 / Attention aux clôtures ! »
3. *(panneau, Route 14)* « ROUTE 14 »
4. *(panneau, Route 15)* « ROUTE 15 / Ouest : Parmanie »
5. *(panneau, Route 16)* « ROUTE 16 / Céladopole ↔ Piste Cyclable »
6. *(panneau, Route 18)* « ROUTE 18 / Est : Parmanie »
7. *(assistant, poste 15, 2F)* « Je travaille pour le Prof. Chen. / Ton Pokédex en est à {n} espèces ! » / « Continue ! Chaque Pokémon / a quelque chose à t'apprendre. »
8. *(jumelles, poste 15)* « Au loin, on voit Parmanie / et la mer qui scintille. »
9. *(maison de Vol, porte réservée, examen [D])* « Personne ne répond. »
10. *(arbre, Route 16)* : textes existants de la Coupe (J16).

### 16.6 Parmanie

1. *(panneau d'entrée)* « PARMANIE / Ville ouverte sur la nature »
2. *(PNJ, Centre)* « Les Dresseurs viennent de loin / pour le Parc Safari. »
3. *(PNJ, Boutique)* « Les Hyper Balls, c'est cher. / Mais ça vaut le coup ! »
4. *(président du club)* « Bienvenue au club du Parc Safari ! / Nous aimons les Pokémon rares. »
5. *(membre du club)* « Au Safari, on ne combat pas. / On attrape, et c'est tout ! »
6. *(vieil homme)* « J'ai pêché dans toutes les eaux / de Kanto. La mer, ici, est la plus belle. »
7. *(panneau, Arène)* « ARÈNE DE PARMANIE / Champion : Koga »
8. *(panneau, Parc Safari)* « PARC SAFARI / Des Pokémon rares vous attendent ! »
9. *(garçon)* « Le Parc Safari, c'est au nord. / Il paraît qu'on y voit des Pokémon rares ! »
10. *(joueur)* « Koga ? Un vrai ninja, à ce qu'on dit. / Personne ne le voit venir. »
11. *(pêcheur assis)* « L'étang est calme aujourd'hui. »
12. *(femme des enclos)* « Ces Pokémon viennent du Parc Safari. / On les montre aux visiteurs. »
13. *(Kangourex, examen)* « Kangourex garde son petit bien au chaud. »
14. *(Ramoloss, examen)* « Ramoloss bâille… et oublie pourquoi. »
15. *(panneau, Leveinard)* « LEVEINARD / Un Pokémon rare, très doux. »
16. *(panneau, Lokhlass)* « LOKHLASS / Il aime transporter les gens sur l'eau. »
17. *(panneau, Voltorbe)* « VOLTORBE / Ne pas confondre avec une Poké Ball ! »
18. *(panneau, fossile)* « FOSSILE / Un Pokémon d'avant l'histoire. »

### 16.7 Objets et système

1. *(Hyper Potion, Sac)* « Un spray de soin. Il restaure 200 PV d'un Pokémon. »
2. *(Hyper Ball, Sac)* « Une Ball très performante. Elle capture mieux qu'une Super Ball. »
3. *(Pokédex, Magicarpe)* reprise de la fiche officielle, réécrite au ton du projet en 22.0 [D] (même
   règle pour les 12 espèces).

## 17. Cas limites (à couvrir au plan technique)

| Cas | Comportement |
|---|---|
| Sauvegarde sur la Piste | Rechargée **en selle**, compagnon rentré. Si `riding_bicycle` manque, on remet le joueur en selle sur un tronçon de Piste. |
| Défaite sur la Piste | Retour au dernier Centre, à pied. |
| Arrivée à Parmanie par l'est sans vélo | Route 18 est accessible à pied jusqu'au poste ; refus du garde (T-16.1.1), recul d'une case. |
| Vélo dans une grotte, puis entrée dans un intérieur | Descente automatique (`riding_bicycle` à faux). |
| Pêche avec le compagnon sorti | Il rentre pendant la pêche, ressort après (ou reste rentré si le joueur est à vélo). |
| Pêche pendant la dérive | Impossible : pas de pêche sur la Piste. |
| Dresseur qui voit le joueur sur la pente | La dérive s'arrête ; combat ; reprise de la pente après. |
| Objet caché sur la Piste | Action face à la case : la dérive s'interrompt, l'objet est ramassé. |
| Ronflex fuit ou bat le joueur | Il se rendort, le passage reste fermé (L-11). |
| Bon de Commande pour une partie avancée | Remis à la prochaine visite au Fan Club (F-8). |
| Bicyclette sans Bon (sauvegarde ancienne) | Impossible : seule la Boutique donne la Bicyclette. |
| Équipe pleine après une capture à la pêche | Stockage (règle existante). |
| Espèce sans données dans une table | Refusée par un test ; jamais tirée en jeu. |
| Portes `coming_soon` en build de sortie | Comportement existant des bords « À venir ». |
| Safrania | Aucun poste de garde ne lit un drapeau du J22 (test). |

## 18. Découpage et validation S24 [M-24]

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **22.0** | Grilles (Routes 12 sud à 18, Parmanie, postes, maisons), vues générales peintes, données (12 espèces, capacités, objets, 40 Dresseurs, rencontres, `water_rod`), logique pure testée sans scène (`BikeRules`, `CyclingSlope`, `FishingRules`), art (planches, dos, fonds CB.3, bouton HUD), textes validés | Tests, captures, planches à valider par Kevin |
| **22A** « le chemin des pêcheurs » | Route 12 sud, Routes 13, 14, 15 et poste ; Canne à Carmin, Méga Canne ; **pêche** (cartes nouvelles et anciennes) | S24 |
| **22B** « la Piste » | Bon de Commande, Bicyclette, **mode vélo** et bouton HUD ; poste 16, Route 16 ouest, arbre, voie haute ; Route 17 (**pente**, paliers) ; Route 18 et poste | S24 |
| **22C** « Parmanie » | Ville, intérieurs, Super Canne, enclos, portes réservées ; raccords des deux chemins ; QA de bout en bout (Parmanie par l'est puis par l'ouest) ; équilibrage ; clôture | S24 |

22A peut précéder 22B ou l'inverse : les deux chemins sont indépendants. Les cartes de 22A à 22C
attendent la branche d'intégration J15 → J21 (M-2).

## 19. Valeurs par défaut (règle 4)

| Sujet | Valeur |
|---|---|
| Vitesse à vélo | 0,12 s par case |
| Chance de touche | Canne 100 %, Super Canne 50 %, Méga Canne 75 % |
| Attente avant la touche | 1 à 2 s |
| Paliers de la Route 17 | 3 |
| Tailles des grilles | §4 |
| Poste 16 et 18 | 1 niveau, sans 2F |
| Stock de la Boutique de Parmanie | §10.2 |
| Objets de remplacement | §11 |
| Nom de la classe Cue Ball | « Loubard » |
| Drapeaux | §13 |
| Krabby | Évolution coupée tant que Krabboss n'existe pas |

## Décisions verrouillées

| Élément | Décision |
|---|---|
| Périmètre | Routes 12 à 18 et Parmanie ; Safari, Koga, Gardien, maison de Vol au J23 |
| Ronflex « est » | Au croisement de la Route 12, ferme la Route 11 et la Route 12 sud |
| Vélo | Bon (Carmin, après l'histoire) → Bicyclette (Azuria) ; Sac ou bouton HUD ; 2 × la marche ; compagnon rentré |
| Piste | Routes 16 ouest (voie basse), 17, 18 ouest ; Vélo obligatoire ; pente sur la 17 avec paliers ; sans chrono |
| Pêche | Trois cannes (Carmin, Route 12 sud, Parmanie) ; meilleure canne d'office ; cases pêchables marquées ; tables RB |
| Dresseurs | 40, équipes RB, au plus un inévitable par route |
| Espèces | 12 nouvelles ; Métamorph reporté |
| Objets | Remplacés quand la mécanique manque ; Hyper Potion et Hyper Ball créées |
| Parmanie | Centre, Boutique, Super Canne, Salle de réunion, grand-père ouverts ; enclos Kangourex et Ramoloss |
| Sauvegarde | v7, drapeaux seulement |
| Découpage | 22.0, 22A, 22B, 22C ; trois validations S24 |
