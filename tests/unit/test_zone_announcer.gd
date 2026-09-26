extends GutTest
## ZoneAnnouncer : titre de zone seulement pour une zone extérieure nouvelle.

var _announcer: ZoneAnnouncer


func before_each() -> void:
	_announcer = ZoneAnnouncer.new()


func test_interiors_are_never_announced() -> void:
	assert_false(_announcer.should_announce("Bourg Palette", true))
	assert_eq(_announcer.get_last_announced(), "")


func test_first_exit_from_the_bedroom_announces_the_town() -> void:
	assert_false(_announcer.should_announce("Bourg Palette", true), "chambre")
	assert_false(_announcer.should_announce("Bourg Palette", true), "rez-de-chaussée")
	assert_true(_announcer.should_announce("Bourg Palette", false), "première sortie")
	assert_eq(_announcer.get_last_announced(), "Bourg Palette")


func test_going_in_and_out_of_a_door_does_not_repeat_the_title() -> void:
	assert_true(_announcer.should_announce("Bourg Palette", false))
	assert_false(_announcer.should_announce("Bourg Palette", true), "labo")
	assert_false(_announcer.should_announce("Bourg Palette", false), "ressortie")


func test_a_new_outdoor_zone_is_announced_then_the_town_again() -> void:
	assert_true(_announcer.should_announce("Bourg Palette", false))
	assert_true(_announcer.should_announce("Route 1", false))
	assert_true(_announcer.should_announce("Bourg Palette", false))


func test_empty_name_is_never_announced() -> void:
	assert_false(_announcer.should_announce("", false))


func test_reset_forgets_the_last_zone() -> void:
	assert_true(_announcer.should_announce("Bourg Palette", false))
	_announcer.reset()
	assert_true(_announcer.should_announce("Bourg Palette", false))
