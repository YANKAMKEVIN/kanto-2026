# Phase DA — cadrage du rendu final

> Rédigé le 2026-10-24 par une session de coordination, **documents seuls** (aucun code, aucun art).
> Mesuré sur `origin/main` @ `af0e84ef` et sur les branches `art-dos-combat`, `jalon-23`,
> `jalon-26` à `jalon-31` (plans J32 à J40 lus sur `origin/jalon-31`).
> **À valider par Kevin** : recommandation (§2) et arbitrages DA-1 à DA-9 (§4).

## 0. Pourquoi ce document

La règle 3 de `CLAUDE.md` dit que les visuels restent provisoires « jusqu'à la phase DA ». Or aucun
des jalons J32 à J40 ne lui est consacré : le J33 prévoit une **harmonisation visuelle** (T2, 33A)
« après les lots d'art », sans dire qui produit ces lots ni quand. Sans cadrage, la RC (J34), la
bêta (J35) et la 1.0 (J37) sortiraient avec l'art actuel.

Le mot « DA » est déjà pris par le chantier du 2026-10-06 (DA.0 à DA.3, `docs/tech/integration-da-bourg-route1.md`).
Pour éviter la confusion, les lots de la phase DA s'appellent ici **DAF.0 à DAF.8** (« DA finale »)
et les arbitrages **DA-1 à DA-9**.

## 1. État de l'art

### 1.1 Ce qui est déjà au niveau final (ou retenu comme tel)

Le monde du début et du milieu du jeu est **peint**. Le provisoire se concentre sur le combat et sur
les zones codées depuis le J26.

| Famille | Fait (peint) | Source |
|---|---|---|
| Façades de bâtiments, `main` | 44 (dont les 10 de Céladopole, série 22 bis) | `inventaire-art.md` |
| Intérieurs, `main` | toutes les cartes jusqu'au J25 (coques peintes ou modules : Casino, repaire, Tour, Manoir) | `inventaire-art.md`, séries 22 bis et 28 |
| Personnages (héros, rival, PNJ) | ≈ 100 apparences peintes, aucun pixel visible | `inventaire-art.md` |
| Compagnons d'exploration | 27 / 27 espèces de `companions.json` | `inventaire-art.md` |
| Faces de combat, Pokédex, menus | artwork officiel, 151 espèces (`pokemon/official/`, 152 fichiers) | décision du 2026-10-05 (mémoire `pokemon-art-source`) |
| Icônes du Sac | 45 / 45 | série 22 bis |
| UI | thème 2026 (non pixel art, skill `ui-theme-2026`), maquettes de référence validées | `ui-reference.md` |

« Fait » veut dire « peint et validé sur planche », pas « au niveau de la cible du cahier » : la
série 22 bis a été validée **telle quelle, retouches reportées à la phase DA** (une coque par
géométrie, 4F du magasin recoloré, façades en lumière neutre).

### 1.2 Ce qui est encore provisoire

| Famille | Provisoire | Où | Joueur exposé |
|---|---|---|---|
| **Dos de combat (ton Pokémon)** | **125 / 125 en pixel art 64 px sur `main`** (126 espèces en données ; 151 au J32). La branche `art-dos-combat` (2026-10-22, **non fusionnée**, 6 commits) en peint **79 espèces** (54 du lot 2 + 21 dos IA + 4 dos 3D) ; restent 6 refusés par Codex (Kadabra, Tortank, Rondoudou, Staross, Léviator, Voltali, fiche `dos-a-faire-chatgpt.md` sur la branche), 4 conditionnels (Ossatueur, Rhinocorne, Saquedeneu, Kangourex), Ptéra et Magmar à refaire (série 28), et les espèces ajoutées par les J26 à J32 | combat | **chaque combat** |
| **Fonds de combat (CB.3)** | 6 lieux sans fond sur `main` (Forêt de Jade, Routes 2, 2 nord, 22, 25, Arène d'Argenta : repli = carte floutée) ; zones des J26 à J31 à remesurer | combat | les premières heures |
| **Façades en aplats générés** | 17 façades de Safrania (`placeholders_safrania.py`, J26 et J27) | `jalon-26`, `jalon-27` | toute la fin du jeu (ville centrale) |
| **Intérieurs en aplats** | 7 de Sylphe SARL (`placeholders_sylphe.py`), 2 de l'Arène de Morgane (`placeholders_safrania_arene.py`), 1 du J28 (`placeholders_j28.py`) | `jalon-26` à `jalon-28` | scénario principal |
| **Kits en placeholder** | dalles et cases d'arrêt de l'Arène de Jadielle (celles du repaire), grotte de la Route Victoire (kit grotte existant), cinq salles de la Ligue, Grotte Azurée : chaque plan dit « lot d'art ensuite » | plans J28 à J31 | fin du jeu |
| **Séries validées non intégrées** | série 23 (Repos des esprits, « sans intégration ») et série 25 (deux chemins, « rien n'est intégré avant validation ») : **à vérifier** contre `main` (DAF.0) | J21, J22 | milieu du jeu |
| **Reliquats** | `breakfast` et `bed_items` en pixel (Bourg Palette) ; pont extérieur du S.S. Anne à vérifier ; Chenipan d'ambiance de la Forêt de Jade (prompt prêt) | `inventaire-art.md` §4 | début du jeu |
| **Reportés de rendu** (`etat-projet.md`, « Reportés ») | Forêt de Jade à assombrir hors des clairières ; intérieurs « vraie DA » (lumière chaude, décor riche) ; Mont Sélénite (masse d'ardoise, bouche du sas) ; raccord J21/J22 de la Route 16 ; écran de démarrage « GODOT » et icône de l'appli ; Pokémon qui coupent sans planche d'exploration ; sauts, recul du starter et orientations des cinématiques ; détails de combat du J9 (voile du poison, bouton ARRÊTER, icône de l'Antidote…) | transverse | variable |

Hors périmètre de ce cadrage : **audio** (musique et ambiances provisoires, plan J31) ; voir DA-8.

### 1.3 Chiffrage

En **nombre d'images à produire** (ordre de grandeur, à confirmer par DAF.0) :

| Bloc | Images | Remarque |
|---|---|---|
| Dos de combat restants | ≈ 35 à 50 | 151 − 79, moins les espèces dont le dos 3D ou IA est déjà accepté ; dont ≈ 10 par ChatGPT (refus) |
| Fonds de combat | ≈ 6 à 15 | 6 connus + zones J26–J31 |
| Safrania et Sylphe (façades + intérieurs) | ≈ 26 + modules | modèle de la série 22 bis (44 images) |
| Kits de fin de jeu (J28 à J31) | ≈ 40 à 60 | modules et coques, comme les séries 27 et 28 |
| Reliquats et reportés à image | ≈ 10 | objets, Chenipan, icône, splash |
| **Total** | **≈ 120 à 160 images** | à comparer : séries 22 bis + lot 2 ≈ 100 images en 2 jours |

Le reste des reportés est du **travail Godot** (lumière, profils, shaders, animations), sans image.

## 2. Où placer la phase DA

Point commun aux trois options : l'art se remplace **à l'identique** (mêmes identifiants, mêmes
dimensions, mêmes emprises), comme la série 22 bis. Aucune collision, aucun déclencheur, aucune
coordonnée ne bouge, ce que le contrat du J33 exige déjà (`tools/dump_map_logic.gd` avant/après).
Les tests concernés sont surtout `test_battle_art`, `test_painted_backs`, les fixtures
`*_logic.txt` et les tests de cartes.

### Option A — jalon DA dédié, entre le J32 et la RC (J34)

Un jalon « DA » séquentiel : tout le contenu fusionné (J23, J26–J32), puis toute la production d'art,
puis le J33.

- **Gel J33–J34** : propre, l'art est figé avant la stabilisation.
- **Tests** : une seule vague de remplacement, une suite complète par lot.
- **Coût** : retarde la RC de toute la durée de la production (≈ 6 à 10 jours) ; les sessions de code
  attendent l'art alors que l'art n'attend pas le code (il ne touche ni `game/` ni la logique).

### Option B — lots d'art en parallèle des J32 et J33, gel de l'art à l'entrée du J34 (recommandée)

Les lots tournent sur des branches `art-*` dès maintenant, à côté du J32 et de l'outillage du J33,
dans l'ordre du §3. Chaque lot est fusionné dès sa validation, **un à la fois** (couloir
d'intégration unique, levier 2). Le T2 du J33 (harmonisation visuelle) devient le **contrôle final de
la DA** sur S24. **Gel de l'art à l'entrée du J34** : après, seuls les défauts visuels P0/P1.

- **Gel J33–J34** : compatible ; le J33 admet déjà les corrections visuelles qui ne déplacent rien.
  Un lot qui arrive pendant la campagne du J33 relance seulement les parcours des zones touchées.
- **Tests** : chaque lot passe ses tests ciblés et la suite complète avant fusion ; aucun conflit de
  fichiers avec le J32 (données Pokémon, terminal d'échange) ; ≈ 1 suite complète par lot sur le Mac
  (verrou de 2).
- **Dépendance** : DAF.3 et DAF.4 attendent la fusion des J26 à J31 dans `main` (sinon, art sur des
  branches qui bougent). DAF.1 à DAF.2 et DAF.5 à DAF.7 peuvent partir tout de suite.
- **Risque** : quota Codex (épuisé 3 h la nuit du lot 2) et refus de modération ; le gel du J34
  oblige à couper ce qui n'est pas prêt (→ DA-2).

### Option C — par vagues de zones, en continu jusqu'après la 1.0

Une vague par région (début, milieu, fin du jeu), fusionnée au fil de l'eau ; ce qui n'est pas fait
à la RC part en 1.0.x.

- **Gel** : flou ; les J34 à J36 testent un art qui change encore, la bêta voit un jeu inégal.
- **Tests** : plus de régressions visuelles tardives, campagnes à rejouer.
- **Intérêt** : aucun retard ; le jeu étant privé (décision du 2026-10-24), la date de la 1.0 n'a
  pas d'enjeu extérieur.

### Recommandation

**Option B.** L'art ne dépend pas du code et le J33 a déjà prévu sa place (T2) : le faire en
parallèle ne coûte presque rien au calendrier, et le gel à l'entrée du J34 garde la RC propre. On
garde de l'option C la **soupape** : ce qui n'est pas prêt au gel (planches d'exploration,
animations fines, DAF.8) passe en 1.0.x, sans retarder la RC.

## 3. Ordre de remplacement, lots et processus

### 3.1 Ordre (ce que le joueur voit le plus d'abord)

1. **Combat** : le dos de ton Pokémon est à l'écran à chaque combat, pendant tout le jeu.
2. **Les premières heures** : fonds de combat manquants (Forêt de Jade, Routes 2 et 22, Argenta),
   Forêt de Jade, reliquats de Bourg Palette. C'est là que les proches invités jugeront le jeu.
3. **Le chemin principal de la fin** : Safrania, Sylphe, Arènes de Morgane et de Jadielle, Route
   Victoire, Ligue, Grotte Azurée.
4. **La finition** : lumière et ambiance (intérieurs, grottes), identité (icône, démarrage),
   retouches des séries validées « telles quelles ».
5. **Le polish** (soupape 1.0.x) : planches d'exploration, animations fines, cinématiques.

### 3.2 Lots

| Lot | Contenu | Dépend de | Agent |
|---|---|---|---|
| **DAF.0** Mesure | inventaire refait sur `main` après les fusions (commandes de `inventaire-art.md`) ; état réel des séries 23 et 25 ; fonds de combat de toutes les cartes ; grille d'harmonisation du J33 T2 écrite d'avance (sols, bâtiments, personnages, Pokémon, eau, donjons, combats, menus) | rien | Sonnet |
| **DAF.1** Dos de combat | fusion de `art-dos-combat` (après mise à jour sur `main`) ; 6 refusés + Ptéra, Magmar par Kevin (ChatGPT) ; 4 conditionnels ; espèces des J26 à J32 jusqu'à 151 (`serie_dos.py`) | J32 pour les dernières espèces | Sonnet |
| **DAF.2** Fonds de combat | 6 lieux connus + zones des J26 à J31 (`tools/art/combat_decors/`) | fusions J26–J31 pour la 2e moitié | Sonnet |
| **DAF.3** Safrania et Sylphe | 17 façades, 7 + 2 intérieurs, sur le modèle de la série 22 bis (remplacement à l'identique, modules si besoin) | fusion J26–J27 | Sonnet ; Opus si modules |
| **DAF.4** Fin du jeu | dalles et intérieur de l'Arène de Jadielle, kit de la Route Victoire (interrupteur, barrière, gardes), cinq salles de la Ligue, Grotte Azurée et Mewtwo | fusion J28–J31 | Sonnet ; Opus pour les modules |
| **DAF.5** Séries en attente et reliquats | intégration des séries 23 et 25 si absentes ; objets de Bourg Palette ; Chenipan d'ambiance ; pont du S.S. Anne ; retouches retenues des séries 22 bis et 28 (→ DA-9) | DAF.0 | Sonnet |
| **DAF.6** Lumière et ambiance | Forêt de Jade (profil `forest`, `DenseForest`) ; intérieurs « vraie DA » (lumière chaude des références) ; Mont Sélénite ; contrôle 60 i/s et mémoire sur S24 et A17 | rien (Godot seul) | Opus |
| **DAF.7** Identité | icône de l'appli, écran de démarrage (remplace « GODOT »), contrôle de l'écran titre | rien | Sonnet |
| **DAF.8** Polish (soupape) | planches d'exploration des Pokémon de Coupe, Surf, etc. ; animations des sauts et du recul ; orientations des cinématiques ; détails de combat du J9 | après la RC si besoin | Sonnet |

### 3.3 Processus de production (inchangé, éprouvé par les séries 18 à 28)

1. **Fiche de série** (`docs/design/fiches-assets/serie-NN-*.md`) : identifiants, tailles finales,
   emprises, ADN visuel v1 recopié mot pour mot, lumière **neutre** (méthode C), ancre de style.
2. **Prompts versionnés** par un outil de série (`tools/art/serieNN.py`, sur le modèle de
   `serie22bis.py` et `serie_dos.py`) ; essais r1 avec images jointes, puis r2 sans, et **sans nommer
   l'espèce** (astuce d'Évoli).
3. **Génération par Codex** (`tools/art/generer.sh`, abonnement ChatGPT Pro de Kevin, aucune API
   payante). Refus → **Kevin colle le prompt dans l'appli ChatGPT** (avec jointes d'abord). Dos que
   ni Codex ni ChatGPT ne passent → chaîne **3D + repeint par IA sur Colab** (fiche
   `serie-combat-dos-pilote.md` §7 ; Kevin lance le carnet).
4. **Préparation** (`--preparer` : détourage, taille finale, zéro écart de taille avec le provisoire)
   puis **planche de contact à l'échelle du jeu** (`build/art/SERIE*_CONTACT*.png`).
5. **Validation de Kevin sur planche**, dans un créneau groupé (levier 5) : il choisit l'essai par
   identifiant (`RETENUS`) ou demande une révision rN+1.
6. **Intégration** (une session) : copie dans `assets/`, manifeste, règles d'emprise, captures Mac
   relues, `tools/dump_map_logic.gd` avant/après, tests ciblés, **suite complète** avant fusion.
7. **Contrôle S24** par un agent (QA bornée à 30–45 min, départs de débogage) : lisibilité,
   60 i/s, mémoire des textures ; une remarque de rendu restante va au registre du J33.
8. **Fusion dans `main`**, un lot à la fois.

## 4. Ce que Kevin doit décider

- **DA-1 — Placement.** A (jalon dédié avant la RC), **B (lots en parallèle des J32–J33, gel de
  l'art à l'entrée du J34)** ou C (vagues jusqu'après la 1.0) ? *Recommandation : B.*
- **DA-2 — Périmètre avant le gel.** DAF.0 à DAF.7 obligatoires avant la RC, DAF.8 en 1.0.x ? Ou tout,
  DAF.8 compris, avant la RC ? *Recommandation : DAF.0–DAF.7 avant, DAF.8 après.*
- **DA-3 — Faces des Pokémon.** Garder l'artwork officiel pour l'adversaire, le Pokédex et les menus
  (décision du 2026-10-05 ; jeu privé, donc pas d'enjeu de diffusion), ou les repeindre « dans la
  même main » que le monde (`vision.md`), soit ≈ 151 images de plus ? *Recommandation : garder.*
- **DA-4 — Dos refusés par Codex** (≈ 10). Tu les fais dans l'appli ChatGPT (≈ 1 h), ou chaîne
  3D + Colab ? *Recommandation : ChatGPT d'abord, Colab seulement pour ceux qui échouent.*
- **DA-5 — Fusion de `art-dos-combat`.** 79 espèces à dos peint attendent depuis le 2026-10-22 :
  la mettre à jour sur `main` et la fusionner en premier lot ? *Recommandation : oui.*
- **DA-6 — Validation.** Une planche de contact par lot (créneau groupé) + un contrôle S24 par agent,
  ton regard final au J33 T2 ? Ou une session S24 de ta part par lot ? *Recommandation : la
  première.*
- **DA-7 — Gel de l'art.** À l'entrée du J34 ; après, seulement les défauts visuels P0/P1 ?
  *Recommandation : oui.*
- **DA-8 — Audio.** Hors de la phase DA, cadré à part (musique et ambiances provisoires) ? Ou dans
  la même phase ? *Recommandation : à part, cadrage séparé.*
- **DA-9 — Retouches des séries validées « telles quelles »** (22 bis : coques partagées, 4F
  recoloré ; 28 : porte arrière du Musée). Les refaire, ou seulement si la grille du J33 les classe
  P2 ou plus ? *Recommandation : seulement si la grille les signale.*

## 5. Effort estimé

### 5.1 Hypothèses

- Rythme observé : série 22 bis (44 images, intégration, modules) ≈ **3 sessions sur 1 jour** ;
  lot 2 des dos (60 espèces, 55 générées en une nuit, révisions, intégration) ≈ **3 sessions sur
  2 jours**.
- Un lot = 1 session de fiche et génération + 1 session d'intégration (+ 1 si modules ou révisions
  lourdes) ; le contrôle S24 est une demi-session d'agent.
- Codex : ≈ 50 à 60 images par nuit avant la limite de quota ; ≈ un tiers des espèces ne passent qu'à
  r2–r4, ≈ 8 % jamais.
- 2 à 3 sessions d'art en parallèle au plus (fichiers disjoints), une seule intégration à la fois.
- DAF.3 et DAF.4 attendent les fusions des J26 à J31 : le calendrier dépend de celles-ci.

### 5.2 Estimation

| Lot | Sessions | Images | Temps de Kevin |
|---|---|---|---|
| DAF.0 | 1 | — | — |
| DAF.1 | 2–3 | 35–50 | 1 planche + ≈ 10 images ChatGPT (≈ 1 h) |
| DAF.2 | 1–2 | 6–15 | 1 planche |
| DAF.3 | 2–3 | ≈ 30 | 1 planche |
| DAF.4 | 3–4 | 40–60 | 1 à 2 planches |
| DAF.5 | 1–2 | ≈ 10 | 1 planche |
| DAF.6 | 2 | — | captures avant/après |
| DAF.7 | 1 | 2–3 | 1 choix d'icône |
| **Cœur (DAF.0–DAF.7)** | **13 à 18 sessions** | **≈ 120 à 160** | **≈ 7 planches, ≈ 1 h de ChatGPT, J33 T2** |
| DAF.8 (soupape) | 4 à 8 | selon les espèces | 1 à 2 planches |

En option B, avec 2 à 3 lots en parallèle : **≈ 5 à 8 jours** pour le cœur, dont une partie
masquée par le J32 et l'outillage du J33. Le chemin critique est la fusion des J26 à J31 (pour DAF.3
et DAF.4), pas la production d'art.

## 6. Prochaine étape

Après les réponses de Kevin : lancer **DAF.0** (mesure, Sonnet) et **DAF.1** (fusion de
`art-dos-combat` puis dos restants) en sessions séparées ; ajouter une ligne « lots d'art DAF » dans
les plans J33 (§0.2, T2) et J34 (condition d'entrée : gel de l'art) quand ces plans seront repris
sur `main`.
