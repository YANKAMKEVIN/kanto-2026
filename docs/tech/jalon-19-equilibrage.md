# Jalon 19 — équilibrage du rival n° 5 par simulation (T21)

> **Définitif (T21, 2026-10-19) : §8.** Règle de difficulté de Kevin (Q-T21-4, §5), mesurée sur
> les sorties réelles du J18 (§7). Les §1 à §4 sont la simulation préliminaire du 2026-10-16
> (équipes du joueur supposées, seuils du plan abandonnés) ; ils restent comme historique.

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

## 4. Niveaux proposés au préliminaire (remplacés par le §8)

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

**Réponses de Kevin (2026-10-19, « tout reco »)** :
- **Q-T21-4** : on applique **la règle de difficulté de Kevin**, pas les seuils du plan (≥ 70 %
  attentif, ≥ 90 % « bas » en trois essais : abandonnés). Le rival n° 5 est un **grand
  combat** : victoire au premier essai du joueur attentif d'environ **40 à 60 % pour chacun des
  trois starters**, mesurée sur les vraies sorties du J18 (§7) ; **jamais au-dessus de 80 %**.
  Donc le **durcir** contre Salamèche et Carapuce, l'**adoucir** contre Bulbizarre. Pour le
  durcissement, les niveaux peuvent sortir de la fourchette 22–26 (K-6) si c'est nécessaire,
  en restant plausibles (starter évolué du rival au plus ≈ 30) ; toute sortie est notée [D].
- **Q-T21-1** : contre Bulbizarre, **on adapte l'équipe du rival** (capacités et, si besoin, une
  espèce), puis on remesure. Pas de mur.
- **Q-T21-2** : pas de joueur « bas » fictif à trois Pokémon ; on mesure sur les **vraies sorties
  du J18**, à 3 ou 4 Pokémon (§7).
- **Q-T21-3** : Kadabra suit **la règle du J16** (Choc Mental, Rafale Psy).
- Le **texte d'Hypnose** du J17 est gardé (règle d'ancienneté) ; la **précision 0 de Hurlement**
  (ne rate jamais, aucun tirage) est acceptée.
- Exorcistes : relus avec la même règle ; seuls ceux au-dessus de 80 % sont à ajuster, sauf
  les facultatifs volontairement faciles (notés). Résultat : §8.

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

## 7. Mesure du T10 sur les sorties réelles du J18 (2026-10-19, aucune donnée changée)

Après la fusion de `main` (J16, J17, J18) : équipes d'arrivée à Lavanville **mesurées** par
`tools/sim/j18_scenario.json --donnees` (chemin direct, attentif, 100 graines ; niveaux moyens
arrondis), depuis la sortie du J16 (J17 sauté) et depuis la sortie du J17. Parcours de la Tour
inchangé (`tools/sim/tower_scenario_j18_exits.json`, 200 graines, rival en données : r01).
Les vraies sorties ont **3 ou 4 Pokémon**, starter N24–28, seconds N17–19 (sans Pikachu) : plus
proches de l'équipe « bas » du §2 que de la « référence ».

| Sortie du J18 (arrivée à Lavanville) | Rival, 1ᵉʳ essai : attentif · expert | Tour directe, attentif | Avec les facultatifs |
|---|---|---|---|
| depuis J16 — Reptincel 25, Roucoups 19, Férosinge 19, Mystherbe 19 | 96,5 · 98 | 94,5 | 75 |
| depuis J16 — type Kevin, Reptincel 26 (Tunnel), Roucoups 19, Nidorino 18, Rattata 17 | 100 · 100 | 100 | 98,5 |
| depuis J16 — Herbizarre 24, Roucoups 18, Papilusion 19 | **0 · 0** | 0 | 0 |
| depuis J16 — Carabaffe 25, Roucoups 19, Papilusion 18 | 87,5 · 93 | 84 | 79 |
| depuis J17 — Reptincel 27, Roucoups 19, Férosinge 19, Mystherbe 19 | 98,5 · 99 | 96 | 82,5 |
| depuis J17 — type Kevin, Reptincel 28 | 100 · 100 | 99,5 | 98,5 |
| depuis J17 — Herbizarre 26, Roucoups 18, Papilusion 19 | **1,5 · 2** | 1,5 | 1 |
| depuis J17 — Carabaffe 28, Roucoups 19, Papilusion 18 | 99 · 99,5 | 98 | 96,5 |

Lecture :
- Salamèche et Carapuce : le rival n° 5 est **au-dessus de 80 %** partout (87,5 à 100 %).
- Bulbizarre : **mur** (0 à 2 %), comme au préliminaire (Q-T21-1).
- E7 (Ysée, Spectrum N22, facultative) est la seule Exorciste qui coûte (84 % au premier essai
  pour Reptincel 25).
- **Conflit de règles à trancher (Q-T21-4)** : les seuils du plan (≥ 70 % attentif au premier
  essai, ≥ 90 % « bas » en trois essais) datent d'avant la règle de Kevin sur la difficulté
  (victoire au premier essai ≤ 80 % par défaut, 35–60 % pour un grand combat, jamais adoucir
  au-delà de 80 % sans son accord ; appliquée au J16 pour le rival n° 4, recalé à ≈ 40 %, et
  au J18 pour ses Dresseurs). Sous cette règle, le rival n° 5 devrait **monter** contre Salamèche et Carapuce
  (probablement au-dessus de la fourchette 22–26 ou avec Kadabra « règle du J16 ») et
  **descendre** contre Bulbizarre. T21 attend cette réponse ; rien n'est changé dans `data/`.

Reproduire : `godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --scenario
res://tools/sim/tower_scenario_j18_exits.json --donnees --seeds 200` (≈ 10 min).

## 8. T21 : recalage sur la règle de Kevin (2026-10-19, branche `j19-t21-equilibrage`)

Décisions : §5 (« Réponses de Kevin »). Cible : **grand combat**, victoire au premier essai du
joueur attentif ≈ **40–60 %** pour chaque starter, **jamais > 80 %**, sur les sorties réelles du
J18 (§7). Kadabra : Choc Mental, Rafale Psy (règle du J16) dans les trois variantes.

**Outil** : `tools/sim/gen_tower_t21.py` écrit `tools/sim/tower_t21.json` (le rival seul,
équipe soignée, 5 Super Potions, 3 Antidotes, 2 Réveils, premier essai ; un réglage = un groupe ;
« retenu » = `data/`, vérifié par `test_simulate_tower`). 200 graines par ligne (écart-type
≤ 3,5 points). Parcours complet : `tower_scenario_j18_exits.json --donnees`.

### 8.1 Rival seul, premier essai, joueur attentif (sorties du J18)

Niveaux « Roucoups / 2ᵉ / 3ᵉ, Kadabra, starter » ; « J16 » / « J17 » = sortie du J18 depuis la
sortie du J16 (J17 sauté) ou du J17 ; « K » = équipe type Kevin (Reptincel avec Tunnel).

**Contre Salamèche** (Roucoups, Caninos, Noeunoeuf, Kadabra, Carabaffe) :

| Réglage | J16 Reptincel 25 | J17 Reptincel 27 | K J16 (26) | K J17 (28) |
|---|---|---|---|---|
| s00 : T10 (22/22/22, Kadabra 18 naturel, 22) | 96,5 | 98,5 | 100 | 100 |
| s01 : idem, Kadabra du J16 | 94 | 95,5 | 100 | 98,5 |
| s10 : 23/23/23, K20, Carabaffe 24 | 68 | 77,5 | 92 | 97 |
| **s22 : 22/22/22, K20, Carabaffe 25 (retenu)** | **42** | **54,5** | **86** | **94** |
| s20 : 23/23/23, K20, Carabaffe 25 | 35 | 49 | 88,5 | 95,5 |
| s12 : 23/23/23, K21, Carabaffe 25 | 23 | 48 | 78 | 92 |
| s02 : 24/24/24, K22, Carabaffe 26 | 8 | 25 | 59 | 84,5 |

**Contre Carapuce** (Roucoups, Léviator, Caninos, Kadabra, Herbizarre) :

| Réglage | J16 Carabaffe 25 | J17 Carabaffe 28 |
|---|---|---|
| c00 : T10 (22/22/22, Kadabra 18 naturel, 22) | 87,5 | 99 |
| c01 : idem, Kadabra du J16 | 85 | 98 |
| c24 : 23/24/23, K22, Herbizarre 26 | 45,5 | 86,5 |
| c02 : 24/24/24, K22, Herbizarre 26 | 37,5 | 87,5 |
| c32 : 22/25/22, K20, Herbizarre 26 | 20,5 | 66 |
| c50 : 22/25/22, K18, Herbizarre 26 | 23 | 68,5 |
| **c51 : 21/25/21, K18, Herbizarre 26 (retenu)** | **26,5** | **74** |
| c52 : 20/25/20, K18, Herbizarre 26 | 29 | 73,5 |
| c31 : 22/24/22, K20, Herbizarre 30 (Tranch'Herbe) | 12 | 45,5 |

**Contre Bulbizarre** (Roucoups, Noeunoeuf, Léviator ou remplaçant, Kadabra, Reptincel) :

| Réglage | J16 Herbizarre 24 | J17 Herbizarre 26 |
|---|---|---|
| b00 : T10 (22/22/22, Kadabra 18 naturel, 22) | 0 | 1,5 |
| b01 : idem, Kadabra du J16 | 0 | 0,5 |
| b03 : b01, Léviator Charge + Groz'Yeux | 0 | 0 |
| b06 : b01, Sabelette au lieu de Léviator | 1 | 11,5 |
| b11 : 18/18/18, K16, Reptincel 20, Léviator Charge + Groz'Yeux | 6 | 50,5 |
| b13 : b11, Roucoups sans Tornade | 19,5 | 58 |
| b12 : 18/18/18, K16, Reptincel 20, Sabelette | 24,5 | 81 |
| b23 : 20/20/20, K17, Reptincel 22, Roucoups sans Tornade, Sabelette | 37 | 65 |
| **b14 : 20/20/20, K17, Reptincel 21, Roucoups sans Tornade, Sabelette (retenu)** | **41,5** | **68** |

Ce qui pèse :
- **Léviator** reste le mur de Bulbizarre même avec Charge (Attaque 125, plus rapide qu'Herbizarre)
  et même 4 niveaux plus bas (b11) : remplacé par **Sabelette** (Sol, Fouet Lianes super
  efficace), seule espèce essayée qui ouvre le combat (Nidorino : b05/b07, pire). **Tornade** de
  Roucoups est l'autre mur (l'attentif garde Herbizarre en tête) : retirée contre Bulbizarre.
- Contre Carapuce, le **niveau de Léviator** fait tout : 24 → 25 fait perdre ≈ 20 points à la
  sortie J17 ; le niveau d'Herbizarre (26 → 27) ne change presque rien, Tranch'Herbe (N30) écrase
  la sortie J16. L'écart entre les deux sorties (Carabaffe 25 / 28) est de ≈ 45 points dans tous
  les réglages : **aucun réglage ne met les deux dans 40–60** sans que la sortie J17 dépasse 80 %.
  Retenu : la sortie J17 sous 80 %, la moyenne des deux à 50 %.
- Contre Salamèche, Kadabra du J16 seul ne change presque rien (s01) ; ce sont Carabaffe 25 et
  Kadabra 20 qui font le recalage (s22).

### 8.2 Équipes retenues (`data/trainers/pokemon_tower.json`, `rival_tower`)

| Starter du joueur | Équipe du rival | ₽ (35 × dernier) | Attentif J16 · J17 (moy.) | En 3 essais (J16) |
|---|---|---|---|---|
| Salamèche | Roucoups 22, Caninos 22, Noeunoeuf 22, Kadabra 20, **Carabaffe 25** | 875 | **42 · 54,5** (48) | 80 % |
| Carapuce | Roucoups 21 [D], **Léviator 25**, Caninos 21 [D], Kadabra 18, **Herbizarre 26** | 910 | **26,5 · 74** (50) | 60 % |
| Bulbizarre | Roucoups 20 (Jet de Sable, Vive-Attaque), Noeunoeuf 20, **Sabelette 20**, Kadabra 17, **Reptincel 21** — tout [D] | 735 | **41,5 · 68** (55) | 80 % |

- Capacités : Kadabra Choc Mental, Rafale Psy (les trois) ; Léviator Morsure, Draco-Rage,
  Groz'Yeux ; Caninos Morsure, Flammèche, Groz'Yeux ; Roucoups Tornade, Jet de Sable,
  Vive-Attaque (sans Tornade contre Bulbizarre) ; Reptincel Griffe, Rugissement, Flammèche,
  Groz'Yeux ; Noeunoeuf, Sabelette, Carabaffe, Herbizarre : naturelles au niveau.
- **Sorties de la fourchette 22–26 (K-6) [D]** : vers le **bas** seulement (Bulbizarre 17–21,
  Roucoups et Caninos N21 contre Carapuce). Rien au-dessus de 26 ; starter évolué toujours le plus
  haut (≤ 30 vérifié par `test_trainers_j19`).
- **Équipe type Kevin** (Reptincel avec Tunnel) : 86 % (J16) et 94 % (J17), **au-dessus de
  80 %** ; la ramener sous 80 % fait tomber l'équipe ordinaire à 8–25 % (s02). Écart à faire
  trancher (question en fin de section).
- Joueur expert : Salamèche 45,5 · 64, Carapuce 32,5 · 77,5, Bulbizarre 12,5 · 54,5 (cause
  non tracée : ses changements de Pokémon lui coûtent ici, l'attentif reste la référence).

### 8.3 Parcours complet (`tower_scenario_j18_exits.json --donnees`, attentif, premier essai)

| Sortie du J18 | Rival | Tour directe sans défaite | Avec les facultatifs | E3 juste après le rival (sans Centre) |
|---|---|---|---|---|
| J16 Reptincel 25 | 42 | 35,5 | 21 | 84,5 |
| J16 type Kevin | 86 | 72 | 62,5 | 83,7 |
| J16 Herbizarre 24 | 41,5 | 32,5 | 24 | 78,3 |
| J16 Carabaffe 25 | 26,5 | 25 | 21 | 94,3 |
| J17 Reptincel 27 | 54,5 | 45 | 27 | 82,6 |
| J17 type Kevin | 94 | 90 | 88 | 95,7 |
| J17 Herbizarre 26 | 68 | 56,5 | 43,5 | 83,1 |
| J17 Carabaffe 28 | 74 | 71,5 | 67,5 | 96,6 |

(Le simulateur enchaîne sans retour au Centre après le rival : le joueur arrive au 3F avec 13 à
43 % de PV ; en jeu, le Centre de Lavanville est à deux pas.)

### 8.4 Exorcistes

Aucun n'est un grand combat ; ils sont relus par combat (premier essai, attentif) :
- **Après un passage au Centre** (`tower_scenario_j18_exits.json` sans le rival) : **100 %**
  pour les neuf, toutes sorties (Carabaffe 28 avec les facultatifs : E7 99,5 %).
- **Sans Centre après le rival** (§8.3) : E3 78–97 %, E1 84–99 %, E7 (Spectrum 22,
  facultative) 76–100 % ; E8 et E9 : 100 % (juste après la zone purifiée, soin complet).
- **Sonde de niveaux** (Centre, 200 graines, toutes sorties) : E3 à 2 × Fantominus 27 ou 30,
  E8 / E9 à Fantominus 28 ou 32, ou Spectrum 28 : **100 % partout**. Un seul Fantominus
  (Ténèbres = niveau) contre trois ou quatre Pokémon soignés ne se règle pas par les niveaux
  (même constat qu'au J16 pour les Dresseurs ordinaires du navire).
- **Rien n'est changé** : E8 et E9 (inévitables) et E3 dépassent 80 %, mais aucun niveau
  plausible ne les fait descendre ; règle P-1 du J16 (la règle des 80 % porte sur les combats à
  enjeu et les enchaînements sans soin, pas sur chaque Dresseur ordinaire). Les facultatifs
  (E1, E2, E4 à E7) sont laissés faciles. Question pour Kevin ci-dessous.

### 8.5 Questions pour Kevin

- **Réponses de Kevin (2026-10-19, « tout reco »)** : **Q-T21-5** accepté (équipe type Kevin à 86–94 %, cas à part : stratégie Tunnel) ; **Q-T21-6** accepté (Carapuce 26,5 % en ligne droite, 74 % depuis le J17) ; **Q-T21-7** accepté (E3, E8, E9 à 100 %, règle P-1 du J16, aucune équipe agrandie) ; Sabelette contre Bulbizarre gardé.
- **Q-T21-5 — Équipe type Kevin au-dessus de 80 %** (86 % / 94 % contre le rival, Reptincel
  avec Tunnel) : accepter (l'équipe ordinaire est à 42–54,5 %, la règle vise le joueur attentif
  « ligne droite »), ou durcir encore contre Salamèche (s02 : Kevin 59 / 84,5 %, ordinaire
  8 / 25 %) ?
- **Q-T21-6 — Carapuce** : la sortie J16 (ligne droite, Carabaffe 25) est à **26,5 %** (60 % en
  trois essais), la sortie J17 à 74 %. Garder (moyenne 50 %, aucune sortie > 80 %), ou viser
  40 % pour la ligne droite (c24 : 45,5 %, mais 86,5 % pour la sortie J17) ?
- **Q-T21-7 — Exorcistes inévitables à 100 %** (E3, E8, E9) : accepter (P-1), ou changer leur
  équipe (deux ou trois Pokémon, décision de design) ?
- **2026-10-22 (J26, Q26-4)** : Kevin revient à la lignée RB ; Sabelette est retirée, **Léviator 20**
  (Morsure, Draco-Rage, Groz'Yeux) reprend sa place. Bulbizarre attentif : 7 % · 29,5 % (au lieu de
  41,5 · 68). Détail : `jalon-26.md` §10.2.
- **Sabelette** dans l'équipe du rival contre Bulbizarre (remplace Léviator, Q-T21-1) : choix par
  défaut, à valider en 19B.

Reproduire :

```bash
python3 tools/sim/gen_tower_t21.py          # réécrit tools/sim/tower_t21.json depuis data/
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/tower_t21.json --equipe Herbizarre --variante "b14,"   # ≈ 1 min
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/tower_t21.json --variante retenu                      # ≈ 3 min
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/tower_scenario_j18_exits.json --donnees --seeds 200   # ≈ 10 min
```
