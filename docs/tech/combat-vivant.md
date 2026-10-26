# Chantier « Combat vivant » — animations de combat

> **PLAN — aucun code n'est écrit par ce document.** Rédigé le 2026-10-26 par une session de
> coordination, sur `origin/main` @ `9bb1d803` ; branches `jalon-23`, `jalon-26` à `jalon-32` lues
> pour les attaques et les conflits de fichiers, plans `jalon-33.md` et `jalon-34.md` lus sur
> `origin/jalon-31`.
> Source de vérité du design : `docs/design/dossier-05-combat.md` (§4, §9 à §13, §16, §21, §22).
> Arbitrages : `docs/design/passes/combat-vivant-arbitrages-kevin.md` (**CV-1 à CV-14 tranchés par
> Kevin le 2026-10-26** : recommandations retenues, sauf **CV-1 : une animation par attaque**,
> **CV-2 : durée selon l'attaque**, **CV-10 : point d'origine par espèce** ; le plan en tient compte). Valeurs marquées **[D]** : valeurs par défaut (règle 4 de `CLAUDE.md`).
> Le chantier s'appelle **CV** ; ses sous-jalons **CV.0 à CV.Z**.

## 0. Pourquoi ce chantier

Le dossier 05 verrouille « **Attaques réellement animées : oui** » et « Caméra / animations
dynamiques : oui ». Aucun jalon ne les prévoit : le J4 les a reportées (`jalon-04.md`, « réaction du
décor aux attaques (§11), option Animations complètes / rapides (§21) »), le J5 a seulement préparé
`speed_scale`, et la phase DA ne cite que des « détails de combat du J9 » dans DAF.8, après la RC
(`phase-da-cadrage.md` §3.2). Le combat est l'écran que le joueur voit le plus : sans ce chantier,
la RC sortirait avec un élan, un clignotement et un flash pour les 165 attaques.

Ce chantier est du **travail Godot** (présentation) et un peu d'art (sprites de particules). Il ne
touche **ni aux règles ni au moteur** (`Battle`, `DamageCalc`, journal `BattleEvent`) : le moteur
renvoie déjà tout ce qu'il faut savoir.

## 1. État des lieux

### 1.1 Ce que fait le combat aujourd'hui

La chaîne est propre et se prête bien au chantier : `Battle` (moteur pur) → journal de
`BattleEvent` → `BattlePlayback.beats()` (découpe pure en `BattleBeat`) → `BattleDirector._play_beat()`
→ `BattleStage` (décor et Pokémon, un `CanvasLayer`, tout en `Tween`) et `BattleHud` (cartes, PV,
messages). Les durées sont des constantes de `battle_stage.gd` et de `UiTokens`, multipliées par
`speed_scale` (0 = instantané, tests).

**Un tour type** : Pikachu utilise Charge sur Roucool, puis Roucool utilise Tornade (valeurs à
`speed_scale` = 1, vitesse de texte normale) :

| t (s) | Temps (`BattleBeat`) | À l'écran | Code |
|---|---|---|---|
| 0,00 | MESSAGE | « Pikachu utilise Charge ! » s'écrit (≈ 45 car./s, ≈ 0,5 s), tenu 0,9 s | `UiTokens.BATTLE_MESSAGE_HOLD` |
| ≈ 1,40 | MOVE (physique) | élan de **60 px** vers l'adversaire (0,12 s), retour (0,18 s) | `play_move`, `LUNGE_*` |
| ≈ 1,70 | DAMAGE | Roucool **clignote** 3 fois (disparaît franchement, `HIT_ALPHA` 0) et tremble de 10 px (0,36 s) ; **en même temps** la barre de PV descend en 0,4 s (0,25 s si le coup retire plus de 25 % des PV max) ; vibration 30 ms | `play_hit`, `HP_TWEEN`, `HP_BIG_HIT` |
| ≈ 2,10 | MESSAGE | « C'est super efficace ! » le cas échéant (≈ 1,4 s) | |
| ≈ 2,10 | — | **son** de l'attaque, puis son du coup | voir §1.3 |
| … | MOVE (spécial) | Roucool **pulse en blanc** deux fois (2 × 0,28 s), sans rien lancer | `SPECIAL_GLOW` |
| … | MOVE (statut) | deux petits bonds de 18 px (0,64 s) | `STATUS_HOP` |
| coup critique | DAMAGE | en plus : flash blanc 0,35 → 0 en 0,16 s, secousse de la scène de 4 px | `CRIT_*` |

Déjà là, et à garder : l'entrée de combat (~1 s, jamais d'écran noir) et la sortie ; la capture
complète (lancer en arc, absorption rouge, chute, 0 à 3 secousses, éclat doré) ; le rappel ; Tunnel
(le Pokémon s'enfonce), Téléport (scintille), le K.O. (chute et fondu) ; la montée ou la baisse de
statistique (teinte + petit déplacement) ; les voiles de fin de tour (poison violet, brûlure orangée) ;
les **effets de statut** du J11 (`StatusAura` : décharges de paralysie, braises de brûlure, « z » du
sommeil, teinte du gel, étoiles de confusion) ; la **pulsation** de la carte sous 20 % de PV
(`HP_LOW_PULSE`) ; la couleur vert → jaune → rouge ; « Réduire les animations » (×0,6 sur les
durées, particules de statut coupées) et « Réduire les flashs » (clignotement → assombrissement).

### 1.2 Ce qui manque par rapport au dossier 05

| Dossier 05 | Aujourd'hui | Écart |
|---|---|---|
| §4 Caméra : léger zoom, déplacement du cadrage, tremblement subtil, flash, particules, **retour immédiat** | secousse de 4 px et flash **sur un critique seulement** ; aucun zoom | caméra de combat à créer |
| §9 Physique : « Pikachu prend appui → **traverse une partie de l'écran** → impact → revient » ; Morsure : « Rattata **bondit** » | élan de 60 px (≈ 3 % de la largeur), aucun appui, aucun impact | chorégraphie d'appui, de course et d'impact ; variantes (coup, griffe, crocs, perçant, corps) |
| §10 Distance : Éclair « joues qui s'illuminent, CRACK, l'éclair traverse la scène ; ~2 images **tout l'environnement éclairé** ; plumes / particules ; 1 à 1,5 s » | le lanceur pulse en blanc ; **rien ne part**, rien n'arrive | projectiles, rayons, particules par élément ; Éclair comme référence |
| §11 Le monde réagit (électrique → arbres éclairés ; feu → lumière orange au sol ; eau → gouttelettes ~0,5 s ; grosse attaque → feuilles) | rien | lumière simulée sur le décor peint, gouttelettes, feuillage du premier plan |
| §12 Gros coup → descente plus rapide **+ impact sonore** | barre plus rapide (0,25 s) ; son du coup choisi par l'efficacité, pas par la taille du coup | son « coup lourd » ; trace des PV perdus (CV-9) |
| §13 Statuts visibles : paralysie, **poison → aura / particules**, **sommeil → respiration différente**, brûlure | paralysie, brûlure, gel : oui ; sommeil = « z » mais pas de respiration ; **poison : rien de permanent** | aura de poison (et Toxik, J23), respiration du sommeil, petit effet au moment où le statut est infligé |
| §16 Capture « presque sacrée » | storyboard joué, Ball provisoire en pixel art | finition (CV-11) |
| §21 Option **Animations de combat : Complètes / Rapides** ; sauvage faible en 20 à 40 s | `speed_scale` existe, **aucune option** ; seul « Réduire les animations » (Accessibilité) | réglage à créer, distinct de l'accessibilité (CV-4) |
| §22 Boss et légendaires | entrée « légendaire » 1,5 × plus lente (S2, T30) | hors périmètre (CV-12) |

### 1.3 Un défaut de synchronisation du son (trouvé en lisant le code)

`AudioBridge._battle_sfx` joue le bruitage de l'attaque et celui du coup sur le signal
`BattleDirector.event_played`, qui part **après** tous les temps de l'événement
(`battle_director.gd`, boucle `for beat … await _play_beat(beat)` puis `event_played.emit`). Le son
d'une attaque sort donc **après** son élan (et le son du coup après la descente des PV et les
messages qui suivent le coup). Non vérifié à l'oreille sur téléphone ; à confirmer en CV.0, puis à
corriger par des **repères sonores** posés dans la chorégraphie (§2.5).

### 1.4 Ce sur quoi on s'appuie

- `BattleLayout` (pur) : ancres en hauteurs d'écran, **cadrage B** (ton dos grand, coupé par le
  bas ; adversaire à 0,34 ; boîtes maximales), `hud_zones()` (zones calmes de l'interface). Les
  effets se placent avec ces ancres, jamais en pixels fixes : même rendu de 1920 à 2340 de large.
- `BattleStage.get_sprite_rect(side)` et `StatusAura.get_target_rect()` : boîte visible d'un
  Pokémon à l'écran (origine et taille de l'impact).
- Décor peint (CB.3) : calques `back` et `front` (`get_decor_back/front`) ; repli sur la carte
  floutée. Les effets « monde » visent ces deux calques.
- `SfxCatalog.move_sfx(move_id, type, category)` : déjà un choix **par famille** (type ×
  catégorie) avec exceptions par attaque (`data/audio/sfx.json`, `move_sounds`, SON-11). Le
  chantier suit exactement ce modèle pour l'image.
- Perf : l'A17 (Mali-G57) est déjà au bord du budget GPU en extérieur (`moteur-commun.md` : une
  passe qui recopie l'écran coûte ≈ 8 ms) ; aucune mesure de fréquence **en combat** n'existe sur
  l'A17. Le seul usage de particules du jeu est en `CPUParticles2D` (écran d'évolution, Forêt de Jade).

## 2. Architecture

### 2.1 Principe

Trois couches, comme le reste du combat :

1. **Données** : `data/battle/move_fx/` (familles dans `families.json`, attaques dans un fichier par lot) dit, pour chaque attaque, sa **famille** et ses
   réglages ; les familles décrivent leur chorégraphie en **phases** et en **calques d'effets**.
2. **Logique pure** (testable sans scène, `game/battle/fx/`) : catalogue, résolution de l'issue
   d'une attaque à partir du journal, calcul de la chorégraphie (durées, repères, positions
   normalisées) selon le mode (Complètes / Rapides / Réduites).
3. **Présentation** (`game/battle/fx/` aussi, nœuds) : bibliothèque d'effets Godot (particules,
   shaders, tweens de caméra) qui **exécute** une chorégraphie calculée. `BattleStage` garde ses
   responsabilités ; il délègue `play_move` / `play_hit` au lecteur d'effets.

Le moteur de combat (`Battle`) et `BattleEvent` ne changent pas. `BattlePlayback` change à peine
(§2.4).

### 2.2 Données : `data/battle/move_fx/` (exemple réuni en un seul bloc)

```json
{
  "version": 1,
  "families": {
    "electrique": {
      "launch": "charge_spark", "travel": "bolt", "impact": "spark_burst",
      "world": {"light": "#FFF3A0", "light_peak": 0.55, "light_frames": 2},
      "camera": {"zoom": 1.04, "shake": 3},
      "durations": {"full": 1.1, "fast": 0.45},
      "sfx_marks": {"launch": 0.0, "impact": 0.62}
    }
  },
  "impacts": {"coup": "...", "griffe": "...", "crocs": "...", "percant": "...", "corps": "..."},
  "modifiers": {"drain": "...", "multi": "...", "charge": "...", "contrecoup": "...",
                "auto_ko": "...", "ko_un_coup": "...", "piege": "...", "recharge": "...", "chute": "..."},
  "moves": {
    "tackle": {"family": "contact", "impact": "corps"},
    "thunder_shock": {"family": "electrique", "signature": "eclair"},
    "absorb": {"family": "plante", "modifiers": ["drain"]}
  },
  "signatures": {"eclair": {"base": "electrique", "override": {"...": "..."}}}
}
```

- **Une entrée par attaque**, obligatoire (test : toute attaque de `data/pokemon/moves/` a une
  famille). Repli codé si une attaque manque quand même : famille de son type et de sa catégorie,
  comme `move_sfx` (une attaque ajoutée par un jalon en cours ne casse rien ; le test la signale).
- **Une chorégraphie propre par attaque** (CV-1, décision de Kevin) : chaque entrée de `moves`
  part de sa famille (briques communes : émetteurs, impacts, lumières) et la **compose à sa
  façon** (nombre et forme des projectiles, origine, trajectoire, impact, couleur, durée). Une
  attaque qui demande un effet vraiment neuf (une vague, la foudre qui tombe du ciel) ajoute une
  brique à la bibliothèque (« signature », §3.3).
- Les chorégraphies sont réparties en **un fichier par lot** (`data/battle/move_fx/*.json`, fusionnés
  au chargement ; une attaque dans deux fichiers est une erreur de test) : deux sessions qui
  écrivent des lots différents ne se gênent pas.
- Les **modificateurs** viennent des effets de l'attaque (`drain`, `hits`, `charge`…) et ajoutent
  un morceau commun (flux qui revient au lanceur, impact répété, lueur de charge…).
- Les couleurs, durées et intensités sont des données : on règle sur le S24 sans toucher au code.
- **Points d'origine par espèce** (CV-10, décision de Kevin) : `data/battle/fx_anchors.json`, pour
  chacune des 151 espèces, **de face** (artwork officiel) **et de dos** (dos peint, cadrage B), des
  points nommés : `tete` (obligatoire), `bouche`, `yeux`, `joues`, `mains`, `queue`, `cornes`,
  `canons`, `bulbe`, et `centre` (barycentre calculé). Coordonnées **normalisées dans la boîte
  visible de l'image source** (alpha > 0, la boîte en pixels est écrite à côté) ; pour la face,
  l'image source est l'artwork entier, avant le recadrage de `PokedexArt.portrait` (le jeu
  retranche la région du recadrage). Outil : `tools/art/fx_anchors.py` (squelette, grilles,
  planche, vérification) ; test : `tests/unit/test_fx_anchors.gd`. Chaque chorégraphie dit d'où elle
  part (Éclair : `joues` ; Lance-Flammes : `bouche` ; Hydrocanon : `canons` ; Fouet Lianes :
  `bulbe` ; Psyko : `yeux`) ; repli : point demandé → `bouche` → `tete` → `centre`. Un dos qui change
  (lots DAF) garde ses points s'il est remplacé à l'identique ; sinon, sa ligne est refaite.

### 2.3 Logique pure (`game/battle/fx/`, `RefCounted`, testée par GUT)

| Classe | Rôle |
|---|---|
| `MoveFxCatalog` | charge et valide `data/battle/move_fx/` (familles, impacts, signatures, repli par type) ; `entry(move_id)` |
| `MoveFxOutcome` | lit le journal **à partir d'un `MOVE_USED`** jusqu'au prochain `MOVE_USED` ou `TURN_STARTED` : touché / raté (`MOVE_MISSED`) / sans effet (`NO_EFFECT`) / esquivé (`DODGED`) / échec (`FAILED`) / statut posé ; critique, efficacité, nombre de coups (`MULTI_HIT`), K.O. de la cible |
| `MoveFxPlan` | chorégraphie calculée : phases (anticipation, trajet, impact, réaction du monde, retour) avec début et durée, repères sonores, intensité de caméra, positions **normalisées** (ancres de `BattleLayout`) ; dépend du mode (§2.6) et de l'issue (un raté : le projectile passe à côté ; un critique : caméra un cran plus forte) |
| `BattleFxBudget` | durées nominales d'un combat scripté (somme des temps) : sert au test « sauvage faible en 20 à 40 s » (§5, CV.Z) |

Tout est déterministe : aucun tirage dans le RNG du combat (les variations de particules utilisent
une graine locale, comme `StatusAura` qui n'utilise aucun aléatoire).

### 2.4 Branchement sur le journal

- `BattlePlayback` : le temps **MOVE** reçoit son `MoveFxPlan` (le directeur le calcule avec
  `MoveFxOutcome` sur la liste des événements de l'action, qu'il a déjà en main) ; le temps
  **DAMAGE** qui suit joue l'**impact** de ce plan (au lieu du clignotement générique), en même
  temps que la barre de PV, comme aujourd'hui.
- Attaque de statut : l'impact se joue au temps du résultat (`STATUS_TAG`, `STAT`, `CONFUSION`).
- Raté, sans effet, esquive, échec : le plan finit seul (projectile qui file, impact absent,
  petite poussière), puis le message.
- Coups multiples : un impact par `DAMAGE` (déjà un `DAMAGE` par coup dans le journal).
- Attaques à deux tours (Tunnel, Vol, Lance-Soleil, Coud'Krâne, Piqué, Coupe-Vent) : la phase 1
  se joue sur `CHARGE_STARTED` (lueur, ou disparition déjà codée), la phase 2 sur le `MOVE_USED`
  suivant.
- Métronome, Mimique, Copie : l'attaque appelée joue sa propre chorégraphie.
- Dresseur adverse et sauvage : mêmes chorégraphies, **en miroir** (l'adversaire lance de haut à
  droite vers le bas à gauche ; la perspective change la taille des effets avec la profondeur).

### 2.5 Son : repères dans la chorégraphie

Le plan porte des **repères** (`launch`, `impact`, `impact_2`…). Le lecteur d'effets émet
`fx_cue(cue, move_id)` au bon instant ; `AudioBridge` y joue le bruitage de l'attaque
(`move_sfx`, inchangé) au repère `launch`, et le bruitage du coup (`hit_*`, plus un `hit_heavy`
[D] pour un gros coup, §4.2) au repère `impact`. Les autres sons du combat restent sur
`event_played`, sauf ceux qui doivent coller à l'image (à lister en CV.0 : envoi, K.O.). Le
nombre de bruitages ne change pas : ≈ 20 familles sonores (SON-11) pour 17 familles visuelles ; la
correspondance est une table de `data/battle/move_fx/families.json`, pas du code.

### 2.6 Modes d'animation et Paramètres

| Mode | Quand | Effet |
|---|---|---|
| **Complètes** | défaut [CV-4] | chorégraphie entière : appui, trajet, impact, monde, caméra ; **durée selon l'attaque** (CV-2, tableau ci-dessous), de 0,5 à 2,5 s |
| **Rapides** | réglage du joueur | même famille, **sans anticipation ni caméra**, trajet et impact compressés : ≤ 0,5 s par attaque ; monde réduit à la lumière |
| **Réduites** | « Réduire les animations » (Accessibilité), réglage distinct [CV-5] | comme Rapides, **sans aucun mouvement de caméra ni secousse** ; particules réduites de moitié |

**Durée en Complètes selon l'attaque** (CV-2, décision de Kevin ; bornes [D], réglées sur le S24) :

| Attaque | Durée |
|---|---|
| statut, puissance ≤ 40, chaque coup d'une attaque à coups multiples | 0,5 – 0,8 s |
| puissance 45 à 80 | 0,8 – 1,3 s |
| puissance 85 à 110 | 1,2 – 1,8 s |
| puissance > 110, K.O. en un coup, Explosion / Destruction, attaques des légendaires | 1,8 – 2,5 s |

Un sauvage faible ne voit que des attaques de la première ligne : il reste dans les 20 à 40 s du §21.
Un combat de Ligue sera plus long, ce qui est voulu. Rapides : ≤ 0,5 s pour toutes.

- Nouveau réglage `battle_animations` (`GameSettings`, enum `FULL` / `FAST`, défaut `FULL`, nom
  JSON `full` / `fast`) ; contrôle « Animations de combat : Complètes / Rapides » dans la catégorie
  **JEU** de l'écran Paramètres (`SettingsViews`), aide [D] « Rapides : combats plus courts, mêmes
  effets. ». Ancien fichier de réglages : lu à son défaut (pas de changement de version, comme les
  volumes du Son).
- « Réduire les flashs » s'applique **toujours** : pas d'éclair plein écran (lumière simulée
  plafonnée à 0,35), jamais plus de **3 flashs par seconde** (règle d'accessibilité usuelle), quel
  que soit le mode.
- La tenue des messages (`BATTLE_MESSAGE_HOLD`) ne dépend pas du mode (règle T29 existante) ; la
  vitesse de texte reste un réglage à part.

### 2.7 Bibliothèque d'effets (présentation)

| Élément | Choix | Pourquoi |
|---|---|---|
| Lecteur | `MoveFxPlayer` (`Node2D` enfant du `BattleStage`, au-dessus des sprites, sous la HUD) : exécute un `MoveFxPlan` avec un `Tween` maître ; `speed_scale` = 0 → instantané (tests) | même convention que tout le combat |
| Particules | **`CPUParticles2D`** [D], pool préinstancié à l'entrée du combat (≈ 12 émetteurs, ≤ 64 particules chacun, **≤ 200 à l'écran**) | petit nombre de particules ; aucune compilation de shader de particules au premier coup sur Mali (à-coup) ; déjà le choix du jeu. `GPUParticles2D` seulement si la mesure de CV.0 le justifie |
| Rayons, arcs, jets | `Line2D` / `Polygon2D` animés + textures additives ; Éclair : polyligne brisée régénérée 2 à 3 fois (graine locale) | coût faible, net à toutes les tailles |
| Lumière du monde [CV-6] | **lumière simulée** : sprites radiaux additifs (couleur de la famille) posés sur le calque `back` du décor, et `modulate` bref du décor ; **pas de `Light2D`**, **pas de passe qui recopie l'écran** | l'A17 n'a pas la marge (≈ 8 ms par recopie) ; n'interfère pas avec l'étalonnage de `WorldLighting` ni avec DAF.6 |
| Distorsion (Psy, chaleur) | shader **sur le sprite de la cible** ou sur un sprite d'effet, jamais `SCREEN_TEXTURE` | même raison |
| Feuillage | petit balancement (shader de sommet ou `skew` animé) du calque `front` sur les grosses attaques | §11 « feuilles qui bougent » ; aucune destruction |
| Caméra | `BattleCamera` : zoom et décalage **du calque du combat** (le `CanvasLayer` du stage, pas la HUD), tremblement par bruit doux, retour en ≤ 0,15 s ; plafonds dans les données (zoom ≤ 1,06, tremblement ≤ 6 px [CV-3]) | §4 « retour immédiat », « pas Final Fantasy » ; la HUD ne bouge jamais |
| Textures | atlas unique `assets/sprites/battle_fx/` (≈ 20 sprites, 128 à 256 px, LINEAR) + formes dessinées en code [CV-7] | une seule texture à charger, mémoire négligeable |

### 2.8 Budget de performance

- **60 i/s en combat** sur le S24 et l'A17 en Complètes, profil de qualité Élevée ; l'Économie
  (30 i/s) garde tous les effets.
- Mesure de base en **CV.0** sur l'A17 (aucune n'existe en combat) avec `PerfProbe` et un départ
  de débogage « galerie d'effets » qui joue toutes les familles en boucle ; puis à chaque
  sous-jalon.
- Garde-fous dans les données : particules par famille, émetteurs simultanés, taille des sprites
  additifs (le surcoût du remplissage compte plus que le nombre de particules sur Mali).
- Si l'A17 ne tient pas : le profil Économie (ou « Lumière d'ambiance » coupée) divise les
  particules par deux et coupe le balancement du feuillage, sans changer la chorégraphie.

## 3. Familles d'effets

### 3.1 Chorégraphie commune

Chaque attaque suit cinq phases ; une famille choisit ce qui remplit chacune. Durées en Complètes
[D], à régler sur le S24 :

| Phase | Contenu | Durée |
|---|---|---|
| 1. Anticipation | le lanceur se prépare : appui (physique), lueur ou charge (spécial), posture (statut) | 0,15 – 0,30 s |
| 2. Trajet | le lanceur traverse (contact) ou l'effet part : projectile, rayon, jet, onde | 0,15 – 0,40 s |
| 3. Impact | sur la cible : particules, éclat, tremblement du sprite (celui d'aujourd'hui, adouci), barre de PV en même temps | 0,20 – 0,35 s |
| 4. Réaction du monde | lumière simulée sur le décor, gouttelettes, feuillage ; se superpose à l'impact | 0,1 – 0,5 s |
| 5. Retour | caméra et lanceur reviennent au cadrage normal | ≤ 0,15 s |

Le contact physique (§9) devient : appui (le Pokémon recule de 4 % et s'écrase de 6 %), course
sur **25 à 35 % de la distance** entre les deux Pokémon (le tien rétrécit en s'éloignant, l'adversaire
grandit en avançant : la profondeur du cadrage B est respectée), impact au point de contact,
retour en arc. « Bondit » (Morsure, Croc de Mort, Vive-Attaque) : même trajet en arc.

### 3.2 Les 17 familles

| # | Famille (`id`) | Lancement → trajet → impact | Monde | Attaques |
|---|---|---|---|---|
| 1 | Contact (`contact`) | appui → course → impact selon la variante : **coup** (étoile d'impact), **griffe** (3 entailles), **crocs** (deux mâchoires qui se ferment), **perçant** (trait + éclat), **corps** (onde de choc ronde) | poussière au sol | 51 |
| 2 | Feu (`feu`) | lueur orange → flammèches / boule → gerbe de braises | **lumière orange au sol** (§11) | 5 |
| 3 | Eau (`eau`) | bulle qui gonfle → jet / bulles → éclaboussure | **gouttelettes ~0,5 s** (§11) | 8 |
| 4 | Électrique (`electrique`) | étincelles sur le lanceur → arc brisé → décharge en étoile | **scène illuminée 2 images**, arbres éclairés la nuit (§10, §11) | 5 |
| 5 | Plante (`plante`) | feuilles qui tournent → volée de feuilles / lianes / nuage de spores → feuilles qui retombent | feuillage du premier plan | 10 |
| 6 | Glace (`glace`) | givre sur le lanceur → rayon bleu pâle / cristaux → éclats de glace, brume | voile froid bref | 5 |
| 7 | Psy (`psy`) | yeux / aura rose → anneaux concentriques → **distorsion** de la cible | — | 6 |
| 8 | Poison (`poison`) | bulles violettes → giclée / nuage → gouttes et vapeur | — | 7 |
| 9 | Sol et roche (`sol_roche`) | appui lourd → pierres / os / fissure → débris, poussière, **secousse** | feuillage, poussière | 7 |
| 10 | Vol et vent (`vent`) | battement → rafale en lignes → **plumes** et tourbillon | feuillage | 8 |
| 11 | Spectre (`spectre`) | ombre qui s'étire → onde sombre / main → voile noir-violet | décor assombri un instant | 3 |
| 12 | Dragon (`dragon`) | aura bleu nuit → flamme bleue → éclat | — | 1 |
| 13 | Énergie, normal spécial (`energie`) | point lumineux → étoiles (Météores) / trois rayons (Triplattaque) / rayon (Ultralaser) → éclat blanc | lumière blanche | 5 |
| 14 | Son (`son`) | bouche ouverte → **ondes sonores** en arcs → la cible vibre | — | 6 |
| 15 | Statut positif (`statut_plus`) | sur le lanceur : aura montante (lames pour Danse-Lames, bouclier pour Protection / Mur Lumière, flou de vitesse pour Hâte) ; la teinte de stat d'aujourd'hui reste | — | 25 |
| 16 | Statut négatif (`statut_moins`) | regard, sable, fumée, fil… vers la cible → aura descendante sur la cible | — | 10 |
| 17 | Soin (`soin`) | lumière verte douce, particules qui montent, la barre remonte | — | 3 |

Les nombres comptent les **165 attaques de Rouge/Bleu** : 159 dans les données (`main` et les
branches `jalon-23` à `jalon-31`) et 6 absentes à ce jour (Coupe-Vent, Copie, E-Coque, Éboulement,
Affûtage, Conversion), qu'un jalon ajoutera ; elles ont déjà leur famille dans l'annexe A.

**Modificateurs** (un morceau commun ajouté à la famille, lu dans les effets de l'attaque) :
`drain` (flux de lumière de la cible vers le lanceur : Vol-Vie, Méga-Sangsue, Vampirisme,
Dévorêve), `multi` (impact répété, un par coup), `charge` (lueur au tour 1), `contrecoup` (le
lanceur encaisse), `auto_ko` (le lanceur s'effondre), `ko_un_coup` (impact lourd, ralenti bref),
`piege` (anneau ou flammes qui restent autour de la cible jusqu'à `TRAP_ENDED`), `recharge` (le
lanceur halète au tour suivant), `chute` (Pied Sauté raté : le lanceur tombe).

**Attaques à part** : Trempette (petit saut, rien ne part : c'est la blague de Magicarpe) ;
Morphing (fondu vers l'apparence de la cible, selon ce que code le J31) ; Téléport et Tunnel
gardent leurs animations du J14 ; Clonage (silhouette translucide, si le J27 l'affiche).

### 3.3 Une animation par attaque, et les signatures

Décision de Kevin (CV-1, 2026-10-26) : **chacune des 165 attaques a sa propre animation**. Les 17
familles du §3.2 restent les **briques** (et le filet de sécurité : une attaque pas encore faite
joue la version de sa famille, jamais rien). Exemples dans la famille Feu : Flammèche (trois petites
flammes en arc), Poing de Feu (élan, poing enflammé, impact), Danse Flamme (tourbillon qui reste
autour de la cible jusqu'à `TRAP_ENDED`), Lance-Flammes (jet continu), Déflagration (étoile de feu).

Les attaques sont faites **par lots, dans l'ordre d'exposition** : un script (T8 bis) classe les
165 attaques selon le moment où le joueur les voit le plus tôt (learnsets des starters et des
Pokémon des premières routes, Dresseurs, Champions), puis on découpe en quatre lots d'environ 40.

Les **signatures** sont les attaques qui demandent une brique neuve dans la bibliothèque (pas
seulement une composition de données). Liste de départ :

| Priorité | Attaque | Ce qu'elle a en propre | Pourquoi |
|---|---|---|---|
| A | **Éclair** (`thunder_shock`) | les **joues** qui crépitent (point `joues` de l'espèce, CV-10 ; repli : `bouche`, puis `centre`), CRACK, arc qui traverse la scène, **scène entière illuminée 2 images**, plumes si la cible est de type Vol ; 1,2 s | modèle du dossier 05 §10, première attaque du starter du rival |
| A | **Tonnerre** (`thunderbolt`) | arc double plus épais, lumière plus longue | CT24, attaque de fin de jeu courante |
| A | **Fatal-Foudre** (`thunder`) | foudre qui **tombe du ciel** sur la cible, voile sombre 0,1 s avant | Électhor |
| A | **Lance-Flammes** (`flamethrower`) | jet continu qui ondule, lumière orange qui avance au sol | Dracaufeu, Arcanin |
| A | **Déflagration** (`fire_blast`) | boule puis étoile de feu à cinq branches au contact | silhouette célèbre |
| A | **Hydrocanon** (`hydro_pump`) | deux jets jumeaux, gouttelettes sur tout le premier plan | Tortank |
| A | **Surf** (`surf`) | une vague traverse la scène de gauche à droite (ou l'inverse) | CS03, utilisée partout |
| A | **Ultralaser** (`hyper_beam`) | charge, rayon large, **recul de caméra**, poussière ; recharge visible au tour suivant | Dracolosse, Ligue |
| A | **Séisme** (`earthquake`) | secousse longue de toute la scène (plafond de CV-3), poussière, feuillage | CT26 |
| A | **Psyko** (`psychic`) | ondes et forte distorsion de la cible, teinte rose | Alakazam, Mewtwo |
| B | **Blizzard** (`blizzard`) | rafale de neige sur toute la scène, givre sur la cible | Artikodin |
| B | **Lance-Soleil** (`solar_beam`) | tour 1 : lumière qui se concentre ; tour 2 : rayon doré | attaque à deux tours |
| B | **Explosion** / **Destruction** | éclair blanc (plafonné par « Réduire les flashs »), souffle, lanceur à terre | effet unique, partagé |

Les 13 sont marquées « oui » dans la colonne « Phare » de l'annexe A. Les 152 autres attaques sont
des compositions propres faites avec les briques (aucune n'a seulement la version de sa famille à
la fin du chantier).

### 3.4 Art à produire

Atlas de **≈ 35 sprites de particules** [CV-7 ; ≈ 20 au départ, une deuxième série pour les
compositions par attaque] : flamme, braise, goutte, bulle, éclaboussure, feuille, pétale, spore,
plume, éclat de glace, flocon, caillou, os, poussière, étoile d'impact, entailles de griffe,
mâchoires, poing, pied, corne, note de son (ou arc), étincelle, lueur ronde douce, fumée, cœur
(Grobisou), œuf (Bomb'Œuf), étoile (Météores), aiguille (Dard-Nuée), lame (Danse-Lames)… Peints
« dans la même main » que le monde (`vision.md`), fond transparent, lumière neutre, produits par la
chaîne de la phase DA (fiche de série, `tools/art/generer.sh`, planche à l'échelle du jeu, validation
de Kevin, DA-6). Le reste (rayons, arcs, ondes, anneaux, lueurs) est **dessiné en code**. Avant
que l'atlas ne soit validé, CV.0 et CV.1 tournent avec des formes procédurales : le code ne bloque
jamais sur l'art (levier 4).

## 4. Statuts visibles et retours de PV

### 4.1 Statuts (dossier 05 §13)

| Statut | Aujourd'hui (`StatusAura`, J11) | Ajout CV |
|---|---|---|
| Paralysie | décharges jaunes toutes les 1,6 s | inchangé ; décharge plus forte au moment de « … est paralysé ! Il ne peut pas attaquer ! » (`STATUS_PREVENTED`) |
| Brûlure | braises qui montent, voile orangé en fin de tour | inchangé |
| Sommeil | « z » qui s'envolent | **respiration lente** : le sprite gonfle de 2 % sur 2,4 s [D] (échelle verticale, pieds fixes) |
| Gel | teinte bleu glacé figée | quelques éclats de givre qui scintillent |
| Poison | **rien de permanent** (voile en fin de tour) | **aura** : 3 à 5 bulles violettes qui montent et éclatent, par intermittence |
| Toxik (J23, `toxic`) | (selon le J23) | aura de poison plus dense et plus foncée |
| Confusion | étoiles au moment du test | inchangé |
| **Statut infligé** | étiquette et son | petit effet de **pose** (0,3 s) aux couleurs du statut, au temps `STATUS_TAG` |

« Réduire les animations » coupe les particules comme aujourd'hui et garde les teintes et la
respiration (lente, sans risque). Aucun tirage dans le RNG du combat.

**Respiration au repos de tous les Pokémon** (pas seulement du sommeil) : rien ne bouge
aujourd'hui entre deux actions ; un souffle très léger (1 %, 3 s, décalé entre les deux camps)
rendrait la scène vivante et donne son sens à « respiration *différente* » du sommeil. Proposé en
CV-8.

### 4.2 Retours de PV (dossier 05 §12)

| Point | Aujourd'hui | Ajout CV |
|---|---|---|
| Descente normale / rapide | 0,4 s ; 0,25 s si > 25 % des PV max | inchangé ; la descente **commence à l'impact** de la chorégraphie, plus au début du temps DAMAGE |
| Impact sonore d'un gros coup | absent | `hit_heavy` [D] au repère `impact` quand le coup retire plus de `HP_BIG_HIT` |
| Trace des PV perdus | absente | segment clair qui reste 0,3 s puis rattrape la barre [CV-9] |
| PV critiques | pulsation de la carte sous 20 % | inchangé (pas d'alarme permanente : SON-17 décide du son) |
| Couleurs | vert → jaune → rouge | inchangé |
| Vibration | 30 ms, 70 ms sur un critique | 50 ms [D] sur un gros coup |

## 5. Découpage, effort et calendrier

### 5.1 Sous-jalons

Revu le 2026-10-26 après les décisions de Kevin (CV-1 : une animation par attaque ; CV-2 : durée
selon l'attaque ; CV-10 : point d'origine par espèce). Principe : d'abord un **plancher** complet
(socle, option, 17 familles, statuts et PV : toutes les attaques sont animées par leur famille),
puis les **animations propres** par lots, dans l'ordre d'exposition. Si le calendrier serre, ce qui
manque garde la version de sa famille : rien n'est jamais vide.

Validation par sous-jalon sur le S24 (règle 1, CV-14) : une session de validation de Kevin à la fin
de chaque étape, sur un **départ de débogage « galerie d'effets »** (`tools/debug_start/`) qui
enchaîne les attaques sans avoir à jouer, plus un vrai combat.

**CV.0 — Socle et Éclair** (Opus, système nouveau)

| Tâche | Contenu | Critère d'acceptation |
|---|---|---|
| T1 | `data/battle/move_fx/` (un fichier par lot) et `MoveFxCatalog` ; table de l'annexe A (famille de chaque attaque) | test : toute attaque des données a une entrée valide, une seule ; repli par type testé |
| T2 | `MoveFxOutcome`, `MoveFxPlan` (phases, repères, modes, **durée selon la puissance**, §2.6) | tests purs : touché / raté / sans effet / esquive / multi / deux tours / Métronome ; chaque attaque dans les bornes de sa ligne du tableau de CV-2 ; Rapides ≤ 0,5 s |
| T3 | `MoveFxPlayer`, `BattleCamera`, pool de particules, lumière simulée ; branchement dans `BattleStage` / `BattleDirector` | le combat joue les plans ; `speed_scale` = 0 toujours instantané (suite complète verte, aucun test de combat ralenti) |
| T4 | repères sonores (`fx_cue`) ; correction du décalage du §1.3 | test espion : le son de l'attaque part au repère `launch`, celui du coup au repère `impact` |
| T5 | réglage `battle_animations` et contrôle dans Paramètres ; modes Réduites et « Réduire les flashs » | test de `GameSettings` (aller-retour JSON, ancien fichier) ; ≤ 3 flashs/s |
| T6 | `FxAnchors` (lecture de `fx_anchors.json` posé par CV.A, repli `bouche` → `tete` → `centre`) | test pur du repli ; captures |
| T7 | familles **contact** (5 variantes), **électrique** et **feu** ; animation propre d'**Éclair** | captures Mac relues |
| T8 | départ « galerie d'effets » ; mesure `PerfProbe` sur S24 **et A17** | ≥ 58 i/s moyens en Complètes sur les deux, rapport dans `build/qa/` |
| **Validation** | Kevin sur S24 : Charge (§9), Éclair depuis les joues (§10), Flammèche ; bascule Complètes / Rapides | « ça marche, c'est lisible, c'est bien placé » (règle 3) |

**CV.1 — Plancher : toutes les familles** (Sonnet, relu par Opus)

| Tâche | Contenu | Critère |
|---|---|---|
| T9 | les 14 autres familles et les 9 modificateurs | chaque attaque de l'annexe A joue sans erreur dans la galerie (test d'intégration qui parcourt les 159 attaques présentes à `speed_scale` 0) |
| T10 | script de classement par **ordre d'exposition** (learnsets, rencontres, Dresseurs) → découpage des lots P1 à P4 | liste écrite dans ce plan (§5.1 bis) |
| T11 | série d'art « particules de combat », 1re série (≈ 20 sprites, CV-7) ; intégration de l'atlas | planche validée par Kevin (DA-6) ; mémoire de texture du combat + ≤ 4 Mo |
| **Validation** | Kevin sur S24 : galerie (≈ 10 min) + un combat de Dresseur | |

**CV.A — Points d'origine des 151 espèces** (Sonnet) — **en parallèle de CV.1**, fichiers disjoints

> **Fait le 2026-10-26** (branche `cv-a-points`) : T12 et T13 faits ; planche
> `docs/design/fiches-assets/cv-a/` **à valider par Kevin**.

| Tâche | Contenu | Critère |
|---|---|---|
| T12 | outil qui dessine les points sur chaque face (artwork) et chaque dos (cadrage B) ; points posés pour les 151 espèces, de face et de dos | `tools/art/fx_anchors_planche.py` [D] : planches à l'échelle du combat, un point coloré par nom |
| T13 | test : toute espèce de `data/pokemon/species/` a ses points ; coordonnées dans la boîte visible | |
| **Validation** | Kevin sur planche (pas sur S24) | |

**CV.3 — Statuts et PV** (Sonnet) — **en parallèle de CV.1**, fichiers disjoints (`status_aura.gd`,
carte de PV de la HUD, `ui_tokens.gd`)

| Tâche | Contenu | Critère |
|---|---|---|
| T14 | aura de poison et de Toxik, respiration du sommeil, givre, pose du statut | tests de `StatusAura` (état, réduction des animations) |
| T15 | trace des PV perdus (CV-9), `hit_heavy`, vibration du gros coup, descente calée sur l'impact | test : la barre arrive à `event.hp` ; durées inchangées en Rapides |
| T16 | respiration au repos (CV-8) ; finition de la capture (CV-11) | |
| **Validation** | Kevin sur S24, groupée avec celle de CV.1 | |

**CV.2 — Animations propres, par lots P1 à P4** (Sonnet ; Opus pour les signatures et la lumière du
monde) — **2 sessions en parallèle au plus**, une par lot, chacune dans son fichier
`data/battle/move_fx/pN.json`

| Lot | Contenu | Critère |
|---|---|---|
| P1 (≈ 40) | attaques des premières heures (starters, Routes 1 à 4, Forêt de Jade, Argenta, Azuria) + réactions du monde (lumière, gouttelettes, feuillage, arbres éclairés la nuit) | une capture par attaque relue ; 60 i/s sur A17 tenus |
| P2 (≈ 40) | milieu du jeu (Carmin à Céladopole) + 2e série d'art (≈ 15 sprites) | idem |
| P3 (≈ 40) | fin du jeu (Safrania à la Ligue) ; les signatures restantes (§3.3) | idem |
| P4 (≈ 45) | le reste (attaques rares, CT, attaques ajoutées par les J23 à J32) | idem ; **aucune attaque ne garde la version de sa famille** |
| **Validation** | Kevin sur S24 : P1 + P2 ensemble, puis P3 + P4 ensemble | |

**CV.Z — Clôture** (Sonnet) : chronométrage de 5 combats scriptés (sauvage faible, sauvage moyen,
Dresseur, Champion, capture) en Complètes et en Rapides, sur le S24 ; sauvage faible **20 à 40 s**
en Complètes ; mesure A17 ; suite complète ; fusion dans `main` ; ligne dans `etat-projet.md`.

### 5.2 Effort

| Étape | Sessions | Modèle | Temps de Kevin |
|---|---|---|---|
| CV.0 | 2 – 3 | Opus | 1 validation S24 (≈ 15 min) |
| CV.1 | 2 – 3 (+ 1 d'art) | Sonnet, relecture Opus | 1 planche + 1 validation S24 (avec CV.3) |
| CV.A | 1 – 2 | Sonnet | 1 planche (151 × 2 sprites) |
| CV.3 | 1 – 2 | Sonnet | (groupée avec CV.1) |
| CV.2 | 8 – 12 (≈ 2 à 3 par lot, + 1 d'art) | Sonnet ; Opus pour les signatures | 1 planche + 2 validations S24 (≈ 20 min) |
| CV.Z | 1 | Sonnet | — |
| **Total** | **16 à 24 sessions** | | **≈ 2 h en tout, en 4 créneaux S24 et 3 planches** |

Durée : ≈ **7 à 10 jours** avec 2 à 3 sessions en parallèle (contre 3 à 5 jours pour « familles +
13 phares »). Le chemin critique est CV.0 puis les lots de CV.2.

### 5.3 Place dans le calendrier

- **Deux dates butoirs** (application de CV-13 et de DA-7) :
  - **le plancher (CV.0, CV.1, CV.3, CV.A)** dans `main` **avant le début réel du J33** : c'est
    lui qui ajoute l'option des Paramètres et change le déroulé d'un combat ; le J33 déclare un
    « gel fonctionnel » et sa campagne T6 et son harmonisation T2 contrôlent les combats ;
  - **les lots P1 à P4** sont de la mise en scène à données constantes (aucune règle, aucune
    durée de message, aucun déclencheur) : traités comme un **lot d'art**, ils peuvent finir
    pendant le J33 et doivent être dans `main` **au gel de l'art, à l'entrée du J34** (DA-7). Un
    lot pas prêt garde la version de ses familles et passe en 1.0.x (soupape de DA-2). **Validé
    par Kevin le 2026-10-26** (« Oui, les deux », relayé par la session de coordination).
- **En parallèle des fusions J23 et J26 à J31 : oui, avec deux précautions.** Les fichiers
  touchés par les branches en cours, mesurés le 2026-10-26 :

| Fichier | Touché par | Risque pour CV |
|---|---|---|
| `game/battle/battle_stage.gd` | J23 (+49 lignes : Safari), J30 (+5) | moyen : CV y ajoute seulement le branchement du lecteur |
| `game/battle/battle_playback.gd` | J23 (+10), J27 (+3) | faible |
| `game/battle/battle_event.gd` | J27 (+4 : Riposte…) | nul (CV ne le modifie pas) |
| `game/battle/battle.gd`, `battle_ai.gd`, `battler.gd` | J27, J30 | nul (moteur) |
| `battle_director.gd`, `game/systems/settings/`, `game/systems/audio/`, `status_aura.gd` | aucune branche | nul |
| `data/pokemon/moves/` | J23, J27 à J31 (17 attaques nouvelles) | nul : le repli par type couvre une attaque nouvelle ; le test de CV la signale, une ligne de données la règle |

  1. **CV.0 part de `main` après la fusion du J23** (la plus grosse touche dans `battle_stage.gd`) ;
     s'il part avant, il intègre `jalon-23` dès sa fusion.
  2. Tout le code neuf va dans `game/battle/fx/` ; les branchements dans les fichiers partagés sont
     **courts et isolés** (une méthode, un appel). `main` est fusionné dans la branche `combat-vivant`
     avant chaque fin de sous-jalon ; une seule intégration dans `main` à la fois (levier 2).
- **Avec la phase DA** : DAF.6 (lumière) travaille sur `WorldLighting` et les profils ; CV ne
  touche ni l'un ni l'autre (lumière simulée sur le calque du combat). Vérifier la branche de DAF.6
  avant CV.2 (T12, arbres éclairés la nuit). La série d'art de CV.1 (T9) prend un créneau Codex
  comme un lot DAF ordinaire. Le « détail de combat du J9 » de DAF.8 (voile du poison) est couvert
  par CV.3.
- **Jalons actifs** : CV compte comme un jalon actif (2 à 3 au plus, levier 2). Il peut prendre
  la place d'un jalon de contenu qui vient de fusionner.

### 5.4 Risques

| Risque | Parade |
|---|---|
| L'A17 perd des images en combat | mesure dès CV.0 ; plafonds dans les données ; Économie divise les particules ; pas de recopie d'écran |
| Combats trop longs | plafonds de durée testés (T2) ; chronométrage CV.Z ; mode Rapides |
| Flashs gênants | « Réduire les flashs » toujours respecté, ≤ 3 flashs/s, lumière plafonnée |
| Conflits avec les fusions de jalons | §5.3 : code neuf dans `fx/`, branchements courts, départ après le J23 |
| Art refusé ou en retard | formes procédurales d'abord ; l'atlas remplace à l'identique |
| Tests de combat ralentis | `speed_scale` = 0 rend tout instantané, comme aujourd'hui ; la galerie tourne à 0 dans la suite |

## 6. Prochaine étape

Arbitrages CV-1 à CV-14 et dates butoirs du §5.3 validés par Kevin le 2026-10-26. CV.A (points
d'origine, données seules) commence tout de suite, hors de la scène de combat. Ensuite : une session neuve code **CV.0** dans son propre worktree
(branche `combat-vivant` depuis `main`, après la fusion du J23), avec le prompt de reprise
proposé à Kevin.

## Annexe A — Toutes les attaques et leur famille

165 attaques : 159 présentes dans les données (colonne « Source » : `main` ou la branche qui
l'ajoute) et 6 absentes à ce jour (« absente »). « Impact » : variante de la famille Contact.
« Modificateurs » : lus dans les effets de l'attaque. « Phare » : signature du §3.3 (brique neuve). Toutes les attaques auront leur animation propre
(CV-1) ; la famille sert de briques et de plancher. Cette table est la proposition de départ de
`data/battle/move_fx/` (T1) ; Kevin peut y changer une ligne
sans arbitrage.

| id | Nom | Type | Cat. | Famille | Impact | Modificateurs | Phare | Source |
|---|---|---|---|---|---|---|---|---|
| `absorb` | Vol-Vie | Plante | spé. | plante |  | drain |  | main |
| `acid` | Acide | Poison | spé. | poison |  |  |  | main |
| `acid_armor` | Acidarmure | Poison | statut | statut_plus |  |  |  | main |
| `agility` | Hâte | Psy | statut | statut_plus |  |  |  | main |
| `amnesia` | Amnésie | Psy | statut | statut_plus |  |  |  | main |
| `aurora_beam` | Onde Boréale | Glace | spé. | glace |  |  |  | main |
| `barrage` | Pilonnage | Normal | phys. | contact | corps | multi |  | main |
| `barrier` | Bouclier | Psy | statut | statut_plus |  |  |  | main |
| `bide` | Patience | Normal | statut | contact | corps |  |  | main |
| `bind` | Étreinte | Normal | phys. | contact | corps | piege |  | main |
| `bite` | Morsure | Ténèbres | phys. | contact | crocs |  |  | main |
| `blizzard` | Blizzard | Glace | spé. | glace |  |  | **oui** | main |
| `body_slam` | Plaquage | Normal | phys. | contact | corps |  |  | main |
| `bone_club` | Massd'Os | Sol | phys. | sol_roche |  |  |  | main |
| `bonemerang` | Osmerang | Sol | phys. | sol_roche |  | multi |  | main |
| `bubble` | Écume | Eau | spé. | eau |  |  |  | main |
| `bubble_beam` | Bulles d'O | Eau | spé. | eau |  |  |  | main |
| `clamp` | Claquoir | Eau | phys. | eau |  | piege |  | main |
| `comet_punch` | Poing Comète | Normal | phys. | contact | coup | multi |  | main |
| `confuse_ray` | Onde Folie | Spectre | statut | spectre |  |  |  | main |
| `confusion` | Choc Mental | Psy | spé. | psy |  |  |  | main |
| `constrict` | Constriction | Normal | phys. | contact | corps |  |  | main |
| `conversion` | Conversion | Normal | statut | statut_plus |  |  |  | absente |
| `counter` | Riposte | Combat | statut | contact | corps |  |  | jalon-27 |
| `crabhammer` | Pince-Masse | Eau | phys. | eau |  |  |  | main |
| `cut` | Coupe | Normal | phys. | contact | griffe |  |  | main |
| `defense_curl` | Boul'Armure | Normal | statut | statut_plus |  |  |  | main |
| `dig` | Tunnel | Sol | phys. | sol_roche |  | charge |  | main |
| `disable` | Entrave | Normal | statut | statut_moins |  |  |  | main |
| `dizzy_punch` | Uppercut | Normal | phys. | contact | coup |  |  | main |
| `double_edge` | Damoclès | Normal | phys. | contact | corps | contrecoup |  | main |
| `double_kick` | Double Pied | Combat | phys. | contact | coup | multi |  | main |
| `double_slap` | Torgnoles | Normal | phys. | contact | coup | multi |  | main |
| `double_team` | Reflet | Normal | statut | statut_plus |  |  |  | jalon-23 |
| `dragon_rage` | Draco-Rage | Dragon | statut | dragon |  |  |  | main |
| `dream_eater` | Dévorêve | Psy | spé. | psy |  | drain |  | main |
| `drill_peck` | Bec Vrille | Vol | phys. | vent |  |  |  | main |
| `earthquake` | Séisme | Sol | phys. | sol_roche |  |  | **oui** | main |
| `egg_bomb` | Bomb'Œuf | Normal | phys. | contact | corps |  |  | jalon-23 |
| `ember` | Flammèche | Feu | spé. | feu |  |  |  | main |
| `explosion` | Explosion | Normal | phys. | energie |  | auto_ko | **oui** | main |
| `fire_blast` | Déflagration | Feu | spé. | feu |  |  | **oui** | main |
| `fire_punch` | Poing de Feu | Feu | phys. | feu |  |  |  | main |
| `fire_spin` | Danse Flamme | Feu | spé. | feu |  | piege |  | main |
| `fissure` | Abîme | Sol | statut | sol_roche |  | ko_un_coup |  | jalon-28 |
| `flamethrower` | Lance-Flammes | Feu | spé. | feu |  |  | **oui** | main |
| `flash` | Flash | Normal | statut | statut_moins |  |  |  | main |
| `fly` | Vol | Vol | phys. | vent |  | charge |  | main |
| `focus_energy` | Puissance | Normal | statut | statut_plus |  |  |  | main |
| `fury_attack` | Furie | Normal | phys. | contact | percant | multi |  | main |
| `fury_swipes` | Combo-Griffe | Normal | phys. | contact | griffe | multi |  | main |
| `glare` | Regard Médusant | Normal | statut | statut_moins |  |  |  | main |
| `growl` | Rugissement | Normal | statut | son |  |  |  | main |
| `growth` | Croissance | Normal | statut | statut_plus |  |  |  | main |
| `guillotine` | Guillotine | Normal | statut | contact | griffe | ko_un_coup |  | main |
| `gust` | Tornade | Vol | spé. | vent |  |  |  | main |
| `harden` | Armure | Normal | statut | statut_plus |  |  |  | main |
| `haze` | Buée Noire | Glace | statut | glace |  |  |  | main |
| `headbutt` | Coup d'Boule | Normal | phys. | contact | corps |  |  | main |
| `hi_jump_kick` | Pied Voltige | Combat | phys. | contact | coup | chute |  | jalon-27 |
| `horn_attack` | Koud'Korne | Normal | phys. | contact | percant |  |  | main |
| `horn_drill` | Empal'Korne | Normal | statut | contact | percant | ko_un_coup |  | main |
| `hydro_pump` | Hydrocanon | Eau | spé. | eau |  |  | **oui** | main |
| `hyper_beam` | Ultralaser | Normal | spé. | energie |  | recharge | **oui** | main |
| `hyper_fang` | Croc de Mort | Normal | phys. | contact | crocs |  |  | main |
| `hypnosis` | Hypnose | Psy | statut | psy |  |  |  | main |
| `ice_beam` | Laser Glace | Glace | spé. | glace |  |  |  | main |
| `ice_punch` | Poing-Glace | Glace | phys. | glace |  |  |  | jalon-27 |
| `jump_kick` | Pied Sauté | Combat | phys. | contact | coup | chute |  | jalon-27 |
| `karate_chop` | Poing Karaté | Combat | phys. | contact | coup |  |  | main |
| `kinesis` | Télékinésie | Psy | statut | statut_moins |  |  |  | jalon-27 |
| `leech_life` | Vampirisme | Insecte | phys. | contact | percant | drain |  | main |
| `leech_seed` | Vampigraine | Plante | statut | plante |  |  |  | main |
| `leer` | Groz'Yeux | Normal | statut | statut_moins |  |  |  | main |
| `lick` | Léchouille | Spectre | phys. | spectre |  |  |  | main |
| `light_screen` | Mur Lumière | Psy | statut | statut_plus |  |  |  | main |
| `lovely_kiss` | Grobisou | Normal | statut | statut_moins |  |  |  | jalon-30 |
| `low_kick` | Balayage | Combat | phys. | contact | coup |  |  | main |
| `meditate` | Yoga | Psy | statut | statut_plus |  |  |  | main |
| `mega_drain` | Méga-Sangsue | Plante | spé. | plante |  | drain |  | main |
| `mega_kick` | Ultimawashi | Normal | phys. | contact | coup |  |  | jalon-27 |
| `mega_punch` | Ultimapoing | Normal | phys. | contact | coup |  |  | main |
| `metronome` | Métronome | Normal | statut | statut_plus |  |  |  | main |
| `mimic` | Copie | Normal | statut | statut_plus |  |  |  | absente |
| `minimize` | Lilliput | Normal | statut | statut_plus |  |  |  | main |
| `mirror_move` | Mimique | Vol | statut | statut_plus |  |  |  | main |
| `mist` | Brume | Glace | statut | statut_plus |  |  |  | main |
| `night_shade` | Ténèbres | Spectre | statut | spectre |  |  |  | main |
| `pay_day` | Jackpot | Normal | phys. | contact | coup |  |  | main |
| `peck` | Picpic | Vol | phys. | vent |  |  |  | main |
| `petal_dance` | Danse Fleur | Plante | spé. | plante |  |  |  | main |
| `pin_missile` | Dard-Nuée | Insecte | phys. | contact | percant | multi |  | main |
| `poison_gas` | Gaz Toxik | Poison | statut | poison |  |  |  | main |
| `poison_powder` | Poudre Toxik | Poison | statut | poison |  |  |  | main |
| `poison_sting` | Dard-Venin | Poison | phys. | poison |  |  |  | main |
| `pound` | Écras'Face | Normal | phys. | contact | coup |  |  | main |
| `psybeam` | Rafale Psy | Psy | spé. | psy |  |  |  | main |
| `psychic` | Psyko | Psy | spé. | psy |  |  | **oui** | main |
| `psywave` | Vague Psy | Psy | statut | psy |  |  |  | jalon-27 |
| `quick_attack` | Vive-Attaque | Normal | phys. | contact | corps |  |  | main |
| `rage` | Frénésie | Normal | phys. | contact | corps |  |  | main |
| `razor_leaf` | Tranch'Herbe | Plante | phys. | plante |  |  |  | main |
| `razor_wind` | Coupe-Vent | Normal | spé. | vent |  | charge |  | absente |
| `recover` | Soin | Normal | statut | soin |  |  |  | main |
| `reflect` | Protection | Psy | statut | statut_plus |  |  |  | main |
| `rest` | Repos | Psy | statut | soin |  |  |  | main |
| `roar` | Hurlement | Normal | statut | son |  |  |  | main |
| `rock_slide` | Éboulement | Roche | phys. | sol_roche |  |  |  | absente |
| `rock_throw` | Jet-Pierres | Roche | phys. | sol_roche |  |  |  | main |
| `rolling_kick` | Mawashi Geri | Combat | phys. | contact | coup |  |  | jalon-27 |
| `sand_attack` | Jet de Sable | Sol | statut | statut_moins |  |  |  | main |
| `scratch` | Griffe | Normal | phys. | contact | griffe |  |  | main |
| `screech` | Grincement | Normal | statut | son |  |  |  | main |
| `seismic_toss` | Frappe Atlas | Combat | statut | contact | corps |  |  | main |
| `self_destruct` | Destruction | Normal | phys. | energie |  | auto_ko | **oui** | main |
| `sharpen` | Affûtage | Normal | statut | statut_plus |  |  |  | absente |
| `sing` | Berceuse | Normal | statut | son |  |  |  | main |
| `skull_bash` | Coud'Krâne | Normal | phys. | contact | corps | charge |  | main |
| `sky_attack` | Piqué | Vol | phys. | vent |  | charge |  | jalon-29 |
| `slam` | Souplesse | Normal | phys. | contact | corps |  |  | main |
| `slash` | Tranche | Normal | phys. | contact | griffe |  |  | main |
| `sleep_powder` | Poudre Dodo | Plante | statut | plante |  |  |  | main |
| `sludge` | Détritus | Poison | spé. | poison |  |  |  | main |
| `smog` | Purédpois | Poison | spé. | poison |  |  |  | main |
| `smokescreen` | Brouillard | Normal | statut | statut_moins |  |  |  | main |
| `soft_boiled` | E-Coque | Normal | statut | soin |  |  |  | absente |
| `solar_beam` | Lance-Soleil | Plante | spé. | plante |  | charge | **oui** | main |
| `sonic_boom` | Sonicboom | Normal | statut | son |  |  |  | main |
| `spike_cannon` | Picanon | Normal | phys. | contact | percant | multi |  | main |
| `splash` | Trempette | Normal | statut | statut_plus |  |  |  | main |
| `spore` | Spore | Plante | statut | plante |  |  |  | main |
| `stomp` | Écrasement | Normal | phys. | contact | coup |  |  | main |
| `strength` | Force | Normal | phys. | contact | corps |  |  | main |
| `string_shot` | Sécrétion | Insecte | statut | statut_moins |  |  |  | main |
| `struggle` | Lutte | Normal | phys. | contact | corps | contrecoup |  | main |
| `stun_spore` | Para-Spore | Plante | statut | plante |  |  |  | main |
| `submission` | Sacrifice | Combat | phys. | contact | corps | contrecoup |  | main |
| `substitute` | Clonage | Normal | statut | statut_plus |  |  |  | jalon-27 |
| `super_fang` | Croc Fatal | Normal | statut | contact | crocs |  |  | main |
| `supersonic` | Ultrason | Normal | statut | son |  |  |  | main |
| `surf` | Surf | Eau | spé. | eau |  |  | **oui** | main |
| `swift` | Météores | Normal | spé. | energie |  |  |  | main |
| `swords_dance` | Danse-Lames | Normal | statut | statut_plus |  |  |  | main |
| `tackle` | Charge | Normal | phys. | contact | corps |  |  | main |
| `tail_whip` | Mimi-Queue | Normal | statut | statut_moins |  |  |  | main |
| `take_down` | Bélier | Normal | phys. | contact | corps | contrecoup |  | main |
| `teleport` | Téléport | Psy | statut | statut_plus |  |  |  | main |
| `thrash` | Mania | Normal | phys. | contact | corps |  |  | main |
| `thunder` | Fatal-Foudre | Électrik | spé. | electrique |  |  | **oui** | main |
| `thunder_punch` | Poing-Éclair | Électrik | phys. | electrique |  |  |  | jalon-27 |
| `thunder_shock` | Éclair | Électrik | spé. | electrique |  |  | **oui** | main |
| `thunder_wave` | Cage-Éclair | Électrik | statut | electrique |  |  |  | main |
| `thunderbolt` | Tonnerre | Électrik | spé. | electrique |  |  | **oui** | main |
| `toxic` | Toxik | Poison | statut | poison |  |  |  | jalon-23 |
| `transform` | Morphing | Normal | statut | statut_plus |  |  |  | jalon-31 |
| `tri_attack` | Triplattaque | Normal | spé. | energie |  |  |  | main |
| `twineedle` | Double-Dard | Insecte | phys. | contact | percant | multi |  | main |
| `vine_whip` | Fouet Lianes | Plante | phys. | plante |  |  |  | main |
| `vise_grip` | Force Poigne | Normal | phys. | contact | griffe |  |  | main |
| `water_gun` | Pistolet à O | Eau | spé. | eau |  |  |  | main |
| `waterfall` | Cascade | Eau | phys. | eau |  |  |  | main |
| `whirlwind` | Cyclone | Normal | statut | vent |  |  |  | main |
| `wing_attack` | Cru-Ailes | Vol | phys. | vent |  |  |  | main |
| `withdraw` | Repli | Eau | statut | statut_plus |  |  |  | main |
| `wrap` | Ligotage | Normal | phys. | contact | corps | piege |  | main |

