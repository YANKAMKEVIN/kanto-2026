# Jalon « Son » — musique, cris, bruitages, ambiances

> **PLAN — aucun code n'est écrit par ce document, aucun fichier son n'est téléchargé.**
> Claude, 2026-10-24. Arbitrages pour Kevin : `docs/design/passes/son-arbitrages-kevin.md`
> (**SON-1 à SON-17 validés par Kevin le 2026-10-24, toutes les recommandations**). Le
> sous-jalon Son.0 (logique pure, sans aucun fichier son) peut démarrer.
>
> Sources : `etat-projet.md` « Décision de Kevin — son (2026-10-24) » ; `vision.md` (principe 6 :
> « Chaque ville a une identité visuelle et sonore reconnaissable » ; phase 10 « Ambiance ») ;
> `roadmap.md` (6F Paramètres : audio, musique, vibrations) ; `phase-da-cadrage.md` (DA-8 : audio à
> part) ; `strategie-acceleration.md` ; plans `jalon-33.md` et `jalon-34.md` (branche `jalon-31`).
> Données relues sur `origin/main` (`f7ba8f31`) et sur les branches `jalon-23`, `jalon-26` à
> `jalon-31` (`git grep`). Faits Rouge/Bleu : `pret/pokered`, `data/maps/songs.asm` (relu le
> 2026-10-24). Pistes de Let's Go : album officiel « Pokémon: Let's Go, Pikachu! & Pokémon: Let's
> Go, Eevee! Super Music Collection » (2018), fiche MusicBrainz
> `49c36362-5b60-4e92-bdc9-4c97240a16c3` (122 pistes : **67 de Let's Go** + 55 de Jaune).
>
> Origine des règles : **RB** Rouge/Bleu · **LG** Let's Go · **K26** adaptation Kanto 2026 ·
> **[D]** valeur par défaut (règle 4).

## 0. État des lieux (vérifié le 2026-10-24)

| Domaine | Réel aujourd'hui | Manque |
|---|---|---|
| Fichiers | `assets/audio/` ne contient que `.gitkeep` ; aucun `.ogg`, `.wav`, `.mp3` dans `game/`, `data/`, `project.godot` | Tout |
| Code | **aucun** `AudioStreamPlayer` ni `AudioServer` dans `game/` ; `game/systems/audio/` **vide** | Moteur complet |
| Points d'accroche déjà posés | `GameMap.music: StringName` (`game/world/map.gd:41`, toujours vide) ; `EncounterDirector.cry_requested(species_id)` (3 appels) ; `BattleDirector.battle_started / battle_finished / pokemon_caught / event_played` ; `BattleEvent.Kind` (≈ 70 sortes : `MOVE_USED`, `DAMAGE`, `FAINTED`, `BALL_SHAKE`, `CAUGHT`, `LEVEL_UP`…) ; `Haptics` (porte unique des vibrations, modèle à copier) ; signaux des dalles et de l'ascenseur (J20 : `slide_started`, `ride_started`) ; Poké Flûte (J21, `FluteNotes` visuel seul) | Les brancher |
| Réglages | `GameSettings` + `SettingsStore` (`user://settings.json`, **séparé de la sauvegarde**, v1 ; champ absent → défaut) ; catégories JEU, COMMANDES, GRAPHISMES, ACCESSIBILITÉ ; **pas d'AUDIO** (J6, Q-17 : « absent tant qu'il n'y a pas de système ») | Catégorie SON |
| Android | `SessionLifecycle` / `SaveCheckpoint` : `APPLICATION_PAUSED`, `FOCUS_OUT` (bandeau d'appel), `WM_CLOSE_REQUEST` déjà gérés pour la sauvegarde | Couper / reprendre le son |
| Poids | APK debug actuel **≈ 262 Mo** (`build/kanto2026-debug.apk`, 2026-10-23) | Budget audio |
| Licences | `jalon-34.md` T6 : « Inventaire complet des sprites, **musiques**, polices, art généré » | Lignes audio |

Les reports « au jalon audio » relevés dans les plans : sons des dalles et de l'ascenseur (J20 §16),
cris et mélodie de la Flûte, thème de la Tour purifiée (J21), musique du Vélo (J22 §5), son de
poussée des rochers (S2D), pierres qui roulent (J12), machine de Léo (J14), musique d'évolution
(J9 n° 9, dossier 04 §7).

## 1. Moteur

### 1.1 Principes

- **Logique séparée de la présentation** (règle 8) : tout ce qui décide (quel morceau, quelle
  priorité, quel volume, faut-il couper) est en classes `RefCounted` pures, testées sans scène.
  La présentation (lecteurs, bus, fondus) est un seul nœud, l'autoload `Audio`, qui **exécute**.
- **Données dans des fichiers** (règle 7) : `data/audio/*.json`. Aucun nom de fichier son dans le
  code ni dans les `.tscn`.
- **Porte unique** comme `Haptics` : tout le jeu passe par `Audio` ; un **espion** (`sink`)
  remplace les lecteurs dans les tests ; sous GUT et dans les outils, aucun son réel.
- **Muet tolérant** : un morceau ou un bruitage absent du disque n'est **jamais** une erreur de
  jeu (avertissement unique en debug, silence) ; le jeu reste jouable sans aucun fichier son.
  C'est ce qui permet de livrer le moteur avant les fichiers.

### 1.2 Fichiers

```
game/autoload/audio.gd                 autoload « Audio » (présentation : lecteurs, bus, fondus)
game/systems/audio/audio_library.gd    lecture et validation de data/audio/*.json
game/systems/audio/music_selector.gd   carte / zone / état → morceau (pur)
game/systems/audio/music_stack.gd      couches et priorités, reprise (pur)
game/systems/audio/sfx_catalog.gd      identifiant de bruitage → fichier, bus, variantes (pur)
game/systems/audio/cry_catalog.gd      espèce → cri (pur)
game/systems/audio/volume_math.gd      curseur 0–100 → dB, coupure (pur)
game/systems/audio/audio_bridge.gd     branchements Boot ↔ signaux du jeu (seul fichier « collant »)
data/audio/tracks.json                 morceaux : fichier, boucle, volume propre, titre LG
data/audio/music_zones.json            zone → morceau ; exceptions par carte ; surf, vélo
data/audio/battle_music.json           Dresseur / catégorie → musique de combat et de victoire
data/audio/sfx.json                    bruitages
data/audio/ambiences.json              zone ou carte → boucle d'ambiance
default_bus_layout.tres                bus (§1.3)
assets/audio/music/ · sfx/ · cries/ · ambience/
tests/unit/audio/ · tests/integration/audio/
```

**Pourquoi un fichier `music_zones.json` plutôt que `GameMap.music`** : renseigner l'export de la
carte toucherait ≈ 220 `.tscn` sur `main` **et** sur les sept branches ouvertes (conflits garantis).
Le fichier de données s'appuie sur `data/world/zones.json` (qui regroupe déjà les cartes par zone)
et ne touche aucune carte. `GameMap.music` reste comme **surcharge** facultative (vide partout), lue
en premier si elle est posée.

### 1.3 Bus

`Master` → `Music`, `Ambience`, `Sfx` (interface, déplacement, combat), `Cries`. Un curseur des
Paramètres pilote un bus (§1.9). **Atténuation** (« ducking ») de `Music` : −6 dB [D] pendant un cri
de combat, une attaque spéciale ou un dialogue de Grand moment, par un fondu de 0,15 s [D] ; sans
effet de bus coûteux (pas de compresseur sidechain : un simple réglage de volume, moins cher sur
mobile).

### 1.4 Musique par zone, fondus enchaînés

- `MusicSelector.track_for(map_id, state)` : surcharge de carte (`GameMap.music`) → exception de
  carte (`music_zones.json` `maps`) → morceau de la zone (`zones`) → silence. `state` porte le
  **mode de déplacement** (à pied, Vélo, Surf : `music_zones.json` `surf` / `bike` priment sur la
  zone, comme RB) et quelques drapeaux (Tour purifiée, §2.4).
- Changement de carte : **même morceau → il continue sans coupure** (entrer dans une maison de
  Bourg Palette ne relance pas le thème) ; morceau différent → fondu enchaîné 0,6 s [D] (sortie
  0,4 s, entrée 0,6 s, chevauchement), calé sur l'écran noir du raccord.
- Deux lecteurs `AudioStreamPlayer` sur le bus `Music`, qui alternent (A/B) : simple, testable,
  sans dépendre d'`AudioStreamInteractive`.
- **Boucles** : OGG Vorbis avec `loop = true` et `loop_offset` (secondes) lus dans `tracks.json`
  (l'intro joue une fois, la boucle ensuite). Les pistes d'album finissent en fondu après deux
  tours : il faut les **couper à la boucle** une fois (outil `tools/audio/`, §1.11, SON-3).

### 1.5 Priorités (pile de couches)

`MusicStack` garde une pile ; la couche la plus haute joue, les autres attendent.

| Rang | Couche | Exemples | Fin |
|---|---|---|---|
| 1 | **Zone** | route, ville, grotte | toujours là |
| 2 | **Scène** | apparition du rival, Rocket, Chen « Attends ! », Ossatueur, Flûte | étape de cinématique qui l'arrête, ou fin de la cinématique |
| 3 | **Combat** | sauvage, Dresseur, Champion, rival final | fin du combat (puis jingle de victoire) |
| 4 | **Jingle** | soin, objet, objet clé, Badge, capture, évolution, montée de niveau | fin du jingle (durée du fichier) |

- Un **jingle** suspend la couche du dessous (pause, pas d'arrêt) puis la **reprend à la même
  position** : c'est le comportement RB du Centre Pokémon.
- **Après un combat** : la zone reprend **à la position où elle était** (SON-6, recommandé) avec
  un fondu d'entrée de 1 s [D] ; si la carte a changé pendant le combat (défaite → Centre), le
  morceau de la nouvelle carte part du début.
- **Évolution** (en fin de combat ou à l'échange) : « Evolution » remplace tout, puis
  « Congratulations! Your Pokémon Evolved! », puis retour à la couche du dessous ; annulation de
  l'évolution → jingle coupé, retour direct.
- **Grand moment** (`moment` de cinématique, carte de Champion) : pas de morceau propre [D] ; la
  musique est atténuée pendant la carte.

### 1.6 Ambiances en boucle

Bus `Ambience`, un lecteur, fondu 1 s [D] au changement. `ambiences.json` : zone ou carte → boucle
(mer, vent, forêt, grotte, ville, Casino, navire, pluie de la météo déjà codée). **Peu et discret** :
la musique RB/LG porte l'identité ; l'ambiance la soutient (−18 dB [D] sous la musique). Liste au
§3.4.

### 1.7 Bruitages

- `Audio.play_sfx(id, options)` : `sfx.json` donne fichier(s), bus, volume, **variantes** tirées au
  hasard (pas, coups) et **limite de polyphonie** par identifiant (2 [D] : pas de pas qui
  s'empilent). Petit pool de 8 lecteurs [D] sur `Sfx`.
- **Interface** : branchés sur les composants communs (bouton, onglet, case, curseur, ouverture et
  fermeture du menu, refus, page de dialogue suivante) — **une** accroche par composant de
  `game/ui/components`, pas par écran.
- **Déplacement** : pas selon le sol (herbe, sol dur, intérieur, sable, eau peu profonde) **à la
  case**, cogner un mur (RB), saut de rebord, porte, escalier, warp, Surf (entrée), Vélo (sonnette),
  Coupe, Force (rocher qui glisse), Flash, dalles, ascenseur, trou (chute).
- **Combat** : par `BattleEvent.Kind`, dans `event_played` : envoi, rappel, coup normal / super
  efficace / pas très efficace, raté, K.O., stat qui monte / baisse, statut infligé (5 sons),
  Ball lancée / secousse / capture / évasion, XP qui monte, montée de niveau, fuite. **Attaques** :
  par **famille** (≈ 20, type × physique / spécial), pas une par attaque (SON-11).

### 1.8 Cris

- `CryCatalog.path_for(species_id)` → `assets/audio/cries/<numéro>.ogg` (numéro national, celui
  des fichiers PokeAPI). Version `latest` ou `legacy` : SON-1.
- **En combat** : à l'envoi (les deux camps) et au K.O. (cri ralenti et grave, comme RB : lecture
  à `pitch_scale` 0,8 [D]) ; la musique est atténuée (§1.3).
- **Rencontre** : `cry_requested` existant (Pokémon d'ambiance et rencontres).
- **Pokédex** : bouton « Cri » sur la fiche d'une espèce **capturée** (vue seule : SON-12).
- **Compagnon** : cri quand on lui parle (interaction existante du J11) ; jamais en boucle
  automatique.
- **Écran d'évolution** : cri de l'ancienne forme au début, de la nouvelle à la fin (RB).

### 1.9 Paramètres et sauvegarde des volumes

- Nouvelle catégorie **SON** dans `SettingsViews` (et dans les Paramètres de l'écran titre, qui
  passent par le même `setting_changed`). Contenu proposé (SON-7) : **Musique**, **Effets**
  (interface, déplacement, combat, ambiances), **Cris**, curseurs 0–100 par crans de 10 ;
  défauts **70 / 80 / 80** [D].
- Champs `music_volume`, `sfx_volume`, `cry_volume` dans `GameSettings` (flottants 0–1),
  écrits dans **`user://settings.json`** (pas dans la sauvegarde de partie). `GameSettings.from_dict`
  met déjà un champ absent à sa valeur par défaut : **pas de changement de version** du fichier de
  réglages (v1 reste lisible), seulement un test de relecture d'un ancien fichier.
- `VolumeMath` : 0 → bus **coupé** (`set_bus_mute`), sinon `linear_to_db` sur une courbe douce
  (`x²`, [D]) pour que 50 % s'entende « à moitié ».
- Appliqué par `SettingsApplier` (existant) au démarrage et à chaque changement ; un cran du
  curseur Effets joue un bruitage de test, un cran du curseur Cris joue le cri de Pikachu [D].

### 1.10 Android

- **Mise en arrière-plan** (`APPLICATION_PAUSED`) : `Master` coupé immédiatement ; à
  `APPLICATION_RESUMED`, fondu d'entrée de 0,5 s [D]. **Appel ou bandeau** (`FOCUS_OUT` sans
  pause) : musique et ambiance atténuées à −20 dB [D], rétablies au `FOCUS_IN`. Même source
  d'événements que `SaveCheckpoint` (aucune nouvelle notification à écouter).
- **Sourdine** : le jeu sort sur le flux « multimédia » d'Android ; il suit le volume multimédia
  et le mode Ne pas déranger du téléphone, sans chercher à lire le mode silencieux (Godot ne
  l'expose pas). À vérifier sur S24 : un appel entrant, un réveil, une vidéo d'une autre appli
  (le jeu ne doit pas jouer par-dessus après le retour à l'accueil).
- **Casque débranché** : aucune API Godot ; pas traité (noté pour le J34).
- Démarrage : la première musique part **après** le premier rendu de l'écran titre (pas pendant
  l'écran de démarrage) pour ne pas allonger le lancement.

### 1.11 Format, poids de l'APK, outils

- **OGG Vorbis** partout (lecture en flux par Godot, boucle native, petit). Musique stéréo
  44,1 kHz, qualité Vorbis **q3 ≈ 112 kb/s** [D] (SON-8) ; bruitages et cris mono, q4.
- **Budget** (estimation, à mesurer à SonA) : ≈ 40 morceaux en boucle et 12 jingles (§2), une boucle de 1 min 30
  à 2 min 30 + intro → **≈ 60 à 90 Mo** de musique à q3 ; cris **2,05 Mo** (`latest`, 151 fichiers,
  mesuré le 2026-10-24 sur la liste du dépôt `PokeAPI/cries`, sans téléchargement ; `legacy` :
  0,92 Mo) ; bruitages ≈ 150 fichiers × 15 Ko ≈ **2 à 3 Mo** ; ambiances ≈ 10 boucles de 30 s
  ≈ **5 Mo**. Total **≈ 70 à 100 Mo** ajoutés à l'APK (≈ 262 Mo aujourd'hui, debug).
- Import Godot : musique et ambiances en flux (`AudioStreamOggVorbis`, défaut), bruitages courts
  chargés une fois (`preload` par `SfxCatalog` à l'entrée en combat, libérés à la sortie).
- Outils (`tools/audio/`, hors export) : `measure_audio.py` (poids, durée, crêtes, volume perçu
  LUFS par fichier, contrôle des boucles) ; `cut_loop.md` (procédure de découpe d'une piste d'album
  à sa boucle, avec un outil local au choix de Kevin, SON-3) ; **normalisation** à −16 LUFS [D] pour
  la musique, pour que deux morceaux n'aient pas des volumes très différents.
- `export_presets.cfg` : rien à changer (`assets/` est exporté) ; vérifier que `tools/audio/` reste
  exclu.

### 1.12 Tests GUT

- **Unitaires (sans scène)** : `MusicSelector` (zone, exception de carte, surcharge, Surf / Vélo,
  drapeau de la Tour, carte inconnue → silence) ; `MusicStack` (empilement, jingle qui reprend à la
  position, combat puis victoire puis zone, changement de carte pendant le combat, évolution
  annulée) ; `VolumeMath` (0 = coupé, 100 = 0 dB, monotonie) ; `GameSettings` (nouveaux champs,
  ancien `settings.json` sans eux → défauts, valeurs hors bornes refusées) ; `AudioLibrary`
  (chaque carte de `zones.json` a une musique ou une exception explicite `silence`, chaque morceau
  référencé existe dans `tracks.json`, aucun identifiant inconnu) ; `CryCatalog` (151 espèces) ;
  `SfxCatalog` (polyphonie, variantes).
- **Intégration (avec l'espion `sink`)** : changement de carte → bon morceau, même morceau sans
  relance ; rencontre → combat → victoire → reprise ; soin au Centre → jingle → reprise ; Paramètres
  → volume des bus ; `APPLICATION_PAUSED` → coupé, `RESUMED` → rétabli.
- **Contrôle des données** (comme les `plan_check_*.py`) : `tools/audio/check_audio_data.py` — toute
  carte de toutes les branches fusionnées est couverte ; tout fichier référencé existe **ou** est
  déclaré « attendu » (le jeu reste muet tolérant).
- Ciblés pendant les tâches (`tools/test.sh -f audio,settings`), suite complète avant la fusion.

## 2. Table des morceaux

**Règle de base** (SON-4, recommandée) : la musique d'une carte est celle que **Rouge/Bleu** lui
donne (`songs.asm`), jouée dans son **arrangement Let's Go**. RB partage beaucoup de thèmes
(Jadielle, Argenta et Safrania ont le même ; Azuria et Parmanie aussi) : c'est fidèle, et c'est
aussi ce que fait Let's Go. Titres LG : noms anglais exacts de l'album (MusicBrainz).

### 2.1 Correspondance des thèmes RB → pistes LG

| Thème RB (`MUSIC_…`) | Piste Let's Go | Remarque |
|---|---|---|
| `PALLET_TOWN` | **Pallet Town Theme** | |
| `OAKS_LAB` | **Professor Oak's Laboratory** | |
| `ROUTES1` | **Road to Viridian City: Leaving Pallet Town** | |
| `CITIES1` | **Pewter City Theme** | Jadielle, Argenta, Safrania et beaucoup de postes |
| `DUNGEON2` | **Viridian Forest** | aussi Cave Taupiqueur, Îles Écume |
| `POKECENTER` | **Pokémon Center** | aussi toutes les Boutiques et le grand magasin |
| `GYM` | **Pokémon Gym** | |
| `ROUTES3` | **Road to Cerulean City: Leaving Mt. Moon** | |
| `DUNGEON3` | **Caves of Mt. Moon** | aussi Grotte Sombre, Route Victoire |
| `CITIES2` | **Cerulean City Theme** | Azuria et Parmanie |
| `ROUTES2` | **To Bill: Leaving Cerulean City** | Routes 24, 25 |
| `VERMILION` | **Vermilion City Theme** | |
| `SS_ANNE` | **The S.S. Anne** | |
| `ROUTES4` | **Road to Lavender Town: Leaving Vermilion City** | Routes 11 à 15 |
| `LAVENDER` | **Lavender Town Theme** | |
| `POKEMON_TOWER` | **Pokémon Tower** | |
| `CELADON` | **Celadon City Theme** | |
| `GAME_CORNER` | **Game Corner** | |
| `DUNGEON1` | **Rocket Hideout** | aussi Centrale, Grotte Azurée |
| `SILPH_CO` | **Silph Co.** | |
| `CINNABAR` | **Cinnabar Island Theme** | |
| `CINNABAR_MANSION` | **Pokémon Mansion** | |
| `INDIGO_PLATEAU` | **The Final Road** | **à confirmer à l'écoute** (titre le plus probable du thème Route 23 / Plateau Indigo) |
| `SURFING` | **The Sea** | prime sur la zone quand le joueur surfe (Routes 19 à 21) |
| `BIKE_RIDING` | — **absent de LG** (pas de Vélo) | SON-5 |
| `SAFARI_ZONE` | — **absent de LG** (Parc GO à la place) | SON-5 |

### 2.2 Cartes — `main` (161 cartes) et branches ouvertes

| Zone (`zones.json`) | Cartes | Morceau | Écart ou doute |
|---|---|---|---|
| Bourg Palette | `pallet_town`, `player_house_1f/2f`, `rival_house` | Pallet Town Theme | |
| | `oak_lab` | Professor Oak's Laboratory | |
| Route 1 | `route_1` | Road to Viridian City | |
| Jadielle | `viridian_city`, `viridian_center`, `viridian_mart` | Pewter City Theme ; Centre et Boutique : Pokémon Center | |
| | `viridian_gym` (**J28**) | Pokémon Gym | |
| Route 22 | `route_22` ; `route_22_west` (J29) | Road to Cerulean City (RB `ROUTES3`) | RB donne à la Route 22 le thème des Routes 3+, pas celui de la Route 1 |
| | `route_22_gate` (J29) | RB : Viridian Forest (bizarrerie) | **SON-9** : je propose Pewter City Theme (comme les autres postes) |
| Route 2 | `route_2`, `route_2_north`, `route_2_east` | Road to Viridian City | |
| | `route_2_east_gate` | Pewter City Theme (poste) | |
| Forêt de Jade | `viridian_forest` ; postes sud et nord | Viridian Forest ; postes : Pewter City Theme | |
| Argenta | ville, maisons, Musée (3 cartes) | Pewter City Theme | |
| | Centre, Boutique | Pokémon Center | |
| | `pewter_gym` | Pokémon Gym | |
| Route 3, Route 4 | `route_3`, `route_4` | Road to Cerulean City | |
| Mont Sélénite | `mt_moon_1f`, `b1f`, `b2f` | Caves of Mt. Moon | |
| | `mt_moon_center` | Pokémon Center | |
| Azuria | ville, maisons, magasin de vélos, maison cambriolée | Cerulean City Theme | |
| | Centre, Boutique ; `cerulean_gym` | Pokémon Center ; Pokémon Gym | |
| Route 24, Route 25, Cap d'Azuria | `route_24`, `route_25`, `bill_house` | To Bill ; maison de Léo : Cerulean City Theme (RB) | |
| Routes 5 à 8 | `route_5` à `route_8` | Road to Cerulean City | |
| | Pension, postes, entrées du souterrain | Pewter City Theme (RB `CITIES1`) | |
| Passages souterrains | `underground_path`, `underground_path_7_8` | Road to Viridian City (RB `ROUTES1`) | |
| Carmin-sur-Mer | ville, Fan Club, maisons | Vermilion City Theme | |
| | `vermilion_fisher_house` | RB : Cerulean City Theme (bizarrerie) | **SON-9** : Vermilion City Theme |
| | Centre, Boutique ; `vermilion_gym` | Pokémon Center ; Pokémon Gym | |
| S.S. Anne | 9 cartes | The S.S. Anne | départ définitif (J16) : voir §2.3 |
| Cave Taupiqueur | `digletts_cave` | Viridian Forest (RB `DUNGEON2`) | |
| Routes 9, 10 | `route_9`, `route_10` | Road to Cerulean City | |
| | `route_10_center` | Pokémon Center | |
| Grotte Sombre | `dark_cave_1f`, `b1f` | Caves of Mt. Moon | |
| Lavanville | ville, maisons, maison Pokémon | Lavender Town Theme | |
| | Centre, Boutique | Pokémon Center | |
| | Tour `1f` à `7f` | Pokémon Tower | **zone purifiée** (J19, J21) : **SON-10** |
| Routes 11 à 15 | `route_11` à `route_15`, `route_12_south`, postes | Road to Lavender Town ; postes : Pewter City Theme | |
| | `route_12_rod_house` | RB : Celadon City Theme (bizarrerie) | **SON-9** : Road to Lavender Town (sans changement de morceau en entrant) |
| Céladopole | ville, Hôtel, Restaurant, maison du chef, Manoir Céladon (6 cartes) | Celadon City Theme | |
| | Centre ; grand magasin (7 cartes, ascenseur compris) | Pokémon Center | |
| | `celadon_gym` | Pokémon Gym | |
| | `celadon_game_corner` | Game Corner | |
| | repaire Rocket B1F–B4F, ascenseur | Rocket Hideout | |
| Routes 16 à 18 | `route_16`, `route_16_west`, `route_17`, `route_18`, postes | Road to Cerulean City ; postes : Pewter City Theme | **Piste Cyclable** (Route 17) : SON-5 |
| | `route_16_fly_house` | RB : Celadon City Theme (bizarrerie) | **SON-9** : route |
| Parmanie | ville, maisons, salle de réunion | Cerulean City Theme | |
| | Centre, Boutique | Pokémon Center | |
| | `fuchsia_gym`, `wardens_house` (**J23**) | Pokémon Gym ; Cerulean City Theme | |
| Parc Safari (**J23**) | porte, 4 zones, 5 maisons | **absent de LG** | **SON-5** |
| Routes 19 à 21 | `route_19`, `route_20`, `route_21` | **The Sea** (Surf) ; à pied (plages) : Road to Cerulean City | |
| Îles Écume | `seafoam_1f` à `b4f` | Viridian Forest (RB) | |
| Cramois'Île | île, Labo (4 cartes) | Cinnabar Island Theme | |
| | Centre, Boutique ; `cinnabar_gym` | Pokémon Center ; Pokémon Gym | |
| | Manoir `1f` à `b1f` | Pokémon Mansion | |
| Safrania (**J26**, **J27**) | ville, maisons, Dojo | Pewter City Theme | |
| | Centre, Boutique ; `saffron_gym` | Pokémon Center ; Pokémon Gym | |
| | Sylphe SARL 1F–11F, ascenseur | Silph Co. | |
| Route 23, Route Victoire (**J29**) | `route_23` ; `victory_road_1f` à `3f` | The Final Road ; Caves of Mt. Moon | « The Final Road » à confirmer |
| Plateau Indigo (**J29**, **J30**) | `indigo_plateau`, `indigo_plateau_lobby` | The Final Road ; hall : Pokémon Center [D] | RB joue `INDIGO_PLATEAU` dans le hall |
| | `league_lorelei` | Pokémon Gym (RB) | |
| | `league_bruno` | Rocket Hideout (RB) | |
| | `league_agatha` | Pokémon Tower (RB) | |
| | `league_lance`, `league_champion` | The Final Road (RB) | |
| | `hall_of_fame` | **Hall of Fame** (scène) | |
| Grotte Azurée (**J31**) | `cerulean_cave_1f`, `2f`, `b1f` | Rocket Hideout (RB) | |
| Centrale | **aucune carte** sur aucune branche | Rocket Hideout (RB) | à ajouter quand la Centrale existera (J32, N-arbitrages) |

**Règle des intérieurs** (SON-9) : un intérieur prend la musique de sa ville, sauf Centres,
Boutiques, Arènes, Labo de Chen, et les lieux qui ont leur thème (Tour, Manoir, Sylphe, Casino,
repaire, S.S. Anne). Les quatre bizarreries RB (poste de la Route 22, maison du pêcheur de Carmin,
maisons des Routes 12 et 16) sont ramenées à la règle.

### 2.3 Scènes, combats et moments

| Moment | Morceau LG | Source dans le jeu | Écart ou doute |
|---|---|---|---|
| Écran de démarrage | silence [D] | `game/ui/opening` | |
| Écran titre | **Title Screen** | `data/opening/title.json` | |
| Introduction de Chen (prénoms) | **Guide** (probable) | `data/opening/oak_intro.json` | titre à confirmer à l'écoute ; sinon « Professor Oak » |
| Chen « Attends ! » (Route 1), Chen qui guide | **Professor Oak** | `data/cutscenes/prologue.json`, `route_1.json` | |
| Rival qui apparaît (labo, Route 22, Azuria, S.S. Anne, Tour, Sylphe, Ligue) | **Blue's Theme** | cinématiques des rivaux | |
| Dresseur qui repère le joueur (« ! ») | **A Trainer Appears (Boy / Girl / Bad Guy version)** | étape `emote` | **il faut une donnée** « garçon / fille / méchant » par Dresseur (les fichiers n'ont qu'un nom) : `battle_music.json`, rempli par préfixe de nom (« Gamin », « Fillette »…) puis à la main |
| Team Rocket qui apparaît | A Trainer Appears (Bad Guy version) | cinématiques Rocket | « Theme of Jessie and James » : **non utilisé** (pas de Jessie ni James dans K26) |
| Combat sauvage (et Ronflex, oiseaux, Mewtwo) | **Battle! (Wild Pokémon)** | `BattleDirector.battle_started` | RB n'a pas de thème légendaire ; LG n'en a pas sur l'album : SON-13 |
| Victoire contre un sauvage | **absent de LG** | `battle_finished` | **SON-14** |
| Combat de Dresseur, rival (avant la Ligue), Rocket | **Battle! (Trainer Battle)** | | RB : le rival et les Rocket ont la musique des Dresseurs |
| Victoire contre un Dresseur | **Victory! (Trainer Battle)** | | |
| Champion d'Arène, Giovanni, Conseil des Quatre | **Battle! (Gym Leader Battle)** | | RB |
| Victoire contre un Champion | **Victory! (Gym Leader Battle)** | | |
| Badge reçu | **Obtained a Gym Badge!** | étape `badge` | |
| Rival Champion | **Final Battle! (Rival)** | J30 | |
| Panthéon | **Hall of Fame** | J30 30C | |
| Générique | **Ending Theme**, puis **Congratulations!** | J30 30C | |
| Retour en jeu après le générique | **We're Back** [D] | J30 post-Ligue | à écouter : jingle court ou morceau ? |
| Capture réussie | **Caught a Pokémon! (short version)** ; première capture : **Caught a Pokémon!** [D] | `pokemon_caught` | |
| Objet ramassé ou reçu | **Picked Up an Item!** | étape `give`, objets au sol | |
| Objet clé, CT, CS | **Obtained a Key Item!** | étape `give` (objet clé) | |
| Soin au Centre (et chez Maman) | **Pokémon Healed** | `ServiceDirector` | |
| Montée de niveau | **Level Up!** (jingle par-dessus le combat, musique atténuée) | `BattleEvent.LEVEL_UP` | |
| Évolution | **Evolution**, puis **Congratulations! Your Pokémon Evolved!** | écran d'évolution | |
| Ossatueur fantôme, Tour 6F | **Cubone's Mother** | J19 / J21 | |
| Poké Flûte (Ronflex, Pokémon endormis) | **The Poké Flute** | étape `flute` (J21) | |
| Surf | **The Sea** | état « monté » (S2C) | |
| Vélo, Piste Cyclable | absent de LG | état « monté » (S2B) | **SON-5** |
| Menus, Pokédex, Sac, Équipe | musique de la zone continue | | **SON-15** |
| Échange PNJ | musique de la zone [D] | étape `trade` | |
| Grand moment (carte) | aucune, musique atténuée [D] | étape `moment` | |

**Pistes LG non utilisées** (pas d'équivalent dans K26) : « Into the Game: Let's Go! », « Choose
Your Language », « Pokédex Evaluation… », « Jigglypuff's Song », « Catch! (Wild Pokémon) »,
« Successful Catch! (Wild Pokémon) », « Pokémon Road », « GO Park » et ses deux jingles,
« Connection », « Mystery Gift », « Battle! (Master Trainer Battle) », « Opening Movie »,
« Theme of Jessie and James ». Certaines comblent des trous (SON-5, SON-13, SON-14).

**Pistes à vérifier à l'écoute** (Son.0 T1, par Kevin ou avec lui) : « The Final Road », « Guide »,
« Pokémon Road » (thème de monture ? il pourrait servir au Vélo), « We're Back ». Le jeu Let's Go
contient peut-être des morceaux qui ne sont pas sur l'album (combat de rival, Team Rocket,
légendaires) : **seule l'écoute du jeu le dira**, et cela peut fermer SON-5, SON-13 et SON-14.

**Compte** : **52 pistes LG utilisées** sur 67 (≈ 40 morceaux en boucle et ≈ 12 jingles) ; 15 non utilisées.

## 3. Bruitages

### 3.1 Interface (≈ 15)

Appui de bouton (validation), retour / annulation, déplacement du curseur ou changement d'onglet,
refus (action impossible), ouverture et fermeture du Menu Dresseur, page de dialogue suivante,
choix OUI/NON, sauvegarde réussie, achat ou vente (caisse), PC allumé / éteint, dépôt ou retrait
au PC, favori, toast, ouverture de la Carte, Vol (départ et arrivée).

### 3.2 Déplacement et monde (≈ 30)

Pas (herbe, sol dur, intérieur, sable, eau peu profonde, neige des Îles Écume ?) en 2 à 4
variantes ; course (mêmes pas, plus rapides) ; cogner un mur ; saut de rebord ; porte qui s'ouvre ;
escalier ; tapis de sortie ; warp / téléporteur ; trou (chute) ; Surf (entrée dans l'eau, sortie) ;
Vélo (enfourcher, sonnette) ; Coupe (arbuste) ; Force (rocher qui glisse, rocher dans un trou) ;
Flash ; Éclate-Roc si elle existe ; dalle tournante ; ascenseur (départ, arrivée, « ding ») ;
interrupteur (Manoir, Route Victoire) ; herse ; objet trouvé au sol ; examen d'un point
(léger) ; Poké Ball posée ; canne à pêche (lancer, touche) ; Pokémon d'ambiance qui s'envole ;
machine de Léo ; pierres qui roulent (Mont Sélénite) ; Casino (machines, ambiance) ; porte qui
claque (Rocket qui s'enfuit) ; « ! » d'un Dresseur (bruitage court, en plus du thème).

### 3.3 Combat (≈ 45 + attaques)

Entrée en combat (transition), envoi et rappel (Ball qui s'ouvre), coup normal / super efficace /
pas très efficace, sans effet, raté, coup critique, K.O. (chute), stat qui monte / baisse, cinq
statuts (poison, brûlure, paralysie, sommeil, gel) et confusion, soin de PV, objet utilisé, Ball
lancée / qui rebondit / qui se ferme / secousse (×3) / capture (« clic ») / évasion, barre d'XP
qui monte (boucle), montée de niveau (couvert par le jingle), fuite réussie, PV bas (alarme RB :
**SON-17**), pièces éparpillées (Jackpot), fantôme qui parle.

**Attaques** : ≈ 20 familles (type × physique / spécial, plus soin, statut, sons, explosion)
choisies par `sfx.json` à partir du type et de la catégorie de l'attaque ; une attaque peut avoir
son propre son (exception) sans changer le code. SON-11.

### 3.4 Ambiances (≈ 10 boucles)

Mer et mouettes (Bourg Palette côté plage, Carmin, Cramois'Île, Routes 19–21) ; vent léger (routes
ouvertes) ; forêt et oiseaux (Forêt de Jade, Route 2) ; grotte (gouttes, écho : Mont Sélénite,
Grotte Sombre, Cave Taupiqueur, Route Victoire, Grotte Azurée) ; ville (bruit doux : Céladopole,
Safrania) ; Casino ; navire (moteur, coque : S.S. Anne) ; laboratoire / bâtiment (bourdonnement :
Sylphe, Labo) ; pluie (météo déjà codée) ; vent froid (Îles Écume). Intérieurs : rien [D].

### 3.5 Sources possibles (SON-2)

| Source | Pour | Licence | Remarque |
|---|---|---|---|
| **Extraction de son propre Let's Go** (cartouche de Kevin) | bruitages Pokémon reconnaissables (soin, PC, Ball, coups, interface) | même statut que la musique (jeu privé) | cohérent avec la musique ; demande l'outillage d'extraction de Kevin |
| **Kenney** (« Interface Sounds », « Impact Sounds », « RPG Audio ») | interface, pas, impacts | **CC0** | gratuit, propre, petit |
| **Freesound** (filtre CC0) | ambiances, pas, mer, grotte | CC0 (filtrer) | qualité variable, tri nécessaire |
| **Sonniss GDC Game Audio Bundle** | ambiances de qualité | libre d'usage (licence Sonniss) | gros téléchargements, tri |
| Génération (jsfxr / sfxr, sur le Mac) | petits « blips » d'interface | aucun droit tiers | rendu « rétro », à éviter pour le monde |
| Génération par IA (ElevenLabs SFX, etc.) | trous ponctuels | selon le service | coût, cohérence variable |

**Rien n'est téléchargé sans l'accord explicite de Kevin, fichier par fichier ou lot par lot, avec
la source et la taille** (le plan de chaque lot liste les fichiers d'avance).

## 4. Découpage

### 4.1 Sous-jalons et validations

| Sous-jalon | Contenu | Fichiers son | Validation |
|---|---|---|---|
| **Son.0** | Moteur pur + données + tests ; autoload branché nulle part ; catégorie SON des Paramètres | aucun | tests seuls (rien à entendre) |
| **SonA** | Musique : zones, fondus, combats, jingles, scènes, reprise ; Android | musique (lot 1) | **S24 par Kevin** (écoute) |
| **SonB** | Cris (combat, rencontre, Pokédex, compagnon, évolution) | cris (151) | S24 par agent + écoute de Kevin groupée avec SonC |
| **SonC** | Bruitages (interface, déplacement, combat) + ambiances | bruitages, ambiances | **S24 par Kevin** |
| **SonD** | Clôture : poids, mesures, volumes relatifs, licences, plan → `main` | — | rapport |

Les lots de fichiers son suivent le même processus que l'art (`phase-da-cadrage.md`) : liste
d'avance, accord de Kevin pour chaque téléchargement ou extraction, intégration à l'identique,
contrôle par agent.

### 4.2 Tâches

| Tâche | Contenu | Agent | Critère d'acceptation |
|---|---|---|---|
| **T1** | Écoute et liste exacte des pistes : confirmer « The Final Road », « Guide », « Pokémon Road », « We're Back » ; repérer les morceaux du jeu absents de l'album (avec Kevin) | Kevin + Sonnet | §2 corrigé, SON-5/13/14 fermés ou confirmés |
| **T2** | `data/audio/*.json` (morceaux attendus, zones, exceptions, combats, scènes) d'après le §2 ; `battle_music.json` rempli par préfixe de nom | Sonnet | `check_audio_data.py` : 100 % des cartes de `main` couvertes |
| **T3** | `AudioLibrary`, `MusicSelector`, `MusicStack`, `VolumeMath`, `SfxCatalog`, `CryCatalog` + tests unitaires | Opus (architecte) | tests verts, aucune scène chargée |
| **T4** | Autoload `Audio` (bus, lecteurs A/B, pool, fondus, espion `sink`, muet tolérant) | Opus | tests d'intégration verts, import sans erreur, jeu identique sans fichier son |
| **T5** | `GameSettings` + catégorie SON (Paramètres du menu et de l'écran titre) | Sonnet (ui-mobile) | ancien `settings.json` relu ; capture des Paramètres relue |
| **T6** | `AudioBridge` : changement de carte, combat, jingles (soin, objet, Badge, capture, évolution), étape de cinématique `music` (clé facultative sur n'importe quelle étape, **sans nouvelle sorte** de `CutsceneStep.Kind`), Surf / Vélo | Opus | tests d'intégration ; rien ne change sans fichier son |
| **T7** | Android : arrière-plan, bandeau d'appel, retour ; démarrage après le premier rendu | Sonnet | test `SessionLifecycle` étendu ; vérification S24 (T10) |
| **T8** | Lot musique : partir des fichiers fournis par Kevin dans `~/Music/kanto-lets-go/` (SON-3 révisé : KHInsider), faire correspondre leurs noms à la table §2, couper les boucles, normaliser, convertir en OGG q3, mesurer | Kevin + Sonnet | `measure_audio.py` : boucles sans clic, −16 LUFS ±1, poids dans le budget |
| **T9** | Intégration du lot musique (`tracks.json` passe de « attendu » à « présent ») | Sonnet | suite complète verte ; APK mesuré |
| **T10** | **QA SonA sur S24** (agent, 30–45 min) : Bourg Palette → Route 1 → Jadielle (même morceau en intérieur, fondu au raccord), combat sauvage et Dresseur, victoire, reprise, Centre, objet, évolution (départ de débogage), Surf, Paramètres, arrière-plan, appel simulé | qa-mobile | rapport, aucun clic de boucle, aucun trou de son > 0,5 s, 60 i/s tenus |
| — | **Validation SonA par Kevin sur S24** | Kevin | |
| **T11** | Cris : accord SON-1 → téléchargement des 151 fichiers (2,05 Mo `latest`) ; branchement combat, rencontre, Pokédex, compagnon, évolution ; ralenti du K.O. | Sonnet | test : 151 espèces ont un cri ; capture du Pokédex relue |
| **T12** | Lot bruitages et ambiances (source SON-2), `sfx.json`, `ambiences.json` | Sonnet | liste du §3 couverte, ou manques listés |
| **T13** | Branchements bruitages : composants d'interface, pas à la case, monde, `BattleEvent`, familles d'attaques | Sonnet ; Opus si le combat résiste | tests (espion) : chaque `BattleEvent.Kind` sonore joue son identifiant |
| **T14** | **QA SonB + SonC sur S24** (agent) puis **validation de Kevin** | qa-mobile, Kevin | rapport ; volumes relatifs notés |
| **T15** | Clôture : poids final de l'APK, lignes audio pour l'inventaire des licences du J34, `etat-projet.md`, fusion | Sonnet | suite complète, fusion dans `main` |

Règle 1 de `CLAUDE.md` : Son.0 et SonA ne touchent pas la sauvegarde (les volumes sont des
réglages) ; aucun sous-jalon ne valide trois systèmes à la fois (SonA = musique, SonB = cris,
SonC = bruitages et ambiances, validés séparément même si SonB et SonC passent dans la même
session S24).

### 4.3 Place dans le calendrier

- **Le moteur peut avancer maintenant, en parallèle des J23 et J26 à J31, sans conflit** :
  Son.0 ne crée que des fichiers neufs (`game/systems/audio/` est vide, `data/audio/` n'existe pas,
  `default_bus_layout.tres` n'existe pas) et une catégorie de réglages. Relevé des branches ouvertes
  sur les fichiers que SonA touchera : `boot.gd`, réglages, `battle_director.gd`, `session/`,
  `map.gd` — `jalon-23` +127 lignes (réglages / Boot), `jalon-29` +13, `jalon-30` +31, `jalon-31`
  +2, `jalon-26` à `jalon-28` rien. Conflits **faibles et additifs**.
- **SonA** se branche sur `main` ; ses données couvrent d'avance les cartes des branches (§2.2) :
  une carte qui arrive après n'a besoin de rien (sa zone a déjà un morceau) ; `check_audio_data.py`
  le vérifie à chaque fusion d'un jalon. **Une seule écriture partagée** : la clé `music` des
  cinématiques (données), ajoutée aux fichiers de `main` seulement ; les branches l'ajoutent à leurs
  propres cinématiques après fusion, ou SonA le fait en reprise.
- **Pas de nouvelle sorte de `CutsceneStep.Kind`** (le J23 ajoute `SAFARI` après `TRADE` : un ajout
  concurrent décalerait les rangs) — d'où la clé facultative `music`.
- **Fin** : le son est une **fonctionnalité** ; le J33 (gel fonctionnel) n'admet plus que des
  correctifs. SonA et SonB doivent donc être **dans `main` avant l'ouverture du J33**. Les **lots de
  fichiers** (bruitages, ambiances, remplacement d'un morceau) peuvent continuer comme l'art jusqu'au
  **gel de l'entrée du J34** (DA-7). SON-16.
- Charge : Son.0 ≈ 1 session ; SonA ≈ 2 sessions (+ le temps de Kevin pour obtenir et couper les
  morceaux) ; SonB ≈ 0,5 ; SonC ≈ 1,5 à 2 ; SonD ≈ 0,5. **≈ 5 à 6 sessions**, ordre de grandeur non
  mesuré. Au plus 2 à 3 jalons en code à la fois (`strategie-acceleration.md`) : le Son compte pour
  un ; il passe naturellement à côté des lots d'art (DAF), qui ne touchent aucun fichier de code.

## 5. Hors périmètre

Musique dynamique par couches (exploration / danger), réverbération par lieu, son 3D positionné
(les PNJ ne « sonnent » pas selon la distance), voix, synthèse d'une piste manquante, sons de la
Pension ou des échanges en ligne, adaptation au casque. Le **volume relatif final** (mixage fin)
est une remarque de rendu : notée dans « Reportés », corrigée en lot.

## 5 bis. Décision de Kevin — source des morceaux (2026-10-25, révise SON-3)

Mot pour mot : « je prendrai toutes les bandes son de let's go sur KHInsider ». SON-3 ne passe
plus par l'achat de l'album : **Kevin télécharge lui-même** tout l'album Let's Go (FLAC si possible,
sinon MP3 en meilleure qualité) dans `~/Music/kanto-lets-go/`, **sans renommer les fichiers**.
Claude ne télécharge rien. T8 part de ce dossier : correspondance des noms avec la table §2,
découpe des boucles, normalisation à −16 LUFS, conversion en OGG q3, mesure. Licences (J34 T6,
lignes audio) : source « **KHInsider (fichiers fournis par Kevin)** », jeu privé, cercle restreint.

## 5 ter. Lot musique fait (T8–T9, 2026-10-25)

54 OGG q3 (`oggenc`, vorbis-tools installé avec l'accord de Kevin) dans `assets/audio/music/`,
**34,4 Mo**. Outils : `tools/audio/prepare_music.py` (correspondance des titres, boucle à
l'échantillon près, jointure fondue 20 ms, −16 LUFS, crête ≤ −1 dBTP) et
`tools/audio/measure_audio.py` (poids, durée, LUFS, crête, contrôle des jointures). 51 boucles
exactes sur 52 ; « Cubone's Mother » ne se répète pas sur l'album (piste entière, T1 n° 8).

## 5 quater. Lots de fichiers téléchargés (accord de Kevin du 2026-10-25 : « Oui, cris + bruitages »)

| Lot | Source | Taille téléchargée | Dans le jeu | Licence |
|---|---|---|---|---|
| Cris (T11) | `raw.githubusercontent.com/PokeAPI/cries`, `cries/pokemon/latest/1..151.ogg` | 2,3 Mo (151 fichiers) | `assets/audio/cries/`, 2,0 Mo (OGG mono q4) | jeu privé, cercle restreint (comme la musique) |
| Bruitages n° 1 (T12) | kenney.nl : Interface Sounds (834 Ko), UI Audio (412 Ko), Impact Sounds (801 Ko), RPG Audio (965 Ko) | 3,0 Mo (334 OGG) | `assets/audio/sfx/`, 84 fichiers, 696 Ko (69 identifiants sur 107) | CC0 |
| Ambiances (T12, option A de Kevin : « OpenGameArt CC0 ») | voir le détail ci-dessous | 4,1 Mo (6 fichiers) | `assets/audio/ambience/`, 7 boucles, 816 Ko (OGG mono q3, −16 LUFS, jointure fondue) | CC0 (vérifiée sur chaque page) |

Détail des ambiances (OpenGameArt, licence affichée sur la page : CC0 seule) :

| Boucle | Page source | Fichier téléchargé | Taille |
|---|---|---|---|
| `sea` | opengameart.org/content/beach-ocean-waves (qubodup) | `wave_01_cc0-18363__jasinski__alkaibeach.flac` | 626 Ko |
| `wind`, `cold_wind` | opengameart.org/content/wind (ignasd) | `wind.zip` (`Wind.ogg`, `Wind2.ogg`) | 264 Ko |
| `forest` | opengameart.org/content/ambient-bird-sounds (isaiah658) | `birds-isaiah658_0.ogg` | 545 Ko |
| `cave` | opengameart.org/content/loopable-dungeon-ambience (jaggedstone) | `dungeon_ambient_1_0.ogg` | 1,6 Mo |
| `ship` | opengameart.org/content/underwater-or-space-engine-rumble (gmason) | `underwater_or_space_engine_0.ogg` | 512 Ko |
| `building` | même page (gmason) | `deep_rumble.ogg` | 554 Ko |

Restent sans fichier (silence) : `city` et `casino` (pas de boucle CC0 convenable sans compte ;
les « park ambiences » font 74 à 99 Mo en WAV) et `rain` (aucune météo dans le jeu pour
l'instant). `sea` boucle sur une seule vague de 3 s : à écouter.

## 5 quinquies. Validations de Kevin (2026-10-25)

- **Écoute de SonA, SonB et SonC sur l'A17 : « Je valide ».**
- **T1** (`docs/design/passes/son-t1-ecoute.md`) : « Oui » aux 8 pistes, valeurs par défaut retenues :
  « Guide » pour l'introduction de Chen ; « The Final Road » pour la Route 23 et le Plateau ;
  « Pokémon Road » pour le Vélo (**SON-5 B**) ; « We're Back » en jingle ; « Blue's Theme » pour
  le rival ; « Theme of Jessie and James » non utilisé ; victoire sauvage = « Victory! (Trainer
  Battle) » coupé à 4 s (**SON-14 A**) ; « Cubone's Mother » en boucle entière. Légendaires :
  musique des sauvages (**SON-13 A**). SON-5, SON-13 et SON-14 sont fermés.

## 5 sexies. SonD — clôture (2026-10-25)

**Lignes audio pour l'inventaire des licences du J34 (T6)** — à recopier telles quelles :

| Contenu | Fichiers du jeu | Source | Licence / statut |
|---|---|---|---|
| Musique (54 morceaux, bande-son de Pokémon Let's Go Pikachu / Évoli) | `assets/audio/music/*.ogg` (34,4 Mo) | KHInsider, fichiers fournis par Kevin (`~/Music/kanto-lets-go/`, album « Super Music Collection ») ; découpe, normalisation et encodage par `tools/audio/prepare_music.py` | © The Pokémon Company / Nintendo / Game Freak ; jeu privé, cercle restreint, jamais public |
| Cris des 151 Pokémon | `assets/audio/cries/1..151.ogg` (2,0 Mo) | PokeAPI, dépôt `PokeAPI/cries`, `cries/pokemon/latest/` | © The Pokémon Company ; même statut que la musique |
| Bruitages (69) | `assets/audio/sfx/*.ogg` (696 Ko) | Kenney (kenney.nl) : Interface Sounds, UI Audio, Impact Sounds, RPG Audio | CC0 |
| Ambiances (7 boucles) | `assets/audio/ambience/*.ogg` (816 Ko) | OpenGameArt : beach-ocean-waves (qubodup), wind (ignasd), ambient-bird-sounds (isaiah658), loopable-dungeon-ambience (jaggedstone), underwater-or-space-engine-rumble (gmason) — détail §5 quater | CC0 |

**Poids final** (APK debug du 2026-10-25, `main` fusionné dans `jalon-son`) : **352 Mo**, dont **38,6 Mo d'audio** (296 fichiers importés : 54 morceaux, 151 cris, 84 bruitages, 7 ambiances) ; le budget estimé au §1.11 était de 70 à 100 Mo. Suite complète sur l'état fusionné : 6 928 / 6 928.

**Volumes relatifs** (mesurés ; validés à l'écoute par Kevin le 2026-10-25, « Je valide ») :
musique et jingles à −16 LUFS (boucles mesurées sur la partie qui boucle) ; ambiances à
−16 LUFS jouées −18 dB plus bas (≈ −34 LUFS) ; cris à −3 dBFS de crête ; bruitages à −6 dBFS
(combat), −8 (monde), −12 (interface), −14 (pas) ; curseurs par défaut Musique 70 %, Effets
80 %, Cris 80 %. Aucun réglage fin demandé ; le mixage fin reste une remarque de rendu (§5).

**Restes connus** (hors fusion, lots possibles jusqu'au gel de l'entrée du J34, SON-16) : 38
bruitages sans fichier (liste dans `etat-projet.md`) ; ambiances `city`, `casino`, `rain` ;
atténuation dans la zone purifiée de la Tour ; « ducking » pendant les cris ; musiques de scène
des cinématiques des branches (après leur fusion).

## 6. Questions ouvertes

Aucune : SON-1 à SON-17 validés par Kevin le 2026-10-24 ; écoute T1 et écoute des trois
sous-jalons validées le 2026-10-25 (§5 quinquies).
