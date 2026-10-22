extends GutTest
## Cohérence des scènes scriptées de data/cutscenes/ avec les vraies cartes, les vrais PNJ
## et les vrais dialogues (jalon 3B §3.6, T4) :
## - chargement sans erreur ; chaque déclencheur vise une scène existante, chaque scène est
##   visée ; chaque dialogue d'étape existe ; chaque change_map vise une carte et un point
##   d'apparition existants ;
## - simulation statique de chaque variante : départ sur la carte de son déclencheur, avec
##   les drapeaux qui la choisissent ; « set » et « spawn » au fil des étapes ; à chaque
##   change_map, PNJ **présents** de la carte cible pour les drapeaux du moment. Chaque
##   acteur (face, move, follower, near), chaque cible de face qui n'est pas une direction,
##   et chaque acteur ou cible de « turn » des dialogues joués existe à ce moment-là.
## Jalon 4 (T1) : la variante 1 de route1_grass finit par la proposition de Chen
## (wait 0,5 s, oak_starter_offer, set starter_offered).
## T3 (jalon-04.md §13.5, §13.6) : scène oak_lab_exit (déclencheur LabExit du labo, choix en
## cours seulement) ; scène starter_chosen **jouée par le code** (StarterChoice, pas de
## déclencheur), simulée sur le labo avec les 3 jeux d'alias de l'offre ; elle lève
## starter_chosen une seule fois, juste après « On dirait que le choix est réciproque. ».
## Jalon 7 (T25) : scène du rival n° 2 (déclencheur de la Route 22), simulée pour les trois
## paires `taken_*` (Pokémon du rival) et les deux issues du combat ; l'étape « wake_up » arrête
## la simulation (la scène s'arrête au réveil). Correctif : les scènes **déclenchées** n'étaient
## plus simulées (boucle indentée sous `if CODE_PLAYED.has(id)`), elles le sont de nouveau.
## Jalon 8 (T4) : objets de la Route 2 — deux visibles (scène lancée par le dialogue du PNJ
## « objet », qui le retire : `despawn` → `give found` → `set`), deux cachés (déclencheurs de la
## carte, comme la Potion de la Route 1), posés par `tools/build_route_2.gd` (T5).
## Jalon 10 (T8) : arrivée à Argenta et garde de la Route 3 (déclencheurs d'Argenta, en attente de
## la carte du T11 : simulés sur les PNJ de son fichier), Potion de la Route 2 nord et scène de
## Pierre (lancées par le dialogue de leur PNJ) ; étapes `champion_card` et `badge` au T9 (la
## simulation vérifie le Dresseur et sa carte, le badge et son drapeau).

const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
	&"route_1", &"viridian_city", &"route_22", &"viridian_mart", &"route_2",
	# Jalon 9 (T19) : déclencheurs des objets cachés de la forêt.
	&"viridian_forest",
	# Jalon 10 (T11) : arrivée à Argenta et verrou du garde de la Route 3.
	&"pewter_city",
	# Jalon 13 (T17) : arrivée à Azuria (déclencheurs ouest et nord).
	&"cerulean_city",
	# Jalon 13 (T19) : déclencheurs du rival n° 3 et de la reprise d'Ondine.
	&"route_24",
	# Jalon 12 (T18) : première entrée sur la Route 3.
	&"route_3",
	# Jalon 12 (T25) : scène du chercheur au bas du couloir des lampes (B2F).
	&"mt_moon_b2f",
	# Jalon 12 (T28) : arrivée dans le sas de la Route 4.
	&"route_4",
	# Jalon 14 (T17) : l'entrée de la maison de Léo.
	&"bill_house",
	# Jalon 15 (T14) : reculs du garde de Safrania (Route 6), arrivée à Carmin.
	&"route_6", &"vermilion_city",
	# Jalon 15 (T13) : arrivée sur la Route 5, recul du garde du poste nord.
	&"route_5", &"route_5_gate",
	# Jalon 16 (T12) : les objets du S.S. Anne (cartes à fouler ; scènes lancées par dialogue).
	&"ss_anne_main_deck", &"ss_anne_lower_deck", &"ss_anne_restaurant", &"ss_anne_outer_deck",
	&"ss_anne_cabin_a", &"ss_anne_cabin_b", &"ss_anne_cabin_c",
	# Jalon 16 (T13) : la vue du rival n° 4 dans le couloir du capitaine.
	&"ss_anne_captain_corridor",
	# Jalon 16 (T15) : `ss_anne_main_deck` (passerelle, départ) est déjà dans la liste (T12).
	# Jalon 18 (T18, T24) : déclencheurs silencieux des objectifs (Route 9, Route 10, Lavanville).
	&"route_9", &"route_10", &"lavender_town",
	# Jalon 19 (T14) : le déclencheur du SPECTRE du 6F.
	&"pokemon_tower_6f",
	# Jalon 19 (T16) : le premier pas du rez-de-chaussée de la Tour.
	&"pokemon_tower_1f",
	# Jalon 19 (T17) : les deux cases du rival n° 5.
	&"pokemon_tower_2f",
	# Jalon 19 (T18) : zone purifiée du 5F et objets des 3F à 6F (PNJ « objet » de leurs fichiers).
	&"pokemon_tower_3f", &"pokemon_tower_4f", &"pokemon_tower_5f",
	# Jalon 20 (T16) : COUPER sur les arbustes de l'Arène d'Erika (examens posés dans les scènes).
	&"celadon_city", &"celadon_gym",
	# Jalon 20 (T17) : arrivées silencieuses (Route 8 est, Céladopole est).
	&"route_8",
	# Jalon 26 (T11, T12) : le rival n° 6 (7F) et Giovanni (11F) de la Sylphe SARL.
	&"silph_co_7f", &"silph_co_11f",
	# Jalon 21 (T21) : arrivée silencieuse sur la Route 12.
	&"route_12",
	# Jalon 21 (T14, T22) : entrée de la Maison des Pokémon (remise de la Flûte), arrivée
	# silencieuse sur la Route 16.
	&"pokemon_house", &"route_16",
]
## Jalon 7 (T18) : partie qui revient au labo avec le colis (rival parti après le combat).
const PARCEL_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel",
]
## Jalon 7 (T25) : partie qui arrive sur la Route 22 après l'activation du Pokédex.
const ROUTE22_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated",
]
## Jalon 10 (T8) : partie qui arrive à Argenta (fin du J9 : poison annoncé, Théo battu).
const OFFER_WATER: StringName = &"saffron_gate_offer_water"
const OFFER_SODA: StringName = &"saffron_gate_offer_soda"
const OFFER_LEMONADE: StringName = &"saffron_gate_offer_lemonade"
const PEWTER_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated", &"poison_unlocked", &"beaten_forest_scout_theo",
]
## Jalon 12 (T18) : partie qui arrive sur la Route 3 (Badge Roche, garde décalé).
const ROUTE3_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated", &"poison_unlocked", &"beaten_forest_scout_theo",
	&"pewter_arrived", &"brock_met", &"badge_boulder", &"route_3_guard_cleared",
]
## Jalon 12 (T25) : partie badgée au Mont Sélénite, le gardien R3 battu (scène du chercheur),
## puis le chercheur battu (choix du fossile).
const R3_FLAGS: Array[StringName] = [
	&"oak_met", &"oak_lab_reunion", &"starter_offered", &"starter_chosen", &"rival_challenged",
	&"rival_lab_won", &"rival_battle_done", &"rival_left_lab", &"viridian_arrived",
	&"got_oak_parcel", &"pokedex_activated", &"poison_unlocked", &"beaten_forest_scout_theo",
	&"pewter_arrived", &"brock_met", &"badge_boulder", &"route_3_guard_cleared",
	&"route_3_entered", &"beaten_mt_moon_rocket_3",
]
## Paires `taken_*` posées au labo (starter du joueur, puis celui du rival) → Pokémon du rival
## présent sur la Route 22 (data/npcs/route_22.json).
const RIVAL_PAIRS: Dictionary = {
	&"rival_charmander": [&"taken_bulbasaur", &"taken_charmander"],
	&"rival_squirtle": [&"taken_charmander", &"taken_squirtle"],
	&"rival_bulbasaur": [&"taken_squirtle", &"taken_bulbasaur"],
}
## Scène → drapeaux qui choisissent chaque variante, dans l'ordre (§3.6).
const VARIANT_FLAGS: Dictionary = {
	&"route1_grass": [[], [&"oak_met"]],
	&"route_1_potion": [[]],
	&"oak_lab_exit": [[&"oak_met", &"oak_lab_reunion", &"starter_offered"]],
	&"starter_chosen": [[&"oak_met", &"oak_lab_reunion", &"starter_offered"]],
	&"viridian_arrival": [[&"rival_battle_done"]],
	&"mart_parcel": [[&"rival_battle_done", &"viridian_arrived"]],
	&"oak_parcel": [PARCEL_FLAGS],
	&"rival_route22": [ROUTE22_FLAGS],
	&"route_2_item_1": [ROUTE22_FLAGS],
	&"route_2_item_2": [ROUTE22_FLAGS],
	&"route_2_item_3": [ROUTE22_FLAGS],
	&"route_2_item_4": [ROUTE22_FLAGS],
	# Jalon 9 (T18) : les 6 objets de la Forêt de Jade.
	&"viridian_forest_item_1": [ROUTE22_FLAGS],
	&"viridian_forest_item_2": [ROUTE22_FLAGS],
	&"viridian_forest_item_3": [ROUTE22_FLAGS],
	&"viridian_forest_item_4": [ROUTE22_FLAGS],
	&"viridian_forest_item_5": [ROUTE22_FLAGS],
	&"viridian_forest_item_6": [ROUTE22_FLAGS],
	# Jalon 10 (T8) : Route 2 nord et Argenta.
	&"route_2_north_item_1": [PEWTER_FLAGS],
	# Jalon 14 (T16) : les 3 objets visibles et l'objet caché de la Route 25.
	&"route_25_item_1": [PEWTER_FLAGS], &"route_25_item_2": [PEWTER_FLAGS],
	&"route_25_item_3": [PEWTER_FLAGS], &"route_25_hidden_1": [PEWTER_FLAGS],
	# Jalon 15 (T19) : la Guérison cachée du souterrain.
	&"underground_hidden_1": [PEWTER_FLAGS],
	# Jalon 15 (T13) : arrivée, Super Potion, Antidote caché, garde du poste nord.
	&"route_5_arrival": [PEWTER_FLAGS], &"route_5_item_1": [PEWTER_FLAGS],
	# Jalon 16 (T11) : la barrière de l'Arène de Carmin (une variante, puzzle pas encore résolu).
	&"vermilion_gym_barrier_open": [PEWTER_FLAGS],
	# Jalon 16 (T14) : Major Bob (première rencontre et reprise), rattrapage de la CT24.
	&"vermilion_gym_surge": [PEWTER_FLAGS], &"vermilion_gym_surge_tm_late": [PEWTER_FLAGS],
	# Jalon 16 (T13) : le rival n° 4 (une variante, avant sa victoire) et le capitaine.
	&"ss_anne_rival": [PEWTER_FLAGS], &"ss_anne_captain": [PEWTER_FLAGS + [&"rival_ss_anne_won"]],
	&"route_5_hidden_1": [PEWTER_FLAGS], &"route_5_gate_rule": [PEWTER_FLAGS],
	&"pewter_arrival": [PEWTER_FLAGS],
	# Jalon 13 (T17) : arrivée à Azuria, Poké Ball de la Route 4, Potion de la Route 24.
	&"cerulean_arrival": [PEWTER_FLAGS],
	&"route_4_item_1": [PEWTER_FLAGS],
	&"route_24_item_1": [PEWTER_FLAGS],
	# Jalon 13 (T22) : Antidote caché de la Route 24 ; recruteur (première rencontre, reprise).
	&"route_24_antidote": [PEWTER_FLAGS],
	&"route_24_rocket": [PEWTER_FLAGS, PEWTER_FLAGS + [&"got_nugget"]],
	# Jalon 13 (T19) : rival n° 3, scène d'Ondine au pont, Ondine à l'Arène (+ rattrapage).
	&"route_24_rival": [PEWTER_FLAGS],
	&"route_24_misty": [PEWTER_FLAGS + [&"rival_cerulean_won"]],
	&"cerulean_gym_misty": [PEWTER_FLAGS + [&"rival_cerulean_won", &"misty_invited"]],
	&"cerulean_gym_misty_tm_late": [PEWTER_FLAGS + [&"rival_cerulean_won", &"misty_invited",
		&"badge_cascade"]],
	&"route_3_guard": [PEWTER_FLAGS + [&"pewter_arrived"],
		PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	&"pewter_gym_brock": [PEWTER_FLAGS + [&"pewter_arrived"]],
	# Jalon 11 (T14) : remise tardive de la CT34 (partie déjà badgée).
	&"pewter_gym_brock_tm_late": [PEWTER_FLAGS + [&"pewter_arrived", &"brock_met",
		&"badge_boulder"]],
	# Jalon 12 (T18) : Route 3 (entrée, trois objets visibles, Réveil caché).
	&"route_3_entered": [ROUTE3_FLAGS],
	&"route_3_item_1": [ROUTE3_FLAGS],
	&"route_3_item_2": [ROUTE3_FLAGS],
	&"route_3_item_3": [ROUTE3_FLAGS],
	&"route_3_hidden_1": [ROUTE3_FLAGS],
	# Jalon 12 (T28) : arrivée dans le sas de la Route 4.
	&"route_4_reached": [R3_FLAGS + [&"beaten_mt_moon_researcher", &"mt_moon_fossil_chosen"]],
	# Jalon 12 (T21) : objets du Mont Sélénite (partie badgée).
	&"mt_moon_1f_item_1": [PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	&"mt_moon_1f_hidden_1": [PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	&"mt_moon_b1f_item_2": [PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	# Jalon 12 (T25) : Pierre Lune visible (B1F), CT01 et Pierre Lune cachée (B2F), chercheur,
	# choix du fossile.
	&"mt_moon_b1f_item_1": [PEWTER_FLAGS + [&"pewter_arrived", &"brock_met", &"badge_boulder"]],
	&"mt_moon_b2f_item_1": [R3_FLAGS],
	&"mt_moon_b2f_hidden_1": [R3_FLAGS],
	&"mt_moon_researcher": [R3_FLAGS],
	&"mt_moon_fossil_dome": [R3_FLAGS + [&"beaten_mt_moon_researcher"]],
	&"mt_moon_fossil_helix": [R3_FLAGS + [&"beaten_mt_moon_researcher"]],
	# Jalon 14 (T17) : la maison de Léo (entrée : avant la rencontre, puis Léo dans la cabine).
	&"bill_house_enter": [PEWTER_FLAGS, PEWTER_FLAGS + [&"bill_met", &"bill_in_cabin"]],
	&"bill_screen": [PEWTER_FLAGS + [&"bill_met"]],
	&"bill_module": [PEWTER_FLAGS + [&"bill_met", &"bill_screen_checked"]],
	&"bill_machine": [PEWTER_FLAGS + [&"bill_met", &"bill_screen_checked", &"bill_in_cabin"]],
	# Jalon 14 (T20b) : poursuite, combat du Rocket d'Azuria, barrage sud.
	&"cerulean_rocket_chase": [PEWTER_FLAGS],
	&"cerulean_rocket_fight": [PEWTER_FLAGS + [&"cerulean_rocket_spotted"]],
	&"cerulean_south_guard": [PEWTER_FLAGS + [&"cerulean_rocket_beaten"]],
	# Jalon 15 (T14) : Route 6 (Poké Ball, Super Potion cachée, reculs du garde), arrivée à
	# Carmin-sur-Mer.
	&"route_6_item_1": [PEWTER_FLAGS], &"route_6_hidden_1": [PEWTER_FLAGS],
	&"route_6_gate_rule_w": [PEWTER_FLAGS], &"route_6_gate_rule_e": [PEWTER_FLAGS],
	&"route_6_gate_rule_s": [PEWTER_FLAGS], &"vermilion_arrival": [PEWTER_FLAGS],
	# Jalon 17 (T8) : remise de la CS05 par l'assistant (10 espèces capturées).
	&"route_2_east_give_hm05": [PEWTER_FLAGS],
	# Jalon 17 (T17) : les deux objets au sol et l'objet caché de la Route 11.
	&"route_11_item_1": [PEWTER_FLAGS], &"route_11_item_2": [PEWTER_FLAGS],
	&"route_11_hidden_1": [PEWTER_FLAGS],
	# Jalon 17 (T20) : Pierre Lune et Super Bonbon du couloir de la Route 2 est.
	&"route_2_east_item_1": [PEWTER_FLAGS], &"route_2_east_item_2": [PEWTER_FLAGS],
	# Jalon 17 (T21) : Super Potion de la clairière de FUTUR A.
	&"route_2_item_5": [PEWTER_FLAGS],
	# Jalon 17 (intégration) : Corde Sortie du renfoncement R1 de la Cave Taupiqueur.
	&"digletts_cave_item_1": [PEWTER_FLAGS],
	# Jalon 16 (T12) : six objets au sol et trois cachés du S.S. Anne.
	&"ss_anne_item_01": [PEWTER_FLAGS], &"ss_anne_item_02": [PEWTER_FLAGS],
	&"ss_anne_item_03": [PEWTER_FLAGS], &"ss_anne_item_04": [PEWTER_FLAGS],
	&"ss_anne_item_05": [PEWTER_FLAGS], &"ss_anne_item_06": [PEWTER_FLAGS],
	&"ss_anne_hidden_1": [PEWTER_FLAGS], &"ss_anne_hidden_2": [PEWTER_FLAGS],
	&"ss_anne_hidden_3": [PEWTER_FLAGS],
	# Jalon 16 (T15) : départ du S.S. Anne (après la CS01 ; avant : TXT-03), Coupe de l'arbuste.
	&"ss_anne_departure": [PEWTER_FLAGS + [&"got_hm01"], PEWTER_FLAGS],
	&"cut_tree_vermilion_gym": [PEWTER_FLAGS],
	&"ss_anne_boarding": [PEWTER_FLAGS],
	# Jalon 17 (T23) : Coupe des arbustes du couloir de la Route 2 est et de FUTUR A.
	&"cut_tree_route_2_east_bush": [PEWTER_FLAGS], &"cut_tree_route_2_futur_a": [PEWTER_FLAGS],
	# Jalon 18 (T15) : Coupe de l'arbre de la sortie est d'Azuria.
	&"cut_tree_cerulean_east": [PEWTER_FLAGS],
	# Jalon 20 (T16) : Coupe des deux arbustes de l'Arène d'Erika.
	&"cut_tree_celadon_gym_bush": [PEWTER_FLAGS], &"cut_tree_celadon_gym_inner_bush": [PEWTER_FLAGS],
	# Jalon 18 (T16) : objets et déclencheurs silencieux des objectifs (une variante chacun).
	&"route_9_entered": [PEWTER_FLAGS], &"route_9_item_1": [PEWTER_FLAGS],
	&"route_9_item_2": [PEWTER_FLAGS], &"route_9_item_3": [PEWTER_FLAGS],
	&"route_10_reached": [PEWTER_FLAGS], &"dark_cave_crossed": [PEWTER_FLAGS],
	# Jalon 21 (T12) : variante A du 6F (révélation, Scope dans le Sac : VARIANT_ITEMS) en tête.
	&"tower_6f_ghost": [PEWTER_FLAGS, PEWTER_FLAGS], &"tower_guardian": [PEWTER_FLAGS],
	&"tower_rival": [PEWTER_FLAGS],
	# Jalon 21 (T21) : Route 12 (arrivée silencieuse, CT39 du poste, réveil de Ronflex).
	&"route_12_visited": [PEWTER_FLAGS], &"route_12_gate_tm39": [PEWTER_FLAGS],
	&"snorlax_route_12_wake": [PEWTER_FLAGS],
	# Jalon 21 (T13, T14, T22) : sauvetage de Fuji, remise de la Flûte, Route 16.
	&"tower_7f_fuji_rescue": [PEWTER_FLAGS],
	&"pokemon_house_flute": [PEWTER_FLAGS + [&"fuji_rescued"]],
	&"route_16_visited": [PEWTER_FLAGS], &"snorlax_route_16_wake": [PEWTER_FLAGS],
	# Jalon 19 (T18) : zone purifiée et objets de la Tour.
	&"tower_purified_zone": [PEWTER_FLAGS], &"tower_3f_objet_1": [PEWTER_FLAGS],
	&"tower_4f_objet_1": [PEWTER_FLAGS], &"tower_4f_objet_2": [PEWTER_FLAGS],
	&"tower_5f_objet_1": [PEWTER_FLAGS], &"tower_5f_cache_1": [PEWTER_FLAGS],
	&"tower_6f_objet_1": [PEWTER_FLAGS],
	&"route_10_item_1": [PEWTER_FLAGS], &"dark_cave_1f_item_1": [PEWTER_FLAGS],
	&"dark_cave_1f_item_2": [PEWTER_FLAGS], &"dark_cave_b1f_item_1": [PEWTER_FLAGS],
	&"dark_cave_b1f_hidden_1": [PEWTER_FLAGS], &"lavender_reached": [PEWTER_FLAGS],
	# Jalon 20 (T25) : boisson donnée au garde d'un poste de Safrania (une fois).
	&"saffron_gate_drink_water": [PEWTER_FLAGS], &"saffron_gate_drink_soda": [PEWTER_FLAGS],
	&"saffron_gate_drink_lemonade": [PEWTER_FLAGS],
	# Jalon 26 (T8) : suites des déclencheurs du J15 (boisson choisie par drapeau, sinon recul).
	&"route_5_gate_after": [PEWTER_FLAGS + [OFFER_WATER], PEWTER_FLAGS + [OFFER_SODA],
		PEWTER_FLAGS + [OFFER_LEMONADE], PEWTER_FLAGS],
	&"route_6_gate_after_w": [PEWTER_FLAGS + [OFFER_WATER], PEWTER_FLAGS + [OFFER_SODA],
		PEWTER_FLAGS + [OFFER_LEMONADE], PEWTER_FLAGS],
	&"route_6_gate_after_e": [PEWTER_FLAGS + [OFFER_WATER], PEWTER_FLAGS + [OFFER_SODA],
		PEWTER_FLAGS + [OFFER_LEMONADE], PEWTER_FLAGS],
	&"route_6_gate_after_s": [PEWTER_FLAGS + [OFFER_WATER], PEWTER_FLAGS + [OFFER_SODA],
		PEWTER_FLAGS + [OFFER_LEMONADE], PEWTER_FLAGS],
	# Jalon 20 (T12) : don d'Évoli (une fois).
	&"celadon_eevee_gift": [PEWTER_FLAGS],
	# Jalon 20 (T17) : arrivées, objet et caches, Erika (scène et rattrapage de la CT21), fillette.
	&"route_8_reached": [PEWTER_FLAGS], &"celadon_reached": [PEWTER_FLAGS],
	&"route_8_item_1": [PEWTER_FLAGS], &"route_8_hidden_1": [PEWTER_FLAGS],
	&"souterrain_hidden_1": [PEWTER_FLAGS], &"souterrain_hidden_2": [PEWTER_FLAGS],
	&"celadon_hidden_1": [PEWTER_FLAGS],
	&"celadon_gym_erika": [PEWTER_FLAGS], &"celadon_gym_erika_tm_late": [PEWTER_FLAGS],
	&"celadon_roof_trade": [PEWTER_FLAGS],
	# Jalon 20 (T21) : interrupteur (une fois), chute et prise de la Clé, Giovanni, Scope, objets.
	&"game_corner_switch": [PEWTER_FLAGS], &"rocket_hideout_key_drop": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_lift_key": [PEWTER_FLAGS + [&"rocket_dropped_lift_key"]],
	&"giovanni_hideout": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_silph_scope": [PEWTER_FLAGS + [&"giovanni_hideout_won"]],
	&"rocket_hideout_b1f_item_1": [PEWTER_FLAGS],
	&"rocket_hideout_b1f_item_2": [PEWTER_FLAGS],
	&"rocket_hideout_b1f_hidden_1": [PEWTER_FLAGS],
	&"rocket_hideout_b2f_item_1": [PEWTER_FLAGS],
	&"rocket_hideout_b2f_item_2": [PEWTER_FLAGS],
	&"rocket_hideout_b2f_item_3": [PEWTER_FLAGS],
	&"rocket_hideout_b2f_item_4": [PEWTER_FLAGS],
	&"rocket_hideout_b3f_item_1": [PEWTER_FLAGS],
	&"rocket_hideout_b3f_item_2": [PEWTER_FLAGS],
	&"rocket_hideout_b3f_hidden_1": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_item_1": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_item_2": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_item_3": [PEWTER_FLAGS],
	&"rocket_hideout_b4f_hidden_1": [PEWTER_FLAGS],
	# Jalon 26 (T9) : objets au sol et cachés de Safrania et de la Sylphe (une fois chacun).
	&"silph_co_3f_item_4": [PEWTER_FLAGS],
	&"silph_co_4f_item_5": [PEWTER_FLAGS],
	&"silph_co_4f_item_6": [PEWTER_FLAGS],
	&"silph_co_4f_item_7": [PEWTER_FLAGS],
	&"silph_co_5f_card_key": [PEWTER_FLAGS],
	&"silph_co_5f_hidden_1": [PEWTER_FLAGS],
	&"silph_co_5f_item_6": [PEWTER_FLAGS],
	&"silph_co_5f_item_7": [PEWTER_FLAGS],
	&"silph_co_6f_item_9": [PEWTER_FLAGS],
	&"silph_co_6f_item_10": [PEWTER_FLAGS],
	&"silph_co_9f_hidden_1": [PEWTER_FLAGS],
	&"silph_co_10f_item_4": [PEWTER_FLAGS],
	&"silph_co_10f_item_5": [PEWTER_FLAGS],
	&"silph_co_10f_item_6": [PEWTER_FLAGS],
	&"saffron_copycat_hidden_1": [PEWTER_FLAGS],
	# Jalon 26 (T11, T12) : rival n° 6, Lokhlass, Giovanni, Master Ball, objets du 7F.
	&"rival_silph": [[]],
	&"silph_co_lapras_gift": [[&"rival_silph_won"]],
	&"silph_co_giovanni": [[&"rival_silph_won"]],
	&"silph_co_master_ball": [[&"silph_giovanni_defeated"]],
	&"silph_co_7f_item_10": [[]],
	&"silph_co_7f_item_11": [[]],
	# Jalon 27 (T8 à T10) : Morgane (scène et rattrapage de la CT46), maître du Dojo, choix.
	&"saffron_gym_sabrina": [PEWTER_FLAGS], &"saffron_gym_sabrina_tm_late": [PEWTER_FLAGS],
	&"fighting_dojo_master": [PEWTER_FLAGS],
	&"fighting_dojo_take_hitmonlee": [PEWTER_FLAGS], &"fighting_dojo_take_hitmonchan": [PEWTER_FLAGS],
}
## Scènes jouées par le code (pas de déclencheur) → carte où elles sont jouées.
## Jalon 7 (T18) : la scène du colis est lancée par la variante « cutscene » du dialogue de Chen.
## Jalon 8 : les objets visibles de la Route 2, par le dialogue de leur PNJ « objet ».
const CODE_PLAYED: Dictionary[StringName, StringName] = {
	# Jalon 20 (T25) : choix OUI du garde d'un poste de Safrania (« confirm_cutscene »).
	&"saffron_gate_drink_water": &"route_8_gate", &"saffron_gate_drink_soda": &"route_8_gate",
	&"saffron_gate_drink_lemonade": &"route_8_gate",
	# Jalon 26 (T8) : suites des déclencheurs du J15 (`next`) et choix OUI du garde (PARLER).
	&"route_5_gate_after": &"route_5_gate", &"route_6_gate_after_w": &"route_6",
	&"route_6_gate_after_e": &"route_6", &"route_6_gate_after_s": &"route_6",
	# Jalon 20 (T12) : choix OUI de la Poké Ball d'Évoli (PNJ `eevee_ball` de la maison du toit).
	&"celadon_eevee_gift": &"celadon_mansion_roof_house",
	# Jalon 20 (T17) : objets et caches (PNJ « objet » et points d'examen), Erika (son dialogue),
	# échange de la fillette (« confirm_cutscene »).
	&"route_8_item_1": &"route_8", &"route_8_hidden_1": &"route_8",
	&"souterrain_hidden_1": &"underground_path_7_8", &"souterrain_hidden_2": &"underground_path_7_8",
	&"celadon_hidden_1": &"celadon_city", &"celadon_gym_erika": &"celadon_gym",
	&"celadon_gym_erika_tm_late": &"celadon_gym", &"celadon_roof_trade": &"celadon_dept_roof",
	# Jalon 20 (T21) : choix OUI de l'affiche, dialogues du sbire à la Clé, de Giovanni et des
	# Poké Balls, objets et caches du repaire.
	&"game_corner_switch": &"celadon_game_corner", &"rocket_hideout_key_drop": &"rocket_hideout_b4f",
	&"rocket_hideout_b4f_lift_key": &"rocket_hideout_b4f", &"giovanni_hideout": &"rocket_hideout_b4f",
	&"rocket_hideout_b4f_silph_scope": &"rocket_hideout_b4f",
	&"rocket_hideout_b1f_item_1": &"rocket_hideout_b1f",
	&"rocket_hideout_b1f_item_2": &"rocket_hideout_b1f",
	&"rocket_hideout_b1f_hidden_1": &"rocket_hideout_b1f",
	&"rocket_hideout_b2f_item_1": &"rocket_hideout_b2f",
	&"rocket_hideout_b2f_item_2": &"rocket_hideout_b2f",
	&"rocket_hideout_b2f_item_3": &"rocket_hideout_b2f",
	&"rocket_hideout_b2f_item_4": &"rocket_hideout_b2f",
	&"rocket_hideout_b3f_item_1": &"rocket_hideout_b3f",
	&"rocket_hideout_b3f_item_2": &"rocket_hideout_b3f",
	&"rocket_hideout_b3f_hidden_1": &"rocket_hideout_b3f",
	&"rocket_hideout_b4f_item_1": &"rocket_hideout_b4f",
	&"rocket_hideout_b4f_item_2": &"rocket_hideout_b4f",
	&"rocket_hideout_b4f_item_3": &"rocket_hideout_b4f",
	&"rocket_hideout_b4f_hidden_1": &"rocket_hideout_b4f",
	&"starter_chosen": &"oak_lab", &"oak_parcel": &"oak_lab",
	&"route_2_item_1": &"route_2", &"route_2_item_2": &"route_2",
	# Jalon 9 (T18) : objets visibles de la Forêt de Jade (PNJ « objet » de son fichier).
	&"viridian_forest_item_1": &"viridian_forest", &"viridian_forest_item_2": &"viridian_forest",
	&"viridian_forest_item_5": &"viridian_forest",
	# Jalon 10 (T8) : Potion de la Route 2 nord (PNJ « objet »), Pierre (son dialogue).
	&"route_2_north_item_1": &"route_2_north", &"pewter_gym_brock": &"pewter_gym",
	# Jalon 14 (T16) : objets de la Route 25 (PNJ « objet » et point d'examen du coquillage).
	&"route_25_item_1": &"route_25", &"route_25_item_2": &"route_25",
	&"route_25_item_3": &"route_25", &"route_25_hidden_1": &"route_25",
	# Jalon 15 (T19) : Guérison cachée (point d'examen de la pierre descellée).
	&"underground_hidden_1": &"underground_path",
	# Jalon 15 (T14) : Poké Ball (PNJ « objet ») et Super Potion cachée (point d'examen des
	# joncs) de la Route 6.
	&"route_6_item_1": &"route_6", &"route_6_hidden_1": &"route_6",
	# Jalon 15 (T13) : Super Potion (PNJ « objet ») et Antidote caché (point d'examen du tronc).
	&"route_5_item_1": &"route_5", &"route_5_hidden_1": &"route_5",
	# Jalon 16 (T11) : barrière de l'Arène de Carmin, jouée par Boot quand le puzzle est résolu.
	&"vermilion_gym_barrier_open": &"vermilion_gym",
	# Jalon 16 (T14) : Major Bob, par son dialogue (scène de l'Arène et rattrapage de la CT24).
	&"vermilion_gym_surge": &"vermilion_gym", &"vermilion_gym_surge_tm_late": &"vermilion_gym",
	# Jalon 16 (T12) : objets du S.S. Anne (PNJ « objet » et points d'examen de l'indice).
	&"ss_anne_item_01": &"ss_anne_main_deck", &"ss_anne_item_02": &"ss_anne_cabin_a",
	&"ss_anne_item_03": &"ss_anne_cabin_c", &"ss_anne_item_04": &"ss_anne_lower_deck",
	&"ss_anne_item_05": &"ss_anne_restaurant", &"ss_anne_item_06": &"ss_anne_outer_deck",
	&"ss_anne_hidden_1": &"ss_anne_cabin_b", &"ss_anne_hidden_2": &"ss_anne_lower_deck",
	&"ss_anne_hidden_3": &"ss_anne_restaurant",
	# Jalon 16 (T13) : le capitaine, par son dialogue.
	&"ss_anne_captain": &"ss_anne_captain_room",
	# Jalon 16 (T15) : COUPER (« confirm_cutscene » de l'examen de l'arbuste).
	&"cut_tree_vermilion_gym": &"vermilion_city",
	# Jalon 17 (T23) : COUPER sur les arbustes du couloir de la Route 2 est et de FUTUR A.
	&"cut_tree_route_2_east_bush": &"route_2_east", &"cut_tree_route_2_futur_a": &"route_2",
	# Jalon 18 (T15) : COUPER sur l'arbre de la sortie est d'Azuria.
	&"cut_tree_cerulean_east": &"cerulean_city",
	# Jalon 20 (T16) : COUPER sur les arbustes de l'Arène d'Erika.
	&"cut_tree_celadon_gym_bush": &"celadon_city", &"cut_tree_celadon_gym_inner_bush": &"celadon_gym",
	# Jalon 16 : embarquement, par le dialogue du marin (TXT-01).
	&"ss_anne_boarding": &"vermilion_city",
	# Jalon 11 (T14) : remise tardive de la CT34 (dialogue de Pierre).
	&"pewter_gym_brock_tm_late": &"pewter_gym",
	# Jalon 13 (T17) : objets visibles des Routes 4 et 24 (PNJ « objet »).
	&"route_4_item_1": &"route_4", &"route_24_item_1": &"route_24",
	# Jalon 13 (T22) : Antidote caché (point d'examen de la souche).
	&"route_24_antidote": &"route_24",
	# Jalon 13 (T19) : Ondine, par son dialogue (scène de l'Arène et rattrapage de la CT11).
	&"cerulean_gym_misty": &"cerulean_gym", &"cerulean_gym_misty_tm_late": &"cerulean_gym",
	# Jalon 12 (T18) : objets visibles de la Route 3 (PNJ « objet ») et Réveil caché (point
	# d'examen de l'indice, `unless_flags`).
	&"route_3_item_1": &"route_3", &"route_3_item_2": &"route_3", &"route_3_item_3": &"route_3",
	&"route_3_hidden_1": &"route_3",
	# Jalon 12 (T21) : Corde et Potion (PNJ « objet »), Réveil caché (point d'examen de l'indice).
	&"mt_moon_1f_item_1": &"mt_moon_1f", &"mt_moon_1f_hidden_1": &"mt_moon_1f",
	&"mt_moon_b1f_item_2": &"mt_moon_b1f",
	# Jalon 12 (T25) : Pierre Lune et CT01 (PNJ « objet »), Pierre Lune cachée (point d'examen),
	# choix du fossile (confirmation « confirm_cutscene » du dialogue d'un fossile).
	&"mt_moon_b1f_item_1": &"mt_moon_b1f", &"mt_moon_b2f_item_1": &"mt_moon_b2f",
	&"mt_moon_b2f_hidden_1": &"mt_moon_b2f",
	&"mt_moon_fossil_dome": &"mt_moon_b2f", &"mt_moon_fossil_helix": &"mt_moon_b2f",
	# Jalon 14 (T17) : les trois objets de Léo (dialogue de l'écran, du module, de la console).
	&"bill_screen": &"bill_house", &"bill_module": &"bill_house", &"bill_machine": &"bill_house",
	# Jalon 17 (T8) : remise de la CS05 (variante « cutscene » du dialogue de l'assistant), dans
	# le poste de la Route 2 est (carte du T19 ; la scène n'a aucun acteur).
	&"route_2_east_give_hm05": &"route_2_east_gate",
	# Jalon 17 (T17) : objets de la Route 11 (PNJ « objet » et point d'examen du caillou).
	&"route_11_item_1": &"route_11", &"route_11_item_2": &"route_11",
	&"route_11_hidden_1": &"route_11",
	# Jalon 17 (T20) : objets visibles du couloir (PNJ « objet » de son fichier).
	&"route_2_east_item_1": &"route_2_east", &"route_2_east_item_2": &"route_2_east",
	# Jalon 17 (T21) : Super Potion de la clairière de FUTUR A (PNJ « objet » de la Route 2).
	&"route_2_item_5": &"route_2",
	# Jalon 17 (intégration) : Corde Sortie de la Cave (PNJ « objet » de son fichier).
	&"digletts_cave_item_1": &"digletts_cave",
	# Jalon 18 (T16) : objets visibles (PNJ « objet ») et Super Potion cachée (point d'examen des
	# racines, posé au T20).
	&"route_9_item_1": &"route_9", &"route_9_item_2": &"route_9", &"route_9_item_3": &"route_9",
	&"route_10_item_1": &"route_10", &"dark_cave_1f_item_1": &"dark_cave_1f",
	&"dark_cave_1f_item_2": &"dark_cave_1f", &"dark_cave_b1f_item_1": &"dark_cave_b1f",
	&"dark_cave_b1f_hidden_1": &"dark_cave_b1f",
	# Jalon 19 (T18) : objets de la Tour (PNJ « objet » ; l'objet caché : point d'examen du 5F).
	&"tower_3f_objet_1": &"pokemon_tower_3f", &"tower_4f_objet_1": &"pokemon_tower_4f",
	&"tower_4f_objet_2": &"pokemon_tower_4f", &"tower_5f_objet_1": &"pokemon_tower_5f",
	&"tower_5f_cache_1": &"pokemon_tower_5f", &"tower_6f_objet_1": &"pokemon_tower_6f",
	# Jalon 26 (T9) : objets au sol (PNJ « objet ») et caches (points d'examen).
	&"silph_co_3f_item_4": &"silph_co_3f",
	&"silph_co_4f_item_5": &"silph_co_4f",
	&"silph_co_4f_item_6": &"silph_co_4f",
	&"silph_co_4f_item_7": &"silph_co_4f",
	&"silph_co_5f_card_key": &"silph_co_5f",
	&"silph_co_5f_hidden_1": &"silph_co_5f",
	&"silph_co_5f_item_6": &"silph_co_5f",
	&"silph_co_5f_item_7": &"silph_co_5f",
	&"silph_co_6f_item_9": &"silph_co_6f",
	&"silph_co_6f_item_10": &"silph_co_6f",
	&"silph_co_9f_hidden_1": &"silph_co_9f",
	&"silph_co_10f_item_4": &"silph_co_10f",
	&"silph_co_10f_item_5": &"silph_co_10f",
	&"silph_co_10f_item_6": &"silph_co_10f",
	&"saffron_copycat_hidden_1": &"saffron_copycat_house_2f",
	# Jalon 26 (T11, T12) : dialogues de l'employé du Lokhlass, du président et des objets du 7F.
	&"silph_co_lapras_gift": &"silph_co_7f", &"silph_co_master_ball": &"silph_co_11f",
	&"silph_co_7f_item_10": &"silph_co_7f", &"silph_co_7f_item_11": &"silph_co_7f",
	# Jalon 27 (T8 à T10) : dialogues de Morgane et du maître, choix OUI des deux Poké Balls.
	&"saffron_gym_sabrina": &"saffron_gym", &"saffron_gym_sabrina_tm_late": &"saffron_gym",
	&"fighting_dojo_master": &"fighting_dojo", &"fighting_dojo_take_hitmonlee": &"fighting_dojo",
	&"fighting_dojo_take_hitmonchan": &"fighting_dojo",
	# Jalon 21 (T21) : CT39 (dialogue de la jeune femme du 2F) et réveil de Ronflex (choix OUI).
	&"route_12_gate_tm39": &"route_12_gate_2f", &"snorlax_route_12_wake": &"route_12",
	# Jalon 21 (T13, T22) : sauvetage de Fuji (dialogue de Fuji au 7F ; sa suite `next` est
	# `pokemon_house_flute`, aussi lancée par le déclencheur d'entrée de la maison) et réveil du
	# Ronflex 16 (« flute_cutscene » et choix OUI).
	&"tower_7f_fuji_rescue": &"pokemon_tower_7f", &"snorlax_route_16_wake": &"route_16",
}
## Jalon 21 (T10, T12) : objets du Sac qui choisissent chaque variante (« if_items » /
## « unless_items »), ligne par ligne comme VARIANT_FLAGS ; absent : Sac vide. La variante A du
## 6F (révélation) demande le Scope Sylphe ; la variante B (SPECTRE du J19) s'applique sans.
const VARIANT_ITEMS: Dictionary = {
	&"tower_6f_ghost": [[&"silph_scope"], []],
}
## Scènes à déclencheur dont la carte n'est pas encore construite → leur carte (simulées sur les
## PNJ de son fichier). Vidée au T19 du jalon 9 (la forêt existe), puis au T11 du jalon 10 (les
## deux scènes d'Argenta ont leurs déclencheurs sur la carte).
const AWAITING_MAP: Dictionary[StringName, StringName] = {}
## Jalon 20 (T21) : interrupteur du Casino, Clé, Giovanni, Scope, objets et caches du repaire.
const J20_T21_IDS: Array[StringName] = [
	&"game_corner_switch", &"rocket_hideout_key_drop", &"rocket_hideout_b4f_lift_key",
	&"giovanni_hideout", &"rocket_hideout_b4f_silph_scope",
	&"rocket_hideout_b1f_item_1", &"rocket_hideout_b1f_item_2", &"rocket_hideout_b1f_hidden_1",
	&"rocket_hideout_b2f_item_1", &"rocket_hideout_b2f_item_2", &"rocket_hideout_b2f_item_3",
	&"rocket_hideout_b2f_item_4", &"rocket_hideout_b3f_item_1", &"rocket_hideout_b3f_item_2",
	&"rocket_hideout_b3f_hidden_1", &"rocket_hideout_b4f_item_1", &"rocket_hideout_b4f_item_2",
	&"rocket_hideout_b4f_item_3", &"rocket_hideout_b4f_hidden_1",
]
## Jalon 26 (T9) : objets au sol et cachés de Safrania et de la Sylphe (`saffron_life.json`,
## `silph_co_life.json`) : scène → [carte, objet donné]. Les objets absents du dépôt sont remplacés
## [D] (fallback des grilles) : Corde/Hyper Potion → Super Potion, etc.
const J26_T9_ITEMS: Dictionary[StringName, Array] = {
	&"silph_co_3f_item_4": [&"silph_co_3f", &"super_potion"],
	&"silph_co_4f_item_5": [&"silph_co_4f", &"super_potion"],
	&"silph_co_4f_item_6": [&"silph_co_4f", &"revive"],
	&"silph_co_4f_item_7": [&"silph_co_4f", &"escape_rope"],
	&"silph_co_5f_card_key": [&"silph_co_5f", &"card_key"],
	&"silph_co_5f_hidden_1": [&"silph_co_5f", &"revive"],
	&"silph_co_5f_item_6": [&"silph_co_5f", &"nugget"],
	&"silph_co_5f_item_7": [&"silph_co_5f", &"rare_candy"],
	&"silph_co_6f_item_9": [&"silph_co_6f", &"rare_candy"],
	&"silph_co_6f_item_10": [&"silph_co_6f", &"x_accuracy"],
	&"silph_co_9f_hidden_1": [&"silph_co_9f", &"super_potion"],
	&"silph_co_10f_item_4": [&"silph_co_10f", &"nugget"],
	&"silph_co_10f_item_5": [&"silph_co_10f", &"rare_candy"],
	&"silph_co_10f_item_6": [&"silph_co_10f", &"rare_candy"],
	&"saffron_copycat_hidden_1": [&"saffron_copycat_house_2f", &"nugget"],
}
## Jalon 18 (T16) : scènes de ses fichiers (objets, objectifs).
const J18_IDS: Array[StringName] = [
	&"dark_cave_1f_item_1", &"dark_cave_1f_item_2", &"dark_cave_b1f_hidden_1",
	&"dark_cave_b1f_item_1", &"dark_cave_crossed", &"lavender_reached", &"route_10_item_1",
	&"route_10_reached", &"route_9_entered", &"route_9_item_1", &"route_9_item_2",
	&"route_9_item_3",
]
## Jalon 18 (T16) : scènes en données dont le déclencheur est posé par la vie de la carte (T18
## Route 9 / 10, T24 Lavanville ; jalon-18.md §4.13) → leur carte. À retirer en posant le
## déclencheur (la carte rejoint alors [constant MAPS]).
## T18 : `route_9_entered` et `route_10_reached` sont posés (Route 9, Route 10 nord).
const AWAITING_TRIGGER: Dictionary[StringName, StringName] = {
}

var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
var _offer: StarterOffer
var _pokemon: PokemonData
var _trainers: TrainerLibrary
var _items: ItemLibrary
var _badges: BadgeLibrary
## Scène → cartes de ses déclencheurs.
var _triggered_on: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_badges = BadgeLibrary.new()
	_badges.load_file()
	for map_id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Triggers").get_children():
			var id := (point as EventTriggerPoint).cutscene_id
			if not _triggered_on.has(id):
				_triggered_on[id] = []
			(_triggered_on[id] as Array).append(map_id)
		map.free()


func _all_steps() -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	for id: StringName in _real_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			steps.append_array(variant.steps)
	return steps


func test_library_loads_without_error() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "data/cutscenes/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(_without_qa(library.get_ids()), _sorted([&"bill_house_enter", &"bill_machine", &"bill_module",
		&"bill_screen", &"cerulean_arrival", &"cerulean_gym_misty",
		&"cerulean_rocket_chase", &"cerulean_rocket_fight", &"cerulean_south_guard",
		&"cerulean_gym_misty_tm_late", &"mart_parcel", &"mt_moon_1f_hidden_1", &"mt_moon_1f_item_1",
		&"mt_moon_b1f_item_1", &"mt_moon_b1f_item_2", &"mt_moon_b2f_hidden_1",
		&"mt_moon_b2f_item_1", &"mt_moon_fossil_dome", &"mt_moon_fossil_helix",
		&"mt_moon_researcher", &"oak_lab_exit", &"oak_parcel", &"pewter_arrival",
		&"pewter_gym_brock", &"pewter_gym_brock_tm_late", &"rival_route22", &"route1_grass",
		&"route_1_potion", &"route_24_antidote", &"route_24_item_1", &"route_24_misty",
		&"route_24_rival", &"route_24_rocket", &"route_25_hidden_1", &"route_25_item_1",
		&"route_25_item_2", &"route_25_item_3",
		&"route_6_gate_rule_e", &"route_6_gate_rule_s", &"route_6_gate_rule_w",
		# Jalon 26 (T8) : suites des déclencheurs du J15.
		&"route_5_gate_after", &"route_6_gate_after_e", &"route_6_gate_after_s",
		&"route_6_gate_after_w",
		&"route_6_hidden_1", &"route_6_item_1", &"vermilion_arrival",
		&"vermilion_gym_barrier_open", &"vermilion_gym_surge", &"vermilion_gym_surge_tm_late",
		# Jalon 16 (T15) : départ du S.S. Anne, Coupe de l'arbuste de l'Arène.
		&"ss_anne_departure", &"cut_tree_vermilion_gym", &"ss_anne_boarding",
		&"route_2_item_1", &"route_2_item_2", &"route_2_item_3", &"route_2_item_4",
		&"route_2_north_item_1", &"route_3_entered", &"route_3_guard", &"route_3_hidden_1",
		&"route_3_item_1", &"route_3_item_2", &"route_3_item_3", &"route_4_item_1",
		&"route_4_reached", &"route_5_arrival", &"route_5_gate_rule", &"route_5_hidden_1",
		&"route_5_item_1", &"ss_anne_captain", &"ss_anne_rival", &"starter_chosen",
		&"underground_hidden_1",
		&"viridian_arrival", &"viridian_forest_item_1", &"viridian_forest_item_2",
		&"viridian_forest_item_3", &"viridian_forest_item_4", &"viridian_forest_item_5",
		&"viridian_forest_item_6", &"ss_anne_hidden_1", &"ss_anne_hidden_2", &"ss_anne_hidden_3",
		&"ss_anne_item_01", &"ss_anne_item_02", &"ss_anne_item_03", &"ss_anne_item_04",
		&"ss_anne_item_05", &"ss_anne_item_06",
		# Jalon 17 (T8) : remise de la CS05 ; (T17) objets de la Route 11 ; (T20, T21) objets du
		# couloir et Super Potion de FUTUR A.
		&"route_2_east_give_hm05", &"route_11_item_1", &"route_11_item_2",
		&"route_11_hidden_1", &"route_2_east_item_1", &"route_2_east_item_2",
		&"route_2_item_5", &"digletts_cave_item_1",
		# Jalon 17 (T23) : Coupe des deux arbustes.
		&"cut_tree_route_2_east_bush", &"cut_tree_route_2_futur_a",
		# Jalon 18 (T15) : l'arbre de la sortie est d'Azuria.
		&"cut_tree_cerulean_east", &"cut_tree_celadon_gym_bush",
		&"cut_tree_celadon_gym_inner_bush", &"tower_6f_ghost", &"tower_guardian",
		&"tower_rival",
		# Jalon 19 (T18) : zone purifiée, objets de la Tour (cinq visibles, un caché).
		&"tower_purified_zone", &"tower_3f_objet_1", &"tower_4f_objet_1", &"tower_4f_objet_2",
		&"tower_5f_objet_1", &"tower_5f_cache_1", &"tower_6f_objet_1",
		&"saffron_gate_drink_water", &"saffron_gate_drink_soda", &"saffron_gate_drink_lemonade",
		# Jalon 20 (T12) : don d'Évoli.
		&"celadon_eevee_gift",
		# Jalon 20 (T17) : arrivées, objet et caches, Erika, échange de la fillette.
		&"route_8_reached", &"celadon_reached", &"route_8_item_1", &"route_8_hidden_1",
		&"souterrain_hidden_1", &"souterrain_hidden_2", &"celadon_hidden_1",
		&"celadon_gym_erika", &"celadon_gym_erika_tm_late", &"celadon_roof_trade",
		# Jalon 21 (T21) : Route 12.
		&"route_12_visited", &"route_12_gate_tm39", &"snorlax_route_12_wake",
		# Jalon 21 (T13, T14, T22) : 7F, Maison des Pokémon, Route 16.
		&"tower_7f_fuji_rescue", &"pokemon_house_flute", &"route_16_visited",
		&"snorlax_route_16_wake"]
		+ J18_IDS + J20_T21_IDS + J26_T9_ITEMS.keys()
		# Jalon 26 (T11, T12) : rival n° 6, Lokhlass, Giovanni, Master Ball, objets du 7F.
		+ [&"rival_silph", &"silph_co_lapras_gift", &"silph_co_giovanni", &"silph_co_master_ball",
		&"silph_co_7f_item_10", &"silph_co_7f_item_11"]
		# Jalon 27 (T8 à T10) : Morgane, maître du Dojo, choix Kicklee / Tygnon.
		+ [&"saffron_gym_sabrina", &"saffron_gym_sabrina_tm_late", &"fighting_dojo_master",
		&"fighting_dojo_take_hitmonlee", &"fighting_dojo_take_hitmonchan"]))


func _sorted(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(values)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


func test_route1_grass_ends_with_the_starter_offer() -> void:
	var steps := _cutscenes.get_cutscene(&"route1_grass").variants[0].steps
	assert_gt(steps.size(), 4)
	var tail := steps.slice(steps.size() - 4)
	assert_eq(tail[0].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(tail[0].flags, [&"oak_lab_reunion"] as Array[StringName], "après la réunion")
	assert_eq(tail[1].kind, CutsceneStep.Kind.WAIT)
	assert_eq(tail[1].seconds, 0.5)
	assert_eq(tail[2].kind, CutsceneStep.Kind.DIALOGUE)
	assert_eq(tail[2].dialogue_id, &"oak_starter_offer")
	assert_eq(tail[3].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(tail[3].flags, [&"starter_offered"] as Array[StringName], "dernière étape")


func test_every_trigger_targets_a_scene_and_every_scene_is_triggered() -> void:
	assert_false(_triggered_on.is_empty())
	for id: StringName in _triggered_on:
		assert_true(_cutscenes.has_cutscene(id), "scène « %s » définie" % id)
	for id: StringName in _real_ids():
		if CODE_PLAYED.has(id):
			assert_false(_triggered_on.has(id), "« %s » jouée par le code seulement" % id)
			continue
		if AWAITING_MAP.has(id) and not MapCatalog.has_map(AWAITING_MAP[id]):
			continue
		if AWAITING_TRIGGER.has(id):
			assert_false(_triggered_on.has(id), "« %s » : retirer de AWAITING_TRIGGER" % id)
			continue
		assert_true(_triggered_on.has(id), "scène « %s » visée par un déclencheur" % id)
	assert_eq(_triggered_on.get(&"route1_grass"), [&"pallet_town"])
	assert_eq(_triggered_on.get(&"route_1_potion"), [&"route_1"])
	assert_eq(_triggered_on.get(&"oak_lab_exit"), [&"oak_lab"])
	assert_eq(_triggered_on.get(&"viridian_arrival"), [&"viridian_city"])
	assert_eq(_triggered_on.get(&"rival_route22"), [&"route_22"])
	assert_eq(_triggered_on.get(&"mart_parcel"), [&"viridian_mart"])
	assert_eq(_triggered_on.get(&"route_2_item_3"), [&"route_2"])
	assert_eq(_triggered_on.get(&"route_2_item_4"), [&"route_2"])
	assert_eq(_triggered_on.get(&"pewter_arrival"), [&"pewter_city"])
	assert_eq(_triggered_on.get(&"route_3_guard"), [&"pewter_city"])
	assert_eq(_triggered_on.get(&"route_3_entered"), [&"route_3"])
	assert_eq(_triggered_on.get(&"route_4_reached"), [&"route_4"])
	assert_eq(_triggered_on.get(&"mt_moon_researcher"), [&"mt_moon_b2f"])
	assert_eq(_offer.chosen_scene, &"starter_chosen", "scène du choix = CODE_PLAYED")
	assert_eq(CODE_PLAYED[_offer.chosen_scene], _offer.map_id)


func test_every_dialogue_step_exists() -> void:
	for id: StringName in _cutscenes.get_dialogue_ids():
		assert_true(_dialogues.has_dialogue(id), "dialogue « %s » défini" % id)


## Jalon 4B : chaque étape « battle » vise un dresseur chargé, chaque étape « give » un objet
## chargé.
func test_every_trainer_and_item_step_exists() -> void:
	var trainer_ids := _cutscenes.get_trainer_ids()
	assert_false(trainer_ids.is_empty(), "au moins le combat du rival")
	for id: StringName in trainer_ids:
		assert_true(_trainers.has_trainer(id), "dresseur « %s » chargé" % id)
	var item_ids := _cutscenes.get_item_ids()
	assert_false(item_ids.is_empty(), "au moins les Poké Balls")
	for id: StringName in item_ids:
		assert_true(_items.has_item(id), "objet « %s » chargé" % id)


## Jalon 10 (T9) : chaque Dresseur présenté par une carte en a une, chaque badge remis existe, et
## l'étape « badge » d'une scène suit le combat qui lève déjà son drapeau (« win »).
func test_every_champion_card_and_badge_step_exists() -> void:
	assert_eq(_cutscenes.get_card_trainer_ids(), [&"celadon_gym_erika", &"cerulean_gym_misty",
		&"giovanni_hideout", &"pewter_gym_brock", &"saffron_gym_sabrina", &"silph_co_giovanni",
		&"vermilion_gym_surge"]
		as Array[StringName])
	for id: StringName in _cutscenes.get_card_trainer_ids():
		var trainer := _trainers.get_trainer(id)
		assert_true(trainer != null and trainer.has_card(), "« %s » a une carte" % id)
	assert_eq(_cutscenes.get_badge_ids(), [&"boulder", &"cascade", &"marsh", &"rainbow",
		&"thunder"] as Array[StringName])
	for id: StringName in _cutscenes.get_badge_ids():
		assert_true(_badges.has_badge(id), "badge « %s » connu" % id)
	for id: StringName in _real_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			var won: Array[StringName] = []
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.BATTLE:
					won.append_array(step.win_flags)
				if step.kind == CutsceneStep.Kind.BADGE:
					var flag := _badges.flag(step.badge_id)
					assert_true(won.has(flag), "%s : « %s » levé par le combat d'abord" % [id,
						flag])
					assert_eq(step.if_flags, [flag] as Array[StringName],
						"%s : badge remis seulement après la victoire" % id)


## Jalon 5C.5 (décision de Kevin) : la Potion de la Route 1 est un objet **trouvé** dans le
## monde ; les 5 Poké Balls de Chen sont **reçues** (pas au journal des objets trouvés).
## Jalon 8 : les quatre objets de la Route 2 (dossier 11 §11) sont trouvés eux aussi.
func test_only_world_items_are_found_items() -> void:
	var found: Array[String] = []
	for id: StringName in _real_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.GIVE and step.found:
					found.append("%s:%s" % [id, step.item_id])
	var expected: Array[String] = ["celadon_hidden_1:revive", "dark_cave_1f_item_1:escape_rope", "dark_cave_1f_item_2:antidote",
		"dark_cave_b1f_hidden_1:super_potion", "dark_cave_b1f_item_1:super_potion",
		"digletts_cave_item_1:escape_rope", "mt_moon_1f_hidden_1:awakening",
		"mt_moon_1f_item_1:escape_rope", "mt_moon_b1f_item_1:moon_stone",
		"mt_moon_b1f_item_2:potion", "mt_moon_b2f_hidden_1:moon_stone", "mt_moon_b2f_item_1:tm01",
		"rocket_hideout_b1f_hidden_1:revive", "rocket_hideout_b1f_item_1:escape_rope",
		"rocket_hideout_b1f_item_2:super_potion", "rocket_hideout_b2f_item_1:moon_stone",
		"rocket_hideout_b2f_item_2:nugget", "rocket_hideout_b2f_item_3:super_potion",
		"rocket_hideout_b2f_item_4:super_potion", "rocket_hideout_b3f_hidden_1:nugget",
		"rocket_hideout_b3f_item_1:super_potion", "rocket_hideout_b3f_item_2:rare_candy",
		"rocket_hideout_b4f_hidden_1:super_potion", "rocket_hideout_b4f_item_1:super_potion",
		"rocket_hideout_b4f_item_2:revive", "rocket_hideout_b4f_item_3:super_potion",
		"rocket_hideout_b4f_lift_key:lift_key", "rocket_hideout_b4f_silph_scope:silph_scope",
		"route_10_item_1:super_potion", "route_11_hidden_1:poke_ball",
		"route_11_item_1:super_potion", "route_11_item_2:awakening", "route_1_potion:potion",
		"route_24_antidote:antidote", "route_24_item_1:potion", "route_25_hidden_1:potion",
		"route_25_item_1:tm19", "route_25_item_2:potion", "route_25_item_3:poke_ball",
		"route_2_east_item_1:moon_stone", "route_2_east_item_2:rare_candy",
		"route_2_item_1:poke_ball", "route_2_item_2:potion", "route_2_item_3:poke_ball",
		"route_2_item_4:potion", "route_2_item_5:super_potion", "route_2_north_item_1:potion",
		"route_3_hidden_1:awakening", "route_3_item_1:poke_ball", "route_3_item_2:potion",
		"route_3_item_3:paralyze_heal", "route_4_item_1:poke_ball",
		"route_5_hidden_1:antidote", "route_5_item_1:super_potion",
		"route_6_hidden_1:super_potion", "route_6_item_1:poke_ball",
		"route_8_hidden_1:revive", "route_8_item_1:super_potion",
		"route_9_item_1:super_potion", "route_9_item_2:antidote", "route_9_item_3:poke_ball",
		"silph_co_7f_item_10:rare_candy", "silph_co_7f_item_11:nugget",
		"souterrain_hidden_1:nugget", "souterrain_hidden_2:super_potion",
		"ss_anne_hidden_1:awakening", "ss_anne_hidden_2:antidote", "ss_anne_hidden_3:potion",
		"ss_anne_item_01:potion", "ss_anne_item_02:potion", "ss_anne_item_03:super_potion",
		"ss_anne_item_04:super_potion", "ss_anne_item_05:super_potion",
		"ss_anne_item_06:paralyze_heal",
		"tower_3f_objet_1:escape_rope", "tower_4f_objet_1:awakening",
		"tower_4f_objet_2:super_potion", "tower_5f_cache_1:super_potion",
		"tower_5f_objet_1:nugget", "tower_6f_objet_1:super_potion",
		"underground_hidden_1:full_restore",
		"viridian_forest_item_1:antidote", "viridian_forest_item_2:poke_ball",
		"viridian_forest_item_3:potion", "viridian_forest_item_4:antidote",
		"viridian_forest_item_5:poke_ball", "viridian_forest_item_6:potion"]
	# Jalon 26 (T9) : objets au sol et cachés de Safrania et de la Sylphe.
	for id: StringName in J26_T9_ITEMS:
		expected.append("%s:%s" % [id, J26_T9_ITEMS[id][1]])
	expected.sort()
	found.sort()
	assert_eq(found, expected)


## Jalon 8 (jalon-08.md §2.3, §2.4) : un objet visible disparaît d'abord (son PNJ, retiré au
## prochain chargement par son « unless »), puis entre au Sac, puis son drapeau ; un objet
## caché joue sa narration d'abord. Une seule fois chacun (variante unique sous « unless »).
func test_route_2_items() -> void:
	var roster := NpcRoster.load_for_map(&"route_2")
	var expected := {
		&"route_2_item_1": [&"despawn", &"route_2_ball_1", &"poke_ball", &"got_route_2_item_1"],
		&"route_2_item_2": [&"despawn", &"route_2_ball_2", &"potion", &"got_route_2_item_2"],
		&"route_2_item_3": [&"dialogue", &"route_2_item_3_found", &"poke_ball",
			&"got_route_2_item_3"],
		&"route_2_item_4": [&"dialogue", &"route_2_item_4_found", &"potion",
			&"got_route_2_item_4"],
	}
	for id: StringName in expected:
		var row: Array = expected[id]
		var cutscene := _cutscenes.get_cutscene(id)
		assert_eq(cutscene.variants.size(), 1, String(id))
		var variant := cutscene.variants[0]
		assert_eq(variant.unless_flags, [row[3]] as Array[StringName], "%s : une fois" % id)
		assert_eq(variant.steps.size(), 3, String(id))
		var first := variant.steps[0]
		assert_eq(CutsceneStep.kind_name(first.kind), row[0], String(id))
		assert_eq(first.actor if first.kind == CutsceneStep.Kind.DESPAWN
			else first.dialogue_id, row[1], String(id))
		var give := variant.steps[1]
		assert_eq(give.kind, CutsceneStep.Kind.GIVE)
		assert_eq([give.item_id, give.count, give.found], [row[2], 1, true], String(id))
		assert_eq(variant.steps[2].flags, [row[3]] as Array[StringName], String(id))
		assert_true(cutscene.pick(_flags([row[3]])) == null, "%s : rien ensuite" % id)
		if first.kind == CutsceneStep.Kind.DESPAWN:
			var spec := roster.get_spec(row[1])
			assert_not_null(spec, "%s : PNJ « objet » sur la Route 2" % row[1])
			if spec == null:
				continue
			assert_eq(spec.verb, Interaction.Kind.TAKE, "%s : PRENDRE" % row[1])
			assert_eq(spec.sprite, &"object/poke_ball_ground", "même aspect (Q-1)")
			assert_eq(spec.unless_flags, [row[3]] as Array[StringName], "retiré ensuite")
			var dialogue := _dialogues.get_dialogue(spec.dialogue)
			assert_eq(dialogue.variants.size(), 1)
			assert_eq(dialogue.variants[0].cutscene, id, "le dialogue lance la scène")
			assert_true(dialogue.variants[0].pages.is_empty(), "aucune bulle avant le toast")


func test_every_change_map_targets_an_existing_map_and_spawn() -> void:
	var count := 0
	for step: CutsceneStep in _all_steps():
		if step.kind != CutsceneStep.Kind.CHANGE_MAP:
			continue
		count += 1
		assert_true(MapCatalog.has_map(step.map_id), "carte « %s »" % step.map_id)
		if not MapCatalog.has_map(step.map_id):
			continue
		var map := (load(MapCatalog.scene_path(step.map_id)) as PackedScene).instantiate() \
				as GameMap
		assert_true(map.has_spawn(step.spawn), "%s : point « %s »" % [step.map_id, step.spawn])
		map.free()
	# Jalon 21 (T13) : + la téléportation du 7F vers la Maison des Pokémon.
	assert_eq(count, 3, "le retour au labo ; le quai de Carmin (départ du S.S. Anne, J16 T15) ; "
		+ "la Maison des Pokémon (sauvetage de Fuji, J21 T13)")


func test_every_variant_is_chosen_by_its_flags() -> void:
	for id: StringName in _real_ids():
		assert_true(VARIANT_FLAGS.has(id), "%s : drapeaux des variantes écrits" % id)
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		assert_eq(rows.size(), cutscene.variants.size())
		var items: Array = VARIANT_ITEMS.get(id, [])
		for i: int in mini(rows.size(), cutscene.variants.size()):
			assert_same(cutscene.pick(_flags(rows[i]), _bag(items[i] if i < items.size() else [])),
				cutscene.variants[i], "%s : variante %d" % [id, i + 1])


func test_static_simulation_of_every_variant() -> void:
	var checked := 0
	for id: StringName in _real_ids():
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		var maps: Array = _triggered_on.get(id, [])
		if CODE_PLAYED.has(id):
			maps = [CODE_PLAYED[id]]
		elif maps.is_empty() and AWAITING_MAP.has(id):
			maps = [AWAITING_MAP[id]]
		# Une scène avec un combat est jouée « à blanc » pour les deux issues (jalon-04.md §14.11
		# T8 ; rival n° 2, T25).
		var outcomes: Array[int] = ([Battle.Outcome.WIN, Battle.Outcome.LOSS] as Array[int]) \
			if _has_battle(cutscene) else ([Battle.Outcome.WIN] as Array[int])
		for i: int in mini(rows.size(), cutscene.variants.size()):
			for map_id: StringName in maps:
				for aliases: Dictionary in _alias_sets(id):
					for extra: Array in _extra_flag_sets(id):
						for outcome: int in outcomes:
							checked += _simulate("%s/%d %s %s %d" % [id, i + 1, aliases, extra,
								outcome], cutscene.variants[i], map_id,
								_flags(rows[i] + extra), aliases, outcome)
	assert_gt(checked, 60, "acteurs vérifiés")


func _has_battle(cutscene: Cutscene) -> bool:
	for variant: CutsceneVariant in cutscene.variants:
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.BATTLE:
				return true
	return false


## Drapeaux ajoutés à chaque simulation d'une scène : les trois paires `taken_*` pour la scène
## du rival n° 2 (le Pokémon du rival présent en dépend), aucun sinon.
func _extra_flag_sets(cutscene_id: StringName) -> Array:
	if cutscene_id != &"rival_route22":
		return [[]]
	return RIVAL_PAIRS.values()


## Jalon 7 (T2) : la simulation connaît l'étape « scare » (acteur présent et « shy », retiré
## ensuite), sur les vrais Pokémon d'ambiance de la Route 1 et sur un PNJ créé par la scène.
func test_simulation_knows_the_scare_step() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"scare_test": {"steps": [
		{"scare": "route_pidgey"},
		{"spawn": "roof_bird", "sprite": "pidgey", "cell": [3, 3], "shy": {"action": "fly"}},
		{"scare": "$bird"},
		{"face": "traveler", "to": "player"},
	]}}, "test"), str(library.get_errors()))
	var variant := library.get_cutscene(&"scare_test").variants[0]
	var checked := _simulate("scare_test", variant, &"route_1", _flags([]),
		{&"bird": &"roof_bird"})
	assert_eq(checked, 4, "deux Pokémon effrayés, le voyageur et le joueur")


## Jeux d'alias d'une scène : ceux de l'offre pour la scène du choix (un par starter), un
## jeu vide sinon.
func _alias_sets(cutscene_id: StringName) -> Array[Dictionary]:
	if cutscene_id != _offer.chosen_scene:
		return [{}]
	var sets: Array[Dictionary] = []
	for option: StarterOption in _offer.get_choices():
		var rival := _offer.get_choice(_offer.rival_pick(option.species, _pokemon))
		sets.append({
			StarterChoice.PLAYER_ALIAS: option.npc, StarterChoice.RIVAL_ALIAS: rival.npc,
		})
	return sets


func test_alias_sets_of_the_choice_cover_the_three_starters() -> void:
	var sets := _alias_sets(&"starter_chosen")
	assert_eq(sets.size(), 3)
	assert_eq(_cutscenes.get_aliases(&"starter_chosen"),
		[StarterChoice.PLAYER_ALIAS, StarterChoice.RIVAL_ALIAS] as Array[StringName])
	assert_true(_cutscenes.get_aliases(&"oak_lab_exit").is_empty())


## Décision n° 1 (§13.3) : done_flag levé une seule fois, à l'étape qui suit le dialogue
## « oak_starter_reciprocal » ; la scène finit par rival_challenged ; ordre des dialogues
## (§13.5, décision n° 16 : « Ça devrait être intéressant. » après « Alors ce sera toi. »).
func test_starter_chosen_sets_done_flag_right_after_the_reciprocal_line() -> void:
	var cutscene := _cutscenes.get_cutscene(_offer.chosen_scene)
	assert_eq(cutscene.variants.size(), 1)
	var variant := cutscene.variants[0]
	assert_true(variant.if_flags.is_empty())
	assert_eq(variant.unless_flags, [&"rival_challenged"] as Array[StringName])
	var steps := variant.steps
	var set_at: Array[int] = []
	var dialogues: Array[StringName] = []
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS and steps[i].flags.has(_offer.done_flag):
			set_at.append(i)
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE:
			dialogues.append(steps[i].dialogue_id)
	assert_eq(set_at.size(), 1, "done_flag levé une seule fois")
	if set_at.size() == 1:
		var previous := steps[set_at[0] - 1]
		assert_eq(previous.kind, CutsceneStep.Kind.DIALOGUE)
		assert_eq(previous.dialogue_id, &"oak_starter_reciprocal")
		assert_eq(steps[set_at[0]].flags, [_offer.done_flag] as Array[StringName])
	assert_eq(dialogues, [&"oak_starter_reciprocal", &"rival_starter_pick",
		&"rival_starter_smile", &"rival_challenge_wait", &"rival_challenge", &"rival_lab_won",
		&"rival_lab_won_leaving", &"rival_lab_lost", &"oak_after_battle",
		&"oak_poke_balls_intro", &"oak_poke_balls"] as Array[StringName])
	assert_eq(steps.back().kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps.back().flags, [&"rival_challenged"] as Array[StringName], "dernière étape")
	# Le Pokémon descend (hop) et s'approche (lean) avant Chen.
	var kinds: Array[int] = []
	for step: CutsceneStep in steps.slice(0, set_at[0] if set_at.size() == 1 else 0):
		kinds.append(step.kind)
	assert_true(kinds.has(CutsceneStep.Kind.HOP), "le starter descend de la table")
	assert_true(kinds.has(CutsceneStep.Kind.LEAN), "il s'approche")
	# Décision n° 16 (Q-A) : après l'arrivée de son Pokémon, le rival regarde celui du joueur,
	# puis le joueur, temps mort (petit sourire), « Ça devrait être intéressant. ».
	var smile := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE \
				and steps[i].dialogue_id == &"rival_starter_smile":
			smile = i
	assert_gt(smile, 3)
	if smile > 3:
		assert_eq(steps[smile - 1].kind, CutsceneStep.Kind.WAIT, "temps mort")
		assert_eq([steps[smile - 2].actor, steps[smile - 2].target], [&"rival", &"player"])
		assert_eq(steps[smile - 3].kind, CutsceneStep.Kind.WAIT)
		assert_eq([steps[smile - 4].actor, steps[smile - 4].target],
			[&"rival", &"$player_starter"])


## Jalon 4B (§14.7) : le combat, puis rival_battle_done (quelle que soit l'issue), les
## répliques selon l'issue (conditions d'étape), le départ du rival, Chen, les 5 Poké Balls.
func test_starter_chosen_battle_and_aftermath() -> void:
	var steps := _cutscenes.get_cutscene(_offer.chosen_scene).variants[0].steps
	var battle := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.BATTLE:
			battle = i
	assert_gt(battle, 0, "une étape de combat")
	var step: CutsceneStep = steps[battle]
	assert_eq(step.trainer_id, &"rival_lab")
	assert_eq(CutsceneStep.alias_name(step.player_pokemon), StarterChoice.PLAYER_ALIAS)
	assert_eq(CutsceneStep.alias_name(step.foe_pokemon), StarterChoice.RIVAL_ALIAS)
	assert_eq(step.win_flags, [&"rival_lab_won"] as Array[StringName])
	assert_eq(step.lose_flags, [&"rival_lab_lost"] as Array[StringName])
	# Juste après le combat : rival_battle_done, sans condition (les deux issues).
	assert_eq(steps[battle + 1].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[battle + 1].flags, [&"rival_battle_done"] as Array[StringName])
	assert_true(steps[battle + 1].if_flags.is_empty() and steps[battle + 1].unless_flags.is_empty(),
		"levé quelle que soit l'issue")
	# La remise des 5 Poké Balls et le départ du rival.
	var give := -1
	var left := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.GIVE:
			give = i
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS \
				and steps[i].flags == ([&"rival_left_lab"] as Array[StringName]):
			left = i
	assert_gt(give, battle, "give après le combat")
	assert_eq(steps[give].item_id, &"poke_ball")
	assert_eq(steps[give].count, 5)
	assert_gt(left, battle, "rival_left_lab après le combat")


## §13.6 : Chen se tourne vers le joueur, parle, le joueur recule d'un pas (vers le haut) ;
## seulement pendant le choix.
func test_oak_lab_exit_only_during_the_choice() -> void:
	var cutscene := _cutscenes.get_cutscene(&"oak_lab_exit")
	assert_eq(cutscene.variants.size(), 1)
	var steps := cutscene.variants[0].steps
	assert_eq(steps.size(), 3)
	assert_eq(steps[0].kind, CutsceneStep.Kind.FACE)
	assert_eq([steps[0].actor, steps[0].target], [&"oak", &"player"])
	assert_eq(steps[1].dialogue_id, &"oak_lab_exit_block")
	assert_eq(steps[2].kind, CutsceneStep.Kind.MOVE)
	assert_eq(steps[2].actor, &"player")
	assert_eq(steps[2].path, [Vector2i.UP] as Array[Vector2i])
	assert_null(cutscene.pick(_flags([&"oak_met", &"oak_lab_reunion"])), "avant l'offre")
	assert_not_null(cutscene.pick(_flags([&"oak_met", &"starter_offered"])), "pendant")
	assert_null(cutscene.pick(_flags([&"starter_offered", &"starter_chosen"])), "après")


## Jalon 7 (T18, dossier 09 §6 et §19) : scène du colis, lancée en parlant à Chen avec le colis
## (variante « cutscene » de son dialogue). Ordre : le colis quitte le Sac, Chen remarque les
## rencontres (réplique de l'espèce dans le même dialogue, omise sans rencontre), le Pokédex est
## activé **une seule fois**, juste avant la légende POKÉDEX ACTIVÉ, puis « Observe. Explore. » ;
## le rival entre ensuite, reçoit le sien, ses répliques, il repart.
func test_oak_parcel_scene_order() -> void:
	var cutscene := _cutscenes.get_cutscene(&"oak_parcel")
	assert_eq(cutscene.variants.size(), 1)
	var variant := cutscene.variants[0]
	assert_true(variant.if_flags.is_empty())
	assert_eq(variant.unless_flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName],
		"jamais rejouée après l'activation")
	var steps := variant.steps
	var take := _index_of(steps, CutsceneStep.Kind.TAKE)
	var activated := -1
	var caption := _index_of(steps, CutsceneStep.Kind.CAPTION)
	var spawn := _index_of(steps, CutsceneStep.Kind.SPAWN)
	var dialogues: Array[StringName] = []
	for i: int in steps.size():
		assert_true(steps[i].if_flags.is_empty() and steps[i].unless_flags.is_empty(),
			"étape %d sans condition" % i)
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS:
			assert_eq(steps[i].flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName])
			assert_eq(activated, -1, "un seul « set »")
			activated = i
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE:
			dialogues.append(steps[i].dialogue_id)
	assert_eq(steps[take].item_id, &"oak_parcel")
	assert_eq(steps[take].count, 1)
	assert_eq(steps[caption].text, "POKÉDEX ACTIVÉ")
	assert_lt(take, _index_of_dialogue(steps, &"oak_parcel_records"), "colis remis d'abord")
	assert_lt(_index_of_dialogue(steps, &"oak_parcel_records"), activated)
	assert_eq(caption, activated + 1, "la légende suit l'activation")
	assert_eq(_index_of_dialogue(steps, &"oak_pokedex_activated"), caption + 1)
	assert_gt(spawn, caption, "le rival arrive après l'activation")
	assert_eq(steps[spawn].spec.id, &"rival")
	assert_eq(steps[spawn].spec.sprite, &"rival")
	assert_eq(dialogues, [&"oak_parcel_records", &"oak_pokedex_activated",
		&"rival_parcel_return", &"rival_parcel_greet", &"oak_parcel_rival_dex",
		&"oak_parcel_rival", &"rival_parcel_leaving"] as Array[StringName])
	var despawn := _index_of(steps, CutsceneStep.Kind.DESPAWN)
	assert_eq(steps[despawn].actor, &"rival", "il repart")
	assert_gt(despawn, _index_of_dialogue(steps, &"rival_parcel_leaving"))
	assert_eq(_cutscenes.get_item_ids().count(&"oak_parcel"), 1)


## Une seule étape de toutes les données lève pokedex_activated (jamais un dialogue).
func test_pokedex_activated_is_raised_only_by_the_parcel_scene() -> void:
	var raised := 0
	for id: StringName in _real_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.flags.has(StoryFlags.POKEDEX_ACTIVATED) \
						or step.win_flags.has(StoryFlags.POKEDEX_ACTIVATED) \
						or step.lose_flags.has(StoryFlags.POKEDEX_ACTIVATED):
					raised += 1
					assert_eq(id, &"oak_parcel")
	assert_eq(raised, 1)
	assert_false(_dialogues.get_set_flags().has(StoryFlags.POKEDEX_ACTIVATED))


func _index_of(steps: Array[CutsceneStep], kind: CutsceneStep.Kind) -> int:
	for i: int in steps.size():
		if steps[i].kind == kind:
			return i
	return -1


func _index_of_dialogue(steps: Array[CutsceneStep], dialogue_id: StringName) -> int:
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE and steps[i].dialogue_id == dialogue_id:
			return i
	return -1


## Joue [param variant] « à blanc » : renvoie le nombre d'acteurs vérifiés. [param aliases] :
## « nom sans $ » → PNJ, remplacés comme le fait le directeur.
func _simulate(label: String, variant: CutsceneVariant, start_map: StringName,
		flags: StoryFlags, aliases: Dictionary = {}, outcome: int = Battle.Outcome.WIN) -> int:
	var map_id := start_map
	var actors := _present(map_id, flags)
	var checked := 0
	# PNJ créés par les étapes « spawn » de la carte courante.
	var spawned: Dictionary[StringName, NpcSpec] = {}
	for source: CutsceneStep in variant.steps:
		# Conditions d'étape (« if » / « unless ») évaluées au moment de la jouer : une étape
		# sautée ne vérifie aucun acteur (jalon-04.md §14.3).
		if not source.applies(flags):
			continue
		var step := _resolved(source, aliases)
		var where := "%s sur %s (%s)" % [label, map_id, CutsceneStep.kind_name(step.kind)]
		var needed: Array[StringName] = []
		if step.kind == CutsceneStep.Kind.WAKE_UP:
			# Réveil au point de repos (T25) : la scène s'arrête là.
			break
		match step.kind:
			CutsceneStep.Kind.SET_FLAGS:
				for flag: StringName in step.flags:
					flags.set_flag(flag)
			CutsceneStep.Kind.BATTLE:
				assert_true(_trainers.has_trainer(step.trainer_id),
					"%s : dresseur « %s »" % [where, step.trainer_id])
				for who: StringName in [step.player_pokemon, step.foe_pokemon]:
					if not who.is_empty():
						needed.append(who)
				for flag: StringName in step.outcome_flags(outcome):
					flags.set_flag(flag)
			CutsceneStep.Kind.GIVE:
				assert_true(_items.has_item(step.item_id), "%s : objet « %s »" % [where,
					step.item_id])
			CutsceneStep.Kind.GIFT_POKEMON:
				# Jalon 20 (T12) : espèce connue, dialogues existants, drapeau levé.
				assert_true(_pokemon.has_species(step.species), "%s : espèce « %s »" % [where,
					step.species])
				for said: StringName in [step.dialogue_id, step.dialogue_stored]:
					if not said.is_empty():
						assert_true(_dialogues.has_dialogue(said), "%s : dialogue « %s »" % [
							where, said])
				flags.set_flag(step.gift_flag)
			CutsceneStep.Kind.CHAMPION_CARD:
				var trainer := _trainers.get_trainer(step.trainer_id)
				assert_true(trainer != null and trainer.has_card(), "%s : carte de « %s »" % [
					where, step.trainer_id])
			CutsceneStep.Kind.BADGE:
				assert_true(_badges.has_badge(step.badge_id), "%s : badge « %s »" % [where,
					step.badge_id])
				flags.set_flag(_badges.flag(step.badge_id))
			CutsceneStep.Kind.TAKE:
				assert_true(_items.has_item(step.item_id), "%s : objet « %s »" % [where,
					step.item_id])
			CutsceneStep.Kind.SPAWN:
				assert_false(actors.has(step.spec.id), "%s : « %s » déjà là" % [where,
					step.spec.id])
				actors.append(step.spec.id)
				spawned[step.spec.id] = step.spec
			CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				actors = _present(map_id, flags)
				spawned.clear()
			CutsceneStep.Kind.FACE:
				needed.append(step.actor)
				if not Grid.is_direction_name(step.target):
					needed.append(step.target)
			CutsceneStep.Kind.MOVE, CutsceneStep.Kind.HOP:
				needed.append(step.actor)
				for other: StringName in [step.follower, step.near]:
					if not other.is_empty():
						needed.append(other)
			CutsceneStep.Kind.LEAN:
				needed.append(step.actor)
				if not Grid.is_direction_name(step.target):
					needed.append(step.target)
			CutsceneStep.Kind.DESPAWN:
				needed.append(step.actor)
			CutsceneStep.Kind.SCARE:
				# Jalon 7 (T2) : seul un Pokémon d'ambiance « shy » peut être effrayé.
				needed.append(step.actor)
				var spec := _spec_of(step.actor, map_id, spawned)
				assert_true(spec != null and spec.is_shy(), "%s : « %s » est « shy »" % [
					where, step.actor])
			CutsceneStep.Kind.DIALOGUE:
				var dialogue := _dialogues.get_dialogue(step.dialogue_id)
				var picked: DialogueVariant = dialogue.pick(flags) if dialogue != null else null
				# Jalon 16 (T15) : une scène de capacité de terrain (COUPER) n'est lancée que
				# dans l'état « prêt » : ses répliques suivent cette variante.
				if picked == null and dialogue != null:
					picked = dialogue.pick(flags, null, 0, func(_move: StringName) -> Variant:
						return FieldMoves.Result.new(FieldMoves.State.READY, 0))
				assert_not_null(picked, "%s : « %s » a une variante" % [where,
					step.dialogue_id])
				if picked != null:
					for page: DialoguePage in picked.pages:
						for actor: StringName in page.turn:
							needed.append(actor)
							if not Grid.is_direction_name(page.turn[actor]):
								needed.append(page.turn[actor])
		for who: StringName in needed:
			checked += 1
			assert_false(CutsceneStep.is_alias(who), "%s : alias « %s » résolu" % [where, who])
			assert_true(actors.has(who), "%s : « %s » présent" % [where, who])
		if step.kind == CutsceneStep.Kind.DESPAWN or step.kind == CutsceneStep.Kind.SCARE:
			actors.erase(step.actor)
	return checked


## Description du PNJ [param id] : créé par la scène, sinon lu dans le fichier de la carte.
func _spec_of(id: StringName, map_id: StringName,
		spawned: Dictionary[StringName, NpcSpec]) -> NpcSpec:
	if spawned.has(id):
		return spawned[id]
	return NpcRoster.load_for_map(map_id).get_spec(id)


## Copie de [param step] avec ses alias remplacés (acteur, cible, voisin, suiveur).
func _resolved(step: CutsceneStep, aliases: Dictionary) -> CutsceneStep:
	if step.get_aliases().is_empty():
		return step
	var copy := CutsceneStep.new()
	copy.kind = step.kind
	copy.dialogue_id = step.dialogue_id
	copy.flags = step.flags
	copy.spec = step.spec
	copy.map_id = step.map_id
	copy.actor = _alias(step.actor, aliases)
	copy.target = _alias(step.target, aliases)
	copy.near = _alias(step.near, aliases)
	copy.follower = _alias(step.follower, aliases)
	copy.trainer_id = step.trainer_id
	copy.item_id = step.item_id
	copy.count = step.count
	copy.win_flags = step.win_flags
	copy.lose_flags = step.lose_flags
	copy.player_pokemon = _alias(step.player_pokemon, aliases)
	copy.foe_pokemon = _alias(step.foe_pokemon, aliases)
	return copy


func _alias(ref: StringName, aliases: Dictionary) -> StringName:
	if not CutsceneStep.is_alias(ref):
		return ref
	return aliases.get(CutsceneStep.alias_name(ref), ref)


## Joueur et PNJ présents sur [param map_id] pour [param flags].
func _present(map_id: StringName, flags: StoryFlags) -> Array[StringName]:
	var ids: Array[StringName] = [NpcRoster.PLAYER_ID]
	for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(flags):
		ids.append(spec.id)
	return ids


## Jalon 21 : Sac contenant un exemplaire de chaque objet de [param ids].
func _bag(ids: Array) -> Bag:
	var bag := Bag.new()
	for id: StringName in ids:
		bag.add(id)
	return bag


func _flags(names: Array) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in names:
		flags.set_flag(flag)
	return flags


## Scènes sans celles d'une éventuelle carte de QA (`qa_*` ; celles du jalon 16 sont retirées au
## T20).
func _real_ids() -> Array[StringName]:
	return _without_qa(_cutscenes.get_ids())


func _without_qa(ids: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in ids:
		if not MapCatalog.is_qa_map(id):
			result.append(id)
	return result
