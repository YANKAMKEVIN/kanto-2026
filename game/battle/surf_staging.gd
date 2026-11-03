class_name SurfStaging
extends RefCounted
## Combat en surfant (fiche `docs/design/fiches-assets/entree-dresseurs.md` §13 ; demande de
## Kevin du 2026-11-03 : « le joueur sur son Pokémon de Surf », à comparer au banc de sable avant
## de choisir). Classe pure : décide si la mise en scène « Surf » remplace la mise en scène à pied.
##
## Elle s'applique quand **tout** est vrai :
## - le réglage `surf.enabled` de `data/battle/decors.json` est vrai (faux par défaut tant que
##   Kevin n'a pas tranché : le banc de sable `sea_open` reste) ;
## - le joueur surfe (`GameState.player_mount` = [constant Mount.Kind.SURF]) ;
## - le décor du lieu a un remplaçant en Surf (`surf.decors`, mer ouverte `sea_surf` pour
##   `sea_open`) ;
## - le combat est sauvage, ou l'adversaire est peint dans l'eau (Nageur, Nageuse :
##   `surf.classes` de `data/battle/trainer_intro.json`). [D] Un Dresseur de la terre ferme
##   (Pêcheur sur son îlot, Topdresseur sur la plage) garde la mise en scène à pied sur le banc
##   de sable : il ne peut pas se tenir sur la mer ouverte.
## Images : le joueur de dos sur la monture générique du monde (`dos_<apparence>_surf`, comme
## `player_surf` en exploration), l'adversaire dans l'eau (`<classe>_surf`) ; [TrainerIntro]
## [member TrainerIntro.surf].


## Décor du combat en surfant qui remplace [param decor], ou null si la mise en scène à pied
## reste. [param surfing] : le joueur surfe ; [param wild] : combat sauvage ; [param foe_class] :
## classe du Dresseur adverse ([method TrainerIntroCatalog.class_of]).
static func surf_decor(decors: BattleDecorCatalog, intros: TrainerIntroCatalog,
		decor: BattleDecor, surfing: bool, wild: bool, foe_class: StringName) -> BattleDecor:
	if decors == null or decor == null or not surfing or not decors.surf_enabled:
		return null
	if not wild and (intros == null or not intros.has_surf_art(foe_class)):
		return null
	return decors.surf_decor_for(decor.id)
