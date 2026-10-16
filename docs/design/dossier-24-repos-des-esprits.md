# Dossier 24 — Le repos des esprits (jalon 21)

> Consolidé par Claude le 2026-10-15 à partir de la V2 de ChatGPT (`passes/j21-v2-chatgpt.md`) et de
> la passe d'alignement (`passes/j21-v2-alignement.md`). **Les 7 décisions de la V2 et les
> arbitrages L-1 à L-16 sont validés par Kevin** (« Toutes tes recommandations sont ok »,
> 2026-10-15). Les **textes du §15 sont à valider** en un seul lot.
>
> Faits Rouge/Bleu : désassemblage `pret/pokered` (`af51989`). Marqueurs : **[V]** validé par Kevin,
> **[D]** valeur par défaut (règle 4 de `CLAUDE.md`), **RB** Rouge/Bleu, **K26** invention de Kanto
> 2026.
>
> Branche : `docs/dossier-24-j21`. Dossiers voisins : 20 (J17, Route 11 et Ronflex), 21 (J18,
> Lavanville), 22 (J19, Tour 1F–6F), 23 (J20, Céladopole et Scope Sylphe).

## Décisions de Kevin

### Les 7 décisions de la V2 [V]

1. Tour Pokémon complète, M. Fuji, Poké Flûte et deux Ronflex.
2. Ossatueur : combat narratif obligatoire, non capturable.
3. Team Rocket : combats au dernier étage, puis sauvetage de M. Fuji.
4. Poké Flûte : objet clé permanent, utilisable devant Ronflex et en combat selon Rouge/Bleu.
5. Deux Ronflex uniques, capturables ou pouvant être vaincus.
6. Route 12 : début accessible au J21, suite au J22.
7. Fin du jalon : exploration libre, sans séquence forcée vers Parmanie.

### Arbitrages L-1 à L-16 [V]

| # | Décision |
|---|---|
| L-1 | Dossier n° 24, `dossier-24-repos-des-esprits.md`. |
| L-2 | Le « Ronflex est » **est celui du J17** (un seul Ronflex, comme RB). **Révisé par M-3** (passe du J22, confirmé par Kevin le 2026-10-16) : il quitte la carte de la Route 11 et dort **sur la Route 12, au croisement**, où il ferme la Route 11 et la suite vers le sud ; drapeaux `snorlax_route_12_*`. |
| L-3 | **Route 12 nord complète** : de Lavanville au croisement de la Route 11, poste, ponton, 4 Pêcheurs RB ; bord sud « À venir ». |
| L-4 | **Route 16 est** : sortie ouest de Céladopole (la haie du J20 est remplacée), Ronflex sur la voie basse, façade du poste fermée ; aucun texte sur le Vélo. |
| L-5 | Ossatueur : RB, sauf la **Ball refusée avant le lancer, non consommée**. Fuite possible (recul, réarmé), défaite (Centre, réarmé), XP et « vu » au Pokédex. |
| L-6 | Révélation : la silhouette SPECTRE du J19 se dissout en Ossatueur dans l'intro du combat ; après la victoire, brume qui se lève, petite lumière qui monte, cri, phrases RB. |
| L-7 | 7F : 3 Sbires RB, équipes et niveaux RB, inévitables, rencontres sauvages RB ; aucun chef. |
| L-8 | Fuji : fondu et téléportation dans sa maison (RB) ; remise **idempotente** de la Flûte. |
| L-9 | Flûte en combat : effet RB (réveille l'équipe du joueur et l'adversaire) ; **sans effet, elle ne prend pas le tour**. |
| L-10 | Flûte hors combat : Sac → UTILISER (RB), **plus** « Jouer de la Poké Flûte ? » en parlant à Ronflex ; ailleurs, message RB et bulle « ♪ » du compagnon. |
| L-11 | Ronflex : capture ou K.O. → retiré ; **fuite ou défaite → il se rendort**. |
| L-12 | Ronflex N30, Coup d'Boule, Amnésie, Repos ; intro sauvage ordinaire. |
| L-13 | Objectifs : « trouver M. Fuji, au sommet de la Tour. », « rendre visite à M. Fuji. », puis aucun. |
| L-14 | Après le jalon : variantes de texte, 6F moins brumeux, Osselait près de Fuji (sans don). |
| L-15 | Fuji : répliques RB au ton du projet, sans allusion à son passé ni à Mewtwo. |
| L-16 | Découpage **21.0 / 21A / 21B**, deux validations S24. |

## 1. Intention

Au J19, la Tour était le lieu où l'on ne gagne pas en se battant. Au J21, le joueur y revient avec de
quoi **voir**. Ce qu'il découvre n'est pas un monstre : c'est une mère qui protège encore son petit.
Il faut la combattre pour qu'elle trouve le repos, puis monter chasser ceux qui ont causé sa mort.

Le joueur ressort avec trois choses : un vieil homme sauvé, un instrument de musique, et la
sensation que Kanto **s'ouvre** (Ronflex se réveille, les routes se relient).

Ton : deuil, apaisement, colère sourde contre la Team Rocket, gratitude. Jamais d'horreur, jamais de
comique.

## 2. Périmètre

| Dans le J21 | Hors du J21 |
|---|---|
| 6F : révélation et combat d'Ossatueur ; passage ouvert pour toujours | Route 12 sud, Routes 13 à 15, Parmanie (J22) |
| 7F : carte, 3 Sbires Rocket, rencontres sauvages, M. Fuji | Piste Cyclable, Vélo, poste de la Route 16 (intérieur), CS02 Vol |
| Maison de Fuji : retour de Fuji, remise de la Poké Flûte | Safrania (accès, Thé, PNJ que RB permute) |
| Poké Flûte : objet clé utilisable hors combat et en combat | Osselait offert ; Ronflex compagnon |
| Ronflex du croisement de la Route 12 (ex-Ronflex de la Route 11 du J17, M-3) : réveil, combat, issue | Musique et sons (intentions notées, §11) |
| **Route 12 nord** (Lavanville → croisement), poste, ponton, 4 Pêcheurs | Toute capacité d'exploration nouvelle |
| **Route 16 est** (Céladopole → Ronflex → façade du poste), Ronflex | |
| Variantes de Lavanville et de la Tour ; objectifs du tableau de bord | |
| Espèces : Ossatueur (complété), Ronflex ; capacité Amnésie ; espèces des Pêcheurs si absentes | |

## 3. Contrat d'entrée

| Le J21 suppose | Jalon | Si c'est faux |
|---|---|---|
| Ronflex de la Route 11 : `FlagGate` + `InteractPoint` 2 × 2 en (66..67, 14..15), `unless snorlax_route_12_awake`, textes T-6 / T-7, bord est (75, 14..15) `raccord_est role=route_12` | J17 (codé, `jalon-17`) | Le J21 ajoute la variante « Flûte » et le raccord. |
| Lavanville : bord sud « ROUTE 12 — À venir » ; Maison des Pokémon (enfant, Rondoudou, Nidoran ♀) | J18 | — |
| Maison des Pokémon au J19 : homme, fille, **Osselait** ; textes du dossier 22 §15.6 | J19 | Le J21 les remplace par ses variantes. |
| 6F : scène `tower_6f_ghost`, déclencheur (10, 16), étape `wild_battle marowak 30 ghost: always`, recul (10, 15), variante `unless ghost_marowak_calmed` ; escalier du 7F (9, 16), paire T67 | J19 (plan `jalon-19.md` §2.4) | Le J21 change la **donnée** de scène. |
| Étape `wild_battle` avec drapeaux `win` / `lose` ; règles `ball_refused`, `flee_always`, masque d'identité | J19 | Le J21 ajoute l'issue `flee` et `catch`, et une règle `uncatchable` (§13). |
| `silph_scope` (objet clé) obtenu après Giovanni ; objectif « retourner à la Tour Pokémon. » | J20 | — |
| Céladopole : sortie ouest = haie dense et talus (H-4) | J20 | Le J21 la remplace par le raccord de la Route 16. |
| Drapeaux jamais posés avant le J21 : `ghost_marowak_calmed`, `fuji_rescued`, `got_poke_flute`, `beaten_tower_rocket_1..3` | J19, J20 (tests) | — |
| Espèces : Osselait, Ossatueur (données de combat), Fantominus, Spectrum (J19) ; Soporifik (J17) ; Smogo, Nosferapti, Nosferalto, Rattata, Rattatac (`main`) | J15–J19 | — |
| Équipe du joueur vers les niveaux 28 à 35 | J20 | Combats de récit : rien à rééquilibrer. |

**Le J21 ne touche jamais** à la sauvegarde du J19 : il **lit** les mêmes cartes, les mêmes drapeaux
et les mêmes objets ramassés. Aucun Dresseur ni objet du J19 ne réapparaît.

## 4. Le retour à la Tour

- **Aucune annonce** : l'objectif du J20 (« retourner à la Tour Pokémon. ») suffit. Lavanville ne
  change pas avant le sauvetage [D].
- **Étages 2F à 6F** : inchangés. Avec le Scope, les rencontres sont identifiées et capturables
  (règle du J19, sans drapeau). Exorcistes, rival et objets gardent leur état.
- **Le Scope ne s'utilise pas** : sa possession suffit (dossiers 22 et 23).

## 5. Ossatueur [V décision 2, L-5, L-6]

### 5.1 Condition

La scène du 6F se joue en version **révélation** si les trois conditions sont vraies :
- le joueur marche sur le déclencheur (10, 16) ;
- `ghost_marowak_calmed` n'est **pas** posé ;
- `silph_scope` est **dans le Sac**.

Sans le Scope, la scène du J19 reste telle quelle (SPECTRE, recul). Ossatueur n'est jamais
accessible autrement.

### 5.2 Déroulé

1. Le joueur s'arrête ; la brume s'épaissit (comme au J19).
2. Texte : « …Va-t'en… Intrus… » (§15.1).
3. **Combat** : fondu de combat ordinaire. L'intro montre la **silhouette SPECTRE du J19**, puis le
   texte « Le Scope Sylphe révèle l'identité du SPECTRE ! » ; la silhouette **se dissout** (fondu
   d'environ 1 s [D]) et laisse voir **Ossatueur** (artwork de face). Cri d'Ossatueur. Puis
   « C'est un Ossatueur ! » et le combat commence.
4. **Ossatueur N30** : Massd'Os, Rugissement, Groz'Yeux, Puissance (RB). IA `random` [D].

### 5.3 Règles du combat

| Aspect | Règle | Origine |
|---|---|---|
| Ball | **Refusée avant le lancer, non consommée** : « Ce Pokémon ne peut pas être capturé. » | K26 (RB la consomme) |
| Sac | Autorisé (soins, remèdes, Flûte) | RB |
| Changer de Pokémon | Autorisé | RB |
| Fuite | Possible, calcul de fuite normal. Ensuite : recul d'une case en (10, 15), « Quelque chose retient encore l'esprit… » (§15.1), déclencheur réarmé | RB |
| Défaite | Réveil au Centre de Lavanville ; déclencheur réarmé | RB |
| XP | Gagnée | RB |
| Pokédex | Ossatueur **vu** | RB |
| Argent | Aucun (sauvage) | RB |

### 5.4 Victoire

1. `ghost_marowak_calmed` est posé **à la fin du combat**, avant tout texte.
2. Retour au monde. Texte : « Le SPECTRE était l'âme de la mère d'Osselait… »
3. Une **petite lumière** pâle monte depuis la case de l'esprit (particules, environ 2 s [D]) ; cri
   d'Ossatueur, doux.
4. Texte : « Son âme s'est apaisée. Elle est partie en paix. »
5. La **brume du 6F se lève** : le profil de lumière du 6F passe à la variante « apaisée » (moins de
   brume, même palette) pour toujours [D].
6. Le passage vers l'escalier du 7F est libre.

« Réduire les animations » : textes et changement de brume gardés, lumière qui monte coupée.

## 6. Le 7e étage [V décision 3, L-7]

### 6.1 Carte

- **20 × 18 cases**, comme les autres étages, géométrie RB. Grille `tools/plans/pokemon_tower_7f.txt`
  (fait foi). Escalier qui descend, paire T67.
- Lumière `tower`, un peu plus sombre ; au fond, **M. Fuji agenouillé** devant une stèle à bougies.
- **Rencontres sauvages** (RB, taux 15) : table `pokemon_tower_top` — Fantominus N20–24, Spectrum
  N28–30, Osselait N22–24, mêmes poids que le 6F [D].
- **Aucun objet** (RB).

### 6.2 Les 3 Sbires Rocket

Inévitables, chacun avec sa ligne de vue, sur le seul chemin vers Fuji (RB). Classe « Sbire Rocket »
existante (J12) ; planche existante.

| Id | Équipe (RB) | Argent |
|---|---|---|
| `tower_rocket_1` | Nosferapti, Nosferapti, Nosferalto N25 | barème Rocket existant |
| `tower_rocket_2` | Smogo, Soporifik N26 | barème Rocket existant |
| `tower_rocket_3` | Nosferapti, Rattata, Rattatac, Nosferapti N23 | barème Rocket existant |

IA : celle des Sbires du J12 [D]. Drapeaux `beaten_tower_rocket_1..3` (mécanisme existant). Textes
§15.2. Aucun chef.

### 6.3 M. Fuji au 7F [L-8]

Le joueur parle à Fuji (il ne réagit qu'une fois les 3 Sbires battus ; avant, il prie et ne répond
pas, §15.3).

1. Fuji se relève et se tourne vers le joueur ; texte §15.3.
2. `fuji_rescued` est posé **à ce moment**, avant le fondu.
3. **Fondu au noir** et **téléportation** dans la Maison des Pokémon (`change_map`), le joueur devant
   Fuji.
4. La remise de la Flûte suit aussitôt (§7.2).

Fuji est présent au 7F `unless fuji_rescued` ; dans sa maison, `if fuji_rescued`.

## 7. La Maison des Pokémon de M. Fuji [L-8, L-14, L-15]

### 7.1 Habitants après le sauvetage

| Qui | Avant (J19) | Après (J21) |
|---|---|---|
| M. Fuji | absent | présent, près de la fenêtre [D] |
| Enfant (J18) | « Papy Fuji n'est pas redescendu » | §15.5 |
| Homme (J19) | « des gens montaient à la Tour, la nuit » | §15.5 |
| Fille et Osselait (J19) | Osselait attend sa mère | §15.5 ; Osselait reste dans la maison, **sans don** |
| Rondoudou, Nidoran ♀ (J18) | cris | inchangés |

### 7.2 Remise de la Poké Flûte (idempotente)

**Condition** : `fuji_rescued` posé **et** `poke_flute` absente du Sac.

- **Déclenchement** : à l'arrivée par la téléportation, **et** à toute entrée dans la maison, **et**
  en parlant à Fuji, tant que la condition est vraie. Une sauvegarde interrompue n'importe où donne
  donc exactement **une** Flûte.
- **Déroulé** : texte de Fuji (§15.4) → `give poke_flute` et `got_poke_flute` dans **la même étape**
  → toast « Poké Flûte — ajoutée aux objets clés » (modèle existant) → explication (§15.4).
- **Ensuite** : Fuji dit la réplique d'après (§15.4).
- Un objet clé ne remplit jamais le Sac : aucun cas « Fais de la place ! ».

## 8. La Poké Flûte [V décision 4, L-9, L-10]

### 8.1 Objet

- Id `poke_flute`, catégorie **objets clés**, permanente : jamais consommée, vendue ni jetée.
- **Premier objet clé utilisable** : bouton UTILISER en exploration et en combat (sauvage et
  Dresseur). Les autres objets clés ne changent pas.
- Description et nom : §15.6. Icône : lot d'art.

### 8.2 En combat [L-9]

| Cas | Effet |
|---|---|
| Au moins un Pokémon endormi (n'importe lequel des deux camps) | « {player} joue de la Poké Flûte. » → **tous les Pokémon endormis de l'équipe du joueur** se réveillent, ainsi que le Pokémon sauvage, ou **toute l'équipe adverse** contre un Dresseur (RB). « Tous les Pokémon endormis se réveillent ! » **Le tour est utilisé.** |
| Personne ne dort | « Personne ne dort. La Flûte n'aurait aucun effet. » **Le tour n'est pas utilisé** : retour au menu de combat (K26). |

- Elle ne soigne **que** le sommeil : ni PV, ni autre statut.
- Un Pokémon réveillé par la Flûte agit normalement au tour suivant ; son compteur de sommeil est
  effacé.

### 8.3 Hors combat [L-10]

| Où | Effet |
|---|---|
| Sur une case voisine d'un Ronflex endormi (Sac → UTILISER) | Réveil (§9.2). |
| En parlant à un Ronflex endormi, Flûte dans le Sac | « Jouer de la Poké Flûte ? » OUI → réveil (§9.2) ; NON → rien. |
| Ailleurs | « {player} joue de la Poké Flûte… Quel air entraînant ! » ; si un compagnon est sorti, il affiche la bulle « ♪ » existante. |

Mise en scène : notes de musique peintes simples qui montent du joueur (environ 1,5 s [D]) ; coupées
par « Réduire les animations ». Son : jalon audio.

## 9. Les deux Ronflex [V décision 5, L-2, L-4, L-11, L-12]

### 9.1 Où

| Id | Carte | Cases | Accès |
|---|---|---|---|
| `snorlax_route_12` | Route 12, croisement (M-3) | grille `route_12.txt` (passage de 2 cases) | depuis Lavanville (nord), depuis la Route 11 (ouest) ; il ferme aussi le sud |
| `snorlax_route_16` | Route 16 est | grille `route_16.txt` | depuis Céladopole |

Chacun a **ses propres drapeaux** : réveiller, capturer ou battre l'un ne change jamais l'autre.

### 9.2 Réveil

1. « {player} joue de la Poké Flûte. »
2. Ronflex ouvre un œil, se redresse (petit saut de l'image endormie et bulle « ! » existante [D]).
3. « Ronflex se réveille ! Il attaque, de très mauvaise humeur ! »
4. `snorlax_route_*_awake` posé, puis **combat sauvage** (intro ordinaire, pas d'écran de boss).

### 9.3 Combat

- **Ronflex N30**, Coup d'Boule, Amnésie, Repos (RB). Taux de capture 25 (RB). IA `random` [D].
- Règles d'un combat sauvage normal : Ball, Sac, Flûte (s'il dort après Repos), fuite.
- Pokédex : vu à l'apparition, capturé à la capture.

### 9.4 Issues [L-11]

| Issue | Résultat |
|---|---|
| **Capture** | `snorlax_route_*_done` posé ; Ronflex retiré du monde ; il rejoint l'équipe ou le Stockage (règle existante). |
| **K.O.** | `snorlax_route_*_done` ; « Ronflex se calme… Avec un grand bâillement, il retourne dans les montagnes. » ; retiré. |
| **Fuite** | `snorlax_route_*_awake` **effacé** ; « Ronflex bâille… et se rendort aussitôt. » ; il reste en place. |
| **Défaite** | Réveil au Centre ; `*_awake` effacé ; Ronflex dort toujours à sa place. |

Le passage (`FlagGate`) s'ouvre sur **`*_done`**, pas sur `*_awake` : un Ronflex rendormi bloque
toujours. Aucune duplication possible (la capture pose `*_done` avant tout).

## 10. Les routes qui s'ouvrent [V décision 6, L-3, L-4]

### 10.1 Route 12 nord

- **De Lavanville au croisement de la Route 11**, où dort **Ronflex** (M-3). Grille `tools/plans/route_12.txt` (fait foi).
- Le bord sud de Lavanville (« ROUTE 12 — À venir », J18) devient le raccord nord de la Route 12.
- **Poste** traversé par la route (RB) [D : intérieur selon le modèle de poste existant] ;
  **CT39 Météores** offerte au 2F par une jeune femme (RB ; la capacité existe déjà dans
  `moves.json`), remise unique `got_tm39` [D].
- **Ponton** et eau (décor, pas de Surf ni de pêche).
- **4 Pêcheurs** (RB) : équipes RB (Poissirène, Ptitard, Magicarpe…) ; espèces créées si absentes
  ; niveaux RB [D].
- **Croisement** : le raccord avec le bord est de la Route 11 (75, 14..15). **Ronflex y dort** (M-3) :
  le passage fait 2 cases de large et ses 2 × 2 cases ferment à la fois la Route 11 (ouest) et la
  suite vers le sud. **Bord sud « ROUTE 12 — À venir »** (J22 construit la suite).
- Rencontres : selon RB sur ce tronçon [D].
- **Avant la Flûte**, la Route 12 nord est ouverte depuis Lavanville : c'est un cul-de-sac au
  croisement, Ronflex endormi en vue (comme RB).
- Depuis Carmin, la Route 11 bute sur Ronflex au croisement.
- **Après la capture ou le K.O.** (`snorlax_route_12_done`), boucle **Carmin ↔ Route 11 ↔ Route 12 ↔
  Lavanville**, et le sud s'ouvre (au J22).

### 10.2 Route 16 est

- **Sortie ouest de Céladopole** : la haie du J20 est remplacée par le raccord (modification de la
  grille `celadopole.txt`).
- Voie basse avec **Ronflex** en goulet, sans contournement ; puis **façade du poste** de la Piste
  Cyclable, **porte fermée** (bord « ROUTE 16 — À venir » en développement, mécanisme existant).
- Voie haute et arbre à Couper : **décor dense infranchissable** (CS Vol hors jalon).
- Aucun Dresseur, **aucun texte sur le Vélo**. La seule récompense est Ronflex.

### 10.3 Dépendance J22 — tranchée par M-3

Le J22 a proposé et Kevin a confirmé (2026-10-16, M-3 de `j22-v2-alignement.md`, dossier 25 §5) :
**Ronflex au croisement de la Route 12**, comme RB. Il ferme la Route 12 sud tant qu'il n'est ni
capturé ni mis K.O. Conséquence pour le J17 : son `FlagGate` et son `InteractPoint` 2 × 2 quittent
la Route 11 (`tools/build_route_11.gd`, `route_11.txt`) ; le goulet de la Route 11 devient un simple
chemin jusqu'au raccord est. Retouche faite à l'intégration (T9 du plan).

## 11. Lavanville et la Tour après le jalon [L-14]

- **Textes** : gardienne (1F), enfant, homme et fille de la Maison des Pokémon, gentleman du Centre
  (§15.5). Les autres PNJ ne changent pas.
- **6F** : brume « apaisée » (§5.4). Les étages 2F à 5F ne changent pas.
- **Tour** revisitable : rencontres normales (Scope), zone purifiée maintenue, Exorcistes, rival et
  Rocket battus le restent.
- **Son (hors jalon)** : intentions pour le jalon audio — thème de la Tour qui s'éclaircit après la
  victoire, mélodie de la Flûte (courte, douce), aucun stinger.

## 12. Objectifs du tableau de bord [L-13]

| État | Objectif |
|---|---|
| `silph_scope`, sauf `ghost_marowak_calmed` | « retourner à la Tour Pokémon. » (J20, inchangé) |
| `ghost_marowak_calmed`, sauf `fuji_rescued` | « trouver M. Fuji, au sommet de la Tour. » |
| `fuji_rescued`, sauf `got_poke_flute` | « rendre visite à M. Fuji. » |
| `got_poke_flute` | **aucun** objectif du J21 (exploration libre) |

Mises à jour en silence (existant). Rien ne montre Ronflex.

## 13. Données, systèmes et sauvegarde

**Aucun changement de version de sauvegarde.**

| Drapeau | Posé par |
|---|---|
| `ghost_marowak_calmed` | Victoire contre Ossatueur (issue `win` de l'étape `wild_battle`) |
| `beaten_tower_rocket_1..3` | Sbires du 7F (mécanisme existant) |
| `fuji_rescued` | Scène du 7F, avant la téléportation |
| `got_poke_flute` | Même étape que `give poke_flute` (la condition lit aussi la possession) |
| `snorlax_route_12_woken`, `snorlax_route_16_woken` | Premier réveil (jamais effacé ; sert aux répliques) |
| `snorlax_route_12_caught`, `snorlax_route_16_caught` | Capture |
| `snorlax_route_12_done`, `snorlax_route_16_done` | Capture ou K.O. ; ouvre le `FlagGate` |
| `snorlax_route_*_awake` | Pendant la scène seulement, jamais sauvegardé (plan §2.10) |
| `route_12_visited`, `route_16_visited` | Titre d'arrivée (méthode existante) |
| `got_tm39` | Remise de la CT39 au poste de la Route 12 |

**Systèmes à ajouter** (coûts dans la passe, §4) :
- usage d'**objet clé** (`key_use`) en exploration et en combat ; onglet Objets clés dans le Sac de
  combat ; bouton UTILISER ;
- effet « réveiller tous les endormis » et son événement de combat ;
- issues `flee` et `catch` de l'étape `wild_battle` ; règle `uncatchable` (refus avant le lancer,
  message propre), indépendante du mode spectre ;
- choix OUI / NON « Jouer de la Poké Flûte ? » sur un `InteractPoint` (dialogue à choix existant) ;
- capacité **Amnésie** (Défense Spé. +2) ; données de **Ronflex** et d'**Ossatueur** (complètes) ;
  espèces des Pêcheurs si absentes ;
- profil de lumière du 6F « apaisé ».

**Tests d'interruption** (plan technique) : relecture de la sauvegarde après Ossatueur et avant le
7F ; entre le dernier Sbire et Fuji ; après `fuji_rescued` et avant la Flûte ; après le réveil de
chaque Ronflex (fuite, défaite, capture, K.O.). Une sauvegarde J20 relue en J21 : rien ne change avant
le 6F.

## 14. Espèces, capacités, objets et art

### 14.1 Espèces

| Espèce | Rôle | Données | Art |
|---|---|---|---|
| Ossatueur (105) | esprit du 6F | **complètes** (Sol ; Pokédex) | face : artwork officiel ; **pas de dos** |
| Ronflex (143) | deux rencontres | **complètes** (Normal ; Pokédex) | face : artwork ; **dos** (capturable) ; sprite endormi du monde (J17) |
| Poissirène, Ptitard, Magicarpe… | Pêcheurs de la Route 12 | complètes si absentes | face : artwork ; dos : pipeline existant |

### 14.2 Capacités

| Capacité | Valeurs | Remarque |
|---|---|---|
| **Amnésie** | Psy, statut, 20 PP, Défense Spé. +2 | Ronflex (RB : Spécial +2 ; le projet sépare les deux statistiques [D]) |

### 14.3 Objets

`poke_flute` (objet clé utilisable, §8). `tm39` CT39 Météores (§10.1), si le J20 ne l'a pas déjà créée.

### 14.4 Art (lot 21.0)

- **Cartes** : grilles et vues peintes du **7F** (sur l'enveloppe du J19), de la **Route 12 nord**,
  de la **Route 16 est** ; variante « apaisée » du 6F (lumière seulement).
- **Personnages** : planche **M. Fuji** (vieil homme, marche + prière agenouillée) ; **Pêcheur** (si
  absent).
- **Pokémon** : Ossatueur (face), Ronflex (face, dos), Pêcheurs (face, dos).
- **Combat** : fond CB.3 `tour_pokemon` (J19) au 7F ; Ronflex est : fond de route existant [D] ;
  Route 16 : fond de route existant [D] ; Route 12 : ponton [D, ou fond de route existant].
- **Interface** : icône de la Poké Flûte ; notes de musique (effet simple).

## 15. Lot de textes — À VALIDER

> Rédigés par Claude le 2026-10-15. Ton : sobre. Bulles de 2 lignes d'environ 40 caractères ; « / »
> sépare les bulles. `{player}`, `{pokemon}` sont des jetons. Le joueur est tutoyé, comme partout.

### 15.1 Ossatueur (6F)

1. *(avant le combat, inchangé du J19)* « …Va-t'en… Intrus… »
2. *(intro du combat)* « Le Scope Sylphe révèle l'identité du SPECTRE ! »
3. *(après la dissolution)* « C'est un Ossatueur ! »
4. *(Ball)* « Ce Pokémon ne peut pas être capturé. »
5. *(après une fuite, recul)* « Quelque chose retient encore l'esprit… »
6. *(victoire, 1)* « Le SPECTRE était l'âme de la mère d'Osselait… »
7. *(victoire, 2, après la lumière)* « Son âme s'est apaisée. / Elle est partie en paix. »

### 15.2 Sbires Rocket (7F)

| Sbire | Avant le combat | Défaite | Après |
|---|---|---|---|
| 1 | « Qu'est-ce que tu fais là, toi ? » | « J'abandonne ! » | « Je ne vais pas oublier ta tête. » |
| 2 | « Ce vieux est venu nous faire la morale. / Comme si ces Pokémon valaient quelque chose. » | « Arrête ! Ça suffit ! » | « Les Pokémon, ça sert à faire de l'argent. / Le reste, c'est du sentiment. » |
| 3 | « Le boss est parti, mais nous, on reste. / Tu ne sauveras personne, gamin ! » | « On ne se mesure pas à la Team Rocket… » | « Tu ne t'en tireras pas comme ça. » |

### 15.3 M. Fuji (7F)

1. *(avant que les 3 Sbires soient battus ; il prie)* « … »
2. *(il se relève)* « Oh… Tu es venu me chercher ? / Merci, mon enfant. »
3. « Mais je suis monté ici de mon plein gré. / Je voulais apaiser l'âme de la mère d'Osselait. »
4. « Ces hommes m'ont empêché de redescendre. / Ils disaient que je les gênais. »
5. « Je crois qu'elle a enfin trouvé la paix. / C'est grâce à toi, n'est-ce pas ? »
6. « Viens chez moi, au pied de la Tour. / J'aimerais te remercier comme il se doit. »

### 15.4 M. Fuji (maison)

1. *(remise)* « {player}. Tes Pokémon te font confiance, ça se voit. »
2. « Un Pokédex se remplit avec des Pokémon. / Une aventure, avec de l'affection. »
3. « Prends ceci. Elle t'aidera sur ton chemin. »
4. *(système)* « {player} reçoit la Poké Flûte ! »
5. *(explication)* « Sa mélodie réveille les Pokémon endormis. / Même les plus gros dormeurs. »
6. *(ensuite)* « Ma Flûte t'a-t-elle été utile ? »
7. *(ensuite, variante [D], une fois un Ronflex réveillé)* « Ronflex ? Ha ha… / Il aura bien dormi, au moins. »

### 15.5 Lavanville après le sauvetage

1. *(gardienne, 1F)* « Les esprits se sont calmés. / On peut de nouveau prier en paix. »
2. *(enfant, Maison des Pokémon)* « Papy Fuji est rentré ! / Il dit que c'est grâce à toi. »
3. *(homme, Maison des Pokémon)* « Ces gens en noir ont quitté la Tour. / Bon débarras. »
4. *(fille, près d'Osselait)* « Osselait ne pleure plus la nuit. / Je crois qu'il sait, pour sa maman. »
5. *(gentleman, Centre)* « Le spectre de la Tour a disparu, paraît-il. / Quelqu'un a apaisé son âme. »

### 15.6 Poké Flûte

1. *(nom)* « Poké Flûte »
2. *(description du Sac)* « Une flûte à la mélodie douce. Elle réveille les Pokémon endormis. »
3. *(combat, jouée)* « {player} joue de la Poké Flûte. »
4. *(combat, effet)* « Tous les Pokémon endormis se réveillent ! »
5. *(combat, sans effet)* « Personne ne dort. / La Flûte n'aurait aucun effet. »
6. *(ailleurs)* « {player} joue de la Poké Flûte… / Quel air entraînant ! »
7. *(choix devant Ronflex)* « Jouer de la Poké Flûte ? »

### 15.7 Ronflex

1. *(examen, sans Flûte : textes T-6 / T-7 du J17, inchangés)*
2. *(réveil)* « Ronflex se réveille ! / Il attaque, de très mauvaise humeur ! »
3. *(K.O.)* « Ronflex se calme… / Avec un grand bâillement, il retourne dans les montagnes. »
4. *(fuite)* « Ronflex bâille… / et se rendort aussitôt. »
5. *(examen après fuite ou défaite)* « Ronflex dort de nouveau. / Il ronfle comme si de rien n'était. »

### 15.8 Routes

1. *(panneau, Route 12 nord)* « ROUTE 12 / Lavanville — Route 11 »
2. *(panneau du ponton)* « PONTON DE PÊCHE / Prière de ne pas effrayer les poissons. »
3. *(description de zone, Route 12)* « Une longue route au bord de l'eau, au sud de Lavanville. »
4. *(description de zone, Route 16)* « Une route boisée à l'ouest de Céladopole. »
5. *(Pêcheurs, avant / après)* : à rédiger au plan technique, d'après RB (« Ça mord ! », « Encore
   raté… »), même ton que les Pêcheurs existants s'il y en a.

### 15.8 bis Poste de la Route 12

1. *(jeune femme, 2F, remise)* « Tu as l'air pressé. Tiens, ça devrait te plaire. » · *(système)* « {player} obtient la CT39 — Météores ! » · « Météores ne rate jamais sa cible. »
2. *(ensuite)* « D'ici, on voit tout le ponton. Les pêcheurs y passent leurs journées. »

### 15.9 Objectifs

1. « trouver M. Fuji, au sommet de la Tour. »
2. « rendre visite à M. Fuji. »

### 15.10 Pokédex

| Espèce | Taille / poids | Description |
|---|---|---|
| Ossatueur | 1,0 m · 45,0 kg | « Il manie l'os qu'il tient depuis l'enfance. Devenu fort, il protège farouchement les siens. » |
| Ronflex | 2,1 m · 460,0 kg | « Il ne fait que manger et dormir. Quand il s'endort au milieu d'un chemin, plus personne ne passe. » |

### 15.11 Capacité

- **Amnésie** : « Le lanceur fait le vide dans sa tête. Augmente beaucoup sa Défense Spéciale. »

## 16. Cas limites (à couvrir au plan technique)

1. **Sans Scope au 6F** (sauvegarde J19 relue en J21) : scène du J19, inchangée.
2. **Fuite contre Ossatueur, puis retour immédiat** : la scène se rejoue, combat neuf (PV pleins).
3. **Défaite contre un Sbire** : réveil au Centre ; Sbires battus le restent ; Ossatueur reste apaisé.
4. **Sauvegarde entre `fuji_rescued` et la Flûte** (application tuée pendant le fondu) : reprise dans
   la maison ou au 7F ; Fuji est dans la maison ; la remise se relance (§7.2).
5. **Flûte contre un Pokémon sauvage endormi par le joueur** : il se réveille aussi (RB).
6. **Flûte dans un combat SPECTRE (J19)** : effet normal sur les endormis ; la peur ne change rien.
7. **Ronflex utilise Repos, puis le joueur joue de la Flûte** : Ronflex se réveille.
8. **Équipe pleine à la capture de Ronflex** : Stockage (règle existante).
9. **Ronflex rendormi** : réveil possible à l'infini jusqu'à la capture ou au K.O.
10. **Compagnon** : il rentre dans sa Ball à chaque scène (règle J11) ; il ne gêne ni le recul du 6F
    ni le goulet de Ronflex (il n'occupe pas la grille) ; après le réveil, il passe avec le joueur.
11. **Corde Sortie au 7F** : ramène devant la porte de la Tour (règle du J19) ; Fuji non sauvé
    attend toujours.
12. **Deux Ronflex** : capturer l'un ne pose aucun drapeau de l'autre. Test dédié.
13. **Aucun drapeau du J21** n'est posé par une donnée des J19 ou J20 (tests de ces jalons, gardés).

## 17. Découpage et validation S24 [L-16]

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **21.0** | Grilles `pokemon_tower_7f.txt`, `route_12.txt`, `route_16.txt` et leur contrôle ; modification de la sortie ouest de `celadopole.txt` ; vues peintes ; données (Ossatueur, Ronflex, Amnésie, Pêcheurs, Sbires, Flûte, textes) ; lot d'art (Fuji, Pokémon, icône) | Kevin valide grilles, vues et art |
| **21A** « La Tour résolue » | Révélation et combat d'Ossatueur, brume apaisée, 7F et Sbires, Fuji, téléportation, remise de la Flûte, variantes de Lavanville, objectifs. Départ de débogage `tower_marowak_qa` | S24 |
| **21B** « La Flûte » | Objet clé utilisable (exploration et combat), deux Ronflex, Route 12 nord, Route 16 est, QA de bout en bout (Tour → Flûte → deux Ronflex) et tests d'interruption | S24 |

**Critère de clôture (V2)** : le joueur apaise Ossatueur, sauve M. Fuji, obtient la Poké Flûte,
affronte les deux Ronflex et continue librement, sans blocage.

**Le code commence après la clôture du J20** (moteur de combat, étape de scène du J19, Scope).
Grilles, vues, données et art avancent dès maintenant.

## 18. Valeurs par défaut (règle 4)

- Dissolution SPECTRE → Ossatueur : environ 1 s ; lumière qui monte : environ 2 s.
- IA d'Ossatueur et de Ronflex : `random`.
- Table du 7F : poids du 6F.
- Fuji dans sa maison : près de la fenêtre.
- Notes de musique de la Flûte : environ 1,5 s.
- Réveil de Ronflex : petit saut et bulle « ! » existante.
- Poste de la Route 12 : modèle de poste existant ; CT39 Météores au 2F, drapeau `got_tm39`.
- Fonds de combat des Routes 12 et 16 : fonds de route existants.
- Amnésie : Défense Spéciale +2.

## 19. Grilles v1 (lot 21.0) — À VALIDER par Kevin

> **M-3 (2026-10-16)** : la grille `route_12.txt` est révisée pour poser Ronflex au croisement
> (passage de 2 cases ; tronc en x 25..26 de la rangée 92 au bord sud ; Ronflex (25..26, 93..94) ;
> Lavanville → devant Ronflex : 144 pas). Contrôle conforme ; vue peinte refaite (r3, Ronflex visible).
> Le tableau ci-dessous décrit la v1 avant révision.

> Conçues le 2026-10-15 (branche `j21-grilles`, fusionnée ici). La grille fait foi pour la
> géométrie. Contrôle : `python3 -I tools/art/plan_check_j21.py` → **TOUT EST CONFORME** (il lit
> les grilles voisines des J17 à J20 sur leurs branches). Son enregistrement dans
> `tools/art/plan_check.py` se fera à l'intégration (une ligne, indiquée dans son en-tête).

| Carte | Taille | Points clés |
|---|---|---|
| `pokemon_tower_7f.txt` | 20 × 18 | Géométrie RB ; 3 Sbires en (9, 11) →, (12, 9) ←, (9, 7) →, vue 3, **inévitables dans l'ordre 1, 2, 3** ; Fuji en (10, 3) devant un autel de 2 cases ; escalier (9, 16), paire T67 ; au 6F, `arrivee_T67` à ajouter en (10, 16). |
| `route_12.txt` | 39 × 102 | Route 12 nord à l'échelle × 1,5 ; raccord nord (21..23, 0) ↔ Lavanville (21..23, 35) ; raccord ouest (0, 93..94) ↔ Route 11 (75, 14..15) ; poste 9 × 9 traversant (portes nord et sud de 3 cases) ; 4 Pêcheurs (vue 6), le n° 1 inévitable ; bord sud « À venir » ; Lavanville → croisement : 145 pas. |
| `route_16.txt` | 44 × 28 | Raccord (43, 21..23) ↔ Céladopole (0, 21..23) ; Ronflex 2 × 2 en (24..25, 22..23) ferme tout le goulet ; `face_ronflex` (26, 22..23) ; porte du poste (15..16, 20) « À venir » ; voie haute et arbre en décor. |

**Valeurs par défaut retenues [D]** (en attendant l'avis de Kevin) :
- **Ronflex : le `FlagGate` s'ouvre sur `*_done`** (dossier §9.4).
- **Ronflex de la Route 12** (M-3) : au croisement, en (25..26, 93..94) ; on lui parle depuis le nord (25..26, 92), l'ouest (24, 93..94)
  ou le sud (25..26, 95) (repères `face_ronflex`) ; panneau du ponton en (24, 95).
- **Poste de la Route 12** : deux portes (traversée) et un 2F (CT39) ; lisibilité de la porte nord
  à vérifier sur la vue peinte.
- **Îlot de la CT Jackpot de RB** (accessible seulement en Surf dans RB) : **îlot décor vide** ; la
  question revient avec le Surf.
- **Arbre de la Route 16** : peint comme un **arbre dense ordinaire** (la Coupe existe depuis le J16 :
  un faux arbre à Couper frustrerait).
- **Aucune herbe ni rencontre** sur la Route 12 nord et la Route 16 est (dans RB, les herbes sont au
  sud du croisement et sur la voie haute).
- Fuji tourné vers le nord (il prie devant l'autel) ; ponton de 3 cases ; raccord de la Route 11 sur
  2 rangées.

**Question pour Kevin** : la Route 12 nord fait 39 × 102 cases à l'échelle × 1,5 (un peu plus que
Céladopole), surtout de l'eau et du ponton. Garder, ou réduire à × 1,25 pour alléger la peinture ?
Défaut : **garder × 1,5**.

## Décisions verrouillées

- Les 7 décisions de la V2 et les arbitrages L-1 à L-16.
- **Résolution de la Tour = possession de `silph_scope`**, jamais un drapeau du J20.
- **Ossatueur n'est jamais capturable** ; la Ball n'est pas consommée.
- **Une seule Poké Flûte**, remise de façon idempotente.
- **Deux Ronflex indépendants** : le passage s'ouvre sur `*_done` (capture ou K.O.).
- Aucun Dresseur ni objet du J19 ne réapparaît ; **aucun changement de version de sauvegarde**.
