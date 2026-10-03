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
