# QA téléphone — entrée des combats de Dresseur et effets (A17, 2026-11-04)

Session QA (aucune modification du code du jeu). Appareil : **Galaxy A17** (SM-A175F, série `R5GYB2R7W2Y`, USB, paysage 2340×1080, Ne pas déranger resté activé). Build : APK **debug 0.34.0 de `main` @ `f3470936`** (`tools/build_android.sh`, 610 Mo), installé par `adb push` + `pm install -r` (aucun APK release). Durée : ≈ 35 min, départs de débogage uniquement, aucune partie réelle. Captures et vidéos (non versionnées) : `build/qa/` du worktree `qa-entree-combats-c88367` ; une image jointe : `docs/design/reference/qa/qa-a17-surf-tortank-dos-pixel.jpg`.

## Verdict

**Aucun P0, aucun P1.** L'entrée des combats de Dresseur fonctionne sur l'A17 dans les six cas joués, la séquence « VS » est lisible et conforme à la maquette, et **aucun toucher ne la saute** (240 touchers en 17 s, deux fois). Les effets des vagues 1 et 2 ne saccadent pas hors du chargement à froid du premier effet. Reste cinq P2 (dos de Tortank pixélisé déjà connu, petites saccades de chargement, durée de l'entrée à juger, cadence A17, outillage de mesure).

## Scénarios et résultats

| # | Scénario (départ de débogage) | Résultat | Preuve |
|---|---|---|---|
| 1 | **Ordinaire — Gamin Hugo, Route 3** (`route_3`) | OK. Fondu depuis la carte, dresseurs en place sur le décor peint de la Route 3, cartouche de Poké Balls de l'adversaire, « Gamin Hugo veut se battre ! », lancer, « Gamin Hugo envoie Rattata ! », « En avant, Reptincel ! ». Textes entiers, lisibles. Premier combat de la session : image la plus lente 7 i/s (≈ 140 ms) à l'ouverture, voir P2-2 | `build/qa/r3_entree_gamin.mp4`, `r3_0*.png` |
| 2 | **Ordinaire — Campeur Liam, Arène d'Argenta** (`pewter_gym`) | OK, même séquence dans le décor de l'Arène | `pewter_liam_tap_burst.mp4` |
| 3 | **Champion — Pierre, Arène d'Argenta** (`qa_pierre`, nouveau : Liam déjà battu) | OK. Dresseurs en place, puis « VS » : banderole rouge « PIERRE / Champion d'Arène d'Argenta » avec portrait, banderole bleue « KEVIN » avec portrait, éclair « VS », les banderoles s'écartent, puis lancers (« Pierre envoie Racaillou ! », « En avant, Reptincel ! »). Titre petit mais net | `pierre_vs_entree.mp4`, `pierre_vs_tap_continu.mp4` |
| 4 | **Champion — Morgane, Arène de Safrania** (`sabrina`, tapis du centre : un pas à gauche, face au nord) | OK, même séquence « VS » (musique `battle_gym_leader`) dans le décor violet de l'Arène | journal ; vidéo perdue (supprimée par erreur sur le téléphone avant la fin de l'enregistrement) |
| 5 | **Rival — « Régis », titre « Rival », Route 24** (`rival_cerulean`) | OK. « VS » avec portrait du rival et « Rival » sous le nom, décor du pont d'Azuria, lancers de Roucoups puis de Salamèche | `rival_vs_tap_burst.mp4` |
| 6 | **Surf — Nageur Tanguy, Route 19** (`trailer_surf`) | OK. Le joueur reste sur sa monture dans le monde, puis combat sur le décor de mer ouverte au coucher de soleil (monture visible au premier plan à l'entrée, cartouche, lancer, « Nageur Tanguy envoie Hypotrempe ! »). Le dos de Tortank est pixélisé : P2-1 | `surf_nageur_entree.mp4`, image jointe |
| 7 | **Non sautable** | OK, voir ci-dessous | journaux horodatés |

### Séquence non sautable

Méthode : un script lancé **sur le téléphone** (`nohup`, indépendant des redémarrages d'adb) envoie 240 touchers (deux positions alternées, dont la zone du bandeau de texte) en 17 s, à partir du premier toucher de dialogue ; le journal horodate `battle_*` (début), `battle_intro`, premier `send_out` (adversaire), second `send_out` (joueur). Référence : même combat sans rafale.

| Cas | début → `battle_intro` | → lancer adverse | → lancer du joueur |
|---|---|---|---|
| Ordinaire (Liam), 240 touchers | 1,34 s | +1,14 s | +1,19 s |
| Ordinaire (Liam), sans rafale | 1,26 s | +1,18 s | +1,16 s |
| Champion Pierre « VS », 240 touchers | **2,76 s** | +1,19 s | +1,14 s |
| Champion Pierre « VS », touchers espacés | 2,76 s | +1,17 s | +1,14 s |
| Morgane « VS », ≈ 135 touchers (adb) | 2,81 s | +1,18 s | +1,14 s |
| Rival « VS », ≈ 120 touchers (adb) | 2,79 s | +1,13 s | +1,19 s |

Aucune étape raccourcie ; la vidéo `pierre_vs_tap_continu.mp4` montre le « VS » entier (≈ 1,4 s) puis les deux lancers pendant la rafale. (Le même essai en Surf n'est **pas** compté : le serveur adb a redémarré en cours de route et la plupart des touchers se sont perdus.)

## Cadence (A17)

Journal `[perf]` toutes les 2 s (`fps` moyenne, `min` image la plus lente).

| Situation | fps | min | Note |
|---|---|---|---|
| Exploration Route 3 / Arène | 46–54 | 20–39 | cohérent avec le plafond ≈ 50 i/s de l'A17 (profilage J33, RP-093) |
| Combat Hugo (Route 3) | 43–47 | 23–40 | `fps=38 min=7` à l'ouverture du combat |
| Combat Pierre / Liam (Arène) | 42–47 au repos, 44–56 en attaquant | 17–36 | `min=17` après une Flammèche |
| Combat Morgane (Arène de Safrania) | 52–58 | 30–42 | `min=8` une fois (≈ 125 ms) à l'ouverture du panneau d'équipe après un K.O. (textures 357 → 370 Mo) |
| Combat en Surf (Route 19) | 43–53 | 25–37 | |
| Textures en combat | 325–370 Mo | | sous le repère de 384 Mo |

**Effets des vagues 1 et 2** (galerie d'effets `qa_fx_vagues` : 46 attaques, puis `qa_fx_vague2` : 28 attaques de la vague 2, mode Complètes, décor de la Route 1) : moyenne 57,5–60 i/s pour chaque attaque ; image la plus lente ≥ 30 i/s partout, sauf le **premier effet joué** (chargement à froid : `tail_whip` min 8,3 ; `teleport` min 8,1) et `explosion` à froid (min 19,6 ; 40,0 au tour suivant). Enregistrement d'écran des 28 attaques de la vague 2 (54 s) : ≥ 55 images par seconde dans toutes les secondes, plus grand écart entre deux images 36 ms. Dans les vrais combats, Flammèche, Griffe, Rugissement, Groz'Yeux, Psychique (adverse), Surf et Pistolet à O n'ont montré aucune saccade visible (relevés ci-dessus). Les 9 attaques à confronter à Rouge (liste de l'état du projet) n'ont pas été jugées sur le fond, seulement sur la fluidité.

Textes coupés ou illisibles : **aucun** relevé (HUD, menus d'attaque — « LANCE-FLAMMES », « PISTOLET À O » entiers —, panneau d'équipe, dialogues, titres des banderoles, bandeaux de message).

## Défauts et reports

| Id | P | Constat | Détail |
|---|---|---|---|
| P2-1 | P2 | **Dos de Tortank pixélisé** (repli) en combat, très visible en Surf, où Tortank est la monture attendue | Déjà suivi : RP-010 (8 dos manquants, repli accepté par Kevin jusqu'à la phase DA). Image : `docs/design/reference/qa/qa-a17-surf-tortank-dos-pixel.jpg` |
| P2-2 | P2 | **Saccade de chargement** : première image de combat de Dresseur ≈ 140 ms (`min=7`, Hugo), premier effet de la galerie ≈ 120 ms, `explosion` à froid ≈ 50 ms, panneau d'équipe après K.O. ≈ 125 ms | Voisin de RP-261 (50–60 ms mesurés au J33) mais plus long avec la nouvelle entrée. À précharger (décor, sprites de dresseurs, famille d'effet) si le temps le permet ; pas gênant en jeu |
| P2-3 | P2 | **Cadence A17 : 42–54 i/s** en combat comme en exploration (60 seulement dans la galerie, décor léger). Pas de régression : plafond A17 déjà mesuré | S24 non mesuré (indisponible) |
| P2-4 | P2 | **Durée de l'entrée** : ordinaire ≈ 3,6 s du début du combat au lancer du joueur (deux lancers de ≈ 1,15 s), Champion/rival ≈ 5,1 s (« VS » ≈ 1,4 s) ; la décision de Kevin annonce ≈ 2 s [D] pour l'ordinaire | Conforme à `data/battle/trainer_intro.json`. Une valeur à juger, pas un bug : sur 34 classes ordinaires répétées, l'entrée jamais sautable pèse. À valider par Kevin |
| P2-5 | P2 | **Outillage** : (a) la galerie d'effets (`fx_gallery`) affiche `fps=59.0 min=59.0` pour toutes les attaques à partir de la 19e du premier essai (46 attaques) et pour tout le tour suivant ; les essais de 28 attaques sont corrects, mesure à fiabiliser avant de s'y fier ; (b) le serveur adb redémarre toutes les 2–3 min : les rafales de touchers doivent tourner sur le téléphone | Aucun effet sur le jeu |

## État laissé

- **A17 rendu** : appli arrêtée, `files/debug_start.json` retiré, **aucune sauvegarde** (le dossier `files/` ne contient que `shader_cache` et `vulkan`, comme à la remise), fichiers temporaires de `/data/local/tmp` et vidéos de `/sdcard` supprimés, **Ne pas déranger toujours activé** (`zen_mode=1`). L'APK debug 0.34.0 de `main` remplace celui de la branche Johto.
- Départs de débogage ajoutés (`tools/debug_start/`, décrits dans le README) : `qa_pierre`, `qa_fx_vagues`, `qa_fx_vague2`. Tests ciblés (`debug_start_starter`, `key_item_repair`) verts.
- Non joué : combat de Dresseur avec Pokémon du monde (labo du rival), Giovanni, Ligue, grands combats sur les 8 Champions autres que Pierre et Morgane, victoire complète d'un Champion (fin de combat, badge).

## Reproduire

```bash
tools/build_android.sh   # puis adb push + adb shell pm install -r (jamais adb install, jamais d'APK release)
# départ : écrire tools/debug_start/<nom>.json dans files/debug_start.json par run-as (voir tools/deploy_s24.sh)
# noms : route_3 · pewter_gym · qa_pierre · sabrina · rival_cerulean · trailer_surf · qa_fx_vagues · qa_fx_vague2
```
