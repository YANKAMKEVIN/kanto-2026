# Dossier 28 — Le secret du Manoir Pokémon : Manoir, Laboratoire et Arène de Cramois'Île (jalon 25)

> **Statut : arbitrages VALIDÉS par Kevin le 2026-10-16** (X-1 à X-24 selon les recommandations de
> `docs/design/passes/j25-v2-alignement.md`). **Textes du §16 à valider en un lot.** Grilles et vues
> peintes à venir. **Aucune ligne de code** avant le plan `docs/tech/jalon-25.md`.
>
> Sources : V2 de Kevin (`passes/j25-v2-chatgpt.md`), passe d'alignement (même dossier), relevé
> Rouge/Bleu `passes/j25-annexe-rb-cramois.md` (`pret/pokered`, Poképédia). Code audité :
> `origin/main` `440f9b17` (J15, sauvegarde v7) et `jalon-16` à `jalon-21`.
>
> Origine des règles : **RB** Rouge/Bleu · **G+** génération ultérieure · **K26** adaptation Kanto
> 2026 · **[D]** valeur par défaut (règle 4 de CLAUDE.md).

---

## 1. Décisions verrouillées

### 1.1 V2 (7 décisions, non rouvertes)

| # | Sujet | Décision |
|---|---|---|
| 1 | Périmètre | Manoir Pokémon complet + Laboratoire + Arène d'Auguste |
| 2 | Manoir | Quatre niveaux, statues, portes, trous, journaux |
| 3 | Mewtwo | Raconté par les journaux, fidèles à RB ; aucune apparition |
| 4 | Laboratoire | Échanges fixes et résurrection des fossiles |
| 5 | Arène | Six quiz historiques, ou combats au choix |
| 6 | Auguste | Caninos 42, Ponyta 40, Galopa 42, Arcanin 47, capacités adaptées au moteur |
| 7 | Fin | Badge Volcan, exploration libre, aucun événement imposé |

### 1.2 Arbitrages de la passe (validés le 2026-10-16)

| N° | Décision |
|---|---|
| X-1 | Dossier 28, branche `docs/dossier-28-j25` |
| X-2 | 25.0 démarre tout de suite ; les cartes attendent une branche d'intégration qui contient le J24 |
| X-3 | **Vieil Ambre RB** : porte arrière du Musée d'Argenta derrière un arbre à Couper ; nom corrigé dans le dossier 12 |
| X-4 | Manoir et Arène à l'échelle RB **1:1** (1 case = 1 pas) |
| X-5 | **Un interrupteur global**, deux jeux de portes par étage ; remis à ARRÊT en entrant depuis l'île |
| X-6 | Nouveau `Warp` « chute » ; à partager avec la session du J24 |
| X-7 | Les 6 Dresseurs RB du Manoir, au plus un combat inévitable par étage |
| X-8 | Rencontres : union Rouge + Bleu, Magmar rare |
| X-9 | Objets RB, vitamines remplacées, Potion Max et Rappel Max en données, CT14 et CT22 si leurs capacités tiennent |
| X-10 | 1ᵉʳ journal : « une jungle lointaine », sans pays réel |
| X-11 | Lire les journaux ne change **pas** le Pokédex |
| X-12 | Clé Secrète gardée ; `cinnabar_gym_unlocked` au premier passage ; réparation de la Clé |
| X-13 | Salle R. et D. : scientifique **sans CT35** (Métronome hors J25) |
| X-14 | Mail du PC RB entier, « caverne près d'Azuria » comprise |
| X-15 | Échange sur place, même niveau, surnom VF RB, dresseur d'origine = nom du PNJ, ni bonus d'expérience ni désobéissance |
| X-16 | Fossiles : transaction du §7.3, niveau 30, un à la fois, sortie sur l'île = prêt |
| X-17 | Quiz : questions K26 du §16, sens et réponses RB |
| X-18 | Auguste : capacités RB, **Hurlement → Groz'Yeux** ; Déflagration et contrecoup de Bélier par données |
| X-19 | Badge Volcan sans bonus caché ; Grand moment ; CT38 unique |
| X-20 | Après la victoire, les sept Dresseurs de l'Arène sont marqués battus (RB) |
| X-21 | Niveaux RB ; simulation en 25.0 ; tout écart à la cible va à Kevin |
| X-22 | 14 dos peints dès 25.0 ; placeholders acceptés pour Lamantine, Kabutops, Amonistar si le pipeline bloque |
| X-23 | Planches PNJ : Pillard, Intello, Papi, Beauté, guide de l'Arène, Auguste (réutiliser l'existant) |
| X-24 | Découpage : **25.0**, **25A** Manoir, **25B** Laboratoire (validé seul), **25C** Arène et clôture |

---

## 2. Périmètre

| Dans le J25 | Réservé / plus tard | Hors J25 |
|---|---|---|
| Manoir 1F, 2F, 3F, B1F ; Laboratoire (hall + 3 salles) ; Arène ; porte à Clé ; réserve arrière du Musée d'Argenta et son arbre à Couper ; 14 espèces nouvelles ; Déflagration, Bélier (contrecoup), CT38 ; 2 fonds de combat | Métronome et CT35 ; Mimitoss (J22/J23) | Ville de Cramois'Île, Centre, Boutique, Surf, Routes 20–21, Îles Écume, Artikodin (J24) ; Giovanni (J26) ; Mewtwo, Grotte Azurée ; obéissance ; vitamines ; Cordon d'échange |

---

## 3. Contrat d'entrée (J24 → J25)

Rien n'est fusionné ni validé sur téléphone ; le J25 suppose livrés :

| Origine | Élément attendu |
|---|---|
| **J24** | Carte `cinnabar_island` avec **cinq portes** aux places RB (ville 20 × 18 pas) : Manoir (6,3), Arène (18,3), Labo (6,9), Centre (11,11), Boutique (15,11). Manoir et Labo : portes « à venir » ; Arène : porte fermée (le J25 y ajoute la règle de la Clé). Surf conservé entre cartes. |
| J23 | Badge Âme, CS03 Surf |
| J20 | `PokemonGift.give` ; Saquedeneu, Caninos, Arcanin, Goupix, Feunard ; Rappel ; Pierre Foudre ; Écrasement |
| J17 | Magnéti, Magnéton |
| J16 | Coupe (`field_moves.gd`), `key_item_repair.gd` |
| J14 | CT28 Tunnel, combat « deux tours » |
| J12 | `dome_fossil` / `helix_fossil` (un seul, choix définitif) |
| J10 | Musée d'Argenta (deux salles, porte « LABORATOIRE » fermée) |
| `main` | `StoryFlags`, drapeaux d'objets et de Dresseurs, étapes de scène `champion_card` / `battle` / `badge` / `give` / `moment`, OUI/NON, autosave aux moments stables, sélecteur de cible (Super Bonbon), Danse Flamme (piège), brûlure, contrecoup (`RECOIL`) |

À transmettre à la session du J24 : la liste des cinq portes et le besoin d'un `Warp` « chute »
commun (§4.4).

---

## 4. Le Manoir Pokémon (`pokemon_mansion_1f`, `_2f`, `_3f`, `_b1f`)

### 4.1 Ambiance

Un manoir de chercheurs abandonné après un incendie : parquets noircis, papiers peints décollés,
meubles renversés, plafonds ouverts par endroits sur un ciel de fin d'après-midi. La lumière entre
par les fenêtres crevées en longs rais dorés ; les fonds de pièce sont sombres. Statues de
Pokémon sur socle, carnets ouverts sur des pupitres, grilles de fer entre les pièces. Rien
d'horrifique : du silence, de la poussière, des Pokémon de feu et de poison installés là. Mewtwo
n'est jamais montré, ni en image, ni en silhouette.

### 4.2 Plans fonctionnels

Grilles RB à 1:1 (X-4) : 1F, 2F, B1F **30 × 28**, 3F **30 × 18**. Les grilles
`tools/plans/manoir_1f.txt`, `_2f`, `_3f`, `_b1f` feront foi ; topologie RB (annexe §1.2–§1.9),
habillage DA.

| Étage | Accès | Contenu |
|---|---|---|
| **1F** | Porte principale (sud, depuis l'île) ; **2ᵉ sortie sud-est**, derrière une porte du jeu A ; escalier ↑ 2F (5,10) ; escalier ↓ B1F (21,23), dans une partie qu'on atteint par la chute du 3F | Scientifique, Corde Sortie, Pépite, Pierre Lune cachée, statue (2,5) |
| **2F** | ↓ 1F ; **trois** escaliers vers 3F : (7,10), (6,1), (25,14) | Pillard, Super Bonbon, journaux n° 1 (18,2) et n° 2 (3,22), statue (2,11) |
| **3F** | trois escaliers vers 2F ; **trous** (16,14) et (17,14) → 1F (16,14), (19,14) → 2F (18,14) | Pillard, Scientifique, Potion Max, Pépite, Rappel Max caché, journal n° 3 (6,12), statue (10,5) |
| **B1F** | ↑ 1F seulement | Pillard, Scientifique, Super Bonbon (+ un caché), Guérison, CT14, CT22, **Clé Secrète** (5,13), journal n° 4 (16,20), statues (20,3) et (18,25) |

Coordonnées RB indicatives : la grille peut les décaler, la topologie reste.

### 4.3 Statues et portes (X-5)

- **Statue** : objet peint (statue de Pokémon sur socle), bloquant ; Action **face à elle** (comme
  RB, où il faut regarder vers le haut) : textes 9 à 11. OUI → l'interrupteur bascule.
- **Un seul drapeau** `mansion_switch_on` pour les quatre étages. Chaque étage a deux jeux de
  portes : **jeu A** fermé sur ARRÊT, **jeu B** fermé sur MARCHE (répartition RB, annexe §1.4 :
  1F 3 + 1, 2F 2 + 1, 3F 1 + 1, B1F 2 + 2).
- **Portes** : grilles de fer basses, deux images (fermée / ouverte) ; collision et image pilotées
  par le drapeau (modèle `FlagGate` à `blocking_cells`), mises à jour au chargement de la carte et
  au basculement.
- **Remise à ARRÊT** en entrant dans le Manoir **depuis Cramois'Île** (porte principale ou 2ᵉ
  sortie). Pas aux escaliers, pas aux chutes, pas au chargement d'une sauvegarde.
- Basculement [D] : son mécanique sourd, les portes visibles à l'écran coulissent en 0,25 s ; aucune
  flèche, aucun marqueur, aucun texte d'aide automatique.

### 4.4 Trous (X-6)

- `Warp` de type **chute** : la case du trou est praticable, la chute se déclenche quand le joueur
  y entre.
- Présentation [D] : le joueur s'enfonce (0,2 s), fondu au noir 0,3 s, arrivée sur la case cible
  avec un petit rebond et de la poussière, regard vers le bas ; le compagnon rentre dans sa Ball et
  ressort à l'arrivée.
- Les trous sont **peints** (plancher effondré aux bords nets), visibles de loin ; on ne tombe
  jamais par surprise sur une case qui ne le montre pas.
- Arrivées : 1F (16,14) pour les deux trous ouest, 2F (18,14) pour le trou est.
- Système commun avec le J24 (rochers des Îles Écume) : la première session qui le code le livre ;
  l'autre le réutilise.

### 4.5 Contrôle du puzzle

Vérifié sur les données RB (passe §4.3) : Clé atteignable ; inatteignable sans interrupteur ;
aucun des 3 030 états atteignables n'empêche de ressortir ; chutes sur cases praticables. Chemin
type : 1F → 2F → 3F, statue du 3F (MARCHE), trou → 1F, escalier ↓ B1F, statue sud (ARRÊT), statue
nord (MARCHE), salle ouest.

En 25.0, `tools/art/plan_check_manoir.py` refait ce contrôle sur **nos** grilles, et le refait à
chaque modification :

1. Clé atteignable depuis l'entrée, interrupteur sur ARRÊT.
2. Depuis **tout** état atteignable (étage, case, interrupteur), une sortie est atteignable.
3. Chaque trou mène à une case praticable, d'où l'on peut repartir dans les deux états.
4. Le B1F est inatteignable sans interrupteur (le puzzle reste nécessaire).
5. Au plus **un** Dresseur qui voit le joueur sur un passage obligatoire, par étage.
6. Objets, journaux et statues accessibles.

### 4.6 Dresseurs (X-7)

| Id [D] | Étage | Classe | Équipe RB | Vue | Récompense |
|---|---|---|---|---|---|
| `mansion_scientist_1` | 1F | Scientifique | Électrode 29, Smogogo 29 | 3 | 1 450 ₽ |
| `mansion_burglar_1` | 2F | Pillard | Salamèche 34, Reptincel 34 | 0 | 3 060 ₽ |
| `mansion_burglar_2` | 3F | Pillard | Feunard 38 | 0 | 3 420 ₽ |
| `mansion_scientist_2` | 3F | Scientifique | Magnéti 33, Magnéton 33, Voltorbe 33 | 2 | 1 650 ₽ |
| `mansion_burglar_3` | B1F | Pillard | Caninos 34, Ponyta 34 | 0 | 3 060 ₽ |
| `mansion_scientist_3` | B1F | Scientifique | Magnéti 34, Électrode 34 | 3 | 1 700 ₽ |

Pillards : vue 0, on leur parle (« largement facultatifs », RB). Capacités : montée de niveau à
leur niveau, vérifiées en 25.0 (tout « sans effet » remplacé). IA `random` [D]. Les Pillards
parlent d'un manoir-labyrinthe ; le Pillard du 2F donne l'indice des portes alternées (texte 17).

### 4.7 Rencontres (X-8)

Union Rouge + Bleu, niveaux RB, rencontres sur toutes les cases praticables sauf escaliers, seuils
et trous [D].

| Espèce (niveaux) | 1F | 2F | 3F | B1F |
|---|---|---|---|---|
| Ponyta (28–36) | 40 % | 25 % | 14 % | 15 % |
| Smogo (30–35) | 22,5 % | 25 % | 20 % | 27 % |
| Tadmorv (30–35) | 22,5 % | 25 % | 20 % | 27 % |
| Smogogo (37–42) | 2,7 % | 2,7 % | 8 % | 7,7 % |
| Grotadmorv (37–42) | 2,7 % | 2,7 % | 8 % | 5,7 % |
| Caninos (32–35) | 4,9 % | 10 % | 10 % | 7,6 % |
| Goupix (32–35) | 4,9 % | 10 % | 10 % | 7,6 % |
| Magmar | — | — | 34, 5 % | 38, 2 % |

Taux : celui des grottes du projet, ajusté en 25.0 pour RB 10/256 par pas [D]. Fond de combat
`manoir_salle`.

### 4.8 Objets (X-9)

| Étage | Objet | Type |
|---|---|---|
| 1F | Corde Sortie ; Pépite (RB : Carbone) ; Pierre Lune | visible ; visible ; **caché** |
| 2F | Super Bonbon (RB : Calcium) | visible |
| 3F | Potion Max ; Pépite (RB : Fer) ; Rappel Max | visible ; visible ; **caché** |
| B1F | Super Bonbon ; Guérison ; CT14 Blizzard ; CT22 Lance-Soleil ; Super Bonbon ; **Clé Secrète** | visibles ; caché (le 2ᵉ Super Bonbon) ; Clé visible |

- Potion Max (PV au maximum) et Rappel Max (ranime avec tous ses PV) : **données seules**, sur la
  mécanique de Potion et de Rappel (`jalon-20`).
- CT14 et CT22 : gardées si Blizzard (gel 10 %) et Lance-Soleil (charge en deux tours, mécanisme du
  J14) tiennent dans le moteur (vérifié en 25.0) ; sinon remplacées par Hyper Potion et Pépite [D].
- Drapeaux habituels `got_<carte>_item_N` / `got_<carte>_hidden_N`.
- Corde Sortie et Tunnel fonctionnent dans le Manoir et ramènent **devant la porte principale**.

### 4.9 Journaux (X-10, X-11)

Quatre carnets ouverts sur des pupitres (objets peints, bords de page brûlés). Action → textes 1 à
8 ; relisibles à volonté. **Aucun** Grand moment, son spécial, entrée Pokédex, apparition ni
flashback. Mew et Mewtwo ne deviennent ni « vus » ni « capturés ».

---

## 5. La Clé Secrète et la porte de l'Arène (X-12)

1. La Clé (`secret_key`, objet clé, « Clé Secrète ») est une Poké Ball au B1F (5,13), ramassée
   comme un objet ordinaire (drapeau `got_pokemon_mansion_b1f_item_N`). Description : texte 74.
2. Porte de l'Arène, **sans** la Clé : texte 75, le joueur recule d'une case (RB).
3. Première arrivée **avec** la Clé : textes 76–77 → `cinnabar_gym_unlocked`. Ensuite, porte
   ordinaire.
4. La Clé **reste** dans les objets clés. Au chargement, drapeau de ramassage sans objet → objet
   rendu (`key_item_repair`).

---

## 6. Le Laboratoire (`cinnabar_lab`, `_reunion`, `_recherche`, `_test`)

### 6.1 Plan

```
┌──────────────┐┌──────────────┐┌──────────────┐
│   RÉUNION    ││   R. et D.   ││     TEST     │
│ Intello      ││ Scientifique ││ Scientifique │
│ Papi    ⇄    ││ Scientifique ││  (fossiles)  │
│ Beauté  ⇄    ││ PC (mail)    ││ Scientif. ⇄  │
└──────┬───────┘└──────┬───────┘└──────┬───────┘
═══════╧═══════════════╧═══════════════╧══════ hall (18 × 8) : photo du Dr Fuji, chercheur
                ▲ sortie vers Cramois'Île
```

Hall à la largeur RB (18 × 8) ; salles à la convention des intérieurs peints (15 × 10) [D]. Trois
panneaux de porte (textes 26–28). Laboratoire propre et blanc, en contraste avec le Manoir :
paillasses, écrans, plantes, lumière froide. La machine de résurrection (Salle de test) est un
gros appareil vitré, non interactif.

### 6.2 Échanges fixes (X-15)

| Id | Salle | PNJ [D] | Veut | Donne | Surnom |
|---|---|---|---|---|---|
| `cinnabar_trade_electrode` | Réunion | Papi **Hector** | Raichu | Électrode | **Kourjus** |
| `cinnabar_trade_tangela` | Réunion | Beauté **Lina** | Mimitoss | Saquedeneu | **Bigoudi** |
| `cinnabar_trade_seel` | Test | Scientifique **Marc** | Ponyta | Otaria | **Bibi** |

Déroulé :
1. Offre (OUI/NON). NON → réplique de refus ; rien ne change.
2. OUI → sélecteur de l'équipe, limité à l'espèce demandée. Aucune → réplique « pas la bonne
   espèce » ; rien ne change. ANNULER → refus.
3. Échange, **en un seul bloc synchrone** : le Pokémon donné quitte l'équipe (s'il est le
   compagnon, règle du J11 d'abord) ; le Pokémon reçu prend **sa place** ; Pokédex vu + capturé ;
   rencontre notée ; drapeau `<id>_done`.
4. « Branchez le câble comme ça ! », fondu, « {joueur} a échangé X contre Y ! », remerciement.
5. Ensuite, réplique d'après échange ; l'offre ne revient jamais.

Pokémon reçu : **niveau du Pokémon donné** ; capacités de montée de niveau à ce niveau ; PV pleins,
sans statut ; IV tirés normalement ; surnom fixe ; dresseur d'origine = prénom du PNJ ; origine
`TRADE`. Pas de bonus d'expérience, pas de désobéissance. Le dernier Pokémon de l'équipe peut être
échangé (la taille de l'équipe ne change pas).

Mimitoss n'existe pas encore : l'offre de Lina reste en attente tant que le joueur n'en a pas.

### 6.3 Résurrection des fossiles (X-16)

Scientifique **Dr Kazuo** [D], Salle de test.

| État | Drapeaux | Passage |
|---|---|---|
| disponible | fossile dans le Sac | parler au scientifique → liste des fossiles possédés (un seul : pas de liste) → confirmation OUI |
| confié | `cinnabar_lab_fossil_<f>_given` + `cinnabar_lab_reviving` | fossile retiré **dans le même bloc** que les deux drapeaux ; textes 59–60 |
| prêt | `_given` sans `reviving` | `cinnabar_lab_reviving` est effacé à **chaque arrivée sur la carte de Cramois'Île** |
| récupéré | `cinnabar_lab_fossil_<f>_revived` (et `_given` effacé) | `PokemonGift.give`, **niveau 30** ; équipe, sinon stockage ; Pokédex, rencontre, drapeau en un bloc ; Grand moment « Pokémon reçu » s'il existe [D] |

`<f>` ∈ `dome`, `helix`, `amber` → Kabuto, Amonita, Ptéra.

- Un seul fossile à la fois : avec un fossile confié ou prêt, les autres sont refusés (texte 62).
- Aucune minuterie ; aucun nombre de pas.
- Le stockage n'a pas de limite : pas de cas « PC plein ».
- Interruption à tout moment : la dernière sauvegarde stable contient **soit** le fossile, **soit**
  `_given` ; **soit** `_given`, **soit** le Pokémon et `_revived`. Jamais les deux, jamais aucun.
- Réparation au chargement : fossile **et** `_given` (impossible sauf corruption) → fossile retiré ;
  `_revived` **et** `_given` → `_given` effacé.
- Kabutops et Amonistar existent (évolution au niveau 40).

### 6.4 Les autres PNJ

- **Hall** : chercheur (texte 29) ; photo du Dr Fuji (texte 30).
- **Réunion** : Intello qui a trouvé un fossile au Mont Sélénite (texte 31).
- **R. et D.** : scientifique de la CT (texte 32, **sans CT**) ; scientifique d'Évoli (texte 33) ;
  PC (textes 34–36) ; tuyau d'ambre (texte 37).
- **Test** : deux PC décoratifs.

---

## 7. Le Vieil Ambre (Argenta) (X-3)

- **Carte d'Argenta** (J10) : une **porte arrière** sur la façade est du Musée, devant laquelle
  pousse un **arbre à Couper** (Coupe du J16 ; buisson `InteractPoint` + drapeau, règle des CS).
- **Réserve du Musée** (`argenta_musee_reserve`, 15 × 10 [D]) : comptoir, vitrine de l'ambre, deux
  scientifiques.
  - Scientifique du comptoir : textes 67–69 (question OUI/NON sur l'ambre).
  - Scientifique de l'ambre : textes 70–71 → **Vieil Ambre** (`old_amber`, objet clé), drapeau
    `pewter_museum_got_old_amber`, vitrine vidée ; ensuite texte 72 ; vitrine : texte 73.
- Le Vieil Ambre peut donc être obtenu dès la Coupe, bien avant Cramois'Île (RB).
- **Dossier 12 corrigé** : « Ambre Vieille » → « Vieil Ambre ».

---

## 8. L'Arène d'Auguste (`cinnabar_gym`)

### 8.1 Plan

```
┌──────────┬──────────┬──────────┐
│ AUGUSTE  │ Q2   D3  │ D1       │
│          │          │ (libre)  │
├══ P6 ════┼══ P2 ════┼══ P1 ════┤
│ Q6   D7  │ Q3   D4  │ Q1   D2  │
├══ P5 ════┼══ P3 ════┤ guide    │
│ Q5   D6  │ Q4   D5  │ statue   │
│        P4║          │ entrée ▲ │
└──────────┴──────────┴──────────┘
Q = machine de quiz · D = Dresseur · P = porte de quiz
```

Grille RB 1:1, **20 × 18** (`tools/plans/cramois_arene.txt`). Ordre : Q1 → P1 → couloir nord → Q2 →
P2 → Q3 → P3 → Q4 → P4 → Q5 → P5 → Q6 → P6 → Auguste. Ambiance : roche volcanique sombre, braises
dans des rigoles, chaleur qui fait trembler l'air près des grilles ; portes = herses de métal
chaud, deux images.

### 8.2 Quiz (X-17)

- Machine : pupitre à écran, Action face à elle. Introduction (texte 80), puis la question, puis
  OUI/NON.
- **Bonne réponse** : texte 87 → `cinnabar_gym_gate_<n>`, herse ouverte pour toujours. Le Dresseur
  lié reste affrontable en lui parlant.
- **Mauvaise réponse**, Dresseur pas encore battu : texte 88, le Dresseur vient au joueur, combat.
  Victoire → herse ouverte. Défaite → Centre, herse fermée, la machine repose la question.
- **Mauvaise réponse**, Dresseur déjà battu : texte 88 ; sa herse est déjà ouverte.
- **Parler au Dresseur** = combat ; victoire → herse ouverte.
- Machine déjà résolue : texte 89.
- Les Dresseurs de l'Arène **ne voient pas** le joueur (RB).

### 8.3 Dresseurs de l'Arène

| Id [D] | Classe | Équipe RB | Lié à | Récompense |
|---|---|---|---|---|
| `cinnabar_gym_1` | Intello | Goupix 36, Goupix 36, Feunard 36 | aucune (facultatif) | 900 ₽ |
| `cinnabar_gym_2` | Pillard | Caninos 36, Goupix 36, Feunard 36 | Q1 / P1 | 3 240 ₽ |
| `cinnabar_gym_3` | Intello | Ponyta 34, Salamèche 34, Goupix 34, Caninos 34 | Q2 / P2 | 850 ₽ |
| `cinnabar_gym_4` | Pillard | Ponyta 41 | Q3 / P3 | 3 690 ₽ |
| `cinnabar_gym_5` | Intello | Galopa 41 | Q4 / P4 | 1 025 ₽ |
| `cinnabar_gym_6` | Pillard | Goupix 37, Caninos 37 | Q5 / P5 | 3 330 ₽ |
| `cinnabar_gym_7` | Intello | Caninos 37, Goupix 37 | Q6 / P6 | 925 ₽ |

IA `random` [D] ; fond `arene_cramois`. Le Dresseur 5 raconte l'oiseau de feu qui a guidé Auguste
(Sulfura, jamais nommé).

### 8.4 Auguste (X-18, X-21)

| Pokémon | Niv. | Capacités |
|---|---|---|
| Caninos | 42 | Flammèche, Groz'Yeux, Bélier, Hâte |
| Ponyta | 40 | Mimi-Queue, Écrasement, Rugissement, Danse Flamme |
| Galopa | 42 | Mimi-Queue, Écrasement, Rugissement, Danse Flamme |
| Arcanin | 47 | **Groz'Yeux** (RB : Hurlement), Flammèche, Déflagration, Bélier |

- **Déflagration** (`fire_blast`) : Feu, spéciale, 110, 85 %, 5 PP, brûlure 10 % (valeurs modernes,
  comme Lance-Flammes à 90).
- **Bélier** (`take_down`) : Normal, physique, 90, 85 %, contrecoup ¼ des dégâts infligés.
- IA `smart`, récompense 4 653 ₽, carte de Champion (`champion_card`).
- Simulation en 25.0 avec l'équipe type attendue après le J24 : cible **35–60 %** de victoire au
  premier essai. Hors cible → question à Kevin, aucun ajustement silencieux.
- Défaite : Centre ; herses ouvertes, Dresseurs battus et Clé conservés.

### 8.5 Victoire (X-19, X-20)

`battle` (gagné) → texte 100 → `badge` : `badge_volcano`, légende, Grand moment « badge », **aucun
bonus** → textes 101–102 → `give` `tm38` (`tm38_received`, une seule fois) → textes 103–104. Les sept
Dresseurs sont marqués battus. Ensuite : texte 105 en reparlant à Auguste ; guide : texte 106.
Aucun déplacement, aucune scène, aucun objectif, aucun PNJ qui oriente vers Jadielle.

---

## 9. Espèces nouvelles (X-22)

| Espèce | Rôle | Dos peint |
|---|---|---|
| Ponyta, Galopa | sauvage / Dresseurs / Auguste ; échange | oui |
| Tadmorv, Grotadmorv, Smogogo | sauvages, Dresseur | oui |
| Magmar | sauvage rare | oui |
| Électrode | échange, Dresseurs | oui |
| Otaria, Lamantine | échange (Otaria évolue au 34) | oui (Lamantine : placeholder accepté) |
| Kabuto, Kabutops, Amonita, Amonistar, Ptéra | fossiles | oui (Kabutops, Amonistar : placeholders acceptés) |

Pour chacune : données d'espèce, montée de niveau RB (capacités vérifiées dans le moteur),
compatibilités CT, entrée Pokédex (description et note dans le ton du projet, sans nommer d'autre
espèce), dos peint (X/Y repeint), face = illustration officielle (déjà là). Mimitoss : J22/J23.

---

## 10. Capacités et objets nouveaux

| Id | Nom | Données |
|---|---|---|
| `fire_blast` | Déflagration | §8.4 |
| `take_down` | Bélier | contrecoup ¼ (corrige le « sans effet » des branches) |
| `stomp` | Écrasement | repris de `jalon-20` |
| `blizzard`, `solar_beam` | Blizzard, Lance-Soleil | si CT14 / CT22 gardées |
| `tm38` | CT38 | Déflagration (`tm_compatibility.json` la déclare déjà) |
| `tm14`, `tm22` | CT14, CT22 | selon §4.8 |
| `secret_key` | Clé Secrète | objet clé |
| `old_amber` | Vieil Ambre | objet clé |
| `max_potion`, `max_revive` | Potion Max, Rappel Max | soin, données seules |

Toute capacité de montée de niveau des nouvelles espèces encore « sans effet » est listée en 25.0
et remplacée par la précédente de la liste RB qui fonctionne [D].

---

## 11. Drapeaux

| Drapeau | Rôle |
|---|---|
| `mansion_switch_on` | Interrupteur global (remis à ARRÊT en entrant depuis l'île) |
| `got_pokemon_mansion_<étage>_item_N`, `_hidden_N` | Objets du Manoir, Clé comprise |
| `beaten_<id>` | Dresseurs du Manoir et de l'Arène |
| `cinnabar_gym_unlocked` | Porte de l'Arène |
| `cinnabar_gym_gate_1` … `_6` | Herses de quiz |
| `badge_volcano`, `tm38_received` | Badge, CT38 |
| `cinnabar_trade_electrode_done`, `_tangela_done`, `_seel_done` | Échanges |
| `cinnabar_lab_reviving` | Fossile en cours |
| `cinnabar_lab_fossil_<f>_given`, `_revived` | Transaction des fossiles |
| `pewter_museum_got_old_amber`, drapeau de l'arbre coupé | Vieil Ambre |

Sauvegarde **v7 inchangée** ; ajout de l'origine `TRADE` (lecture tolérante vérifiée en 25.0).

---

## 12. Cas limites

| Cas | Attendu |
|---|---|
| Une statue ouvre une porte et en ferme une autre | Toujours une issue (`plan_check_manoir.py`) |
| Chute | Case praticable, jamais enfermée |
| Sauvegarde dans le Manoir, interrupteur sur MARCHE | Rechargé tel quel |
| Sortie puis retour au Manoir | Interrupteur sur ARRÊT |
| Corde Sortie / Tunnel dans le Manoir | Devant la porte principale |
| Objets, Clé | Jamais deux fois ; Clé rendue si absente |
| Porte de l'Arène après rechargement | Ouverte |
| Fermeture pendant le dépôt d'un fossile ou la remise du Pokémon | Ni perte ni double (§6.3) |
| Deuxième fossile | Refusé tant qu'un premier est en cours |
| Échange sans l'espèce, ou annulé | Rien ne change |
| Échange du compagnon | Compagnon retiré (J11), puis échange |
| Échange répété | Impossible |
| Défaite contre un Dresseur de quiz | Centre, herse fermée, question reposée |
| Défaite contre Auguste | Centre, progrès de l'Arène conservés |
| Après le Badge | Rien d'imposé |
| Lecture des journaux | Pokédex inchangé |

---

## 13. Art et fonds de combat

| Lot | Contenu |
|---|---|
| Vues générales peintes (à valider) | Manoir 1F, 2F, 3F, B1F ; Laboratoire (hall + 3 salles) ; Arène ; réserve du Musée ; façade est du Musée d'Argenta (porte arrière, arbre) |
| Objets de décor | statue à interrupteur ; grilles de fer (2 états) ; trous ; carnet sur pupitre ; machine de quiz ; herses (2 états) ; machine de résurrection ; photo du Dr Fuji ; PC ; vitrine de l'ambre (pleine / vide) |
| PNJ | Pillard, Intello, Scientifique, Papi, Beauté, guide de l'Arène, Auguste (+ carte de Champion) — réutiliser les planches existantes |
| Fonds CB.3 | `manoir_salle`, `arene_cramois` |
| Espèces | 14 dos (§9) |

DA : 2D HD peinte, orthogonale, sans pixel art, sans isométrie ; aucune minimap ni flèche
d'objectif.

---

## 14. Découpage et validation S24 (X-24)

| Lot | Contenu | Validation |
|---|---|---|
| **25.0** | Données, logique pure et tests (interrupteur, chute, échange, transaction des fossiles, quiz, porte à Clé), grilles + `plan_check_manoir.py`, vues peintes, art, simulation d'Auguste | captures et grilles relues |
| **25A** | Manoir complet | S24 |
| **25B** | Laboratoire (échanges, fossiles) + Vieil Ambre à Argenta | S24, **seul** (anti-duplication) |
| **25C** | Arène, Auguste, Badge Volcan, CT38 ; clôture | S24 |

Les cartes de 25A à 25C attendent la branche d'intégration qui contient le J24. Tests et
sauvegarde sont faits **dans chaque lot**.

---

## 15. Tests

- **GUT** : interrupteur (bascule, remise à ARRÊT, chargement) ; portes A/B (image + collision) ;
  chute (arrivée, compagnon) ; échange (espèce exacte, refus, annulation, niveau, surnom, dresseur
  d'origine, compagnon, une seule fois, atomicité) ; fossiles (chaque état, interruption simulée
  entre chaque étape, deux fossiles, réparation, niveau 30) ; quiz (bonne, mauvaise, Dresseur battu
  ou non, défaite, parole directe) ; porte à Clé et réparation ; Badge et CT38 uniques ; journaux
  sans effet sur le Pokédex ; Vieil Ambre unique.
- **Grilles** : `plan_check_manoir.py`, contrôles habituels des intérieurs et d'Argenta.
- **Équilibrage** : Auguste 35–60 % ; Dresseurs ≤ 80 %.
- **QA téléphone** par lot, bornée (~30–45 min, départs de débogage).

---

## 16. Textes À VALIDER

> Ton des dossiers précédents : phrases courtes, deux lignes de 40 caractères au plus par bulle
> (« / » = retour à la ligne). {joueur} = prénom du joueur. Numérotés pour les retours.

### Journaux du Manoir

1. *(n° 1, 2F, page 1)* « Journal — 5 juillet. » / « Expédition au cœur d'une jungle lointaine. »
2. *(n° 1, page 2)* « Un Pokémon inconnu a été découvert. »
3. *(n° 2, 2F, page 1)* « Journal — 10 juillet. » / « Nous avons baptisé le nouveau Pokémon : »
4. *(n° 2, page 2)* « Mew. »
5. *(n° 3, 3F, page 1)* « Journal — 6 février. » / « Mew a donné naissance. »
6. *(n° 3, page 2)* « Nous avons appelé le petit Mewtwo. »
7. *(n° 4, B1F, page 1)* « Journal — 1ᵉʳ septembre. » / « Mewtwo est bien trop puissant. »
8. *(n° 4, page 2)* « Nous n'arrivons plus à maîtriser » / « sa violence… »

### Statues

9. « Un interrupteur secret ! » / « L'actionner ? » *(OUI/NON)*
10. *(OUI)* « Qui ne le ferait pas ? » *(un déclic ; des grilles bougent)*
11. *(NON)* « Pas encore. »

### Dresseurs du Manoir

12. *(Scientifique 1F, avant)* « Qui êtes-vous ? » / « Personne ne devrait être ici. »
13. *(Scientifique 1F, défaite)* « Une clé ? » / « Je ne vois pas de quoi tu parles. »
14. *(Scientifique 1F, après)* « Ce manoir a brûlé il y a longtemps. » / « Les notes, elles, sont restées. »
15. *(Pillard 2F, avant)* « Je n'arrive pas à sortir ! » / « Ce manoir est un vrai casse-tête ! »
16. *(Pillard 2F, défaite)* « Bon, bon… J'abandonne. »
17. *(Pillard 2F, après)* « Les statues ouvrent et ferment les » / « grilles, chacune son tour ! »
18. *(Pillard 3F, avant)* « Cet endroit est immense ! »
19. *(Pillard 3F, après)* « Je me demande où est passé mon associé. »
20. *(Scientifique 3F, avant)* « Mon mentor vivait ici. »
21. *(Scientifique 3F, après)* « Coincé ? Essaie de sauter par là-bas ! » *(indice des trous)*
22. *(Pillard B1F, avant)* « Oh oh. Où suis-je ? »
23. *(Pillard B1F, après)* « On trouve des trucs par terre, ici. »
24. *(Scientifique B1F, avant)* « Cet endroit est idéal pour un labo. »
25. *(Scientifique B1F, après)* « Je me plais ici. » / « On y étudie au calme. »

### Laboratoire

26. *(panneau Réunion)* « LABORATOIRE POKÉMON » / « Salle de réunion »
27. *(panneau R. et D.)* « LABORATOIRE POKÉMON » / « Recherche et Développement »
28. *(panneau Test)* « LABORATOIRE POKÉMON » / « Salle de test »
29. *(chercheur du hall)* « Ici, nous étudions les Pokémon. » / « On nous apporte souvent des raretés. »
30. *(photo)* « Une photo du fondateur du » / « Laboratoire : le Dr Fuji. »
31. *(Intello, Réunion)* « J'ai trouvé un fossile très étrange » / « au Mont Sélénite ! » · « Je crois que c'est un Pokémon » / « très ancien ! »
32. *(scientifique R. et D.)* « Je mets au point une CT spéciale. » / « Elle n'est pas encore prête. »
33. *(scientifique d'Évoli)* « Évoli peut évoluer de trois façons » / « différentes. »
34. *(PC, page 1)* « Un mail est ouvert à l'écran. » / « Sujet : les oiseaux légendaires. »
35. *(PC, page 2)* « Artikodin, Électhor, Sulfura. » / « Leurs repaires restent inconnus. »
36. *(PC, page 3)* « Prochaine étape : explorer la caverne » / « près d'Azuria. — Équipe de recherche »
37. *(tuyau, R. et D.)* « Un tuyau couleur d'ambre. »

### Échanges

> X = espèce demandée, Y = espèce donnée, Z = surnom.

38. *(Hector, offre)* « Bonjour ! Tu veux échanger ton X » / « contre mon Y ? »
39. *(Hector, refus)* « Bon, si tu ne veux pas… »
40. *(Hector, mauvaise espèce)* « Hmm ? Ce n'est pas un X. » / « Pense à moi si tu en as un. »
41. *(Hector, merci)* « Merci ! »
42. *(Hector, après)* « Ton X se porte à merveille ! »
43. *(Lina, offre)* « Salut ! Tu as un X ? » / « Tu l'échangerais contre un Y ? »
44. *(Lina, refus)* « Dommage. »
45. *(Lina, mauvaise espèce)* « Ce n'est pas un X… » / « Si tu en trouves un, reviens me voir ! »
46. *(Lina, merci)* « Merci beaucoup ! »
47. *(Lina, après)* « Comment va mon ancien Y ? »
48. *(Marc, offre)* « Je cherche un X ! » / « Je te l'échange contre un Y ? »
49. *(Marc, refus)* « Oh… tant pis. »
50. *(Marc, mauvaise espèce)* « Quoi ? Ce n'est pas un X ! » / « Reviens quand tu en auras un ! »
51. *(Marc, merci)* « Super, merci ! »
52. *(Marc, après)* « Mon ancien Y est génial, hein ? »
53. *(commun)* « Branchez le câble comme ça ! »
54. *(commun)* « {joueur} a échangé X contre Z ! »

### Fossiles

55. *(Dr Kazuo, accueil)* « Bonjour ! J'étudie les fossiles de » / « Pokémon rares. Tu en as un ? »
56. *(sans fossile)* « Non ? Dommage ! »
57. *(confirmation)* « Oh ! C'est un Fossile Dôme ! Il vient » / « de Kabuto, un Pokémon disparu ! » · « Ma machine peut le ramener à la vie ! » / « Je te le prends ? » *(OUI/NON ; nom et espèce selon le fossile)*
58. *(NON)* « Reviens quand tu veux ! »
59. *(OUI)* « {joueur} confie le Fossile Dôme. »
60. *(OUI, suite)* « Il me faut un peu de temps ! » / « Va donc faire un tour dehors ! »
61. *(avant d'être sorti)* « Pas encore ! Va faire un tour dehors ! »
62. *(deuxième fossile)* « Je m'occupe déjà d'un fossile ! » / « Un seul à la fois ! »
63. *(prêt)* « Te voilà ! Ton fossile a repris vie ! » / « C'est bien un Kabuto, comme prévu ! »
64. *(légende de remise)* « {joueur} reçoit Kabuto ! »
65. *(après, s'il reste un fossile)* « Tu as un autre fossile ? Montre ! »
66. *(après, plus de fossile)* « Prends bien soin de lui. » / « Il vient de très loin. »

### Vieil Ambre (Argenta)

67. *(scientifique du comptoir)* « On n'entre pas par-derrière ! » / « Bon, tant pis. Tu sais ce qu'est l'ambre ? » *(OUI/NON)*
68. *(OUI)* « Il paraît qu'un labo essaie de » / « faire revivre des Pokémon avec. »
69. *(NON)* « C'est de la sève d'arbre fossilisée. »
70. *(scientifique de l'ambre)* « Chut ! Je crois que cet ambre » / « contient l'ADN d'un Pokémon ! » · « Ce serait formidable de le ramener » / « à la vie ! Mais mes collègues… » · « Tiens, prends-le. Fais-le examiner. »
71. *(légende de remise)* « {joueur} reçoit le Vieil Ambre ! »
72. *(après)* « Chut ! Fais examiner le Vieil Ambre ! »
73. *(vitrine, avant)* « L'ambre est clair et doré. »

### Clé Secrète et porte

74. *(description)* « Une clé ancienne trouvée au Manoir. » / « Elle ouvre une porte de Cramois'Île. »
75. *(porte, sans Clé)* « La porte est verrouillée… »
76. *(porte, avec Clé, 1ʳᵉ fois)* « La Clé Secrète tourne dans la serrure. »
77. *(suite)* « La porte de l'Arène est ouverte ! »

### Arène

78. *(panneau)* « ARÈNE DE CRAMOIS'ÎLE — CHAMPION : AUGUSTE » / « Le maître du quiz au sang chaud ! »
79. *(guide, avant)* « Salut, futur Champion ! Auguste est » / « un expert du Feu. Mise sur l'Eau ! » · « Et prends quelques Antibrûle ! »
80. *(intro des machines)* « Quiz Pokémon ! Bonne réponse : la porte » / « s'ouvre. Mauvaise : un Dresseur t'attaque ! » · « Garde tes forces pour le Champion : » / « réponds juste ! »
81. *(Q1)* « Chenipan finit par devenir Papilusion ? » *(OUI)*
82. *(Q2)* « La Ligue délivre-t-elle 9 Badges ? » *(NON)*
83. *(Q3)* « Ptitard évolue-t-il trois fois ? » *(NON)*
84. *(Q4)* « L'Électrik touche-t-il le type Sol ? » *(NON)*
85. *(Q5)* « Deux Pokémon de même espèce et même » / « niveau peuvent-ils être différents ? » *(OUI)*
86. *(Q6)* « La CT28 contient-elle Fosse ? » *(NON)*
87. *(bonne réponse)* « Exact ! Tu peux passer ! »
88. *(mauvaise réponse)* « Raté ! Mauvaise réponse ! »
89. *(machine déjà résolue)* « Porte ouverte. »
90. *(D1, avant)* « Tu sais à quelle température monte » / « le souffle d'un Pokémon Feu ? »
91. *(D2, avant)* « J'étais voleur. Grâce aux Pokémon, » / « je suis devenu honnête ! »
92. *(D3, avant)* « Tu ne gagneras pas ! » / « J'ai tout étudié sur les Pokémon ! »
93. *(D4, avant)* « J'aime juste les Pokémon Feu ! »
94. *(D5, avant)* « Je sais pourquoi Auguste est devenu Dresseur ! »
95. *(D5, après)* « Un jour, il s'est perdu en montagne. » / « Un oiseau de feu est apparu… » · « Sa lumière l'a guidé jusqu'en bas. »
96. *(D6, avant)* « J'ai visité beaucoup d'Arènes, » / « mais celle-ci est ma préférée ! »
97. *(D7, avant)* « Le Feu craint l'eau ! »
98. *(défaites des Dresseurs, commun [D])* « Trop chaud pour moi ! »

### Auguste

99. *(avant)* « Ha ! Je suis Auguste, Champion de » / « Cramois'Île ! » · « Mes Pokémon Feu vont tout réduire » / « en cendres ! Tu as de l'Antibrûle ? »
100. *(défaite)* « J'ai brûlé tout mon feu ! » / « Tu as gagné le Badge Volcan ! »
101. *(légende)* « {joueur} reçoit le BADGE VOLCAN ! »
102. *(après le badge)* « Ha ! Ce Badge prouve ta valeur. » / « Prends ceci aussi ! »
103. *(légende)* « {joueur} reçoit la CT38 ! »
104. *(CT38)* « La CT38 contient Déflagration ! » / « Apprends-la à un Pokémon Feu ! »
105. *(ensuite)* « Déflagration, c'est le Feu à son sommet ! » / « Ne la gâche pas sur un Pokémon Eau ! »
106. *(guide, après)* « {joueur} ! Tu as éteint ce volcan ! »

### Objets (descriptions)

107. *(Vieil Ambre)* « Un morceau d'ambre ancien. » / « Il contiendrait l'ADN d'un Pokémon. »
108. *(Potion Max)* « Restaure tous les PV d'un Pokémon. »
109. *(Rappel Max)* « Ranime un Pokémon K.O. » / « avec tous ses PV. »
110. *(CT38)* « Apprend Déflagration à un Pokémon. »

Descriptions et notes Pokédex des 14 espèces : rédigées en 25.0 avec les données, validées avec
ce lot complémentaire.

---

## 17. Dépendances et propagation

- **Session du J24** : cinq portes de Cramois'Île (§3) ; `Warp` « chute » commun (§4.4).
- **Dossier 12** : « Ambre Vieille » → « Vieil Ambre » (fait avec ce dossier) ; la carte d'Argenta
  recevra la porte arrière et l'arbre au 25B.
- **Dossier 17 / `trade_cord`** : sans changement ; les échanges du J25 sont des échanges fixes,
  pas des évolutions par échange (Électrode, Saquedeneu, Otaria n'évoluent pas par échange).
- **Roadmap** : inchangée.
