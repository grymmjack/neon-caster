''
' NEON-CASTER - GAME/ITEMS.BI
' =============================================================================
' Chapter 3: things in the world - the pickups, and the loot breakables
' leave.
'

'-----------------------------------------------------------------------------
' CHAPTER 3: THINGS IN THE WORLD
'-----------------------------------------------------------------------------
' Everything that isn't a wall - pickups, decorations, monsters, bolts - is a
' list of numbered things kept in "parallel arrays": thing number i is at
' (itemX(i), itemY(i)), is of kind itemKind(i), and so on. A count says how
' many are in use (numItems). It's the simplest way to keep lists in BASIC.
' (QB64PE's TYPE could bundle each thing's fields into one record instead -
' a nice exercise once you know the code.)
'
' Things are never deleted while a level runs; they're switched off
' (itemOn(i) = 0) so the numbering stays put.

' --- Pickups lying on the map ---
' IT_ = ITem: the kinds of pickup, the numbers kept in itemKind(i). Kinds 1-3
' are the red, blue and yellow keycards (they have no IT_ name - the number
' is the card's colour).
CONST IT_HEALTH = 4, IT_CELLS = 5, IT_SHELLS = 6, IT_SCATTER = 7, IT_REPEATER = 8
CONST IT_ARMOR = 9, IT_BIGMED = 10, IT_RAIL = 11, IT_MAP = 12
CONST IT_CORE = 15 ' (a data core: only in the network)
CONST IT_OVERCHARGE = 13, IT_AMP = 14 ' (overcharge: health up to MAX_OVER; damage amp: double damage for AMP_FRAMES)
CONST IT_GOGGLES = 16 ' (8 on the map: a night-vision headset - yours till you die, as a gun is; N switches it on and off)
CONST IT_SUIT = 17 ' (9 on the map: a hazmat suit - poison, slime and acid wear it, not you; fire and lava go straight through)
CONST IT_LAUNCHER = 18, IT_ROCKETS = 19 ' (on the map ) and (: the rocket launcher - gun 5, with five rockets - and a box of five rockets)
CONST IT_ROUNDS = 20, IT_SLUGS = 21 ' (on the map { and }: a box of forty repeater rounds, a canister of five railgun slugs)
CONST SUIT_MAX = 100, SUIT_WEAR = 0.5 ' (a suit's wear: SUIT_MAX new, and SUIT_WEAR of it for each point of harm it takes - a good half-minute in poison)
DIM SHARED suitLeft AS SINGLE ' (what's left of your suit: 0 none - lost when you die, as night vision is)
DIM SHARED nvHave AS SINGLE, nvOn AS INTEGER ' (night vision: whether you have a headset (1), and whether it's on - ApplyNight, and OpenGL's post shader's "night")
CONST MAX_OVER = 200, AMP_FRAMES = 1800
' MAX_ = the most there can be: the arrays below have room for this many
CONST MAX_ITEMS = 128
DIM SHARED itemX(MAX_ITEMS) AS SINGLE, itemY(MAX_ITEMS) AS SINGLE
DIM SHARED itemKind(MAX_ITEMS) AS INTEGER, itemOn(MAX_ITEMS) AS INTEGER, numItems AS INTEGER
' Loot tossed out of something broken (TossItem) flies for itemToss more
' frames, itemVX and itemVY a frame, in an arc - LOOT_TOSS frames in all,
' landing up to LOOT_REACH cells away
CONST LOOT_TOSS = 14, LOOT_REACH = 0.8, LOOT_CLEAR = 0.8 ' (and LOOT_CLEAR from you at least: you walk to it - pickups are taken within 0.45)
DIM SHARED itemToss(MAX_ITEMS) AS INTEGER, itemVX(MAX_ITEMS) AS SINGLE, itemVY(MAX_ITEMS) AS SINGLE
DIM SHARED hasCard(3) AS INTEGER

' ...and what each kind of decoration may leave when it breaks: LOOT_SLOTS
' drops, A to D, each a pickup kind (IT_) and its chance in percent. The
' game's own table (LootTable), then the level's [loot] lines over it -
' kept as their lines in lvlLoot$(), one a kind (chapter 22)
CONST LOOT_SLOTS = 4
CONST LOOT_HELP$ = "' breakable = up to four drops, A B C D - each pickup:chance (in %), or - for none. Breaking one rolls 1-100 once: the first drop whose chance (added to those before it) covers it comes out"
DIM SHARED lootKind(DECO_KINDS, LOOT_SLOTS) AS INTEGER, lootPct(DECO_KINDS, LOOT_SLOTS) AS INTEGER
DIM SHARED lvlNumLoot AS INTEGER, lvlLoot$(DECO_KINDS)
