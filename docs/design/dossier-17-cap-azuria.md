# Dossier 17 — Le mystère du Cap d'Azuria (jalon 14)

> V0.1, 2026-10-11. Consolidation de la V2 de Kevin (`passes/j14-v2-chatgpt.md`) et de la passe
> d'alignement (`passes/j14-v2-alignement.md`). **Kevin a retenu toutes les recommandations
> E-1 à E-15 et V-1 à V-3** (2026-10-11). Les petites valeurs laissées ouvertes par ces
> recommandations ont reçu un **défaut (règle 4)**, marqué **[D]**.
> **Textes : §15, à valider en un seul lot avant le code.**
>
> Origine des règles : **RB** = Rouge/Bleu, **G+** = génération plus récente, **K26** = invention
> de Kanto 2026. Code après la clôture du J13 ; conception, grilles et art en parallèle.

## 1. Décisions verrouillées

| # | Décision | Source |
|---|---|---|
| 1 | Léo est transformé en **Mélofée** | V2 |
| 2 | Machine : **plusieurs interactions courtes**, guidées, sans échec | V2, E-12 |
| 3 | Léo remet le **Passe Bateau** et un **Super Bonbon** | V2, V-1, E-6 |
| 4 | Route 25 : **6 Dresseurs**, dont 2 inévitables | V2, grille |
| 5 | Rocket d'Azuria : **courte poursuite scriptée**, puis combat rejouable | V2, E-13 |
| 6 | **CT28 Tunnel** remise au J14, **utilisable en combat** ; usage hors combat reporté au jalon des ex-CS | V2, E-7 à E-9 |
| 7 | Sortie sud d'Azuria : **barrage de police** levé après la victoire contre le Rocket | V2, E-10 |
| 8 | Compagnon : suit sur la Route 25, rentre dans sa Ball chez Léo (règle des intérieurs du J11) | V2 |
| 9 | Les deux histoires se font **dans n'importe quel ordre** | V-3 |
| 10 | L'enfant de Bourg Palette prénommé Léo est **renommé Nils** [D] | E-1 |
| 11 | Léo **n'a pas inventé le stockage** (système de recherche de Chen) | E-2 |
| 12 | **Abra** sur la Route 25, rare, avec **fuite par Téléport** | E-3 |
| 13 | **Évolutions par échange** : un objet unique, le **Cordon d'échange** [D] | E-3 |
| 14 | Espèces nouvelles : **Abra, Kadabra, Machoc** | E-5 |
| 15 | Accès à la Route 25 : rival battu et recruteur passé, sans verrou de plus | E-11 |
| 16 | **Un Grand moment** à la fin de la transformation de Léo | E-14 |
| 17 | **Aucune nouvelle version de sauvegarde** | passe §2.12 |

## 2. Périmètre

**Dans le J14** :

- Route 25 et Cap d'Azuria (une carte) ;
- maison de Léo (un intérieur) ;
- scène de Léo-Mélofée et de la machine ;
- récompenses de Léo ;
- jardin de la maison cambriolée et poursuite du Rocket (sur la carte d'Azuria du J13) ;
- CT28 Tunnel et le mécanisme « deux tours » ;
- barrage sud levé ;
- raccord « ROUTE 5 — À venir » ;
- Abra, Kadabra, Machoc ;
- fuite par Téléport ;
- Super Bonbon ;
- règle du Cordon d'échange ;
- renommage de Nils.

**Hors du J14** :

- Route 5 et au-delà ;
- S.S. Anne ;
- Route 9 (Coupe) ;
- Tunnel hors combat ;
- source du Cordon d'échange ;
- eau jouable ;
- maison d'échange ;
- vélo.

## 3. Géographie

Références validées par Kevin (2026-10-11) :

- `reference/route-25-vue-generale-v1.png` (DA) ;
- `reference/route-25-plan-v1.png` (géométrie) ;
- `reference/maison-leo-v1.png` (intérieur ; la marche d'entrée de l'image n'existe pas en jeu).

**Les grilles font foi** :

- `tools/plans/route_25.txt` (80 × 28), contrôlée par `tools/art/plan_check_route_25.py` ;
- `tools/plans/bill_house.txt` (16 × 11).

### 3.1 Route 25 et Cap d'Azuria (`route_25`)

D'ouest en est :

1. **la sortie de la Route 24** (prairie, hautes herbes H1 évitables, goulet de D1) ;
2. **la corniche** (chemin côtier de 3 cases, terrasse nord avec H2, D3 et la CT19, rebord de
   retour, crique de sable avec D4, goulet de D2, H3 obligatoire) ;
3. **le Cap** (H4 et D5, maison de Léo entre deux massifs de fleurs, poche du sud-est avec D6,
   objet caché).

Chiffres de la grille :

- 73 pas jusqu'à la porte de Léo, environ 5 min avec les deux combats inévitables ;
- 4 cases de hautes herbes obligatoires.

Pas de Surf ni de pêche : la mer est un obstacle.

**Raccord ouest** : `(0, 13..15)` ↔ bord est de la Route 24 nord (J13).

- Le J13 aligne ses trois rangées sur celles-ci.
- Son raccord provisoire « ROUTE 25 — À venir » devient le warp `route_24` / `from_route_25`.

### 3.2 Maison de Léo (`bill_house`)

Une pièce de 16 × 11 cases :

- cabine A (départ) au nord-ouest, cabine B (arrivée) au nord-est ;
- écran de diagnostic, console au centre, module ;
- bibliothèques, bureau encombré, lit, plante.

Sortie au sud vers `route_25` / `from_bill_house`. Le compagnon rentre dans sa Ball en entrant.

### 3.3 Azuria (carte du J13) : ce que le J14 y ajoute

Relais à demander à la session du J13 (aucune modification par le J14 de la grille d'Azuria avant
son dossier 16) :

- **Jardin de la maison cambriolée** :
  - accessible depuis la rue par le côté de la maison (clôture arrachée, J13 C-8) ;
  - au fond, une **impasse** d'au moins 6 cases de long, fermée à l'est par la végétation (la
    Route 9 reste fermée jusqu'à Coupe) ;
  - point d'arrêt du Rocket au fond de l'impasse.
- **Sortie sud** : 2 ou 3 cases de large. Le policier du barrage occupe une case et un plot ou une
  barrière basse la fin ; il ne laisse aucun passage. Le bord sud mène au raccord
  « ROUTE 5 — À venir » (développement), avec l'identifiant `route_5` et l'arrivée
  `from_cerulean` réservés pour le J15.
- **Maison cambriolée** : fermée tant que le Rocket n'est pas battu (J13), ouverte ensuite.

## 4. Léo et sa machine

### 4.1 Personnage

Léo est passionné, curieux, bavard et un peu excentrique. Il travaille sur la **téléportation de
la matière**. Il a « aidé Chen sur les transferts », sans plus : le stockage reste le système de
recherche de Chen (E-2).

- **Transformé** : il garde la planche d'exploration du Mélofée du J12, sans accessoire. Il parle,
  ne combat pas, n'a ni cri ni capture. Nom affiché : « Mélofée » à la première réplique, puis
  « Léo » une fois présenté (E-4).
- **Humain** : nouveau personnage peint (série d'art du J14). Il porte une tenue de bricoleur et
  ses manches sont retroussées [D].

### 4.2 Déroulé (E-12)

| Étape | Déclencheur | Effet | Drapeau levé |
|---|---|---|---|
| 0 | Entrée dans la maison | Mélofée se tourne vers le joueur, bulle « ! » | — |
| 1 | PARLER à Mélofée | Présentation, problème, consigne : l'écran | `bill_met` |
| 2 | EXAMINER l'écran | Texte du diagnostic ; Léo : consigne suivante, le module | `bill_screen_checked` |
| 3 | EXAMINER le module | Texte du module ; Léo entre dans la cabine A (marche, disparaît) | `bill_module_checked`, `bill_in_cabin` |
| 4 | EXAMINER la console | Effet de la machine (§4.3) ; Léo humain sort de la cabine B ; remerciements, récompenses, Grand moment | `bill_restored`, `got_ss_ticket`, `got_bill_rare_candy` |

- **Repère** : l'objet attendu porte une **lueur douce** [D] ; les autres objets répondent par une
  phrase d'aide (§15, n° 9 à 11).
- **Sortie en cours de route** : l'avancement est gardé. À l'étape 3, Léo est **déjà dans la
  cabine** au retour ; la console attend.
- **Fermeture pendant l'étape 4** : les drapeaux de l'étape 4 sont levés **ensemble à la fin** ;
  une scène interrompue est rejouée en entier au retour (la console reste l'objet attendu).
- Les récompenses sont données **une seule fois** (`got_ss_ticket`, `got_bill_rare_candy`).

### 4.3 Effet de la machine

C'est une **petite étape de scène nouvelle**, `flash`, réutilisable [D] :

- éclair blanc-bleu plein écran d'environ 0,4 s, deux fois de suite ;
- vibration légère ;
- son de machine (provisoire).

« Réduire les animations » remplace l'éclair par un fondu doux. La séquence complète : le module
s'allume, flash, la cabine A s'éteint, flash, la porte de la cabine B s'ouvre, Léo apparaît.

## 5. Récompenses

| Objet | Données | Règles |
|---|---|---|
| **Passe Bateau** | `ss_ticket`, objet clé (`key`), sans prix | Invendable, jamais perdu, aucun bouton UTILISER au J14. Servira au S.S. Anne. |
| **Super Bonbon** | `rare_candy`, AVENTURE (`field`), prix 0 = jamais en vente au J14 [D] | Sac → AVENTURE → Super Bonbon → choisir un Pokémon : **+1 niveau**. Les stats sont recalculées et les PV montent de la différence. Les capacités du nouveau niveau s'apprennent (écran « oublier une capacité » des CT, 11B), puis l'évolution est vérifiée (évolution hors combat de la Pierre Lune, J12). Niveau 100 : « Sans effet ». Pas en combat (RB). |
| **CT28 Tunnel** | `tm28`, catégorie CT (11B) | Lâchée par le Rocket battu, une seule fois (`got_tm28`). |

## 6. Le cambriolage et la poursuite

### 6.1 Avant le J14 (rappel du J13)

- Policier devant la maison cambriolée.
- Maison fermée (« L'enquête est en cours. »).
- Indices matériels : on a vu « un homme en noir partir par l'arrière ».

### 6.2 Poursuite (une seule fois, `cerulean_rocket_spotted`)

1. Le joueur entre dans le jardin. **Bulle « ! »** au-dessus du Rocket, qui fouille près du trou
   du mur.
2. Réplique de repérage (§15, n° 30).
3. Le Rocket part en **marche scriptée rapide** de quelques cases vers le fond de l'impasse et s'y
   arrête, tourné vers le joueur.
4. Le joueur reprend la main et le rejoint **à son rythme**. Il n'y a ni chronomètre ni course.
5. La vue du Rocket (toute la largeur de l'impasse) déclenche la réplique d'avant combat, puis le
   combat.

### 6.3 Issue

- **Défaite** : réveil au dernier Centre (règle existante, sans perte d'argent). Le Rocket attend
  **à son point d'arrêt**. Une réplique de reprise courte, sans moquerie (§15, n° 32), puis le
  combat. Modèle de Pierre.
- **Victoire** :
  - réplique (§15, n° 33), puis la CT28 lâchée (`give` → `got_tm28`) ;
  - le Rocket part par le trou du mur (`despawn`), drapeau `cerulean_rocket_beaten` ;
  - pas de Grand moment (ni rival ni Champion).
- **Après la victoire** :
  - le policier de la maison part ;
  - la maison s'ouvre, et la victime remercie (§15, n° 36) ;
  - le **policier du barrage sud part** et la sortie sud est libre ;
  - deux habitants commentent (§15, n° 38 et 39).

Le Rocket **ne nomme personne** et ne révèle aucun chef : au plus, « Les ordres viennent d'en
haut. »

## 7. Combat : Tunnel et le mécanisme « deux tours »

### 7.1 Tunnel (`dig`)

| Champ | Valeur |
|---|---|
| Type | Sol |
| Puissance / précision / PP | **100 / 100 / 10** (RB) |
| Tour 1 | « {pokemon} creuse un trou ! » ; le sprite disparaît (sous terre) |
| Tour 2 | Frappe ; action verrouillée (le joueur ne choisit rien) |
| Sous terre | **Toute attaque adverse échoue** : « {pokemon} évite l'attaque ! ». Poison, brûlure et Vampigraine s'appliquent en fin de tour. |
| Immunité | Les Pokémon Vol ne sont pas affectés (déjà dans `types.json`) |
| Séisme | Ne double pas (G+ écarté) |

### 7.2 Interruptions (E-8)

- **Tour 1** : sommeil, gel, paralysie totale, confusion qui frappe et apeurement empêchent de
  creuser. Le Pokémon reste en surface.
- **Tour 2** : endormi ou gelé entre-temps, il **remonte sans frapper** (« {pokemon} remonte à la
  surface. »).
- **Changement de Pokémon** : impossible pendant le tour verrouillé, comme pour Patience.
- **Capture** : une Ball sur un sauvage sous terre échoue (« Impossible de viser ! »). Aucun
  sauvage du J14 ne connaît Tunnel.
- **Fin du combat** pendant le tour sous terre (fuite, K.O. adverse par poison) : rien n'est gardé.
- **IA** : `smart` peut choisir Tunnel. **Aucun adversaire du J14 ne connaît Tunnel.**

### 7.3 Mécanisme général

On écrit **« charge puis frappe »** une fois, avec deux paramètres :

- le message du tour de charge ;
- l'invulnérabilité ou non pendant la charge.

Il servira ensuite à Lance-Soleil et Coud'Krâne (sans invulnérabilité), puis à Vol (avec). Le
verrou d'action est celui de Patience (J11 §6.3). L'état est volatil : il n'est jamais sauvegardé.

### 7.4 Tunnel hors combat (E-9)

**Reporté** au jalon des ex-CS (Coupe, S.S. Anne), qui concevra une seule fois le menu des
capacités de terrain (dossier 06 §11). La règle est déjà fixée, c'est celle de la Corde Sortie
(J12) :

- grottes de `caves.json` seulement ;
- ni soin ni point de repos touchés ;
- refus « Impossible de l'utiliser ici. ».

## 8. Abra, Téléport et le Cordon d'échange

### 8.1 Fuite par Téléport (E-3)

- Un Pokémon **sauvage** qui lance Téléport met fin au combat : « {pokemon} s'est téléporté ! »,
  sans XP et sans capture. L'IA sauvage d'Abra lance Téléport **dès son premier tour** (RB).
- Le joueur agit avant lui s'il est plus rapide. Une Ball ou un objet passe toujours avant l'attaque
  adverse (règle existante). On a donc **une chance** : capturer d'entrée, ou endormir ou paralyser
  pour l'empêcher de fuir.
- Téléport **en combat de Dresseur** : « Mais rien ne se passe ! » (RB).
- Téléport lancé par le joueur contre un sauvage : le joueur fuit, comme avec FUITE.

### 8.2 Évolutions par échange (E-3, option a)

- Kadabra, Machopeur, Gravalanche et Spectrum évoluent avec le **Cordon d'échange** [D]
  (`trade_cord`, AVENTURE, prix 0), utilisé depuis le Sac comme la Pierre Lune. Il est consommé.
- La donnée existante `"method": "trade"` signifie désormais « avec le Cordon d'échange ». Le format
  des espèces ne change pas.
- **Aucune source au J14.** Le premier Cordon sera placé dans un jalon ultérieur. D'ici là, Kadabra
  reste Kadabra : le Pokédex et la fiche n'annoncent pas d'évolution par niveau.
- Le code de la règle vient avec la première source. Le J14 ne le code pas.

## 9. Dresseurs de la Route 25

Classes et équipes de RB (`pret/pokered`), réduites de 9 à 6. Récompense = base de la classe
× niveau du dernier Pokémon (RB) ; bases : Gamin 15, Fillette 15, Jeune Dresseur 20, Montagnard
35. IA `random` (comme la Forêt et la Route 3). Niveaux RB, **à recaler au plan avec l'outil de
simulation du J12**.

| Rôle | Identifiant | Nom [D] | Équipe | ₽ | Position |
|---|---|---|---|---|---|
| D1 | `route_25_youngster_malo` | Gamin Malo | Rattata 15, Piafabec 15 | 225 | (18, 10) ↓, vue 5 — inévitable |
| D2 | `route_25_hiker_gaston` | Montagnard Gaston | **Machoc** 15, Racaillou 15 | 525 | (45, 10) ↓, vue 5 — inévitable |
| D3 | `route_25_lass_clara` | Fillette Clara | Nidoran ♂ 15, Nidoran ♀ 15 | 225 | (31, 6) ←, vue 3 — terrasse |
| D4 | `route_25_hiker_bernard` | Montagnard Bernard | Onix 17 | 595 | (38, 19) ↑, vue 2 — crique |
| D5 | `route_25_jr_trainer_adam` | Jeune Dresseur Adam | Rattata 14, Abo 14 | 280 | (63, 10) ↑, vue 3 — garde H4 |
| D6 | `route_25_youngster_yanis` | Gamin Yanis | Abo 14, Sabelette 14 | 210 | (73, 17) ←, vue 4 — poche du sud-est |

Écartés : le Gamin au Ramoloss, le Montagnard aux quatre Pokémon, la Fillette aux Mystherbe
(E-5). Le peintre de la vue a dessiné un Scout en D5 : c'est la DA, la grille et ce tableau font
foi (Jeune Dresseur).

### 9.1 Rocket d'Azuria

`cerulean_rocket` : **Sbire Rocket** (modèle peint du J12), équipe **Machoc 17, Nosferapti 17**
[D], 510 ₽ (base 30). Écart avec RB, qui lui donne un Soporifik : on économise une espèce.
IA `smart`.

### 9.2 Capacités (à vérifier au plan)

Les capacités suivent les tables de niveau des espèces. Machoc 15 (RB) : Poing Karaté, Groz'Yeux,
Puissance. Toute capacité absente du moteur après le J11 est signalée au plan, jamais inventée.

## 10. Rencontres de la Route 25

Taux **15** (RB, plus bas que la Route 24). Table [D] fidèle à RB et limitée aux espèces qui
existeront :

| Espèce | Niveaux | Part |
|---|---|---|
| Roucool | 13 | 20 % |
| Mystherbe / Chétiflor (si D-8 du J13 les retient ; sinon Roucool et Chenipan à la place) | 12–14 | 35 % |
| Chenipan | 8 | 10 % |
| Aspicot | 8 | 10 % |
| Chrysacier | 7 | 5 % |
| Coconfort | 9 | 5 % |
| **Abra** | 10–12 | 15 % |

Les quatre zones (H1 à H4) partagent la table.

## 11. Objets de la Route 25

| Rôle | Objet | Position |
|---|---|---|
| O1 | **CT19 Frappe Atlas** (RB) si 11B est fusionné | (33, 5), fond de la terrasse |
| O2 | Potion | (35, 19), fond de la crique |
| O3 | Poké Ball | (77, 21), pointe du sud-est |
| O4 | Potion, **cachée** (indice : coquillage) | rocher (64, 20), examiné depuis (64, 19) |

Les deux objets cachés de RB (Huile, Élixir) rendent des PP, ce que Kanto 2026 ne fait pas par
objet : un seul objet caché, existant.

## 12. Espèces nouvelles

- **Abra** : sauvage, face et dos provisoire. Seule capacité de départ : Téléport.
- **Kadabra** : atteignable (Abra au niveau 16). Face et dos provisoire ; évolution par le Cordon.
- **Machoc** : Dresseur seulement. Face, sans dos ni planche d'exploration.

Pokédex : §15, n° 50 à 55.

## 13. Drapeaux

| Drapeau | Sens |
|---|---|
| `bill_met` | Léo-Mélofée a parlé au joueur |
| `bill_screen_checked` · `bill_module_checked` · `bill_in_cabin` | Étapes de la machine |
| `bill_restored` | Léo est humain (variante des PNJ de la maison) |
| `got_ss_ticket` · `got_bill_rare_candy` | Récompenses de Léo |
| `cerulean_rocket_spotted` | Poursuite jouée |
| `cerulean_rocket_beaten` | Rocket battu : maison ouverte, policiers partis, sortie sud libre |
| `got_tm28` | CT28 reçue |
| `beaten_route_25_*` · `got_route_25_item_*` | Dresseurs et objets (modèles existants) |

Grand moment : `bill_restored` (« Léo a retrouvé forme humaine »), écrit une fois.

## 14. Sauvegarde et cas limites

Aucun format nouveau : tout tient dans `flags`, `bag` et `moments`. L'état « sous terre » n'est
jamais sauvegardé.

| Cas | Comportement |
|---|---|
| Sortie de la maison au milieu de la machine | Avancement gardé ; au retour, Léo est où l'étape le place |
| Fermeture pendant l'effet de la machine | Scène rejouée en entier (drapeaux de l'étape 4 levés ensemble à la fin) |
| Défaite contre le Rocket | Réveil au Centre ; Rocket au point d'arrêt ; reprise courte |
| Rocket battu avant la visite à Léo | Possible ; la sortie sud s'ouvre ; Léo reste à aider |
| Sauvegarde pendant la marche du Rocket | L'autosave n'a lieu qu'aux changements de carte : au retour, le Rocket est au point d'arrêt (`cerulean_rocket_spotted` levé au début de la scène) |
| Tunnel et statuts, Vol, capture, changement | §7 |
| Kadabra sans Cordon | Reste Kadabra, sans message trompeur |
| Partie sauvegardée sur le raccord « Route 25 — À venir » du J13 | Retombe sur `from_route_24` de la vraie Route 25 (cases praticables) |
| Super Bonbon sur un Pokémon niveau 100 | « Sans effet », l'objet n'est pas consommé |
| Joueur au sud avant le J15 | Raccord « ROUTE 5 — À venir » (bord bloqué en release) |

## 15. Textes à valider (un seul lot)

> Ton des dossiers précédents : phrases courtes, aucune ironie envers le joueur. {joueur} = prénom
> du joueur. Numérotés pour les retours (« 12 : … »).

### Léo-Mélofée (maison de Léo)

1. *(Mélofée, à l'entrée du joueur)* « Ah ! Enfin quelqu'un ! Non, non, ne sors pas ta Poké Ball ! »
2. *(Mélofée)* « Je ne suis pas un Pokémon. Enfin… pas d'habitude. Je m'appelle Léo. »
3. *(Léo)* « Je travaille sur la téléportation de la matière. Une cabine, une autre cabine, et entre les deux… plus de distance. »
4. *(Léo)* « Ce matin, un Mélofée est entré dans la cabine en même temps que moi. Et voilà le résultat. »
5. *(Léo)* « La machine peut nous séparer. Mais avec ces petites pattes, je n'atteins plus rien. Tu veux bien m'aider ? »
6. *(Léo)* « Commence par l'écran de diagnostic, là, au mur. Il me dira si les réglages ont tenu. »
7. *(Léo, après l'écran)* « Parfait. Maintenant, le module, à droite de la console. Vérifie que tout est bien branché. »
8. *(Léo, après le module)* « Bon. J'entre dans la cabine. Quand je te fais signe, appuie sur le grand bouton de la console. Et… ne te trompe pas de bouton. »
9. *(aide, console avant le module)* « Léo t'a demandé de vérifier autre chose d'abord. »
10. *(aide, module avant l'écran)* « Des câbles partout. Mieux vaut commencer par l'écran. »
11. *(Léo, si l'on revient alors qu'il est dans la cabine)* « Je suis prêt ! Le grand bouton, sur la console ! »
12. *(Léo, si l'on parle à Mélofée pendant une étape)* « Prends ton temps. Je ne vais nulle part. Littéralement. »

### Machine (EXAMINER)

13. *(écran)* « Des courbes et des voyants. Une ligne clignote : SÉPARATION PRÊTE. »
14. *(module)* « Tous les câbles sont en place. Le boîtier ronronne doucement. »
15. *(console, au bon moment)* « Un grand bouton rouge. Tu appuies dessus. »
16. *(console, avant)* « Beaucoup de boutons. Mieux vaut attendre les consignes de Léo. »
17. *(écran, après le retour de Léo)* « SÉPARATION RÉUSSIE. Le Mélofée est retourné dehors. »

### Léo humain

18. « Ha ! Deux bras, deux jambes, et à la bonne taille ! Merci, {joueur} ! »
19. « Le Mélofée va bien, il est reparti vers les falaises. Il était sûrement plus pressé que moi. »
20. « Tiens, j'ai reçu ça pour la soirée du S.S. Anne, mais je n'aime pas les bateaux. Prends-le. »
21. *(légende de remise)* « {joueur} reçoit le PASSE BATEAU ! »
22. « Et ça aussi. Un Super Bonbon. Il aide un Pokémon à grandir d'un coup. »
23. *(légende de remise)* « {joueur} reçoit un SUPER BONBON ! »
24. « Le S.S. Anne fait escale à Carmin-sur-Mer, au sud. Il paraît que les Dresseurs du monde entier y montent. »
25. *(Léo, ensuite)* « Je reprends mes réglages. Promis, plus aucun Pokémon dans la cabine. »
26. *(Léo, ensuite, si le Rocket n'est pas battu)* « Il paraît qu'il y a eu un cambriolage à Azuria. Les gens deviennent nerveux. »
27. *(Léo, ensuite, une fois sur trois)* « Chen m'a demandé conseil pour ses transferts de Pokémon, une fois. Il ne m'a jamais rendu mon tournevis. »

### Rocket d'Azuria

28. *(policier devant la maison, avant)* « L'enquête est en cours. Personne n'entre. » *(J13, inchangé)*
29. *(narration, trou du mur)* « Un trou dans le mur. Quelqu'un est passé par ici. »
30. *(Rocket, repéré)* « Hein ?! Un gamin ? Pas question que tu me suives ! »
31. *(Rocket, au point d'arrêt)* « Bon. Tu l'auras voulu. Je ne vais pas me laisser coincer par un môme ! »
32. *(Rocket, reprise après une défaite du joueur)* « Encore toi ? Tu ne lâches jamais, hein. »
33. *(Rocket, battu)* « Pfff… Je ne suis pas payé pour ça. Tiens, reprends ce truc, il ne vaut rien pour moi. »
34. *(légende)* « {joueur} reçoit la CT28 ! »
35. *(Rocket, en partant)* « Les ordres viennent d'en haut. Moi, je fais ce qu'on me dit. »
36. *(victime, maison ouverte)* « Il avait pris ma CT28 ! Garde-la, tu l'as bien mérité. Et merci. »
37. *(victime, ensuite)* « J'ai fait réparer le mur. Plus personne ne passera par le jardin. »

### Azuria après la victoire

38. *(habitant)* « Le voleur s'est enfui par le jardin, paraît-il. On n'a plus revu personne en noir. »
39. *(habitante)* « La police est partie. On peut de nouveau aller vers le sud ! »
40. *(policier du barrage, avant)* « On recherche un voleur. Personne ne sort par le sud tant qu'il court. »
41. *(policier du barrage, au départ)* « Le voleur a filé ? Alors ma garde est finie. La route du sud est libre. »

### Route 25

42. *(panneau ouest)* « ROUTE 25 — Azuria ← → Cap d'Azuria »
43. *(panneau du Cap)* « CAP D'AZURIA — Maison de Léo. Sonnez fort. »
44. *(promeneur)* « Le Cap, là-bas. Un drôle de type y vit. Des fois, sa maison fait des étincelles. »
45. *(homme âgé, face à la mer)* « La mer est calme ce soir. Léo vit tout au bout. Il ne sort pas beaucoup. »

**Dresseurs** (avant · défaite · après) :

46. *(Gamin Malo)* « La route est à moi ! » · « Déjà fini ?! » · « Je m'entraîne ici tous les jours. Pas assez, faut croire. »
47. *(Montagnard Gaston)* « Mes Pokémon ont des muscles de montagne ! » · « Ho ho ! Belle poigne ! » · « Je redescends des falaises. Le Cap est juste après les hautes herbes. »
48. *(Fillette Clara)* « Tu as vu mes Nidoran ? Ils sont mignons, mais ils piquent ! » · « Aïe… » · « Ils boudent un peu. Ça va leur passer. »
49. *(Montagnard Bernard)* « Je cherche des pierres sur la plage. Et toi, tu cherches la bagarre ? » · « Solide comme un roc, ton équipe ! » · « Onix adore le sable. Il s'y roule pendant des heures. »
50. *(Jeune Dresseur Adam)* « Ces hautes herbes, c'est mon terrain d'entraînement ! » · « Bien joué. » · « Il y a des Abra ici. Ils disparaissent dès qu'on les approche. »
51. *(Gamin Yanis)* « Tu ne passeras pas sans combattre ! Enfin… si, mais combats quand même ! » · « Oh non ! » · « J'aime bien regarder la mer depuis ici. »

### Combat

52. « {pokemon} creuse un trou ! »
53. « {pokemon} évite l'attaque ! »
54. « {pokemon} remonte à la surface. »
55. « Impossible de viser ! »
56. « {pokemon} s'est téléporté ! »
57. « Mais rien ne se passe ! » *(existant si déjà présent)*

### Objets (descriptions)

58. Passe Bateau : « Une invitation pour le S.S. Anne, le paquebot qui fait escale à Carmin-sur-Mer. »
59. Super Bonbon : « Un bonbon plein d'énergie. Fait monter un Pokémon d'un niveau. »
60. CT28 Tunnel : « Le Pokémon creuse au premier tour et frappe au second. Sous terre, il évite les attaques. »
61. Cordon d'échange : « Un cordon tressé, chargé d'une énergie étrange. Fait évoluer certains Pokémon. » *(sans source au J14)*
62. Résultat du Super Bonbon : « {pokemon} monte au niveau {niveau} ! » *(existant si déjà présent)*

### Pokédex (descriptions et notes)

| # | Espèce | Taille / poids | Description | Note |
|---|---|---|---|---|
| 63 | Abra | 0,9 m / 19,5 kg | « Il dort presque tout le temps. Au moindre danger, il disparaît avant même d'ouvrir les yeux. » | « Vu sur la Route 25. Il s'est évanoui dans l'air dès que je me suis approché. » |
| 64 | Kadabra | 1,3 m / 56,5 kg | « Sa cuillère amplifie ses pouvoirs. Les appareils électroniques se dérèglent quand il est proche. » | « Évolué d'Abra. On dit qu'il en devient un autre encore, par un lien très particulier. » |
| 65 | Machoc | 0,8 m / 19,5 kg | « Il s'entraîne sans relâche. Sa force dépasse de loin ce que laisse croire sa petite taille. » | « Vu dans l'équipe d'un Montagnard. Il soulève des rochers comme des cailloux. » |

### Tableau de bord (objectifs)

66. « Rejoindre le Cap d'Azuria. » *(après le Pont Pépite, tant que `bill_restored` n'est pas levé)*
67. « Aider Léo. » *(après `bill_met`)*
68. « Le S.S. Anne fait escale à Carmin-sur-Mer. » *(après `got_ss_ticket`)*

Le cambriolage n'a **aucun objectif** (J13 : pas de marqueur).

### Grand moment

69. « Léo a retrouvé forme humaine » *(Cap d'Azuria)*

### Nils (ex-Léo, Bourg Palette)

70. *(locuteur seul)* « Nils » remplace « Léo » ; répliques inchangées.

## 16. Dépendances

- **J11** : CT et Sac CT (11B), statuts, verrou de Patience, Frappe Atlas, écran « oublier une
  capacité ».
- **J12** : planche de Mélofée, Sbire Rocket peint, Nosferapti, étape « choix qui lance une
  scène », évolution hors combat (Pierre Lune), objets cachés, outil de simulation.
- **J13** : Azuria, jardin et impasse (§3.3), policier, sortie sud, Route 24 nord et son raccord
  est, D-8 (Mystherbe / Chétiflor).

## 17. Sous-jalons et validation S24 (E-15)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **14.0** | Art (Léo humain, coque et meubles de la maison, sol et rivage côtiers, maison du Cap, mer), données (espèces, Tunnel, Passe Bateau, Super Bonbon, Dresseurs, rencontres), renommage de Nils | captures Mac |
| **14A** | Route 25 et Cap, maison de Léo, scène complète, récompenses, Super Bonbon | S24 |
| **14B** | Mécanisme « deux tours » et Tunnel en combat, fuite par Téléport | **S24 seul** (système risqué) |
| **14C** | Jardin, poursuite, Rocket, CT28, barrage levé, raccord Route 5, clôture | S24 |

## 18. Propagation

- `dossier-02-prologue.md` §4 : l'enfant s'appelle **Nils** (fait dans ce commit).
- `roadmap.md` : rien sans l'accord de Kevin. À proposer à la clôture : rival, Léo, S.S. Anne.
- Session du J13 : relais §3.1 (raccord est de la Route 24 nord) et §3.3 (jardin, impasse, sortie
  sud).
