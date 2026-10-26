# Série CV-FX 1 — effets peints des familles du plancher (Combat vivant, CV.1)

> Chantier « Combat vivant » (`docs/tech/combat-vivant.md` §2.7, §2.9 barre de qualité, §3.4 art à
> produire). Processus : `docs/design/phase-da-cadrage.md` §3.3. Outil : `tools/art/serie_cv_fx.py`.
> Statut : **planche validée par Kevin le 2026-10-26 (DA-6)** ; non branché au jeu (CV.0 / CV.1 le font).

## 1. Périmètre

- **12 flipbooks** (8 images clés → 16 images par interpolation en boucle, 320 × 320, atlas 4 × 4) :
  jet de flammes, boule de feu, gerbe de braises, jet d'eau, éclaboussure, arc électrique A et B,
  décharge en étoile, rafale de feuilles, nuage de spores, onde psy, poussière et éboulis.
- **23 sprites de particules** (192 × 192) : flamme, braise, étincelle, lueur douce, étoile d'impact,
  griffes, mâchoires, onde sonore ; goutte, bulle, feuille, pétale, plume, éclat de glace, caillou,
  flocon ; fumée, poussière, spore, os, poing, étoile, aiguille. **Le cœur (Grobisou) est rejeté** : le rose part avec la clé magenta ; à refaire sur fond noir dans la vague 2.
- Sortie : `assets/sprites/battle_fx/` (`fb_*.webp`, `p_*.webp`, `manifeste_vague1.json`).

## 2. Décisions de production (valeurs par défaut)

| Sujet | Valeur |
|---|---|
| Style | peint, même main que le monde, **aucun pixel art**, dégradé de 3 à 4 teintes (cœur presque blanc, couleur, bord sombre), lumière **neutre** (l'effet brille de lui-même) |
| Une image Codex = | une **planche de 8 images clés** (4 × 2, 1536 × 1024) par flipbook ; une planche de 8 sprites par lot de particules |
| Transparence | Codex ne rend pas d'alpha : fond **noir pur** pour la lumière (feu, éclair, psy, lueurs), alpha tiré de la luminance, **mélange additif** dans le jeu ; fond **magenta pur** pour la matière (eau, feuilles, fumée, poussière, glace), détourage par distance de couleur et retrait de la frange magenta, **mélange normal** |
| Cadrage | cadrage **commun** à toutes les images d'un flipbook (l'effet ne saute pas) ; carré 320 px |
| Interpolation | fondu enchaîné entre images clés voisines, la dernière revient à la première (boucle) ; l'art définitif d'une famille pourra demander 16 clés réelles |
| Orientation | jets, boules et arcs partent du bord **gauche** vers la droite ; le code retourne, tourne et met à l'échelle (profondeur §2.9) |
| Génération | `tools/art/generer.sh` (Codex, abonnement ChatGPT, aucune API payante) ; prompts versionnés dans `build/art/prompts/cv_fx/` (régénérables par `--prompts`) ; essais `r1` ; une révision `rN+1` se génère en écrivant le prompt révisé |

## 3. ADN visuel des effets (v1, recopié dans chaque prompt)

Voir `ADN_FX` dans `tools/art/serie_cv_fx.py` : rendu peint, couleur en 3 à 4 teintes, lumière neutre,
aucun sol, décor, personnage, Pokémon ni texte.

## 4. Validation

`docs/design/fiches-assets/cv-fx-1/planche.png` (tous les flipbooks et toutes les particules, sur un
fond de combat sombre, au mélange du jeu) et un **GIF en boucle par flipbook** (`*.gif`). Kevin note
par identifiant : retenu, ou à reprendre (avec la remarque). Les identifiants servent de `RETENUS`.
