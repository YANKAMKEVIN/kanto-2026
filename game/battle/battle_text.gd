class_name BattleText
extends RefCounted
## Phrases des messages de combat, à partir des modèles de `data/battle/messages.json`
## (jalon 4 §2.2, décisions de Kevin du §8 point 5). Classe pure.
##
## Format :
## [codeblock]
## {
##   "templates": {
##     "sent_out_foe": { "text": "{trainer} envoie {pokemon} !" },
##     "move_used": { "text": "{pokemon} utilise {move} !", "draft": true },
##     "recoil": { "text": "{pokemon} est blessé par le contrecoup !",
##                 "text_f": "{pokemon} est blessée par le contrecoup !" }, ...
##   },
##   "stats": { "atk": "L'Attaque", ... }
## }
## [/codeblock]
## Tous les modèles de [constant TEMPLATE_IDS] sont obligatoires, aucun autre n'est admis.
## Marques admises : {pokemon} (nom seul, jamais « ennemi » ni « du Rival »), {de_pokemon}
## (« de Salamèche », « d'Évoli »), {species} (nom de l'espèce de l'événement), {move},
## {trainer}, {stat} (nom de « stats »), {level} (niveau de l'événement), {exp} (son
## [member BattleEvent.amount]), {old_move} (capacité oubliée, seulement par
## [method line_for]), {item} (nom de la Ball, [member BattleEvent.item_name]).
## Capture (jalon 5D) : BALL_THROWN → « ball_thrown » ; BROKE_FREE → « broke_free » ;
## BALL_SHAKE, CAUGHT et BATTLE_ENDED (CAUGHT) n'ont pas de phrase. La carte de capture
## (dossier 05 §17) demande à [method line_for], avec l'événement CAUGHT (accord au féminin) :
## « caught_title » (« Roucool CAPTURÉ ! » ; la carte l'affiche en capitales), « pokedex_new »
## (seulement pour une nouvelle entrée), puis « joined_party » ou « sent_to_storage ».
## XP (jalon 5C) : EXP_GAINED et LEVEL_UP n'ont pas de phrase : le bilan de fin de combat
## raconte la progression (demande n° 1, décision de Kevin du 2026-10-06 : il remplace « … monte
## au niveau … ! ») ; MOVE_LEARNED → « move_learned » ; MOVE_FORGET_OFFERED →
## « move_forget_prompt ». La suite de l'oubli (« move_forgot », « move_not_learned ») ne
## vient pas d'un événement : la présentation la demande à [method line_for].
## Soin (jalon 6) : ITEM_USED → « item_used » (« Tu utilises Potion sur Salamèche. »), puis
## « hp_restored » ({amount} : PV rendus, [member BattleEvent.amount] ; pas de phrase si aucun
## PV n'est rendu : l'Antidote).
## Statuts (jalon 9, le poison) : STATUS_INFLICTED, STATUS_UNCHANGED, STATUS_DAMAGED,
## STATUS_CURED → « status_inflicted_<statut> », « status_unchanged_<statut> »,
## « status_damaged_<statut> », « status_cured_<statut> » ([member BattleEvent.status] ; pas de
## phrase pour un statut sans modèle). Immunité : NO_EFFECT (« no_effect »).
## Jalon 11 (dossier 14 §13, lot validé le 2026-10-10) : paralysie, sommeil, brûlure, gel avec
## les mêmes préfixes, plus STATUS_PREVENTED → « status_prevented_<statut> » (ne peut pas agir)
## et STATUS_ENDED → « status_ended_<statut> » (réveil, dégel) ; FAILED → « move_failed »
## (« Mais ça échoue ! », cas nouveaux du J11 seulement). Confusion : CONFUSED →
## « confusion_inflicted », CONFUSION_UNCHANGED → « confusion_unchanged », CONFUSION_CHECK →
## « confusion_check », HURT_ITSELF → « confusion_hurt », CONFUSION_ENDED → « confusion_ended » ;
## MULTI_HIT → « multi_hit » ({amount} : coups portés) ; FLINCHED → « flinched » ; FOCUSED →
## « focused ». Patience (n° 28 à 32) : BIDE_STARTED → « bide_started », BIDE_STORING →
## « bide_storing », BIDE_UNLEASHED → « bide_unleashed », BIDE_BROKEN → « bide_broken » (riposte
## à vide : FAILED, « Mais ça échoue ! »).
## Jalon 14 (dossier 17 §15, n° 52 à 57) : CHARGE_STARTED → « charge_<texts>_start » et
## CHARGE_BROKEN → « charge_<texts>_broken » ([member MoveEffect.texts] de l'effet CHARGE de la
## capacité [member BattleEvent.move_id] ; pas de phrase sans modèle) ; CHARGE_RELEASED : pas de
## phrase (le MOVE_USED suit) ; DODGED → « dodged » ; BALL_BLOCKED → « ball_blocked » ;
## TELEPORTED → « teleported » ; NOTHING_HAPPENED → « nothing_happened ». Super Bonbon (T18b,
## n° 62) : « rare_candy_level » ({level} : le niveau atteint), sans événement du moteur (le voile
## du Sac le demande à [method line_for]).
## Passe systèmes 2 : OHKO → « ohko » (K.O. en un coup) ; HEALED → « heal » ; SCREEN_STARTED /
## SCREEN_ENDED → « screen_started_<camp> » / « screen_ended_<camp> » ({move} : le mur) ;
## STATS_RESET → « haze ».
## Jalon 19 : RECHARGING → « recharging » (Ultralaser) ; SCARED_AWAY → « scared_away »
## (Hurlement, combat sauvage) ; FORCED_OUT → « forced_out » (Hurlement contre un Dresseur, puis
## « sent_out_player » ou « sent_out_foe » du remplaçant).
## Jalon 19, mode SPECTRE (dossier 22 §15.3 et §15.7, validés) : SENT_OUT adverse masqué
## ([member BattleEvent.disguised]) → « ghost_appeared » puis « ghost_unidentified » (au lieu de
## « wild_appeared ») ; GHOST_SCARED → « ghost_scared » ; GHOST_SPOKE → « ghost_spoke ». Sans
## événement ([method get_template]) : « ghost_name » (nom affiché du SPECTRE, posé par le
## directeur) et « ghost_ball_refused » (Ball refusée avant le lancer). La fuite garde « fled ».
## Changement de Pokémon (jalon 7) : WITHDRAWN → « withdrawn » (« Reviens, Salamèche ! ») ; le
## Pokémon envoyé reprend « sent_out_player ». Côté adverse (jalon 13, IA qui change, §21 n° 60) :
## « withdrawn_foe » (« {trainer} rappelle {pokemon} ! »), puis « sent_out_foe ». Le panneau ÉQUIPE lit, sans événement
## ([method get_template]), « switch_reason_active », « switch_reason_fainted » (raisons sur
## les cartes) et « replace_prompt » (son titre après un K.O.).
## Argent (jalon 7) : « prize_won » ({money} : somme formatée, « 280 ₽ ») ne vient pas d'un
## événement du moteur ; le directeur le demande à [method prize_line] après une victoire.
## Bilan de fin de combat (demande n° 1) : libellés courts, sans événement — « summary_exp »
## ([method summary_exp], « +11 XP »), « summary_level » ([method summary_level], « Nv. 9 »),
## « summary_stat » ({stat} : nom court de « stat_labels », {amount} ; [method summary_stats] :
## « PV +2 · Attaque +1 »), « summary_continue » (consigne « Touchez l'écran pour continuer »).
## Évolution (jalon 9, lot verrouillé le 2026-10-07, bloc B) : sans événement du moteur ;
## [EvolutionDirector] les demande à [method line_for] avec un événement qui porte le nom du
## Pokémon [b]d'avant[/b] l'évolution — « evolution_started » (« Quoi ? {pokemon} évolue ! »),
## « evolution_finished » ({species} : nom de [member BattleEvent.species_id], la nouvelle
## espèce), « evolution_cancelled » ; « evolution_stop » est le libellé du bouton ARRÊTER
## ([method get_template]).
## « stat_labels » (facultatif ; s'il est là, complet) : noms courts des six statistiques
## ([constant SpeciesData.STATS]) ; sans lui, l'identifiant de la statistique est écrit.
## « draft » : texte à relire par Kevin. « text_f » (facultatif) : la phrase accordée au
## féminin, employée quand le Pokémon de l'événement est une femelle (décision de Kevin
## n° 15, jalon 4 §8) ; sans elle, « text » sert pour tous. [method lines] traduit un
## [BattleEvent] en 0, 1 ou plusieurs phrases (un coup critique super efficace en donne
## deux). Un dresseur sans message de fin ([member TrainerData.end_message] faux : premier
## combat du rival, dont les répliques en tiennent lieu) n'a pas de phrase à la fin ; de
## même, sans message de début ([member TrainerData.start_message] faux, décision n° 17 :
## « On ne va quand même pas partir… » lance le combat), pas de « … veut se battre ! ».
## Jalon 12 (dossier 15 §20 n° 46, annexe A.4 de `jalon-12.md`) : DRAINED_HP → « drain_hp » ;
## TRAPPED et TRAP_DAMAGED → « trap_<famille>_started » et « trap_<famille>_damaged », la famille
## étant [member MoveEffect.messages] de l'effet TRAP de [member BattleEvent.move_id] (Ligotage
## « wrap », Étreinte « bind », Danse Flamme « fire_spin », Claquoir « clamp » au jalon 13) ;
## TRAP_ENDED → « trap_ended » ;
## MOVE_DISABLED → « move_disabled », DISABLE_ENDED → « disable_ended » ({move} : la capacité
## bloquée) ; RESTED → « rested » ; SELF_KO : pas de phrase (celle du FAINTED suit). Sans
## événement ([method get_template], T14) : « switch_reason_trapped » (raison sur les cartes de
## l'équipe : « Impossible de changer ») et « move_disabled_label » (carte de capacité :
## « BLOQUÉE »).
## Jackpot (jalon 15, `jalon-15.md` §2.7.3) : COINS_SCATTERED → « coins_scattered » ; à la fin
## du combat, « coins_collected » ({money}, [method coins_line]) après « prize_won ».
## Textes de l'annexe A de `jalon-15.md` (A.1), validés par Kevin le 2026-10-14 (Q-1).
## J23 (rencontre Safari, dossier 26 §8, textes 20 à 29 validés le 2026-10-16) : SENT_OUT du
## sauvage → « wild_appeared » (texte 20) ; SAFARI_BALL_THROWN → « safari_ball_thrown » (21) ;
## BAIT_THROWN → « safari_bait » (22) ; ROCK_THROWN → « safari_rock » (23) ; SAFARI_EATING →
## « safari_eating » (24) ; SAFARI_ANGRY → « safari_angry » (25) ; SAFARI_FLED → « safari_fled »
## (26) ; SAFARI_LEFT → « safari_left » (27) ; capture : textes existants (28) ;
## SAFARI_NO_BALLS → « safari_no_balls » (29). Libellés des quatre boutons, sans événement
## ([method get_template], [method safari_ball_label]) : « safari_action_ball » ({amount} : Balls
## restantes), « safari_action_bait », « safari_action_rock », « safari_action_run ».
## Nom du dresseur (OUV.2, dossier 13 §3.5) : il peut porter un jeton de [DialogueTokens]
## (`"name": "{rival}"`), résolu avec [member token_values] (posé par Boot) ; sans valeur, le nom
## reste tel quel.

const DATA_PATH: String = "res://data/battle/messages.json"
const TEMPLATE_IDS: Array[StringName] = [
	&"battle_started", &"sent_out_foe", &"sent_out_player", &"move_used", &"move_missed",
	&"critical", &"super_effective", &"not_very_effective", &"no_effect",
	&"stat_rose", &"stat_rose_2", &"stat_rose_3", &"stat_fell", &"stat_fell_2",
	&"stat_fell_3", &"stat_no_higher", &"stat_no_lower", &"recoil", &"fainted",
	&"battle_won", &"battle_lost", &"wild_appeared", &"fled", &"flee_failed",
	&"move_learned", &"move_forget_prompt", &"move_forgot", &"move_not_learned",
	&"seeded", &"drained",
	&"ball_thrown", &"broke_free", &"caught_title", &"pokedex_new", &"joined_party",
	&"sent_to_storage",
	&"item_used", &"hp_restored", &"prize_won",
	&"forget_confirm_title", &"forget_confirm_detail", &"forget_confirm_yes",
	&"forget_confirm_no",
	&"withdrawn", &"withdrawn_foe", &"switch_reason_active", &"switch_reason_fainted", &"replace_prompt",
	&"summary_exp", &"summary_level", &"summary_stat", &"summary_continue",
	&"status_inflicted_poison", &"status_unchanged_poison", &"status_damaged_poison",
	&"status_cured_poison",
	&"status_inflicted_paralysis", &"status_unchanged_paralysis", &"status_prevented_paralysis",
	&"status_cured_paralysis",
	&"status_inflicted_sleep", &"status_unchanged_sleep", &"status_prevented_sleep",
	&"status_ended_sleep", &"status_cured_sleep",
	&"status_inflicted_burn", &"status_unchanged_burn", &"status_damaged_burn",
	&"status_cured_burn",
	&"status_inflicted_freeze", &"status_unchanged_freeze", &"status_prevented_freeze",
	&"status_ended_freeze", &"status_cured_freeze",
	&"move_failed",
	&"confusion_inflicted", &"confusion_unchanged", &"confusion_check", &"confusion_hurt",
	&"confusion_ended", &"multi_hit", &"flinched", &"focused",
	&"bide_started", &"bide_storing", &"bide_unleashed", &"bide_broken",
	&"evolution_started", &"evolution_finished", &"evolution_cancelled", &"evolution_stop",
	&"drain_hp", &"trap_wrap_started", &"trap_wrap_damaged", &"trap_bind_started",
	&"trap_bind_damaged", &"trap_fire_spin_started", &"trap_fire_spin_damaged",
	&"trap_clamp_started", &"trap_clamp_damaged", &"trap_ended",
	&"move_disabled", &"disable_ended", &"rested", &"switch_reason_trapped",
	&"move_disabled_label",
	&"charge_dig_start", &"charge_dig_broken", &"charge_fly_start", &"charge_fly_broken", &"dodged", &"ball_blocked", &"teleported",
	&"nothing_happened", &"rare_candy_level",
	&"coins_scattered", &"coins_collected",
	&"recharging", &"scared_away", &"forced_out",
	&"ghost_name", &"ghost_appeared", &"ghost_unidentified", &"ghost_scared", &"ghost_spoke",
	&"ghost_ball_refused",
	&"ohko",
	&"heal", &"screen_started_player", &"screen_started_foe", &"screen_ended_player",
	&"screen_ended_foe", &"haze",
	&"charge_solar_beam_start", &"charge_solar_beam_broken",
	&"charge_skull_bash_start", &"charge_skull_bash_broken",
	&"battle_item_used", &"item_escape", &"item_escape_2", &"revived",
	&"flute_played", &"flute_all_woke", &"flute_no_effect", &"flute_no_effect_2",
	&"safari_ball_thrown", &"safari_bait", &"safari_rock", &"safari_eating", &"safari_angry",
	&"safari_fled", &"safari_left", &"safari_no_balls",
	&"safari_action_ball", &"safari_action_bait", &"safari_action_rock", &"safari_action_run",
]
## Entre deux gains de statistiques du bilan (« PV +2 · Attaque +1 »).
const SUMMARY_SEPARATOR: String = " · "
const PLACEHOLDERS: Array[String] = [
	"pokemon", "de_pokemon", "move", "trainer", "stat", "level", "exp", "old_move", "item",
	"amount", "money", "species", "player",
]
## Prénom du joueur ({player}, jalon 20) quand [member token_values] n'en donne aucun.
const PLAYER_FALLBACK: String = "Le Dresseur"

const _TEMPLATE_KEYS: Array[String] = ["text", "text_f", "draft"]
## Début du modèle de chaque événement de statut (suivi de « _<statut> »).
const _STATUS_PREFIXES: Dictionary[BattleEvent.Kind, String] = {
	BattleEvent.Kind.STATUS_INFLICTED: "status_inflicted",
	BattleEvent.Kind.STATUS_UNCHANGED: "status_unchanged",
	BattleEvent.Kind.STATUS_DAMAGED: "status_damaged",
	BattleEvent.Kind.STATUS_CURED: "status_cured",
	BattleEvent.Kind.STATUS_PREVENTED: "status_prevented",
	BattleEvent.Kind.STATUS_ENDED: "status_ended",
}
## J23 : modèle de chaque événement de la rencontre Safari.
const _SAFARI_TEMPLATES: Dictionary[BattleEvent.Kind, StringName] = {
	BattleEvent.Kind.SAFARI_BALL_THROWN: &"safari_ball_thrown",
	BattleEvent.Kind.BAIT_THROWN: &"safari_bait",
	BattleEvent.Kind.ROCK_THROWN: &"safari_rock",
	BattleEvent.Kind.SAFARI_EATING: &"safari_eating",
	BattleEvent.Kind.SAFARI_ANGRY: &"safari_angry",
	BattleEvent.Kind.SAFARI_FLED: &"safari_fled",
	BattleEvent.Kind.SAFARI_LEFT: &"safari_left",
	BattleEvent.Kind.SAFARI_NO_BALLS: &"safari_no_balls",
}
const _VOWELS: String = "AEIOUYÀÂÄÉÈÊËÎÏÔÖÙÛÜaeiouyàâäéèêëîïôöùûü"

## Valeurs des jetons du nom du dresseur (`func() -> Dictionary[StringName, String]`, OUV.2) :
## Boot y met le prénom du rival. Non valide : aucun jeton résolu.
var token_values: Callable

var _texts: Dictionary[StringName, String] = {}
## Variantes au féminin (modèles qui en ont une).
var _texts_f: Dictionary[StringName, String] = {}
var _drafts: Dictionary[StringName, bool] = {}
var _stats: Dictionary[StringName, String] = {}
## Noms courts des statistiques du bilan (« PV », « Atq. Spé. »).
var _stat_labels: Dictionary[StringName, String] = {}
var _errors: PackedStringArray = PackedStringArray()
var _placeholder: RegEx = RegEx.create_from_string("\\{([^}]*)\\}")


## Charge [param path]. Faux si le fichier est illisible ou invalide (aucun modèle gardé).
func load_file(path: String = DATA_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return _fail("fichier introuvable : %s" % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		# get_error_line() compte à partir de 0.
		return _fail("%s, ligne %d : %s" % [path, json.get_error_line() + 1,
			json.get_error_message()])
	if not json.data is Dictionary:
		return _fail("%s : un objet { \"templates\": …, \"stats\": … } est attendu" % path)
	return add_from_dict(json.data, path)


## Lit un objet déjà décodé. Tout ou rien : en cas d'erreur, aucun modèle n'est gardé.
func add_from_dict(data: Dictionary, source: String = "") -> bool:
	var ok := true
	for key: Variant in data:
		if not ["templates", "stats", "stat_labels"].has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [source, key])
	if not data.get("templates") is Dictionary or not data.get("stats") is Dictionary:
		return _fail("%s : « templates » et « stats » doivent être des objets" % source)
	if data.has("stat_labels") and not data["stat_labels"] is Dictionary:
		return _fail("%s : « stat_labels » doit être un objet" % source)
	var texts: Dictionary[StringName, String] = {}
	var texts_f: Dictionary[StringName, String] = {}
	var drafts: Dictionary[StringName, bool] = {}
	var templates: Dictionary = data["templates"]
	for key: Variant in templates:
		var id := StringName(str(key))
		var where := "%s modèle « %s »" % [source, id]
		if not TEMPLATE_IDS.has(id):
			ok = _fail("%s : modèle inconnu" % where)
			continue
		ok = _parse_template(templates[key], id, texts, texts_f, drafts, where) and ok
	for id: StringName in TEMPLATE_IDS:
		if not templates.has(String(id)):
			ok = _fail("%s : modèle « %s » manquant" % [source, id])
	var stats: Dictionary[StringName, String] = {}
	var raw_stats: Dictionary = data["stats"]
	for key: Variant in raw_stats:
		var stat := StringName(str(key))
		if not MoveEffect.STAGE_STATS.has(stat):
			ok = _fail("%s stats : statistique inconnue « %s »" % [source, stat])
		elif not raw_stats[key] is String or (raw_stats[key] as String).strip_edges().is_empty():
			ok = _fail("%s stats « %s » : texte non vide attendu" % [source, stat])
		else:
			stats[stat] = raw_stats[key]
	for stat: StringName in MoveEffect.STAGE_STATS:
		if not raw_stats.has(String(stat)):
			ok = _fail("%s stats : « %s » manquant" % [source, stat])
	var labels: Dictionary[StringName, String] = {}
	# Facultatif (jeux de messages de test) ; s'il est là, les six statistiques sont nommées.
	var raw_labels: Dictionary = data.get("stat_labels", {})
	for key: Variant in raw_labels:
		var stat := StringName(str(key))
		if not SpeciesData.STATS.has(stat):
			ok = _fail("%s stat_labels : statistique inconnue « %s »" % [source, stat])
		elif not _is_text(raw_labels[key]):
			ok = _fail("%s stat_labels « %s » : texte non vide attendu" % [source, stat])
		else:
			labels[stat] = raw_labels[key]
	for stat: StringName in SpeciesData.STATS:
		if not raw_labels.is_empty() and not raw_labels.has(String(stat)):
			ok = _fail("%s stat_labels : « %s » manquant" % [source, stat])
	if not ok:
		return false
	_stat_labels = labels
	_texts = texts
	_texts_f = texts_f
	_drafts = drafts
	_stats = stats
	return true


## Modèle brut [param id] (chaîne vide s'il n'existe pas). [param feminine] : sa variante
## au féminin si elle existe, sinon le modèle commun.
func get_template(id: StringName, feminine: bool = false) -> String:
	if feminine and _texts_f.has(id):
		return _texts_f[id]
	return _texts.get(id, "")


## Vrai si le modèle [param id] a une variante au féminin (« text_f »).
func has_feminine(id: StringName) -> bool:
	return _texts_f.has(id)


## Vrai si le modèle [param id] est un texte provisoire, à relire par Kevin.
func is_draft(id: StringName) -> bool:
	return _drafts.get(id, false)


## Phrases à afficher pour [param event], dans l'ordre (vide = pas de message). Les noms
## de capacités viennent de [param data]. [param trainer] : le dresseur adverse (null =
## message de fin par défaut) ; s'il n'a pas de message de fin, BATTLE_ENDED n'en a pas.
func lines(event: BattleEvent, data: PokemonData, trainer: TrainerData = null) \
		-> PackedStringArray:
	var result := PackedStringArray()
	var foe := event.side == BattleEvent.SideId.FOE
	match event.kind:
		BattleEvent.Kind.BATTLE_STARTED:
			var wanted_start := trainer == null or trainer.start_message
			if wanted_start and not event.trainer_name.is_empty():
				result.append(_fill(&"battle_started", event, data))
		BattleEvent.Kind.SENT_OUT:
			if not foe:
				result.append(_fill(&"sent_out_player", event, data))
			elif event.disguised:
				result.append(_fill(&"ghost_appeared", event, data))
				result.append(_fill(&"ghost_unidentified", event, data))
			elif not event.trainer_name.is_empty():
				result.append(_fill(&"sent_out_foe", event, data))
			else:
				result.append(_fill(&"wild_appeared", event, data))
		BattleEvent.Kind.MOVE_USED:
			result.append(_fill(&"move_used", event, data))
		BattleEvent.Kind.MOVE_MISSED:
			result.append(_fill(&"move_missed", event, data))
		BattleEvent.Kind.DAMAGE:
			if event.critical:
				result.append(_fill(&"critical", event, data))
			if event.effectiveness > 1.0:
				result.append(_fill(&"super_effective", event, data))
			elif event.effectiveness < 1.0:
				result.append(_fill(&"not_very_effective", event, data))
		BattleEvent.Kind.NO_EFFECT:
			result.append(_fill(&"no_effect", event, data))
		BattleEvent.Kind.STAT_CHANGED:
			var size := mini(absi(event.stages), 3)
			var base := "stat_rose" if event.stages > 0 else "stat_fell"
			var id := StringName(base if size == 1 else "%s_%d" % [base, size])
			result.append(_fill(id, event, data))
		BattleEvent.Kind.STAT_UNCHANGED:
			result.append(_fill(&"stat_no_higher" if event.stages > 0 else &"stat_no_lower",
				event, data))
		BattleEvent.Kind.RECOIL:
			result.append(_fill(&"recoil", event, data))
		BattleEvent.Kind.FAINTED:
			result.append(_fill(&"fainted", event, data))
		BattleEvent.Kind.FLED:
			result.append(_fill(&"fled", event, data))
		BattleEvent.Kind.FLEE_FAILED:
			result.append(_fill(&"flee_failed", event, data))
		BattleEvent.Kind.MOVE_LEARNED:
			result.append(_fill(&"move_learned", event, data))
		BattleEvent.Kind.MOVE_FORGET_OFFERED:
			result.append(_fill(&"move_forget_prompt", event, data))
		BattleEvent.Kind.SEEDED:
			result.append(_fill(&"seeded", event, data))
		BattleEvent.Kind.DRAINED:
			result.append(_fill(&"drained", event, data))
		BattleEvent.Kind.BALL_THROWN:
			result.append(_fill(&"ball_thrown", event, data))
		BattleEvent.Kind.BROKE_FREE:
			result.append(_fill(&"broke_free", event, data))
		BattleEvent.Kind.WITHDRAWN:
			result.append(_fill(&"withdrawn_foe" if event.side == BattleEvent.SideId.FOE
				else &"withdrawn", event, data))
		BattleEvent.Kind.ITEM_USED:
			result.append(_fill(&"item_used", event, data))
			if event.amount > 0:
				result.append(_fill(&"hp_restored", event, data))
		BattleEvent.Kind.BATTLE_ITEM_USED:
			result.append(_fill(&"battle_item_used", event, data))
		BattleEvent.Kind.ITEM_ESCAPE:
			result.append(_fill(&"item_escape", event, data))
			result.append(_fill(&"item_escape_2", event, data))
		BattleEvent.Kind.REVIVED:
			result.append(_fill(&"revived", event, data))
		BattleEvent.Kind.FLUTE_PLAYED:
			result.append(_fill(&"flute_played", event, data))
		BattleEvent.Kind.ALL_WOKE:
			result.append(_fill(&"flute_all_woke", event, data))
		BattleEvent.Kind.FAILED:
			result.append(_fill(&"move_failed", event, data))
		BattleEvent.Kind.SAFARI_BALL_THROWN, BattleEvent.Kind.BAIT_THROWN, \
				BattleEvent.Kind.ROCK_THROWN, BattleEvent.Kind.SAFARI_EATING, \
				BattleEvent.Kind.SAFARI_ANGRY, BattleEvent.Kind.SAFARI_FLED, \
				BattleEvent.Kind.SAFARI_LEFT, BattleEvent.Kind.SAFARI_NO_BALLS:
			result.append(_fill(_SAFARI_TEMPLATES[event.kind], event, data))
		BattleEvent.Kind.CONFUSED:
			result.append(_fill(&"confusion_inflicted", event, data))
		BattleEvent.Kind.CONFUSION_UNCHANGED:
			result.append(_fill(&"confusion_unchanged", event, data))
		BattleEvent.Kind.CONFUSION_CHECK:
			result.append(_fill(&"confusion_check", event, data))
		BattleEvent.Kind.HURT_ITSELF:
			result.append(_fill(&"confusion_hurt", event, data))
		BattleEvent.Kind.CONFUSION_ENDED:
			result.append(_fill(&"confusion_ended", event, data))
		BattleEvent.Kind.MULTI_HIT:
			result.append(_fill(&"multi_hit", event, data))
		BattleEvent.Kind.FLINCHED:
			result.append(_fill(&"flinched", event, data))
		BattleEvent.Kind.FOCUSED:
			result.append(_fill(&"focused", event, data))
		BattleEvent.Kind.BIDE_STARTED:
			result.append(_fill(&"bide_started", event, data))
		BattleEvent.Kind.BIDE_STORING:
			result.append(_fill(&"bide_storing", event, data))
		BattleEvent.Kind.BIDE_UNLEASHED:
			result.append(_fill(&"bide_unleashed", event, data))
		BattleEvent.Kind.BIDE_BROKEN:
			result.append(_fill(&"bide_broken", event, data))
		BattleEvent.Kind.DRAINED_HP, BattleEvent.Kind.TRAPPED, BattleEvent.Kind.TRAP_DAMAGED, \
				BattleEvent.Kind.TRAP_ENDED, BattleEvent.Kind.MOVE_DISABLED, \
				BattleEvent.Kind.DISABLE_ENDED, BattleEvent.Kind.RESTED:
			var id := _template_j12(event, data)
			if _texts.has(id):
				result.append(_fill(id, event, data))
		BattleEvent.Kind.CHARGE_STARTED, BattleEvent.Kind.CHARGE_BROKEN:
			var charge_id := _charge_template(event, data)
			if _texts.has(charge_id):
				result.append(_fill(charge_id, event, data))
		BattleEvent.Kind.DODGED:
			result.append(_fill(&"dodged", event, data))
		BattleEvent.Kind.BALL_BLOCKED:
			result.append(_fill(&"ball_blocked", event, data))
		BattleEvent.Kind.TELEPORTED:
			result.append(_fill(&"teleported", event, data))
		BattleEvent.Kind.NOTHING_HAPPENED:
			result.append(_fill(&"nothing_happened", event, data))
		BattleEvent.Kind.COINS_SCATTERED:
			result.append(_fill(&"coins_scattered", event, data))
		BattleEvent.Kind.RECHARGING:
			result.append(_fill(&"recharging", event, data))
		BattleEvent.Kind.SCARED_AWAY:
			result.append(_fill(&"scared_away", event, data))
		BattleEvent.Kind.FORCED_OUT:
			result.append(_fill(&"forced_out", event, data))
		BattleEvent.Kind.GHOST_SCARED:
			result.append(_fill(&"ghost_scared", event, data))
		BattleEvent.Kind.GHOST_SPOKE:
			result.append(_fill(&"ghost_spoke", event, data))
		BattleEvent.Kind.OHKO:
			result.append(_fill(&"ohko", event, data))
		BattleEvent.Kind.HEALED:
			result.append(_fill(&"heal", event, data))
		BattleEvent.Kind.SCREEN_STARTED, BattleEvent.Kind.SCREEN_ENDED:
			var started := event.kind == BattleEvent.Kind.SCREEN_STARTED
			result.append(_fill(StringName("screen_%s_%s" % ["started" if started else "ended",
				"foe" if event.side == BattleEvent.SideId.FOE else "player"]), event, data))
		BattleEvent.Kind.STATS_RESET:
			result.append(_fill(&"haze", event, data))
		BattleEvent.Kind.STATUS_INFLICTED, BattleEvent.Kind.STATUS_UNCHANGED, \
				BattleEvent.Kind.STATUS_DAMAGED, BattleEvent.Kind.STATUS_CURED, \
				BattleEvent.Kind.STATUS_PREVENTED, BattleEvent.Kind.STATUS_ENDED:
			var id := StringName("%s_%s" % [_STATUS_PREFIXES[event.kind], event.status])
			if _texts.has(id):
				result.append(_fill(id, event, data))
		BattleEvent.Kind.BATTLE_ENDED:
			# FLED ne porte pas de message ici (il est sur l'événement FLED). Un sauvage n'a
			# pas de dresseur (trainer_name vide) : « Tu as battu… » ne s'affiche pas.
			var wanted := trainer == null or trainer.end_message
			if wanted and not event.trainer_name.is_empty() \
					and event.outcome in [Battle.Outcome.WIN, Battle.Outcome.LOSS]:
				result.append(_fill(&"battle_won" if event.outcome == Battle.Outcome.WIN
					else &"battle_lost", event, data))
	return result


## Phrase du modèle [param id] remplie avec [param event] (chaîne vide si le modèle n'existe
## pas). [param old_move] : la capacité oubliée ({old_move}). Sert à ce qui ne vient pas d'un
## événement du moteur : « Salamèche oublie Griffe et apprend Frénésie ! »
## ([code]line_for(&"move_forgot", offered, data, &"scratch")[/code]), « … n'apprend pas … ».
func line_for(id: StringName, event: BattleEvent, data: PokemonData,
		old_move: StringName = &"") -> String:
	if not _texts.has(id):
		return ""
	return _fill(id, event, data, old_move)


## « Tu remportes 280 ₽. » : gain d'argent [param amount] après une victoire contre un dresseur
## (chaîne vide si le modèle manque).
func prize_line(amount: int) -> String:
	if not _texts.has(&"prize_won"):
		return ""
	return get_template(&"prize_won").format({"money": MenuFormat.money(amount)})


## « Tu ramasses 34 ₽. » : pièces du Jackpot [param amount] ramassées en fin de combat (chaîne
## vide si le modèle manque).
func coins_line(amount: int) -> String:
	if not _texts.has(&"coins_collected"):
		return ""
	return get_template(&"coins_collected").format({"money": MenuFormat.money(amount)})


## J23 : libellé du bouton SAFARI BALL avec [param balls] Balls restantes.
func safari_ball_label(balls: int) -> String:
	return get_template(&"safari_action_ball").format({"amount": balls})


## « +11 XP » (bilan de fin de combat).
func summary_exp(amount: int) -> String:
	return get_template(&"summary_exp").format({"exp": amount})


## « Nv. 9 » (bilan de fin de combat).
func summary_level(level: int) -> String:
	return get_template(&"summary_level").format({"level": level})


## « PV +2 · Attaque +1 · … » : les gains de [param gains] dans l'ordre de
## [constant SpeciesData.STATS] ; une statistique qui n'augmente pas (+0) n'est pas écrite.
## Chaîne vide si rien n'augmente.
func summary_stats(gains: Dictionary[StringName, int]) -> String:
	var parts := PackedStringArray()
	for stat: StringName in SpeciesData.STATS:
		var amount: int = gains.get(stat, 0)
		if amount > 0:
			parts.append(get_template(&"summary_stat").format({
				"stat": _stat_labels.get(stat, String(stat)), "amount": amount}))
	return SUMMARY_SEPARATOR.join(parts)


## Nom affiché du dresseur : jetons (`{rival}`) résolus par [member token_values] ; un jeton
## sans valeur laisse le nom tel quel.
func trainer_display_name(raw: String) -> String:
	if DialogueTokens.tokens_in(raw).is_empty() or not token_values.is_valid():
		return raw
	var values: Dictionary[StringName, String] = {}
	var given: Variant = token_values.call()
	if given is Dictionary:
		values.assign(given)
	var resolved := DialogueTokens.resolve(raw, values)
	return raw if resolved.is_empty() else resolved


## « de Salamèche », « d'Évoli » : élision devant une voyelle.
static func de_name(name: String) -> String:
	if not name.is_empty() and _VOWELS.contains(name.left(1)):
		return "d'" + name
	return "de " + name


## Erreurs signalées depuis la création.
func get_errors() -> PackedStringArray:
	return _errors


func _fill(id: StringName, event: BattleEvent, data: PokemonData,
		old_move: StringName = &"") -> String:
	var move := data.get_move(event.move_id)
	var forgotten := data.get_move(old_move)
	var species := data.get_species(event.species_id)
	return get_template(id, event.gender == Pokemon.Gender.FEMALE).format({
		"pokemon": event.pokemon_name,
		"species": species.name if species != null else String(event.species_id),
		"de_pokemon": de_name(event.pokemon_name),
		"move": move.name if move != null else String(event.move_id),
		"trainer": trainer_display_name(event.trainer_name),
		"stat": _stats.get(event.stat, String(event.stat)),
		"level": event.level,
		"exp": event.amount,
		"old_move": forgotten.name if forgotten != null else String(old_move),
		"item": event.item_name,
		"amount": event.amount,
		"player": player_name(),
	})


## Prénom du joueur ({player}) : la valeur « player » de [member token_values], sinon
## [constant PLAYER_FALLBACK].
func player_name() -> String:
	if token_values.is_valid():
		var given: Variant = token_values.call()
		if given is Dictionary and not str((given as Dictionary).get(DialogueTokens.PLAYER,
				"")).is_empty():
			return str((given as Dictionary)[DialogueTokens.PLAYER])
	return PLAYER_FALLBACK


## « charge_<texts>_start » ou « _broken » pour un événement de charge (jalon 14), ou &"" si la
## capacité n'a pas d'effet CHARGE.
func _charge_template(event: BattleEvent, data: PokemonData) -> StringName:
	var move := data.get_move(event.move_id)
	var effect := move.charge_effect() if move != null else null
	if effect == null:
		return &""
	var suffix := "start" if event.kind == BattleEvent.Kind.CHARGE_STARTED else "broken"
	return StringName("charge_%s_%s" % [effect.texts, suffix])


func _parse_template(value: Variant, id: StringName, texts: Dictionary[StringName, String],
		texts_f: Dictionary[StringName, String], drafts: Dictionary[StringName, bool],
		where: String) -> bool:
	if not value is Dictionary:
		return _fail("%s : un objet { \"text\": … } est attendu" % where)
	var entry: Dictionary = value
	var ok := true
	for key: Variant in entry:
		if not _TEMPLATE_KEYS.has(str(key)):
			ok = _fail("%s : clé inconnue « %s »" % [where, key])
	if not _is_text(entry.get("text")):
		return _fail("%s : « text » doit être un texte non vide" % where)
	ok = _check_placeholders(entry["text"], where) and ok
	if entry.has("text_f"):
		if not _is_text(entry["text_f"]):
			ok = _fail("%s : « text_f » doit être un texte non vide" % where)
		else:
			ok = _check_placeholders(entry["text_f"], where + " text_f") and ok
			texts_f[id] = entry["text_f"]
	if entry.has("draft") and not entry["draft"] is bool:
		ok = _fail("%s : « draft » vaut true ou false" % where)
	texts[id] = entry["text"]
	drafts[id] = entry.get("draft") is bool and entry["draft"]
	return ok


static func _is_text(value: Variant) -> bool:
	return value is String and not (value as String).strip_edges().is_empty()


func _check_placeholders(text: String, where: String) -> bool:
	var ok := true
	for found: RegExMatch in _placeholder.search_all(text):
		if not PLACEHOLDERS.has(found.get_string(1)):
			ok = _fail("%s : marque inconnue « {%s} »" % [where, found.get_string(1)])
	return ok


func _fail(message: String) -> bool:
	var full := "BattleText : " + message
	_errors.append(full)
	push_error(full)
	return false


## Modèle d'un événement du jalon 12 (&"" : aucun).
func _template_j12(event: BattleEvent, data: PokemonData) -> StringName:
	match event.kind:
		BattleEvent.Kind.DRAINED_HP:
			return &"drain_hp"
		BattleEvent.Kind.TRAP_ENDED:
			return &"trap_ended"
		BattleEvent.Kind.MOVE_DISABLED:
			return &"move_disabled"
		BattleEvent.Kind.DISABLE_ENDED:
			return &"disable_ended"
		BattleEvent.Kind.RESTED:
			return &"rested"
		BattleEvent.Kind.TRAPPED, BattleEvent.Kind.TRAP_DAMAGED:
			var move := data.get_move(event.move_id)
			var trap := move.effect_of(MoveEffect.Kind.TRAP) if move != null else null
			if trap == null:
				return &""
			var stage := "started" if event.kind == BattleEvent.Kind.TRAPPED else "damaged"
			return StringName("trap_%s_%s" % [trap.messages, stage])
	return &""
