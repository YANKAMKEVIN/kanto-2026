# Dossier 15 — Route 3 et Mont Sélénite (jalon 12)

> **VERROUILLÉ — validé par Kevin le 2026-10-11.** Consolidé par Claude le 2026-10-10 à partir de
> la V1 de ChatGPT (9 arbitrages présélectionnés), de la passe d'alignement de Claude
> (`passes/j12-v1-alignement.md`, B-1 à B-14) et du retour de Kevin (B-1 à B-14 retenus, **B-4, B-7
> et B-11 ajustés**). **C-1 à C-8 retenus** (§21) et **lot de textes §20 validé** le 2026-10-11.
> Prochaine étape : vues générales peintes + grilles, puis plan `docs/tech/jalon-12.md`. **Code
> après la clôture du J11** (C-7).
>
> **Numérotation** : 13 = ouverture (OUV), 14 = systèmes du J11 (branche
> `claude/lancement-j11-4pkt2k`) → **15** est le premier numéro libre (vérifié sur toutes les
> branches le 2026-10-10). Le numéro suit l'ordre de conception, pas celui des jalons.
>
> Légende : **[V]** décision de Kevin · **[D]** valeur par défaut technique (règle 4 de
> `CLAUDE.md`, modifiable sans rouvrir la conception) · **[C-n]** arbitrage du §21 (tranché le 2026-10-11).
> Origine des règles : **RB** Rouge/Bleu · **G+** génération plus récente · **K26** invention de
> Kanto 2026.

## Arbitrages de Kevin (2026-10-10)

| N° | Décision | Statut |
|---|---|---|
| V-1 | Périmètre : **Route 3 + Mont Sélénite + sas de sortie sur la Route 4** ; Azuria au J13 | [V] |
| V-2 | Mont Sélénite en **3 niveaux** connectés (1F, B1F, B2F) | [V] |
| V-3 | Embranchements **lisibles**, sans mini-carte ni GPS | [V] |
| V-4 | Team Rocket **progressive et inquiétante** (direction en B-7) | [V] |
| V-5 | **3 combats Rocket**, dont un final marquant | [V] |
| V-6 | **Un seul fossile**, choix définitif | [V] |
| V-7 | **Combat du chercheur** conservé | [V] |
| V-8 | **Mélofée rare** | [V] |
| V-9 | **Sas extérieur jouable** sur la Route 4, Azuria plus tard | [V] |
| B-1 | **Pierre Lune** : une visible, une cachée ; pas en vente | [V] |
| B-2 | **Grodoudou et Mélodelfe** disponibles par la Pierre Lune | [V] |
| B-3 | Rencontres de grotte sur des **sols de gravats identifiables**, couloirs calmes entre eux | [V] |
| B-4 | **Corde Sortie** : ramène à **l'entrée extérieure du Mont Sélénite**, ne soigne pas, ne change pas le point de repos ; **Repousse reporté** | [V, ajusté] |
| B-5 | Route 3 : **Piafabec, Rondoudou, Sabelette, Abo** | [V] |
| B-6 | Chercheur : **Voltorbe et Smogo** | [V] |
| B-7 | Team Rocket : nom officiel, uniforme sombre, R rouge, recherche des fossiles, **aucun chef** ; rôles crédibles (surveillance, fouilles, sécurisation), dialogues courts, personnalités distinctes ; ni ton militaire ni caricature ; **après leur défaite, ils quittent la grotte** | [V, ajusté] |
| B-8 | Combats inévitables : **2 Dresseurs de la Route 3, le Rocket final, le chercheur** | [V] |
| B-9 | Fin : **Rocket final, puis le chercheur** | [V] |
| B-10 | **Objets cachés** : interagir face à une case signalée discrètement par le décor | [V] |
| B-11 | Compagnon : **suit dans les galeries praticables** ; **masqué temporairement** dans les passages trop étroits, réapparaît dès que possible ; rentre dans sa Ball au Centre | [V, ajusté] |
| B-12 | **Rival absent**, sans allusion | [V] |
| B-13 | **Pas de vendeur de Magicarpe** | [V] |
| B-14 | Validation S24 : **12.0 → 12A → 12B → 12C → 12D** | [V] |

## Vues générales peintes v1 et grilles (validées par Kevin le 2026-10-11)

- **Grilles (autorité de la géométrie ; en cas de contradiction, la grille gagne)** :
  `tools/plans/route_3.txt` (82 × 38), `mont_selenite_1f.txt` (60 × 46), `mont_selenite_b1f.txt`
  (40 × 30), `mont_selenite_b2f.txt` (50 × 38), `route_4_sas.txt` (24 × 14). Contrôles :
  `tools/art/plan_check_route_3.py` (via `plan_check.py`) et `tools/art/plan_check_mont_selenite.py`
  (les trois étages et le sas reliés par les échelles). Les étages sont **plus petits que les
  enveloppes du §5.1** (grotte dense à repères) [D, validé].
- **Plans** : `reference/route-3-plan-v1.png`, `reference/mont-selenite-plan-v1.png` (trois étages
  empilés, 1F en haut), `reference/route-4-sas-plan-v1.png`
  (`tools/art/plan_aplats.py tools/plans/route_3.txt …`, `--mont-selenite`, `tools/plans/route_4_sas.txt`).
- **Vues = référence DA et ambiance** : `reference/route-3-vue-generale-v1.png` (essai 2,
  `tools/art/prompts/CONCEPT_ROUTE3_VUE_GENERALE_r2.txt`) et `reference/mont-selenite-vue-generale-v1.png`
  (essai 2, `CONCEPT_MONT_SELENITE_VUE_GENERALE_r2.txt`), ancre de style : la vue d'Argenta.
- **Mesures** : Route 3, chemin principal 93 pas (≈ 5 min 46 s avec Hugo et Léa), 8 cases d'herbes
  obligatoires ; Mont Sélénite, parcours 206 pas et 4 échelles (≈ 10 min avec R1, R3 et le
  chercheur), 8 cases de gravats obligatoires, 96 % en couloirs calmes, retour à l'entrée possible
  de partout.
- **Décisions de Kevin (2026-10-11)** : D3 et D4 restent **contournables sur leur propre chemin**
  (sinon un troisième combat obligatoire, contraire à B-8) ; **une Potion en B1F** (au fond de la
  galerie de la fouilleuse) ; le chercheur est inévitable parce qu'il **occupe le seul passage**
  vers l'échelle de sortie (combat lancé par la scène, il se range ensuite). Pierre Lune visible en
  B1F (poche de l'échelle C), R1 à 10 cases de l'échelle A (pas vu dès l'arrivée).
- **Écarts des vues à ne pas reproduire** : Route 3 — la montagne reste beige chaud (la cible est
  le passage à l'**ardoise et au gris bleuté** vers l'est, §7), la Fillette est sur le plateau du
  Centre (elle garde le goulet de la jonction). Mont Sélénite — le randonneur est dans la galerie
  est (il est dans la salle du bas, près du puits de jour). Aucun élément n'est implémenté parce
  qu'il est sur une image (règle 10).
- Deux essais par vue (essai 1 : Gamin absent, Scout sans chapeau de paille ; une Sbire aux
  cheveux roses rappelant un personnage connu, entrée de grotte en escalier). **Essais 2 retenus.**

## 1. Intention

Après le Badge Roche, le joueur quitte la sécurité d'Argenta, traverse une grande route ouverte
qui monte vers la montagne, puis entre dans le premier vrai donjon : silence, pierre froide,
lumière rare. Il y découvre que Kanto a des secrets (fossiles, Pierre Lune) et des gens aux
intentions moins innocentes (la Team Rocket). Il en sort par l'autre versant, Azuria en vue.

Transition voulue : chaleur d'Argenta → grands espaces lumineux de la Route 3 → ardoise, gris
bleuté et éclats minéraux de la montagne.

## 2. Périmètre

| Dedans | Réservé au J13 et après | Reporté sans date |
|---|---|---|
| Route 3 (≈ 82 × 38), Centre Pokémon du pied de la montagne, Mont Sélénite 1F / B1F / B2F, sas extérieur de la Route 4 (raccord « AZURIA — À venir ») ; 12 espèces nouvelles (§16) ; rencontres de grotte ; Corde Sortie ; objets cachés ; Pierre Lune et évolutions par pierre ; Team Rocket (3 combats) ; chercheur et fossiles ; capacités nouvelles (§16.2) | le reste de la Route 4 (rebords, Dresseurs, rencontres, objets), Azuria, Pont Pépite, **rival n° 3**, toute nouvelle apparition Rocket | Repousse ; vendeur de Magicarpe ; résurrection des fossiles (Amonita, Kabuto) ; Vieil Ambre (J25, dossier 28) ; Métronome (§16.2) ; Flash et toute capacité d'exploration |

Contraintes [V] : aucun puzzle qui demande une capacité d'exploration ; pas de quête secondaire sur
la Route 3 ; ni Giovanni, ni Mewtwo, ni chef Rocket ; pas de rival.

## 3. Route 3

### 3.1 Forme

Enveloppe **≈ 82 × 38 cases** [D, recalée sur la grille], orientée ouest → est, de la sortie est
d'Argenta (garde du J10, qui laisse passer depuis le badge) au Centre Pokémon et à l'entrée du Mont
Sélénite. Relief qui monte vers l'est, rebords franchissables **vers le sud** (raccourcis de
retour), hautes herbes en blocs nets, **vue progressive sur le Mont Sélénite** (la montagne grandit
dans le décor au fil de la marche).

Trois séquences [V] :

```
ARGENTA ─ garde ─┐
                 │  ① LA SORTIE : vue dégagée sur les collines, herbes H1, Dresseur D1 (inévitable)
                 ▼
         ┌───────┴────────┐   ② LES CHEMINS DES DRESSEURS : deux itinéraires qui se rejoignent
         │ nord (H2, D3)  │      D2 (inévitable) à la jonction ; D3, D4 sur un seul des deux chemins ;
         │ sud  (H3, D4)  │      D5, D6 sur des détours (facultatifs) ; rebords vers le sud
         └───────┬────────┘
                 ▼
         ③ LE PIED DE LA MONTAGNE : roche, végétation rare, herbes H4,
           CENTRE POKÉMON, puis l'entrée du MONT SÉLÉNITE (1F)
```

Schéma de progression seulement : la **grille `tools/plans/route_3.txt` fera foi**, après la vue
générale peinte (§19). Règle de grille [V] : **aucun combat inévitable contournable**, vérifié
par `plan_check.py` comme dans la forêt.

### 3.2 Dresseurs (6, dont 2 inévitables) [D sauf B-8]

Récompense = base de la classe × niveau du dernier Pokémon (règle RB déjà en place : Scout 12,
Campeur 20) [D : Gamin 15, Fillette 15]. IA `random` (débutants). Équipes **sans capacité
choisie à la main** (capacités apprises au niveau, comme la forêt).

| | Dresseur | Où | Évitable | Équipe | ₽ |
|---|---|---|---|---|---|
| D1 | Gamin Hugo | ① sortie | **non** | Rattata Nv. 10, Abo Nv. 10 | 150 |
| D2 | Fillette Léa | ② jonction | **non** | Roucool Nv. 9, Nidoran ♀ Nv. 9 | 135 |
| D3 | Scout Sacha | ② chemin nord | oui | Chenipan Nv. 10, Aspicot Nv. 10, Chrysacier Nv. 10 | 120 |
| D4 | Gamin Enzo | ② chemin sud | oui | Piafabec Nv. 14 | 210 |
| D5 | Fillette Inès | ② détour | oui | Rondoudou Nv. 14 | 210 |
| D6 | Scout Nolan | ③ détour | oui | Aspicot Nv. 9, Coconfort Nv. 9, Chenipan Nv. 9 [D, 2026-10-11 : « Kakuna » = Coconfort, doublon corrigé] | 108 |

Rouge/Bleu en compte 8 ; 6 suffisent à l'échelle A+ (V1). Modèles peints : Gamin et Scout
existent ; **Fillette = nouveau modèle** (§16.4).

### 3.3 Rencontres sauvages [V B-5 ; niveaux et poids D]

| Espèce | Niveaux | Poids |
|---|---|---|
| Piafabec | 8–10 | 35 |
| Rattata | 8–9 | 25 |
| Sabelette | 8–10 | 15 |
| Abo | 8–10 | 15 |
| Rondoudou | 7–9 | 10 |

Même taux et même rampe que la Route 2 nord (`rate` 25, `ramp` 15 → 20) [D]. **Rondoudou** est la
découverte marquante de la route.

### 3.4 Vie, objets

- **PNJ non combattants (2)** [V] : un **voyageur** à la sortie d'Argenta, face à la vue sur la
  montagne ; une **randonneuse** au pied de la montagne, qui revient de la grotte. Répliques §20.
- **Pokémon d'ambiance** [D] : Piafabec (planche existante) sur les hauteurs ; Rondoudou si sa
  planche existe (C-4).
- **Objets visibles (3)** [D] : Poké Ball, Potion, Anti-Para (J11). **Objet caché (1)** : Réveil.

## 4. Centre Pokémon du Mont Sélénite

- Au bout de la Route 3, au pied de la montagne (V1 ; dans RB il est sur la Route 4, côté entrée).
- **Même modèle que les Centres de Jadielle et d'Argenta** (enveloppe peinte réutilisée), sans
  Boutique (RB) [D].
- Nom de zone de l'intérieur : **« Mont Sélénite »** → toast « Point de repos enregistré — Mont
  Sélénite » (format existant) [D].
- Le compagnon rentre dans sa Ball en entrant (bâtiment) [V B-11].

## 5. Mont Sélénite — structure

### 5.1 Les trois niveaux [V-2 ; grilles D, recalées sur le plan]

| Niveau | Enveloppe | Rôle | Lumière |
|---|---|---|---|
| **1F — Les galeries d'entrée** | ≈ 68 × 54 | exploration, embranchements, premiers indices humains (caisses, lampe abandonnée, traces de fouille) | puits de jour depuis des fissures, la plus claire |
| **B1F — Les passages inférieurs** | ≈ 44 × 36 | tunnels plus étroits, raccourcis, **Rocket 1 et 2** | rare ; **lampes de chantier Rocket** = repères et indices |
| **B2F — La chambre des fossiles** | ≈ 56 × 42 | **Rocket final**, chercheur, fossiles, échelle de sortie | chambre éclairée par les projecteurs Rocket ; le reste sombre |

Parcours principal (Rouge/Bleu simplifié) :

```
ROUTE 3 ─ entrée ─▶ 1F ─ échelle A ─▶ B1F (court) ─ échelle B ─▶ 1F (autre secteur)
                     │                                             │
                     └─ échelle C (détour : Pierre Lune visible)   └─ échelle D ─▶ B2F
                                                                                    │
       ROUTE 4 (sas) ◀─ échelle de sortie ◀─ chercheur ◀─ chambre ◀─ Rocket final ◀─┘
```

Les échelles exactes, leur nombre et les détours viennent de la grille (§19). Règles [V-3] :

- **Repères mémorables** par secteur (formes rocheuses, couleur minérale, éclats de Pierre Lune
  incrustés, lampes Rocket) plutôt qu'un labyrinthe ; un embranchement se reconnaît sans carte.
- **Échelles et passages entre étages clairement visibles** ; passage = **fondu comme une porte**
  (nouveau type de passage, peu coûteux) [D].
- **Retour vers l'entrée toujours possible** à pied (et par la Corde Sortie, §11).
- **Sombre mais jamais illisible** : on distingue les chemins **sans augmenter la luminosité du
  téléphone** (critère de validation S24).
- Pas de cycle jour/nuit à l'intérieur (comme les intérieurs) ; transitions de lumière
  progressives entre les étages.
- Budgets [D] : ≤ 3 000 nœuds par carte ; mémoire = carte + voisines (règle du J10) ; lumière
  surtout **peinte dans le décor**, quelques sources légères (rendu `mobile`).

## 6. Rencontres de grotte [V B-3, K26]

- **Nouvelle mécanique** : un **terrain de rencontre « gravats »** (sol de gravats, galeries plus
  sombres), à côté du terrain « herbes » existant ; les **couloirs calmes** n'ont aucune rencontre.
  Le joueur choisit son risque comme avec les herbes. Taux et rampe des herbes [D].
- **Introduction** (dossier 04, ≤ 2 s) : petit éboulis de gravats sous les pieds + son de pierres
  qui roulent, le héros se retourne, combat. Pas d'herbe agitée.
- Le compagnon ne déclenche aucune rencontre (J11).

| Espèce | 1F | B1F | B2F |
|---|---|---|---|
| Nosferapti | 8–10 (55) | 9–11 (50) | 10–12 (45) |
| Racaillou | 8–10 (30) | 9–11 (30) | 10–12 (30) |
| Paras | 8–10 (13) | 10–11 (16) | 10–12 (19) |
| Mélofée | 9 (2) | 10 (4) | 10–12 (6) |

Niveaux et poids [D] ; Mélofée « rare mais trouvable » [V-8]. **Aucun Racaillou sauvage ≥ Nv. 21**.

## 7. Ambiance

- **Route 3** : continuité des couleurs chaudes d'Argenta, grands ciels, herbes sèches qui se
  raréfient vers l'est, roche qui affleure.
- **Montagne** : ardoise, pierre froide, gris bleuté, touches de minéraux clairs (Pierre Lune).
- **Son** (intention) : vent sur la Route 3 ; dans la grotte, gouttes, échos, silence ; près des
  Rocket, bruits de chantier lointains (outils, caisses) qui grandissent.
- **Décors de combat** (CB.3) : **Route 3 rocheuse**, **galerie du Mont Sélénite**, variante
  **chambre des fossiles** pour le Rocket final et le chercheur.

## 8. La Team Rocket [V-4, V-5, B-7]

### 8.1 Direction (verrouillée)

Une organisation criminelle reconnaissable, plus crédible dans sa mise en scène : nom **« Team
Rocket »** prononcé, **uniforme sombre et R rouge** légèrement modernisés dans la main peinte du
jeu, ni soldats réalistes ni caricatures. Les membres **ont une mission** : surveiller les
passages, fouiller les galeries, sécuriser les fossiles. Dialogues courts, parfois arrogants,
**personnalités distinctes**, **aucun chef local**, aucune intrigue parallèle. On ne dévoile ni
Giovanni ni leurs projets : le joueur comprend seulement qu'il a contrarié une organisation qu'il
recroisera. Lien avec le J10 : la phrase des « collectionneurs de fossiles » du Musée d'Argenta
prend son sens ici, sans qu'aucun personnage ne la rappelle.

### 8.2 Avant le premier combat

- 1F : indices sans personnage (caisses marquées d'un R, lampe abandonnée, traces de fouille).
- 1F : un **randonneur** a vu « des gens en noir » plus bas (il ne sait que ce qu'il a vu).

### 8.3 Les trois combats

Classe affichée **« Sbire Rocket »** [D] ; base de récompense 30 (RB) [D] ; IA `random` pour les
deux premiers, **`smart`** pour le final [D] ; capacités apprises au niveau.

| | Rôle | Où | Inévitable | Équipe | ₽ |
|---|---|---|---|---|---|
| R1 | **Le guetteur** : surveille le bas d'une échelle | B1F | selon la grille [D : oui] | Rattata Nv. 11, Nosferapti Nv. 11 | 330 |
| R2 | **La fouilleuse** : occupée à creuser, ne lève la tête qu'au dernier moment | B1F | non | Abo Nv. 12, Sabelette Nv. 12 | 360 |
| R3 | **Le gardien** : sécurise l'accès à la chambre des fossiles | B2F | **oui** [V B-8] | Nosferapti Nv. 13, Abo Nv. 13, Rattatac Nv. 13 [D, T26 2026-10-14 : 15 → 13, Croc de Mort en IA `smart` faisait de R3 un mur] | 390 |

Modèles peints : **un homme, une femme** [D], réutilisés ; R3 se distingue par sa pose et sa place
(pas de tenue de chef).

### 8.4 Mise en scène

- R1 et R2 : déclenchement de Dresseur habituel (il te voit → « ! » → s'approche → quelques mots
  → combat). R1 ouvre par **« Hé, toi ! Ce passage est interdit. Fais demi-tour. »** [V-4].
- **R3, combat de conclusion** : courte scène avant le combat (3 bulles au plus), décor de combat
  « chambre des fossiles ». Pas de monologue sur les motivations.
- **Départ** [V B-7] : après sa défaite, chaque Sbire dit sa réplique, **s'éloigne de quelques cases
  et disparaît au fondu suivant** ; il n'est plus là quand on repasse [D : s'il ne peut pas marcher
  hors champ, il disparaît au prochain chargement de la carte]. Après R3, les **lampes et caisses
  restent** (traces), aucun Rocket ne revient au J12.
- Défaite du joueur contre un Rocket : réveil au dernier Centre (règle existante) ; le Rocket reste
  à sa place, réplique de reprise courte (§20).

## 9. Le chercheur et les fossiles [V-6, V-7, B-9]

- **Le chercheur** (« Chercheur Gaspard » [D, texte à valider]) : indépendant, il a découvert les
  fossiles et s'est retranché dans la chambre pendant la présence des Rocket. Il **garde le passage
  vers l'échelle de sortie** : combat **inévitable** [V B-8].
- **Ordre** [V B-9] : R3 vaincu et parti → le chercheur sort de l'ombre, **te prend pour un des
  leurs** (sa méfiance découle de la scène précédente) → combat → il reconnaît son erreur → partage.
- Équipe [V B-6, niveaux D] : **Voltorbe Nv. 12, Smogo Nv. 12** [D, T26 2026-10-14 : 13 → 12] ; IA `smart` ; base 25 → 300 ₽.
- **Choix du fossile** : les deux fossiles posés sur une dalle ; le joueur **interagit avec l'un** →
  « Prendre le Fossile Dôme ? » **OUI / NON** ; OUI → objet clé, toast, le chercheur prend l'autre.
  NON → rien, on peut regarder l'autre. **Définitif** [V-6] : aucun moyen d'obtenir le second dans
  une partie normale.
- Les fossiles vont dans les **objets clés** ; aucune indication sur leur résurrection [D] ;
  **Amonita et Kabuto non implémentés**.
- Défaite contre le chercheur : réveil au dernier Centre ; il reprend sa garde, réplique de reprise.
- Après le partage, le chercheur reste dans la chambre (une réplique) [D] : il se range en **(15, 30)**,
  tourné vers la dalle [D] ; case vérifiée le 2026-10-14 (grille et vraie scène) : elle ne coupe aucun
  passage — la salle de l'échelle de sortie reste reliée au reste de la grotte par le goulet
  (13..14, 31), juste au sud — et n'est ni sur un passage ni sur une case d'examen.
- **Grand moment** à l'obtention du fossile [C-6].

## 10. Pierre Lune et évolutions par pierre [V B-1, B-2 ; dossier 14 A-5]

- **Deux Pierres Lune** : une **visible** (détour du 1F ou de B1F), une **cachée** (B2F) [D pour
  les lieux]. **Pas en vente**.
- **Compatibles** (données RB) : Nidorina → Nidoqueen, Nidorino → Nidoking, Mélofée → Mélodelfe,
  Rondoudou → Grodoudou.
- **Parcours** (prévu au J11, reporté au J12) : Sac → **Pierre Lune** → l'équipe avec **COMPATIBLE /
  INCOMPATIBLE** (libellés des CT, J11) → **UTILISER** → séquence d'évolution courte du J11 → la
  pierre est consommée.
- **Pas d'ARRÊTER** pendant une évolution par pierre (RB : le joueur l'a choisie) [D] ; retour
  Android sans effet pendant la séquence. Les capacités apprises à l'évolution suivent la règle
  existante.
- Hors combat seulement ; catégorie du Sac **OBJETS** [D].

## 11. Corde Sortie [V B-4]

- **Effet** : ramène le joueur, après un fondu, **devant l'entrée extérieure du Mont Sélénite côté
  Route 3**, tourné vers le sud. **Ne soigne pas**, **ne change pas le point de repos**, consommée.
- **Utilisable** : dans les cartes **de grotte** (1F, B1F, B2F) seulement, **hors combat, hors
  cinématique**, depuis le Sac. Ailleurs : refus (§20). Utilisée depuis B2F après l'événement, elle
  ramène aussi côté Route 3 (jamais au sas de la Route 4) [D].
- **Prix et sources** : **550 ₽** (RB) à la **Boutique d'Argenta** (stock du J10 modifié) + **1 au
  sol au 1F** [D]. Pas de Boutique au Centre du pied de la montagne.
- **Vérification transport / sauvegarde** (demande de Kevin) : la Corde n'est qu'un changement de
  carte (`SceneRouter.change_map`, même chemin qu'une porte ou que le réveil au Centre, sans le
  soin) ; la position est enregistrée par les autosaves existants comme après une porte ; aucun
  champ de sauvegarde nouveau ; le compagnon réapparaît derrière le joueur (règle « après une
  téléportation » du J11). Un Dresseur battu reste battu, un objet ramassé reste ramassé.

## 12. Objets cachés [V B-10, K26 — mécanique nouvelle]

- Une case **signalée discrètement par le décor** (éclat minéral, caillou d'une autre teinte,
  touffe différente) ; **INTERAGIR face à elle** → l'objet est trouvé (texte de ramassage
  existant), toast. **Aucun indicateur d'interface**, aucun son avant la trouvaille.
- Mémoire : la liste existante des objets trouvés (`found_items`) [D].
- J12 : **3** (Route 3 : Réveil ; 1F : Réveil ; B2F : Pierre Lune) [D].

## 13. Compagnon dans la grotte [V B-11]

Vérification demandée par Kevin : le J11 distingue **carte d'extérieur** (compagnon visible) et
**carte d'intérieur** (`Map.interior` : il rentre dans sa Ball). Le J12 fixe :

| Carte | Catégorie | Compagnon |
|---|---|---|
| Route 3, sas de la Route 4 | extérieur | visible (J11) |
| Centre Pokémon | **bâtiment** (intérieur) | rentre dans sa Ball, ressort en sortant |
| Mont Sélénite 1F, B1F, B2F | **grotte** (catégorie nouvelle : ni bâtiment ni extérieur à ciel ouvert) | **visible**, comme en extérieur |

- **Passage trop étroit** : la règle J11 « aucune case libre pour un suivi propre → masqué jusqu'au
  premier pas qui libère une case » couvre les goulets et les culs-de-sac ; **aux échelles**, il
  rentre au fondu et réapparaît derrière le joueur à l'arrivée (comme une porte).
- La catégorie **grotte** sert aussi à : la Corde Sortie (§11), l'absence de jour/nuit (§5),
  les réactions du compagnon (une phrase « grotte », §20).
- Cinématiques Rocket / chercheur : il rentre au début, ressort à la fin (règle J11).

## 14. Sas de la Route 4 et frontière avec le J13 [V-9]

- **Sas** : petite carte extérieure [D : ≈ 24 × 14] au pied du versant est, en sortant de l'échelle
  de B2F : un chemin, un panneau, la vue sur la plaine ; **aucun Dresseur, aucune herbe, aucun
  objet** [D].
- **Raccord est** : « AZURIA — À venir » (mécanisme `show_coming_soon` des jalons précédents).
- **Retour** : par la grotte (l'échelle reste praticable dans les deux sens).
- *(2026-10-11 : la Route 4 du J13, qui prolonge ce sas, est décrite au dossier 16 §3.)*
- **Réservé au J13** (ne rien poser au J12) : la Route 4 proprement dite (rebords à sens unique,
  Dresseurs, herbes, objets), Azuria, Pont Pépite, rival n° 3. Le J13 pourra **remplacer** le sas
  par la vraie Route 4 en gardant son point d'arrivée.

## 15. Objectifs du tableau de bord

| Moment | Ligne |
|---|---|
| Après le badge (existant) | « continuer vers la Route 3. » |
| Première entrée sur la Route 3 | « traverser le Mont Sélénite. » |
| Arrivée dans le sas de la Route 4 | « continuer vers Azuria. » |

Mises à jour en silence (règle existante) [D, textes §20].

## 16. Espèces, capacités et assets (vérification demandée par Kevin)

### 16.1 Espèces nouvelles : **12**

| Espèce | Source au J12 | Pourquoi |
|---|---|---|
| Rondoudou | Route 3 | sauvage [B-5] |
| Grodoudou | Pierre Lune | évolution de Rondoudou [B-2] |
| Abo | Route 3, Rocket | sauvage [B-5] |
| Arbok | Abo Nv. 22 | évolution atteignable |
| Nosferapti | grotte, Rocket | sauvage |
| Nosferalto | Nosferapti Nv. 22 | évolution atteignable |
| Paras | grotte | sauvage |
| Parasect | Paras Nv. 24 | évolution atteignable |
| Mélofée | grotte (rare) | sauvage [V-8] |
| Mélodelfe | Pierre Lune | évolution de Mélofée [B-2] |
| Voltorbe | chercheur | Dresseur seulement (vu au Pokédex, pas d'évolution à fournir) |
| Smogo | chercheur | Dresseur seulement |

Existant réutilisé : Sabelette (sauvage pour la première fois), Racaillou (sauvage pour la
première fois), Rattata, Rattatac, Piafabec, Roucool, Nidoran ♀, Chenipan, Aspicot, Chrysacier,
Coconfort, Kakuna ; Nidoqueen et Nidoking (déjà dans les données, enfin atteignables).

Par espèce : données (statistiques, capacités apprises, taux de capture, compatibilités CT du
J11), entrée du Pokédex, **artwork officiel** (face en combat et Pokédex), **dos de combat** (même
traitement que les 40 espèces actuelles), décor de combat inchangé.

### 16.2 Capacités (vérification des dépendances J11)

Capacités que ces espèces apprennent **jusqu'au Nv. 30 environ** (RB) :

| Capacité | Qui (niveau) | Effet | État du moteur |
|---|---|---|---|
| Vampirisme | Nosferapti 1, Paras 20 | dégâts + rend ½ des dégâts infligés | **à créer** (drain d'attaque ; Vampigraine existe) |
| Ultrason | Nosferapti 10 | confusion | J11 (11A) |
| Onde Folie | Nosferapti 21 | confusion 100 % | J11 (11A) |
| Morsure | Nosferapti 15, Abo 17 | apeurement 30 % | J11 (11A) |
| Para-Spore | Paras 13 | paralysie | J11 (11A) |
| Spore | Paras 27 | sommeil 100 % | J11 (11A) ; donnée nouvelle |
| Berceuse | Rondoudou 1, Mélofée 13 | sommeil, précision 55 | J11 (11A) ; donnée nouvelle |
| Écras'Face | Rondoudou 9, Mélofée 1 | dégâts | donnée nouvelle |
| Torgnoles | Rondoudou 24, Mélofée 18 | 2 à 5 coups | J11 (11A) ; donnée nouvelle |
| Ligotage | Abo 1 | **piège** (reporté par le dossier 14) | **à créer** [C-1] |
| Regard Médusant | Abo 24, Arbok 27 | paralysie 100 % | J11 (11A) ; donnée nouvelle |
| Purédpois | Smogo 1 | poison 40 % | existant (poison) ; donnée nouvelle |
| Entrave | Rondoudou 14 | bloque une capacité adverse | **à créer** [C-2] |
| Repos | Rondoudou 29 | s'endort 2 tours, PV pleins | **à créer** [C-3] |
| Lilliput | Mélofée 24 | Esquive +1 | étages existants (esquive gérée) ; donnée nouvelle |
| Destruction | **Racaillou 21** (désormais capturable) | K.O. du lanceur | **à créer** (reporté par le dossier 14 « au J12 si ») [C-3] |
| Métronome | Mélofée 31 | capacité au hasard | **reportée** (hors de portée au J12) : donnée avec la mention « Sans effet dans le moteur actuel. » |

Voltorbe et Smogo du chercheur n'utilisent que Charge, Grincement et Purédpois.

### 16.3 Planches d'exploration (compagnon et décor)

Règle du J11 : **pas de FAIRE SORTIR sans planche repos + marche 4 directions**, aucun substitut.
Lot à décider en **C-4**.

### 16.4 Personnages et décors

- **Personnages peints** : Sbire Rocket ♂ et ♀, Chercheur, Fillette (nouvelle classe), voyageur et
  randonneuse / randonneur (réutiliser des modèles existants si possible) ; Gamin et Scout existent.
- **Décors de carte** : Route 3, Centre (réutilisé), Mont Sélénite (3 étages, kit de grotte), sas.
- **Décors de combat** : Route 3, galerie, chambre des fossiles.
- **Objets** : icônes Pierre Lune, Corde Sortie, Fossile Dôme, Fossile Nautile (+ CT si C-5).

## 17. Dépendances avec le J11 (vérification demandée par Kevin)

| Le J12 a besoin de | Livré par | Conséquence |
|---|---|---|
| Paralysie, sommeil, confusion, apeurement, multi-coups | **11A** | aucune espèce du J12 ne joue juste sans 11A |
| Séquence d'évolution courte | **11C** | évolution par pierre (§10) |
| Libellés COMPATIBLE / INCOMPATIBLE, catégorie CT du Sac | **11B** | parcours Pierre Lune, CT éventuelle (C-5) |
| Compagnon, catégories extérieur / intérieur, masquage | **11D** | catégorie « grotte » (§13), planches (C-4) |
| Sauvegarde : identifiant de Pokémon, compteur de sommeil | **11.0** (v6, après la v5 d'OUV) | Repos (C-3) s'appuie sur le compteur de sommeil |
| Remèdes Anti-Para, Réveil en vente | **11A** | objets de la Route 3 et de la grotte |
| **Créés par le J12** | — | drain d'attaque, piège (C-1), Entrave (C-2), Repos et Destruction (C-3), terrain « gravats », échelles, catégorie « grotte », Corde Sortie, objets cachés, évolution par objet |

Ordre de code : voir C-7.

## 18. Données et sauvegarde

- **Drapeaux** [D, noms indicatifs] : Dresseurs de la Route 3 et de la grotte battus (mécanisme
  existant), `mt_moon_rocket_1/2/3` (départ = Dresseur battu), `mt_moon_fossil_chosen`,
  `route_3_entered` (objectif), `route_4_reached` (objectif).
- **Objets** : Pierre Lune, Corde Sortie, fossile choisi (objet clé), objets cachés dans
  `found_items`.
- **Point de repos** : le Centre du Mont Sélénite (mécanisme existant).
- Quitter dans la grotte et reprendre : position, Dresseurs battus, objets, état de l'événement
  repris sans rien rejouer (V1 §8).
- **Version de sauvegarde** : a priori **aucune nouvelle version** (tout tient dans les drapeaux, le
  Sac et `found_items`) ; à confirmer au plan, après la v5 d'OUV et la v6 du J11.

## 19. Découpage et validation S24 [V B-14]

| Sous-jalon | Contenu | Validation S24 |
|---|---|---|
| **12.0** | Données des 12 espèces et des capacités ; moteur : drain, piège, Entrave, Repos, Destruction (selon C-1 à C-3) ; art (artworks, dos, planches C-4, personnages) ; vues générales peintes et grilles validées par Kevin | combats de test (carte de QA) |
| **12A** | Route 3, Centre, Dresseurs, rencontres, objets cachés | S24 |
| **12B** | Mont Sélénite 1F / B1F / B2F : échelles, terrain « gravats », lumière, catégorie « grotte », compagnon, Corde Sortie | S24 (lisibilité sans monter la luminosité) |
| **12C** | Team Rocket (3), chercheur, fossiles, Pierre Lune et évolution par pierre, Grand moment | S24 |
| **12D** | Sas de la Route 4, objectifs, QA finale Argenta → sas, retrait de la carte de QA | S24 |

Avant toute carte : **vue générale peinte** de la Route 3 et du Mont Sélénite + **grilles
`tools/plans/`** validées par Kevin (filière des J9 et J10). Les images de la V1 (sites tiers, fan
art) ne vont pas dans le dépôt.

## 20. Lot de textes — VALIDÉ par Kevin le 2026-10-11

Conventions des lots précédents : bulles de 2 lignes de ~40 caractères, `/` = bulle suivante,
`[e]` = forme au féminin du joueur.

### 20.1 Route 3
1. Voyageur (sortie d'Argenta) : « Le Mont Sélénite, là-bas. » / « On dit que des pierres sont tombées du ciel, autrefois. »
2. Randonneuse (pied de la montagne) : « Je reviens de la grotte. » / « Il fait noir, là-dedans. Garde tes Potions. »
3. Panneau ouest : « ROUTE 3 » / « Argenta ← → Mont Sélénite »
4. Panneau du Centre : « CENTRE POKÉMON » / « Mont Sélénite »
5. Gamin Hugo — avant : « Tu viens d'Argenta ? Montre-moi ton badge ! » · après : « D'accord… il est mérité. »
6. Fillette Léa — avant : « Mes Pokémon adorent cette route ! » · après : « On s'est bien amusés quand même. »
7. Scout Sacha — avant : « Mon filet est plein, mon équipe aussi ! » · après : « Je retourne chercher des insectes. »
8. Gamin Enzo — avant : « Un seul Pokémon, mais le meilleur ! » · après : « Il lui faut plus d'entraînement… »
9. Fillette Inès — avant : « Mon Rondoudou chante très bien, tu sais ! » · après : « Il chantera encore mieux la prochaine fois. »
10. Scout Nolan — avant : « Les insectes de la montagne sont coriaces ! » · après : « Les tiens aussi, apparemment. »

### 20.2 Centre et grotte
11. Toast : « Point de repos enregistré — Mont Sélénite » (format existant)
12. Panneau d'entrée (1F) : « MONT SÉLÉNITE » / « Galeries non éclairées. Prudence. »
13. Caisse marquée (1F) : « Une caisse marquée d'un R rouge. » / « Elle est vide. »
14. Lampe abandonnée (1F) : « Une lampe de chantier. Encore tiède. »
15. Randonneur (1F) : « Des gens en noir fouillent plus bas. » / « Je préfère ne pas savoir pourquoi. »

### 20.3 Team Rocket
16. R1, le guetteur — avant : « Hé, toi ! Ce passage est interdit. Fais demi-tour. » · défaite : « Tch… Je préviens les autres. » · reprise (après ta défaite) : « Encore toi ? Demi-tour. »
17. R2, la fouilleuse — avant : « Encore un curieux ? J'ai du travail. » · défaite : « Ces fossiles valent plus que ce combat. » · reprise : « Tu ne comprends pas quand on te dit non ? »
18. R3, le gardien — scène : « Les fossiles sont à nous. » / « La Team Rocket ne laisse rien derrière elle. » / « Et surtout pas un gamin[e] curieux[se]. » · défaite : « La Team Rocket n'oublie pas les visages. » · reprise : « Tu reviens perdre ? »
19. Nom affiché en combat : « Sbire Rocket »

### 20.4 Le chercheur et les fossiles
20. Avant : « Encore un de ces voleurs ?! » / « Ces fossiles, c'est moi qui les ai trouvés ! »
21. Défaite : « D'accord, d'accord ! Tu n'es pas avec eux. »
22. Partage : « Sans toi, ils les auraient emportés. » / « Un fossile chacun. Choisis. »
23. Confirmation : « Prendre le {fossil} ? » — OUI / NON
24. Après le choix : « Alors je garde celui-ci. » / « Prends-en soin. »
25. Reprise (après ta défaite) : « Tu es revenu[e] ? Tu ne les auras pas ! »
26. Ensuite : « Je vais les étudier de près. »
27. Toast : « {fossil} obtenu »
28. Fossile Dôme — description : « Fossile d'un Pokémon ancien à la carapace en dôme. »
29. Fossile Nautile — description : « Fossile d'un Pokémon ancien à la coquille en spirale. »
30. Grand moment [C-6] : « Mont Sélénite : la Team Rocket repoussée, {fossil} obtenu. »

### 20.5 Objets
31. Pierre Lune — description : « Une pierre étrange. Fait évoluer certains Pokémon. »
32. Corde Sortie — description : « Ramène à l'entrée de la grotte. »
33. Corde Sortie — utilisée : « Tu utilises la Corde Sortie. »
34. Corde Sortie — refus : « Impossible de l'utiliser ici. »
35. Pierre — bouton : « UTILISER » ; libellés « COMPATIBLE » / « INCOMPATIBLE » (J11)

### 20.6 Sas, objectifs, compagnon
36. Panneau du sas : « ROUTE 4 » / « Mont Sélénite ← → Azuria »
37. Raccord est : « AZURIA — À venir » (mécanisme existant, développement)
38. Objectif : « traverser le Mont Sélénite. »
39. Objectif : « continuer vers Azuria. »
40. Compagnon, phrase « grotte » : « {pokemon} écoute l'écho de ses pas. »

### 20.7 Capacités nouvelles (description)
41. Vampirisme : « Inflige des dégâts et rend la moitié des dégâts infligés. »
42. Ligotage : « Enserre l'ennemi plusieurs tours. Il ne peut pas fuir. »
43. Entrave : « Empêche l'ennemi d'utiliser sa dernière capacité quelques tours. »
44. Repos : « Le lanceur dort deux tours et récupère tous ses PV. »
45. Destruction : « Inflige de gros dégâts. Le lanceur est mis K.O. »
46. Messages de combat : drain « {pokemon} récupère des PV ! » · piège « {pokemon} est ligoté[e] ! » / « {pokemon} souffre du Ligotage ! » / « {pokemon} est libéré[e] ! » · Entrave « {move} de {pokemon} est bloquée ! » / « {move} n'est plus bloquée. » · Repos « {pokemon} s'endort et récupère ! »

Les noms d'espèces, de capacités et de Pokédex suivent la nomenclature française officielle ; les
descriptions de Pokédex des 12 espèces sont écrites au plan (même ton que les 40 existantes) et
relues avec ce lot.

## 21. Derniers arbitrages (C-1 à C-8) — toutes les recommandations retenues par Kevin le 2026-10-11

| N° | Question | Décision [V] |
|---|---|---|
| **C-1** | **Ligotage** (Abo Nv. 1, sauvage et Rocket) : le piège était reporté par le dossier 14. | **Le créer au J12** (G+ : 4–5 tours, 1/8 des PV par tour, ni fuite ni changement), ce qui débloque aussi Étreinte (Onix) et Danse Flamme. Sinon, Abo garde une capacité qui ne fait que des dégâts. |
| **C-2** | **Entrave** (Rondoudou Nv. 14, atteint vite) | **Oui**, règle G+ : la dernière capacité de la cible est bloquée **4 tours**. |
| **C-3** | **Repos** (Rondoudou 29) et **Destruction** (Racaillou 21, désormais capturable) | **Oui pour les deux** : simples une fois le sommeil du J11 en place ; tous deux atteignables pendant J12–J13. |
| **C-4** | **Planches d'exploration** du J12 (compagnon + décor) | **Rondoudou, Mélofée, Abo, Paras, Nosferapti (en vol), Racaillou (marche)**. Les recommandations du dossier 14 (Roucoups, Nidorino, Nidorina, Rattatac, Rapasdepic) en **lot parallèle**. Évolutions (Grodoudou, Nosferalto…) : plus tard. |
| **C-5** | **CT dans la grotte** (RB : CT12 Pistolet à O au 1F, CT01 Ultimapoing en B2F) | **Une seule : CT01 Ultimapoing** (dégâts simples), sur un détour de B2F — « objets rares ». |
| **C-6** | **Grand moment** à l'obtention du fossile | **Oui**, un seul (texte 30). |
| **C-7** | **Quand coder le J12** | **Après la clôture du J11** (un seul jalon à la fois dans le moteur de combat et la sauvegarde) ; la conception, les vues générales, les grilles et l'art peuvent avancer avant. |
| **C-8** | **Gaspard, Hugo, Léa, Sacha, Enzo, Inès, Nolan** | Prénoms par défaut, à valider avec le lot de textes. |

## 22. Valeurs par défaut (règle 4)

Enveloppes de cartes (Route 3 ≈ 82 × 38, 1F ≈ 68 × 54, B1F ≈ 44 × 36, B2F ≈ 56 × 42, sas ≈ 24 × 14) ;
taux et rampe de rencontre des herbes pour les gravats ; niveaux et poids des tables §3.3 et §6 ;
récompenses (Gamin et Fillette 15, Sbire 30, Chercheur 25 × niveau) ; IA `smart` pour R3 et le
chercheur ; Corde Sortie 550 ₽ à Argenta + 1 au 1F ; Pierre Lune sans ARRÊTER ; catégorie OBJETS ;
modèles Rocket ♂ et ♀ ; départ des Rocket au fondu ; Centre sans Boutique ; sas sans contenu ;
emplacements des objets.

## Décisions verrouillées

| Élément | Décision |
|---|---|
| Périmètre | Route 3 + Centre + Mont Sélénite (3 niveaux) + sas Route 4 ; Azuria, Route 4, rival n° 3 au J13 |
| Team Rocket | Première apparition ici ; 3 combats ; nom, uniforme sombre, R rouge ; mission (fossiles) ; aucun chef ; partent après leur défaite |
| Fossiles | Un seul, choix définitif, objet clé ; résurrection bien plus tard |
| Chercheur | Combat inévitable après le Rocket final, puis partage |
| Rencontres de grotte | Terrain « gravats », couloirs calmes |
| Pierre Lune | 1 visible + 1 cachée ; évolutions par pierre au J12 ; Grodoudou et Mélodelfe inclus |
| Corde Sortie | Entrée extérieure du Mont Sélénite ; ne soigne pas ; point de repos inchangé |
| Repousse, Magicarpe | Reportés |
| Compagnon | Visible dans la grotte, masqué dans les goulets, Ball au Centre |
| Rival | Absent, sans allusion |
| Navigation | Ni mini-carte, ni GPS, ni flèche ; aucune capacité d'exploration requise |
| Capacités | Piège (Ligotage, Étreinte, Danse Flamme), Entrave 4 tours, Repos, Destruction, drain créés au J12 ; Métronome reportée |
| Planches J12 | Rondoudou, Mélofée, Abo, Paras, Nosferapti (vol), Racaillou (marche) ; Roucoups, Nidorino, Nidorina, Rattatac, Rapasdepic en lot parallèle |
| CT | CT01 Ultimapoing sur un détour de B2F, seule CT du J12 |
| Grand moment | Un seul, à l'obtention du fossile |
| Calendrier | Code après la clôture du J11 ; conception, vues générales, grilles et art avant |
| Prénoms | Gaspard, Hugo, Léa, Sacha, Enzo, Inès, Nolan |
| Textes | Lot §20 validé (46 entrées) |
| Validation | 12.0 → 12A → 12B → 12C → 12D |
