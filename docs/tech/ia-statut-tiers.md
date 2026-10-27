# IA « smart » : tirage de statut à 1 sur 3 (2026-10-27)

Décision de Kevin (2026-10-27, option 1) : « une attaque de statut utile pas encore jouée a 1 chance
sur 3 d'être choisie ». Constat d'origine : `jalon-23.md` §9.2 (Toxik de Koga 34 contre Détritus 97,5 ;
Poudre Dodo et Para-Spore d'Erika 30 contre Méga-Sangsue 60 : presque jamais joués).

## Règle (règle 0 de `game/battle/battle_ai.gd`)

Avant le choix par la meilleure note : s'il existe au moins une capacité de statut **utile** (note > 0
selon les règles existantes : pas sous ⅓ des PV, effet encore possible, cible pas immunisée…) que ce
Pokémon n'a **pas encore jouée** dans ce combat (`times_used == 0`), un tirage
`rng.chance(STATUS_CHANCE_NUM, STATUS_CHANCE_DEN)` (1 sur 3) décide de la jouer ; plusieurs
candidates : `pick_index` parmi elles. Sinon, règles 1 à 4 inchangées. Le changement de Pokémon
(`AiSwitchRule`) reste décidé avant, sans tirage.

Valeurs par défaut [D] :

- **Le tirage passe avant « super efficace d'abord »** (règle 2) : sinon Toxik resterait bloqué dès
  que la cible craint une attaque du lanceur.
- **« Statut » au sens de la règle 0** = catégorie « status », **sauf** les capacités qui infligent des
  dégâts : dégâts fixes (Sonicboom, Frappe Atlas, Croc Fatal, Ombre Nocturne, Draco-Rage, Vague
  Psy), K.O. en un coup (Guillotine, Empal'Korne, Abîme), Riposte, Patience. Elles gardent leur note
  habituelle. Hurlement et Cyclone comptent comme statuts.
- Un statut joué par le tirage compte dans `times_used` (au plus 2 usages, comme avant) : jamais une
  deuxième fois **par le tirage**, mais un second usage reste possible par la note (égalité, ou plus
  d'attaque utile).
- Le **joueur simulé** des outils (`simulate_mt_moon.gd`, `simulate_brock.gd`) garde l'ancien
  comportement (`status_draw = false`) : le tirage ne concerne que les adversaires.
- Les combats « random » ne changent pas. Un tirage `roll(3)` de plus par tour seulement quand un
  statut neuf et utile existe : les combats « smart » rejouent d'autres tirages qu'avant à graine égale.

## Simulations avant / après (400 graines par ligne, `--donnees`)

Victoire au premier essai contre le combat nommé (parmi les parties qui l'atteignent), joueur
**attentif** sauf mention. Mêmes graines avant et après, mais les tirages divergent dès le premier
statut neuf : un écart de ±5 points est du bruit. **Gras** : ligne qui franchit un seuil de Kevin
(≤ 80 % par défaut, gros combats 35–60 %) ou bouge de plus de 15 points.

| Combat | Équipe (scénario) | Avant | Après |
|---|---|---|---|
| Pierre | Bulbizarre seul N11, 3 Potions (`simulate_brock`) | **76,2** | **37,5** |
| Pierre | Bulbizarre + Roucool, 3 Potions | 53,8 | 44,5 |
| Pierre | Kevin fin J9, 5 Potions | 1,0 | 7,0 |
| Pierre | Kevin, Salamèche N15 / N18 | 11,5 / 78,8 | 18,2 / 68,5 |
| Rival n° 3 | Herbizarre 19 (`cerulean_scenario`) | 10,8 | 23,0 |
| Rival n° 3 | Kevin : Reptincel 17… | 20,5 | 32,0 |
| Ondine | Herbizarre 19 / bas Herbizarre 18 | 100 / 84,6 | 95,7 / 87,5 |
| Rival n° 4 | Reptincel 21… (`ss_anne_scenario`, directe, soin) | 40,0 | 36,8 |
| Rival n° 4 | Carabaffe 21… | **43,8** | **28,2** |
| Rival n° 4 | Sol : Herbizarre 20… | **76,2** | **85,0** |
| Major Bob | Reptincel 21… / Kevin | 71,9 / 61,1 | 79,6 / 70,5 |
| Major Bob | Herbizarre 20… | 20,6 | 13,0 |
| Rival n° 5 | Reptincel 24… (`tower_scenario`) | **80,5** | **54,2** |
| Rival n° 5 | Herbizarre 24… | 33,2 | 44,5 |
| Rival n° 5 | Carabaffe 24… | **19,0** | **4,0** |
| Erika | Reptincel 26 + Férosinge (`celadon_thresholds`, 3 S.Potions) | 86,0 | 71,2 |
| Erika | Carabaffe 28 / 30 | 40,8 / 68,8 | 41,2 / 71,2 |
| Giovanni (Céladopole) | Reptincel 30… | **22,8** | **6,8** |
| Giovanni (Céladopole) | Reptincel 28 + Tunnel / Carabaffe 28 | 29,8 / 31,5 | 22,5 / 32,8 |
| Rival n° 6 | Dracaufeu 38… (`silph_scenario`) | 12,2 | 19,2 |
| Rival n° 6 | Tortank 38… | **57,2** | **38,8** |
| Giovanni (Sylphe) | Tortank, Centre après le rival | 46,7 | 53,5 |
| Koga | Arrivée basse Florizarre 38, deux inévitables (`fuchsia_j23_realiste`) | 49,2 | 60,2 |
| Koga | Arrivée basse Dracaufeu 38, six Dresseurs sans soin | 38,7 | 50,0 |
| Koga | Équipes « réalistes » N42 | 98–100 | 98–100 |
| Morgane | Dracaufeu / Florizarre / Tortank 42 (`saffron_gym_scenario`) | 34,2 / 13,0 / 48,0 | 40,0 / 19,0 / 53,2 |
| Auguste | QA j25 : Tortank 46…, six combats sans soin (`cinnabar_j25_realiste`) | **91,2** | **76,5** |
| Auguste | Florizarre 45 (basse), six combats sans soin | 38,0 | **60,2** |
| Auguste | Florizarre 48, six combats sans soin | 85,5 | 94,2 |
| Auguste | QA j25, joueur naïf | 39,8 | 58,2 |

Lecture : l'IA joue plus de statuts et moins de coups forts. **La plupart des Champions deviennent un
peu plus faciles** (Pierre pour Kevin, Major Bob, Koga, Morgane, Auguste à basse arrivée) ; **certains
rivaux et Giovanni deviennent plus durs** quand leurs statuts tombent bien (Rival n° 4 et n° 5 contre
Carabaffe, Rival n° 6 contre Tortank, Giovanni de Céladopole contre Reptincel 30, Pierre contre un
Bulbizarre seul : Boul'Armure et Armure ralentissent un combat que les Potions ne suffisent plus à
tenir).

Aucune donnée n'a été rééquilibrée. **Kevin a validé le tableau le 2026-10-27** : règle fusionnée telle quelle ; lignes en gras à rééquilibrer plus tard (`reportes.md` §2.14, RP-249 à RP-254).

Rapports bruts : copie de session (non versionnée) ; relancer avec
`godot --headless --path . -s res://tools/simulate_mt_moon.gd -- --scenario tools/sim/<x>.json --donnees --seeds 400`
et `tools/simulate_brock.gd -- --seeds 400`.
