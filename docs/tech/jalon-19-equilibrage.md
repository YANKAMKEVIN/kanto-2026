# Jalon 19 — équilibrage du rival n° 5 par simulation (T21)

> **PRÉLIMINAIRE, À RELANCER APRÈS T10.** Les équipes réelles des J16 à J18 n'existent pas encore
> (jalons en cours) : les équipes du joueur sont **supposées** (§2). Les niveaux retenus (§4) sont
> posés dans `data/trainers/pokemon_tower.json` (`rival_tower`) comme **provisoires** ; la version
> définitive se refait après T10 sur les vraies sorties (plan `jalon-19.md` T21, §6).

Branche `j19-t21-simulation` (depuis `jalon-19` à `41265377`), 2026-10-16, architecte.
Plan : `jalon-19.md` §2.6, T21, §7 (seuils [D]). Modèle : `jalon-13-equilibrage.md`.

## 1. Méthode

- Outil : `tools/simulate_mt_moon.gd` (vrai moteur, vraie IA `smart` du rival avec changement de
  Pokémon, vraies données ; une graine = une partie). **200 graines par ligne** (écart-type
  ≤ 3,5 points : les écarts < 7 points ne comptent pas).
- `tools/sim/tower_scenario.json --donnees` (parcours complet, Dresseurs relus dans `data/`) :
  Centre de Lavanville, **rival (2F)**, [Centre], [E1, E2], **E3**, [E4 à E7], zone purifiée (soin),
  **E8**, **E9**. Variantes : directe ou avec les Exorcistes facultatifs ; joueurs attentif,
  expert et naïf ; 5 reprises au Centre après une défaite.
- `tools/sim/tower_thresholds.json` (nouveau, seuils) : **le rival seul**, équipe soignée,
  5 Super Potions, 3 Antidotes, 2 Réveils, au premier essai ; 16 réglages du rival (groupes
  `r01` à `r16`), joueurs attentif et expert.
- **« En trois essais »** = 1 − (1 − p)³, p = victoire au premier essai. Les reprises du simulateur
  gardent le Sac entamé (Super Potions dépensées au premier essai, rien de racheté) : elles sont
  pessimistes, alors qu'en jeu le joueur se réveille au Centre de Lavanville, à côté de la
  Boutique. Elles sont données à titre d'information (§3, dernière colonne).
- Joueurs : **attentif** (IA `smart` du jeu, Potions, meilleur Pokémon en tête), **expert**
  (attaque la plus forte, change de Pokémon quand un autre est nettement mieux placé), **naïf**
  (attaque au hasard, aucun objet). L'attentif ne change jamais de Pokémon de lui-même : il garde
  par exemple un Herbizarre face à Léviator plutôt que d'envoyer Pikachu.
- **Joueur « bas »** du plan = équipe « bas » ci-dessous jouée par l'attentif.

## 2. Hypothèses d'équipes (supposées)

| Équipe | Contenu | Source |
|---|---|---|
| **référence** (« attentif ») | starter évolué N24, Roucoups N21, Papilusion N20, Sabelette N19, Pikachu N20 | équipe de référence du J18 (`jalon-18.md` §4.16), reprise par `tower_scenario.json` |
| **bas** | starter évolué N22, Roucoups N19, Papilusion N18 | sortie directe supposée du J18 (`tower_scenario.json`) |
| plus1 (sensibilité) | référence + 1 niveau partout (starter N25) | plan §0.2 : « référence du J18 augmentée de 1 à 2 niveaux » |

Capacités : naturelles au niveau (Roucoups : Tornade, Jet de Sable, Vive-Attaque). Aucune CT,
aucune capture, aucun entraînement pendant la Tour. Les SPECTRES ne donnent pas d'XP.

**Hypothèse la plus fragile** : l'équipe « bas » n'a que **trois** Pokémon contre cinq chez le
rival. C'est elle qui fixe les niveaux (§4). Une vraie sortie du J18 à quatre ou cinq Pokémon
change fortement la conclusion : à relancer après T10.

## 3. Résultats

Rival en données Rouge/Bleu (avant T21 : Roucoups 25, 2ᵉ 23, 3ᵉ 22, Kadabra 20, starter 25),
parcours complet, premier essai (attentif) : **Salamèche 87 %, Carapuce 47 %, Bulbizarre 0 %** ;
équipe « bas » : 1,5 %, 0 %, 0 %. Aucun seuil n'est tenu.

Rival seul (`tower_thresholds.json`), victoire au **premier essai**, attentif · expert. Niveaux
« Roucoups / 2ᵉ / 3ᵉ, Kadabra, starter » ; « K16 » = Kadabra avec la règle du J16 (Choc Mental,
Rafale Psy, `rival_ss_anne` de la branche `jalon-16`), sinon ses capacités naturelles (Téléport,
Choc Mental, Entrave, comme dans `data/`).

| Réglage | Salamèche réf. | Salamèche bas | Carapuce réf. | Carapuce bas | Bulbizarre réf. | Bulbizarre bas |
|---|---|---|---|---|---|---|
| **r01 : 22/22/22, Kadabra 18, starter 22 (retenu)** | **100 · 100** | **80 · 90** | **92 · 95** | **8 · 3** | **2 · 11** | **0 · 0** |
| r02 : r01, K16 | 99 · 100 | 67 · 73 | 89 · 94 | 7 · 2 | 1 · 7 | 0 · 0 |
| r03 : 22/22/22, Kadabra 20, starter 22 | 98 · 100 | 57 · 71 | 87 · 94 | 5 · 2 | 0 · 5 | 0 · 0 |
| r04 : r03, K16 | 89 · 97 | 14 · 23 | 82 · 87 | 4 · 1 | 0 · 2 | 0 · 0 |
| r05 : 23/22/22, Kadabra 18, starter 23 | 99 · 100 | 51 · 56 | 87 · 95 | 7 · 3 | 1 · 4 | 0 · 0 |
| r07 : 24/22/22, Kadabra 18, starter 24 | 99 · 100 | 26 · 30 | 88 · 93 | 6 · 1 | 1 · 3 | 0 · 0 |
| r09 : 24/23/22, Kadabra 20, starter 25 | 93 · 95 | 2 · 2 | 53 · 63 | 0 · 0 | 0 · 0 | 0 · 0 |
| r11 : Rouge/Bleu 25/23/22, Kadabra 20, starter 25 | 87 · 95 | 2 · 1 | 47 · 58 | 0 · 0 | 0 · 0 | 0 · 0 |
| r12 : r11, K16 | 66 · 87 | 1 · 2 | 33 · 50 | 0 · 0 | 0 · 0 | 0 · 0 |
| r13 : 25/24/23, Kadabra 18, starter 22 | 99 · 100 | 67 · 68 | 34 · 40 | 0 · 0 | 0 · 4 | 0 · 0 |
| r15 : r01, Bulbizarre adouci (1) | = r01 | = r01 | = r01 | = r01 | 46 · 63 | 0 · 2 |
| r16 : r01, Bulbizarre très adouci (2) | = r01 | = r01 | = r01 | = r01 | 61 · 81 | 0 · 1 |

(1) contre Bulbizarre : Léviator Charge + Groz'Yeux, Reptincel sans Flammèche (Griffe,
Rugissement, Groz'Yeux, Frénésie), Kadabra K16. (2) Léviator Charge + Groz'Yeux, Noeunoeuf
Pilonnage seul, **Salamèche N22 non évolué**, Kadabra naturel.
Sensibilité « plus1 » avec r01 : Salamèche 100 %, Carapuce 95 %, Bulbizarre 2,5 % (r16 : 71,5 %).

**Ce qui pèse** (traces `--trace`) :
- **Léviator** (Attaque 125, plus rapide que Carabaffe et Herbizarre) : Morsure fait souvent
  tressaillir, et le Super Potion ne suffit plus. C'est le mur des équipes Carapuce « bas » et de
  toutes les équipes Bulbizarre. Avec Charge au lieu de Morsure (et Reptincel sans Flammèche), Bulbizarre passe de 1,5 à 46 % (r15).
  Draco-Rage seul (40 PV fixes) est **pire** que Morsure pour Carapuce (69 % contre 89 %).
- **Kadabra** : son niveau et Rafale Psy comptent plus que le reste. Passer de 18 à 20, ou lui
  donner la règle du J16, fait perdre 13 à 66 points à l'équipe Salamèche « bas » (80 % → 67, 57 ou 14 %).
- **Le starter du rival** : contre Salamèche, chaque niveau de Carabaffe au-dessus de 22 coûte
  ≈ 30 points à l'équipe « bas » ; Roucoups et le 2ᵉ peuvent monter (r13 : 25/24/23 garde 67 %).
- **Bulbizarre** : Roucoups (Tornade), Reptincel (Flammèche), Léviator et Noeunoeuf (Hypnose)
  le battent tous ; même le réglage le plus doux mesuré (r16) reste sous le seuil.

Parcours complet avec le réglage retenu (`tower_scenario.json --donnees`, premier essai, attentif) :

| Équipe | Rival | Toute la Tour, directe | Avec les Exorcistes facultatifs | Reprises sans rachat (≤ 6 essais) |
|---|---|---|---|---|
| Salamèche réf. | 100 % | 98,5 % | 88,5 % | rival 100 % |
| Salamèche bas | 80 % | 68,5 % | 32,5 % | rival battu dans 86 % des parties (1,3 essai) |
| Carapuce réf. | 91,5 % | 86,5 % | 75,5 % | rival battu dans 98 % (1,15 essai) |
| Carapuce bas | 8 % | 4 % | 2,5 % | 8 % |
| Bulbizarre réf. | 1,5 % | 0 % | 0 % | 1,5 % |
| Bulbizarre bas | 0 % | 0 % | 0 % | 0 % |

Exorcistes : E3 (deux Fantominus N23) coûte 1,05 à 1,2 essai pour les équipes qui passent le
rival ; les facultatifs coûtent 10 à 35 points d'arrivée « sans défaite » (usure, puis reprise
après la zone purifiée). Joueur naïf : rival 0 à 11,5 % au premier essai (Salamèche réf. : 3,7
essais).

## 4. Niveaux proposés (provisoires, posés dans `data/`)

**r01 pour les trois starters** : tous les Pokémon du rival **N22**, **Kadabra N18** (capacités
inchangées, celles de `data/` : Kadabra naturel, Léviator Morsure / Draco-Rage / Groz'Yeux,
Caninos Morsure / Flammèche / Groz'Yeux, Reptincel Griffe / Rugissement / Flammèche / Groz'Yeux).
Récompense : 35 ₽ × 22 = 770 ₽.

| Starter du joueur | Équipe du rival | Attentif, 1ᵉʳ essai (≥ 70 %) | Bas, 3 essais (≥ 90 %) |
|---|---|---|---|
| Salamèche | Roucoups 22, Caninos 22, Noeunoeuf 22, Kadabra 18, Carabaffe 22 | **100 %** ✓ | 80 % → **99 %** ✓ |
| Carapuce | Roucoups 22, Léviator 22, Caninos 22, Kadabra 18, Herbizarre 22 | **91,5 %** ✓ | 8 % → **22 %** ✗ |
| Bulbizarre | Roucoups 22, Noeunoeuf 22, Léviator 22, Kadabra 18, Reptincel 22 | **1,5 %** ✗ | 0 % ✗ |

Pourquoi le plancher de la fourchette partout :
- Salamèche : le starter du rival ne peut pas dépasser 22 sans faire tomber l'équipe « bas » sous
  le seuil (r05 : 51 % → 88 % en trois essais). r13 (Roucoups 25, Caninos 24, Noeunoeuf 23,
  Carabaffe 22) tiendrait aussi (67 % → 96 %), mais avec le starter du rival **sous** ses
  autres Pokémon ; écarté par défaut (le starter reste son meilleur Pokémon).
- Carapuce et Bulbizarre : **aucun réglage dans la fourchette ne tient le seuil « bas »** ; le
  plancher est le plus proche. Pour Carapuce, l'attentif garde de la marge jusqu'à r07 (88 %),
  mais l'équipe « bas » n'y gagne rien.
- **Kadabra N18** (≤ 22 [D]) : comme le rival n° 4 du J16 ; N20 coûte 23 points à l'équipe
  Salamèche « bas » (r03).
- Capacités de Kadabra : **naturelles** (Téléport, Choc Mental, Entrave) en attendant le J16. La
  règle du J16 (Choc Mental, Rafale Psy) durcit nettement (r02 : Salamèche « bas » 67 %, encore
  au-dessus du seuil en trois essais : 96 %) ; à trancher à T10 (Q-T21-3).

Le test `test_trainers_j19` vérifie la fourchette du plan : aucun Pokémon du rival hors de
22–26 (starter compris), Kadabra ≤ 22.

## 5. Questions pour Kevin

- **Q-T21-1 — Bulbizarre** : avec les équipes du dossier (Roucoups, Noeunoeuf, Léviator, Kadabra,
  Reptincel), aucun réglage de niveaux 22–26 ne passe (≤ 2 % pour l'attentif). Options mesurées :
  (a) accepter un mur, comme au J13 (réglage (g) retenu alors) ; (b) adoucir les capacités contre
  Bulbizarre seulement : r15 (Léviator Charge, Reptincel sans Flammèche) 46 % ; r16 (en plus
  Salamèche **non évolué** N22, Noeunoeuf sans Hypnose) 61 % ; (c) changer une espèce de l'équipe
  contre Bulbizarre (Léviator surtout), à mesurer. Le seuil « bas » ne tient dans aucune option.
- **Q-T21-2 — Joueur « bas »** : à trois Pokémon (N22, 19, 18), il ne bat pas cinq Pokémon N22
  avec Carapuce ou Bulbizarre. Faut-il viser ce joueur (et descendre sous la fourchette 22–26 ou
  alléger l'équipe du rival), ou le seuil « bas » se mesure-t-il sur une sortie du J18 à quatre
  ou cinq Pokémon (à confirmer par les vraies équipes après T10) ?
- **Q-T21-3 — Kadabra** : règle du J16 (Choc Mental, Rafale Psy) ou capacités naturelles ?

## 6. Reproduire

```bash
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/tower_scenario.json --donnees --seeds 200     # ≈ 10 min sous charge
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/tower_thresholds.json --seeds 200             # ≈ 8 min
# --equipe <texte>, --variante <texte> (ex. « r01, attentif »), --trace <étape> pour cibler
```

**Relance après T10** : remplacer les équipes de `tower_scenario.json` et de
`tower_thresholds.json` par les vraies sorties des J16 à J18 (`--save` sur une sauvegarde de
fin de J18 si elle existe), relancer les deux, recaler `rival_tower` et `RIVAL` dans
`test_trainers_j19.gd`, et retirer la mention « préliminaire ».
