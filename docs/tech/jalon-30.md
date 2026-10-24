# Jalon 30 — La Ligue Pokémon (Conseil des Quatre, rival Champion, Panthéon, générique)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j30-v1-chatgpt.md` (7 arbitrages verrouillés par Kevin le 2026-10-19 ; ne pas
> les rouvrir). Plan écrit le 2026-10-21 (branche `plans-j26-j30`), en conception seulement.

> Objectif jouable sur le téléphone : **le sommet.** Depuis le Plateau Indigo, le joueur ouvre
> volontairement la porte de la Ligue. Il affronte **Olga**, **Aldo**, **Agatha** et **Peter**, salle
> après salle, sans retour en arrière ni Centre Pokémon : seuls les objets du Sac le soignent. Puis
> le **rival**, devenu **Champion**, avec six Pokémon choisis selon le starter. Victoire : le
> professeur Chen arrive, l'équipe entre au **Panthéon**, le **générique** défile, et la partie
> reprend à Bourg Palette. Défaite : retour au Centre du Plateau, tout est à refaire depuis Olga.
>
> **Mécaniques nouvelles** (propres au J30, pas à la passe systèmes 2) :
> - la **tentative de Ligue** : une machine à états de cinq combats, temporaire, séparée des faits
>   permanents ;
> - le **Panthéon** : un instantané immuable de l'équipe à chaque victoire ;
> - le **générique** et le passage à l'état **post-Ligue**.
>
> **Format de sauvegarde : v7, un champ facultatif nouveau** (`hall_of_fame`, lu avec une valeur par
> défaut, §2.6). À faire valider **seul** (règle 1 de `CLAUDE.md` : la sauvegarde est un système
> risqué).

## 0. État et dépendances

### 0.1 Contrat d'entrée, relu sur le code (2026-10-21)

| Besoin | Où, état réel | Ce que fait le J30 |
|---|---|---|
| Plateau Indigo, hall, Centre, porte nord « À venir » | **J29** (plan `jalon-29.md` §0.2) | Branche la porte sur la première salle |
| Point de repos du Plateau | J29 (`indigo_plateau_lobby`) ; `main` : `RestPointLibrary.wakeup_point` (dernier Centre), `DefeatRecovery` (réveil soigné, écriture immédiate) | À l'entrée dans la Ligue, le Plateau devient le point de repos [D] |
| Sauvegarde à la mise en arrière-plan, reprise juste avant un combat | `systemes-2` (S2A, **validé**) | Rien à coder ; tests propres à la Ligue |
| Vol / Téléport / Tunnel / Corde Sortie | `systemes-2` : `MapTraits.no_fly`, `no_teleport` ; Tunnel et Corde seulement en grotte | Les six cartes de la Ligue sont `no_fly` et `no_teleport` |
| Ultralaser (recharge) | `main` (J19, T2) | Rien |
| Soin, Protection, Mur Lumière, Buée Noire, deux tours | `systemes-2` (S2G, validé) | Rien |
| Effets encore en attente : Frénésie (`rage`), Mania / Danse Fleur, Mimique, Métronome | non codés (Q-7 de la passe : laissés) | Audit T3 : chaque capacité RB des équipes qui en a un est **remplacée explicitement** (Q30-3) |
| Rival par starter (`starter_species`) | `main` : `GameState.starter_species`, `rival.json` | Nouvelle entrée `rival_champion` |
| Grands moments | `main` : `GameState.moments` (`rival_battle`, Champions) | Victoire de la Ligue = un Grand moment (type `champion` [D]) |
| Écran titre, « Continuer » | `main` (OUV) | Rien ; la partie post-Ligue se charge comme une autre |
| Espèces | sur `main` : Onix, Nosferalto, Spectrum, Arbok, Léviator, Roucarnage, Arcanin, Dracaufeu, Tortank, Florizarre ; J24 : Crustabri, Flagadoss, Lamantine ; J25 : Ptéra ; J26 : Lokhlass, Alakazam ; J27 : Kicklee, Tygnon ; J28 : Rhinoféros | **À créer** si absentes à l'ouverture : Lippoutou, Mackogneur, Ectoplasma, Draco, Dracolosse, Noadkoko (et toute espèce encore manquante) |

### 0.2 Contrat de sortie (post-game, J31)

| Donnée | Règle |
|---|---|
| `league_champion_defeated` | Fait permanent : titre de Champion, post-game ouvert. **Un seul drapeau** pour `league_first_clear_completed` et `postgame_unlocked` de la passe [D] |
| `GameState.hall_of_fame` | Historique ; jamais effacé |
| Ligue rejouable | Une nouvelle tentative est toujours possible après le titre (RB) |

### 0.3 Ce qui peut commencer maintenant, ce qui attend

**Maintenant** (branche `jalon-30`, fichiers nouveaux seulement) :
- grilles des six salles (T2), données des équipes (T3), textes (T4) ;
- **logique pure et tests** : `LeagueAttempt` (machine à états) et `HallOfFame` (instantané,
  sérialisation), sans toucher `GameState` ni `Boot` (T5, T6).

**Après la fusion de la passe systèmes 2** : branchement dans `GameState` (champ `hall_of_fame`),
`Boot` (directeur de la Ligue) — T7, T8.

**Après la fusion du J29** : cartes, porte du Plateau, combats (T9 et suivantes). Le J30 est le
**dernier** de la série : il se fusionne après le J29.

### 0.4 Écarts relevés

- La passe propose sept identifiants. Le dépôt n'a pas de drapeau à valeur (`StoryFlags`) ; on
  les remplace par des drapeaux simples et un champ de sauvegarde (§2.5, §2.6). Même sens.
- La passe demande une « reprise sécurisée dans la salle courante ou au dernier point valide ». Le
  plan retient **la salle courante** (comme RB : on peut sauvegarder dans la Ligue et reprendre où
  l'on était) ; un arrêt pendant un combat ramène juste avant ce combat (S2A).

## 1. Découpage

| Sous-jalon | Lots de la passe | Tâches | Validation |
|---|---|---|---|
| **30.0** | 30.0 | T0 à T6 | Kevin sur planches : salles, équipes, textes |
| **30A — Tentative et sauvegarde** | 30A, une part de 30F | T7 à T10 | **téléphone, seule** (système de sauvegarde nouveau, règle 1) |
| **30B — Le Conseil et le Champion** | 30B, 30C, 30D | T11 à T14 | téléphone |
| **30C — Panthéon et générique** | 30E | T15 à T18 | téléphone, puis QA finale et clôture |

Fichiers chauds : `game/autoload/game_state.gd` (un champ), `game/boot.gd` (un directeur, un bloc
`_setup_league()`), `game/systems/save/*` (lecture du champ), `game/ui/` (deux écrans nouveaux).

## 2. Conception technique

### 2.1 Cartes (`tools/plans/`)

| Grille | Carte | Contenu |
|---|---|---|
| `ligue_olga.txt` | `league_lorelei` | Entrée sud (depuis le hall), Olga, porte nord |
| `ligue_aldo.txt` | `league_bruno` | idem |
| `ligue_agatha.txt` | `league_agatha` | idem |
| `ligue_peter.txt` | `league_lance` | couloir RB, Peter, porte nord |
| `ligue_champion.txt` | `league_champion` | rival, place de Chen, porte nord |
| `pantheon.txt` | `hall_of_fame` | salle de la cérémonie |

Plans RB (pokered), salles à 1:1 [D]. Toutes `no_fly`, `no_teleport`. Contrôle `plan_check_j30.py` :
chaîne hall → 5 salles → Panthéon, une seule entrée et une seule sortie par salle.

### 2.2 La tentative : `LeagueAttempt` (pure)

```
# game/systems/league/league_attempt.gd — pur, statique
## Étapes : 0 Olga, 1 Aldo, 2 Agatha, 3 Peter, 4 Champion, 5 terminé (Panthéon).
## Calcule, depuis les drapeaux, l'étape courante, les portes ouvertes et la réaction à un
## événement (entrée, victoire, défaite, Panthéon).
```

| Événement | Effet (drapeaux) |
|---|---|
| Entrée par la porte du hall | `league_attempt_active` posé ; `league_stage_<0..4>_cleared` effacés ; point de repos = Plateau |
| Victoire contre le membre k | `league_stage_<k>_cleared` |
| Défaite (n'importe quelle salle) | réveil au Plateau (soin, mécanisme existant) ; tous les drapeaux de tentative effacés |
| Cérémonie du Panthéon écrite | `league_champion_defeated` ; drapeaux de tentative effacés |

- **Portes** : la porte nord de la salle k est un warp actif `if [league_stage_<k>_cleared]` ; la
  porte sud de chaque salle est **fermée** tant que `league_attempt_active` (pas de retour) ; le
  hall n'a pas de porte de retour depuis la première salle pendant la tentative (RB : la porte se
  referme derrière le joueur).
- **Membres** : combats `heal_after: false`, IA `smart`, `can_lose: false` (défaite = réveil).
  Vaincu ne signifie rien hors de la tentative : chaque tentative remet tout (vigilance A).
- **Aucun soin gratuit** : ni Centre, ni PC, ni soin de fin de combat ; PP, PV et statuts restent
  ceux du combat précédent (comportement normal du moteur entre deux combats).

### 2.3 Sauvegarde pendant la tentative

- Les drapeaux de tentative sont des drapeaux ordinaires : une sauvegarde (Menu, autosave d'entrée de
  salle) les contient. **Recharger reprend dans la salle courante**, avec l'équipe telle qu'elle était.
- Arrêt pendant un combat → point de reprise S2A : **juste avant** ce combat. On ne saute jamais un
  combat : la porte nord exige la victoire.
- Arrêt entre la victoire contre le Champion et l'écriture du Panthéon : le drapeau
  `league_stage_4_cleared` est écrit avec la fin du combat ; à la reprise dans `league_champion`,
  la scène de Chen et du Panthéon repart (variante `if [league_stage_4_cleared]`). La cérémonie est
  **idempotente** : l'entrée du Panthéon et `league_champion_defeated` sont écrits dans **une seule
  écriture**.
- Sortie forcée de la Ligue (Corde, Vol, Téléport) : impossible (`no_fly`, `no_teleport`, pas de
  grotte).

### 2.4 Panthéon et générique

- **Cérémonie** (scène `league_victory`) : rival vaincu (texte) → Chen arrive (marche) → texte →
  le joueur et Chen passent au Panthéon (warp) → étape nouvelle **`hall_of_fame`** : l'écran du
  Panthéon montre les six Pokémon un par un (nom, surnom, niveau), puis l'instantané est ajouté et
  la partie est **écrite** → générique → arrivée à Bourg Palette.
- **Instantané** (`HallOfFame`, pur) : date (horloge de l'appareil), temps de jeu, nom du joueur,
  starter, et pour chaque Pokémon : espèce, surnom, niveau, `uid`. Immuable : une entrée n'est
  jamais modifiée ni effacée ; chaque victoire en ajoute une.
- **Générique** (`CreditsScreen`, UI) : défilement de textes (données `data/story/credits.json`),
  sur un fond peint existant [D], musique si disponible ; touchable pour accélérer ; **passable**
  seulement si `league_champion_defeated` était déjà posé avant cette victoire [D].
- **Après le générique** : le joueur apparaît devant sa maison à Bourg Palette (`pallet_town`,
  `player_house_door`, comme le Vol) [D] ; Badges, Pokémon, objets, captures et événements
  conservés ; aucune scène imposée ; autosave d'arrivée.
- Le Panthéon est consultable plus tard : **Q30-4** (défaut : une entrée « Panthéon » dans l'écran
  Dresseur du Menu, en lecture seule ; peut attendre le post-game).

### 2.5 Drapeaux

| Drapeau | Rôle | Durée |
|---|---|---|
| `league_attempt_active` | Tentative en cours | temporaire |
| `league_stage_0_cleared` … `league_stage_4_cleared` | Membre k battu dans cette tentative | temporaire |
| `league_champion_defeated` | Titre de Champion, post-game | permanent |
| `league_credits_seen` | Générique déjà vu une fois (rend le suivant passable) | permanent |

### 2.6 Sauvegarde : un champ facultatif

| Ajout | Lecture d'une ancienne sauvegarde |
|---|---|
| `hall_of_fame` : liste d'entrées (§2.4) | liste vide |

Lu par `JsonFields.get_*` avec valeur par défaut, comme les champs de la passe systèmes 2 : **pas de
changement de version** (v7, ou v8 si le J23 l'a introduite entre-temps). Plafond [D] : 50 entrées
(RB), la plus ancienne n'est **pas** effacée au-delà : on n'ajoute plus, et on le dit (Q30-5).

### 2.7 Équipes

| Membre | Équipe (arbitrage verrouillé) |
|---|---|
| Olga | Lamantine 54, Crustabri 53, Flagadoss 54, Lippoutou 56, Lokhlass 56 |
| Aldo | Onix 53, Tygnon 55, Kicklee 55, Onix 56, Mackogneur 58 |
| Agatha | Ectoplasma 56, Nosferalto 56, Spectrum 55, Arbok 58, Ectoplasma 60 |
| Peter | Léviator 58, Draco 56, Draco 56, Ptéra 60, Dracolosse 62 |
| Rival (`rival_champion`) | trois variantes du tableau de la passe §4, clé `starter_species` |

- Capacités RB auditées au T3 ; capacité à effet absent → remplacement explicite listé (Q30-3).
- Pokémon répétés (deux Onix, deux Ectoplasma, deux Draco) : rien à faire (une équipe est une liste).
- Simulation d'équilibrage (outil du J12) sur une équipe type N55–N60.

### 2.8 Départs de débogage

`league_start` (hall, équipe N60, 10 Hyper Potions) · `league_agatha` (tentative en cours, Olga et
Aldo battus, équipe abîmée) · `league_champion` ×3 starters · `league_weak` (défaite assurée) ·
`postgame` (titre obtenu, une entrée au Panthéon).

### 2.9 Art

Avant le code : grilles + une vue générale de la salle du Champion. Lot d'art ensuite : cinq salles
(modules), Panthéon, Olga, Aldo, Agatha, Peter, Chen (existe), rival Champion (tenue), espèces
nouvelles, fonds de combat (un par salle [D] ou un fond « Ligue » commun).

## 3. Textes

La passe ne propose aucun texte : tout ce qui suit est **[D] (défaut, à relire)**. Les répliques de
victoire et de défaite des quatre membres suivent le même modèle (avant / vaincu).

| N° | Locuteur | Texte |
|---|---|---|
| T30-01 [D] | Garde du hall (porte de la Ligue) | « Au-delà de cette porte, pas de retour avant la fin. Tu es prêt ? » OUI / NON |
| T30-02 [D] | Olga (avant) | « Bienvenue à la Ligue Pokémon. Je suis Olga, du Conseil des Quatre. Mes Pokémon de glace vont te figer sur place ! » |
| T30-03 [D] | Olga (vaincue) | « Tu as du talent… Va. Les autres t'attendent. » |
| T30-04 [D] | Aldo (avant) | « Je suis Aldo ! Mes Pokémon et moi nous entraînons sans relâche. Voyons si tu tiens le choc ! » |
| T30-05 [D] | Aldo (vaincu) | « Ma force n'a pas suffi… Continue ! » |
| T30-06 [D] | Agatha (avant) | « Je suis Agatha. Ce vieux Chen ne jure que par toi ? Je vais te montrer ce qu'est un vrai Dresseur. » |
| T30-07 [D] | Agatha (vaincue) | « Hé hé… Tu iras loin, petit. Va voir Peter. » |
| T30-08 [D] | Peter (avant) | « Je suis Peter, maître des Dragons. On dit qu'ils sont invincibles. Prouve le contraire ! » |
| T30-09 [D] | Peter (vaincu) | « Je n'ai plus rien à t'apprendre. Le Champion t'attend. » |
| T30-10 [D] | Rival Champion (avant) | « {player} ! Je suis arrivé ici avant toi. Je suis le Champion maintenant. Tu sais ce que ça veut dire ? Que je suis le meilleur Dresseur du monde ! » |
| T30-11 [D] | Rival (vaincu) | « Non… Pas maintenant… Pas contre toi… » |
| T30-12 [D] | Rival (victoire du rival) | « Tu vois ? Le titre est à moi. » |
| T30-13 [D] | Chen | « {player} ! Félicitations. Tu es le nouveau Champion de la Ligue Pokémon. » |
| T30-14 [D] | Chen (au rival) | « {rival}… Tu as oublié de traiter tes Pokémon avec confiance et amour. C'est pour cela que tu as perdu. » |
| T30-15 [D] | Chen (Panthéon) | « Viens. Ton équipe mérite d'entrer au Panthéon. » |
| T30-16 [D] | Panthéon (écran) | « Bienvenue au Panthéon ! » puis, pour chaque Pokémon : « {pokemon} — N{niveau} » |
| T30-17 [D] | Narration (fin) | « {player} et son équipe entrent dans la légende. » |
| T30-18 [D] | Défaite (réveil) | texte de réveil existant (`nurse_wakeup`) |
| T30-19 [D] | Générique (premier écran) | « KANTO 2026 » |
| T30-20 [D] | Générique (contenu) | rôles et noms à fournir par Kevin (Q30-1) |

## 4. Tâches

### 4.1 Sous-jalon 30.0 — **maintenant**

#### T0 — A : plan (ce document) — fait
#### T1 — A : branche `jalon-30` depuis `origin/main` ; audit (pokered : salles, équipes, capacités ; branches J21 à J29 : espèces)
#### T2 — C : grilles des six salles, `plan_check_j30.py` → K
#### T3 — A : données des cinq équipes, `rival_champion`, liste des remplacements de capacités
#### T4 — A : textes [D] en lot (membres, rival, Chen, générique)
#### T5 — A : `LeagueAttempt` (pure) + `test_league_attempt.gd`
#### T6 — A : `HallOfFame` (pure, sérialisation) + `test_hall_of_fame.gd`

### 4.2 Sous-jalon 30A — **après la fusion de la passe systèmes 2** (et du J29 pour la carte réelle)

#### T7 — A : champ `GameState.hall_of_fame`, lecture avec défaut, test de chargement d'une v7 sans le champ
#### T8 — A : `LeagueDirector` dans `Boot` (entrée, victoires, défaite, portes) ; `no_fly`, `no_teleport`
#### T9 — C : six cartes (géométrie), porte du Plateau branchée, départs de débogage
#### T10 — Q : **session 30A seule** (interruptions dans la Ligue) → K

### 4.3 Sous-jalon 30B

#### T11 — C : Olga et Aldo — après T10
#### T12 — C : Agatha et Peter — après T10
#### T13 — C : rival Champion, trois variantes — après T10
#### T14 — A : simulation d'équilibrage des cinq combats

### 4.4 Sous-jalon 30C

#### T15 — U : écran du Panthéon (étape `hall_of_fame`) — après T6, T7
#### T16 — U : générique (`CreditsScreen`, `credits.json`) — après T15
#### T17 — C : scène `league_victory`, arrivée à Bourg Palette — après T13, T16
#### T18 — Q : **session 30B + 30C** et QA finale (vraie partie si possible) → K ; clôture, passation J31

## 5. Tests

- `test_league_attempt.gd` (pur) : toutes les transitions ; défaite à chaque étape → retour à 0 ;
  victoire → étape suivante ; drapeaux temporaires jamais confondus avec `league_champion_defeated`.
- `test_league_doors.gd` : porte nord fermée tant que le membre n'est pas battu ; porte sud fermée
  pendant la tentative ; `no_fly`, `no_teleport`.
- `test_league_resources.gd` : PV, PP et statuts conservés entre deux salles ; objet de soin consommé
  une fois ; aucun soin automatique.
- `test_league_defeat.gd` : défaite contre Agatha → réveil au Plateau, équipe soignée, rien de perdu
  (Badges, objets importants, Pokémon) ; nouvelle tentative depuis Olga.
- `test_league_save.gd` : sauvegarde dans la salle 3, rechargement → salle 3, même équipe ; arrêt
  pendant le combat → avant le combat ; arrêt entre la victoire finale et le Panthéon → cérémonie
  rejouée, une seule entrée.
- `test_rival_champion.gd` : trois variantes par `starter_species`, jamais par l'équipe.
- `test_hall_of_fame.gd` : instantané immuable ; deuxième victoire → deuxième entrée ; v7 sans le
  champ → liste vide ; écriture et relecture identiques.
- `test_postgame.gd` : après le générique, Bourg Palette, tout est conservé ; la Ligue se rejoue.

## 6. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. Cinq combats, dans l'ordre, sans retour, sans soin gratuit ; défaite → Plateau, reprise depuis Olga.
3. Aucun redémarrage ne permet de sauter un combat ni de dupliquer un objet ou une entrée du Panthéon.
4. Panthéon : une entrée immuable par victoire ; générique ; reprise libre à Bourg Palette.
5. Une sauvegarde v7 sans `hall_of_fame` se charge sans perte.
6. Les sessions 30A (seule), 30B et 30C sont validées par K.

## 7. QA téléphone

| Session | Scénario |
|---|---|
| **30A** (seule) | `league_agatha` : (1) verrouillage pendant le combat d'Agatha, relance ; (2) Menu → sauvegarder, tuer l'appli, relancer ; (3) rideau 3 s ; (4) arrêt forcé pendant une transition de salle. À chaque fois : salle, équipe, PP, drapeaux identiques ; aucune porte franchissable sans victoire |
| **30B** | `league_start` jusqu'à Peter ; `league_champion` ×3 ; `league_weak` → défaite, Plateau, reprise depuis Olga |
| **30C** | victoire → Chen, Panthéon (six Pokémon lisibles), générique, Bourg Palette ; deuxième victoire → deuxième entrée, générique passable ; 60 fps sur l'écran du Panthéon |

## 8. Valeurs par défaut [D]

- Reprise dans la salle courante (RB) ; arrêt en combat → juste avant le combat.
- Un seul drapeau permanent `league_champion_defeated` ; `league_credits_seen` pour passer le générique.
- Point de repos forcé au Plateau à l'entrée dans la Ligue.
- Arrivée post-Ligue devant la maison du joueur.
- 50 entrées au Panthéon au plus.
- Confirmation OUI / NON à la porte de la Ligue (T30-01).
- Textes T30-01 à T30-19.

## 9. Points ouverts pour Kevin

- **Q30-1 — Générique** : quels noms et quels rôles ? (toi, outils, mentions « fan-made, non
  officiel » ?) Défaut : « Kanto 2026 — un remake personnel de Kevin », puis l'équipe Pokémon du
  joueur, puis « Merci d'avoir joué ».
- **Q30-2 — Textes** : propositions [D]. Couverts par ta validation d'avance, ou à relire ?
- **Q30-3 — Capacités sans effet** : Frénésie (Onix d'Aldo), Mania, Mimique… restent non codées
  (Q-7 de la passe systèmes 2). Défaut : remplacées par la capacité RB suivante de la liste
  d'apprentissage, listées au T3. Ou faut-il les coder (petit lot d'effets) ?
- **Q30-4 — Consulter le Panthéon** : depuis le Menu (écran Dresseur), ou seulement au PC du
  Plateau (RB : PC → « Panthéon ») ? Peut attendre le post-game.
- **Q30-5 — Au-delà de 50 victoires** : arrêter d'ajouter (défaut) ou effacer la plus ancienne ?
- **Q30-6 — Confirmation à la porte** : la passe dit « entrée volontaire » ; RB n'a pas de question.
  Défaut : une question OUI / NON (T30-01), pour ne pas entrer par erreur au doigt.

## 10. Avancement — nuit du 2026-10-21 au 2026-10-22 (branche `jalon-30`, worktree `~/dev/kanto-2026-wt-j30`)

Base : `origin/systemes-2` @ `8c2cb6ee` (passe systèmes 2 comprise) + `origin/plans-j26-j30` (docs).
Textes et prénoms : propositions du plan, **validés par Kevin le 2026-10-21, validation d'avance
(proposition du plan)**.

**Décisions de Kevin du 2026-10-22** (relayées par la coordination, appliquées ici) :
- **Q30-1** générique : défaut du plan (« Kanto 2026 — un remake personnel de Kevin », l'équipe du
  joueur, « Merci d'avoir joué ») — à coder au T16 ;
- **Q30-2** textes du plan : validés ;
- **Q30-3** capacités de la Ligue sans effet : **les coder** (pas de remplacement) — Frénésie,
  Mania / Danse Fleur, Mimique codées ici (§10.6) ; Riposte, Pied Sauté, Pied Voltige **codés par
  le J27** (commit `865c97e7`, consigne de la coordination : pas de double codage) ;
- **Q30-4** Panthéon consultable depuis le **Menu Dresseur** (écran Dresseur, lecture seule) — T15 ;
- **Q30-5** au-delà de 50 entrées : **arrêter d'ajouter** — fait (`HallOfFame.add` → `FULL`) ;
- **Q30-6** question OUI / NON à la porte de la Ligue : **oui** (T30-01, `league_guard_door`) ;
- **ordre des validations de sauvegarde** : le J23 (v8) d'abord, puis le J30 (`hall_of_fame`)
  **séparément**.
- **défauts de la Ligue (§8) gardés** (décision de Kevin du 2026-10-22, le code les applique déjà) :
  Frénésie selon la règle de 2e génération ; déclencheur à l'entrée de chaque salle ; Agatha et le
  rival changent de Pokémon ; pas d'objets pour l'IA.

### 10.1 Fait

| Tâche | Livré |
|---|---|
| **T2** grilles | `tools/plans/ligue_olga.txt`, `ligue_aldo.txt`, `ligue_agatha.txt`, `ligue_peter.txt`, `ligue_champion.txt`, `pantheon.txt`, écrites par `tools/art/j30_rb_decode.py <pokered> --ecrire` (RB 1:1) ; contrôle `tools/art/plan_check_j30.py` (+ `--autotest`, 6 pièges) ; `tests/unit/test_league_plans.gd` |
| **T3** données | `data/trainers/league.json` (Olga, Aldo, Agatha, Peter, `rival_champion` × 3 starters), vérifié contre pokered ; `tests/unit/test_league_data.gd` |
| **T4** textes | `data/league/dialogues.json` (T30-01 à T30-17) ; `tests/unit/test_league_texts.gd` |
| **T5** `LeagueAttempt` | `game/systems/league/league_attempt.gd` (pur, statique) ; `tests/unit/test_league_attempt.gd` |
| **T6** `HallOfFame` | `game/systems/league/hall_of_fame.gd` (pur) ; `tests/unit/test_hall_of_fame.gd` |
| **T7** (30A) champ de sauvegarde | `GameState.hall_of_fame`, champ facultatif `hall_of_fame` de la **v7** ; `tests/unit/test_save_v7_hall_of_fame.gd` |

### 10.2 Valeurs et choix [D]

- **Équipes** : pokered `parties.asm` (espèces, niveaux, ordre = la passe) ; capacités = celles
  de RB au niveau (capacités de départ + apprentissage, la plus ancienne sort quand il y en a
  quatre) ; **capacité d'équipe RB** (`special_moves.asm` : 3e capacité du 5e Pokémon) : Blizzard
  (Lokhlass d'Olga), Abîme (Mackogneur d'Aldo), Toxik (Ectoplasma N60 d'Agatha), Bouclier
  (Dracolosse de Peter) ; rival (`read_trainer_party.asm`) : Piqué au Roucarnage, Déflagration /
  Blizzard / Méga-Sangsue au starter.
- **Q30-3** (décision de Kevin : coder) : les équipes gardent **toutes** leurs capacités RB
  (Mania de Lippoutou, Frénésie des Onix et du Dracaufeu du rival, Riposte de Tygnon, Pied Sauté
  et Pied Voltige de Kicklee, Mimique du Roucarnage du rival) ; effets codés ici (§10.6), sauf
  Riposte, Pied Sauté et Pied Voltige : **effets livrés par le J27** (ici encore « à faire »).
  **Toxik** (Ectoplasma N60 d'Agatha) : poison grave **déjà codé par le J23** (fusionné avant le
  J30) ; ici, simple poison en attendant (`j30_reprises.json`, `pending_effects: ["toxic"]`).
- **Argent** : 99 par niveau du dernier Pokémon (pokered `pic_money … 9900`).
- **IA** : `smart` ; changement de Pokémon pour **Agatha** (pokered `AgathaAI`) et le **rival
  Champion** (comme les rivaux) ; les objets de l'IA RB (Super Potion d'Olga, Défense Spé. d'Aldo,
  Hyper Potion de Peter, Guérison totale du rival) ne sont pas joués (l'IA du projet n'en a pas).
- **Cartes de présentation** : « OLGA », « ALDO », « AGATHA », « PETER », titre « Conseil des
  Quatre » ; le rival n'en a pas (comme ses autres combats).
- **Grilles** : portes `X` ; porte nord `si=league_stage_<k>_cleared`, porte sud
  `unless=league_attempt_active` ; déclencheur d'appel `appel_<membre>` (RB : `EntranceCoords`,
  marche forcée) au-dessus de l'entrée (couloir chez Peter, rangée 5 chez le Champion) ; vue 4 ;
  le membre reste en place une fois battu ; tuile RB `$30` (passage fermé par script) = sol ;
  pourtour et îlots inaccessibles → mur ; entrée de Peter sur (23, 16), porte sur la case
  d'arrivée RB (24, 16) ; Chen (3, 7) chez le Champion `si=league_stage_4_cleared` ; Panthéon
  **sans porte** (la cérémonie enchaîne).
- **Panthéon** : entrée = { date, play_time, player, starter, team [{ species, nickname, level,
  uid }] } ; 6 Pokémon au plus ; **Q30-5** : au-delà de 50 entrées, `add` rend `FULL` et
  n'efface rien ; une entrée mal formée d'une sauvegarde est écartée (les autres gardées).
- **`LeagueAttempt`** : l'étape courante est la première non gagnée (un drapeau plus loin, fichier
  retouché, ne fait rien sauter) ; `start` pendant une tentative ne remet rien à zéro (reprise) ;
  `complete` n'est vrai qu'une fois (l'appelant n'ajoute l'entrée du Panthéon que sur vrai, dans
  la même écriture).
- **Textes** rangés dans `data/league/` (pas `data/dialogues/`) : `test_dialogue_data` exige que
  chaque dialogue de `data/dialogues/` soit utilisé ; le fichier y passera avec les cartes (T9).

### 10.3 Espèces et capacités : dépendances des autres branches (à régler à la fusion)

Convention des « reprises » (J29) : copies exactes des entrées d'une autre branche, **à retirer**
du J30 quand cette branche est fusionnée avant lui (sinon « identifiant déjà défini »).

| Fichier | Contenu | Origine |
|---|---|---|
| `data/pokemon/species/kanto_j30.json` | Lippoutou, Mackogneur, Ectoplasma, Draco (→ Dracolosse N55), Dracolosse | nouvelles (J30) |
| `data/pokemon/species/kanto_j30_reprises.json` | Lamantine, Crustabri, Flagadoss (J24) ; Lokhlass, Alakazam (J26, `kanto_silph.json`) ; Ptéra (J25) ; Rhinoféros (J28) ; Noadkoko (J29) ; Kicklee, Tygnon (J27, `kanto_saffron.json`) | copies exactes |
| `data/pokemon/moves/j30.json` | Grobisou (nouvelle) | nouvelle |
| `data/pokemon/moves/j30_emprunts.json` | **J27** (`saffron.json`) : Riposte, Pied Sauté, Pied Voltige (`hi_jump_kick`, Riposte priorité −1), copiés à l'identique de `865c97e7^` (version « à faire », `pending_effects`, car ce moteur n'a pas les sortes `crash` / `counter`) ; Poing-Glace, Poing-Éclair, Mawashi Geri (identiques à `origin/jalon-27`). **À la fusion : supprimer ce fichier, la version du J27 (effets livrés) fait foi** | emprunts |
| `data/pokemon/moves/j30_reprises.json` | Blizzard, Picanon (J24) ; Déflagration, Poing de Feu (J25) ; Abîme (J28) ; Ultimawashi, Piqué (J29) ; **Toxik** (J23, **simplifié** : sans `toxic: true`, `pending_effects: ["toxic"]`, la base ne connaît pas la clé) | copies (Amnésie et Bouclier retirées : celles du J21 fusionné font foi, `j21.json`) |

Statistiques des espèces nouvelles : valeurs modernes (comme le dépôt), `base_exp` de PokeAPI
(`build/rb/pokeapi/pokemon.csv`) ; apprentissages RB complets. Pas de fiche de Pokédex pour les
15 espèces (`NO_ENTRY_YET`, textes à écrire) ; pas de compatibilité de CT.
Tests de décompte mis à jour (conflits attendus à la fusion, à résoudre en additionnant) :
`test_pokemon_data` (104 espèces, 147 capacités, taux de capture, Draco), `test_mt_moon_data`,
`test_pokedex_library`, `test_trainer_card` (Conseil des Quatre), `test_trainer_library`
(changements : Agatha, rival Champion).

### 10.4 Sous-jalon 30A : sauvegarde — **à valider SEUL par Kevin sur téléphone (règle 1)**

- Champ **facultatif** `hall_of_fame` de la **v7**, comme `mount` (S2B) : **aucun changement de
  version**, donc aucun conflit de numéro avec la **v8 du J23** (le champ reste facultatif dans
  la v8). Écrit seulement si le Panthéon n'est pas vide ; absent ou illisible → Panthéon vide.
- Tests : v7 sans le champ (partie réelle du S21) relue et **réécrite à l'identique** ; v6 migrée ;
  dictionnaire « v8 » sans le champ ; aller-retour à l'identique ; entrée mal formée écartée et
  signalée ; nouvelle partie = Panthéon vide.
- La QA téléphone 30A (§7) attend les cartes (T9) et le directeur (T8) ; le champ seul peut être
  validé avant (sauvegarde chargée puis réécrite sans différence).

### 10.6 Capacités codées (Q30-3, décision de Kevin du 2026-10-22)

Vérifié le 2026-10-22 : aucune branche `origin/jalon-21` … `jalon-29` ne codait Frénésie, Mania
ni Mimique (le J24 code Métronome, le J23 Toxik ; le **J27 code Riposte, Pied Sauté et Pied
Voltige**, commit `865c97e7` : non recodés ici). Code nouveau dans `game/battle/battle.gd` (bloc
« Jalon 30 » en fin de fichier), `battler.gd`, `battle_ai.gd`, `move_effect.gd` (sortes `rage`,
`rampage`, `mirror` ajoutées en fin d'enum : à fusionner avec `METRONOME` du J24 et `CRASH`,
`COUNTER` du J27), données `moves.json` (Frénésie, Mania, Danse Fleur, Mimique) ; tests
`tests/unit/test_league_moves.gd`.
Règles [D] :
- **Frénésie** (2e génération) : tant que le lanceur relance Frénésie, chaque coup direct reçu
  monte son Attaque d'un niveau ; lancer autre chose y met fin (RB : bloqué jusqu'à la fin du
  combat, non repris) ;
- **Mania, Danse Fleur** (RB) : 2 ou 3 tours d'affilée imposés, sans PP après le premier, puis
  confusion de fatigue (en fin de tour, 1 à 4 tours) ; interrompue (statut, apeurement,
  confusion, Entrave) : elle s'arrête sans confusion ;
- **Mimique** (RB) : copie la dernière capacité lancée par la cible (MOVE_USED « Mimique » puis
  MOVE_USED de la copie, sans PP) ; échoue si rien à copier, Mimique, Lutte, ou capacité liée à
  un emplacement (charge, Patience, Mania, Ultralaser) ; IA : seulement s'il y a quelque chose à
  copier ;
- **Riposte, Pied Sauté, Pied Voltige** : règles RB du J27 (voir `jalon-27.md`).

### 10.7 Vérification

Import headless sans erreur ; **suite complète 6 539 / 6 539** (598 scripts), journaux dans
`build/logs/` du worktree ; `python3 -I tools/art/plan_check_j30.py` (+ `--autotest`) OK.

### 10.5 Restant

- **Q30-4** : entrée « Panthéon » de l'écran Dresseur du Menu (lecture seule de
  `GameState.hall_of_fame`), avec le T15.
- **À la fusion du J29** (§10.8) ; **T10** QA 30A (téléphone, seule) ;
  **T11–T14** combats et équilibrage ; **T15–T18** Panthéon (écran), générique
  (`data/story/credits.json`, Q30-1), scène `league_victory`, QA finale.

### 10.8 T8 et T9 — 2026-10-23 (branche `jalon-30`, sans fusion du J29)

**T8 — `LeagueDirector`** (`game/systems/league/league_director.gd`, bloc `_setup_league()` en fin
de `game/boot.gd`, modèle `_setup_strength`) : relais de `SceneRouter.map_changed` (branché avant
celui de Boot : drapeaux à jour avant la présence des PNJ) et de `BattleDirector.battle_finished`.
- **Entrée** : arrivée dans `league_lorelei` hors tentative → `LeagueAttempt.start`, `beaten_*` des
  cinq Dresseurs de la Ligue effacés, point de repos = `indigo_plateau_lobby` / `heal` ; toute
  salle pendant la tentative (re)force ce point (départs de débogage).
- **Victoire** contre le membre de l'étape courante → `league_stage_<k>_cleared` (+ `beaten_<id>`
  posé par la scène d'appel) ; PNJ rafraîchis (Chen chez le Champion paraît aussitôt).
- **Défaite** → drapeaux de tentative et `beaten_*` de la Ligue effacés **avant** l'étape
  `wake_up` (réveil soigné, sauvegarde écrite au réveil par Boot).
- **Portes** (aucun code de warp nouveau) : porte sud = warp `unless league_attempt_active` +
  `FlagGate` bloquante `if league_attempt_active` ; porte nord = warp derrière une `FlagGate`
  bloquante `unless league_stage_<k>_cleared` (le relais des drapeaux de Boot ouvre le battant).
- **`no_fly` / `no_teleport`** : deux `@export` nouveaux de `GameMap` (après `battle_arena`, pour
  ne pas toucher la zone modifiée par le J29), lus par `FlyDirector` et `FieldTravelDirector`
  dans leurs `MapTraits`. Les salles sont aussi des intérieurs (Vol et Téléport déjà refusés).
- **Champion** : la victoire pose `league_stage_4_cleared` et **s'arrête là** (pas de titre, pas de
  Panthéon, pas de générique : T15–T17). La porte nord mène au Panthéon (Chen y attend, réplique
  T30-15) **sans sortie** tant que la cérémonie n'existe pas : fin provisoire, connue.

**T9 — cartes** : `tools/build_j30_league.gd` (modèle `tools/build_j29.gd` de `origin/jalon-29`,
tuiles provisoires d'intérieur `InteriorTiles` : sol de labo, murs de labo, tapis sur les portes,
battants dessinés) → `game/world/maps/league_{lorelei,bruno,agatha,lance,champion}.tscn`,
`hall_of_fame.tscn` ; intérieurs, `no_fly`, `no_teleport`, lumière `interior_warm`, nom « Plateau
Indigo » (zone `indigo_plateau`). PNJ : `data/npcs/<salle>.json` (membres en Dresseurs, vue 4, `heal_after:
false` / IA `smart` / défaite = réveil par `league.json`) ; Chen `if league_stage_4_cleared` chez le
Champion, Chen au Panthéon. Scènes d'appel `data/cutscenes/league.json` (`<dresseur>_call`, une
variante `unless league_stage_<k>_cleared`) : marche forcée devant le membre, réplique, carte de
présentation (pas pour le rival), combat (`win: beaten_<id>`), réplique « vaincu », sinon
`rival_champion_won` (rival) puis `wake_up`. Textes : `data/league/dialogues.json` →
`data/dialogues/league.json` ; en attente (`UNUSED_YET` de `test_dialogue_data`) :
`league_guard_door` (hall du J29), `league_oak_to_rival`, `league_hall_welcome`, `league_ending`
(T17).

**Valeurs [D] choisies** :
- sprites provisoires : Olga `cooltrainer_f`, Aldo `docker`, Agatha `channeler`, Peter `traveler`,
  rival `rival`, Chen `oak` ;
- Chen chez le Champion en **(3, 6)** au lieu de (3, 7) (grille et décodeur retouchés) : un PNJ ne
  peut pas tenir sur la case d'un battant fermé ;
- salle d'Olga : point d'arrivée **`from_lobby`** (même case que `from_south`, 4, 10) ; porte sud →
  `indigo_plateau_lobby:league_door` (point du hall du J29 ; `from_league` n'existe pas) ;
- déclencheurs d'appel sur toutes les directions de pas ; la scène d'appel ne lit que le drapeau
  d'étape (`unless league_stage_<k>_cleared`) ;
- départs : **10 Guérisons** à la place des 10 Hyper Potions (absente : elle vient du J22) ;
  starter **de base** N60 en tête (clé du rival, convention du J29) ; point de repos de départ =
  Jadielle (`league_*` : `rest_point: viridian_center`), remplacé par le Plateau dès que le hall
  existe.

**Écarts (J29 non fusionné)** :
- le hall `indigo_plateau_lobby` et son point de repos `heal` n'existent pas ici : le directeur ne
  change alors pas le point de repos (défaite → Jadielle dans les départs) ; les tests attendent
  le Plateau **si** la carte existe, Jadielle sinon (aucune copie de la carte) ;
- la porte sud d'Olga vise une carte absente (`indigo_plateau_lobby`) : sans effet, elle est
  fermée pendant toute tentative et la tentative s'ouvre à l'arrivée ;
- `zones.json` : la zone `indigo_plateau` reçoit les six salles, avec le sous-titre et la
  description **du J29** (copie exacte) : conflit attendu sur ces lignes, à résoudre en
  additionnant les cartes (`indigo_plateau`, `indigo_plateau_lobby` + les six salles) et les
  services du J29. `interiors.json`, `lighting.json` : ajouts en fin de liste (conflits additifs).

**À faire à la fusion du J29** :
1. `tools/build_painted_interiors.gd`, `_indigo_plateau_lobby()` : warp `ToLeague` (12, 3), cible
   vide aujourd'hui → `target_map = league_lorelei`, `target_spawn = from_lobby` (orientation
   ↑) ; reconstruire le hall ;
2. question **T30-01** (`league_guard_door`, OUI / NON, Q30-6) devant la porte : garde du hall (ou
   déclencheur) dont le OUI ouvre le passage (le NON garde le joueur dans le hall) ; retirer
   `league_guard_door` de `UNUSED_YET` et la porte « À venir » du J29 (`indigo_league_door`) ;
3. vérifier `league_door` du hall (arrivée par la porte sud d'Olga hors tentative) et le point
   `heal` (réveil) ; les tests `test_league_defeat` / `test_league_doors` passent alors sur le
   Plateau sans changement ;
4. retirer « Jadielle » des départs `league_*` si l'on veut (`rest_point: indigo_plateau_lobby`).

**Départs de débogage** : `league_lorelei`, `league_agatha`, `league_champion_{bulbasaur,
charmander,squirtle}`, `league_weak` (`tools/debug_start/README.md`).

**Tests** : `tests/unit/test_league_director.gd` (8), `tests/unit/test_rival_champion.gd` (3),
`tests/integration/test_league_doors.gd` (4 : scènes, battants contre `LeagueAttempt` à chaque
étape, vraie partie : porte refermée, Vol refusé, victoire contre Olga → salle d'Aldo),
`test_league_defeat.gd` (2), `test_league_save.gd` (3 : reprise dans la salle d'Agatha, arrêt
pendant le combat → entrée de la salle, appel rejoué ; arrêt après le Champion → Chen, pas de
titre), `test_league_resources.gd` (4). `test_dialogue_data`, `test_cutscene_data`,
`test_league_texts`, `test_rival_name_layers` mis à jour (listes du J30). **Vérification** : import
headless sans erreur ; suite complète **6 739 / 6 739** (627 scripts, 362 126 assertions),
`build/logs/j30_t8t9_suite2.log` ; `plan_check_j30.py` (+ `--autotest`) OK. Captures (Mac) :
`build/captures/jalon30_ligue/` (`tools/capture_j30_league.gd`).
- Planche des grilles pour Kevin (sous-jalon 30.0) ; fiches de Pokédex des 15 espèces.

## QA A17 du 2026-10-23

Pas de session téléphone : rien de la Ligue n'est encore jouable dans l'APK (cartes T9,
`LeagueDirector` T8 et départs `league_*` à venir ; seules les parties pures T2–T7 existent). À
reprendre avec la session 30A.

### 10.9 QA A17 du départ `league_lorelei` — 2026-10-24 (branche `jalon-30` `0123cd10`)

Une passe d'agent par adb sur l'A17 (`ANDROID_SERIAL=R5GYB2R7W2Y`, `deploy_s24.sh --debug-start
league_lorelei`), gestes par `adb shell input swipe` (glisser tenu = marche ; les touches
`DPAD_*` ne font rien). Captures dans `build/qa_j30/` (non versionnées).
- **Salle d'Olga** : arrivée `from_lobby`, porte nord fermée ; un pas vers le nord déclenche
  `league_lorelei_call` : marche forcée devant Olga, réplique, carte « OLGA — Conseil des
  Quatre », combat (Lamantine N54 en tête, Fuite grisée). Victoire → battants nord ouverts,
  réplique « vaincu » au PARLER (« Tu as du talent… Va. Les autres t'attendent. ») ;
  scène d'appel **ignorée** ensuite (aucune variante pour les drapeaux) : **OK**.
- **Porte sud** pendant la tentative : joueur poussé contre elle, aucun warp : **OK**.
- **Passage nord** → `league_bruno` (44,5 ms), `league_bruno_call` jouée aussitôt : **OK**.
- **Défaite contre Aldo** (équipe perdue exprès) → réveil au Centre de Jadielle
  (`viridian_center`, 143,9 ms ; attendu sans le hall du J29), équipe soignée (Salamèche
  116 / 116) : **OK**.
- Journal Godot : **aucune erreur ni avertissement**. Cadence : ≈ 49–50 i/s dans les salles,
  **≈ 40 i/s en combat** (salles d'Olga et d'Aldo).
- Non couvert : salles d'Agatha, Peter et du Champion, Chen, Panthéon ; rechargement d'une
  sauvegarde (le départ ne lit ni n'écrit la sauvegarde) ; Sac (Guérisons) en combat.
- Remarque : l'objectif du Menu Dresseur affiche « traverser le Pont Pépite » (drapeaux du départ
  de débogage, sans effet sur une vraie partie).
