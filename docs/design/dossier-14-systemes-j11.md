# Dossier 14 — Grande passe de systèmes (jalon 11)

> V1 de ChatGPT reçue le 2026-10-10 (prompt `prompts/chatgpt-dossier-14-systemes-j11.md`), **8 décisions
> créatives verrouillées par Kevin** (§1), passe d'alignement de Claude contre `main`, **arbitrages A-1 à
> A-14 tranchés par Kevin le 2026-10-10** (toutes les recommandations retenues, §12). **Lot de textes du §13 validé par Kevin le 2026-10-10** (avec retouches). Plan technique : `docs/tech/jalon-11.md`,
> validé sur le principe par Kevin le 2026-10-10 ; **feu vert pour T1 (sauvegarde) seulement**, la suite après la
> validation S24 de 11.0.
>
> **Numérotation** : ex-« dossier 13 », renuméroté **14** le 2026-10-10 sans rien écraser : le numéro 13
> appartient au chantier d'ouverture (OUV : écran titre, introduction de Chen, noms du joueur et du
> rival, nouvelle partie), `dossier-13-ouverture.md`, fusionné dans `main` le 2026-10-10 (ex-branche `docs/dossier-13-ouverture`
> (non poussée). Le numéro de dossier suit l'ordre de conception, pas celui des jalons.
>
> Légende : **[V]** décision de Kevin · **[D]** valeur par défaut technique (règle 4 de `CLAUDE.md`,
> notée, modifiable sans rouvrir la conception).

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

Et les arbitrages A-1 à A-14 du §12 [V].

## 2. Périmètre

**Dans le J11** : statuts majeurs complets (§3) ; confusion [V A-2] ; effets secondaires simples [V A-3]
(§4) ; remèdes (§5) ; CT, Sac et CT34 Patience (§6) ; évolution courte (§7) ; compagnon et son lot
d'art (§8) ; sauvegarde (§9).

**Hors du J11** [V] :
- Route 3, Mont Sélénite, toute zone nouvelle (décision 8) ; aucune espèce nouvelle.
- **IA qui change de Pokémon** et **Hurlement** (A-4). Le changement de Pokémon **du joueur**
  (volontaire et après un K.O.) existe depuis le J7 : la ligne de la roadmap est faite côté joueur.
- **Évolutions par pierre** (A-5) : **dépendance explicite du J12** — le parcours Sac → pierre →
  Pokémon doit être opérationnel avant que le joueur puisse obtenir la Pierre Lune (§10).
- Effets lourds : deux tours, piège (Danse Flamme, Étreinte d'Onix), Frénésie, Mimique, Mania,
  Empal'Korne, Destruction / Explosion (§4).
- Réorganiser les capacités hors combat, Maître des capacités, Total Soin, CT de Boutique.
- Dos peints du joueur en combat (A-6) : chantier d'art du combat, suivi à part.
- Humeur / amitié du compagnon : **aucun système caché**.

## 3. Statuts

### 3.1 Règles [V 3 ; détails D]

| Statut | Abrév. | En combat | Immunité | Capture |
|---|---|---|---|---|
| Poison | PSN | **inchangé depuis le J9** : 1/8 des PV max en fin de tour (au moins 1) | Poison (et Acier) | ×1,5 (existant) |
| Brûlure | BRÛ | 1/16 des PV max en fin de tour (au moins 1) ; dégâts **physiques** infligés ÷ 2 | Feu [D] | ×1,5 [D] |
| Paralysie | PAR | Vitesse ÷ 2 (ordre d'action compris) ; 25 % de chance de ne pas agir, chaque tour | Électrik [D] | ×1,5 [D] |
| Sommeil | SOM | 1 à 3 tours tirés à l'application ; le compteur baisse à chaque tentative d'agir ; **au réveil, le Pokémon agit dans le même tour** [D] | aucune | ×2,5 [D] |
| Gel | GEL | ne peut pas agir ; 20 % de dégel à chaque tentative d'agir ; **dégelé s'il est touché par une capacité Feu** [D] | Glace [D] | ×2,5 [D] |

Règles communes [V] : un seul statut majeur à la fois (la confusion, temporaire, se cumule) ; statut
gardé après le combat ; guéri au Centre et par son remède ; **aucun dégât ni effet en marchant** ; le
compteur de sommeil (et l'état de gel) est **gardé** au changement de Pokémon, à la fin du combat et
dans la sauvegarde (A-1) ; un Pokémon K.O. perd son statut (existant pour le poison).

Autres valeurs [D] : les capacités de statut suivent la table des types (Cage-Éclair sans effet sur
Sol) ; les poudres touchent le type Plante (défaut du J9 reconduit) ; une capacité de statut sur une
cible qui a déjà ce statut : « … est déjà … ! » ; sur une cible qui a un autre statut majeur : « Mais
ça échoue ! » (texte nouveau, n° 27 du §13).

### 3.2 Confusion [V A-2]

Temporaire, perdue au changement de Pokémon et à la fin du combat (jamais sauvegardée) ; 1 à 4 tours
[D] ; à chaque tentative d'agir, 33 % [D] de se frapper (attaque physique sans type de puissance 40
contre soi, ni critique ni recul). Se cumule avec un statut majeur ; un Pokémon déjà confus ne l'est
pas « plus ». Sources réelles avant la Route 3 : **Papilusion (Choc Mental au Nv. 12)**, Ultrason
(21), Rafale Psy (32). **Interactions vérifiées au plan** : Patience (rompue si le lanceur se
frappe), Vampigraine et poison (fin de tour inchangée), changement forcé après K.O. (confusion
perdue), capture (aucun bonus), IA `smart` (ne choisit pas une capacité de confusion sur une cible
déjà confuse).

### 3.3 Présentation

- **Sur le Pokémon** (dossier 05 §13), par le moteur, **aucune image nouvelle** : PAR petites
  décharges jaunes occasionnelles ; BRÛ braises intermittentes ; SOM respiration ralentie + « z »
  discrets ; GEL teinte bleu glacé figée ; PSN voile existant ; confusion petites étoiles au moment du
  test. « Réduire les animations » coupe les particules et garde la teinte.
- **Carte de PV, Équipe, Sac, tableau de bord** : abréviation en texte (dossier 08) et pastille de
  couleur, comme PSN.
- **Messages** : §13.
- **CB.1 / CB.3** : l'adversaire est un artwork officiel étalonné par un matériau propre (le J9 l'avait
  cassé avec le voile du poison, corrigé) : tout effet se pose **au-dessus** du sprite, sans remplacer
  son matériau.

## 4. Effets de capacités

### 4.1 Déjà codés (rien à reconstruire)

`MoveEffect` connaît `stat_stage` (étages, soi ou cible, chance), `recoil`, `seed` (Vampigraine) et
`status` (aujourd'hui poison seul : Poudre Toxik, Dard-Venin, Double-Dard 20 %). La précision, les
critiques, `priority`, `crit_stage` et `typeless` existent. **Le J11 étend `status` aux quatre
statuts et à la confusion, et ajoute les genres manquants** ; il ne refait rien de ce qui existe.

### 4.2 En attente (`pending_effects` de `data/pokemon/moves/moves.json`, 32 capacités sur 66)

| Effet | Capacités | Appris avant la Route 3 ? | J11 |
|---|---|---|---|
| paralysie (100 / 10 / 30 %) | Cage-Éclair, Para-Spore · Éclair · Plaquage, Fatal-Foudre | oui (Pikachu sauvage, Papilusion 16) | **oui** |
| sommeil | Poudre Dodo | oui (Papilusion 17) | **oui** |
| brûlure 10 % | Flammèche, Lance-Flammes | **oui (Salamèche 9)** | **oui** |
| confusion (100 / 10 %) | Ultrason · Choc Mental, Rafale Psy | **oui (Papilusion 12)** | **oui** [A-2] |
| deux coups / 2–5 coups | Double Pied, Double-Dard · Furie, Combo-Griffe, Dard-Nuée | oui (Dardargnan 1, Piafabec 15) | **oui** [A-3] |
| apeurement 10 / 30 % | Croc de Mort · Morsure | oui (Rattata 14) | **oui** [A-3] |
| Puissance | Puissance | oui (Nidoran ♂ 21) | **oui** [A-3] (critique +2 étages) |
| dégâts fixes | Croc Fatal (moitié des PV), Frappe Atlas (= niveau) | non (33–34) | **oui** [A-3] |
| Patience | CT34 | CT | **oui** (§6.3) |
| Hurlement | Hurlement | Roucool 19 | reporté [A-4] |
| deux tours | Lance-Soleil, Coud'Krâne | non | reporté |
| piège | Danse Flamme, **Étreinte** (Onix 15, J10) | Onix non capturable | reporté |
| Destruction / Explosion | **Racaillou 21** (J10) | Racaillou non sauvage avant le J12 | reporté (à faire **au J12** si le Mont Sélénite a des Racaillou ≥ 21, §10) |
| Frénésie, Mimique, Mania, Empal'Korne | … | non (≥ 22) | reporté |

Une capacité reportée garde la mention « Sans effet dans le moteur actuel. » dans sa description. Le
plan liste capacité par capacité ce qui change (données, moteur, texte, test).

## 5. Remèdes

| Objet | Soigne | Prix [D, Rouge/Bleu] | En vente |
|---|---|---|---|
| Antidote | PSN | 100 ₽ (existant) | inchangé |
| Anti-Para | PAR | 200 ₽ | Jadielle et Argenta, dès le J11 |
| Réveil | SOM | 250 ₽ | Jadielle et Argenta, dès le J11 |
| Anti-Brûle | BRÛ | 250 ₽ | Jadielle et Argenta, dès le J11 |
| Antigel | GEL | 250 ₽ | **pas encore** : aucune capacité ne gèle avant la Route 3 [D, « l'objet arrive avec la mécanique »] ; données prêtes |

Usage : Sac en exploration et en combat, même parcours que l'Antidote, refus « Sans effet » sur un
Pokémon sain. Catégorie SOINS. Boutiques : `data/shops/viridian_mart.json` et `pewter_mart.json` (J10).

## 6. CT

### 6.1 Règles [V 2, A-7]

Objet permanent (quantité 1, jamais consommé), **hors combat seulement**, **non vendable**.
Compatibilité **par espèce** (donnée de l'espèce, reprise de Rouge/Bleu [D]), pour les **40 espèces**
des données (dont Racaillou, Gravalanch, Grolem, Onix, Sabelette, Sablaireau du J10). Parcours : Sac →
**CT** → capacité → l'équipe (COMPATIBLE / DÉJÀ CONNUE / INCOMPATIBLE, toujours visibles) → APPRENDRE →
si 4 capacités, déroulé « oublier une capacité » existant → GARDER annule. PP pleins pour la capacité
apprise ; un Pokémon qui la connaît déjà ne peut pas l'apprendre.

### 6.2 Sac [V A-7]

Catégorie **CT**, **absente tant que le joueur n'a aucune CT**. Carte : numéro, nom de la capacité,
type ; détail : puissance, précision, PP, description.

### 6.3 CT34 — Patience [V 1, A-8 : trois tours au total]

1. **Tour 1** : « {pokemon} se prépare à encaisser ! » ; stock à 0 ; un seul PP dépensé.
2. **Tour 2** : action verrouillée (le joueur ne choisit rien) ; « {pokemon} encaisse ! ».
3. **Tour 3** : « {pokemon} riposte ! » → dégâts = **2 × dégâts directs reçus des tours 1 à 3** (avant
   la riposte), au plus les PV restants de la cible ; **ignore types, statistiques, précision et
   esquive** [D] ; **échoue** si le stock est nul (« Mais ça échoue ! »).

Interactions [A-1 n° 3 et D] :
- **Comptent** : chaque coup des capacités adverses (chaque coup d'un multi-coups).
- **Ne comptent pas** : poison, brûlure, Vampigraine, recul, se frapper dans la confusion.
- **Rompent Patience** (stock perdu, « La patience de {pokemon} est rompue ! ») : le lanceur change de
  Pokémon, est K.O., s'endort, gèle, est paralysé au point de ne pas agir, se frappe dans la
  confusion, est apeuré.
- **L'adversaire change de Pokémon** : le stock reste et frappe le nouveau.
- Fin du combat pendant Patience (capture, fuite) : rien n'est gardé. L'IA `smart` ne la choisit pas.

### 6.4 Remise par Pierre (le J10 est fusionné)

- **Partie qui bat Pierre après le J11** : après « C'est la preuve de ta victoire / à l'Arène
  d'Argenta. », Pierre enchaîne sur la remise (§13) → toast → drapeau `tm34_received` [D].
- **Partie déjà badgée** (`badge_boulder` sans `tm34_received`, dossier 12 §14) : en lui reparlant,
  « J'allais oublier. » / « Ceci devrait t'être utile. » → même remise, **une seule fois**. Ensuite, sa
  réplique d'après-badge du J10 (`pewter_gym_brock_badge` / allusion au rival) revient.
- Fichiers du J10 touchés : `data/dialogues/pewter_gym.json`, `data/cutscenes/pewter_gym.json`.

## 7. Évolution courte [V 7, A-9]

- Conditions et logique **inchangées** (`Evolution`, `EvolutionDirector`, J9).
- Cible **≈ 6 s** de « Quoi ? {pokemon} évolue ! » à la révélation (aujourd'hui ≈ 9 s : ouverture 0,5,
  présentation 1,5, entrée 0,7, **transformation 5,0**, flash 0,3, silence 0,4, révélation 0,8) ; on
  raccourcit surtout la transformation (≈ 2,5 s [D]).
- **Accélérer** : toucher l'écran pendant la séquence la joue ×2 [D] ; **ARRÊTER** reste un bouton
  distinct (retour Android compris). « Réduire les animations » inchangé.
- Textes inchangés : « Quoi ? {pokemon} évolue ! » · « Félicitations ! {pokemon} a évolué en
  {species} ! » · « Hein ? {pokemon} n'évolue plus. »
- **Pas d'écran de statistiques** ; Pokédex mis à jour en silence (A-9).
- DA : silhouettes peintes, aucune déformation des illustrations, 60 fps visés sur S24.

## 8. Compagnon

### 8.1 Qui [V 4, A-11, A-12]

- Disponible **tout de suite** pour toutes les parties, sans tutoriel ni compagnon imposé : fiche
  Équipe → **FAIRE SORTIR** ; sur le compagnon actuel → **RAPPELER**. Un seul compagnon ; **aucun** est
  un état valide (état de départ).
- **Éligible** = espèce qui a une planche d'exploration **repos + marche en 4 directions** validée
  (liste en données). **FAIRE SORTIR n'existe pas** sur la fiche d'une espèce non éligible ; aucun
  asset de remplacement.
- Un compagnon qui **évolue** en espèce non éligible **rentre en silence** (plus de compagnon) ; un
  compagnon déposé au Stockage n'est plus compagnon.

### 8.2 Assets et équipes réelles [V A-10, audit du 2026-10-10]

- **Éligibles aujourd'hui (9)** : Bulbizarre, Salamèche, Carapuce, Roucool, Rattata, Piafabec,
  Férosinge, Nidoran ♀, Nidoran ♂. Planches « repos + réaction » sans marche (non éligibles) :
  Chenipan, Aspicot, Chrysacier, Coconfort, Kakuna, Métapod, Racaillou.
- **Lot d'art du J11 (A-10, 5 planches)** : Herbizarre, Reptincel, Carabaffe, Pikachu, Papilusion (en
  vol), dans la main 2D HD peinte des planches existantes (validées par Kevin comme les autres
  séries Codex).
- **Équipe réelle de Kevin** (fin du J9 : Salamèche, Roucool, Chenipan ×2, Rattata, Nidoran ♂) :
  4 éligibles sur 6 aujourd'hui ; avec le lot, Papilusion et Reptincel le restent. **Point faible**
  au J12 (Nv. 16–25) : Roucoups (18), Nidorino / Nidorina (16), Rattatac (20), Rapasdepic (20) ne
  sont pas couverts → **recommandation pour la liste d'assets du J12** (pas une décision du J11) :
  ces 5 planches, plus Racaillou en marche s'il devient capturable.
- Une espèce qui n'a pas sa planche : critère d'acceptation « aucun substitut ».

### 8.3 Visible ou non [V 5, A-1]

| Situation | Compagnon |
|---|---|
| Carte d'extérieur (routes, villes, Forêt de Jade) | visible |
| Carte d'intérieur (`Map.interior`, postes de la forêt compris) | rentre dans sa Ball ; ressort en sortant |
| Compagnon K.O. | reste choisi, invisible jusqu'à sa guérison |
| Aucune case libre pour un suivi propre | masqué jusqu'au premier pas qui libère une case |
| Cinématique qui déplace le joueur ou exige son absence | rentre au début, ressort à la fin [D] |
| Combat | rien ne change sur la carte ; il ne combat pas en premier [D] |

Sortie et rappel : petit éclat de Ball ≈ 0,4 s [D] ; aux portes, il rentre au moment du fondu.

### 8.4 Déplacement [V, D]

- Suit **la case que le joueur vient de quitter**, à la même vitesse (marche ou course), à angles
  droits ; saute un rebord derrière lui ; ne va que sur des cases où le joueur est passé (jamais à
  travers un obstacle).
- **Ne bloque pas le joueur** : si le joueur marche vers lui, ils échangent leurs places.
- **Les PNJ l'attendent** au lieu de le traverser ; **il ne coupe aucune ligne de vue de Dresseur** ; il
  ne déclenche **ni rencontre ni déclencheur** ; à moitié caché par les hautes herbes comme le joueur.
- Après une porte, une téléportation, un réveil au Centre : derrière le joueur si la case est libre,
  sinon au premier pas (A-1).

### 8.5 Les trois réactions [V 6, A-13]

Sans image nouvelle : orientations de la planche, petit saut, bulles « ! » « ♪ » « … » du moteur.

| Réaction | Déclenchement [D] | Présentation |
|---|---|---|
| Curiosité | le joueur lui parle (INTERAGIR face à lui, ou le toucher) | se tourne vers le joueur, bulle, **une phrase** (§13, ≈ 10 génériques choisies selon le contexte) |
| Repos | joueur immobile ≈ 8 s | regarde à gauche, à droite, puis vers le joueur ; recommence toutes les ≈ 6 s |
| Enthousiasme | victoire contre un Dresseur, capture, montée de niveau du compagnon, sortie du Centre après un soin | petit saut + bulle « ♪ » au retour sur la carte, une fois |

Aucune humeur ni amitié cachée : la phrase dépend seulement de faits visibles (PV bas, statut, lieu).

## 9. Sauvegarde

- **Données** : CT (dans le Sac, existant) ; drapeau `tm34_received` ; **compteur de sommeil** et état
  de gel ; **compagnon choisi** ; **identifiant stable de chaque Pokémon** (indispensable : aujourd'hui
  aucun, et le compagnon ne peut pas être « le n° 2 de l'équipe »). Non sauvegardés : visibilité du
  compagnon, réaction en cours, confusion.
- **État vérifié le 2026-10-10 (après la fusion d'OUV.0)** : `main` est en **v4** ; le J10 n'a pas changé
  le format (`jalon-10.md` §2.15) ; **OUV.1 crée la v5** (`rival_name`, `player_look` : dossier 13 §3.4,
  `docs/tech/ouverture.md` §2), validé par Kevin et prochain lot du chantier OUV. **Conflit réel** : les
  deux chantiers veulent la version suivante.
- **Règle retenue** [D, appliquée de la règle « le second fusionné renumérote »] : OUV a réservé la v5 le
  premier (dossier validé) → **le J11 écrit la v6** (migration v5 → v6), **par-dessus** la v5 d'OUV. Le
  code de T1 est écrit dès maintenant avec un numéro provisoire, mais **11.0 n'est ni fusionné ni joué
  sur le S24 de Kevin avant la fusion d'OUV.1** : jamais deux APK qui écrivent deux « v5 » différentes
  sur la vraie partie. Si Kevin veut passer le J11 avant OUV.1, c'est OUV qui renumérote (à décider
  par lui).
- **Champs additifs, avec valeur par défaut** : absent = aucun compagnon ; `uid` attribué au chargement
  à chaque Pokémon qui n'en a pas (équipe dans l'ordre, puis Stockage dans l'ordre : **ordre et contenu
  inchangés**) ; compteur de sommeil absent = tiré au premier tour. Le compagnon est désigné **par
  `uid`, jamais par sa position** ; il reste choisi quand il rentre dans sa Ball (intérieurs, K.O.,
  cinématiques) : seule la visibilité change, jamais le choix.
- Une partie J10 se charge sans perte (Pokémon, objets, badges, drapeaux, Grands moments).
- **Sous-jalon validé seul sur S24** (règle 1).

## 10. Dépendances

| Avec | État au 2026-10-10 | Conséquence |
|---|---|---|
| **J10** | **terminé, fusionné dans `main`** (`e80f636`) | plus de blocage : la remise de la CT34 et les stocks d'Argenta se font sur les fichiers réels ; compatibilités CT des 40 espèces. |
| **CB.3** | fusionné dans `main` | effets de statut au-dessus des sprites (§3.3) ; Patience et messages passent par le `BattleDirector`. |
| **OUV** | OUV.0 fusionné ; OUV.1 (sauvegarde v5) à venir | le J11 écrit la **v6** par-dessus ; 11.0 fusionné et joué sur S24 **après** OUV.1 (§9). `game_state.gd` / `save_system.gd` / `boot.gd` partagés : aucun fichier propre à OUV touché par le J11. |
| **J12** | conception en cours avec ChatGPT | **le J12 dépend du J11** pour : évolutions par pierre (Pierre Lune ; à coder au J12 avant de la rendre obtenable), Destruction / Explosion si des Racaillou ≥ Nv. 21, Antigel si une capacité gèle, planches de compagnon (§8.2). |
| Roadmap | phase 7 | mise à jour à la clôture (changement de Pokémon du joueur déjà fait ; IA, pierres, dos peints reportés). |

## 11. Découpage et validation S24

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **11.0** | Sauvegarde : identifiant de Pokémon, compteurs de statut, compagnon, `tm34_received` | **seul**, sur la vraie partie de Kevin |
| **11A** | Statuts + confusion + effets simples + présentation + remèdes | S24, carte de QA retirée à la clôture |
| **11B** | CT, Sac, Patience, remise par Pierre | S24 |
| **11C** | Évolution courte | S24 |
| **11D** | Compagnon (+ lot d'art) | S24 en vraie partie |
| clôture | QA finale J1 → J10 + J11, retrait de la carte de QA | S24 |

Critères d'acceptation : `docs/tech/jalon-11.md` §4.

## 12. Arbitrages (tranchés par Kevin le 2026-10-10)

| N° | Question | Décision |
|---|---|---|
| A-1 | 4 finitions de ChatGPT | **Acceptées** : compagnon K.O. invisible ; masqué sans case libre ; Patience sans dégâts indirects ; compteurs de sommeil / gel gardés |
| A-2 | Confusion au J11 | **Oui**, interactions vérifiées (§3.2) |
| A-3 | Effets simples | **Oui** : multi-coups, apeurement, Puissance, dégâts fixes ; le reste reporté |
| A-4 | IA qui change, Hurlement | **Reportés** |
| A-5 | Évolutions par pierre | **J12**, avec la Pierre Lune ; dépendance documentée (§10) |
| A-6 | Dos peints | **Hors J11** (chantier d'art du combat) |
| A-7 | Catégorie CT | **Oui**, masquée tant qu'elle est vide ; CT non vendables |
| A-8 | Patience | **Trois tours au total** (§6.3) |
| A-9 | Écran de statistiques après évolution | **Non** |
| A-10 | Lot d'art | **Herbizarre, Reptincel, Carabaffe, Pikachu, Papilusion**, dans la DA 2D HD peinte |
| A-11 | Espèce sans planche | **Pas de FAIRE SORTIR**, aucun substitut |
| A-12 | Déblocage | **Immédiat**, sans tutoriel |
| A-13 | Phrases du compagnon | **≈ 10 génériques**, contextualisées, sans amitié cachée |
| A-14 | OUV | **Chantier d'ouverture** (écran titre, introduction de Chen, noms, nouvelle partie, sauvegarde) ; branche locale `docs/dossier-13-ouverture` ; ce dossier renuméroté 14 |

## 13. Lot de textes — VALIDÉ par Kevin le 2026-10-10 (avec retouches)

Conventions des lots J7 et J9 : `{pokemon}` = nom ou surnom, `{move}` capacité, `{n}` nombre ; la forme
au féminin (`text_f`) est donnée entre crochets ; bulles de 2 lignes de ~40 caractères. **Validé par Kevin le 2026-10-10** : tout le lot, avec les
retouches des n° 1, 2, 21, 25, 27, 33, 45, 50, 51, 54 (intégrées ci-dessous). Les textes déjà verrouillés
ailleurs (n° 18, 43, 48) restent mot pour mot ; « Mais ça échoue ! » (n° 27) ne sert qu'aux cas
nouveaux du J11 et ne remplace aucun message existant.

### 13.1 Paralysie
1. Infligée : « {pokemon} est paralysé[e] ! »
2. Ne peut pas agir : « {pokemon} est paralysé[e] ! Impossible d'agir ! »
3. Déjà : « {pokemon} est déjà paralysé[e] ! »
4. Soignée : « {pokemon} n'est plus paralysé[e]. »

### 13.2 Sommeil
5. Infligé : « {pokemon} s'endort ! »
6. Dort : « {pokemon} dort profondément. »
7. Réveil **naturel** (fin du compteur, en combat) : « {pokemon} se réveille ! »
8. Déjà : « {pokemon} est déjà endormi[e] ! »
9. Soigné **par l'objet Réveil** (après « Tu utilises Réveil sur {pokemon}. », en combat ou hors
   combat) : « {pokemon} est réveillé[e]. » — événement distinct du n° 7 (`STATUS_CURED` et non
   `WOKE_UP`), jamais affiché pour un réveil spontané.

### 13.3 Brûlure
10. Infligée : « {pokemon} est brûlé[e] ! »
11. Dégâts : « {pokemon} souffre de sa brûlure ! »
12. Déjà : « {pokemon} est déjà brûlé[e] ! »
13. Soignée : « {pokemon} n'est plus brûlé[e]. »

### 13.4 Gel
14. Infligé : « {pokemon} est gelé[e] ! »
15. Ne peut pas agir : « {pokemon} est gelé[e] ! Il[Elle] ne peut pas bouger ! »
16. Dégel : « {pokemon} n'est plus gelé[e] ! »
17. Déjà : « {pokemon} est déjà gelé[e] ! »

### 13.5 Immunités (communes)
18. « Ça n'affecte pas {pokemon}... » (existant : `no_effect`, réutilisé pour les immunités de statut)

### 13.6 Confusion
19. Infligée : « {pokemon} est confus[e] ! »
20. Test : « {pokemon} est confus[e]… »
21. Se frappe : « {pokemon} se blesse dans sa confusion ! »
22. Fin : « {pokemon} n'est plus confus[e] ! »
23. Déjà : « {pokemon} est déjà confus[e] ! »

### 13.7 Effets de capacités
24. Multi-coups : « Touché {n} fois ! »
25. Apeurement : « {pokemon} a peur ! Impossible d'agir ! »
26. Puissance : « {pokemon} se concentre ! »
27. Échec générique (Puissance déjà active, statut sur une cible déjà atteinte d'un autre statut, Patience
    sans dégâts) : « Mais ça échoue ! » (nouveau, cas du J11 seulement)

### 13.8 Patience
28. Tour 1 : « {pokemon} se prépare à encaisser ! »
29. Tour 2 : « {pokemon} encaisse ! »
30. Tour 3 : « {pokemon} riposte ! »
31. Stock nul : n° 27
32. Rompue : « La patience de {pokemon} est rompue ! »
33. Description de la capacité : « Encaisse deux tours, puis riposte avec le double des dégâts reçus. »
    Vérifié contre §6.3 : tours 1 et 2 = encaisser, tour 3 = riposter (les dégâts reçus au tour 3
    avant la riposte, quand l'adversaire est plus rapide, comptent aussi : c'est toujours « reçus »).

### 13.9 Remèdes (nom · pluriel · description)
34. Anti-Para · Anti-Para · « Soigne un Pokémon paralysé. »
35. Réveil · Réveils · « Réveille un Pokémon endormi. »
36. Anti-Brûle · Anti-Brûle · « Soigne un Pokémon brûlé. »
37. Antigel · Antigels · « Dégèle un Pokémon gelé. » (données prêtes, pas en vente)

### 13.10 CT et Sac
38. Catégorie : « CT »
39. Nom d'objet : « CT34 — Patience »
40. Toast de remise : « CT34 — Patience obtenue »
41. États dans la liste : « COMPATIBLE » · « DÉJÀ CONNUE » · « INCOMPATIBLE »
42. Bouton : « APPRENDRE »
43. Apprise : « {pokemon} apprend {move} ! » (existant : `move_learned`)
44. Refus en combat (toucher une CT pendant un combat) : « Les CT s'utilisent hors combat. »

### 13.11 Pierre
45. Nouvelle partie, juste après « … à l'Arène d'Argenta. » : « Prends ceci aussi. »
46. « Avec Patience, ton Pokémon encaisse, »
47. « puis rend les coups au double. »
48. Partie déjà badgée (dossier 12 §14, déjà validé) : « J'allais oublier. » / « Ceci devrait t'être
    utile. » puis 46–47.

### 13.12 Compagnon
49. Actions : « FAIRE SORTIR » · « RAPPELER »
50. Générique : « {pokemon} te regarde, l'air heureux. »
51. Générique : « {pokemon} renifle l'air. »
52. Générique : « {pokemon} suit quelque chose des yeux. »
53. Générique : « {pokemon} s'étire. »
54. Générique : « {pokemon} s'étire doucement. »
55. PV bas : « {pokemon} a l'air fatigué[e]. »
56. Statut : « {pokemon} n'a pas l'air dans son assiette. »
57. Forêt : « {pokemon} écoute les bruits de la forêt. »
58. Ville : « {pokemon} observe les passants. »
59. Près de l'eau : « {pokemon} regarde l'eau. »

## 14. Valeurs par défaut techniques (règle 4)

Immunités Feu / Électrik / Glace ; capture ×2,5 (SOM, GEL) et ×1,5 (PAR, BRÛ, PSN) ; sommeil 1–3
tours, réveil et action dans le même tour ; gel 20 %, dégel par une capacité Feu ; confusion 1–4
tours, 33 %, puissance 40 ; prix des remèdes de Rouge/Bleu ; Antigel pas en vente ; CT non vendables ;
compatibilités CT de Rouge/Bleu ; transformation ≈ 2,5 s, accélération ×2 au toucher ; sortie / rappel
≈ 0,4 s ; repos du compagnon après ≈ 8 s ; PNJ qui attendent le compagnon ; échange de places ;
compagnon caché pendant les cinématiques qui déplacent le joueur ; identifiant unique de Pokémon ;
drapeau `tm34_received` ; version de sauvegarde = version de `main` au 11.0 + 1.
