# Dossier 23 — Route 8, souterrain, Route 7, Céladopole, Erika et le repaire Rocket (jalon 20)

> **VERROUILLÉ — validé par Kevin le 2026-10-14** (arbitrages H-1 à H-14, lot de textes §20, valeurs par défaut §21).

> **Consolidé par Claude le 2026-10-14**, à partir de trois sources :
> - la V2 de Kevin avec ChatGPT (`passes/j20-v2-chatgpt.md` : 7 décisions verrouillées) ;
> - la passe d'alignement de Claude (`passes/j20-v2-alignement.md`, H-1 à H-14) ;
> - le retour de Kevin le même jour : **toutes les recommandations retenues** (H-1 à H-14).
>
> Lot de textes du §20 et valeurs par défaut du §21 **validés le 2026-10-14**. Ensuite viennent les grilles `tools/plans/` et les vues générales peintes, puis le plan
> `docs/tech/jalon-20.md`. **Code après la clôture du J19** (C-7 : un seul jalon à la fois dans le
> moteur de combat et dans la sauvegarde).
>
> Faits Rouge/Bleu : CSV PokeAPI (groupe `red-blue`) et désassemblage pret/pokered (`af51989`),
> détaillés dans la passe (§2). Marqueurs : **[V]** décision de la V2 · **[H-n]** arbitrage retenu ·
> **[D]** valeur par défaut de Claude (règle 4, à valider au §21) · **RB** / **RFVF** / **K26**.
>
> Le dessin ASCII donne la logique, **pas une grille de production**. Les images de la V2 ne vont
> pas dans le dépôt.

## Décisions verrouillées

| # | Décision | Source |
|---|---|---|
| 1 | Périmètre : Route 8, souterrain, Route 7, Céladopole | V |
| 2 | Ville complète : grand magasin et bâtiments principaux, **≈ 70 × 46 cases** | V, H-3 |
| 3 | Erika affrontable, Badge Prisme et CT21 dès le J20 ; badge **sans effet** | V, passe §3.5 |
| 4 | Repaire Rocket complet, Giovanni, Scope Sylphe | V |
| 5 | Dalles tournantes et ascenseur fidèles à RB, avec une ergonomie mobile | V |
| 6 | Casino narratif : machines en décor, **aucun jeton** ; Coin à lots et Boîte Jetons retirés ; Porygon confié au dossier de Safrania | V, H-6, H-12 |
| 7 | Fin au Scope Sylphe ; la résolution de la Tour relève du J21 | V |
| 8 | Deux sous-jalons validés sur S24 : **20-I** (Routes, ville, Arène) et **20-II** (Casino, repaire, Giovanni) | H-2 |
| 9 | Sortie ouest (Route 16) fermée par un obstacle naturel, sans promesse | H-4 |
| 10 | Safrania : règle d'accès décidée avec son jalon ; au J20, ni Thé, ni gardes assoiffés | H-5 |
| 11 | CT : seulement celles dont la capacité existe à l'ouverture du J20, plus la CT21 Méga-Sangsue créée | H-7 |
| 12 | Pierres d'évolution vendues ; évolutions en données, art en lot (ou provisoire) ; pas de vitamines | H-8 |
| 13 | Dresseurs : Route 8 **7**, Arène **5**, repaire **10** | H-9 |
| 14 | Évoli offert, unique, dans la maison du toit de la Résidence | H-10 |
| 15 | Giovanni : niveaux RB en référence, simulation, nouvel essai après défaite, aucune révélation | H-11 |
| 16 | Sauvages : union Rouge + Bleu | H-13 |
| 17 | Objets cachés, avec le mécanisme existant du J12 | H-14 |
| 18 | Aucun ordre imposé entre Erika et le repaire | V, passe §2.3 |
| 19 | Le J20 ne touche ni Lavanville, ni M. Fuji, ni Ossatueur, ni la Poké Flûte, ni Ronflex | V |

## Grilles v1 — VALIDÉES par Kevin le 2026-10-15

> Validées avec la densification de Céladopole et le raccord recalé sur Lavanville. Maison du chef :
> deux habitants ordinaires (valeur par défaut retenue). Textes manquants : lot complémentaire au
> plan technique.

29 grilles nouvelles dans `tools/plans/` (la grille fait foi pour la géométrie). Contrôle global :
`python3 tools/art/plan_check.py` → **38 plans conformes** (9 existants + 29 du J20), profils
`plan_check_routes_j20.py`, `plan_check_celadopole.py`, `plan_check_repaire.py`.

| Groupe | Fichiers | Taille |
|---|---|---|
| Routes | `route_8.txt`, `route_7.txt`, `souterrain_7_8.txt`, `souterrain_entree.txt` (2 instances), `poste_safrania.txt` (2 instances) | 80 × 26 · 28 × 24 · 48 × 10 · 12 × 10 · 12 × 10 |
| Ville | `celadopole.txt` ; `celadopole_arene.txt` ; `celadopole_magasin_{rdc,2e,3e,4e,5e,toit,ascenseur}.txt` ; `celadopole_residence_{rdc,1er,2e,3e,toit,maison_toit}.txt` ; `celadopole_{restaurant,maison_chef,hotel}.txt` | 70 × 46 ; 17 × 16 ; 20 × 13 (toit 20 × 11, ascenseur 6 × 6) ; 16 × 11 (toit 16 × 10, maison 10 × 8) ; 15 × 10 |
| Repaire | `casino.txt`, `repaire_b1f.txt` … `repaire_b4f.txt` (géométrie RB 1:1, 59 trajets de dalles RB reproduits), `repaire_ascenseur.txt` | 20 × 18 ; 30 × 28 (B4F 30 × 24) ; 6 × 8 |

**Raccords** :
- Lavanville (0, 10..12) ↔ Route 8 (79, 10..12), recalé le 2026-10-15 sur la grille du J18
  (`lavanville.txt`, branche `docs/dossier-j18`) ;
- Route 7 (0, 10..12) ↔ Céladopole (69, 21..23) ;
- Casino (15..16, 17) ↔ porte de la ville (39..40, 32), arrivée `from_casino` (39..40, 33). La
  Corde Sortie du repaire ramène sur `from_casino` ;
- tous les escaliers et portes d'ascenseur du repaire sont déclarés des deux côtés.

Traversée Lavanville → Céladopole : 158 pas. Depuis l'entrée est de la ville : 13 pas jusqu'au
Centre, 63 jusqu'au grand magasin, 74 jusqu'à l'Arène.

**Densification de Céladopole** (2026-10-15, après le premier aperçu, trop de pavé vide) :
jardin en terrasse au nord du Casino et de l'ancien Coin à lots, massifs prolongés le long de
l'avenue, pelouse et haie arborée au-dessus de l'enclos de l'Arène, massifs et arbres à l'arrière
des maisons du sud. Aucune porte, aucun accès ni aucune rue n'a changé.

**Ce que vérifient les contrôles** :
- chaque dalle mène à une case d'arrêt, sans boucle ;
- les deux moitiés du B4F sont disjointes à pied ;
- l'Arène est fermée sans Coupe, et toute la ville reste ouverte sans Coupe ;
- Erika est atteignable par le tour, et E5 est inévitable ;
- D1, D2, D4 et D5 sont inévitables, D3, D6 et D7 évitables ;
- le toit de la Résidence n'est atteignable que par l'escalier de service ;
- l'ascenseur du magasin dessert du RdC au 5e ; celui du repaire, B1F, B2F et B4F ;
- les 14 PNJ ne sont sur aucune case de coupure.

**Valeurs par défaut prises par les grilles** (règle 4) :
- 14 PNJ en ville : 12 habitants et 2 Rocket en civil ;
- Arène en 17 × 16, pour un second lacet de haies ;
- aucun PNJ au 3e de la Résidence ;
- vendeur d'objets X conditionnel (`condition=stat_stages`) ;
- 2 Pokémon d'ambiance par route, pris dans les sauvages ;
- herbe H1 de la Route 8 obligatoire (5 cases) ;
- Casino : 5 PNJ aux places RB ; le Rocket de l'affiche se range en (11, 6) après sa défaite ;
- arrivée d'ascenseur sur la case devant la porte ;
- objets RB posés sur un décor (Fer, PV Plus) ou cachés dans un mur, ramassés depuis la case voisine.

**Points à trancher par Kevin** :
1. **Maison du chef** : RB l'appelle « Chief House » sans en faire un personnage. Par défaut, deux
   habitants ordinaires.
2. **Textes manquants** : 10 habitants de la ville, les petits intérieurs (hôtel, maison du chef,
   restaurant hors client n° 44) et les étages du magasin n'ont pas de réplique dans le lot §20.
   Proposition : un **petit lot complémentaire** au moment du plan technique, validé en une fois.
3. **Distances** (Arène à 74 pas, grand magasin à 63) et **Arène plus haute que l'écran** : à juger
   sur S24 au 20-I (caméra qui suit).

## Vue générale peinte v1 — VALIDÉE par Kevin le 2026-10-15 (telle quelle)

> Produite le 2026-10-15 selon la filière du J13 (plan en aplats non annoté + vue d'Azuria comme
> ancre de style, Codex, sans nom de licence dans les prompts). **Référence de DA et de composition
> seulement** ; la grille `tools/plans/celadopole.txt` fait foi pour toute coordonnée, et rien
> n'est implémenté parce qu'il est sur l'image (règle 10).

- **Vue retenue** : `docs/design/reference/celadopole-vue-generale-v1.png` (essai 4,
  `tools/art/prompts/CONCEPT_CELADOPOLE_VUE_GENERALE_r4.txt`, plan joint
  `docs/design/reference/celadopole-plan-v1.png`, ancre `azuria-vue-generale-v1.png` : même pinceau,
  même lumière, même Centre ; composition non reprise).
- **Plan** : `python3 tools/art/plan_aplats.py tools/plans/celadopole.txt` → `build/art/PLAN_CELADOPOLE_v1.png`
  (`dessiner_celadopole`, paysage 1536 × 1024, 1 case = 21 px ; aucun personnage, aucune case
  cachée). Fonction à part de `dessiner_j13`, car la légende de Céladopole redonne un autre sens à
  des lettres d'Azuria (M, Z, K, s) ; mêmes couleurs de base. Les autres plans sont inchangés
  (contrôle `plan_check.py` : 38 plans conformes).
- **Essais** : 4. r1 composition et style justes, mais passerelle de bois au lieu du talus, ni
  pêcheur ni créature, pas d'arbuste devant l'enclos ; r2 talus, pêcheur et créature, arbuste
  clair dans la haie, grand magasin et Résidence plus hauts, mais étang sans quai distinct et
  aucune silhouette dans la ruelle ; r3 quai blanc-crème et silhouette dans la ruelle, mais une
  allée sort par le bas de l'image et le talus devient une falaise ; **r4 retenu** (sud fermé,
  talus de terre, arbuste vert-jaune aligné dans la haie est).
- **Écarts connus avec la grille (la grille gagne)** :
  - la **ruelle de service** au nord de la Résidence (y 5..6) ne se lit pas : la tour d'escalier
    de service est collée au toit, entre des haies ;
  - un **petit escalier** est peint dans le jardin en terrasse au nord du Casino (aucun escalier
    dans la grille ; à ignorer) ;
  - la **créature** du pêcheur est une forme ronde à spirale **sans bras** (le dossier dit le
    Tartard du pêcheur, §7.1) ;
  - le Rocket en civil de la porte du Casino est **juste devant la porte** (grille : (37, 33), à
    gauche) ; celui de la ruelle est à son **entrée sud** (grille : (47, 30)) ; aucun détail rouge
    visible (§7.1) ;
  - l'**ouverture de la haie** de l'enclos se lit peu : l'arbuste est plus clair et aligné dans la
    haie, mais on ne voit pas qu'il bouche un passage ;
  - le grand magasin a **trois niveaux** visibles sous le toit-terrasse ; l'hôtel ressemble à une
    grande maison (lucarnes) ; les panneaux ocre du plan ne sont pas peints ;
  - le parc ouest, la pelouse est et les massifs de l'avenue sont proches du plan, sans
    correspondance case à case.
- **Points à juger par Kevin** :
  1. lisibilité des deux silhouettes (« deux hommes qui ne bougent pas ») et des néons du Casino ;
  2. lecture de l'arbuste devant l'Arène (faut-il un essai qui montre mieux l'ouverture ?) ;
  3. la créature du pêcheur (forme ronde sans bras) : acceptable comme référence d'ambiance ?
  4. équilibre « prospère et verte » : densité des massifs, hauteur du grand magasin.

## 1. Intention

Céladopole est **la grande ville du milieu du voyage** : prospère, verte, commerçante, élégante. Le
joueur y découvre l'abondance (le grand magasin), la nature domestiquée (l'Arène d'Erika, les
jardins) et, sous les néons du Casino, la Team Rocket installée au cœur de la ville. **Les lumières
et les ombres** : rien en surface ne la montre ; tout ce qui compte se passe en dessous.

Rythme : la Route 8 est une route de Dresseurs. Le souterrain apporte un silence et une découverte.
La Route 7 laisse apparaître les toits de la ville. La ville se visite librement. Puis vient la
descente, étage par étage, jusqu'au bureau de Giovanni. On repart avec un objet qui ne sert qu'à
une chose : **voir ce qui se cache dans la Tour**.

## 2. Périmètre

| Au J20 | Hors J20 |
|---|---|
| Route 8, 2 bâtiments d'entrée du souterrain, souterrain ouest-est, Route 7 ; poste de garde de Safrania sur chaque route (fermé) ; Céladopole (extérieur, Centre, grand magasin à 5 étages + toit + ascenseur, Résidence à 3 étages + toit + maison du toit, Arène, Casino, restaurant, maison du chef, hôtel) ; repaire B1F à B4F + ascenseur ; Erika, Badge Prisme, CT21 ; Giovanni, Scope Sylphe ; Évoli ; 3 mécaniques (ascenseur, dalles tournantes, don de Pokémon) | Safrania et l'ouverture de ses postes, Thé, Route 16, Vol, Ronflex, Piste Cyclable, Coin à lots, jetons, Porygon, Surf et pêche dans l'étang, vitamines, CT dont la capacité n'existe pas, Diplôme (post-game), tout événement de la Tour au-delà des règles du J19 |

**Cartes : 32** (recompté sur les grilles v1). 2 routes, le souterrain, 2 bâtiments d'entrée et
2 postes de garde (une enveloppe chacun), la ville, 19 intérieurs de ville (dont le Centre, réutilisé,
et le Casino) et 5 cartes de repaire.

## 3. Route 8 [V, H-9, H-13]

### 3.1 Forme [D]

Bande est-ouest d'environ **80 × 26 cases** : RB fait 60 × 18, et on applique le rapport
d'Azuria. Le bord est se raccorde à **Lavanville** (contrat d'entrée du J18). Le bord ouest bute
sur le **poste de garde de Safrania**. Le bâtiment d'entrée du souterrain est au nord-ouest.

```
 [poste Safrania]──┬── herbes ── D2 ── clôtures ── duo D4/D5 ── herbes ── D6 ── D7 ──[Lavanville]
                   │                 ↑ chemin haut (corniche)        ↑ chemin bas (herbes)
 [souterrain] ─────┘   D1          D3
```

- Deux chemins parallèles (haut et bas) qui se rejoignent. Ce sont les « chemins alternatifs » de
  la V2 : on peut éviter **D3, D6 et D7**.
- 3 zones d'herbes. Rebords franchissables vers le sud seulement (règle existante).
- **Pas d'arbuste à Couper** : RB en a un vers une poche d'herbes, on ne le reprend pas (une zone
  de plus pour rien).

### 3.2 Dresseurs [H-9 ; équipes RB de référence, D pour la sélection]

| # | Classe | Équipe RB (référence) | Évitable |
|---|---|---|---|
| D1 | Intello | Voltorbe, Smogo, Voltorbe, Magnéti 20 | non (devant l'entrée du souterrain) |
| D2 | Joueur | Ptitard, Ptitard, Têtarte 22 | non |
| D3 | Intello | Tadmorv, Grotadmorv, Tadmorv 22 | oui |
| D4 + D5 | Fillettes (duo côte à côte) | Nidoran♀, Nidorina 23 · Miaouss ×3 24 | non (combats successifs, pas de combat en duo) |
| D6 | Joueur | Caninos, Goupix 24 | oui |
| D7 | Fillette | Mélofée ×2 22 | oui |

Les espèces absentes des données à l'ouverture du J20 sont **remplacées par une espèce déjà
présente, de type proche** [D]. Le plan en fait la liste, à partir des données réelles. Le trio RB
de quatre Dresseurs côte à côte devient le duo D4 / D5.

### 3.3 Sauvages [H-13]

Union Rouge + Bleu, niveaux RB : Roucool 18–20, Férosinge 18–20, Miaouss 18–20, Abo 17–19,
Sabelette 17–19, **Caninos 15–18**, **Goupix 15–18**. Taux : RB fusionnés, à rééquilibrer au plan
(même règle que la Route 3).

### 3.4 Objets [D]

1 Super Potion visible sur le chemin haut ; 1 **Rappel** caché près de la corniche.

## 4. Souterrain ouest-est [V]

- **Deux bâtiments d'entrée** (un sur chaque route), avec l'enveloppe des postes de garde : un
  escalier, un panneau, un habitant [D].
- **Couloir** d'environ **48 × 10 cases** [D]. Il est plus développé que dans RB : une **niche
  latérale** au tiers ouest (bancs, carrelage fissuré, lampe qui grésille) et une **galerie en
  coude** au milieu, qui donne un peu de profondeur sans créer de labyrinthe.
- **Aucune rencontre, aucun Dresseur** (RB).
- **2 objets cachés** (RB) : **Pépite** dans la niche, **Huile** au coude. Huile → **Super
  Potion** si les PP ne se restaurent pas encore par objet [D].
- Lumière : néons froids et réguliers, un tube qui clignote lentement. Son : écho des pas, ventilation
  lointaine. Le compagnon suit (couloir de 2 cases au moins).

## 5. Route 7 [V]

- Environ **28 × 24 cases** [D]. Courte, en **pente douce vers l'ouest**. Les toits de Céladopole
  apparaissent : cime des arbres du parc, puis le toit-terrasse du grand magasin, puis la façade.
- **Aucun Dresseur** (RB). 2 zones d'herbes.
- Poste de garde de Safrania à l'est, bâtiment d'entrée du souterrain au sud-est.
- Sauvages (union, niveaux RB) : Roucool 19–22, Mystherbe 19–22, Chétiflor 19–22, Férosinge 17–20,
  Miaouss 17–20, Caninos 18–20, Goupix 18–20.

## 6. Postes de garde de Safrania [H-5]

Un poste sur la Route 8 et un sur la Route 7, même enveloppe. Le garde barre la porte côté
Safrania. **Il ne parle pas de soif.** Sa réplique (§20.2) dit que la ville est fermée « pour le
moment ». Le jalon de Safrania décidera de l'ouverture (boissons RB ou Thé RFVF). Aucun drapeau
n'est posé.

> **Modifié le 2026-10-19 (décision de Kevin, après le verrouillage)** : l'entrée dans Safrania se
> fait au J20, comme dans Rouge/Bleu. Une boisson donnée au garde d'un poste ouvre les quatre
> postes (drapeau `saffron_gates_open`). Remplace H-5 (C). Confirmé par Kevin le 2026-10-19 (Q-4 : A,
> textes 215–219 validés). Détail : `docs/tech/jalon-20.md` §2.16, Q-4, annexe A.14.

## 7. Céladopole [V, H-3, H-4]

### 7.1 Structure (logique, pas grille) [D sauf la taille]

**≈ 70 × 46 cases**, angles droits (dossiers 01 et 07). Une grande **avenue est-ouest** relie la
Route 7 au parc ouest ; deux rues nord-sud la croisent.

```
 ┌──────────────────────────────────────────────────────────────────┐
 │ [obstacle    GRAND MAGASIN      RÉSIDENCE (esc. service nord)    │
 │  ouest]       (toit-terrasse)        ┌──étang──┐    CENTRE        │
 │  haies       ══════════ AVENUE ═════════════════════════════ → Route 7
 │ ┌haies┐      jardins  panneaux     CASINO   [façade]   arbres    │
 │ │ARÈNE│◄arbuste      fontaine     (néons)  (ex-lots)             │
 │ └─────┘      MAISON DU CHEF   RESTAURANT   HÔTEL                 │
 └──────────────────────────────────────────────────────────────────┘
```

- **Arène** au sud-ouest, ceinte de haies ; un **arbuste à Couper** devant l'entrée (RB) [V].
- **Étang** au centre-nord, avec son pêcheur et son Tartard (PNJ). Pas de Surf, pas de pêche.
- **Sortie ouest** [H-4] : la rue se termine sur **une haie d'arbres denses et un talus**, sans
  panneau, sans texte qui promette quoi que ce soit (modèle du Sentier est d'Argenta). Le jalon de
  la Route 16 remplacera l'obstacle.
- **Façade de l'ancien Coin à lots** [H-6] : un **décor** sans porte interactive, vitrine éteinte,
  sans aucun mot sur les jetons [D].
- **2 Rocket en extérieur** (RB), PNJ sans combat, en civil élégant avec un détail rouge [D] (§13.1).
- **1 objet caché** : PP Plus en RB → **Rappel** si PP Plus n'existe pas [D].

### 7.2 Règles de lecture

- Plus dense et plus animée qu'Azuria, **sans foule** : environ **12 habitants** dehors [D], aucun
  sur une case de passage obligée, aucun déplacement qui bloque une porte.
- Signes de prospérité : vitrines, enseignes, jardins taillés, fontaine.
- Signes d'ombre : néons trop vifs du Casino, deux silhouettes qui ne bougent pas, une ruelle derrière
  le Casino plus sombre que le reste.
- **Pas de minimap, pas de flèche** : le grand magasin et le Casino se repèrent à leur silhouette.

### 7.3 Habitants [D]

12 habitants, dont 4 qui portent l'histoire (§20.3) :
- un client du Casino, qui trouve que « le patron a des amis bizarres » ;
- une jardinière, qui parle d'Erika et de l'arbuste devant l'Arène ;
- un vieil homme près de l'étang : souvenir de Lavanville, lien discret avec la Tour ;
- un employé de bureau qui a entendu parler de « Sylphe », sans rien d'autre (amorce de Safrania).

## 8. Centre Pokémon

Standard, enveloppe existante. Point de retour après une défaite dans la ville, à l'Arène ou dans le
repaire.

## 9. Grand magasin [V, H-7, H-8]

**7 cartes** : RdC, 2e, 3e, 4e, 5e, toit, ascenseur. **Escaliers** à l'ouest, **ascenseur** à
l'est, qui dessert du RdC au 5e (RB). Le toit se rejoint par l'escalier depuis le 5e.

| Étage | Contenu |
|---|---|
| RdC | Accueil ; tableau des étages (le seul « plan » du magasin, à lire) ; 2 clients |
| 2e | **Vendeur 1** : Super Ball, Super Potion, Rappel, soins de statut ; Super Repousse quand la Repousse existera [D] · **Vendeur 2** : CT dont la capacité existe à l'ouverture du J20 (liste RB : Reflet, Protection, Coupe-Vent, Empal'Korne, Bombe-Œuf, Ultimapoing, Ultimawashi, Bélier, Sacrifice ; **le plan filtre**) [H-7] |
| 3e | Rayon des jeux : PNJ ; l'homme qui offre **CT18 Riposte** dans RB est présent, mais **ne donne rien** tant que Riposte n'existe pas (réplique neutre) [H-7] |
| 4e | **Poupée Poké** (1 000 ₽, fuite assurée d'un combat sauvage) [D] ; **Pierre Feu, Pierre Eau, Pierre Foudre, Pierre Plante** (2 100 ₽ chacune, RB) [H-8] |
| 5e | **Objets X** si le moteur gère les niveaux de statistiques ; sinon l'étage est un salon avec PNJ [H-8]. **Aucune vitamine.** |
| Toit | 3 distributeurs (**Eau Fraîche 200 ₽, Soda Cool 300 ₽, Limonade 350 ₽**, soins 50 / 60 / 80 PV, RB) ; une **fillette** qui échange une boisson contre une CT : Eau Fraîche → **CT13 Laser Glace** (la capacité existe), Soda Cool → CT48 Éboulement, Limonade → CT49 Triplattaque, **seulement si la capacité existe** [H-7] ; vue sur la ville |

**Pierres d'évolution [H-8]** : le J20 ajoute aux données les évolutions qu'elles débloquent pour des
espèces **capturables à ce stade**, soit Arcanin, Feunard, Aquali, Voltali, Pyroli, ainsi que
Rafflesia et Empiflor (créées pour Erika). Le plan recense les autres lignées déjà présentes (Raichu,
Staross…). Art : en lot avec les espèces du J20 ; à défaut, art provisoire signalé dans
`etat-projet.md`.

## 10. Résidence Céladon [H-5, H-10]

| Carte | Contenu |
|---|---|
| RdC | Hall ; la **vieille dame** et ses Pokémon (PNJ, Miaouss, Mélofée) ; **elle ne donne rien** [H-5] |
| 1er, 2e | Paliers, 2 habitants |
| 3e | Palier ; une porte **« Bureau privé »** fermée [D] (le Diplôme RB est post-game) |
| Toit | Terrasse, vue sur la ville ; on y monte **par l'escalier de service**, entrée au nord du bâtiment (RB) |
| Maison du toit | Une Poké Ball sur une table : **Évoli N25** [H-10] |

**Don d'Évoli** (mécanique nouvelle, réutilisable) : il rejoint l'équipe, ou le **stockage** si
l'équipe est pleine (message). Il est **enregistré au Pokédex**, comme vu et capturé. Drapeau
`eevee_received`. La Poké Ball disparaît. Pas de surnom imposé ; proposition de surnom comme
pour une capture [D].

## 11. Arène d'Erika [V, H-9]

### 11.1 Lieu

Serre élégante, environ **17 × 15 cases** [D] : allées de **haies**, massifs, bassin, verrière.
Entrée : **arbuste à Couper** dehors (RB) [V]. À l'intérieur, **un second arbuste** coupe un
raccourci vers Erika : on peut aussi faire le tour par les allées [D]. Lumière verte filtrée, sans
scintillements excessifs.

### 11.2 Dresseuses [H-9]

5 Dresseuses (RB : 7). Toutes sont évitables, sauf la dernière avant Erika.

| # | Classe | Équipe RB (référence) |
|---|---|---|
| E1 | Fillette | Chétiflor, Boustiflor 23 |
| E2 | Fillette | Mystherbe, Ortide 23 |
| E3 | Beauté | Chétiflor ×2 24 |
| E4 | Jeune Dresseuse | Bulbizarre, Herbizarre 24 |
| E5 | Topdresseuse (obligatoire) | Boustiflor, Ortide, Herbizarre 24 |

### 11.3 Erika [V, H-11 par analogie]

- Équipe RB : **Empiflor 29, Saquedeneu 24, Rafflesia 29**. **Retenu par Kevin le 2026-10-16 (E-1)** :
  **Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29**. Niveaux et capacités fixés par
  simulation (méthode de Pierre, T16 du J10), avec RB comme référence. Méga-Sangsue sur Rafflesia
  (RB).
- IA `smart`, avec le changement de Pokémon du J13. Récompense en argent RB [D].
- Caractère (dossier 06) : **altérations et contrôle**. Calme, polie, un peu rêveuse, ferme au
  combat. Elle somnole à l'arrivée du joueur (RB), ce qui donne un **petit moment** sans
  cinématique.
- **Défaite** : retour au Centre, Dresseuses battues gardées ; on la retente librement.

### 11.4 Badge Prisme et CT21

- **Badge Prisme** (`badge_rainbow`, existant) : inscription et vibration, comme les badges
  précédents. **Aucun effet** : ni bonus, ni obéissance, ni Force (dossier 12 ; passe §3.5).
- **CT21 Méga-Sangsue** : capacité **créée** au J20 (Plante, valeurs actuelles : 40 / 100 % /
  15 PP, soigne la moitié des dégâts). Compatibilités générées par `tools/gen_tm_compatibility.py`.
- Grand moment : « Badge Prisme » (règle des badges).

## 12. Casino [V, H-6, H-12]

- Salle visible, **machines en décor** : non interactives. Au contact, la réplique dit seulement
  qu'elles sont éteintes « pour inventaire » [D]. **Aucun jeton, aucune mise, aucun gain.** Les
  jetons cachés de RB disparaissent.
- 5 PNJ [D], aucun Dresseur sauf le **Rocket de l'affiche**. Il se tient devant une affiche au mur
  nord. Lui parler déclenche le combat (Rattatac, Nosferapti 20, RB).
- **Après sa victoire**, il s'éloigne en lâchant un mot de trop (§20.6). L'affiche devient
  examinable : **un interrupteur derrière**. Un bruit sourd, une partie du mur coulisse, et
  l'escalier du B1F apparaît. Drapeau `game_corner_switch`. Le passage reste ouvert ensuite.
- Restaurant [H-6] : **pas de Boîte Jetons.** Le client qui la donnait dans RB se plaint d'avoir
  tout perdu au Casino, la veille de sa « fermeture pour inventaire ».

## 13. Repaire Rocket [V, H-9]

### 13.1 Ton

Dossier 15 §8.1 et B-7 du J12 : une organisation, des rôles crédibles (gardes, techniciens,
logisticiens), des répliques courtes, **ni caricature, ni ton militaire**. Uniforme sombre et R
rouge, modernisés dans la main peinte. Les sbires vaincus **restent en place** (RB) et ne
recombattent pas.

### 13.2 Étages [V ; géométrie RB à 1:1 pour les énigmes]

Les grilles des **B1F à B4F reprennent la géométrie RB case pour case** [D] : les énigmes de dalles
en dépendent. Le décor change (béton, néons, caisses, câbles), mais la topologie reste la même.

| Carte | Contenu (RB, sélection H-9) | Dresseurs (10 en tout, Casino compris) |
|---|---|---|
| B1F | Arrivée par l'escalier du Casino ; escalier vers le B2F ; porte de l'ascenseur ; Corde Sortie, Hyper Potion (→ Super Potion si absente) ; 1 objet caché (PP Plus → Rappel [D]) | 3 : Soporifik / Machoc 21 · Rattatac ×2 21 · Tadmorv / Smogo ×2 20 |
| B2F | **Dalles tournantes** ; Pierre Lune, Pépite, CT07 Empal'Korne (si la capacité existe, sinon → Super Potion [H-7]), Super Potion ; ascenseur | 1 : Nosferapti, Smogo, Tadmorv, Nosferapti, Rattatac 17 |
| B3F | **Dalles tournantes** ; CT10 Damoclès (même règle), **Super Bonbon** ; 1 objet caché (Pépite) | 2 : Rattata, Rattatac, Soporifik 20 · Machoc ×2 21 |
| B4F ouest (par l'escalier) | Le **Rocket à la Clé** ; PV Plus (→ Rappel [D]), CT02 Coupe-Vent (même règle) | 1 : Smogo, Nosferapti 21, puis la Clé (§13.4) |
| B4F est (**par l'ascenseur**) | 2 gardes devant la porte du bureau ; **Giovanni** ; **Scope Sylphe** ; Fer (→ Super Potion [D] ; dans cette moitié en RB, correction des grilles v1) ; 1 objet caché (Super Potion, lisible seulement depuis la case du Scope) | 2 : Sabelette, Abo, Sablaireau 23 · Abo, Sabelette, Arbok 23 |
| Ascenseur | Panneau d'étages : **B1F, B2F, B4F** (RB) | — |

Sélection H-9 : on retire 2 des 5 sbires du B1F (RB 11 et 12). Espèces absentes → remplacées
(§3.2) [D].

### 13.3 Dalles tournantes [V ; règles de la passe §3.8]

- Une **flèche peinte au sol** (lisible, sans pixel art) pousse le joueur **case par case**, à vitesse
  de course, jusqu'à une **case d'arrêt** marquée (disque clair). C'est déterministe : même dalle,
  même trajet.
- Pendant la glisse : entrées ignorées, menu fermé, joueur qui pivote dans le sens de la flèche,
  compagnon rétracté. Un son court au départ, un son à l'arrêt.
- **Aucune sauvegarde automatique pendant une glisse.** La position enregistrée est toujours une
  case stable. Après une coupure, on reprend sur la dernière case stable.
- **Données, pas code** : les dalles et les cases d'arrêt sont déclarées dans la carte. Un test
  vérifie que **chaque dalle mène à une case d'arrêt praticable**, sans traverser de mur.
- Moteur **réutilisable** (Arène de Jadielle, RB).

### 13.4 Clé Ascenseur [V ; passe §2.3]

- Elle est au **B4F ouest**, chez le sbire qu'on atteint par l'escalier du B3F, **pas** chez
  Giovanni.
- Quand on lui reparle après sa défaite, il la laisse tomber (RB) : une Poké Ball apparaît à côté de
  lui, à ramasser. Drapeau `rocket_dropped_lift_key`, objet-clé `lift_key`.
- **Ascenseur** (mécanique nouvelle, partagée avec le grand magasin) : une petite carte, un panneau
  d'étages, un fondu bref et une légère secousse. **Sans la Clé**, le panneau du repaire ne répond
  pas (« Il faut une clé. »). Il ne propose **que** B1F, B2F et B4F.

### 13.5 Giovanni [V, H-11]

- Bureau au B4F est. Les 2 gardes battus, la porte s'ouvre.
- **Calme, autoritaire, sûr de lui** ; jamais caricatural. Il n'évoque **ni** l'Arène de Jadielle,
  **ni** Mewtwo ; il parle d'affaires, de la Tour (« ce qu'on y cherche »), du joueur comme d'un
  contretemps.
- Équipe RB : **Onix 25, Rhinocorne 24, Kangourex 29**. **Retenu par Kevin le 2026-10-16 (G-1)** :
  **Onix 23, Rhinocorne 22, Kangourex 25** (simulation : Kangourex N29 bloquait les trois starters).
  IA `smart` avec changement de Pokémon. Récompense en argent RB [D].
- **Défaite du joueur** : retour au Centre de Céladopole ; Rocket battus gardés ; Clé gardée ; on
  peut redescendre directement par l'ascenseur.
- **Victoire** :
  1. une réplique courte (§20.7) ;
  2. fondu : Giovanni est parti ;
  3. le **Scope Sylphe** reste au sol, à côté du bureau ;
  4. le joueur le ramasse ;
  5. Grand moment « Giovanni » (passe §3.11).

  Drapeaux : `giovanni_hideout_won`, puis l'objet-clé `silph_scope`.
- Le repaire reste ouvert ensuite : objets restants, aucun combat réinitialisé.

## 14. Scope Sylphe et lien avec la Tour [V ; passe §2.4]

- Objet-clé **unique**, catégorie `key`, sans action UTILISER : il agit **dès qu'on le possède**.
- **Contrat avec le J19** : les règles des spectres testent **`silph_scope` dans le Sac**, pas un
  drapeau du J20. Aucune migration, aucune réécriture de la sauvegarde du J19.
- **Dans une build J20 sans J21** :
  - les rencontres sauvages de la Tour deviennent identifiables (règle du J19) ;
  - le **spectre du 6e étage reste un blocage**, avec le traitement « à venir » existant [D] ;
  - **aucun** drapeau `fuji_*`, `marowak_*` ou `poke_flute` n'est posé. Un test le vérifie.

## 15. Évoli, pierres et espèces [H-8, H-10]

### 15.1 Espèces nouvelles (selon les données à l'ouverture du J20)

| Rôle | Espèces |
|---|---|
| Sauvages | Caninos, Goupix |
| Don | Évoli |
| Erika | Empiflor, Saquedeneu, Rafflesia |
| Giovanni | Rhinocorne, Kangourex |
| Évolutions par pierre | Arcanin, Feunard, Aquali, Voltali, Pyroli |
| Dresseurs (si on ne les remplace pas) | Soporifik, Tadmorv, Sablaireau, Magnéti, Ptitard, Têtarte, Mélofée, Nidorina… : **remplacées par défaut** (§3.2) |

| Tour Pokémon (données créées au J19) | **Fantominus, Spectrum, Osselait** : capturables dès que le joueur a le Scope (règle K-11 du J19), donc **dos de combat** et art définitif à la charge du J20 |

Soit **12 espèces nouvelles** au minimum, plus l'art de capture des 3 espèces de la Tour. Pour chacune : données (stats, capacités, compatibilités CT),
artwork du Pokédex, face de combat, et dos pour les espèces capturables (Caninos, Goupix, Évoli et
leurs évolutions).

### 15.2 Capacités

À créer au minimum : **Méga-Sangsue**. Le plan recense les capacités naturelles des 12 espèces au
niveau où on les rencontre, et applique la règle du J12 : une capacité qui demande une mécanique
absente est remplacée par un choix manuel dans la fiche du Dresseur.

## 16. Dépendances (contrat d'entrée, passe §4)

| Le J20 suppose | Jalon | Sinon |
|---|---|---|
| Coupe utilisable hors combat (capacité d'exploration) | J16 | L'Arène est inaccessible : il faut un autre accès (K26) |
| Bord ouest de Lavanville raccordé à la Route 8 | J18 | Raccord repris au plan |
| Spectres conditionnés à `silph_scope` | J19 | Écrire la règle dans le dossier 22 |
| Rival n° 5 vaincu ; aucun rival au J20 | J19 | — |
| Équipe d'environ N25–28 | J19 | Absorbé par la simulation d'Erika et de Giovanni |
| Objets cachés (J12), stockage (J7), Grands moments (J6), changement de Pokémon par l'IA (J13) | faits | — |

## 17. Données et sauvegarde

**Drapeaux** [D, noms indicatifs] :

| Domaine | Drapeaux |
|---|---|
| Zones | `route_8_reached`, `celadon_reached` |
| Erika | `badge_rainbow` (existant), `tm21_received` |
| Évoli | `eevee_received` |
| Toit | `rooftop_tm13`, et un drapeau par CT de la fillette quand sa capacité existe |
| Casino | `game_corner_switch` |
| Repaire | `rocket_dropped_lift_key`, `giovanni_hideout_won` |
| Dresseurs | `beaten_<id>` (7 + 5 + 10) |

**Objets** : objets-clés `lift_key`, `silph_scope` ; pierres d'évolution (AVENTURE, UTILISER sur
un Pokémon) ; boissons (soins) ; Poupée Poké ; CT21 et les CT retenues ; Super Ball, Super Potion,
Rappel si absentes ; objets trouvés (`found_items`).

**Version de sauvegarde** : **aucune nouvelle prévue** (tout tient dans `flags`, `bag`,
`found_items`, `moments`, l'équipe et le stockage). Le plan le confirme sur la version en vigueur à
l'ouverture du J20. La position est toujours une case stable (§13.3).

**Tests de reprise obligatoires** :
- une partie sauvegardée sur chaque case praticable du bord ouest de Lavanville se charge sur la
  Route 8 ;
- une partie coupée pendant une glisse ou dans l'ascenseur reprend sur une case stable.

## 18. Objectifs du tableau de bord [D]

| État | Objectif |
|---|---|
| Route 8 atteinte | « rejoindre Céladopole. » |
| Céladopole atteinte, Casino pas encore ouvert | « explorer Céladopole. » |
| Interrupteur trouvé, Giovanni non battu | « fouiller sous le Casino. » |
| Scope obtenu | « retourner à la Tour Pokémon. » |

Le badge n'a pas d'objectif propre, car l'ordre est libre ; il apparaît au tableau des badges.
Mises à jour en silence (existant).

## 19. Cas limites

| Cas | Comportement |
|---|---|
| Arrivée devant l'Arène sans Coupe | Message de l'arbuste (règle du J16) ; rien d'autre ne bloque la ville |
| Équipe pleine au don d'Évoli | Évoli va au stockage, avec un message |
| Partie quittée pendant une glisse ou dans l'ascenseur | Reprise sur la dernière case stable (§13.3) |
| Clé ramassée, puis défaite | Clé gardée ; descente directe par l'ascenseur |
| Giovanni battu, application coupée avant le ramassage du Scope | La Poké Ball du Scope est toujours au sol (`found_items`) |
| Corde Sortie dans le repaire | Ramène devant le Casino [D] |
| Joueur qui va à la Tour avec le Scope (build J20) | Rencontres identifiées ; 6e étage bloqué « à venir » (§14) |
| Joueur qui retourne au poste de Safrania | Même réplique, porte fermée (§6) |
| Pierre utilisée sur une espèce sans art définitif | Évolution jouée ; art provisoire (§9) |
| Compagnon | Suit dehors, sur les routes et dans le souterrain ; rentre dans les intérieurs ; se rétracte dans l'ascenseur et sur les dalles |
| Défaite dans le repaire | Réveil au Centre de Céladopole ; Rocket battus gardés ; interrupteur gardé |

## 20. Lot de textes — VALIDÉ par Kevin le 2026-10-14

> **Numérotés pour une réponse groupée** (« 12 : … »). Répliques courtes. Erika : calme, polie,
> légèrement rêveuse, ferme. Giovanni : posé, économe en mots, jamais menaçant à voix haute. Rocket :
> des employés d'une organisation, pas des brutes. `{player}` = prénom du joueur.

### 20.1 Route 8 et souterrain

1. Panneau : « ROUTE 8 » / « Lavanville → ← Safrania »
2. Panneau du souterrain : « PASSAGE SOUTERRAIN » / « Route 7 — Céladopole »
3. Intello D1, avant : « Mes calculs disaient que personne ne passerait aujourd'hui. »
4. D1, battu : « Il faut que je revoie mes calculs. »
5. Joueur D2, avant : « On parie ? Non ? Tant pis, on se bat quand même. »
6. D2, battu : « Je n'aurais pas misé sur moi. »
7. Fillettes D4 / D5, avant : « Toutes les deux, on ne perd jamais ! » / « Enfin… presque jamais. »
8. D4 / D5, battues : « D'accord, presque jamais. »
9. Joueur D6, après : « À Céladopole, tout le monde parle du Casino. Moi, je n'y mets plus les pieds. »
10. Habitant d'un bâtiment d'entrée : « Le souterrain passe sous Safrania. Plus court, et plus calme. »

### 20.2 Route 7 et postes

11. Panneau : « ROUTE 7 » / « Céladopole ← → Safrania »
12. Garde de Safrania : « Désolé, Safrania est fermée pour le moment. » / « Je n'en sais pas plus
    que vous. »

### 20.3 Céladopole

13. Titre de zone : « CÉLADOPOLE » / « La cité aux mille couleurs »
14. Panneau de la ville : « CÉLADOPOLE » / « Ville des fleurs et du commerce »
15. Jardinière : « Erika soigne chaque plante de son Arène elle-même. » / « Même l'arbuste devant
    l'entrée. Il faut bien le Couper pour entrer. »
16. Client du Casino : « Le patron du Casino a de drôles d'amis. » / « Toujours en costume, jamais
    un sourire. »
17. Vieil homme près de l'étang : « J'ai grandi à Lavanville. » / « Ces temps-ci, on dit que la Tour
    ne dort plus la nuit. »
18. Employé de bureau : « Sylphe ? Une grande entreprise de Safrania. » / « Ils fabriquent des
    appareils que personne ne comprend. »
19. Rocket en civil 1 : « Tu regardes quoi ? Circule. »
20. Rocket en civil 2 : « … Le Casino ? Il est très bien, le Casino. »
21. Obstacle ouest (examiner) : « Des arbres serrés et un talus. On ne passe pas. »

### 20.4 Grand magasin et Résidence

22. Tableau des étages : « RdC Accueil · 2e Soins et CT · 3e Jeux · 4e Cadeaux et pierres ·
    5e Salon · Toit »
23. Homme du 3e (CT non disponible) : « J'avais un cadeau pour un Dresseur doué. Repasse plus tard. »
24. Fillette du toit : « J'ai tellement soif… Tu as quelque chose à boire ? »
25. Fillette, après l'échange : « Merci ! Tiens, c'est pour toi. »
26. Vieille dame de la Résidence : « Bienvenue. Je reçois rarement des visiteurs, mais j'aime ça. »
27. Porte du 3e : « BUREAU PRIVÉ » / « C'est fermé. »
28. Maison du toit, Poké Ball : « Un Pokémon attend dans cette Poké Ball. » / « Le prendre ? »
29. Don : « {player} reçoit Évoli ! »
30. Équipe pleine : « Évoli a été envoyé au stockage. »

### 20.5 Arène d'Erika

31. Panneau : « ARÈNE DE CÉLADOPOLE » / « Champion : Erika — la beauté des plantes »
32. Dresseuse E1, avant : « Chut… Les fleurs n'aiment pas le bruit. »
33. Topdresseuse E5, après : « Erika t'attend. Elle ne t'a sans doute pas entendu arriver. »
34. Erika, avant : « Oh… Bonjour. Je crois que je m'étais assoupie. » / « Je suis Erika. Les plantes
    m'apprennent la patience. » / « Voyons ce que tu as appris, toi. »
35. Erika, battue : « Tu as gagné. Avec beaucoup d'élégance. »
36. Badge : « {player} reçoit le Badge Prisme ! »
37. CT21 : « Prends aussi ceci. » / « {player} reçoit la CT21 Méga-Sangsue ! » / « Elle reprend
    des forces à l'adversaire. »
38. Erika, après : « Reviens quand tu veux. Les fleurs changent à chaque saison. »

### 20.6 Casino et restaurant

39. Machines (examiner) : « Les machines sont éteintes. Une affichette dit : “Fermé pour inventaire.” »
40. Rocket de l'affiche, avant : « Cette affiche ne te regarde pas. » / « Va jouer ailleurs. »
41. Rocket, battu : « Hé… Ne touche pas à l'affiche ! » (il s'éloigne)
42. Affiche (examiner) : « Il y a un interrupteur derrière l'affiche. » / « Appuyer ? »
43. Interrupteur : « Un bruit sourd… Un passage s'est ouvert. »
44. Client du restaurant : « J'ai tout perdu au Casino hier soir. » / « Et ce matin, ils ont fermé
    “pour inventaire”. »

### 20.7 Repaire et Giovanni

45. Sbire B1F, avant : « Un intrus ? Personne n'entre ici sans badge d'accès. »
46. Sbire B2F, après : « Ces dalles, on les a installées pour ralentir les curieux. »
47. Sbire à la Clé, battu : « Non !… »
48. Sbire à la Clé, après : « Oh non. J'ai laissé tomber la Clé Ascenseur. »
49. Clé : « {player} obtient la Clé Ascenseur ! »
50. Ascenseur sans Clé : « Le panneau ne répond pas. Il faut une clé. »
51. Garde du bureau, avant : « Le patron ne reçoit pas. »
52. Giovanni, avant : « Tu es donc l'enfant qui dérange mes affaires depuis le Mont Sélénite. » /
    « La Tour Pokémon cache une chose qui m'intéresse. » / « Je n'aime pas qu'on se mette en
    travers de mon chemin. »
53. Giovanni, battu : « … Je vois. »
54. Giovanni, après : « Ce repaire ne m'est plus utile. » / « Garde ta victoire. Nous nous
    reverrons. »
55. Scope : « {player} obtient le Scope Sylphe ! » / « Il permet de voir ce que l'œil seul ne voit
    pas. »

### 20.8 Objectifs

56. « rejoindre Céladopole. »
57. « explorer Céladopole. »
58. « fouiller sous le Casino. »
59. « retourner à la Tour Pokémon. »

### 20.9 Pokédex (12 espèces)

60. Entrées reprises du ton des précédentes (une phrase d'observation, sans chiffre), rédigées au
    plan et validées avec le lot d'art.

## 21. Valeurs par défaut (règle 4) — validées par Kevin le 2026-10-14

- **Enveloppes** : Route 8 ≈ 80 × 26, souterrain ≈ 48 × 10, Route 7 ≈ 28 × 24, Céladopole ≈ 70 × 46,
  Arène ≈ 17 × 15 ; repaire B1F–B4F en **géométrie RB 1:1** ; bâtiments d'entrée et postes =
  enveloppe des postes de garde.
- **Dresseurs** :
  - sélection RB du §3.2, du §11.2 et du §13.2 ;
  - espèces absentes remplacées par une espèce présente de type proche ;
  - IA `random`, sauf Erika, Giovanni et la Topdresseuse (`smart`) ;
  - récompenses en argent RB.
- **Objets** :
  - remplacements quand l'objet RB n'existe pas encore (Huile, PP Plus, PV Plus, Fer, Hyper Potion
    → Super Potion ou Rappel) ;
  - CT d'objets au sol remplacées par Super Potion si leur capacité n'existe pas.
- **Ville** :
  - 12 habitants ;
  - 2 Rocket en civil ;
  - façade de l'ancien Coin à lots en décor ;
  - sortie ouest en haie et talus ;
  - porte « Bureau privé » au 3e de la Résidence.
- **Grand magasin** :
  - stocks du §9 ;
  - Poupée Poké 1 000 ₽ ;
  - pierres 2 100 ₽ ;
  - boissons 200 / 300 / 350 ₽ ;
  - 5e en salon si les niveaux de statistiques n'existent pas.
- **Arène** : second arbuste intérieur (raccourci facultatif) ; E5 obligatoire.
- **Casino** : 5 PNJ ; machines « fermées pour inventaire ».
- **Dalles** : vitesse de course ; case d'arrêt marquée d'un disque clair.
- **Ascenseur** : fondu de 0,4 s et légère secousse.
- **Scope dans une build J20** : 6e étage « à venir ».
- **Corde Sortie dans le repaire** : devant le Casino.

## 22. Découpage et validation S24 [H-2]

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **20.0** | Plan `docs/tech/jalon-20.md` ; données (12 espèces, évolutions par pierre, Méga-Sangsue, CT retenues, objets) ; simulations d'Erika et de Giovanni ; grilles `tools/plans/` et vues générales peintes **validées par Kevin** ; lot d'art (espèces, Erika, Giovanni, Intello, Joueur, Beauté, Topdresseuse, Rocket en civil ; fonds de combat CB.3 : route urbaine, serre, repaire) | combats de test |
| **20-I** (lots V 20A–20C) | Route 8, souterrain, Route 7, postes ; Céladopole et ses intérieurs ; **ascenseur** (grand magasin) ; **don d'Évoli** ; pierres ; Arène, Erika, Badge Prisme, CT21 | **S24** |
| **20-II** (lots V 20D–20E) | Casino, interrupteur ; repaire B1F–B4F ; **dalles tournantes** ; Clé et ascenseur du repaire ; Giovanni ; Scope ; contrôle de la Tour en build J20 ; **QA finale** de Lavanville au Scope, en vraie partie (lot V 20F) | **S24** + fusion |

Les dalles et l'ascenseur sont les deux mécaniques à risque. Chacune a son test automatique (§13.3,
§13.4), en plus de la validation S24 du sous-jalon. Pour gagner du temps, on prépare toutes les
cartes du repaire avant ses événements (V).

## 23. Direction artistique et son

- **Ville** : pierre claire, briques miel, verdure taillée, verre et acier discrets ; **golden hour**
  sur les façades. Le Casino est le seul bâtiment aux **néons** : magenta et or, un peu trop vifs.
- **Grand magasin** : sols clairs, vitrines, un étage = une couleur d'accent. Toit-terrasse ouvert sur
  le ciel.
- **Serre d'Erika** : verts profonds, fleurs pâles, lumière filtrée par la verrière, eau calme.
- **Souterrain** : carrelage, néons froids, silence.
- **Repaire** : béton, acier, câbles, caisses ; lumière blanche et dure ; R rouge rare et net.
  Aucune obscurité punitive.
- **Combat** : fonds CB.3 « route urbaine », « serre », « repaire ».
- **Musique** : ville légère et vivante ; Arène calme et élégante ; repaire tendu, sans être
  angoissant ; Giovanni plus grave.
- 2D HD peinte, top-down orthogonal ; ni pixel art, ni isométrie, ni minimap, ni flèche d'objectif.

## 24. Tests et QA

**Automatiques** (GUT) :
- raccords des 32 cartes (aller-retour sur chaque porte) ;
- dalles : chaque dalle mène à une case d'arrêt praticable ;
- ascenseur : seulement les étages autorisés, refus sans la Clé ;
- don d'Évoli (équipe pleine, unicité) ;
- unicité du Scope et de la Clé ;
- indépendance d'Erika et du repaire (deux ordres joués en simulation) ;
- **aucun drapeau J21** posé ;
- sauvegarde et reprise (§17) ;
- données des 12 espèces, des CT retenues et des boutiques.

**S24** (QA bornée, départs de débogage) :
- 20-I : lisibilité de la ville, ascenseur du grand magasin, Évoli, Arène et badge ;
- 20-II : dalles (prise en main, coupure pendant une glisse), ascenseur du repaire, Giovanni, Scope ;
- fps dans la ville et dans le repaire.
