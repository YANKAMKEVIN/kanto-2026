> **Annexe de recherche du J25** (Claude, 2026-10-16), en anglais : relevé Rouge/Bleu de Cramois'Île tiré de `pret/pokered` et de Poképédia. Sert la passe `j25-v2-alignement.md` ; les croquis ASCII sont approximatifs (voir §1.9). Ce n'est pas un document de conception.

# Pokémon Red/Blue (EN): Cinnabar Island reference (Cramois'Île)

Researched 2026-10-16. **Main source: the pret/pokered disassembly** (`https://github.com/pret/pokered`, branch `master`). All file paths below are relative to that repo (raw files at `https://raw.githubusercontent.com/pret/pokered/master/<path>`). French names come from Poképédia (cited where used).

Conventions:
- **Coordinates** are pokered "steps" (16×16 px squares, 2×2 tiles of 8 px), origin at the top-left, x to the right, y downwards.
- **Map dimensions** in `constants/map_constants.asm` are in **blocks**. A block is 32×32 px, which is 2×2 steps or 4×4 tiles. The brief said "16×16 blocks", but Gen 1 blocks are 32×32 and the 16×16 unit is the step.
- **[R]** means Red only, **[B]** Blue only. Anything not marked is identical in both versions; pokered only branches on `_RED`/`_BLUE` in the wild data.
- **UNVERIFIED** marks anything I did not confirm in the source.

---

## 1. Pokémon Mansion (Manoir Pokémon)

### 1.1 Dimensions (`constants/map_constants.asm`)

| Map | Blocks (w×h) | Steps | Tiles (8 px) | Tileset |
|---|---|---|---|---|
| POKEMON_MANSION_1F | 15×14 | 30×28 | 60×56 | FACILITY |
| POKEMON_MANSION_2F | 15×14 | 30×28 | 60×56 | FACILITY |
| POKEMON_MANSION_3F | 15×9 | 30×18 | 60×36 | FACILITY |
| POKEMON_MANSION_B1F | 15×14 | 30×28 | 60×56 | FACILITY |

The tileset comes from `data/maps/headers/PokemonMansion*.asm`. Border block: $2e on 1F, $01 on the other floors.

### 1.2 Warps (`data/maps/objects/PokemonMansion*.asm`)

**1F**
- (4,27), (5,27), (6,27), (7,27) → LAST_MAP (Cinnabar Island). This is the **main entrance**, on the south wall.
- (26,27), (27,27) → LAST_MAP. A **second south-east exit**. It sits right below the 1F switch gate at block (13,13), so it is closed while the switch is OFF (see §1.4). That last point is my reading of the gate coordinates.
- (5,10) → 2F warp 1 (stairs up).
- (21,23) → B1F warp 1 (stairs down).
- On Cinnabar Island, the mansion door is at (6,3) and leads to **1F warp 2**, so you arrive at (5,27).

**2F**
- (5,10) → 1F (the down stairs).
- (7,10) → 3F at (7,10).
- (25,14) → 3F at (25,14).
- (6,1) → 3F at (6,1).
- So 2F and 3F are linked by **three separate staircases**.

**3F**
- (7,10) → 2F.
- (6,1) → 2F.
- (25,14) → 2F.

**B1F**
- (23,22) → 1F at (21,23). This is the **only staircase**: B1F connects to 1F alone.

**Ways out:** 1F is the only floor with exits (the two south doors). From B1F the only way out is the stairs back up to 1F (or an Escape Rope / Dig). Entering the Cinnabar Island map runs `ResetEvent EVENT_MANSION_SWITCH_ON` (`scripts/CinnabarIsland.asm`), so **the switch is always OFF when you come back in**.

### 1.3 Holes on 3F (`scripts/PokemonMansion3F.asm`, `data/maps/special_warps.asm`)

There are three hole squares: `.holeCoords` (16,14), (17,14) and (19,14). Walking onto one triggers a dungeon warp, and `DungeonWarpList` / `DungeonWarpData` give the landing points:
- **Hole 1 (16,14) and hole 2 (17,14)** → **1F, landing at (16,14)**.
- **Hole 3 (19,14)** → **2F, landing at (18,14)**.

A 3F scientist hints at this: "So, you're stuck? Try jumping off over there!"

### 1.4 Secret switches (statues)

**Where they are.** The switches are *hidden events* that only work when the player faces UP (`data/events/hidden_events.asm`):

| Floor | Switch position(s) |
|---|---|
| 1F | (2,5) |
| 2F | (2,11) |
| 3F | (10,5) |
| B1F | (20,3) **and** (18,25), two switches |

**How they work** (`scripts/PokemonMansion1F.asm` and the 2F/3F/B1F scripts):
- Every floor has the same prompt: "A secret switch!" / "Press it?" YES/NO.
- YES: prints "Who wouldn't?", plays SFX_GO_INSIDE, then **toggles one single global flag, `EVENT_MANSION_SWITCH_ON`**. If the flag was clear it is set, otherwise it is reset.
- NO: prints "Not quite yet!".
- 3F and B1F reuse the 2F switch script, so their behaviour is identical.
- **The state is not per floor.** One flag drives every floor. Each floor's script redraws its gate blocks from that flag on map load, and also right after a press, through `BIT_CUR_MAP_LOADED_1`.
- So each floor has two sets of doors that alternate: set A is closed while the flag is OFF and open while it is ON, and set B is the opposite.
- The 2F burglar says so after the battle: "Switches open and close alternating sets of doors!"
- The flag resets to OFF whenever you step onto Cinnabar Island.

**Gate blocks per floor.** `ReplaceTileBlock` takes b = Y, c = X, in block coordinates (see `engine/overworld/update_map.asm`). A block (bx,by) covers steps (2bx..2bx+1, 2by..2by+1). Block IDs: $0e = open floor, $2d / $54 = horizontal gate, $5f = vertical gate.

| Floor | Closed when switch **OFF** (default), open when ON | Closed when switch **ON**, open when OFF |
|---|---|---|
| 1F | block (8,3) = steps (16-17, 6-7) [$2d]; block (10,8) = steps (20-21, 16-17) [$2d]; block (13,13) = steps (26-27, 26-27) [$2d] (just above the SE exit) | block (12,6) = steps (24-25, 12-13) [$2d] |
| 2F | block (9,4) = steps (18-19, 8-9) [$54]; block (3,11) = steps (6-7, 22-23) [$5f] | block (4,2) = steps (8-9, 4-5) [$5f] |
| 3F | block (7,5) = steps (14-15, 10-11) [$5f] | block (7,2) = steps (14-15, 4-5) [$5f] |
| B1F | block (4,3) = steps (8-9, 6-7) [$5f]; block (8,8) = steps (16-17, 16-17) [$54] | block (13,8) = steps (26-27, 16-17) [$2d]; block (6,11) = steps (12-13, 22-23) [$5f] |

### 1.5 Trainers (`data/maps/objects/*.asm` + `data/trainers/parties.asm`)

In Gen 1, `db L, A, B, 0` means every Pokémon in the party is level L. The number after the header flag in each map script is the sight range.

| Floor | Position / sprite | Class (FR) | Party | Sight | Prize* |
|---|---|---|---|---|---|
| 1F | (17,17) scientist, facing left | SCIENTIST #4 (Scientifique). Same party as Silph 3F | ELECTRODE 29, WEEZING 29 | 3 | ¥1450 |
| 2F | (3,17) super nerd sprite, walks left/right | BURGLAR #7 (Pillard) | CHARMANDER 34, CHARMELEON 34 | 0 (talk only) | ¥3060 |
| 3F | (5,11) super nerd sprite, walks left/right | BURGLAR #8 | NINETALES 38 | 0 | ¥3420 |
| 3F | (20,11) scientist, facing left | SCIENTIST #12 | MAGNEMITE 33, MAGNETON 33, VOLTORB 33 | 2 | ¥1650 |
| B1F | (16,23) super nerd sprite, standing | BURGLAR #9 | GROWLITHE 34, PONYTA 34 | 0 | ¥3060 |
| B1F | (27,11) scientist, facing down | SCIENTIST #13 | MAGNEMITE 34, ELECTRODE 34 | 3 | ¥1700 |

\*Prize = class base money ÷ 100 × level of the last Pokémon. Base money is in `data/trainers/pic_pointers_money.asm`: Scientist 5000, Burglar 9000, Super Nerd 2500, Blaine 9900. My calculation; Blaine's ¥4653 matches Poképédia.

Pre-battle lines (`text/PokemonMansion*.asm`):
- 1F scientist: "Who are you? There shouldn't be anyone here." After the battle: "A key? I don't know what you're talking about."
- 2F burglar: "I can't get out! This old place is one big puzzle!"
- 3F burglar: "This place is like, huge!" After: "I wonder where my partner went."
- 3F scientist: "My mentor once lived here."
- B1F burglar: "Uh-oh. Where am I now?" After: "You can find stuff lying around."
- B1F scientist: "This place is ideal for a lab." After: "I like it here! It's conducive to my studies!"

### 1.6 Items (FR names from Poképédia)

| Floor | Visible Poké Balls | Hidden items (`data/events/hidden_events.asm`) |
|---|---|---|
| 1F | ESCAPE ROPE (Corde Sortie) (14,3); CARBOS (Carbone) (18,21) | MOON STONE (Pierre Lune) (8,16) |
| 2F | CALCIUM (28,7) | none |
| 3F | MAX POTION (Potion Max) (1,16); IRON (Fer) (25,5) | MAX REVIVE (Rappel Max) (1,9) |
| B1F | RARE CANDY (Super Bonbon) (10,2); FULL RESTORE (Guérison) (1,22); TM14 BLIZZARD (19,25); TM22 SOLARBEAM (Lance-Soleil) (5,4); **SECRET KEY (Clé Secrète) (5,13)** | RARE CANDY (1,9) |

**The SECRET KEY** is a normal Poké Ball object on **B1F at (5,13)**, in the west room. Poképédia describes it as "between four potted plants". Picking it up goes through `PickUpItemText`, with no special script.

### 1.7 Journals (diary entries), exact EN text

The diaries are SPRITE_POKEDEX objects. Line breaks are shown as " / ".

| Floor / position | Text |
|---|---|
| 2F (18,2) | "Diary: July 5 / Guyana, / South America" ‖ "A new #MON was / discovered deep / in the jungle." |
| 2F (3,22) | "Diary: July 10 / We christened the / newly discovered / #MON, MEW." |
| 3F (6,12) | "Diary: Feb. 6 / MEW gave birth." ‖ "We named the / newborn MEWTWO." |
| B1F (16,20) | "Diary; Sept. 1 / MEWTWO is far too / powerful." ‖ "We have failed to / curb its vicious / tendencies..." |

"#MON" is the engine's POKéMON glyph. The semicolon in "Diary; Sept. 1" is in the original.

French Gen 1 text, as quoted by Poképédia (Manoir Pokémon (Kanto)). Poképédia does not give the floors.
- « Jungle X. Un nouveau type de Pokémon fut découvert »
- « Le Pokémon fut baptisé Mew. »
- « Mew est papa (ou maman?). Le petit fut baptisé Mewtwo. »
- « Mewtwo est trop puissant. Nous sommes impuissants face à ses pièges… »

### 1.8 Wild Pokémon (`data/wild/maps/PokemonMansion*.asm`)

- Encounter rate: **10/256 per step on every floor**. Floors count as "grass" everywhere. There is no water.
- The 10 slots in order have probabilities 51, 51, 39, 25, 25, 25, 13, 13, 11, 3 out of 256, i.e. **19.9 / 19.9 / 15.2 / 9.8 / 9.8 / 9.8 / 5.1 / 5.1 / 4.3 / 1.2 %**. This is standard Gen 1; the cumulative table is in `data/wild/probabilities.asm` (I did not re-fetch it).

| Slot | 1F [R] | 1F [B] | 2F [R] | 2F [B] | 3F [R] | 3F [B] | B1F [R] | B1F [B] |
|---|---|---|---|---|---|---|---|---|
| 1 | Koffing 32 | Grimer 32 | Growlithe 32 | Vulpix 32 | Koffing 31 | Grimer 31 | Koffing 33 | Grimer 33 |
| 2 | Koffing 30 | Grimer 30 | Koffing 34 | Grimer 34 | Growlithe 33 | Vulpix 33 | Koffing 31 | Grimer 31 |
| 3 | Ponyta 34 | Ponyta 34 | Koffing 34 | Grimer 34 | Koffing 35 | Grimer 35 | Growlithe 35 | Vulpix 35 |
| 4 | Ponyta 30 | Ponyta 30 | Ponyta 30 | Ponyta 30 | Ponyta 32 | Ponyta 32 | Ponyta 32 | Ponyta 32 |
| 5 | Growlithe 34 | Vulpix 34 | Koffing 30 | Grimer 30 | Ponyta 34 | **Magmar 34** | Koffing 31 | Grimer 31 |
| 6 | Ponyta 32 | Ponyta 32 | Ponyta 32 | Ponyta 32 | Weezing 40 | Muk 40 | Weezing 40 | Muk 40 |
| 7 | Grimer 30 | Koffing 30 | Grimer 30 | Koffing 30 | Grimer 34 | Koffing 34 | Ponyta 34 | Ponyta 34 |
| 8 | Ponyta 28 | Ponyta 28 | Ponyta 28 | Ponyta 28 | Weezing 38 | Muk 38 | Grimer 35 | Koffing 35 |
| 9 | Weezing 37 | Muk 37 | Weezing 39 | Muk 39 | Ponyta 36 | Ponyta 36 | Weezing 42 | **Magmar 38** |
| 10 | Muk 39 | Weezing 39 | Muk 37 | Weezing 37 | Muk 42 | Weezing 42 | Muk 42 | Weezing 42 |

In short:
- Red has Growlithe and more Koffing/Weezing.
- Blue has Vulpix and more Grimer/Muk.
- **Magmar is Blue only**: 3F slot 5 (9.8 %) and B1F slot 9 (4.3 %).

FR names: Smogo, Smogogo, Tadmorv, Grotadmorv, Caninos, Goupix, Ponyta, Magmar.

### 1.9 ASCII sketches (derived from the block data; approximate)

**How these were made.** A script read `maps/<Map>.blk` and `gfx/blocksets/facility.bst`. For each step it checks the bottom-left 8×8 tile against `Facility_Coll` in `data/tilesets/collision_tile_ids.asm`. The script is in this scratchpad (`render2.py`, output `maps2.txt`).

**Approximations:**
- `.` = walkable and `#` = blocked come only from that tile check. Ledges, desks and statues are not drawn separately.
- Some areas may be out-of-bounds voids, for example the big open square in the bottom-right of 2F (x15-29, y16-27). Check against a real screenshot before using.
- Gate blocks are drawn over the base map.

Legend:
- `E` exit · `U` stairs up · `D` stairs down · `O` hole (3F)
- `S` scientist · `B` burglar · `i` item ball · `h` hidden item · `K` SECRET KEY · `J` diary · `$` switch (face up to use)
- `=` gate closed while switch OFF (default) · `%` gate closed while switch ON

```
1F (30x28)
    0         1         2
    012345678901234567890123456789
  0 ##############################
  1 #............................#
  2 ####.........#.#.#.#.#......##
  3 ####.....#....i.............##
  4 ###...##.#............####..##
  5 ##$...##.#............#.....##
  6 #...#....#......==....#......#
  7 #...#....#...###==#####......#
  8 #.......####.#......###.##..##
  9 ##########...#......###.##..##
 10 #..#.U..#....#..#.#..##....###
 11 #............#..#.#..##....###
 12 #..#....#....#........##%%...#
 13 #..........#############%%####
 14 #..#....#..#......####......##
 15 #..........#......##........##
 16 #..#....h..#......#.==.......#
 17 #..........#.....S##==##..####
 18 #..#....#..#..######..##..####
 19 #..........#..######..###...##
 20 #..#....#..#............#....#
 21 #..........#......i.....#....#
 22 #..#....#..#..######....#....#
 23 #..........#..######.D..#....#
 24 #..#....#..#............##...#
 25 #..........#............##...#
 26 #..........#............##==##
 27 ####EEEE##################EE##
```
```
2F (30x28)
    0         1         2
    012345678901234567890123456789
  0 ##############################
  1 ######U..#.....#......#.######
  2 ####.....#.....#..J#..#...####
  3 ####.....#.....#..##........##
  4 ##......%%.....#......###....#
  5 ##......%%.....###..#####....#
  6 #...#.#..#.............#####.#
  7 #...#.#..#.............#####i#
  8 #........#...#####==##########
  9 ##########...###..==..##..####
 10 #.#..D.U.....###......#......#
 11 #.$..........###......#......#
 12 #......##.....####....#......#
 13 #......##..#########..#...####
 14 #####.###..#######....##.U...#
 15 ####..###..#######....##.....#
 16 #....#####.#..#...############
 17 #..B.#####.#..#...............
 18 ########...#..#...............   <- area x15-29,y16-27: probably
 19 ######.#...#..#...............      void/outside, not playable
 20 #......#...#..#...............      (UNVERIFIED)
 21 #......#...#..#...............
 22 #.#J##==......#...............
 23 #.####==...#..#...............
 24 #......#...#..#...............
 25 #......#...#..#...............
 26 #......#...####...............
 27 ############..................
```
```
3F (30x18)
    0         1         2
    012345678901234567890123456789
  0 ##############################
  1 #.....D...####.########.######
  2 #...........##.#......#...####
  3 #...........##.#......#...####
  4 ###......##...%%..##.......###
  5 ###......#$...%%..##.....i.###
  6 ##########.....#.....##......#
  7 ##########.....#.....##......#
  8 #####...#####..#..######.....#
  9 #h###.....###..###############
 10 #.##...D..###.==##....#......#
 11 #.##.B....###.==....S.#......#
 12 #.##..J#.###..##..#..........#
 13 #.....##.#######..#.###.######
 14 ####....####....OO.O..#..D...#   O(16,14),O(17,14) -> 1F (16,14)
 15 ####....####..........#......#   O(19,14)          -> 2F (18,14)
 16 #i....######..........#......#
 17 ############..........########
```
```
B1F (30x28)
    0         1         2
    012345678901234567890123456789
  0 ##############################
  1 ########.###########.........#
  2 ##.......#i.......###.#.#.#..#
  3 ##.......#........##$.#.#.#..#
  4 #...#i...#.........#.........#
  5 #...##...###..##########..####
  6 #.......==...................#
  7 #.......==...................#
  8 ####..####################...#
  9 #h.......#...............#...#
 10 #.##..##.#...............#...#
 11 #.##..##.#...............#.S.#
 12 #........#...............#...#
 13 #....K...#...............#...#
 14 #.##..##.#...............#...#
 15 #.##..##.#...............#...#
 16 #........#...###==###....#%%.#
 17 ##########...###==###....#%%##
 18 #............#......#........#
 19 #............#......#........#
 20 #............#..J#..#........#
 21 #............#..##..#........#
 22 #i..........%%......#..U.....#
 23 #...........%%..B...#........#
 24 #............#....#.#........#
 25 #............#....$i#........#
 26 #............#......#........#
 27 ##############################
```

**Typical route to the Secret Key.** UNVERIFIED: this is reconstructed from common walkthrough knowledge, not traced step by step in the code.
1. 1F → stairs (5,10) → 2F.
2. 2F → 3F (by (7,10) or (6,1)).
3. On 3F, use the switch (10,5) to open the passage east.
4. Drop through the 3F holes to reach otherwise isolated parts of 1F, including the 1F stairs down at (21,23).
5. On B1F, use the switches (20,3) / (18,25) to open the way west to the key at (5,13).

Because the flag is global, pressing a switch on one floor also changes the doors on the others.

---

## 2. Cinnabar Lab (Laboratoire Pokémon)

### 2.1 Rooms

Sources: `constants/map_constants.asm`, `data/maps/objects/CinnabarLab*.asm`, scripts and text. Poképédia's FR room names are given in brackets.

**Lobby: CINNABAR_LAB, 9×4 blocks (18×8 steps)** [« Entrée et couloir »]
- Exit warps (2,7) and (3,7) lead to the island door at (6,9).
- Three doors in the corridor, each with a sign to its right:
  - (8,4) → **Meeting Room**, sign "#MON LAB / Meeting Room" [« Salle de réunion »]
  - (12,4) → **R-and-D Room**, sign "#MON LAB / R-and-D Room" [« Département Recherche et Développement »]
  - (16,4) → **Testing Room**, sign "#MON LAB / Testing Room" [« Salle de test »]
- The bg event at (3,2) is a photo: "A photo of the LAB's founder, DR.FUJI!"
- A Fishing Guru NPC stands at (1,3): "We study #MON extensively here. People often bring us rare #MON for examination."

**Meeting Room: CINNABAR_LAB_TRADE_ROOM, 4×4 blocks**
- Super Nerd at (3,2): "I found this very strange fossil in MT.MOON! I think it's a rare, prehistoric #MON!"
- Gramps at (1,4): **trade TRADE_FOR_DORIS**.
- Beauty at (5,5): **trade TRADE_FOR_CRINKLES**.

**R-and-D Room: CINNABAR_LAB_METRONOME_ROOM, 4×4 blocks**
- Scientist at (7,2) gives **TM35 METRONOME** once (EVENT_GOT_TM35).
  - Before: "Tch-tch-tch! I made a cool TM! It can cause all kinds of fun!"
  - Bag full: "Your pack is crammed full!"
  - Afterwards he explains METRONOME.
- Scientist at (2,3), walking left/right: "EEVEE can evolve into 1 of 3 kinds of #MON."
- PC at (0,4)/(1,4) shows an e-mail: the 3 legendary birds are ARTICUNO, ZAPDOS and MOLTRES, their whereabouts are unknown, and the team plans "to explore the cavern close to CERULEAN". Signed "#MON RESEARCH TEAM".
- (2,1): "An amber pipe!"

**Testing Room: CINNABAR_LAB_FOSSIL_ROOM, 4×4 blocks**
- Scientist 1 at (5,2), walking left/right, is the **fossil reviver**.
- Scientist 2 at (7,6), facing up: **trade TRADE_FOR_SAILOR**.
- Hidden PCs at (0,4) and (2,4): OpenPokemonCenterPC (`hidden_events.asm`).

### 2.2 In-game trades on Cinnabar (`data/events/trades.asm`)

These are all of Cinnabar's trades; there are none elsewhere on the island in RB. They are identical in EN Red and Blue.

| Room / NPC | You give | You get | Nickname (EN) | FR nickname (Poképédia) | Dialogue set |
|---|---|---|---|---|---|
| Meeting Room, Gramps | RAICHU | ELECTRODE | **DORIS** | Kourjus | EVOLUTION (set 2) |
| Meeting Room, Beauty | VENONAT (Mimitoss) | TANGELA (Saquedeneu) | **CRINKLES** | Bigoudi | HAPPY (set 3) |
| Testing Room, Scientist 2 | PONYTA | SEEL (Otaria) | **SAILOR** | Bibi | CASUAL (set 1) |

Dialogue texts (`data/text/text_*.asm`):
- **Set 1 (casual)**
  - Offer: "I'm looking for X! Wanna trade one for Y?"
  - Refuse: "Awww! Oh well..."
  - Wrong Pokémon: "What? That's not X! If you get one, come back here!"
  - Done: "Hey thanks!"
  - After: "Isn't my old Y great?"
- **Set 2**
  - Offer: "Hello there! Do you want to trade your X for Y?"
  - Refuse: "Well, if you don't want to..."
  - Wrong Pokémon: "Hmmm? This isn't X. Think of me when you get one."
  - Done: "Thanks!"
  - After: "The X you traded to me went and evolved!" pokered notes this is a leftover from JP Blue and makes no sense for Raichu.
- **Set 3**
  - Offer: "Hi! Do you have X? Want to trade it for Y?"
  - Refuse: "That's too bad."
  - Wrong Pokémon: "...This is no X. If you get one, trade it with me!"
  - Done: "Thanks pal!"
  - After: "How is my old Y?"
- Shared lines: "Okay, connect the cable like so!", then "<PLAYER> traded X for Y!"

**Gen 1 trade mechanics** (`engine/events/in_game_trades.asm`):
- You confirm with YES/NO, then pick the Pokémon from the party menu. It must be the exact species.
- **The received Pokémon has your Pokémon's level** (`wCurEnemyLevel` = the selected party member's level).
- Its nickname is fixed, and the player is not allowed to rename it.
- Its **OT name is "TRAINER"** (the `<TRAINER>` glyph, `InGameTrade_TrainerString`).
- Its OT ID is random (`Random` → `wTradedEnemyMonOTID`).
- Because the OT ID differs from yours, it gains boosted EXP and obeys only up to your badge cap. This is standard Gen 1 behaviour, not re-traced here.
- DVs come from `AddPartyMon`. UNVERIFIED whether they are random or fixed.
- Each trade is done once only (`wCompletedInGameTradeFlags`).
- A trade-evolution check runs afterwards (`InGameTrade_CheckForTradeEvo`), but none of these three species evolves by trade.
- The Cinnabar Pokémon Center gentleman: "#MON you get in trades grow very quickly."

### 2.3 Fossil revival

Sources: `scripts/CinnabarLabFossilRoom.asm`, `engine/events/cinnabar_lab.asm`, `scripts/CinnabarIsland.asm`.

1. **Talk to Scientist 1** while EVENT_GAVE_FOSSIL_TO_LAB is clear. He says: "Hiya! I am important doctor! I study here rare #MON fossils! You! Have you a fossil for me?"
2. **Bag check.** He looks for DOME FOSSIL, HELIX FOSSIL and OLD AMBER, in that order (`FossilsList`). With none: "No! Is too bad!"
3. **Several fossils:** a menu lists every fossil in the bag and you pick one (B cancels). One fossil gives a one-line menu. **Only one fossil can be in revival at a time.**
4. **Species mapping:**
   - DOME FOSSIL → KABUTO
   - HELIX FOSSIL → OMANYTE (Amonita)
   - OLD AMBER → AERODACTYL (Ptéra)
5. **Confirmation.** He says: "Oh! That is <fossil>! It is fossil of <mon>, a #MON that is already extinct! My Resurrection Machine will make that #MON live again!" Then YES/NO.
   - NO: "Aiyah! You come again!"
   - YES: "So! You hurry and give me that! <PLAYER> handed over <fossil>!" The item is removed, and he adds "I take a little time! You go for walk a little while!"
   - This sets **EVENT_GAVE_FOSSIL_TO_LAB** and **EVENT_LAB_STILL_REVIVING_FOSSIL**.
6. **The "come back later" condition.** `CinnabarIsland_Script` runs `ResetEvent EVENT_LAB_STILL_REVIVING_FOSSIL` every time the Cinnabar Island overworld map script runs. So you only have to **step out of the lab onto the island and go back in**. No time, steps or battles are needed.
   - If you talk to him before that: "I take a little time! You go for walk a little while!"
7. **Collecting.** He says: "Where were you? Your fossil is back to life! It was <mon> like I think!" Then `GivePokemon` with **level 30** (`ld c, 30`).
   - Party full: `GivePokemon` sends it to the current PC box (standard message).
   - Box also full: the carry flag is clear, the events are not reset, and you can collect later.
   - Success resets all three flags (GAVE / STILL_REVIVING / HANDING_OVER), so another fossil can be given.
8. **Limit:** in RB you can own at most two fossils, Old Amber plus one of Dome or Helix, so two revivals.

---

## 3. Cinnabar Gym (Arène de Cramois'Île)

### 3.1 Access and layout

**Locked door.** `scripts/CinnabarIsland.asm`:
- The gym door on the island is at (18,3).
- Without the **SECRET KEY** in the bag, standing at (18,4) shows "The door is locked..." and the game makes the player step back down. No other check exists; holding the key is enough.

**Dimensions:** 10×9 blocks (20×18 steps), FACILITY tileset. Entrance warps (16,17) and (17,17).

**Gym sign:** "CINNABAR ISLAND #MON GYM LEADER: BLAINE" ‖ "The Hot-Headed Quiz Master!"

**Objects** (`data/maps/objects/CinnabarGym.asm`):
- Blaine at (3,3).
- Gym Guide at (16,13).
- Gym statue (hidden) at (17,13).
- Seven trainers, numbered #1 to #7 in the table below.

**Gates** (`engine/events/hidden_events/cinnabar_gym_quiz.asm`, `CinnabarGymGateCoords`, block coordinates):

| Gate | Block | Steps | Type |
|---|---|---|---|
| 1 | (9,3) | (18-19, 6-7) | horizontal |
| 2 | (6,3) | (12-13, 6-7) | horizontal |
| 3 | (6,6) | (12-13, 12-13) | horizontal |
| 4 | (3,8) | (6-7, 16-17) | vertical |
| 5 | (2,6) | (4-5, 12-13) | horizontal |
| 6 | (2,3) | (4-5, 6-7) | horizontal |

Each gate is open if EVENT_CINNABAR_GYM_GATE<n>_UNLOCKED is set and locked otherwise. All are redrawn on map load.

**Gym trainers do not spot you.** No trainer headers are used, so you only fight them by talking to them or by answering a quiz wrong.

### 3.2 Quiz machines

Machines are hidden events; you face UP to read them. Argument = (answer << 4) | gate index. `CinnabarGymQuiz_AskQuestion` compares the answer with `wCurrentMenuItem`, where YES = 0 and NO = 1. So **FALSE means YES is correct, and TRUE means NO is correct.**

Intro text, shown on every machine: "#MON Quiz!" ‖ "Get it right and the door opens to the next room!" ‖ "Get it wrong and face a trainer!" ‖ "If you want to conserve your #MON for the GYM LEADER..." ‖ "Then get it right! Here we go!"

| # | Machine pos. | Question (exact EN) | Correct | Opens gate | Wrong answer → trainer |
|---|---|---|---|---|---|
| 1 | (15,7) | "CATERPIE evolves into BUTTERFREE?" | **YES** | 1 | #2 Burglar (17,8) |
| 2 | (10,1) | "There are 9 certified #MON LEAGUE BADGEs?" | **NO** | 2 | #3 Super Nerd (11,4) |
| 3 | (9,7) | "POLIWAG evolves 3 times?" | **NO** | 3 | #4 Burglar (11,8) |
| 4 | (9,13) | "Are thunder moves effective against ground element-type #MON?" | **NO** | 4 | #5 Super Nerd (11,14) |
| 5 | (1,13) | "#MON of the same kind and level are not identical?" | **YES** | 5 | #6 Burglar (3,14) |
| 6 | (1,7) | "TM28 contains TOMBSTONER?" | **NO** | 6 | #7 Super Nerd (3,8) |

**Right answer:** "You're absolutely correct!" ‖ "Go on through!" The gate opens, with a jingle and SFX_GO_INSIDE the first time.

**Wrong answer:** SFX_DENIED, "Sorry! Bad call!"
- If that trainer is not yet beaten, he walks to you (one step left; #3 goes left then up) and battles you.
- Winning the battle opens the gate. Losing resets the scripts.
- If the trainer was already beaten, nothing happens. His gate is already open anyway, because beating trainer #k sets gate k-1.
- **Trainer #1** (17,2) is linked to no machine. Beating him sets the unused flag GATE0, so he is optional.

FR questions (Poképédia; machine 1 is the intro there, so its 2-7 are our 1-6):
1. « Chenipan évolue en Papilusion ? » Oui
2. « Il existe 9 Badges Pokémon ? » Non
3. « Ptitard évolue 3 fois ? » Non
4. « La foudre est efficace contre les Pokémon du sol ? » Non
5. « Les Pokémon du même type et du même niveau sont différents ? » Oui
6. « CT28 contient Fosse ? » Non

### 3.3 Gym trainers (`data/trainers/parties.asm`)

All seven use the SUPER_NERD sprite but come in two classes: Super Nerd (Intello) and Burglar (Pillard). Burglar #4/#5/#6 in parties.asm are the gym's Burglar entries.

| # | Pos. | Class | Party | Prize (my calc.) | Battle line |
|---|---|---|---|---|---|
| 1 | (17,2) | SUPER NERD #9 | VULPIX 36, VULPIX 36, NINETALES 36 | ¥900 | "Do you know how hot #MON fire breath can get?" |
| 2 | (17,8) | BURGLAR #4 | GROWLITHE 36, VULPIX 36, NINETALES 36 | ¥3240 | "I was a thief, but I became straight as a trainer!" |
| 3 | (11,4) | SUPER NERD #10 | PONYTA 34, CHARMANDER 34, VULPIX 34, GROWLITHE 34 | ¥850 | "You can't win! I have studied #MON totally!" |
| 4 | (11,8) | BURGLAR #5 | PONYTA 41 | ¥3690 | "I just like using fire #MON!" |
| 5 | (11,14) | SUPER NERD #11 | RAPIDASH 41 | ¥1025 | "I know why BLAINE became a trainer!" After the battle: Blaine was lost in the mountains when a fiery bird #MON appeared, and its light led him down. |
| 6 | (3,14) | BURGLAR #6 | VULPIX 37, GROWLITHE 37 | ¥3330 | "I've been to many GYMs, but this is my favorite!" |
| 7 | (3,8) | SUPER NERD #12 | GROWLITHE 37, VULPIX 37 | ¥925 | "Fire is weak against H2O!" |

### 3.4 Blaine (Auguste)

**Party.** `BlaineData` is `db $FF, 42 GROWLITHE, 40 PONYTA, 42 RAPIDASH, 47 ARCANINE`.

**Moves.** Each Pokémon gets its last four level-up moves at its level, from `evos_moves.asm` and `base_stats`. In addition, `LoneMoves` entry 7 (`wGymLeaderNo` = 7) is "3, FIRE_BLAST". That writes to `wEnemyMon1Moves + 2 + 3×struct`, i.e. **Pokémon #4, move slot 3**.

| Pokémon | Level | Moves |
|---|---|---|
| GROWLITHE (Caninos) | 42 | EMBER, LEER, TAKE DOWN, AGILITY |
| PONYTA | 40 | TAIL WHIP, STOMP, GROWL, FIRE SPIN |
| RAPIDASH (Galopa) | 42 | TAIL WHIP, STOMP, GROWL, FIRE SPIN |
| ARCANINE (Arcanin) | 47 | ROAR, EMBER, **FIRE BLAST**, TAKE DOWN (Fire Blast replaces Leer) |

These match Poképédia's list. Prize: **¥4653** (99 × 47), confirmed by Poképédia.

**Dialogue** (`text/CinnabarGym.asm`):
- Before the battle: "Hah! I am BLAINE! I am the LEADER of CINNABAR GYM! My fiery #MON will incinerate all challengers! Hah! You better have BURN HEAL!"
- On losing: "I have burnt out! You have earned the VOLCANOBADGE!"
- **Badge info:** "Hah! The VOLCANOBADGE heightens the SPECIAL abilities of your #MON! Here, you can have this too!"
  - Gen 1 effect: an in-battle ×9/8 boost to the Special stat. Volcano gives no obedience level or field move.
- **TM38 FIRE BLAST:** "<PLAYER> received TM38!" ‖ "TM38 contains FIRE BLAST! Teach it to fire-type #MON! CHARMELEON or PONYTA would be good bets!"
  - Bag full: "Make room for my gift!" You can collect it later by talking to him again (EVENT_GOT_TM38 stays clear).
- After: "FIRE BLAST is the ultimate fire technique! Don't waste it on water #MON!"

**After the win:** all seven gym trainers are flagged as beaten (`SetEventRange` TRAINER_0..6).

**Gym Guide:**
- Before: "Yo! Champ in making! The hot-headed BLAINE is a fire #MON pro! Douse his spirits with water! You better take some BURN HEALs!"
- After: "<PLAYER>! You beat that fire brand!"

### 3.5 Gym ASCII sketch (block data; same caveats as §1.9)

Legend:
- `L` Blaine · `1`–`7` trainers · `a`–`f` quiz machines 1–6 (stand below them, face up)
- `G` guide · `s` statue · `E` entrance
- Runs of the same digit, e.g. `11` or `22`, are gate N. They overlap the trainer digits, so read them in context.
- The single-step `.` column at x=7 and the openings at (1,1) / (9,1) may be tile-check artifacts (UNVERIFIED).

```
    0         1
    01234567890123456789
  0 ####################
  1 #.#####.#.b#........
  2 #.....#.#.....#..1..
  3 #..L..#.#.....#.....
  4 #.....#.#..3..#.....
  5 #.....#.#.....#.....
  6 ####66#.####22####11      gate6 (4-5,6-7)  gate2 (12-13,6-7)  gate1 (18-19,6-7)
  7 #f..66#.#c..22#a..11
  8 #..7..#.#..4..#..2..
  9 #.....#.#.....#.....
 10 #.....#.#.....#.....
 11 #.....#.#.....####..
 12 ####55#.####33#..#..      gate5 (4-5,12-13)  gate3 (12-13,12-13)
 13 #e..55#.#d..33#.Gs..
 14 #..6..#.#..5..#.....
 15 #.....###.....#.....
 16 #.....44......#.....      gate4 (6-7,16-17)
 17 #.....44......#.EE..
```

**Order of progress:**
1. Entrance (SE room: machine 1, trainer #2).
2. Gate 1 north (NE room: trainer #1).
3. West along row 1 to the N-centre room (machine 2, trainer #3).
4. Gate 2 south (machine 3, #4).
5. Gate 3 south (machine 4, #5).
6. Gate 4 west (SW room: machine 5, #6).
7. Gate 5 north (machine 6, #7).
8. Gate 6 north to Blaine's room (NW).

---

## 4. Rest of Cinnabar Island

**Map.** CINNABAR_ISLAND is 10×9 blocks (20×18 steps), OVERWORLD tileset (`data/maps/headers/CinnabarIsland.asm`).
- Connections: **north → ROUTE_21** (water, Surf, up to Pallet Town) and **east → ROUTE_20** (water east to the Seafoam Islands and on to Route 19 / Fuchsia).
- Seafoam Islands (Îles Écume) are reached from Route 20. Fly also works.

**Warps** (`data/maps/objects/CinnabarIsland.asm`):
- Mansion (6,3)
- Gym (18,3)
- Lab (6,9)
- Pokémon Center (11,11)
- Mart (15,11)

**Signs:**
- (9,5) town sign: "CINNABAR ISLAND / The Fiery Town of Burning Desire"
- (13,3) gym sign
- (9,11) "#MON LAB"
- (12,11) Center sign
- (16,11) Mart sign

**NPCs:**
- Girl at (12,5), walking: "CINNABAR GYM's BLAINE is an odd man who has lived here for decades."
- Gambler at (14,6): "Scientists conduct experiments in the burned out building."

**Pokémon Center** (7×4 blocks):
- Nurse.
- Cool Trainer F: "You can cancel evolution. When a #MON is evolving, you can stop it and leave it the way it is."
- Gentleman: the line about traded Pokémon quoted in §2.2.
- Link receptionist (Cable Club).
- Hidden bench guy (0,4) and PC (13,3).

**Mart** (`data/items/marts.asm`, CinnabarMartClerkText): **ULTRA BALL, GREAT BALL, HYPER POTION, MAX REPEL, ESCAPE ROPE, FULL HEAL, REVIVE**. FR, UNVERIFIED exact: Hyper Ball, Super Ball, Hyper Potion, Max Repousse, Corde Sortie, Total Soin, Rappel.
- Silph worker F: "Don't they have X ATTACK? It's good for battles!"
- Scientist: "It never hurts to have extra items!"

**Noted and skipped:** the "Cinnabar coast" MissingNo./item-duplication glitch is a shore-tile and wild-data artefact and is irrelevant here. CINNABAR_MART_COPY is an unused duplicate map.

---

## 5. Fossils before Cinnabar

### 5.1 Old Amber (Vieil Ambre), Pewter Museum 1F

Sources: `data/maps/objects/Museum1F.asm`, `scripts/Museum1F.asm`, `text/Museum1F.asm`.

**The back room.**
- Museum 1F has the front entrance (10-11,7) and a **back entrance (16-17,7)**, both leading to Pewter City.
- Scientist 2 stands at (15,2) in the back room, next to the amber display object at (16,2). Touching the display: "The AMBER is clear and gold!"

**What he says and does:**
- "Ssh! I think that this chunk of AMBER contains #MON DNA! It would be great if #MON could be resurrected from it! But, my colleagues…"
- He then gives **OLD AMBER** (EVENT_GOT_OLD_AMBER) and hides the display object (TOGGLE_OLD_AMBER).
- Bag full: "You don't have space for this!"
- Afterwards: "Ssh! Get the OLD AMBER checked!"

**The scientist at the back counter** (Scientist1 behind it):
- "You can't sneak in the back way! Oh, whatever! Do you know what AMBER is?"
- YES: "There's a lab somewhere trying to resurrect ancient #MON from AMBER."
- NO: "AMBER is fossilized tree sap."

**Needs Cut:** the back door is reached via a Cut tree in Pewter City. **UNVERIFIED in code**: it is standard walkthrough knowledge, and I did not check the Pewter City block data.

**Naming note for Kanto 2026:** the official Gen 1 FR item name is « Vieil Ambre » (Poképédia). `dossier-12-argenta.md` writes « Ambre Vieille ».

### 5.2 Dome / Helix, Mt. Moon B2F

Sources: `data/maps/objects/MtMoonB2F.asm`, `scripts/MtMoonB2F.asm`.
- DOME FOSSIL at (12,6) and HELIX FOSSIL at (13,6).
- The Super Nerd guarding them (OPP_SUPER_NERD 2, at (12,8)) must be beaten first (EVENT_BEAT_MT_MOON_EXIT_SUPER_NERD).
- When you take one (EVENT_GOT_DOME_FOSSIL or EVENT_GOT_HELIX_FOSSIL), the script `MtMoonB2FSuperNerdTakesOtherFossilScript` has the Super Nerd take the other, which is then hidden. **You only get one.**
- Revival gives Kabuto (Dome) or Omanyte (Helix) at level 30 (§2.3).
- Lab hint: the Meeting Room Super Nerd says he found "this very strange fossil in MT.MOON!"

---

## 6. French names used (Poképédia)

**Places and characters:** Cramois'Île, Manoir Pokémon, Laboratoire Pokémon (de Cramois'Île), Arène de Cramois'Île, Auguste.

**Badge and TMs:** Badge Volcan, CT38 Déflagration, CT35 Métronome, CT14 Blizzard, CT22 Lance-Soleil.

**Items:** Clé Secrète, Vieil Ambre, Fossile Dôme, Nautile (Helix Fossil; Poképédia only gives it through an image link).

**Trainer classes:** Pillard (Burglar), Intello (Super Nerd), Scientifique.

**Pokémon:** Kabuto, Amonita, Ptéra, Otaria, Saquedeneu, Mimitoss, Électrode, Caninos, Arcanin, Galopa, Goupix, Feunard, Smogo, Smogogo, Tadmorv, Grotadmorv, Salamèche, Reptincel, Magnéti, Magnéton, Voltorbe.

## Sources

- pret/pokered (all paths above): https://github.com/pret/pokered
- Poképédia, Manoir Pokémon (Kanto): https://www.pokepedia.fr/Manoir_Pok%C3%A9mon_(Kanto)
- Poképédia, Arène de Cramois'Île: https://www.pokepedia.fr/Ar%C3%A8ne_de_Cramois%27%C3%8Ele
- Poképédia, Laboratoire de Cramois'Île: https://www.pokepedia.fr/Laboratoire_de_Cramois'%C3%8Ele
- Eternia, RB in-game trades (confirms FR nicknames): https://eternia.fr/dossier/pokemon-rouge-bleu-les-echanges-internes-au-jeu
- Bulbapedia returned HTTP 403 and was not used.
