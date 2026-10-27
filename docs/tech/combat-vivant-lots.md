# Combat vivant — lots d'animations P1 à P4 (classement par ordre d'exposition)

> Généré par `tools/art/classer_lots_cv.py` (T10, version courte). **Ne pas modifier à la main : relancer le script.** Annexe A de `combat-vivant.md` pour les familles. Les lots P1 à P4 ont 40, 40, 40 attaques puis le reste.

**Méthode.** Pour chaque attaque, la première étape de l'histoire où le joueur la voit : jouée par un Pokémon sauvage ou un Dresseur (les 4 dernières attaques de son learnset au niveau rencontré, ou la liste fixée par le Dresseur), ou apprise par un starter. Ordre des étapes ci-dessous ; à égalité : signature d'abord, puis nombre d'apparitions à cette étape. Les CT sont hors du calcul.

## Étapes

0. Bourg Palette et Route 1
1. Route 22, Route 2 sud, Jadielle
2. Forêt de Jade
3. Argenta (Route 2 nord, Arène de Pierre)
4. Route 3 et Mont Sélénite
5. Route 4, Azuria, Routes 24 et 25
6. Routes 5 et 6, Carmin, S.S. Anne
7. Routes 9 à 11, Grotte Sombre, Taupiqueur
8. Lavanville, Tour Pokémon, Céladopole
9. Routes 12 à 18, Parmanie, Safrania
10. Routes 19 à 21, Îles Écume, Cramois
11. Fin du jeu (Jadielle, Route 22 finale)

## Lot P1 (40 attaques)

Familles : contact 13, statut_moins 5, son 4, plante 4, statut_plus 4, poison 3, vent 2, eau 2, feu 1, electrique 1, sol_roche 1.

| # | id | Nom | Type | Famille | Impact | Modificateurs | Phare | Première exposition |
|---|---|---|---|---|---|---|---|---|
| 1 | `tackle` | Charge | Normal | contact | corps |  |  | Bourg Palette et Route 1 — Rattata niv. 3 (route_1) |
| 2 | `tail_whip` | Mimi-Queue | Normal | statut_moins |  |  |  | Bourg Palette et Route 1 — Rattata niv. 3 (route_1) |
| 3 | `growl` | Rugissement | Normal | son |  |  |  | Bourg Palette et Route 1 — Salamèche niv. 5 (rival:rival_lab) |
| 4 | `gust` | Tornade | Vol | vent |  |  |  | Bourg Palette et Route 1 — Roucool niv. 3 (route_1) |
| 5 | `bubble` | Écume | Eau | eau |  |  |  | Bourg Palette et Route 1 — apprise par Carapuce niv. 8 (starter) |
| 6 | `ember` | Flammèche | Feu | feu |  |  |  | Bourg Palette et Route 1 — apprise par Salamèche niv. 9 (starter) |
| 7 | `leech_seed` | Vampigraine | Plante | plante |  |  |  | Bourg Palette et Route 1 — apprise par Bulbizarre niv. 7 (starter) |
| 8 | `scratch` | Griffe | Normal | contact | griffe |  |  | Bourg Palette et Route 1 — Salamèche niv. 5 (rival:rival_lab) |
| 9 | `leer` | Groz'Yeux | Normal | statut_moins |  |  |  | Bourg Palette et Route 1 — apprise par Dracaufeu niv. 1 (starter) |
| 10 | `sand_attack` | Jet de Sable | Sol | statut_moins |  |  |  | Bourg Palette et Route 1 — Roucool niv. 5 (route_1) |
| 11 | `water_gun` | Pistolet à O | Eau | eau |  |  |  | Bourg Palette et Route 1 — apprise par Tortank niv. 1 (starter) |
| 12 | `vine_whip` | Fouet Lianes | Plante | plante |  |  |  | Bourg Palette et Route 1 — apprise par Florizarre niv. 1 (starter) |
| 13 | `peck` | Picpic | Vol | vent |  |  |  | Route 22, Route 2 sud, Jadielle — Piafabec niv. 6 (route_2) |
| 14 | `string_shot` | Sécrétion | Insecte | statut_moins |  |  |  | Forêt de Jade — Chenipan niv. 5 (viridian_forest) |
| 15 | `harden` | Armure | Normal | statut_plus |  |  |  | Forêt de Jade — Coconfort niv. 6 (viridian_forest) |
| 16 | `poison_sting` | Dard-Venin | Poison | poison |  |  |  | Forêt de Jade — Aspicot niv. 5 (viridian_forest) |
| 17 | `quick_attack` | Vive-Attaque | Normal | contact | corps |  |  | Forêt de Jade — Rattata niv. 7 (viridian_forest:forest_youngster_tom) |
| 18 | `thunder_shock` | Éclair | Électrik | electrique |  |  | **oui** | Forêt de Jade — Pikachu niv. 5 (viridian_forest) |
| 19 | `poison_powder` | Poudre Toxik | Poison | poison |  |  |  | Argenta (Route 2 nord, Arène de Pierre) — apprise par Bulbizarre niv. 20 (starter) |
| 20 | `bite` | Morsure | Ténèbres | contact | crocs |  |  | Argenta (Route 2 nord, Arène de Pierre) — apprise par Carapuce niv. 22 (starter) |
| 21 | `screech` | Grincement | Normal | son |  |  |  | Argenta (Route 2 nord, Arène de Pierre) — Onix niv. 14 (pewter_gym:pewter_gym_brock) |
| 22 | `defense_curl` | Boul'Armure | Normal | statut_plus |  |  |  | Argenta (Route 2 nord, Arène de Pierre) — Racaillou niv. 12 (pewter_gym:pewter_gym_brock) |
| 23 | `rock_throw` | Jet-Pierres | Roche | sol_roche |  |  |  | Argenta (Route 2 nord, Arène de Pierre) — Onix niv. 14 (pewter_gym:pewter_gym_brock) |
| 24 | `rage` | Frénésie | Normal | contact | corps |  |  | Argenta (Route 2 nord, Arène de Pierre) — apprise par Salamèche niv. 22 (starter) |
| 25 | `supersonic` | Ultrason | Normal | son |  |  |  | Route 3 et Mont Sélénite — Nosferapti niv. 10 (mt_moon) |
| 26 | `leech_life` | Vampirisme | Insecte | contact | percant | drain |  | Route 3 et Mont Sélénite — Nosferapti niv. 10 (mt_moon) |
| 27 | `pound` | Écras'Face | Normal | contact | coup |  |  | Route 3 et Mont Sélénite — Mélofée niv. 9 (mt_moon) |
| 28 | `wrap` | Ligotage | Normal | contact | corps | piege |  | Route 3 et Mont Sélénite — Abo niv. 10 (route_3) |
| 29 | `sing` | Berceuse | Normal | son |  |  |  | Route 3 et Mont Sélénite — Rondoudou niv. 9 (route_3) |
| 30 | `disable` | Entrave | Normal | statut_moins |  |  |  | Route 3 et Mont Sélénite — Rondoudou niv. 14 (route_3:route_3_ines) |
| 31 | `smog` | Purédpois | Poison | poison |  |  |  | Route 3 et Mont Sélénite — Smogo niv. 12 (mt_moon:mt_moon_researcher) |
| 32 | `hyper_fang` | Croc de Mort | Normal | contact | crocs |  |  | Route 4, Azuria, Routes 24 et 25 — Rattata niv. 14 (rival:rival_cerulean) |
| 33 | `withdraw` | Repli | Eau | statut_plus |  |  |  | Route 4, Azuria, Routes 24 et 25 — Kokiyas niv. 16 (cerulean_gym:cerulean_gym_lucas) |
| 34 | `karate_chop` | Poing Karaté | Combat | contact | coup |  |  | Route 4, Azuria, Routes 24 et 25 — Machoc niv. 17 (cerulean_rocket:cerulean_rocket) |
| 35 | `absorb` | Vol-Vie | Plante | plante |  | drain |  | Route 4, Azuria, Routes 24 et 25 — Mystherbe niv. 14 (route_24) |
| 36 | `growth` | Croissance | Normal | statut_plus |  |  |  | Route 4, Azuria, Routes 24 et 25 — Chétiflor niv. 14 (route_24) |
| 37 | `razor_leaf` | Tranch'Herbe | Plante | plante |  |  |  | Route 4, Azuria, Routes 24 et 25 — apprise par Bulbizarre niv. 27 (starter) |
| 38 | `horn_attack` | Koud'Korne | Normal | contact | percant |  |  | Route 4, Azuria, Routes 24 et 25 — Nidoran♂ niv. 16 (route_24:route_24_romane) |
| 39 | `fury_attack` | Furie | Normal | contact | percant | multi |  | Route 4, Azuria, Routes 24 et 25 — Piafabec niv. 15 (route_25:route_25_youngster_jules) |
| 40 | `slash` | Tranche | Normal | contact | griffe |  |  | Route 4, Azuria, Routes 24 et 25 — apprise par Salamèche niv. 30 (starter) |

## Lot P2 (40 attaques)

Familles : contact 10, statut_plus 3, psy 3, plante 3, spectre 3, poison 3, eau 2, son 2, sol_roche 2, vent 2, statut_moins 2, electrique 1, feu 1, dragon 1, soin 1, energie 1.

| # | id | Nom | Type | Famille | Impact | Modificateurs | Phare | Première exposition |
|---|---|---|---|---|---|---|---|---|
| 1 | `bind` | Étreinte | Normal | contact | corps | piege |  | Route 4, Azuria, Routes 24 et 25 — Onix niv. 17 (route_25:route_25_hiker_bernard) |
| 2 | `teleport` | Téléport | Psy | statut_plus |  |  |  | Route 4, Azuria, Routes 24 et 25 — Abra niv. 12 (route_25) |
| 3 | `bubble_beam` | Bulles d'O | Eau | eau |  |  |  | Route 4, Azuria, Routes 24 et 25 — Staross niv. 19 (cerulean_gym:cerulean_gym_misty) |
| 4 | `confusion` | Choc Mental | Psy | psy |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Kadabra niv. 13 (rival:rival_ss_anne) |
| 5 | `thunder_wave` | Cage-Éclair | Électrik | electrique |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Pikachu niv. 16 (route_6:route_6_lass_manon) |
| 6 | `psybeam` | Rafale Psy | Psy | psy |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Kadabra niv. 13 (rival:rival_ss_anne) |
| 7 | `sonic_boom` | Sonicboom | Normal | son |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Voltorbe niv. 20 (vermilion_gym:vermilion_gym_rocker_axel) |
| 8 | `low_kick` | Balayage | Combat | contact | coup |  |  | Routes 5 et 6, Carmin, S.S. Anne — Machoc niv. 18 (ss_anne:ss_anne_sailor_erwan) |
| 9 | `stun_spore` | Para-Spore | Plante | plante |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Papilusion niv. 20 (route_6:route_6_scout_basile) |
| 10 | `sleep_powder` | Poudre Dodo | Plante | plante |  |  |  | Routes 5 et 6, Carmin, S.S. Anne — Papilusion niv. 20 (route_6:route_6_scout_basile) |
| 11 | `focus_energy` | Puissance | Normal | statut_plus |  |  |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Nidorino niv. 26 (dark_cave:dark_cave_yanis) |
| 12 | `double_slap` | Torgnoles | Normal | contact | coup | multi |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Rondoudou niv. 26 (dark_cave:dark_cave_simon) |
| 13 | `dig` | Tunnel | Sol | sol_roche |  | charge |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Taupiqueur niv. 22 (digletts_cave) |
| 14 | `hypnosis` | Hypnose | Psy | psy |  |  |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Soporifik niv. 15 (route_11) |
| 15 | `whirlwind` | Cyclone | Normal | vent |  |  |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Roucool niv. 22 (dark_cave:dark_cave_elsa) |
| 16 | `glare` | Regard Médusant | Normal | statut_moins |  |  |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Abo niv. 26 (route_9:route_9_camper_jules) |
| 17 | `pay_day` | Jackpot | Normal | contact | coup |  |  | Routes 9 à 11, Grotte Sombre, Taupiqueur — Miaouss niv. 26 (route_9:route_9_lass_zoe) |
| 18 | `confuse_ray` | Onde Folie | Spectre | spectre |  |  |  | Lavanville, Tour Pokémon, Céladopole — Fantominus niv. 24 (pokemon_tower) |
| 19 | `night_shade` | Ténèbres | Spectre | spectre |  |  |  | Lavanville, Tour Pokémon, Céladopole — Fantominus niv. 24 (pokemon_tower) |
| 20 | `lick` | Léchouille | Spectre | spectre |  |  |  | Lavanville, Tour Pokémon, Céladopole — Fantominus niv. 24 (pokemon_tower) |
| 21 | `bone_club` | Massd'Os | Sol | sol_roche |  |  |  | Lavanville, Tour Pokémon, Céladopole — Osselait niv. 22 (pokemon_tower) |
| 22 | `skull_bash` | Coud'Krâne | Normal | contact | corps | charge |  | Lavanville, Tour Pokémon, Céladopole — apprise par Carapuce niv. 35 (starter) |
| 23 | `smokescreen` | Brouillard | Normal | statut_moins |  |  |  | Lavanville, Tour Pokémon, Céladopole — Hypotrempe niv. 22 (route_8:route_8_gambler_rene) |
| 24 | `roar` | Hurlement | Normal | son |  |  |  | Lavanville, Tour Pokémon, Céladopole — Caninos niv. 20 (route_7) |
| 25 | `flamethrower` | Lance-Flammes | Feu | feu |  |  | **oui** | Lavanville, Tour Pokémon, Céladopole — apprise par Salamèche niv. 38 (starter) |
| 26 | `barrage` | Pilonnage | Normal | contact | corps | multi |  | Lavanville, Tour Pokémon, Céladopole — Noeunoeuf niv. 20 (pokemon_tower:rival_tower) |
| 27 | `dragon_rage` | Draco-Rage | Dragon | dragon |  |  |  | Lavanville, Tour Pokémon, Céladopole — Léviator niv. 20 (pokemon_tower:rival_tower) |
| 28 | `headbutt` | Coup d'Boule | Normal | contact | corps |  |  | Lavanville, Tour Pokémon, Céladopole — Soporifik niv. 26 (pokemon_tower_7f:tower_rocket_2) |
| 29 | `constrict` | Constriction | Normal | contact | corps |  |  | Lavanville, Tour Pokémon, Céladopole — Saquedeneu niv. 24 (celadon_gym:celadon_gym_erika) |
| 30 | `comet_punch` | Poing Comète | Normal | contact | coup | multi |  | Lavanville, Tour Pokémon, Céladopole — Kangourex niv. 25 (rocket_hideout:giovanni_hideout) |
| 31 | `hydro_pump` | Hydrocanon | Eau | eau |  |  | **oui** | Lavanville, Tour Pokémon, Céladopole — apprise par Carapuce niv. 42 (starter) |
| 32 | `mega_drain` | Méga-Sangsue | Plante | plante |  | drain |  | Lavanville, Tour Pokémon, Céladopole — Rafflesia niv. 29 (celadon_gym:celadon_gym_erika) |
| 33 | `acid` | Acide | Poison | poison |  |  |  | Routes 12 à 18, Parmanie, Safrania — Mystherbe niv. 24 (route_12_sud) |
| 34 | `mirror_move` | Mimique | Vol | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Piafabec niv. 22 (route_16_ouest) |
| 35 | `poison_gas` | Gaz Toxik | Poison | poison |  |  |  | Routes 12 à 18, Parmanie, Safrania — Hypnomade niv. 38 (fuchsia_gym:fuchsia_gym_juggler_1) |
| 36 | `fury_swipes` | Combo-Griffe | Normal | contact | griffe | multi |  | Routes 12 à 18, Parmanie, Safrania — Férosinge niv. 31 (fighting_dojo:fighting_dojo_blackbelt_hippolyte) |
| 37 | `recover` | Soin | Normal | soin |  |  |  | Routes 12 à 18, Parmanie, Safrania — Kadabra niv. 31 (fuchsia_gym:fuchsia_gym_juggler_2) |
| 38 | `sludge` | Détritus | Poison | poison |  |  |  | Routes 12 à 18, Parmanie, Safrania — Smogo niv. 37 (fuchsia_gym:fuchsia_gym_koga) |
| 39 | `wing_attack` | Cru-Ailes | Vol | vent |  |  |  | Routes 12 à 18, Parmanie, Safrania — Roucarnage niv. 37 (rival:rival_silph) |
| 40 | `self_destruct` | Destruction | Normal | energie |  | auto_ko | **oui** | Routes 12 à 18, Parmanie, Safrania — Smogogo niv. 43 (fuchsia_gym:fuchsia_gym_koga) |

## Lot P3 (40 attaques)

Familles : statut_plus 12, contact 11, psy 3, glace 3, feu 3, plante 2, sol_roche 2, vent 1, poison 1, eau 1, energie 1.

| # | id | Nom | Type | Famille | Impact | Modificateurs | Phare | Première exposition |
|---|---|---|---|---|---|---|---|---|
| 1 | `reflect` | Protection | Psy | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Noeunoeuf niv. 25 (safari) |
| 2 | `light_screen` | Mur Lumière | Psy | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Voltorbe niv. 29 (route_12_sud:route_12_rocker) |
| 3 | `psychic` | Psyko | Psy | psy |  |  | **oui** | Routes 12 à 18, Parmanie, Safrania — Hypnomade niv. 38 (fuchsia_gym:fuchsia_gym_juggler_1) |
| 4 | `minimize` | Lilliput | Normal | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Grotadmorv niv. 39 (fuchsia_gym:fuchsia_gym_koga) |
| 5 | `stomp` | Écrasement | Normal | contact | coup |  |  | Routes 12 à 18, Parmanie, Safrania — Tauros niv. 28 (safari) |
| 6 | `barrier` | Bouclier | Psy | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — M. Mime niv. 31 (saffron_gym:saffron_gym_psychic_albin) |
| 7 | `drill_peck` | Bec Vrille | Vol | vent |  |  |  | Routes 12 à 18, Parmanie, Safrania — Piafabec niv. 29 (route_14:route_14_bird_2) |
| 8 | `meditate` | Yoga | Psy | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Kicklee niv. 37 (fighting_dojo:fighting_dojo_master) |
| 9 | `take_down` | Bélier | Normal | contact | corps | contrecoup |  | Routes 12 à 18, Parmanie, Safrania — Caninos niv. 38 (rival:rival_silph) |
| 10 | `vise_grip` | Force Poigne | Normal | contact | griffe |  |  | Routes 12 à 18, Parmanie, Safrania — Scarabrute niv. 23 (safari) |
| 11 | `splash` | Trempette | Normal | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Magicarpe niv. 24 (route_12_sud:route_12_fisher_5) |
| 12 | `agility` | Hâte | Psy | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Tygnon niv. 37 (fighting_dojo:fighting_dojo_master) |
| 13 | `haze` | Buée Noire | Glace | glace |  |  |  | Routes 12 à 18, Parmanie, Safrania — Smogo niv. 37 (fuchsia_gym:fuchsia_gym_koga) |
| 14 | `body_slam` | Plaquage | Normal | contact | corps |  |  | Routes 12 à 18, Parmanie, Safrania — Nidoqueen niv. 41 (silph_co:silph_co_giovanni) |
| 15 | `seismic_toss` | Frappe Atlas | Combat | contact | corps |  |  | Routes 12 à 18, Parmanie, Safrania — Scarabrute niv. 28 (safari) |
| 16 | `double_kick` | Double Pied | Combat | contact | coup | multi |  | Routes 12 à 18, Parmanie, Safrania — Kicklee niv. 37 (fighting_dojo:fighting_dojo_master) |
| 17 | `double_team` | Reflet | Normal | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Insécateur niv. 28 (safari) |
| 18 | `dream_eater` | Dévorêve | Psy | psy |  | drain |  | Routes 12 à 18, Parmanie, Safrania — Spectrum niv. 38 (saffron_gym:saffron_gym_channeler_ophelie) |
| 19 | `fire_punch` | Poing de Feu | Feu | feu |  |  |  | Routes 12 à 18, Parmanie, Safrania — Tygnon niv. 37 (fighting_dojo:fighting_dojo_master) |
| 20 | `metronome` | Métronome | Normal | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Mélofée niv. 33 (route_15:route_15_lass_2) |
| 21 | `psywave` | Vague Psy | Psy | psy |  |  |  | Routes 12 à 18, Parmanie, Safrania — Alakazam niv. 43 (saffron_gym:saffron_gym_sabrina) |
| 22 | `rolling_kick` | Mawashi Geri | Combat | contact | coup |  |  | Routes 12 à 18, Parmanie, Safrania — Kicklee niv. 37 (fighting_dojo:fighting_dojo_master) |
| 23 | `spore` | Spore | Plante | plante |  |  |  | Routes 12 à 18, Parmanie, Safrania — Parasect niv. 30 (safari) |
| 24 | `swords_dance` | Danse-Lames | Normal | statut_plus |  |  |  | Routes 12 à 18, Parmanie, Safrania — Canarticho niv. 33 (route_14:route_14_bird_1) |
| 25 | `toxic` | Toxik | Poison | poison |  |  |  | Routes 12 à 18, Parmanie, Safrania — Smogogo niv. 43 (fuchsia_gym:fuchsia_gym_koga) |
| 26 | `aurora_beam` | Onde Boréale | Glace | glace |  |  |  | Routes 19 à 21, Îles Écume, Cramois — Kokiyas niv. 30 (seafoam_1f) |
| 27 | `clamp` | Claquoir | Eau | eau |  | piege |  | Routes 19 à 21, Îles Écume, Cramois — Kokiyas niv. 30 (seafoam_1f) |
| 28 | `fire_spin` | Danse Flamme | Feu | feu |  | piege |  | Routes 19 à 21, Îles Écume, Cramois — Ponyta niv. 45 (cinnabar_gym:cinnabar_gym_4) |
| 29 | `guillotine` | Guillotine | Normal | contact | griffe | ko_un_coup |  | Routes 19 à 21, Îles Écume, Cramois — Krabby niv. 30 (seafoam_1f) |
| 30 | `swift` | Météores | Normal | energie |  |  |  | Routes 19 à 21, Îles Écume, Cramois — Stari niv. 32 (seafoam_b1f) |
| 31 | `solar_beam` | Lance-Soleil | Plante | plante |  | charge | **oui** | Routes 19 à 21, Îles Écume, Cramois — apprise par Bulbizarre niv. 48 (starter) |
| 32 | `fire_blast` | Déflagration | Feu | feu |  |  | **oui** | Routes 19 à 21, Îles Écume, Cramois — Arcanin niv. 47 (cinnabar_gym:cinnabar_gym_blaine) |
| 33 | `horn_drill` | Empal'Korne | Normal | contact | percant | ko_un_coup |  | Fin du jeu (Jadielle, Route 22 finale) — Rhinocorne niv. 45 (viridian_gym:viridian_gym_giovanni) |
| 34 | `thrash` | Mania | Normal | contact | corps |  |  | Fin du jeu (Jadielle, Route 22 finale) — Nidoking niv. 39 (viridian_gym:viridian_gym_cooltrainer_damien) |
| 35 | `fissure` | Abîme | Sol | sol_roche |  | ko_un_coup |  | Fin du jeu (Jadielle, Route 22 finale) — Rhinoféros niv. 50 (viridian_gym:viridian_gym_giovanni) |
| 36 | `acid_armor` | Acidarmure | Poison | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 37 | `amnesia` | Amnésie | Psy | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 38 | `bide` | Patience | Normal | contact | corps |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 39 | `blizzard` | Blizzard | Glace | glace |  |  | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 40 | `bonemerang` | Osmerang | Sol | sol_roche |  | multi |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |

## Lot P4 (45 attaques)

Familles : contact 17, statut_plus 6, eau 3, energie 3, statut_moins 3, vent 3, electrique 3, sol_roche 2, glace 2, soin 2, plante 1.

| # | id | Nom | Type | Famille | Impact | Modificateurs | Phare | Première exposition |
|---|---|---|---|---|---|---|---|---|
| 1 | `conversion` | Conversion | Normal | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 2 | `counter` | Riposte | Combat | contact | corps |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 3 | `crabhammer` | Pince-Masse | Eau | eau |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 4 | `cut` | Coupe | Normal | contact | griffe |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 5 | `dizzy_punch` | Uppercut | Normal | contact | coup |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 6 | `double_edge` | Damoclès | Normal | contact | corps | contrecoup |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 7 | `earthquake` | Séisme | Sol | sol_roche |  |  | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 8 | `egg_bomb` | Bomb'Œuf | Normal | contact | corps |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 9 | `explosion` | Explosion | Normal | energie |  | auto_ko | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 10 | `flash` | Flash | Normal | statut_moins |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 11 | `fly` | Vol | Vol | vent |  | charge |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 12 | `hi_jump_kick` | Pied Voltige | Combat | contact | coup | chute |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 13 | `hyper_beam` | Ultralaser | Normal | energie |  | recharge | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 14 | `ice_beam` | Laser Glace | Glace | glace |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 15 | `ice_punch` | Poing-Glace | Glace | glace |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 16 | `jump_kick` | Pied Sauté | Combat | contact | coup | chute |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 17 | `kinesis` | Télékinésie | Psy | statut_moins |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 18 | `lovely_kiss` | Grobisou | Normal | statut_moins |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 19 | `mega_kick` | Ultimawashi | Normal | contact | coup |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 20 | `mega_punch` | Ultimapoing | Normal | contact | coup |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 21 | `mimic` | Copie | Normal | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 22 | `mist` | Brume | Glace | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 23 | `petal_dance` | Danse Fleur | Plante | plante |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 24 | `pin_missile` | Dard-Nuée | Insecte | contact | percant | multi |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 25 | `razor_wind` | Coupe-Vent | Normal | vent |  | charge |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 26 | `rest` | Repos | Psy | soin |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 27 | `rock_slide` | Éboulement | Roche | sol_roche |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 28 | `sharpen` | Affûtage | Normal | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 29 | `sky_attack` | Piqué | Vol | vent |  | charge |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 30 | `slam` | Souplesse | Normal | contact | corps |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 31 | `soft_boiled` | E-Coque | Normal | soin |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 32 | `spike_cannon` | Picanon | Normal | contact | percant | multi |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 33 | `strength` | Force | Normal | contact | corps |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 34 | `struggle` | Lutte | Normal | contact | corps | contrecoup |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 35 | `submission` | Sacrifice | Combat | contact | corps | contrecoup |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 36 | `substitute` | Clonage | Normal | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 37 | `super_fang` | Croc Fatal | Normal | contact | crocs |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 38 | `surf` | Surf | Eau | eau |  |  | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 39 | `thunder` | Fatal-Foudre | Électrik | electrique |  |  | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 40 | `thunder_punch` | Poing-Éclair | Électrik | electrique |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 41 | `thunderbolt` | Tonnerre | Électrik | electrique |  |  | **oui** | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 42 | `transform` | Morphing | Normal | statut_plus |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 43 | `tri_attack` | Triplattaque | Normal | energie |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 44 | `twineedle` | Double-Dard | Insecte | contact | percant | multi |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
| 45 | `waterfall` | Cascade | Eau | eau |  |  |  | jamais vue — jamais vue (CT, apprentissage, jalon à venir) |
