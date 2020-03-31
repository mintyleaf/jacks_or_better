extends Panel

const CRES_POOL = "res://assets/graphics/"
const CARD_POOL = [
	"BG",																# 0,
	"ACE_CLUBS",   "ACE_DIAMONDS",   "ACE_HEARTS",   "ACE_SPADES",		# 1,  2,  3,  4,
	"KING_CLUBS",  "KING_DIAMONDS",  "KING_HEARTS",  "KING_SPADES",		# 5,  6,  7,  8,
	"QUEEN_CLUBS", "QUEEN_DIAMONDS", "QUEEN_HEARTS", "QUEEN_SPADES",	# 9,  10, 11, 12,
	"JACK_CLUBS",  "JACK_DIAMONDS",  "JACK_HEARTS",  "JACK_SPADES",		# 13, 14, 15, 16,
	"TEN_CLUBS",   "TEN_DIAMONDS",   "TEN_HEARTS",   "TEN_SPADES",		# 17, 18, 19, 20,
	"NINE_CLUBS",  "NINE_DIAMONDS",  "NINE_HEARTS",  "NINE_SPADES",		# 21, 22, 23, 24,
	"EIGHT_CLUBS", "EIGHT_DIAMONDS", "EIGHT_HEARTS", "EIGHT_SPADES",	# 25, 26, 27, 28,
	"SEVEN_CLUBS", "SEVEN_DIAMONDS", "SEVEN_HEARTS", "SEVEN_SPADES",	# 29, 30, 31, 32,
	"SIX_CLUBS",   "SIX_DIAMONDS",   "SIX_HEARTS",   "SIX_SPADES",		# 33, 34, 35, 36,
	"FIVE_CLUBS",  "FIVE_DIAMONDS",  "FIVE_HEARTS",  "FIVE_SPADES",		# 37, 38, 39, 40,
	"FOUR_CLUBS",  "FOUR_DIAMONDS",  "FOUR_HEARTS",  "FOUR_SPADES",		# 41, 42, 43, 44,
	"THREE_CLUBS", "THREE_DIAMONDS", "THREE_HEARTS", "THREE_SPADES",	# 45, 46, 47, 48,
	"TWO_CLUBS",   "TWO_DIAMONDS",   "TWO_HEARTS",   "TWO_SPADES"		# 49, 50, 51, 52
]
const PAYS = {
	"ROYAL FLUSH" :		[250, 500, 750, 1000, 4000],
	"STRAIGHT FLUSH" :	[50,  100, 150, 200,  250],
	"FOUR OF A KIND" :	[25,  50,  75,  100,  125],
	"FULL HOUSE" :		[9,   18,  27,  36,   45],
	"FLUSH" :			[6,   12,  18,  24,   30],
	"STRAIGHT" :		[4,   8,   12,  16,   20],
	"THREE OF A KIND" :	[3,   6,   9,   12,   15],
	"TWO PAIRS" :		[2,   4,   8,   6,    10],
	"JACKS OR BETTER" :	[1,   2,   3,   4,    5]
}

const HOLD_TIME = 1.0
const NOT_PICK_HOLD_TIME = 3.0
const DEFMONEY = 10

onready var SUIT = range(13)

onready var card_0 =	$"cardholder/0"
onready var card_1 =	$"cardholder/1"
onready var card_2 =	$"cardholder/2"
onready var card_3 =	$"cardholder/3"
onready var card_4 =	$"cardholder/4"

onready var bet_one =	$buttons/bet_one
onready var bet_max =	$buttons/bet_max
onready var deal =		$buttons/deal

onready var lbet =		$buttons/bet
onready var lbal =		$buttons/balance
onready var lwin =		$win

onready var tw =		$tw

var nccard = null
var nchold = null
var ncres = null
var ncbet = null

var chand = ["BG", "BG", "BG", "BG", "BG"]
var chand_idx = [0, 0, 0, 0, 0]
var chold = [false, false, false, false, false]
var cbet = 1
var cbal = DEFMONEY
var cholding = false
var canhold = false
var playing = false
var playcount = 0

var lplaycount = 0

var hold_timer = 0.0

var lastwin = 0


func start() -> void:
	if cbal - cbet < 0:
		cbal = DEFMONEY
		restart()
		return
	playcount += 1
	cholding = false
	giveahand(["BG", "BG", "BG", "BG", "BG"])
	bet_max.disabled = true
	bet_one.disabled = true
	deal.disabled = true
	clearhold()
	yield(get_tree().create_timer(0.5), "timeout")
	betanim()
	yield(get_tree().create_timer(0.1 * cbet + 0.2), "timeout")
	cbal -= cbet
	lbal.text = str(cbal) + "$"
	giveahand(randhand())
	yield(get_tree().create_timer(0.5), "timeout")
	checkhand()
	cholding = true
	canhold = true
	hold_timer = NOT_PICK_HOLD_TIME


func restart() -> void:
	playcount = 0
	clearhold()
	giveahand(["BG", "BG", "BG", "BG", "BG"])
	cbet = 1
	lbal.text = str(cbal) + "$"
	lbet.text = "BET: " + str(cbet)
	bet_max.disabled = false
	bet_one.disabled = false
	deal.disabled = false
	deal.text = "Deal"
	cholding = false


func roll(comb) -> void:
	if comb == "EMPTY":
		lastwin = 0
		deal.text = "Deal"
		deal.disabled = true
		return
	
	lastwin = PAYS[comb][cbet - 1]
	if comb == "ROYAL FLUSH":
		winspl(comb, lastwin)
		yield(get_tree().create_timer(1.0), "timeout")
		cbal += lastwin
		restart()
		return
	
	if cholding:
		winspl(comb, lastwin)
		deal.text = "Deal"
		deal.disabled = true
		cbal += lastwin
		lbal.text = str(cbal) + "$"
	else:
		simspl(comb, lastwin)
		deal.text = "Draw " + str(lastwin) + "$"
		deal.disabled = false


func _process(delta: float) -> void:
	if hold_timer > 0:
		hold_timer -= delta
		if hold_timer < 0:
			hold_timer = 0.0
			lplaycount = playcount
			giveahand(randhand())
			canhold = false
			deal.text = "Deal"
			deal.disabled = true
			yield(get_tree().create_timer(0.5), "timeout")
			if playcount == lplaycount:
				checkhand()
			yield(get_tree().create_timer(1.0), "timeout")
			if playcount == lplaycount:
				start()


func checkhand() -> void:
	chand_idx = []
	for card in chand:
		chand_idx.append(CARD_POOL.find(card))
	
	var flush = checkflush(chand_idx) # [is flash, is royal]
	var straight = checkstraight(chand_idx) # is straight
	
	var sc = checksc(chand_idx) # [first pair count, second pair count, is jorbetter]
	
	if flush[0]:
		if flush[1]:
			roll("ROYAL FLUSH")
			return
		elif straight:
			roll("STRAIGHT FLUSH")
			return
		else:
			roll("FLUSH")
			return
	
	if straight:
		roll("STRAIGHT")
		return
	
	if sc[0] > 1:
		if sc[0] == 4:
			roll("FOUR OF A KIND")
			return
		elif sc[0] == 3:
			if sc[1] == 2:
				roll("FULL HOUSE")
				return
			else:
				roll("THREE OF A KIND")
				return
		elif sc[0] == 2:
			if sc[1] == 2:
				roll("TWO PAIRS")
				return
			elif sc[2]:
				roll("JACKS OR BETTER")
				return
	
	roll("EMPTY")


func checkflush(hand: PoolIntArray) -> Array:
	var ret = [false, false]
	var cursuit = []
	
	for i in range(4):
		
		cursuit = []
		for s in SUIT:
			cursuit.append((s * 4) + 1 + i)
		ret[0] = true
		
		for idx in hand:
			if !idx in cursuit:
				ret[0] = false
				break
		
		if ret[0]:
			for j in range(4):
				if ((1  + j) in hand and
					(5  + j) in hand and
					(9  + j) in hand and
					(13 + j) in hand and
					(17 + j) in hand):
					ret[1] = true
					break
			break
	
	return ret


func checkstraight(hand: PoolIntArray) -> bool:
	
	var hand_rank = []
	
	for c_idx in hand:
		for s in SUIT:
			for i in range(4):
				if (s * 4) + 1 + i == c_idx:
					hand_rank.append(s)
					break
	
	var last_idx = -1
	
	for i in range(5):
		if hand_rank[i] > last_idx:
			last_idx = hand_rank[i]
		else:
			if i == 4 and hand_rank[i] == 0:
				return true
			break
		if i == 4:
			return true
	
	last_idx = -1
	
	for i in range(5):
		if hand_rank[4 - i] > last_idx:
			last_idx = hand_rank[4 - i]
		else:
			if i == 4 and hand_rank[4 - i] == 0:
				return true
			break
		if i == 4:
			return true
	
	return false


func checksc(hand: PoolIntArray) -> Array:
	var ret = [0, 0, false]
	
	var tmp_sc = 0
	
	for s in SUIT:
		
		tmp_sc = 0
		
		for i in range(4):
			if (s * 4) + 1 + i in hand:
				tmp_sc += 1
		
		if tmp_sc > 1:
			if s < 4:
				ret[2] = true
		
		if tmp_sc > 1:
			if tmp_sc == 2:
				if ret[0] == 0:
					ret[0] = tmp_sc
				else:
					ret[1] = tmp_sc
			else:
				ret[0] = tmp_sc
	
	return ret


func randhand() -> PoolStringArray:
	var ret = []
	var newcard 
	var used = []
	for i in range(5):
		if chold[i]:
			ret.append(chand[i])
		else:
			while true:
				newcard = CARD_POOL[randi()%(CARD_POOL.size() - 1) + 1]
				if !newcard in chand and !newcard in used:
					break
			ret.append(newcard)
			used.append(newcard)
	return ret


func betanim() -> void:
	for i in range(cbet):
		if i > 0:
			get_node("tableholder/bet_" + str(i) + "/bg").hide()
		get_node("tableholder/bet_" + str(i + 1) + "/bg").show()
		yield(get_tree().create_timer(0.1), "timeout")
	yield(get_tree().create_timer(0.2), "timeout")
	get_node("tableholder/bet_" + str(cbet) + "/bg").hide()


func simspl(comb: String, prize: int) -> void:
	lwin.set("custom_colors/font_color", Color("#ffffff"))
	lwin.set("custom_colors/font_outline", Color("#750000"))
	lwin.text = comb + "!"
	tw.remove(lwin, "modulate:a")
	tw.remove(lwin, "rect_scale")
	tw.interpolate_property(lwin, "modulate:a",
	0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.interpolate_property(lwin, "modulate:a",
	1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.5)
	tw.interpolate_property(lwin, "rect_scale",
	Vector2(3, 3), Vector2(2, 2), 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.interpolate_property(lwin, "modulate:a",
	0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.6)
	tw.interpolate_property(lwin, "modulate:a",
	1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 1.1)
	tw.interpolate_property(lwin, "rect_scale",
	Vector2(4, 4), Vector2(3, 3), 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.6)
	tw.start()
	yield(get_tree().create_timer(0.6), "timeout")
	lwin.text = str(prize) + "$"


func winspl(comb: String, prize: int) -> void:
	lwin.set("custom_colors/font_color", Color("#ffea00"))
	lwin.set("custom_colors/font_outline", Color("#750000"))
	lwin.text = comb + "!"
	tw.remove(lwin, "modulate:a")
	tw.remove(lwin, "rect_scale")
	tw.interpolate_property(lwin, "modulate:a",
	0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.interpolate_property(lwin, "modulate:a",
	1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.5)
	tw.interpolate_property(lwin, "rect_scale",
	Vector2(4, 4), Vector2(3, 3), 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.interpolate_property(lwin, "modulate:a",
	0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.6)
	tw.interpolate_property(lwin, "modulate:a",
	1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 1.1)
	tw.interpolate_property(lwin, "rect_scale",
	Vector2(5, 5), Vector2(4, 4), 0.25, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.6)
	tw.start()
	yield(get_tree().create_timer(0.6), "timeout")
	lwin.text = str(prize) + "$"


func clearhold() -> void:
	chold = [false, false, false, false, false]
	for i in range(5):
		nchold = get("card_" + str(i)).get_node("HOLD")
		tw.remove(nchold, "modulate:a")
		tw.remove(nchold, "rect_position:y")
		tw.interpolate_property(nchold, "modulate:a",
			null, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, float(i) / 25)
		tw.interpolate_property(nchold, "rect_position:y",
			null, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, float(i) / 25)
	tw.start()


func hold(idx: int) -> void:
	if !cholding or !canhold: return
	nchold = get("card_" + str(idx)).get_node("HOLD")
	tw.remove(nchold, "modulate:a")
	tw.remove(nchold, "rect_position:y")
	if chold[idx]:
		tw.interpolate_property(nchold, "modulate:a",
			null, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tw.interpolate_property(nchold, "rect_position:y",
			null, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	else:
		tw.interpolate_property(nchold, "modulate:a",
			0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tw.interpolate_property(nchold, "rect_position:y",
			0, -40, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.start()
	hold_timer = HOLD_TIME
	chold[idx] = !chold[idx]


func giveahand(hand: PoolStringArray) -> void:
	for i in range(5):
		if hand[i] != chand[i]:
			chand[i] = hand[i]
			chcard(i, chand[i])
			yield(get_tree().create_timer(0.1), "timeout")


func chcard(idx: int, card_n: String) -> void:
	nccard = get("card_" + str(idx)) as TextureRect
	ncres = load(CRES_POOL + card_n + ".png") as StreamTexture
	if nccard == null || ncres == null:
		print("Failed to load idx: " +
			str(idx) + ", card_n: " + str(card_n))
		return
	
	tw.remove(nccard, "rect_scale:x")
	tw.interpolate_property(nccard, "rect_scale:x",
		1, 0, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tw.interpolate_property(nccard, "rect_scale:x",
		0, 1, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.1)
	tw.start()
	yield(get_tree().create_timer(0.1), "timeout")
	
	nccard.texture = ncres

func _on_bet_one_pressed() -> void:
	cbet += 1
	if cbet > 5:
		cbet = 1
	lbet.text = "BET: " + str(cbet)

func _on_bet_max_pressed() -> void:
	cbet = 5
	lbet.text = "BET: " + str(cbet)

func _on_deal_pressed() -> void:
	hold_timer = 0.0
	if playcount > 0 and lastwin > 0:
		cbal += lastwin
		lbal.text = str(cbal) + "$"
	start()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lmb"):
		for i in range(5):
			if (get("card_" + str(i)) as TextureRect).\
					get_global_rect().has_point(get_local_mouse_position()):
				hold(i)
				break


func _ready() -> void:
	bet_one.connect("pressed", self, "_on_bet_one_pressed")
	bet_max.connect("pressed", self, "_on_bet_max_pressed")
	deal.connect("pressed", self, "_on_deal_pressed")
	lbal.text = str(cbal) + "$"
