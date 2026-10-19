# Dossier 22 — Les mystères de la Tour Pokémon (jalon 19)

> Consolidé par Claude le 2026-10-14, à partir de la V2 de ChatGPT (`passes/j19-v2-chatgpt.md`) et
> de la passe d'alignement (`passes/j19-v2-alignement.md`).
>
> **Arbitrages de Kevin** : les 7 décisions de la V2 sont verrouillées, et **K-1 à K-20 sont acceptés
> tels que recommandés** (2026-10-14).
>
> **Faits Rouge/Bleu** : vérifiés dans le désassemblage `pret/pokered` (cartes, rencontres, scripts,
> équipes) ; les espèces sont recoupées avec PokeAPI (`red-blue`).
>
> **Sigles** :
> - **[V]** : validé par Kevin.
> - **[D]** : valeur par défaut (règle 4), notée et non bloquante.
> - **RB** : Rouge/Bleu.
> - **K26** : invention de Kanto 2026.
>
> **Textes** : le lot du §15 est **validé par Kevin (2026-10-14)**.
>
> **Grilles v1** : validées par Kevin (2026-10-14), avec leurs trois choix (recul du SPECTRE au
> nord, rival rendu inévitable en murant (14..15, 4), murs dans la grille comme les grottes).
>
> **Étages** : « 2F » = 1er étage = « 2e niveau » de la V2. Les cartes s'appellent
> `pokemon_tower_1f` à `pokemon_tower_7f`.

## Décisions de Kevin

### Les 7 décisions de la V2 [V]

1. Tour partiellement explorable au J19. Le Scope Sylphe s'obtient à Céladopole au J20.
2. Cinquième combat contre le rival, victoire obligatoire.
3. Atmosphère mystérieuse, émouvante et respectueuse.
4. Fantominus et Spectrum selon les tables historiques.
5. Rencontre et résolution du spectre d'Ossatueur uniquement après le Scope.
6. M. Fuji disparu ; son sauvetage attend le retour avec le Scope.
7. Team Rocket suggérée par des indices, sans confrontation au J19.

### Arbitrages K-1 à K-20 (passe d'alignement) [V]

| # | Décision |
|---|---|
| K-1 | Dossier n° 22. |
| K-2 | Classe des Dresseurs : **Exorciste** partout. La gardienne de l'escalier du J18 (« Médium ») devient une Exorciste qui ne combat pas. |
| K-3 | Au J19, la gardienne s'écarte de l'escalier **après un déclencheur**, avec une ligne d'inquiétude. Un seul drapeau. |
| K-4 | Scène du rival = dossier 06 §6, plus **une** réplique sur les spectres au plus. Jamais un mot sur son Rattatac. |
| K-5 | Équipe du rival : **celle de RB** (5 Pokémon, dont Caninos, Léviator, Noeunoeuf selon la variante). |
| K-6 | Niveaux du rival fixés par **simulation**, RB comme repère. Fourchette visée : 22 à 26. |
| K-7 | **Osselait** est dans les tables (RB). Au J19, il reste un SPECTRE. |
| K-8 | Combat SPECTRE : toutes les règles RB, mais **la Ball n'est pas consommée** (refus avant le lancer). |
| K-9 | Le SPECTRE n'enregistre **rien** au Pokédex. |
| K-10 | Taux de rencontres RB : 10 du 3F au 5F, 15 au 6F. À revoir après la QA S24 si c'est pénible. |
| K-11 | Le mode spectre se déclenche sur la **possession de `silph_scope`** dans le Sac. |
| K-12 | Blocage du 6F : **combat SPECTRE scripté**, puis le joueur est repoussé. Jamais nommé Ossatueur au J19. |
| K-13 | Le 7F **n'est pas construit** au J19. |
| K-14 | **9 Exorcistes** : 2, 2, 3 et 2 du 3F au 6F, dont les 3 inévitables de RB. |
| K-15 | Un PNJ dit que Fuji avait vu des gens étranges monter à la Tour. Flou : ni « Rocket », ni « enlevé ». |
| K-16 | Indices : panneau du Scope Sylphe, Exorciste du 2F, plus **une** rumeur sur le Casino de Céladopole. |
| K-17 | **Seulement des objets existants**, remplacés sinon. L'objet caché du 5F est gardé (les objets cachés existent depuis le J12), avec un objet existant à la place de l'Élixir. |
| K-18 | Son hors du J19. Les intentions sont notées pour le jalon audio. |
| K-19 | Zone purifiée RB : soin complet, illimité, ni rencontre ni Dresseur. |
| K-20 | Trois sous-jalons : **19.0, 19A, 19B**, avec deux validations S24. |

## 1. Intention

La Tour Pokémon est le premier lieu du jeu **où l'on ne gagne pas en se battant**.

Le joueur y entre fort de quatre badges possibles et d'une équipe rodée. Il découvre pourtant des
Pokémon qu'il ne peut ni voir, ni toucher, ni capturer. Ses Pokémon ont peur. Il y affronte un rival
moins bavard que d'habitude, se repose dans une zone de lumière blanche, puis bute contre une
présence qui refuse de le laisser monter.

Le joueur ressort avec une seule question : *qu'est-ce qui m'empêche de monter ?* Avec elle, deux
fils : un panneau sur un Scope Sylphe, et une rumeur à Céladopole.

Ton : calme, presque solennel. Le mystère passe avant la peur, il n'y a aucun jumpscare. On honore
les Pokémon disparus ; on n'en fait jamais un décor d'horreur.

## 2. Périmètre

| Dans le J19 | Hors du J19 |
|---|---|
| Ouverture de l'escalier du rez-de-chaussée (gardienne, K-3) | Carte du 7F, Sbires Rocket, M. Fuji (**J21**) |
| Cartes 2F à 6F | Scope Sylphe : objet et obtention (J20) |
| Rival n° 5 au 2F | Ossatueur révélé, combattu, apaisé ; Poké Flûte (**J21**) |
| Mode spectre : rencontres sauvages, combat, combat scripté, retour en arrière | Poké Flûte, Ronflex |
| 9 Exorcistes, zone purifiée, objets | Capture de Fantominus, Spectrum ou Osselait (impossible sans Scope) |
| Variantes de dialogue à Lavanville, panneau, rumeur | Son, musique, pas (K-18) |
| Fantominus, Spectrum, Osselait (données) ; Caninos, Léviator, Noeunoeuf (rival) | Planches de marche des spectres (compagnon) |

## 3. Contrat d'entrée

| Le J19 suppose | Jalon | Si c'est faux |
|---|---|---|
| Lavanville, son Centre (point de repos), la maison de M. Fuji, la maison d'Osselait | J18 | Le J19 ajoute ses variantes là où les PNJ existent. Sinon, il les place lui-même. |
| Rez-de-chaussée de la Tour, avec une gardienne sur l'escalier (I-21, renommée par K-2) | J18 | **Confirmé par le J18** (2026-10-15, `docs/dossier-j18` 89b46a9a) : pnj `exorciste_gardienne` en (17, 3) de `tour_pokemon_rdc.txt`, `unless=tower_stairs_open` ; escalier (17, 2) → `pokemon_tower_2f`. La planche Exorciste est **produite par le J18** et réutilisée ici. |
| **Un emplacement de panneau à Lavanville** pour le Scope Sylphe | J18 | **Réservé par le J18** en (42, 11) de `tools/plans/lavanville.txt` (`panneau_scope_j19`, repère libre au J18), lu depuis (41, 11) tourné →. Le J19 le passe en panneau bloquant. |
| **La sortie ouest (Route 8) ouverte**, ou au moins annoncée | J18 / J20 | **Annoncée par le J18** : (0, 10..12) « ROUTE 8 — À venir », spawns `from_route_8` prêts ; ouverte par le J20 (grille de la Route 8 à recaler sur Lavanville). |
| Rival n° 4 : Roucoups, Rattatac, Kadabra, starter évolué | J16 | Le n° 5 reste cohérent : Rattatac disparaît (dossier 06 §6). |
| Kadabra existe (données, art) | J16 | Le J19 le crée. |
| Équipe du joueur vers les niveaux 22 à 25 | J16–J18 | La simulation K-6 absorbe l'écart. |

**Contrat de sortie vers le J20** (passe J20 §4, accepté) :
- les spectres dépendent de la possession de `silph_scope` ;
- `rival_tower_won` est posé.

## 4. La Tour : étage par étage

### 4.1 Règles communes

- **Taille** : 20 × 18 cases par étage, comme RB [D]. Le rez-de-chaussée garde sa taille du J18.
- **Escaliers** : ils alternent droite / gauche comme dans RB. Un escalier est un warp `STEP_ON`
  sur la case de l'escalier ; on arrive à côté de l'escalier d'en face.
- **Entrée** : pas de Corde Sortie au rez-de-chaussée.
- **Corde Sortie** : la Tour est déclarée dans `caves.json` [D]. Utilisée du 2F au 6F, elle ramène
  **devant la porte de la Tour**.
- **Lumière** : un profil `tower` dans `lighting.json`, gris violacé, doux, très lisible. Les
  bougies sont des halos additifs à battement lent. Une brume lente est posée en calque. **Pas de
  `Light2D`.** « Réduire les animations » coupe la brume et le battement.
- **Défaite** : réveil au Centre de Lavanville.
- **Compagnon (J11)** : il suit comme ailleurs, sans réaction propre [D].

### 4.2 Contenu

| Étage | Contenu | Sauvages |
|---|---|---|
| **1F** (J18) | Visiteurs, tombes, gardien, **gardienne** (Exorciste) sur l'escalier. Au J19, elle s'écarte (K-3, §6.4). | non |
| **2F** | **Rival n° 5**, au bord du seul passage vers l'escalier du 3F (inévitable). Une **Exorciste qui ne combat pas** parle du Scope Sylphe. Tombes. | non |
| **3F** | 2 Exorcistes (facultatifs) ; Corde Sortie au sol. Premiers SPECTRES. | oui (10) |
| **4F** | 2 Exorcistes, dont **E3, inévitable** ; Réveil, Super Potion [D]. | oui (10) |
| **5F** | 3 Exorcistes (facultatifs) ; **zone purifiée** au centre ; Pépite. Une **Exorciste qui ne combat pas** se tient près de la zone. | oui (10) |
| **6F** | 2 Exorcistes, **tous deux inévitables** ; Super Potion [D]. **Le SPECTRE bloque l'escalier du 7F** (§6.3). | oui (15) |
| **7F** | Non construit (K-13). Le warp est en place, mais on ne peut jamais l'atteindre. | — |

**Objets [V K-17]** :
- les objets RB qui n'existent pas sont remplacés par la **Super Potion** si le J15 l'a créée,
  sinon par la **Potion** ;
- l'Élixir, le PV Plus, le Super Bonbon et Précision + attendent leur jalon ;
- l'Élixir caché du 5F devient une **Super Potion cachée** en (4, 11) de la grille (RB : (4, 12), un mur dans la grille v1) : les objets cachés existent déjà (Route 3 au J12, Route 24 au J13) [D] ;
- au total : 3F 1, 4F 2, 5F 1 (+ 1 caché), 6F 1.

## 5. Rencontres sauvages [V décision 4, K-7, K-10]

**Terrain** : nouveau terrain `floor`, qui couvre **toute case praticable**. Il exclut la zone
purifiée et ses abords immédiats. Les poids reprennent les emplacements de tirage RB (sur 256).

| Table | Cartes | Taux | Fantominus | Spectrum | Osselait |
|---|---|---|---|---|---|
| `pokemon_tower_low` | 3F | 10 | N18–24, poids 229 | N25, poids 3 | N20–22, poids 24 |
| `pokemon_tower_mid` | 4F, 5F | 10 | N18–24, poids 219 | N25, poids 13 | N20–22, poids 24 |
| `pokemon_tower_high` | 6F | 15 | N19–24, poids 216 | N26–28, poids 16 | N22–24, poids 24 |

La table du 7F (Fantominus N20–24, Spectrum N28–30, Osselait N22–24, taux 15) est **notée pour le
J20**, mais pas créée.

**Sans `silph_scope` dans le Sac**, chacune de ces rencontres est un **SPECTRE** (§6). L'espèce
réelle est tirée en coulisse, puis jetée.

## 6. Le mode spectre [V K-8, K-9, K-11, K-12]

### 6.1 Quand ?

Un combat est un combat SPECTRE si les deux conditions sont vraies :
- c'est une rencontre sauvage sur une carte marquée `ghost_unless_item: "silph_scope"` (2F à 7F) ;
- le joueur **n'a pas** `silph_scope` dans le Sac.

Ce test est relu à **chaque** rencontre. Aucun drapeau, aucune migration : le jour où le Scope est
dans le Sac, le mode normal revient tout seul.

### 6.2 Déroulé du combat

| Aspect | Règle |
|---|---|
| Entrée | Fondu de combat ordinaire, **pas de cri**. Silhouette **SPECTRE** peinte (une seule planche). Carte adverse : nom « SPECTRE », **niveau masqué** (« N?? ») [D]. Message d'ouverture §15.3. |
| Pokédex | **Rien** n'est enregistré : ni « vu », ni première rencontre (K-9). |
| Tour du joueur, capacité choisie | Remplacée par « {pokemon} est trop effrayé pour bouger ! ». Le **sommeil** et le **gel** gardent leur propre message. Une confusion ne fait pas se blesser : la peur passe avant [D]. |
| Tour du SPECTRE | Il ne fait que parler (« Va-t'en… »). Ni dégâts, ni statut. |
| Sac | Autorisé. Soins et remèdes fonctionnent. |
| Ball | **Refusée avant le lancer, non consommée** : message §15.3 (K-8). |
| Changer de Pokémon | Autorisé. |
| Fuir | **Réussit toujours**, quelles que soient les Vitesses. |
| Fin | Aucune XP, aucun argent, aucun Grand moment. |

### 6.3 Le SPECTRE du 6F (blocage)

- **Déclencheur** : la case devant l'escalier du 7F, tant que `ghost_marowak_calmed` n'est pas posé.
  Ce drapeau est **nommé ici, mais posé seulement au J21**.
- **Scène** :
  1. le joueur s'arrête, la brume s'épaissit ;
  2. une ligne de texte (§15.3) ;
  3. **combat SPECTRE scripté**, selon les règles du §6.2, **toujours masqué** (`ghost: always`),
     même si le joueur a le Scope (J20) : seul le J21 change cette donnée. L'espèce réelle est Ossatueur N30, mais
     **elle n'est jamais nommée, montrée ni enregistrée** au J19 ;
  4. à la fin du combat (fuite, ou défaite impossible), le joueur est **repoussé d'une case** vers le
     nord, à l'opposé de l'escalier qui est en bas de la carte (grille : déclencheur (10, 16), recul
     (10, 15) ; RB repoussait d'une case à droite), sur le modèle de `route_3_guard`. Le déclencheur se réarme.
- **Au J20**, le joueur a le Scope : les rencontres sauvages sont identifiées (K-11), mais le SPECTRE du
  6F **reste un blocage** (dossier 23 §14 : le J20 s'arrête au Scope). **Au J21** (dossier 24), la
  même scène bascule vers la révélation. C'est la session J21 qui la
  conçoit.

### 6.4 La gardienne de l'escalier (rez-de-chaussée) [V K-3]

- **Au J18**, elle prie sur l'escalier et demande le silence.
- **Au J19** : à la première entrée dans la Tour (déclencheur à la porte, `unless tower_stairs_open`),
  elle se retourne. Elle dit la ligne d'inquiétude (§15.1), qui annonce que Fuji n'est pas redescendu.
  Elle **s'écarte d'une case** et `tower_stairs_open` est posé. Elle reste ensuite à côté de
  l'escalier, avec un dialogue d'après.

## 7. Le rival n° 5 (2F) [V décision 2, K-4, K-5, K-6]

### 7.1 Scène

- **Déclenchement** : sur les cases devant lui, au bord du passage vers l'escalier du 3F, tant que
  `rival_tower_won` n'est pas posé.
- **Déroulé** :
  1. il se retourne ;
  2. dialogue avant le combat (§15.2) ;
  3. combat ;
  4. après la victoire du joueur, il reste un temps silencieux (≈ 2 s [D]) ;
  5. sa dernière réplique ;
  6. il part par l'escalier du bas.
- **Il n'y a pas** de « JE VAIS M'ENTRAÎNER » (dossier 06 §6).

### 7.2 Défaite et persistance

On reprend le **motif du J13**, avec les drapeaux `rival_tower_won`, `rival_tower_lost_once` et
`rival_tower_retried` :
- une défaite ramène au Centre de Lavanville ;
- le rival attend de nouveau au 2F ;
- la deuxième tentative a une réplique courte ;
- **aucun drapeau de victoire n'est posé avant une vraie victoire**.

Le **Grand moment** `rival_battle` n'est écrit qu'à la victoire, comme pour le n° 4.

### 7.3 Équipe (RB comme repère ; niveaux finaux par simulation, K-6)

La variante suit **le starter du joueur**, comme `team_by_starter`. Dans RB, elle découle du starter
du rival, et c'est la même chose.

| Starter du joueur | Équipe RB (repère) |
|---|---|
| Bulbizarre | Roucoups 25, Noeunoeuf 23, Léviator 22, Kadabra 20, **Reptincel 25** |
| Salamèche | Roucoups 25, Caninos 23, Noeunoeuf 22, Kadabra 20, **Carabaffe 25** |
| Carapuce | Roucoups 25, Léviator 23, Caninos 22, Kadabra 20, **Herbizarre 25** |

Ce que dit la règle :
- **Pas de Rattatac** : c'est le tournant du dossier 06 §6, jamais commenté.
- **Fourchette visée : 22 à 26.** Le n° 4 est vers 16–20, et le J20 attend une équipe de 25 à 28 à
  Céladopole.
- **La simulation** (méthode `simulate_brock.gd`) tourne quand les équipes des J16 à J18 sont
  connues. Elle peut adoucir la variante Bulbizarre, comme le J13 l'a fait.
- **IA** : `smart`. Les changements de Pokémon suivent ce que le moteur sait faire à l'ouverture du
  J19.
- **Capacités** : naturelles au niveau. Elles sont **choisies à la main** quand une mécanique manque :
  Kadabra suit la règle du J16, et Draco-Rage de Léviator demande des dégâts fixes de 40, une valeur
  déjà prévue pour Sonicboom au J16.
- **Récompense** : `prize_per_level` du rival, dans la continuité des n° 3 et 4. Repère RB :
  1 625 ₽.

**Équipes finales (T21, 2026-10-19, règle de difficulté de Kevin, `docs/tech/jalon-19-equilibrage.md`
§8)** — la fourchette 22–26 n'est plus la cible :

| Starter du joueur | Équipe du rival (T21) |
|---|---|
| Bulbizarre | Roucoups 20 (sans Tornade), Noeunoeuf 20, **Sabelette 20** (au lieu de Léviator), Kadabra 17, **Reptincel 21** |
| Salamèche | Roucoups 22, Caninos 22, Noeunoeuf 22, Kadabra 20, **Carabaffe 25** |
| Carapuce | Roucoups 21, Léviator 25, Caninos 21, Kadabra 18, **Herbizarre 26** |

## 8. Les Exorcistes [V K-2, K-14]

- **Avant le combat** : ils sont **possédés**. Leur ligne est une voix d'esprit (§15.4).
- **Après le combat** : ils reprennent leurs esprits, et l'un d'eux parle du Scope.
- **Récompense** : `prize_per_level` 30 (RB).
- **Vision** : 2 à 3 cases.
- **IA** : `random`.
- **Sprite** : une planche « Exorciste » (servante de prière, voile, chapelet), la même que la
  gardienne du J18.

| Id | Étage | Prénom [D] | Équipe (RB) | Inévitable |
|---|---|---|---|---|
| `tower_channeler_1` | 3F | Exorciste Hortense | Fantominus 23 | non |
| `tower_channeler_2` | 3F | Exorciste Odile | Fantominus 22 | non |
| `tower_channeler_3` | 4F | Exorciste Solange | Fantominus 23, Fantominus 23 | **oui** |
| `tower_channeler_4` | 4F | Exorciste Mireille | Fantominus 24 | non |
| `tower_channeler_5` | 5F | Exorciste Bérénice | Spectrum 23 | non |
| `tower_channeler_6` | 5F | Exorciste Marthe | Fantominus 24 | non |
| `tower_channeler_7` | 5F | Exorciste Ysée | Spectrum 22 | non |
| `tower_channeler_8` | 6F | Exorciste Paulette | Fantominus 24 | **oui** |
| `tower_channeler_9` | 6F | Exorciste Clémence | Fantominus 24 | **oui** |

**Capacités naturelles** : au N22–24, Fantominus et Spectrum connaissent **Léchouille, Onde Folie
et Ténèbres**. Hypnose arrive au N27 et au N29, donc après ces niveaux.

**Pokédex** : ces combats marquent Fantominus et Spectrum « vus », par le chemin habituel des
Dresseurs. **C'est ainsi que le joueur les découvre.**

## 9. La zone purifiée (5F) [V K-19]

- **Où** : un carré de 2 × 2 cases au centre du 5F, sur un sol plus clair, avec un halo blanc fixe.
- **En entrant** :
  1. fondu blanc court ;
  2. **soin complet** de l'équipe (PV, PP, statuts) ;
  3. message (§15.5).
- **À l'intérieur** : ni rencontre, ni vision de Dresseur.
- **En sortant** : la zone se réarme. Le soin est **illimité**.
- **Point de repos** : ce n'en est **pas** un. Une défaite ramène au Centre de Lavanville.

## 10. Lavanville au J19 [V décision 6, K-15, K-16]

**PNJ du J18 à Lavanville** (dossier 21 §6.3) : un enfant et son Pokémon à la Maison des Pokémon ; il n'y a ni « homme » chez Fuji ni gentleman au Centre : **le J19 les ajoute lui-même**.

**Variantes de dialogue** : elles sont ajoutées aux PNJ du J18 et actives dès la build J19, sans
drapeau. Elles **remplacent** les lignes du J18 qui parlent de Fuji au présent.

| PNJ | Rôle au J19 |
|---|---|
| Enfant, maison de Fuji (J18) | Fuji est monté à la Tour **et n'est pas redescendu**. |
| Homme, maison de Fuji | Fuji avait vu des gens étranges monter à la Tour, la nuit (K-15). |
| Fille, **Maison des Pokémon de M. Fuji** (Q-2 = A, Kevin, 2026-10-15 : pas de nouveau bâtiment) | Osselait, recueilli chez Fuji, attend sa mère ; on dit qu'elle est morte en fuyant des gens. Rien ne nomme la Team Rocket. |
| Gentleman, Centre de Lavanville | **La rumeur du Casino de Céladopole** (K-16). |
| **Panneau** près de la Tour | Publicité pour le **Scope Sylphe** (K-16). |

Décision 7 : le mot **« Rocket » n'apparaît nulle part au J19**. Les « hommes en noir » et l'argent
suffisent.

## 11. Ambiance [V décision 3, K-18]

- **Lumière et décor** :
  - palette : pierre gris violacé, lumière douce et froide ;
  - tombes et stèles basses, fleurs fanées et fraîches, offrandes ;
  - une bougie par stèle importante.
- **Animations** : une flamme qui bat lentement, une brume qui glisse, quelques particules. Rien qui
  surgit.
- **SPECTRE** : une silhouette peinte en brume violette, sans yeux lisibles, sans contour noir. Elle
  apparaît dans le fondu de combat, jamais en surprise dans le monde.
- **Exorcistes possédés** : leur voix d'esprit est **typographique** (italique, points de
  suspension), sans effet d'écran.
- **Son (K-18)** : hors J19. Intentions pour le jalon audio :
  - thème intérieur feutré, dérivé de celui de Lavanville ;
  - pas sur la pierre ;
  - longs silences ;
  - aucun stinger d'horreur.

## 12. Espèces, capacités, objets et assets

### 12.1 Espèces

| Espèce | Rôle au J19 | Données | Art |
|---|---|---|---|
| Fantominus (92) | Exorcistes ; sauvage caché | complètes (Spectre / Poison ; évolue au N25) | face : artwork officiel existant ; dos : **lot** |
| Spectrum (93) | Exorcistes ; sauvage caché | complètes. L'évolution par échange vers Ectoplasma reste inactive : pas d'échange. | face : existant ; dos : `dos_ia_093` provisoire existant |
| Osselait (104) | sauvage caché seulement | complètes (Sol ; évolue au N28) | **aucun au J19**, il ne s'affiche jamais. Art au J20 (capturable dès que le Scope est dans le Sac). |
| Ossatueur (105) | spectre du 6F, caché | données de combat (N30) | aucun au J19 |
| Caninos, Léviator, Noeunoeuf | rival n° 5 | complètes | face : artwork officiel |
| Kadabra | rival n° 5 | créé par le J16 (sinon ici) | J16 |

**Pokédex** : entrées de Fantominus, Spectrum, Caninos, Léviator et Noeunoeuf. Celles d'Osselait et
d'Ossatueur peuvent attendre le J20 (Osselait) et le J21 (Ossatueur), car on ne les voit jamais au J19.

### 12.2 Capacités

| Capacité | Valeurs | Remarque |
|---|---|---|
| **Léchouille** | Spectre, 30, 100 %, 30 PP, paralysie 30 % | valeurs actuelles |
| **Ténèbres** | Spectre, dégâts = niveau | `fixed_damage` `mode:"level"` existe déjà. Ne touche pas un type Normal (règle actuelle) [D]. |
| **Hypnose** | Psy, 60 %, sommeil | pour les learnsets et le J20 |
| **Massd'Os** | Sol, 65, 85 %, peur 10 % | Osselait et Ossatueur |
| **Morsure**, **Draco-Rage** | si absentes | rival (Léviator), selon la simulation |

**Onde Folie** existe déjà (J12).

### 12.3 Objets

Rien de nouveau au J19.
- `silph_scope` est **réservé** : son identifiant est fixé ici, mais l'objet est créé par le J20.
- Les objets au sol sont des objets existants (§4.2).

### 12.4 Art (lot 19.0)

- **Cartes** :
  - 5 vues peintes, du 2F au 6F, sur une même enveloppe déclinée ;
  - décor de la zone purifiée ;
  - panneau du Scope à Lavanville.
- **Personnages** :
  - planche **Exorciste** (marche et pose de prière), mutualisée avec le J18 ;
  - silhouette **SPECTRE** de combat.
- **Pokémon** : dos de Fantominus. Celui de Spectrum (provisoire) suffit tant qu'on ne peut pas le
  capturer.
- **Combat** : fond **CB.3 `tour_pokemon`** (dalles, stèles, brume), qui sert à tous les étages.

### 12.4 bis Lot d'art 19.0 (série 20) — VALIDÉ par Kevin le 2026-10-15

- Fiche `fiches-assets/serie-20-tour-pokemon.md`, script `tools/art/serie20.py`.
- Silhouette SPECTRE (brume indistincte, taille constante quelle que soit l'espèce cachée) ; dos de
  Fantominus **provisoire IA** (pas de modèle 3D 092) ; décor CB.3 `tour_pokemon` (brume ajoutée
  dans Godot) ; panneau du Scope (2 cases, sans texte). La planche Exorciste vient du J18.

### 12.5 Vue générale peinte v1 — VALIDÉE par Kevin le 2026-10-14

- **Image** : `reference/tour-pokemon-vue-generale-v1.png` (essai 4,
  `tools/art/prompts/CONCEPT_TOUR_POKEMON_VUE_GENERALE_r4.txt`).
- **Plan** : `reference/tour-pokemon-plan-v1.png` (`python3 tools/art/plan_aplats.py --tour-pokemon`).
- **Disposition** : 2F et 3F en haut, 4F et 5F au milieu, 6F en bas.
- Elle donne la DA et l'ambiance ; **la grille `tools/plans/pokemon_tower_*.txt` fait foi** (règle 10).
- **Écarts connus** :
  - 2F : 3 × 2 tombes dans la salle est au lieu de 4 × 2, et le rival est trop haut ; la grille le
    place en (14, 5).
  - 6F : le spectre a une silhouette humaine encapuchonnée. **En jeu, il reste une forme indistincte**
    (§11), comme la colonne de brume de l'essai 3.
  - 4F : le labyrinthe est respecté dans l'esprit, mais pas case par case.
  - Les étages 2F à 5F s'assombrissent peu ; le profil de lumière `tower` fera la gradation.

## 13. Données et sauvegarde [V K-11]

**Aucun changement de version de sauvegarde.**

| Drapeau | Posé par |
|---|---|
| `tower_stairs_open` | Scène de la gardienne (§6.4) |
| `tower_ghost_met` | Première rencontre du SPECTRE du 6F (§6.3) ; sert aux objectifs (§15.7) |
| `rival_tower_won`, `rival_tower_lost_once`, `rival_tower_retried` | Rival n° 5 |
| `beaten_tower_channeler_1` … `_9` | Exorcistes (mécanisme existant) |
| Objets ramassés | Mécanisme existant |

**Réservés au J21** (dossier 24), nommés ici et **jamais posés ni lus par le J19 ni par le J20** :
- `ghost_marowak_calmed` ;
- `fuji_rescued` ;
- `got_poke_flute` ;
- `beaten_tower_rocket_1..3`.

**Code à ajouter** (coûts dans la passe, §3) :
- un champ de carte ou de table `ghost_unless_item` ;
- un terrain `floor` ;
- un **masque d'identité** sur le combattant adverse (nom, sprite, niveau, pas de « vu ») ;
- des règles de combat `fear` (trop effrayé), `flee_always` et `ball_refused` ;
- une action d'IA « message » ;
- une étape de scène **`battle` sauvage** (espèce, niveau, règles) ;
- une étape ou une action de **soin** pour la zone purifiée.

## 14. Découpage et validation S24 [V K-20]

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **19.0** | Grilles `tools/plans/pokemon_tower_2f.txt` à `6f.txt` (**v1 validées par Kevin le 2026-10-14**, contrôle `tools/art/plan_check_tour_pokemon.py` OK) et leur contrôle, vues peintes, données (espèces, capacités, Exorcistes, rival), lot d'art | Kevin valide les grilles et les vues, comme aux jalons précédents |
| **19A** | **Mode spectre** complet : rencontres `floor`, combat SPECTRE, combat scripté, retour en arrière. Exorcistes et combats contre Fantominus et Spectrum. Départ de débogage `tower_ghost_qa`. | S24 |
| **19B** | Cartes 2F à 6F, gardienne, rival n° 5, zone purifiée, blocage du 6F, objets, variantes de Lavanville, panneau, rumeur. **QA de bout en bout** (départ `tower_qa`) et tests de sauvegarde. | S24 |

**Critère de clôture (V2)** :
- le joueur explore le 1F au 6F, bat le rival, rencontre des SPECTRES et bute contre le blocage ;
- il **ne peut ni** atteindre le 7F, **ni** voir Fuji, **ni** obtenir la Poké Flûte.

**Le code commence après la clôture du J18** (C-7).

## 15. Lot de textes — VALIDÉ par Kevin le 2026-10-14

> Textes proposés par Claude, conformes au dossier 06 §6 pour le rival. Ton : sobre, respectueux.
> `{rival}`, `{player}`, `{pokemon}` sont des jetons.

### 15.1 Rez-de-chaussée, gardienne (K-3)

1. *(J19, première entrée ; elle se retourne)* « Ah… C'est vous. Pardonnez-moi, je priais. »
2. « Les esprits sont agités, ces derniers jours. Même ici, on ne trouve plus le calme. »
3. « M. Fuji est monté il y a plusieurs jours. Il n'est jamais redescendu. »
4. « Si vous montez… restez près de vos Pokémon. » *(elle s'écarte)*
5. *(après)* « Je prie pour ceux qui reposent ici… et pour ceux qui sont montés. »

### 15.2 Rival n° 5 (2F)

1. *(il se retourne)* « … »
2. « {player}. …Tu es venu pour quoi ? »
3. *(il se met en garde, sans attendre la réponse)* « Peu importe. »
4. *(défaite du rival, après le silence)* « …Il y a des choses, plus haut. Des Pokémon que personne
   n'arrive à voir. »
5. « Laisse tomber. » *(il descend)*
6. *(le joueur a perdu une fois ; nouvelle tentative)* « Encore toi. …Vas-y. »
7. *(victoire du rival, avant le réveil au Centre)* « …Rentre. Ce n'est pas un endroit pour toi. »

### 15.3 SPECTRE

1. *(ouverture)* « Un SPECTRE apparaît ! »
2. « Impossible d'identifier le SPECTRE… »
3. *(tour du joueur)* « {pokemon} a trop peur pour bouger ! » *(forme neutre, §15.7)*
4. *(tour du SPECTRE)* « SPECTRE : Va-t'en… Va-t'en… »
5. *(Ball)* « Pas question de lancer une Ball sur… ça. Elle passerait au travers. »
6. *(fuite)* « Vous prenez la fuite ! » *(message de fuite existant, s'il convient)*
7. *(6F, avant le combat scripté)* « …Va-t'en… Intrus… »
8. *(6F, après le retour en arrière)* « Quelque chose refuse qu'on passe. »

### 15.4 Exorcistes

**Possédés, avant le combat** (une ligne chacun, dans l'ordre E1 à E9) :

1. « Laisse… nous… »
2. « Tu… n'as… rien… à faire… ici… »
3. « Plus… haut… personne… ne… monte… »
4. « Froid… si… froid… »
5. « Rends… les… nous… »
6. « Qui… es… tu… ? »
7. « Silence… silence… »
8. « Ne… monte… pas… »
9. « Elle… attend… son… petit… »

**Après le combat** (ils reprennent leurs esprits) :

- E1 : « Qu'est-ce que… J'étais possédée ? Les esprits sont trop nombreux, cette fois. »
- E3 : « Ces spectres qu'on ne voit pas… Seul un Scope Sylphe permettrait de voir leur vrai
  visage. »
- E5 : « Je n'avais jamais vu les esprits aussi troublés. Quelqu'un les a blessés. »
- E9 : « Là-haut… il y a une présence plus forte que les autres. Une mère, je crois. »
- Les autres : « Merci… Je me sens plus légère. » *(variante unique)*

**Exorciste qui ne combat pas, 2F** : « On dit que Sylphe SARL a inventé un appareil qui révèle les
spectres. Un Scope… Avec ça, on saurait enfin ce qui hante cette tour. »

**Exorciste qui ne combat pas, 5F** : « Cette dalle a été bénie. Les esprits ne la franchissent
pas. Reposez-vous. »

### 15.5 Zone purifiée

1. « Une lumière douce vous enveloppe. Cette zone est purifiée et protégée. »
2. « Votre équipe est entièrement soignée. »

### 15.6 Lavanville

1. *(enfant, maison de Fuji)* « Papy Fuji est monté à la Tour… Il n'est pas redescendu. Il revient
   toujours, d'habitude. »
2. *(homme, maison de Fuji)* « M. Fuji m'a dit avoir vu des gens monter à la Tour, la nuit. Pas des
   visiteurs. Il est allé voir. Depuis… »
3. *(fille, Maison des Pokémon de M. Fuji, près d'Osselait)* « Osselait attend sa maman. On dit qu'elle s'est fait attraper en
   protégeant son petit… par des gens qui ne venaient pas prier. »
4. *(gentleman, Centre de Lavanville)* « Des hommes en noir, j'en ai vu traîner autour du Casino de
   Céladopole. Toujours là où il y a de l'argent, ces gens-là. »
5. *(panneau)* « SCOPE SYLPHE — Voir ce que l'œil ne voit pas. Une innovation Sylphe SARL. »
6. *(légende de la Tour, inchangée depuis le J18)* « TOUR POKÉMON »

### 15.7 Textes complémentaires (Q-1 du plan technique) — VALIDÉS par Kevin le 2026-10-15

> Rédigés par Claude le 2026-10-15 (T2 du plan `docs/tech/jalon-19.md`). Même ton que le Pokédex
> et les capacités existants. Osselait et Ossatueur n'ont pas d'entrée au J19 (jamais vus).

**Pokédex** (taille et poids officiels) :

| Espèce | Taille / poids | Description |
|---|---|---|
| Fantominus | 1,3 m · 0,1 kg | « Un corps de gaz autour d'un noyau sombre. Il se dissipe au moindre souffle de vent, alors il préfère les lieux clos et silencieux. » |
| Spectrum | 1,6 m · 0,1 kg | « Il traverse les murs sans bruit. On dit qu'il aime surprendre, mais il fuit dès qu'on le regarde vraiment. » |
| Caninos | 0,7 m · 19,0 kg | « Fidèle et courageux, il aboie pour protéger ceux qu'il aime. Son flair ne le trompe jamais. » |
| Léviator | 6,5 m · 235,0 kg | « Sa colère soulève les vagues. Peu de Dresseurs gardent son respect après l'avoir fait évoluer. » |
| Noeunoeuf | 0,4 m · 2,5 kg | « Six œufs qui communiquent entre eux par télépathie. Si l'un d'eux s'égare, les autres l'attendent. » |

**Capacités nouvelles** (une ligne, comme les existantes) :
- **Léchouille** : « Un coup de langue glacé. Peut paralyser la cible. »
- **Ténèbres** : « Une vision effrayante. Inflige des dégâts égaux au niveau du lanceur. »
- **Hypnose** : « Une berceuse hypnotique qui endort la cible. Peu précise. »
- **Massd'Os** : « Un coup d'os. Peut apeurer la cible. »
- **Draco-Rage** *(si absente)* : « Une onde de choc draconique. Inflige toujours 40 PV de dégâts. »

**Combat** :
- Nom affiché de l'adversaire masqué : **« SPECTRE »** (déjà validé au §15.3).
- **Forme « effrayée »** : proposition **neutre**, pour éviter l'accord masculin / féminin selon le
  Pokémon : « **{pokemon} a trop peur pour bouger !** » (**remplace §15.3.3**, validé).
- **Défaite d'une Exorciste** (fin de combat, encore possédée) : « Les esprits… se taisent… »

**Objectifs du tableau de bord** (`data/story/objectives.json`, sans flèche ni marqueur) :
- `climb_tower` : « monter dans la Tour Pokémon. » — si `tower_stairs_open`, sauf `tower_ghost_met`.
- `see_the_ghosts` : « trouver un moyen de voir les spectres. » — si `tower_ghost_met`.
  (Le J20 le remplace quand le Scope est obtenu.)

**Nom de zone des étages** : aucun nouveau [D]. Les étages gardent la légende « TOUR POKÉMON ».

## 16. Cas limites (à couvrir au plan technique)

1. **Le joueur sauvegarde au 6F, puis le J20 lui donne le Scope** : les rencontres sauvages sont
   identifiées sans migration ; le SPECTRE du 6F reste un blocage jusqu'au J21.
2. **Toute l'équipe est KO pendant un combat contre un Exorciste** : réveil au Centre de Lavanville.
   Les Exorcistes battus le restent.
3. **SPECTRE et statuts** : un Pokémon endormi ou gelé affiche son statut, pas la peur. L'empoisonné
   perd ses PV de poison à chaque tour **[D]**. Le joueur peut toujours
   fuir.
4. **Le joueur n'a plus de Ball** : rien ne change, le refus vient avant le lancer.
5. **Corde Sortie dans la Tour** : retour devant la porte. Le rival non battu attend toujours.
6. **Le compagnon** marche dans la Tour ; il ne gêne ni les cases de déclenchement, ni le retour en
   arrière (le compagnon suit le joueur repoussé).
7. **Le joueur est repoussé du 6F pendant que le compagnon est sur la case d'arrivée** : c'est
   l'échange de places habituel.
8. **Zone purifiée** : en entrer et en sortir en boucle soigne à chaque fois, sans effet de bord sur
   les rencontres (case exclue du terrain `floor`).
9. **Le rival vaincu** n'est plus jamais déclenché. Le Grand moment est écrit une seule fois.
10. **Départ de débogage** au 6F sans le rival battu : le blocage fonctionne quand même. Les
    drapeaux sont indépendants.
11. **Pokédex** : aucun combat SPECTRE n'ajoute d'espèce. Test dédié.
12. **Aucun drapeau du J21** (Ossatueur, Fuji, Flûte) n'est posé par une donnée du J19. Test dédié, comme celui du J20 sur
    Lavanville.

## 17. Valeurs par défaut (règle 4)

- **Étages** : 20 × 18 cases.
- **Corde Sortie** : ramène devant la porte de la Tour.
- **Silhouette SPECTRE** : une seule planche ; niveau masqué « N?? ».
- **Peur du SPECTRE** :
  - la confusion ne fait pas se blesser ;
  - le poison fait des dégâts pendant le combat SPECTRE.
- **Rival** : silence de 2 s avant la dernière réplique.
- **Exorcistes** : prénoms ; 2 à 3 cases de vue ; IA `random`.
- **Objets** : Super Potion si elle existe, sinon Potion.
- **Lumière** : profil `tower` ; « Réduire les animations » coupe brume et battement.
- **Compagnon** : sans réaction propre.
- **Ténèbres** : sans effet sur un type Normal (règle actuelle).

## Décisions verrouillées

- Les 7 décisions de la V2 et les arbitrages K-1 à K-20.
- **Le J19 ne donne ni le Scope Sylphe, ni la Poké Flûte**, et ne montre ni Ossatueur, ni Fuji, ni la
  Team Rocket.
- **Mode spectre = possession de `silph_scope`**, jamais un drapeau.
- **Exorciste** est le nom de la classe partout.
- Le rival n° 5 n'a **pas** de Rattatac, et personne n'en parle.
