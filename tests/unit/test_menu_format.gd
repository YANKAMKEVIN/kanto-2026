extends GutTest
## MenuFormat : dates et nombres en français (jalon-06.md §13).


func test_long_date() -> void:
	assert_eq(MenuFormat.long_date("2026-10-02T19:07:52"), "2 octobre 2026")
	assert_eq(MenuFormat.long_date("2026-11-01T00:00:00"), "1er novembre 2026")
	assert_eq(MenuFormat.long_date("2027-02-14"), "14 février 2027")
	assert_eq(MenuFormat.long_date("2026-08-31T23:59:59"), "31 août 2026")


func test_long_date_unreadable_is_empty() -> void:
	for iso: String in ["", "hier", "2026-13-01", "2026-00-10", "2026-10", "2026-10-xx",
			"2026-10-32"]:
		assert_eq(MenuFormat.long_date(iso), "", "illisible : « %s »" % iso)


func test_number_groups_thousands() -> void:
	var nbsp := MenuFormat.THOUSANDS_SEPARATOR
	assert_eq(MenuFormat.number(0), "0")
	assert_eq(MenuFormat.number(560), "560")
	assert_eq(MenuFormat.number(1250), "1" + nbsp + "250")
	assert_eq(MenuFormat.number(117360), "117" + nbsp + "360")
	assert_eq(MenuFormat.number(1000000), "1" + nbsp + "000" + nbsp + "000")
	assert_eq(MenuFormat.number(-1500), "-1" + nbsp + "500")


func test_play_time() -> void:
	assert_eq(MenuFormat.play_time(0.0), "0 h 00")
	assert_eq(MenuFormat.play_time(420.0), "0 h 07")
	assert_eq(MenuFormat.play_time(1616.6), "0 h 26")
	assert_eq(MenuFormat.play_time(45780.0), "12 h 43")
	assert_eq(MenuFormat.play_time(-1.0), "0 h 00")
	assert_eq(DashboardViews.play_time_text(45780.0), MenuFormat.play_time(45780.0),
		"une seule règle pour le tableau de bord et l'écran Dresseur")


## Jalon 7 (dossier 09 §10) : « 3 000 ₽ », espaces insécables (le nombre et le symbole ne
## se séparent jamais).
func test_money() -> void:
	var nbsp := MenuFormat.THOUSANDS_SEPARATOR
	assert_eq(MenuFormat.money(3000), "3" + nbsp + "000" + nbsp + "₽")
	assert_eq(MenuFormat.money(0), "0" + nbsp + "₽")
	assert_eq(MenuFormat.money(200), "200" + nbsp + "₽")
	assert_eq(MenuFormat.money(999999), "999" + nbsp + "999" + nbsp + "₽")
	assert_eq(MenuFormat.MONEY_SUFFIX, nbsp + "₽")
