# Refonte des attaques Combat (décidée le 2026-11-20)

Suite de la refonte par famille de types, après l'Électrik, le Feu, l'Eau, le Psy, la Plante et la Glace (`attaques-electriques.md`, `attaques-feu.md`, `attaques-eau.md`, `attaques-psy.md`, `attaques-plante.md`, `attaques-glace.md`). Choix du type : valeur par défaut [D] (le plus fourni après le Normal, Kevin a dit « passe au type suivant »). Avant : les neuf attaques Combat à dégâts étaient la course de Contact avec l'étoile `coup` ou l'onde `corps` communes ; Frappe Atlas avait sa famille `atlas` (vague 2) avec l'onde de choc commune.

**Direction retenue par Kevin : A, « impact peint »**, ondes et étoiles d'impact blanc crème aux bords déchirés, traînées de pinceau, poussière ocre, touches orange chaud ; la même main que la flamme, l'eau et la glace peintes. Planche de référence : `docs/design/references/attaques/combat_direction_A.png` (directions B « aura de combattant » et C « choc brut » écartées). Codex refuse la vraie scène de combat pour ce type (modération) : les planches montrent des créatures de remplacement. Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

**Décision de Kevin : les dix attaques sont refaites**, aucune n'est gardée telle quelle.

## Les dix attaques

Inventaire de `data/pokemon/moves/` (`type: "fighting"`), Johto compris.

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Double Pied | 30 ×2 | Deux petites étoiles d'éclat, la plus petite | `contact` `coup`, `multi` |
| 2 | Contre | 40 | Aura flamboyante sur le lanceur pendant l'élan, puis étoile | `contact` `coup` |
| 3 | Poing Karaté | 50 | Arc en croissant qui s'abat en diagonale, petite étoile | `contact` `coup` |
| 4 | Balayage | 50 | Arc rasant aux pieds de la cible, poussière | `contact` `coup` |
| 5 | Mawashi Geri | 60 | Grand arc circulaire autour de la cible, étoile | `contact` `coup` |
| 6 | Sacrifice | 80 | Traînée de vitesse derrière la ruée, grosse explosion d'éclat, contrecoup | `contact` `corps`, `contrecoup` |
| 7 | Pied Sauté | 100 | Traînée qui plonge d'en haut, explosion, onde au sol | `contact` `coup`, `chute` |
| 8 | Pied Voltige | 130 | La plus grosse : même plongeon, explosion énorme, onde qui traverse le terrain, nuage de poussière | `contact` `coup`, `chute` |
| 9 | Frappe Atlas | dégâts fixes | La cible est soulevée puis projetée ; onde de choc au sol peinte, cailloux, poussière ocre | `atlas` (onde commune) |
| 10 | Riposte | statut | Garde de lumière sur le lanceur pendant l'élan, puis éclair de choc | `contact` `corps` |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**). Effets puissants et bien visibles (matière dense, tailles généreuses, secousse, lumière à l'impact).
- La gradation de puissance doit se lire : Double Pied la plus petite, Pied Voltige la plus grosse.
- Les Pokémon n'ont pas de pose de coup de pied ni de poing : la course de Contact porte le geste, les marques peintes font le reste.

## Étapes

1. Art : `tools/art/serie_cv_fx_combat.py` (Codex, `manifeste_combat.json`).
2. Famille `combat`, variantes d'impact et briques dans `data/battle/move_fx/` et `game/battle/fx/move_fx_player.gd`.
3. Vidéo des dix attaques : `game/battle/fx/fx_gallery.tscn -- --moves=double_kick,reversal,karate_chop,low_kick,rolling_kick,submission,jump_kick,hi_jump_kick,seismic_toss,counter --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-20)

- **Art :** `tools/art/serie_cv_fx_combat.py` (Codex, 10 flipbooks et 16 particules, `manifeste_combat.json`), sur la chaîne de `serie_cv_fx_eau.py`. Étoiles, arcs, ondes, traînée et poussière sur magenta, en mélange normal ; aura de Contre, garde de Riposte et étincelles additives sur noir.
- **Famille `combat` :** course de Contact (`crouch`, `dash`) ; la variante d'impact porte la brique, la marque, ses rôles, la taille (`impact_size`, lue désormais aussi dans la variante d'impact), la secousse et la lumière (`light_peak`, `flashes`, idem). Briques neuves `slash_arc`, `low_sweep`, `spin_arc`, `plunge`, `rush` (`_pose_martial`) ; Double Pied, Contre et Riposte gardent l'étoile commune (`impact_star`), avec l'aura `aura_combat` ou `garde_choc` sur le lanceur pour les deux derniers. Frappe Atlas garde sa famille, repeinte (`onde_sol`, cailloux, poussière ocre).
- **Valeurs par défaut [D] :** tailles d'impact (Double Pied 1,3, Contre 1,7, Riposte 1,8, Poing Karaté et Balayage 1,9, Mawashi Geri et Frappe Atlas 2,2, Pied Sauté 2,6, Sacrifice 2,7, Pied Voltige 3,4), impact allongé (moitié du coup), secousses (2,5 à 6), lumière (0,35, Pied Sauté 0,5, Pied Voltige 0,65) dans `families.json` ; tailles des arcs et du plongeon (`MARTIAL_*`, `PLUNGE_*`) dans `move_fx_player.gd`.
