extends RefCounted

const TRASH_LAYOUT_REVISION := 2

# All monetary amounts are integer cents. Lost-property rules are deliberately untouched.
const COSTS := {
	"quick_hands": [20,45,85,140,220], "reinforced_bag": [25,60,125,225,800],
	"sealed_bags": [75,180,350,400,900], "sprint": [50,125,250,425,1000],
	"multi_pickup": [95,220,425,1200], "manual_reach": [35,90,180,300],
	"recycle_value": [300,800,1400,1800], "all_seeing_eye": [100,250,700],
	"vacuum_reach": [225,450,850,3000], "vacuum_battery": [175,350,650,2200],
	"vacuum_recharge": [150,300,550,2000],
}
const OBJECTIVE_REWARDS := {
	"room_01_clean":50, "room_02_clean":100, "room_03_clean":100,
	"room_04_clean":150, "lobby_clean":100, "movies_reactivated":100,
	"arcade_found":100, "arcade_second":150, "documents_found":100,
	"collectibles_found":150,
	"movie_watched_room_01":25, "movie_watched_room_02":25,
	"movie_watched_room_03":25, "movie_watched_room_04":25,
}

static func money(cents: int) -> String:
	var magnitude := absi(cents)
	return ("-" if cents < 0 else "") + "%d,%02d" % [magnitude / 100, magnitude % 100]

static func percent(done: int, total: int) -> float:
	if total <= 0:
		return 100.0
	if done >= total:
		return 100.0
	return minf(99.99, roundf(float(maxi(0, done)) * 10000.0 / total) / 100.0)
