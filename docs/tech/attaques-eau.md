# Refonte des attaques Eau (décidée le 2026-11-10)

Suite de la refonte par famille de types, après l'Électrik et le Feu (`attaques-electriques.md`, `attaques-feu.md`). Avant : Pistolet à O, Surf et Hydrocanon étaient le même jet bleu mince, Écume se voyait à peine, Repli et Danse Pluie montraient l'aura bleue générique, Claquoir et Pince-Masse des coquille et pince peintes hors de la direction.

**Direction retenue par Kevin : A, « eau peinte »**, bleus clairs et turquoise, écume blanche, transparences et reflets, coups de pinceau visibles ; la même main que la foudre et la flamme peintes. Planche de référence : `docs/design/references/attaques/eau_direction_A.png` (directions B « océan profond » et C « cristal liquide » écartées). Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

**Décision de Kevin : on revoit toutes les attaques Eau sauf Bulles d'O**, qui reste telle quelle.

## Les dix attaques

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Repli | statut | Coque d'eau translucide qui se referme autour du lanceur ; rien vers la cible | `statut_plus` (aura bleue) |
| 2 | Écume | 40 | Nuée de petites bulles qui flottent vers la cible et éclatent | `bulles` |
| 3 | Pistolet à O | 40 | Petit jet fin et vif, petite éclaboussure | `eau` |
| 4 | Claquoir | 35, piège | Deux valves de coquillage d'eau qui se referment sur la cible | `contact`, impact `claquoir` |
| 5 | Bulles d'O | 65 | **Inchangée** (décision de Kevin) | `bulles`, variante `rafale` |
| 6 | Cascade | 80, physique | Chute d'eau qui s'abat sur la cible, gerbe au sol | `contact`, impact `cascade` |
| 7 | Surf | 90 | Grande vague qui déferle sur le terrain et engloutit la cible | `eau`, signature `surf` (jet) |
| 8 | Pince-Masse | 100, physique | Énorme pince d'eau qui s'abat, gerbe d'éclaboussures | `contact`, impact `pince_masse` |
| 9 | Hydrocanon | 110 | Jet énorme sous pression en spirale, explosion d'eau | `eau`, signature `hydrocanon` (jet) |
| 10 | Danse Pluie | statut | Pluie sur tout le terrain, ciel assombri ; rien sur la cible | `statut_plus` (aura bleue) |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**).
- Les Pokémon n'ont pas de pose de course ni de coup de poing : pour 4, 6 et 8, la charge de Contact existante porte le geste.
- La gradation de puissance doit se lire : Écume et Pistolet à O les plus petites, Hydrocanon la plus grosse.

## Étapes

1. Art : `tools/art/serie_cv_fx_eau.py` (Codex, `manifeste_eau.json`) ; masses d'eau détourées sur magenta et posées en mélange normal.
2. Familles, variantes et signatures dans `data/battle/move_fx/` ; briques nouvelles : vague qui traverse le terrain (Surf), pluie plein écran (Danse Pluie), coque sur le lanceur (Repli).
3. Vidéo des dix attaques : `game/battle/fx/fx_gallery.tscn -- --moves=withdraw,bubble,water_gun,clamp,bubble_beam,waterfall,surf,crabhammer,hydro_pump,rain_dance --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-10)

- **Art :** `tools/art/serie_cv_fx_eau.py` (Codex, 9 flipbooks et 16 particules, `manifeste_eau.json`). Vague, torrent, chute, gerbes, explosion, valve et pince détourées sur magenta, en mélange normal ; bulles, jets fins et pluie additifs sur noir. La chute d'eau a été peinte en 4 colonnes pleine hauteur (découpe propre, `_QUATRE_COLONNES`) ; la vague touche les bords de sa case (fondus, `_fondre_bords`). `mousse_eau` : `ecume` existe déjà.
- **Par attaque :** Repli `repli` (coque `coque_eau` sur le lanceur, brique `shield`) ; Écume `bulles` variante `ecume` (nuée de petites bulles) ; Pistolet à O `eau` (jet fin `jet_fin_eau`, petite éclaboussure) ; Claquoir, Cascade, Pince-Masse : même geste de Contact, art refait (`valve_eau`, `chute_eau` et `gerbe_eau`, `pince_eau`) ; Surf `surf` (brique `wave_sweep` : la vague se lève derrière le lanceur, traverse le terrain et engloutit la cible ; la signature `surf` est retirée) ; Hydrocanon signature `hydrocanon` (`torrent_spirale`, `explosion_eau`) ; Danse Pluie `danse_pluie` (brique `rain` : quatre tuiles de pluie, scène assombrie). Bulles d'O inchangée.
- **Valeurs par défaut [D] :** `bolt_height` (0,1 et 0,5), tailles d'impact et volée d'Écume dans `families.json` ; `RAIN_ALPHA`, `SURF_HEIGHT`, `SURF_PAST` de `move_fx_player.gd`.
- **Plus d'impact (retour de Kevin : « trop soft, ça fait léger ») :** eau plus dense (alpha renforcé des masses d'eau, `_densifier`), tailles et éclaboussures plus grandes (`SHELL_SIZE`, `PINCER_SIZE`, `CASCADE_SIZE`, gerbe ×1,5), secousse et zoom propres à une signature ou une variante d'impact (`shake`, `zoom` : Hydrocanon, Claquoir, Cascade, Pince-Masse), Surf et Pistolet à O plus forts, pluie opaque.
- **Bulles et jet (retour de Kevin : « on voit à peine les bulles, le pistolet est comme une ligne », « les bulles peuvent être plus grandes ») :** Écume en bulles opaques `bulle_eau` (planche `part_q`, mélange normal), taille de volée 0,12 ; Pistolet à O en jet dense `jet_pistolet` (mélange normal), `bolt_height` 0,2.
