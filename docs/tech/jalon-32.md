# Jalon 32 — Un Kanto complet et vivant

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j32-v1-chatgpt.md` (7 arbitrages verrouillés). Arbitrages et textes
> recommandés **validés par Kevin le 2026-10-21 (validation d'avance des textes recommandés)**.
> Texte manquant : proposition marquée **[D]**.

> Objectif jouable : **on peut finir le Pokédex dans une seule sauvegarde solo, échanger
> localement pour faire évoluer Kadabra, Machopeur, Gravalanch et Spectrum, rejouer la Ligue, le
> Safari et la pêche, et gérer ses Pokémon sans rien perdre.** Pas de nouvelle région, pas de
> campagne, pas de marqueur d'objectif.
>
> Mécaniques nouvelles : la **matrice d'obtention** des 151 espèces, le **terminal d'échange
> local**, le **suivi de collection** (Pokédex et stockage). Format de sauvegarde : champs
> ajoutés avec valeur par défaut (§2.4) ; un incrément de version se valide seul.

## 0. État et dépendances (relu sur le dépôt)

| Point | Réel aujourd'hui | Conséquence |
|---|---|---|
| Évolution par échange | `game/pokemon/evolution/evolution_rule.gd` connaît `Method.TRADE` ; Gravalanch → Grolem déclaré dans `data/pokemon/species/kanto.json` ; **aucune logique ne le déclenche** | Le terminal appelle ce chemin (T4) |
| Échanges PNJ | `InGameTrade` (logique pure) sur la branche `jalon-25` | S'en inspirer après la fusion du J25 |
| Espèces | Environ la moitié des 151 en données sur `main` ; le reste arrive jalon par jalon | La matrice se refait sur le `main` du moment (T1) |
| Pokédex et stockage | Écrans existants (`docs/tech/pokedex-refonte.md`) ; départs de débogage `storage_qa.json`, `team_full.json` | UX en retouche, pas en refonte |
| Fossiles, Dojo | Remise unique (J25), choix unique (J27) : **non annulés** | Solutions post-game compatibles seulement |
| Safari, pêche | J22–J23 | Contrôle de rejouabilité |
| Sauvegarde | `SaveSystem.VERSION = 7`, atomique | Nouveaux champs par `JsonFields.get_*` avec défaut |

### 0.1 Ce qui peut commencer tout de suite
- **T1** matrice des 151 (outil de lecture des données) et audit 32.0 ;
- **T2** règles d'obtention et d'échange en **logique pure** ;
- **T4** terminal d'échange en logique pure (sans écran) ;
- **T6** inventaire des objets et secrets (lecture des cartes et des données déjà fusionnées).

### 0.2 Ce qui attend
- Espèces des jalons non fusionnés (J21 à J31) : la matrice reste « à compléter ».
- Écran du terminal et UX Pokédex/stockage (T5, T7) : après la clôture de la passe systèmes 2.
- Solutions starters, fossiles, Dojo, Mew : décisions de Kevin prises le 2026-10-22 (§7) ; reste à les concevoir en détail (T3).

## 1. Contrats

### 1.1 Une voie d'obtention testée par espèce
Chaque espèce a **au moins une** voie, **testée de bout en bout** (capture, évolution, cadeau,
fossile, échange PNJ, légendaire unique, exclusivité répartie, événement). Le Pokédex n'est pas
déclaré complétable tant qu'une espèce n'a pas sa voie testée. Distinction nette : « 151 dans le
Pokédex » et « 151 capturables en solo » ; le J32 vise la seconde.

### 1.2 Échange local atomique
Choix d'un Pokémon compatible, confirmation, puis **le même individu** évolué (surnom,
identifiant, statistiques individuelles, historique conservés). Tout réussit ou rien ne change.
Ni réseau, ni second appareil.

### 1.3 Rejouabilité par activité
Ligue : retour au Plateau, soins, cinq combats, une entrée de Panthéon par victoire, aucun reset du
post-game ni des légendaires. Safari et pêche rejouables. Dresseurs ordinaires **non rejouables**
(nouvelle mécanique, hors périmètre). Les objets uniques ne reviennent jamais.

### 1.4 Pas de guidage
Ni flèche vers une espèce manquante, ni minimap, ni localisation d'un Pokémon jamais rencontré. La
provenance se révèle selon ce que le joueur a découvert.

## 2. Tâches

### T1 — Audit 32.0 et matrice des 151 (Sonnet)
`tools/audit_pokedex.py` (lecture seule) lit `data/pokemon/species/`, `data/encounters/`,
`data/pokemon/starters.json` et produit un CSV : numéro, nom, types, évolution, voies d'obtention
trouvées, statut. Sortie en `build/` (non suivie). Critère : une ligne par numéro 001–151, les
espèces manquantes listées, les espèces sans voie signalées.

### T2 — Règles d'obtention (Opus, logique pure)
`CollectionRules` : pour chaque espèce, voies et conditions ; vérification « au moins une voie ».
Tests : le test lit la matrice et échoue si une espèce **déclarée comme obtenable** n'a pas de voie.

### T3 — Obstacles de collection (Opus)
**Décision de Kevin (2026-10-22) : tout est obtenable dans une seule partie, sans échange avec un
autre joueur.** Une solution par cas, sans annuler la première récompense (J25, J27) :
- **Mew** : obtenable en solo par un événement narratif (voie dédiée, une seule fois, persistée) ;
  la voie exacte est à fixer et à tester par T1/T2 (jamais d'objet ni de cadeau perdu en cas de
  fuite ou de défaite).
- **Starters non choisis** : voie post-game sans échange avec un joueur, par un échange PNJ
  (Bourg Palette) ou un cadeau unique ; les deux Pokémon manquants sont tous les deux accessibles.
- **Second fossile** : l'autre fossile se récupère après le premier choix (machine de
  Cramois'Île, une seule fois), sans annuler la première remise du J25.
- **Autre Pokémon du Dojo** : le second Pokémon du Dojo est accessible en récompense de revisite,
  sans annuler le choix unique du J27.
- **Exclusivités Rouge/Bleu** : chaque exclusivité de version est répartie dans le monde (capture
  sauvage, échange PNJ, cadeau ou évolution) ; la liste vient de T1 et chaque entrée a une voie
  testée de bout en bout.
Chaque voie est ajoutée à la matrice de T1 et vérifiée par T2.

### T4 — Échange local, logique (Opus)
`LocalTrade` : liste des Pokémon compatibles (Kadabra, Machopeur, Gravalanch, Spectrum), évolution
via `EvolutionRule` méthode `TRADE`, opération atomique (copie de travail validée, puis remplacement).
Tests : individu identique (surnom, IV, EV, PP, statut) ; équipe pleine sans perte ; interruption
simulée au milieu : état d'origine intact ; Pokémon incompatible refusé.

### T5 — Échange local, écran (après passe systèmes 2)
Terminal dans un Centre Pokémon (4 cases tactiles minimum, lisible au S24).

### T6 — Audit des secrets et objets (Sonnet)
Tableau par carte : objets visibles et cachés, CT/CS, pierres, cadeaux, échanges, pêche, Safari.
Source : données et cartes déjà fusionnées ; référence Rouge/Bleu. Les écarts vont dans un registre
`P0–P3`, sans correction de masse.

### T7 — UX Pokédex et stockage
Vus / capturés distincts, recherche par numéro et par nom, tableau de bord (espèces, vues,
capturées). Stockage : recherche, tri, déplacement sans risque. Grandes zones de contact.

### T8 — Rejouabilité (Sonnet)
Contrôle de la Ligue (J30), du Safari et de la pêche : aucun drapeau consommé à tort.

### T9 — Tests de complétion, migrations, performances, QA S24
Test « complétion » en suite complète ; ancienne sauvegarde chargée ; stockage très rempli
(mesure de la durée d'ouverture sur S24).

## 3. Textes
Validés par Kevin le 2026-10-21 : mise en scène du terminal sans texte long, deux lignes de
40 caractères au plus. Propositions **[D]** :
- Terminal : « Choisis un Pokémon à échanger. » ; confirmation : « Échanger [nom] ? » ;
  résultat : « [nom] a évolué ! » [D]
- Aucun texte pour les cartes de Pokédex : la fiche existante suffit. [D]

## 4. Critères d'acceptation
1. `audit_pokedex.py` liste 151 lignes ; aucune espèce « obtenable » sans voie testée.
2. Les 4 évolutions par échange se font localement, individu conservé, sans perte.
3. Ligue gagnée plusieurs fois, Panthéon sans écrasement ; Safari et pêche rejouables.
4. Ancienne sauvegarde v7 chargée ; collection non dépendante d'un second appareil.
5. Suite complète verte.

## 5. QA téléphone (S24)
Échange complet d'un Kadabra ; équipe pleine ; recherche dans un Pokédex bien rempli ; stockage
rempli ; une Ligue rejouée ; appli tuée au milieu d'un échange (état d'origine ou fini, jamais
entre les deux).

## 6. Risques
Duplication ou perte au transfert ; espèce déclarée mais inobtenable ; sauvegarde ancienne
écrasée ; confusion entre les voies « sauvages » et les exclusivités.

## 7. Décisions de Kevin (2026-10-22)
**Tout est obtenable dans une seule partie** (aucun échange avec un autre joueur) :
1. **Mew** : obtenable en solo par un événement narratif (voie à fixer au T3).
2. **Starters non choisis** : obtenus par une voie post-game (échange PNJ à Bourg Palette ou
   cadeau), sans second appareil.
3. **Second fossile** : machine de Cramois'Île, une seule fois.
4. **Autre Pokémon du Dojo** : récompense de revisite.
5. **Exclusivités Rouge/Bleu** : réparties dans le monde (liste proposée par T1), chacune avec une
   voie testée.
6. Terminal d'échange local : dans tous les Centres Pokémon (évolutions par échange seulement ;
   il n'est jamais nécessaire pour compléter le Pokédex en dehors de ces 4 évolutions).
