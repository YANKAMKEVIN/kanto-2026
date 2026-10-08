class_name TrainerEncounter
extends RefCounted
## Séquence d'un Dresseur du monde (jalon 9, jalon-09.md §2.4.3), construite en code avec les
## étapes de scène existantes et jouée par [method CutsceneDirector.play_variant] : aucun
## fichier de scène par Dresseur.
##
## Classe pure. Repéré à [param distance] cases ([method build]) :
## 1. « ! » au-dessus du Dresseur, puis une courte pause ;
## 2. il marche jusqu'à la case voisine du joueur ([method TrainerRules.approach_path]) ;
## 3. le joueur et le Dresseur se font face ;
## 4. réplique « avant » ;
## 5. combat, `beaten_<id>` levé à la victoire ;
## 6. réplique « après », tout de suite, si le Dresseur est battu (décision de Kevin, Q-3) ; s'il
##    a une réplique « vaincu » ([member NpcSpec.defeated_dialogue], jalon 10 §2.5), c'est elle,
##    dite cette fois seulement (la réplique « après » reste celle qu'on entend en lui reparlant) ;
## 7. sinon (défaite du joueur), réveil au dernier point de repos : rien n'est retiré, le
##    Dresseur n'est pas battu et redéfiera (dossier 10 §15).
## Défié à la parole (distance 0) : ni « ! » ni approche, étapes 3 à 7.

## Bulle de l'étape 1.
const EXCLAMATION: StringName = &"exclamation"
## Pause après le « ! » (s), avant l'approche (défaut du plan, règle 4).
const SPOTTED_PAUSE: float = 0.3
## Préfixe de l'identifiant de scène (journal [qa], signaux du directeur de scènes).
const CUTSCENE_PREFIX: String = "trainer_"
## Distance d'un défi à la parole ([method build]).
const TALKED_TO: int = 0


## Identifiant de la scène jouée pour le Dresseur [param trainer_id] : `trainer_<id>`.
static func cutscene_id(trainer_id: StringName) -> StringName:
	return StringName(CUTSCENE_PREFIX + String(trainer_id))


## Séquence du Dresseur [param npc_id] (PNJ de la carte, description [param spec] avec un
## bloc « trainer ») qui a vu le joueur à [param distance] cases ; [constant TALKED_TO] = le
## joueur lui a parlé. null (push_error) si [param spec] n'est pas un Dresseur.
static func build(npc_id: StringName, spec: NpcSpec, distance: int) -> CutsceneVariant:
	if spec == null or not spec.is_trainer():
		push_error("TrainerEncounter : « %s » n'est pas un Dresseur" % npc_id)
		return null
	var beaten := TrainerRules.beaten_flag(spec.trainer_id)
	var variant := CutsceneVariant.new()
	var steps := variant.steps
	if distance > TALKED_TO:
		var emote := _step(CutsceneStep.Kind.EMOTE, npc_id)
		emote.emote = EXCLAMATION
		steps.append(emote)
		var pause := _step(CutsceneStep.Kind.WAIT)
		pause.seconds = SPOTTED_PAUSE
		steps.append(pause)
		var path := TrainerRules.approach_path(spec.facing, distance)
		if not path.is_empty():
			var approach := _step(CutsceneStep.Kind.MOVE, npc_id)
			approach.path = path
			steps.append(approach)
	var player_faces := _step(CutsceneStep.Kind.FACE, NpcRoster.PLAYER_ID)
	player_faces.target = npc_id
	steps.append(player_faces)
	var trainer_faces := _step(CutsceneStep.Kind.FACE, npc_id)
	trainer_faces.target = NpcRoster.PLAYER_ID
	steps.append(trainer_faces)
	var before := _step(CutsceneStep.Kind.DIALOGUE)
	before.dialogue_id = spec.before_dialogue
	steps.append(before)
	var battle := _step(CutsceneStep.Kind.BATTLE)
	battle.trainer_id = spec.trainer_id
	battle.win_flags = [beaten]
	steps.append(battle)
	var after := _step(CutsceneStep.Kind.DIALOGUE)
	after.dialogue_id = spec.dialogue if spec.defeated_dialogue.is_empty() \
		else spec.defeated_dialogue
	after.if_flags = [beaten]
	steps.append(after)
	var wake_up := _step(CutsceneStep.Kind.WAKE_UP)
	wake_up.unless_flags = [beaten]
	steps.append(wake_up)
	return variant


static func _step(kind: CutsceneStep.Kind, actor: StringName = &"") -> CutsceneStep:
	var step := CutsceneStep.new()
	step.kind = kind
	step.actor = actor
	return step
