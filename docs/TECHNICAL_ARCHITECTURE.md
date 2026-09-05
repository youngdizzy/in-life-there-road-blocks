# Critterbound — Technical Architecture

Companion to `FOUNDATION_ROADMAP.md`. That document says *what* changes
and *why*; this one says *how* — the module boundaries, data patterns,
and system sketches new work should follow so it stays consistent with
what already exists instead of drifting into a second, incompatible
architecture.

## 1. Module Boundaries (established, keep following this)

```
src/
  ReplicatedStorage/
    Config/     -- pure data, no logic, required by both client and server
    Modules/    -- small shared utilities (Remotes accessor, PartUtil, ...)
  ServerScriptService/
    Server/     -- one module per concern ("Service" suffix), Init.server.lua
                   is the only bootstrap entrypoint
  StarterPlayer/
    StarterPlayerScripts/
      Client/   -- one module per UI panel, Init.client.lua is the only
                   bootstrap entrypoint
```

Rules that are already load-bearing and should not be broken:

- **Only `Init.server.lua` and `Init.client.lua` use the `.server.lua` /
  `.client.lua` suffix.** Every other file is plain `.lua` (a
  `ModuleScript`), because Rojo's filename convention decides the
  Roblox class it becomes on sync — see `README.md`'s Rojo verification
  notes for why this matters and how it was confirmed with a real
  `rojo build`.
- **Config modules never require Server/Client modules.** Data flows one
  direction: Config → Service → Remote → Client UI.
- **Circular requires are avoided with a lazy-require helper**
  (`local function getX() return require(script.Parent.X) end` called
  inside a function body, not at module top-level) rather than
  restructuring module boundaries — see `StateService`↔`CollectionService`/
  `EventService`/`HabitatThemeService` for the existing pattern. New
  systems that need this (trading ↔ inventory, guilds ↔ social) should
  use the same idiom, and any new module set should be re-checked for
  cycles the same way the existing DFS-over-`require`-statements script
  in this project's git history does.

## 2. Server Authority (established, extend, don't reinvent)

Every value-bearing action already follows one shape: the client fires a
`RemoteEvent` naming *what* it wants (a food id, a zone id, an item id) —
never an amount, never a computed effect — and a `*Service` module on the
server validates ownership/cooldowns/state before mutating the profile
and calling `StateService.Push` to send the new authoritative state back
down. See `InfluenceService.HandleFeed`/`HandlePlayAtZone` as the
reference implementation.

**New systems must follow this exactly, with no exceptions for
trading:** a trade proposal, accept, or cancel is a remote naming *which*
trade and *which* action; the server is the only thing that ever moves a
Critter or currency between two profiles. There is no "client says I
traded my Critter for yours" message — there is only "client says accept
trade #X," validated server-side against the trade's actual current
contents.

## 3. Data Persistence & Schema Evolution

`DataManager`'s `fillDefaults` pattern (backfilling missing fields from
defaults on load, so an old save never crashes against a newer schema)
is exactly the mechanism a growing save schema needs, and should keep
being the *only* way the schema grows — additive fields with defaults,
never a field whose absence is unhandled.

**Schema growth this vision requires, roughly in the order Section 7 of
the Roadmap implies:**

- `profile.Critters` already exists as a uid-keyed table; it needs
  provenance fields per-Critter (`Origin`, `FirstOwner`, `ObtainedAt`,
  `TradeCount`, `HatchEventId`) added the same additive way
  `EvolutionHistory` was added previously.
- A `profile.Guild` reference (guild id + role), separate from the guild's
  own data (which should NOT live inside a player profile — a guild is
  its own DataStore-backed entity with its own save/load lifecycle,
  referenced by id, not duplicated per member).
- `profile.TradeHistory` / an in-flight `profile.PendingTrade`, guarded so
  a disconnect mid-trade cannot leave either side's inventory
  inconsistent — this needs a two-phase-commit-style pattern (both sides
  lock their offered items, server validates both still hold what they
  offered, then atomically swaps and unlocks) rather than a naive
  "remove from A, add to B" that can partially fail.
- `profile.QuestState` / `profile.Discoveries` at world scale — the
  existing `DiscoveryLogService` pattern (a flat table of discovered ids)
  scales fine to hundreds of entries; it does not need to change shape,
  just grow the id list it's validated against.

## 4. RemoteEvent/Function Conventions

`Remotes.lua` is a thin `WaitForChild`-caching accessor over instances
declared in `default.project.json` — new remotes are added the same way:
one line in `default.project.json`'s `Remotes` folder, one
`Remotes.get("Name")` call site on each side. Keep using
`RemoteFunction` sparingly and only for synchronous reads that must block
the client's UI on a server answer (see `GetMutationAnalysis` as the one
existing example) — everything else is a fire-and-forget `RemoteEvent`
plus a `StateUpdate` push, which is already the pattern
`InfluenceService`/`EvolutionService` use and should stay the pattern for
trading/quest/guild actions too.

Every new server-side remote handler needs the same validation shape the
existing ones already have: re-fetch the profile from `DataManager` (never
trust a client-passed profile snapshot), re-check ownership/cooldown/
state server-side even if the client UI already prevents the invalid
action, and `warn`/no-op rather than error on a malformed payload so one
bad actor can't crash a shared server.

## 5. Scaling the Critter Roster (6 → 300+)

`CritterDefinitions.Critters` is already the right shape: one table
entry per species, with `Implemented = false` stub entries already
proving the pattern (see `pebble`/`zappy`/`glimmer`/`munch`). Growing
this to 300+ needs one architectural addition, not a rewrite:

```lua
-- Proposed addition to each entry, additive/optional:
AssetModelId = nil,      -- Roblox asset id for a real rigged model, when it exists
AssetAnimations = nil,   -- { Idle = id, Walk = id, ... }, when they exist
AssetSounds = nil,       -- { Idle = id, Reaction = id, ... }, when they exist
```

`CritterService.buildCritterModel` should check for `AssetModelId` first
and only fall back to the current procedural builder when it's absent —
exactly mirroring how `Implemented` already gates whether a species is
playable at all. This lets the *data* and *code* scale to 300+ entries
immediately, with each entry independently upgradeable from
procedural-prototype to real-asset the moment art exists for it, with no
migration step for the entries that haven't been upgraded yet.

## 6. World & Terrain

Three real options, not a default to slide into silently (see Roadmap
Section 7.1 — this needs to be a ratified decision):

- **Roblox `Terrain` (voxel).** Real mountains/rivers/caves/islands,
  Roblox-native water, but needs `Workspace.StreamingEnabled` for a map
  this large, real GPU/network performance testing this environment
  cannot do (no Studio, no client to profile against), and a terrain
  *generation* strategy (hand-sculpted in Studio vs. procedural at
  runtime — procedural voxel terrain at this scale is a substantial
  engineering project on its own).
- **Part-based, much larger.** Extends the existing
  `WorldBuilder`/`HabitatBuilder` pattern (everything as code, no binary
  asset to keep in sync with git) to a far larger footprint, with biome
  regions instead of hand-placed landmarks. Cheaper to keep fully
  procedural and git-diffable, but "mountains/caves/waterfalls" read
  noticeably more artificial than real Terrain at large scale.
  A shared streaming/generation strategy is required either way.
- **Hybrid.** Real `Terrain` for the base geography (hills, water,
  ground), Part-based landmarks/structures on top of it — closest to
  what most polished Roblox open-world games actually do, at the cost of
  needing both systems to agree on a coordinate/streaming plan.

Whichever is chosen, `WorldConfig.lua`'s existing role (one file holding
every shared coordinate, read by both the world builder and the habitat
builder) should keep being the single source of truth for
zone/biome/landmark placement, extended rather than replaced.

## 7. Sketch: Trading System

- `TradeService` (new), server-authoritative, holds an in-memory table of
  open trade sessions keyed by a generated trade id (not by either
  player — a trade outlives neither player disconnecting cleanly without
  the other side finding out).
- Remotes: `ProposeTrade`, `UpdateTradeOffer`, `ConfirmTrade`,
  `CancelTrade` — each re-validates the acting player actually owns
  what they're currently offering at the moment of the call, not just
  when the offer was first added (closes the "duplicate/already-traded
  item" exploit class).
- Both sides must explicitly re-confirm after either side's offer
  changes (a changed offer un-confirms both sides) — standard anti-scam
  UX the Design Bible calls for by name.
- The actual transfer is a single atomic profile mutation (both
  inventories change together or neither does), following the same
  "never let a trade corrupt player data" rule `GAME_DESIGN.md`'s
  persistence section already states for the existing single-player
  systems.
- Trade history writes to `profile.TradeHistory` on both sides
  immediately on completion, feeding the Codex provenance fields from
  Section 3.

## 8. Sketch: Guilds

- Guilds are their own DataStore-backed record (own id, own save/load),
  not embedded in a member's profile — a profile only stores a reference
  (`GuildId`, `GuildRole`). This avoids the classic "50 members' profiles
  all embed a stale copy of the guild roster" consistency bug.
- A `GuildService` mirrors the shape of `DataManager` (load-on-demand,
  cache while any member is online, periodic autosave, save-on-empty)
  rather than inventing a new persistence pattern.
- Guild habitat reuses `HabitatBuilder`'s plot-building code, parented
  under a guild-owned area instead of a personal one — same procedural
  approach, different ownership model.

## 9. Sketch: World Events / Rescues

- `WorldEventService` (new) owns a small state machine per active event:
  `Announced → InProgress → (Succeeded | Failed) → Cleared`, broadcast to
  all players via a `WorldEvent` remote (name, rarity, a
  vague-on-purpose location hint) — this generalizes the existing
  `EventConfig`/`EventService` pattern (which already supports one
  concurrent event) to multiple simultaneous, spatially-located events.
- Team-rescue mechanics (distract/track/care/gather/solve/clear) are
  per-encounter mini state machines, not one universal "hold E" — each
  encounter type should be its own small config-driven module the same
  way `EnvironmentConfig`'s zones are each a data row, not four copies of
  bespoke code.
- Participation tracking (for reward eligibility and AFK prevention)
  needs a per-event contribution log server-side, checked at reward time
  — never trust a client "I helped" flag.

## 10. Performance

`GAME_DESIGN.md`'s existing performance notes (avoid unnecessary
thousands of parts, avoid excessive particle emitters/transparent
objects, modular construction so the map can expand without a full
rebuild) carry forward directly and get more important, not less, at
world scale. A huge world specifically needs:

- `Workspace.StreamingEnabled` planning from the start if `Terrain` is
  chosen (Section 6) — this changes how/when server-built content
  becomes visible to a given client and needs to be designed in, not
  retrofitted.
- A real client-side performance budget for Critter count-on-screen
  (procedural Critters are cheaper per-instance than a rigged mesh, but
  neither scales to "hundreds visible at once" without LOD/culling).
- None of this is verifiable in this environment (no Studio, no client to
  profile) — it needs real in-Studio testing on real hardware once built,
  which `FOUNDATION_ROADMAP.md`'s testing section already flags as a gap
  this environment cannot close on its own.
