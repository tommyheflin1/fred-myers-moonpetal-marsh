class_name FredWardrobeLayout
extends RefCounted

const PAGE_SIZE := 6
const TABS := {
	"hero": Rect2(500,132,136,52),
	"body": Rect2(644,132,136,52),
	"size": Rect2(788,132,136,52),
	"tongue": Rect2(932,132,136,52),
	"attire": Rect2(1076,132,136,52),
}
const HEADINGS := {"hero":"HERO STYLE", "body":"SKIN", "size":"BUILD", "tongue":"TONGUE", "attire":"OUTFITS"}
const FILTER := Rect2(1002,70,210,46)
const COINS := Rect2(952,24,260,34)
const PREVIOUS := Rect2(500,532,100,48)
const NEXT := Rect2(1112,532,100,48)
const APPLY := Rect2(500,604,712,58)
const HOME := Rect2(88,632,348,56)
const PREVIEW_ORIGIN := Vector2(258,350)
const PREVIEW_SCALE := 2.2
const PREVIEW_RECT := Rect2(44,155,424,392)

static func card(index: int) -> Rect2:
	if index < 0 or index >= PAGE_SIZE:
		return Rect2()
	return Rect2(500+(index%3)*242,204+(index/3)*160,228,144)

static func entries(profile: RefCounted, category: String, owned_only: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in profile.CATALOG.get(category, []):
		if not owned_only or profile.owns(category,str(entry.id)):
			result.append(entry.duplicate(true))
	return result

static func pages(count: int) -> int:
	return maxi(1,ceili(float(count)/PAGE_SIZE))
