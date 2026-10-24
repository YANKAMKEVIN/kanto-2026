extends GutTest
## Données de dialogue du jalon 3A (jalon-03.md §3.3, §3.4, T4) : data/dialogues/*.json
## avec les vrais PNJ (data/npcs/*.json) et les vrais points d'examen des cartes.
## Chargement sans erreur, références (dialogues, react), drapeaux, textes du dossier 02
## repris mot pour mot, trois lignes au plus dans la vraie DialogueBox à 1920 × 1080,
## aucun texte provisoire (draft) depuis la validation du lot de textes (2026-10-06).
## Jalon 3B (T2) : dialogues joués par les scènes de data/cutscenes/ (via les
## EventTriggerPoint des cartes), drapeaux lus et levés par dialogues, scènes et PNJ.
## T3 : répliques du Prof. Chen, acteurs et cibles des « turn » (PNJ de la carte ou créés
## par la scène qui joue le dialogue).
## T4 : retour au labo (change_map : les dialogues suivants sont joués sur la carte cible),
## « oak_lab_reunion », nouvelle variante de Maya (oak_met), drapeau oak_lab_reunion.
## Jalon 4 (T1) : « oak_starter_offer » (Chen propose, 4 pages, regard vers la table à la 3e)
## joué à la fin de la variante 1 de route1_grass, qui lève starter_offered.
## T3 (jalon-04.md §13.5 à §13.7) : répliques du choix (« réciproque », rival, sortie
## empêchée), jouées par la scène du choix (lancée par le code sur la carte de l'offre) ou
## par le déclencheur LabExit ; variantes starter_chosen de Maya et de Chen ; drapeaux levés
## par le code (StarterChoice.get_set_flags : taken_*, starter_female).
## Décision n° 16 : répliques de la phase de choix ; celles de la décision n° 8 réservées à
## l'après-combat (rival_battle_done, drapeau « futur » du 4B), Maya accordée (lui / elle).
## Jalon 9 (T11) : répliques des 5 Dresseurs de la Forêt de Jade, mot pour mot depuis les
## « Textes verrouillés » du dossier 10 (« « … » / « … » » = une page de deux lignes), locuteur
## = nom du Dresseur ; réplique « avant » du bloc « trainer » utilisée comme un dialogue de PNJ.
## Jalon 10 (T8) : Route 2 nord et Argenta, mot pour mot depuis les « Textes verrouillés » du
## dossier 12 (même forme que le dossier 10) et le lot de textes du J10 validé le 2026-10-08
## (panneaux, noms affichés) ; dialogues en attente de leurs cartes ([constant UNUSED_YET]).

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const DOSSIER := "res://docs/design/dossier-02-prologue.md"
## Route 1 (jalon 5) : ses textes définitifs viennent du dossier-07, pas du dossier-02.
const DOSSIER_07 := "res://docs/design/dossier-07-route-1.md"
## Jalon 7 : textes de référence validés (dossier 09 §19) ; un jeton y est écrit « {espèce} ».
const DOSSIER_09 := "res://docs/design/dossier-09-jadielle.md"
## Jalon 9 : textes verrouillés du dossier 10 (Forêt de Jade, gardes, Dresseurs) ; une réplique
## de deux lignes « « ligne 1 » / « ligne 2 » » = une page, lignes jointes par « \n ».
const DOSSIER_10 := "res://docs/design/dossier-10-foret-de-jade.md"
## Gardes des postes de la Forêt de Jade (T6) : textes vérifiés par un test dédié.
const GATE_GUARDS: Array[StringName] = [&"forest_gate_north_guard", &"forest_gate_south_guard"]
## Dialogues pas encore posés sur une carte (vidée au T19 du jalon 9 : la forêt et ses postes
## sont dans [constant MAPS]). Jalon 10 (T8) : tous ceux de la Route 2 nord et d'Argenta, en
## attente de leurs cartes (T11 Route 2 nord et Argenta, T13 intérieurs, T14 la vie, T17
## l'Arène ; `pewter_gym_liam_defeated` est lue par la clé « defeated » du bloc « trainer »
## depuis le T9). À retirer carte par carte en ajoutant la carte à [constant MAPS].
## T13 : les intérieurs d'Argenta sont dans [constant MAPS] (Musée, maisons, Arène : retirés).
## T11 : la Route 2 nord et Argenta (extérieur) sont dans [constant MAPS] : liste vide.
## Jalon 14 (T23) : D5 et D6 posés, leurs répliques (n° 50, 51) sortent de la liste.
## Jalon 15 (T14) : les Dresseurs de la Route 6 sont posés avec la carte : liste vide.
## Jalon 18 (T16) : textes en données, points d'examen et déclencheurs posés par la vie des cartes
## (T18 Route 9 / 10, T20 grotte ; T24 : Lavanville et Tour posés, retirés de la liste) ; « Il fait très sombre ici… » (T-3) est
## celui du J17 (`dark_caves.json`, joué par FlashDirector : [constant PLAYED_BY_BOOT]).
const UNUSED_YET: Array[StringName] = [
	# Jalon 21 (T21) : `route_11_snorlax` repris par `snorlax_route_12` (retiré de la liste).
	&"dark_cave_1f_sign", &"dark_cave_column", &"dark_cave_roots", &"dark_cave_crack",
	&"dark_cave_b1f_hidden_1",
	# Jalon 20 (T17) : la Poké Ball d'Évoli (maison du toit) et le panneau d'ascenseur (cabine du
	# grand magasin) sont posés : plus rien du J20 n'attend ici.
]
## Jalon 17 (T8) : pages à jeton (texte → jetons attendus) : l'assistant et la CS05 reçue.
const J17_TOKENS: Dictionary[String, Array] = {
	"Ton Pokédex compte {caught} espèces !": [&"caught"],
	"Ton Pokédex en compte {caught}. Reviens me voir !": [&"caught"],
	"Ton Pokédex compte {caught} espèces capturées.": [&"caught"],
	"Encore {caught_missing}, et c'est à toi.": [&"caught_missing"],
	"{player} reçoit la CS05 — Flash !": [&"player"],
	# Passe systèmes 2 (S2B) : la Poké Flûte jouée « ailleurs ».
	"{player} joue de la Poké Flûte…": [&"player"],
}
## Textes pas encore validés, exemptés du contrôle « mot pour mot » (jalon 14 T16 : ceux du
## coquillage de la Route 25, validés depuis : dossier 17 §15 n° 71 ; le n° 72 est retiré le 2026-10-14).
## Jalon 20 (T17) : le panneau neutre de la cabine du T16 est remplacé par `elevator_panel` (T13).
## S2C (option A de Kevin, 2026-10-21) : question du choix « Pêcher / Surfer » [D], à valider.
const UNVALIDATED: Array[StringName] = [&"water_choice"]
## Passe systèmes 2 (T25b) : Téléport et Tunnel hors combat, joués par [FieldTravelDirector] ;
## textes provisoires du lot `systemes-2.md` §8.1 (pas encore dans un dossier).
const S2_FIELD_TRAVEL: Array[StringName] = [&"dig_used", &"teleport_used", &"fly_takeoff",
	&"fly_landing", &"key_door_locked"]
## Jalon 11 (T20c) : phrases jouées par le contrôleur du compagnon (ni PNJ, ni point, ni scène).
const PLAYED_BY_COMPANION: Array[StringName] = [
	&"companion_cave", &"companion_city", &"companion_forest", &"companion_happy",
	&"companion_sniff", &"companion_stretch", &"companion_stretch_soft", &"companion_tired",
	&"companion_tired_f", &"companion_unwell", &"companion_watch", &"companion_water",
]
## Jalon 12 (T20) : phrases jouées par Boot (ni PNJ, ni point, ni scène) : la Corde Sortie
## ([constant Boot.ESCAPE_ROPE_DIALOGUE], dossier 15 §20 n° 33).
## Jalon 17 (T24) : avertissement sans Flash, joué par FlashDirector (dossier 21 T-3).
## Jalon 20 (T13) : refus du panneau sans la Clé (T-50), joué par ElevatorDirector.
## Passe systèmes 2 (S2B) : refus du Vélo (MountDirector) et Flûte « ailleurs » (KeyItemDirector).
const PLAYED_BY_BOOT: Array[StringName] = [&"escape_rope_used", &"dark_cave_too_dark",
	&"elevator_locked", &"bike_indoors", &"bike_cycling_road_walk", &"poke_flute_played",
	&"surf_water", &"surf_first_ride", &"surf_current_too_strong", &"water_choice"]
## Passe systèmes 2 (S2B) : textes validés des dossiers 25 (§16.1.3, §16.1.4) et 24 (§15.6.6),
## qui vivent encore sur les branches de conception du J21 et du J22 (pas dans `main`) : comparés
## ici mot pour mot, page par page.
## S2C : textes du Surf, dossier 27 T-1, T-2, T-3, T-14 (branche du J24).
const IDS_S2B: Array[StringName] = [&"bike_cycling_road_walk", &"bike_indoors",
	&"poke_flute_played", &"surf_water", &"surf_first_ride", &"surf_current_too_strong"]
const TEXTS_S2B: Dictionary[StringName, Array] = {
	&"bike_indoors": ["Ce n'est pas le moment de pédaler !"],
	&"bike_cycling_road_walk": ["Pas de marche à pied", "sur la Piste Cyclable !"],
	&"poke_flute_played": ["{player} joue de la Poké Flûte…", "Quel air entraînant !"],
	&"surf_water": ["L'eau est profonde. Un Pokémon pourrait vous porter.",
		"Il faut le Badge Âme pour utiliser Surf hors des combats."],
	&"surf_first_ride": ["{pokemon} vous porte sur l'eau !"],
	&"surf_current_too_strong": ["Le courant est beaucoup trop fort !"],
}
## Passe systèmes 2 (S2C-bis) : textes de la pêche, joués par [FishingDirector] ; validés au
## dossier 25 §16.2.8 à §16.2.11 (branche de conception du J22, pas dans `main`).
const TEXTS_S2C_FISH: Dictionary[StringName, Array] = {
	&"fishing_cast": ["{player} lance sa ligne…"],
	&"fishing_bite": ["Oh ! Ça mord !"],
	&"fishing_nothing": ["Rien ne mord…"],
	&"fishing_no_water": ["On ne peut pas pêcher ici."],
}
## Passe systèmes 2 (S2D) : textes de Force, joués par [StrengthDirector] (EXAMINER d'un rocher,
## activation, chute) ; validés au dossier 27 T-5, T-6, T-7, T-15 (branche de conception du J24,
## pas dans `main`) : comparés ici mot pour mot.
const TEXTS_S2D_STRENGTH: Dictionary[StringName, Array] = {
	&"strength_boulder": ["Un gros rocher. Il pourrait être déplacé.",
		"Il faut le Badge Prisme pour utiliser Force hors des combats."],
	&"strength_used": ["{pokemon} utilise Force ! Les rochers peuvent être déplacés."],
	&"strength_boulder_fell": ["Le rocher a dévalé dans le trou !"],
}
## Jalon 24 : textes du dossier 27 §15 (validés le 2026-10-16) mis en page dans la bulle (retours
## à la ligne, panneaux « TITRE / texte », T-60 et T-62 écrits par fossile) et répliques de don
## (« reçoit », « au stockage », modèle du J20) : recommandés, validés d'avance par Kevin le
## 2026-10-21. Chaque page doit être l'une de celles-ci.
const TEXTS_J24: Dictionary[StringName, Array] = {
	&"cinnabar_fossil_ready_kabuto": ["Te voilà ! Ton fossile\nétait un Kabuto !"],
	&"cinnabar_fossil_ready_omanyte": ["Te voilà ! Ton fossile\nétait un Amonita !"],
	&"cinnabar_lab_tm35_use": ["{player} reçoit la CT35 Métronome !"],
	&"cinnabar_fossil_taken": ["Bien. Ça prend un peu de temps :\nva faire un tour dehors !"],
	&"cinnabar_fossil_received_kabuto": ["{player} reçoit Kabuto !"],
	&"cinnabar_fossil_received_omanyte": ["{player} reçoit Amonita !"],
	&"cinnabar_fossil_stored_kabuto": ["Kabuto a été envoyé au stockage."],
	&"cinnabar_fossil_stored_omanyte": ["Amonita a été envoyé au stockage."],
	&"cinnabar_fossil_scientist": ["Patience !\nVa faire un tour.", "Je recrée des Pokémon\nà partir de fossiles.", "Tu en as un ?", "Le Fossile Dôme ?\nJe te le prends ?", "Le Fossile Nautile ?\nJe te le prends ?", "Le Vieil Ambre ?\nJe te le prends ?", "Sans fossile, je n'ai rien\nà recréer.", "Il paraît qu'on en trouve\nau Mont Sélénite."],
	&"cinnabar_gym_sign": ["ARÈNE DE CRAMOIS'ÎLE\nChampion : Auguste,", "le maître du feu\net des énigmes"],
	&"cinnabar_sign": ["CRAMOIS'ÎLE\nL'île au cœur de feu"],
	&"cinnabar_lab_pc": ["Un courriel : « Trois Pokémon\noiseaux légendaires", "vivraient à Kanto.", "On parle de l'un d'eux\nprès des Îles Écume… »"],
	&"route_19_sign": ["ROUTE MARINE 19\nParmanie ↑ · Îles Écume ←"],
	&"route_20_sign": ["ÎLES ÉCUME\nGrottes glaciales, accès par la mer"],
}
## Jalon 25 (T9) : Manoir Pokémon, Arène de Cramois'Île, échanges du Labo, réserve du Musée, Ptéra
## (dossier 28 §16, validés par Kevin le 2026-10-16 ; répliques « draft » des Dresseurs et mise en
## page, recommandées, validées d'avance par Kevin le 2026-10-21). Pas encore posés par des cartes :
## [constant UNUSED_YET] (T14, T17, T18, T20, T21).
const IDS_J25: Array[StringName] = [
	&"cinnabar_blaine",
	&"cinnabar_blaine_after",
	&"cinnabar_blaine_badge",
	&"cinnabar_blaine_before",
	&"cinnabar_blaine_defeated",
	&"cinnabar_blaine_tm38",
	&"cinnabar_fossil_ready_aerodactyl",
	&"cinnabar_fossil_received_aerodactyl",
	&"cinnabar_fossil_stored_aerodactyl",
	&"cinnabar_gym_1_after",
	&"cinnabar_gym_1_before",
	&"cinnabar_gym_1_defeated",
	&"cinnabar_gym_2_after",
	&"cinnabar_gym_2_before",
	&"cinnabar_gym_2_defeated",
	&"cinnabar_gym_3_after",
	&"cinnabar_gym_3_before",
	&"cinnabar_gym_3_defeated",
	&"cinnabar_gym_4_after",
	&"cinnabar_gym_4_before",
	&"cinnabar_gym_4_defeated",
	&"cinnabar_gym_5_after",
	&"cinnabar_gym_5_before",
	&"cinnabar_gym_5_defeated",
	&"cinnabar_gym_6_after",
	&"cinnabar_gym_6_before",
	&"cinnabar_gym_6_defeated",
	&"cinnabar_gym_7_after",
	&"cinnabar_gym_7_before",
	&"cinnabar_gym_7_defeated",
	&"cinnabar_gym_door_unlock",
	&"cinnabar_gym_guide",
	&"cinnabar_gym_quiz_1",
	&"cinnabar_gym_quiz_1_question",
	&"cinnabar_gym_quiz_2",
	&"cinnabar_gym_quiz_2_question",
	&"cinnabar_gym_quiz_3",
	&"cinnabar_gym_quiz_3_question",
	&"cinnabar_gym_quiz_4",
	&"cinnabar_gym_quiz_4_question",
	&"cinnabar_gym_quiz_5",
	&"cinnabar_gym_quiz_5_question",
	&"cinnabar_gym_quiz_6",
	&"cinnabar_gym_quiz_6_question",
	&"cinnabar_gym_quiz_intro",
	&"cinnabar_gym_quiz_right",
	&"cinnabar_gym_quiz_wrong",
	&"cinnabar_trade_cable",
	&"cinnabar_trade_hector",
	&"cinnabar_trade_hector_after",
	&"cinnabar_trade_hector_done",
	&"cinnabar_trade_hector_offer",
	&"cinnabar_trade_hector_refuse",
	&"cinnabar_trade_hector_thanks",
	&"cinnabar_trade_hector_wrong",
	&"cinnabar_trade_lina",
	&"cinnabar_trade_lina_after",
	&"cinnabar_trade_lina_done",
	&"cinnabar_trade_lina_offer",
	&"cinnabar_trade_lina_refuse",
	&"cinnabar_trade_lina_thanks",
	&"cinnabar_trade_lina_wrong",
	&"cinnabar_trade_marc",
	&"cinnabar_trade_marc_after",
	&"cinnabar_trade_marc_done",
	&"cinnabar_trade_marc_offer",
	&"cinnabar_trade_marc_refuse",
	&"cinnabar_trade_marc_thanks",
	&"cinnabar_trade_marc_wrong",
	&"mansion_burglar_1_after",
	&"mansion_burglar_1_before",
	&"mansion_burglar_1_defeated",
	&"mansion_burglar_2_after",
	&"mansion_burglar_2_before",
	&"mansion_burglar_2_defeated",
	&"mansion_burglar_3_after",
	&"mansion_burglar_3_before",
	&"mansion_burglar_3_defeated",
	&"mansion_journal_1",
	&"mansion_journal_2",
	&"mansion_journal_3",
	&"mansion_journal_4",
	&"mansion_scientist_1_after",
	&"mansion_scientist_1_before",
	&"mansion_scientist_1_defeated",
	&"mansion_scientist_2_after",
	&"mansion_scientist_2_before",
	&"mansion_scientist_2_defeated",
	&"mansion_scientist_3_after",
	&"mansion_scientist_3_before",
	&"mansion_scientist_3_defeated",
	&"mansion_statue",
	&"mansion_statue_yes",
	&"pewter_museum_reserve_amber",
	&"pewter_museum_reserve_amber_give",
	&"pewter_museum_reserve_counter",
	&"pewter_museum_reserve_showcase",
	&"pewter_museum_tree",
	&"pokemon_mansion_1f_hidden_1",
	&"pokemon_mansion_1f_item_1",
	&"pokemon_mansion_1f_item_2",
	&"pokemon_mansion_2f_item_1",
	&"pokemon_mansion_3f_hidden_1",
	&"pokemon_mansion_3f_item_1",
	&"pokemon_mansion_3f_item_2",
	&"pokemon_mansion_b1f_hidden_1",
	&"pokemon_mansion_b1f_item_1",
	&"pokemon_mansion_b1f_item_2",
	&"pokemon_mansion_b1f_item_3",
	&"pokemon_mansion_b1f_item_4",
	&"pokemon_mansion_b1f_item_5"
]
const TEXTS_J25: Dictionary[StringName, Array] = {
	&"cinnabar_blaine_after": ["Déflagration, c'est le Feu à son sommet !\nNe la gâche pas sur un Pokémon Eau !"],
	&"cinnabar_blaine_badge": ["Ha ! Ce Badge prouve ta valeur.\nPrends ceci aussi !"],
	&"cinnabar_blaine_before": ["Ha ! Je suis Auguste, Champion de\nCramois'Île !", "Mes Pokémon Feu vont tout réduire\nen cendres ! Tu as de l'Antibrûle ?"],
	&"cinnabar_blaine_defeated": ["J'ai brûlé tout mon feu !\nTu as gagné le Badge Volcan !"],
	&"cinnabar_blaine_tm38": ["La CT38 contient Déflagration !\nApprends-la à un Pokémon Feu !"],
	&"cinnabar_fossil_ready_aerodactyl": ["Te voilà ! Ton fossile\nétait un Ptéra !"],
	&"cinnabar_fossil_received_aerodactyl": ["{player} reçoit Ptéra !"],
	&"cinnabar_fossil_stored_aerodactyl": ["Ptéra a été envoyé au stockage."],
	&"cinnabar_gym_1_after": ["Tu sais à quelle température monte\nle souffle d'un Pokémon Feu ?"],
	&"cinnabar_gym_1_before": ["Tu sais à quelle température monte\nle souffle d'un Pokémon Feu ?"],
	&"cinnabar_gym_1_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_2_after": ["J'étais voleur. Grâce aux Pokémon,\nje suis devenu honnête !"],
	&"cinnabar_gym_2_before": ["J'étais voleur. Grâce aux Pokémon,\nje suis devenu honnête !"],
	&"cinnabar_gym_2_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_3_after": ["Tu ne gagneras pas !\nJ'ai tout étudié sur les Pokémon !"],
	&"cinnabar_gym_3_before": ["Tu ne gagneras pas !\nJ'ai tout étudié sur les Pokémon !"],
	&"cinnabar_gym_3_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_4_after": ["J'aime juste les Pokémon Feu !"],
	&"cinnabar_gym_4_before": ["J'aime juste les Pokémon Feu !"],
	&"cinnabar_gym_4_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_5_after": ["Un jour, il s'est perdu en montagne.\nUn oiseau de feu est apparu…", "Sa lumière l'a guidé jusqu'en bas."],
	&"cinnabar_gym_5_before": ["Je sais pourquoi Auguste est devenu Dresseur !"],
	&"cinnabar_gym_5_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_6_after": ["J'ai visité beaucoup d'Arènes,\nmais celle-ci est ma préférée !"],
	&"cinnabar_gym_6_before": ["J'ai visité beaucoup d'Arènes,\nmais celle-ci est ma préférée !"],
	&"cinnabar_gym_6_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_7_after": ["Le Feu craint l'eau !"],
	&"cinnabar_gym_7_before": ["Le Feu craint l'eau !"],
	&"cinnabar_gym_7_defeated": ["Trop chaud pour moi !"],
	&"cinnabar_gym_door_unlock": ["La Clé Secrète tourne dans la serrure.", "La porte de l'Arène est ouverte !"],
	&"cinnabar_gym_guide": ["{player} ! Tu as éteint ce volcan !", "Salut, futur Champion ! Auguste est\nun expert du Feu. Mise sur l'Eau !", "Et prends quelques Antibrûle !"],
	&"cinnabar_gym_quiz_1": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_1_question": ["Chenipan finit par devenir Papilusion ?"],
	&"cinnabar_gym_quiz_2": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_2_question": ["La Ligue délivre-t-elle 9 Badges ?"],
	&"cinnabar_gym_quiz_3": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_3_question": ["Ptitard évolue-t-il trois fois ?"],
	&"cinnabar_gym_quiz_4": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_4_question": ["L'Électrik touche-t-il le type Sol ?"],
	&"cinnabar_gym_quiz_5": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_5_question": ["Deux Pokémon de même espèce et même\nniveau peuvent-ils être différents ?"],
	&"cinnabar_gym_quiz_6": ["Porte ouverte.", "Porte ouverte."],
	&"cinnabar_gym_quiz_6_question": ["La CT28 contient-elle Fosse ?"],
	&"cinnabar_gym_quiz_intro": ["Quiz Pokémon ! Bonne réponse : la porte\ns'ouvre. Mauvaise : un Dresseur t'attaque !", "Garde tes forces pour le Champion :\nréponds juste !"],
	&"cinnabar_gym_quiz_right": ["Exact ! Tu peux passer !"],
	&"cinnabar_gym_quiz_wrong": ["Raté ! Mauvaise réponse !"],
	&"cinnabar_trade_cable": ["Branchez le câble comme ça !"],
	&"cinnabar_trade_hector_after": ["Ton Raichu se porte à merveille !"],
	&"cinnabar_trade_hector_done": ["{player} a échangé Raichu contre Kourjus !"],
	&"cinnabar_trade_hector_offer": ["Bonjour ! Tu veux échanger ton Raichu\ncontre mon Électrode ?"],
	&"cinnabar_trade_hector_refuse": ["Bon, si tu ne veux pas…"],
	&"cinnabar_trade_hector_thanks": ["Merci !"],
	&"cinnabar_trade_hector_wrong": ["Hmm ? Ce n'est pas un Raichu.\nPense à moi si tu en as un."],
	&"cinnabar_trade_lina_after": ["Comment va mon ancien Saquedeneu ?"],
	&"cinnabar_trade_lina_done": ["{player} a échangé Mimitoss contre Bigoudi !"],
	&"cinnabar_trade_lina_offer": ["Salut ! Tu as un Mimitoss ?\nTu l'échangerais contre un Saquedeneu ?"],
	&"cinnabar_trade_lina_refuse": ["Dommage."],
	&"cinnabar_trade_lina_thanks": ["Merci beaucoup !"],
	&"cinnabar_trade_lina_wrong": ["Ce n'est pas un Mimitoss…\nSi tu en trouves un, reviens me voir !"],
	&"cinnabar_trade_marc_after": ["Mon ancien Otaria est génial, hein ?"],
	&"cinnabar_trade_marc_done": ["{player} a échangé Ponyta contre Bibi !"],
	&"cinnabar_trade_marc_offer": ["Je cherche un Ponyta !\nJe te l'échange contre un Otaria ?"],
	&"cinnabar_trade_marc_refuse": ["Oh… tant pis."],
	&"cinnabar_trade_marc_thanks": ["Super, merci !"],
	&"cinnabar_trade_marc_wrong": ["Quoi ? Ce n'est pas un Ponyta !\nReviens quand tu en auras un !"],
	&"mansion_burglar_1_after": ["Les statues ouvrent et ferment les\ngrilles, chacune son tour !"],
	&"mansion_burglar_1_before": ["Je n'arrive pas à sortir !\nCe manoir est un vrai casse-tête !"],
	&"mansion_burglar_1_defeated": ["Bon, bon… J'abandonne."],
	&"mansion_burglar_2_after": ["Je me demande où est passé mon associé."],
	&"mansion_burglar_2_before": ["Cet endroit est immense !"],
	&"mansion_burglar_2_defeated": ["Perdu, en plus de ça…"],
	&"mansion_burglar_3_after": ["On trouve des trucs par terre, ici."],
	&"mansion_burglar_3_before": ["Oh oh. Où suis-je ?"],
	&"mansion_burglar_3_defeated": ["Aïe. Encore raté."],
	&"mansion_journal_1": ["Journal — 5 juillet.\nExpédition au cœur d'une jungle lointaine.", "Un Pokémon inconnu a été découvert."],
	&"mansion_journal_2": ["Journal — 10 juillet.\nNous avons baptisé le nouveau Pokémon :", "Mew."],
	&"mansion_journal_3": ["Journal — 6 février.\nMew a donné naissance.", "Nous avons appelé le petit Mewtwo."],
	&"mansion_journal_4": ["Journal — 1ᵉʳ septembre.\nMewtwo est bien trop puissant.", "Nous n'arrivons plus à maîtriser\nsa violence…"],
	&"mansion_scientist_1_after": ["Ce manoir a brûlé il y a longtemps.\nLes notes, elles, sont restées."],
	&"mansion_scientist_1_before": ["Qui êtes-vous ?\nPersonne ne devrait être ici."],
	&"mansion_scientist_1_defeated": ["Une clé ?\nJe ne vois pas de quoi tu parles."],
	&"mansion_scientist_2_after": ["Coincé ? Essaie de sauter par là-bas !"],
	&"mansion_scientist_2_before": ["Mon mentor vivait ici."],
	&"mansion_scientist_2_defeated": ["Je n'étais pas prête."],
	&"mansion_scientist_3_after": ["Je me plais ici.\nOn y étudie au calme."],
	&"mansion_scientist_3_before": ["Cet endroit est idéal pour un labo."],
	&"mansion_scientist_3_defeated": ["Mes calculs étaient faux."],
	&"mansion_statue": ["Un interrupteur secret !\nL'actionner ?", "Pas encore."],
	&"mansion_statue_yes": ["Qui ne le ferait pas ?"],
	&"pewter_museum_reserve_amber": ["Chut ! Fais examiner le Vieil Ambre !"],
	&"pewter_museum_reserve_amber_give": ["Chut ! Je crois que cet ambre\ncontient l'ADN d'un Pokémon !", "Ce serait formidable de le ramener\nà la vie ! Mais mes collègues…", "Tiens, prends-le. Fais-le examiner."],
	&"pewter_museum_reserve_counter": ["On n'entre pas par-derrière !\nBon, tant pis. Tu sais ce qu'est l'ambre ?", "Il paraît qu'un labo essaie de\nfaire revivre des Pokémon avec.", "C'est de la sève d'arbre fossilisée."],
	&"pewter_museum_reserve_showcase": ["L'ambre est clair et doré."],
	&"pewter_museum_tree": ["Un petit arbre pousse devant une porte.", "Sans le Badge Cascade, {pokemon}\nn'ose pas couper cet arbuste.", "Aucun Pokémon de l'équipe\nne peut couper cet arbuste.", "{pokemon} peut couper cet arbuste.", "Utiliser Coupe ?"],
}
## Jalon 10 : textes verrouillés du dossier 12 (même forme que le dossier 10) et lot de textes du
## J10 (panneaux, noms affichés), où un retour à la ligne est écrit « \n ».
const DOSSIER_12 := "res://docs/design/dossier-12-argenta.md"
const LOT_J10 := "res://docs/design/textes/textes-brouillon-j10.md"
## Jalon 11 : textes du §13 (« « … » » par ligne).
const DOSSIER_14 := "res://docs/design/dossier-14-systemes-j11.md"
## Jalon 14 (T17) : textes validés du dossier 17 §15 (« {joueur} » = jeton {player}) et annexe A
## du plan (A-8, console après le retour de Léo).
const DOSSIER_17 := "res://docs/design/dossier-17-cap-azuria.md"
const PLAN_J14 := "res://docs/tech/jalon-14.md"
## Jalon 15 : textes validés du §15 (« … » par page ; jetons écrits tels quels).
const DOSSIER_18 := "res://docs/design/dossier-18-carmin-sur-mer.md"
## Jalon 24 (T4) : répliques des Dresseurs des Routes 19 à 21 (§15.4, validé le 2026-10-16).
const DOSSIER_27 := "res://docs/design/dossier-27-iles-ecume.md"
## Jalon 18 (T16) : lot validé du dossier 21 §15 et annexe A du plan (une bulle = un morceau d'une
## citation ; retour à la ligne = espace, ou « / » d'un panneau à titre).
const DOSSIER_21 := "res://docs/design/dossier-21-grotte-sombre-lavanville.md"
const PLAN_J18 := "res://docs/tech/jalon-18.md"
## Jalon 15 : annexe A de son plan, validée le 2026-10-14 (panneaux A.3, personnages A.4 ; une
## page peut ne porter qu'un morceau de la citation, comme pour le dossier 18).
const JALON_15 := "res://docs/tech/jalon-15.md"
const AnnexATexts := preload("res://tests/unit/test_annex_a_texts.gd")
## Jalon 13 : lot de textes du dossier 16 §21 (« « … » / « … » » par numéro, lignes repliées).
const DOSSIER_16 := "res://docs/design/dossier-16-azuria.md"
## Jalon 12 : lot de textes du §20 du dossier 15 (« n. Libellé : « … » »).
const DOSSIER_15 := "res://docs/design/dossier-15-route-3-mont-selenite.md"
## Jalon 8 : textes T1–T16 validés (dossier 11, « Textes à valider ») ; dans son tableau, « / »
## marque le retour à la ligne de la bulle et le gras (« ** ») le titre d'un panneau.
const DOSSIER_11 := "res://docs/design/dossier-11-route-2.md"
## Jalon 17 (T8) : lot de textes validé du dossier 20 §16 (« / » entre deux bulles, « ** » le
## titre d'un panneau ; jetons {n}, {reste}) et annexe A de son plan (accord à 1 espèce, Q-2).
## Jalon 19 (T14) : lot de textes du dossier 22 §15 (Exorcistes §15.4, SPECTRE §15.3, §15.7).
const DOSSIER_22 := "res://docs/design/dossier-22-tour-pokemon.md"
## Jalon 21 (T12 à T14) : textes du dossier 24 §15 (Tour résolue, Fuji, Lavanville après le sauvetage).
const DOSSIER_24 := "res://docs/design/dossier-24-repos-des-esprits.md"
const DOSSIER_20 := "res://docs/design/dossier-20-chemins-retrouves.md"
const JALON_17 := "res://docs/tech/jalon-17.md"
const _DOSSIER_TOKENS: Dictionary[String, String] = {"{first_wild_species}": "{espèce}",
	"{player}": "{joueur}"}
const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
	&"route_1", &"route_22", &"viridian_city", &"viridian_center", &"viridian_mart",
	&"route_2",
	# Jalon 9 (T19) : la Forêt de Jade et ses deux postes.
	&"viridian_forest", &"viridian_forest_gate_south", &"viridian_forest_gate_north",
	# Jalon 10 (T13) : les intérieurs d'Argenta.
	&"pewter_center", &"pewter_mart", &"pewter_museum", &"pewter_museum_science", &"pewter_gym",
	&"pewter_house_mason", &"pewter_house_researcher",
	# Jalon 10 (T11) : la Route 2 nord et Argenta (extérieur).
	&"route_2_north", &"pewter_city",
	# Jalon 12 (T18) : la Route 3 et le Centre du Mont Sélénite.
	&"route_3", &"mt_moon_center",
	# Jalon 12 (T21) : le Mont Sélénite (1F, B1F) ; B2F au T25 (Rocket, chercheur, fossiles).
	&"mt_moon_1f", &"mt_moon_b1f", &"mt_moon_b2f",
	# Jalon 13 (T17) : Routes 4 (panneau du sas du J12 T28 compris) et 24, Azuria et ses
	# intérieurs.
	&"route_4", &"route_24", &"cerulean_city", &"cerulean_center", &"cerulean_mart",
	&"cerulean_gym", &"cerulean_bike_shop", &"cerulean_house", &"cerulean_burgled_house",
	# Jalon 14 (T17) : la maison de Léo.
	&"bill_house",
	# Jalon 14 (T16) : la Route 25.
	&"route_25",
	# Jalon 15 (T18, T19) : le passage souterrain (passant T-18, indice T-19).
	&"underground_path",
	# Jalon 15 (T14) : la Route 6, Carmin-sur-Mer et ses intérieurs.
	&"route_6", &"route_6_underground_gate", &"vermilion_city", &"vermilion_center",
	&"vermilion_mart", &"vermilion_fan_club", &"vermilion_fisher_house", &"vermilion_house_1",
	&"vermilion_house_2",
	# Jalon 15 (T13) : la Route 5, la Pension, le poste nord et l'entrée du souterrain.
	&"route_5", &"route_5_daycare", &"route_5_gate", &"route_5_underground_gate",
	# Jalon 17 (T16, T17) : la Route 11 (Dresseurs, objets, panneaux, Ronflex).
	&"route_11",
	# Jalon 17 (T15) : la Cave Taupiqueur (Corde Sortie du renfoncement, posée à l'intégration).
	&"digletts_cave",
	# Jalon 17 (T19) : le couloir de la Route 2 est et le poste de l'assistant.
	&"route_2_east", &"route_2_east_gate",
	# Jalon 16 (T11) : l'Arène de Carmin (puzzle et barrière ; Major Bob et les siens au T14).
	&"vermilion_gym",
	# Jalon 16 (T12) : la vie du navire (les 7 cartes à fouler ; couloir et cabine du capitaine = T13).
	&"ss_anne_main_deck", &"ss_anne_lower_deck", &"ss_anne_restaurant", &"ss_anne_outer_deck",
	&"ss_anne_cabin_a", &"ss_anne_cabin_b", &"ss_anne_cabin_c",
	# Jalon 16 (T13) : le couloir du rival n° 4 et la cabine du capitaine.
	&"ss_anne_captain_corridor", &"ss_anne_captain_room",
	# Jalon 16 (T15) : `ss_anne_main_deck` (passerelle, départ) est déjà dans la liste (T12).
	# Jalon 18 (T16) : PNJ, Dresseurs et objets en données sur les cartes du T12 au T14.
	&"route_9", &"route_10", &"route_10_center", &"dark_cave_1f", &"dark_cave_b1f",
	&"lavender_town", &"lavender_center", &"lavender_mart", &"pokemon_house",
	&"lavender_house_1", &"lavender_house_2", &"pokemon_tower_1f",
	&"pokemon_tower_3f", &"pokemon_tower_4f", &"pokemon_tower_5f", &"pokemon_tower_6f",
	# Jalon 20 (T16) : Céladopole (panneaux, examens, arbustes ; la vie vient au T17).
	&"celadon_city", &"celadon_dept_gf", &"celadon_dept_elevator", &"celadon_mansion_3f",
	&"celadon_gym",
	# Jalon 20 (T20) : Casino (machines) et cabine du repaire (panneau d'étages).
	&"celadon_game_corner", &"rocket_hideout_elevator",
	# Jalon 19 (T17) : le rival n° 5 et l'Exorciste calme du 2F.
	&"pokemon_tower_2f",
	# Jalon 20 (T15) : Routes 7 et 8, postes, bâtiments d'entrée, souterrain (panneaux).
	&"route_8", &"route_7", &"route_7_gate", &"route_8_gate", &"route_7_underground_gate",
	&"route_8_underground_gate", &"underground_path_7_8",
	# Jalon 20 (T17) : la vie de Céladopole (Centre, grand magasin, Résidence, maisons, Arène).
	&"celadon_center", &"celadon_dept_2f", &"celadon_dept_3f", &"celadon_dept_4f",
	&"celadon_dept_5f", &"celadon_dept_roof", &"celadon_mansion_gf", &"celadon_mansion_1f",
	&"celadon_mansion_2f", &"celadon_mansion_roof", &"celadon_mansion_roof_house",
	&"celadon_restaurant", &"celadon_chief_house", &"celadon_hotel",
	# Jalon 20 (T21) : la vie du 20-II (Casino déjà listé ; repaire Rocket B1F à B4F).
	&"rocket_hideout_b1f", &"rocket_hideout_b2f", &"rocket_hideout_b3f", &"rocket_hideout_b4f",
	# Jalon 24 : la mer, les Îles Écume, Cramois'Île et son Labo.
	&"route_19", &"route_20", &"route_21", &"seafoam_1f", &"seafoam_b1f", &"seafoam_b2f",
	&"seafoam_b3f", &"seafoam_b4f", &"cinnabar_island", &"cinnabar_center", &"cinnabar_mart",
	&"cinnabar_lab", &"cinnabar_lab_meeting", &"cinnabar_lab_rd", &"cinnabar_lab_fossil",
	# Jalon 25 : Manoir, Arène, réserve du Musée.
	&"pokemon_mansion_1f", &"pokemon_mansion_2f", &"pokemon_mansion_3f", &"pokemon_mansion_b1f",
	&"cinnabar_gym", &"pewter_museum_reserve",
	# Jalon 21 (T13) : le 7F (Sbires, M. Fuji).
	&"pokemon_tower_7f",
	# Jalon 21 (T22) : la Route 16 est (Ronflex ; aucun autre texte).
	&"route_16",
	# Jalon 21 (T21) : la Route 12 (panneaux, Pêcheurs, Ronflex) et le 2F du poste (CT39).
	&"route_12", &"route_12_gate_2f",
]
## Jalon 21 (T22) : dialogues de Ronflex de la Route 16 (`j21_snorlax_16.json`, dossier 24 §15.6-§15.7).
## Les répliques communes (flûte jouée, réveil, calme, rendormi) sont celles de `j21_snorlax.json`.
const IDS_J21_T22: Array[StringName] = [&"snorlax_route_16"]
## Jalon 21 (T22) : textes validés (dossier 24 §15.6.3, §15.7 ; T-6 et T-7 du J17), page par page.
const TEXTS_J21_T22: Dictionary[StringName, Array] = {
	&"snorlax_route_16": ["Ronflex dort de nouveau.", "Il ronfle comme si de rien n'était.",
		"Jouer de la Poké Flûte ?", "Un énorme Pokémon dort au milieu du chemin.",
		"Il ne bouge pas d'un pouce.", "Il ronfle paisiblement.",
		"Rien ne semble pouvoir le réveiller."],
}
## Jalon 21 (T22) : jouées par la scène `snorlax_route_16_wake` (le premier est lu par le point).
const PLAYED_J21_T22: Array[StringName] = []
## Lot de textes validé par Kevin le 2026-10-06 (anciens brouillons : panneau, observations,
## soin de Maman, terminal du Stockage, portes de Jadielle…) : source des textes hors dossiers.
const TEXTES_VALIDES := "res://docs/design/textes/textes-brouillon-j7.md"
## Identifiants attendus (3A) : Maman, table, rival, carte, Maya, 3 starters, 3 habitants,
## panneau ; (3B) « Hé ! Attends ! », les répliques du Prof. Chen et la pensée des herbes ;
## (4A, T1) la proposition du Prof. Chen ; (4A, T3) le choix et la sortie empêchée.
const IDS: Array[StringName] = [
	&"aoki", &"breakfast_table", &"clerk", &"clerk_parcel",
	&"clerk_parcel_hello",
	# Jalon 13 (T17) : Azuria, Route 4 et Route 24 (dossier 16 §21).
	&"cerulean_bike_clerk",
	&"cerulean_burgled_door",
	&"cerulean_city_sign",
	&"cerulean_closed_exit",
	&"cerulean_gym_diane_after",
	&"cerulean_gym_diane_before",
	&"cerulean_gym_guide",
	&"cerulean_gym_lucas_after",
	&"cerulean_gym_lucas_before",
	&"cerulean_gym_sign",
	&"cerulean_h1_fisher",
	&"cerulean_h2_kid",
	&"cerulean_h3_neighbor",
	&"cerulean_h4_policeman",
	&"cerulean_h5_swimmer",
	&"cerulean_h6_trainer",
	&"cerulean_h7_resident",
	&"cerulean_house_resident",
	&"cerulean_torn_fence",
	&"route_24_ball_1",
	&"route_24_bridge_sign",
	# Jalon 13 (T17) : Clara. (T22) : les cinq Dresseurs du pont, le recruteur, l'Antidote caché.
	&"route_4_clara_before", &"route_4_clara_defeated", &"route_4_clara_after",
	&"route_24_timeo_before", &"route_24_timeo_after", &"route_24_alice_before",
	&"route_24_alice_after", &"route_24_malo_before", &"route_24_malo_after",
	&"route_24_romane_before", &"route_24_romane_after", &"route_24_ethan_before",
	&"route_24_ethan_after", &"nugget_rocket", &"nugget_rocket_welcome", &"nugget_rocket_given",
	&"nugget_rocket_offer", &"nugget_rocket_yes", &"nugget_rocket_no", &"nugget_rocket_beaten",
	&"nugget_rocket_lost", &"nugget_rocket_resume", &"route_24_antidote",
	# Jalon 13 (T19) : le rival n° 3, Ondine au pont et à l'Arène.
	&"rival_cerulean_intro", &"rival_cerulean_lost", &"rival_cerulean_resume",
	&"rival_cerulean_resume_again", &"rival_cerulean_won", &"misty_bridge",
	&"misty_bridge_invite", &"cerulean_gym_misty", &"cerulean_gym_misty_intro",
	&"cerulean_gym_misty_lost", &"cerulean_gym_misty_resume", &"cerulean_gym_misty_won",
	&"cerulean_gym_misty_badge", &"cerulean_gym_misty_tm", &"cerulean_gym_misty_tm_use",
	&"cerulean_gym_misty_tm_late",
	&"route_4_ball_1",
	# Jalon 11 (T20c) : phrases du compagnon (dossier 14 §13.12) ; grotte (jalon 12, T20).
	&"companion_cave", &"companion_city", &"companion_forest", &"companion_happy",
	&"companion_sniff", &"companion_stretch", &"companion_stretch_soft", &"companion_tired",
	&"companion_tired_f", &"companion_unwell", &"companion_watch", &"companion_water",
	# Jalon 15 (T4) : la Pension (dossier 18 §15.1).
	&"daycare_after", &"daycare_deposited", &"daycare_keeper", &"daycare_last_able",
	&"daycare_offer", &"daycare_party_full", &"daycare_pick", &"daycare_returned",
	&"daycare_returned_short", &"daycare_visit", &"daycare_visit_levels",
	# Jalon 12 (T20) : narration de la Corde Sortie, jouée par Boot.
	&"escape_rope_used",
	&"forest_gate_north_guard", &"forest_gate_south_guard",
	&"forest_hiker", &"forest_naturalist",
	&"forest_scout_eli_after", &"forest_scout_eli_before", &"forest_scout_milo_after",
	&"forest_scout_milo_before", &"forest_scout_noe_after", &"forest_scout_noe_before",
	&"forest_scout_theo_after", &"forest_scout_theo_before", &"forest_youngster_tom_after",
	&"forest_youngster_tom_before",
	&"haru", &"maya", &"mom", &"nils",
	&"mom_wakeup",
	# Jalon 12 (T21) : la vie du Mont Sélénite (dossier 15 §20 n° 12–15, objets).
	&"mt_moon_1f_ball_1", &"mt_moon_1f_crate", &"mt_moon_1f_hidden_1", &"mt_moon_1f_hiker",
	&"mt_moon_1f_lamp", &"mt_moon_1f_sign", &"mt_moon_b1f_ball_1", &"mt_moon_b1f_ball_2",
	# Jalon 12 (T25) : Team Rocket, chercheur, fossiles, CT01, Pierre Lune cachée (§20 n° 16–26).
	&"mt_moon_b2f_ball_1", &"mt_moon_b2f_hidden_1", &"mt_moon_fossil_dome",
	&"mt_moon_fossil_helix", &"mt_moon_researcher_before", &"mt_moon_researcher_chosen",
	&"mt_moon_researcher_defeated", &"mt_moon_researcher_guard", &"mt_moon_researcher_rematch",
	&"mt_moon_researcher_share", &"mt_moon_researcher_talk", &"mt_moon_rocket_1_before",
	&"mt_moon_rocket_1_defeated", &"mt_moon_rocket_1_rematch", &"mt_moon_rocket_2_before",
	&"mt_moon_rocket_2_defeated", &"mt_moon_rocket_2_rematch", &"mt_moon_rocket_3_before",
	&"mt_moon_rocket_3_defeated", &"mt_moon_rocket_3_rematch",
	&"nurse", &"nurse_wakeup",
	&"oak_after_battle",
	&"oak_lab_exit_block", &"oak_lab_reunion", &"oak_lab_waiting", &"oak_parcel_records",
	&"oak_parcel_rival", &"oak_parcel_rival_dex", &"oak_poke_balls", &"oak_poke_balls_intro",
	&"oak_pokedex_activated", &"oak_route1_call", &"oak_route1_warning", &"oak_starter_offer",
	&"oak_starter_reciprocal", &"observe_aoki_pidgey", &"observe_bulbasaur",
	&"observe_charmander", &"observe_nils_rattata", &"observe_squirtle",
	# Jalon 10 (T8) : Argenta (dossier 12, lot du J10).
	&"pewter_city_sign", &"pewter_gym_brock", &"pewter_gym_brock_badge", &"pewter_gym_brock_intro",
	&"pewter_gym_brock_lost", &"pewter_gym_brock_resume", &"pewter_gym_brock_tm",
	&"pewter_gym_brock_tm_late", &"pewter_gym_brock_tm_use", &"pewter_gym_brock_won",
	&"pewter_gym_guide", &"pewter_gym_liam_after", &"pewter_gym_liam_before",
	&"pewter_gym_liam_defeated", &"pewter_gym_sign", &"pewter_house_mason_kid",
	&"pewter_house_mason_partner", &"pewter_house_researcher", &"pewter_kid", &"pewter_lass",
	&"pewter_museum_clerk", &"pewter_museum_dome", &"pewter_museum_helix", &"pewter_museum_journal",
	&"pewter_museum_lab_door", &"pewter_museum_lab_sign", &"pewter_museum_moon_stone",
	&"pewter_museum_researcher", &"pewter_museum_researcher_f", &"pewter_museum_science_panel",
	&"pewter_museum_sign", &"pewter_old_man", &"pewter_route_3_guard",
	&"pewter_route_3_guard_cleared", &"pewter_route_3_guard_rule", &"pewter_stonemason",
	&"pewter_visitor",
	# DA.2 : le chercheur de Bourg Palette (réplique validée par Kevin, dossier-02 §4).
	&"researcher",
	&"rival", &"rival_challenge", &"rival_challenge_wait", &"rival_kanto_map",
	&"rival_lab_lost", &"rival_lab_waiting", &"rival_lab_won", &"rival_lab_won_leaving",
	&"rival_parcel_greet", &"rival_parcel_leaving", &"rival_parcel_return",
	&"rival_starter_pick", &"rival_starter_smile", &"route1_grass_thought",
	&"route22_rival_greet", &"route22_rival_hesitates", &"route22_rival_lost",
	&"route22_rival_won", &"route22_youngster_sigh",
	&"route_1_potion_found", &"route_1_traveler", &"route_22_traveler",
	# Jalon 8 : la Route 2 (dossier 11, T1 à T11).
	&"route_2_ball_1", &"route_2_ball_2", &"route_2_closed_gate", &"route_2_closed_sign",
	&"route_2_dense_tree", &"route_2_forest_sign", &"route_2_hiker", &"route_2_item_3_found",
	&"route_2_item_4_found",
	# Jalon 10 (T8) : la Route 2 nord.
	&"route_2_north_ball_1", &"route_2_north_mountaineer", &"route_2_north_rockslide",
	&"route_2_north_sign",
	&"route_2_sign", &"route_2_youngster",
	# Jalon 12 (T18) : la vie de la Route 3 (dossier 15 §20 n° 1–11, panneaux, objets).
	&"route_3_enzo_after", &"route_3_enzo_before", &"route_3_hidden_1", &"route_3_hiker",
	&"route_3_hugo_after", &"route_3_hugo_before", &"route_3_ines_after", &"route_3_ines_before",
	&"route_3_item_1", &"route_3_item_2", &"route_3_item_3", &"route_3_lea_after",
	&"route_3_lea_before", &"route_3_nolan_after", &"route_3_nolan_before",
	&"route_3_sacha_after", &"route_3_sacha_before", &"route_3_sign_center",
	&"route_3_sign_west", &"route_3_traveler",
	# Jalon 12 (T28) : le panneau du sas de la Route 4 (dossier 15 §20 n° 36).
	&"route_4_sign",
	# Jalon 15 (T12) : Dresseurs de la Route 6 (dossier 18 §15.5).
	&"route_6_camper_gabin_after", &"route_6_camper_gabin_before",
	&"route_6_camper_gabin_defeated", &"route_6_camper_mathis_after",
	&"route_6_camper_mathis_before", &"route_6_camper_mathis_defeated",
	&"route_6_lass_chloe_after", &"route_6_lass_chloe_before", &"route_6_lass_chloe_defeated",
	&"route_6_lass_manon_after", &"route_6_lass_manon_before", &"route_6_lass_manon_defeated",
	&"route_6_scout_axel_after", &"route_6_scout_axel_before", &"route_6_scout_axel_defeated",
	&"route_6_scout_basile_after", &"route_6_scout_basile_before",
	&"route_6_scout_basile_defeated",
	&"sign_pallet_town",
	&"storage_terminal",
	# Jalon 15 (T18, T19) : passant et pierre descellée du souterrain.
	&"underground_hidden_1", &"underground_hidden_1_found", &"underground_passer",
	&"viridian_courier",
	# Jalon 9 (T18) : objets de la Forêt de Jade.
	&"viridian_forest_item_1", &"viridian_forest_item_2", &"viridian_forest_item_3_found",
	&"viridian_forest_item_4_found", &"viridian_forest_item_5", &"viridian_forest_item_6_found",
	&"viridian_gym_door", &"viridian_gym_watcher", &"viridian_house_door",
	&"viridian_kid",
	&"viridian_lass", &"viridian_old_man", &"viridian_traveler",
	# Jalon 14 (T16) : la Route 25 (dossier 17 §15 n° 42 à 51).
	&"route_25_hidden_1", &"route_25_hidden_1_found", &"route_25_hiker_bernard_after",
	&"route_25_hiker_bernard_before", &"route_25_hiker_bernard_defeated",
	&"route_25_hiker_gaston_after", &"route_25_hiker_gaston_before",
	&"route_25_hiker_gaston_defeated", &"route_25_item_1", &"route_25_item_2", &"route_25_item_3",
	&"route_25_jr_trainer_adam_after", &"route_25_jr_trainer_adam_before",
	&"route_25_jr_trainer_adam_defeated", &"route_25_lass_zoe_after", &"route_25_lass_zoe_before",
	&"route_25_lass_zoe_defeated", &"route_25_old_man", &"route_25_sign_cape",
	&"route_25_sign_west", &"route_25_traveler", &"route_25_youngster_jules_after",
	&"route_25_youngster_jules_before", &"route_25_youngster_jules_defeated",
	&"route_25_youngster_yanis_after", &"route_25_youngster_yanis_before",
	&"route_25_youngster_yanis_defeated",
	# Jalon 15 (T14) : Route 6 et Carmin-sur-Mer (dossier 18 §15, annexe A du plan).
	&"route_6_sign", &"route_6_gate_sign", &"route_6_underground_gate_sign", &"route_6_guard",
	&"route_6_fisher", &"route_6_walker", &"route_6_item_1", &"route_6_hidden_1",
	&"vermilion_city_sign", &"vermilion_gym_sign", &"vermilion_dock_sign",
	&"vermilion_sailor", &"vermilion_docker_1", &"vermilion_docker_2", &"vermilion_old_man",
	&"vermilion_resident", &"vermilion_kid", &"vermilion_fan_club_chairman",
	&"vermilion_fan_club_member", &"vermilion_fan_club_member_2", &"vermilion_fisher",
	&"vermilion_house_1_resident", &"vermilion_house_2_resident",
]
## Jalon 17 (T8) : Route 11, Route 2 est (assistant, visiteur, panneau), barrière de FUTUR B vue
## de l'est (route_2.json) ; T24 : avertissement sans Flash (dark_caves.json).
const IDS_J17: Array[StringName] = [
	&"dark_cave_too_dark",
	&"route_11_sign", &"route_11_cave_sign",
	&"route_11_youngster_lucas_before", &"route_11_youngster_lucas_defeated",
	&"route_11_youngster_lucas_after", &"route_11_youngster_arthur_before",
	&"route_11_youngster_arthur_defeated", &"route_11_youngster_arthur_after",
	&"route_11_youngster_louis_before", &"route_11_youngster_louis_defeated",
	&"route_11_youngster_louis_after", &"route_11_youngster_raphael_before",
	&"route_11_youngster_raphael_defeated", &"route_11_youngster_raphael_after",
	&"route_11_gambler_marcel_before", &"route_11_gambler_marcel_defeated",
	&"route_11_gambler_marcel_after", &"route_11_gambler_roger_before",
	&"route_11_gambler_roger_defeated", &"route_11_gambler_roger_after",
	&"route_11_engineer_bruno_before", &"route_11_engineer_bruno_defeated",
	&"route_11_engineer_bruno_after", &"route_11_engineer_victor_before",
	&"route_11_engineer_victor_defeated", &"route_11_engineer_victor_after",
	&"route_11_item_1", &"route_11_item_2", &"route_11_hidden_1",
	&"route_2_east_cave_sign", &"route_2_east_assistant", &"route_2_east_assistant_hm05_system",
	&"route_2_east_assistant_hm05_use", &"route_2_east_visitor", &"route_2_gate_east",
	&"route_2_east_item_1", &"route_2_east_item_2", &"route_2_item_5", &"digletts_cave_item_1",
	# T23 : examen de l'arbuste du couloir (Coupe du J16).
	&"route_2_east_bush",
	# Raccords J21 ↔ J22 (2026-10-23) : examen de l'arbre de la Route 16 (mêmes textes).
	&"route_16_tree",
]
## Jalon 14 (T17, dossier 17 §15 n° 1 à 27) : dialogues de la maison de Léo, ajoutés aux autres.
const IDS_J14_BILL: Array[StringName] = [
	&"bill", &"bill_candy_offer", &"bill_clefairy", &"bill_console", &"bill_give_candy",
	&"bill_give_ticket", &"bill_greet", &"bill_module", &"bill_module_next", &"bill_ready",
	&"bill_screen", &"bill_screen_next", &"bill_ss_anne", &"bill_thanks",
]
## Jalon 14 (T20b, dossier 17 §15 n° 29 à 41) : le Rocket d'Azuria, la victime, le barrage sud.
const IDS_J14_ROCKET: Array[StringName] = [
	&"cerulean_fence_hole", &"cerulean_rocket", &"cerulean_rocket_beaten",
	&"cerulean_rocket_before", &"cerulean_rocket_leaving", &"cerulean_rocket_resume",
	&"cerulean_rocket_spotted", &"cerulean_rocket_tm", &"cerulean_south_guard",
	&"cerulean_south_guard_leaving", &"cerulean_victim",
]
## Jalon 24 (T4) : répliques des 29 Dresseurs des Routes 19 à 21 (dossier 27 §15.4), en
## attente de leurs cartes (T8, T11) : exemptées de « utilisé par un PNJ » jusque-là.
## Jalon 24 (T8, T11 à T15, T18) : panneaux, PNJ et scènes de la mer, des Îles Écume et de
## Cramois'Île (textes du dossier 27 §15, validés par Kevin le 2026-10-16 ; adaptations de mise en
## page et répliques de don, recommandées, validées d'avance le 2026-10-21).
const IDS_J24: Array[StringName] = [
	&"articuno", &"articuno_cry", &"articuno_flew_away", &"cinnabar_center_cooltrainer",
	&"cinnabar_center_gentleman", &"cinnabar_fossil_ready_kabuto", &"cinnabar_fossil_ready_omanyte",
	&"cinnabar_fossil_received_kabuto", &"cinnabar_fossil_received_omanyte",
	&"cinnabar_fossil_scientist", &"cinnabar_fossil_stored_kabuto",
	&"cinnabar_fossil_stored_omanyte", &"cinnabar_fossil_taken", &"cinnabar_girl",
	&"cinnabar_gym_locked", &"cinnabar_gym_sign", &"cinnabar_lab_eevee", &"cinnabar_lab_expert",
	# J25 : les répliques du Labo (canon, gramps, seel) et l'éboulis du Manoir sont remplacées par
	# les échanges et la porte du Manoir.
	&"cinnabar_lab_pc",
	&"cinnabar_lab_photo", &"cinnabar_lab_tm35", &"cinnabar_lab_tm35_offer",
	&"cinnabar_lab_tm35_use", &"cinnabar_man", &"cinnabar_mart_scientist",
	&"cinnabar_mart_silph_worker", &"cinnabar_sign", &"route_19_sign", &"route_20_item_1",
	&"route_20_sign", &"route_21_item_1", &"seafoam_b2f_hidden_1", &"seafoam_b4f_hidden_1",
	&"seafoam_sign_boulders", &"seafoam_sign_currents", &"seafoam_sign_danger"
]
const IDS_J24_TRAINERS: Array[StringName] = [
	&"route_19_cooltrainer_hugo_after", &"route_19_cooltrainer_hugo_before",
	&"route_19_cooltrainer_hugo_defeated", &"route_19_cooltrainer_malo_after",
	&"route_19_cooltrainer_malo_before", &"route_19_cooltrainer_malo_defeated",
	&"route_19_swimmer_anais_after", &"route_19_swimmer_anais_before",
	&"route_19_swimmer_anais_defeated", &"route_19_swimmer_erwan_after",
	&"route_19_swimmer_erwan_before", &"route_19_swimmer_erwan_defeated",
	&"route_19_swimmer_gwen_after", &"route_19_swimmer_gwen_before",
	&"route_19_swimmer_gwen_defeated", &"route_19_swimmer_lena_after",
	&"route_19_swimmer_lena_before", &"route_19_swimmer_lena_defeated",
	&"route_19_swimmer_loic_after", &"route_19_swimmer_loic_before",
	&"route_19_swimmer_loic_defeated", &"route_19_swimmer_maelle_after",
	&"route_19_swimmer_maelle_before", &"route_19_swimmer_maelle_defeated",
	&"route_19_swimmer_tanguy_after", &"route_19_swimmer_tanguy_before",
	&"route_19_swimmer_tanguy_defeated", &"route_19_swimmer_yann_after",
	&"route_19_swimmer_yann_before", &"route_19_swimmer_yann_defeated",
	&"route_20_bird_keeper_bastien_after", &"route_20_bird_keeper_bastien_before",
	&"route_20_bird_keeper_bastien_defeated", &"route_20_swimmer_clara_after",
	&"route_20_swimmer_clara_before", &"route_20_swimmer_clara_defeated",
	&"route_20_swimmer_elsa_after", &"route_20_swimmer_elsa_before",
	&"route_20_swimmer_elsa_defeated", &"route_20_swimmer_iris_after",
	&"route_20_swimmer_iris_before", &"route_20_swimmer_iris_defeated",
	&"route_20_swimmer_kilian_after", &"route_20_swimmer_kilian_before",
	&"route_20_swimmer_kilian_defeated", &"route_20_swimmer_lou_after",
	&"route_20_swimmer_lou_before", &"route_20_swimmer_lou_defeated",
	&"route_20_swimmer_mathis_after", &"route_20_swimmer_mathis_before",
	&"route_20_swimmer_mathis_defeated", &"route_20_swimmer_nina_after",
	&"route_20_swimmer_nina_before", &"route_20_swimmer_nina_defeated",
	&"route_20_swimmer_ronan_after", &"route_20_swimmer_ronan_before",
	&"route_20_swimmer_ronan_defeated", &"route_20_swimmer_solene_after",
	&"route_20_swimmer_solene_before", &"route_20_swimmer_solene_defeated",
	&"route_21_fisher_gilles_after", &"route_21_fisher_gilles_before",
	&"route_21_fisher_gilles_defeated", &"route_21_fisher_marcel_after",
	&"route_21_fisher_marcel_before", &"route_21_fisher_marcel_defeated",
	&"route_21_fisher_rene_after", &"route_21_fisher_rene_before",
	&"route_21_fisher_rene_defeated", &"route_21_fisher_yves_after",
	&"route_21_fisher_yves_before", &"route_21_fisher_yves_defeated",
	&"route_21_swimmer_arthur_after", &"route_21_swimmer_arthur_before",
	&"route_21_swimmer_arthur_defeated", &"route_21_swimmer_dylan_after",
	&"route_21_swimmer_dylan_before", &"route_21_swimmer_dylan_defeated",
	&"route_21_swimmer_noe_after", &"route_21_swimmer_noe_before",
	&"route_21_swimmer_noe_defeated", &"route_21_swimmer_simon_after",
	&"route_21_swimmer_simon_before", &"route_21_swimmer_simon_defeated",
	&"route_21_swimmer_thibault_after", &"route_21_swimmer_thibault_before",
	&"route_21_swimmer_thibault_defeated",
]
## Jalon 15 (T13) : la Route 5 et ses intérieurs (dossier 18 §15.2, annexe A.3).
const IDS_J15_ROUTE_5: Array[StringName] = [
	&"route_5_crossroads_sign", &"route_5_daycare_sign", &"route_5_guard", &"route_5_hidden_1",
	&"route_5_item_1", &"route_5_sign", &"route_5_traveler", &"route_5_underground_sign",
	&"route_5_walker",
]
## Jalon 16 (T11) : le puzzle de l'Arène de Carmin (dossier 19 §0.5 n° 32 à 35).
const IDS_J16_GYM: Array[StringName] = [
	&"vermilion_gym_switch_first", &"vermilion_gym_switch_reset", &"vermilion_gym_switch_solved",
	&"vermilion_gym_trash",
	# Jalon 16 (T14) : guide, Louis, Axel, Marc, Major Bob (dossier 19 §0.5 n° 31, 36 à 44, §4).
	&"vermilion_gym_guide", &"vermilion_gym_louis_before", &"vermilion_gym_louis_defeated",
	&"vermilion_gym_louis_rematch", &"vermilion_gym_axel_before", &"vermilion_gym_axel_defeated",
	&"vermilion_gym_axel_rematch", &"vermilion_gym_marc_before", &"vermilion_gym_marc_defeated",
	&"vermilion_gym_marc_rematch", &"vermilion_gym_surge", &"vermilion_gym_surge_intro",
	&"vermilion_gym_surge_lost", &"vermilion_gym_surge_resume", &"vermilion_gym_surge_won",
	&"vermilion_gym_surge_badge", &"vermilion_gym_surge_tm", &"vermilion_gym_surge_tm_use",
	&"vermilion_gym_surge_tm_late",
]
## Jalon 16 (T12) : la vie du navire (dossier 19 §0.5 n° 10 à 15, §4 ; objets du plan).
const IDS_J16_SHIP: Array[StringName] = [
	&"ss_anne_armand_after", &"ss_anne_armand_before", &"ss_anne_armand_defeated",
	&"ss_anne_basile_after", &"ss_anne_basile_before", &"ss_anne_basile_defeated",
	&"ss_anne_deck_passenger", &"ss_anne_deckhand", &"ss_anne_diner", &"ss_anne_emile_after",
	&"ss_anne_emile_before", &"ss_anne_emile_defeated", &"ss_anne_erwan_after",
	&"ss_anne_erwan_before", &"ss_anne_erwan_defeated", &"ss_anne_gangway_sailor",
	&"ss_anne_hidden_1", &"ss_anne_hidden_2", &"ss_anne_hidden_3", &"ss_anne_hostess",
	&"ss_anne_item_01", &"ss_anne_item_02", &"ss_anne_item_03", &"ss_anne_item_04",
	&"ss_anne_item_05", &"ss_anne_item_06", &"ss_anne_lena_after", &"ss_anne_lena_before",
	&"ss_anne_lena_defeated", &"ss_anne_loic_after", &"ss_anne_loic_before",
	&"ss_anne_loic_defeated", &"ss_anne_passenger", &"ss_anne_paul_after", &"ss_anne_paul_before",
	&"ss_anne_paul_defeated", &"ss_anne_remi_after", &"ss_anne_remi_before",
	&"ss_anne_remi_defeated", &"ss_anne_victor_after", &"ss_anne_victor_before",
	&"ss_anne_victor_defeated", &"ss_anne_waiter", &"ss_anne_yann_after", &"ss_anne_yann_before",
	&"ss_anne_yann_defeated",
]
## Jalon 16 (T11) : GYM-03, dit par la scène de la barrière ouverte ; (T14) les répliques de
## Major Bob dites par ses scènes.
const PLAYED_J16_GYM: Array[StringName] = [&"vermilion_gym_switch_solved",
	&"vermilion_gym_surge_badge", &"vermilion_gym_surge_intro", &"vermilion_gym_surge_lost",
	&"vermilion_gym_surge_resume", &"vermilion_gym_surge_tm", &"vermilion_gym_surge_tm_late",
	&"vermilion_gym_surge_tm_use", &"vermilion_gym_surge_won"]
## Jalon 16 (T13) : le rival n° 4 et le capitaine (dossier 19 §0.5 n° 16 à 24).
const IDS_J16_RIVAL_CAPTAIN: Array[StringName] = [
	&"rival_ss_anne_intro", &"rival_ss_anne_lost", &"rival_ss_anne_resume", &"rival_ss_anne_won",
	&"ss_anne_captain", &"ss_anne_captain_gift", &"ss_anne_captain_gift_use",
	&"ss_anne_captain_relieved", &"ss_anne_captain_rub", &"ss_anne_captain_sick",
]
## Jalon 16 (T13) : tous joués par les scènes du rival et du capitaine, sauf CAP-04 (son PNJ).
const PLAYED_J16_RIVAL_CAPTAIN: Array[StringName] = [
	&"rival_ss_anne_intro", &"rival_ss_anne_lost", &"rival_ss_anne_resume", &"rival_ss_anne_won",
	&"ss_anne_captain_gift", &"ss_anne_captain_gift_use", &"ss_anne_captain_relieved",
	&"ss_anne_captain_rub", &"ss_anne_captain_sick",
]
## Jalon 16 (T15) : Coupe sur l'arbuste de l'Arène (examen `cut_tree` remplace
## `vermilion_gym_tree` du J15) et départ du S.S. Anne (dossier 19 §0.5 n° 3 à 7, 25 à 29).
const IDS_J16_T15: Array[StringName] = [
	&"cut_tree", &"cut_tree_used", &"ss_anne_departure_confirm",
]
## Jalon 16 (T15) : joués par les scènes du départ et de la coupe ; le marin de la passerelle
## (TXT-03, seule source du texte) l'est aussi par la sortie, avant la CS01.
const PLAYED_J16_T15: Array[StringName] = [
	&"cut_tree_used", &"ss_anne_departure_confirm", &"ss_anne_gangway_sailor",
]
## Jalon 16 : textes validés du dossier 19 (§0.5, « … » par ligne).
const DOSSIER_19 := "res://docs/design/dossier-19-ss-anne-major-bob.md"
## Jalon 18 (T16) : Route 9, Route 10, Grotte Sombre, Lavanville, Tour (dossier 21 §15, annexe A
## du plan ; mot pour mot : test_j18_data, test_trainers_j18).
## Jalon 20 (T15) : panneaux des Routes 7 et 8 (dossier 23 §20, textes 1, 2, 11).
const IDS_J20: Array[StringName] = [
	&"route_7_sign", &"route_7_underground_sign", &"route_8_sign", &"route_8_underground_sign",
	# T25 : garde des postes de Safrania et boisson donnée (annexe A.14 du plan, texte 12).
	&"saffron_gate_guard", &"saffron_gate_drink_water", &"saffron_gate_drink_soda",
	&"saffron_gate_drink_lemonade",
	# T12 : don d'Évoli (dossier 23 §20, textes 28 à 30).
	&"celadon_eevee_ball", &"celadon_eevee_received", &"celadon_eevee_stored",
	# T13 : panneau d'ascenseur (sans page) et refus sans la Clé (texte 50).
	&"elevator_panel", &"elevator_locked",
	# T16 : Céladopole (panneaux, examens, arbustes de Coupe, tableau et panneau d'ascenseur).
	&"celadon_city_sign", &"celadon_gym_sign", &"celadon_dept_board",
	&"celadon_mansion_office_door", &"celadon_gym_bush",
	&"celadon_gym_inner_bush",
	# T20 : machines du Casino (texte 39).
	&"game_corner_machine",
]
## Jalon 20 (T17) : la vie du 20-I (dossier 23 §20 et annexe A du plan, textes 3 à 10, 15 à 26,
## 32 à 38, 44, 61 à 129) ; un identifiant par dialogue des données.
const IDS_J20_T17: Array[StringName] = [
	&"celadon_casino_client", &"celadon_chief_man", &"celadon_chief_woman", &"celadon_clerk",
	&"celadon_cook", &"celadon_dept_2f_clerk", &"celadon_dept_2f_clerk_tm",
	&"celadon_dept_2f_customer_1", &"celadon_dept_2f_customer_2", &"celadon_dept_3f_gift_man",
	&"celadon_dept_3f_player_1", &"celadon_dept_3f_player_2", &"celadon_dept_4f_clerk",
	&"celadon_dept_4f_clerk_stones", &"celadon_dept_4f_customer", &"celadon_dept_5f_clerk",
	&"celadon_dept_5f_lounge_1", &"celadon_dept_5f_lounge_2", &"celadon_dept_gf_customer_1",
	&"celadon_dept_gf_customer_2", &"celadon_dept_hostess", &"celadon_dept_roof_lemonade",
	&"celadon_dept_roof_soda", &"celadon_dept_roof_water", &"celadon_fisherman",
	&"celadon_gardener_f", &"celadon_gardener_m", &"celadon_gym_beauty_violette_after",
	&"celadon_gym_beauty_violette_before", &"celadon_gym_beauty_violette_defeated",
	&"celadon_gym_cooltrainer_camelia_after", &"celadon_gym_cooltrainer_camelia_before",
	&"celadon_gym_cooltrainer_camelia_defeated", &"celadon_gym_erika", &"celadon_gym_erika_badge",
	&"celadon_gym_erika_intro", &"celadon_gym_erika_lost", &"celadon_gym_erika_resume",
	&"celadon_gym_erika_tm", &"celadon_gym_erika_tm_late", &"celadon_gym_erika_tm_use",
	&"celadon_gym_erika_won", &"celadon_gym_jr_trainer_apolline_after",
	&"celadon_gym_jr_trainer_apolline_before", &"celadon_gym_jr_trainer_apolline_defeated",
	&"celadon_gym_lass_capucine_after", &"celadon_gym_lass_capucine_before",
	&"celadon_gym_lass_capucine_defeated", &"celadon_gym_lass_lila_after",
	&"celadon_gym_lass_lila_before", &"celadon_gym_lass_lila_defeated", &"celadon_hidden_1",
	&"celadon_hotel_guest_1", &"celadon_hotel_guest_2", &"celadon_hotel_reception",
	&"celadon_kid", &"celadon_mansion_1f_man", &"celadon_mansion_1f_woman",
	&"celadon_mansion_2f_man", &"celadon_mansion_2f_woman", &"celadon_mansion_old_lady",
	&"celadon_old_man", &"celadon_restaurant_diner", &"celadon_restaurant_gambler",
	&"celadon_restaurant_waiter", &"celadon_rocket_1", &"celadon_rocket_2", &"celadon_roof_girl",
	&"celadon_roof_girl_thanks", &"celadon_shopper", &"celadon_stroller", &"celadon_tourist",
	&"celadon_youth", &"route_8_gambler_fernand_after", &"route_8_gambler_fernand_before",
	&"route_8_gambler_fernand_defeated", &"route_8_gambler_rene_after",
	&"route_8_gambler_rene_before", &"route_8_gambler_rene_defeated", &"route_8_hidden_1",
	&"route_8_item_1", &"route_8_lass_iris_after", &"route_8_lass_iris_before",
	&"route_8_lass_iris_defeated", &"route_8_lass_margot_after", &"route_8_lass_margot_before",
	&"route_8_lass_margot_defeated", &"route_8_lass_nina_after", &"route_8_lass_nina_before",
	&"route_8_lass_nina_defeated", &"route_8_nerd_anatole_after", &"route_8_nerd_anatole_before",
	&"route_8_nerd_anatole_defeated", &"route_8_nerd_firmin_after", &"route_8_nerd_firmin_before",
	&"route_8_nerd_firmin_defeated", &"souterrain_hidden_1", &"souterrain_hidden_2",
	&"underground_7_8_resident",
]
## Jalon 21 (T21) : Route 12 (dossier 24 §15.7, §15.8, §15.8 bis, annexe A) et Ronflex.
const IDS_J21_T21: Array[StringName] = [
	&"route_12_sign", &"route_12_pier_sign",
	&"route_12_fisher_1_before", &"route_12_fisher_1_defeated", &"route_12_fisher_1_after",
	&"route_12_fisher_2_before", &"route_12_fisher_2_defeated", &"route_12_fisher_2_after",
	&"route_12_fisher_3_before", &"route_12_fisher_3_defeated", &"route_12_fisher_3_after",
	&"route_12_fisher_4_before", &"route_12_fisher_4_defeated", &"route_12_fisher_4_after",
	&"route_12_gate_tm39", &"route_12_gate_tm39_give", &"route_12_gate_tm39_got",
	&"snorlax_route_12", &"snorlax_flute_played", &"snorlax_wakes", &"snorlax_calms",
	&"snorlax_sleeps",
]
## Jalon 20 (T21) : la vie du 20-II (dossier 23 §20.6, §20.7 et annexe A.5, A.8 du plan, textes
## 39 à 55, 95 à 100, 130 à 156) ; un identifiant par dialogue des données.
const IDS_J20_T21: Array[StringName] = [
	&"game_corner_client_1", &"game_corner_client_2", &"game_corner_client_3",
	&"game_corner_client_4", &"game_corner_clerk", &"game_corner_poster",
	&"game_corner_rocket_before", &"game_corner_rocket_defeated", &"game_corner_switch",
	&"giovanni_hideout", &"giovanni_hideout_intro", &"giovanni_hideout_lost",
	&"giovanni_hideout_resume", &"giovanni_hideout_won",
	&"rocket_hideout_b1f_1_after", &"rocket_hideout_b1f_1_before",
	&"rocket_hideout_b1f_1_defeated", &"rocket_hideout_b1f_2_after",
	&"rocket_hideout_b1f_2_before", &"rocket_hideout_b1f_2_defeated",
	&"rocket_hideout_b1f_3_after", &"rocket_hideout_b1f_3_before",
	&"rocket_hideout_b1f_3_defeated", &"rocket_hideout_b1f_hidden_1",
	&"rocket_hideout_b1f_item_1", &"rocket_hideout_b1f_item_2",
	&"rocket_hideout_b2f_1_after", &"rocket_hideout_b2f_1_before",
	&"rocket_hideout_b2f_1_defeated", &"rocket_hideout_b2f_item_1", &"rocket_hideout_b2f_item_2",
	&"rocket_hideout_b2f_item_3", &"rocket_hideout_b2f_item_4",
	&"rocket_hideout_b3f_1_after", &"rocket_hideout_b3f_1_before",
	&"rocket_hideout_b3f_1_defeated", &"rocket_hideout_b3f_2_after",
	&"rocket_hideout_b3f_2_before", &"rocket_hideout_b3f_2_defeated",
	&"rocket_hideout_b3f_hidden_1", &"rocket_hideout_b3f_item_1", &"rocket_hideout_b3f_item_2",
	&"rocket_hideout_b4f_guard_1_after", &"rocket_hideout_b4f_guard_1_before",
	&"rocket_hideout_b4f_guard_1_defeated", &"rocket_hideout_b4f_guard_2_after",
	&"rocket_hideout_b4f_guard_2_before", &"rocket_hideout_b4f_guard_2_defeated",
	&"rocket_hideout_b4f_hidden_1", &"rocket_hideout_b4f_item_1", &"rocket_hideout_b4f_item_2",
	&"rocket_hideout_b4f_item_3", &"rocket_hideout_b4f_key_after",
	&"rocket_hideout_b4f_key_before", &"rocket_hideout_b4f_key_defeated",
	&"rocket_hideout_b4f_key_dropped", &"rocket_hideout_b4f_lift_key",
	&"rocket_hideout_b4f_lift_key_got", &"rocket_hideout_b4f_office_door",
	&"rocket_hideout_b4f_silph_scope", &"rocket_hideout_b4f_silph_scope_got",
]
## Jalon 20 : lot de textes validé du dossier 23 (§20, une citation par ligne).
const DOSSIER_23 := "res://docs/design/dossier-23-celadopole.md"
## Jalon 20 (T25) : annexe A.14 du plan (postes de Safrania, textes 215 à 219).
const PLAN_J20 := "res://docs/tech/jalon-20.md"
## Jalon 21 (T12 à T14) : `data/dialogues/j21_tower.json`.
const IDS_J21: Array[StringName] = [
	&"tower_6f_marowak_held", &"tower_6f_marowak_soul", &"tower_6f_marowak_peace",
	&"tower_rocket_1_before", &"tower_rocket_1_defeated", &"tower_rocket_1_after",
	&"tower_rocket_2_before", &"tower_rocket_2_defeated", &"tower_rocket_2_after",
	&"tower_rocket_3_before", &"tower_rocket_3_defeated", &"tower_rocket_3_after",
	&"tower_7f_fuji", &"tower_7f_fuji_thanks", &"fuji_flute_give", &"fuji_flute_received",
	&"fuji_flute_explain", &"pokemon_house_fuji",
]
const IDS_J19: Array[StringName] = [
	&"tower_channeler_1_after",
	&"tower_channeler_1_before",
	&"tower_channeler_1_defeated",
	&"tower_channeler_2_after",
	&"tower_channeler_2_before",
	&"tower_channeler_2_defeated",
	&"tower_channeler_3_after",
	&"tower_channeler_3_before",
	&"tower_channeler_3_defeated",
	&"tower_channeler_4_after",
	&"tower_channeler_4_before",
	&"tower_channeler_4_defeated",
	&"tower_channeler_5_after",
	&"tower_channeler_5_before",
	&"tower_channeler_5_defeated",
	&"tower_channeler_6_after",
	&"tower_channeler_6_before",
	&"tower_channeler_6_defeated",
	&"tower_channeler_7_after",
	&"tower_channeler_7_before",
	&"tower_channeler_7_defeated",
	&"tower_channeler_8_after",
	&"tower_channeler_8_before",
	&"tower_channeler_8_defeated",
	&"tower_channeler_9_after",
	&"tower_channeler_9_before",
	&"tower_channeler_9_defeated",
	&"tower_6f_ghost_after",
	&"tower_6f_ghost_warning",
	# T16 : la gardienne du rez-de-chaussée (§15.1.1 à 4).
	&"tower_guardian_worried",
	# T20 : Lavanville au J19 (§15.6.2 à 15.6.5).
	&"pokemon_house_man", &"pokemon_house_girl", &"lavender_center_gentleman",
	&"lavender_scope_sign",
	# T17 : le rival n° 5 (§15.2) et l'Exorciste calme du 2F (§15.4).
	&"rival_tower_intro", &"rival_tower_lost", &"rival_tower_resume", &"rival_tower_won",
	&"tower_2f_calm",
	# T18 : Exorciste calme du 5F (§15.4), zone purifiée (§15.5), objets de la Tour (scènes).
	&"tower_exorcist_calm", &"tower_purified_zone_heal", &"tower_purified_zone_done",
	&"tower_3f_objet_1", &"tower_4f_objet_1", &"tower_4f_objet_2", &"tower_5f_objet_1",
	&"tower_5f_cache_1", &"tower_6f_objet_1",
]

const IDS_J18: Array[StringName] = [
	&"dark_cave_1f_item_1", &"dark_cave_1f_item_2", &"dark_cave_1f_sign",
	&"dark_cave_b1f_hidden_1", &"dark_cave_b1f_item_1", &"dark_cave_column", &"dark_cave_crack",
	&"dark_cave_elsa_after", &"dark_cave_elsa_before", &"dark_cave_elsa_defeated",
	&"dark_cave_marcel_after", &"dark_cave_marcel_before", &"dark_cave_marcel_defeated",
	&"dark_cave_roger_after", &"dark_cave_roger_before", &"dark_cave_roger_defeated",
	&"dark_cave_roots", &"dark_cave_simon_after", &"dark_cave_simon_before",
	&"dark_cave_simon_defeated", &"dark_cave_yanis_after",
	&"dark_cave_yanis_before", &"dark_cave_yanis_defeated",
	&"lavender_bouquet_woman", &"lavender_girl", &"lavender_house_1_old_lady",
	&"lavender_house_2_husband", &"lavender_house_2_wife", &"lavender_passerby",
	&"lavender_pokemon_house_sign", &"lavender_tower_sign", &"lavender_town_sign",
	&"lavender_young_man", &"pokemon_house_kid",
	&"pokemon_tower_exorcist", &"pokemon_tower_girl", &"pokemon_tower_grave",
	&"pokemon_tower_grave_1", &"pokemon_tower_grave_2", &"pokemon_tower_grave_3",
	&"pokemon_tower_grave_4", &"pokemon_tower_grave_5", &"pokemon_tower_keeper",
	&"pokemon_tower_visitor_f", &"pokemon_tower_visitor_m",
	&"route_10_cave_sign", &"route_10_center_sign", &"route_10_hiker", &"route_10_hiker_paul_after",
	&"route_10_hiker_paul_before", &"route_10_hiker_paul_defeated", &"route_10_item_1",
	&"route_10_maniac_hector_after", &"route_10_maniac_hector_before",
	&"route_10_maniac_hector_defeated",
	&"route_9_camper_adam_after", &"route_9_camper_adam_before", &"route_9_camper_adam_defeated",
	&"route_9_camper_jules_after", &"route_9_camper_jules_before",
	&"route_9_camper_jules_defeated", &"route_9_hiker_benoit_after",
	&"route_9_hiker_benoit_before", &"route_9_hiker_benoit_defeated",
	&"route_9_hiker_gilles_after", &"route_9_hiker_gilles_before",
	&"route_9_hiker_gilles_defeated", &"route_9_item_1", &"route_9_item_2", &"route_9_item_3",
	&"route_9_lass_lou_after", &"route_9_lass_lou_before", &"route_9_lass_lou_defeated",
	&"route_9_lass_zoe_after", &"route_9_lass_zoe_before", &"route_9_lass_zoe_defeated",
	&"route_9_scout_noa_after", &"route_9_scout_noa_before", &"route_9_scout_noa_defeated",
	&"route_9_sign",
]
## Jalon 18 (T16) : drapeaux levés par ses dialogues (Exorciste, enfant de la Maison des Pokémon)
## et ses scènes (objets, déclencheurs silencieux des objectifs).
## J19 (T16) : l'Exorciste ne pose plus `tower_medium_talked` (T-34 remplacé par la scène).
const SET_J18_DIALOGUES: Array[StringName] = [&"pokemon_house_kid_talked"]
const SET_J18_CUTSCENES: Array[StringName] = [
	&"dark_cave_crossed", &"got_dark_cave_1f_item_1", &"got_dark_cave_1f_item_2",
	&"got_dark_cave_b1f_hidden_1", &"got_dark_cave_b1f_item_1", &"got_route_10_item_1",
	&"got_route_9_item_1", &"got_route_9_item_2", &"got_route_9_item_3", &"lavender_reached",
	&"route_10_reached", &"route_9_entered",
]
## Jalon 15 (T13) : la réplique du garde du poste nord, jouée aussi par la scène du recul.
const PLAYED_J15_ROUTE_5: Array[StringName] = [&"route_5_guard"]
## Dialogues joués par les scènes du Rocket et du barrage.
const PLAYED_J14_ROCKET: Array[StringName] = [
	&"cerulean_rocket_beaten", &"cerulean_rocket_before", &"cerulean_rocket_leaving",
	&"cerulean_rocket_resume", &"cerulean_rocket_spotted", &"cerulean_rocket_tm",
	&"cerulean_south_guard_leaving",
]
const SET_J14_ROCKET_DIALOGUES: Array[StringName] = [&"cerulean_victim_thanked"]
const SET_J14_ROCKET_CUTSCENES: Array[StringName] = [
	&"cerulean_rocket_beaten", &"cerulean_rocket_spotted", &"cerulean_south_guard_left",
	&"got_tm28", &"lost_cerulean_rocket",
]
## Dialogues joués par les scènes de la maison de Léo.
const PLAYED_J14_BILL: Array[StringName] = [
	&"bill_candy_offer", &"bill_give_candy", &"bill_give_ticket", &"bill_greet",
	&"bill_module_next", &"bill_ready", &"bill_screen_next", &"bill_ss_anne", &"bill_thanks",
]
## Drapeaux levés par les dialogues et les scènes de la maison de Léo.
const SET_J14_BILL_DIALOGUES: Array[StringName] = [&"bill_met"]
const SET_J14_BILL_CUTSCENES: Array[StringName] = [
	&"bill_in_cabin", &"bill_module_checked", &"bill_restored", &"bill_screen_checked",
	&"got_bill_rare_candy", &"got_ss_ticket",
]
## Plus aucun drapeau futur au 4B : rival_battle_done est levé par la scène du combat
## (jalon-04.md §14.5, §14.8), quelle que soit l'issue.
## Jalon 7 : got_oak_parcel, lu par Chen (scène du colis, T18), est levé par la première visite
## de la Boutique depuis le T12 (data/cutscenes/viridian_mart.json).
## Jalon 9 : `pewter_arrived` (lu par le garde du poste nord) est posé par le J10, à l'arrivée à
## Argenta : levé par la scène `pewter_arrival` depuis le T8 du J10.
## Jalon 13 (T19) : `badge_cascade` et `misty_invited` sont désormais levés par les scènes d'Ondine ;
## `beaten_nugget_rocket` (lu par la réplique n° 41 b d'Ondine) est levé au T22 (recruteur) :
## plus aucun drapeau futur.
## Jalon 14 (T17) : `cerulean_rocket_beaten` (lu par Léo) est levé par la scène du Rocket
## d'Azuria (T20b).
## T20b : levé (scène du combat), plus aucun drapeau futur.
## Jalon 16 (T12, T15) : `got_hm01` (lu par le marin de la passerelle et le départ du navire) est
## levé par la scène du capitaine (T13). Jalon 18 (T16) : `tower_stairs_open` (présence de
## l'Exorciste de la Tour) est levé au J19 (T16 : scène `tower_guardian`, dossier 22 K-3).
## Jalon 21 : `ghost_marowak_calmed` (6F) et `snorlax_route_*_woken` (Ronflex) sont levés par leurs
## scènes : plus aucun drapeau futur.
const FUTURE_FLAGS: Array[StringName] = []
var _library: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _offer: StarterOffer
## Dialogue → cartes où il est utilisé (PNJ ou point d'examen).
var _used_on: Dictionary[StringName, Array] = {}
## Carte → identifiants de PNJ.
var _npc_ids: Dictionary[StringName, Array] = {}
## Jalon 21 : carte → acteurs de décor déclarés (nœuds du groupe « scene_props », [PropActor]).
var _prop_ids: Dictionary[StringName, Array] = {}
## Dialogue joué par une scène → PNJ créés (« spawn ») par cette scène.
var _spawned_for: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_library = DialogueLibrary.new()
	_library.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()
	# Scène du choix : jouée par le code (StarterChoice) sur la carte de l'offre.
	_use_cutscene(_offer.chosen_scene, _offer.map_id)
	# Mots de réveil après une défaite (dossier 07 §11, dossier 09 §7) : joués par le code sur
	# la carte du point de repos (data/world/rest_points.json, jalon 7 T6), pas par un PNJ.
	var rest_points := RestPointLibrary.new()
	rest_points.load_file()
	for rest_map: StringName in rest_points.get_maps():
		_use(rest_points.get_point(rest_map).wakeup_dialogue, rest_map)
	# Jalon 15 (T4) : répliques de la Pension, jouées par le DaycareDirector (code).
	for daycare_line: StringName in DaycareLines.PLAYED_BY_DIRECTOR:
		_use(daycare_line, &"route_5_daycare")
	var puzzles := SwitchPuzzleLibrary.new()
	puzzles.load_file()
	for map_id: StringName in MAPS:
		_npc_ids[map_id] = []
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			(_npc_ids[map_id] as Array).append(spec.id)
			if spec.is_interactive():
				_use(spec.dialogue, map_id)
			# Jalon 9 : la réplique « avant » d'un Dresseur est jouée par sa séquence, sur sa carte.
			if spec.is_trainer():
				_use(spec.before_dialogue, map_id)
				# Jalon 10 (T9) : la réplique « vaincu », dite par la séquence à la victoire.
				if not spec.defeated_dialogue.is_empty():
					_use(spec.defeated_dialogue, map_id)
				# Jalon 12 (T25) : la réplique de reprise, dite par la séquence après une défaite.
				if spec.has_rematch():
					_use(spec.rematch_dialogue, map_id)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		_prop_ids[map_id] = []
		for node: Node in map.find_children("*", "", true, false):
			if node.is_in_group(PropActor.GROUP):
				(_prop_ids[map_id] as Array).append(StringName(node.name))
		for point: Node in map.get_node(^"Interactables").get_children():
			_use((point as InteractPoint).dialogue_id, map_id)
			# Jalon 16 (T11) : objet à fouiller d'un puzzle : Boot joue les textes du puzzle et
			# sa scène de réussite sur la carte de l'objet.
			var puzzle := puzzles.get_spec((point as InteractPoint).puzzle)
			if puzzle != null:
				for line: StringName in [puzzle.nothing, puzzle.first, puzzle.reset]:
					_use(line, map_id)
				_use_cutscene(puzzle.solved_cutscene, map_id)
		for point: Node in map.get_node(^"Triggers").get_children():
			_use_cutscene((point as EventTriggerPoint).cutscene_id, map_id)
		map.free()
	# Jalon 7 (T18) : scène lancée par un dialogue (variante « cutscene ») sur les cartes où ce
	# dialogue est joué (la scène du colis, en parlant à Chen).
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				for map_id: StringName in (_used_on.get(id, []) as Array).duplicate():
					_use_cutscene(variant.cutscene, map_id)
			# Jalon 12 (T25) : scène lancée par le OUI d'un choix (« confirm_cutscene » : le
			# choix du fossile).
			if variant.choice != null and not variant.choice.confirm_cutscene.is_empty():
				for map_id: StringName in (_used_on.get(id, []) as Array).duplicate():
					_use_cutscene(variant.choice.confirm_cutscene, map_id)


## Dialogues joués par les étapes de la scène [param cutscene_id], sur la carte de son
## déclencheur, puis sur la carte de chaque « change_map » (T4). Un PNJ créé par « spawn »
## disparaît avec sa carte.
func _use_cutscene(cutscene_id: StringName, trigger_map: StringName) -> void:
	var cutscene := _cutscenes.get_cutscene(cutscene_id)
	if cutscene == null:
		return
	for variant: CutsceneVariant in cutscene.variants:
		var spawned: Array[StringName] = []
		var map_id := trigger_map
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				spawned = []
			if step.kind == CutsceneStep.Kind.SPAWN:
				spawned.append(step.spec.id)
			if step.kind == CutsceneStep.Kind.GIFT_POKEMON:
				# Jalon 20 (T12) : « reçoit » et « au Stockage » du don.
				for said: StringName in [step.dialogue_id, step.dialogue_stored]:
					if not said.is_empty():
						_use(said, map_id)
			if step.kind == CutsceneStep.Kind.TRADE:
				# Jalon 25 : « wrong », « refuse » et « say » de l'échange.
				for said: StringName in [step.dialogue_id, step.dialogue_stored] + step.say:
					_use(said, map_id)
			if step.kind == CutsceneStep.Kind.DIALOGUE:
				_use(step.dialogue_id, map_id)
				if not _spawned_for.has(step.dialogue_id):
					_spawned_for[step.dialogue_id] = []
				(_spawned_for[step.dialogue_id] as Array).append_array(spawned)


func _use(dialogue: StringName, map_id: StringName) -> void:
	if not _used_on.has(dialogue):
		_used_on[dialogue] = []
	(_used_on[dialogue] as Array).append(map_id)


## Toutes les pages de toutes les variantes : [id, texte, page].
func _pages() -> Array[Array]:
	var pages: Array[Array] = []
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			for page: DialoguePage in variant.pages:
				pages.append([id, page.text, page, variant])
			# Jalon 7 (T8) : pages des réponses d'un choix (SOIGNER / PAS MAINTENANT).
			if variant.choice != null:
				for page: DialoguePage in variant.choice.confirm_pages + variant.choice.cancel_pages:
					pages.append([id, page.text, page, variant])
	return pages


func _sorted(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(values)
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


func test_library_loads_without_error() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "data/dialogues/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	# Les identifiants sont comparés triés (la liste IDS est groupée par jalon).
	var found := _without_qa(library.get_ids())
	found.sort()
	var expected := IDS + IDS_J14_BILL + IDS_J14_ROCKET + IDS_J15_ROUTE_5 + IDS_J16_GYM \
		+ IDS_J16_SHIP + IDS_J16_RIVAL_CAPTAIN + IDS_J16_T15 + IDS_J17 + IDS_J18 + IDS_J19 + IDS_J20 \
		+ IDS_J20_T17 + IDS_J20_T21 + IDS_J21 + IDS_J21_T21 + IDS_S2B + S2_FIELD_TRAVEL + IDS_J21_T22 \
		+ IDS_J24_TRAINERS + IDS_J24 + IDS_J25
	expected.append_array(TEXTS_S2C_FISH.keys())
	expected.append_array(TEXTS_S2D_STRENGTH.keys())
	expected.append_array(UNVALIDATED)
	expected.sort()
	assert_eq(found, expected)


func test_every_used_dialogue_exists() -> void:
	assert_gt(_used_on.size(), 0)
	for dialogue: StringName in _used_on:
		assert_true(_library.has_dialogue(dialogue), "dialogue « %s » défini" % dialogue)


func test_every_dialogue_is_used() -> void:
	var played := _cutscenes.get_dialogue_ids()
	for id: StringName in _real_ids():
		if UNUSED_YET.has(id) or PLAYED_BY_COMPANION.has(id) or PLAYED_BY_BOOT.has(id) \
				or S2_FIELD_TRAVEL.has(id) or TEXTS_S2C_FISH.has(id) \
				or TEXTS_S2D_STRENGTH.has(id):
			continue
		assert_true(_used_on.has(id) or played.has(id),
			"dialogue « %s » utilisé par un PNJ, un point ou une scène" % id)


func test_every_dialogue_played_by_a_cutscene_exists() -> void:
	assert_eq(_cutscenes.get_errors().size(), 0, str(_cutscenes.get_errors()))
	var played := _without_qa(_cutscenes.get_dialogue_ids())
	assert_eq(played, _sorted([
		# Jalon 24 : Artikodin, porte de l'Arène, CT35, fossiles.
		&"articuno_cry", &"articuno_flew_away", &"cinnabar_gym_locked", &"cinnabar_lab_tm35_offer",
		&"cinnabar_lab_tm35_use", &"cinnabar_fossil_taken", &"cinnabar_fossil_ready_kabuto", &"cinnabar_fossil_ready_omanyte",
		&"cinnabar_fossil_received_kabuto", &"cinnabar_fossil_received_omanyte",
		&"cinnabar_fossil_stored_kabuto", &"cinnabar_fossil_stored_omanyte",
		# Jalon 25 : Ptéra (Vieil Ambre), calque des fossiles du J24.
		&"cinnabar_fossil_ready_aerodactyl", &"cinnabar_fossil_received_aerodactyl",
		&"cinnabar_fossil_stored_aerodactyl",
		# Jalon 13 (T19) : Ondine à l'Arène.
		&"cerulean_gym_misty_badge", &"cerulean_gym_misty_intro", &"cerulean_gym_misty_lost",
		&"cerulean_gym_misty_resume", &"cerulean_gym_misty_tm", &"cerulean_gym_misty_tm_late",
		&"cerulean_gym_misty_tm_use", &"cerulean_gym_misty_won",
		&"clerk_parcel", &"clerk_parcel_hello",
		# Jalon 13 (T19) : Ondine au pont.
		&"misty_bridge_invite",
		# Jalon 19 (T14) : le SPECTRE du 6F.
		&"tower_6f_ghost_after", &"tower_6f_ghost_warning",
		# Jalon 20 (T25) : la boisson donnée au garde d'un poste de Safrania.
		&"saffron_gate_drink_lemonade", &"saffron_gate_drink_soda", &"saffron_gate_drink_water",
		# Jalon 21 (T21) : CT39 du poste et réveil de Ronflex.
		&"route_12_gate_tm39_give", &"route_12_gate_tm39_got", &"snorlax_flute_played",
		&"snorlax_wakes", &"snorlax_calms", &"snorlax_sleeps",
		# Jalon 20 (T12) : le don d'Évoli.
		&"celadon_eevee_received", &"celadon_eevee_stored",
		# Jalon 20 (T17) : Erika (scène de l'Arène et rattrapage de la CT21) et la fillette du toit.
		&"celadon_gym_erika_badge", &"celadon_gym_erika_intro", &"celadon_gym_erika_lost",
		&"celadon_gym_erika_resume", &"celadon_gym_erika_tm", &"celadon_gym_erika_tm_late",
		&"celadon_gym_erika_tm_use", &"celadon_gym_erika_won", &"celadon_roof_girl_thanks",
		# Jalon 20 (T21) : interrupteur du Casino, Clé Ascenseur, Giovanni et Scope Sylphe.
		&"game_corner_switch", &"giovanni_hideout_intro", &"giovanni_hideout_lost",
		&"giovanni_hideout_resume", &"giovanni_hideout_won", &"rocket_hideout_b4f_key_dropped",
		&"rocket_hideout_b4f_lift_key_got", &"rocket_hideout_b4f_silph_scope_got",
		# Jalon 19 (T16) : la gardienne du rez-de-chaussée.
		&"tower_guardian_worried",
		# Jalon 21 (T13, T14) : Fuji remercie au 7F, remise de la Poké Flûte à la maison.
		&"tower_7f_fuji_thanks", &"fuji_flute_give", &"fuji_flute_received",
		&"fuji_flute_explain",
		# Jalon 21 (T12) : la variante A du 6F (Ossatueur retenu, son âme, la paix).
		&"tower_6f_marowak_held", &"tower_6f_marowak_soul", &"tower_6f_marowak_peace",
		# Jalon 19 (T17) : le rival n° 5 (joué par sa scène).
		&"rival_tower_intro", &"rival_tower_lost", &"rival_tower_resume", &"rival_tower_won",
		# Jalon 19 (T18) : la zone purifiée du 5F.
		&"tower_purified_zone_heal", &"tower_purified_zone_done",
		# Jalon 12 (T25) : scène du chercheur et choix du fossile.
		&"mt_moon_researcher_before", &"mt_moon_researcher_chosen",
		&"mt_moon_researcher_defeated", &"mt_moon_researcher_rematch",
		&"mt_moon_researcher_share",
		# Jalon 13 (T22) : le recruteur Rocket.
		&"nugget_rocket_beaten", &"nugget_rocket_given", &"nugget_rocket_lost",
		&"nugget_rocket_no", &"nugget_rocket_offer", &"nugget_rocket_resume",
		&"nugget_rocket_welcome", &"nugget_rocket_yes",
		&"oak_after_battle", &"oak_lab_exit_block", &"oak_lab_reunion",
		&"oak_parcel_records", &"oak_parcel_rival", &"oak_parcel_rival_dex", &"oak_poke_balls",
		&"oak_poke_balls_intro", &"oak_pokedex_activated", &"oak_route1_call",
		&"oak_route1_warning", &"oak_starter_offer", &"oak_starter_reciprocal",
		# Jalon 10 (T8) : scènes de Pierre et du garde de la Route 3.
		&"pewter_gym_brock_badge", &"pewter_gym_brock_intro", &"pewter_gym_brock_lost",
		&"pewter_gym_brock_resume",
		# Jalon 11 (T14) : remise de la CT34.
		&"pewter_gym_brock_tm", &"pewter_gym_brock_tm_late", &"pewter_gym_brock_tm_use",
		&"pewter_gym_brock_won", &"pewter_route_3_guard_cleared",
		&"pewter_route_3_guard_rule",
		# Jalon 13 (T19) : le rival n° 3.
		&"rival_cerulean_intro", &"rival_cerulean_lost", &"rival_cerulean_resume",
		&"rival_cerulean_resume_again", &"rival_cerulean_won",
		&"rival_challenge", &"rival_challenge_wait", &"rival_lab_lost", &"rival_lab_won",
		# Jalon 15 (T14) : le garde de Safrania sur la Route 6 (recul).
		&"route_6_guard",
		&"rival_lab_won_leaving", &"rival_parcel_greet", &"rival_parcel_leaving",
		&"rival_parcel_return", &"rival_starter_pick", &"rival_starter_smile",
		&"route1_grass_thought", &"route22_rival_greet", &"route22_rival_hesitates",
		&"route22_rival_lost", &"route22_rival_won", &"route22_youngster_sigh",
		&"route_1_potion_found", &"route_25_hidden_1_found", &"underground_hidden_1_found", &"route_2_item_3_found",
		&"route_2_item_4_found",
		&"viridian_forest_item_3_found", &"viridian_forest_item_4_found",
		&"viridian_forest_item_6_found"] + PLAYED_J14_BILL + PLAYED_J14_ROCKET
		+ PLAYED_J15_ROUTE_5 + PLAYED_J16_GYM + PLAYED_J16_RIVAL_CAPTAIN
		+ PLAYED_J16_T15
		# Jalon 17 (T8) : remise de la CS05 par l'assistant (scène lancée par son dialogue).
		+ [&"route_2_east_assistant_hm05_system", &"route_2_east_assistant_hm05_use"]
		# Jalon 25 : Manoir, Arène, réserve du Musée, échanges, porte de l'Arène.
		+ [&"cinnabar_gym_door_unlock", &"cinnabar_blaine_after", &"cinnabar_blaine_badge",
			&"cinnabar_blaine_before", &"cinnabar_blaine_defeated", &"cinnabar_blaine_tm38",
			&"cinnabar_gym_2_before", &"cinnabar_gym_2_defeated", &"cinnabar_gym_3_before",
			&"cinnabar_gym_3_defeated", &"cinnabar_gym_4_before", &"cinnabar_gym_4_defeated",
			&"cinnabar_gym_5_before", &"cinnabar_gym_5_defeated", &"cinnabar_gym_6_before",
			&"cinnabar_gym_6_defeated", &"cinnabar_gym_7_before", &"cinnabar_gym_7_defeated",
			&"cinnabar_gym_quiz_1_question", &"cinnabar_gym_quiz_2_question",
			&"cinnabar_gym_quiz_3_question", &"cinnabar_gym_quiz_4_question",
			&"cinnabar_gym_quiz_5_question", &"cinnabar_gym_quiz_6_question", &"cinnabar_gym_quiz_intro",
			&"cinnabar_gym_quiz_right", &"cinnabar_gym_quiz_wrong", &"cinnabar_trade_cable",
			&"cinnabar_trade_hector_after", &"cinnabar_trade_hector_done", &"cinnabar_trade_hector_offer",
			&"cinnabar_trade_hector_refuse", &"cinnabar_trade_hector_thanks",
			&"cinnabar_trade_hector_wrong", &"cinnabar_trade_lina_after", &"cinnabar_trade_lina_done",
			&"cinnabar_trade_lina_offer", &"cinnabar_trade_lina_refuse", &"cinnabar_trade_lina_thanks",
			&"cinnabar_trade_lina_wrong", &"cinnabar_trade_marc_after", &"cinnabar_trade_marc_done",
			&"cinnabar_trade_marc_offer", &"cinnabar_trade_marc_refuse", &"cinnabar_trade_marc_thanks",
			&"cinnabar_trade_marc_wrong", &"mansion_statue_yes", &"pewter_museum_reserve_amber_give"]
		# Jalon 21 (T22) : le réveil de Ronflex (Route 16).
		+ PLAYED_J21_T22))
	for id: StringName in played:
		assert_true(_library.has_dialogue(id), "dialogue « %s » défini" % id)
		if UNUSED_YET.has(id):
			continue
		assert_true(_used_on.has(id), "« %s » joué depuis un déclencheur ou par le code" % id)
	for id: StringName in [&"oak_starter_reciprocal", &"rival_starter_pick",
			&"rival_starter_smile", &"rival_challenge_wait", &"rival_challenge",
			&"oak_lab_exit_block", &"rival_lab_won", &"rival_lab_won_leaving", &"rival_lab_lost",
			&"oak_after_battle", &"oak_poke_balls_intro", &"oak_poke_balls"]:
		assert_eq(_used_on.get(id), [&"oak_lab"], "%s joué au labo" % id)
	# Jalon 7 (T25) : la scène du rival n° 2, sur la Route 22 seulement.
	for id: StringName in [&"route22_youngster_sigh", &"route22_rival_hesitates",
			&"route22_rival_greet", &"route22_rival_won", &"route22_rival_lost"]:
		assert_eq(_used_on.get(id), [&"route_22"], "%s joué sur la Route 22" % id)


func test_every_react_targets_an_npc_of_the_map_where_it_is_used() -> void:
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		if page.react.is_empty():
			continue
		var maps: Array = _used_on.get(row[0], [])
		assert_false(maps.is_empty(), "%s utilisé" % row[0])
		for map_id: StringName in maps:
			# Jalon 21 : un acteur de décor déclaré sur la carte vaut un PNJ.
			assert_true((_npc_ids[map_id] as Array).has(page.react)
				or (_prop_ids.get(map_id, []) as Array).has(page.react),
				"%s : « react » %s sur %s" % [row[0], page.react, map_id])


func test_every_turn_actor_and_target_exists_where_the_dialogue_is_played() -> void:
	var turns := 0
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		for actor: StringName in page.turn:
			turns += 1
			for who: StringName in [actor, page.turn[actor]]:
				if who == NpcRoster.PLAYER_ID or (who != actor and Grid.is_direction_name(who)):
					continue
				var maps: Array = _used_on.get(row[0], [])
				assert_false(maps.is_empty(), "%s utilisé" % row[0])
				for map_id: StringName in maps:
					var known: bool = (_npc_ids[map_id] as Array).has(who) or \
						(_spawned_for.get(row[0], []) as Array).has(who)
					assert_true(known, "%s : « turn » %s sur %s" % [row[0], who, map_id])
	assert_gt(turns, 0, "les répliques de Chen ont des « turn »")


func test_oak_looks_at_the_grass_on_his_second_line_and_thinks_before_the_last() -> void:
	var pages := _library.get_dialogue(&"oak_route1_warning").variants[0].pages
	assert_eq(pages.size(), 4)
	assert_eq(pages[0].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[1].turn, {&"oak": &"up"} as Dictionary[StringName, StringName],
		"il regarde les hautes herbes (nord)")
	assert_eq(pages[2].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[3].pause, 1.0, "il réfléchit une seconde")
	assert_eq(pages[3].text, "...Viens avec moi.")


func test_every_condition_flag_is_set_somewhere() -> void:
	# Sans les données d'une éventuelle carte de QA (`qa_*.json` ; celles du jalon 16 sont
	# retirées au T20).
	var dialogues := DialogueLibrary.new()
	var cutscenes := CutsceneLibrary.new()
	for pair: Array in [[dialogues, "res://data/dialogues/"], [cutscenes, "res://data/cutscenes/"]]:
		for file: String in DirAccess.get_files_at(pair[1]):
			if file.get_extension() == "json" and not MapCatalog.is_qa_map(StringName(file)):
				assert_true(pair[0].load_file((pair[1] as String).path_join(file)), file)
	var set_flags := dialogues.get_set_flags() + cutscenes.get_set_flags() \
		+ StarterChoice.get_set_flags(_offer)
	# Jalon 24 (T13) : « fossile prêt », posé par le code à l'arrivée sur Cramois'Île
	# ([FossilReadyGate]).
	set_flags.append(&"fossil_ready")
	var read_flags := dialogues.get_condition_flags() + cutscenes.get_condition_flags()
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			read_flags.append_array(spec.if_flags + spec.unless_flags)
			# Jalon 12 (T25) : `beaten_<id>` d'un Dresseur est levé par sa séquence (victoire).
			if spec.is_trainer():
				set_flags.append(TrainerRules.beaten_flag(spec.trainer_id))
	for flag: StringName in read_flags:
		if FUTURE_FLAGS.has(flag):
			continue
		assert_true(set_flags.has(flag), "drapeau « %s » levé par un « set »" % flag)
	for flag: StringName in FUTURE_FLAGS:
		assert_false(set_flags.has(flag), "« %s » : levé par un jalon futur" % flag)
	assert_true(read_flags.has(&"starter_chosen"), "starter_chosen lu (pensée des herbes)")
	assert_eq(dialogues.get_set_flags(),
		_sorted([&"blacked_out_before", &"cerulean_neighbor_talked", &"forest_hiker_talked", &"forest_naturalist_talked",
			&"mom_greeted", &"nugget_rocket_yes", &"pewter_researcher_talked", &"poison_unlocked", &"rival_met",
			&"route_5_gate_warned",
			&"route_2_hiker_talked", &"route_2_youngster_talked", &"storage_terminal_seen",
			&"viridian_old_man_talked",
			# Jalon 16 (T15) : PARTIR (confirmation du départ du S.S. Anne) ; TXT-03 entendu
			# (marin de la passerelle, aussi joué par la sortie).
			&"ss_anne_departure_chosen", &"ss_anne_exit_told"]
			+ SET_J14_BILL_DIALOGUES + SET_J14_ROCKET_DIALOGUES
			# Jalon 17 (T8) : Ronflex vu, assistant rencontré, barrière de FUTUR B ouverte.
			+ [&"hm05_assistant_met", &"route_2_east_gate_open", &"snorlax_route_12_seen"]
			+ SET_J18_DIALOGUES
			# Jalon 20 (T21) : porte du bureau ouverte par le second garde battu (§2.7.3).
			+ [&"rocket_hideout_b4f_door_open"]
			# Jalon 21 (T22) : Ronflex de la Route 16 vu (T-6, T-7 repris).
			+ [&"snorlax_route_16_seen"]
			# Jalon 25 : réponses du quiz, offre d'échange acceptée ou refusée (choix OUI / NON).
			+ [&"cinnabar_gym_quiz_no", &"cinnabar_gym_quiz_yes", &"cinnabar_trade_offer_accepted",
				&"cinnabar_trade_offer_declined"]))
	assert_eq(cutscenes.get_set_flags(), _sorted([&"got_tm39", &"route_12_visited",
		&"snorlax_route_12_awake", &"snorlax_route_12_caught", &"snorlax_route_12_done",
		&"snorlax_route_12_woken", &"badge_boulder", &"badge_cascade",
		&"beaten_mt_moon_researcher", &"beaten_nugget_rocket", &"brock_met", &"cerulean_reached", &"got_mt_moon_1f_hidden_1",
		&"got_mt_moon_1f_item_1", &"got_mt_moon_b1f_item_1", &"got_mt_moon_b1f_item_2",
		&"got_mt_moon_b2f_hidden_1", &"got_mt_moon_b2f_item_1", &"got_nugget", &"got_oak_parcel",
		&"got_potion_route_1", &"got_route_24_antidote", &"got_route_24_potion",
		&"got_route_25_hidden_1", &"got_route_25_item_1", &"got_route_25_item_2",
		&"got_route_25_item_3", &"got_route_2_item_1", &"got_route_2_item_2",
		&"got_route_2_item_3", &"got_route_2_item_4", &"got_route_2_north_item_1",
		&"got_route_3_hidden_1", &"got_route_3_item_1", &"got_route_3_item_2",
		&"got_route_3_item_3", &"got_route_4_poke_ball", &"got_route_5_hidden_1",
		&"got_route_5_item_1", &"got_underground_hidden_1", &"got_viridian_forest_item_1",
		&"got_viridian_forest_item_2", &"got_viridian_forest_item_3", &"got_viridian_forest_item_4",
		&"got_viridian_forest_item_5", &"got_viridian_forest_item_6", &"lost_mt_moon_researcher",
		&"misty_invited", &"misty_met", &"mt_moon_fossil_chosen", &"mt_moon_got_dome_fossil",
		&"mt_moon_got_helix_fossil", &"oak_lab_reunion", &"oak_met", &"pewter_arrived",
		&"pokedex_activated", &"rival_battle_done", &"rival_cerulean_lost_once",
		&"rival_cerulean_retried", &"rival_cerulean_won", &"rival_challenged", &"rival_lab_lost",
		&"rival_lab_won", &"rival_left_lab", &"rival_route22_lost", &"rival_route22_won",
		&"rival_tower_lost_once", &"rival_tower_retried", &"rival_tower_won",
		# Jalon 19 (T24) : première rencontre du SPECTRE du 6F (dossier 22 §13).
		&"tower_ghost_met",
		# Jalon 21 (T13, T14) : Fuji sauvé, Poké Flûte reçue.
		&"fuji_rescued", &"got_poke_flute",
		# Jalon 21 (T12) : Ossatueur apaisé (victoire de la variante A du 6F), brume levée.
		&"ghost_marowak_calmed", &"tower_6f_mist_lifted",
		# Jalon 20 (T25) : boisson donnée, les quatre postes de Safrania s'ouvrent.
		&"saffron_gates_open",
		# Jalon 20 (T12) : Évoli reçu (étape « gift_pokemon »).
		&"eevee_received",
		# Jalon 24 : objets et caches, Artikodin (rencontre fixe), CT35, fossiles confiés et reçus.
		&"got_route_20_item_1", &"got_route_21_item_1", &"got_seafoam_b2f_hidden_1",
		&"got_seafoam_b4f_hidden_1", &"articuno_done", &"articuno_caught", &"got_tm35",
		&"fossil_reviving_kabuto", &"fossil_reviving_omanyte", &"fossil_revived_kabuto",
		&"fossil_revived_omanyte", &"fossil_reviving_aerodactyl", &"fossil_revived_aerodactyl",
		# Jalon 25 : Manoir (objets, caches, interrupteur), Arène (herses, Dresseurs, Auguste, CT38,
		# porte), Vieil Ambre, arbre du Musée, échanges.
		&"badge_volcano", &"beaten_cinnabar_gym_1", &"beaten_cinnabar_gym_2",
		&"beaten_cinnabar_gym_3", &"beaten_cinnabar_gym_4", &"beaten_cinnabar_gym_5",
		&"beaten_cinnabar_gym_6", &"beaten_cinnabar_gym_7", &"blaine_met", &"cinnabar_gym_gate_1",
		&"cinnabar_gym_gate_2", &"cinnabar_gym_gate_3", &"cinnabar_gym_gate_4",
		&"cinnabar_gym_gate_5", &"cinnabar_gym_gate_6", &"cinnabar_gym_unlocked",
		&"cinnabar_trade_electrode_done", &"cinnabar_trade_seel_done",
		&"cinnabar_trade_tangela_done", &"cut_pewter_museum_tree",
		&"got_pokemon_mansion_1f_hidden_1", &"got_pokemon_mansion_1f_item_1",
		&"got_pokemon_mansion_1f_item_2", &"got_pokemon_mansion_2f_item_1",
		&"got_pokemon_mansion_3f_hidden_1", &"got_pokemon_mansion_3f_item_1",
		&"got_pokemon_mansion_3f_item_2", &"got_pokemon_mansion_b1f_hidden_1",
		&"got_pokemon_mansion_b1f_item_1", &"got_pokemon_mansion_b1f_item_2",
		&"got_pokemon_mansion_b1f_item_3", &"got_pokemon_mansion_b1f_item_4",
		&"got_pokemon_mansion_b1f_item_5", &"mansion_switch_on", &"pewter_museum_got_old_amber",
		&"tm38_received",
		&"route_3_entered", &"route_3_guard_cleared", &"route_4_reached", &"route_5_entered",
		&"starter_chosen",
		&"starter_offered", &"tm11_received", &"tm34_received", &"viridian_arrived",
		# Jalon 15 (T14) : Route 6 (Poké Ball, Super Potion cachée), arrivée à Carmin.
		&"got_route_6_hidden_1", &"got_route_6_item_1", &"vermilion_reached",
		# Jalon 16 (T11) : la barrière de l'Arène de Carmin ; (T14) Major Bob.
		&"vermilion_gym_puzzle_solved", &"badge_thunder", &"surge_met", &"tm24_received",
		# Jalon 16 (T12) : les neuf objets du S.S. Anne (six au sol, trois cachés).
		&"got_ss_anne_item_01", &"got_ss_anne_item_02", &"got_ss_anne_item_03",
		&"got_ss_anne_item_04", &"got_ss_anne_item_05", &"got_ss_anne_item_06",
		&"got_ss_anne_hidden_1", &"got_ss_anne_hidden_2", &"got_ss_anne_hidden_3",
		# Jalon 16 (T13) : le rival n° 4 et la CS01 du capitaine.
		&"ss_anne_gangway_open", &"got_hm01", &"rival_ss_anne_lost_once", &"rival_ss_anne_won",
		# Jalon 16 (T15) : départ du S.S. Anne, arbuste coupé.
		&"ss_anne_departed", &"cut_vermilion_gym_bush",
		# Jalon 17 (T8) : remise de la CS05 par l'assistant ; (T17) objets de la Route 11 ;
		# (T20, T21) objets du couloir et Super Potion de FUTUR A.
		&"got_hm05", &"got_route_11_hidden_1", &"got_route_11_item_1",
		&"got_route_11_item_2", &"got_route_2_east_item_1", &"got_route_2_east_item_2",
		&"got_route_2_item_5", &"got_digletts_cave_item_1",
		# Jalon 17 (T23) : les deux arbustes coupés (couloir de la Route 2 est, FUTUR A).
		&"cut_route_2_east_bush", &"cut_route_2_futur_a",
		# Jalon 18 (T15) : l'arbre de la sortie est d'Azuria.
		&"cut_cerulean_east_tree",
		# Jalon 20 (T16) : les deux arbustes de l'Arène d'Erika.
		&"cut_celadon_gym_bush", &"cut_celadon_gym_inner_bush",
		# Raccords J21 ↔ J22 (2026-10-23) : l'arbre de la Route 16.
		&"cut_route_16_tree",
		# Jalon 20 (T17) : arrivées (Route 8, Céladopole), objet et caches, Erika (badge, CT21),
		# CT13 de la fillette du toit.
		&"route_8_reached", &"celadon_reached", &"got_route_8_item_1", &"got_route_8_hidden_1",
		&"got_celadon_hidden_1", &"got_souterrain_hidden_1", &"got_souterrain_hidden_2",
		&"erika_met", &"badge_rainbow", &"tm21_received", &"rooftop_tm13"]
		+ SET_J14_BILL_CUTSCENES + SET_J14_ROCKET_CUTSCENES + SET_J18_CUTSCENES
		# Jalon 22 : Bon, Bicyclette, cannes, CS02, saluts des gardes de la Piste, objets.
		+ [&"got_bike_voucher", &"got_bicycle", &"got_old_rod", &"got_good_rod",
		&"got_super_rod", &"got_hm02", &"cycling_gate_16_greeted", &"cycling_gate_18_greeted",
		&"got_route_12_item_1", &"got_route_12_hidden_1", &"got_route_13_hidden_1",
		&"got_route_13_hidden_2", &"got_route_15_item_1", &"got_route_16_hidden_1",
		&"got_route_17_hidden_1", &"got_route_17_hidden_2", &"got_route_17_hidden_3",
		&"got_route_17_hidden_4", &"got_route_17_hidden_5"]
		# Jalon 19 (T16) : la gardienne de la Tour s'écarte.
		+ [&"tower_stairs_open"]
		# Jalon 19 (T18) : objets de la Tour (cinq visibles, un caché).
		+ [&"got_tower_3f_objet_1", &"got_tower_4f_objet_1", &"got_tower_4f_objet_2",
		&"got_tower_5f_objet_1", &"got_tower_5f_cache_1", &"got_tower_6f_objet_1"]
		# Jalon 20 (T21) : interrupteur du Casino, Clé, Giovanni, Scope, objets du repaire.
		+ [&"game_corner_switch", &"rocket_dropped_lift_key", &"got_rocket_hideout_b4f_lift_key",
		&"giovanni_met", &"giovanni_hideout_won", &"got_rocket_hideout_b4f_silph_scope",
		&"got_rocket_hideout_b1f_item_1", &"got_rocket_hideout_b1f_item_2",
		&"got_rocket_hideout_b1f_hidden_1", &"got_rocket_hideout_b2f_item_1",
		&"got_rocket_hideout_b2f_item_2", &"got_rocket_hideout_b2f_item_3",
		&"got_rocket_hideout_b2f_item_4", &"got_rocket_hideout_b3f_item_1",
		&"got_rocket_hideout_b3f_item_2", &"got_rocket_hideout_b3f_hidden_1",
		&"got_rocket_hideout_b4f_item_1", &"got_rocket_hideout_b4f_item_2",
		&"got_rocket_hideout_b4f_item_3", &"got_rocket_hideout_b4f_hidden_1"]
		# Jalon 21 (T22) : titre de zone de la Route 16, réveil de Ronflex 16 (`_awake` jamais sur disque).
		+ [&"route_16_visited", &"snorlax_route_16_awake", &"snorlax_route_16_woken",
		&"snorlax_route_16_done", &"snorlax_route_16_caught"]))
	assert_eq(_used_on.get(&"oak_lab_reunion"), [&"oak_lab"], "joué au labo, après le fondu")
	assert_eq(_used_on.get(&"oak_starter_offer"), [&"oak_lab"], "joué au labo")


## Drapeaux du choix (§13.3) : l'offre les nomme, le code lève les taken_*, la scène lève
## done_flag ; starter_offered (levé par route1_grass) est lu par la scène oak_lab_exit.
func test_starter_flags_are_set_and_read() -> void:
	assert_eq(StarterChoice.get_set_flags(_offer), [&"taken_bulbasaur", &"taken_charmander",
		&"taken_squirtle", &"starter_female"] as Array[StringName])
	assert_true(_library.get_condition_flags().has(_offer.female_flag), "lu par Maya")
	var read_flags := _cutscenes.get_condition_flags()
	for spec: NpcSpec in NpcRoster.load_for_map(_offer.map_id).get_all():
		read_flags.append_array(spec.if_flags + spec.unless_flags)
	for flag: StringName in StarterChoice.get_set_flags(_offer):
		if flag == _offer.female_flag:
			continue
		assert_true(read_flags.has(flag), "« %s » lu (présence du starter)" % flag)
	assert_true(_cutscenes.get_set_flags().has(_offer.done_flag), "done_flag levé par la scène")
	assert_true(_cutscenes.get_set_flags().has(_offer.open_flag), "open_flag levé par la scène")
	assert_true(read_flags.has(_offer.open_flag), "open_flag lu par oak_lab_exit")


## Décisions de Kevin n° 1, 2, 11 et 16 (jalon-04.md §13.5, §13.12) : textes mot pour mot,
## une page chacun ; « Ça devrait être intéressant. » gardé (décision n° 16, Q-A).
func test_starter_choice_lines() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"oak_starter_reciprocal": ["Prof. Chen", "On dirait que le choix est réciproque."],
		&"rival_starter_pick": ["{rival}", "Alors ce sera toi."],
		&"rival_starter_smile": ["{rival}", "Ça devrait être intéressant."],
		&"rival_challenge_wait": ["{rival}", "Attends."],
		&"rival_challenge": ["{rival}",
			"On ne va quand même pas partir sans savoir ce qu'ils savent faire."],
		&"oak_lab_exit_block": ["Prof. Chen",
			"Pas si vite. Tu n'as pas encore choisi ton partenaire."],
	}
	for id: StringName in expected:
		var dialogue := _library.get_dialogue(id)
		assert_eq(dialogue.speaker, expected[id][0], "%s : locuteur" % id)
		assert_false(dialogue.narration)
		assert_false(dialogue.draft)
		assert_eq(dialogue.variants.size(), 1)
		var pages := dialogue.variants[0].pages
		assert_eq(pages.size(), 1, "%s : une page" % id)
		assert_eq(pages[0].text, expected[id][1])


## Décision n° 16 (Q-G) : pendant la phase de choix (starter_offered, pas encore choisi),
## Chen et le rival ont leurs nouvelles répliques ; avant l'offre, celles du 3B.
## Décision n° 16 (Q-E) : les répliques de la décision n° 8 (Chen « Le monde qui vous
## attend… », Maya « Alors, c'est lui / elle… ») seulement après le combat du 4B
## (rival_battle_done) ; avant, Maya garde celle du 3B ; Maya s'accorde au sexe du starter.
func test_waiting_lines_during_and_after_the_choice() -> void:
	var oak := _library.get_dialogue(&"oak_lab_waiting")
	# 4B : la variante répétée « starter_chosen » du 4A est supprimée (3 variantes) ; J7 (T18) :
	# la variante du colis passe en tête (test_oak_parcel_lines).
	assert_eq(oak.variants.size(), 4)
	assert_eq(oak.variants[0].cutscene, &"oak_parcel")
	assert_eq(oak.variants[1].if_flags, [&"rival_battle_done"] as Array[StringName])
	assert_eq(_texts(oak.variants[1]), [
		"Le monde qui vous attend est bien plus vaste que Bourg Palette.",
		"Prends le temps de l'observer. Les Pokémon ont beaucoup à nous apprendre.",
	] as Array[String])
	assert_eq(oak.variants[2].if_flags, [&"starter_offered"] as Array[StringName])
	assert_eq(_texts(oak.variants[2]), ["Prends ton temps.",
		"Choisis celui avec qui tu as envie de partir."] as Array[String])
	assert_eq(_texts(oak.variants[3]),
		["Un peu de patience. J'ai quelque chose à vous montrer."] as Array[String])
	var rival := _library.get_dialogue(&"rival_lab_waiting")
	assert_eq(rival.speaker, "{rival}")
	# 4B : la variante répétée « rival_challenged » du 4A est supprimée (2 variantes).
	assert_eq(rival.variants.size(), 2)
	assert_eq(rival.variants[0].if_flags, [&"starter_offered"] as Array[StringName])
	assert_eq(_texts(rival.variants[0]), ["Tu comptes les regarder encore longtemps ?",
		"Dépêche-toi de choisir."] as Array[String])
	assert_eq(_texts(rival.variants[1]),
		["Tu vois ? Je t'avais dit que j'étais prêt."] as Array[String])
	var maya := _library.get_dialogue(&"maya")
	assert_eq(maya.variants.size(), 4)
	assert_eq(maya.variants[0].if_flags, [&"rival_battle_done", &"starter_female"]
		as Array[StringName])
	assert_eq(_texts(maya.variants[0]), ["Alors, c'est elle que tu as choisi ?",
		"Vous avez l'air de déjà bien vous entendre."] as Array[String])
	assert_eq(maya.variants[1].if_flags, [&"rival_battle_done"] as Array[StringName])
	assert_eq(_texts(maya.variants[1]), ["Alors, c'est lui que tu as choisi ?",
		"Vous avez l'air de déjà bien vous entendre."] as Array[String])
	var flags := StoryFlags.new()
	flags.set_flag(&"oak_met")
	assert_eq(oak.pick(flags), oak.variants[3], "avant l'offre : réplique du 3B")
	assert_eq(rival.pick(flags), rival.variants[1], "avant l'offre : réplique du 3B")
	assert_eq(maya.pick(flags), maya.variants[2], "réplique du 3B")
	flags.set_flag(&"starter_offered")
	assert_eq(oak.pick(flags), oak.variants[2], "pendant le choix")
	assert_eq(rival.pick(flags), rival.variants[0], "pendant le choix")
	assert_eq(maya.pick(flags), maya.variants[2])
	# L'état « starter choisi, combat pas encore fini » n'est plus atteint par le joueur : la
	# scène s'enchaîne du choix jusqu'à la fin du combat (jalon-04.md §14.8). Après le combat :
	flags.set_flag(&"starter_chosen")
	flags.set_flag(&"rival_challenged")
	flags.set_flag(&"rival_left_lab")
	flags.set_flag(&"rival_battle_done")
	flags.set_flag(&"starter_female")
	assert_eq(oak.pick(flags), oak.variants[1], "après le combat : « Le monde qui vous attend… »")
	assert_eq(maya.pick(flags), maya.variants[0], "starter femelle : « elle »")
	flags.set_flag(&"starter_female", false)
	assert_eq(maya.pick(flags), maya.variants[1], "starter mâle ou sans sexe : « lui »")


func _texts(variant: DialogueVariant) -> Array[String]:
	var texts: Array[String] = []
	for page: DialoguePage in variant.pages:
		texts.append(page.text)
	return texts


## Décision de Kevin (jalon-04.md §4.1, §13.5) : 4 répliques du Prof. Chen, mot pour mot ; il
## regarde les trois Pokémon (table à sa droite) à la 3e, puis revient vers le joueur.
func test_oak_starter_offer_four_lines_and_looks() -> void:
	var dialogue := _library.get_dialogue(&"oak_starter_offer")
	assert_eq(dialogue.speaker, "Prof. Chen")
	assert_false(dialogue.narration)
	assert_false(dialogue.draft)
	assert_eq(dialogue.variants.size(), 1)
	var pages := dialogue.variants[0].pages
	var texts: Array[String] = []
	for page: DialoguePage in pages:
		texts.append(page.text)
	assert_eq(texts, [
		"Vous voulez tous les deux découvrir Kanto.",
		"Mais découvrir ce monde seul serait une mauvaise idée.",
		"Eux aussi ont encore beaucoup à découvrir.",
		"Alors... pourquoi ne pas commencer ensemble ?",
	] as Array[String])
	assert_true(pages[0].turn.is_empty())
	assert_true(pages[1].turn.is_empty())
	assert_eq(pages[2].turn, {&"oak": &"right"} as Dictionary[StringName, StringName],
		"il regarde les trois Pokémon (table à sa droite)")
	assert_eq(pages[3].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])


func test_mom_first_variant_is_automatic_and_only_hers() -> void:
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			# Maman, et le garde du poste sud à son premier passage (jalon 9, Q-4).
			var first_of: Array[StringName] = [&"mom", &"forest_gate_south_guard"]
			assert_eq(variant.auto, first_of.has(id) and variant == \
				_library.get_dialogue(id).variants[0], "%s : auto" % id)


## Lot de textes validé par Kevin le 2026-10-06 : plus aucun dialogue ni variante provisoire,
## sauf ceux qui attendent sa relecture, nommés ici (« id:variante »).
## Jalon 16 (décisions du 2026-10-16) : indice du guide de l'Arène de Carmin (type Sol), validé le
## 2026-10-16 ; jalon 17 : accord de T-2 à 1 espèce validé (Q-2, 2026-10-16) : liste vide.
const PENDING_DRAFT_VARIANTS: Array[String] = []


func test_no_dialogue_nor_variant_is_draft() -> void:
	for id: StringName in _real_ids():
		var dialogue := _library.get_dialogue(id)
		assert_false(dialogue.draft, String(id))
		for i: int in dialogue.variants.size():
			var key := "%s:%d" % [id, i]
			assert_eq(dialogue.variants[i].draft, PENDING_DRAFT_VARIANTS.has(key), key)


## Le soin de Maman (Q22, jalon 5C) : elle soigne l'équipe, seulement après le starter.
func test_mom_heal_variant() -> void:
	var heal: DialogueVariant = _library.get_dialogue(&"mom").variants[1]
	assert_eq(heal.action, &"heal", "soigne l'équipe")
	assert_eq(heal.if_flags, [&"starter_chosen"] as Array[StringName], "après le starter")
	assert_false(heal.auto, "jamais automatique")
	assert_eq(heal.pages.size(), 2, "courte")
	# Seule cette variante soigne (le réveil après défaite soigne par la défaite, pas par le texte).
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			# J19 (T18) : la zone purifiée du 5F soigne à la fin de sa première page (§2.8).
			var zone_heal := id == &"tower_purified_zone_heal"
			assert_eq(variant.action == &"heal", variant == heal or zone_heal, "%s : « heal »" % id)


func test_texts_are_the_dossier_02_texts_word_for_word() -> void:
	assert_true(FileAccess.file_exists(DOSSIER), DOSSIER)
	assert_true(FileAccess.file_exists(DOSSIER_07), DOSSIER_07)
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	var dossier_07 := FileAccess.get_file_as_string(DOSSIER_07)
	var dossier_09 := FileAccess.get_file_as_string(DOSSIER_09)
	var dossier_11 := FileAccess.get_file_as_string(DOSSIER_11).replace("**", "")
	var valides := FileAccess.get_file_as_string(TEXTES_VALIDES)
	var dossier_10 := FileAccess.get_file_as_string(DOSSIER_10)
	var dossier_12 := FileAccess.get_file_as_string(DOSSIER_12)
	var lot_j10 := FileAccess.get_file_as_string(LOT_J10)
	var dossier_14 := FileAccess.get_file_as_string(DOSSIER_14)
	var dossier_18 := FileAccess.get_file_as_string(DOSSIER_18)
	var dossier_27 := FileAccess.get_file_as_string(DOSSIER_27)
	var dossier_19 := FileAccess.get_file_as_string(DOSSIER_19)
	var annex_a_15 := AnnexATexts.annex_a(FileAccess.get_file_as_string(JALON_15))
	var dossier_16 := FileAccess.get_file_as_string(DOSSIER_16).replace("\n    ", " ") \
		.replace("\n   ", " ")
	var dossier_15 := FileAccess.get_file_as_string(DOSSIER_15)
	var dossier_21 := FileAccess.get_file_as_string(DOSSIER_21) \
		+ FileAccess.get_file_as_string(PLAN_J18)
	var dossier_23 := FileAccess.get_file_as_string(DOSSIER_23).replace("\n    ", " ")
	# J22 : dossier 25 à plat (déclaration oubliée au J22 : ce script ne se chargeait plus).
	var dossier_25 := J22Ids.flat_text(FileAccess.get_file_as_string(J22Ids.DOSSIER_25))
	# T25 (n° 219) : « [Joueur] donne un(e) [boisson] au garde. », écrit pour chaque boisson.
	var plan_j20 := FileAccess.get_file_as_string(PLAN_J20).replace("\n     ", " ") \
		.replace("\n    ", " ")
	for drink: String in ["une Eau Fraîche", "un Soda Cool", "une Limonade"]:
		plan_j20 += plan_j20.replace("[Joueur] donne un(e) [boisson]", "{joueur} donne " + drink)
	var dossier_24 := FileAccess.get_file_as_string(DOSSIER_24)
	var dossier_22 := FileAccess.get_file_as_string(DOSSIER_22).replace("\n   ", " ") \
		.replace("\n  ", " ")
	var dossier_20 := FileAccess.get_file_as_string(DOSSIER_20).replace("**", "")
	var annex_a_17 := AnnexATexts.annex_a(FileAccess.get_file_as_string(JALON_17))
	# Jalon 21 (T21) : textes validés du dossier 24 (§15) et de l'annexe A du plan.
	var j21_texts := FileAccess.get_file_as_string("res://docs/design/dossier-24-repos-des-esprits.md") \
		+ FileAccess.get_file_as_string("res://docs/tech/jalon-21.md")
	var dossier_17 := FileAccess.get_file_as_string(DOSSIER_17) \
		+ FileAccess.get_file_as_string(PLAN_J14).replace("\n  ", " ")
	# Formes accordées « fatigué[e] » (n° 55) : masculin et féminin.
	dossier_14 += dossier_14.replace("[e]", "") + dossier_14.replace("[e]", "e")
	# J12 (T25) : formes au masculin du héros actuel (« revenu[e] », « gamin[e] curieux[se] ») et
	# question du choix écrite par fossile (« Prendre le {fossil} ? », §20 n° 23).
	dossier_15 += dossier_15.replace("[e]", "").replace("[se]", "") \
		+ dossier_15.replace("{fossil}", "Fossile Dôme") \
		+ dossier_15.replace("{fossil}", "Fossile Nautile")
	for row: Array in _pages():
		# Une variante en brouillon (PENDING_DRAFT_VARIANTS) attend la relecture de Kevin : son
		# texte n'est encore dans aucun dossier.
		if GATE_GUARDS.has(row[0]) or UNVALIDATED.has(row[0]) or S2_FIELD_TRAVEL.has(row[0]) \
				or (row[3] as DialogueVariant).draft:
			continue
		if TEXTS_J21_T22.has(row[0]):
			assert_true(TEXTS_J21_T22[row[0]].has(text_t22(row[1])), "%s : %s" % [row[0], row[1]])
			continue
		if TEXTS_S2B.has(row[0]):
			assert_true(TEXTS_S2B[row[0]].has(row[1]), "%s : %s" % [row[0], row[1]])
			continue
		if TEXTS_S2C_FISH.has(row[0]):
			assert_true(TEXTS_S2C_FISH[row[0]].has(row[1]), "%s : %s" % [row[0], row[1]])
			continue
		if TEXTS_S2D_STRENGTH.has(row[0]):
			assert_true(TEXTS_S2D_STRENGTH[row[0]].has(row[1]), "%s : %s" % [row[0], row[1]])
			continue
		if TEXTS_J24.has(row[0]):
			assert_true(TEXTS_J24[row[0]].has(row[1]), "%s : %s" % [row[0], row[1]])
			continue
		if TEXTS_J25.has(row[0]):
			assert_true(TEXTS_J25[row[0]].has(row[1]), "%s : %s" % [row[0], row[1]])
			continue
		var text: String = row[1]
		for token: String in _DOSSIER_TOKENS:
			text = text.replace(token, _DOSSIER_TOKENS[token])
		# Prologue : dossier 02 ; Route 1 (jalon 5) : dossier 07 ; Jadielle (jalon 7) : dossier 09 ;
		# anciens brouillons : lot de textes validé le 2026-10-06.
		# Route 2 (jalon 8) : dossier 11, « / » = retour à la ligne (forcé pour un panneau,
		# sinon laissé à la bulle).
		var in_dossier_11 := dossier_11.contains("| %s |" % text.replace("\n", " / ")) \
			or dossier_11.replace(" / ", " ").contains("| %s |" % text)
		assert_true(dossier.contains(text) or dossier_07.contains(text)
			or dossier_09.contains(text) or in_dossier_11 or valides.contains("« %s »" % text)
			or dossier_10.contains(_as_dossier_10(text))
			or dossier_12.contains(_as_dossier_10(text))
			or lot_j10.contains("| « %s » |" % text.replace("\n", "\\n"))
			or _each_line_quoted(dossier_14, text)
			or _in_dossier_18(dossier_18, text)
			or _in_dossier_18(annex_a_15, text)
			# J24 (T4) : Dresseurs des Routes 19 à 21 (dossier 27 §15.4 ; test_j24_data vérifie
			# chaque réplique entière).
			or _in_dossier_18(dossier_27, text)
			# J15 (T13) : panneaux « TITRE — texte » (§15.2, T-1) écrits sur deux lignes ; le
			# carrefour de l'annexe A.3 (« … → · … ← ») aussi.
			or dossier_18.contains("« %s »" % text.replace("\n", " — "))
			or annex_a_15.contains("« %s »" % text.replace("\n", " · "))
			or dossier_18.contains("« %s »" % row[1])
			or _each_line_quoted(dossier_16, text)
			or dossier_15.contains(" : « %s »" % text)
			# J12 (T21) : bulles suivantes (« / ») et panneaux sur deux lignes du §20.
			or _each_line_quoted(dossier_15, text)
			# J12 (T18) : une réplique du §20 coupée en deux lignes dans sa bulle (retour à la
			# ligne de mise en page) : la bulle entière est une citation du dossier.
			or dossier_15.contains("« %s »" % text.replace("\n", " "))
			# J21 (T21) : dossier 24 §15 et annexe A du plan (bulles « / », panneaux sur deux lignes).
			or j21_texts.contains(text.replace("{joueur}", "{player}"))
			or j21_texts.contains(text.replace("{joueur}", "{player}").replace("\n", " / "))
			# J14 (T17) : dossier 17 §15 et annexe A du plan.
			or dossier_17.contains("« %s »" % text.replace("{player}", "{joueur}"))
			or dossier_17.contains(text.replace("\n", " "))
			or dossier_17.contains(text.replace("\n", " — "))
			# J17 (T8) : dossier 20 §16 (bulle entre « | », « / » ou « · ») et annexe A.
			or _in_dossier_20(dossier_20, row[1])
			or annex_a_17.contains("« %s »" % text)
			# J16 (T11) : lot de textes du dossier 19 (§0.5), une citation par ligne.
			or _each_line_quoted(dossier_19, text)
			# J16 (T15) : une réplique du lot coupée en deux lignes dans sa bulle.
			or dossier_19.contains("« %s »" % text.replace("\n", " "))
			# J18 (T16) : dossier 21 §15 et plan (annexe A).
			or dossier_21.contains(text.replace("\n", " "))
			or dossier_21.contains("« %s »" % text.replace("\n", " / "))
			# J19 (T14) : dossier 22 §15 (une réplique peut tenir sur deux pages).
			or _in_dossier_18(dossier_22, text)
			or _in_dossier_18(dossier_22, text.replace("{joueur}", "{player}"))
			# J19 (T17) : citation du §15 repliée sur deux lignes du dossier.
			or _in_dossier_18(_flat_lines(dossier_22), text)
			# J21 (T12 à T14) : dossier 24 §15, « / » entre les deux lignes d'une bulle.
			or _in_dossier_18(dossier_24, text.replace("{joueur}", "{player}").replace("\n", " / "))
			# J20 (T15) : dossier 23 §20, un panneau sur deux lignes, une citation par ligne.
			or _each_line_quoted(dossier_23, text)
			or _in_dossier_18(dossier_23, text) or _in_dossier_18(plan_j20, text)
			# J20 (T12) : « {player} » écrit tel quel dans le dossier 23 (texte 29).
			or _each_line_quoted(dossier_23, text.replace("{joueur}", "{player}"))
			# J22 (T13, T17) : dossier 25 §16, bulles « / » et lignes à plat.
			or dossier_25.contains(J22Ids.flat_text(row[1])),
			"%s : « %s » dans un dossier de conception" % [row[0], text])


## Jalon 17 : vrai si [param text] est une bulle du §16 du dossier 20 (gras retiré) : bordée par
## « | », « / », « · » ou « : » (répliques des Dresseurs) ; un panneau « TITRE\ntexte » s'y
## écrit « TITRE / texte ». Jetons du code écrits comme le dossier ({n}, {reste}, {joueur}).
func _in_dossier_20(dossier: String, text: String) -> bool:
	var flat := text.replace("{caught_missing}", "{reste}").replace("{caught}", "{n}") \
		.replace("{player}", "{joueur}").replace("\n", " / ")
	for before: String in ["| ", "/ ", "· ", ": ", "*(système)* "]:
		for after: String in [" |", " /", " ·"]:
			if dossier.contains(before + flat + after):
				return true
	return false


## Vrai si chaque ligne de [param text] figure entre guillemets dans [param dossier] (dossier 14 :
## une réplique par numéro, « Avec Patience, ton Pokémon encaisse, » puis « puis rend… »).
func _each_line_quoted(dossier: String, text: String) -> bool:
	for line: String in text.split("\n"):
		if not dossier.contains("« %s »" % line):
			return false
	return true


## Dossier dont les lignes d'un même paragraphe sont rejointes.
func _flat_lines(dossier: String) -> String:
	return RegEx.create_from_string("(?<!\\n)\\n[ ]*(?=\\S)").sub(dossier, " ", true) \
			.replace("  ", " ")


## Jalon 15 : vrai si [param text] (retours à la ligne de la bulle remplacés par des espaces) est
## dans une réplique « … » du lot validé du dossier 18 (§15 : une réplique longue peut tenir sur
## plusieurs pages, coupées entre deux phrases ; test_vermilion_data vérifie la réplique entière).
func _in_dossier_18(dossier: String, text: String) -> bool:
	var flat := text.replace("\n", " ")
	for quote: RegExMatch in RegEx.create_from_string("« (.+?) »").search_all(dossier):
		if quote.get_string(1).contains(flat):
			return true
	return false


func test_speakers_and_narration() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"mom": ["Maman", false], &"mom_wakeup": ["Maman", false],
		&"rival": ["{rival}", false], &"maya": ["Maya", false],
		&"aoki": ["Mme Aoki", false], &"nils": ["Nils", false], &"haru": ["Haru", false],
		&"breakfast_table": ["", true], &"rival_kanto_map": ["", true],
		&"observe_bulbasaur": ["Bulbizarre", true], &"observe_charmander": ["Salamèche", true],
		&"observe_squirtle": ["Carapuce", true], &"observe_aoki_pidgey": ["Roucool", true],
		&"observe_nils_rattata": ["Rattata", true], &"sign_pallet_town": ["", false],
		&"oak_route1_call": ["???", false], &"route1_grass_thought": ["", true],
		&"oak_route1_warning": ["Prof. Chen", false], &"oak_lab_reunion": ["", false],
		&"oak_lab_waiting": ["Prof. Chen", false], &"rival_lab_waiting": ["{rival}", false],
		&"oak_starter_offer": ["Prof. Chen", false],
		&"oak_starter_reciprocal": ["Prof. Chen", false], &"rival_starter_pick": ["{rival}", false],
		&"rival_starter_smile": ["{rival}", false],
		&"rival_challenge_wait": ["{rival}", false], &"rival_challenge": ["{rival}", false],
		&"oak_lab_exit_block": ["Prof. Chen", false],
		&"rival_lab_won": ["{rival}", false], &"rival_lab_won_leaving": ["{rival}", false],
		&"rival_lab_lost": ["{rival}", false], &"oak_after_battle": ["Prof. Chen", false],
		&"oak_poke_balls_intro": ["Prof. Chen", false], &"oak_poke_balls": ["Prof. Chen", false],
		&"viridian_courier": ["Livreur", false], &"viridian_lass": ["Dresseuse", false],
		&"viridian_kid": ["Enfant", false], &"viridian_traveler": ["Voyageur", false],
		&"viridian_old_man": ["Vieil homme", false],
		&"viridian_gym_watcher": ["Habitant", false], &"viridian_gym_door": ["", true],
		&"viridian_house_door": ["", true],
		&"oak_parcel_records": ["Prof. Chen", false],
		&"oak_pokedex_activated": ["Prof. Chen", false], &"oak_parcel_rival": ["", false],
		&"oak_parcel_rival_dex": ["Prof. Chen", false],
		&"rival_parcel_return": ["{rival}", false], &"rival_parcel_greet": ["{rival}", false],
		&"rival_parcel_leaving": ["{rival}", false],
		&"nurse": ["Infirmière", false], &"nurse_wakeup": ["Infirmière", false],
		&"route22_youngster_sigh": ["Jeune Dresseur", false],
		&"route22_rival_hesitates": ["{rival}", false], &"route22_rival_greet": ["{rival}", false],
		&"route22_rival_won": ["{rival}", false], &"route22_rival_lost": ["{rival}", false],
		# Jalon 8 (dossier 11, T16) : panneaux sans locuteur, comme celui de Bourg Palette.
		&"route_2_sign": ["", false], &"route_2_forest_sign": ["", false],
		&"route_2_closed_sign": ["", false], &"route_2_hiker": ["Randonneuse", false],
		&"route_2_youngster": ["Jeune Dresseur", false], &"route_2_dense_tree": ["", true],
		&"route_2_closed_gate": ["", true], &"route_2_item_3_found": ["", true],
		&"route_2_item_4_found": ["", true],
		# Jalon 12 (T21) : panneau sans locuteur, examens du camp en narration.
		&"mt_moon_1f_sign": ["", false], &"mt_moon_1f_crate": ["", true],
		&"mt_moon_1f_lamp": ["", true], &"mt_moon_1f_hiker": ["Randonneur", false],
		# Jalon 12 (T18) : panneaux de la Route 3 sans locuteur.
		&"route_3_sign_west": ["", false], &"route_3_sign_center": ["", false],
		&"route_3_traveler": ["Voyageur", false], &"route_3_hiker": ["Randonneuse", false],
		# Jalon 12 (T25) : Sbires (§20 n° 19), chercheur, question du fossile en narration.
		&"mt_moon_rocket_1_before": ["Sbire Rocket", false],
		&"mt_moon_rocket_2_before": ["Sbire Rocket", false],
		&"mt_moon_rocket_3_before": ["Sbire Rocket", false],
		&"mt_moon_researcher_before": ["Chercheur Gaspard", false],
		&"mt_moon_researcher_talk": ["Chercheur Gaspard", false],
		&"mt_moon_fossil_dome": ["", true], &"mt_moon_fossil_helix": ["", true],
		# Jalon 15 (T14) : panneaux sans locuteur, l'arbre de l'Arène en narration.
		&"route_6_sign": ["", false], &"vermilion_city_sign": ["", false],
		&"cut_tree": ["", true], &"route_6_guard": ["Garde", false],
		&"vermilion_sailor": ["Marin", false],
		# Jalon 17 (T23) : l'arbuste du couloir en narration, comme celui de l'Arène.
		&"route_2_east_bush": ["", true],
		# Raccords J21 ↔ J22 (2026-10-23) : l'arbre de la Route 16, en narration.
		&"route_16_tree": ["", true],
	}
	for id: StringName in expected:
		var dialogue := _library.get_dialogue(id)
		assert_eq(dialogue.speaker, expected[id][0], "%s : locuteur" % id)
		assert_eq(dialogue.narration, expected[id][1], "%s : narration" % id)


func test_every_page_fits_in_three_lines_of_the_real_box() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	viewport.add_child(box)
	box.open()
	var label := box.get_node(^"%Text") as Label
	for row: Array in _pages():
		var dialogue := _library.get_dialogue(row[0])
		box.show_page(dialogue.speaker, row[1], dialogue.narration)
		box.set_visible_characters(-1)
		await wait_process_frames(1)
		assert_lte(label.get_line_count(), UiTokens.DIALOG_MAX_LINES,
			"%s : « %s » en %d lignes" % [row[0], row[1], label.get_line_count()])
		assert_eq(box.get_panel().size.x, float(UiTokens.DIALOG_BOX_WIDTH))


## Décisions de Kevin 6, 7 et 9 : Maya a une variante « oak_met » placée avant celle de 3A
## (après les deux de l'après-combat, décision n° 16) ; au labo, quatre répliques avec « Rival » et « Prof. Chen »
## page par page.
func test_maya_after_oak_returns_and_the_lab_reunion() -> void:
	var maya := _library.get_dialogue(&"maya")
	assert_eq(maya.variants.size(), 4)
	assert_eq(maya.variants[2].if_flags, [&"oak_met"] as Array[StringName], "avant celle de 3A")
	assert_eq(_texts(maya.variants[2]), ["Ah, le professeur est revenu.",
		"Et à voir son air, j'imagine qu'il a encore quelque chose en tête."] as Array[String])
	assert_eq(maya.variants[3].pages[0].text, "Bonjour ! Tu cherches le professeur Chen ?",
		"réplique de 3A inchangée")
	var flags := StoryFlags.new()
	assert_eq(maya.pick(flags), maya.variants[3])
	flags.set_flag(&"oak_met")
	assert_eq(maya.pick(flags), maya.variants[2])
	var reunion := _library.get_dialogue(&"oak_lab_reunion").variants[0].pages
	var lines: Array = []
	for page: DialoguePage in reunion:
		lines.append([page.speaker, page.text])
	assert_eq(lines, [
		["{rival}", "Enfin."],
		["Prof. Chen", "Un peu de patience."],
		["{rival}", "Ça fait une heure que tu dis ça."],
		["Prof. Chen", "Et pourtant, tu es toujours là."],
	])
	assert_eq(reunion[1].turn, {&"oak": &"rival"} as Dictionary[StringName, StringName])
	assert_eq(reunion[2].turn, {&"rival": &"oak"} as Dictionary[StringName, StringName])


## Jalon 7 (T18, dossier 09 §6, §19) : parler à Chen avec le colis lance la scène (variante sans
## page, en tête) ; jamais après l'activation. Répliques de la scène dans l'ordre du §19, la
## réplique de l'espèce porte le jeton, « Observe. Explore. » garde sa phrase.
func test_oak_parcel_lines() -> void:
	var oak := _library.get_dialogue(&"oak_lab_waiting")
	var first := oak.variants[0]
	assert_eq(first.if_flags, [&"got_oak_parcel"] as Array[StringName])
	assert_eq(first.unless_flags, [StoryFlags.POKEDEX_ACTIVATED] as Array[StringName])
	assert_eq(first.cutscene, &"oak_parcel")
	assert_true(first.pages.is_empty(), "la scène porte toutes les répliques")
	var flags := StoryFlags.new()
	for flag: StringName in [&"rival_battle_done", &"got_oak_parcel"]:
		flags.set_flag(flag)
	assert_same(oak.pick(flags), first)
	flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(oak.pick(flags).cutscene, &"", "après l'activation : Chen parle normalement")
	assert_eq(_used_on.get(&"oak_parcel_records"), [&"oak_lab"], "joué au labo")
	var records := _library.get_dialogue(&"oak_parcel_records").variants[0].pages
	var texts: Array[String] = []
	for page: DialoguePage in records:
		texts.append(page.text)
	assert_eq(texts, ["Tiens…", "Il a déjà commencé à enregistrer tes rencontres.",
		"Un {first_wild_species}… Tu n'as pas perdu de temps.",
		"J'étudie depuis longtemps la manière dont les Pokémon vivent à travers Kanto.",
		"Mais aucune recherche ne remplacera ce qu'un Dresseur découvre sur le terrain.",
		"Ton voyage peut nous apprendre beaucoup."] as Array[String])
	var activated := _library.get_dialogue(&"oak_pokedex_activated").variants[0].pages
	assert_eq(activated.back().text, "Observe. Explore. Fais-toi ta propre idée du monde.")
	var rival := _library.get_dialogue(&"oak_parcel_rival").variants[0].pages
	assert_eq([rival[0].speaker, rival[1].speaker], ["Prof. Chen", "{rival}"])
	assert_gt(rival[1].pause, 0.0, "« …On verra. » après une courte pause")
	# Toute scène lancée par un dialogue existe.
	var launched := 0
	for id: StringName in _real_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched += 1
				assert_true(_cutscenes.has_cutscene(variant.cutscene), "%s : scène « %s »" % [
					id, variant.cutscene])
	# La scène du colis ; jalon 8 : les deux objets visibles de la Route 2 (PRENDRE) ; jalon 9 :
	# les trois de la Forêt de Jade ; jalon 10 : la Potion de la Route 2 nord et Pierre.
	# Jalon 11 : la remise tardive de la CT34 par Pierre. Jalon 12 (T21) : la Corde Sortie et
	# la Potion au sol du Mont Sélénite, le Réveil caché (examen de l'indice). Jalon 12 (T18) :
	# les trois objets au sol de la Route 3 et son objet caché. Jalon 12 (T25) : la Pierre Lune
	# (B1F) et la CT01 (B2F) au sol, la Pierre Lune cachée (B2F). Jalon 13 : la Poké Ball de la
	# Route 4, la Potion de la Route 24, Ondine (pont, Arène et rattrapage), l'Antidote caché et le
	# recruteur (T22). Jalon 14 : l'écran, le module et la console de Léo (T17), quatre objets de
	# la Route 25 (T16). Jalon 15 (T19) : la Guérison cachée du souterrain.
	# Jalon 15 (T14) : la Poké Ball et la Super Potion cachée de la Route 6.
	# Jalon 15 (T13) : la Super Potion et l'Antidote caché de la Route 5.
	# Jalon 16 (T14) : Major Bob (Arène et rattrapage de la CT24) ; (T12) neuf objets du S.S. Anne ;
	# (T13) le capitaine (CS01).
	# Jalon 16 : le marin de la passerelle après la CS01 (la confirmation du départ) ; son
	# embarquement avec le Passe Bateau (TXT-01).
	# Jalon 17 (T8) : la remise de la CS05 par l'assistant ; (T17) deux objets au sol et un caché
	# de la Route 11 ; (T20) Pierre Lune et Super Bonbon ; (T21) Super Potion de FUTUR A ;
	# (intégration) Corde Sortie de la Cave.
	# Jalon 18 (T16) : sept objets au sol (Route 9, Route 10, grotte) et la Super Potion cachée.
	# Jalon 20 (T21) : onze objets au sol et trois caches du repaire, la Clé (chute et prise),
	# Giovanni et le Scope Sylphe.
	# Jalon 22 (T13, T17) : la Canne du pêcheur de Carmin, l'échange du Bon à Azuria (les données
	# des fichiers j22_*.json sont vérifiées par test_j22_data).
	# Jalon 24 : deux objets au sol, deux caches, Artikodin, la CT35, deux dons de fossile.
	# Jalon 25 : objets et caches du Manoir (13), statue, six machines, Auguste, trois échanges,
	# Vieil Ambre, arbre du Musée.
	assert_eq(launched, 141, "la scène du colis, dix-sept objets au sol, six cachés, Pierre et "
		+ "sa CT34, Ondine (pont, Arène et rattrapage), écran, module, console, objets de la "
		+ "Route 25, le Rocket d'Azuria (2) et le barrage sud ; J15 : objets de la Route 5 ; "
		+ "J16 : Major Bob (2), neuf objets du S.S. Anne, le capitaine, le marin (2) ; "
		+ "J17 : la CS05, Route 11 (3), deux objets du couloir, la Super Potion de la clairière "
		+ "et la Corde Sortie de la Cave ; J18 : huit objets ; J19 : la gardienne de la Tour et six objets de la Tour (T18) ; "
		+ "J20 (T17) : Super Potion de la Route 8, quatre caches (Route 8, souterrain ×2, "
		+ "ville), Erika (2) ; "
		+ "J20 (T21) : repaire (11 objets, 3 caches, Clé ×2, Giovanni, Scope) ; "
		+ "J21 (T13, T14) : M. Fuji au 7F et dans sa maison ; J22 : la Canne, la Bicyclette ; "
		+ "J24 : objets (2), caches (2), Artikodin, CT35, fossiles (2) ; J25 : Ptéra (1)")
	# Le jeton n'apparaît que dans la réplique de l'espèce, « {pokemon} » dans les phrases du
	# compagnon (J11), et ceux de la Pension dans ses répliques (J15).
	for row: Array in _pages():
		if row[0] == &"cerulean_rocket_tm":
			assert_eq(DialogueTokens.tokens_in(row[1]), [DialogueTokens.PLAYER] as Array[StringName])
			continue
		if IDS_J14_BILL.has(row[0]):
			continue # {player} de Léo (dossier 17 §15) : testé dans test_bill_house
		if row[0] in [&"fuji_flute_give", &"fuji_flute_received"]:
			continue # Jalon 21 (T14) : {player} de la remise de la Flûte (§15.4), test_pokemon_house_fuji
		var tokens := DialogueTokens.tokens_in(row[1])
		if String(row[0]).begins_with("daycare_"):
			for token: StringName in tokens:
				assert_true(DialogueTokens.CONTEXT.has(token),
					"%s : jeton {%s} à sa place" % [row[0], token])
			continue
		var expected: Array[StringName] = []
		if row[1] == records[2].text:
			expected = [DialogueTokens.FIRST_WILD_SPECIES]
		elif PLAYED_BY_COMPANION.has(row[0]):
			expected = [DialogueTokens.POKEMON]
		elif row[0] == &"nugget_rocket_given" \
				or (row[0] == &"rival_tower_intro" and row[1].contains("{player}")) \
				or (String(row[0]).begins_with("saffron_gate_drink_") and row[1].contains("{player}")) \
				or row[0] == &"celadon_eevee_received" or row[0] == &"fishing_cast" \
				or String(row[0]).begins_with("cinnabar_fossil_received_") \
				or (String(row[0]).begins_with("cinnabar_trade_") and row[1].contains("{player}")) \
				or (row[0] == &"cinnabar_gym_guide" and row[1].contains("{player}")) \
				or row[0] == &"cinnabar_lab_tm35_use" \
				or (row[0] in [&"route_12_gate_tm39_got", &"snorlax_flute_played"] \
					and row[1].contains("{player}")) \
				or (row[0] in [&"rocket_hideout_b4f_lift_key_got",
					&"rocket_hideout_b4f_silph_scope_got"] and row[1].contains("{player}")) \
				or (String(row[0]).begins_with("celadon_gym_erika_") and row[1].contains("{player}")):
			expected = [DialogueTokens.PLAYER]
		elif J17_TOKENS.has(row[1]):
			# Jalon 17 (T8) : compte d'espèces de l'assistant (T-1 à T-3), joueur de T-3.
			expected.assign(J17_TOKENS[row[1]])
		elif not (row[3] as DialogueVariant).field.is_empty() and row[1].contains("{pokemon}"):
			# Jalon 16 (T15) : variante de capacité de terrain, Pokémon qui coupe.
			expected = [DialogueTokens.POKEMON]
		assert_eq(tokens, expected, "%s : jeton" % row[0])



## Jalon 21 (T22) : le jeton « {player} » s'écrit « {joueur} » dans les textes validés.
static func text_t22(text: String) -> String:
	return text.replace("{player}", "{joueur}")


## Forme d'une réplique dans le dossier 10 : « ligne » ou « ligne 1 » / « ligne 2 ».
static func _as_dossier_10(text: String) -> String:
	var quoted := PackedStringArray()
	for line: String in text.split("\n"):
		quoted.append("« %s »" % line)
	return " / ".join(quoted)


## Jalon 9 (T11) : une réplique avant et une après par Dresseur de la forêt, une page chacune,
## locuteur = nom du Dresseur (data/trainers/), mot pour mot (dont « Enfin... presque. »).
func test_forest_trainer_lines() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	var expected: Dictionary[StringName, Array] = {
		&"forest_scout_theo": ["Hé ! Toi aussi, tu cherches\ndes Pokémon dans la forêt ?",
			"Ton Pokémon est bien entraîné.\nJe dois encore progresser."],
		&"forest_scout_noe": ["Mes Pokémon ont grandi ici.\nTu veux les affronter ?",
			"Ils deviennent plus forts\nchaque jour."],
		&"forest_youngster_tom": ["Je connais cette forêt par cœur !\nEnfin... presque.",
			"D'accord. Peut-être pas par cœur."],
		&"forest_scout_milo": ["Les Pokémon Insecte évoluent vite.\nRegarde ça !",
			"Pas encore assez vite, apparemment."],
		&"forest_scout_eli": ["Tu as traversé toute la forêt ?\nAlors montre-moi ton équipe !",
			"Pas mal !\nArgenta n'est plus très loin."],
	}
	var dossier_10 := FileAccess.get_file_as_string(DOSSIER_10)
	for trainer_id: StringName in expected:
		var trainer := trainers.get_trainer(trainer_id)
		assert_not_null(trainer, String(trainer_id))
		var suffixes: Array[String] = ["_before", "_after"]
		for i: int in suffixes.size():
			var id := StringName(String(trainer_id) + suffixes[i])
			var dialogue := _library.get_dialogue(id)
			assert_not_null(dialogue, String(id))
			if dialogue == null or trainer == null:
				continue
			assert_eq(dialogue.speaker, trainer.name, "%s : locuteur" % id)
			assert_false(dialogue.narration)
			assert_eq(dialogue.variants.size(), 1, String(id))
			var pages := dialogue.variants[0].pages
			assert_eq(pages.size(), 1, "%s : une page" % id)
			assert_eq(pages[0].text, expected[trainer_id][i], String(id))
			assert_string_contains(dossier_10, _as_dossier_10(pages[0].text))


## Jalon 9 (T6) : les deux gardes, mot pour mot du dossier 10 (« Textes verrouillés »), nom
## affiché « Garde » (lot de textes n° 55), une page de deux lignes par réplique.
func test_forest_gate_guards_say_the_locked_lines() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER_10)
	var south := _library.get_dialogue(&"forest_gate_south_guard")
	var north := _library.get_dialogue(&"forest_gate_north_guard")
	assert_eq([south.speaker, north.speaker], ["Garde", "Garde"])
	assert_eq(south.variants.size(), 2)
	assert_eq(north.variants.size(), 2)
	var pages: Array[String] = []
	for dialogue: Dialogue in [south, north]:
		for variant: DialogueVariant in dialogue.variants:
			assert_eq(variant.pages.size(), 1, "une réplique = une page")
			pages.append(variant.pages[0].text)
	assert_eq(pages.size(), 4)
	for text: String in pages:
		var lines := text.split("\n")
		assert_eq(lines.size(), 2, "bulle de 2 lignes : %s" % text)
		assert_true(dossier.contains("« %s » / « %s »" % [lines[0], lines[1]]),
			"« %s » dans le dossier 10" % text)
	assert_eq(pages[0], "La Forêt de Jade est juste devant.\nGarde un Antidote avec toi.")
	assert_eq(pages[1], "Les Aspicot peuvent empoisonner.\nLa Boutique de Jadielle vend des Antidotes.")
	# Garde du sud : première conversation = avertissement + `poison_unlocked`, automatique,
	# une seule fois ; ensuite PNJ ordinaire (rappel, pas de drapeau).
	var first: DialogueVariant = south.variants[0]
	assert_true(first.auto)
	assert_eq(first.unless_flags, [&"poison_unlocked"] as Array[StringName])
	assert_eq(first.set_flags, [&"poison_unlocked"] as Array[StringName])
	assert_false(south.variants[1].auto)
	assert_true(south.variants[1].set_flags.is_empty())
	# Garde du nord : la variante d'Argenta attend le drapeau du J10.
	assert_eq(north.variants[0].if_flags, [&"pewter_arrived"] as Array[StringName])


## Jalon 11 (T20c) : chaque phrase que le compagnon peut choisir existe (et sa forme féminine),
## en narration (style « observer »), sans locuteur.
func test_companion_lines_exist_as_narration() -> void:
	var lines: Array[StringName] = [CompanionRules.LINE_TIRED, CompanionRules.LINE_UNWELL,
		CompanionRules.LINE_WATER]
	lines.append_array(CompanionRules.CONTEXT_LINES.values())
	lines.append_array(CompanionRules.GENERIC_LINES)
	for line: StringName in CompanionController.FEMININE_LINES:
		lines.append(StringName(String(line) + CompanionController.FEMININE_SUFFIX))
	for line: StringName in lines:
		assert_true(PLAYED_BY_COMPANION.has(line), "%s : listée" % line)
		var dialogue := _library.get_dialogue(line)
		assert_not_null(dialogue, "%s : définie" % line)
		if dialogue != null:
			assert_eq(dialogue.speaker, "", "%s : sans locuteur" % line)
			assert_true(dialogue.narration, "%s : narration" % line)
			assert_true(dialogue.variants[0].pages[0].text.begins_with("{pokemon} "), line)
	assert_eq(lines.size(), PLAYED_BY_COMPANION.size())


## Dialogues sans ceux de la carte de QA (`qa_*`, jalon 13 T14, retirés au T22).
func _real_ids() -> Array[StringName]:
	return _without_qa(_library.get_ids())


## Sans les cartes de QA ni les données du jalon 22 (fichiers `j22_*.json`, vérifiés par
## `test_j22_data.gd`).
func _without_qa(ids: Array[StringName]) -> Array[StringName]:
	var j22 := J22Ids.in_dir("res://data/dialogues/")
	var result: Array[StringName] = []
	for id: StringName in ids:
		if not MapCatalog.is_qa_map(id) and not j22.has(id):
			result.append(id)
	return result


const J22Ids := preload("res://tests/helpers/j22_ids.gd")
