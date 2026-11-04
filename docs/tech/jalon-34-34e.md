# Jalon 34 — 34E : inventaire des licences, ressources et confidentialité (T6)

> **Fiche factuelle, en lecture seule** (2026-11-04, session « J34 34E », branche `claude/j34-34e`). Aucun
> code de jeu, aucun asset n'a été modifié ni retiré. **Aucune conclusion juridique** : ce document dit
> *ce que l'APK embarque, d'où ça vient et ce que le dépôt prouve ou ne prouve pas*. Le **Go juridique**
> reste une décision de Kevin, éclairée par un avis compétent (`jalon-34.md` §7.1), jamais par une session.
> Règle du plan (T6) : aucune affirmation « libre de droits » sans preuve — ici, seules les polices et les
> sons CC0 ont une licence lisible ; tout le reste est soit **sans licence**, soit **de provenance
> Nintendo / Game Freak / The Pokémon Company / Creatures**, soit **produit par IA sans licence tierce
> mais imitant des œuvres protégées**.

## 0. Résumé en dix lignes

1. L'APK debug mesuré (`build/kanto2026-debug.apk`, 2026-11-04 01:34, 612 Mo) contient **≈ 546 Mo d'assets importés** : l'essentiel est de l'art généré par IA (Codex) ; ≈ 39 Mo d'audio ; 2 polices OFL ; GUT (MIT) est bien exclu.
2. **Œuvres Nintendo / Game Freak / The Pokémon Company reproduites telles quelles dans l'APK** : 54 morceaux de la bande-son de *Let's Go* (35,9 Mo), 151 cris (1,8 Mo), 152 artworks officiels PokeAPI (6,9 Mo dans l'APK), 16 rendus de modèles 3D de *X/Y* (extraits de la 3DS) ; **aucune licence** pour aucun d'eux.
3. **Œuvres dérivées / imitations par IA** : dos des Pokémon (155 fichiers, 65 Mo dans l'APK) repeints par IA à partir de rendus 3D de *X/Y* et de l'artwork officiel (LoRA entraîné sur des images Pokémon sous copyright), Pokémon, Dresseurs, Champions, objets et carte de Kanto « fidèles à Rouge/Bleu » dessinés par Codex ; noms, types, statistiques, cartes (via un désassemblage `pokered` local) de Rouge/Bleu.
4. **Libre et prouvé** : Cinzel et Cormorant Garamond (SIL OFL 1.1), bruitages Kenney (CC0, 0,5 Mo), 7 ambiances OpenGameArt (CC0, 0,8 Mo), GUT (MIT, hors APK), Godot 4.7.2 (MIT) ; icônes SVG et placeholders écrits par code.
5. **Confidentialité : très bonne** : une seule permission (`VIBRATE`), **pas d'`INTERNET`**, aucune bibliothèque d'analytique, `allowBackup=false`, sauvegarde locale en clair (prénom seulement).
6. **Risque n° 1 (bloquant hors du cercle de la maison, à décider maintenant)** : le dépôt GitHub `YANKAMKEVIN/kanto-2026` est **public** (0 fork, 0 étoile au 2026-11-04) et **suit dans Git** la musique, les cris, les artworks officiels et les rendus 3DS (historique compris). Cela contredit « jamais diffusé » du générique.
7. `export_presets.cfg` : le preset **iOS** n'a **aucun filtre d'exclusion** (embarquerait `docs/`, `tools/`, `tests/`, `proto/`, `battle_proto/`) ; le preset Android est correct.
8. L'APK **release** n'existe pas encore (pas de clé) : `debuggable` y doit être faux, à vérifier à T7.
9. Aucun texte de licence (OFL, MIT de Godot) ni crédit CC0 n'est affiché ou livré avec l'APK.
10. Les décisions juridiques (voir §11) sont à Kevin ; cette fiche ne retire aucune ressource.

## 1. Méthode et limites

- Lecture du dépôt (`CLAUDE.md`, `docs/tech/etat-projet.md`, `jalon-34.md`, `release.md`, `jalon-son.md`, mémoires du projet), `find`, `du`, lecture des fichiers de licence, `git log --diff-filter=A`, `gh repo view`, `aapt2` / `unzip -v` sur l'APK debug existant, recherche de motifs dans `game/` et `tools/`. Un sous-agent (Sonnet) a relevé la provenance des familles d'images dans `tools/art/`, les fiches et les prompts.
- **Pas de réseau** : aucune licence en ligne n'a été relue (KHInsider, PokeAPI, Kenney, OpenGameArt, The Models Resource, Hugging Face). Les statuts CC0 des bruitages et ambiances reprennent ceux notés par le jalon Son (« vérifiée sur chaque page »).
- **Limites** : (a) l'APK mesuré est l'**APK debug** du 2026-11-04 01:34 (build du checkout principal, antérieur à certains commits de `main`) ; (b) l'identité exacte de chaque fichier peint (Codex seul, Codex d'après référence, ou fait à la main par Kevin dans l'app ChatGPT) n'est pas toujours tracée ; (c) les 213 fichiers de `docs/design/reference/` (maquettes de Kevin) n'ont pas été audités image par image : leur origine est « fournie par Kevin » (conception avec ChatGPT) sans plus de précision ; (d) les 83 icônes SVG ont été lues par échantillon.
- Les tailles « APK » sont les octets **compressés** de la sortie importée (`.godot/imported/*.ctex|.oggvorbisstr|…`) dans l'APK debug ; « source » = fichiers du dépôt. Un APK release peut différer de quelques pourcents.

## 2. Ce que l'APK embarque vraiment (filtre d'export)

`export_presets.cfg`, preset **Android** : `export_filter="all_resources"`, `exclude_filter="tests/*, tools/*, docs/*, addons/gut/*, build/*, proto/*, assets/sprites/pokemon/battle_proto/*"`, arm64-v8a seul, `permissions/vibrate=true`, `package/signed=true`, clé release vide (lue dans l'environnement).

Vérifié dans l'APK debug : 0 entrée `addons/`, `tests/`, `tools/`, `docs/`, `proto/`, `battle_proto`, 0 fichier `.md`, `.jks` ou `LICENSE` ; les scripts partent en `.gdc` (506) ; 3 362 ressources importées (546 Mo), 1 073 scènes exportées (12 Mo), 13 `classes*.dex` (≈ 6 Mo), `libgodot_android.so` (76 Mo décompressé, 26 Mo compressés avec `libc++_shared`).

| Famille (`assets/…`) | Fichiers | Source (Mo) | **Dans l'APK (Mo)** |
|---|---:|---:|---:|
| `battle/decors` (fonds de combat peints) | 48 | 37,6 | **152,3** |
| `sprites/pokemon/dos` (dos des Pokémon) | 155 | 98,0 | **65,1** |
| `sprites/pokemon/official` (artworks PokeAPI) | 153 | 25,2 | **6,9** |
| `sprites/pokemon/painted` (planches du monde) | 86 | 3,7 | 3,3 |
| `sprites/pokemon/placeholder` (provisoires par code) | 305 | 0,7 | 0,2 |
| `sprites/pokemon/battle_proto` | 50 | 29 | **0 (exclu Android)** |
| `world/interiors` | 393 | 90,0 | 71,5 |
| `sprites/characters` (`painted` 418 + `placeholder` 30) | 449 | 54,1 | 51,1 |
| `world/buildings` | 190 | 49,1 | 38,3 |
| `audio/music` | 54 | 36,0 | **35,9** |
| `sprites/battle_fx` | 101 | 30,9 | 29,3 |
| `sprites/trainers` | 108 | 7,2 | 22,3 |
| `ui/map` (carte de Kanto + 48 aperçus de zones) | 51 | 1,7 | 16,0 |
| `world/ground`, `props`, `relief`, `backdrops`, `decals`, `fx`, `maps` | ≈ 880 | ≈ 38 | ≈ 32 |
| `ui/battle`, `items`, `menu`, `opening`, `icon`, `badges`, `icons`, `pokedex` | ≈ 240 | ≈ 13 | ≈ 17 |
| `audio/cries` (151) + `sfx` (85) + `ambience` (7) | 243 | 3,1 | 3,1 |
| `fonts` | 5 | 1,3 | 0,6 |
| `tiles` | 99 | 0,7 | 0,4 |
| `ui/opening/trailer` (16 captures du jeu, WebP bruts) | 16 | 5,4 | WebP non importés (copiés tels quels) |

À retenir : **le poids est dominé par l'art peint par IA** (≈ 400 Mo) ; les ressources dont l'origine est directement Nintendo représentent ≈ 45 Mo (musique, cris, artworks), plus les dos (65 Mo) qui en sont dérivés.

**Filtre iOS** : le preset `iOS` a `exclude_filter=""` : un export iOS embarquerait aussi `docs/` (676 Mo), `tools/`, `tests/`, `proto/` et `battle_proto/`. Hors du chemin de diffusion actuel (`release.md` §5 : iOS hors périmètre), mais à corriger avant tout build iOS partagé.

## 3. Images : provenance famille par famille

Légende — **Prouvé** : fichier ou script du dépôt qui l'établit ; **Déduit** : cohérent avec les outils mais non tracé fichier par fichier ; **Inconnu**.

| Famille | Production | Source externe nommée | Licence | Protégé Nintendo / Game Freak / TPC ? | Certitude |
|---|---|---|---|---|---|
| **Artworks officiels** `sprites/pokemon/official` (152 PNG 475 × 475 + atlas) | copiés « tels quels » de PokeAPI (`sprites.other.official-artwork`), commit `702a95e6` (2026-10-06) | PokeAPI (URL exacte non écrite dans le dépôt) | **Aucune** (© Nintendo / Game Freak / The Pokémon Company ; mention dans `docs/tech/pokedex-refonte.md:87`) | **Oui, œuvres officielles brutes** : Pokédex, menus, adversaire en combat | Prouvé |
| **Dos 3D** `dos3d_*` (16 + 16 en `battle_proto`) | rendus Blender (`tools/art/blender/`) de **modèles 3D extraits de Pokémon X/Y** (« rips ») | The Models Resource ; extracteurs Random Talking Bush, TheBen, Mystie (qui demande à être créditée), Ploaj | **Aucune** : « œuvres dérivées de modèles sous copyright » (`docs/design/fiches-assets/provenance-modeles-3d.md`) | **Oui** | Prouvé |
| **Dos IA** `dos_ia_*` (77) | rendus 3D repeints sur Google Colab (AnyLoRA + LoRA Pokémon + ControlNet + IP-Adapter avec l'artwork officiel à 35 %), **ou** dos faits par Codex d'après l'artwork officiel ; certains faits à la main par Kevin dans l'app ChatGPT | Hugging Face : `Lykon/AnyLoRA`, `juliensimon/stable-diffusion-v1-5-pokemon-lora` (**entraîné sur des images Pokémon sous copyright**, dit le fichier), `lllyasviel` (ControlNet), `h94/IP-Adapter` | licences des modèles non relues ici ; le fichier de provenance les dit « même statut que le reste » | **Oui** (dérivés d'artworks et de modèles officiels) | Prouvé pour la chaîne ; Déduit fichier par fichier (le nom ne distingue pas Colab et Codex) |
| **Dos RB** `dos_rb_*` (62) | Codex (`tools/art/serie_dos_rb.py`, prompts `tools/art/prompts/dos_rb/`), **artwork officiel de face joint en référence**, sujet décrit sans nommer l'espèce | — | aucune | **Imite des créatures protégées** | Prouvé |
| **Pokémon du monde** `painted` (86) | Codex (planches de marche 4 × 4) ; « de Pokémon Rouge/Bleu, fidèle à son design officiel » dans les prompts (`serie09.py:33-39`) ; une planche de Salamèche faite à la main par Kevin dans l'app ChatGPT (Codex la refuse) | — | aucune | **Imite des créatures protégées** | Prouvé |
| **Pokémon provisoires** `placeholder` (305) | pixel art 64 px généré par code (`tools/gen_placeholder_battlers*.gd`), « mêmes silhouettes et couleurs » | — | propriété du projet (code) | imite des créatures | Prouvé |
| **Personnages** `characters/painted` (418) | Codex, planches 4 × 4 (`serie06.py`, `serie09.py` à `serie28.py`, `costumes/`, `joueuse_rivale/`, `course_pnj/`), ancre de style = héros du projet | — | aucune | Personnages propres au projet **et** personnages de la franchise (Champions, Rocket, classes de Dresseurs « fidèles à Rouge/Bleu », `serie12.py:284`) ; héros à casquette rouge d'après le storyboard | Prouvé (voie Codex) ; Déduit (identité de chaque fichier) |
| **Dresseurs en combat** `trainers` (108) | Codex (`entree_dresseurs.py`, `entree_ordinaires.py`, `entree_champions.py`, `entree_grands_combats.py`) ; prompts : « Design moderne fidèle au personnage de Pokémon Rouge/Bleu », Giovanni, Pierre, etc. | — | aucune | **Imite des personnages protégés** (sans logo Rocket : « aucun R, aucun logo ») | Prouvé |
| **Décors du monde** `world/*` (≈ 1 300 fichiers) | Codex (`serie01`…`serie28.py`, `daf*.py`, `preparer.py`), vues générales ancrées sur des **plans en aplats tirés de `tools/plans/*.txt`** ; grilles en partie issues du décodage de cartes RB (voir §7) | — | aucune | Disposition des cartes = Game Freak ; Centre Pokémon et Poké Ball dans le décor | Prouvé (outil) |
| **Fonds de combat** `battle/decors` (48) | Codex (`tools/art/combat_decors/preparer_decor.py`) | — | aucune | non (lieux) | Prouvé |
| **Effets de combat** `battle_fx` (98 WebP), `effects` | Codex (`serie_cv_fx*.py`) ; trajets et formes « inspirés des animations de Rouge », parfois de mémoire (`docs/tech/combat-vivant.md` §3.2) ; aucune capture de jeu trouvée | — | aucune | idées d'animation de Rouge, pas d'image copiée | Prouvé (outil) |
| **Objets, badges, menus** `ui/items` (85), `badges` (9), `menu` (8), `battle` (18) | Codex (`serie14.py`…, `menu_peint.py`) ; badges « formes de Rouge/Bleu » ; Fossile « fidèle au Fossile Dôme officiel » (`serie14.py:342`) | — | aucune | **Imite des objets et emblèmes de la franchise** (Poké Ball, badges, fossiles) | Prouvé |
| **Icônes** `ui/icons` (83 SVG) | tracés à la main / par code (commits de Kevin et de Claude, 2026-09-25/26) | aucune bibliothèque tierce détectée | propriété du projet | non | Prouvé par échantillon |
| **Logo « Pokemake », splash, ident, bande-annonce** `ui/opening` | logo peint par Codex (« ce n'est PAS le logo officiel Pokémon »), détouré par `tools/art/detourer_logo.py` ; bande-annonce = **captures du jeu** | — | aucune | le mot « Pokemake » contient « Poke » (nom, pas imitation graphique du logo) | Prouvé |
| **Icône de l'application** `ui/icon` | `tools/art/identite_daf7.py` : fond peint par Codex + « K » de l'ancien logo | — | aucune | non | Prouvé |
| **Carte de Kanto** `ui/map/kanto_placeholder.webp` | « illustration de Kanto **fournie par Kevin** » (`etat-projet.md:2158`, commit `79857ed6`, source `docs/design/reference/kanto-carte-v1.webp`) ; outil de génération non documenté ; peinture de style IA reprenant la forme de la région | — | **Inconnue** | reprend la géographie de Kanto (région protégée) | **Inconnu** |
| **Aperçus de zones** `ui/map/zones` (48) | captures floutées du jeu (`tools/build_zone_previews.gd`) | — | propriété du projet | — | Prouvé |
| **Tuiles provisoires** `tiles/placeholder` (96) | code (`tools/gen_placeholder_*.gd`) | — | propriété du projet | — | Prouvé |

Constats :
- **Aucun fichier de `assets/` n'a été identifié comme capture d'écran ou extrait brut d'un jeu officiel** ; les seules images officielles brutes sont les artworks PokeAPI. Des sprites RB 32 px (PokeAPI) figurent seulement en comparaison dans `docs/design/fiches-assets/dos-cadrage-rb/comparaison-dos-rb.webp` (documentation, hors APK Android).
- Les images brutes de Codex sont dans `build/art/` (hors dépôt, sur le Mac de Kevin). Les prompts sont versionnés (`tools/art/prompts/`, 178 fichiers, dont 143 « CONCEPT_* »).
- **Les conditions d'utilisation des services de génération (OpenAI / Codex, ChatGPT ; modèles Hugging Face) n'ont pas été relues** : elles encadrent la propriété et l'usage des sorties. Question pour l'avis compétent (§11).
- Les modèles 3D de *X/Y* **ne sont pas dans le dépôt** (`~/dev/kanto-2026-modeles/art-pokemon-pilote/`), mais **les 16 + 16 rendus et les 155 dos le sont**.

## 4. Polices

| Fichier | Auteur / licence (lue dans le fichier) | Utilisation | Poids dans l'APK |
|---|---|---|---|
| `assets/fonts/cinzel/Cinzel.ttf` (+ `OFL.txt`) | « Copyright 2020 The Cinzel Project Authors (github.com/NDISCOVER/Cinzel) », **SIL Open Font License 1.1** | bandeau « VS » du combat (`game/ui/theme/ui_tokens.gd:1676`, `game/ui/battle/vs_banner.gd`) | 136 Ko (source) |
| `assets/fonts/cormorant_garamond/CormorantGaramond.ttf` (+ `OFL.txt`) | « Copyright 2015 the Cormorant Project Authors (github.com/CatharsisFonts/Cormorant) », **SIL OFL 1.1** | titre serif du bandeau « VS » (`ui_tokens.gd:1680`) | 1,2 Mo (source) |
| Police par défaut du moteur (Open Sans, Noto Sans) | embarquée dans `libgodot_android.so` ; mentions « Open Sans Project Authors » présentes dans le binaire | tout le reste du texte du jeu (aucune autre `FontFile` : `grep` de `game/`) | comprise dans la bibliothèque |

Constats :
- Les deux polices sont **libres** (OFL 1.1, usage, redistribution et embarquement autorisés). Les polices sont ajoutées au dépôt le 2026-11-02 (entrée des Dresseurs), pas à l'initialisation.
- **L'APK ne contient aucun fichier `OFL.txt`** (extensions `.txt` non exportées). L'OFL demande que l'avis de copyright et la licence accompagnent la police redistribuée : à régler par une ligne dans le générique ou un écran « Licences » si la diffusion dépasse la maison (risque faible).
- Aucune police Nintendo / Game Freak n'est embarquée.

## 5. Musique, cris, bruitages, ambiances (`assets/audio/`, 39 Mo dans l'APK)

Source de vérité : `docs/tech/jalon-son.md` §5 bis à §5 sexies (lignes « à recopier telles quelles » pour cet inventaire), recoupées avec les fichiers.

| Contenu | Fichiers | Source | Licence / statut | Poids APK |
|---|---|---|---|---|
| **Musique** (54 morceaux) | `assets/audio/music/*.ogg` | Bande-son de **Pokémon Let's Go Pikachu / Évoli** (album « Super Music Collection »), fichiers téléchargés par Kevin sur **KHInsider** dans `~/Music/kanto-lets-go/`, puis découpés, bouclés, normalisés à −16 LUFS et encodés en OGG q3 par `tools/audio/prepare_music.py` | **© The Pokémon Company / Nintendo / Game Freak (Creatures, Game Freak).** Aucune licence d'utilisation : enregistrements officiels extraits d'un site tiers non officiel. Statut retenu dans le plan : « jeu privé, cercle restreint, jamais public » | 35,9 Mo |
| **Cris** (151) | `assets/audio/cries/1..151.ogg` | PokeAPI, dépôt `PokeAPI/cries`, `cries/pokemon/latest/` (OGG ; réencodés en mono q4 par le lot T11) | **© The Pokémon Company.** Le dépôt PokeAPI/cries est public mais cela ne vaut pas licence ; même statut que la musique | 1,8 Mo |
| **Bruitages** (69 identifiants, 84 fichiers) | `assets/audio/sfx/*.ogg` | **Kenney** (kenney.nl) : Interface Sounds, UI Audio, Impact Sounds, RPG Audio | **CC0** (domaine public). Aucune obligation d'attribution | 0,5 Mo |
| **Ambiances** (7 boucles) | `assets/audio/ambience/*.ogg` | **OpenGameArt** : beach-ocean-waves (qubodup, d'après un enregistrement de « jasinski »), wind (ignasd), ambient-bird-sounds (isaiah658), loopable-dungeon-ambience (jaggedstone), underwater-or-space-engine-rumble (gmason) | **CC0**, vérifiée page par page par la session du jalon Son (`jalon-son.md` §5 quater). Pas de nouvelle vérification ici (pas de réseau) | 0,8 Mo |

Constats :
- **Le seul point d'appui du statut « jeu privé » pour la musique et les cris est une décision de Kevin** (2026-10-24 / 2026-10-25), pas un droit. Un enregistrement de la bande-son officielle est une œuvre protégée ; l'usage dans un remake non officiel n'est autorisé par aucune licence connue.
- La musique est la **plus grosse ressource tierce protégée par poids** (35,9 Mo, 54 fichiers) et la plus facile à identifier par un tiers (écoute).
- Les fichiers d'origine (FLAC / MP3) ne sont pas dans le dépôt (`~/Music/kanto-lets-go/`) ; seuls les OGG encodés le sont (suivis par Git depuis le 2026-10-25).
- Le jalon Son note que `city`, `casino`, `rain` n'ont pas de fichier et que 38 bruitages manquent : le jeu reste muet à ces endroits (sans effet sur les droits).
- Les 54 morceaux portent chacun leur titre officiel dans `data/audio/tracks.json` (« Pallet Town Theme », etc.).
- Crédits à l'écran : aucun crédit à Kenney, OpenGameArt, aux auteurs d'ambiances (CC0 : non requis, mais courtois) ni à KHInsider.

## 6. Addons, moteur et bibliothèques

| Élément | Licence | Dans l'APK ? |
|---|---|---|
| `addons/gut` (GUT 9.7.1, Tom « Butch » Wesley) | **MIT** (`addons/gut/LICENSE.md`) | **Non** : exclu par `exclude_filter` (`addons/gut/*`) ; vérifié dans `build/kanto2026-debug.apk` du 2026-11-04 (0 entrée `addons`, 0 entrée `tests/`, `tools/`, `docs/`, `proto/`, `battle_proto`) |
| Moteur **Godot 4.7.2** (modèle d'export Android `libgodot_android.so`, 76 Mo non compressés, arm64-v8a) | **MIT** pour le moteur ; bibliothèques tierces intégrées (FreeType, HarfBuzz, ICU, libpng, libwebp, libvorbis / libogg, zlib, mbedTLS, etc.) sous licences permissives listées dans le « COPYRIGHT » de Godot ; MPL 2.0 mentionnée dans le binaire | Oui. **Aucun texte de licence n'est affiché dans le jeu ni livré dans l'APK** (aucun appel `Engine.get_license_text`) |
| Couche Android du modèle Godot : `androidx.*`, Kotlin (`kotlinx`), Guava (`com/google/common`) | Apache 2.0 | Oui (13 `classes*.dex`, ≈ 6 Mo) |
| Bibliothèques Google Play, Firebase, publicité, analytique | — | **Aucune** (aucune occurrence de `firebase`, `crashlytics`, `gms`, `play`, `admob`, `analytics`, `vending` dans les `.dex`) |
| `tools/` (Python, scripts Blender, notebook Colab), `proto/` | code du projet | Non (exclus) |

Constats :
- La licence MIT de Godot demande que l'avis de copyright soit conservé dans « toutes les copies ou parties substantielles ». Godot l'affiche dans son menu « À propos » de l'éditeur, pas dans un export : un écran ou un fichier « Licences » est l'usage courant (Godot propose `Engine.get_license_text()`). Risque faible, utile seulement hors de la maison.
- Les scripts du jeu sont livrés en `.gdc` (jetons GDScript, non chiffrés : `encrypt_pck=false`) ; **tout le contenu de l'APK (images, sons, données JSON) est extractible par quiconque détient le fichier** (outils de lecture de PCK/APK).

## 7. Données issues de Rouge/Bleu (noms, textes, statistiques, cartes)

| Donnée | Où | Origine connue | Statut |
|---|---|---|---|
| 151 espèces : noms français officiels, types, statistiques de base, courbes d'expérience, taux de capture, `base_exp`, talents d'évolution | `data/pokemon/species/*.json` (151) | Données de jeu de Rouge/Bleu (équivalent aux tables de PokeAPI et du désassemblage `pret/pokered`) | Les **faits de jeu** (statistiques, noms) sont couramment repris par les fans, mais les **noms, désignations et créatures** sont des marques et œuvres de Nintendo / Game Freak / Creatures. À soumettre à un avis compétent |
| 164 capacités : noms français officiels, type, puissance, précision, PP | `data/pokemon/moves/*.json` | idem. **Les descriptions sont rédigées pour le jeu** (par exemple la description de Coupe est une phrase propre au projet) | idem |
| 121 objets, boutiques, rencontres, Dresseurs (≈ 42 fichiers de Dresseurs), CT/CS | `data/items`, `data/shops`, `data/encounters`, `data/trainers` | Rouge/Bleu pour les listes ; `tools/gen_tm_compatibility.py` lit six CSV de PokeAPI (téléchargés à la demande, non versionnés) pour la compatibilité CT/CS | idem |
| Cartes (grilles) | `tools/plans/*.txt`, `tools/art/*_rb_decode.py` | Plusieurs scripts **lisent un désassemblage `pokered` local** (`maps/*.blk`, `gfx/blocksets/*.bst`, `data/maps/objects/*.asm`) passé en argument ; le désassemblage **n'est pas dans le dépôt** (« jamais embarqué dans le dépôt », en-têtes des scripts). Les grilles issues de ce décodage sont ensuite retouchées | La disposition des cartes de Rouge/Bleu est une œuvre de Game Freak ; les grilles du projet en sont dérivées, sans les images d'origine |
| Dialogues, PNJ, cinématiques | `data/dialogues` (139 fichiers, 640 Ko), `data/npcs`, `data/cutscenes`, `data/story` | **Textes rédigés pour le projet** (« textes validés par Kevin », dossiers de conception) ; certaines répliques de Rouge/Bleu sont remaniées ou citées dans l'esprit (par exemple l'introduction de Chen, « Bienvenue dans le monde des Pokémon ! ») | Texte propre au projet, mais personnages, lieux, scénario et noms (Chen, Régis / Blue, Sacha, Léo…) sont ceux de la franchise |

Aucun ROM, aucun fichier `.gb`, `.asm`, `.blk`, aucun désassemblage n'est suivi par Git (`git ls-files` : zéro occurrence).

## 8. Confidentialité

### 8.1 Ce que le jeu écrit (dossier `user://`)

Sur Android, `user://` = le dossier privé de l'application (`/data/data/dev.kevin.kanto2026/files/`), inaccessible aux autres applications.

| Fichier | Contenu | Quand | Source |
|---|---|---|---|
| `user://save.json` (+ `save.previous.json`) | la partie : prénom du joueur et du rival (choisis au démarrage, 10 caractères au plus ; défauts « Kevin », « Régis »), équipe, Sac, Pokédex, progression, date de début (`started_at`) et temps de jeu, **dates de l'appareil** (`DeviceClock`, ISO local sans fuseau) | à chaque sauvegarde (écriture atomique) et à la pause de l'application (`SessionLifecycle`) | `game/autoload/game_state.gd:323`, `game/systems/save/` |
| `user://settings.json` | réglages du jeu (vitesse du texte, joystick, volumes, etc.) | à la modification | `game/systems/settings/` |
| `user://perf_probe.json`, `debug_unlocks.json`, `debug_start.json` | n'existent que si on les dépose ; lus **seulement en build debug** (`OS.is_debug_build()`, scène principale) | jamais en release | `game/systems/debug/` |

- La sauvegarde est en **JSON clair, non chiffrée**. Elle ne contient aucune donnée personnelle hors le prénom saisi par le joueur.
- **`allowBackup=false`** dans le manifeste : la sauvegarde **n'est pas** sauvegardée par Android (ni cloud, ni transfert vers un nouveau téléphone). Elle est supprimée à la désinstallation (voir 34B / texte [D] « Désinstaller le jeu peut supprimer ta sauvegarde. »).
- Journaux : aucun fichier de journal du jeu ; les `print` / `push_warning` (≈ 360 appels dans `game/`) vont au journal système (logcat), lisible seulement par adb depuis un ordinateur autorisé. Le dossier `logs/` de Godot n'est pas activé dans `project.godot`.
- Rien ne lit le nom de l'appareil, l'identifiant publicitaire, la position, le micro, l'appareil photo, les contacts ou le presse-papiers (aucun appel `OS.get_unique_id`, `get_model_name`, `OS.request_permission`, etc. dans `game/`).

### 8.2 Permissions Android demandées (manifeste de l'APK, lu avec `aapt2`)

| Élément | Valeur |
|---|---|
| Permissions | **`android.permission.VIBRATE` seule** (`export_presets.cfg` : `permissions/vibrate=true`, rien d'autre) |
| **`INTERNET`** | **absente** : l'application ne peut ouvrir aucune connexion réseau |
| Accès au stockage partagé, appareil photo, micro, position, contacts, notifications | aucun |
| `uses-feature` | Vulkan (niveau et version) seulement |
| `minSdkVersion` / `targetSdkVersion` | 24 (Android 7.0) / 36 — **le minimum annoncé reste « à mesurer, pas à supposer »** (`jalon-34.md` §7.4) |
| `allowBackup` | `false` |
| `debuggable` | `true` dans l'APK debug du 2026-11-04 ; l'APK release signé n'a pas été construit ici (la clé n'existe pas encore : `docs/tech/release.md` §2) — **à vérifier à T2/T7 : `debuggable` doit être faux dans l'APK diffusé** |
| Composants exportés | un seul : l'activité de lancement ; le récepteur `ProfileInstallReceiver` d'AndroidX est exporté (normal) ; `FileProvider` non exporté |

### 8.3 Réseau et analytique

- Aucun `HTTPRequest`, `HTTPClient`, `WebSocket`, `TCPServer`, `ENet`, `OS.shell_open` ni URL (`http://`, `https://`) dans `game/` : zéro occurrence.
- Aucune bibliothèque d'analytique, de plantage distant ou de publicité dans l'APK (§6).
- Aucun mode en ligne : sans API réseau dans `game/` et sans permission `INTERNET`, les échanges et la Pension sont forcément locaux.
- Hors de l'APK : le **dépôt GitHub** reçoit le code et les assets (voir §10, risques B1 et D1) et la CI GitHub Actions les construit.

### 8.4 Ce qu'il faudrait dire à un proche qui installe l'APK

Texte proposé (à relire par Kevin ; rien n'est décidé) :

1. « C'est un jeu fait par Kevin pour la maison, non officiel et non commercial. Pokémon et tout ce qui va avec appartient à Nintendo, Game Freak, Creatures et The Pokémon Company. Ne le partage pas, ne le publie pas, ne le mets pas en ligne. »
2. « Il ne se connecte pas à Internet et ne demande qu'une autorisation : faire vibrer le téléphone. Il ne collecte ni envoie rien. »
3. « Ta partie est enregistrée seulement sur ce téléphone, dans le dossier privé de l'application (en clair, avec le prénom que tu as choisi). Désinstaller le jeu supprime la sauvegarde, et elle ne passe pas sur un nouveau téléphone. »
4. « Pour installer le fichier, Android te demandera d'autoriser "les applications de sources inconnues" pour l'application qui l'ouvre (messagerie, fichiers…) : c'est normal ; vérifie que le code SHA-256 donné par Kevin est le même, et retire l'autorisation ensuite. »
5. « Si le jeu se comporte bizarrement, dis-le à Kevin ; ne cherche pas de mise à jour dans un store : il n'y en a pas. »

## 9. Mentions et traces dans le jeu et dans le dépôt

- **Générique du jeu** (`data/story/credits.json`) : « Pokémon © Nintendo, Creatures, Game Freak » / « Projet personnel, non officiel, jamais diffusé » / « Pokemake — un remake personnel de Kevin ». Il ne crédite ni Kenney, ni OpenGameArt, ni les auteurs de rips 3D (Mystie demande à être créditée), ni les polices. Le bloc `{ "logo": "KANTO 2026" }` du même fichier garde l'ancien nom (à voir avec le jalon logo).
- **`README.md`** : « Projet de fan, non commercial et privé. » La même phrase de `jalon-34.md` / `CLAUDE.md` (« remake personnel »).
- **Dépôt GitHub** `YANKAMKEVIN/kanto-2026` : **public** (créé le 2026-09-26 ; rendu public « quelque temps » le 2026-10-26 pour la CI illimitée, décision de Kevin, mémoire `depot-public-ci`), 0 fork, 0 étoile, 0 observateur au 2026-11-04. Il suit dans Git : `assets/audio/music` (54 OGG, depuis le 2026-10-25), `assets/audio/cries` (151), `assets/sprites/pokemon/official` (152, depuis le 2026-10-06), `dos` (depuis le 2026-10-22), `battle_proto` (depuis le 2026-10-05), tout l'art Codex, `docs/` (676 Mo, dont 213 maquettes de référence) et les sauvegardes de test de Kevin (`tests/fixtures/save/*.json` : prénom « Kevin », rival « Régis »). La taille du dépôt (pack) est de 1,43 Gio : **une fois publié, l'historique reste lisible tant que le dépôt a été public, et un retour en privé ne reprend pas les copies éventuelles.**
- Secrets : aucun fichier `.jks`, `.keystore`, `.p12`, `.pem` ni mot de passe suivi ou ajouté dans l'historique (`git log --all --diff-filter=A`), et `tools/build_rc.sh` refuse un keystore situé dans le dépôt. Les occurrences de « secret » sont des objets ou des cartes du jeu (« Clé Secrète », « maison secrète »).
- Adresse e-mail de Kevin dans les 2 366 commits (`yankamkevin95@gmail.com`) : exposée par le dépôt public (information personnelle, non liée au jeu).
- Mémoires et documents anciens parlent encore de « dépôt privé » (`etat-projet.md:1976`, `pokedex-refonte.md:87`) : ils ne sont plus vrais tant que le dépôt est public.

## 10. Risques classés

Classement proposé, **à confirmer par Kevin** ; rien n'est décidé ici. « Cercle de la maison » = Kevin et moins de dix proches, APK installé à la main, jamais de store (`diffusion-cercle-restreint`).

### 10.1 Bloquant pour toute diffusion hors de la maison

| N° | Risque | Famille |
|---|---|---|
| **B1** | Musique de *Let's Go* (54 morceaux), cris (151), artworks officiels (152), rendus 3DS : œuvres protégées reproduites **sans licence** ; toute diffusion au-delà de la maison les rend identifiables et retirables (écoute, hachage). | `audio/music`, `audio/cries`, `sprites/pokemon/official`, `dos3d_*` |
| **B2** | Dos IA et planches de Pokémon dérivés d'artworks et de modèles officiels, avec un LoRA entraîné sur des images sous copyright : la « chaîne de rendu ne règle pas la question des droits » (`provenance-modeles-3d.md` §3). | `pokemon/dos`, `painted`, `placeholder` |
| **B3** | Noms, créatures, personnages, lieux, scénario et dispositions de cartes de Rouge/Bleu (noms français officiels, 151 espèces, 164 capacités, Champions, Rocket…), le tout sous marques et droits de Nintendo / Game Freak / Creatures / The Pokémon Company. | `data/*`, tous les décors et personnages |
| **B4** | Le mot « Pokemake » et le nom d'application « Pokemake » : proximité avec la marque « Pokémon » (avis compétent). | `config/name`, logo |
| **B5** | Carte de Kanto sans origine documentée. | `ui/map/kanto_placeholder.webp` |

### 10.2 Acceptable dans le cercle de la maison (hypothèse de Kevin : non commercial, privé, jamais public — **pas un droit**)

| N° | Risque | Remarque |
|---|---|---|
| **A1** | Les 5 familles ci-dessus, tant que l'APK reste dans la maison. | L'acceptabilité est une décision de Kevin, pas un fait juridique : la qualification d'une copie remise à des tiers, même proches et gratuite, est une question pour l'avis compétent (§11). |
| **A2** | Aucun texte de licence livré (OFL des polices, MIT de Godot) ; pas de crédit CC0. | Obligation de conservation d'avis (OFL, MIT) ; à régler (écran ou fichier « Licences ») si la diffusion s'élargit. |
| **A3** | Sauvegarde en clair, sans copie d'appareil à appareil (`allowBackup=false`). | Aucune donnée personnelle ; perte à la désinstallation (texte [D] déjà prévu). |
| **A4** | `debuggable=true` dans l'APK debug. | À vérifier faux dans l'APK release (T2 / T7). |
| **A5** | Contenu extractible : l'APK n'est pas chiffré (`encrypt_pck=false`) et les scripts sont en `.gdc` lisibles. | Normal pour un jeu Godot ; sans effet sur la vie privée. |

### 10.3 À décider (immédiat ou avant T7)

| N° | Sujet | Pourquoi maintenant |
|---|---|---|
| **D1** | **Dépôt public** : le laisser public jusqu'à quand, et avec ces fichiers ? | C'est la seule diffusion **déjà en cours** d'œuvres protégées (musique, cris, artworks), 9 jours après la décision du 2026-10-26, contraire à « jamais diffusé » du générique. Le retour en privé est prévu (`depot-public-ci`) ; la décision porte sur la date et sur l'historique. |
| **D2** | Preset iOS sans filtre d'exclusion. | À corriger avant tout build iOS, si l'iOS reste une cible (`ios.md`). |
| **D3** | Faut-il créditer / lister les sources dans le jeu (CC0, OFL, rips 3D, MIT) ? | Cohérence avec « jamais diffusé » ; à trancher avec A2. |
| **D4** | Nom « Pokemake », texte du générique (« jamais diffusé »), `README` (« privé ») : à aligner sur la décision de diffusion. | Évite une promesse fausse dans le jeu. |
| **D5** | Tracer, pour chaque fichier peint, s'il est « Codex seul », « Codex d'après référence officielle » ou « fait à la main » (aujourd'hui : déduit). | Ne coûte que du temps ; utile à l'avis compétent. |
| **D6** | Fournir le texte du §8.4 aux proches (message d'installation). | Doit être validé par Kevin. |

## 11. Questions que seuls Kevin ou un avis compétent peuvent trancher

Pour **Kevin** :
1. **Dépôt public (D1)** : repasser le dépôt en privé maintenant (CI limitée de nouveau) ou garder le public quelques jours ? Veux-tu que l'historique soit réécrit pour retirer musique, cris, artworks et rendus 3DS (décision lourde, hors du périmètre d'une session) ?
2. **Cercle de la maison** : confirmes-tu que les proches n'ont qu'à installer et jouer, sans copier ni partager le fichier ? Veux-tu l'écrire en tête du message d'installation (§8.4) ?
3. **Mention « jamais diffusé »** du générique : à garder, nuancer (« jamais publié ») ou compléter par une liste des sources ?
4. **Carte de Kanto** : d'où vient l'image fournie (outil, prompt) ? La conserver ?
5. **Mystie** (Nosferapti) demande à être créditée : fait-on un crédit, même dans la documentation ?
6. **Nom « Pokemake »** : le garder tel quel pour la maison ?
7. **Preset iOS** : filtre à corriger tout de suite ou quand l'iOS redevient actuel ?

Pour un **avis compétent** (juriste en propriété intellectuelle, pas une session) :
1. La distribution privée gratuite d'un APK à moins de dix proches d'une même maison, contenant des enregistrements et artworks officiels non licenciés, relève-t-elle du cadre privé ou d'une communication au public ?
2. Statut des **sorties d'IA** (Codex / ChatGPT / modèles Hugging Face dont un LoRA entraîné sur des images Pokémon) quand elles imitent des créatures et personnages protégés ; conditions d'utilisation des services.
3. Statut de la **disposition des cartes** de Rouge/Bleu reprise par décodage (`pokered`) puis retouchée, et des **textes** repris dans l'esprit de l'original.
4. Statut des **noms** (Pokémon, capacités, lieux) et du **nom « Pokemake »**.
5. Conséquences de l'**exposition passée** du dépôt public (neuf jours au 2026-11-04, historique complet), et quoi faire (retrait, avis aux ayants droit, rien).

## 12. À vérifier plus tard (T2 / T7, lecture de l'APK release)

- `debuggable` absent ou faux, signature release, `versionCode` 3400, mêmes permissions (`VIBRATE` seule), mêmes exclusions (`aapt2 dump permissions`, `unzip -l`).
- Taille de l'APK release (le debug de 612 Mo est une borne haute indicative).
- Reproduire les chiffres du §2 sur l'APK diffusé.

## 13. Commandes de reproduction

```bash
aapt2 dump permissions build/kanto2026-debug.apk
aapt2 dump xmltree --file AndroidManifest.xml build/kanto2026-debug.apk | grep -E "uses-permission|allowBackup|debuggable"
unzip -l build/kanto2026-debug.apk | grep -cE "addons|tests/|assets/tools|assets/docs|proto"   # 0 attendu
gh repo view --json visibility,url
git log --diff-filter=A --format='%ad' --date=short -- assets/audio/music | tail -1
```
