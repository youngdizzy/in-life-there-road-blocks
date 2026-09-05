# Critterbound — Foundation Roadmap

This document reconciles `CRITTERBOUND_DESIGN_BIBLE.md` (the long-term
vision) against what actually exists in this repository today. Read the
**Conflict With Existing Scope** section first — it's the most important
part of this document.

## 1. Current State — what exists today

The repository is a working, tested Rojo 7 project (verified with a real
`rojo build` and `rojo serve` against the pinned `aftman.toml` version —
see the git history for that verification). It implements one complete,
polished, small vertical slice: raise a starter Critter named Pip,
influence what it becomes, evolve it, and show it off — built and
iterated across 8 prior development rounds (MVP → monetization →
monetization gaps closed → core-loop-fun pass → visual pass → world map
→ Pip model pass → a rendering bug fix).

**Server (`src/ServerScriptService/Server/`, 26 modules, ~4,300 lines):**
`DataManager` (DataStore persistence with defaulting/backfill for schema
changes), `WorldBuilder` + `HabitatBuilder` + `HabitatManager` (the
procedural world and per-player habitat plots), `CritterService`
(procedural Critter models + animation), `CritterSlotService`,
`InfluenceService`, `GrowthService`, `EvolutionService`, `StateService`
(the one authoritative client-state push), `MonetizationService`,
`MutationLabService`, `MutationItemService`, `CosmeticService`,
`CollectionService`, `EventService`, `HabitatThemeService`,
`DiscoveryLogService`, `DiscoveryService`, `GoalService`,
`InventoryService`, `LuckService`, `MilestoneService`, `MoodService`,
`BoostService`, `Init.server.lua` (bootstrap).

**Client (`src/StarterPlayer/StarterPlayerScripts/Client/`, 10 modules):**
status panel, interaction UI, evolution reveal, notifications, shop,
mutation lab, collection, inventory, discovery log, goals.

**Shared (`src/ReplicatedStorage/`):** 13 data-only Config modules
(`CritterDefinitions`, `FoodConfig`, `EnvironmentConfig`, `GrowthConfig`,
`HabitatConfig`, `WorldConfig`, `MonetizationConfig`, `CosmeticConfig`,
`MutationItemConfig`, `EventConfig`, `HabitatThemeConfig`) plus
`Remotes.lua` (a thin RemoteEvent/Function accessor) and `PartUtil.lua`
(a shared procedural-Part constructor).

**What actually works, tested:**
- Server-authoritative feed/play/grow/evolve loop with cooldowns and
  validation.
- Real DataStore save/load, including quick leave/rejoin.
- A shared overworld: a Meadow hub with a landmark Critter Tree, four
  public Environment Zones (Verdant Wilds / Ember Zone / Tidepool / Gloom
  Grove) that drive real Fire/Water/Nature/Shadow influence, a Critter
  Archive, a Critter Plaza, an Evolution Sanctum, and a habitat
  neighborhood — all built procedurally at server start, no binary
  `.rbxl` to keep in sync.
- 6 total Critters (Pip, 4 elemental evolutions, 1 secret evolution),
  each a data-driven procedural model (head/body split, expressive
  mood-driven face, idle/blink/look-around animation, evolution reveal
  VFX) built by one shared `CritterService` builder function reading
  `CritterDefinitions`.
- A second-Critter acquisition path, a real Bestiary/Discovery Log, a
  Goals checklist, a small inventory system with 5 Mutation Items, one
  real toggled world event ("First Eclipse"), and a monetization layer
  (Luck, Growth Boost, VIP Habitat, Extra Slots, Auto-Care, Mutation Lab,
  Cosmetics, Gem packs) with every Gamepass/Product Id left as an
  explicit `0`/placeholder pending real Creator Dashboard Ids.

**What does not exist at all, today:** trading, guilds, seasonal events,
world bosses / giant-Critter rescues, breeding, flying/swimming/climbing/
diving/gliding/riding/boating, NPCs, a quest system (the "Goals
checklist" is not a quest system — see `GAME_DESIGN.md`'s own note on
this), the CritterLink device UI, Critter provenance/history tracking,
leaderboards, a Season Pass, a rotating shop, and any terrain (rivers,
mountains, caves, islands) — the current world is built entirely from
plain Parts, no `Terrain`/voxel geography anywhere.

## 2. Conflict With Existing Scope

**This is the most important section of this document, and it exists
because the Design Bible's own final rule requires it: "if a future
instruction conflicts with this document, point out the conflict before
making the change."**

The current `GAME_DESIGN.md` — the design doc that governed everything
built so far — contains an explicit, reasoned, and repeatedly-reaffirmed
decision to build small and prove the core loop is fun *before* adding
scope. Its "Explicitly Not Built Yet" section names, verbatim, almost
every system the new Design Bible now asks for as foundational:
**trading between players, multiple concurrent/scheduled live events,
multiple currencies, a large open world, a large Critter catalog beyond
the current 5+4, a large quest system, a large inventory/item system, a
shared central hub with themed destinations** (this one has since been
built — see below), and a scripted tutorial. Its own "Core Loop Fun
Audit" section states the reasoning directly: *"a second, public copy of
the same mechanic adds world surface area without adding depth to the
actual raising loop... reasonable next step once the loop is confirmed
fun, not before."*

**The Design Bible you're reading this against is not an extension of
that plan — it's a replacement of it.** It describes a fundamentally
different game: an open-world MMO-adjacent creature collector with 300+
Critters, huge explorable terrain, trading, guilds, world-boss rescue
events, breeding, flight, a live-service cadence, and a Season Pass.
Almost nothing about the *scale* of the existing build transfers directly
— the existing world is a walkable hub the size of a large parking lot,
not a huge, semi-open continent; the existing Critter roster was
deliberately capped at 6 with a stated principle ("do not build a huge
Critter roster before the first Critter experience is polished"); there
is no economy, no other player interaction beyond seeing each other's
habitats, and no terrain system at all.

This is not a reason to refuse the new direction — it's a reason to be
explicit that adopting it means **retiring** Development Principle #12's
"prove it's fun small before scaling up" stance, not layering on top of
it. The architecture underneath (server authority, a real DataManager
with schema-safe defaulting, a data-driven Config pattern, a modular
service-per-concern layout, a documented "never invent fake Ids"
monetization discipline) is sound and worth keeping. The *content and
world scale* is not something that can be incrementally grown from what
exists — it needs a deliberate re-scoping decision, which is why Phase 1
below is a decision-and-planning phase, not a code phase.

## 3. The Critical Technical Constraint

**This session/environment has no ability to author or import 3D
meshes, rigs, skeletal animations, or custom audio assets, and — per an
explicit, hard rule carried through this entire project — no ability to
mint or guess real Roblox asset Ids.** Every visual in the current build
is a plain Roblox Part assembled at runtime (see `GAME_DESIGN.md`'s
"Placeholder Art Policy"); there is no sound in the game at all.

The Design Bible's Critter requirements — *"unique models, unique
animations, unique sounds"* for a 300+ roster, Pokémon-grade Codex
entries, expressive per-species animation — assume access to a real 3D
content pipeline (a modeler/rigger, Roblox Studio's asset import, a sound
library) that does not exist in this environment. No amount of iterating
on procedural-Part code closes that gap; it can only be closed by
someone actually authoring assets in Studio (or a DCC tool) and this
codebase consuming the resulting asset Ids.

**The practical implication for architecture, not scope:** every
Critter/cosmetic/sound-bearing system should be built so a real asset Id
slots in later without a rewrite — an `AssetId`/`AnimationId`/`SoundId`
field on the relevant Config entry that's `nil`/unset today and falls
back to the current procedural builder, exactly like `CritterDefinitions`
already does for `Implemented = false` stub entries. This lets the
*code* scale toward 300+ Critters immediately while the *art* catches up
whenever real production capacity exists.

## 4. What Can Be Reused As-Is

- **Server authority + DataManager.** The save schema, the
  `fillDefaults` backward-compatibility pattern, and the leave/rejoin/
  autosave lifecycle are exactly the right foundation for a much larger
  save schema (Critters plural with provenance, trades, guild
  membership, quest state). No rewrite needed — extend the schema.
- **The `Remotes.lua` accessor + server-validates-everything discipline.**
  Directly reusable for trading, quests, and events; it's already the
  pattern anti-exploit validation should follow.
- **The Config-module-as-data pattern.** `CritterDefinitions`,
  `FoodConfig`, etc. are exactly the shape a 300-entry Critter table
  should take. The pattern scales; only the row count needs to grow, and
  growth should be additive (new entries), never a schema rewrite.
- **The "never invent fake Ids" monetization discipline.** Directly
  carries over to VIP, Luck, Season Pass, and the rotating shop.
- **`CritterService`'s procedural builder, as a fallback/prototype
  layer** for any Critter that doesn't have real Studio-authored assets
  yet — not as the permanent visual solution for 300+ Critters.

## 5. What Must Be Rebuilt or Newly Decided

- **World scale and terrain approach.** The current Part-based world
  (hub + 4 zones + habitat grid, roughly 600×600 studs) does not become
  "huge" by extension — it needs a real decision: Roblox `Terrain`
  (voxel, needs `StreamingEnabled` and real playtesting this environment
  cannot do) vs. a much larger Part-based approach vs. a hybrid. This is
  a Phase-1/Phase-3 decision, not something to default into silently.
- **Pip's onboarding.** Today Pip is granted instantly on join. The new
  vision requires a rescue tutorial (Pip found abandoned, the player
  rescues it) — a real, if small, new system.
- **The Critter roster ceiling.** 6 hand-tuned species is not "the
  architecture for 300+" yet, even though the data pattern scales — it
  needs the `AssetId`-with-procedural-fallback pattern from Section 3
  built in before the roster grows meaningfully past what's hand-tunable
  procedurally.

## 6. What's Missing Entirely (net-new systems)

Trading (+ anti-scam UX + a Trading Plaza), guilds, a real quest/NPC
system, world events with server-wide announcements, team rescues, giant
Critter world-effects, seasonal event infrastructure, breeding,
flight/swim/climb/dive/glide/ride/boat traversal, the CritterLink UI,
Critter provenance tracking, leaderboards, a Season Pass, and a rotating
shop. None of these have any code today — they are all Phase 10+ work
per the Design Bible's own ordering.

## 7. Recommended Phase 1

Per the Design Bible's own build order, Phase 1 is **"technical
foundation."** Much of that already exists and passes verification
(valid Rojo project, server-authoritative architecture, persistence).
What Phase 1 concretely needs, in order:

1. **World scale/terrain approach — RATIFIED 2026-09-03.** Hybrid as the
   end state (real `Terrain` for geography, Parts for landmarks/
   structures — Section 5's Hybrid option), but sequenced to start with a
   Part-based expansion of the existing `WorldBuilder`/`HabitatBuilder`
   pattern first. Reasoning: this environment has no Studio to visually
   verify hand-scripted `Terrain` against, while Part geometry is
   something that can be reasoned about and gotten right precisely, the
   same way the existing world/Critter work was. Real `Terrain` is a
   later pass, once there's a way to actually playtest it.
2. **What happens to the existing small-scope game — RATIFIED
   2026-09-03.** Extend, not supersede. The current Meadow/zones/habitat
   build already *is* this plan's own Phase 3 ("basic world/town"); the
   existing Pip raise/evolve loop already *is* Phases 4–9 (Critter
   framework, food/growth/bond, basic evolution). Both stay and get built
   on top of — the Meadow becomes the starting town a much larger world
   extends outward from; the 6-Critter roster becomes the first 6 real
   entries in a 300-target roster; Pip's instant-grant onboarding still
   needs to become a real rescue tutorial (Section 6's "missing
   entirely" list), but that's additive work, not a rewrite.
3. **The `AssetId`-with-procedural-fallback schema addition — DONE.**
   `CritterDefinitions` now documents `AssetModelId`/`AssetAnimations`/
   `AssetSounds` as the upgrade path (all nil today), and
   `CritterService.buildCritterModel` checks `AssetModelId` first via a
   new `loadAssetModel` helper, falling back to the procedural builder on
   any absence or load failure. Every field stays nil against the
   current roster, so this is dormant, not yet exercised — but the
   architecture claim in Section 5 is now literally true, not just
   documented.
4. **A DataManager schema extension — DONE (schema only).**
   `DataManager.DefaultCritterRecord` gained `Origin`, `ObtainedAt`,
   `FirstOwner`, `TradeCount`, `HatchEventId`; `DataManager.DefaultProfile`
   gained `GuildId`, `GuildRole`, `TradeHistory`, `PendingTrade`. All
   additive with safe defaults (no `SCHEMA_VERSION` bump needed, per its
   own documented policy). `Origin`/`ObtainedAt` are actually populated
   today (`CritterSlotService.AddCritter` now takes an `origin` tag,
   passed as `"starter"`/`"milestone"` from its two existing call sites);
   `FirstOwner`/`TradeCount`/`HatchEventId` stay honestly SCHEMA ONLY
   until trading exists to populate them and a Codex/trade UI exists to
   display them.

With 1–4 settled, Phase 2 (player movement/character — likely mostly
default Roblox; worth a quick explicit confirmation, not a rebuild) and
Phase 3 (the Part-based world *expansion*, per decision 1) are next.

## 8. Dependencies

- Phase 3 (world) depends on the Section 5 terrain decision.
- Phase 5 (Pip rescue tutorial) depends on Phase 3 existing enough to
  place Pip somewhere findable.
- Phase 9 (evolution framework expansion) depends on Phase 4's roster
  architecture (Section 3/5) being in place first, or every new Critter
  re-does the same procedural-vs-real-asset decision individually.
- Phase 14 (trading) and Phase 21 (guilds) both depend on the DataManager
  schema extension (Section 7.4) landing first — trading a Critter that
  doesn't have a stable, provenance-capable data shape yet is exactly the
  kind of "trade corrupts player data" risk `GAME_DESIGN.md`'s own
  persistence rules warn against.
- Phase 16 (monetization expansion — Season Pass, rotating shop) depends
  on real Gamepass/Product Ids existing, same as every monetization
  system already in the repo.

## 9. Testing Requirements Going Forward

Every new system needs the same bar already applied to the existing
monetization work: a FUNCTIONAL / PARTIALLY FUNCTIONAL / SCHEMA ONLY /
PLACEHOLDER label, honest about what's real; a documented manual test
plan (new player, returning player, leave-mid-action, multiple
concurrent players, exploit attempts); and — specifically for
trading/guilds — an explicit test for "player disconnects mid-trade" and
"two players trade simultaneously," since those are exactly the failure
modes `GAME_DESIGN.md`'s persistence rules call out by name.
