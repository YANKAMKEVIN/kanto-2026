# Jalon 13 — équilibrage par simulation (T20)

> **Information pour Kevin. Aucune donnée de jeu n'a été changée** (`data/` intact). Les réglages
> « essayés » ci-dessous n'existent que dans les scénarios de simulation (`tools/sim/`).
> Plan : `jalon-13.md` §2.22 et fiches T9 / T20. Modèle : J12 T26 (`jalon-12.md` §9).

Branche `j13-t20` (depuis `jalon-13` à `748b317`), 2026-10-14, architecte.

## 1. Méthode

- Outil : `tools/simulate_mt_moon.gd` (vrai moteur, vraie IA, vraies données ; une graine = une
  partie). **1 000 graines par ligne** (écart-type ≤ 1,6 point ; les écarts < 3 points ne
  comptent pas).
- `tools/sim/cerulean_scenario.json` (parcours complet, `--donnees` : rival, Ondine, Clara, Arène,
  pont, recruteur et tables tels que dans `data/`) : Route 4 H2 (4 cases), [détours : H1/H3,
  Clara, Lucas, Diane], Centre, **rival**, Centre, [Route 24 nord : P1–P5, recruteur, 40 cases
  d'herbes, Centre], **Ondine**. Reprises au Centre après une défaite (« retries » : 5) →
  **tentatives** jusqu'à la victoire.
- `tools/sim/cerulean_thresholds.json` (seuils) : un seul combat (équipe soignée, 3 Potions),
  échelle de niveaux par starter, réglages de comparaison. Au premier essai p ; rien ne change
  entre deux essais, donc tentatives ≈ 1 / p.
- `switch: true` sur le rival et Ondine (comme `data/`). Les Dresseurs et l'IA sont ceux du jeu.
- Joueurs : **naïf** (attaque au hasard, aucun objet), **attentif** (IA `smart` du jeu, Potions,
  meilleur Pokémon en tête, J12), **expert** (nouveau : toujours l'attaque la plus forte, jamais de
  statut, change de Pokémon quand un autre est nettement mieux placé). L'attentif gâche des tours
  (Rugissement contre une attaque spéciale) : l'expert borne ce biais.
- **Pas de capture, pas de CT, pas d'entraînement libre** : le simulateur ne joue que les cases
  d'herbes obligatoires. Durées en **tours** (pas en secondes).

### Partie de Kevin

La sauvegarde copiée pendant la QA 13.0 (`save.json` du 2026-10-13, v6) est **à Jadielle** :
Salamèche N8, Roucool N3, Rattata N3, Nidoran♂ N3, 5 Potions, 2 100 ₽. Elle ne peut pas servir de
départ (`--save` mettrait un N8 contre Roucoups N18). Seules ses **espèces** sont reprises :
équipe « Kevin » (Reptincel, Roucool, Nidoran♂, Rattata, niveaux [D]). **Les équipes de départ
sont donc estimées** (ci-dessous).

## 2. Niveau d'arrivée estimé

| Point | Salamèche | Bulbizarre | Carapuce | Source |
|---|---|---|---|---|
| Sortie du Mont Sélénite, directe | Reptincel **17,1** (Férosinge 15,6, Roucool 14, Papilusion 12) | Herbizarre **17,6** | Carabaffe **18,0** | J12 (`mt_moon_scenario.json --donnees`, attentif + Potions) |
| Sortie, avec détours du J12 | 18,7 | 18,1 | 19,0 | idem |
| Estimation du §2.22 (« J12 minimal ») | 19 | 19 | 19 | plan, à la main |
| Devant le rival (Route 4 H2) | +0 (0,4 combat) ; détours d'Azuria +0,5 | | | T20 |
| Devant Ondine, directe | +0,3 (XP du rival) | | | T20 |
| Devant Ondine, avec la Route 24 nord | **+2,5 à +3** (19,7–22,1) | | | T20 |

L'estimation du §2.22 (meneur 19–22) est **1 à 2 niveaux trop haute** pour un joueur qui ne
s'entraîne pas ; seuls les meneurs progressent, les autres membres restent à leur niveau de
sortie. « Bas » = sortie directe (17 / 18 / 18) ; « haut » = §2.22 (19 + Roucool 16…).

## 3. Résultats (données actuelles)

Victoire au **premier essai** (attentif · expert · naïf) ; entre parenthèses : tentatives
moyennes jusqu'à la victoire, et part des parties qui gagnent en 6 essais au plus si < 100 %.

| Starter, équipe | Rival n° 3 | Ondine (directe) | Ondine (après Route 24 nord) |
|---|---|---|---|
| Salamèche bas : Reptincel 17, Férosinge 16, Roucool 14, Papilusion 12 | 90 · 87 · 18 % (1,1 · 1,2 · 3,1 ; naïf 80 %) | **0 · 0 · 0 %** (jamais) | **0 · 0 · 0 %** (jamais) |
| Salamèche haut : Reptincel 19, Férosinge 16, Roucool 16 | 95 · 94 · 51 % (1,05 · 1,06 · 1,9) | 0 · 0 · 0 % | 0 · 0 · 0 % |
| Salamèche « Kevin » : Reptincel 17, Roucool 14, Nidoran♂ 12, Rattata 12 | **4 · 2 · 0 %** (4,4 · 4,7 · 5,0 ; **56 · 53 · 13 %**) | 0 % | 0 % |
| Salamèche bas + Mystherbe 13 | 99 · 99 · 52 % | 0 % | 0 % |
| Bulbizarre bas : Herbizarre 18, Roucool 14, Papilusion 12 | **0 · 0 · 0 %** (jamais en 6 essais) | — (≈ 88–90 % au seuil) | — |
| Bulbizarre haut : Herbizarre 19, Roucool 16 | **0 · 0 · 0 %** | — | — |
| Carapuce bas : Carabaffe 18, Roucool 14, Papilusion 12 | 98 · 98 · 51 % (1,03 · 1,03 · 1,9) | **0 · 0 · 0 %** | 0 · 0 % (≤ 1 % en 6 essais) |
| Carapuce haut : Carabaffe 19, Roucool 16, Papilusion 15 | 100 · 100 · 95 % | 0 · 0 · 0 % | 0 · 1 % (2 · 8 % en 6 essais) |

**Seuils** (premier essai, attentif · expert, `cerulean_thresholds.json`) :

| Équipe (meneur N) | Rival N18 · 20 · 22 | Ondine N18 · 20 · 22 · 24 |
|---|---|---|
| Reptincel, Férosinge N−2, Roucool N−3, Papilusion N−5 | 99 · 100 · 100 | 0 · 0 · 0 · **0–1** |
| Reptincel + Mystherbe N−4 | 100 · 100 · 100 | 0 · 0–2 · **47–72** · 98–100 |
| « Kevin » (Roucool N−3, Nidoran♂ et Rattata N−5) | **28–35** · 98–99 · 100 | 0 · 0 · 0 · 0–4 |
| Herbizarre, Roucool N−3, Papilusion N−5 | **0 · 0–8 · 75–94** | 88–90 · 99 · 100 · 100 |
| Carabaffe, Roucool N−3, Papilusion N−5 | 98–99 · 100 · 100 | 0 · 5–9 · **59–78** · 100 |

- **Changement de Pokémon de l'IA** : sans effet sur le rival (± 5 points) ; pour Ondine, il
  **aide** plutôt le joueur (Carabaffe 22 : 59–78 % avec, 36–50 % sans).
- **Pont Pépite** (P1–P5 + recruteur, enchaînés après le Centre) : **≈ 27 tours** (attentif),
  35–45 (naïf), soit ≈ 6 à 7 min de combats en comptant 10 s par tour et 20 s d'entrée et de
  sortie par combat [hypothèse]. Usure sans blocage : attentif, défaites au premier essai ≤ 2 %
  par Dresseur et 4 % dans les herbes du nord (Salamèche bas), mais Carabaffe bas 20 % (Ethan),
  32 % (recruteur), 30 % (herbes) ; naïf 45–82 % au recruteur. Battus en 1,0 à 1,4 tentative
  (≥ 99 % des parties en 6 essais).
- Route 4, Clara, Lucas : ≤ 0,3 % de défaites ; Diane (Poissirène N19) 7 % (Salamèche haut).

## 4. Constats

1. **Blocage possible : Bulbizarre contre le rival** (combat **obligatoire**, V-6). Roucoups N18
   (Tornade, super efficace) ouvre, Reptincel N17 (Flammèche) ferme. Herbizarre 18–20 : 0 à 8 % ;
   il faut **N22** (75–94 %). De 18 à 22 : ≈ 3 800 XP, ≈ 45 combats sauvages sur la Route 4
   (seules herbes accessibles avant lui, avec l'Arène : Lucas et Diane ne suffisent pas, 0 % avec
   les détours). Les détours n'y changent rien.
2. **Salamèche sans Férosinge** (équipe aux espèces de Kevin) : rival à 2–4 % au N17,
   28–35 % au N18, 98 % au N20. Le Férosinge (Poing Karaté contre Rattata et Roucoups) fait la
   différence.
3. **Ondine est un mur pour Salamèche et Carapuce** aux niveaux d'arrivée (0 %, même après la
   Route 24 nord). Salamèche sans plante : 0–4 % même au N24 ; avec un Mystherbe à N−4 : 47–72 %
   au N22. Carapuce : il faut N22. Staross N21 (Bulles d'O, Vitesse 115, IA `smart` qui lance
   toujours Bulles d'O) met un Pokémon K.O. en 1 à 2 coups. Pas d'impasse stricte (la Route 24 nord
   et l'Arène restent accessibles, Ondine n'ouvre rien au J13), mais l'entraînement demandé est
   bien au-delà du « tendu » du §2.22.
4. La Route 24 nord donne +2,5 à +3 niveaux au meneur seulement : elle prépare, elle ne suffit pas.

## 5. Recommandations (à trancher par Kevin)

**R-1 Rival n° 3 — ajuster (blocage).** Mesuré (Herbizarre N18 · N20, attentif–expert) :

| Réglage (tous starters) | Herbizarre 18 | Herbizarre 20 | Kevin 18 | Autres |
|---|---|---|---|---|
| Données actuelles | 0 % | 0–8 % | 28–35 % | 98–100 % |
| **IA `random` (garde le changement) + Roucoups N16** | **54–73 %** | **93–98 %** | 94–96 % | inchangés |
| IA `random` seule | 20–38 % | 74–87 % | 91–93 % | inchangés |
| Contre Bulbizarre seul : Roucoups N16, Reptincel N15, IA `random` | 66–85 % | 97–99 % | (= IA `random`) | inchangés |
| Roucoups N16 seul · Roucool N16 · starter N15 | 0–1 % · 0–1 % · 0 % | 10–36 · 24–52 · 4–37 % | — | — |

Recommandation : **IA `random` + Roucoups N16** (même levier qu'au J12 pour R3 ; espèces, ordre et
changement de Pokémon gardés ; récompense 35 ₽ × dernier niveau inchangée). Le rival reste le plus
dur des quatre combats de la boucle pour Bulbizarre. À noter : son **Rattata N15 a Croc de
Mort** (cause du mur de R3 au J12 avec l'IA `smart`) ; son poids n'est pas isolé ici.

**R-2 Ondine — ajuster.** Mesuré (premier essai, attentif–expert) :

| Réglage | Carabaffe 20 | Carabaffe 22 | Reptincel 20 + Mystherbe 16 | Reptincel 22 sans plante | Herbizarre 18 |
|---|---|---|---|---|---|
| Données actuelles | 5–9 % | 59–78 % | 0–2 % | 0 % | 88–90 % |
| **IA `random` (garde le changement)** | **52–69 %** | **97–99 %** | **92–95 %** | 8–22 % | 99,6 % |
| Staross N19 | 66–84 % | 97–99 % | 49–68 % | 0–1 % | 99 % |
| Staross sans Bulles d'O (N21) | 37–52 % | 93–98 % | 90–95 % | 1–5 % | 97 % |
| Staross N19 sans Bulles d'O | 89–96 % | 100 % | 99 % | 32–81 % | 100 % |

Recommandation : **IA `random`**, équipe et capacités de Rouge/Bleu gardées (Bulles d'O comprise,
c'est aussi la CT11 donnée) : Ondine reste le mur historique de Salamèche **sans plante**, et le
Mystherbe de la Route 24 nord devient la vraie réponse (le rôle voulu par le §2.22). Plus
généreux : Staross N19 sans Bulles d'O.

**R-3 Pont Pépite (niveaux 10–18), recruteur : garder.** Usure voulue, aucun blocage
(≤ 1,4 tentative), ≈ 27 tours.

**R-4 Route 4, Clara, Arène (Lucas, Diane) : garder.**

## 6. Questions pour Kevin

- Q-T20-1 : rival n° 3 — R-1 (IA `random` + Roucoups N16) ou autre réglage, ou garder (risque de
  blocage pour Bulbizarre) ?
- Q-T20-2 : Ondine — R-2 (IA `random`) ou autre réglage, ou garder le mur ?
- Q-T20-3 : niveaux de sortie du Mont Sélénite plus bas que l'estimation du §2.22 : faut-il viser
  un joueur qui s'entraîne (meneur ≈ 20) ou celui qui suit le chemin (≈ 17–18) ?

## 7. Reproduire

```bash
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/cerulean_scenario.json --donnees --seeds 1000   # ≈ 10 min
godot --headless --path . -s res://tools/simulate_mt_moon.gd -- \
  --scenario res://tools/sim/cerulean_thresholds.json --seeds 1000           # ≈ 10 min
# --equipe <texte>, --variante <texte>, --trace <étape> pour cibler
```

Rapports bruts (non versionnés) : `build/sim/t20/`.
