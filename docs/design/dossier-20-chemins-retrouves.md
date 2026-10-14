# Dossier 20 — Les chemins retrouvés : Route 11, Cave Taupiqueur, Route 2 est, CS05 Flash (jalon 17)

> **Arbitrages tranchés par Kevin le 2026-10-14 ; textes du §16 à valider.** Consolidé par Claude le
> 2026-10-14 à partir de la V2 de Kevin avec ChatGPT (`passes/j17-v2-chatgpt.md`, 6 décisions), de
> la passe d'alignement (`passes/j17-v2-alignement.md`, H-1 à H-17) et du retour de Kevin (**H-1 à
> H-17 retenus tels quels**). Prochaine étape : validation des textes (§16), grilles fonctionnelles
> et vues générales peintes, puis plan `docs/tech/jalon-17.md`.
>
> **Numérotation** : 16 (J13), 17 (J14), 18 (J15) pris, 19 réservé au J16 → **20** (vérifié sur
> toutes les branches locales et distantes le 2026-10-14).
>
> Légende : **[V]** décision de Kevin · **[D]** valeur par défaut technique (règle 4 de `CLAUDE.md`,
> modifiable sans rouvrir la conception) · **[T]** texte à valider (§16).
> Origine des règles : **RB** Rouge/Bleu (vérifié sur `pret/pokered` et PokeAPI) · **K26** Kanto 2026.

**Ligne directrice** : *Kanto commence à se reconnecter.* Le joueur réutilise ce qu'il sait et
redécouvre des lieux familiers : une route qui longe la mer, un tunnel creusé par des Pokémon, et un
sentier fermé de la Route 2 qui s'ouvre enfin, de l'autre côté. Aucun Champion, aucun rival, aucune
Team Rocket : un jalon de respiration et d'exploration.

## Décisions

| N° | Décision | Statut |
|---|---|---|
| 1 | Périmètre : **Route 11 + Cave Taupiqueur + Route 2 revisitée** (couloir est, FUTUR A, FUTUR B) | [V] |
| 2 | Cave **courte et naturelle**, quelques renfoncements, sans Flash | [V] |
| 3 | Raccourcis et découvertes ouverts par Coupe | [V] |
| 4 | **CS05 Flash** remise par un assistant de Chen contre **10 espèces possédées** | [V] |
| 5 | Route 11 complète, Dresseurs, **Ronflex** bloquant à l'est | [V] |
| 6 | Grotte obscure (Tunnel Roche) et Route 9 au **J18** | [V] |
| H-1 | Route 11 ouverte **dès l'arrivée à Carmin**, sans condition (RB) | [V] |
| H-2 | Assistant et CS05 atteignables **sans Coupe** (par la Cave). Coupe n'ouvre que des bonus | [V] |
| H-3 | **Nouvelle carte `route_2_east`** (zone `route_2`) ; barrière de FUTUR B ouverte depuis l'est, définitivement ; éboulis fermés | [V] |
| H-4 | FUTUR A = **arbuste coupable** ; petite clairière avec 1 objet, dans la carte existante | [V] |
| H-5 | Arbustes **définitifs** (G-4 du J16) ; pas de repousse | [V] |
| H-6 | CS05 sur le **modèle hybride de Coupe** (G-2) ; aucune condition de badge ; en combat, précision 70 %, Précision de l'adversaire −1 | [V] |
| H-7 | Flash **automatique** à l'entrée d'une carte obscure, courte mise en scène | [V] |
| H-8 | **Fondation** de l'éclairage au J17 sur une carte de QA ; réglage au J18 | [V] |
| H-9 | Condition : `caught_count() ≥ 10` ; l'assistant dit le compte actuel | [V] |
| H-10 | Ronflex au bout est de la Route 11, infranchissable, sans entrée au Pokédex | [V] |
| H-11 | Assistant au Cherch'Objet **reporté** | [V] |
| H-12 | Maison d'échange **absente** | [V] |
| H-13 | **8 Dresseurs**, équipes RB sans les 2 Joueurs aux espèces absentes ; Magnéti, Magnéton, Caninos, Goupix côté adversaire seulement ; au plus 1 inévitable | [V] |
| H-14 | Rencontres Rouge **et** Bleu réunies ; Hypno créé | [V] |
| H-15 | Triopikeur 5 %, **Nv. 24–26** | [V] |
| H-16 | Nom officiel **« Cave Taupiqueur »** partout | [V] |
| H-17 | Validation S24 : **17A → 17B → 17C → 17D** | [V] |

## Grilles fonctionnelles (2026-10-14, à valider par Kevin avec les vues générales)

- **Grilles (autorité de la géométrie ; en cas de contradiction, la grille gagne)** :
  `tools/plans/route_11.txt` (76 × 36), `digletts_cave.txt` (34 × 80), `route_2_east.txt` (16 × 48),
  `route_2_east_gate.txt` (15 × 10) ; retouches de la Route 2 sud dans `route_2_j17_retouches.txt`
  (`route_2.txt` n'est modifié qu'à l'implémentation). Contrôle : `tools/art/plan_check_j17.py`
  (tous les critères passent). Plans : `reference/route-11-plan-v1.png`,
  `cave-taupiqueur-plan-v1.png`, `route-2-est-plan-v1.png` (+ versions `-annote-`).
- **Raccords** : Carmin (63, 11..13) ↔ Route 11 (0, 11..13) ; bouche de la Cave (15..16, 7) ↔ Cave
  (15..16, 79) ; Cave (16..17, 0) ↔ Route 2 est (6..7, 3) ; Route 2 est (0, 43..44) ↔ Route 2 sud
  (41, 43..44) ; porte du poste (11, 11).
- **Mesures** : Carmin → bouche de la Cave 20 pas ; Cave 96 pas (un seul sol de gravats
  obligatoire) ; bouche nord → poste 12 pas **sans Coupe** ; bouche nord → bord ouest 45 pas avec
  Coupe ; Carmin → Ronflex 71 à 83 pas selon le parcours (trois parcours : herbes au nord, chemin
  central, digue au sud).
- **Écarts avec le §3 [D]** : le goulet d'Arthur (D2) est **à l'ouest** de la bouche de la Cave, pour
  qu'il soit inévitable vers la Cave comme vers l'est (bouche en haut de l'écran d'arrivée : à vérifier
  sur S24) ; la clairière de FUTUR A occupe **x 0..3, y 16..22** (les colonnes 4..6 portent l'arbuste
  et la retouche peinte, et (3, 16) reste forêt pour qu'on ne la rejoigne pas par la prairie de la
  rangée 15 sans Coupe) ; Ronflex en (66..67, 14..15) dans un goulet de 2 cases.

## 1. Hors périmètre

Route 9, Route 10, Tunnel Roche, Lavanville (J18) ; Route 12 et réveil de Ronflex (jalon de la Poké
Flûte) ; Cherch'Objet ; échanges ; vitamines (PV Plus, §9) ; vélo ; pêche ; Repousse. Aucune carte
obscure dans le jeu au J17 (seulement la carte de QA, H-8).

## 2. Hypothèses d'entrée

| Reçu de | Attendu |
|---|---|
| J15 | Carmin, bord est (63, 11..13) « ROUTE 11 — À venir », arrivée `from_route_11` réservée ; Centre de Carmin ; sauvegarde v7 |
| J16 | CS01, Coupe dans le monde (G-2), arbustes définitifs (G-4), **cases libérées par un drapeau**, `FieldMoves.can_cut`, section CS de `tm_compatibility.json`, textes génériques de l'arbuste (avec / sans Pokémon compatible) |
| J12 | Kit de grotte : terrain `rubble`, profils `cave_*`, voile de pénombre précalculé, `LightGlow`, Corde Sortie |
| J14 | Super Bonbon (`rare_candy`) |

Si un de ces jeux livre autrement, c'est le J17 qui s'aligne. **Rien du chemin principal du J17 ne
dépend du J16** (H-2) : seuls l'arbuste du couloir, FUTUR A et le raccourci l'attendent.

## 3. Géographie

```text
                      ROUTE 2 NORD (éboulis fermés, inchangés)
                                  ·
   ROUTE 2 SUD          ROUTE 2 EST (carte neuve, H-3)
   FUTUR A ◄ arbuste     ┌─ bouche nord de la CAVE ─┐
   (clairière, H-4)      │  poste de l'assistant     │
                         │  ── arbuste ──            │
   FUTUR B barrière ◄────┤  Pierre Lune, Super Bonbon│
   (ouverte de l'est)    └───────────────────────────┘
                                  │
                           CAVE TAUPIQUEUR (nord → sud)
                                  │
   CARMIN-SUR-MER ═══ ROUTE 11 (bouche sud de la Cave à l'ouest) ═══ RONFLEX ║ (Route 12)
```

### 3.1 Raccords [D, recalés par les grilles]

| De | Vers | Forme |
|---|---|---|
| Carmin (63, 11..13) | Route 11, bord ouest (3 cases) | bord, mêmes rangées |
| Route 11, partie ouest, côté nord | Cave, bouche sud | ouverture dans la paroi, STEP_ON ↑ |
| Cave, bouche nord | Route 2 est, extrémité nord | ouverture, STEP_ON |
| Route 2 est, bord ouest (partie sud, 2 cases) | Route 2 sud (41, 43..44) | bord ; le sentier peint `b` (35..41, 43..44) devient praticable, la barrière reste en (34, 43..44) |
| Route 2 est, porte du poste | intérieur `route_2_east_gate` (une pièce) | porte, STEP_ON ↑ |
| Route 2 sud, arbuste FUTUR A (4, 19) | clairière ouest (colonnes 0..6, rangées 16..22) | case libérée par Coupe |
| Route 11, bord est | aucun | Ronflex sur la route, la case du bord n'est pas atteignable |

### 3.2 Route 11 (≈ 76 × 36) [D]

Route côtière horizontale, la mer au sud, les prairies au nord. **Plusieurs parcours sans
labyrinthe** : un chemin principal à angles droits et deux variantes par les herbes ou par une
rangée de clôtures. Repères d'ouest en est : la bouche de la Cave dans un talus rocheux au nord-ouest
(visible depuis Carmin) ; une prairie centrale avec les Dresseurs ; une portion de digue le long de la
mer ; à l'est, Ronflex endormi en travers de la route, vu de loin.
**Ronflex** : PNJ présent tant que `snorlax_route_11_awake` n'est pas posé ; il occupe les cases du
seul passage vers le bord est ; aucune case contournable (contrôle `plan_check`).
**Dresseurs** : 8 (§6), dont **1 inévitable** au plus, dans un goulet du chemin principal [D].

### 3.3 Cave Taupiqueur (≈ 34 × 80) [D]

Tunnel **principalement linéaire**, du sud (Route 11) au nord (Route 2 est), creusé dans une roche
claire et sableuse ; lumière naturelle lisible (profil `cave_1f` du J12 ou dérivé) ; des Taupiqueur
d'ambiance passent la tête hors du sol. **Deux renfoncements** facultatifs, l'un avec un objet (§7).
Rencontres sur les sols de gravats identifiables (B-3 du J12), couloirs calmes entre eux. **Bouches
naturelles**, sans bâtiment ni PNJ (RB : deux maisonnettes) [D]. Aucun Dresseur.

### 3.4 Route 2 est (≈ 16 × 48) [D]

Couloir boisé à l'est de la forêt, parallèle à la Route 2. Du nord au sud :
1. **Bouche nord de la Cave**, dans une paroi rocheuse ; au nord-ouest, l'arrière des éboulis de la
   Route 2 nord, visible, infranchissable.
2. **Poste de l'assistant** : petit bâtiment en bois et ardoise (même famille que les postes de la
   forêt), porte au sud.
3. **Arbuste** `cut_route_2_east_bush` en travers du chemin.
4. **Partie sud** : clairière avec **Pierre Lune** et **Super Bonbon** (§7).
5. **Bord ouest** vers le sentier `b` de la Route 2 sud et la **barrière de FUTUR B**.
Pas d'herbes hautes, pas de Dresseur [D].

### 3.5 Route 2 sud, retouches

- **FUTUR A** : l'arbre dense devient un **arbuste coupable** (`cut_route_2_futur_a`). Avant le J17,
  son texte reste celui du dossier 11 (T7) ; avec la CS01, il prend les textes génériques du J16.
  Derrière : le sentier peint `aaaa` mène à une **petite clairière** taillée dans la forêt (colonnes
  0..6, rangées 16..22), avec **1 objet** et une trouée sur la canopée. Retouche du fond peint.
- **FUTUR B** : la barrière (34, 43..44) **s'ouvre depuis l'est** : le joueur arrivé par le couloir
  l'examine, elle s'ouvre (`route_2_east_gate_open`), définitivement. Depuis l'ouest, tant qu'elle est
  fermée, son texte reste T9 du dossier 11 ; le panneau (33, 42) change de texte après l'ouverture.
- Les éboulis de la Route 2 nord : **inchangés** (dossier 12, arbitrage 9).

### 3.6 Zone et Carte

`route_2_east` appartient à la zone **`route_2`** (une seule « Route 2 » dans la Carte et le Pokédex,
comme la Route 2 nord). Nouvelles zones : `route_11`, `digletts_cave` (« CAVE TAUPIQUEUR »). Titres
d'arrivée : « ROUTE 11 », « CAVE TAUPIQUEUR » ; le couloir garde le titre de la Route 2.

## 4. Ordre de jeu et équilibrage

La Route 11 s'ouvre dès Carmin (H-1) : le joueur peut y arriver **avant le S.S. Anne**, vers le
Nv. 18–22. Les niveaux du §5 et du §6 sont des références RB, **recalés par la simulation du plan**
(comme au J12) pour ce profil, sans dépasser les références de Major Bob.

## 5. Rencontres

| Lieu | Espèce | Poids | Niveaux | Origine |
|---|---|---|---|---|
| Route 11, herbes | Abo | 20 | 12–15 | RB (Rouge) |
| | Sabelette | 20 | 12–15 | RB (Bleu) |
| | Piafabec | 35 | 13–17 | RB |
| | Soporifik | 25 | 9–15 | RB |
| Cave Taupiqueur, gravats | Taupiqueur | 95 | 15–22 | RB |
| | Triopikeur | 5 | **24–26** | K26 (H-15 ; RB 29–31) |

Taux de rencontre : celui des routes pour la Route 11, celui du Mont Sélénite pour la Cave [D].
Route 2 est : aucune rencontre [D].

**Espèces nouvelles** (données, Pokédex, dos de combat, sprite du monde si visible) : **Taupiqueur,
Triopikeur, Soporifik, Hypno** (évolution de Soporifik au Nv. 26, atteignable). **Côté adversaire
seulement** (données + Pokédex ; artwork officiel déjà présent) : **Magnéti, Magnéton, Caninos,
Goupix**. **Ronflex** : sprite du monde seul, sans données ni Pokédex au J17.

## 6. Dresseurs de la Route 11

Équipes RB (`parties.asm`), capacités du moveset au niveau donné (méthode du J12) ; capacité absente
du moteur → signalée au plan, remplacée par la plus proche existante. Argent RB : base de classe ×
niveau du dernier Pokémon. IA `random` (Dresseurs de route). Prénoms nouveaux, aucun doublon [D].

| # | Nom | Équipe | Argent | Inévitable |
|---|---|---|---|---|
| D1 | **Gamin Lucas** | Abo Nv. 21 | 315 | non |
| D2 | **Gamin Arthur** | Sabelette Nv. 19, Nosferapti Nv. 19 | 285 | **oui** [D] |
| D3 | **Gamin Louis** | Rattata Nv. 17, Rattata Nv. 17, Rattatac Nv. 17 | 255 | non |
| D4 | **Gamin Raphaël** | Nidoran ♂ Nv. 18, Nidorino Nv. 18 | 270 | non |
| D5 | **Joueur Marcel** | Voltorbe Nv. 18, Magnéti Nv. 18 | 1 260 | non |
| D6 | **Joueur Roger** | Caninos Nv. 18, Goupix Nv. 18 | 1 260 | non |
| D7 | **Ingénieur Bruno** | Magnéti Nv. 21 | 1 050 | non |
| D8 | **Ingénieur Victor** | Magnéti Nv. 18, Magnéti Nv. 18, Magnéton Nv. 18 | 900 | non |

Classes nouvelles : **Joueur** (Gambler) et **Ingénieur** (Engineer) [D, noms à confirmer avec les
textes]. Sprites : nouveaux modèles peints pour ces deux classes (lot d'art). Les deux Joueurs RB
retirés (Ptitard + Hypotrempe ; Chétiflor + Mystherbe) pourront revenir quand leurs espèces existeront.

## 7. Objets

| Lieu | Objet | Forme | Drapeau [D] |
|---|---|---|---|
| Route 11 | Super Potion | visible | `item_route_11_super_potion` |
| Route 11 | Réveil (Soporifik endort) | visible | `item_route_11_awakening` |
| Route 11 | Poké Ball | **cachée** (B-10 du J12 : case signalée par le décor) | `item_route_11_hidden_ball` |
| Cave, renfoncement | Corde Sortie | visible | `item_digletts_cave_rope` |
| Route 2 est, sud | **Pierre Lune** | visible (RB) | `item_route_2_east_moon_stone` |
| Route 2 est, sud | **Super Bonbon** | visible (remplace le PV Plus RB, §9) | `item_route_2_east_rare_candy` |
| Clairière FUTUR A | Super Potion | visible | `item_route_2_futur_a_super_potion` |

Chaque objet est ramassé **une seule fois** (méthode existante).

## 8. L'assistant de Chen et la CS05

- **Où** : intérieur du poste de la Route 2 est, une pièce ; l'assistant (blouse de scientifique) et un
  **visiteur** qui parle des grottes obscures [D].
- **Condition** (H-9) : `Pokedex.caught_count() ≥ 10` (espèces distinctes capturées ; évolutions
  comprises ; relâcher ou déposer ne retire rien). Nouvelle **condition de variante de dialogue sur ce
  compteur** (logique pure, testable sans scène), avec le compte et le reste affichés.
- **Avant le seuil** : il donne la condition et le compte, **à chaque visite** (T-1, T-2).
- **Au seuil** : il remet la CS05 **une seule fois** (`got_hm05`), puis réplique d'après (T-4). Si
  l'application est tuée pendant la remise, l'objet et le drapeau sont écrits ensemble (même règle que
  la CT34 de Pierre) : on ne peut ni la perdre ni la recevoir deux fois.

### 8.1 Flash (H-6, H-7, H-8)

- **Objet** : `hm05` « CS05 — Flash », catégorie CS (section créée par le J16), **jamais consommée**,
  jamais vendue, ne se jette pas.
- **Dans le monde** : débloqué dès que `got_hm05` est posé **et** qu'un Pokémon compatible est dans
  l'équipe, **sans** occuper d'emplacement (dossier 06 §11). Compatibilités : PokeAPI `red-blue`
  (CS05).
- **Automatique** (H-7) : en entrant dans une carte marquée *obscure*, si Flash est disponible, courte
  mise en scène (le Pokémon compatible apparaît, éclair, le halo s'ouvre ; ≈ 1,5 s [D]), puis le halo
  suit le joueur pour toute la carte. Pas de menu, pas de bouton. Sans Flash : la carte reste obscure ;
  **son comportement exact est conçu au J18** (Tunnel Roche).
- **En combat** : la CS05 s'utilise comme une CT réutilisable (`TmTeach`), oubliable normalement.
  Capacité `flash` : Normal, statut, **précision 70 %**, PP 20, Précision de l'adversaire −1 (RB).
- **Fondation d'éclairage** (H-8) : obscurité + halo autour du joueur, compatible avec le rendu
  `mobile` (aucune `Light2D` aujourd'hui) et avec le voile précalculé du J12. Testée sur une carte de
  QA provisoire `qa_flash` et un départ de débogage, **retirés à la clôture**. Critères : fps
  inchangés sur S24, contraste du héros ≥ 3,0 dans le halo, mise en scène jouée une fois par entrée.

## 9. Écarts volontaires à Rouge/Bleu (K26)

- Arbustes **définitifs** (G-4) ; barrière de FUTUR B ouverte une fois pour toutes.
- Triopikeur **Nv. 24–26** (RB 29–31).
- **8** Dresseurs au lieu de 10.
- **Super Bonbon au lieu du PV Plus** : les vitamines ne sont pas conçues [D].
- Pas de Cherch'Objet, pas de maison d'échange, pas de poste sur la Route 11 (Ronflex directement
  sur la route).
- Bouches de Cave naturelles au lieu des maisonnettes.
- Flash sans condition de badge, automatique, sans emplacement (dossier 06 §11).

## 10. Drapeaux [D]

`route_11_visited` (titre d'arrivée, méthode existante) · `snorlax_route_11_awake` (jamais posé au
J17) · `cut_route_2_east_bush` · `cut_route_2_futur_a` · `route_2_east_gate_open` · `got_hm05` · les
7 objets du §7 · les 8 Dresseurs (méthode existante). **Sauvegarde : pas de v8** (drapeaux et objets
seulement).

## 11. Compagnon

Aucune règle nouvelle : il suit sur toutes les cartes extérieures du J17 et dans la Cave (comme au
Mont Sélénite), se cache dans le poste (intérieur), n'est jamais posé sur une bouche de Cave. Il
n'occupe aucune case : il ne peut ni contourner Ronflex ni être bloqué par lui.

## 12. Point de repos et défaites

Règle existante : dernier Centre visité (Carmin depuis la Route 11 et la Cave ; Argenta ou Jadielle
depuis le couloir, selon le dernier visité). Corde Sortie dans la Cave : ramène à la bouche par
laquelle le joueur est entré [D, même règle que B-4 du J12 : « l'entrée extérieure »].

## 13. Cas limites (à tester)

- Seuil des 10 espèces atteint **par une évolution**, ou après avoir **relâché / déposé** des Pokémon.
- CS05 reçue **sans Pokémon compatible** dans l'équipe : rien ne se passe ; aucune carte obscure au
  J17, donc aucun blocage.
- Application tuée pendant la remise de la CS05, pendant l'ouverture de la barrière, juste après
  avoir coupé un arbuste.
- Joueur arrivé dans le couloir **sans la CS01** : il atteint l'assistant, reçoit la CS05, revient par
  la Cave ; l'arbuste et la barrière ne le bloquent jamais.
- Barrière ouverte, sauvegarde côté Route 2 sud, rechargement : le passage reste ouvert.
- Traversées Carmin → Route 11 → Cave → Route 2 est → (Coupe) → Route 2 sud → Jadielle, et le retour
  complet par la Cave.
- Ronflex : aucune case contournable, le compagnon ne passe pas, aucun Dresseur ne pousse le joueur
  au-delà.
- Défaite contre Triopikeur dans la Cave ; Corde Sortie depuis chaque moitié.
- Dresseur inévitable : impossible de le contourner (contrôle `plan_check`).

## 14. Validation (H-17)

| Lot | Contenu | Dépend de | S24 |
|---|---|---|---|
| **17A** | Route 11 (rencontres, 8 Dresseurs, objets, Ronflex), Cave Taupiqueur, raccord de Carmin | fusion J12 + J15 | oui |
| **17B** | Route 2 est, poste et assistant, condition Pokédex, CS05 (objet), FUTUR B ; arbuste du couloir et FUTUR A après la fusion du J16 | J16 pour Coupe | oui |
| **17C** | Flash : données, combat, fondation d'éclairage sur `qa_flash` | 17B | oui |
| **17D** | Clôture : non-régression, retrait de `qa_flash`, traversées complètes, sauvegarde / rechargement à chaque transition | tout | oui |

Aucun lot ne touche un système à risque de perte de données : pas de validation isolée.

## 15. Art (lot du J17)

- **Vues générales peintes** (puis plans) : Route 11, Cave Taupiqueur, Route 2 est ; retouche de la
  Route 2 sud (clairière FUTUR A, barrière ouverte).
- **Sprites du monde** : Taupiqueur (sort du sol), Soporifik, **Ronflex endormi** (grand, ≈ 2 × 2
  cases [D]).
- **Dos de combat** (méthode Colab) : Taupiqueur, Triopikeur, Soporifik, Hypno.
- **Personnages** : Joueur, Ingénieur, assistant de Chen (si le scientifique existant ne convient
  pas), visiteur.
- **Décor** : poste de la Route 2 est, arbuste (celui du J16), barrière ouverte, bouches de Cave,
  digue.
- **Fonds de combat** (méthode CB.3) : Route 11 (prairie côtière), Cave (roche claire).

## 16. Textes à valider (lot unique)

Format : bulles séparées par « / ». `{n}` = espèces capturées ; `{reste}` = 10 − n ; `{joueur}`,
`{pokemon}` = noms.

| N° | Où | Texte |
|---|---|---|
| T-1 | Assistant, première visite, n < 10 | Je suis un assistant du Professeur Chen. / Il m'a confié quelque chose pour toi. / Mais il faut d'abord avoir capturé 10 espèces. / Ton Pokédex en compte {n}. Reviens me voir ! |
| T-2 | Assistant, visites suivantes, n < 10 | Ton Pokédex compte {n} espèces capturées. / Encore {reste}, et c'est à toi. |
| T-3 | Assistant, remise | Ton Pokédex compte {n} espèces ! / Le Professeur Chen sera ravi. / Voici la CS05 : Flash. · *(système)* {joueur} reçoit la CS05 — Flash ! · Flash éclaire les grottes les plus sombres. / Il suffit d'avoir dans ton équipe un Pokémon capable de l'utiliser. |
| T-4 | Assistant, après | Avec Flash, plus besoin d'avancer à tâtons. / Continue de remplir ton Pokédex ! |
| T-5 | Visiteur du poste | Certaines grottes de Kanto sont plongées dans le noir. / Sans lumière, on s'y perd en trois pas. |
| T-6 | Ronflex, examen | Un énorme Pokémon dort au milieu du chemin. / Il ne bouge pas d'un pouce. |
| T-7 | Ronflex, examen suivant | Il ronfle paisiblement. / Rien ne semble pouvoir le réveiller. |
| T-8 | Barrière de FUTUR B, côté est (fermée) | La barrière s'ouvre de ce côté. / Le sentier rejoint la Route 2. |
| T-9 | Panneau de FUTUR B, après ouverture | **SENTIER ROUVERT** / Route 2 — Cave Taupiqueur |
| T-10 | Panneau, Route 11, près de la Cave | **CAVE TAUPIQUEUR** / Vers la Route 2 |
| T-11 | Panneau, Route 2 est, près de la Cave | **CAVE TAUPIQUEUR** / Vers la Route 11 et Carmin-sur-Mer |
| T-12 | Panneau, Route 11, entrée ouest | **ROUTE 11** / Carmin-sur-Mer — Route 12 |
| T-13 | Description de zone, Route 11 | Une route côtière entre les prairies et la mer, à l'est de Carmin. |
| T-14 | Description de zone, Cave Taupiqueur | Un long tunnel creusé par des Taupiqueur. |
| T-15 | Sac, CS05 | Éclaire les grottes obscures si un Pokémon compatible est dans l'équipe. Peut aussi apprendre Flash pour le combat. |
| T-16 | Capacité Flash | Une lumière aveuglante qui baisse la précision de l'ennemi. |
| T-17 | Mise en scène, carte obscure | {pokemon} utilise Flash ! |
| T-18 | Gamin Lucas | avant : Mon Abo est prêt à mordre ! · défaite : Il a mordu… la poussière. · après : Je vais l'entraîner encore. |
| T-19 | Gamin Arthur (inévitable) | avant : Personne ne passe sans m'affronter ! · défaite : D'accord, d'accord, tu passes. · après : La prochaine fois, je gagnerai. |
| T-20 | Gamin Louis | avant : Trois Rattata, c'est trois fois plus fort ! · défaite : Le calcul était faux… · après : Il me faut d'autres Pokémon. |
| T-21 | Gamin Raphaël | avant : Mon Nidorino vient d'évoluer ! · défaite : Il avait pourtant grandi… · après : On va continuer à progresser ensemble. |
| T-22 | Joueur Marcel | avant : On parie ? Pile, je gagne ! · défaite : Face… Je perds ma mise. · après : La chance tourne, parfois. |
| T-23 | Joueur Roger | avant : Mes Pokémon de feu sont mon porte-bonheur. · défaite : Mon porte-bonheur s'est éteint. · après : Je retente ma chance demain. |
| T-24 | Ingénieur Bruno | avant : Je teste mes Pokémon électriques. · défaite : Court-circuit ! · après : Il faut revoir mes réglages. |
| T-25 | Ingénieur Victor | avant : Trois Magnéti valent mieux qu'un ! · défaite : Ils ont fusionné… mais pas assez. · après : Mon Magnéton a besoin de réglages. |

**Points pour la relecture** : T-9 et T-12 reprennent le format des panneaux existants (titre en
capitales) ; T-22 introduit un pari « pour la forme », sans mécanique d'argent ; les noms de classe
**Joueur** et **Ingénieur** sont à confirmer.
