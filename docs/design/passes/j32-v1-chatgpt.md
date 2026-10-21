# Kanto 2026 — J32 : Un Kanto complet et vivant

> Dossier de conception consolidé V1 (ChatGPT), transmis par Kevin le 2026-10-19, **avant le
> lancement du J32** (conception en avance, `strategie-acceleration.md` levier 2). 7 arbitrages
> verrouillés. Les images et la maquette chiffrée de la passe d'origine ne sont pas reprises. Notes
> de la session de coordination à la fin.

Après les Arènes, la Ligue et Mewtwo, la priorité change : plus de nouvelles régions ni de nouvelle
campagne, mais un Kanto **cohérent, complet et durablement rejouable**. Un joueur doit pouvoir finir
l'aventure, compléter les 151 entrées du Pokédex et continuer à explorer sans blocage artificiel.

## 1. Les sept arbitrages définitifs

| Sujet | Décision verrouillée |
|---|---|
| Périmètre | Post-game libre : collection, secrets, revisites et rejouabilité |
| Pokédex | Audit et complétion des 151 espèces de la première génération |
| Évolutions | Solution locale cohérente pour les évolutions historiquement liées aux échanges |
| Activités | Ligue, Safari, pêche, captures et revisites rejouables |
| Secrets | Audit exhaustif des objets, capacités, rencontres et secrets historiques |
| Qualité de vie | Amélioration du Pokédex, du stockage et du suivi de collection |
| Fin | Kanto libre, collection réalisable et préparation du J33 |

Le J32 n'ajoute ni campagne scénarisée, ni nouvelles régions, ni nouvelles générations, ni
marqueurs d'objectif permanents.

## 2. Architecture fonctionnelle

Kanto post-game (monde libre après la Ligue), avec six chantiers : **Pokédex** (151 espèces et
provenance), **Évolutions** (échanges adaptés au solo), **Rejouabilité** (Ligue, Safari, pêche),
**Secrets** (objets et rencontres), **Stockage** (gestion de collection), **Persistance** (aucune
perte de progression).

## 3. Le Pokédex : les 151 Pokémon

Chaque espèce a ses données, son comportement de capture ou d'évolution, et **au moins une voie
d'obtention réellement fonctionnelle**.

| Domaine | Exigence |
|---|---|
| Identité | Numéro national 001–151, nom français, identifiant stable |
| Combat | Types, statistiques, capacités et progression |
| Évolution | Niveau, pierre, échange adapté ou absence d'évolution |
| Rencontre | Zone, méthode, niveau et fréquence |
| Collection | Vu, capturé, forme enregistrée dans le Pokédex |
| Présentation | Sprite, fiche et informations disponibles |
| Stockage | Pokémon conservé avec ses données individuelles |
| Sauvegarde | Capture et évolution persistantes |

Les 151 entrées comprennent Mew, ce qui n'implique pas une rencontre sauvage classique : Mew est
historiquement événementiel et demande une décision dédiée.

**Catégories d'obtention** (chaque espèce dans au moins une) : capture sauvage, pêche ou Safari ;
évolution par niveau, pierre ou autre condition ; cadeau, fossile ou échange PNJ ; légendaire
unique ; exclusivité de version Rouge/Bleu ; Pokémon événementiel.

Pour les exclusivités Rouge/Bleu : une voie d'obtention cohérente dans notre version unique, sans
obliger à posséder deux jeux. **Le Pokédex n'est pas déclaré complétable tant qu'une espèce n'a pas
de voie d'obtention testée de bout en bout.**

## 4. Évolutions historiquement liées aux échanges

| Pokémon initial | Évolution |
|---|---|
| Kadabra | Alakazam |
| Machopeur | Mackogneur |
| Gravalanch | Grolem |
| Spectrum | Ectoplasma |

**Proposition technique (pas un huitième arbitrage)** : garder le principe de l'échange via une
simulation locale intégrée au monde, par exemple un terminal d'échange dans un Centre Pokémon. Le
joueur choisit un Pokémon compatible, confirme, puis récupère **le même individu** évolué (surnom,
identifiant, statistiques individuelles et historique conservés). Ni Internet, ni second appareil,
ni perte du Pokémon. Claude vérifie d'abord les mécanismes existants pour proposer l'intégration la
moins intrusive.

## 5. Complétion de la collection : les autres obstacles

| Cas | Risque | Solution à étudier |
|---|---|---|
| Starters | Deux starters non choisis | Voie d'obtention post-game |
| Fossiles | Choix initial exclusif | Obtention différée de l'autre fossile |
| Kicklee / Tygnon | Choix unique au Dojo | Accès ultérieur à l'autre |
| Exclusivités Rouge/Bleu | Espèces absentes d'une version | Répartition dans le monde unique |
| Échanges PNJ | Pokémon donnés définitivement | Préserver les conditions et données |
| Légendaires | Rencontre consommée | Politique cohérente de capture unique |
| Mew | Distribution événementielle historique | Arbitrage dédié avant toute implémentation |

Le J25 a verrouillé les fossiles à remise unique et le J27 le choix unique du Dojo : **ne pas les
annuler rétroactivement**. Une solution post-game préserve le sens de la première récompense tout
en ouvrant une autre voie, si elle est validée. Distinguer « 151 espèces dans le Pokédex » et
« 151 espèces capturables dans une partie solo » : le J32 vise la seconde.

## 6. Rejouabilité

Gérée **par activité**, sans réinitialisation globale du monde.

| Activité | Rejouable ? | Éléments persistants |
|---|---|---|
| Ligue Pokémon | Oui | Panthéon, première victoire, historique |
| Safari | Oui | Pokémon capturés, objets uniques récupérés |
| Pêche | Oui | Pokédex et captures |
| Rencontres sauvages | Oui | Pokémon capturés et progression |
| Exploration des routes | Oui | Objets ramassés, Dresseurs vaincus |
| Grotte Inconnue | Oui | Mewtwo et objets uniques |
| Arènes | Visites libres | Badges et victoires définitifs |
| Échanges PNJ | Selon le contrat historique | Transactions déjà réalisées |

**Ligue rejouable** : retour au Plateau Indigo, soins, cinq combats. Chaque victoire crée une entrée
au Panthéon, sans réinitialiser le post-game ni les légendaires. Les Dresseurs ordinaires **ne
deviennent pas** rejouables : ce serait une nouvelle mécanique, à arbitrer séparément.

## 7. Audit des secrets et objets

Toutes les cartes, du Bourg Palette à la Grotte Inconnue.

| Catégorie | Contrôle |
|---|---|
| Objets visibles | Position, interaction, quantité, persistance |
| Objets cachés | Position historique et méthode de découverte |
| CT et CS | Obtention, possession, utilisation |
| Pierres évolutives | Disponibilité suffisante |
| Fossiles | Obtention, remise et résurrection |
| Cadeaux | Remise unique, stockage si équipe pleine |
| Échanges PNJ | Conditions et récompenses |
| Pêche | Canne, zone, table de rencontres |
| Safari | Pas, Safari Balls, appâts, cailloux et espèces |
| Pokémon uniques | Capture, K.O., fuite et sauvegarde |
| Éléments de décor | Collisions, interactions et transitions |

Objets cachés découvrables sans minimap ni marqueurs ; vérifier le système de recherche et les
indices environnementaux existants.

## 8. Qualité de vie : Pokédex et stockage

- **Pokédex** : distinguer clairement vus et capturés, retrouver une espèce par numéro ou nom,
  consulter les informations déjà découvertes ; tableau de bord (espèces, vues, capturées,
  progression).
- **Stockage** : rechercher, trier et déplacer sans risque de perte, en conservant les
  caractéristiques individuelles.
- Adapté au Galaxy S24 : grandes zones de contact, lisibilité, navigation courte.
- **Aucun guidage intrusif** : pas de flèche vers les espèces manquantes, pas de minimap, pas de
  localisation exacte d'un Pokémon jamais rencontré. La provenance se révèle progressivement selon
  ce que le joueur a découvert.

## 9. Dépendances J16–J31 → J32

| Dépendance | Origine | Vérification de conception |
|---|---|---|
| Pokédex et captures | Moteur initial | 151 identifiants et enregistrements |
| Évolutions | Moteur initial | Niveau, pierres et échanges |
| Modèle hybride des CS | J16 | Aucun changement des prérequis |
| Pêche et Safari | J22–J23 | Activités rejouables |
| Artikodin | J24 | Rencontre unique préservée |
| Fossiles et échanges PNJ | J25 | Pas de duplication des récompenses |
| Master Ball | J26 | Objet unique, jamais réattribué |
| Dojo | J27 | Choix initial préservé |
| Badges | J28 | Huit Badges persistants |
| Sulfura | J29 | Rencontre unique préservée |
| Ligue et Panthéon | J30 | Rejouabilité et historique |
| Mewtwo | J31 | Capture unique et accès post-Ligue |

**Risques critiques** :

- **Collection impossible** : une espèce existe dans les données sans action réelle pour l'obtenir.
  Tester les voies d'obtention, pas seulement compter les entrées.
- **Duplication ou perte de Pokémon** : échange local, évolution et transfert au stockage sont
  atomiques (tout réussit, ou rien ne change).
- **Sauvegardes anciennes** : les nouvelles informations de collection s'ajoutent sans effacer
  Pokémon, objets, Badges et événements.

**Matrice de validation** : une sauvegarde ancienne se charge après le J32 ; les 151 espèces ont des
données cohérentes et un statut d'obtention documenté ; les quatre évolutions par échange se font
localement ; une équipe pleine ne provoque aucune perte (cadeau, échange) ; les objets uniques ne
réapparaissent pas ; la Ligue se gagne plusieurs fois ; les entrées du Panthéon ne s'écrasent pas ;
pêche et Safari fonctionnent ; la collection ne dépend ni d'un second téléphone ni d'un serveur ; le
jeu reste utilisable sur Galaxy S24 avec un stockage très rempli. Mew et les récompenses exclusives
sont résolus avant de certifier la complétion intégrale.

## 10. Découpage technique

| Lot | Livrable |
|---|---|
| 32.0 | Audit transversal du dépôt, des 151 espèces et des sauvegardes |
| 32A | Catalogue Pokédex, espèces manquantes et voies d'obtention |
| 32B | Évolutions par échange et solutions de collection solo |
| 32C | Rejouabilité : Ligue, Safari, pêche et revisites |
| 32D | Audit des secrets, objets, CT, CS et rencontres |
| 32E | UX Pokédex, stockage et suivi de collection |
| 32F | Tests de complétion, migrations, performances et QA |

**« J32 terminé »** : la collection est techniquement réalisable dans une seule sauvegarde, les
activités principales restent rejouables, et le joueur gère ses Pokémon sans perdre sa progression.
Cela suppose de résoudre les exceptions historiques : Mew, starters, fossiles, cadeaux exclusifs.

## 11. Prompt de transmission à Claude (au lancement du J32)

> **Kanto 2026 — J32 : complétion et rejouabilité.** Prépare le J32 : post-game libre, collection des
> 151 Pokémon, secrets historiques et qualité de vie.
>
> **Arbitrages verrouillés** (ne pas les rouvrir) : 1. Post-game libre : collection, secrets,
> revisites et rejouabilité. 2. Audit et complétion des 151 entrées de la première génération.
> 3. Solution locale cohérente pour les évolutions historiquement liées aux échanges. 4. Ligue
> rejouable, Safari, pêche, captures et revisites. 5. Audit exhaustif des objets, capacités,
> rencontres et secrets historiques. 6. Amélioration du Pokédex, du stockage et du suivi de
> collection, sans guidage intrusif. 7. Kanto libre, collection réalisable, puis J33 de finition
> globale.
>
> **Audit réel du dépôt** : code Godot, données Pokémon, scènes, cartes, évolutions, sauvegardes,
> stockage, combat. Classer chaque fonctionnalité : implémentée et vérifiée ; présente mais
> incomplète ; seulement spécifiée ; absente. N'inventer ni fichiers ni résultats de tests.
>
> **Pokédex** : matrice des 151 espèces (numéro, nom, types, données de combat ; évolutions et
> conditions ; voies d'obtention réellement disponibles ; zones, méthodes, niveaux, taux ; captures
> uniques, cadeaux, fossiles, échanges PNJ ; exclusivités Rouge/Bleu ; cas de Mew ; statut
> d'implémentation et tests manquants). Prouver ou réfuter la complétion des 151 dans une seule
> sauvegarde solo. Traiter starters non choisis, deux fossiles, Kicklee/Tygnon, exclusivités et
> événementiels. Ne pas modifier les récompenses uniques du J25/J27 sans solution post-game
> compatible explicite.
>
> **Évolutions par échange** : Kadabra → Alakazam, Machopeur → Mackogneur, Gravalanch → Grolem,
> Spectrum → Ectoplasma. Solution locale sans réseau, de préférence sur les mécanismes existants,
> avec intégrité des Pokémon et sécurité transactionnelle.
>
> **Rejouabilité** : Ligue et Panthéon (J30), Safari et pêche (J22/J23), légendaires (J24/J29/J31),
> revisites ; distinguer le répétable et le consommé définitivement.
>
> **Secrets et qualité de vie** : inventaire des objets visibles et cachés, CT/CS, pierres, cadeaux,
> fossiles, échanges, rencontres ; améliorations du Pokédex et du stockage pour Galaxy S24, sans
> minimap ni flèches d'objectif ; DA 2D HD peinte, orthogonale, sans pixel art.
>
> **Livrables** : 1. Rapport d'audit. 2. Matrice des 151 espèces et voies d'obtention. 3. Obstacles à
> la collection complète. 4. Proposition d'évolution locale. 5. Contrats de rejouabilité.
> 6. Inventaire des objets et secrets. 7. UX Pokédex et stockage. 8. Persistance et migrations.
> 9. Lots 32.0 à 32F. 10. Tests automatisés, tests de complétion et QA Galaxy S24. 11. Risques,
> dépendances et arbitrages résiduels. Séparer fidélité Rouge/Bleu, adaptations Kanto 2026 et faits
> vérifiés dans le dépôt.
>
> Conception et audit uniquement. Ne rien coder avant validation. Transmission exploitable, avec
> chemins de fichiers réels.

---

## Notes de la session de coordination (2026-10-19), pour l'audit 32.0

- **Évolution par échange** : le format existe déjà. `game/pokemon/evolution/evolution_rule.gd`
  connaît la méthode `trade` (`Method.TRADE`), et Gravalanch → Grolem est déjà déclaré ainsi dans
  `data/pokemon/species/kanto.json`. Mais le fichier précise qu'**aucune logique de jeu ne déclenche
  encore** ces évolutions. Le terminal d'échange du §4 n'aurait qu'à appeler ce chemin.
- **Échanges PNJ** : `InGameTrade` (logique pure, branche `jalon-25`) existe déjà ; le terminal
  local peut s'en inspirer ou s'appuyer dessus, après la fusion du J25.
- **Espèces** : environ **72** espèces sont déclarées sur `main` aujourd'hui ; les autres arrivent
  jalon par jalon (J19 à J31). La matrice des 151 du lot 32A sera donc à refaire sur le `main` de ce
  moment-là.
- **Arbitrages résiduels** que le dossier annonce lui-même et qui reviendront à Kevin : Mew ; les
  deux starters non choisis ; le second fossile ; l'autre Pokémon du Dojo ; la répartition des
  exclusivités Rouge/Bleu ; Dresseurs rejouables (hors périmètre sauf nouvel arbitrage).
