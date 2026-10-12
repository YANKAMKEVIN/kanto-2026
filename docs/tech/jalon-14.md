# Jalon 14 — Le mystère du Cap d'Azuria

> Objectif jouable sur le téléphone : **l'épisode de Léo**. Depuis le bout de la Route 24 nord (le
> recruteur passé), la **Route 25** longe la mer jusqu'au **Cap d'Azuria** : six Dresseurs (deux
> inévitables), Abra sauvage qui **se téléporte**, une CT au sol, un objet caché. Au bout, la
> **maison de Léo** : un Mélofée qui parle, une machine en quatre gestes guidés, un **flash**, Léo
> redevenu humain, le **Passe Bateau**, un **Super Bonbon** et un **Grand moment**. À Azuria, le
> **jardin de la maison cambriolée** : une courte poursuite, le **Rocket** dans son impasse, la
> **CT28 Tunnel**, la maison qui rouvre et le **barrage sud** levé vers « ROUTE 5 — À venir ».
>
> Mécaniques nouvelles : attaques **« charge puis frappe »** (Tunnel, avec invulnérabilité),
> **fuite adverse par Téléport**, **montée de niveau hors combat** (Super Bonbon), étape de scène
> **`flash`**, trois petites briques de monde (décor qui suit les drapeaux, PNJ dont la place
> dépend d'un drapeau, réplique « une fois sur trois »). **Format de sauvegarde inchangé** :
> v6, preuve au §2.16.

**Pré-requis.** Dossier 17 **verrouillé** (2026-10-12 : décisions §1, E-1 à E-15, V-1 à V-3,
textes §15) : c'est la **source de vérité**. Grilles `tools/plans/route_25.txt` (contrôle
`tools/art/plan_check_route_25.py`, **conforme**, relancé pour ce plan : 73 pas, 5 min 12 s) et
`tools/plans/bill_house.txt` ; références validées `route-25-vue-generale-v1.png`,
`route-25-plan-v1.png`, `maison-leo-v1.png`.

**Règle de parallélisme (Kevin)** : une session = un jalon ; J11, J12 et J13 avancent en même
temps. Tout ce qui n'exige pas un système précis d'un autre jalon part **maintenant**. Une
intégration qui l'exige attend **la fusion de ce système précis** (nommé), avec un repli.

Plan écrit sur `docs/dossier-17-j14` (base `main` à `a34e433`). Code lu, jamais modifié :
`origin/main` à **`ee5d5c9`** (J11 **11A statuts et 11B CT, Patience, oublier une capacité
fusionnés**, sauvegarde **v6**) ; `jalon-12` à `5b3fe9b` (T6 série 14, T7 fondations, T8 Route 3,
T9 Mont Sélénite ; T10 simulation) ; `jalon-13` à `2a1fe23` (main + J12 partiel + T1–T3, T6 eau,
T9 scénario) avec `docs/tech/jalon-13.md` et `docs/design/dossier-16-azuria.md` de cette branche.
Les numéros de ligne citent `origin/main` sauf mention.

Références : `CLAUDE.md`, `dossier-17-cap-azuria.md`, `passes/j14-v2-alignement.md`,
`jalon-12.md` (méthode, briques du J12), `jalon-13.md` (Azuria, eau), `dossier-14-systemes-j11.md`
(Patience §6.3, CT), `dossier-05-combat.md`, `dossier-08-menu-dresseur.md` (Sac, Grands moments).

---

## 0. État des lieux et écarts

### 0.1 Ce qui existe pour chaque besoin (`origin/main` à `ee5d5c9`) et ce qu'apportent J12 et J13

| Besoin (dossier 17) | Existant sur `origin/main` | Apporté par J12 / J13 (non fusionné) | Manque |
|---|---|---|---|
| Grilles, contrôle | `route_25.txt` (80 × 28), `bill_house.txt` (16 × 11), `plan_check_route_25.py` (profil de `plan_check.py`) | — | en-têtes encore marqués « BROUILLON » (commentaires seulement) |
| Carte côtière peinte | `pewter_map_kit.gd` ; `PaintedGround` : rivage sable + mer (`shore_mask`, `GroundMask.build_shore`) ; `ground_sable_01`, `ground_eau_01` | J12 T7 : textures de sol réglables ; **J13 T6** : `square_shore`, `foam_strength`, `water_texture`, `GroundMask.build_water`, `tools/cerulean_map_kit.gd` (eau `WATER`, modules de bord sur toute frontière eau / sol) | `tools/coast_map_kit.gd`, `build_route_25.gd` ; modules de **rivage rocheux** |
| Intérieur | `tools/build_painted_interiors.gd` (enveloppe peinte + meubles, `--rooms=`, lecture d'une grille « plan » comme Argenta, `triggers`, `interactables`) ; `interiors.json` | J13 T7 : `cerulean_house` (maison ouverte) | `bill_house`, `cerulean_burgled_house` |
| Raccords | `Warp` PUSH / STEP_ON ; `coming_soon` (développement) | J13 T8 : `route_24`, raccord est `(55, 6..8)` `coming_soon=route_25` (`route_24.txt` l. 113) ; J13 : sortie sud d'Azuria **fermée sans warp** (palissade, `azuria.txt` rangées 38–40) | raccord Route 24 ↔ 25 ; raccord « ROUTE 5 — À venir » |
| Dresseurs | `TrainerLibrary` (un fichier par lot, `trainer_library.gd:55`) ; bloc `trainer` ; `TrainerWatcher` (vue : `npc.get_cell()` mais **`spec.facing`**, `trainer_watcher.gd:62`) | J12 T17 : `rematch`, `leave` (non nécessaires ici, §2.12) | 6 Dresseurs, Rocket |
| PNJ conditionnels | `if` / `unless` (`NpcRoster`) ; `GameMap.refresh_npcs` **au changement de carte seulement** (`boot.gd:1041`) ; un identifiant = une entrée à **place fixe** (`npc_roster.gd:48`) | — | place qui dépend d'un drapeau (Rocket, §2.8) |
| Scènes | étapes `move` (premier plan, arrière-plan, course), `despawn` (fondu 0,2 s, `cutscene_director.gd:64`), `spawn`, `emote`, `face`, `dialogue`, `give`, `set`, `battle` (`win` / `lose`), `wake_up`, `caption`, `react` ; conditions d'étape ; acteur absent = étape sautée (push_error) | J12 T23 : étape `moment` ; `confirm_cutscene` | étape **`flash`** |
| Effet plein écran | `ScreenFade` (teinte au choix, `screen_fade.gd:34`) ; `Haptics.vibrate` (étape `badge`, `cutscene_director.gd:583`) ; réglages **`reduce_motion`** et **`reduce_flashes`** (`game_settings.gd:76`, `boot.gd:1383`) | — | `ScreenFlash` |
| Repère lumineux | — | **J12 T7** : `LightGlow` (sprite additif généré, types en données `light_glows.json`, vacillement coupé par « Réduire les animations ») | type `hint` ; décor qui suit les drapeaux |
| Dialogues | variantes `if` / `unless` / `set` / `auto` / `cutscene` (`dialogue_variant.gd`) ; locuteur **par page** (`dialogue_page.gd:21`) ; jeton `{player}` | J12 : `confirm_cutscene` ; J13 : `confirm_set` | tirage « une fois sur trois » (§2.8) |
| Déclencheurs | `EventTriggerPoint` (taille, direction) ; **apparaître sur la case ne déclenche rien** (`event_trigger.gd:10`) | — | — |
| Objets au sol, cachés | `object/poke_ball_ground` + `give found` + `got_<id>` | **J12 T17** : point d'examen `unless_flags` (objet caché) | — |
| Sac, CT | catégories `BALL HEAL BATTLE FIELD KEY TM` (`item_data.gd:20`) ; `TmTeach`, Sac CT, `TmLearnOverlay`, `MoveLearnPrompt.teach` (11B) ; refus « Sans effet », « Ce Pokémon est K.O. » (`bag_query.gd:41`) ; `ItemUse` refuse les K.O. (`item_use.gd:109`) | **J12 T20** : `ItemData.field_use` ; **J12 T23–T24** : UTILISER d'un objet AVENTURE sur un Pokémon, sélecteur d'états, évolution lancée depuis le Sac | `rare_candy`, parcours Super Bonbon |
| Montée de niveau | `Pokemon.gain_exp` → `LevelUp` (capacités du niveau, gains), `recalc` (garde les PV perdus, un K.O. le reste) (`pokemon.gd:114`, `:182`) | — | `RareCandy` (règle pure) |
| Évolution | `Evolution.level_up_target` (`evolution.gd:14`) ; `EvolutionDirector.play` (après combat) ; règle `trade` jamais déclenchée (`evolution.gd:8`) | J12 T23 : écran d'évolution hors combat (`play_item`, `cancellable`) | branchement Super Bonbon |
| Combat : verrou d'action | **Patience** (11B) : `Battler.bide_stage/slot/stock` (`battler.gd:32-34`) ; `get_locked_move` (`battle.gd:186`) ; `is_legal` refuse tout sauf l'action imposée (`:194`) ; `_foe_action` impose sans tirage (`:415`) ; rupture si endormi ou gelé (`:532`) | J12 T13 : piège, Entrave ; J13 T12 : IA qui change (jamais en Patience) | état **« charge puis frappe »** |
| Combat : statuts | 5 statuts, confusion, apeurement, `_can_act` (`battle.gd:569`) | — | — |
| Capacités | 67 (`moves.json`) ; `solar_beam`, `skull_bash` en `pending_effects: ["two_turn"]` ; `seismic_toss` = `fixed_damage` « level » ; CT : `tm34` | J12 : 21 capacités dont `disable` | `dig`, `teleport`, `low_kick`, `submission`, `recover`, `psychic`, `reflect` |
| Fuite | joueur seul (`_attempt_flee`, `battle.gd:325`) ; `Outcome.FLED` ; les consommateurs ne traitent que WIN / LOSS / CAUGHT (`battle_director.gd:632`, `encounter_director.gd:172`) | — | fuite **adverse** |
| Capture | Ball retirée du Sac **au choix**, avant le moteur (`battle_director.gd:35-37`) ; `_throw_ball` (`battle.gd:341`) | — | « Impossible de viser ! » |
| Espèces | 38 (`kanto.json`) ; **tous les `.json` de `species/` et `moves/` sont lus** (`pokemon_data.gd:72`), objets aussi (`item_library.gd:44`) ; artworks 063–065 présents ; dos provisoires (`gen_placeholder_battlers.gd:21`) | J12 : 12 espèces (Abo, Nosferapti…) ; J13 T11 : 9 espèces (Mystherbe, Chétiflor…) | Abra, Kadabra, Machoc |
| Pokédex | `data/pokedex/kanto.json` (un seul fichier, notes `unlock: {seen: 1}`) | J12 et J13 y ajoutent | 3 fiches |
| Grands moments | `MomentLibrary.TYPES` (5 types), `moments.json` | J12 T23 : étape `moment`, type `fossil` | type `bill_restored` |
| Objectifs | `objectives.json` (première entrée valide ; préfixe « Objectif : », convention en minuscule, `dashboard_views.gd:7`) | J13 : `explore_cerulean` (`if badge_cascade, beaten_nugget_rocket`) | 3 entrées |
| Zones | `zones.json` : aucune zone `route_24`, `route_25` ; rectangles de la Carte dans `kanto_placeholder_areas.json` | J13 : zones d'Azuria, Route 24 | `route_25`, `cerulean_cape` |
| Compagnon | rien sur `main` | J11 11D : rentre dans toute carte de `interiors.json` | `bill_house` dans `interiors.json` (données seules) |
| Sauvegarde | **v6** (`save_system.gd:35`) ; autosave aux changements de carte, fins de scène et de combat, jamais pendant une scène ni un combat | — | rien (§2.16) |
| Départs de QA | `tools/debug_start/*.json` (équipe, capacités, drapeaux, Sac, **table sauvage forcée** `wild`) | J11 / J12 : cartes de QA retirées à la clôture | départs du J14, carte `qa_charge_j14` |
| Son | aucun `AudioStreamPlayer` dans `game/` | — | point d'accroche « machine » |

### 0.2 Écarts et trous constatés

1. **Relais du dossier §3.1 (raccord Route 24 → 25) : satisfait sur le fond.** Le J13 a trois
   rangées au bord est, `(55, 6..8)`, avec `coming_soon=route_25` (`route_24.txt` l. 113). Les
   rangées diffèrent de celles de la Route 25 (13..15) : **sans effet**, chaque warp vise un point
   d'apparition nommé (`from_route_24_n|c|s` ↔ `from_route_25_n|c|s`). Rien à demander au J13.
2. **Relais du §3.3 (jardin, impasse, sortie sud) : non satisfait, et transmis au J14 par le
   J13 lui-même.** La grille d'Azuria validée (G-1 à G-5) garde le jardin **clos** (`j` bloqué),
   le trou `(14, 3)` **impraticable**, la sortie sud **fermée sans warp** (palissade `s`) ;
   `jalon-13.md` l. 99 et l. 351 renvoient la suite au J14. Le J14 modifie donc lui-même la grille
   et la carte d'Azuria **après la fusion de T7 et T17 du J13** (§1.3, §2.12). À transmettre à la
   session du J13 : garder stables les positions `porte_cambriolee`, `trou_cloture`,
   `barriere_sud`, `h4_policier`, et ne rien poser dans la bande de forêt `x 15..22, y 2..3`.
3. **Deux noms déjà pris.** « Gamin Malo » existe au J13 (P3 du Pont Pépite, même classe) et
   « Clara » aussi (Jeune Dresseuse de la Route 4). Les noms du dossier §9 sont des défauts [D] :
   **D1 → Gamin Jules, D3 → Fillette Zoé** (vérifiés libres sur toutes les branches).
   Identifiants `route_25_youngster_jules`, `route_25_lass_zoe`.
4. **Machoc Nv. 15 (RB) ne connaît que Poing Karaté.** Le dossier §9.2 cite « Poing Karaté,
   Groz'Yeux, Puissance » : c'est la table de Rouge Feu / Vert Feuille. Celle de RB
   (`pret/pokered`, vérifiée) : Poing Karaté au départ, Balayage 20, Groz'Yeux 25, Puissance 32,
   Frappe Atlas 39, Sacrifice 46. La règle écrite du dossier (« les capacités suivent les tables de
   niveau ») l'emporte : **défaut = table RB** (Gaston et le Rocket : Poing Karaté seul). Si Kevin
   préfère le trio, c'est une clé `moves` d'une ligne.
5. **Capacités des tables absentes du moteur** : Kadabra (Entrave 20 = J12, Rafale Psy et Choc
   Mental existent, **Soin 31, Psyko 38, Protection 42**), Machoc (**Balayage 20, Sacrifice 46**).
   Un learnset ne peut citer qu'une capacité connue. → 5 capacités nouvelles (Soin, Protection et
   le recul de Sacrifice « en attente », convention du J12) ; Entrave citée **après la fusion des
   données du J12** (T12), d'ici là absente de la table de Kadabra.
6. **Kadabra → Alakazam** : une règle `trade` doit viser une espèce connue (`check_references`).
   Alakazam n'entre pas au J14 → **aucune règle d'évolution pour Kadabra** au J14, ce qui tient le
   §8.2 (« la fiche n'annonce pas d'évolution par niveau »).
7. **« Étape choix qui lance une scène » (dossier §16, J12)** : **inutile au J14**. Aucun choix
   OUI / NON dans le dossier ; une variante de dialogue lance déjà une scène
   (`DialogueVariant.cutscene`).
8. **Rocket : un PNJ change de place au milieu d'une visite.** Il fouille près du trou, court au
   fond de l'impasse, puis doit y **rester** aux visites suivantes. Aujourd'hui une entrée de PNJ a
   une seule case ; deux entrées imposent deux identifiants, et la scène du combat ne sait pas
   lequel est présent. → clé **`moved`** (§2.8).
9. **Un décor qui réagit aux drapeaux pendant la visite** (lueur sur l'objet attendu) n'existe
   pas : les drapeaux changent dans la maison sans changement de carte. → **`FlagGate`** (§2.8).
10. **« Une fois sur trois »** (n° 27) : aucun tirage dans les dialogues. → clé **`one_in`**.
11. **Accueil de Mélofée à l'entrée** : une variante `auto` d'un PNJ serait rejouée quand on lui
    parle. → déclencheur au **premier pas** dans la maison (§2.9).
12. **États des meubles** (« la cabine A s'éteint, la porte de B s'ouvre ») : aucun mécanisme
    d'état de meuble. → défaut : **flash ×2, Léo disparaît puis apparaît** ; les états peints des
    cabines vont dans « Reportés » (phase DA, règle 3).
13. **Maison cambriolée** : aucun intérieur au J13. → `cerulean_burgled_house`, **même définition**
    que `cerulean_house` (précédent des Centres et des postes de la forêt).
14. **Porte qui s'ouvre** : aucun warp conditionnel. → la porte devient praticable avec son warp,
    et un **ruban** (PNJ objet, `unless cerulean_rocket_beaten`) occupe la case.
15. **« J'ai fait réparer le mur »** (n° 37) : fermer le trou ou le jardin après la victoire
    **coincerait** un joueur sauvegardé dans l'impasse (autosave de fin de scène). → décor
    seulement (planche clouée à côté du trou), aucune case ne change.
16. **Super Bonbon sur un Pokémon K.O.** : RB le permet, `ItemUse` refuse les K.O. partout. →
    défaut : **refusé** (« Ce Pokémon est K.O. »), comme les soins.
17. **Objectif n° 68** : « Le S.S. Anne fait escale à Carmin-sur-Mer. » ; les objectifs suivent
    « Objectif : » en minuscule. → mots gardés, initiale en minuscule (relu à 14A).
18. **Son de machine** : aucun son dans le jeu. → point d'accroche (signal), aucun son au J14.
19. **« Mais rien ne se passe ! »** et **« {pokemon} monte au niveau {niveau} ! »** n'existent pas
    dans `messages.json` → nouveaux.
20. **Réduction des effets** : deux réglages existent (`reduce_motion`, `reduce_flashes`). Le
    dossier ne nomme que le premier ; le flash s'adoucit **avec l'un ou l'autre** [D].
21. **Téléport et piège** (J12) : défaut, un Pokémon piégé **ne peut pas** se téléporter (« Mais
    ça échoue ! »), comme il ne peut pas fuir.
22. **Lance-Soleil, Coud'Krâne** restent en attente : le dossier dit « ensuite ». Seul Tunnel
    utilise le mécanisme au J14.
23. **Interruptions au tour 2** : le dossier cite sommeil et gel. Défaut : **toute action
    empêchée** au tour 2 (paralysie totale, confusion, apeurement aussi) fait remonter le
    Pokémon, comme la rupture de Patience (`battle.gd:532-535`).
24. **Doc** : `dossier-11-route-2.md` l. 200 nomme le Dresseur de la forêt « Scout Léo » ; les
    données disent Théo. À signaler à Kevin (aucune modification d'un dossier par ce plan).

### 0.3 Ce que le J14 attend des autres jalons (et repli)

| Livraison | Pour | Repli si elle manque |
|---|---|---|
| J11 11A–11B (**fusionnés**) | statuts, Patience (verrou), CT, oublier une capacité, Frappe Atlas | — |
| J11 11D compagnon | « rentre chez Léo » | rien à coder : `bill_house` dans `interiors.json` |
| J12 T6 (fait sur `jalon-12`) | Sbire ♂ `sbire_h`, Fillette `lass_young` | — |
| J12 T7 (fait) | `LightGlow`, textures de sol réglables | — |
| J12 T3 / T21 : planche de Mélofée intégrée comme apparence | Léo-Mélofée | le T13 du J14 l'intègre lui-même (entrée en fin de `LOOKS`) si elle manque encore |
| **J12 T12** (données) | Abo (D5, D6), Nosferapti (Rocket), Entrave (Kadabra) | D5, D6 et le Rocket attendent ; Kadabra sans Entrave |
| **J12 T17** (`unless_flags`) | objet caché O4 | point d'examen sans `unless_flags` (le bouton reste après la trouvaille) |
| **J12 T20 + T23 + T24** | Super Bonbon dans le Sac ; évolution depuis le Sac | le Super Bonbon reste visible et inutilisable ; sa validation passe à 14C ; une évolution due attend le prochain niveau gagné en combat (règle existante) |
| **J12 T23** (étape `moment`) | Grand moment de Léo | scène sans moment ; ajouté à l'alignement suivant (T23 du J14) |
| J12 T10 (fait) | simulation d'équilibrage | — |
| J13 T6 (fait sur `jalon-13`) | mer, rivage à angles droits | — |
| J13 T5 (série 15) | ruban, planche clouée | images provisoires en mémoire (tests seulement) |
| **J13 T7** (cartes d'Azuria, `build_cerulean_city.gd`, `cerulean_house`) | jardin, impasse, sortie sud, maison cambriolée | 14C attend |
| **J13 T8** (`route_24`, `build_route_24.gd`) | raccord ouest réel | bord ouest de la Route 25 en « ROUTE 24 — À venir » |
| **J13 T11** (données : Mystherbe, Chétiflor) | rencontres de la Route 25 | Roucool et Chenipan à leur place (dossier §10) |
| **J13 T17** (vie d'Azuria : policier H4, porte) | maison cambriolée, policier qui part | 14C attend |
| J13 T22 (objectifs, raccord est vivant) | ordre des objectifs | entrées du J14 en tête quoi qu'il arrive |

---

## 1. Découpage

### 1.1 Sous-jalons et validations (dossier §17)

| Sous-jalon | Contenu | Validation |
|---|---|---|
| **14.0** | art de la série 16, données (espèces, capacités, objets, Pokédex, CT, Dresseurs), Nils, étape `flash`, briques de monde | captures Mac (art sur planche de contact) |
| **14A** | Route 25 et Cap, maison de Léo, scène complète, récompenses, Super Bonbon | **S24** |
| **14B** | mécanisme « charge puis frappe », Tunnel en combat, fuite par Téléport | **S24 seul** (système risqué) |
| **14C** | jardin, poursuite, Rocket, CT28, maison, barrage levé, raccord Route 5, clôture | **S24** + fusion |

- **14B peut être validé avant 14A** : son moteur ne dépend que de la Patience, déjà sur `main`.
- Jamais trois systèmes à la fois : 14A = scène de Léo (étape `flash`, briques) + Super Bonbon ;
  14B = un système ; 14C = événement Rocket (sur briques existantes) + du contenu.
- Aucune validation de sauvegarde isolée : format inchangé (§2.16).

### 1.2 « Maintenant » ou « après fusion de … »

**Branche d'intégration `jalon-14` depuis `jalon-13`** (copie dédiée, mémoire « worktree
d'intégration »). Raison : la carte côtière a besoin de l'eau du J13 (T6) et des fondations du
J12 (T7), déjà dans `jalon-13`. Précédent : le J13 fusionne `jalon-12` dans `jalon-13`. Une
branche par tâche (`j14-t<n>-<sujet>`). `jalon-13` est refusionnée dans `jalon-14` à chaque
avancée utile (T23). **`jalon-14` n'entre dans `main` qu'après le J13** (elle le contient).

**Fichiers partagés avec J12 / J13 (risque de conflit) et parade** :

| Fichier | Autre jalon | Parade |
|---|---|---|
| `game/battle/battle.gd`, `battler.gd`, `battle_event.gd`, `battle_text.gd`, `battle_ai.gd`, `move_effect.gd`, `pokemon_data.gd` (`_EFFECT_KEYS`), `data/battle/messages.json` | J12 T13 (drain, piège, Entrave, Repos, Destruction), J13 T12 (IA qui change) | **valeurs en fin d'enum** ; logique dans un **fichier nouveau** `game/battle/charge_rules.gd` ; dans `battle.gd`, 5 points d'accroche courts et des fonctions privées **en fin de fichier** ; tests dans des fichiers nouveaux. Le J14 fusionne en dernier : **il absorbe les conflits**, les autres jalons n'ont rien à faire |
| `game/systems/cutscene/cutscene_step.gd`, `cutscene_library.gd`, `cutscene_director.gd` | J12 T23 (`moment`) | `FLASH` **après** `MOMENT` si celui-ci est déjà fusionné, sinon en fin ; « garder les deux » |
| `game/world/npc/npc_spec.gd`, `npc_roster.gd`, `game/world/map.gd` | J12 T17 (`rematch`, `leave` dans `TRAINER_KEYS`) | clé `moved` ajoutée à `KEYS` (autre ligne) ; copie de spec dans `_present_specs` |
| `game/systems/dialogue/dialogue_library.gd`, `dialogue.gd`, `dialogue_variant.gd`, `dialogue_runner.gd` | J12 T23, J13 (`_CHOICE_KEYS`) | `one_in` dans `_VARIANT_KEYS` (autre ligne) |
| `game/systems/menu/menu_director.gd`, `bag_query.gd`, `item_data.gd` | J12 T20, T23, T24 | Super Bonbon **après** eux |
| `game/boot.gd` | tous | 3 lignes (portes de drapeaux, réglages du flash, overlay du Super Bonbon) |
| `data/pokedex/kanto.json`, `objectives.json`, `moments.json`, `zones.json`, `interiors.json`, `light_glows.json`, `assets/ui/map/kanto_placeholder_areas.json` | J12, J13 | ajouts **en fin** ; « garder les deux côtés » |
| `data/pokemon/tm_compatibility.json` | J12 T12, J13 T11 | fichier **généré** : en cas de conflit, relancer `tools/gen_tm_compatibility.py` |
| espèces, capacités, objets | J12, J13 (`kanto.json`, `moves.json`, `items.json`) | **fichiers nouveaux** `species/kanto_j14.json`, `moves/moves_j14.json`, `items/items_j14.json` (les chargeurs lisent tout le dossier) : aucun conflit |
| `tools/build_character_frames.gd`, `assets/world/catalogue.json`, `tools/art/manifeste.json`, `painted_prop_rules.gd`, `tools/gen_placeholder_battlers.gd` | J12, J13 | entrées **en fin** |
| tests qui comptent les espèces ou listent des dialogues | J12, J13 | nombre aligné à chaque fusion (T23) |
| `tools/plans/azuria.txt`, `build_cerulean_city.gd`, `data/npcs/cerulean_city.json`, `build_route_24.gd` | J13 | après la fusion des tâches du J13 qui les créent ; dialogues du J14 dans un fichier nouveau `data/dialogues/cerulean_rocket.json` |

| Tâche | Agent | Quand | Dépendance réelle |
|---|---|---|---|
| T0 Plan | architecte | fait | — |
| T1 Kit série 16 | architecte | **maintenant** | — |
| T2 Génération Codex | constructeur-monde (Mac) | **maintenant**, après T1 | — |
| T3 Annexe A (textes) | Kevin | **maintenant** | — |
| T4 Nils | constructeur-monde | **maintenant** | — |
| T5 Données 14.0 | architecte | **maintenant** | (D5, D6, Rocket, Entrave : T23 après J12 T12) |
| T6 Briques de monde (`FlagGate`, `moved`, `one_in`) | architecte | **maintenant** | — |
| T7 Moteur « charge puis frappe », Tunnel | architecte | **maintenant** | Patience (`main`) |
| T8 Téléport | architecte | **maintenant**, après T7 | — |
| T9 Présentation de combat | ui-mobile | **maintenant**, après T7, T8 | — |
| T10 Carte `qa_charge_j14`, départs | constructeur-monde | **maintenant**, après T8 | — |
| T11 Session 14B | qa-mobile | après T9, T10 | — |
| T12 Étape `flash` | architecte | **maintenant** | — |
| T13 Intégration série 16 (+ Mélofée si absent) | constructeur-monde (Mac) | **maintenant**, après T2 | J12 T3 (images faites) |
| T14 Cartes `route_25`, `bill_house` (sans PNJ) | constructeur-monde | **maintenant**, après T13 | J13 T6, J12 T7 (dans `jalon-13`) |
| T15 Raccord Route 24 ↔ 25 | constructeur-monde | après fusion de **J13 T8** | J13 T8 |
| T16 Vie de la Route 25 | constructeur-monde | **maintenant**, après T5, T14 | O4 : J12 T17 ; D5, D6 : J12 T12 ; table : J13 T11 (replis) |
| T17 Scène de Léo | constructeur-monde | **maintenant**, après T5, T6, T12, T14 | moment : J12 T23 (repli) |
| T18a `RareCandy` (pur) | architecte | **maintenant** | — |
| T18b Super Bonbon dans le Sac | architecte puis ui-mobile | après fusion de **J12 T20, T23, T24** | J12 |
| T19 Session 14A | qa-mobile | après T16, T17 (T18b si prêt) | — |
| T20a Grille d'Azuria du J14 (préparée) | architecte | **maintenant** | — |
| T20b Azuria du J14 (14C) | constructeur-monde | après fusion de **J13 T7 et T17** (+ **J12 T12** pour le Rocket) | J13, J12 |
| T21 Équilibrage | architecte | après T16, T20b | — |
| T22 Session 14C | qa-mobile | après T20b | — |
| T23 Alignements | architecte | à chaque fusion de `jalon-13` | — |
| T24 Fin du J14 | constructeur-monde puis qa-mobile | après T22 et la clôture du J13 | — |
| T25 Clôture | architecte | après T24 | — |

**Parallélisme maintenant** : T1 → T2 → T13 → T14 → (T16 ∥ T17) ; en même temps T4, T5, T6, T12,
T18a, T20a ; T7 → T8 → (T9 ∥ T10) → **T11 (session 14B)**.

### 1.3 Grilles : lecture et normalisations

Les grilles font foi ; leurs `POSITIONS` sont des défauts ajustables. **Aucune case de
`route_25.txt` ni de `bill_house.txt` ne change.** Seuls les en-têtes (« BROUILLON ») sont mis à
jour (T1 : « validée le 2026-10-11, dossier 17 verrouillé »).

**Route 25** (lecture par l'outil de T14) :
1. Praticables : `.=hvsD`. `w` → tuile `WATER` (solide, `GridWorld.is_water` pour le compagnon) ;
   `s` → sable praticable ; `K`, `T`, `R`, `x`, `f`, `M` → solides.
2. Spawns sur plusieurs cases : `from_route_24_n|c|s` (0, 13..15) tournés → ;
   `from_bill_house_w|e` (71..72, 12) tournés ↓.
3. Porte (71..72, 11) STEP_ON ↑ → `bill_house` / `from_route_25` ; raccord ouest (0, 13..15) PUSH
   ← → `route_24` / `from_route_25_n|c|s` (T15 ; avant : « ROUTE 24 — À venir »).
4. Objet caché O4 : indice = case `R` (64, 20), examiné depuis (64, 19) tourné ↓ (règle du J12
   §1.3 : point d'examen sur la case-indice). Drapeau `got_route_25_hidden_1`.
5. Écarts de la vue non reproduits : Scout en D5 (le tableau dit Jeune Dresseur) ; personnages
   placés par le peintre.

**Maison de Léo** : `X` (7..8, 10) PUSH ↓ → `route_25` / `from_bill_house_w|e` ; spawn
`from_route_25` sur (7..8, 10) tourné ↑ ; meubles aux cases de la grille ; Mélofée (6, 6) ;
cabine A (2..3, 3..4), Léo y entre par (3, 5) ; Léo humain apparaît en (12, 5). La marche
d'entrée de la référence n'existe pas.

**Azuria : changements du J14** (préparés par T20a sur `jalon-14`, appliqués par T20b après le
J13 ; défauts, contrôle étendu `plan_check_azuria_j14.py`) :

| Où | J13 | J14 |
|---|---|---|
| Clôture ouest du jardin (6, 2..3) | `c` | praticable (« clôture arrachée ») ; l'examen (6, 1) reste |
| Jardin (7..13, 2..3) | `j` bloqué | praticable ; pot renversé (9, 2) reste bloqué |
| Trou (14, 3) | `y` bloqué | praticable (le passage) ; examinable (n° 29) depuis (13, 3) tourné → |
| Impasse (15..21, 2..3) | forêt, haie | praticable : **7 cases de long, 2 de large**, fermée à l'est par la forêt (x 22) |
| Porte cambriolée (10, 9) | `f` + examen | porte praticable + warp STEP_ON ↑ → `cerulean_burgled_house` ; ruban sur la case jusqu'à la victoire |
| Sortie sud (31..33, 38..40) | palissade `s`, sentier peint `a` | chemin praticable ; raccord (31..33, 40) PUSH ↓ `coming_soon` « Route 5 » ; spawns `from_route_5_w|c|e` (31..33, 40) ; (30, 38..39) et (34, 38..39) → forêt |

**Forme (T20a)** : variante `J14` **en fin de** `tools/plans/azuria.txt` (sections
`PRATICABLES_J14`, `GRILLE_J14` = 6 rangées remplacées, `POSITIONS_J14`), lue par
`lire(chemin, "J14")` (`plan_grille.py`) et `load_file(chemin, "J14")` (`plan_grid.gd`) ; sans
variante, la grille et les positions du J13 se lisent comme avant (contrôle du J13 et plan du J13
inchangés). Légende ajoutée : `J` jardin ouvert, `Y` trou praticable. Plan :
`plan_aplats.py tools/plans/azuria.txt --variante J14 --annote` →
`build/art/PLAN_AZURIA_J14_v1(_annote).png`.

Critères du contrôle : impasse ≥ 6 cases, seul accès par le trou ; jardin accessible depuis la
rue ; **aucune case du jardin ni de l'impasse ne devient jamais bloquée** (pas de piège après
une sauvegarde) ; la bande de déclenchement du combat couvre toute la largeur de l'impasse.
Aucune vue peinte nouvelle : la grille fait foi, rendu relu sur capture à 14C.

### 1.4 Kit d'assets : série 16 (méthode des J8–J13)

**Consigne de Kevin (J8–J13)** : le plus petit kit modulaire qui donne la **sensation** de la vue
validée, sans répétition visible. Vues : `route-25-vue-generale-v1.png` (falaise beige au nord,
forêt serrée, chemin de terre, mer turquoise à rivage de pierres, crique de sable, maison à toit
d'ardoise bleue entre deux massifs de fleurs) et `maison-leo-v1.png`. **La grille fait foi.**
Série **16** : **libre** sur toutes les branches (vérifié le 2026-10-12 : aucun `serie16`, aucune
fiche `serie-16-*` ; 12 = Argenta, 13 = compagnon, 14 = J12, 15 = J13). Lumière neutre (NE) pour
les objets et personnages. Fiche `docs/design/fiches-assets/serie-16-cap-azuria.md`, outil
`tools/art/serie16.py` (T1).

**A. Réutilisés tels quels**

| Rôle | Asset(s) |
|---|---|
| Sols | `ground_herbe_01`, `ground_chemin_01`, **`ground_sable_01`** (crique), **`ground_eau_01`** (mer de Bourg Palette, écume) ; décalcomanies touffes, terre, fleurs |
| Falaise du nord (`K`), piliers rocheux intérieurs (`R` hors rivage) | `relief_paroi_01..04` (série 12, beige : la vue a la même roche) |
| Forêt (`T`) | `tree_foret_01..08` par `DenseForest` + `ForestFloor` |
| Hautes herbes H1–H4 | `ground_hautes_herbes_jaune_01` (+ `_bas`) |
| Rebord L1 (`v`) | `relief_rebord_01` |
| Buissons (`x`), massifs (`f`) | `prop_buisson_a/b/c_01`, `prop_massif_01`, `prop_hortensias_01`, `prop_platebande_01` |
| Accents dans l'eau | `prop_rocher_mer_01` |
| Panneaux, objets | `prop_panneau_01`, `object/poke_ball_ground` |
| Personnages | Gamin `youngster` ×2, Montagnard `mountaineer` ×2, Fillette `lass_young` (J12), Jeune Dresseur `camper` [D], promeneur `traveler`, homme âgé `old_man`, policier `guard` ×2, Sbire ♂ `sbire_h` (J12), victime : un habitant absent d'Azuria (choisi au T20b) |
| Mélofée de Léo | planche de Mélofée (série 14, J12 T3), sans accessoire (E-4) |
| Pokémon d'ambiance | Roucool `pidgey` ×2 (`shy=fly`) |
| Pokémon en combat | artworks 063, 064, 066 ; dos **provisoires** (`gen_placeholder_battlers.gd`) |
| Intérieur | `int_grande_etagere_01`, `int_petite_etagere_01`, `int_lit_01`, `int_chevet_lampe_01`, `int_plante`, `int_chaise_bureau_01`, tapis `int_tapis_*` |
| Azuria | ruban et planche clouée de la planche « cambriolage » (série 15, J13) |

**B. Variations sans nouvel asset** : falaise plus claire au soleil couchant (étalonnage du profil
`golden_hour`) ; piliers rocheux en modules de paroi empilés ; massifs en miroir ± 8 %.

**C. Nouveaux (série 16, Codex, lumière NE) — ≈ 11 images** [D]

| Fiche → asset | Rôle que rien d'existant ne tient | Emprise | Images |
|---|---|---|---|
| `WORLD_RELIEF_RIVAGE_PLANCHE` → `relief_rivage_01..06` | bord de pierres entre sol et mer (droits, angles, extrémités), à angles droits | modules ≈ 2 × 1 | 1 |
| `WORLD_BLDG_MAISON_LEO_01` → `bldg_maison_leo_01` | maison du Cap : toit d'ardoise bleue, parabole, cheminée, porte en bois (porte = 4e et 5e colonnes) | 8 × 6 | 1 |
| `WORLD_PROP_INDICE_COQUILLAGE_01` → `prop_indice_coquillage_01` | indice discret de l'objet caché O4 | 1 × 1 | 1 |
| `INT_COQUE_MAISON_LEO_01` → enveloppe | parquet, murs boisés, grande fenêtre sur la mer, sans meubles | 16 × 11 | 1 |
| `INT_MACHINE_LEO_PLANCHE` → `int_cabine_teleport_01` (A et B, miroir), `int_console_leo_01` (grand bouton rouge), `int_ecran_diagnostic_01`, `int_module_leo_01` | la machine | 2 × 2, 2 × 1, 1 × 1 | 1 |
| `INT_BUREAU_LEO_01` → `int_bureau_leo_01` | bureau encombré de plans | 3 × 1 | 1 |
| `PNJ_LEO` (+ attente) → `leo_humain` (look `bill`) | Léo humain, tenue de bricoleur, manches retroussées [D] | 128 px | 2 |
| `WORLD_PROP_BARRIERE_POLICE_01` → `object/police_barrier` | barrière basse du barrage sud | 1 × 1 | 1 |
| `UI_ITEM_PASSE_BATEAU`, `UI_ITEM_SUPER_BONBON` → `assets/ui/items/ss_ticket.webp`, `rare_candy.webp` | illustrations du Sac (`preparer_menu.py`) ; CT28, CT19 : l'illustration CT du J11 | — | 2 |

**Conditionnels** (prompts prêts, jamais lancés par défaut) : `COMBAT_DECOR_ROUTE25_COTE_r1` (le
dossier ne liste aucun décor de combat ; repli existant = carte floutée) ; `INT_BUREAU_LEO_01`
si `int_bureau_chen_01` ne tient pas sur capture.

**D. Abandonnés** : personnages placés par la vue, Scout de D5, marche d'entrée de la maison,
états peints des cabines (reportés DA, §0.2 n° 12).

**Poids attendu** : ≈ 3 à 4 Mo de PNG.

---

## 2. Conception technique

### 2.1 Cartes et raccords (T14, T15, T20b)

| Carte | Taille | Catégorie | Lumière | `display_name` / `region` |
|---|---|---|---|---|
| `route_25` | 80 × 28 | extérieur | `golden_hour` | « Route 25 » / « Azuria — Cap d'Azuria » |
| `bill_house` | 16 × 11 | bâtiment (`interiors.json`) | `interior_warm` | « Maison de Léo » |
| `cerulean_burgled_house` | celle de `cerulean_house` | bâtiment | `interior_warm` | convention des maisons d'Azuria (J13) |

- **Outils** : `tools/coast_map_kit.gd` (étend `cerulean_map_kit.gd`, §2.2) ;
  `tools/build_route_25.gd` (deux passes masque / scène, graines fixes) ; maison :
  `build_painted_interiors.gd -- --rooms=bill_house` (lecture « plan » de la grille).
- **Sans PNJ ni rencontres** au T14 : les cases des Dresseurs, PNJ, objets et de l'indice sont
  **réservées** ; `data/npcs/route_25.json` lu s'il existe.
- **Raccords** : §1.3. T15 régénère `route_24` (constantes du warp est de `build_route_24.gd`,
  spawns `from_route_25_n|c|s` sur (55, 6..8) tournés ←) ; `test_coming_soon` passe du bord est de
  la Route 24 au **bord sud d'Azuria** (T20b).
- **Relais J15** : identifiant `route_5`, arrivée `from_cerulean` **réservés** ; repère de
  coordonnées = colonnes 31..33 au bord sud d'Azuria.

### 2.2 La côte : mer, sable, rivage rocheux (T14)

- **Mer** : cases `w`, `GroundMask.build_water` / rivage du J13, texture `ground_eau_01`, **écume**
  (`foam_strength` = celle de Bourg Palette), **`square_shore` vrai** (angles droits, paliers
  rectilignes, dossiers 01 et 07). Aucun nœud par case, aucune `Light2D`, aucune particule.
- **Sable** (`s`) : canal du masque sur `ground_sable_01` ; l'eau touche le sable sans module
  (écume seule).
- **Rivage rocheux** : modules `relief_rivage_*` posés **sur les cases `R`** qui touchent l'eau
  (droits, angles, bouts), jamais sur une case praticable (erreur sinon, règle du kit).
- **Piliers** (`R` loin de l'eau) et **falaise** (`K`) : modules de paroi série 12.
- **Tests** : `test_coast_map_kit` (modules seulement sur `R` au contact de l'eau ; sable sans
  module ; aucune case praticable couverte ; graines fixes).

### 2.3 Mécanisme « charge puis frappe » (T7)

**Donnée** (`MoveEffect.Kind.CHARGE`, en fin d'enum ; clés dans `pokemon_data.gd`
`_EFFECT_KEYS`) :

```json
"dig": { "name": "Tunnel", "type": "ground", "category": "physical",
  "power": 100, "accuracy": 100, "pp": 10,
  "effects": [{ "kind": "charge", "texts": "dig", "invulnerable": true }],
  "description": "Le Pokémon creuse au premier tour et frappe au second. Sous terre, il évite les attaques." }
```

`texts` choisit les messages (`charge_dig_start`, `charge_dig_broken`) ; `invulnerable` faux
servira à Lance-Soleil et Coud'Krâne (pas convertis au J14, §0.2 n° 22), vrai à Vol.

**État volatil** (`Battler`, en fin de variables, perdu au changement, au K.O., en fin de combat,
jamais sauvegardé) : `charge_slot: int = -1`, `invulnerable: bool`. Méthodes
`is_charging()`, `is_locked()` (Patience **ou** charge), `locked_slot()`.

**Règles pures** (`game/battle/charge_rules.gd`, fichier nouveau, statique) :
`targets_foe(move) -> bool` (capacité offensive, ou effet visant la cible : statut, confusion,
graine, apeurement, dégâts fixes, niveaux de la cible) ; `dodges(target: Battler, move) -> bool`
(`target.invulnerable and targets_foe(move)`) ; `breaks_charge(battler, can_act) -> bool`.

**Branchements dans `Battle`** (cinq points, le reste en fonctions privées en fin de fichier) :

1. `get_locked_move()` et `_foe_action()` lisent `is_locked()` / `locked_slot()` au lieu de
   `is_biding()` / `bide_slot`. Le joueur ne choisit rien (la présentation du J11 soumet
   l'action imposée), ni changement, ni Sac, ni fuite (`is_legal`). L'IA adverse n'est pas
   consultée : elle ne change donc jamais de Pokémon pendant une charge (J13 T12 compris).
2. **Tour 1** (`_apply_effect`, cas `CHARGE`) : après MOVE_USED (PP −1) : `charge_slot`,
   `invulnerable`, événement **CHARGE_STARTED** (« {pokemon} creuse un trou ! », n° 52 ; la
   présentation cache le sprite). Aucun dégât ce tour. Si le Pokémon ne peut pas agir au tour 1
   (`_can_act` faux : sommeil, gel, paralysie totale, confusion qui frappe, apeurement), rien ne
   commence : il reste en surface (E-8, comportement existant).
3. **Tour 2** (`_execute`, avant le MOVE_USED ordinaire) : si `is_charging()` : sommeil ou gel
   (même s'il se réveille ici, comme Patience) ou `_can_act` faux → **CHARGE_BROKEN** (« {pokemon}
   remonte à la surface. », n° 54 ; sprite rendu), état effacé, rien d'autre. Sinon
   **CHARGE_RELEASED** (sprite rendu), état effacé, MOVE_USED **sans PP**, puis la frappe
   ordinaire (`_strike`, précision, efficacité : Vol « n'est pas affecté », `types.json`).
4. **Invulnérabilité** (`_execute`, après MOVE_USED, avant la frappe ou la précision ; et dans la
   riposte de Patience) : si `ChargeRules.dodges(cible, capacité)` → **DODGED** sur le camp de la
   cible (« {pokemon} évite l'attaque ! », n° 53), PP dépensé, rien d'autre. Capacités sur soi
   (Puissance, Armure, Patience) : non touchées. Poison, brûlure, Vampigraine : fin de tour
   ordinaire (inchangée).
5. **Capture** (`_throw_ball`) : cible invulnérable → **BALL_BLOCKED** (« Impossible de viser ! »,
   n° 55) à la place du lancer ; la Ball est déjà retirée au choix (règle existante) ;
   l'adversaire joue son tour. Aucun sauvage du J14 ne connaît Tunnel (test seulement).

- **Fin de combat pendant la charge** (fuite adverse, K.O. par le poison) : le Battler disparaît,
  rien n'est gardé.
- **IA `smart`** (`BattleAI.score_move`) : une capacité `charge` vaut une attaque de sa puissance
  **× 0,5** [D] (deux tours) ; rien d'autre ne change. `random` : inchangée.
- **Événements** (`BattleEvent.Kind`, fin d'enum) : `CHARGE_STARTED`, `CHARGE_RELEASED`,
  `CHARGE_BROKEN`, `DODGED`, `BALL_BLOCKED` ; textes `messages.json` (`charge_dig_start`,
  `charge_dig_broken`, `dodged`, `ball_blocked`) et `battle_text.gd`.
- **Tests** (`test_charge_rules` pur ; `test_battle_charge`, graines fixées) : tour 1 puis tour 2,
  PP une seule fois ; verrou (`is_legal` refuse capacité, changement, Sac, fuite) ; adversaire qui
  charge = action imposée sans tirage d'IA ; esquive de toute capacité visant la cible, pas des
  capacités sur soi ; poison et graine en fin de tour sous terre ; chaque interruption du tour 1
  et du tour 2 ; Vol non affecté ; Ball bloquée ; K.O. par le poison sous terre ; fuite adverse
  pendant la charge ; Patience contre un Pokémon sous terre (riposte esquivée) ; IA `smart`
  choisit Tunnel ; **non-régression** : Patience, statuts, poison (`test_battle_bide`,
  `test_battle_status_j11`), Pierre (`test_brock_sequence`) et `tools/simulate_brock.gd` identiques.

### 2.4 Tunnel et CT28 (T5, T7)

- `dig` : données §2.3 (RB : 100 / 100 / 10). Au T5, `dig` entre en `pending_effects:
  ["charge"]` (le chargeur refuse un genre d'effet inconnu) ; T7 le remplace par l'effet.
- `tm28` « CT28 — Tunnel » (catégorie `tm`, `tm: 28`, `teaches: dig`, description n° 60, modèle
  `tm34`) ; toast « CT28 — Tunnel obtenue » (forme du J11).
- `tm19` « CT19 — Frappe Atlas » (`teaches: seismic_toss`, effet existant) : **11B est fusionné**,
  O1 = CT19 (dossier §11 tranché par les faits). Description : celle de la capacité.
- **Hors combat** : rien (E-9, reporté au jalon des ex-CS).

### 2.5 Téléport et fuite adverse (T8)

- **Donnée** : `teleport` « Téléport » (Psy, statut, précision 0, 20 PP, `effects: [{ "kind":
  "teleport" }]`, `MoveEffect.Kind.TELEPORT` en fin d'enum ; description à l'annexe A).
- **Règle** (`_apply_effect`, cas `TELEPORT`, après MOVE_USED) :
  - combat **de Dresseur** → **NOTHING_HAPPENED** (« Mais rien ne se passe ! », n° 57) ;
  - lanceur **piégé** (J12) → FAILED (« Mais ça échoue ! ») [D] ;
  - combat **sauvage**, lanceur adverse → **TELEPORTED** (« {pokemon} s'est téléporté ! » /
    « téléportée » au féminin, n° 56) puis BATTLE_ENDED **`Outcome.FOE_FLED`** (fin d'enum) : ni
    XP, ni capture ; Pokédex : déjà vu à l'apparition ;
  - combat sauvage, lanceur du joueur → TELEPORTED puis BATTLE_ENDED **`Outcome.FLED`** (comme
    FUITE).
- **Ordre** : règle existante (priorité 0, puis Vitesse) ; une Ball ou un objet passe avant
  l'attaque adverse. Abra sauvage ne connaît que Téléport : l'IA `random` le lance **dès son
  premier tour**. Endormi, paralysé (totalement) ou apeuré, il ne peut pas (`_can_act`).
- **Consommateurs** : `FOE_FLED` passe partout par le « sinon » (ni victoire, ni défaite :
  `battle_director.gd:632`, `encounter_director.gd:172`, `cutscene_step.gd` `outcome_flags`). IA
  `smart` : ne choisit jamais Téléport en combat de Dresseur (score 0).
- **Tests** (`test_battle_teleport`) : Abra plus lent et plus rapide ; Ball avant Téléport ; Abra
  endormi ou paralysé reste ; joueur qui se téléporte ; Dresseur « rien ne se passe » ; piégé ;
  `FOE_FLED` sans XP ni capture ; rencontre terminée proprement (`test_encounter_director`).

### 2.6 Super Bonbon (T18a pur, T18b Sac)

**Règle pure** `RareCandy` (`game/items/rare_candy.gd`) :

```gdscript
enum Check { OK, MAX_LEVEL, FAINTED }
static func check(pokemon: Pokemon) -> Check
## +1 niveau : XP portée au seuil du niveau suivant, puis Pokemon.gain_exp (stats recalculées,
## PV montés de la différence, capacités du niveau dans le LevelUp, rien d'appris ici).
static func apply(pokemon: Pokemon, data: PokemonData) -> LevelUp
## Espèce d'évolution due après le niveau gagné (Evolution.level_up_target), ou &"".
static func evolution_after(pokemon: Pokemon, data: PokemonData) -> StringName
```

- Niveau 100 → `MAX_LEVEL` (« Sans effet », objet gardé). K.O. → `FAINTED` (« Ce Pokémon est
  K.O. », objet gardé) [D, §0.2 n° 16].
- **Données** : `rare_candy` « Super Bonbon » / « Super Bonbons », catégorie `field` (AVENTURE),
  prix 0 (jamais vendu au J14), description n° 59. Au T5 **sans usage** (la clé `field_use` vient
  du J12 T20) ; T18b ajoute `field_use: "rare_candy"`.
- **Parcours (T18b, après J12 T20, T23, T24)** : Sac → AVENTURE → Super Bonbon → UTILISER →
  sélecteur de l'équipe (raisons « Sans effet », « Ce Pokémon est K.O. ») → toucher un Pokémon :
  1. le Super Bonbon est retiré, `RareCandy.apply` ;
  2. voile `TmLearnOverlay` (11B, à généraliser en « overlay d'apprentissage » [D]) : « {pokemon}
     monte au niveau {niveau} ! » (n° 62), puis chaque capacité du niveau par
     `MoveLearnPrompt.teach` (« apprend », ou oublier une capacité, GARDER annule) ;
  3. puis, si `evolution_after` n'est pas vide : évolution **par niveau**, donc **annulable**
     (ARRÊTER présent, retour Android annule, reproposée au prochain niveau gagné : règles
     existantes), par l'écran hors combat du J12 T23 ;
  4. fin → retour au Sac ; `mark_changed`, autosave à la fermeture.
- **Atomicité** : rien n'est écrit avant la fermeture du menu ; une fermeture de l'application au
  milieu reprend avant l'usage (Super Bonbon et niveau ensemble).
- **Pas en combat** : AVENTURE n'est jamais proposée en combat (`ItemData.contexts`).
- **Tests** : `test_rare_candy` (pur : stats, PV, capacités du niveau, évolution due, Nv. 100,
  K.O., Kadabra sans évolution) ; intégration `test_rare_candy_bag` (Boot réel : Abra 15 →
  Kadabra 16 avec Choc Mental ; 4 capacités → oublier ; ARRÊTER ; un exemplaire consommé une
  fois ; rechargement).

### 2.7 Étape de scène `flash` (T12)

- `CutsceneStep.Kind.FLASH` (fin d'enum, après `MOMENT` s'il est fusionné), clé `"flash"` :
  nombre d'éclairs (≥ 1). Exemple : `{ "flash": 1 }`.
- **Présentation** : `ScreenFlash` (`game/ui/components/screen_flash.gd`, un `ColorRect` plein
  écran sous le rideau de transition, `MOUSE_FILTER_IGNORE`) tenu par `ExplorationHud` :
  `flash(count: int) -> await`. Éclair [D] : blanc bleuté `UiTokens.FLASH_COLOR` (#e6f0ff), alpha
  0 → 0,9 → 0 en **0,4 s** (montée 0,08, tenue 0,08, descente 0,24), 0,2 s entre deux éclairs ;
  vibration légère `UiTokens.HAPTIC_FLASH_MS` au début de chaque éclair (si les vibrations sont
  permises). **Réduction** (`reduce_motion` **ou** `reduce_flashes`) : fondu doux, alpha max
  0,35 en 0,6 s.
- **Son** : signal `flash_started` du directeur (point d'accroche, aucun son au J14).
- Boot passe les deux réglages à `ExplorationHud` (une ligne près de `boot.gd:1389`).
- La scène attend la fin du flash. Sans HUD : push_error, étape sautée.
- **Tests** : `test_cutscene_library` (`flash`, nombre ≥ 1), `test_cutscene_director` (attend la
  fin), `test_screen_flash` (`TweenClock` : pas fini avant 0,4 s, au plus un pas de plus ; deux
  éclairs ; version réduite ; contrôles tactiles non bloqués).

### 2.8 Briques de monde (T6)

**`FlagGate`** (`game/world/flag_gate.gd`, `Node2D`) : `@export var if_flags`, `unless_flags` ;
`apply(flags: StoryFlags)` règle `visible`. Groupe `&"flag_gate"`. `GameMap.apply_flag_gates
(flags)` les applique tous (appelé dans `refresh_npcs`) ; Boot relie
`GameState.flags.flag_changed` à la carte courante. Sert aux lueurs de la machine (un `LightGlow`
du J12, type **`hint`** en fin de `light_glows.json` : blanc bleuté, rayon 1,3 case, alpha 0,22,
vacillement 0,12 coupé par « Réduire les animations ») et à la planche clouée d'Azuria.
Tests : `test_flag_gate` (pur), intégration (une lueur suit un `set` en cours de visite).

**`moved`** (clé d'une entrée de PNJ) :

```json
"cerulean_rocket": { "cell": [13, 2], "facing": "up", "sprite": "sbire_h",
  "unless": ["cerulean_rocket_beaten"],
  "moved": { "if": ["cerulean_rocket_spotted"], "cell": [21, 3], "facing": "left" } }
```

`NpcSpec.placed_for(flags) -> NpcSpec` (copie à la case et l'orientation de `moved` si ses
drapeaux sont levés) ; `GameMap._present_specs` l'utilise. Dans la visite où le drapeau se lève,
le PNJ reste où la scène l'a mené (aucun rafraîchissement). Refusé avec un bloc `trainer` (la
vue lit `spec.facing`, `trainer_watcher.gd:62`). Tests : `test_npc_roster`, `test_game_map`.

**`one_in`** (clé d'une variante de dialogue, entier ≥ 2) : la variante ne s'applique qu'une fois
sur N, tirée par le `DialogueRunner` (`GameRng`) **après** ses drapeaux ; sinon on passe à la
suivante. `Dialogue.pick(flags, rng = null)` : sans tirage, une variante `one_in` est sautée
(tests déterministes). Tests : `test_dialogue_library`, `test_dialogue_runner` (graine).

### 2.9 Scène de Léo (T17)

**PNJ** (`data/npcs/bill_house.json`) :
- `bill_clefairy` (6, 6), planche de Mélofée, verbe PARLER, `unless: [bill_in_cabin]`, dialogue
  `bill_clefairy` ;
- `bill` (12, 5), look `bill`, `if: [bill_restored]`, dialogue `bill`.

**Objets interactifs** (verbe EXAMINER, cases de la grille) : écran (5, 3), module (10, 3),
console (7..8, 3), cabine A (2..3, 3..4). **Lueurs** (`FlagGate` + `LightGlow hint`) : écran `if
bill_met unless bill_screen_checked` ; module `if bill_screen_checked unless bill_module_checked` ;
console `if bill_in_cabin unless bill_restored`.

**Déclencheur d'entrée** : (7..8, 9), pas vers ↑ (premier pas depuis le paillasson) → scène
`bill_house_enter` : variante `unless bill_met` (`emote !` Mélofée, `face` Mélofée → joueur,
`dialogue` n° 1) ; variante `if bill_in_cabin unless bill_restored` (`dialogue` n° 11, locuteur
« Léo ») ; sinon rien.

**Dialogues** (`data/dialogues/bill_house.json`, textes §15 mot pour mot, `{joueur}` → `{player}`) :

| Dialogue | Variantes (première qui s'applique) |
|---|---|
| `bill_clefairy` | `if bill_met` → n° 12 ; sinon → n° 2 à 6 (locuteur par page : « Mélofée » pour 1–2, « Léo » ensuite [D]), `set bill_met` |
| écran | `if bill_restored` → n° 17 ; `if bill_met unless bill_screen_checked` → n° 13 puis n° 7 (« Léo »), `set bill_screen_checked` ; sinon → n° 13 |
| module | `if bill_screen_checked unless bill_module_checked` → n° 14 puis scène `bill_module` ; `if bill_met unless bill_screen_checked` → n° 10 ; sinon → n° 14 |
| console | `if bill_in_cabin unless bill_restored` → n° 15 puis scène `bill_machine` ; `if bill_met unless bill_module_checked` → n° 9 ; `if bill_restored` → annexe A n° A-8 ; sinon → n° 16 |
| cabine A | `if bill_in_cabin unless bill_restored` → n° 11 ; sinon → rien (pas d'interaction) |
| `bill` | `one_in: 3` → n° 25 puis 27 ; `unless cerulean_rocket_beaten` → n° 25 puis 26 ; sinon → n° 25 |

**Scène `bill_module`** (étape 3) : `dialogue` n° 8 → `move bill_clefairy` vers (3, 5) → `face`
↑ → `despawn bill_clefairy` → `set [bill_module_checked, bill_in_cabin]`.

**Scène `bill_machine`** (étape 4) : signal machine → `flash 1` → `wait 0.3` → `flash 1` →
`spawn bill` (12, 5) tourné ↓ → `react bill` → `face` × 2 → `dialogue` n° 18–20 → `give ss_ticket`
→ `dialogue` n° 21 (narration) → `dialogue` n° 22 → `give rare_candy` → `dialogue` n° 23
(narration) → `dialogue` n° 24 → `moment bill_restored` (J12 T23) → **`set [bill_restored,
got_ss_ticket, got_bill_rare_candy]` en dernier**.

- **Sortie en cours de route** : drapeaux des étapes 1–3 gardés ; au retour, Mélofée est absent
  après l'étape 3 (`unless bill_in_cabin`) et la console attend.
- **Fermeture pendant l'étape 4** : aucune autosave pendant une scène ; Sac, moment et drapeaux
  sont écrits ensemble à la fin. Au retour, la console rejoue la scène entière ; les objets ne
  sont jamais donnés deux fois (drapeaux posés au même moment que la sauvegarde).
- **Compagnon** : rentre en entrant (`interiors.json`, règle du J11).
- **Tests** : `test_bill_house` (Boot réel : chaque étape dans l'ordre ; objets hors de l'ordre →
  aides ; lueur sur le bon objet à chaque étape ; sortie et retour à chaque étape ; fermeture
  simulée pendant l'étape 4 → rejouée, objets une seule fois ; Grand moment unique ; Léo après).

### 2.10 Récompenses, Grand moment, objectifs (T5, T17)

- `ss_ticket` « Passe Bateau » (catégorie `key`, sans prix, description n° 58) ; toast « PASSE
  BATEAU — ajouté aux objets clés » (existant) ; aucun bouton UTILISER.
- Grand moment : `MomentLibrary.TYPES += bill_restored` ; `moments.json` : titre « Léo a retrouvé
  forme humaine » (n° 69), détail vide ; lieu = zone de `bill_house` = **« Cap d'Azuria »**.
- Zones (`zones.json`, en fin) : `route_25` (route, `[route_25]`, sous-titre et description :
  annexe A) ; `cerulean_cape` « Cap d'Azuria » (lieu, `[bill_house]`) ; rectangles de la Carte.
- Objectifs (`objectives.json`, **en tête**) : `ss_anne` « le S.S. Anne fait escale à
  Carmin-sur-Mer. » `if got_ss_ticket` ; `help_bill` « aider Léo. » `if bill_met unless
  bill_restored` ; `go_cerulean_cape` « rejoindre le Cap d'Azuria. » `if beaten_nugget_rocket
  unless bill_met`. Le cambriolage n'a aucun objectif. Test `test_objective_library`.

### 2.11 Route 25 : Dresseurs, rencontres, objets, PNJ (T5, T16)

**Dresseurs** (`data/trainers/route_25.json`, IA `random`, capacités des tables) :

| Rôle | Identifiant | Nom | Équipe | ₽ | Case, vue | Quand |
|---|---|---|---|---|---|---|
| D1 | `route_25_youngster_jules` | Gamin Jules | Rattata 15, Piafabec 15 | 225 | (18, 10) ↓, 5 | T5 |
| D2 | `route_25_hiker_gaston` | Montagnard Gaston | Machoc 15, Racaillou 15 | 525 | (45, 10) ↓, 5 | T5 |
| D3 | `route_25_lass_zoe` | Fillette Zoé | Nidoran ♂ 15, Nidoran ♀ 15 | 225 | (31, 6) ←, 3 | T5 |
| D4 | `route_25_hiker_bernard` | Montagnard Bernard | Onix 17 | 595 | (38, 19) ↑, 2 | T5 |
| D5 | `route_25_jr_trainer_adam` | Jeune Dresseur Adam | Rattata 14, Abo 14 | 280 | (63, 10) ↑, 3 | après J12 T12 |
| D6 | `route_25_youngster_yanis` | Gamin Yanis | Abo 14, Sabelette 14 | 210 | (73, 17) ←, 4 | après J12 T12 |

Répliques n° 46–51 (avant · `defeated` · après). Classe nouvelle « Jeune Dresseur » (base 20).

**Rencontres** (`data/encounters/route_25.json`, `grass`, **taux 15**, rampe par défaut des
routes) : Roucool 13 (20), Mystherbe 12–14 (18) [D], Chétiflor 12–14 (17) [D], Chenipan 8 (10),
Aspicot 8 (10), Chrysacier 7 (5), Coconfort 9 (5), **Abra 10–12 (15)**. Repli avant J13 T11 :
Roucool 38, Chenipan 27.

**Objets** : O1 `tm19` (33, 5), O2 Potion (35, 19), O3 Poké Ball (77, 21) (modèle du J8) ; O4
Potion cachée, indice coquillage (64, 20) (J12 T17 ; repli §0.3).

**PNJ** : promeneur `traveler` (14, 10) → n° 44 ; homme âgé `old_man` (66, 16) ↓ → n° 45 ;
panneaux (3, 12) n° 42 et (69, 12) n° 43 ; Roucool (33, 18) et (62, 18) `shy=fly`.

**Tests** : `test_route_25` (grille de la scène = grille ; critères de `plan_check_route_25.py`
sur la vraie scène ; nœuds ≤ 3 000), `test_route_25_trainers` (D1, D2 inévitables, D3–D6
évitables avec les PNJ), `test_route_25_life` (objets, panneaux, rencontres, Abra), `test_map_links`.

### 2.12 Azuria : jardin, poursuite, Rocket, barrage, maison (T20a, T20b)

Grille : §1.3. Données nouvelles dans `data/dialogues/cerulean_rocket.json` et
`data/trainers/cerulean_rocket.json` ; entrées ajoutées à `data/npcs/cerulean_city.json` (J13).

- **Rocket** : PNJ `cerulean_rocket` (exemple du §2.8) : fouille en (13, 2) tourné ↑ (dos au
  joueur) ; `moved` → (21, 3) tourné ← ; dialogue → scène du combat. Dresseur `cerulean_rocket`
  « Sbire Rocket », Machoc 17, Nosferapti 17, 510 ₽, `smart` (après **J12 T12**).
- **Poursuite** : déclencheur (7, 2..3), pas vers → → scène `cerulean_rocket_chase` (variante
  `unless cerulean_rocket_spotted`) : `set cerulean_rocket_spotted` (au début, dossier §14) →
  `emote !` → `face` → `dialogue` n° 30 → `move` **en courant** par le trou jusqu'à (21, 3) →
  `face` ←. Le joueur reprend la main.
- **Trou** : point d'examen (14, 3) → n° 29 (narration).
- **Combat** : déclencheur (17, 2..3), pas vers → (toute la largeur de l'impasse) → scène
  `cerulean_rocket_fight` (`if cerulean_rocket_spotted unless cerulean_rocket_beaten`) : `move`
  près du joueur (`near`, facultatif) → `face` × 2 → `dialogue` n° 31 (`unless
  lost_cerulean_rocket`) ou n° 32 (`if`) → `battle cerulean_rocket` (`win:
  [cerulean_rocket_beaten]`, `lose: [lost_cerulean_rocket]`) → victoire : n° 33 → `give tm28` →
  n° 34 (narration) → `set got_tm28` → n° 35 → `move` jusqu'au trou (14, 3) → `despawn` →
  `despawn` du policier de la maison et du ruban ; défaite : `wake_up` (réveil au Centre, sans
  perte d'argent, règle existante). Pas de Grand moment. Modèle de Pierre, **aucune brique du
  J12** (`lose` existe sur `main`).
- **Maison** : ruban `cerulean_police_tape` (PNJ objet, ruban de la série 15) sur la porte (10,
  9), `unless cerulean_rocket_beaten`, EXAMINER → n° 12 du J13 ; policier H4 du J13 : `unless
  cerulean_rocket_beaten`. Intérieur `cerulean_burgled_house` : victime → n° 36, puis n° 37.
  Planche clouée (`FlagGate if cerulean_rocket_beaten`) sur la clôture (14, 2), à côté du trou,
  **qui reste praticable** (§0.2 n° 15).
- **Barrage sud** : policier `guard` (31, 38) tourné ↑, barrières `object/police_barrier` (32,
  38) et (33, 38), tous `unless cerulean_rocket_beaten` ; parler avant → n° 40. Après la
  victoire, dans la même visite : déclencheur (31..33, 37), pas vers ↓, ou parler → scène
  `cerulean_south_guard` (`if cerulean_rocket_beaten`) : n° 41 → `move` vers le nord → `despawn`
  du policier et des deux barrières, puis `set cerulean_south_guard_left`. **[D] T20a** : barrage
  `unless cerulean_south_guard_left` (et non `unless cerulean_rocket_beaten`) et scène `if
  cerulean_rocket_beaten unless cerulean_south_guard_left` : sinon, aux visites suivantes, la bande
  relancerait n° 41 sans policier (un `EventTrigger` n'a pas de condition). Conséquence : qui
  quitte Azuria sans passer au sud retrouve le policier, qui annonce la réouverture et part.
- **Habitants** : variantes `if cerulean_rocket_beaten` en tête des dialogues du pêcheur H1 →
  n° 38 et de la voisine H3 → n° 39 [D].
- **Raccord sud** : `coming_soon = "Route 5"` (développement ; bord bloqué en release).
- **Tests** : `test_cerulean_garden` (grille J14 sur la scène ; impasse ≥ 6 ; aucune case
  bloquée après la victoire), `test_cerulean_rocket` (Boot réel : poursuite une fois ; reprise
  au point d'arrêt après rechargement ; défaite → Centre → n° 32 ; victoire → CT28 une fois,
  départ, maison ouverte ; ordre libre avec Léo), `test_cerulean_south` (barrage avant, départ,
  absent ensuite, « ROUTE 5 — À venir »), `test_coming_soon` (déplacé), `test_map_links`.

### 2.13 Espèces, capacités, Pokédex, CT, sprites (T5)

- `data/pokemon/species/kanto_j14.json` : `abra` (063), `kadabra` (064), `machop` (066) —
  **conventions existantes** : statistiques et taux actuels, types modernes (Psy, Combat),
  apprentissages RB (`pret/pokered`, vérifiés) : Abra `[1, teleport]` ; Kadabra `[1, teleport]`,
  `[1, confusion]`, `[16, confusion]`, `[27, psybeam]`, `[31, recover]`, `[38, psychic]`,
  `[42, reflect]` (+ `disable` 1 et 20 après J12 T12) ; Machoc `[1, karate_chop]`,
  `[20, low_kick]`, `[25, leer]`, `[32, focus_energy]`, `[39, seismic_toss]`,
  `[46, submission]`. Évolutions : Abra → Kadabra (16) ; Kadabra **aucune** (§0.2 n° 6) ; Machoc →
  Machopeur (28) **omise** (espèce absente, Machoc de Dresseur seulement).
- `data/pokemon/moves/moves_j14.json` : `teleport`, `dig` (§2.3–2.5), `low_kick` Balayage
  (50 / 90 / 20, apeurement 30 %, RB), `submission` Sacrifice (80 / 80 / 25, recul en attente),
  `recover` Soin (attente), `psychic` Psyko (90 / 100 / 10, Déf. Spé. −1 à 10 %, comme Acide au
  J12), `reflect` Protection (attente). Descriptions : n° 60 pour Tunnel, annexe A pour les autres.
- `data/items/items_j14.json` : `tm19`, `tm28`, `ss_ticket`, `rare_candy` (§2.4, §2.6, §2.10).
  **`trade_cord` n'est pas créé** (aucune source, §2.15).
- Pokédex (`kanto.json`) : 3 fiches (n° 63–65 ; notes `unlock: {seen: 1}`).
- CT : `gen_tm_compatibility.py` relancé (Abra : pas de CT28 ; Kadabra et Machoc : CT28).
- Sprites provisoires : `gen_placeholder_battlers.gd` += `abra`, `kadabra`, `machop` (en fin).
- Tests : `test_pokemon_data` (learnsets résolus, nombre d'espèces), `test_pokedex_library`,
  `test_tm`, `test_item_library`, `test_trainer_library`.

### 2.14 Nils (T4)

`data/npcs/pallet_town.json` : `leo` → `nils`, `leo_rattata` → `nils_rattata` ;
`data/dialogues/pallet_town.json` : dialogue `nils` (locuteur « Nils », n° 70, répliques
inchangées), `react: "nils_rattata"`, `observe_nils_rattata` ; `tests/integration/
test_dialogue_data.gd` (l. 84, 91, 586, 590). **L'apparence `leo` garde son nom** (planche,
`catalogue.json`, `build_character_frames.gd:62`) : aucun effet visible, et aucun fichier
partagé avec J12 / J13 n'est touché [D]. Les fixtures de test gardent `leo` (données de test).

### 2.15 Cordon d'échange

Règle fixée (dossier §8.2) : `"method": "trade"` = « avec le Cordon d'échange », objet consommé,
parcours de la Pierre Lune. **Rien n'est codé au J14** : ni objet, ni règle, ni source. Le jalon
qui place le premier Cordon ajoute `trade_cord` et la règle, et Alakazam si besoin.

### 2.16 Drapeaux et sauvegarde : **aucune version nouvelle** (preuve)

Règle d'en-tête de `save_system.gd` (l. 22) : incrémenter `VERSION` quand un champ change de
forme ou quand on ajoute un champ. Inventaire, champ par champ de `GameState.to_dict()`
(`game_state.gd:264`) :

| Ce que le J14 mémorise | Champ existant | Forme |
|---|---|---|
| `bill_met`, `bill_screen_checked`, `bill_module_checked`, `bill_in_cabin`, `bill_restored`, `got_ss_ticket`, `got_bill_rare_candy`, `cerulean_rocket_spotted`, `cerulean_rocket_beaten`, `lost_cerulean_rocket`, `cerulean_south_guard_left`, `got_tm28`, `beaten_route_25_*`, `got_route_25_*` | `flags` | inchangée |
| Passe Bateau, Super Bonbon, CT28, CT19, Potions, Ball | `bag` | inchangée |
| Objets trouvés O1–O4 | `found_items` | inchangée |
| Grand moment `bill_restored` | `moments` (`{type, date, map, details}`) | inchangée |
| Abra, Kadabra, niveaux du Super Bonbon, Tunnel appris | `party`, `storage` | inchangée |
| Position (Route 25, maisons) | `map`, `cell`, `facing` | inchangée |
| Charge, invulnérabilité, verrou | **rien** : volatils, jamais écrits pendant un combat | — |
| Étapes de la machine en cours, poursuite en cours | **rien** : aucune autosave pendant une scène | — |

Aucun champ ajouté ni transformé → le J14 écrit la **v6**. Une build plus ancienne écarte les
valeurs inconnues (espèce, capacité, objet) dans `save.json.rejected`, comme aux J8–J13.
**Garde** : toute tâche qui voudrait un champ nouveau s'arrête et revient à l'architecte.
Test `test_save_j14` : partie au Cap (Léo dans la cabine, Rocket repéré non battu, Super Bonbon
utilisé, Kadabra Tunnel) → `to_dict` → JSON → `load_dict` → tout identique ; `VERSION` inchangée.

### 2.17 Budgets et mesures

- ≤ 3 000 nœuds par carte, mesuré dès le premier passage du T14 (2 240 cases, dont ≈ 30 % de
  forêt et 6 rangées de mer sans nœud).
- Mémoire « carte + voisines » : Route 25 (Route 24 ; la maison, intérieure, n'est pas
  préchargée) ; Azuria (inchangée hors trois PNJ objets).
- fps : moyenne ≥ 58, creux ≥ 50 sur la Route 25 (mer animée) ; flash sans chute (≥ 55).

### 2.18 Départs de débogage et carte de QA (T10, T16, T17, T20b)

- **Carte `qa_charge_j14`** (modèle `qa_status` / `qa_moves_j12`, tuiles provisoires) :
  Dresseur `smart` d'essai (QA seulement) dont un Pokémon connaît Tunnel, un autre Poudre Dodo,
  un autre Cage-Éclair ; herbes forcées (Abra Nv. 10) ; départ **`charge_qa`** (Kadabra Tunnel,
  Pikachu, Roucool (type Vol), Balls, remèdes). La Ball bloquée n'est vérifiée qu'en test (aucun
  sauvage ne peut connaître Tunnel). **Retirée au T24.**
- Départs (`tools/debug_start/`, README) : `route_25` (après le recruteur, équipe Nv. 18–22 [D]),
  `route_25_cape` (près de la maison), `bill_house` (avant, `bill_met`, `bill_in_cabin`),
  `bill_after`, `teleport_qa` (Route 25, table forcée Abra), `rare_candy_qa` (Abra 15, Pokémon à 4
  capacités au seuil d'un niveau, Pokémon Nv. 100, Pokémon K.O., 5 Super Bonbons),
  `cerulean_garden` (avant la poursuite), `cerulean_rocket_weak` (pour perdre), `cerulean_after`.

---

## 3. Tâches

Branche **`jalon-14`** depuis `jalon-13`, une branche par tâche (`j14-t<n>-<sujet>`) ; jamais de
`pkill` ; chaque tâche met à jour `etat-projet.md` dans son commit ; textes **mot pour mot** du §15
et de l'annexe A validée.

#### T0 — architecte : plan (fait)

#### T1 — architecte : kit d'assets série 16 — **maintenant**
- Fiche `docs/design/fiches-assets/serie-16-cap-azuria.md` (une fiche par asset du §1.4 C :
  taille, emprise, couche, ombre, références recadrées `REF_R25_*`, `REF_LEO_*`) ;
  `tools/art/serie16.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste`
  préparé non lancé, `--controle`) ; prompt d'attente de Léo ; planche de contrôle ; en-têtes des
  deux grilles mis à jour (commentaires).
- **CA** : chaque élément des deux vues a un asset (réutilisé, varié, nouveau) ou est abandonné
  explicitement ; aucune case de grille changée.
- **Fait (2026-10-12, branche `j14-t1`)** : `tools/art/serie16.py` (`--prompts`, `--refs`,
  `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` non lancé, `--controle`),
  9 prompts (`tools/art/prompts/serie16/`, `attente/prompts/LEO_HUMAIN_ATTENTE.txt`,
  `combat_decors/prompts/COMBAT_DECOR_ROUTE25_COTE_r1.txt`), 24 recadrages `REF_R25_*` /
  `REF_LEO_*`, planche `build/art/R25_KIT_v1.png` relue, fiche
  `docs/design/fiches-assets/serie-16-cap-azuria.md`, en-têtes des deux grilles (commentaires ;
  `plan_check_route_25.py` conforme). **7 images** au lieu de ≈ 11 [D] : coquillage et clôture
  réparée dans la planche du rivage, bureau dans la planche de Léo (+ bibliothèque de côté), deux
  icônes sur une planche, barrière de police → conditionnel (croisillon de la série 15) ; look
  `bill` (le look `leo` est Nils).

#### T2 — constructeur-monde (Mac, Codex) : série 16 → **14.0-art** — **maintenant**, après T1
- Génération (trois à la fois, corrections en `_r2`) ; repli app ChatGPT si Codex refuse ;
  planche de contact `build/captures/jalon14_assets/` → Kevin. **CA** : images validées.
- **Fait (2026-10-12, branche `j14-t1`)** : 7 images générées en `_r1`, sans reprise (Codex), relues
  contre la fiche ; planche `build/captures/jalon14_assets/serie16_contact.png` (non versionnée).
  Écarts à valider par Kevin : Léo humain lit plus « jeune » que 25 ans (proportions chibi de la
  main du projet) ; rivage : fine ligne d'eau claire au pied des blocs, un peu d'écume possible
  (`_r2` « ni écume » si refusé) ; cabine : anneau bleu lumineux au sol (pas de halo extérieur).

#### T3 — Kevin : annexe A — **maintenant**
- **CA** : validée en une passe ; bloque les données concernées (T5, T16, T17), pas le code.

#### T4 — constructeur-monde : Nils — **maintenant**
- §2.14. **CA** : `test_dialogue_data` vert ; « Nils » affiché à Bourg Palette (capture Mac).

#### T5 — architecte : données 14.0 — **maintenant**
- §2.13, §2.4 (CT, `dig` en attente), §2.10 (objets, moment `bill_restored` dans
  `moments.json` seulement si `MomentLibrary` l'accepte, sinon au T17), Dresseurs D1–D4, zones et
  rectangles de la Carte. **CA** : tests verts ; aucune carte touchée.

#### T6 — architecte : briques de monde — **maintenant**
- §2.8 (`FlagGate` + `GameMap.apply_flag_gates` + Boot, `moved`, `one_in`, type de halo `hint`).
- **CA** : tests verts ; cartes existantes inchangées (diff nul sur leurs `.tscn`).
- **Fait (2026-10-12, commit `1c3119c`, branche `j14-t6`)** : `FlagGate` (`game/world/flag_gate.gd`, groupe
  `flag_gate`, visuel seulement), `GameMap.apply_flag_gates` (appelée par `refresh_npcs`, puis
  par Boot à chaque `flag_changed`) ; clé `moved` (`NpcSpec.placed_for`, `MOVED_KEYS`, refusée
  avec `trainer`, `route` et dans une étape `spawn`) ; `refresh_npcs` recrée à l'arrivée un PNJ
  qui n'est pas à sa place, jamais pendant la visite ; `one_in` (`DialogueVariant.one_in`,
  `Dialogue.pick(flags, rng)`, `DialogueRunner.rng_source` posé par Boot sur `GameState.rng`,
  refusé avec `auto`) ; type `hint` en fin de `light_glows.json` ; Boot coupe aussi le
  vacillement des halos avec « Réduire les animations » (`LightGlow.set_reduce_motion`, jamais
  appelé jusque-là). Tests dans des fichiers nouveaux (`test_flag_gate`, `test_npc_moved`,
  `test_dialogue_one_in`, `test_world_bricks_j14`) plutôt que dans `test_npc_roster`,
  `test_game_map`, `test_dialogue_runner` (moins de conflits avec J12 / J13). Aucune `.tscn` de
  carte touchée.

#### T7 — architecte : moteur « charge puis frappe » + Tunnel — **maintenant**
- §2.3. **CA** : tests verts ; Pierre et le rival inchangés ; `simulate_brock.gd` identique.

#### T8 — architecte : Téléport — **maintenant**, après T7
- §2.5. **CA** : tests verts ; rencontres sauvages inchangées hors Téléport.

#### T9 — ui-mobile : présentation de combat — après T7, T8
- Sprite caché au CHARGE_STARTED, rendu au CHARGE_RELEASED / CHARGE_BROKEN (fondu court,
  « Réduire les animations » : immédiat) ; sprite adverse qui s'efface au TELEPORTED ; textes ;
  aucune carte de capacité nouvelle (le tour 2 passe seul, présentation du J11). Captures relues.
- **CA** : `game/battle/battle_stage.gd` et `game/ui/battle/` seuls touchés (+ `ui_tokens.gd`
  en fin).

#### T10 — constructeur-monde : carte `qa_charge_j14` + départs `charge_qa`, `teleport_qa` — après T8

#### T11 — qa-mobile : **session 14B** (S24 seul) → Kevin
- Tunnel (deux tours, sprite, esquive, poison sous terre, interruptions, Vol, verrou), IA d'essai qui creuse, Téléport (Abra qui fuit, Ball d'entrée, Abra endormi capturé,
  joueur qui fuit, Dresseur « rien ne se passe »). **CA** : rapport `build/qa/jalon14_t11/` ;
  validation de Kevin.

#### T12 — architecte : étape `flash` — **maintenant**
- §2.7. **CA** : tests verts ; capture Mac du flash et de sa version réduite.
- **Fait (2026-10-12, commit `1c3119c`, branche `j14-t6`)** : `CutsceneStep.Kind.FLASH` / `"flash"` **en fin
  d'enum** (l'étape `moment` du J12 T23 n'existe sur aucune branche locale) : **à la fusion du
  J12, `FLASH` passe après `MOMENT`**, dans `Kind`, `TYPE_KEYS` et `_EXTRA_KEYS` (garder les
  deux, `[]` pour `flash`) ; `CutsceneDirector._flash` + signal `flash_started(count)` ;
  `ScreenFlash` (`game/ui/components/screen_flash.gd`, dernier enfant de `Root` dans
  `exploration_hud.tscn` : au-dessus du HUD, sous le rideau, toucher non bloqué),
  `ExplorationHud.flash(count)`, `set_flash_reduced` (Boot : `reduce_motion or
  reduce_flashes`) ; jetons `FLASH_*`, `HAPTIC_FLASH_MS` (25 ms) en fin de `ui_tokens.gd`.
  Captures Mac relues (`build/captures/jalon14_t12/` : `avant`, `flash_normal`,
  `flash_reduit`). Tests `test_cutscene_flash`, `test_screen_flash`,
  `test_cutscene_director_flash`.

#### T13 — constructeur-monde (Mac) : intégration série 16 — **maintenant**, après T2
- `serie16.py --manifeste` (en fin), `preparer.py` deux fois, règles de décor, scènes
  d'objets, looks `bill`, objets `police_barrier` et `police_tape` (image de la série 15),
  icônes ; **Mélofée** en look `pokemon/clefairy` si absente (noté pour le J12).
- **CA** : second passage de `preparer.py` sans changement ; `test_painted_props` vert.

#### T14 — constructeur-monde : cartes `route_25` et `bill_house` (sans PNJ) — **maintenant**, après T13
- §2.1, §2.2 ; raccord ouest provisoire « ROUTE 24 — À venir » ; `lighting`, `zones`,
  `interiors.json`. Tests `test_route_25`, `test_coast_map_kit`, `test_bill_house_map`,
  `test_map_catalog`, `test_map_links` ; captures 2340 × 1080 relues contre les vues ; nœuds.

#### T15 — constructeur-monde : raccord Route 24 ↔ 25 — après fusion de **J13 T8**
- §2.1. **CA** : aller-retour sur les trois rangées ; `test_map_links`.

#### T16 — constructeur-monde : vie de la Route 25 (14A) — **maintenant**, après T5, T14
- §2.11 ; D5, D6 au T23 (J12 T12) ; O4 par point d'examen (J12 T17, repli) ; table de repli
  jusqu'à J13 T11 ; objectifs ; départs `route_25`, `route_25_cape`, `teleport_qa`.

#### T17 — constructeur-monde : scène de Léo (14A) — **maintenant**, après T5, T6, T12, T14
- §2.9, §2.10 ; moment par J12 T23 (repli : ajouté au T23) ; départs `bill_house`, `bill_after`.

#### T18a — architecte : `RareCandy` — **maintenant**
- §2.6 (règle pure, tests). **CA** : tests verts.

#### T18b — architecte puis ui-mobile : Super Bonbon dans le Sac — après fusion de **J12 T20, T23, T24**
- §2.6 (parcours, overlay, évolution) ; départ `rare_candy_qa` ; captures.

#### T19 — qa-mobile : **session 14A** → Kevin
- Vraie route depuis la Route 24 (ou départ `route_25`) : D1, D2 inévitables, D3–D6, Abra,
  objets, O4 ; maison : accueil, quatre gestes, aides, lueurs, sortie et retour à chaque étape,
  flash, Léo, Passe Bateau, Super Bonbon, Grand moment, objectifs ; Super Bonbon (si T18b) ;
  fps, mémoire.

#### T20a — architecte : grille d'Azuria du J14 — **maintenant**
- §1.3 : rangées modifiées et bloc `POSITIONS` « J14 » dans `tools/plans/azuria.txt` (sur
  `jalon-14`) ; `tools/art/plan_check_azuria_j14.py`. **CA** : contrôle conforme.
- **Fait (2026-10-12, commit `923269f`, branche `j14-t20a`)** : variante `J14` en fin d'`azuria.txt` (base du J13
  intacte, son contrôle et son plan inchangés) ; lecteurs Python et GDScript étendus
  (`lire(..., "J14")`, `PlanGrid.load_file(..., "J14")`, 3 tests dans `test_plan_grid`) ;
  `plan_check_azuria_j14.py` conforme (24 critères, 6 mutations détectées) ; plan annoté
  `build/art/PLAN_AZURIA_J14_v1_annote.png` relu. Défaut : drapeau `cerulean_south_guard_left`
  (§2.12). Pour T20b : `build_cerulean_city.gd` lit la grille avec la variante `J14`.

#### T20b — constructeur-monde : Azuria du J14 (14C) — après fusion de **J13 T7 et T17** (+ **J12 T12**)
- §2.12 ; régénération d'Azuria par `build_cerulean_city.gd` ; intérieur
  `cerulean_burgled_house` ; départs `cerulean_garden`, `cerulean_rocket_weak`, `cerulean_after`.

#### T21 — architecte : équilibrage — après T16, T20b
- `simulate_mt_moon.gd` + scénario `tools/sim/route_25_scenario.json` (D1, D2, Rocket, combats
  sauvages tirés dans la vraie table) ; **information pour Kevin**, aucune donnée changée sans lui.

#### T22 — qa-mobile : **session 14C** → Kevin
- Poursuite, impasse, défaite → reprise, victoire, CT28, maison, victime, barrage, raccord
  « ROUTE 5 — À venir », ordre libre avec Léo, reprise après fermeture à chaque étape.

#### T23 — architecte : alignements — à chaque fusion de `jalon-13` dans `jalon-14`
- Kadabra + Entrave, D5, D6, Rocket (J12 T12) ; O4 `unless_flags` (J12 T17) ; moment (J12 T23) ;
  table de rencontres (J13 T11) ; compte des espèces dans les tests ; écarts notés au §0.4 (à
  créer).

#### T24 — constructeur-monde puis qa-mobile : fin du J14
- Retrait de `qa_charge_j14` et de son départ ; README. QA finale (**vraie partie de Kevin**) :
  Azuria → Route 24 → Route 25 → Léo → retour → Rocket → sud. **CA** : rapport ; validation de
  Kevin ; fusion de `jalon-14` dans `main` **après le J13** (copie d'intégration ;
  `project.godot` et filtre d'export vérifiés).

#### T25 — architecte : clôture
- `etat-projet.md`, proposition roadmap (rival, Léo, S.S. Anne : avec l'accord de Kevin) ;
  passation J15 (`route_5`, `from_cerulean`, colonnes 31..33, Passe Bateau sans UTILISER) ; dos
  peints d'Abra, Kadabra, Machoc ; son « machine ».

---

## 4. Critères d'acceptation par sous-jalon

**14.0** — planches de la série 16 validées par Kevin ; données chargées sans erreur (3 espèces,
7 capacités, 4 objets, 3 fiches de Pokédex, CT régénérées) ; Nils à Bourg Palette ; étape
`flash` relue sur capture (et réduite) ; tests verts, import propre.

**14A** — raccord Route 24 ↔ 25 sur les trois rangées (ou « À venir » si J13 T8 manque) ; **D1 et
D2 impossibles à contourner**, D3–D6 évitables ; récompenses du §2.11 ; Abra vu sur la Route 25 ;
O1 CT19, O2, O3 ; O4 trouvé face au coquillage ; panneaux ; maison : accueil « ! » et n° 1 ;
quatre gestes dans l'ordre, aides hors de l'ordre, **lueur sur l'objet attendu seulement** ;
sortie et retour à chaque étape sans rien perdre ; flash ×2 (doux avec la réduction) ; Léo
humain ; Passe Bateau (objets clés, sans UTILISER) ; Super Bonbon dans AVENTURE ; **Grand moment
unique** ; objectifs n° 66 → 67 → 68 ; compagnon rentré chez Léo (si 11D) ; traversée ≈ 5 min ;
≥ 58 fps moyens, creux ≥ 50 ; nœuds ≤ 3 000. Super Bonbon (si T18b) : +1 niveau, capacité,
oubli, évolution annulable, « Sans effet » au Nv. 100, pas en combat.

**14B** (seul) — Tunnel : creuse, sprite caché, toute attaque adverse esquivée, frappe au tour 2
sans PP, PP une fois ; interruptions des deux tours ; Vol non affecté ; poison sous terre ;
changement, Sac et fuite impossibles pendant le tour verrouillé ; Ball « Impossible de viser ! »
(test seulement) ;
Téléport : Abra fuit au premier tour, sans XP ; capturable d'entrée ou endormi ; le joueur fuit ;
« Mais rien ne se passe ! » contre un Dresseur ; Patience, statuts, Pierre inchangés ; ≥ 55 fps en
combat.

**14C** — poursuite une seule fois, sans chronomètre ; le Rocket attend au fond de l'impasse,
même après rechargement ; vue sur toute la largeur ; défaite → Centre → n° 32 ; victoire → CT28
une fois, départ par le trou, maison ouverte (victime n° 36, puis 37), policier de la maison
parti ; barrage : n° 40 avant, n° 41 et départ après, absent ensuite ; « ROUTE 5 — À venir » ;
habitants n° 38–39 ; ordre libre avec Léo ; aucune case du jardin bloquée ; **vraie partie de
Kevin** sans régression J1–J13 ; sauvegarde relue par l'APK final (v6) ; carte de QA retirée.

---

## 5. Risques

| Risque | Effet | Parade |
|---|---|---|
| **Conflits dans le moteur de combat** (J12 T13, J13 T12 après lui) | fusions coûteuses | fin d'enum, `charge_rules.gd` à part, 5 points d'accroche ; le J14 fusionne en dernier et absorbe ; tests de non-régression des trois jalons |
| **J12 tarde** (T12, T17, T20, T23, T24 attendent la clôture du J11) | Super Bonbon, D5, D6, Rocket, O4, moment en attente | replis du §0.3 ; Super Bonbon validé à 14C au besoin ; 14A sans lui |
| **J13 tarde** (T7, T8, T17) | 14C attend | 14C en dernier ; T20a prépare la grille dès maintenant |
| **Le J13 modifie encore la grille d'Azuria** | conflit sur `azuria.txt` | relais §0.2 n° 2 ; grille J13 validée (peu probable) |
| **Mélofée intégrée deux fois** (J12 et J14) | doublon de look | vérifier `catalogue.json` avant T13 ; noter dans `etat-projet.md` |
| **Joueur coincé dans l'impasse** | partie bloquée | aucune case ne change après la victoire (contrôle et test) |
| **Fermeture pendant la scène de la machine** | objets doublés ou perdus | drapeaux en dernière étape, aucune autosave en scène ; test |
| **Mer animée sur la Route 25** | fps | eau du shader existant, sans nœud ; mesure dès T14 |
| **Codex refuse le Sbire ou Léo** | délai | repli app ChatGPT ; Sbire déjà fait (J12) |
| **Abra frustrant** (fuit avant toute action) | ressenti | règle verrouillée (RB) ; QA 14B mesure ; information pour Kevin |
| **Machoc à une capacité** (table RB) | Gaston et le Rocket faibles | simulation T21 ; clé `moves` d'une ligne si Kevin le veut |

---

## 6. Valeurs par défaut (règle 4)

| Sujet | Défaut |
|---|---|
| Branches | `jalon-14` depuis `jalon-13`, refusionnée à chaque avancée ; jamais dans `main` avant le J13 |
| Validations | 14.0 sur captures Mac et planche ; 14A, 14B (seul, peut précéder 14A), 14C sur téléphone |
| Identifiants | `route_25`, `bill_house`, `cerulean_burgled_house` ; spawns `_n/_c/_s`, `_w/_e`, `from_route_5_w/c/e` ; PNJ `bill_clefairy`, `bill`, `cerulean_rocket`, `cerulean_police_tape` |
| Noms | D1 **Gamin Jules**, D3 **Fillette Zoé** (Malo et Clara déjà pris au J13) ; Jeune Dresseur = modèle `camper` |
| Machoc | table RB (Poing Karaté seul aux Nv. 15 et 17) |
| Fichiers de données | `species/kanto_j14.json`, `moves/moves_j14.json`, `items/items_j14.json` |
| Charge | état sur le Battler, verrou de Patience ; toute action empêchée au tour 2 = remonte ; IA `smart` × 0,5 |
| Ball sous terre | Ball perdue (retirée au choix), « Impossible de viser ! » |
| Téléport | piégé → échoue ; `FOE_FLED` ; joueur → `FLED` ; « téléportée » au féminin |
| Super Bonbon | AVENTURE, prix 0 ; K.O. refusé ; évolution annulable ; overlay du J11 généralisé |
| Flash | 0,4 s, 0,2 s d'écart, #e6f0ff alpha 0,9, vibration légère ; réduit (l'un des deux réglages) : alpha 0,35 en 0,6 s ; son = point d'accroche |
| Lueur | `LightGlow` type `hint` (rayon 1,3, alpha 0,22, vacillement 0,12) sous `FlagGate` |
| Accueil | déclencheur au premier pas (7..8, 9) ↑ ; rejoué tant que `bill_met` n'est pas levé |
| Locuteur | « Mélofée » aux n° 1–2, « Léo » ensuite |
| Machine | flash ×2, Léo disparaît puis apparaît ; états des cabines reportés DA |
| Console après Léo | texte A-8 (annexe A) |
| Rocket | fouille (13, 2) ↑ ; arrêt (21, 3) ← ; poursuite en courant ; combat par bande (17, 2..3) ; `lost_cerulean_rocket` |
| Azuria | jardin ouvert par (6, 2..3), impasse 7 × 2, trou praticable, planche clouée décorative ; barrage : policier (31, 38), barrières (32..33, 38), bande (31..33, 37) |
| Habitants après | H1 pêcheur n° 38, H3 voisine n° 39 |
| Rencontres | Mystherbe 18, Chétiflor 17 ; repli Roucool 38, Chenipan 27 |
| Objectifs | initiale en minuscule (convention « Objectif : ») |
| Zones | `route_25` (route) et `cerulean_cape` « Cap d'Azuria » (`bill_house`) |
| Nils | apparence `leo` gardée |
| Décor de combat | aucun (repli flou) ; prompt conditionnel prêt |
| Budgets | ≤ 3 000 nœuds ; ≥ 58 fps moyens, creux ≥ 50 ; ≥ 55 en combat et pendant le flash |
| Sauvegarde | v6, aucune nouvelle |

---

## 7. Questions pour Kevin

**Aucune question de game design** : le dossier 17 tranche tout ; les petites valeurs ont un
défaut (§6), notées pour relecture.

**À valider (pas une question)** : le **lot de textes de l'annexe A** (descriptions de
capacités, zones, console après Léo, accord féminin de Téléport), en une passe, comme aux J9–J13.
Il bloque des données, pas le code.

**Pour information** (défauts qui touchent un texte ou un équilibre, réversibles d'une ligne) :
D1 et D3 renommés Jules et Zoé ; Machoc selon la table RB ; Super Bonbon refusé sur un K.O. ;
objectif n° 68 en minuscule ; `dossier-11-route-2.md` cite encore « Scout Léo ».

---

## 8. Premières tâches à lancer maintenant

1. Créer **`jalon-14` depuis `jalon-13`** dans une copie dédiée.
2. **T1** (kit série 16) → **T2** (Codex, Mac) → planche de contact pour Kevin.
3. En parallèle : **T4** (Nils), **T5** (données), **T6** (briques), **T12** (`flash`),
   **T18a** (`RareCandy`), **T20a** (grille d'Azuria) ; Kevin relit l'annexe A (**T3**).
4. **T7** (moteur « charge puis frappe ») → **T8** (Téléport) → **T9** ∥ **T10** → **T11**
   (session 14B, seule).
5. Après T2 : **T13** → **T14** → **T16** ∥ **T17** → **T19** (session 14A).
6. Aux fusions : J13 T8 → T15 ; J12 T20/T23/T24 → T18b ; J13 T7 + T17 (+ J12 T12) → T20b → T22.

---

## Annexe A — Textes À VALIDER par Kevin (non couverts par le §15)

Conventions des lots précédents : phrases courtes ; « Sans effet dans le moteur actuel. » pour un
effet en attente (convention du J12) ; `{pokemon}`, `{player}`.

### A.1 Capacités (description)

- Téléport : « Le lanceur se téléporte ailleurs. Permet de fuir un Pokémon sauvage. »
- Balayage : « Un coup de pied bas. Peut apeurer la cible. »
- Sacrifice : « Une charge violente qui blesse aussi le lanceur. Sans effet dans le moteur
  actuel. »
- Soin : « Le lanceur récupère la moitié de ses PV. Sans effet dans le moteur actuel. »
- Psyko : « Une puissante onde psychique. Peut baisser la Défense Spéciale de la cible. »
- Protection : « Un mur de lumière qui réduit les dégâts physiques reçus. Sans effet dans le
  moteur actuel. »
- Tunnel : n° 60 (même texte que la CT, précédent de Patience).

### A.2 Zones (Carte, Pokédex)

- Route 25 — sous-titre « Azuria — Cap d'Azuria » ; description « Un chemin côtier qui longe la
  mer vers l'est, entre falaises et criques. Tout au bout, une maison isolée sur la pointe. »
- Cap d'Azuria — sous-titre « Route 25 » ; description « La pointe la plus avancée de la côte.
  Un chercheur un peu à part y vit seul, entouré de ses machines. »

### A.3 Maison de Léo

- A-8 *(console, après le retour de Léo)* : « Léo a débranché la console. Le grand bouton ne
  répond plus. »

### A.4 Combat

- n° 56 au féminin : « {pokemon} s'est téléportée ! »

### A.5 Grand moment (présentation du n° 69)

- Titre « Léo a retrouvé forme humaine » · détail vide · lieu « Cap d'Azuria » (nom de la zone,
  comme pour le badge) — la ligne se lit « Cap d'Azuria : Léo a retrouvé forme humaine. ».
