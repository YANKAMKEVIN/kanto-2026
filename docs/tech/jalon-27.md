# Jalon 27 — Les défis de Safrania (Arène de Morgane, Badge Marais, CT46, Dojo de Combat)

> **PLAN — aucun code n'est écrit par ce document.** Source de vérité :
> `docs/design/passes/j27-v2-chatgpt.md` (7 arbitrages verrouillés par Kevin le 2026-10-19 ; ne pas
> les rouvrir). Plan écrit le 2026-10-21 (branche `plans-j26-j30`), en conception seulement.

> Objectif jouable sur le téléphone : **deux défis, dans l'ordre que l'on veut.** Dans l'**Arène
> Psy**, le joueur cherche son chemin entre des salles reliées par des **téléporteurs**, sans aide
> affichée. Il bat **Morgane** (Kadabra, M. Mime, Aéromite, Alakazam) et reçoit le **Badge Marais**
> et la **CT46 Vague Psy**. Au **Dojo de Combat**, il bat les élèves puis le maître, et choisit
> **un seul** Pokémon : **Kicklee** ou **Tygnon**. Ensuite, rien n'est imposé.
>
> **Mécanique nouvelle : aucune.** Téléporteurs (passe systèmes 2, S2F), don de Pokémon (J20),
> scène de Champion (modèle d'Erika), effet de Vague Psy (S2G). Seul ajout de logique : le **choix
> transactionnel** du Dojo, fait de données et d'un test (étapes de scène existantes).
>
> **Format de sauvegarde inchangé : v7.**

## 0. État et dépendances

### 0.1 Contrat d'entrée, relu sur le code (2026-10-21)

| Besoin | Où, état réel | Ce que fait le J27 |
|---|---|---|
| Carte `saffron_city`, portes de l'Arène et du Dojo | **J26** (plan `jalon-26.md` §0.2) : portes posées en « À venir » | Crée `saffron_gym` et `fighting_dojo`, relance l'outil de Safrania |
| Libération : drapeau **`silph_giovanni_defeated`** | J26 | Le sbire du J26 devant l'Arène disparaît avec ce drapeau. **Aucun drapeau `saffron_gym_unlocked`** [D] |
| Téléporteurs (`Warp.Style.TELEPORT`, `relocate`, `plan_check_teleports.py`) | `systemes-2` (S2F, validé) ; pas encore dans `main` | Nouveau graphe, données seulement |
| Vague Psy : effet `fixed_damage` mode `psywave` (niveau × 50 à 150 %, au moins 1) | `systemes-2` (S2G, T31, validé) ; **la capacité n'existe pas en données** | Crée la capacité `psywave` **avec** cet effet ; `tm_compatibility.json` la lie déjà à la CT46 |
| Soin, Protection, Mur Lumière (Alakazam, M. Mime) | `systemes-2` (S2G, validé) | Rien : données des capacités |
| Badge Marais | `main` : `data/badges.json` (`marsh`, `badge_marsh`) | Rien à créer |
| Don de Pokémon (Stockage si équipe pleine) | `main` (J20) : `PokemonGift` | Kicklee / Tygnon |
| Table des types | `main` : `data/pokemon/types.json` **moderne** (Spectre super efficace sur Psy, Acier, Ténèbres, Fée) | La question du §6 de la passe est tranchée par le dépôt ; rien à changer (Q27-3 si Kevin veut la 1re génération) |
| Espèces | `main` : Kadabra ; J22 : Aéromite (`venomoth`) ; J26 : Alakazam | **À créer** : M. Mime, Kicklee, Tygnon, et les espèces des Dresseurs absentes (audit T3) |
| CS hybrides du J16 | `main` | Le Badge Marais n'ouvre aucune CS (RB : obéissance jusqu'au N70) |

### 0.2 Contrat de sortie

| Donnée | Lue par |
|---|---|
| `badge_marsh` | J29 (garde n° 6 de la Route 23) |
| Espèces `hitmonlee`, `hitmonchan`, `mr_mime` | J30 (Aldo : Tygnon, Kicklee) |
| Capacité `psywave`, CT46 | Tout le jeu |

### 0.3 Ce qui peut commencer maintenant, ce qui attend

**Maintenant** : T1 à T5 (décodage RB du graphe de l'Arène, grilles de l'Arène et du Dojo, données,
textes, vue générale). Aucune carte réelle.

**Après la fusion de la passe systèmes 2 et du J26 dans `main`** : T6 et suivantes (les deux cartes
s'ouvrent depuis Safrania, créée par le J26). Le J27 peut être codé **en même temps que le J28**
(zones de carte disjointes : Safrania / Jadielle).

### 0.4 Écarts relevés

- La passe fait venir les téléporteurs « du J26 » : ils viennent de la passe systèmes 2 (décision
  du 2026-10-19). Le J27 ne fournit qu'un graphe.
- La passe propose `saffron_gym_unlocked` : remplacé par `silph_giovanni_defeated` (une seule
  source de vérité, posée par le J26).
- La passe propose `fighting_dojo_reward_choice` (`none` / `hitmonlee` / `hitmonchan`) : un drapeau
  ne porte pas de valeur dans le dépôt (`StoryFlags`). Remplacé par **deux drapeaux exclusifs**
  (§2.4) ; même sens, aucun champ de sauvegarde nouveau.

## 1. Découpage

### 1.1 Sous-jalons et validations

| Sous-jalon | Lots de la passe | Tâches | Validation |
|---|---|---|---|
| **27.0** | 27.0 | T0 à T5 | Kevin sur planches : grilles, graphe, vue générale, textes |
| **27-I** | 27A à 27F | T6 à T13 | **une session téléphone** (contenu sur systèmes validés), puis clôture |

### 1.2 Fichiers chauds

| Fichier | Risque |
|---|---|
| Grille et outil de Safrania (J26) | Faible : seulement les deux warps des portes |
| `data/pokemon/moves/*` (`psywave`) | Faible : vérifier qu'aucun jalon ne l'a créée |
| Fichiers d'espèces, `tm_compatibility.json` | Moyen : régénérer à chaque fusion |

## 2. Conception technique

### 2.1 Arène de Morgane (`tools/plans/safrania_arene.txt`, carte `saffron_gym`)

- **Topologie RB à 1:1** : salles reliées par des tapis de téléportation (pokered, `SaffronGym`).
  Décodage : `tools/art/saffron_gym_rb_decode.py` → positions `teleporteur` (`vers=`, `paire=`).
- **Une seule carte** : toutes les salles sont sur la même carte (comme RB) ; les téléporteurs
  utilisent `relocate` (S2F), sans rechargement.
- **Contrôles** : `plan_check_teleports.py` (paires, graphe imprimé, retour toujours possible) et
  `plan_check_j27.py` : la salle de Morgane n'est atteinte que par le bon parcours ; chaque Dresseur
  évitable a un parcours qui l'évite (arbitrage 3) ; aucune salle isolée.
- **Règles de la passe** respectées par la S2F : destination fixe, retour possible, aucune boucle
  (arriver sur un tapis ne le déclenche pas), orientation conservée. Le « court verrouillage à
  l'arrivée » de la passe est inutile : le `STEP_ON` ne se déclenche qu'en entrant sur la case [D,
  S2F].
- **Aucune aide** : ni flèche, ni minimap, ni marquage des tapis déjà pris.

### 2.2 Dresseurs de l'Arène et Morgane

- Dresseurs : équipes, niveaux, places et vision RB (audit T3, pokered `parties.asm` et
  `SaffronGym`). Bloc `trainer` existant ; vaincu = vaincu pour toujours.
- **Morgane** (`saffron_gym_sabrina`) : Kadabra 38, M. Mime 37, Aéromite 38, Alakazam 43
  (arbitrage verrouillé). Capacités RB, avec celles du lot S2G (Soin, Protection, Mur Lumière) ;
  une capacité encore en `pending_effects` est remplacée explicitement (liste au T3). IA `smart`.
- Scène sur le modèle d'Erika (`celadon_gym.json`) : `sabrina_met`, carte, combat →
  `badge_marsh` ; badge, puis CT46 si `tm46_received` absent (rattrapage si le Sac était plein).
  Défaite → réveil, rejouable, Badge non donné.

### 2.3 Dojo de Combat (`tools/plans/safrania_dojo.txt`, carte `fighting_dojo`)

- Salle RB à 1:1 : élèves en deux rangées, maître au fond, deux Poké Balls sur l'estrade.
- Élèves et maître : équipes RB (audit T3). Accès **libre** dès que Safrania est ouverte, avant
  comme après la libération (la passe : « le Dojo ne dépend pas de Giovanni »).
- Ordre : RB laisse aborder le maître directement ; la passe dit « Dresseurs du Dojo, puis le
  maître ». Défaut [D] : comme RB, les élèves gardent l'allée par leur vision ; aucun verrou ajouté.

### 2.4 Le choix Kicklee / Tygnon (transaction)

- Les deux Poké Balls sont des PNJ `unless [dojo_got_hitmonlee]` et `unless [dojo_got_hitmonchan]`,
  présents seulement `if [fighting_dojo_master_defeated]` (avant : le maître dit de le battre).
- **EXAMINER** une Ball : fiche de l'espèce (texte T27-10 ou T27-11), puis « Choisir KICKLEE ? »
  **OUI / NON** (confirmation explicite, comme le don d'Évoli). NON → rien.
- **OUI** : dans **un seul bloc synchrone** (aucune écriture entre les deux) : don (`PokemonGift`,
  Stockage si l'équipe est pleine) **et** drapeau `dojo_got_<espèce>` ; puis écriture immédiate
  (comme le don d'Évoli). Les deux Balls disparaissent (variantes `unless` des deux drapeaux).
- **Arrêt de l'application** : avant OUI → rien n'a changé ; après → l'écriture immédiate contient
  le Pokémon et le drapeau ; entre les deux, le point de reprise S2A ramène avant la scène. Jamais
  deux Pokémon, jamais zéro après un OUI écrit.

### 2.5 Drapeaux (v7 inchangée)

| Drapeau | Rôle |
|---|---|
| `sabrina_met` | Introduction déjà dite (modèle Erika) |
| `badge_marsh` | Badge (existe dans `badges.json`) ; posé à la victoire |
| `tm46_received` | CT46 remise |
| `fighting_dojo_master_defeated` | `defeated` du maître |
| `dojo_got_hitmonlee`, `dojo_got_hitmonchan` | Choix fait (exclusifs par construction) |
| `defeated` de chaque Dresseur | mécanisme existant |

### 2.6 Départs de débogage

`saffron_gym` (entrée de l'Arène, Safrania libérée, équipe N42) · `sabrina` (devant Morgane) ·
`fighting_dojo` (entrée du Dojo, Safrania occupée) · `dojo_choice` (maître battu, équipe pleine).

### 2.7 Art

Avant le code : grilles + une vue générale de l'Arène. Lot d'art ensuite : intérieurs (modules),
tapis de téléportation, Morgane, M. Mime, Alakazam, Kicklee, Tygnon, élèves, maître, fonds de combat
« Arène Psy » et « Dojo ».

## 3. Textes

La passe ne propose aucun texte : tout ce qui suit est **[D] (défaut, à relire)**.

| N° | Locuteur | Texte |
|---|---|---|
| T27-01 [D] | Guide de l'Arène | « Salut, futur Champion ! Morgane lit dans les pensées. Ici, les tapis t'emmènent ailleurs : souviens-toi d'où tu viens. » |
| T27-02 [D] | Morgane (avant) | « Je savais que tu viendrais. Je l'ai vu bien avant que tu franchisses la porte. » |
| T27-03 [D] | Morgane (reprise) | « Tu reviens. Je l'avais vu aussi. » |
| T27-04 [D] | Morgane (victoire du joueur) | « Je ne l'avais pas prévu… Tu as gagné. Prends le Badge Marais. » |
| T27-05 [D] | Morgane (CT) | « Et ceci : la CT46, Vague Psy. Sa force dépend du niveau de ton Pokémon. » |
| T27-06 [D] | Morgane (après) | « L'avenir n'est pas écrit. Tu viens de me le rappeler. » |
| T27-07 [D] | Maître du Dojo (avant) | « Ha ! Un challenger ! Le Dojo de Combat ne recule devant personne ! » |
| T27-08 [D] | Maître (victoire du joueur) | « Quelle force ! Choisis l'un de nos Pokémon. Il te suivra. » |
| T27-09 [D] | Maître (avant la victoire, si on parle aux Balls) | « Ces Pokémon sont réservés à qui me bat. » |
| T27-10 [D] | Narration (Ball de Kicklee) | « KICKLEE, le Pokémon Lutteur. Ses jambes s'allongent pour frapper de loin. » |
| T27-11 [D] | Narration (Ball de Tygnon) | « TYGNON, le Pokémon Puncheur. Ses poings sont plus rapides que l'œil. » |
| T27-12 [D] | Choix | « Choisir {pokemon} ? » OUI / NON |
| T27-13 [D] | Maître (après le choix) | « Prends-en soin. Et reviens t'entraîner quand tu veux ! » |
| T27-14 [D] | Narration (Ball restante, plus là) | aucune : la Ball disparaît (pas de texte) |

## 4. Tâches

### 4.1 Sous-jalon 27.0 — **maintenant**

#### T0 — A : plan (ce document) — fait
#### T1 — A : branche `jalon-27` depuis `origin/main` ; audit (espèces, `psywave`, équipes RB) sur toutes les branches
#### T2 — C : décodage RB, grilles de l'Arène et du Dojo, contrôles → K
#### T3 — A : données (espèces, capacités, `psywave` avec l'effet S2G, Dresseurs, Morgane, maître, répliques [D])
#### T4 — A : simulation d'équilibrage de Morgane (outil du J12), sur les données seules
#### T5 — C (Mac) : vue générale de l'Arène → K

### 4.2 Sous-jalon 27-I — **après la fusion de la passe systèmes 2 et du J26**

#### T6 — C : cartes `saffron_gym` et `fighting_dojo`, warps depuis Safrania
#### T7 — C : téléporteurs de l'Arène depuis la grille ; test du graphe joué — après T6
#### T8 — C : Dresseurs, guide, Morgane, Badge, CT46 — après T7, T3
#### T9 — C : Dojo, élèves, maître — après T6, T3
#### T10 — A : choix Kicklee / Tygnon (§2.4), test de transaction — après T9
#### T11 — A : départs de débogage ; contrôle de non-régression de la Sylphe (J26)
#### T12 — Q : **session 27** → K
#### T13 — A : clôture, passation J29 / J30, fusion après accord de K

## 5. Tests

- `test_saffron_gym.gd` : grille = plan ; chaque tapis → sa destination ; aucun aller-retour
  automatique ; salle de Morgane seulement par le bon parcours ; retour à l'entrée toujours possible.
- `test_saffron_gym_closed.gd` : pendant l'occupation, sbire devant la porte ; après, porte libre ;
  aucune autre condition (ni Badge, ni Morgane pour le Dojo).
- `test_sabrina.gd` : défaite → pas de Badge, rejouable ; victoire → Badge et CT46 une fois ; Sac plein
  → CT46 donnée à la visite suivante.
- `test_psywave.gd` : dégâts dans [niveau × 0,5 ; niveau × 1,5], au moins 1 (règle S2G, données J27).
- `test_dojo_choice.gd` : NON → rien ; OUI → un Pokémon, l'autre Ball partie ; équipe pleine →
  Stockage ; arrêt simulé avant / après l'écriture → jamais 0 après OUI, jamais 2.
- `test_dojo_independent.gd` : Dojo jouable avec Safrania occupée.
- `test_save_j27.gd` : v7 ; partie du J26 chargée sans changement.

## 6. Critères d'acceptation

1. `tools/test.sh` passe ; import sans erreur ; captures relues.
2. Grilles conformes (`plan_check_teleports.py`, `plan_check_j27.py`).
3. Morgane : équipe verrouillée, Badge Marais et CT46 une seule fois.
4. Dojo : exactement un Pokémon parmi Kicklee et Tygnon, quoi qu'il arrive à l'application.
5. Les deux défis sont indépendants ; rien n'est imposé après eux.
6. Session téléphone validée par K.

## 7. QA téléphone (une session, 45 min au plus)

| Scénario | Attendu |
|---|---|
| Arène, parcours libre | Arrivées lisibles, pas de boucle, on peut se perdre et revenir |
| Dresseur évité | Aucun combat forcé hors de sa vision |
| Morgane : défaite puis victoire | Rejouable ; Badge, CT46 |
| Dojo avant la libération | Accessible |
| Examiner les deux Balls, NON, puis OUI | Fiche lisible, confirmation claire au doigt |
| `dojo_choice` (équipe pleine) | Pokémon au Stockage, message clair |
| Arrêt forcé juste après OUI, relance | Un seul Pokémon |

## 8. Valeurs par défaut [D]

- Deux drapeaux exclusifs `dojo_got_hitmonlee` / `dojo_got_hitmonchan` au lieu d'une valeur.
- Accès à l'Arène lu sur `silph_giovanni_defeated` (sbire du J26).
- Pas de verrou d'arrivée sur les tapis (règle S2F).
- Kicklee et Tygnon N30 (RB).
- Élèves du Dojo sans verrou d'ordre (RB).
- Textes T27-01 à T27-13.

## 9. Points ouverts pour Kevin

- **Q27-1 — Textes** : propositions [D] (la passe n'en a pas). Couverts par ta validation d'avance,
  ou à relire ?
- **Q27-2 — Ordre du Dojo** : RB permet d'aller au maître sans battre tous les élèves. La passe dit
  « Dresseurs, puis maître ». Défaut : RB. Faut-il exiger les élèves ?
- **Q27-3 — Table des types** : le dépôt suit la table moderne (Psy moins dominant qu'en 1re
  génération). Rien ne change par défaut.
- **Q27-4 — Revanche** : Morgane et le maître ne se rejouent pas après la victoire (RB). Le post-game
  (passe J31 : Champions améliorés) s'en chargera.

## 10. Avancement (2026-10-22, branche `jalon-27` depuis `origin/jalon-26` @ `b510cc8c`)

Codé d'un trait la nuit du 2026-10-22 (Kevin absent, textes du plan **validés par Kevin le
2026-10-21, validation d'avance (proposition du plan)** ; défauts Q27-2 élèves non obligatoires,
Q27-3 table des types moderne, Q27-4 pas de revanche avant le post-game).

Suite complète **6 615 / 6 615** (610 scripts, 371 141 assertions) le 2026-10-22 après les effets de
Pied Sauté, Pied Voltige et Riposte, import sans erreur.

Fait : **T1 à T4, T6 à T11**. Reste : **T5** (vue générale peinte de l'Arène ; le code ne
l'attend pas), **T12** (QA téléphone, une session → Kevin), **T13** (clôture, fusion après accord).

| Tâche | Contenu |
|---|---|
| T1 | Branche `jalon-27` ; audit des espèces et capacités sur toutes les branches `origin/*` ; prénoms vérifiés libres partout (Mélusine, Ophélie, Cassandre, Albin, Nestor, Barnabé, Léandre, Hippolyte, Tancrède, Urbain, Wilfried) |
| T2 | `tools/art/saffron_gym_rb_decode.py` (pokered local, jamais embarqué) ; grilles `safrania_arene.txt` (20 × 18, neuf salles, 30 tapis = 15 paires RB) et `safrania_dojo.txt` (10 × 12) ; `plan_check_teleports.py` et `plan_check_j27.py` conformes (un seul tapis vers Morgane, chaque Dresseur évitable, un parcours sans aucun combat) |
| T3 | `kanto_saffron.json` (Kicklee, Tygnon ; fiches de Pokédex [D] et sprites provisoires générés), `moves/saffron.json` (**`psywave`** avec l'effet S2G, kinesis, rolling_kick, jump_kick, hi_jump_kick, ice_punch, thunder_punch, counter), `items_j27.json` (`tm46`), `tm_compatibility.json` régénéré ; 7 Dresseurs de l'Arène, Morgane (équipe verrouillée, capacités RB dont Vague Psy, Soin, Protection, Mur Lumière, Bouclier ; IA smart, carte), 4 élèves et le maître |
| T4 | `tools/sim/saffron_gym_scenario.json` (200 graines, équipe J26 + 4 niveaux [D]) : maître 100 % ; **Morgane du premier coup** (attentif) : Dracaufeu 35 %, Florizarre 12 %, Tortank 36,5 % (expert 48 / 23,5 / 56,5 %). Aucune donnée changée (information pour Kevin) |
| T6 | `tools/build_saffron_gym.gd` (enveloppes provisoires `placeholders_safrania_arene.py`) ; portes de Safrania ouvertes (`a_venir` retiré de `safrania.txt`, outil du J26 relancé : seules les deux portes changent) ; zone, lumière `interior_warm` [D], intérieurs, service « Arène » |
| T7 | 30 tapis `Warp.Style.TELEPORT` sur la même carte (`relocate`) ; parcours en 4 tapis joué de l'entrée à Morgane (S → SE → NE → NO → centre) ; arriver sur un tapis ne le déclenche pas ; retour possible |
| T8 | Morgane : scène sur le modèle d'Erika (`sabrina_met`, `badge_marsh`, `tm46_received`, rattrapage de la CT46) ; défaite → réveil ; guide (T27-01) |
| T9 | Dojo : 4 élèves (vision RB, aucun verrou d'ordre), maître parlé (scène : `fighting_dojo_master_defeated`) ; jouable Safrania occupée (porte sans drapeau) |
| T10 | Deux Poké Balls (`unless` des deux drapeaux) : avant la victoire, T27-09 ; après, fiche + « Choisir … ? » OUI / NON ; OUI → scène `fighting_dojo_take_<espèce>` (`unless` des deux drapeaux) : `gift_pokemon` N30 qui pose `dojo_got_<espèce>` **dans le même bloc** que le don, puis les deux Balls disparaissent ; autosave « don » immédiate |
| T11 | Départs `saffron_gym`, `sabrina`, `fighting_dojo` (Safrania occupée), `dojo_choice` (équipe pleine) ; README |

Tests : `test_saffron_gym` (7), `test_fighting_dojo` (6 : indépendance, Balls réservées, défaite,
NON puis OUI, Stockage + relance, arrêt avant l'écriture), `test_j27_debug_starts`,
`test_saffron_data` ; registres des tests de données mis à jour. Captures Mac :
`tools/capture_safrania_arene.sh` (relues : tapis lisibles, Balls sur l'estrade).

**Écarts et points ouverts** :
- **Emprunts à supprimer à la fusion** : `species/kanto_j27_emprunts.json` (venomoth, machoke de
  `jalon-22` ; slowpoke, slowbro de `jalon-24` ; **mr_mime de `jalon-29`**, psy seul), leurs fiches
  de Pokédex et sprites provisoires (copies identiques) et `moves/j27_emprunts.json` (barrier, amnesia de
  `jalon-22`, fire_punch de `jalon-25`, mega_kick, substitute de `jalon-29`) : copies identiques,
  sinon doublons d'identifiants au chargement. `tm_compatibility.json` : régénérer, ne pas fusionner
  à la main.
- Capacités créées sans branche d'origine : noms français confirmés par la coordination (Télékinésie, Mawashi Geri, Pied
  Sauté, Pied Voltige, Poing-Glace, Poing-Éclair, Riposte), puissances modernes. Kicklee / Tygnon
  apprennent ces capacités. Effets codés le 2026-10-22 (voir « Décisions de Kevin ») ; **à la fusion
  avec le J30** : `origin/jalon-30` crée aussi `jump_kick`, `counter` (priorité −5) et
  **`high_jump_kick`** (identifiant différent de notre `hi_jump_kick`) en `pending_effects` ; garder
  une seule définition, avec les effets du J27.
- Drapeau du maître : `fighting_dojo_master_defeated` posé par la victoire de sa scène (le maître
  n'est pas un Dresseur à vision, comme en RB) ; pas de `sabrina_defeated` (`badge_marsh` suffit).
- **Équilibrage** : Morgane est rude pour Florizarre (12 % au premier essai) ; à resimuler sur les
  vraies sorties des J21 à J26 avant de toucher l'équipe verrouillée ou ses capacités.
- Art provisoire : enveloppes générées, Morgane = `beauty`, Médiums = `youngster`, Karatékas =
  `hiker` (silhouette féminine), maître = `hiker` ; pas de fond de combat « Arène Psy » / « Dojo »
  (repli existant). Les bords est et ouest des salles touchent le bord de la carte (RB à 1:1).

## Décisions de Kevin (2026-10-22)

Choix validés par Kevin sur la page d'arbitrages.

Décisions de Kevin du 2026-10-22 : elles **remplacent les « recommandations appliquées par
défaut »** notées plus tôt. Le code les applique déjà.

- Morgane : à resimuler sur les vraies sorties des J21–J26, puis ajuster.
- Effets de Pied Sauté, Pied Voltige et Riposte : à coder avant la fusion → **fait le 2026-10-22**,
  règles de Rouge/Bleu vérifiées dans le pokered local (`build/rb/pokered` du worktree J28,
  `PrintMoveFailureText`, `HandleCounterMove`). Aucune branche `origin/*` ne les codait (le J30 les a
  aussi en `pending_effects`).
  - `crash` (`{ "kind": "crash", "amount": 1 }`) : raté, esquive (Tunnel) ou immunité (Spectre) →
    CRASHED, le lanceur perd 1 PV (RB : `wDamage` vaut 0, donc toujours 1 PV), K.O. possible ;
    texte « {pokemon} s'écrase au sol ! » (clé `crash`) **validé par Kevin le 2026-10-22**.
  - `counter` (priorité −1) : 2 × les dégâts du dernier coup reçu de la capacité adverse la plus
    récente si elle est **de type** Normal ou Combat (RB regarde le type, pas la catégorie : Météores
    se riposte, Pistolet à O non) ; sinon raté sans tirage ; précision ordinaire ; dégâts sans type
    (touche un Spectre, comme RB) ; Riposte contre Riposte rate. IA : Riposte seulement juste après un
    coup Normal ou Combat reçu [D].
  - Tests : `tests/unit/test_battle_crash_counter.gd` (14 : données, touche, rate, immunité,
    esquive, chute mortelle, Riposte après coup physique, sur Spectre, après coup spécial Eau,
    Normal spéciale, sans dégât reçu, attaque adverse ratée, seule la dernière capacité compte).
- Riposte comme Rouge/Bleu : capacité de type Normal ou Combat, même spéciale (c'est le type qui
  compte, pas la catégorie) : **décidé, déjà codé**.
- Morgane et le maître changent de Pokémon en combat : gardé. **Décidé, déjà codé.**
