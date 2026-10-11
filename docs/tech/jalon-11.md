# Jalon 11 — Grande passe de systèmes

> Objectif jouable sur le S24 : **sans zone nouvelle**, les Pokémon deviennent plus stratégiques en
> combat (paralysie, sommeil, brûlure, gel, confusion, multi-coups, apeurement, Patience), plus faciles
> à entraîner (CT réutilisables, CT34 remise par Pierre), plus beaux quand ils évoluent (séquence
> courte) et **présents dans le monde** (un compagnon choisi qui suit le joueur dehors).
>
> **Source de vérité** : `docs/design/dossier-14-systemes-j11.md` (8 décisions et A-1 à A-14 validés
> par Kevin le 2026-10-10). **Statut : plan validé sur le principe par Kevin le 2026-10-10**, lot de textes
> du dossier §13 validé avec retouches. **Feu vert pour T1 seulement** ; T2 et la suite après la
> validation S24 de 11.0. Le J11 reste isolé de CB.3, d'OUV et de la conception du J12.
>
> Plan écrit sur `claude/lancement-j11-4pkt2k` depuis `main` à `e80f636` (J10 terminé, fusionné).

## 0. État des lieux

### 0.1 Ce qui existe (`main` à `e80f636`)

| Besoin | Existant | Fichiers |
|---|---|---|
| Statut majeur | un champ `Pokemon.status`, sauvegardé (v4) ; règles du poison seul | `game/pokemon/pokemon.gd`, `game/pokemon/status_rules.gd` |
| Effets de capacités | `MoveEffect` : `STAT_STAGE`, `RECOIL`, `SEED`, `STATUS` (poison) ; `pending_effects` non joués (32 capacités sur 66) | `game/pokemon/moves/move_effect.gd`, `move_data.gd`, `data/pokemon/moves/moves.json` |
| Tour de combat | `Battle.submit` → ordre (`_player_goes_second`, `_priority`) → `_execute` → `_apply_effect` → `_end_turn` (Vampigraine, poison) | `game/battle/battle.gd` (731 lignes) |
| Volatil | Vampigraine seule (sur le `BattleSide`) | `battle.gd`, `battle_side.gd` |
| Changement du joueur | volontaire et forcé (J7) | `battle_action.gd`, `battle.gd`, `battle_party_panel.*` |
| IA | `random`, `smart` (meilleur dégât) | `game/battle/battle_ai.gd` |
| Remèdes | `ItemData.cures`, `ItemUse`, Antidote | `game/items/item_data.gd`, `item_use.gd`, `data/items/items.json` |
| Sac | catégories `ball, heal, battle, field, key` ; écran à onglets | `item_data.gd`, `game/ui/bag/bag_screen.gd` |
| Apprendre / oublier | `MoveLearnPrompt`, panneau d'oubli (combat et évolution) | `game/battle/move_learn_prompt.gd`, `game/ui/battle/move_forget_panel.*` |
| Évolution | logique + directeur + écran (≈ 9 s) | `game/pokemon/evolution/`, `game/systems/evolution/`, `game/ui/evolution/`, `UiTokens.EVOLUTION_*` |
| Pierre | scène écrite, `badge_boulder`, réplique d'après-badge | `data/dialogues/pewter_gym.json`, `data/cutscenes/pewter_gym.json`, `data/trainers/pewter_gym.json` |
| Boutiques | Jadielle, Argenta | `data/shops/viridian_mart.json`, `pewter_mart.json` |
| Monde | grille avec occupants (`GridWorld.occupy`, `can_enter`), `Map.interior`, joueur (`moved`, `facing_changed`), PNJ (`step_finished`, `hopped`), cinématiques, bulle « ! » | `game/world/grid_world.gd`, `map.gd`, `game/player/player.gd`, `game/world/npc/npc.gd`, `game/systems/cutscene/` |
| Vision des Dresseurs | ligne coupée par tout occupant autre que le joueur | `game/world/npc/trainer_rules.gd` (`sight_distance`) |
| Planches de Pokémon | 9 espèces repos + marche 4 directions ; 7 « repos + réaction » | `assets/sprites/pokemon/painted/` |
| Sauvegarde | **v4**, migrations pas à pas, champ absent = défaut ; J10 sans changement de format | `game/systems/save/save_system.gd` |
| Départs de QA | `tools/debug_start/*.json` (+ README) | `poison_qa`, `evolution_qa`, `learn_move`, `badge_after`… |

### 0.2 Trous

1. `StatusRules` teste `== POISON` partout ; aucun compteur ; le test `test_status_rules.gd` verrouille
   l'absence de paralysie (à retourner).
2. Aucun état « action verrouillée » (Patience ; préparera les capacités à deux tours du futur).
3. Aucun multi-coups (un seul `_execute` = un coup), aucun apeurement (il faut savoir qui agit en second).
4. Aucun identifiant stable de Pokémon.
5. Aucune catégorie CT, aucune compatibilité, aucun objet « permanent ».
6. Aucun suiveur dans le monde (hors pas de cinématique `follow_path`).

## 1. Découpage

### 1.1 Sous-jalons

| Sous-jalon | Contenu | Validation (règle 1) |
|---|---|---|
| **11.0** | Sauvegarde : identifiant de Pokémon, compteurs de statut, compagnon choisi, `tm34_received` | **seule** sur S24, vraie partie de Kevin |
| **11A** | Statuts majeurs, confusion, effets simples, présentation, remèdes | S24, carte de QA `qa_status` (retirée à la clôture) |
| **11B** | CT, Sac, Patience, remise par Pierre | S24 |
| **11C** | Évolution courte | S24 (≈ 10 min, peut accompagner 11B si Kevin le veut : deux petits systèmes non risqués) |
| **11D** | Compagnon + lot d'art de 5 planches | S24 en vraie partie |
| **Clôture** | QA finale, retrait de `qa_status`, roadmap, passation au J12 | S24 ou S21 |

Ordre : 11.0 → 11A → 11B → 11C → 11D. 11C et la génération du lot d'art (T18) peuvent avancer en
parallèle de 11A (fichiers disjoints). 11D en dernier : système le plus risqué côté monde.
**Fable** (sur demande de Kevin, `CLAUDE.md`) : relecture de la conception du compagnon (T19) et de
la migration 11.0 (T2).

### 1.2 Fichiers partagés (conflits attendus)

`battle.gd`, `battle_director.gd`, `messages.json`, `moves.json`, `items.json`, `UiTokens`,
`save_system.gd`, `boot.gd`. Une seule tâche à la fois par fichier « chaud » ; les autres partent
après sa fusion dans `jalon-11`.

## 2. Conception technique

### 2.1 Sauvegarde (T1–T3, 11.0)

- `Pokemon.uid: String` (16 caractères hexadécimaux, unique dans la partie) ; `to_dict` / `from_dict` ;
  un Pokémon sans `uid` en reçoit un au chargement, **équipe dans l'ordre puis Stockage dans l'ordre :
  aucun Pokémon ajouté, retiré ni déplacé** ; un doublon (fichier modifié à la main) est régénéré pour
  le second. Copié tel quel au Stockage et à l'évolution (même objet `Pokemon`).
- `Pokemon.status_turns: int` (0 = aucun compteur) : tours de sommeil restants ; gel sans compteur.
- `GameState.companion_uid: String` (vide = aucun) ; relu tolérant (uid absent de l'équipe = vide +
  journal `[qa]`). **Le compagnon est toujours désigné par `uid`, jamais par sa position** :
  réordonner l'équipe ne le change pas ; rentrer dans sa Ball (intérieur, K.O., cinématique) ne
  touche pas `companion_uid` (seule la visibilité, calculée, change).
- `tm34_received` : drapeau d'histoire ordinaire (aucun format).
- **Version (vérifié au démarrage de T1, 2026-10-10)** : `main` en v4 ; **OUV.1 réserve la v5**
  (`rival_name`, `player_look`) → **le J11 écrit la v6** (dossier §9). Tant qu'OUV.1 n'est pas dans
  `main`, la branche de T1 porte un numéro provisoire et **n'est ni fusionnée ni installée sur la
  vraie partie de Kevin** ; à la fusion d'OUV.1 : fusion de `main`, migration v5 → v6, fixture v5
  réelle d'OUV, puis T2 et T3. Migration **additive** : le pas du J11 attribue les `uid`, rien
  d'autre ; tout autre champ absent prend sa valeur par défaut. Refus par l'APK précédent vérifié octet
  pour octet (procédure du 9A.1).
- Tests : aller-retour ; migration depuis un fichier v4 réel (`save_v4_qa`) puis depuis la v5 d'OUV :
  **mêmes Pokémon, même ordre** dans l'équipe et au Stockage, mêmes objets, argent, badges, drapeaux,
  Grands moments ; `uid` stables d'un chargement à l'autre et uniques après capture, Stockage,
  évolution ; doublon régénéré ; compagnon gardé après réordonnancement de l'équipe, effacé s'il est
  déposé ou absent ; uid inconnu ; fichier corrompu inchangé ; version plus récente refusée.

### 2.2 Statuts (T4–T6, 11A)

- `StatusRules` devient une table : `PARALYSIS`, `SLEEP`, `BURN`, `FREEZE` + `POISON` ; par statut :
  immunités de type, multiplicateur de capture, dégâts de fin de tour (fraction), effet sur une
  statistique (Vitesse ÷ 2, Attaque physique ÷ 2), test « peut agir » (`can_act(pokemon, rng) ->
  ActCheck { OK, FULLY_PARALYZED, ASLEEP, WOKE_UP, FROZEN, THAWED }`). Valeurs dans
  `data/battle/status.json` (règle 7) ; logique pure, testable sans scène.
- `Battle._execute` : test `can_act` avant la capacité ; dégel par une capacité Feu reçue ; ordre
  d'action avec la Vitesse modifiée ; dégâts physiques de la brûlure dans le calcul de dégâts.
- `Battle._end_turn` : poison (inchangé), brûlure (1/16).
- **Confusion** : volatil du `BattleSide` (comme la graine) : `confusion_turns` ; test après `can_act`,
  33 %, dégâts typeless 40 physiques contre soi ; perdue au changement et à la fin du combat.
- **Effets** (nouveaux genres de `MoveEffect`, documentés dans `move_effect.gd`) : `status` accepte
  les 4 statuts ; `confusion` (chance) ; `hits` (`{min, max}` : 2 fixes ou 2–5 avec 3/8, 3/8, 1/8,
  1/8 [D, moderne]) ; `flinch` (chance, seulement si le lanceur agit en premier) ; `crit_up` (+2
  étages, échoue si déjà actif) ; `fixed_damage` (`half_hp` / `level`). Chaque capacité du dossier §4.2
  passe de `pending_effects` à `effects` ; les reportées gardent `pending_effects`.
- **IA** : `smart` n'utilise pas une capacité de statut sur une cible déjà atteinte (ni confusion sur
  un confus, ni Puissance active) ; `random` inchangé.
- **Événements** : `STATUS_INFLICTED/DAMAGED/CURED/UNCHANGED` généralisés au statut (au lieu du poison
  implicite), `CANT_ACT`, `WOKE_UP`, `THAWED`, `CONFUSED`, `HURT_ITSELF`, `MULTI_HIT`, `FLINCHED`,
  `FOCUSED`, `FAILED`. Textes du dossier §13 dans `messages.json` (clé par statut, `text_f`).
- Tests : chaque statut × combat sauvage, Dresseur, changement, K.O., fin de combat, sauvegarde /
  rechargement, capture ; immunités ; graines fixées (`GameRng`) ; **chaque capacité du §4.2**
  avec son effet (table de test pilotée par les données) ; non-régression du poison du J9.
- **Matrice d'interactions** (ordre des tests d'un tour : sommeil / gel → paralysie → apeurement →
  confusion → capacité) : endormi **et** confus (le sommeil bloque, la confusion ne baisse pas pendant
  le sommeil [D]) ; paralysé **et** confus (paralysie testée d'abord : bloqué = pas de test de
  confusion) ; apeuré quand il est endormi (rien : déjà bloqué, pas de message d'apeurement) ; se
  frapper dans la confusion pendant un multi-coups (aucun coup) ; multi-coups qui met K.O. au 2e coup
  (arrêt, « Touché 2 fois ! ») ; multi-coups contre un Pokémon qui gèle ou s'endort entre deux coups
  (impossible : le statut s'applique après le dernier coup) ; apeurement par le 1er coup d'un
  multi-coups (une seule chance par capacité [D]) ; changement de Pokémon (confusion et apeurement
  perdus, statut majeur et compteur gardés) ; réveil naturel (n° 7) **et** Réveil objet (n° 9)
  distingués par leur événement.

### 2.3 Présentation des statuts (T7, 11A)

`StatusView` / `TeamMemberView` / `battle_info_card` : abréviations et pastilles pour les 5 statuts
(`UiTokens`) ; effets par statut sur le sprite de combat **au-dessus** du matériau de l'artwork (leçon
du J9 × CB.1) : particules légères (décharges, braises, « z », étoiles), teinte du gel ; « Réduire les
animations » ; messages dans le bandeau existant. Captures relues pour chaque statut, de face et de dos.

### 2.4 Remèdes (T8, 11A)

`items.json` : `paralyze_heal`, `awakening`, `burn_heal`, `ice_heal` (`cures`, prix, textes §13) ;
Boutiques de Jadielle et d'Argenta : les trois premiers, **sans condition** (le J11 rend les statuts
présents partout ; Antigel absent des stocks). Tests : achat, usage exploration / combat, refus.

### 2.5 Carte de QA `qa_status` (T9, 11A)

Petite carte de tuiles provisoires (modèle `qa_forest_systems` du J9) : herbes avec une table forcée
(Pikachu Cage-Éclair, Papilusion Choc Mental / Para-Spore / Poudre Dodo, Dardargnan Furie, Rattata Croc
de Mort), un Dresseur `random` et un `smart`, une Boutique de QA ; départ `status_qa` (équipe avec
Salamèche Flammèche, Papilusion, Nidoran ♂ Puissance ; remèdes). Retirée à la clôture (comme au J9).

### 2.6 CT (T10–T12, 11B)

- `ItemData` : catégorie `tm` + champ `teaches: StringName` et `permanent: bool` (jamais décrémenté,
  `price` nul = invendable ; la Boutique refuse la vente d'un objet permanent).
- Espèces : compatibilités **déjà générées** (2026-10-10) dans `data/pokemon/tm_compatibility.json`
  par `tools/gen_tm_compatibility.py` (CSV publics de PokeAPI, Rouge/Bleu, CT 01–50 → capacité,
  espèce → numéros) pour les 38 espèces ; fichier séparé de `kanto.json` (rien ne le lit avant le
  11B). `PokemonData.can_learn_tm(species, number)` le lira ; une espèce absente = aucune CT.
  La capacité `bide` (Patience) et l'objet `tm34` restent à ajouter au T13.
- Logique `TmTeach.check(pokemon, item) -> { COMPATIBLE, KNOWN, INCOMPATIBLE }` ; apprentissage par
  `MoveLearnPrompt` (oubli, GARDER) ; hors combat seulement.
- Sac : onglet « CT » visible seulement si une CT est possédée ; carte et détail (§6.2) ; parcours
  Sac → CT → liste de l'équipe (`party_picker` existant, états du §13) → APPRENDRE.
- Tests : catégorie masquée / visible, compatibilités, déjà connue, 4 capacités → oubli / GARDER, CT
  jamais consommée, vente refusée, refus en combat.

### 2.7 Patience (T13, 11B)

- `BattleSide.locked_move` (état : capacité, tour 1..3, stock) ; `Battle.get_usable_moves` /
  `is_legal` : action imposée pendant les tours 2 et 3 (l'interface ne propose pas de choix ; le
  `BattleDirector` soumet l'action verrouillée sans attendre).
- Stock alimenté par chaque coup direct reçu (`MULTI_HIT` compris) ; exclusions et ruptures du
  dossier §6.3 ; riposte typeless, sans précision, plafonnée aux PV de la cible ; échec à 0.
- Données : `bide` dans `moves.json` (Normal, physique, PP 10, priorité 0, `effects: [{kind:
  "bide"}]`) ; objet `tm34`.
- **Déroulé exact** (dossier §6.3) :

  | Tour | Lanceur | Stock |
  |---|---|---|
  | 1 | choisit Patience (1 PP) → « se prépare à encaisser ! » | 0, puis + coups directs reçus |
  | 2 | action imposée → « encaisse ! » | + coups directs reçus |
  | 3 | action imposée → « riposte ! » : 2 × stock (au plus les PV de la cible), ou « Mais ça échoue ! » | + coups reçus **avant** la riposte |

  **Ruptures** (stock perdu, « La patience de {pokemon} est rompue ! », le lanceur redevient libre au
  tour suivant) : **paralysé au point de ne pas agir** (un tour où la paralysie ne bloque pas laisse
  Patience continuer) ; **endormi** ou **gelé** ; **K.O.** (pas de message, le K.O. suffit) ;
  **retiré** (changement volontaire du joueur) ; se frappe dans la confusion ; apeuré. **L'adversaire
  change de Pokémon** : le stock reste et frappe le nouveau. Fin du combat (capture, fuite) : rien
  n'est gardé, rien n'est sauvegardé.
- Tests : riposte exacte, multi-coups, stock nul, **chaque rupture** (paralysie bloquante et non
  bloquante, sommeil, gel, K.O., retrait, confusion, apeurement), adversaire qui change, adversaire
  plus rapide au tour 3, capture / fuite pendant Patience, sauvegarde après le combat sans trace.

### 2.8 Remise par Pierre (T14, 11B)

`pewter_gym.json` (dialogues et cinématique) : branche après le badge (nouvelle partie) et variante
`if badge_boulder` / `unless tm34_received` en lui reparlant ; pose `tm34_received` ; toast ; objet au
Sac. Départs : `badge_after` (partie badgée sans CT) et `brock_kevin` (victoire). Tests : une seule
remise dans les deux cas, rechargement entre les deux répliques, réplique d'après-badge ensuite.

### 2.9 Évolution courte (T15, 11C)

`UiTokens.EVOLUTION_*` : transformation 5,0 → ≈ 2,5 s, présentation et silence resserrés, total ≈ 6 s ;
`EvolutionScreen` : toucher = ×2 (`Engine` non touché : vitesse des `Tween` de l'écran) ; ARRÊTER
inchangé. `test_evolution_screen` : durée cible, accélération, annulation, apprentissage après.

### 2.10 Compagnon (T16–T21, 11D)

- **Données** : `data/pokemon/companions.json` : espèce → planche (`frames`), profil d'animation
  (taille, décalage d'ombre, vol). Seules les espèces listées sont éligibles (aucun repli).
- **Logique pure** (`game/world/companion/`) :
  - `CompanionRules` : éligible (espèce listée, Pokémon dans l'équipe), visible (carte d'extérieur, pas
    K.O., pas de cinématique, case libre), phrase de curiosité (contexte → clé du §13).
  - `CompanionTrail` : file des cases quittées par le joueur ; prochaine case du compagnon ; échange
    de places ; rebord ; réinitialisation après un warp (case derrière le joueur si libre).
- **Nœud** `Companion` (personnage léger, `CharacterLook` + planche) : suit `Player.moved` à la même
  durée de pas (marche / course) ; saute avec le joueur ; tri en profondeur comme un PNJ ; caché sous
  les hautes herbes comme le joueur ; éclat de Ball ≈ 0,4 s.
- **Grille** : le compagnon **n'occupe pas** la grille du joueur ; `GridWorld` gagne une occupation
  « douce » consultée **par les PNJ seulement** (ils attendent) ; `TrainerRules.sight_distance` et les
  déclencheurs l'ignorent ; aucune rencontre.
- **Boot / SceneRouter** : création et rappel aux changements de carte (`Map.interior`), au réveil au
  Centre, au début / à la fin des cinématiques qui déplacent le joueur (`CutsceneDirector`), au K.O.
  et à la guérison, à l'évolution (rentre si l'espèce n'est plus éligible), au dépôt au Stockage.
- **Menu Équipe** : FAIRE SORTIR / RAPPELER sur la fiche (absent si non éligible) ; `MenuDirector`
  écrit `GameState.companion_uid`.
- **Réactions** : curiosité (interaction face au compagnon ou toucher), repos (≈ 8 s d'immobilité),
  enthousiasme (victoire contre un Dresseur, capture, montée de niveau du compagnon, sortie du Centre
  après un soin) ; bulle du moteur (`Npc.show_emote`, J9) ; aucune humeur.
- Tests : `CompanionTrail` (couloirs, demi-tour, rebords, impasses, warps), `CompanionRules` (toutes
  les lignes du tableau §8.3), intégration sur les vraies cartes (Bourg Palette, Route 1, Jadielle,
  Forêt de Jade, Argenta) : portes, Centre, Dresseur qui voit à travers, PNJ qui attend, herbes sans
  rencontre, cinématiques du prologue et du rival, fps ≥ 58 dans la forêt.

### 2.11 Lot d'art du compagnon (T18)

5 planches repos + marche 4 directions (Herbizarre, Reptincel, Carabaffe, Pikachu, Papilusion en vol)
par la chaîne Codex des séries précédentes (`tools/art/`, fiche dans `docs/design/fiches-assets/`),
même gabarit et même main que `charmander_frames` ; **validation de Kevin sur planche de contact**
avant intégration. Aucune espèce n'entre dans `companions.json` sans sa planche validée.

## 3. Tâches

| T | Tâche | Agent | Dépend de | Sous-jalon |
|---|---|---|---|---|
| T0 | Lot de textes §13 relu par Kevin → `messages.json`, `items.json`, dialogues (intégration à chaque tâche) | — | Kevin | tous |
| T1 | Sauvegarde : `uid`, `status_turns`, `companion_uid`, migration, tests | architecte-godot (Opus ; Fable sur demande) | plan validé | 11.0 |
| T2 | Relecture adversariale de la migration (fichiers réels, refus par l'APK précédent) | architecte-godot | T1 | 11.0 |
| T3 | QA S24 11.0 seule (vraie partie, fermeture forcée, retour) | qa-mobile | T2 | 11.0 |
| T4 | `StatusRules` + `status.json` + `can_act` + brûlure / paralysie / sommeil / gel dans `Battle` | architecte-godot | T3 | 11A |
| T5 | Confusion + effets `hits`, `flinch`, `crit_up`, `fixed_damage` ; capacités du §4.2 ; IA `smart` | architecte-godot | T4 | 11A |
| T6 | Événements et textes de combat (`BattleText`, `messages.json`) | architecte-godot | T5 | 11A |
| T7 | Présentation des statuts (pastilles, effets sur sprite, réduits) + captures | ui-mobile | T6 | 11A |
| T8 | Remèdes + Boutiques | constructeur-monde | T4 | 11A |
| T9 | Carte et départ `qa_status` | constructeur-monde | T5 | 11A |
| T10 | QA S24 11A | qa-mobile | T7–T9 | 11A |
| T11 | Catégorie CT, objet permanent, vente refusée, compatibilités des 38 espèces | architecte-godot | T10 | 11B |
| T12 | Sac « CT » + parcours d'apprentissage | ui-mobile | T11 | 11B |
| T13 | Patience (verrou d'action, stock, ruptures) | architecte-godot | T11 | 11B |
| T14 | Remise par Pierre (deux cas) + départs | constructeur-monde | T11 | 11B |
| T15 | Évolution courte (durées, accélération) | ui-mobile | plan validé (parallèle) | 11C |
| T16 | QA S24 11B (+ 11C si Kevin le veut) | qa-mobile | T12–T15 | 11B / 11C |
| T17 | Conception détaillée du compagnon : `CompanionTrail`, `CompanionRules`, occupation douce, points d'accroche Boot (relecture Fable sur demande) | architecte-godot | T10 | 11D |
| T18 | Lot d'art : 5 planches, planche de contact, validation de Kevin | constructeur-monde (Mac) | plan validé (parallèle) | 11D |
| T19 | Logique du compagnon + tests | architecte-godot | T17 | 11D |
| T20 | Nœud, menu Équipe, réactions, intégration sur les vraies cartes | constructeur-monde + ui-mobile | T18, T19 | 11D |
| T21 | QA S24 11D (vraie partie : routes, villes, forêt, portes, rebords, herbes, Dresseurs, Centre, fps) | qa-mobile | T20 | 11D |
| T22 | Clôture : QA finale, retrait de `qa_status`, roadmap, passation au J12 | architecte-godot + qa-mobile | T21 | clôture |

## 4. Critères d'acceptation (QA S24)

**11.0** — partie J10 réelle chargée sans perte (équipe, Stockage, Sac, argent, badges, drapeaux,
Grands moments) ; une seule ligne `[qa]` de migration ; `uid` uniques après capture, Stockage,
évolution ; deux fermetures forcées sans perte ; l'APK précédent refuse le fichier sans le modifier.

**11A** — chaque statut vu sur le téléphone : infligé, empêche d'agir, fin de tour, fin naturelle
(réveil, dégel), changement de Pokémon, K.O., après combat (Équipe, tableau de bord), après fermeture
forcée ; immunités (Pikachu contre Cage-Éclair, Salamèche contre la brûlure) ; capture plus facile ;
confusion de Papilusion (se frapper, fin, perdue au changement) ; Furie « Touché n fois ! » ; Croc de
Mort qui apeure ; Puissance ; remèdes en exploration et en combat, refus « Sans effet », Boutiques ;
lisibilité des pastilles et des effets ; « Réduire les animations » ; poison du J9 inchangé ;
≥ 55 fps en combat hors transitions.

**11B** — CT34 reçue une fois (nouvelle partie et partie badgée) ; onglet CT absent puis présent ;
COMPATIBLE / DÉJÀ CONNUE / INCOMPATIBLE ; oubli d'une capacité ; GARDER ; CT toujours là ; vente
impossible ; refus en combat ; Patience : riposte au double, échec, rupture (changement, sommeil,
paralysie), adversaire qui change.

**11C** — évolution ≈ 6 s, accélérée au toucher, ARRÊTER et retour Android, apprentissage après,
fermeture forcée pendant la séquence sans évolution à moitié ; 60 fps.

**11D** — FAIRE SORTIR / RAPPELER ; absent pour une espèce sans planche ; suit en marche et en course,
rebords, demi-tour (échange), couloirs ; rentre aux portes et ressort ; invisible K.O. puis de retour
après le Centre ; aucune rencontre ni déclencheur ; un Dresseur voit le joueur « à travers » ; un PNJ
attend ; cinématiques sans compagnon ; réactions (curiosité, repos, enthousiasme) ; évolution en
espèce sans planche → rentre ; sauvegarde / reprise avec le compagnon ; ≥ 58 fps dans la Forêt de Jade.

**Clôture** — vraie partie J1 → J10 rejouée sur les points de contrôle (prologue, Route 1, Jadielle,
forêt, Pierre) sans régression ; `tools/test.sh` vert ; import propre ; carte de QA retirée.

## 5. Risques

| Risque | Parade |
|---|---|
| Statuts qui cassent l'équilibrage de Pierre (brûlure de Flammèche, paralysie de Pikachu) | relancer `tools/simulate_brock.gd` (J10) après T5 ; écarts signalés à Kevin, pas corrigés en douce |
| Migration en concurrence avec OUV | version fixée au T1 d'après `main` ; renumérotation par le second fusionné (dossier §9) |
| Compagnon qui se coince (couloirs d'une case, warps en bord de carte, cinématiques) | règle « masqué sans case libre » (A-1) ; tests sur toutes les vraies cartes |
| Performance dans la forêt (nœuds, tri en profondeur) | budget mesuré au T20, comme au J9 |
| Effets de statut sur l'artwork de l'adversaire | au-dessus du sprite, jamais de matériau remplacé ; test de non-régression du J9 |
| Lot d'art refusé ou en retard | 11D livrable avec les 9 espèces existantes ; les planches entrent quand elles sont validées |

## 6. Valeurs par défaut

Celles du dossier §14, plus : `uid` 16 hexadécimaux ; répartition 2–5 coups 3/8, 3/8, 1/8, 1/8 ;
apeurement seulement si le lanceur agit en premier ; accélération de l'évolution par la vitesse des
`Tween` de l'écran ; carte de QA `qa_status` ; départ `status_qa`.

## 7. Questions ouvertes

Aucune décision de game design ouverte : textes du dossier §13 en attente de relecture (T0).

## 8. Fait

### T1 — sauvegarde (2026-10-10, branche `claude/lancement-j11-4pkt2k`, **non fusionnée**)

- `game/pokemon/pokemon_uid.gd` (nouveau) : `PokemonUid.generate()` (16 hexadécimaux, générateur
  propre, **jamais `GameRng`** : l'aléatoire du jeu n'est pas décalé), `is_valid()`.
- `Pokemon` : `uid`, `status_turns` (remis à 0 par `heal_full` et `cure_status`), `ensure_uid()` ;
  `to_dict` / `from_dict` tolérants (uid mal formé → vide + avertissement ; compteur borné à
  `MAX_STATUS_TURNS` = 7, nul sans statut).
- `Party.add`, `PokemonStorage.add` et `PokemonStorage.load_array` : identifiant donné à l'entrée
  (même objet ensuite au Stockage et à l'évolution), **seulement pour l'équipe et le Stockage du
  joueur** (`assigns_uids`, posé par `GameState`) : les équipes de Dresseurs et les équipes de
  travail restent reproductibles à l'identique (tests `test_trainer_library`, `test_trainer_slot_moves`).
- `GameState` : `companion_uid` (« companion » dans le fichier ; remis à vide par `new_game`),
  `ensure_unique_uids()` (équipe puis Stockage, ordre et contenu inchangés, doublon régénéré pour
  le second), `get_companion()`, `set_companion()` ; compagnon inconnu au chargement → aucun +
  ligne `[qa]`.
- `SaveSystem.VERSION = 5` **provisoire** (commentaire dans le fichier) : OUV.1 a réservé la v5 ;
  à sa fusion, le J11 devient la v6. Le pas de migration ne transforme rien (tout est additif).
- Tests : `tests/unit/test_save_j11.gd` (18 : format et unicité des identifiants, `GameRng`
  intact, entrée dans l'équipe / le Stockage, évolution, aller-retour, valeurs mal formées, vraie
  partie v3 passée en v4 puis migrée : **mêmes Pokémon, même ordre**, Sac, argent, drapeaux,
  Grands moments, Pokédex identiques ; identifiants stables d'un chargement à l'autre ; vraie partie
  v2 ; doublon ; version future refusée ; **refus par la build v4 sans écrire** ; compagnon gardé
  après réordonnancement, gardé K.O., refusé hors équipe, perdu au dépôt, inconnu = aucun) ;
  `test_save_system` et `test_save_boot` alignés sur `SaveSystem.VERSION` (plus de « 4 » en dur
  pour la version courante) et sur les trois champs nouveaux ; `test_starter_choice`,
  `test_debug_start` (identifiant hors de la graine) et `test_game_state` (« companion ») alignés.
- **Environnement de cette session (conteneur Linux, pas le Mac)** : deux tests échouent **aussi sur
  `main` propre** (`e80f636`…`29ed036`, vérifié dans une copie séparée) : `test_service_director`
  (`test_center_heal_on_the_center_registers_it_once`) **fait planter Godot** (signal 11, objet
  libéré pendant l'émission de `animation_finished` de la machine de soin) et arrête la suite ;
  `test_center_heal` (`…_registers_and_saves`) dépasse son délai de dialogue. Sans rapport avec
  T1 ; la suite a été jouée sans le premier fichier : **3 610 tests verts** (1 732 d'intégration,
  1 878 unitaires), seul échec `test_center_heal` (préexistant, ci-dessus). Import propre. À revoir
  sur le Mac avant T2.
- **Reste avant T2 / T3** : fusion d'OUV.1 dans `main` puis dans cette branche, passage en v6
  (migration v5 → v6), fixture v5 réelle d'OUV, puis relecture adversariale (T2) et QA S24 seule
  (T3) sur la vraie partie de Kevin.

### T18 — lot d'art du compagnon : préparé (2026-10-10, en avance, pendant l'attente d'OUV.1)

`tools/art/serie13.py` + fiche `docs/design/fiches-assets/serie-13-compagnon.md` : prompts des cinq
planches (gabarit des starters, ancres héros + forme précédente), hauteurs par défaut, intégration
décrite (manifeste, `preparer.py`, `LOOKS`, `companions.json` au T20). Génération et validation :
Kevin, sur le Mac. Rien de branché dans le jeu.

### T17 — conception technique du compagnon : écrite (2026-10-10, en avance)

`docs/tech/jalon-11-compagnon.md` : constats du code (le compagnon n'occupe pas la grille ; relais
`Player.step_started` ; occupation douce consultée par les seules routines de PNJ ; fournisseur
« compagnon » de `InteractionFinder` ; caché en combat car `BattleStage` montre le monde ; rentre à
toute scène car les déplacements de scène abandonnent au bout de 2 s), architecture
(`CompanionRules`, `CompanionTrail` purs, nœud `Companion`, `CompanionController`,
`companions.json`, `EmoteBubble` extrait avec `♪` et `…`), défauts D-1 à D-8, découpage T19a–T20d,
tests et risques. Aucun code. Relecture par Fable possible sur demande.

### T11 (partie données) — compatibilités des CT : générées (2026-10-10, en avance)

`data/pokemon/tm_compatibility.json` + `tools/gen_tm_compatibility.py` : les 50 CT de Rouge/Bleu et
leurs espèces compatibles parmi les 38 du jeu (34 pour la CT34 ; aucune CT pour Chenipan,
Chrysacier, Aspicot, Coconfort). Source : CSV de PokeAPI (téléchargés hors dépôt). Non lu par le jeu.

### T1 rebasé sur OUV.1 → v6 (2026-10-11)

`main` (OUV.1 et OUV.2 validés, v5 = `rival_name` + `player_look` ; dossier 15 du J12) fusionné
dans la branche. Conflits résolus en gardant les deux côtés : `save_system.gd` (**`VERSION = 6`**,
historique « 6 = J11 », pas 5 → 6 qui ne transforme rien), `game_state.gd` (fonctions d'OUV et du
J11), tests de sauvegarde (comptes de champs : v5 + v6). `test_save_j11` part maintenant de la
**vraie partie v4 du S21** (`tests/fixtures/save/v4_kevin_s21.json`, relevée par OUV.1) et d'une
**v5 d'OUV** (la même, avec prénom du rival et apparence) : mêmes Pokémon, même ordre, prénom du
rival gardé, refus par la build d'OUV (v5) sans écrire. Il n'existe pas encore de **vraie** v5 dans
le dépôt : elle sera relevée sur le téléphone à l'étape 1 du T3 et ajoutée en fixture.

### T2 — relecture adversariale de la migration (2026-10-11)

Points vérifiés (code et tests) :
1. **Additif** : le pas 5 → 6 ne touche pas au fichier ; tout champ nouveau a un défaut au
   chargement ; un champ inconnu est ignoré ; rien ne plante sur un `uid` mal formé, un compteur
   hors bornes, un compagnon inconnu (tests).
2. **Ordre et contenu** : `Party.load_array` / `PokemonStorage.load_array` gardent l'ordre ;
   `ensure_unique_uids` ne retire ni ne déplace rien (tests sur trois parties réelles).
3. **Aléatoire du jeu intact** : identifiants tirés hors de `GameRng` ; équipes de Dresseurs et de
   travail sans identifiant (reproductibilité des combats et des départs vérifiée par les tests).
4. **Commit d'OUV** (`OpeningCommit`, nouvelle partie écrite en écritures atomiques) : passe par
   `GameState.to_dict`, donc écrit la v6 avec `companion` vide ; ses tests restent verts.
5. **Risque réel trouvé : la cohabitation avec OUV.3.** Une fois la vraie partie migrée en v6, toute
   APK construite depuis `main` **sans** le J11 (les sessions d'OUV.3) la refusera (« version plus
   récente ») et jouera **sans sauvegarder**. Parade, dans la procédure du T3 : sauvegarde de
   sécurité v5 avant, **restauration de la v5 après** la validation, tant que le J11 n'est pas
   fusionné dans `main`. Après la fusion de 11.0 dans `main`, plus de restauration (toutes les
   APK écrivent la v6).

### Procédure du T3 (qa-mobile, téléphone qui porte la vraie partie, 11.0 validé seul)

Variables et règles de la procédure du J9 (`jalon-09.md` §6.2) : `PKG`, `ADB`, `S`, dossier
`build/qa/jalon11_t3/`, **jamais `adb uninstall`**, lecture / écriture par `run-as`.

0. **APK v5 de référence** : construire l'APK de `main` (OUV, v5) dans une copie dédiée →
   `build/qa/jalon11_t3/kanto2026-v5.apk`.
1. **Relevé de la vraie partie** : `save_v5_kevin_avant.json` (`"version": 5`) ; copie en
   `tests/fixtures/save/v5_kevin.json` (fixture réelle, test de migration doublé par l'architecte).
   Répétition sur le Mac avec la branche du J11 : une ligne `[qa] sauvegarde v5 → v6`, aucune erreur.
2. **Migration sur le téléphone** : `tools/deploy_s24.sh` (branche du J11). Attendus : une ligne
   `[qa] sauvegarde v5 → v6` ; reprise intacte (carte, case, équipe et ordre, PV, Sac, argent,
   badge, prénom du rival, titre « Continuer »). Relever `save_v6_kevin_apres.json` : `"version": 6`,
   chaque Pokémon a un `uid` de 16 hexadécimaux, tous différents, `"status_turns": 0`,
   `"companion": ""` ; **rien d'autre ne change** hors `version`, `play_time` :
   `python3 -c "import json;a=json.load(open('save_v5_kevin_avant.json'));b=json.load(open('save_v6_kevin_apres.json'));[m.pop(k) for x in ('party','storage') for m in b[x] for k in ('uid','status_turns')];b.pop('companion');[d.pop(k) for d in (a,b) for k in ('version','play_time')];print('IDENTIQUE' if a==b else 'DIFF')"`.
   Deux fermetures forcées + relances : aucune ligne de migration, **mêmes `uid`** dans le fichier.
3. **Refus par la build v5** : `adb install -r -d build/qa/jalon11_t3/kanto2026-v5.apk`, lancer :
   avertissement « version plus récente » sur le titre, partie jouée sans sauvegarde ; le fichier
   reste **identique octet pour octet** (`cmp`) ; aucun `.corrupt`.
4. **Restauration** (tant que 11.0 n'est pas dans `main`) : réinstaller l'APK v5 de référence et
   écrire `save_v5_kevin_avant.json` dans `files/save.json` ; relancer : reprise identique à
   l'étape 1. **Ne jamais laisser une v6 sur le téléphone** pendant qu'OUV.3 se teste.
5. Rapport `build/qa/jalon11_t3/rapport.md` (verdict par étape, fichiers, journal, captures) →
   **validation de Kevin** ; puis fusion de 11.0 dans `main` (accord de Kevin) avant tout lot suivant.

### T4–T6 — statuts majeurs, confusion, effets simples, textes (2026-10-11, 11A)

Détail dans `etat-projet.md` (entrées du 2026-10-11). Capacités encore en attente
(`pending_effects`) : Hurlement, Lance-Soleil, Coud'Krâne, Danse Flamme, Ligotage, Frénésie,
Mimique, Mania, Empal'Korne, Destruction, Explosion (hors J11, dossier 14 §4.3).

### T8 — remèdes et Boutiques (2026-10-11, 11A)

`data/items/items.json` : Anti-Para (200 ₽), Réveil (250 ₽, « Réveils »), Anti-Brûle (250 ₽),
Antigel (250 ₽, « Antigels », **pas en vente**) — textes n° 34 à 37 du §13, catégorie SOINS, icône
générique du Sac (pas d'art). Stock de Jadielle et d'Argenta : les trois premiers après l'Antidote,
sans condition (dossier 14 §3.4). Textes de soin hors combat : n° 4, 9, 13, 16 (`BagQuery`), testés
(le Réveil donne « est réveillé[e]. », jamais « se réveille ! »). La liste de la Boutique de Jadielle
passe de 2 à 5 cartes et défile (le test des marges ne compte que la partie visible des cartes).

### Équilibrage de Pierre après T5 (`tools/simulate_brock.gd`, 200 graines, `main` à 906566a contre J11)

Seul écart notable : **Salamèche gagne des chances contre Pierre**, très probablement par la
brûlure de Flammèche (10 %), qui divise par deux les dégâts physiques d'Onix (Charge, Jet-Pierres)
et lui retire 1/16 de PV par tour. Victoires de Salamèche seul selon son niveau :
N12 0 → 3,5 % · N14 0,5 → 6 % · N15 0,5 → 12,5 % · N16 21,5 → 47,5 % · N17 46 → 60 % ·
N18 72 → 80,5 %. Kevin à l'arrivée (route + Liam, 5 Potions) : 0 → 2 %. Bulbizarre et Carapuce :
inchangés (± 1,5 point). Grille Onix (Racaillou 10/10) Kevin 5 Potions : 8,5 → 23,5 %. Liam
(Salamèche seul) : 34,5 → 44 %. **Signalé à Kevin, rien de corrigé ; décision de Kevin (2026-10-11) : « garde comme ça »** (risque noté au §7) :
Pierre reste un mur pour Salamèche sous N15, ce qui reste l'intention du dossier 12.

### T9 — QA des statuts : départ `status_qa` (2026-10-11, 11A) — **écart au plan §2.5**

Pas de carte `qa_status` (défaut, règle 4) : à construire puis retirer à la clôture comme au J9,
pour un seul usage. À la place, deux clés de `DebugStart` (débogage seul, jamais sauvegardées) :
`wild` (table d'herbes forcée sur la carte de départ, `EncounterLibrary.override_grass`, appliquée
par `Boot`) et `status_turns` par membre (sommeil seul). Départ `tools/debug_start/status_qa.json`
sur la Route 1 (détail dans `tools/debug_start/README.md`) : une équipe qui lance brûlure,
confusion, Para-Spore, Poudre Dodo, Puissance, Double Pied, Croc Fatal, Frappe Atlas ; trois
membres déjà brûlé / endormi 3 tours / paralysé, un gelé au Stockage ; tous les remèdes ; herbes
forcées Pikachu N12, Papilusion N17, Dardargnan N16, Rattata N14. **Non couverts** : un Dresseur
`random` et un `smart` dédiés (les Dresseurs existants de la Forêt et d'Argenta servent, départs
`trainers_qa` et `pewter_gym`). Capture de la Boutique à 5 cartes : `tools/capture_shop_j11.gd`
(relue : lisible, icône générique des remèdes).
