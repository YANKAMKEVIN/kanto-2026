# Jalon 16 — équilibrage par simulation (T18) : rival n° 4 et Major Bob

> **Information pour Kevin. Aucune donnée de jeu n'a été changée** (`data/` intact). Les réglages
> « essayés » n'existent que dans les scénarios de simulation (`tools/sim/`).
> Plan : `jalon-16.md` §3 « T18 » et §5 (risques « Kadabra trop fort », « Tonnerre de Raichu au
> N24 »). Dossier : `dossier-19-ss-anne-major-bob.md` §5, §9, Q-8. Modèle : `jalon-13-equilibrage.md`.

Branche `j16-t18-equilibrage` (depuis `jalon-16` à `5742a397`), 2026-10-16, architecte.

## 1. Méthode

- Outil : `tools/simulate_mt_moon.gd` (vrai moteur `Battle`, vraie IA `BattleAI`, vraies espèces,
  capacités, objets, tables et Dresseurs de `data/` avec `--donnees`, XP et évolutions de fin de
  combat). Une graine = une partie ; **graines 0 à 999 par ligne** (écart-type ≤ 1,6 point ; un
  écart de moins de 3 points ne compte pas).
- Scénarios **générés** par `tools/sim/gen_ss_anne_scenarios.py` (relançable, Dresseurs et tables
  recopiés de `data/`) :
  - `tools/sim/ss_anne_scenario.json` — **parcours** depuis la fin du J13 (Ondine battue) :
    Route 25 (D1, D2, H3 obligatoires), Rocket d'Azuria, Route 6 (Chloé, seule inévitable),
    Centre de Carmin, rival n° 4, Centre, Arène (Louis, Axel, Marc), [Centre], Major Bob.
    Groupe « tous » : D3–D6 et 30 cases de la Route 25, 20 cases de la Route 5, les 5 autres
    Dresseurs et 30 cases de la Route 6, les **10 Dresseurs du navire** (aucun soin à bord, 0
    inévitable). « retour » : retour au Centre du quai après 5 Dresseurs du navire et avant le
    rival. Reprises au Centre après une défaite (5 au plus).
  - `tools/sim/ss_anne_thresholds.json` — **seuils** : un seul combat par partie, équipe soignée,
    échelle de niveaux (meneur N20 à N26) contre le rival et Major Bob de `data/` et des réglages
    de comparaison.
- Joueurs (ceux du J13) : **naïf** (attaque au hasard, aucun objet), **attentif** (IA `smart` du
  jeu, Potions, meilleur Pokémon en tête), **expert** (attaque la plus forte, jamais de statut,
  change de Pokémon quand un autre est 2 × mieux placé).
- **Ajout à l'outil** (seul changement de code) : clé de variante `keep_order` (« ordre gardé ») :
  l'équipe part dans son ordre au lieu de mettre en tête « le mieux placé ». Sans elle, l'attentif
  envoie son Racaillou contre Voltorbe (Sonicboom, Grincement) et le perd avant Raichu ; avec
  elle, le Pokémon de type Sol, placé en dernier, attend Raichu (ce que ferait un joueur).
- `rival_ss_anne` et `vermilion_gym_surge` ont `switch: true` (R-19, décision de Kevin) : l'IA
  change de Pokémon une fois par combat, comme en jeu.
- Pas de capture, pas de CT apprise en chemin, pas d'entraînement libre ; durées en **tours**.

### Hypothèses (à corriger si Kevin joue autrement)

- **Équipes de départ** = fin du J13 du scénario du J14 T21 (`route_25_scenario.json`) :
  Reptincel 21 + Férosinge 18, Roucool 17, Mystherbe 17 ; « Kevin » (espèces de sa partie :
  Reptincel 21, Roucool 18, Nidorino 16, Rattata 16) ; Herbizarre 20 + Roucool 17, Papilusion 15 ;
  Carabaffe 21 + Roucool 18, Papilusion 16 ; trois équipes « bas » (Herbizarre 18, Carabaffe 20,
  Reptincel 20). Variantes **« Sol »** : + Racaillou 16 (Mont Sélénite, 30 % des rencontres), ou
  Nidoking 16 au lieu de Nidorino (Pierre Lune du J12). Seuils : **« Tunnel »** (CT28 du J14,
  obligatoire : Reptincel ou Carabaffe), **« Plante »** (Carabaffe + Mystherbe).
- **Sac** (parcours ; seuils « sac de Carmin ») : 3 Potions, 2 Super Potions (Boutique de Carmin,
  navire), 1 Antidote, 1 Anti-Para. Seuils « 3 Potions » : comme au J13.
- Le Pokémon de type Sol de Kevin n'existe pas dans le jeu avant Carmin sous la forme de RB
  (Taupiqueur, Grotte Taupiqueur « À venir », dossier 18) : seuls Racaillou, Sabelette, Nidoking.

### Cible de référence (celle du J13, faute de cible écrite au dossier 19)

Combat obligatoire : joueur attentif, **premier essai ≥ 60 %** au niveau d'arrivée sans détour,
**≈ 90 %** avec les Dresseurs facultatifs. Repères validés : rival n° 3 retenu (b)/(g) = 76–100 %
au N18 (Bulbizarre : 13–39 %, « mur doux » accepté) ; Ondine retenue Staross 19 = 66–84 %
(Carabaffe N20), 49–68 % (Salamèche + Mystherbe), Salamèche **sans plante bloqué** (« mur
historique voulu », la réponse étant à côté, Route 24).

## 2. Niveau d'arrivée (parcours, attentif, meneur avant le combat)

| Équipe de départ | Rival : directe | Rival : tous les Dresseurs | Bob : directe | Bob : tous |
|---|---|---|---|---|
| Reptincel 21 (+ Férosinge, Roucool, Mystherbe) | **22,0** | 26,3 | 23,6 | 27,7 |
| « Kevin » Reptincel 21 | 21,8 | 25,7 | 23,6 | 27,1 |
| Herbizarre 20 | **20,0** | 24,4 | — (bloqué) | — |
| Carabaffe 21 | 21,0 | 25,6 | 22,6 | 26,8 |
| « bas » Reptincel 20 / Carabaffe 20 / Herbizarre 18 | 21,0 / 20,0 / 18,4 | 25,7 / 26,2 / — | 22,9 / 22,1 / — | 27,2 / 27,5 / — |
| Avec un Pokémon de type Sol (XP partagée) | 20,0–21,1 | 22,7–24,5 | 20,0–22,0 | 24,1–26,5 |

- Le chemin **direct** (D1, D2, 4 cases, Rocket, Chloé) ne donne que **0 à 1 niveau** depuis la fin
  du J13 ; tous les Dresseurs et herbes facultatifs (J14 → navire) en donnent **≈ 4 à 5**.
- L'Arène (Louis, Axel, Marc) ajoute ≈ 1,5 niveau avant Bob.
- Navire : 10 Dresseurs ≈ 50 tours ; **sans retour au Centre du quai**, l'équipe arrive usée au
  rival (premier essai 0–9 % au lieu de 88–98 %).

## 3. Rival n° 4 (Roucoups 19, Rattatac 16, Kadabra 18, starter évolué 20 ; IA smart qui change)

**Parcours** (premier essai attentif · expert ; entre parenthèses : battu en 6 essais si < 98 %) :

| Équipe | Directe | Tous les Dresseurs (retours au quai) |
|---|---|---|
| Reptincel 21 | **63 · 80 %** | 88 · 97 % |
| « Kevin » | **63 · 77 %** | 88 · 98 % |
| Carabaffe 21 | **72 · 91 %** | 88 · 99,5 % |
| **Herbizarre 20** | **0 · 0 % (jamais en 6 essais)** | **0 · 2 % (3–29 %)** |
| bas Reptincel 20 · bas Carabaffe 20 | 46 · 58 % · **8,5 · 31 %** (26–60 %) | 82 · 96 % · 60 · 72 % |
| Sol, ordre gardé (Racaillou ; Nidoking ; Carabaffe + Racaillou ; Herbizarre + Racaillou) | 74 ; 70 ; 86 ; **0 %** | 87 ; 99 ; 89 ; 2 % |
| Naïf (toutes équipes) | 1,5–9,8 % | peu l'atteignent (usure) |

Durée : 14 à 23 tours, 1,5 à 3,4 K.O. (attentif, directe) ; 13 à 16 tours avec tous les Dresseurs.

**Seuils** (attentif, premier essai ; **3 Potions | sac de Carmin**), meneur N20 · 22 · 24 · 26 :

| Réglage | Reptincel | « Kevin » | Herbizarre | Carabaffe |
|---|---|---|---|---|
| **Données** 19 / 16 / 18 / 20 | 1 · 28 · 77 · 97 \| 27 · 72 · 95 · 99 | 0 · 22 · 85 · 99 \| 6 · 66 · 97 · 100 | **0 · 0 · 0 · 9 \| 0 · 0 · 3 · 27** | 1 · 14 · 92 · 100 \| 44 · 75 · 99 · 100 |
| (b) 17 / 15 / 16 / 18 | 36 · 86 · 99 \| **86 · 97 · 100** | 32 · 93 · 100 \| **79 · 99 · 100** | 0 · 0 · 17 · 87 \| 0 · 22 · 56 · 98 | 32 · 90 · 100 \| **86 · 98 · 100** |
| (f) 16 / 14 / 15 / 17 | 71 · 97 \| 95 · 99 | 76 · 99 \| 95 · 100 | 0 · 6 · 65 · 100 \| 8 · 32 · 90 · 100 | 70 · 99 \| 94 · 100 |
| (h) contre Bulbizarre : 16 / 14 / 15 / 16 | — | — | 2 · 13 · 84 · 100 \| 14 · 41 · 96 · 100 | — |
| **(i) contre Bulbizarre : 14 / 12 / 13 / 15** | — | — | 31 · 82 · 100 · 100 \| **76 · 98 · 100 · 100** | — |

- **Kadabra** (risque du plan §5) : mesuré sur Herbizarre + Racaillou N24 (données 33 %) :
  Kadabra N16 → 59 %, sans Rafale Psy → 56 %, starter N18 → 64 %. Il pèse, mais le mur de
  Bulbizarre vient des **trois** faiblesses (Tornade, Rafale Psy sur Plante/Poison, Flammèche).
- **Changement de Pokémon de l'IA** : sans effet mesurable (34 % sans, 33 % avec).
- Le **sac de Carmin** (2 Super Potions) vaut ≈ 2 niveaux pour Salamèche et Carapuce.

## 4. Major Bob (Voltorbe 21, Pikachu 18, Raichu 24 Éclair / Cage-Éclair / Tonnerre ; smart qui change)

**Parcours** (attentif, premier essai ; entre parenthèses : battu en 6 essais), soin avant Bob :

| Équipe | Directe (meneur N22,6–23,7) | Tous les Dresseurs (N26,8–28,0) |
|---|---|---|
| Reptincel 21 | **0,3 % (5 %)** | 32 % (90 %) |
| « Kevin » (Nidorino) | **0 % (1 %)** | 9 % (60 %) |
| **Carabaffe 21** | **0 % (0 %)** | **0 % (0,1 %)** |
| bas Reptincel · bas Carabaffe | 0,2 % · 0 % | 22 % · 0 % |
| **Sol, ordre gardé** (Racaillou ou Nidoking, toutes équipes) | **100 %** | **100 %** (Nidoking : 4 tours, 0 K.O.) |
| Sol, « meilleur en tête » (Racaillou envoyé contre Voltorbe) | 52–76 % | 53–69 % |

- **Sans soin entre les Dresseurs de l'Arène et Bob** : Reptincel (tous) 32 → 6 % ; Sol en tête
  76 → 6 % (directe). Le Centre est à côté : effet réel, mais le joueur se soignera.
- Dresseurs de l'Arène : ≤ 20 % de défaites au premier essai (Marc, contre Carabaffe), 1,0 à
  1,2 tentative. Bob : 8 à 15 tours sans Sol.
- **Tunnel (CT28) ne suffit pas** : Raichu (Vitesse 110) frappe avant que le Pokémon ne creuse et
  Tonnerre met K.O. en un coup la plupart des Pokémon non Sol (Carabaffe N22 et ses 64 PV).
  Reptincel avec Tunnel : 5 · 40 · 83 % (N20 · 22 · 24) au lieu de 0 · 1 · 31 %.
- L'IA de Bob continue d'utiliser ses capacités Électrik sur un Pokémon de type Sol (« Ça n'affecte
  pas… ») : Raichu n'a **aucune** capacité qui le touche, d'où les 100 %.

**Seuils** (attentif ; **3 Potions | sac de Carmin**), N20 · 22 · 24 · 26 :

| Réglage | Reptincel | « Kevin » | Herbizarre | Carabaffe |
|---|---|---|---|---|
| **Données** | 0 · 1 · 31 · 63 \| 1 · 4 · 26 · 58 | 0 · 0 · 0 · 6 \| 0 · 0 · 4 · 11 | 0 · 2 · 30 · 86 \| 23 · 73 · 92 · 96 | **0 · 0 · 0 · 0 \| 0 · 0 · 0 · 0** |
| (b) Voltorbe 20, Raichu 21 | 8 · 42 · 82 · 97 | 0 · 1 · 7 · 54 | 12 · 56 · 95 · 100 \| 90 · 94 · 98 | 0 · 0 · 0 · 3 |
| (f) Voltorbe 19, Raichu 20 | 11 · 60 · 90 · 99 | 0 · 3 · 17 · 76 | 37 · 83 · 98 · 100 | 0 · 0 · 0 · 6 |
| **(c) Raichu 24 sans Tonnerre** (Vive-Attaque) | 16 · 68 · 100 \| 56 · **94 · 100** | 4 · 44 · 98 \| 28 · **89 · 100** | 10 · 78 · 100 \| 92 · 95 · 100 | 0 · 0 · 1 · 14 \| 0 · 0 · 6 · 50 |
| **(g) Voltorbe 20, Raichu 21 sans Tonnerre** | 78 · 100 \| 97 · 100 | 61 · 98 \| 93 · 100 | 93 · 99 \| 96 · 99 | 0 · 1 · 19 · 86 \| 1 · 10 · **73 · 97** |
| (e) Raichu 26 ; (d) Raichu + Vive-Attaque (plus durs) | Sol, ordre gardé : 98–100 % ; 90–100 % | | | |

Carabaffe avec un Pokémon d'appoint : + Mystherbe 2 · 21 % (N22 · 24, données), 70 · 76 % (c) ;
Tunnel 0 · 1 % (données), 43 · 86 % (c).

## 5. Constats

1. **Major Bob est un mur binaire** : avec un Pokémon de type Sol gardé pour Raichu, 100 % ; sans,
   0 à 5 % pour Salamèche et Carapuce au niveau d'arrivée (N23–24), même en 6 essais. Pour
   **Carapuce sans Sol, aucun niveau mesuré ne suffit** (0 % jusqu'au N26–27). Cause unique :
   **Tonnerre** de Raichu N24 (un coup pour la plupart des Pokémon non Sol : Carabaffe, Roucoups,
   Papilusion). Bulbizarre (Plante résiste) passe à partir du N22–24.
   Comparaison : Ondine laissait Salamèche sans plante bloqué, mais la réponse (Mystherbe) était
   sur la Route 24, juste avant. Ici la réponse (Racaillou, Sabelette, Pierre Lune) est **trois
   jalons plus tôt** et rien dans le jeu ne l'annonce ; la Grotte Taupiqueur de RB est « À venir ».
2. **Le rival n° 4 est un mur pour Bulbizarre** (0 % au N20–24, 9 % au N26, jamais battu en 6
   essais en directe) — le même schéma qu'au rival n° 3 (Roucoups, puis le starter Feu, avec en plus
   Kadabra). Pour Salamèche et Carapuce, il est **dans la cible** pour une équipe moyenne (63–72 %
   en directe, 88 % avec les Dresseurs), mais sous la cible pour les équipes « bas » (8–46 %).
3. Le **navire sans soin** use l'équipe : sans retour au quai, le rival devient très dur (0–9 %).
   Le quai est à une sortie : aucun blocage, mais le joueur doit y penser.
4. L'équipe aux espèces de Kevin est la plus exposée à Bob **sauf si Nidorino a reçu la Pierre
   Lune** : Nidoking (Sol) le bat à 100 % en 4 tours.

## 6. Recommandations (à valider par Kevin ; rien n'est appliqué)

**R-1 Rival n° 4 contre Salamèche et Carapuce : (b) Roucoups 17, Rattatac 15, Kadabra 16,
starter évolué 18** (− 2 partout, la même logique que le rival n° 3 retenu). Sac de Carmin :
79–86 % au N20 (équipes « bas »), 97–99 % au N22 ; 3 Potions : 86–93 % au N22. Ou **garder les
données** (63–72 % en directe, 88 % avec les Dresseurs) si Kevin veut ce rival plus tendu que le
n° 3. Espèces, ordre, capacités et changement de Pokémon gardés ; récompense 35 ₽ × dernier niveau.

**R-2 Rival n° 4 contre Bulbizarre : (i) Roucoups 14, Rattatac 12, Kadabra 13, Reptincel 15**
(76 % au N20, 98 % au N22 avec le sac de Carmin ; 31 · 82 % avec 3 Potions). Écart assumé de
− 5 niveaux, comme l'asymétrie du rival n° 3 ; Kadabra garde Choc Mental et Rafale Psy. Plus
tendu : (h) 16 / 14 / 15 / 16 (14 · 41 · 96 % aux N20 · 22 · 24, il faut alors les Dresseurs
facultatifs).

**R-3 Major Bob : retirer Tonnerre à Raichu, garder les niveaux — (c) Raichu N24 Éclair,
Cage-Éclair, Vive-Attaque.** Salamèche et « Kevin » au niveau d'arrivée (N23–24) : 89–100 %
(sac, dès le N22) ; Bulbizarre 95–100 % ; avec un Pokémon de type Sol, toujours 100 %. Carapuce sans Sol reste
bloqué (0–6 % au N24, 50 % au N26) : la réponse de RB (Sol, Plante) garde un sens. Tonnerre reste
la récompense (CT24) au lieu d'être la capacité qui met tout K.O. Plus généreux : **(g)** Voltorbe
20, Pikachu 18, Raichu 21 sans Tonnerre (Carapuce 73 % au N24, 97 % au N26 avec le sac). Plus
fidèle à RB : **garder les données** et annoncer le type Sol (texte du guide, question Q-T18-4).

**R-4 Garder** : Dresseurs du navire et de l'Arène (usure sans blocage, ≤ 20 % de défaites au
premier essai, ≤ 1,2 tentative), changement de Pokémon de l'IA (sans effet mesurable).

## 7. Questions pour Kevin

- **Q-T18-1** : rival n° 4 contre Salamèche et Carapuce — (b) 17 / 15 / 16 / 18 ou données ?
- **Q-T18-2** : rival n° 4 contre Bulbizarre — (i) 14 / 12 / 13 / 15, (h) 16 / 14 / 15 / 16, ou mur
  assumé ?
- **Q-T18-3** : Major Bob — (c) Raichu sans Tonnerre, (g) plus doux, ou données (Sol obligatoire
  pour Salamèche et Carapuce, sans Grotte Taupiqueur) ?
- **Q-T18-4** : si les données restent, faut-il un indice dans le jeu (guide de l'Arène, PNJ de
  Carmin : « les Pokémon de type Sol ne craignent pas l'électricité ») ? Texte à écrire par Kevin.
- **Q-T18-5** : le navire n'a aucun soin (cuisine, lit) : est-ce voulu ? (Le quai est à une
  sortie ; sans y retourner, le rival tombe à 0–9 %.)

## 8. Reproduire

```bash
python3 tools/sim/gen_ss_anne_scenarios.py            # régénère les deux scénarios
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/ss_anne_scenario.json --donnees --seeds 1000 --equipe "Carabaffe 21"
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/ss_anne_thresholds.json --seeds 1000 --variante "rival_ss_anne"
# --variante « vermilion_gym_surge », « sac de Carmin », « ordre », « surge_c_sans »… pour cibler
python3 tools/sim/path_table.py build/sim/j16_t18/parcours_*.txt       # tableau des parcours
python3 tools/sim/table_sim.py build/sim/j16_t18/seuils_*.txt          # tableau des seuils
```

Un parcours complet (11 équipes × 16 variantes × 1 000 graines) prend ≈ 1 h 30 sur le Mac chargé,
réparti en 5 processus par `--equipe` ; les seuils ≈ 15 min par réglage. Rapports bruts (non
versionnés) : `build/sim/j16_t18/`. Test : `tests/integration/test_simulate_ss_anne.gd`.
