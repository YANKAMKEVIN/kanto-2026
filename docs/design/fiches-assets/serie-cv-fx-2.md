# Série CV-FX 2 — effets peints du lot P1 (Combat vivant, CV.1 / CV.2)

> Suite de `serie-cv-fx-1.md` (mêmes décisions de production : planches de 8 images clés, cadrage commun,
> 16 images par interpolation, ADN des effets, orientation vers la droite). Outil :
> `tools/art/serie_cv_fx2.py` (importe `serie_cv_fx.py`). Classement des attaques :
> `docs/tech/combat-vivant-lots.md` (généré par `tools/art/classer_lots_cv.py`).
> Statut : **planche validée par Kevin le 2026-10-27 (DA-6)** ; non branché au jeu.

## 1. Ce que le lot P1 demande (40 attaques, familles : contact 13, statut moins 5, poison 5, son 4, vent 3, plante 3, statut plus 3, eau 2, psy, feu)

La vague 1 couvre déjà : jet de flammes, boule et gerbe de feu (Flammèche), jet d'eau, éclaboussure, arcs et
décharge (Éclair), feuilles, spores, onde psy, poussière et éboulis (Jet-Pierres), et 23 particules.
La vague 2 comble le reste de P1 :

| Besoin P1 | Effet (flipbook) | Attaques concernées |
|---|---|---|
| Écume | `bulles_eclatent` | Écume |
| Poison | `nuage_poison`, `giclee_poison` | Poudre Toxik, Purédpois, Acide, Détritus, Dard-Venin (+ particules) |
| Vent | `tourbillon_vent` | Tornade, Cyclone, Picpic |
| Son | `onde_sonore` | Rugissement, Berceuse, Ultrason, Grincement, Sonicboom |
| Fumée | `fumee_volutes` | Brouillard, retombées |
| Soin | `lumiere_soin` | famille soin (Repos…) |
| Statut plus | `aura_montante` | Armure, Boul'Armure, Croissance, Puissance |
| Contact corps | `onde_choc` | Charge, Écras'Face, Frénésie |
| Contact griffe | `entailles_griffes` | Griffe, Tranche |
| Statut moins | `jet_sable` | Jet de Sable (+ Groz'Yeux avec l'œil menaçant) |
| Plante | `lianes_fouet` | Fouet Lianes, Ligotage |

Pistes du §3.4 **non faites** (le lot P1 n'en a pas besoin) : explosion, rayon d'énergie, rayon de glace,
vague, ombre spectrale, flamme de dragon : P2 et P3.

## 2. Fonds (changement par rapport à la vague 1)

Trois fonds, selon la couleur : **noir** (lumière, additif), **magenta** (matière), **vert pur** (matière
violette ou rose, que la clé magenta détruit : poison, cœur, psy, ombre ; le cœur de Grobisou, rejeté en
vague 1, est refait ici). Les identifiants et mélanges sont dans `manifeste_vague2.json`.
