extends GutTest
## Chapitre Johto, JOH6 (`docs/tech/jalon-joh6.md`) : données générées depuis les grilles
## (`tools/gen_joh6_data.py`) : textes du dossier joh-07 §16 mot pour mot (C-1 à C-46, A-1 et A-2 du
## dossier joh-10), Dresseurs §6, objets §7, rencontres par moment §5, PNJ de la semaine §11 (horloge
## injectée), contrat d'identifiants des PNJ d'histoire, données de monde. Les dialogues et scènes
## d'histoire (`joh6_story.json`, écrits à la main) sont vérifiés par `test_joh6_story.gd`.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

const PREFIX := "joh6_"
const DOSSIER_07 := "res://docs/design/dossier-joh-07-acajou.md"
const DOSSIER_10 := "res://docs/design/dossier-joh-10-mont-argente.md"
const GRILLE_LAC := "res://tools/plans/lake_of_rage.txt"
const MAPS: Array[StringName] = [&"burned_tower_1f", &"burned_tower_b1f", &"route_42", &"mahogany_town",
	&"mahogany_souvenir_shop", &"route_43", &"lake_of_rage", &"mahogany_hideout_b1f",
	&"mahogany_hideout_b2f", &"mahogany_hideout_b3f", &"mahogany_center", &"mahogany_house_1",
	&"mahogany_house_2"]
## Fichiers de dialogues générés ici (le fichier d'histoire est écrit à la main).
const GENERATED_FILES: Array[String] = ["joh6_burned_tower_1f", "joh6_route_42", "joh6_mahogany_town",
	"joh6_mahogany_souvenir_shop", "joh6_route_43", "joh6_lake_of_rage", "joh6_mahogany_hideout_b1f",
	"joh6_mahogany_hideout_b2f", "joh6_mahogany_hideout_b3f", "joh6_mahogany_house_1",
	"joh6_mahogany_house_2", "joh6_week"]
const BRACE_LINES: Array[String] = ["Encore toi ! Tu me suis partout ! / Tant mieux. Au puits, tu avais des "
	+ "Pokémon de rien du tout. / Montre-moi tes vrais Pokémon. Je fonce !", "Non, non, non ! Pas encore !",
	"Ta victoire ne change rien."]
const ALARM_LINES: Array[String] = ["Intrus ! Pas un pas de plus !", "Coupez l'alarme…",
	"Tu ne sortiras pas d'ici."]
## Dossier §6 et C-4, C-15, C-21 à C-23, C-27, C-31, C-40 à C-42 : Dresseur → [nom, équipe, répliques
## (avant, défaite, après)].
const TRAINERS: Dictionary = {
	&"burned_tower_1f_odile": ["Médium Odile", [[&"haunter", 46], [&"gengar", 48]],
		["Les esprits de la tour n'aiment pas les visiteurs.", "Ils t'acceptent, finalement.",
			"En bas, quelque chose respire."]],
	&"burned_tower_1f_sbire_p": ["Sbire Rocket", [[&"weezing", 48], [&"raticate", 48]],
		["Le patron veut ce qui dort en bas. Dégage !", "Le patron va être furieux.",
			"De toute façon, Brace est déjà en route."]],
	&"route_42_marcel": ["Pêcheur Marcel", [[&"gyarados", 47], [&"tentacruel", 46]],
		["Le lac est à moi aujourd'hui !", "Bon, partageons.", "À Acajou, les poissons deviennent bizarres."]],
	&"route_42_hector": ["Montagnard Hector", [[&"golem", 48], [&"onix", 47]],
		["Les montagnes forgent les Pokémon !", "Ils étaient mal forgés.",
			"Le Mont Creuset est fermé depuis l'éboulement."]],
	&"route_42_coralie": ["Nageuse Coralie", [[&"azumarill", 48], [&"staryu", 46]],
		["Tu nages bien ? Voyons ça !", "Tu nages mieux que moi.", "Acajou est juste après le lac."]],
	&"route_42_louis": ["Super Nerd Louis", [[&"magneton", 47], [&"electrode", 47]],
		["Mes Pokémon captent des ondes étranges depuis une semaine !", "Les ondes m'ont déconcentré.",
			"Elles viennent de l'est. D'Acajou, peut-être."]],
	&"route_43_sbire_q": ["Sbire Rocket", [[&"arbok", 52], [&"golbat", 52]],
		["Péage ! 1 000 Pokédollars pour passer. Ou tes Pokémon.", "Bon, c'est gratuit aujourd'hui.",
			"Le péager, devant, ne rigole pas."]],
	&"route_43_peager": ["Sbire péager", [[&"houndoom", 54], [&"weezing", 53]],
		["Tu veux passer sans payer ? Chez nous, ça se règle en combat.", "Le péage est fermé. Définitivement.",
			"Va voir le lac, si ça t'amuse. Les ondes, c'est notre œuvre."]],
	&"route_43_basile": ["Campeur Basile", [[&"nidoking", 52], [&"fearow", 51]],
		["La route du lac est à moi !", "Elle est à toi.", "Au milieu du lac, il y a un Léviator rouge. Rouge !"]],
	&"lake_of_rage_ludovic": ["Pêcheur Ludovic", [[&"gyarados", 52], [&"lapras", 51]],
		["Le lac est calme, enfin. Un combat pour fêter ça ?", "Bien joué.",
			"Les Léviator reviendront à la normale, j'espère."]],
	&"mahogany_hideout_b1f_sbire_alarme_1": ["Sbire Rocket", [[&"raticate", 55], [&"arbok", 55]], ALARM_LINES],
	&"mahogany_hideout_b1f_sbire_alarme_2": ["Sbire Rocket", [[&"muk", 56]], ALARM_LINES],
	&"mahogany_hideout_b1f_sbire_alarme_3": ["Sbire Rocket", [[&"houndour", 55], [&"golbat", 56]], ALARM_LINES],
	&"mahogany_hideout_b2f_sbire_r": ["Sbire Rocket", [[&"weezing", 57], [&"magneton", 56]],
		["Dante a dit : personne ne passe.", "Dante ne va pas aimer ça.",
			"Moi, j'ai choisi Dante. Les autres sont partis, les lâches."]],
	&"mahogany_hideout_b2f_sbire_s": ["Sbire Rocket", [[&"houndoom", 57], [&"murkrow", 56]],
		["On n'est plus pour Giovanni. On est pour Dante !", "Pour Dante… aïe.", "Il a un plan. Un vrai."]],
	&"mahogany_hideout_b2f_scientifique": ["Scientifique Rocket",
		[[&"electrode", 57], [&"magneton", 57], [&"porygon", 56]],
		["Mes ondes sont parfaites ! Tu ne toucheras pas à la porte !", "Erreur de mesure.",
			"Le mot de passe ? Je ne le dirai jamais. Jamais !"]],
	&"mahogany_hideout_b3f_brace": ["Brace", [[&"fearow", 63], [&"arbok", 63], [&"weezing", 64],
		[&"houndoom", 62]], BRACE_LINES],
}
## Dresseurs de la vue : [carte, position, case, regard, portée] (grilles) ; Dresseurs déclenchés par
## une scène (alarmes, Brace) à part.
const SEEN: Dictionary = {
	&"burned_tower_1f_odile": [&"burned_tower_1f", &"odile", Vector2i(4, 19), Vector2i.RIGHT, 2],
	&"burned_tower_1f_sbire_p": [&"burned_tower_1f", &"sbire_p", Vector2i(23, 14), Vector2i.LEFT, 3],
	&"route_42_hector": [&"route_42", &"hector", Vector2i(20, 7), Vector2i.LEFT, 2],
	&"route_42_marcel": [&"route_42", &"marcel", Vector2i(29, 13), Vector2i.RIGHT, 1],
	&"route_42_coralie": [&"route_42", &"coralie", Vector2i(40, 5), Vector2i.DOWN, 3],
	&"route_42_louis": [&"route_42", &"louis", Vector2i(53, 9), Vector2i.DOWN, 1],
	&"route_43_peager": [&"route_43", &"peager", Vector2i(12, 25), Vector2i.LEFT, 1],
	&"route_43_sbire_q": [&"route_43", &"sbire_q", Vector2i(8, 21), Vector2i.RIGHT, 2],
	&"route_43_basile": [&"route_43", &"basile", Vector2i(14, 10), Vector2i.LEFT, 2],
	&"lake_of_rage_ludovic": [&"lake_of_rage", &"ludovic", Vector2i(20, 39), Vector2i.UP, 1],
	&"mahogany_hideout_b2f_sbire_r": [&"mahogany_hideout_b2f", &"sbire_r", Vector2i(23, 14), Vector2i.UP, 3],
	&"mahogany_hideout_b2f_sbire_s": [&"mahogany_hideout_b2f", &"sbire_s", Vector2i(9, 13), Vector2i.DOWN, 1],
	&"mahogany_hideout_b2f_scientifique": [&"mahogany_hideout_b2f", &"scientifique", Vector2i(2, 4),
		Vector2i.RIGHT, 1],
}
## Dossier §7 et §11 : scène → [objet, nombre, trouvé dans le monde, drapeau].
const GIFTS: Dictionary = {
	&"burned_tower_1f_rappel": [&"revive", 1, true, &"got_burned_tower_1f_rappel"],
	&"burned_tower_1f_hyper_potion": [&"hyper_potion", 1, true, &"got_burned_tower_1f_hyper_potion"],
	&"burned_tower_b1f_peau_metal": [&"metal_coat", 1, true, &"got_burned_tower_b1f_peau_metal"],
	&"route_42_ultra_balls": [&"ultra_ball", 2, true, &"got_route_42_ultra_balls"],
	&"route_42_super_bonbon": [&"rare_candy", 1, true, &"got_route_42_super_bonbon"],
	&"route_43_max_potion": [&"max_potion", 1, true, &"got_route_43_max_potion"],
	&"lake_of_rage_rappel_max": [&"max_revive", 1, true, &"got_lake_of_rage_rappel_max"],
	&"mahogany_hideout_b1f_hyper_potion": [&"hyper_potion", 1, true,
		&"got_mahogany_hideout_b1f_hyper_potion"],
	&"mahogany_hideout_b2f_ultra_balls": [&"ultra_ball", 3, true, &"got_mahogany_hideout_b2f_ultra_balls"],
	&"mahogany_hideout_b2f_pp_plus": [&"pp_up", 1, true, &"got_mahogany_hideout_b2f_pp_plus"],
	&"mahogany_hideout_b3f_max_repousse": [&"max_repel", 2, true, &"got_mahogany_hideout_b3f_max_repousse"],
	&"week_saturday_gift": [&"hyper_potion", 3, false, &"week_saturday_gift"],
	&"week_sunday_gift": [&"max_revive", 1, false, &"week_sunday_gift"],
}
## Dossier §5 : table → [moments, terrain, taux, niveaux, poids par espèce].
const TABLES: Dictionary = {
	&"burned_tower_1f_floor": [[], &"floor", 15, [40, 44],
		{&"raticate": 30, &"golbat": 25, &"weezing": 20, &"haunter": 15, &"magmar": 10}],
	&"route_42_grass_day": [[&"morning", &"day"], &"grass", 25, [40, 45],
		{&"furret": 30, &"pidgeotto": 20, &"gloom": 20, &"marill": 15, &"fearow": 15}],
	&"route_42_grass_night": [[&"night"], &"grass", 25, [40, 45],
		{&"noctowl": 35, &"golbat": 25, &"gloom": 20, &"marill": 20}],
	&"route_42_water": [[], &"water", 10, [40, 45], {&"marill": 60, &"azumarill": 10, &"tentacruel": 30}],
	&"route_43_grass_day": [[&"morning", &"day"], &"grass", 25, [44, 48],
		{&"furret": 25, &"nidorino": 20, &"nidorina": 20, &"pidgeotto": 15, &"venomoth": 20}],
	&"route_43_grass_night": [[&"night"], &"grass", 25, [44, 48],
		{&"noctowl": 30, &"houndoom": 20, &"nidorino": 15, &"nidorina": 15, &"venomoth": 20}],
	&"lake_of_rage_grass_day": [[&"morning", &"day"], &"grass", 25, [45, 50],
		{&"nidorino": 25, &"nidorina": 25, &"furret": 25, &"pidgeotto": 25}],
	&"lake_of_rage_grass_night": [[&"night"], &"grass", 25, [45, 50],
		{&"sneasel": 20, &"noctowl": 30, &"houndoom": 20, &"venomoth": 30}],
	&"lake_of_rage_water": [[], &"water", 10, [45, 50],
		{&"magikarp": 50, &"marill": 20, &"azumarill": 10, &"gyarados": 20}],
}
## Textes qui ne sont pas des répliques de Dresseur : dialogue → [variante, texte du dossier].
const LINES: Dictionary = {
	&"burned_tower_1f_plancher_effondre": [0, "Le plancher a brûlé. / On voit une salle, en dessous."],
	&"route_42_panneau": [0, "**ROUTE 42** / Rosalia — Acajou"],
	&"route_42_porte_mont_creuset": [0, "Un éboulement bloque l'entrée. / Le passage est fermé."],
	&"mahogany_town_panneau_ville": [0, "**ACAJOU** / La ville des montagnes et des vieux secrets"],
	&"mahogany_town_habitant": [0, "Tu as vu l'homme en noir, tout à l'heure ? Il traînait une cage qui "
		+ "crépitait. / Il est entré quelque part en ville, mais où ?"],
	&"mahogany_town_habitante": [0, "Au Lac Colère, au nord, les Magicarpe sont devenus fous. / Ils évoluent "
		+ "tous en Léviator, et ils sont furieux."],
	&"mahogany_souvenir_shop_vendeur": [0, "Bienvenue ! Des souvenirs d'Acajou ? / … Non ? Alors ne traîne "
		+ "pas, je ferme bientôt."],
	&"route_43_panneau": [0, "**ROUTE 43** / Acajou — Lac Colère"],
	&"lake_of_rage_panneau": [0, "**LAC COLÈRE** / Ne pas déranger les Pokémon du lac"],
	&"lake_of_rage_pecheur": [0, "Tu l'as calmé ? Bravo ! / Ce Léviator était un Magicarpe, il y a dix jours. "
		+ "/ Des ondes viennent d'Acajou et forcent les Magicarpe à évoluer. / J'ai vu une antenne sur le toit "
		+ "de la boutique de souvenirs. Drôle d'endroit pour une antenne, non ?"],
	&"lake_of_rage_garde_forestier": [0, "La montagne est fermée. / Là-haut, la neige ne pardonne pas."],
	&"mahogany_hideout_b3f_generateur": [0, "Une énorme machine bourdonne. / Des câbles partent de la cage de "
		+ "Raikou. / Raikou sert de pile à la machine !"],
	&"week_saturday_samuel": [0, "Le samedi, je guide les randonneurs dans la montagne. / Tiens, en montagne, "
		+ "on n'en a jamais trop."],
	&"week_saturday_received": [0, "{joueur} reçoit 3 Hyper Potions !"],
	&"week_sunday_diane": [0, "Le dimanche, je sonne les cloches de Rosalia. / Elles réveillent les cœurs "
		+ "endormis. Prends ceci."],
	&"week_sunday_received": [0, "{joueur} reçoit un Rappel Max !"],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _items: ItemLibrary
var _trainers: TrainerLibrary
var _encounters: EncounterLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_encounters = EncounterLibrary.new(_pokemon)
	_encounters.load_dir()


func _flags(raised: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


## Texte des pages de la variante [param index] de [param id], à plat (sans « \n »).
func _said(id: StringName, index: int = 0) -> String:
	var dialogue := _dialogues.get_dialogue(id)
	assert_not_null(dialogue, String(id))
	if dialogue == null or dialogue.variants.size() <= index:
		return ""
	return _flat(dialogue.variants[index])


func _flat(variant: DialogueVariant) -> String:
	var parts := PackedStringArray()
	for page: DialoguePage in variant.pages:
		parts.append(page.text)
	return J22Ids.flat_text(" ".join(parts))


func _expected(text: String) -> String:
	return J22Ids.flat_text(text.replace("{joueur}", "{player}"))


func _spec(map_id: StringName, id: StringName) -> NpcSpec:
	var spec := NpcRoster.load_for_map(map_id).get_spec(id)
	assert_not_null(spec, "%s / %s" % [map_id, id])
	return spec


func _generated_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for name: String in GENERATED_FILES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/dialogues/%s.json" % name))
		assert_true(parsed is Dictionary, name)
		if parsed is Dictionary:
			for key: String in parsed:
				ids.append(StringName(key))
	return ids


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_gt(_generated_ids().size(), 60)


## Chaque réplique générée non marquée « draft » est dans le dossier joh-07 §16 (A-1 et A-2 : dossier
## joh-10 ; « Le lac est fou. » : grille du lac), mot pour mot.
func test_every_validated_line_is_in_the_dossiers() -> void:
	var source := _expected(FileAccess.get_file_as_string(DOSSIER_07) + "\n"
		+ FileAccess.get_file_as_string(DOSSIER_10) + "\n" + FileAccess.get_file_as_string(GRILLE_LAC)
		# JOH8 : H-38, la variante de Diane après le sommet.
		+ "\n" + FileAccess.get_file_as_string("res://docs/design/dossier-joh-09-tour-carillon.md"))
	var checked := 0
	for id: StringName in _generated_ids():
		var dialogue := _dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null or dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				checked += 1
				assert_true(source.contains(J22Ids.flat_text(page.text.replace("{joueur}", "{player}"))),
					"%s : « %s »" % [id, page.text])
	assert_gt(checked, 70)


## Les textes complets (aucune phrase perdue ni ajoutée) : panneaux, habitants, vendeur, pêcheur,
## garde, générateur, Samuel et Diane.
func test_full_texts_follow_the_dossier() -> void:
	for id: StringName in LINES:
		assert_eq(_said(id, LINES[id][0]), _expected(LINES[id][1]), String(id))
	assert_eq(_said(&"lake_of_rage_garde_forestier", 1), _expected(
		"Le Mont Argenté ? Des hommes en noir y sont montés cette nuit. / Je n'ai pas pu les arrêter. Toi, "
		+ "peut-être. Passe."), "A-2")
	assert_eq(_said(&"mahogany_souvenir_shop_vendeur", 1), _expected(
		"Hé ! Qui t'a permis de… / … Tant pis. De toute façon, Brace t'attend."), "C-29")
	assert_eq(_said(&"lake_of_rage_pecheur", 1), "Le lac est fou.", "grille du lac")
	assert_eq(_said(&"week_saturday_samuel", 1), "À samedi, sur les sentiers !")
	# JOH8 : H-38 en variante 1, la réplique de fin passe en 2.
	assert_eq(_said(&"week_sunday_diane", 2), "Reviens un dimanche écouter les cloches.")


func test_panels_keep_title_and_text_on_one_page() -> void:
	var page: DialoguePage = _dialogues.get_dialogue(&"route_42_panneau").variants[0].pages[0]
	assert_eq(page.text, "ROUTE 42\nRosalia — Acajou")
	assert_eq(_dialogues.get_dialogue(&"route_42_panneau").variants[0].pages.size(), 1)
	assert_eq(_dialogues.get_dialogue(&"mahogany_town_panneau_ville").variants[0].pages.size(), 1)
	# Bulles de 32 caractères et 2 lignes au plus (panneaux : titre + 2 lignes).
	for id: StringName in _generated_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			for p: DialoguePage in variant.pages:
				var lines := p.text.split("\n")
				assert_lte(lines.size(), 3, "%s : %s" % [id, p.text])
				for line: String in lines:
					assert_lte(line.length(), 34, "%s : %s" % [id, line])


func test_trainers_follow_dossier_6() -> void:
	assert_eq(TRAINERS.size(), 17)
	for id: StringName in TRAINERS:
		assert_true(_trainers.has_trainer(id), String(id))
		if not _trainers.has_trainer(id):
			continue
		var trainer := _trainers.get_trainer(id)
		assert_eq(trainer.name, TRAINERS[id][0], String(id))
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], String(id))
		var expected_prize := 45
		if str(id).ends_with("_odile") or str(id).contains("route_42") or str(id).ends_with("basile") \
				or str(id).ends_with("ludovic"):
			expected_prize = 40
		if str(id).ends_with("_brace"):
			expected_prize = 60
		assert_eq(trainer.prize_per_level, expected_prize, "%s : prix par niveau" % id)
		assert_eq(trainer.ai, &"smart" if str(id).ends_with("_brace") else &"random", "%s : IA" % id)
		var lines: Array = TRAINERS[id][2]
		for i: int in 3:
			var suffix: String = ["before", "defeated", "after"][i]
			assert_eq(_said(StringName("%s_%s" % [id, suffix])), _expected(lines[i]),
				"%s_%s" % [id, suffix])


func test_seen_trainers_are_placed_by_the_grids() -> void:
	for id: StringName in SEEN:
		var info: Array = SEEN[id]
		var spec := _spec(info[0], info[1])
		if spec == null:
			continue
		assert_eq([spec.trainer_id, spec.cell, spec.facing, spec.sight], [id, info[2], info[3], info[4]],
			String(id))
		assert_eq(spec.dialogue, StringName("%s_after" % id), "réplique après")
		assert_eq(spec.before_dialogue, StringName("%s_before" % id))
		assert_eq(spec.defeated_dialogue, StringName("%s_defeated" % id))
	# Inévitables (grilles) : Louis (passage de l'éperon), le péager, le Scientifique devant la porte.
	for pair: Array in [[&"route_42", &"louis"], [&"route_43", &"peager"],
			[&"mahogany_hideout_b2f", &"scientifique"]]:
		assert_eq(_spec(pair[0], pair[1]).sight, 1, "%s : inévitable (portée 1 sur le seul passage)" % pair[1])


## Alarmes du B1F et Brace du B3F : Dresseurs déclenchés par une scène, pas par la vue (contrat).
func test_scene_triggered_trainers() -> void:
	for n: int in [1, 2, 3]:
		var id := StringName("sbire_alarme_%d" % n)
		var spec := _spec(&"mahogany_hideout_b1f", id)
		if spec == null:
			continue
		assert_eq(spec.trainer_id, StringName("mahogany_hideout_b1f_%s" % id))
		assert_eq(spec.sight, 0, "la vue ne le déclenche pas")
		assert_eq(spec.if_flags, [StringName("johto_alarm_%d" % n)] as Array[StringName])
	var cells := [Vector2i(10, 1), Vector2i(19, 13), Vector2i(24, 1)]
	for i: int in 3:
		assert_eq(_spec(&"mahogany_hideout_b1f", StringName("sbire_alarme_%d" % (i + 1))).cell, cells[i])
	var brace := _spec(&"mahogany_hideout_b3f", &"brace")
	assert_eq(brace.trainer_id, &"", "aucun bloc « trainer » : la scène lance le combat")
	assert_eq(brace.unless_flags, [&"johto_brace_defeated_2"] as Array[StringName])
	assert_eq(brace.dialogue, &"mahogany_hideout_b3f_brace_after")
	assert_eq(brace.cell, Vector2i(12, 8))
	assert_true(_trainers.has_trainer(&"mahogany_hideout_b3f_brace"))
	assert_eq(_said(&"mahogany_hideout_b3f_brace_after"), "Ta victoire ne change rien.", "1re bulle de C-42")


func test_items_and_gifts_once() -> void:
	for id: StringName in GIFTS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var expected: Array = GIFTS[id]
		assert_eq(cutscene.variants.size(), 1, String(id))
		var variant := cutscene.variants[0]
		assert_eq(variant.unless_flags, [expected[3]] as Array[StringName], "%s : une fois" % id)
		var gives := 0
		var sets := false
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				gives += 1
				assert_eq([step.item_id, step.count, step.found], expected.slice(0, 3), String(id))
				assert_true(_items.has_item(step.item_id), String(step.item_id))
			if step.kind == CutsceneStep.Kind.SET_FLAGS:
				sets = sets or step.flags.has(expected[3])
		assert_eq(gives, 1, String(id))
		assert_true(sets, "%s : drapeau posé" % id)
	# Objets visibles : PNJ « prendre », absent une fois pris ; Hyper Potion du B1F de la tour : cachée.
	var rappel := _spec(&"burned_tower_1f", &"rappel")
	assert_eq(rappel.verb, Interaction.Kind.TAKE)
	assert_eq(rappel.unless_flags, [&"got_burned_tower_1f_rappel"] as Array[StringName])
	assert_eq(rappel.dialogue, &"burned_tower_1f_rappel")
	assert_null(NpcRoster.load_for_map(&"burned_tower_1f").get_spec(&"hyper_potion"), "cachée sous la poutre")
	assert_true(_dialogues.has_dialogue(&"burned_tower_1f_hyper_potion"))


func test_encounter_tables_by_period() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		var info: Array = TABLES[id]
		assert_eq(table.periods, info[0] as Array[StringName], "%s : moments" % id)
		assert_eq(table.terrain, info[1], "%s : terrain" % id)
		assert_eq(table.rate, info[2], "%s : taux" % id)
		var weights: Dictionary = info[4]
		assert_eq(table.total_weight(), 100, String(id))
		var seen: Dictionary = {}
		for slot: EncounterSlot in table.slots:
			assert_true(weights.has(slot.species), "%s : %s" % [id, slot.species])
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], info[3], "%s : %s" % [id, slot.species])
			seen[slot.species] = true
			assert_true(_pokemon.has_species(slot.species), String(slot.species))
			for back: bool in [false, true]:
				assert_true(BattleArt.new().has_image(slot.species, back),
					"%s : sprite %s" % [slot.species, "dos" if back else "face"])
		assert_eq(seen.size(), weights.size(), String(id))
	# La table du moment (JOH0 §2.5).
	for pair: Array in [[&"route_42", &"route_42"], [&"route_43", &"route_43"], [&"lake_of_rage", &"lake_of_rage"]]:
		var map_id: StringName = pair[0]
		for period: StringName in [&"morning", &"day"]:
			assert_eq(_encounters.get_table(map_id, &"grass", period).id, StringName("%s_grass_day" % map_id))
		assert_eq(_encounters.get_table(map_id, &"grass", &"night").id, StringName("%s_grass_night" % map_id))
	# Eau et cendres : toute la journée (tables sans moment) ; rien au B1F de la tour ni au repaire.
	for period: StringName in [&"morning", &"day", &"night", &""]:
		assert_eq(_encounters.get_table(&"route_42", &"water", period).id, &"route_42_water")
		assert_eq(_encounters.get_table(&"lake_of_rage", &"water", period).id, &"lake_of_rage_water")
		assert_eq(_encounters.get_table(&"burned_tower_1f", &"floor", period).id, &"burned_tower_1f_floor")
	for map_id: StringName in [&"burned_tower_b1f", &"mahogany_hideout_b1f", &"mahogany_hideout_b2f",
			&"mahogany_hideout_b3f", &"mahogany_town"]:
		for terrain: StringName in [&"grass", &"floor", &"water"]:
			assert_false(_encounters.has_table(map_id, terrain, &"night"), "%s / %s" % [map_id, terrain])
	assert_false(_encounters.has_table(&"route_43", &"water"), "pas d'eau sur la Route 43")


func test_super_rod_of_the_lake() -> void:
	var tables := WaterRodTables.new(_pokemon)
	assert_true(tables.load_game_files(), "\n".join(tables.get_errors()))
	var table := tables.get_table(&"super_rod", &"lake_of_rage")
	assert_eq(table.id, &"super_rod_lake_of_rage")
	var seen: Dictionary = {}
	for slot: EncounterSlot in table.slots:
		seen[slot.species] = [slot.min_level, slot.weight]
	assert_eq(seen, {&"magikarp": [40, 1], &"gyarados": [50, 1]})
	assert_eq(tables.get_table(&"old_rod", &"lake_of_rage").id, tables.get_table(&"old_rod", &"route_6").id,
		"la Canne : Magicarpe comme partout")


## Samuel le samedi (Acajou), Diane le dimanche (Rosalia) avec une horloge injectée ; don une fois.
func test_week_npcs_with_an_injected_clock() -> void:
	var clock := WorldClock.new()
	var device := FixedClock.new("2026-11-07T15:00:00") # un samedi
	clock.start_on_device(device)
	assert_eq(clock.weekday_name(), &"saturday")
	var samuel := _spec(&"mahogany_town", &"samuel")
	assert_eq([samuel.cell, samuel.dialogue, samuel.sprite], [Vector2i(4, 14), &"week_saturday_samuel",
		&"mountaineer"])
	assert_eq(samuel.if_weekdays, [&"saturday"] as Array[StringName])
	assert_true(samuel.is_present(_flags(), clock.period_name(), clock.weekday_name()), "samedi")
	var diane := _spec(&"ecruteak_city", &"diane")
	assert_eq([diane.cell, diane.dialogue], [Vector2i(23, 13), &"week_sunday_diane"])
	assert_eq(diane.if_weekdays, [&"sunday"] as Array[StringName])
	assert_false(diane.is_present(_flags(), clock.period_name(), clock.weekday_name()), "pas le samedi")
	device.iso = "2026-11-08T10:00:00" # dimanche
	clock.sync()
	assert_eq(clock.weekday_name(), &"sunday")
	assert_true(diane.is_present(_flags(), clock.period_name(), clock.weekday_name()), "dimanche")
	assert_false(samuel.is_present(_flags(), clock.period_name(), clock.weekday_name()), "pas le dimanche")
	device.iso = "2026-11-04T10:00:00" # mercredi
	clock.sync()
	assert_false(samuel.is_present(_flags(), clock.period_name(), clock.weekday_name()), "mercredi")
	assert_false(diane.is_present(_flags(), clock.period_name(), clock.weekday_name()), "mercredi")
	for entry: Array in [[&"week_saturday_samuel", &"week_saturday_gift", &"saturday"],
			[&"week_sunday_diane", &"week_sunday_gift", &"sunday"]]:
		var dialogue := _dialogues.get_dialogue(entry[0])
		var gift := dialogue.pick(_flags(), null, 0, Callable(), Callable(), Callable(), &"day", entry[2])
		assert_eq(gift.cutscene, entry[1], "%s : don" % entry[0])
		assert_eq(gift.pages.size(), 2)
		var after := dialogue.pick(_flags([entry[1]]), null, 0, Callable(), Callable(), Callable(), &"day",
			entry[2])
		assert_eq(after.cutscene, &"", "%s : plus de don" % entry[0])
	for id: StringName in [&"week_saturday_received", &"week_sunday_received"]:
		var text := _dialogues.get_dialogue(id).variants[0].pages[0].text
		assert_eq(DialogueTokens.tokens_in(text), [DialogueTokens.PLAYER] as Array[StringName])


## Retouches de Rosalia (C-1, C-2, C-3, C-11, C-12) : lues par la ville (`gen_joh2_data.py`).
func test_rosalia_retouches() -> void:
	var sage := _dialogues.get_dialogue(&"ecruteak_city_sage_tour")
	var act2: Array[StringName] = [&"johto_act2"]
	var open: Array[StringName] = [&"johto_act2", &"johto_burned_tower_open"]
	assert_eq(_flat(sage.pick(_flags(act2))),
		_expected("Le doyen t'attend, jeune Dresseur. / Toute la ville a entendu la radio."), "C-1")
	assert_true(sage.pick(_flags(open)).draft, "après l'ouverture : texte [D]")
	assert_eq(sage.pick(_flags()).pages[0].text, "Vous n'obtiendrez rien de moi.", "acte 1 inchangé")
	var doyen := _dialogues.get_dialogue(&"ecruteak_elders_house_doyen")
	var first := doyen.pick(_flags(act2))
	assert_eq(first.set_flags, [&"johto_burned_tower_open"] as Array[StringName], "le doyen ouvre la tour")
	assert_eq(_flat(first), _expected("Tu es revenu. Et avec tes vrais compagnons, cette fois. / Cet homme, à la radio… « quand "
			+ "tout sera cendres ». / Je crains qu'il ne parle de notre tour. / Je t'ouvre la Tour Cendrée. Va "
			+ "voir si les trois dorment toujours."), "C-2")
	var again := doyen.pick(_flags(open))
	assert_eq(again.set_flags, [] as Array[StringName])
	assert_eq(J22Ids.flat_text(again.pages[0].text), "Va voir si les trois dorment toujours.")
	var plan := doyen.pick(_flags([&"johto_act2", &"johto_burned_tower_open", &"johto_dante_plan_known"]))
	assert_eq(J22Ids.flat_text(plan.pages[0].text),
		"L'homme qui a pris Raikou est parti vers l'est. Vers Acajou.", "fin de C-11")
	var garde := _dialogues.get_dialogue(&"ecruteak_city_garde_carillon")
	assert_eq(_flat(garde.pick(_flags(act2))), _expected("La Tour Carillon reste fermée. / Le doyen dit que le "
		+ "moment n'est pas encore venu."), "C-12")
	assert_true(garde.pick(_flags()).pages[0].text.begins_with("La Tour Carillon est sacrée"), "R-20")
	assert_eq(_said(&"ecruteak_city_panneau_tour_cendree"), _expected("**TOUR CENDRÉE** / Elle brûla il y a "
		+ "cent cinquante ans. Ne pas allumer de feu."), "C-3")
	var roster := NpcRoster.load_for_map(&"ecruteak_city")
	assert_eq(roster.get_spec(&"garde_route_42").unless_flags, [&"johto_act2"] as Array[StringName],
		"à l'acte 2, le garde de la Route 42 s'efface")


func test_vendor_and_fisher_variants() -> void:
	var vendor := _dialogues.get_dialogue(&"mahogany_souvenir_shop_vendeur")
	var before := vendor.pick(_flags())
	assert_eq([before.action, before.shop], [&"open_shop", &"mahogany_mart"], "C-19 puis la Boutique")
	var found := vendor.pick(_flags([&"johto_hideout_found"]))
	assert_eq(found.action, &"", "C-29 : plus de Boutique")
	assert_true(found.pages[0].text.begins_with("Hé !"))
	var spec := _spec(&"mahogany_souvenir_shop", &"vendeur")
	assert_eq([spec.cell, spec.sprite], [Vector2i(7, 3), &"clerk"])
	var fisher := _dialogues.get_dialogue(&"lake_of_rage_pecheur")
	assert_eq(fisher.pick(_flags()).pages[0].text, "Le lac est fou.")
	assert_true(fisher.pick(_flags([&"johto_red_gyarados_done"])).pages[0].text.begins_with("Tu l'as calmé"))
	var guard := _dialogues.get_dialogue(&"lake_of_rage_garde_forestier")
	assert_true(guard.pick(_flags()).pages[0].text.begins_with("La montagne est fermée"), "A-1")
	assert_true(guard.pick(_flags([&"johto_act3"])).pages[0].text.begins_with("Le Mont Argenté"), "A-2")
	assert_false(guard.draft)
	# Barrière du sentier jusqu'à l'acte 3 (scène d'un pas en arrière, comme les gardes de Rosalia).
	var scene := _cutscenes.get_cutscene(&"lake_trail_guard")
	assert_not_null(scene)
	assert_eq(scene.variants[0].unless_flags, [&"johto_act3"] as Array[StringName])


func test_shop_of_the_souvenir_store() -> void:
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir(), "\n".join(shops.get_errors()))
	assert_true(shops.check_references(_items), "\n".join(shops.get_errors()))
	var shop := shops.get_shop(&"mahogany_mart")
	assert_not_null(shop)
	assert_eq(shop.item_ids(), [&"ultra_ball", &"hyper_potion", &"max_potion", &"full_heal", &"revive",
		&"max_repel", &"escape_rope"] as Array[StringName])


## Contrat d'identifiants des PNJ d'histoire (dialogues et scènes écrits à la main dans joh6_story).
func test_story_actors_follow_the_contract() -> void:
	for id: StringName in [&"raikou", &"entei", &"suicune"]:
		var beast := _spec(&"burned_tower_b1f", id)
		assert_eq(beast.sprite, StringName("pokemon/%s" % id))
		assert_eq(beast.unless_flags, [&"johto_beasts_awakened"] as Array[StringName])
		assert_false(beast.turn_to_player)
		assert_eq(beast.dialogue, &"", "pas de dialogue : la scène les réveille")
	assert_eq(_spec(&"burned_tower_b1f", &"raikou").cell, Vector2i(8, 8))
	assert_null(NpcRoster.load_for_map(&"burned_tower_b1f").get_spec(&"brace"), "Brace surgit (spawn)")
	var gyarados := _spec(&"lake_of_rage", &"leviator_rouge")
	assert_eq([gyarados.sprite, gyarados.dialogue, gyarados.turn_to_player],
		[&"pokemon/gyarados_red", &"joh6_red_gyarados", false])
	assert_eq(gyarados.unless_flags, [&"johto_red_gyarados_done"] as Array[StringName])
	var deserter := _spec(&"mahogany_hideout_b2f", &"deserteur")
	assert_eq([deserter.sprite, deserter.dialogue, deserter.cell], [&"rocket_grunt_m", &"joh6_deserter",
		Vector2i(7, 18)])
	assert_eq(deserter.unless_flags, [&"johto_raikou_done"] as Array[StringName])
	var raikou := _spec(&"mahogany_hideout_b3f", &"raikou")
	assert_eq([raikou.sprite, raikou.dialogue, raikou.cell], [&"pokemon/raikou", &"joh6_raikou",
		Vector2i(17, 9)])
	assert_eq(raikou.unless_flags, [&"johto_raikou_done"] as Array[StringName])
	var center := NpcRoster.load_for_map(&"mahogany_center")
	assert_not_null(center.get_spec(&"nurse"))
	var after := center.get_spec(&"deserteur")
	assert_eq([after.dialogue, after.if_flags], [&"joh6_deserter_center", [&"johto_raikou_done"]])
	# Les habitants des maisons parlent (textes [D]).
	assert_eq(_spec(&"mahogany_house_1", &"habitante").dialogue, &"mahogany_house_1_habitante")
	assert_eq(_spec(&"mahogany_house_2", &"habitant_1").dialogue, &"mahogany_house_2_habitant_1")


func test_zone_texts_and_world_data() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var texts: Dictionary = {
		&"burned_tower": "Une tour noircie, où dorment les légendes.",
		&"route_42": "Une route entre lac et montagne, vers Acajou.",
		&"mahogany_town": "Une petite ville de montagne, plus secrète qu'elle n'en a l'air.",
		&"route_43": "Une route boisée, vers le Lac Colère.",
		&"lake_of_rage": "Un grand lac de montagne, troublé par d'étranges ondes.",
		&"mahogany_hideout": "Le repaire de la Team Rocket, sous Acajou.",
	}
	for id: StringName in texts:
		assert_eq(zones.get_zone(id).description, texts[id], String(id))
		assert_false(zones.get_zone(id).draft, "%s : descriptions validées (dossier §16)" % id)
		assert_eq(zones.get_zone(id).region, ZoneData.REGION_JOHTO, String(id))
	assert_eq(zones.get_zone(&"mahogany_town").maps.size(), 5)
	assert_eq(zones.zone_of(&"mahogany_souvenir_shop"), &"mahogany_town")
	assert_eq(zones.zone_of(&"burned_tower_b1f"), &"burned_tower")
	assert_eq(zones.zone_of(&"dante_flashback_hq"), &"mahogany_hideout")
	var rest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/rest_points.json"))
	assert_true((rest["points"] as Dictionary).has("mahogany_center"), "point de repos « Acajou »")
	var fly: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/fly_points.json"))
	var found := false
	for point: Dictionary in fly["points"]:
		if point["zone"] == "mahogany_town":
			found = true
			assert_eq([point["map"], point["spawn"]], ["mahogany_town", "from_center"])
	assert_true(found, "point de Vol Acajou")
	var lighting: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/lighting.json"))
	var maps: Dictionary = lighting["maps"]
	for map_id: StringName in [&"burned_tower_1f", &"burned_tower_b1f", &"route_42", &"mahogany_town",
			&"route_43", &"lake_of_rage", &"mahogany_center", &"mahogany_souvenir_shop", &"mahogany_house_1",
			&"mahogany_house_2", &"mahogany_hideout_b1f", &"mahogany_hideout_b2f", &"mahogany_hideout_b3f",
			&"dante_flashback_hq"]:
		assert_true(maps.has(String(map_id)), "lumière de %s" % map_id)
		var profile: String = maps[String(map_id)]
		assert_true(profile == "johto_auto" or (lighting["profiles"] as Dictionary).has(profile),
			"profil de %s" % map_id)
	var music: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/music_zones.json"))
	for id: StringName in texts:
		assert_true((music["zones"] as Dictionary).has(String(id)), "musique de %s" % id)
