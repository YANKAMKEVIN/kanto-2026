# Dossier 19 — S.S. Anne et Badge Foudre (jalon 16)

> **Statut : VERROUILLÉ le 2026-10-15** : textes validés par Kevin (lot du §0.5, qui remplace le
> §15 et complète le §4), grilles validées (§0.4), plan `docs/tech/jalon-16.md` validé sur le
> principe. Reste : les trois vues générales (Mac). Base : la V3 de ChatGPT du 2026-10-15 (copie intacte :
> `passes/j16-v3-chatgpt.md`), relue par Claude le même jour contre `main` (J14 fusionné).
> Historique : V2 de Kevin → passe `passes/j16-v2-alignement.md` (G-1 à G-10, corrections des
> 13 et 14 octobre) → prompt `prompts/chatgpt-dossier-16-ss-anne.md` → V3.
>
> **Le §0 prévaut sur le corps du dossier** (§1 à §17, texte de la V3 inchangé) partout où ils
> diffèrent. Les corrections du §0 sont des valeurs par défaut (règle 4 de `CLAUDE.md`) ou des
> constats sur le code réel ; aucune ne rouvre G-1 à G-10.
>
> **Numérotation** : 13 = ouverture, 14 = J11, 15 = J12, 16 = J13, 17 = J14, 20 = J17
> (`docs/dossier-20-j17`), 22 = J19 (`docs/dossier-j19`) → **19** libre (vérifié sur toutes les
> branches distantes le 2026-10-15) ; 18 reste au J15. Kit d'art : prochaine série libre au moment du
> 16.0.
>
> **Code** : après la clôture du J15 (C-7 : un seul jalon à la fois dans le moteur de combat et la
> sauvegarde). Conception, vue générale peinte, grilles et art peuvent avancer avant.

## 0. Relecture de Claude (2026-10-15) — corrections à appliquer

### 0.1 Ce que le code réel change

| # | V3 | Réalité de `main` | Correction |
|---|---|---|---|
| R-1 | Sonicboom à créer | **existe** depuis le J12 (`data/pokemon/moves/mt_moon.json`, 20 dégâts fixes) | rien à créer ; restent **Coupe** et **Tonnerre** |
| R-2 | « choix → scène » à construire | **existe** depuis le J12 (`confirm_cutscene` de `DialogueChoice`) | PARTIR / PAS ENCORE et COUPER / LAISSER le réutilisent |
| R-3 | Corde Sortie à refuser dans le navire (Q-6) | elle ne marche **que dans les grottes** (`field_item_rules.gd`, `caves.json`) ; ailleurs le refus « Impossible de l'utiliser ici. » existe déjà | Q-6 close ; TXT-34 = texte existant, pas un nouveau texte |
| R-4 | Espèces présumées présentes | **toutes présentes** : Abra, Kadabra, Machoc (J14), Voltorbe (J12), Kokiyas, Stari, Poissirène, Hypotrempe, Mystherbe, Dardargnan, Pikachu, Raichu, Roucoups, Rattatac, starters évolués | **zéro espèce nouvelle** confirmé |
| R-5 | Capacités des équipes | toutes présentes (Balayage, Poing Karaté, Repli, Picpic, Vol-Vie, Dard-Venin, Furie, Armure…) sauf **Doux Parfum** (n'existe pas) | Fillette Léna : Mystherbe **Vol-Vie, Poudre Toxik** (repli prévu par la V3) |
| R-6 | Objets : Super Potion ×3, Huile, Baie | **aucun des trois n'existe** | **Super Potion** créée en données (soin existant : 50 PV, 700 ₽, Rouge/Bleu) ; **Huile** (restaure des PP = mécanique absente) → **Anti-Para** (existe, utile contre Major Bob) ; **Baie** → Potion (repli prévu par la V3) |
| R-7 | Drapeaux `ss_trainer_NN_defeated`, `ss_item_NN_taken` | conventions du moteur : `beaten_<id du Dresseur>` (posé par `TrainerEncounter`), `got_<id de l'objet>` | suivre les conventions ; ids des Dresseurs `ss_anne_<nom>` et `vermilion_gym_<nom>` |
| R-8 | `vermilion_gym_leader_defeated` + `badge_thunder` | `badge_thunder` existe (`data/badges.json`) et suffit (modèle du J13 : `misty_met`, `badge_cascade`, `tm11_received`) | `surge_met`, `badge_thunder`, `tm24_received` ; pas de drapeau « leader_defeated » |
| R-9 | Objectifs avec majuscule (« Monter à bord… ») | convention : minuscule et point (« obtenir le Badge Cascade. ») | « monter à bord du S.S. Anne. », etc. ; **« Explorer Kanto librement. » retiré** : l'objectif après le Badge Foudre appartient au J17 (`dossier-20`) |
| R-10 | Noms Scout Noé, Marin Hugo, Marin Malo | Scout Noé (forêt), Gamin Hugo, Gamin Malo **existent** | **Scout Basile**, **Marin Erwan**, **Marin Loïc** (règle du Scout Théo, dossier 10) |
| R-11 | Accords « gentil », « jeune ami », « jeune Dresseur » | héros masculin (dossier 13, option A) | conservés |
| R-12 | Kadabra : Choc Mental seul | Télékinèse n'existe pas ; Téléport et Entrave exclus | **Choc Mental, Rafale Psy** (choisies à la main, comme Pierre ; la confusion fonctionne depuis le J11) ; recalable par simulation |
| R-13 | Carte `vermilion_dock` séparée | Carmin appartient au J15 (non livré) | le quai est **où le J15 le pose** (carte de ville ou carte à part) ; le J16 s'y raccorde. Ajout au contrat d'entrée : le navire et son warp sont des objets que le J16 peut retirer par drapeau |
| R-14 | Tailles des cartes (pont principal 72 × 26, Arène 52 × 36…) | budget ≤ 3 000 nœuds par carte ; Arène d'Argenta 15 × 11 | tailles = **plafonds** ; la grille `tools/plans/*.txt` fait foi après la vue générale |
| R-15 | 16.0 = plans + données | filière du projet : **vue générale peinte** validée par Kevin, puis grilles, puis kit d'art | 16.0 commence par la vue générale du navire et de l'Arène |
| R-16 | QA « Galaxy S24 » | les validations se font sur le **S21** depuis le 2026-10-10 | même procédure, téléphone de Kevin |
| R-17 | CS01 « objet » | catégorie `tm` du J11 (réutilisable, compatibilités) | CS01 = objet de catégorie `tm` marqué CS, compatibilités Coupe ajoutées au générateur (Q-3) |

| R-18 | `cut_tree_vermilion_gym`, carte `vermilion_dock` | le J15 a livré (2026-10-15) : arbuste `prop_jeune_arbre_arene_01` (49..50, 10) en `FlagGate.blocking_cells`, drapeau **`cut_vermilion_gym_bush`** ; quai dans `vermilion_city` ; navire = 3 objets absents si `ss_anne_departed` ; passerelle (31..32, 27), marin (31, 26) | le J16 **adopte les noms du J15** (`jalon-16.md` §0.3) |

| R-19 | Rival n° 4 et Major Bob « sans changement de Pokémon » | le J13 a introduit le changement par l'IA (`switch`), utilisé par le rival n° 3 et Ondine ; la règle du dossier venait d'une erreur de Claude | **décision de Kevin du 2026-10-15** : `switch: true` pour le rival n° 4 et Major Bob (les Dresseurs ordinaires restent sans) |

### 0.2 Valeurs par défaut prises (règle 4)

- Super Potion : 50 PV, 700 ₽ ; vendue nulle part au J16 (trouvée seulement).
- Kadabra du rival : Choc Mental, Rafale Psy.
- Gains des Dresseurs : ceux de la V3, à confronter à `prize_per_level` des données existantes au
  16.0.
- Le puzzle tire son hasard à l'entrée dans l'Arène ; état partiel jamais sauvegardé (V3 §9, gardé).

### 0.3 Ce qui reste à Kevin

1. **Valider les textes** : TXT-01 à TXT-33 (§15) et les 39 répliques des 13 Dresseurs (§4), avec les
   trois noms changés (R-10).
2. **Relire le §0** : toute correction contestée se tranche avant le 16.0.

### 0.5 Lot de textes VALIDÉ par Kevin le 2026-10-15 (remplace le §15)

Recommandations de Claude du 2026-10-15, retenues en entier. `{rival}` = prénom du rival,
`{pokemon}` = nom du Pokémon qui coupe. Les 39 répliques des Dresseurs du §4 sont validées telles
quelles, avec les noms de R-10 (Scout Basile, Marin Erwan, Marin Loïc).

**Navire et passerelle**
1. Titre de zone : « S.S. ANNE » / « Le grand paquebot de Kanto »
2. TXT-01, marin, Passe Bateau : « Ton Passe Bateau, s'il te plaît. » / « Parfait, bienvenue à bord ! »
3. TXT-02, sans Passe Bateau : « Il te faut un Passe Bateau » / « pour monter sur ce navire. »
4. TXT-03, sortie avant la CS01 (une fois) : « Tu redescends à terre ? Le navire reste à quai pour l'instant. »
5. TXT-04, DEP-01 : « Si tu pars, le navire appareille. » / « Tu ne pourras plus remonter. »
6. TXT-05 : cartes **PARTIR** / **PAS ENCORE**
7. Marin, après PAS ENCORE : « Prends ton temps. On ne part pas sans toi. »
8. TXT-06, DEP-02 (légende) : « Le S.S. Anne quitte Carmin. »
9. TXT-07, DEP-03 (quai, ensuite) : « Le S.S. Anne a pris le large. »

**PNJ d'ambiance**
10. Hôtesse : « Bienvenue à bord du S.S. Anne ! Les cabines sont au nord. »
11. Passager : « Le capitaine ? On ne l'a pas vu depuis le départ… »
12. Matelot : « Le pont inférieur, c'est chez nous. Les passagers se perdent toujours ici. »
13. Serveur : « Désolé, la cuisine est réservée au personnel. »
14. Convive : « Le repas est délicieux. Dommage que la mer bouge autant. »
15. Passagère, pont extérieur : « Regarde, on voit tout Carmin d'ici ! »

**Rival n° 4**
16. Introduction : « Tiens. Toi aussi, tu as un billet. » / « Le capitaine ? Il a le mal de mer. Il ne quitte plus sa cabine. » / « Moi, j'ai déjà fait le tour du navire. Voyons si tu as avancé, toi aussi. »
17. Le joueur perd : « Tu vois ? Toujours une longueur d'avance. » / « Va te soigner à Carmin. Je ne bouge pas. »
18. Reprise : « Déjà de retour ? » / « Bien. Cette fois, ne me déçois pas. »
19. Le joueur gagne : « …D'accord. Cette fois, je l'admets. » / « Tu avances vite. Trop vite. » / « Va voir ton capitaine. Moi, j'ai mieux à faire. »

**Capitaine**
20. CAP-01 : « Ooh… ce roulis… » / « Le capitaine qui a le mal de mer… C'est le comble. »
21. Narration : « Tu lui frottes doucement le dos. »
22. CAP-02 : « Ah… merci. Ça va beaucoup mieux. »
23. CAP-03 : « Tiens, prends ça. C'est la CS01, Coupe. » / « Avec elle, un Pokémon de ton équipe peut tailler les petits arbres. Il faut le Badge Cascade, par contre. » / « Tu peux aussi la lui apprendre, comme une CT. »
24. CAP-04 : « Merci encore ! » / « Profite bien de la traversée. »

**Arbuste**
25. ARB-00, sans la CS01 : « Un arbuste barre le passage. » / « Il faudrait savoir le couper. »
26. ARB-01, sans le Badge Cascade : « Sans le Badge Cascade, {pokemon} n'ose pas couper cet arbuste. »
27. ARB-02, équipe incompatible : « Aucun Pokémon de l'équipe » / « ne peut couper cet arbuste. »
28. ARB-03 : « {pokemon} peut couper cet arbuste. » / « Utiliser Coupe ? » → **COUPER** / **LAISSER**
29. ARB-04 : « {pokemon} utilise Coupe ! »

Note : ARB-01 nomme un Pokémon compatible s'il y en a un ; sinon (pas de badge et aucun compatible),
ARB-01 prime avec le premier Pokémon de l'équipe (défaut, dossier §7).

**Arène de Carmin**
30. Panneau : « ARÈNE DE CARMIN » / « Champion : Major Bob — L'homme électrique »
31. Guide : « Major Bob s'est retranché derrière une barrière électrique ! » / « Les interrupteurs sont cachés dans les poubelles. Il en faut deux, côte à côte. » / « Une erreur, et tout se remet à zéro. »
32. GYM-01 : « Rien… juste des papiers froissés. »
33. GYM-02 : « Un interrupteur ! » / « Le premier verrou cède. »
34. GYM-03 : « Le second interrupteur ! » / « La barrière s'ouvre ! »
35. GYM-04 : « Mauvais interrupteur ! » / « Les verrous se referment. »

**Major Bob**
36. Introduction : « Hé, petit ! Tu as réussi à ouvrir ma barrière ? » / « Pas mal. Mais ici, c'est l'électricité qui commande. » / « Voyons si tu tiens le choc ! »
37. Le joueur perd : « Trop lent, petit ! » / « Reviens quand tu tiendras la charge. »
38. Reprise : « Encore toi ? J'aime ça. En position ! »
39. Le joueur gagne : « Ouch ! Tu m'as bien secoué. » / « Du cran, petit. Tu as gagné. »
40. Badge : « Voici le Badge Foudre. » / « Il prouve que tu as tenu le choc face à Major Bob. »
41. Légende : « BADGE FOUDRE »
42. CT24 : « Prends aussi ceci. » / « C'est la CT24, Tonnerre. Un Pokémon qui l'apprend la garde, et tu peux t'en resservir. »
43. Rattrapage de la CT : « J'allais oublier. » (puis 42)
44. Après, en lui reparlant : « Fais bon usage du Badge Foudre ! »

**Objectifs** (R-9) : « aider le capitaine. », « obtenir le Badge Cascade. », « rejoindre l'Arène
de Carmin. », « ouvrir le passage vers Major Bob. », « affronter Major Bob. ».

**Restent au plan (annexe A, T3)** : descriptions de Coupe, Tonnerre, CS01, CT24, Super Potion ;
zone du Pokédex et de la Carte.

### 0.4 Grilles et vues générales (grilles **validées par Kevin le 2026-10-15** ; vues générales à générer)

- **Grilles** (font foi sur le §3, R-14) : `tools/plans/ss_anne_pont_principal.txt` (26 × 13),
  `ss_anne_couloir_capitaine.txt` (18 × 7), `ss_anne_cabine_capitaine.txt` (14 × 10),
  `ss_anne_restaurant.txt` (18 × 11), `ss_anne_pont_inferieur.txt` (22 × 11),
  `ss_anne_pont_exterieur.txt` (26 × 11), `ss_anne_cabine_a|b|c.txt` (12 × 9),
  `carmin_arene.txt` (17 × 15). Le quai reste au J15.
- **Contrôle** : `python3 tools/art/plan_check_ss_anne.py` — tout est vert : tout est atteignable ;
  Armand et Paul évitables, **0 Dresseur inévitable** hors rival ; rival inévitable (déclencheur sur
  les 3 cases de largeur du couloir) ; barrière fermée = Major Bob inaccessible, ouverte =
  accessible ; 15 objets fouillables. Les 3 Dresseurs de l'Arène sont **évitables** (défaut validé avec les
  plans ; Rouge/Bleu en impose au moins un).
- **Planche** : `docs/design/reference/ss-anne-plans-v1.png` (`python3 tools/art/plan_ss_anne.py`).
- **Vues générales à générer sur le Mac** (Codex, `tools/art/generer.sh`) :
  - `tools/art/generer.sh CONCEPT_SS_ANNE_PONT_PRINCIPAL_r1 tools/art/prompts/CONCEPT_SS_ANNE_PONT_PRINCIPAL_r1.txt docs/design/reference/labo-chen-v1.png`
  - `tools/art/generer.sh CONCEPT_SS_ANNE_PONT_EXTERIEUR_r1 tools/art/prompts/CONCEPT_SS_ANNE_PONT_EXTERIEUR_r1.txt docs/design/reference/azuria-vue-generale-v1.png docs/design/reference/labo-chen-v1.png`
  - `tools/art/generer.sh CONCEPT_ARENE_CARMIN_r1 tools/art/prompts/CONCEPT_ARENE_CARMIN_r1.txt docs/design/reference/labo-chen-v1.png`

  Fait le 2026-10-15 (branche `j16-vues-generales`) : plans en aplats sans annotation joints en image 1
  (`python3 tools/art/plan_aplats_ss_anne.py` → `build/art/PLAN_*_v1.png`), coque validée de
  `carmin-vue-generale-v1.png` jointe pour le pont extérieur ; meilleurs essais : pont principal `_r3`,
  pont extérieur `_r2`, Arène `_r3` (prompts `tools/art/prompts/CONCEPT_*_r1..r3.txt`), à valider par Kevin.

  Une fois validées par Kevin : `reference/ss-anne-pont-principal-v1.png`,
  `ss-anne-pont-exterieur-v1.png`, `arene-carmin-v1.png` ; les autres salles du navire suivent le
  rendu du pont principal.

Aucune autre décision de game design n'est ouverte : Q-1 à Q-11 (§16) sont techniques et seront
réglées au plan `docs/tech/jalon-16.md`.

---

## 1. Intention — deux phrases

Le S.S. Anne offre une exploration libre, chaleureuse et mémorable, où le joueur affronte une nouvelle fois son rival et aide un capitaine malade avant de recevoir la CS01 Coupe. À Carmin, Coupe donne accès à une Arène au puzzle exigeant dont la victoire contre Major Bob consacre la progression par le Badge Foudre, sans bonus caché. [RB pour le parcours ; K26 pour la confirmation de départ et la mise en scène]

## 2. Contrat d'entrée J13–J15 — G-1, version finale amendée

**Important :** la passe ne contient pas un bloc contractuel unique déjà rédigé « mot pour mot » dans sa version du 14 octobre : elle comporte G-1 puis des corrections datées. Le bloc suivant est donc la **formulation contractuelle consolidée**, et non une fausse citation littérale de Claude.

> J13 fournit Azuria, le Pont Pépite, le rival n° 3 vaincu, le Badge Cascade `badge_cascade` obtenable mais **non obligatoire** avant l'accès au Passe Bateau. Le rival n° 3 possède Roucoups N16, Rattata N14 et le starter évolué N16, **sans Abra** ; si le dépôt indique des niveaux différents, les niveaux de `docs/tech/jalon-13-equilibrage.md` sur `main` font foi et le J16 n'en déduit pas ses niveaux automatiquement.
>
> J14 fournit le Cap Azuria, Léo (Bill), donneur du **Passe Bateau** `ss_ticket` de catégorie `key`, non consommable et conservé après le départ ; l'enfant de Bourg Palette est nommé **Nils**. Le Passe Bateau peut être obtenu avant la victoire contre Ondine.
>
> J14–J15 fournissent l'accès à Carmin via Routes 5/6 et passage souterrain, Carmin-sur-Mer avec Centre Pokémon, quai, navire amarré visible, passerelle d'embarquement et Arène derrière un arbuste. Le J15 pose l'arbuste de l'Arène, mais ne le rend pas coupable avant le J16.
>
> J13–J15 rendent capturable avant Carmin, indépendamment du starter, au moins une espèce compatible avec Coupe : Dardargnan, Sabelette, Paras, Chétiflor ou Mystherbe. Les espèces Abra, Kadabra, Machoc, Voltorbe, Pikachu, Raichu, Roucoups, Rattatac, Kokiyas, Stari, Poissirène et Hypotrempe sont présumées présentes selon l'état J14 déclaré par l'utilisateur ; Claude doit vérifier la disponibilité effective et les assets dans la branche de référence.
>
> **Coupe exige le Badge Cascade** pour couper les arbustes ; le S.S. Anne et la CS01 restent accessibles sans ce badge. La victoire contre Ondine précède donc obligatoirement l'accès à l'Arène de Major Bob, sans garde supplémentaire. [RB pour la condition ; K26 pour le modèle hybride]

**Identifiants d'entrée minimaux :** `badge_cascade`, `ss_ticket`, victoire rival n° 3, zones Azuria/Carmin/Routes 5–6/passage souterrain, navire amarré et arbuste d'Arène ; vérifier les noms exacts existants, ne pas créer des doublons. **Numérotation :** 16 et 17 sont pris ; le présent numéro 19 est celui demandé, à revérifier au push.

## 3. Plans fonctionnels ASCII

**Convention commune :** 1 case ≈ 1 m, viewport ≈ 24 × 11 ; origine (0,0) en haut à gauche ; plans ci-dessous **schématiques et non grille exhaustive**, les dimensions sont contractuelles pour le prototype et doivent être confirmées avec `tools/plans/*.txt` avant placement. `#` mur/bord, `.` passage, `D>` Dresseur regard est, `D<` ouest, `D^` nord, `Dv` sud, `o` objet visible, `?` objet caché, `S` escalier, `W` warp/porte, `R` rival, `C` capitaine, `A` arbuste, `i` objet à fouiller, `X` barrière, `G` Major Bob, `M` marin de passerelle. Les coordonnées précises ci-dessous ont priorité sur les diagrammes miniatures ; aucun Dresseur ne regarde à travers un mur. Pas d'isométrie.

### 3.1 Carmin, quai et passerelle — `vermilion_dock` 64×32

```text
 N ↑              CARMIN
 ########################
 # CENTRE     ARENE A W #   A=(51,7), porte Arène=(53,7)
 #                      #
 #     quai . . . . M W #   M=(35,21) regarde ouest
 #     mer ~ ~ ~ ~ ~ ~  #   W=(37,21) vers navire
 #       [ S.S. ANNE ]  #   coque conditionnelle
 ########################
```

Le quai reste praticable après départ ; la coque et le warp sont désactivés par `ss_anne_departed`. Aucun objet caché indispensable. [K26]

### 3.2 Pont principal — `ss_main_deck` 72×26

```text
 ################################
 # W quai  . . D> . . W cabines #
 # . . . . . . . . . . . . . .  #
 # W restaurant . . W inférieur #
 # . . . . . o . . . . W extér. #
 # . . . . . . W couloir capit. #
 ################################
```

Warps : quai (4,21), cabines (58,5), restaurant (12,18), pont inférieur (43,18), extérieur (65,18), couloir capitaine (61,22). Dresseur T01 (20,7) regard est, facultatif ; objet visible Potion (36,20). Deux sorties vers le quai avant CS01 ; après CS01 la passerelle confirme le départ. [K26]

### 3.3 Pont inférieur — `ss_lower_deck` 64×24

```text
 #############################
 # S principal  . . Dv . .  o #
 # . . W cabines . . . . . .  #
 # . . . . D< . . . . ? . . . #
 #############################
```

S=(5,3), Dresseurs T02 (24,7) regard sud, T03 (32,16) regard ouest, objets Super Potion visible (54,7), objet caché Antidote (48,17). Les lignes de vue sont interrompues par mobilier. [K26]

### 3.4 Restaurant — `ss_restaurant` 46×26

```text
 ########################
 # W . tables . . . .   #
 # . D> . . . . o . .   #
 # . tables . . . . .   #
 # . . ? cuisine W      #
 ########################
```

W principal (3,20), cuisine décorative (38,20) sans carte supplémentaire ; T04 (10,9) regarde est ; objet visible Super Potion (29,9), caché Baie (12,20), si l'objet Baie existe dans le système, sinon Potion cachée. Pas de cuisine jouable. [K26]

### 3.5 Pont extérieur — `ss_outer_deck` 66×22

```text
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 # W . . Dv . . . . . . o .  #
 # rambarde . . . D< . . . . #
 ##############################
```

W principal (4,10), T05 (18,5) regard sud, T06 (42,13) regard ouest, objet visible Huile (56,7). Mer en fond, pas de collision traversable au-delà de la rambarde. [K26]

### 3.6 Cabines des passagers — `ss_cabin_a`, `ss_cabin_b`, `ss_cabin_c` : 18×14 chacune

```text
 ##############
 # lit . o . .#
 # . . Dv . . #
 # . . . . . .#
 # . W . . ?  #
 ##############
```

A : warp pont principal (7,12), T07 (8,5) regard sud, objet visible Potion (6,3). B : warp pont inférieur (7,12), T08 (8,5) regard sud, objet caché Réveil (13,11). C : warp pont principal (7,12), T09 (8,5) regard sud, objet visible Super Potion (6,3). Un Dresseur par cabine, tous évitables en restant dans le couloir. [K26]

### 3.7 Couloir du capitaine — `ss_captain_corridor` 44×14

```text
 ################################
 # W entrée . . R< . . . W cap. #
 # . . . . . . . . . . . . . .  #
 ################################
```

Entrée (3,7), rival R=(23,7) regarde ouest, porte capitaine (41,7). Le déclencheur couvre la largeur du passage, sans contournement. Après victoire, rival absent. Pas de Dresseur autre que le rival. [RB emplacement narratif ; K26 victoire obligatoire]

### 3.8 Cabine du capitaine — `ss_captain_room` 28×18

```text
 #######################
 # bureau . . C< . .  #
 # . . . . . . . . . . #
 # . . . W retour . . #
 #######################
```

C=(17,6), regard ouest ; W=(13,15). CS01 remise par interaction avec C. Aucun mini-jeu. [RB/K26]

### 3.9 Arène de Carmin — `vermilion_gym` 52×36

```text
 #################################
 # . i . i . i . i . i . i . .  #
 # . . . Dv . . . . . D< . . .  #
 # . i . i . i . i . i . i . .  #
 # . . . . . X X X . . . . . . #
 # . i . i . i . i . i . i . .  #
 # . . . . . . . . Gv . . . . . #
 # . W entrée . guide . . . .  #
 #################################
```

Porte (25,33), guide (29,31), T10 (13,10) regard sud, T11 (38,10) regard ouest, T12 (19,24) regard nord ; Major Bob G=(28,27) regard sud ; barrière X=(23..29,19). **15 objets à fouiller** en grille 3×5, coordonnées : x={8,17,26,35,44}, y={6,14,22}. Tous sont visuellement identiques, interactifs et lisibles. Aucun indice visuel ne désigne la bonne paire. La barrière et les objets ne gênent jamais la sortie. [RB puzzle ; K26 implantation]

**Nombre de Dresseurs sur navire : exactement 10** (T01–T09 et T13 ci-dessous). T13 est dans le pont principal, côté cabines, position (51,11), regard nord, facultatif. **Trois Dresseurs d'Arène distincts** T10–T12. **Au plus deux inévitables hors rival : zéro dans ce plan**, le placement doit être testé sur la grille complète. Le capitaine n'est pas un Dresseur.

## 4. Dresseurs ordinaires, équipes, argent, dialogues

**Convention :** les montants sont des propositions en Pokédollars [K26] ; Claude vérifiera les multiplicateurs de classes existants et pourra remplacer les valeurs sans toucher aux décisions de parcours. Les capacités proposées doivent être validées dans `data/moves` ; aucune capacité interdite ne figure dans ces équipes. **Toutes les équipes et niveaux de cette section sont des propositions à simuler, pas des équipes historiques certifiées.** Répliques : chaque `/` indique un saut de ligne (2 lignes max par bulle, ≈40 caractères par ligne).

| ID / emplacement | Classe, nom | Équipe (niveau ; capacités proposées) | Gain | Avant / après victoire joueur / après défaite joueur |
|---|---|---|---:|---|
| T01 principal | Gentleman Armand | Rattata 17 (Charge, Vive-Attaque), Rattatac 19 (Vive-Attaque, Morsure) | 760 | « Un voyage forme le caractère ! » / « Tu as du talent, jeune ami. » / « Reviens après t'être entraîné. » |
| T02 inférieur | Marin Hugo | Machoc 18 (Balayage, Poing-Karaté) | 360 | « Tu as le pied marin ? » / « Je manque d'entraînement ! » / « La mer me donne de la force ! » |
| T03 inférieur | Marin Malo | Kokiyas 18 (Charge, Repli), Poissirène 18 (Picpic, Mimi-Queue) | 360 | « Je connais ces eaux par cœur. » / « Tu connais aussi les combats ! » / « Cap sur une autre victoire ! » |
| T04 restaurant | Gentleman Émile | Pikachu 18 (Éclair, Vive-Attaque) | 720 | « À table, puis au combat ! » / « Quel service remarquable ! » / « Le dessert attendra ! » |
| T05 extérieur | Marin Yann | Hypotrempe 18 (Écume, Groz'Yeux), Kokiyas 18 (Charge, Repli) | 360 | « Le vent me porte chance ! » / « Le vent a tourné... » / « Rien ne vaut le grand air ! » |
| T06 extérieur | Marin Rémi | Machoc 19 (Balayage, Poing-Karaté) | 380 | « Mes bras soulèvent des caisses ! » / « Ton équipe est plus forte ! » / « Je reprends mes exercices ! » |
| T07 cabine A | Fillette Léna | Mystherbe 18 (Vol-Vie, Doux Parfum*) | 180 | « Tu veux jouer avec nous ? » / « Bien joué ! » / « On rejoue plus tard ! » |
| T08 cabine B | Scout Noé | Dardargnan 18 (Dard-Venin, Furie) | 360 | « Regarde mon Pokémon ! » / « Il faut qu'on progresse. » / « Tu as vu comme il est rapide ? » |
| T09 cabine C | Gentleman Victor | Stari 19 (Pistolet à O, Armure) | 760 | « Je voyage pour me détendre. » / « Quelle rencontre ! » / « Un petit défi me plaît. » |
| T13 principal | Marin Paul | Rattatac 19 (Vive-Attaque, Morsure) | 380 | « On ne dort jamais au port ! » / « J'aurais dû me reposer. » / « Le prochain voyage sera mien ! » |
| T10 Arène | Gentleman Louis | Pikachu 20 (Éclair, Cage-Éclair) | 800 | « Le courant passe ici ! » / « Je n'ai pas résisté ! » / « Attention aux décharges ! » |
| T11 Arène | Rockeur Axel | Voltorbe 20 (Charge, Sonicboom) | 400 | « Ça va faire des étincelles ! » / « Je suis à plat ! » / « Mon rythme est électrique ! » |
| T12 Arène | Marin Marc | Pikachu 19 (Éclair, Vive-Attaque), Voltorbe 19 (Charge, Grincement) | 380 | « Même les marins aiment l'orage ! » / « Je baisse pavillon ! » / « Tu n'as pas peur du tonnerre ? » |

*Si Doux Parfum n'existe pas ou est non fonctionnel, utiliser Poudre Toxik si implémentée, sinon Vol-Vie seul. **La composition des 10 équipes du navire utilise zéro espèce nouvelle**, à condition que les espèces déclarées présentes au J14 le soient effectivement. Aucun Tentacool requis. Pour chaque Pokémon, l'ensemble exact des capacités doit être vérifié : si une capacité n'existe pas, la remplacer par une capacité déjà fonctionnelle de la même espèce ; ne jamais introduire silencieusement une mécanique. Les combats ordinaires n'ont pas d'IA de changement.

## 5. Rival n°4 — obligatoire, dans le couloir

**Structure verrouillée [RB] :** Roucoups N19, Rattatac N16, Kadabra N18, starter évolué N20, dans cet ordre. **Choix du dernier Pokémon :** joueur Bulbizarre → rival Reptincel ; joueur Salamèche → rival Carabaffe ; joueur Carapuce → rival Herbizarre. IA `smart`, **aucun changement volontaire de Pokémon** ; niveaux recalables uniquement après simulation et validation.

| Pokémon | Capacités proposées, toutes sans mécanique interdite |
|---|---|
| Roucoups 19 | Tornade, Vive-Attaque, Jet de Sable |
| Rattatac 16 | Vive-Attaque, Morsure, Mimi-Queue |
| Kadabra 18 | Choc Mental, Téléport **exclu**, Entrave **exclue** ; utiliser Choc Mental et éventuellement une capacité déjà implémentée et légalement compatible validée par Claude |
| Reptincel 20 | Flammèche, Griffe, Rugissement |
| Carabaffe 20 | Pistolet à O, Charge, Mimi-Queue |
| Herbizarre 20 | Fouet Lianes, Charge, Rugissement |

Kadabra peut combattre avec **une seule capacité fonctionnelle** (Choc Mental) si aucune autre capacité autorisée n'est disponible : ne pas inventer un effet ou une capacité. [K26]

**R4-AVANT :** « Tu vas voir le capitaine ? / Il paraît qu'il a le mal de mer ! » puis « Moi, je ne perds pas l'équilibre. / En garde ! ».

**R4-APRÈS VICTOIRE :** « Tu m'as encore dépassé... / Profite bien de ton voyage ! ».

**R4-REPRISE après défaite du joueur :** « Te revoilà ? / Cette fois, tiens bon ! ».

**R4-DÉFAITE du joueur :** « Tu vois ? Je tiens mieux le cap ! ».

**Règles :** défaite → dernier Centre Pokémon, argent inchangé, `ss_rival4_defeated` non posé ; rival reste au couloir et reprend par R4-REPRISE, sans réintroduction. Victoire → `ss_rival4_defeated`, Grand moment une seule fois à la victoire, rival disparaît. Les autres Dresseurs déjà vaincus restent vaincus. [K26]

## 6. Capitaine et CS01 — scène pas à pas

1. Le rival est battu ; le joueur entre dans la cabine.
2. Capitaine penché, animation courte, sans mini-jeu. **CAP-01** « Oh... la mer ne me réussit pas. / Tu peux rester un instant ? »
3. Le joueur s'approche automatiquement d'une case, geste bref. **CAP-02** « Merci... Ça va déjà mieux. / Tu es vraiment gentil. »
4. Le capitaine remet **CS01 Coupe** une seule fois ; le système vérifie l'absence de `ss_hm01_received` avant de donner l'objet. **CAP-03** « Prends cette CS01 : Coupe. / Elle te sera utile à terre. »
5. Pose `ss_hm01_received` après ajout réussi à l'inventaire, point de sauvegarde stable ; aucune autre récompense nécessaire. [K26]
6. Nouvelle interaction : **CAP-04** « Merci encore ! / Profite bien de la traversée. »

Si la CS01 est déjà dans le Sac mais que le drapeau manque (ancienne sauvegarde), réconcilier sans doublon. Si le drapeau existe mais l'objet manque, restaurer l'objet-clé une fois, en journalisant l'anomalie. [TECH]

## 7. Coupe : modèle hybride et arbustes

**[K26]** Obtenir CS01 débloque Coupe dans le monde sans prendre d'emplacement de capacité. Il faut simultanément `ss_hm01_received` (ou possession de CS01), `badge_cascade` et au moins un Pokémon de l'équipe compatible avec Coupe. Aucune obligation de l'avoir enseignée en combat. **[K26]** La CS01 se comporte également comme une CT réutilisable : un Pokémon compatible peut apprendre Coupe en combat, elle prend alors un emplacement normal parmi les quatre et peut être oubliée normalement. **[REC]** Valeurs en combat : Normal, 50 puissance, 95 % précision, 30 PP.

**CS01 dans le Sac :** « CS01 — COUPE / Débloque Coupe dans le monde. / Enseigne aussi une attaque. » (affichage en pages/bulles distinctes si nécessaire).

**ARB-00, avant CS01 :** « Un arbuste barre le passage. / Il faudrait savoir le couper. »

**ARB-01, sans Badge Cascade, même si Pokémon compatible :** « Il faut le Badge Cascade. / Ton Pokémon refuse de couper. » **Sans choix.** Cette branche prime sur le test de compatibilité.

**ARB-02, badge présent, équipe incompatible :** « Aucun Pokémon de l'équipe / ne peut couper cet arbuste. » **Sans choix.**

**ARB-03, toutes conditions réunies :** « Un arbuste bloque le chemin. / Utiliser Coupe ? » → cartes **COUPER** / **LAISSER**.

**ARB-04, après COUPER :** « L'arbuste a été coupé ! »

Animation ≤2 s : le Pokémon compatible choisi selon ordre stable de l'équipe apparaît brièvement à côté de l'arbuste (ou compagnon déjà visible), geste de coupe générique, retrait de l'obstacle, puis drapeau permanent `cut_tree_vermilion_gym`. En cas de LAISSER, rien ne change. La coupure est définitive, même après sortie de carte, stockage, évolution, sauvegarde ou rechargement. [K26]

**Arbustes posés au J16 :** aucun nouveau hors **arbuste de l'Arène posé au J15**, consommé au J16. Les arbustes de Route 2, Route 9 et Céladopole sont gérés par leurs propres jalons, avec identifiants distincts. [K26]

## 8. Départ définitif — confirmation et séquence

Avant CS01 : le marin laisse sortir sans confirmation, navire reste amarré. Après CS01, interaction avec le marin de la passerelle :

**DEP-01 :** « Si tu pars, le navire appareille. / Tu ne pourras plus remonter. »

Cartes **PARTIR** / **PAS ENCORE**. **PAS ENCORE** : ferme la conversation, reste à bord. **PARTIR** : place le joueur sur une case sûre du quai, désactive le warp, déclenche une scène vue du quai ≤10 s (amarres, recul, navire quittant l'écran), pose `ss_anne_departed` et sauvegarde de manière atomique après repositionnement. Le Passe Bateau reste dans le Sac. [K26]

**DEP-02 (pendant la scène) :** « Le S.S. Anne quitte Carmin. »

**DEP-03 (quai après départ) :** « Le S.S. Anne a pris le large. »

Après départ : aucune entrée possible, coque absente, quai intact. Les Dresseurs et objets non traités du navire sont définitivement perdus, ce que la confirmation avertit suffisamment. Si l'application est interrompue avant commit, reprise avant choix ; si après commit, reprise au quai, navire absent. Jamais de sauvegarde avec `ss_anne_departed=true` et position navire. [TECH]

## 9. Arène, puzzle, guide, Major Bob, récompenses

**Guide GUIDE-01 :** « Major Bob aime les défis. / Fouille bien les objets ici. »

**Puzzle [RB strict] :** 15 objets à fouiller, positions fixes. À chaque **entrée dans la carte** tant que `vermilion_gym_puzzle_solved` est faux, choisir aléatoirement un premier objet valide ayant au moins un voisin orthogonal ; le second interrupteur se trouve dans l'un des objets voisins orthogonaux valides, choisi aléatoirement au moment du premier succès ou pré-tiré de façon équivalente. Le joueur fouille librement :

- Objet ordinaire avant succès : **GYM-01** « Rien ici. » ; le premier emplacement correct : **GYM-02** « Un interrupteur ! / Le premier verrou cède. »
- Après premier succès, fouiller le **second objet voisin correct** : **GYM-03** « Le second interrupteur ! / La barrière s'ouvre ! » ; poser `vermilion_gym_puzzle_solved` de manière persistante.
- Tout autre objet après premier succès : **GYM-04** « Mauvais interrupteur ! / Les verrous se referment. » ; remise à zéro de la progression et **nouveau tirage**.
- Sortir avant résolution : progression partielle effacée, nouveau tirage à la prochaine entrée.
- Une fois résolu : barrière ouverte pour toujours ; plus de tirage, même après défaite contre Major Bob.

Le tirage doit être reproductible au sein d'une entrée, mais non exploitable par rechargement de sauvegarde ; l'état partiel ne persiste pas. Ne pas utiliser d'étincelles ni d'indices désignant le bon objet. Les objets à fouiller doivent être clairement interactifs et accessibles sur tactile. **Mécanique nouvelle** : RNG de puzzle, état temporaire du premier interrupteur, vérification de voisinage et reset. [RB/K26/TECH]

**Major Bob :** Voltorbe N21 (Charge, Grincement, Sonicboom), Pikachu N18 (Éclair, Cage-Éclair, Vive-Attaque), Raichu N24 (Éclair, Cage-Éclair, Tonnerre). IA `smart`, aucun switch IA. Les niveaux sont de référence, à recalibrer par simulation sans changer les trois espèces sans arbitrage. **Sonicboom : 20 dégâts fixes, 90 %, 20 PP** ; **Tonnerre : 90, 100 %, 15 PP, 10 % paralysie**. Pas de Destruction, Explosion, Reflet, Mur Lumière, Protection ou Entrave. [RB composition ; REC données ; K26 capacités manuelles]

**BOB-AVANT :** « Je suis Major Bob ! / Voyons si tu tiens le choc ! »

**BOB-DÉFAITE du joueur :** « Reviens avec une équipe solide ! »

**BOB-VICTOIRE du joueur :** « Bien joué, jeune Dresseur ! / Tu mérites le Badge Foudre. »

**BADGE :** carte de Champion générique, Grand moment badge générique, légende exacte **« BADGE FOUDRE »**, vibration courte ; `badge_thunder` (ou identifiant existant à auditer) posé après victoire. **Aucun bonus caché de Vitesse ou d'obéissance.** [K26]

**CT24 :** **CT24 Tonnerre**, réutilisable, remise une seule fois après le Badge ; **BOB-CT :** « Prends aussi cette CT24. / Elle contient Tonnerre. » ; si on lui reparle **BOB-RETOUR :** « Fais bon usage du Badge Foudre ! ». Le système vérifie le drapeau de récompense et l'inventaire. [RB récompense ; K26 CT réutilisable]

## 10. Tableau de bord — progression silencieuse

| État | Texte affiché dans le tableau de bord |
|---|---|
| Arrivée à Carmin, navire accessible | « Monter à bord du S.S. Anne. » |
| À bord, rival non vaincu | « Explorer le S.S. Anne. » |
| Rival vaincu, CS01 absente | « Aider le capitaine. » |
| CS01 obtenue, navire encore amarré | « Rejoindre Carmin. » |
| CS01 obtenue, Cascade absent | « Obtenir le Badge Cascade. » |
| Cascade présent, arbuste non coupé | « Rejoindre l'Arène de Carmin. » |
| Arène accessible, puzzle non résolu | « Ouvrir le passage vers Major Bob. » |
| Puzzle résolu, badge absent | « Affronter Major Bob. » |
| Badge acquis | « Explorer Kanto librement. » |

Aucune fenêtre « OBJECTIF MIS À JOUR », aucune flèche, aucun marqueur ni tutoriel. [K26]

## 11. Drapeaux — anglais snake_case

| Drapeau | Déclencheur | Persistance |
|---|---|---|
| `ss_rival4_defeated` | victoire rival n°4 | permanent |
| `ss_rival4_encountered` | première introduction | permanent, évite réintroduction |
| `ss_hm01_received` | CS01 remise | permanent |
| `ss_anne_departed` | confirmation PARTIR et commit quai | permanent |
| `cut_tree_vermilion_gym` | Coupe réussie | permanent |
| `vermilion_gym_puzzle_solved` | second interrupteur trouvé | permanent |
| `vermilion_gym_leader_defeated` | victoire contre Major Bob | permanent |
| `badge_thunder` | Badge Foudre | permanent, alias éventuel selon schéma réel |
| `vermilion_tm24_received` | CT24 remise | permanent |
| `ss_trainer_01_defeated` … `ss_trainer_10_defeated` | victoires des 10 Dresseurs | permanent |
| `vermilion_gym_trainer_01_defeated` … `_03_defeated` | victoires Dresseurs d'Arène | permanent |
| `ss_item_01_taken` … `ss_item_09_taken` | objets visibles/cachés, si la couche objets fonctionne par flags | permanent |

**État temporaire non sauvegardé :** `gym_first_switch_index`, `gym_second_switch_index`, `gym_first_found`, `gym_entry_seed` ; ne pas les ajouter au schéma de sauvegarde. **Entrées existantes :** `badge_cascade`, `ss_ticket`. Les noms doivent être comparés au dépôt avant ajout, sans dupliquer un flag déjà défini. [TECH]

## 12. Espèces, capacités et art

**Espèces nouvelles indispensables :** **zéro**, sous réserve que J14 fournisse effectivement Abra/Kadabra/Machoc et que les autres espèces citées existent comme déclaré. **Espèces nouvelles possibles :** Tentacool (facultatif, non utilisé dans les équipes arrêtées), et au maximum trois nouvelles espèces au total si l'audit contredit les présupposés ; tout ajout doit être motivé, et son évolution/sa compatibilité doivent être budgétés. [K26]

**Capacités / systèmes indispensables :** Coupe en combat (50/95/30) et sur le terrain, Tonnerre (90/100/15, paralysie 10 %), Sonicboom (20 fixes/90/20), condition Badge Cascade, compatibilité CS issue des données, choix→scène, RNG puzzle, validation du départ atomique. Aucun des effets interdits n'est introduit. Les valeurs des trois capacités sont les **valeurs contemporaines adoptées par le projet**, non une reconstitution pure de la première génération. [REC/K26]

**Art indispensable :** silhouette complète et portraits/overworld peints du capitaine, Major Bob, rival n°4 si évolution visuelle, marins, gentlemen, passagers, Dresseuses/Scout si absents ; navire extérieur amarré/parti, pont principal, inférieur, restaurant, pont extérieur, trois cabines, couloir et cabine capitaine ; quai et Arène ; 15 objets à fouiller, barrière et arbuste ; animation générique de Coupe avec Pokémon visible ; fonds de combat peints **indépendants** : intérieur navire, pont extérieur, Arène électrique ; fronts/dos peints des espèces réellement utilisées, y compris Kadabra, et sprites du monde. [K26/CB.3]

**Souhaitable seulement :** oiseaux marins, ondulation de mer, léger balancement de décor, animations secondaires des passagers, bruits de vaisselle. Aucun asset officiel récupéré du web ne doit être placé dans le dépôt. [K26]

## 13. Cas limites — résultats attendus

| Scénario | Résultat exigé |
|---|---|
| Défaite contre rival, puis Corde Sortie | Réveil au dernier Centre sans perte d'argent ; rival toujours présent ; Corde Sortie ne permet pas d'éviter sa victoire obligatoire ; depuis le navire, Corde Sortie doit être refusée ou renvoyer à un point sûr défini par le moteur, **jamais** au-delà du rival. Choix recommandé : refuser Corde Sortie dans le navire avec texte explicite « Impossible de l'utiliser ici. ». |
| Fermeture pendant écran de confirmation | Aucun départ ; reprise au dernier état stable à bord, confirmation à refaire. |
| Fermeture pendant scène de départ | Avant commit : à bord, navire présent ; après commit : quai, navire absent. Aucun état mixte. |
| Fermeture juste après scène | Reprise au quai, navire absent ; Passe Bateau et CS01 conservés. |
| CS01 obtenue, sortie sans confirmer | La sortie avant CS01 est libre ; **après CS01**, PAS ENCORE maintient à bord. Pour quitter avec CS01, confirmation PARTIR nécessaire. |
| Pokémon compatible déposé au stockage | Coupe indisponible jusqu'à retrait d'un compatible, sauf arbuste déjà coupé définitivement. |
| Équipe totalement incompatible devant l'arbuste | ARB-02, aucun choix ; accès stockage au Centre de Carmin. |
| CS01 obtenue avant Badge Cascade | ARB-01 sans choix ; retour libre à Azuria, battre Ondine puis Coupe fonctionne sans réobtenir la CS01. |
| Premier interrupteur trouvé puis sortie d'Arène | Reset de progression ; nouveau tirage à la prochaine entrée. |
| Défaite contre Major Bob après puzzle | Réveil au Centre, puzzle toujours résolu, barrière ouverte, Bob à retenter, badge/CT absents. |
| Retour dans le navire après départ | Impossible : warp et coque absents, pas de softlock. |
| Sauvegarde après coupe, puis stockage | Arbuste reste coupé, même sans compatible. |
| CT24 donnée, puis interaction avec Bob | Pas de doublon, BOB-RETOUR. |

**Note de cohérence :** « Corde Sortie après défaite » est un cas de non-régression du système général, pas une capacité à utiliser durant l'écran de défaite. L'exactitude du comportement historique de Corde Sortie sur le S.S. Anne doit être auditée ; la règle ci-dessus est une décision de sécurité [K26] proposée.

## 14. Découpage S24 — 16.0 à 16F

| Lot | Livrable | Critère d'acceptation S24 |
|---|---|---|
| **16.0** | Plans `tools/plans`, données, listes de warps, équipes, dialogues, flags, audit des assets et capacités | Relecture approuvée ; pas de code risqué ; dépendances J13–J15 identifiées |
| **16A** | Embarquement, passe, navire et cartes | Tous les warps valides, 24×11 lisible, pas de traversée de murs, navire accessible sans Badge Cascade |
| **16B** | 10 Dresseurs, rival obligatoire | ≤2 Dresseurs ordinaires inévitables ; défaite rival sans argent perdu, reprise courte, Grand moment une seule fois |
| **16C** | Capitaine, CS01 hybride, Coupe, arbuste | Remise unique, Coupe sans emplacement terrain, CT de combat oubliable, Cascade exigé, 3 cas arbuste, animation ≤2 s, anti-softlock |
| **16D** | Départ et sauvegarde atomique | **Validation isolée obligatoire** : fermeture application avant/pendant/après commit, navire absent après, Passe Bateau conservé |
| **16E** | Puzzle strict, Major Bob, badge, CT24 | RNG/reset, sortie puis retour, défaite après puzzle, IA sans switch, pas de bonus caché, récompenses uniques |
| **16F** | Non-régression complète | J13–J15 intacts, 3 starters, stockage, objets, save/load, batterie/performance Galaxy S24 |

**Contraintes de livraison :** tests automatiques des fonctions pures, import Godot sans erreur, parcours réel sur S24, pas de fusion dans `main` avant validation du propriétaire. Un seul jalon à la fois dans moteur de combat et sauvegarde selon C-7 de la passe. [TECH]

## 15. Textes à valider — index numéroté

| ID | Texte / emplacement |
|---|---|
| TXT-01 | Passe Bateau contrôlé : « Ton Passe Bateau, s'il te plaît. / Parfait, bienvenue à bord ! » |
| TXT-02 | Passe absent : « Il te faut un Passe Bateau / pour monter sur ce navire. » |
| TXT-03 | Marin avant CS01 : « Tu peux revenir quand tu veux. / Bonne visite ! » |
| TXT-04 | DEP-01 : « Si tu pars, le navire appareille. / Tu ne pourras plus remonter. » |
| TXT-05 | Choix : **PARTIR / PAS ENCORE** |
| TXT-06 | DEP-02 : « Le S.S. Anne quitte Carmin. » |
| TXT-07 | DEP-03 : « Le S.S. Anne a pris le large. » |
| TXT-08 | R4-AVANT : « Tu vas voir le capitaine ? / Il paraît qu'il a le mal de mer ! » |
| TXT-09 | R4-AVANT suite : « Moi, je ne perds pas l'équilibre. / En garde ! » |
| TXT-10 | R4-APRÈS : « Tu m'as encore dépassé... / Profite bien de ton voyage ! » |
| TXT-11 | R4-REPRISE : « Te revoilà ? / Cette fois, tiens bon ! » |
| TXT-12 | R4-DÉFAITE : « Tu vois ? Je tiens mieux le cap ! » |
| TXT-13 | CAP-01 : « Oh... la mer ne me réussit pas. / Tu peux rester un instant ? » |
| TXT-14 | CAP-02 : « Merci... Ça va déjà mieux. / Tu es vraiment gentil. » |
| TXT-15 | CAP-03 : « Prends cette CS01 : Coupe. / Elle te sera utile à terre. » |
| TXT-16 | CAP-04 : « Merci encore ! / Profite bien de la traversée. » |
| TXT-17 | ARB-00 : « Un arbuste barre le passage. / Il faudrait savoir le couper. » |
| TXT-18 | **ARB-01 sans Cascade : « Il faut le Badge Cascade. / Ton Pokémon refuse de couper. »** |
| TXT-19 | ARB-02 incompatible : « Aucun Pokémon de l'équipe / ne peut couper cet arbuste. » |
| TXT-20 | ARB-03 : « Un arbuste bloque le chemin. / Utiliser Coupe ? » |
| TXT-21 | Choix : **COUPER / LAISSER** |
| TXT-22 | ARB-04 : « L'arbuste a été coupé ! » |
| TXT-23 | GUIDE-01 : « Major Bob aime les défis. / Fouille bien les objets ici. » |
| TXT-24 | GYM-01 : « Rien ici. » |
| TXT-25 | GYM-02 : « Un interrupteur ! / Le premier verrou cède. » |
| TXT-26 | GYM-03 : « Le second interrupteur ! / La barrière s'ouvre ! » |
| TXT-27 | GYM-04 : « Mauvais interrupteur ! / Les verrous se referment. » |
| TXT-28 | BOB-AVANT : « Je suis Major Bob ! / Voyons si tu tiens le choc ! » |
| TXT-29 | BOB-DÉFAITE : « Reviens avec une équipe solide ! » |
| TXT-30 | BOB-VICTOIRE : « Bien joué, jeune Dresseur ! / Tu mérites le Badge Foudre. » |
| TXT-31 | Grand moment : **BADGE FOUDRE** |
| TXT-32 | BOB-CT : « Prends aussi cette CT24. / Elle contient Tonnerre. » |
| TXT-33 | BOB-RETOUR : « Fais bon usage du Badge Foudre ! » |
| TXT-34 | Corde Sortie navire : « Impossible de l'utiliser ici. » |

Les **39 répliques des 13 Dresseurs** figurent au §4 (avant / après victoire / après défaite) et sont incluses dans le lot à valider. Le tableau de bord est au §10. Les textes sont des propositions définitives de conception ; Claude ne doit pas les réécrire sans signaler la modification. [K26]

## 16. Questions ouvertes résiduelles et recommandations

Ces questions ne rouvrent **aucune** décision G-1 à G-10 ; elles demandent seulement confirmation du code réel ou une décision technique avant implémentation.

**Q-1. Noms exacts des flags et IDs d'objets déjà existants ?** Recommandation : réutiliser ceux de `main` ; fournir une table de correspondance, sans migration si possible.

**Q-2. `Doux Parfum` existe-t-il comme effet fonctionnel ?** Recommandation : remplacer par une capacité déjà implémentée, jamais ajouter un effet pour un seul Dresseur.

**Q-3. Compatibilités de Coupe générées pour les CS ?** Recommandation : étendre le générateur existant aux CS et ajouter tests de compatibilité pour les cinq espèces garanties.

**Q-4. Mode de remise de la CS01 et de la CT24 si inventaire saturé ?** Recommandation : objets clés/CT dans poches sans limite bloquante ; sinon transaction différée idempotente.

**Q-5. RNG puzzle et voisinage sur 15 objets ?** Recommandation : tirer parmi les objets avec voisin valide, choisir un voisin orthogonal, ne persister que le flag final ; tester exhaustivement chaque premier objet possible.

**Q-6. Corde Sortie dans le navire ?** Recommandation : refus explicite pour éviter toute téléportation contournant le rival ou la confirmation de départ.

**Q-7. Capacités exactes de Kadabra et des Dresseurs, selon base actuelle ?** Recommandation : liste blanche de capacités fonctionnelles, Choc Mental seul si nécessaire ; aucun effet manquant inventé.

**Q-8. Équilibrage Major Bob et rival ?** Recommandation : simuler les trois starters avec l'IA `smart`, recalibrer uniquement les niveaux après validation du propriétaire.

**Q-9. Emplacements et prix exacts des objets / gains ?** Recommandation : adapter aux catalogues et multiplicateurs existants sans ajouter de nouvelles espèces ni de nouvelles mécaniques.

**Q-10. Contrat J13/J14/J15 effectivement livré ?** Recommandation : confronter le dépôt et les branches de jalons, produire un delta de dépendances, ne pas supposer que la passe du 11 octobre reflète l'état du 15 octobre.

**Q-11. Numéro 19 disponible au push ?** Recommandation : vérifier toutes les branches distantes juste avant création et éviter une collision de fichier.

## 17. Tableau final — décisions verrouillées

| Décision | Verrouillage | Provenance |
|---|---|---|
| Périmètre | S.S. Anne multi-cartes + Arène de Major Bob, aucune Team Rocket | RB/K26 |
| Rival n°4 | Couloir capitaine ; victoire obligatoire ; défaite sans perte d'argent ; reprise courte ; IA `smart` sans switch | K26 |
| Rival équipe | Roucoups 19, Rattatac 16, Kadabra 18, starter évolué 20 ; pas d'Entrave | RB/K26 |
| Rival n°3 antérieur | Roucoups, Rattata, starter évolué ; sans Abra ; niveaux réels J13 à auditer | K26 |
| Capitaine | Mal de mer, scène courte sans mini-jeu, CS01 unique | RB/K26 |
| Coupe monde | CS01 + Badge Cascade + compatible équipe, sans emplacement | K26 + condition RB |
| Coupe combat | CT réutilisable, oubli normal ; 50/95/30 | K26/REC |
| Arbuste | Devant Arène, posé J15 ; coupe permanente, animation ≤2 s | RB/K26 |
| Texte manque badge | Réplique sans choix expliquant le refus de couper | K26 |
| Anti-blocage | Compatible capturable avant Carmin quel que soit le starter | K26 |
| Navire | Accessible sans Badge Cascade ; départ après CS01 et confirmation PARTIR/PAS ENCORE ; retour impossible ensuite | K26 |
| Passe Bateau | Léo le donne ; conservé après départ ; Nils à Bourg Palette | RB/K26 |
| Puzzle | Premier hasard, second voisin, erreur reset, nouveau tirage à chaque entrée, porte ouverte à vie après réussite | RB/K26 |
| Navire Dresseurs | 10, au plus 2 inévitables hors rival | K26 |
| Espèces nouvelles | Maximum 3 ; zéro requise si dépendances J14 vérifiées | K26 |
| Major Bob | Voltorbe, Pikachu, Raichu ; IA smart sans switch ; aucun bonus caché | RB/K26 |
| Capacités | Tonnerre 90/100/15/10 % ; Sonicboom 20 fixes/90/20 ; Coupe 50/95/30 | REC |
| Effets exclus | Destruction, Explosion, Entrave, Téléport en combat de Dresseur, Mur Lumière, Protection, Reflet, switch IA | K26 |
| Récompenses | Badge Foudre, vibration, CT24 Tonnerre réutilisable, remises uniques | RB/K26 |
| UI | Bulles 2 lignes ≈40 caractères ; cartes de choix ; pas de flèches, minimap, tutoriel ou toast objectif | K26 |
| Livraison | 16.0 à 16F, 16D départ validé isolément, QA Galaxy S24 | TECH |

**Fin du dossier 19 — J16.**
