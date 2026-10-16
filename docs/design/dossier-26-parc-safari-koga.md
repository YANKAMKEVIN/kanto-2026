# Dossier 26 — Les secrets du Parc Safari : Parc Safari, CS03 Surf, CS04 Force, Arène de Koga (jalon 23)

> **Statut : audit et dossier d'alignement, À VALIDER.** Rédigé par Claude le 2026-10-16 à partir de
> la V2 de Kevin (`docs/design/passes/j23-v2-chatgpt.md`). **Aucune ligne de code** avant la réponse
> aux questions du §16. Les 7 décisions verrouillées de la V2 ne sont pas rouvertes.
>
> **Numéro 26** : 25 = J22 (prompt `docs/design/prompts/chatgpt-dossier-25-safrania-j22.md`, branche
> `docs/dossier-25-j22`), 24 = J21, 23 = J20. Vérifié libre sur toutes les branches locales et
> distantes le 2026-10-16.
>
> **Sources.**
> - Code : `origin/main` à `440f9b17` (J15 fusionné, sauvegarde v7) et les branches `jalon-16` à
>   `jalon-21` (état du 2026-10-16). Le `main` local (`2bd6bbf7`) est en retard sur `origin/main`.
> - Rouge/Bleu : désassemblage `pret/pokered` à `af519899` (cartes, scripts, `engine/battle/core.asm`,
>   `engine/items/item_effects.asm`, `data/wild/maps/SafariZone*.asm`, `data/trainers/parties.asm`,
>   `engine/menus/start_sub_menus.asm`). RFVF : `pret/pokefirered` à `037335f4`.
>
> **Mise à jour du 2026-10-16 (après coup)** : le J22 a été recadré par Kevin (« Les deux chemins
> vers Parmanie », passe `j22-v2-alignement.md`, M-1 à M-24, branche `docs/dossier-25-j22`) et le
> partage de Surf et Force avec le J24 a été tranché (P-2 B, passe `j24-v2-alignement.md`, branche
> `docs/dossier-27-j24`, d'après la session du J24). Le §1.1, le §6.3, le §9, le §14 et le §16 en
> tiennent compte. Les arbitrages du J23 portent la lettre **N** (M = J22, P = J24).
>
> **Origine des règles** : **RB** = Rouge/Bleu ; **G+** = génération ultérieure (RFVF surtout) ;
> **K26** = adaptation Kanto 2026 ; **[D]** = valeur par défaut proposée (règle 4 de CLAUDE.md) ;
> **[Q]** = question pour Kevin (§16).

---

## 1. Contrat d'entrée et dépendances

### 1.1 Le J22 livre Parmanie (recadrage du 2026-10-16)

Le prompt du dossier 25 (2026-10-15) mettait Safrania au J22. Kevin l'a **recadré le 2026-10-16** :
le J22 devient « **Les deux chemins vers Parmanie** » (Routes 12 à 18, Parmanie, pêche, Vélo) et
Safrania est reportée. Sa passe d'alignement (M-1 à M-24) est **à trancher** ; elle prévoit, pour le
J23 :

| Point du J22 | Proposition de la passe J22 | Effet sur le J23 |
|---|---|---|
| Parmanie (60 × 54, échelle × 1,5) | ville + 4 intérieurs ouverts, **3 portes réservées au J23** | le J23 ouvre la **porte du Parc**, l'**Arène de Koga** (façade posée par le J22) et la **maison du Gardien** (M-19 B) |
| Sorties de Parmanie | ouest Route 18, est Route 15, **sud Route 19 (mer)** réservée | rien à faire au J23 (la mer est au J24, P-3) |
| Pêche (M-8 à M-11) | trois cannes, terrain `water_rod`, meilleure canne d'office | le Parc peut avoir ses **étangs pêchables** (§6.3, **N-6**) |
| Enclos de Parmanie (M-20) | « vitrines » des Pokémon du Safari | décor du J22 ; aucun lien de code avec le Parc |
| Maison de Vol, Route 16 (M-18 C) | **porte réservée « au J23 »** avec la CS02 | **hors du périmètre verrouillé du J23** → **N-24** |
| Ronflex et Route 12 sud (M-3) | à trancher avec le J21 | un des deux chemins doit être praticable avant le J23 |

Le présent dossier suppose donc qu'**avant le code du J23** existent : Parmanie (extérieur, Centre,
Boutique, façades et portes réservées), au moins un chemin praticable vers elle, et la pêche si
**N-6** la retient. L'ordre des badges devient celui de RB : Koga est le **cinquième** badge (après
Erika), Morgane vient plus tard.

### 1.2 État réel des jalons précédents (2026-10-16)

« Conçu » n'est pas « implémenté » :

| Jalon | État | Ce dont le J23 a besoin |
|---|---|---|
| J15 | fusionné dans `origin/main` | Stockage, Jackpot, sauvegarde v7 |
| J16 | code complet, **non fusionné** (`jalon-16`, empilé sur J15) | CS01 Coupe, modèle hybride (`field_moves.gd`), catégorie CS |
| J17 | code complet, **non fusionné** ; part de `440f9b17`, **sans** le J16 | CS05 Flash ; `poison_gas`, `hypnosis` ; Soporifik, Hypnomade (Jongleurs de Koga) |
| J18, J19 | en cours, non fusionnés | Espèces (Noeunoeuf…) |
| J20 | **à T8** : données et logique pure, aucune carte de Céladopole ni de l'Arène | **Badge Prisme** : aucune scène ne lève encore `badge_rainbow` ; Rhinocorne, Kangourex |
| J21 | à T4 | Poké Flûte, fermeture de la Route 12 sud |
| J22 | prompt ChatGPT seulement | voir §1.1 |

Les branches 17 à 21 partent **toutes** de `440f9b17` et ne se contiennent pas. Conflits déjà connus
à la fusion : `data/world/field_moves.json` (J16 n'a que `cut`, J17 que `flash` : garder les deux),
`hypnosis` défini deux fois (J17 et J19), `tm_compatibility.json` (généré : à **régénérer**, pas à
fusionner). **Règle proposée (comme la C-7 du J21)** : le code du J23 commence sur un `main` qui
contient J16 à J22. Le travail sans code (grilles, vues peintes, données isolées, logique pure du
mode Safari) peut commencer avant.

### 1.3 Dépendances, vérifiées dans le code

| Dépendance | Constat | Conséquence pour le J23 |
|---|---|---|
| Rencontres sauvages | `game/pokemon/encounters/` (directeur, tables `data/encounters/*.json`, `BattleRequest.wild`). Points d'accroche : `BattleRules` (`wild`, `can_flee`, `allow_balls`…), `BattleAction.Kind` | Le mode Safari est un **nouveau jeu de règles de combat** et un nouveau menu ; le déclenchement des rencontres est réutilisé tel quel |
| Capture | Formule **G3/G4** (`capture_calc.gd`, 4 secousses), pas la formule RB. Bonus de statut ×1,5 / ×2,5 | La Safari Ball se branche sur cette formule (§5.4, **N-5**) |
| Stockage | `PokemonStorage` : liste **unique, sans limite** ; pas de boîtes | **Le cas « BOÎTE pleine » de RB n'existe pas** : toute capture réussit à ranger (§12) |
| Pêche | **absente** du code ; **conçue au J22** (M-8 à M-11 : cannes, terrain `water_rod`) | Étangs du Parc pêchables si le J22 la livre (**N-6**) |
| Repousse, compteur de pas | absents ; `_quiet_steps` n'est pas sauvegardé | Le compteur Safari est neuf et doit être sauvegardé (§11) |
| CS (modèle hybride) | `field_moves.gd` : états `NO_HM`, `NO_BADGE`, `NO_POKEMON`, `READY` ; règles dans `data/world/field_moves.json` ; apprentissage par `tm_teach.gd` ; compatibilités `hms` 01 à 05 déjà dans `tm_compatibility.json` | Le J23 livre objets, capacités, apprentissage et entrées `surf` / `strength` ; les mécaniques de monde sont au J24 (§9) |
| Eau | `GridWorld.is_water`, `can_enter` refuse l'eau ; légende `W` des grilles | Aucun état « sur l'eau » : **construit par le J24** (P-2 B) ; le J23 n'en a pas besoin |
| Rochers | **aucun** objet poussable | **construits par le J24** (P-2 B) ; au J23, le rocher du Gardien est un obstacle fixe (§9.2) |
| Badges | `data/badges.json` : `rainbow` et `soul` déclarés ; drapeaux `badge_<id>` ; aucun effet codé sauf Coupe → `badge_cascade` | Badge Âme : drapeau et scène seulement. **Aucun effet caché** (dossier 12) : pas de bonus de Vitesse RB |
| Statuts | `StatusRules.KNOWN` : poison, paralysie, sommeil, brûlure, gel | **Toxik (poison grave) absent** ; il est obligatoire puisque la CT06 est la récompense (§10.4) |
| Obstacles conditionnels | `FlagGate.blocking_cells` (J17) | Réutilisé pour fermer les bords « À venir » sur l'eau |
| Sauvegarde | v7 ; `upgrade()` par version ; drapeaux `StoryFlags` ; autosave à l'arrivée sur une carte, en fin de combat, de scène, à la capture ; écriture immédiate à la mise en pause de l'appli | Le compteur Safari demande un champ neuf → **v8** (ou suivante) (§11, **N-20**) |
| Argent | revenus répétables : Jackpot (J15) et vente à moitié prix (Pépite comprise) ; Dresseurs non re-combattables | §12.3 |

---

## 2. Plans fonctionnels des quatre zones du Parc

### 2.1 Topologie RB (vérifiée dans `data/maps/objects/SafariZone*.asm`)

```
                 ┌───────────── NORD (40 × 36) ──────────────┐
                 │ maison de repos (35,3)                    │
                 │                              est (39,30–31)├──► EST (0,4–5)
                 │ bas (2–3,35) et (8–9,35)   bas (20–21,35)  │
                 └────┬──────────┬─────────────────┬──────────┘
                      ▼          ▼                 ▼
        ┌──── OUEST (30 × 26) ────┐   ┌── CENTRE (30 × 26) ──┐   ┌──── EST (30 × 26) ────┐
        │ MAISON SECRÈTE (3,3)    │   │ haut (14–15,0)        │   │ ouest (0,4–5) ◄ Nord   │
        │ Dents d'Or (19,7)       │◄──┤ ouest (0,10–11)       ├──►│ ouest (0,22–23)        │
        │ est (29,22–23)          │   │ est (29,10–11)        │   │ maison de repos (25,9) │
        │ maison de repos (11,11) │   │ maison de repos (17,19)│  └────────────────────────┘
        └─────────────────────────┘   │ bas (14–15,25)        │
                                      └──────────┬────────────┘
                                                 ▼
                                   PORTE (8 × 6), au nord de Parmanie
```

- Toutes les liaisons sont des **warps** (pas des raccords de carte continus). [RB]
- La **Maison Secrète** est au coin nord-ouest de la zone Ouest ; elle s'atteint **à pied**, sans
  Surf. Aucun lieu du Parc n'exige Surf ni Force. [RB]
- Quatre **maisons de repos** (une par zone), sans PC utilisable. [RB]
- Des étangs existent ; aucune rencontre sur l'eau en RB (taux 0). [RB]

### 2.2 Adaptation K26

- **Géométrie RB 1:1 en nombre de cases** [D], **pas** l'échelle × 1,5 des routes : le budget de
  500 pas n'a de sens que si les distances restent celles de RB. → **N-3**.
- Les liaisons deviennent des **raccords continus** quand deux zones se touchent (passage en bord de
  carte avec fondu, mécanisme existant) ; les quatre zones restent quatre cartes. [K26]
- **Contrôle automatique** (`plan_check`) sur les grilles :
  - chemin le plus court Porte → Maison Secrète → Dents d'Or → Porte **≤ 300 pas** [D] (une visite
    suffit pour les deux récompenses, avec 40 % de marge) ;
  - toute case d'herbe est atteignable ; aucun cul-de-sac sans sortie ;
  - la Maison Secrète et les Dents d'Or sont atteignables sans Surf ni Force.
- Chaque zone a une identité lisible sur téléphone [D] : **Centre** = prairie et étang central,
  statue de Kangourex (RB) ; **Est** = plaine sèche, Doduo et Tauros ; **Nord** = collines et cours
  d'eau, la plus grande ; **Ouest** = bosquets et marais, labyrinthe de haies menant à la Maison
  Secrète.
- Des **panneaux** RB (conseils, noms de zones) ; un panneau de la zone Ouest invite à chercher les
  dents du Gardien (RB, « Find the Warden's teeth »).

Les grilles (`tools/plans/safari_*.txt`) et les vues générales peintes se font après validation, comme
aux jalons précédents ; la grille fait foi.

---

## 3. Plans des bâtiments

| Bâtiment | Lieu | Contenu fonctionnel | Origine |
|---|---|---|---|
| **Porte du Safari** | nord de Parmanie | 8 × 6 ; deux employés au comptoir (accueil et paiement ; explication des zones) ; passage nord vers le Centre ; la zone de comptoir déclenche l'accueil à l'entrée et la question « Partir maintenant ? » à la sortie | RB |
| **Maisons de repos** (× 4) | une par zone | 8 × 8 ; un ou deux PNJ à conseils ; **un seul intérieur peint**, réutilisé quatre fois [D] ; le compteur continue d'y tourner | RB |
| **Maison Secrète** | zone Ouest, nord-ouest | 8 × 8 ; le **Pêcheur expert** remet la CS03 | RB |
| **Maison du Gardien** | Parmanie (porte réservée par le J22, M-19) | le Gardien (CS04) ; **un rocher** devant un Super Bonbon : obstacle fixe au J23, poussable quand le J24 livre Force (§9.2) | RB |
| **Arène de Koga** | Parmanie | 10 × 18 ; murs invisibles ; 6 Dresseurs ; Koga au centre-bas ; Guide et deux statues près de l'entrée (§10) | RB |

Le J22 pose les façades et les portes réservées ; le J23 construit les intérieurs (Porte du Safari,
maison du Gardien, Arène) et ouvre les portes.

---

## 4. Déplacement et compteur de pas

| Règle | Détail | Origine |
|---|---|---|
| Entrée | 500 ₽ débités, 30 Safari Balls, 500 pas | RB (le jeu initialise 502 pour compenser 2 pas scriptés : K26 compte **500 pas joueur**) |
| Ce qui compte | chaque **pas effectif** sur la grille, marche ou course, y compris le pas qui franchit une porte ou un raccord | RB |
| Ce qui ne compte pas | pivoter sur place, se cogner à un obstacle, dialogues, menus, combats, déplacements scriptés | RB |
| Maisons de repos et Maison Secrète | le compteur **continue** | RB |
| Fin par les pas | quand le compteur est à 0, le **pas suivant** déclenche la fin : le joueur peut encore parler à quelqu'un, ramasser un objet ou finir un combat déclenché par son dernier pas | RB |
| Fin par les Balls | la dernière Ball lancée (capturée ou non) termine le combat ; la fin est annoncée dès le retour sur la carte | RB |
| Annonce de fin | haut-parleur (jingle), puis fondu vers la Porte ; l'employé conclut ; les Balls restantes sont perdues | RB |
| Sortie volontaire | en revenant dans la Porte : « Partir maintenant ? » OUI → fin de visite (Balls perdues) ; NON → le joueur remonte d'un pas | RB |
| Corde Sortie | autorisée ; termine la visite (Balls perdues) et ramène au lieu habituel de la Corde | RB |
| Vol, Téléport hors combat | **refusés** dans le Parc (si ces usages existent au moment du J23) | RB |
| Affichage | voir **N-7** : une petite pastille « pas · Balls » visible seulement dans le Parc [D] | K26 (RB : dans le menu Start) |

Les Safari Balls **ne sont pas des objets du Sac** : ce sont deux compteurs de visite (pas, Balls).
Rien n'entre dans le Sac, rien n'en sort. [RB]

---

## 5. Capture Safari : Safari Ball, appât, caillou

### 5.1 Déroulé

Toute rencontre dans les quatre zones est une **rencontre Safari** [RB] : aucun Pokémon du joueur
n'entre en jeu ; écran de combat existant sans Pokémon allié (le dos du joueur à la place) ; menu de
quatre boutons : **SAFARI BALL (×n)**, **APPÂT**, **CAILLOU**, **FUIR**. Ni expérience, ni argent, ni
Sac, ni changement de Pokémon. Pokédex : « vu » à l'apparition, « capturé » à la capture (existant).

### 5.2 Appât et caillou (RB, `engine/battle/core.asm`)

| Action | Taux de capture utilisé | Compteurs |
|---|---|---|
| APPÂT | ÷ 2 | colère = 0 ; repas += 1 à 5 (uniforme), plafond 255 |
| CAILLOU | × 2, plafond 255 | repas = 0 ; colère += 1 à 5 |

**Fin de chaque tour** sans capture : si repas > 0 → repas − 1, « {Pokémon} mange ! » ; sinon si
colère > 0 → colère − 1, « {Pokémon} est en colère ! » ; quand la colère retombe à 0, **le taux revient
au taux de base de l'espèce**.

**Particularités RB conservées** (la V2 le demande) :
- la division due à l'appât **n'est jamais annulée** à la fin du repas : plusieurs appâts rendent le
  Pokémon de plus en plus difficile à capturer ;
- la fin de la colère remet le taux de base, ce qui **efface aussi** les divisions dues aux appâts ;
- un appât qui ne donne qu'un tour de repas est déjà consommé au moment du test de fuite.

### 5.3 Fuite du Pokémon sauvage (RB)

Après chaque action qui ne capture pas (pas avant la première) :

```
b = Vitesse × 2           (Vitesse = stat réelle du Pokémon rencontré)
si repas > 0 : b = b ÷ 4
si colère > 0 : b = min(b × 2, 255)
fuite si hasard(0..255) < b
```

La particularité RB « seul l'octet bas de la Vitesse compte » ne joue jamais ici (aucune espèce du
Parc n'a une Vitesse ≥ 128 aux niveaux du Parc) : **pas reproduite**, sans effet visible. FUIR réussit
toujours.

### 5.4 Safari Ball

En RB, la Safari Ball utilise **le calcul de l'Ultra Ball**. Le projet calcule les captures avec la
formule G3/G4 : la Safari Ball y prend **le multiplicateur de l'Ultra Ball (× 2)** [D], appliqué au taux
de l'espèce **modifié par l'appât ou le caillou** (§5.2). Les statuts ne jouent pas (le joueur ne peut
pas en infliger). → **N-5** (alternative : × 1,5 comme RFVF).

### 5.5 Textes de combat

Voir §8, textes 20 à 29.

---

## 6. Tables de rencontres et espèces

### 6.1 Règle de version

Précédent J12 / J15 (« les deux versions sont réunies ») : **Insécateur et Scarabrute sont tous les
deux présents** ; les lignées Nidoran ♂ et ♀ se partagent les emplacements que Rouge et Bleu leur
donnent séparément [D, **N-4**].

### 6.2 Tables RB (herbe ; taux RB 30/256 par pas, ≈ 11,7 %)

Poids RB des emplacements : 20 / 20 / 15 / 10 / 10 / 10 / 5 / 5 / 4 / 1.

| Empl. | Centre | Est | Nord | Ouest |
|---|---|---|---|---|
| 1 (20) | Nidoran ♂/♀ 22 | Nidoran ♂/♀ 24 | Nidoran ♂/♀ 22 | Nidoran ♂/♀ 25 |
| 2 (20) | Rhinocorne 25 | Doduo 26 | Rhinocorne 26 | Doduo 26 |
| 3 (15) | Mimitoss 22 | Paras 22 | Paras 23 | Mimitoss 23 |
| 4 (10) | Noeunoeuf 24 | Noeunoeuf 25 | Noeunoeuf 25 | Noeunoeuf 24 |
| 5 (10) | Nidorino / Nidorina 31 | Nidorino / Nidorina 33 | Nidorino / Nidorina 30 | Nidorino / Nidorina 33 |
| 6 (10) | Noeunoeuf 25 | Noeunoeuf 23 | Noeunoeuf 27 | Noeunoeuf 26 |
| 7 (5) | Nidorina / Nidorino 31 | Nidoran ♀/♂ 24 | Nidorina / Nidorino 30 | Nidoran ♀/♂ 25 |
| 8 (5) | Parasect 30 | Parasect 25 | Aéromite 32 | Aéromite 31 |
| 9 (4) | **Insécateur / Scarabrute 23** | Kangourex 25 | Leveinard 26 | Tauros 26 |
| 10 (1) | Leveinard 23 | **Insécateur / Scarabrute 28** | Tauros 28 | Kangourex 28 |

« ♂/♀ » et « Nidorino / Nidorina » : l'emplacement est **partagé à parts égales** (somme RB des deux
versions) [D]. Conversion vers le format du projet (`rate`, `ramp`, `slots` avec `weight`) : taux
équivalent à RB, rampe du projet conservée [D].

Ce que cela donne pour le joueur (lisible) : Leveinard, Tauros, Kangourex, Insécateur et Scarabrute
sont **rares** (1 à 4 %) et fuient souvent (Tauros, Insécateur, Scarabrute : rapides). C'est le cœur
de la tension du Parc. [RB]

### 6.3 Pêche et eau

- RB : on pêche dans les étangs du Parc ; **la rencontre pêchée est aussi une rencontre Safari**
  (Balls, appât, caillou). Canne : Magicarpe 5 ; Super Canne : Poissirène ou Ptitard 10 ; Méga Canne
  (table du Parc) : **Minidraco**, Krabby, Psykokwak, Ramoloss 15, une touche sur deux. Aucune
  rencontre en surfant.
- Le J22 conçoit la pêche (M-8 à M-11). Proposition [**N-6**] : si le J22 la livre, les **berges des
  étangs du Parc sont pêchables** (cases marquées), avec les tables RB ; la rencontre suit les règles
  Safari ; un lancer de canne **ne coûte pas de pas**. Minidraco devient le rare caché du Parc.
- Sinon (pêche absente ou reportée), les étangs restent décor et Minidraco attend la pêche.
- **Pas d'eau surfable dans le Parc au J23** (P-3 B).

### 6.4 Espèces à créer (données, Pokédex, art)

| Espèce | Rôle au J23 | État dans le dépôt |
|---|---|---|
| Leveinard, Insécateur, Scarabrute, Tauros, Mimitoss, Doduo | Parc | **absentes partout** |
| Minidraco, Psykokwak, Ramoloss | Parc, Méga Canne (si **N-6**) | absentes (Krabby, Magicarpe, Poissirène, Ptitard : prévus au J22) |
| Aéromite | Parc (et évolution de Mimitoss 31) | absente |
| Dodrio | évolution de Doduo (31) | absente |
| Rhinoféros | évolution de Rhinocorne (42), atteignable au J23 | absente |
| Noadkoko | évolution de Noeunoeuf (Pierre Plante) | absente (Noeunoeuf : J19) |
| Smogogo | Koga (et évolution de Smogo 35, **déjà possible** pour un Smogo du joueur) | absente |
| Tadmorv, Grotadmorv | Koga (Grotadmorv), lignée complète pour le Pokédex | absentes (à revérifier après fusion du J20, dont le Repaire cite Tadmorv) |
| Rhinocorne, Kangourex | Parc | J20 seulement |
| Noeunoeuf | Parc | J19 seulement |
| Soporifik, Hypnomade | Jongleurs de l'Arène | J17 seulement |
| Nidoran ♂/♀ et évolutions, Paras, Parasect, Kadabra, Sablaireau, Arbok, Smogo | Parc, Arène | présentes |

Illustrations : face adverse = artwork officiel, déjà présent pour les 151 ; dos de combat = pipeline
X/Y repeint (dossier « Pokémon art source ») pour toute espèce capturable ; planches de monde peintes
seulement pour les compagnons (règle existante).

---

## 7. Objets visibles, cachés et récompenses

| Lieu | Objet RB | K26 | Règle |
|---|---|---|---|
| Centre | Pépite | Pépite | existe |
| Est | Guérison, Potion Max, Carbone, CT37 Bomb'Œuf | Guérison ; **Potion Max → Hyper Potion** [D] ; **Carbone → Super Bonbon** ou rien [D] ; **CT37 → à créer** (Bomb'Œuf, capacité simple) [D] | « aucun objet pour une mécanique qui n'existe pas » : Potion Max, Carbone, Protéine, Rappel Max, Bomb'Œuf, Reflet sont **absents** du dépôt |
| Nord | Protéine, CT40 Coud'Krâne | **Protéine → Rappel** [D] ; CT40 Coud'Krâne (la capacité existe) | |
| Ouest | Potion Max, CT32 Reflet, Rappel Max, **Dents d'Or** | Hyper Potion ; **CT32 → à créer** (Reflet) [D] ; **Rappel Max → Rappel** [D] ; **Dents d'Or** (objet clé) | |
| Ouest (caché) | Rappel | Rappel | |
| Porte (caché) | Pépite inaccessible | **retirée** | bizarrerie RB |
| Maison Secrète | CS03 Surf | CS03 Surf, une fois | §9 |
| Maison du Gardien | CS04 Force (contre les Dents d'Or) ; Super Bonbon derrière un rocher | CS04 ; Super Bonbon **posé**, atteignable quand le J24 rend les rochers poussables | §9.2 |
| Arène | Badge Âme, CT06 Toxik | idem | §10 |

Arbitrage global des remplacements : **N-19**. Tous les objets uniques ramassés **restent acquis**
d'une visite à l'autre (drapeau de ramassage existant) [RB].

---

## 8. Scènes et dialogues (textes à valider, numérotés)

> Bulles de 2 lignes, ~40 caractères. `{joueur}`, `{pokemon}` comme d'habitude. Textes RB adaptés,
> jamais traduits mot à mot. **Kevin les relit en un seul lot** (réponse « 12 : … »).

**Porte du Safari**
1. Accueil : « Bienvenue au PARC SAFARI ! » / « L'entrée coûte 500 ₽. Tu tentes ta chance ? » → **OUI** / **NON**
2. NON : « Reviens quand tu veux ! »
3. Pas assez d'argent : « Oh… Il te manque de quoi payer l'entrée. »
4. Paiement : « Voici 30 SAFARI BALLS ! » / « Tu as 500 pas. On t'appellera au haut-parleur. »
5. Second employé, première visite : « Le PARC a quatre zones. » / « La Maison Secrète, au fond, garde un prix pour le premier visiteur ! »
6. Second employé, ensuite : « Les Pokémon d'ici sont farouches. » / « Un appât les calme, un caillou les agace. »
7. Sortie anticipée : « Tu pars déjà ? » → **OUI** / **NON**
8. OUI : « Les SAFARI BALLS restantes restent ici. Merci ! »
9. NON : « Bonne chasse ! »
10. Haut-parleur, pas épuisés : « Ding-dong ! Le temps est écoulé ! » / « Ta visite du PARC SAFARI est terminée. »
11. Haut-parleur, Balls épuisées : « Ding-dong ! Tu n'as plus de SAFARI BALLS ! » / « Ta visite du PARC SAFARI est terminée. »
12. Retour à la Porte : « Alors, bonne pêche ? Reviens vite ! »

**Dans le Parc**
13. Panneau d'entrée : « PARC SAFARI — ZONE CENTRE » / « Respectez les Pokémon, ne les nourrissez qu'aux appâts. »
14. Panneau Ouest : « Avis : le Gardien a perdu ses dents en or. » / « Merci de les lui rapporter ! »
15. Maison de repos (PNJ 1) : « Les Pokémon rapides fuient vite. » / « Un caillou, et ils filent encore plus vite ! »
16. Maison de repos (PNJ 2) : « J'ai marché toute la journée… » / « Et pas un seul Tauros. »
17. Maison de repos (PNJ 3) : « On dit qu'un Leveinard rôde au nord. »
18. Pêcheur expert, remise : « Bravo ! Tu as trouvé la Maison Secrète ! » / « Voici ton prix : la CS03, Surf ! »
19. Pêcheur expert, après : « Surf te portera sur l'eau. » / « Il te faudra le Badge Âme de Koga. »

**Rencontre Safari**
20. Apparition : « Un {pokemon} sauvage apparaît ! »
21. Lancer : « {joueur} lance une SAFARI BALL ! »
22. Appât : « {joueur} lance un appât. »
23. Caillou : « {joueur} lance un caillou. »
24. Repas : « {pokemon} mange ! »
25. Colère : « {pokemon} est en colère ! »
26. Fuite : « {pokemon} s'enfuit ! »
27. Fuite du joueur : « Tu t'éloignes doucement. »
28. Capture : textes de capture existants (« Et hop ! {pokemon} est capturé ! »).
29. Dernière Ball : « Ding-dong ! Tu n'as plus de SAFARI BALLS ! »

**Gardien (Parmanie)**
30. Sans les Dents d'Or : « Hif fuff hefifoo ! » / « Hoffuh hoff ! » → **OUI** / **NON**
31. OUI : « Huh ? Hoffu… ! »  · NON : « Hoffuh… fuff… »
32. Avec les Dents d'Or : « Hfuff… ? Mes dents ! Merci ! » / « Personne ne me comprenait. »
33. Remise : « Tiens, prends ça. C'est la CS04, Force. » / « Un Pokémon fort pourra pousser les rochers. »
34. Après : « Il faut le Badge Prisme pour s'en servir. » / « Et je te conseille le rocher, là-bas ! »

**Arène de Koga**
35. Panneau : « ARÈNE DE PARMANIE » / « Champion : Koga — le maître des poisons »
36. Guide, avant : « L'Arène de Koga est pleine de murs invisibles. » / « Observe le sol et avance pas à pas. »
37. Guide, après : « Le Badge Âme ! » / « Tes Pokémon peuvent maintenant surfer. »
38. Koga, avant : « Fwahahaha ! Un enfant ose me défier ? » / « Je suis Koga, maître ninja des poisons. »
39. Koga, suite : « Le poison et le sommeil » / « feront sombrer tes Pokémon. »
40. Koga, défaite : « Hmm ! Tu as prouvé ta valeur. » / « Voici le Badge Âme. »
41. Légende : « BADGE ÂME »
42. Koga, CT : « Prends aussi la CT06, Toxik. » / « Son poison empire à chaque tour. »
43. Rattrapage de la CT : « J'allais oublier. » (puis 42)
44. Après, en lui reparlant : « Le ninja se fond dans l'ombre. » / « Va, et ne sous-estime pas le poison. »
45. Mur invisible, au contact (première fois seulement) : aucun texte [D] — retour haptique et léger frémissement seulement (§10.1).

**Rocher du Gardien** (le reste des textes de Surf et de Force dans le monde appartient au J24)
46. Rocher, au J23 : « Un gros rocher. » / « Il faudrait beaucoup de force pour le pousser. »
47. à 55. *Retirés* (Surf et Force dans le monde : J24, P-2 B). Numéros laissés vides pour ne pas
    décaler la suite.

**Sac**
56. CS03 : « CS03 — SURF » / « Permet de nager sur l'eau. » / « Enseigne aussi une attaque. »
57. CS04 : « CS04 — FORCE » / « Permet de pousser les rochers. » / « Enseigne aussi une attaque. »
58. Dents d'Or : « DENTS D'OR » / « Le dentier en or du Gardien du Parc Safari. »
59. CT06 : « CT06 — TOXIK » / « Empoisonne gravement. »

**Objectifs** (convention minuscule et point) : « explorer le Parc Safari. » (à l'arrivée à Parmanie,
si le jalon précédent n'en pose pas) ; « rapporter ses dents au Gardien. » (Dents d'Or en main) ;
« défier Koga. » ; aucun objectif après le Badge Âme (exploration libre, décision 7).

---

## 9. CS03 Surf et CS04 Force : objets, combat, données

> **Partage avec le J24 (P-2 B, tranché le 2026-10-16)** : le J23 livre les **objets, les capacités,
> l'apprentissage hybride et les entrées de données** ; le J24 construit le **mode Surf dans le monde**
> (monture, verbe SURFER, eau surfable par carte, rencontres sur l'eau, transitions) et les **rochers
> de Force** (poussée, trous, courants), là où ils servent pour la première fois. Le critère de fin
> « obtenir Surf et Force » reste vrai.

### 9.1 Ce que livre le J23

- **Objets** : `hm03` « CS03 — Surf » (Maison Secrète) et `hm04` « CS04 — Force » (Gardien), catégorie
  CS, **jamais consommées**, remises **une fois** (`got_hm03`, `got_hm04`). [K26, J16]
- **Capacités de combat** (à créer) : **Surf** — Eau, 95, 100 %, 15 PP ; **Force** — Normal, 80,
  100 %, 15 PP. [RB]
- **Apprentissage hybride** : la CS s'enseigne comme une CT réutilisable (`tm_teach.gd`), prend un
  emplacement normal, s'oublie normalement. [K26, J16]
- **Entrées `data/world/field_moves.json`** : `"surf": { "hm": "hm03", "badge": "badge_soul" }` et
  `"strength": { "hm": "hm04", "badge": "badge_rainbow" }` (conditions **RB**, confirmées dans
  `start_sub_menus.asm`). Elles ne sont lues par aucun déclencheur de monde avant le J24.
- **Compatibilités** : `tm_compatibility.json` (`hms` 03 et 04) **régénéré** après la fusion des
  jalons 16 à 22 et l'ajout des espèces du §6.4.
- **Textes du Sac** (56, 57) et du Pêcheur expert / Gardien (18, 19, 33, 34).

### 9.2 Ce qui n'est pas au J23

- Aucune eau surfable au J23, ni dans le Parc ni à Parmanie (la côte sud de Parmanie s'ouvre au J24,
  P-3 B).
- **Rocher du Gardien** : posé au J23 comme **obstacle fixe** devant le Super Bonbon, avec le texte 46 ;
  le J24 le rend poussable (son premier rocher de « monde construit »). Le Super Bonbon reste
  inaccessible jusque-là [D, **N-13**].
  Contraintes de grille (accord avec le dossier 27 §6.5) : **même image** que les rochers de Force du
  J24 ; le rocher ne touche ni la porte ni le Gardien, et **une case libre** reste devant la porte
  quelle que soit sa position ; il reprend sa place à la sortie de la carte (RB, sans drapeau).
- Après le Badge Âme, aucun texte ne promet la mer (le Guide dit seulement ce que permet le badge,
  texte 37).

## 10. Arène de Koga, Dresseurs et Champion

### 10.1 Salle et murs invisibles

- **Géométrie RB 1:1** : 10 × 18 cases ; entrée en bas ; **Koga au centre-bas** (4, 10), pas au fond ;
  murs invisibles sur presque toute la moitié haute ; Guide et deux statues près de l'entrée. [RB]
- **Les murs bloquent** comme des murs ; ils ne disparaissent pas après la victoire. [RB]
- **Indices lisibles sur téléphone** [D, **N-15**], du plus discret au plus net :
  1. **au sol** : le parquet change très légèrement de sens ou de jointure sous chaque mur (visible
     si on le cherche, invisible au premier coup d'œil) ;
  2. **au contact** : retour haptique court, petit son mat, et le mur **frémit** 0,4 s (reflet
     translucide d'un panneau de papier, comme une cloison de dojo), puis redevient invisible ;
  3. **jamais** de surbrillance permanente, de flèche ni de case colorée.
- Lumière : salle sombre, lanternes, brume basse légère (`MistLayer` existant) ; le puzzle reste
  lisible sans la brume.

### 10.2 Dresseurs (RB, `data/maps/objects/FuchsiaGym.asm`, `parties.asm`)

| Pos. RB (vue) | Classe | Équipe RB | Remarque K26 |
|---|---|---|---|
| (8,13) (2) | Jongleur | Hypnomade 38 | |
| (7,8) (2) | Jongleur | Soporifik ×2, Kadabra, Soporifik 31 | |
| (1,12) (4) | Jongleur | Soporifik, Kadabra 34 | |
| (3,5) (2) | Dompteur | Sablaireau, Arbok 34 | |
| (8,2) (2) | Dompteur | Arbok, Sablaireau, Arbok 33 | |
| (2,7) (2) | Jongleur | Soporifik, Hypnomade 34 | |

Six Dresseurs, positions et vues RB [D]. Les inévitables se déduisent de la grille (`plan_check` les
liste). Niveaux finaux **fixés par simulation** (règle du projet) ; difficulté par défaut ≤ 80 % de
victoire au premier essai. Classes Jongleur et Dompteur : sprites à peindre si absents (le Jongleur est
aussi prévu à la Sylphe du J22).

### 10.3 Koga

| Pokémon | Niveau RB | Attaques RB | Disponibles ? |
|---|---|---|---|
| Smogo | 37 | Charge, Purédpois, Détritus, Brouillard | oui (`tackle`, `smog`, `sludge`, `haze`) |
| Grotadmorv | 39 | Entrave, Gaz Toxik, Lilliput, Détritus | oui après fusion du J17 (`poison_gas`) ; `disable`, `minimize`, `sludge` existent |
| Smogo | 37 | idem | oui |
| Smogogo | 43 | Purédpois, Détritus, **Toxik**, Destruction | **Toxik à créer** ; `self_destruct` existe |

- **Aucun remplacement nécessaire** si Toxik est créé (il doit l'être pour la CT06) et si la fusion
  du J17 apporte Gaz Toxik. Repli si Gaz Toxik manquait encore : **Purédpois** (même rôle, existant)
  [D].
- **Espèces à créer** : Grotadmorv, Smogogo (§6.4).
- **IA** : `smart` (Destruction seulement sous 1/4 des PV : règle existante). Lilliput + Brouillard
  donnent le rythme « anticipation » du dossier 06 ; la simulation dira si Lilliput cumulé dépasse
  la bande « grand combat » 35–60 % ; si oui, on baisse les niveaux, jamais les attaques sans
  Kevin [D].
- Récompense : argent RB (base 99 × 43 = 4 257 ₽) ; Badge Âme ; CT06 Toxik (avec rattrapage, modèle
  Major Bob). Grand moment « Badge Âme ». [RB]
- Le Badge Âme **n'a aucun effet caché** (dossier 12) : seulement la condition de Surf. Le bonus de
  Vitesse RB n'est pas repris. [K26]

### 10.4 Toxik (mécanique de combat nouvelle, obligatoire)

- **Toxik** : Poison, statut, précision 85 %, 10 PP. [RB]
- **Poison grave** : dégâts N/16 des PV max, N = 1, 2, 3… à chaque fin de tour. [RB]
- **Particularités RB** proposées [D, **N-14**] : le compteur repart à zéro et le poison grave
  redevient **poison simple** quand le Pokémon est **changé** ou **à la fin du combat**. L'interaction
  RB avec Vampigraine **n'est pas** reprise.
- Hors combat : comme le poison simple (aucun effet, règle du J11).
- Interface : même pastille PSN, libellé « PSN+ » ou teinte plus sombre [D].

---

## 11. Drapeaux et données persistantes

| Nom | Posé quand | Remarque |
|---|---|---|
| `safari_intro_heard` | première explication du second employé (texte 5) | |
| `got_hm03` | remise de la CS03 | **dans la même écriture** que l'ajout de l'objet ; réconciliation au chargement (objet sans drapeau → drapeau ; drapeau sans objet → objet rendu une fois, anomalie journalisée), modèle du J16 |
| (ramassage existant) | Dents d'Or ramassées | drapeau de ramassage habituel de l'objet visible |
| `gave_gold_teeth` | Dents d'Or retirées du Sac | posé **avec** le retrait |
| `got_hm04` | remise de la CS04 | si l'écriture est interrompue entre `gave_gold_teeth` et `got_hm04`, le Gardien redonne la CS au dialogue suivant (RB) |
| `koga_met` | premier dialogue de Koga | modèle `surge_met` |
| `badge_soul` | victoire contre Koga | existant dans `badges.json` |
| `tm06_received` | remise de la CT06 | rattrapage si absent |
| `beaten_fuchsia_gym_*` | Dresseurs de l'Arène | règle existante |

**Champ de sauvegarde nouveau : la visite en cours** [K26] :

```
safari = { active: bool, steps_left: int, balls_left: int }
```

- Il change le schéma : **v8** (ou la version suivant celle des J16–J22 si l'une l'a déjà changée),
  migration : `active = false`. → **N-20**.
- Position du joueur : aucun champ nouveau ; l'état « sur l'eau » et les rochers relèvent du J24.

---

## 12. Cas limites et migrations

### 12.1 Parc Safari

| Cas | Comportement |
|---|---|
| Moins de 500 ₽ | texte 3, le joueur recule d'un pas [RB] |
| Équipe pleine | la capture va au Stockage (illimité) ; message existant [K26 : pas de « BOÎTE pleine »] |
| Fin des pas au milieu d'une maison | annonce, puis fondu vers la Porte [RB] |
| Dernier pas qui déclenche une rencontre | le combat se joue ; la fin vient au pas suivant [RB] |
| Dernière Ball qui capture | capture enregistrée, puis fin de visite au retour sur la carte [RB] |
| Corde Sortie | fin de visite, Balls perdues [RB] |
| Application tuée en marchant | reprise à la dernière sauvegarde (arrivée sur la carte, fin de combat, capture, mise en pause) ; les pas faits depuis peuvent être rendus : **accepté** [D] |
| Application tuée en pleine rencontre | reprise avant la rencontre, Balls de cette rencontre rendues, capture perdue : **accepté**, comme pour toute rencontre sauvage du jeu [D, **N-9**] |
| Visite active au chargement mais joueur hors du Parc (sauvegarde incohérente) | visite close (`active = false`), sans remboursement |
| Joueur dans le Parc mais `active = false` (ancienne sauvegarde, bug) | renvoyé à la Porte avec un message neutre, sans débit |
| Défaite | impossible dans le Parc (aucun combat) |
| Compagnon | suit le joueur dans le Parc (extérieur) ; rentre dans sa Ball dans les maisons (existant) |

### 12.2 CS, Dents d'Or, Arène

| Cas | Comportement |
|---|---|
| CS03 reçue sans Badge Âme | aucune conséquence au J23 (le J24 gère l'eau) |
| CS04 reçue sans Badge Prisme | aucune conséquence au J23 ; Force s'enseigne quand même en combat |
| Dents d'Or ramassées, visite terminée | elles restent dans le Sac [RB] |
| Joueur qui parle au Gardien avant les Dents d'Or | texte 30, OUI/NON sans effet [RB] |
| CT06 non remise (interruption) | rattrapage au dialogue suivant (texte 43) |
| Koga perdu | retour au dernier Centre, sans perte (règle du projet) ; Koga reste affrontable |

### 12.3 Risque de blocage d'argent

- RB n'a pas de garde-fou ; le blocage réel y est presque impossible (vente d'objets, Dresseurs non
  battus des Routes 12 à 15, Jackpot).
- Au projet : **vente à moitié prix** (Pépite comprise), **Jackpot** (J15), Dresseurs des routes du
  jalon de Parmanie, et une **Pépite** dans la zone Centre (rentable dès la première visite).
- Une visite suffit pour Surf **et** Force (contrôle des 300 pas, §2.2).
- Proposition : **aucune règle propre au Safari** (conforme à la V2) ; un test de données vérifie
  qu'entre la dernière Arène et la Porte, le joueur a au moins N objets vendables ou Dresseurs non
  battus valant ≥ 500 ₽ [D, **N-17**].

### 12.4 Migration

- v7 (ou version J22) → v8 : ajout de `safari` inactif. Aucune autre donnée touchée.
- Les sauvegardes antérieures au J23 n'ont ni CS03 ni CS04 : rien à réconcilier.

---

## 13. Assets peints, sprites et fonds de combat (CB.3)

**Cartes et intérieurs**
- Vues générales peintes et plans : Porte, **quatre zones** (Centre, Est, Nord, Ouest), Arène de Koga
  (avec les jointures de sol qui trahissent les murs).
- Intérieurs : maison de repos (**un seul**, réutilisé × 4), Maison Secrète, maison du Gardien (si
  Parmanie ne la fournit pas).
- Accessoires : rocher (même image que celui du J24), statue de Kangourex, panneaux du Parc, haies, îlots.

**Personnages**
- Koga (monde + carte de Champion) ; Gardien ; Pêcheur expert ; employés de la Porte (réutiliser un
  modèle d'employé existant [D]) ; Jongleur, Dompteur ; trois visiteurs des maisons de repos
  (réutilisés).
- **Dos du joueur en combat** avec un geste de lancer (Ball, appât, caillou : un seul geste, trois
  petits objets dessinés) — vérifier ce qui existe pour le début des combats de Dresseurs.

**Pokémon**
- Dos de combat (pipeline X/Y repeint) : Leveinard, Insécateur, Scarabrute, Tauros, Mimitoss, Aéromite,
  Doduo, Dodrio, Rhinoféros, Noadkoko, Smogogo, Grotadmorv, Tadmorv (+ Rhinocorne, Kangourex,
  Noeunoeuf s'ils ne sont pas faits au J19–J20).

**Fonds de combat CB.3** (`data/battle/decors.json`)
- **Parc Safari** : un décor par zone [D] (prairie et étang ; plaine sèche ; colline ; marais), ou
  un décor commun avec variantes de lumière (**N-18**).
- **Arène de Koga** : salle sombre, lanternes.
- Aucun décor « eau » au J23 (pas de rencontre en surfant).

---

## 14. Découpage 23.0 à 23F

Le découpage de la V2 est repris ; deux ajustements [D, **N-21**] :
- **23A** contient le nouveau champ de sauvegarde : il est validé **seul** sur ce point (règle
  « système risqué ») ;
- **23D** n'a plus de moteur de monde (P-2 B) : objets, capacités, données. Il est assez petit pour
  être **fusionné avec 23C** dans une même validation.

| Lot | Contenu | Prérequis | S24 |
|---|---|---|---|
| **23.0** | Présent dossier validé ; fusion J16–J22 dans `main` ; grilles `safari_*.txt` et Arène ; vues générales ; données isolées (espèces, attaques Surf, Force, Toxik, Bomb'Œuf, Reflet) ; logique pure du mode Safari (`SafariRules` : compteurs, appât, caillou, fuite, Ball) testée hors scène | passes J22 et J23 tranchées | non |
| **23A** | Porte, péage, quatre zones, raccords, maisons de repos, objets, compteur de pas et de Balls, pastille, fin de visite, sauvegarde v8 | 23.0, Parmanie | oui (sauvegarde : tuer l'appli à chaque étape) |
| **23B** | Rencontres Safari : tables, écran et menu Safari, appât, caillou, fuite, capture, Pokédex, fin par les Balls | 23A | oui |
| **23C** | Maison Secrète et CS03 ; Dents d'Or ; Gardien et CS04 ; rocher fixe ; réconciliations | 23A | regroupé avec 23D |
| **23D** | Capacités Surf et Force en combat ; apprentissage hybride ; entrées `field_moves.json` ; compatibilités régénérées (le mode Surf et les rochers : J24) | 23C | oui, avec 23C |
| **23E** | Arène : murs invisibles et indices, 6 Dresseurs, Koga, Toxik, Badge Âme, CT06 | 23D | oui |
| **23F** | Simulation et équilibrage (Koga, Dresseurs), non-régression, sauvegarde / rechargement à chaque transition, retrait des cartes de QA, QA de bout en bout | tout | oui (clôture) |

---

## 15. Tests automatisés et QA Galaxy S24

**Logique pure (GUT, sans scène)**
- `SafariRules` : appât (÷ 2, compteur 1–5, colère à 0) ; caillou (× 2 plafonné, repas à 0) ;
  décrément de fin de tour ; retour au taux de base en fin de colère ; **division d'appât jamais
  annulée** ; formule de fuite (÷ 4, × 2 plafonné) ; aucune fuite avant la première action ; FUIR
  toujours réussi ; tirages contrôlés par graine.
- Compteur : pivot, collision, dialogue et menu ne comptent pas ; porte et raccord comptent ; fin au
  pas qui suit le zéro ; fin par les Balls ; Corde Sortie.
- Tables : poids et niveaux RB, partage des versions, Insécateur et Scarabrute présents.
- Field moves : états `NO_HM` / `NO_BADGE` / `NO_POKEMON` / `READY` calculés pour `surf` et
  `strength` (sans déclencheur de monde) ; apprentissage et oubli de Surf et Force en combat.
- Pêche dans le Parc (si N-6) : rencontre pêchée = rencontre Safari ; le lancer ne coûte pas de pas.
- Toxik : N/16 croissant, remise à zéro au changement et en fin de combat, précision 85 %.
- Sauvegarde : migration v7 → v8 ; aller-retour du champ `safari` ; réconciliations CS03, CS04,
  Dents d'Or ; aucune duplication après interruption à chaque point d'écriture.
- Données : `plan_check` (300 pas, atteignabilité, inévitables de l'Arène) ; argent ≥ 500 ₽
  atteignable (§12.3) ; aucun objet référant à une capacité ou un objet absent.

**QA S24 (bornée, départs de débogage, 30–45 min par sous-jalon)**
- 23A : entrée avec et sans argent ; marcher, pivoter, entrer dans une maison ; fin par les pas ;
  sortie volontaire ; **tuer l'appli** dans chaque zone et dans une maison, puis reprendre.
- 23B : lisibilité du menu Safari ; 10 rencontres avec appâts et cailloux ; capture avec équipe
  pleine ; dernière Ball.
- 23C–23D : remise des CS, Gardien, rocher fixe ; apprendre Surf et Force à un Pokémon, s'en servir
  en combat, les oublier.
- 23E : traverser l'Arène **sans indication extérieure** (le testeur ne connaît pas la carte) :
  temps et nombre de chocs notés ; combat de Koga ; Badge Âme et CT06.
- Captures d'écran relues ; fps dans le Parc (quatre grandes cartes peintes).

---

## 16. Questions ouvertes (à trancher par numéro)

> Réponse attendue sous la forme « N-1 ok, N-6 : B, … ». **Reco** = ma recommandation. Les numéros
> laissés vides correspondent à des questions résolues depuis la première version.

| # | Question | Reco |
|---|---|---|
| **N-1** | ~~Quel jalon construit Parmanie ?~~ **Résolu** : le J22 (recadrage du 2026-10-16). Reste à trancher côté J22 : M-19 (maison du Gardien réservée au J23) | M-19 B |
| **N-2** | Koga devient le **5e badge** (ordre RB). Niveaux RB (Koga 37–43, Dresseurs 31–38) comme référence, ajustés par simulation (≤ 80 % au premier essai, grand combat 35–60 %) | ok |
| **N-3** | Cartes du Parc à l'échelle **RB 1:1** (et non × 1,5 comme Parmanie) pour que 500 pas gardent leur sens ; contrôle « une visite suffit » ≤ 300 pas | 1:1 |
| **N-4** | Versions réunies : Insécateur **et** Scarabrute ; Nidoran ♂ et ♀ à parts égales (précédent J12 / J15) | ok |
| **N-5** | Safari Ball = multiplicateur de l'**Ultra Ball (× 2)** dans la formule du projet (RB : « comme l'Ultra Ball ») ; alternative × 1,5 (RFVF). Appât, caillou et fuite exactement RB, particularités comprises | × 2 |
| **N-6** | Pêche dans le Parc : **A** étangs pêchables avec les tables RB (Minidraco à la Méga Canne), rencontre Safari, le lancer ne coûte pas de pas — si le J22 livre la pêche · **B** pas de pêche au J23 | **A** |
| **N-7** | Pastille discrète « pas · Balls » visible seulement dans le Parc, sans alerte (RB : chiffres dans le menu Start) | pastille, sans alerte |
| **N-8** | Fin de visite au **pas qui suit** le zéro (RB), pour pouvoir encore parler ou ramasser | ok |
| **N-9** | Application tuée en pleine rencontre Safari : reprise avant la rencontre, Balls rendues (comme toute rencontre) | accepté |
| N-10 | ~~Eau navigable au J23~~ **Résolu** : aucune (P-3 B) | — |
| N-11 | ~~Monture de Surf~~ **Résolu** : J24 | — |
| N-12 | ~~Compagnon pendant le Surf~~ **Résolu** : J24 | — |
| **N-13** | Rocher du Gardien : obstacle fixe au J23, Super Bonbon atteignable seulement après le J24 (pas de rocher « provisoire » sans Force) | ok |
| **N-14** | Toxik RB : remise à zéro au changement et en fin de combat (devient poison simple) ; sans l'interaction avec Vampigraine | ok |
| **N-15** | Murs de l'Arène : jointures de sol très légères + frémissement et retour haptique au contact ; rien de permanent ; les murs restent après la victoire | ok |
| **N-16** | Arène : 6 Dresseurs et positions RB, Koga au centre-bas, Guide à l'entrée | ok |
| **N-17** | Argent : **aucune règle Safari** ; Pépite dans la zone Centre ; test de données « ≥ 500 ₽ atteignables » | ok |
| **N-18** | Fonds de combat du Parc : un par zone (4) ou un commun avec variantes de lumière | un commun + 4 lumières (coût) |
| **N-19** | Objets RB absents du jeu : Potion Max → Hyper Potion, Rappel Max → Rappel, Carbone → Super Bonbon, Protéine → Rappel ; **CT37 Bomb'Œuf** et **CT32 Reflet** créées (capacités simples). À aligner avec M-16 du J22 (vitamines) | ok |
| **N-20** | Visite Safari sauvegardée (champ `safari`, **v8** ou suivante) plutôt que perdue au rechargement | ok |
| **N-21** | Découpage de la V2 conservé ; 23A validé seul pour la sauvegarde ; 23C et 23D validés ensemble (23D sans moteur de monde) | ok |
| **N-22** | Évolutions atteignables au J23 dans les données : Dodrio, Aéromite, Rhinoféros, Noadkoko, Smogogo, Grotadmorv | ok |
| **N-23** | Le dossier 24 (J21) range encore « Route 12 sud, 13–15, Parmanie » au J22 : désormais juste ; seule la mention de Safrania est à corriger côté J22 | ok |
| **N-24** | **CS02 Vol** : la passe du J22 (M-18 C) réserve la maison de Vol « au J23 ». Ce n'est pas dans le périmètre verrouillé du J23 (Safari, CS03, CS04, Koga). **A** Vol reste hors du J23 ; la porte reste réservée pour un jalon des CS / du voyage rapide · **B** le J23 l'ajoute (objet, combat, système de Vol) | **A** : le Vol est un système à part entière (voyage rapide, carte), il alourdirait le J23 |

## Annexe — Ce que la V2 change par rapport à RB (récapitulatif)

| Point | RB | K26 |
|---|---|---|
| Parcours du Parc | 4 cartes reliées par warps | 4 cartes, raccords continus |
| Safari Balls | compteur de visite | idem |
| Pas | 502 (2 scriptés) | 500 joueur |
| BOÎTE pleine | lancer refusé | n'existe pas (stockage illimité) |
| Pêche dans le Parc | 3 cannes, Minidraco | avec la pêche du J22 (N-6) |
| Badge Âme | Surf + bonus de Vitesse | Surf seulement (aucun effet caché) |
| Flash | Badge Roche | sans badge (J17, déjà décidé) |
| Objets absents du jeu | Potion Max, Carbone, Protéine, Rappel Max | remplacés (N-19) |
| Murs invisibles | totalement invisibles | indices très légers (décision 6) |
| Surf et Force dans le monde | dès la CS et le badge | objets et combat au J23, monde au J24 (P-2 B) |
