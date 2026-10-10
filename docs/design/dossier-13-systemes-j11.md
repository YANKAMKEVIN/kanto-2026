# Dossier 13 — Grande passe de systèmes (jalon 11)

> V1 de ChatGPT reçue le 2026-10-10 (prompt `prompts/chatgpt-dossier-13-systemes-j11.md`), **8 décisions
> créatives verrouillées par Kevin** (§1). Passe d'alignement de Claude le 2026-10-10 contre `main`
> (`990fedb`), la roadmap et les dossiers 02, 04, 05, 08, 09, 10, 12. **Statut : arbitrages A-1 à A-14
> (§12) et lot de textes (§13) en attente de Kevin.** Aucun code avant leur validation ; plan technique
> `docs/tech/jalon-11.md` ensuite. Numérotation : dossier 13 = jalon 11 (le numéro de dossier suit
> l'ordre de conception, pas celui des jalons).
>
> Légende : **[V]** décision validée par Kevin · **[R]** recommandation de Claude à trancher (§12) ·
> **[D]** valeur par défaut technique (règle 4 de `CLAUDE.md`, notée et modifiable sans rouvrir la
> conception).

## 1. Décisions verrouillées

| N° | Décision | Statut |
|---|---|---|
| 1 | Pierre remet la **CT34 — Patience** | [V] |
| 2 | Les CT sont **réutilisables sans limite** (objet permanent du Sac) | [V] |
| 3 | Statuts : **règles modernes simplifiées** (§3) | [V] |
| 4 | Compagnon **libre** parmi les espèces qui ont un asset d'exploration validé | [V] |
| 5 | Le compagnon **rentre dans sa Poké Ball dans les bâtiments** | [V] |
| 6 | **Trois réactions** : curiosité, repos, enthousiasme | [V] |
| 7 | Évolution : **cinématique courte** (5–7 s, accélérable, ARRÊTER conservé) | [V] |
| 8 | **Route 3 hors du J11** (dossier géographique séparé, J12) | [V] |

Les quatre « finitions » proposées par ChatGPT (compagnon K.O., zones étroites, Patience et dégâts
indirects, compteurs de sommeil et de gel) sont reprises comme **A-1** (§12) : Claude les recommande
telles quelles.

## 2. Périmètre

**Dans le J11** : statuts majeurs complets (§3) ; confusion **[R A-2]** ; effets secondaires simples
en attente **[R A-3]** (§4) ; remèdes (§5) ; CT, Sac et CT34 Patience (§6) ; évolution courte (§7) ;
compagnon (§8) ; sauvegarde (§9).

**Hors du J11** (sauf avis contraire de Kevin) :
- Route 3, Mont Sélénite, toute zone nouvelle [V 8] ; aucune espèce nouvelle.
- **IA qui change de Pokémon** et **Hurlement** **[R A-4]** : le changement de Pokémon du joueur
  (volontaire et après un K.O.) **existe déjà depuis le J7** ; la ligne « changement de Pokémon en
  combat » de la roadmap est donc faite côté joueur. L'IA qui change arrive avec les « Dresseurs
  expérimentés » (dossier 05 §19), au plus tôt au J12.
- **Évolutions par pierre** **[R A-5]** : aucune pierre n'est trouvable dans les lieux existants ; le
  parcours Sac → pierre → Pokémon arrive avec la Pierre Lune (Mont Sélénite, J12).
- Effets lourds : deux tours (Lance-Soleil, Coud'Krâne), piège (Danse Flamme, Ligotage), Frénésie,
  Mimique, Mania, Empal'Korne (§4). Tous appris au niveau 21 ou plus par les espèces actuelles.
- Réorganiser les capacités hors combat, Maître des capacités, Total Soin, CT de Boutique.
- **Dos peints du joueur en combat** **[R A-6]** : chantier d'art (série de dos, `fiches-assets/
  serie-combat-dos-pilote.md`), suivi à part, pas un critère de fin du J11.
- Humeur / amitié du compagnon : **aucun système caché** [V, V1 §4].

## 3. Statuts

### 3.1 Règles [V 3, détails D]

| Statut | Abrév. | En combat | Immunité | Capture |
|---|---|---|---|---|
| Poison | PSN | **inchangé depuis le J9** : 1/8 des PV max en fin de tour (au moins 1) | Poison (et Acier) | ×1,5 (existant) |
| Brûlure | BRÛ | 1/16 des PV max en fin de tour (au moins 1) ; dégâts **physiques** infligés ÷ 2 | Feu [D] | ×1,5 [D] |
| Paralysie | PAR | Vitesse ÷ 2 (ordre d'action compris) ; 25 % de chance de ne pas agir, chaque tour | Électrik [D] | ×1,5 [D] |
| Sommeil | SOM | 1 à 3 tours tirés à l'application ; le compteur baisse à chaque tentative d'agir ; **au réveil, le Pokémon agit dans le même tour** [D, moderne] | aucune | ×2,5 [D] |
| Gel | GEL | ne peut pas agir ; 20 % de dégel à chaque tentative d'agir ; **dégelé s'il est touché par une capacité Feu** [D, moderne] | Glace [D] | ×2,5 [D] |

Règles communes [V] : un seul statut majeur à la fois (la confusion, temporaire, se cumule) ; statut
gardé après le combat ; guéri au Centre et par son remède ; **aucun dégât ni effet en marchant** ; le
compteur de sommeil (et l'état de gel) est **gardé** au changement de Pokémon, à la fin du combat et
dans la sauvegarde (A-1) ; un Pokémon K.O. perd son statut (existant pour le poison).

Autres valeurs [D] : les capacités de statut suivent la table des types (Cage-Éclair sans effet sur
Sol) ; les poudres touchent le type Plante (défaut du J9 reconduit) ; une capacité de statut sur une
cible déjà atteinte d'un statut majeur échoue avec « déjà … » si c'est le même, « Ça n'a aucun
effet… » sinon.

### 3.2 Confusion **[R A-2]**

Temporaire, perdue au changement de Pokémon et à la fin du combat (jamais sauvegardée) ; dure 1 à 4
tours [D] ; à chaque tentative d'agir, 33 % [D, moderne] de se frapper (dégâts d'une attaque
physique typeless de puissance 40 contre soi). Source réelle avant la Route 3 : **Papilusion (Choc
Mental au niveau 12)**, Ultrason (21).

### 3.3 Présentation

- **Sur le Pokémon** (dossier 05 §13), en effets du moteur, **aucune image nouvelle** : PAR petites
  décharges jaunes occasionnelles ; BRÛ braises intermittentes ; SOM respiration ralentie + « z »
  discrets ; GEL teinte bleu glacé figée ; PSN voile existant (aura légère [D]) ; confusion petites
  étoiles au-dessus de la tête au moment du test. « Réduire les animations » coupe les particules et
  garde la teinte.
- **Carte de PV, Équipe, Sac, tableau de bord** : abréviation en texte (dossier 08) avec la pastille
  de couleur du type associé, comme PSN.
- **Messages** : §13 (même structure que le poison : infligé / déjà / immunisé / empêche d'agir /
  fin de l'état / soigné, avec accords au féminin).
- **Attention CB.1 / CB.3** : l'adversaire est un artwork officiel étalonné avec un matériau propre ;
  le J9 a déjà cassé ce matériau avec le voile du poison (corrigé). Tout effet de statut se pose **au-
  dessus** du sprite, sans remplacer son matériau.

## 4. Effets de capacités en attente

| Effet | Capacités | Appris avant la Route 3 ? | J11 |
|---|---|---|---|
| paralysie (100 / 10 / 30 %) | Cage-Éclair, Para-Spore · Éclair · Plaquage, Fatal-Foudre | oui (Pikachu sauvage, Papilusion 16) | **oui** |
| sommeil | Poudre Dodo | oui (Papilusion 17) | **oui** |
| brûlure 10 % | Flammèche, Lance-Flammes | **oui (Salamèche 9)** | **oui** |
| confusion (100 / 10 %) | Ultrason · Choc Mental, Rafale Psy | **oui (Papilusion 12)** | **[R A-2] oui** |
| deux coups / 2–5 coups | Double Pied, Double-Dard · Furie, Combo-Griffe, Dard-Nuée | oui (Dardargnan 1, Piafabec 15) | **[R A-3] oui** |
| apeurement 10 / 30 % | Croc de Mort · Morsure | oui (Rattata 14) | **[R A-3] oui** |
| Puissance | Puissance | oui (Nidoran ♂ 21) | **[R A-3] oui** (critique +2 étages) |
| dégâts fixes | Croc Fatal (moitié des PV), Frappe Atlas (= niveau) | non (33–34) | **[R A-3] oui** (triviaux) |
| Patience | CT34 | CT | **oui** [V 1] (§6.3) |
| Hurlement | Hurlement | Roucool 19 | **[R A-4] reporté** |
| deux tours, piège, Frénésie, Mimique, Mania, Empal'Korne | … | non (≥ 21) | reporté |

Une capacité reportée garde sa mention « Sans effet dans le moteur actuel. » dans sa description.
Les effets de Racaillou et d'Onix (J10) sont relus à la fusion du J10.

## 5. Remèdes

| Objet | Soigne | Prix [D, Rouge/Bleu] | En vente |
|---|---|---|---|
| Antidote | PSN | 100 ₽ (existant) | inchangé |
| Anti-Para | PAR | 200 ₽ | Jadielle et Argenta, dès le J11 |
| Réveil | SOM | 250 ₽ | Jadielle et Argenta, dès le J11 |
| Anti-Brûle | BRÛ | 250 ₽ | Jadielle et Argenta, dès le J11 |
| Antigel | GEL | 250 ₽ | **pas encore** : aucune capacité ne gèle avant la Route 3 [D, règle « l'objet arrive avec la mécanique »] ; données prêtes |

Usage : Sac en exploration et en combat (même parcours que l'Antidote, refus « Sans effet » sur un
Pokémon sain). Catégorie SOINS. Stock d'Argenta : celui du dossier 12 + ces trois remèdes (le J11
édite la Boutique d'Argenta **après** la fusion du J10).

## 6. CT

### 6.1 Règles [V 2]

Objet permanent (quantité 1, jamais consommé), **utilisable hors combat seulement**, **non vendable**
[D, cohérent avec le réutilisable]. Compatibilité **par espèce** (donnée de l'espèce : liste des CT,
reprise de Rouge/Bleu [D]). Parcours : Sac → **CT** → capacité → liste de l'équipe (compatible /
déjà connue / incompatible, toujours visibles) → APPRENDRE → si 4 capacités, déroulé « oublier une
capacité » existant (`MoveLearnPrompt`) → GARDER annule sans consommer. La capacité apprise a ses PP
pleins ; un Pokémon qui la connaît déjà ne peut pas l'apprendre.

### 6.2 Sac **[R A-7]**

Nouvelle catégorie **CT** dans le Sac, **absente tant que le joueur n'a aucune CT** (dossier 08 §1.8 :
pas de case vide pour un système absent). Carte d'une CT : numéro, nom de la capacité, type ;
détail : puissance, précision, PP, description de la capacité.

### 6.3 CT34 — Patience [V 1, règle détaillée D à valider avec A-8]

« Deux tours de préparation, puis la riposte », lu ainsi :
1. **Tour 1** : « {pokemon} se prépare à encaisser ! » ; le stock commence à 0.
2. **Tour 2** : le Pokémon ne choisit rien (action verrouillée) ; il encaisse.
3. **Tour 3** : « {pokemon} riposte ! » → dégâts = **2 × dégâts directs reçus pendant les tours 1 à
   3 avant d'agir**, au plus les PV restants de la cible ; **ignore types, statistiques, précision et
   esquive** [D] ; **échoue** si le stock est nul (« Mais cela échoue ! »).

Interactions [D, A-1 n° 3 pour les dégâts indirects] :
- **Comptent** : chaque coup des capacités adverses (chaque coup d'un multi-coups).
- **Ne comptent pas** : poison, brûlure, Vampigraine, recul, se frapper dans la confusion.
- **Interrompent Patience** (stock perdu, message « La patience de {pokemon} est rompue ! ») : le
  lanceur change de Pokémon, est K.O., s'endort, gèle, est paralysé au point de ne pas agir, se frappe
  dans la confusion, est apeuré.
- **L'adversaire change de Pokémon** : le stock est gardé et frappe le nouveau.
- PP : un seul PP au tour 1. Fin du combat pendant Patience : rien n'est gardé.
- IA : aucun Dresseur actuel n'a Patience ; l'IA `smart` ne la choisit pas [D].

### 6.4 Remise par Pierre (dépend du J10)

- **Partie qui bat Pierre après le J11** : après « C'est la preuve de ta victoire / à l'Arène
  d'Argenta. », Pierre enchaîne sur la remise (§13) → toast « CT34 — Patience obtenue » → drapeau
  `tm34_received` [D].
- **Partie qui a déjà le badge** (dossier 12 §14) : en lui reparlant, « J'allais oublier. » / « Ceci
  devrait t'être utile. » → même remise, **une seule fois** (drapeau). Ensuite, il revient à sa
  réplique d'après-badge.
- La remise modifie la scène de Pierre écrite au J10 : **sous-jalon 11B après la fusion du J10**.

## 7. Évolution courte [V 7]

- Conditions et logique **inchangées** (`Evolution`, `EvolutionDirector`, J9).
- Durée cible **≈ 6 s** de « Quoi ? {pokemon} évolue ! » à la révélation (aujourd'hui ≈ 9 s : 0,5 +
  1,5 + 0,7 + **5,0** de transformation + 0,3 + 0,4 + 0,8 ; on raccourcit surtout la transformation,
  à ≈ 2,5 s [D]).
- **Accélérer** : toucher l'écran pendant la séquence la joue ×2 [D] ; **ARRÊTER** reste un bouton
  distinct (annulation inchangée, retour Android compris). « Réduire les animations » inchangé.
- Textes **inchangés** (dans `data/battle/messages.json`) : « Quoi ? {pokemon} évolue ! » ·
  « Félicitations ! {pokemon} a évolué en {species} ! » · « Hein ? {pokemon} n'évolue plus. »
  (la V1 de ChatGPT les citait sans leurs noms).
- **Nouvelles statistiques et entrée du Pokédex** (roadmap) : **[R A-9]** pas d'écran de statistiques
  (il allongerait la séquence) ; le Pokédex se met à jour en silence (défaut du J9 conservé).
- DA : silhouettes peintes, aucune déformation des illustrations, 60 fps visés sur S24.

## 8. Compagnon

### 8.1 Qui et quand [V 4, 5]

- Le joueur choisit **un** Pokémon de son équipe : fiche Équipe → action **FAIRE SORTIR** (puis
  **RAPPELER** sur le compagnon actuel) ; un seul compagnon ; **aucun compagnon** est un état valide.
- **Espèces éligibles** = celles qui ont une planche d'exploration **repos + marche en 4 directions**
  validée (liste en données). Aujourd'hui : **Bulbizarre, Salamèche, Carapuce, Roucool, Rattata,
  Piafabec, Férosinge, Nidoran ♀, Nidoran ♂** (9). Chenipan, Aspicot, Chrysacier, Coconfort,
  Kakuna, Métapod n'ont qu'une planche « repos + réaction » (pas de marche) : **non éligibles**.
- **Conflit réel** : une équipe typique d'Argenta (niveau 12–16) contient des espèces **sans planche** :
  les starters évoluent au niveau 16 (Herbizarre, Reptincel, Carabaffe), Pikachu, Papilusion,
  Dardargnan, Roucoups, Racaillou, Onix… → **[R A-10]** lot d'art du J11.
- Action pour une espèce non éligible **[R A-11]**.
- Déblocage **[R A-12]**.

### 8.2 Visible ou non [V 5, A-1]

| Situation | Compagnon |
|---|---|
| Carte d'extérieur (routes, villes, Forêt de Jade) | visible |
| Carte d'intérieur (`Map.interior`, postes de la forêt compris) | rentre dans sa Ball ; ressort en sortant |
| Compagnon K.O. | reste choisi, invisible jusqu'à sa guérison (A-1) |
| Aucune case libre pour un suivi propre (arrivée de carte dans un passage d'une case…) | masqué jusqu'au premier pas qui libère une case (A-1) |
| Cinématique qui déplace le joueur ou qui exige son absence | rentre au début, ressort à la fin [D] |
| Combat | rien ne change sur la carte (l'écran de combat le couvre) ; il ne combat pas en premier [D] |
| Déposé au Stockage / évolue en espèce non éligible | n'est plus compagnon (A-11) |

Sortie et rappel : petit éclat de Ball, ≈ 0,4 s [D] ; rentrée aux portes au même moment que le
fondu.

### 8.3 Déplacement [V, D]

- Suit **la case que le joueur vient de quitter** (wagon), à la même vitesse (marche ou course), à
  angles droits seulement ; saute un rebord derrière lui ; ne traverse jamais un obstacle (il ne va
  que sur des cases où le joueur est passé).
- **Ne bloque pas le joueur** : si le joueur marche vers lui, ils échangent leurs places [D].
- **Les PNJ attendent** au lieu de le traverser [D] ; **il ne coupe pas la ligne de vue d'un Dresseur**
  (`TrainerRules.sight_distance` l'ignore) ; il ne déclenche **ni rencontre ni déclencheur** ; il est
  à moitié caché par les hautes herbes comme le joueur.
- Après une porte, une téléportation, un réveil au Centre : il apparaît derrière le joueur si la case
  est libre, sinon au premier pas (A-1).

### 8.4 Les trois réactions [V 6]

Sans image nouvelle : changements d'orientation (planche existante), petit saut, bulles « ! » « ♪ »
« … » du moteur (bulle « ! » des Dresseurs, J9).

| Réaction | Déclenchement [D] | Présentation |
|---|---|---|
| Curiosité | le joueur lui parle (le toucher ou INTERAGIR face à lui) | se tourne vers le joueur, bulle, **une ligne de texte** (§13) |
| Repos | joueur immobile ≈ 8 s | regarde à gauche, à droite, puis vers le joueur, lentement ; recommence toutes les ≈ 6 s |
| Enthousiasme | victoire contre un Dresseur, capture, montée de niveau du compagnon, sortie du Centre après un soin | petit saut + bulle « ♪ » au retour sur la carte, une fois |

Aucune humeur ni amitié cachée [V] ; les lignes de curiosité varient seulement selon des faits
visibles (PV bas, statut, lieu) **[R A-13]**.

## 9. Sauvegarde

- **Données** : CT possédées (dans le Sac, existant) ; drapeau `tm34_received` ; **compteur de
  sommeil** (et gel) du Pokémon ; **compagnon choisi**. Non sauvegardés : visibilité du compagnon,
  réaction en cours, confusion [V, V1 §6].
- **Identifiant de Pokémon** [D] : un Pokémon n'a aujourd'hui **aucun identifiant stable**
  (`game/pokemon/pokemon.gd`) ; le compagnon ne peut pas être « le n° 2 de l'équipe » (réordonner
  l'équipe le changerait). Ajout d'un identifiant unique attribué à la migration.
- **Version** : `main` est en **v4** (J9). La version du J11 est fixée **au plan**, d'après la branche
  réellement fusionnée (J10, chantier « OUV ») [V, V1 §6]. **« OUV » n'apparaît ni dans le dépôt ni
  sur les branches distantes** au 2026-10-10 → **A-14**.
- Migration : une partie J10 se charge sans perte (Pokémon, objets, badges, drapeaux) ; statuts
  existants gardés ; compteur de sommeil absent = tiré au premier tour.
- **Sous-jalon validé seul sur S24** (règle 1 : système risqué).

## 10. Dépendances

| Avec | Nature | Conséquence |
|---|---|---|
| **J10** (autre session) | Pierre, `badge_boulder`, Boutique d'Argenta, Racaillou et Onix | 11B (CT34) et le stock d'Argenta **après la fusion du J10** ; compatibilités CT de Racaillou / Onix ; version de sauvegarde. 11.0, 11A, 11C, 11D ne touchent pas aux fichiers du J10. |
| **CB.3** (fusionné dans `main`) | décor peint de combat, artwork de l'adversaire | effets de statut au-dessus des sprites (§3.3) ; Patience et messages passent par le `BattleDirector`. Aucun conflit de fichier attendu hors `battle_director.gd`. |
| **OUV** | inconnu dans le dépôt | A-14. |
| Roadmap | phase 7 | à mettre à jour après validation (changement de Pokémon déjà fait ; IA, pierres, dos peints reportés si A-4, A-5, A-6 retenus). |

## 11. Découpage et validation S24

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **11.0** | Sauvegarde : identifiant de Pokémon, compteurs de statut, compagnon, `tm34_received` | **seul**, sur la vraie partie de Kevin (migration, fermeture forcée, refus par l'APK précédent) |
| **11A** | Statuts majeurs + confusion + effets simples + présentation + remèdes (Jadielle) | S24 sur une carte de QA (Pokémon et capacités choisis), retirée à la clôture |
| **11C** | Évolution courte | S24 (ou captures si Kevin le préfère) |
| **11D** | Compagnon (+ lot d'art A-10) | S24 en vraie partie : routes, ville, forêt, portes, rebords, herbes, Dresseurs, Centre |
| **11B** | CT, Sac, Patience, remise par Pierre, stock d'Argenta | S24, **après la fusion du J10** |
| clôture | QA finale sur une vraie partie J1→J10, retrait de la carte de QA | S24 |

**Critères d'acceptation** (V1 §7, précisés) :
1. CT34 obtenue **une seule fois**, y compris pour une partie J10 déjà badgée ; jamais consommée ;
   absente de la Boutique et non vendable.
2. Patience : riposte au double, échec à 0, interruptions (changement, K.O., sommeil, gel, paralysie,
   confusion, apeurement), stock gardé si l'adversaire change ; dégâts indirects exclus.
3. Chaque statut testé en combat sauvage, de Dresseur, au changement, au K.O., à la sauvegarde et au
   rechargement ; capture modifiée ; aucun effet en marchant.
4. Remèdes en exploration et en combat, refus « Sans effet », sans bloquer l'interface.
5. Compagnon : suit sans traverser d'obstacle, rentre dans les intérieurs, invisible K.O., aucune
   rencontre ni déclencheur, ne coupe aucune ligne de vue ; aucune espèce sans planche ne s'affiche.
6. Évolution : achevée, accélérée, annulée sans perte de données ; apprentissage de capacité après
   évolution intact.
7. Anciennes sauvegardes et parcours J1→J10 intacts ; `tools/test.sh` vert ; ≥ 58 fps en exploration
   avec compagnon (forêt comprise).

## 12. Arbitrages pour Kevin

Aucun ne rouvre les 8 décisions du §1.

| N° | Question | Recommandation de Claude |
|---|---|---|
| **A-1** | Les 4 finitions de ChatGPT (compagnon K.O. invisible ; masqué sans case libre ; Patience sans dégâts indirects ; compteurs de sommeil / gel gardés) | **Les accepter telles quelles.** |
| **A-2** | La confusion entre-t-elle au J11 ? La V1 l'oublie, mais **Papilusion apprend Choc Mental au niveau 12** : sans elle, sa capacité phare reste à moitié « sans effet ». | **Oui** (§3.2). |
| **A-3** | Effets secondaires simples (multi-coups, apeurement, Puissance, dégâts fixes) au J11 ? Dardargnan (Furie), Rattata (Croc de Mort), Piafabec les ont déjà. | **Oui** ; reporter deux tours, piège, Frénésie, Mimique, Mania, Empal'Korne (§4). |
| **A-4** | IA qui change de Pokémon et Hurlement : J11 ou plus tard ? | **Plus tard** (Dresseurs expérimentés, J12+). Le changement du joueur existe déjà. |
| **A-5** | Évolutions par pierre au J11 ? | **Non** : avec la Pierre Lune au Mont Sélénite (J12). |
| **A-6** | Dos peints en combat : critère du J11 ? | **Non** : chantier d'art suivi à part. |
| **A-7** | CT dans le Sac : catégorie dédiée « CT », absente tant qu'aucune CT n'est possédée ; CT non vendables. | **Oui.** |
| **A-8** | Patience « deux tours de préparation » = **3 tours au total** (lancement, encaisse, riposte), règles du §6.3. | **Oui, telle que §6.3.** |
| **A-9** | Évolution : écran de statistiques et toast Pokédex (roadmap) ? | **Non** (séquence courte ; Pokédex en silence). |
| **A-10** | Lot d'art du compagnon : quelles nouvelles planches « repos + marche 4 directions » au J11 ? | **Herbizarre, Reptincel, Carabaffe, Pikachu, Papilusion** (5 ; Papilusion en vol). Puis au fil des jalons. |
| **A-11** | Espèce non éligible : comment l'interface le dit, et que devient un compagnon qui évolue en espèce sans planche ? | **FAIRE SORTIR absent** de la fiche d'une espèce non éligible ; un compagnon qui évolue sans planche rentre en silence (plus de compagnon). |
| **A-12** | Déblocage : tout de suite pour toutes les parties, sans tutoriel, ou par un événement ? | **Tout de suite**, sans tutoriel ni compagnon imposé (le bouton apparaît dans Équipe). |
| **A-13** | Lignes de curiosité : génériques (avec {pokemon}) variant selon PV, statut et lieu, ou une ligne par espèce ? | **Génériques** (≈ 10 lignes, §13) ; par espèce plus tard. |
| **A-14** | Qu'est-ce que le chantier « OUV » et sur quelle branche vit-il ? Il n'est pas dans le dépôt. | À préciser par Kevin (seulement pour choisir la version de sauvegarde). |

## 13. Textes à valider (brouillon de Claude)

Mêmes conventions que les lots J7 et J9 (`text_f` pour le féminin, bulles de 2 × ~40 caractères).

**Statuts** (pour PAR, SOM, BRÛ, GEL) : « {pokemon} est paralysé ! Il aura du mal à attaquer. » ·
« {pokemon} est paralysé ! Il ne peut pas attaquer ! » · « {pokemon} s'endort ! » · « {pokemon} dort
profondément. » · « {pokemon} se réveille ! » · « {pokemon} est brûlé ! » · « {pokemon} souffre de sa
brûlure ! » · « {pokemon} est gelé ! » · « {pokemon} est gelé ! Il ne peut pas bouger ! » ·
« {pokemon} n'est plus gelé ! » · « {pokemon} est déjà paralysé / endormi / brûlé / gelé ! » ·
« {pokemon} n'est plus paralysé. » / « … est réveillé. » / « … n'est plus brûlé. » / « … n'est plus
gelé. » (avec féminins).
**Confusion** : « {pokemon} est confus ! » · « {pokemon} est confus… » · « Il se blesse dans sa
confusion ! » · « {pokemon} n'est plus confus ! ».
**Effets** : « Touché {n} fois ! » · « {pokemon} a peur et ne peut pas attaquer ! » · « {pokemon} se
concentre ! ».
**Patience** : « {pokemon} se prépare à encaisser ! » · « {pokemon} encaisse ! » · « {pokemon}
riposte ! » · « Mais cela échoue ! » · « La patience de {pokemon} est rompue ! ».
**Remèdes** : Anti-Para « Soigne un Pokémon paralysé. » · Réveil « Réveille un Pokémon endormi. » ·
Anti-Brûle « Soigne un Pokémon brûlé. » · Antigel « Dégèle un Pokémon gelé. ».
**CT** : catégorie « CT » · toast « CT34 — Patience obtenue » · liste : « COMPATIBLE » / « DÉJÀ
CONNUE » / « INCOMPATIBLE » · « {pokemon} a appris {move} ! » (existant).
**Pierre** (nouvelle partie, après « … à l'Arène d'Argenta. ») : « Prends aussi ceci. » · « Avec
Patience, ton Pokémon encaisse, » / « puis rend les coups au double. » · (partie badgée, dossier 12) :
« J'allais oublier. » / « Ceci devrait t'être utile. » + les deux mêmes lignes sur Patience.
**Patience (description)** : « Le lanceur encaisse pendant deux tours, puis rend le double des dégâts
reçus. »
**Compagnon** : actions « FAIRE SORTIR » / « RAPPELER » · curiosité (génériques) : « {pokemon} te
regarde, l'air content. » · « {pokemon} renifle l'air autour de lui. » · « {pokemon} suit quelque
chose des yeux. » · « {pokemon} s'étire. » · « {pokemon} semble prêt à repartir. » · PV bas :
« {pokemon} a l'air fatigué. » · statut : « {pokemon} n'a pas l'air dans son assiette. » · forêt :
« {pokemon} écoute les bruits de la forêt. » · ville : « {pokemon} observe les passants. » · près de
l'eau : « {pokemon} regarde l'eau. »

## 14. Valeurs par défaut techniques (règle 4)

Immunités Feu / Électrik / Glace ; capture ×2,5 (SOM, GEL) et ×1,5 (PAR, BRÛ, PSN) ; sommeil 1–3
tours, réveil et action dans le même tour ; gel 20 %, dégel par une capacité Feu ; confusion 1–4
tours, 33 %, puissance 40 ; prix des remèdes de Rouge/Bleu ; CT non vendables ; transformation de
l'évolution ≈ 2,5 s, accélération ×2 au toucher ; sortie / rappel ≈ 0,4 s ; repos du compagnon après
≈ 8 s ; PNJ qui attendent le compagnon ; échange de places joueur / compagnon ; identifiant unique de
Pokémon ; drapeau `tm34_received` ; compatibilités CT de Rouge/Bleu.
