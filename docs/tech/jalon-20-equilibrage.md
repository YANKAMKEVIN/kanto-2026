# Jalon 20 — simulations d'Erika et de Giovanni (T8)

> **Information pour Kevin (Q-3). Aucune donnée de jeu n'a été changée** : Erika et Giovanni
> restent aux niveaux de Rouge/Bleu dans `data/trainers/` (T7). Les réglages « essayés »
> n'existent que dans le scénario de simulation (`tools/sim/celadon_thresholds.json`).
> Plan : `jalon-20.md` §3 (T8), dossier 23 §11.3 et §13.5. Modèle : `jalon-13-equilibrage.md`.

Branche `j20-t7-data` (T7 puis T8, non fusionnée), 2026-10-16, architecte.

## 1. Méthode

- Outil : `tools/simulate_mt_moon.gd` **tel quel** (vrai moteur, vraie IA, vraies données ; une
  graine = une partie), avec un scénario nouveau `tools/sim/celadon_thresholds.json` (format des
  seuils du J13 : un combat par partie, équipe soignée, **sans reprise** : taux de victoire au
  premier essai). Pas d'outil `simulate_celadon.gd` : le simulateur du J12–J13 suffit.
- **1 000 graines par ligne** (écart-type ≤ 1,6 point : les écarts < 3 points ne comptent pas).
- Adversaires : Erika et Giovanni **tels que dans `data/`** (T7 : IA `smart`, changement de
  Pokémon, capacités RB sans capacité en attente : Rafflesia avec Méga-Sangsue, Onix avec Charge au
  lieu de Frénésie, Kangourex Poing Comète + Morsure) et des réglages de comparaison.
- Équipes « arrivée J19 » (estimées : aucune partie réelle à ce stade) : starter évolué **N26,
  N28, N30**, Roucoups N−3 (Tornade, Jet de Sable, Vive-Attaque : Cyclone, sans effet, retiré),
  Papilusion N−5 (Choc Mental gardé, poudres, Ultrason) ; variantes : Férosinge N−2 au lieu de
  Papilusion ; Carabaffe avec la **CT11** Bulles d'O (Ondine) ; Reptincel avec la **CT28** Tunnel
  (Cap d'Azuria). Capacités au niveau sinon (aucune autre CT, pas d'entraînement libre).
- Joueurs : **attentif** (IA `smart` du jeu, Super Potion quand le prochain coup peut mettre K.O.)
  avec **0, 3 ou 5 Super Potions** ; **expert** (attaque la plus forte, change de Pokémon quand un
  autre est nettement mieux placé) avec 3 ; **naïf** (attaque au hasard, aucun objet).
- Lecture des tableaux : « 86 · 99 · 100 » = attentif avec 0 · 3 · 5 Super Potions ; « \| »
  sépare N26, N28 et N30.

## 2. Erika (Arène de Céladopole, après 5 Dresseuses)

| Réglage | Reptincel N26 \| N28 \| N30 | Herbizarre N26 \| N28 \| N30 | Carabaffe N26 \| N28 \| N30 |
|---|---|---|---|
| **Données (RB) : Empiflor 29, Saquedeneu 24, Rafflesia 29** | 86 · 99 · 100 \| 100 · 100 · 100 \| 100 · 100 · 100 | 22 · 94 · 98 \| 89 · 100 · 100 \| 100 · 100 · 100 | 1 · 11 · 37 \| 14 · 42 · 67 \| 43 · 72 · 81 |
| (a) Empiflor 27, Saquedeneu 24, Rafflesia 27 | 100 · 100 · 100 \| 100 · 100 · 100 \| 100 · 100 · 100 | 86 · 100 · 100 \| 100 · 100 · 100 \| 100 · 100 · 100 | 10 · 35 · 64 \| 47 · 79 · 86 \| 79 · 94 · 94 |
| (d) Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29 | 99 · 100 · 100 \| 100 · 100 · 100 \| 100 · 100 · 100 | 52 · 100 · 100 \| 99 · 100 · 100 \| 100 · 100 · 100 | 16 · 83 · 92 \| 76 · 99 · 99 \| 99 · 100 · 100 |
| (c) RB, IA `random` | 99 · 100 · 100 \| 100 · 100 · 100 \| 100 · 100 · 100 | 71 · 99 · 99 \| 96 · 100 · 100 \| 100 · 100 · 100 | 64 · 96 · 97 \| 90 · 99 · 99 \| 98 · 100 · 100 |
| (b) RB, Poudre Dodo → Acide | 20 · 69 · 72 \| 89 · 97 · 98 \| 100 · 100 · 100 | 0 · 0 · 2 \| 0 · 10 · 22 \| 3 · 52 · 65 | 0 · 1 · 4 \| 1 · 16 · 31 \| 10 · 57 · 67 |

Expert (3 Super Potions) · naïf, données :

| Réglage | Reptincel N26 \| N28 \| N30 | Herbizarre N26 \| N28 \| N30 | Carabaffe N26 \| N28 \| N30 |
|---|---|---|---|
| **Données (RB) : Empiflor 29, Saquedeneu 24, Rafflesia 29** | 99 · 47 \| 100 · 90 \| 100 · 99 | 95 · 3 \| 100 · 44 \| 100 · 91 | 17 · 1 \| 52 · 18 \| 78 · 62 |

Autres équipes (attentif 0 · 3 · 5) :

| Réglage | Reptincel 26, Férosinge 24, Roucoups 23 | Carabaffe 26, Férosinge 24, Roucoups 23 | Carabaffe 26 + Bulles d'O (CT11) | Reptincel 26 + Tunnel (CT28) | Reptincel 28 + Tunnel (CT28) |
|---|---|---|---|---|---|
| **Données (RB) : Empiflor 29, Saquedeneu 24, Rafflesia 29** | 33 · 88 · 94 | 0 · 0 · 3 | 1 · 11 · 37 | 86 · 99 · 100 | 100 · 100 · 100 |
| (a) Empiflor 27, Saquedeneu 24, Rafflesia 27 | 80 · 98 · 99 | 0 · 8 · 26 | 10 · 35 · 64 | 100 · 100 · 100 | 100 · 100 · 100 |
| (d) Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29 | 52 · 95 · 98 | 0 · 1 · 12 | 16 · 82 · 91 | 99 · 100 · 100 | 100 · 100 · 100 |

- **Salamèche facile, Carapuce difficile** : c'est ce que le plan attendait. Avec les niveaux RB,
  Carabaffe a besoin du N30 et de potions (43 · 72 · 81) ; à N26, 1 · 11 · 37. Le mur est
  Empiflor 29 en tête (Tranch'Herbe, super efficace).
- Bulbizarre passe avec des potions (94 % à N26 avec 3), mal sans (22 %).
- L'**ordre** compte plus que les niveaux : Saquedeneu en tête (d) laisse Rafflesia N29 et donne
  Carabaffe N26 83 % (3 Super Potions).
- (b) Retirer Poudre Dodo la rend **plus dure** : l'IA perd des tours à endormir ; ce n'est pas un
  levier. L'IA `random` (c) la rend très facile (Carabaffe N26 : 96 %).

## 3. Giovanni (repaire, B4F)

| Réglage | Reptincel N26 \| N28 \| N30 | Herbizarre N26 \| N28 \| N30 | Carabaffe N26 \| N28 \| N30 |
|---|---|---|---|
| **Données (RB) : Onix 25, Rhinocorne 24, Kangourex 29** | 0 · 1 · 7 \| 0 · 5 · 20 \| 0 · 21 · 54 | 0 · 0 · 5 \| 0 · 8 · 40 \| 5 · 67 · 90 | 0 · 4 · 33 \| 0 · 30 · 73 \| 4 · 70 · 92 |
| (f) Kangourex 27 | 0 · 2 · 10 \| 0 · 11 · 42 \| 1 · 49 · 84 | 0 · 6 · 40 \| 0 · 41 · 80 \| 22 · 90 · 98 | 0 · 34 · 78 \| 3 · 74 · 94 \| 17 · 94 · 98 |
| (a) Kangourex 25 | 0 · 3 · 16 \| 0 · 25 · 66 \| 2 · 74 · 94 | 0 · 27 · 70 \| 2 · 72 · 93 \| 43 · 96 · 99 | 1 · 64 · 91 \| 9 · 89 · 97 \| 34 · 98 · 99 |
| (d) Onix 23, Rhinocorne 22, Kangourex 25 | 0 · 12 · 45 \| 1 · 58 · 87 \| 6 · 92 · 97 | 0 · 38 · 79 \| 6 · 81 · 96 \| 57 · 98 · 100 | 2 · 69 · 92 \| 16 · 93 · 98 \| 49 · 99 · 100 |
| (c) RB, IA `random` | 0 · 0 · 1 \| 0 · 2 · 4 \| 0 · 8 · 12 | 0 · 2 · 8 \| 1 · 15 · 35 \| 19 · 65 · 76 | 0 · 6 · 20 \| 1 · 30 · 49 \| 13 · 63 · 76 |
| (b) RB, Kangourex sans Morsure | 0 · 4 · 14 \| 0 · 16 · 26 \| 1 · 42 · 47 | 0 · 0 · 0 \| 1 · 3 · 5 \| 17 · 34 · 48 | 0 · 0 · 0 \| 1 · 4 · 6 \| 9 · 21 · 30 |
| (e) Kangourex 27 sans Morsure | 0 · 6 · 18 \| 0 · 29 · 46 \| 3 · 70 · 78 | 0 · 0 · 1 \| 3 · 10 · 18 \| 36 · 60 · 75 | 1 · 2 · 2 \| 5 · 12 · 21 \| 22 · 45 · 60 |

Expert (3 Super Potions) · naïf :

| Réglage | Reptincel N26 \| N28 \| N30 | Herbizarre N26 \| N28 \| N30 | Carabaffe N26 \| N28 \| N30 |
|---|---|---|---|
| **Données (RB) : Onix 25, Rhinocorne 24, Kangourex 29** | 4 · 0 \| 12 · 0 \| 38 · 0 | 0 · 0 \| 6 · 0 \| 65 · 1 | 9 · 0 \| 41 · 0 \| 75 · 2 |
| (a) Kangourex 25 | 9 · 0 \| 49 · 0 \| 91 · 1 | 28 · 0 \| 71 · 0 \| 96 · 26 | 74 · 0 \| 92 · 6 \| 97 · 24 |
| (d) Onix 23, Rhinocorne 22, Kangourex 25 | 28 · 0 \| 82 · 0 \| 98 · 3 | 37 · 0 \| 80 · 3 \| 98 · 37 | 76 · 0 \| 95 · 9 \| 99 · 38 |

Autres équipes (attentif 0 · 3 · 5) :

| Réglage | Reptincel 26, Férosinge 24, Roucoups 23 | Carabaffe 26, Férosinge 24, Roucoups 23 | Carabaffe 26 + Bulles d'O (CT11) | Reptincel 26 + Tunnel (CT28) | Reptincel 28 + Tunnel (CT28) |
|---|---|---|---|---|---|
| **Données (RB) : Onix 25, Rhinocorne 24, Kangourex 29** | 2 · 14 · 29 | 0 · 10 · 41 | 0 · 59 · 88 | 4 · 18 · 29 | 5 · 32 · 61 |
| (a) Kangourex 25 | 7 · 34 · 47 | 6 · 70 · 95 | 25 · 96 · 97 | 5 · 43 · 71 | 18 · 92 · 98 |
| (d) Onix 23, Rhinocorne 22, Kangourex 25 | 26 · 79 · 91 | 25 · 86 · 99 | 32 · 96 · 98 | 7 · 65 · 89 | 40 · 94 · 100 |

- **Giovanni RB est un mur pour les trois starters** (≤ 8 % à N28 avec 3 Super Potions, sauf
  Carabaffe 30 %). Le mur est **Kangourex N29** (100 PV, Vitesse 90, Morsure qui apeure, Poing
  Comète 2 à 5 coups) : l'IA rappelle Onix dès qu'il est mal placé (changement de Pokémon du J13)
  et envoie Kangourex tout de suite.
- **Bulbizarre n'est pas un « cas facile »** (hypothèse du plan) : Onix est rappelé avant de
  subir Fouet Lianes, et Kangourex est neutre. Reptincel est le plus mal loti (Flammèche résistée
  par Onix et Rhinocorne), même avec Tunnel (18 % à N26).
- Retirer Morsure (b, e) le rend **plus dur** (Mimi-Queue puis Poing Comète frappent plus fort en
  moyenne) ; l'IA `random` (c) n'aide pas (Kangourex suffit). Le levier est le **niveau de
  Kangourex** (f, a, d).
- Anomalie notée, non expliquée : avec Tunnel, le joueur **naïf** (sans objet) fait mieux que
  l'attentif contre Giovanni RB (66–72 % contre 18–32 % avec 3 Super Potions) ; à lire comme une
  limite de la politique « attentif » de l'outil, pas comme un réglage.

## 4. Réglages proposés (Kevin tranche, Q-3)

**Erika** (cible du plan : Salamèche facile, Carapuce difficile mais passable) :

- **E-1 (recommandé) : (d) Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29** (Méga-Sangsue
  gardée). Carabaffe N26 : 16 · 83 · 92 ; N28 : 76 · 99 · 99 ; Herbizarre N26 : 52 · 100 · 100 ;
  Salamèche ≈ 100. Écart à RB : Empiflor −2 et ordre inversé ; récompense 99 × 29 = 2 871 ₽
  inchangée.
- **E-2 : garder RB (29 / 24 / 29)** : Carapuce reste un mur doux jusqu'au N30 (43 · 72 · 81).
- **E-3 : (a) 27 / 24 / 27** : Carabaffe N26 : 10 · 35 · 64 ; N28 : 47 · 79 · 86 (2 673 ₽).

**Giovanni** (combat obligatoire pour le Scope, donc pour la suite) :

- **G-1 (recommandé) : (d) Onix 23, Rhinocorne 22, Kangourex 25** : à N28 avec 3 Super Potions,
  58 · 81 · 93 % (Reptincel · Herbizarre · Carabaffe) ; à N26, 12 · 38 · 69 ; à N30, ≥ 92 %.
  Seul réglage mesuré à ≥ 50 % pour les trois starters au N28 (récompense 99 × 25 = 2 475 ₽).
- **G-2 : (a) Kangourex 25** (Onix 25, Rhinocorne 24 gardés) : N28 : 25 · 72 · 89 ; Reptincel
  reste dur (N30 : 74).
- **G-3 : (f) Kangourex 27** : N28 : 11 · 41 · 74 ; N30 : 49 · 90 · 94 (2 673 ₽) — plus proche de
  RB, demande un N30.

## 5. Décisions de Kevin (2026-10-16)

- **Erika : E-1** (Saquedeneu 24 en tête, Empiflor 27, Rafflesia 29 ; 2 871 ₽).
- **Giovanni : G-1** (Onix 23, Rhinocorne 22, Kangourex 25 ; 2 475 ₽). Capacités inchangées
  (choisies à la main, règle du J12).
- Appliquées dans `data/trainers/celadon_gym.json` et `rocket_hideout.json`. Q-3c (niveau
  d'arrivée réel) reste à confirmer par la mesure du J19 ; on resimule si elle s'écarte de N26–28.

## 5 bis. Questions posées à Kevin (historique)

- **Q-3a — Erika** : E-1 (ordre inversé, Empiflor 27), E-2 (RB) ou E-3 (27 / 24 / 27) ?
- **Q-3b — Giovanni** : G-1 (23 / 22 / 25), G-2 (Kangourex 25) ou G-3 (Kangourex 27) ?
- **Q-3c — Niveau d'arrivée visé** : les équipes sont estimées (N26–28 au repaire) ; la
  simulation de la Tour du J19 (rival n° 5) dira l'arrivée réelle. Si le J19 mesure plus haut
  (N30), E-2 et G-3 redeviennent jouables.

## 6. Reproduire

```bash
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/celadon_thresholds.json --seeds 1000 --variante ": erika_donnees"
# une configuration par « --variante » (erika_*, giovanni_*), « --equipe <texte> » pour cibler ;
# ≈ 10 min par configuration sous charge
```

Rapports bruts (non versionnés) : `build/sim/j20/`.
