# Critterbound — Game Design Bible

This document is the source of truth for Critterbound. Any gameplay decision
that isn't written here yet should be added here before (or as) it's built.
If code and this document disagree, this document wins until it's updated.

## Game Identity

**Title:** Critterbound

**Core fantasy:**

> You don't just collect creatures. You create what they become.

**Creative identity:** cute + chaotic + collectible + occasionally
unbelievably cool.

The player should be able to say, in the same play session:

- "Look at my cute little guy."
- "Wait… YOURS turned into THAT?"

Both statements have to be true. Pip has to be lovable as a baby *and* the
payoff for raising it well has to be genuinely surprising and flex-worthy.

## Core Loop

```
DISCOVER → RAISE → INFLUENCE → EVOLVE/MUTATE → COLLECT → SHOW OFF / TRADE → DISCOVER MORE
```

**The first playable version (this repo, right now) only proves:**

```
DISCOVER → RAISE → INFLUENCE → GROW (→ first EVOLVE)
```

COLLECT, SHOW OFF, TRADE, and live events are real future pillars (see
"Future Roster" and "Explicitly Not Built Yet" below) but are not being
built until raising a single Critter is proven fun. Building them early
would be fake complexity — see Development Principle #10.

The single most important question governing every decision in this
codebase: **is raising a Critter actually fun?** If a feature doesn't serve
discovery, progression, collection, social expression, or that fun-check
directly, it doesn't belong yet.

## The First Critter: Pip

**Visual identity:** small, round, huge expressive eyes, tiny feet, a
silhouette a kid could recognize instantly and doodle from memory. The v1
model is a simple procedural placeholder (see "Placeholder Art Policy"
below) but the *shape language* — round body, big eyes, small limbs — is
permanent and should carry into every future evolution of Pip.

**Personality:** curious, hungry, slightly silly, lovable. Pip should read
as a character being raised, not an item that dropped out of a box. There
is no gacha, no egg-hatching RNG reveal in this game — the player owns
exactly one Pip from the moment they join, and everything that happens to
it after that is a consequence of what the player did.

**How Pip develops:** every meaningful player action nudges four hidden
Influence values — Fire, Water, Nature, Shadow — plus a visible Growth
meter. When Growth reaches maturity, Pip evolves into whichever Influence
is dominant (or into the Secret outcome, if the rare unlock condition was
met). Concretely, in v1:

| Action | Effect |
|---|---|
| Feed a food item | + that food's Influence deltas, + Hunger restored, + small Growth |
| Play at an Environment Zone | + that zone's Influence, + Happiness, + small Growth |

Both are real, server-validated actions with cooldowns — not idle-clicker
busywork. See `InfluenceService` and `GrowthService`.

**Example influence paths** (illustrative, not exhaustive — the point is
that choices matter, not that these are the only four numbers that will
ever exist):

- Heat, spicy food, high energy play → fire-oriented evolution (**Blazebit**)
- Water exposure, aquatic zone time → water-oriented evolution (**Ripple**)
- Plant interaction, nature exposure → nature-oriented evolution (**Mossy**)
- Dark environment, mysterious items → shadow-oriented evolution (**Nox**)
- Rare/unusual combinations → **Secret** outcome

## Future Critter Roster

This is the target roster. **Only Pip (and its evolution targets Blazebit /
Mossy / Nox / Ripple, needed to prove the loop) are fully implemented in
v1.** Everything else is a data stub in `CritterDefinitions.lua` — an entry
that exists so the architecture visibly supports adding it, with
`Implemented = false` and no gameplay hooked up yet.

1. **Pip** — starter Critter (fully implemented)
2. **Blazebit** — fire Critter, one of Pip's evolutions (fully implemented)
3. **Mossy** — nature Critter, one of Pip's evolutions (fully implemented)
4. **Nox** — shadow Critter, one of Pip's evolutions (fully implemented)
5. **Ripple** — water Critter, one of Pip's evolutions (fully implemented)
6. **Pebble** — earth Critter (stub)
7. **Zappy** — electric Critter (stub)
8. **Glimmer** — light Critter (stub)
9. **Munch** — food-themed funny Critter (stub)
10. **???** — secret Critter, one of Pip's evolutions, discovered through
    unusual experimentation (fully implemented — the Secret *outcome* is
    part of proving the evolution loop, even though the future roster has
    room for more secrets later)

Adding Pebble/Zappy/Glimmer/Munch later should mean: add a table entry to
`CritterDefinitions.lua`, add matching food/zone influence hooks if new
Influence types are needed, and add a spawn shape to `CritterService`'s
model builder. It should never require touching `InfluenceService`,
`GrowthService`, `EvolutionService`, or `DataManager`.

## Architecture

**Roblox / Rojo project.** Everything lives in this repo as real Luau
source, synced into Studio with the Rojo plugin (see README.md). There is
no binary `.rbxl` to keep in sync — the world (habitats, zones, Pip's
model) is built procedurally by server scripts at runtime.

**Separation of concerns:**

- `ReplicatedStorage/Config/*` — pure data. Critter definitions, food
  items, environment zones, growth thresholds, habitat layout. No
  gameplay logic. Safe for both server and client to read.
- `ReplicatedStorage/Modules/Remotes.lua` — thin accessor for the
  RemoteEvents defined in `default.project.json`.
- `ServerScriptService/Server/*` — all gameplay logic and all
  authority. See "Server Authority" below.
- `StarterPlayer/StarterPlayerScripts/Client/*` — UI and presentation
  only. The client never decides an outcome; it asks the server and
  displays what comes back.

**Data-driven, not hard-coded.** A new Critter, food, zone, or evolution
path is a new table entry, not a new `if` branch scattered through
unrelated scripts. `CritterDefinitions.lua`, `FoodConfig.lua`, and
`EnvironmentConfig.lua` are the extension points.

### Server Authority

The client is never trusted with currency, inventory, Critter ownership,
evolution outcomes, or progression values. Concretely:

- The `FeedCritter` remote carries only *which food* the player chose;
  Play-at-a-Zone isn't a remote at all — it's a habitat ProximityPrompt the
  server triggers directly, so the engine itself guarantees the triggering
  player was physically there. Either way the server looks up the effect
  from config, checks cooldowns server-side, and mutates the profile
  itself. The client cannot say "give me +50 Fire."
- Evolution is decided and executed entirely in `EvolutionService` on the
  server. The client only receives the *result* (`EvolutionReveal`) to
  animate.
- All persistent state lives in `DataManager`'s profile table, saved via
  `DataStoreService`. The client's copy (pushed via `StateUpdate`) is a
  read-only projection for UI.

### Save Data

Per-player profile (see `DataManager.DefaultProfile`):

```lua
{
    SchemaVersion,
    Critters = { [uid] = {
        DefinitionId, Name, GrowthPoints, Stage,
        Influences = { Fire, Water, Nature, Shadow },
        Hunger, Happiness,
        EvolvedInto, -- nil until evolution happens
        EquippedCosmetic, -- cosmeticId or nil; per-Critter, not account-wide
        EvolutionHistory, -- snapshots captured right before each evolution
    } },
    ActiveCritterUid, -- the one Critter the player is raising in v1
    Inventory = { [foodId] = count },
    HabitatIndex,
    NextCritterUid,

    Gems,
    Discoveries, -- count of Rare Discoveries found (see DiscoveryService)
    OwnedGamepasses = { [gamepassKey] = true },
    UnlockedCosmetics = { [cosmeticId] = true }, -- account-wide unlocks
    ActiveBoosts = { [boostType] = { ExpiresAt } }, -- see BoostService
    ProcessedReceipts, -- idempotency ring buffer, see MonetizationService
}
```

Designed to expand: multiple simultaneous Critters later just means
iterating `Critters` instead of assuming one; `Inventory` already supports
arbitrary future item types; nothing here assumes a single evolution or a
single habitat forever. `SchemaVersion` exists so a future field that needs
a real migration (not just an additive default) has something to branch on
— every change so far has been additive.

**Reliability requirements:** loads retry on transient DataStore failure
and fall back to defaults rather than blocking join; saves happen on
leave, on `BindToClose`, and on a periodic autosave timer; missing fields
in old saves are backfilled from defaults so a schema change never crashes
a load (see `fillDefaults` in `DataManager`).

## Placeholder Art Policy

There is no Studio-authored mesh/asset pipeline synced into this repo yet.
Every Critter and habitat prop is a small procedural model (colored Parts,
a BillboardGui label) built by `CritterService` / `HabitatBuilder` at
runtime, so the whole game stays expressible as code. Swapping in real
modeled/animated assets later is a matter of replacing the model-builder
functions — the data (which Critter, which stage, which evolution) doesn't
change.

## The World Map

The overworld is a hub with themed destinations branching off it, built
procedurally by two modules: `WorldBuilder` (everything shared) and
`HabitatBuilder` (the player-habitat neighborhood). Every prop is a plain
Roblox Part built at runtime — same rule as "Placeholder Art Policy" above,
zero imported meshes, zero external asset/texture Ids.

- **The Meadow** — the central hub and spawn point. Home to **the Critter
  Tree** (a large stylized landmark with a `ProximityPrompt` that's a real
  hook for future Discoveries/Evolution/Events/lore, not just decoration
  yet), a meeting-ring of benches, and a compass sign listing every
  destination so a new player is never lost.
- **The Critter Archive** — a small museum/lab building next to the Tree.
  Physically points at the Bestiary concept (two "undiscovered silhouette"
  pedestals out front) but doesn't duplicate `DiscoveryLogService`'s data —
  its `ProximityPrompt` just nudges the player toward the real Collection/
  Discovery Log panel.
- **The Critter Plaza** — an open social area (fountain, benches, empty
  display plinths) next to the Tree. Purely a physical space for now; SHOW
  OFF/TRADE are still real future systems, not built here (see "Explicitly
  Not Built Yet").
- **The four public Environment Zones** — Verdant Wilds (**The Giant
  Bloom**), Ember Zone (**The Ember Core**), Tidepool (**The Great Pool**),
  Gloom Grove (**The Whispering Hollow**). These replaced the old
  per-habitat zone pads: same `zoneId`s (`nature_patch`/`fire_corner`/
  `water_pool`/`shadow_nook`), same `EnvironmentConfig` data, same
  `InfluenceService.HandlePlayAtZone` call — moving them into the shared
  world required no changes to the influence/growth/evolution chain at
  all, since that chain was already zone-id-driven, never location-driven.
  Unlike the old habitat copies, these have no owner check: any player can
  play here with their own active Critter.
- **The Evolution Sanctum** — a circular dais with four Influence-colored
  braziers and a central spire. Visually important, deliberately simple
  for the MVP — a landmark, not a new mechanic.
- **Player Habitats** — a neighborhood south of the Meadow
  (`HabitatBuilder`), connected by a walking path. Each plot keeps its
  pedestal, perimeter fence, and owner sign; the four Environment Zones
  moved out to the shared world above, so a habitat's job is now just "a
  home and a display for your Critter."

A new player spawns in the Meadow (a real `SpawnLocation`, not a scripted
teleport) and walks everywhere themselves — including to their own
habitat — which is the intended first-session flow (see "Map Flow" in the
delivery report for this phase).

Adding a future zone (Electric Stormlands, Cloud Kingdom, Crystal
Caverns, etc.) means one new entry in `WorldConfig.Zones` plus one new
landmark-builder function registered in `WorldBuilder`'s
`ZONE_LANDMARK_BUILDERS` table — the hub-and-spoke path math, the ground
patch, and the `ProximityPrompt` wiring are all generic and don't change.

## MVP Scope (v1 — what this repo currently implements)

- Player joins, is granted a starter Pip if they don't have one yet.
- Player is assigned a personal habitat plot with Pip's pedestal, and can
  walk to any of the four shared public Environment Zones to influence it
  (Fire / Water / Nature / Shadow — see "The World Map").
- Player can **feed** Pip from a small, purposeful food menu.
- Player can **play** with Pip at any Environment Zone.
- Both actions move hidden Influence values and a visible Growth meter,
  and are server-validated with cooldowns.
- UI shows Pip's name, growth stage, Hunger/Happiness, and a soft
  "mystery hint" about what Pip seems to be leaning toward once one
  Influence is clearly ahead — never exact numbers, never a spoiler.
- At the Growth threshold, Pip evolves into Blazebit / Mossy / Nox /
  Ripple / the Secret outcome based on accumulated Influence, with a
  rewarding reveal moment (client popup **and** a world-visible light
  flash + particle burst colored to the new form), and its habitat model
  updates permanently.
- The first time Pip reaches "Ready to Evolve," the player is granted a
  second Critter (Mossy — a first, deliberately small taste of COLLECT)
  and can switch which Critter is active from the Collection panel.
- A small Bestiary (`DiscoveryLogService`) records which of the 6 real
  Critters the player has ever discovered — undiscovered ones show as
  "???" instead of their name.
- A small, always-visible Goals checklist tells a new player what to do
  next (feed, play, reach Juvenile, unlock the second Critter, discover an
  evolution, find a Mutation Item) without a quest system behind it.
- All of the above persists through DataStore save/load, including quick
  leave/rejoin.

## Making Pip Feel Alive

A model standing still with a progress bar over its head is not "raising a
creature" — see the Phase 1 audit that drove this section. Concretely, Pip
(and every Critter) now has:

- **Idle animation.** A continuous, gentle bob (`CritterService`'s
  idle Tween) so it never reads as a frozen prop, even doing nothing.
- **Distinct reactions per action** (`CritterService.PlayReaction`): Feed
  triggers a warm color pulse + a small particle burst; Play triggers a
  cooler pulse, a bigger particle burst, *and* a one-shot hop (paused/
  resumed around the idle bob, not fighting it); using a Mutation Item
  gets its own purple-tinted pulse. Different actions visibly feel
  different, on purpose.
- **A Mood**, computed server-side from real Hunger/Happiness/Growth
  state (`MoodService`) and shown prominently in the status panel:
  Hungry, Tired, Growing (close to evolving), Excited, Happy, or Curious.
  Not a new hidden simulator — just a few clear buckets over numbers that
  already exist, so "how is Pip doing?" has an answer at a glance.
- **A personal habitat with an edge.** A low perimeter fence marks the
  platform as the player's own space (`HabitatBuilder.buildPerimeterFence`)
  — small, not a decorating system.

Which food/zone affects which Influence is also no longer something the
player has to infer from flavor text alone: the Feed menu tags each food
with its Influence (🔥/💧/🌿), and zone billboards carry the same icon.
Mystery Mushroom is the one deliberate exception — it's tagged "❓"
instead, matching its own secretive flavor. The exact eventual *outcome*
stays a mystery; *what nudges what* does not (see GAME_DESIGN.md's own
"Mystery should come from the exact form, not from having no idea what
anything does").

## Monetization Philosophy

> Players should spend because something is cool, convenient, collectible,
> exclusive, or status-enhancing — not because the free game is
> intentionally miserable.

Concretely, that means:

- **Every Gamepass/Developer Product Id lives in one file**
  (`MonetizationConfig.lua`), as a placeholder until real ones are created
  in the Creator Dashboard. Nothing else in the codebase hardcodes an Id.
- **Luck and Growth Speed bonuses stack additively over a base of 1.0**
  (see `LuckService`/`GrowthService`), never multiplicatively — a
  permanent gamepass plus a temporary potion is a strong 3x, never a
  runaway number. See `MonetizationConfig.Luck`/`.Growth`.
- **Luck never guarantees a rare outcome.** It's applied to a capped
  chance (`LuckService.ApplyToChance`, capped by
  `MonetizationConfig.Discovery.MaxChance`), never to "skip the roll."
- **Auto-Care and Growth Boost never remove the player's decisions.**
  Auto-Care tops up Hunger/Happiness only — it never grants Growth Points,
  so evolution always requires the player to actually choose foods/zones.
  Growth Boost multiplies the Growth Points those *real* actions are
  worth; it doesn't grant points on its own.
- **The Mutation Lab gives more information, never the answer.** It shows
  qualitative Influence strength ("strong", "faint", ...), never raw
  numbers, and never names the eventual evolution outcome.
- **Every purchase is server-validated.** Gamepass ownership is checked
  with `MarketplaceService:UserOwnsGamePassAsync` and cached in
  `profile.OwnedGamepasses`, never trusted from the client. Developer
  product grants go through `ProcessReceipt` with an idempotency ring
  buffer (`DataManager.ProcessedReceipts`) so a Roblox retry can never
  grant something twice.
- **A free player can still discover, raise, evolve, and progress.** See
  "MVP Scope" — none of it requires spending.

## Monetization Phase Status

Built in the order the monetization spec asked for, so each phase lands on
a working foundation rather than everything half-built at once. See
`README.md` → "System status" for the full FUNCTIONAL/PARTIALLY
FUNCTIONAL/SCHEMA ONLY/PLACEHOLDER breakdown of every individual system;
this table is the phase-level summary.

| Phase | Contents | Status |
|---|---|---|
| 1 | `MonetizationConfig`, gamepass ownership checking, 2x Luck, Growth Boost, `DiscoveryService` (first real luck-gated hook) | ✅ Functional |
| 2 | Extra Critter Slots (`CritterSlotService`), second-Critter acquisition (`MilestoneService`), Critter Collection (`CollectionService`), VIP Habitat visual, Cosmetic effect system (`CosmeticService`, 2 real effects + 4 stubs) | ✅ Functional |
| 3 | Auto-Care (`InfluenceService.StartAutoCareLoop`), Mutation Lab (`MutationLabService`) | ✅ Functional |
| 4 | `ProcessReceipt`, gem packs, temporary Growth/Luck boosts (`BoostService`) | ✅ Functional |
| 5 | Mystery Mutation Items (`InventoryService`, `MutationItemService`) | ✅ Functional — acquired via Rare Discoveries, consumed on a Critter, nudge real Influence |
| 5b | Evolution reroll/second-chance | 🚧 Still just the snapshot hook (`EvolutionService.EvolutionHistory`); now also feeds the Mutation Lab's "previously seen" hint, but nothing consumes it for an actual reroll |
| 6 | Limited-time event framework | ✅ Functional for one real event ("First Eclipse" / `eclipse`, manually toggled `Active = true`, real Shadow Influence bonus + claimable reward); the other three (`meteor`/`garden_festival`/`chaos_weekend`) remain schema-only stubs |
| 7 | Habitat monetization (theme selection) | ✅ Functional for two real themes (`default`, `vip` — ownership-gated, selectable, persists); the six premium re-skin themes remain schema-only stubs with no render path |

**Extra Critter Slots is now partially meaningful**: the base slot count is
2 (room for Pip + the milestone-granted second Critter), and the gamepass's
extra 3 slots are a real, enforced increase — but v1 still has no way to
*fill* those extra slots (Rare Discoveries grant Mutation Items, not
Critters). The gate (`CritterSlotService.AddCritter`) is the single
sanctioned path any future acquisition system (a real egg/gacha system, more
milestones, event Critters) would use, so extending this further doesn't
require touching the gate itself.

## Explicitly Not Built Yet

Per Development Principle #12 and the phased build plan, the following are
real future pillars but are **out of scope until the above loop is proven
fun**:

- Trading between players
- Multiple concurrent/scheduled live events (one real event runs; see Phase 6 above)
- Multiple currencies
- A large open world
- Combat
- A large Critter catalog (beyond the 5 fully-implemented + 4 stubs above)
- Battle passes
- A large quest system
- Complex crafting
- A large inventory/item system beyond the 5 Mutation Items (the inventory
  itself is generic and real -- see `InventoryService` -- there's just not
  a large catalog of item *types* built on top of it yet)
- Evolution reroll/second-chance (the snapshot data exists; nothing
  consumes it yet — see Phase 5b above)
- A scripted first-session tutorial/onboarding sequence (see "Core Loop Fun
  Audit" below — deliberately deprioritized this round)

## Core Loop Fun Audit

Before adding anything, the standing question was re-asked: **if every
Robux purchase were removed, is raising a Critter still fun?** The honest
gaps found — and what was done about each:

| Gap found | Fix |
|---|---|
| Pip was a static model with a floating progress bar — no idle motion, no reaction to being fed/played with, no readable "how is it doing" | Idle bob, distinct Feed/Play/Item reactions, and a server-computed Mood (see "Making Pip Feel Alive" above) |
| Which food/zone affects which Influence was only inferable from flavor text | Explicit Influence tags in the Feed menu and on zone billboards |
| Evolution was a UI popup with nothing happening in the world | A world-visible light flash + particle burst, colored to the outcome, fires at the moment of transformation |
| No sense of "discovered vs. still a mystery" across Critters as a whole | A 6-entry Bestiary (`DiscoveryLogService`) — undiscovered species show as "???" |
| A new player had no persistent answer to "what should I do next" | A small, always-visible Goals checklist (`GoalService`), derived from existing state, no new progression system |
| The habitat didn't visually read as "mine" | A low perimeter fence per habitat |

**Deliberately not built this round**, and why:

- **A scripted first-10-minutes tutorial.** A popup-driven onboarding
  sequence is exactly the kind of "system that isn't connected to
  gameplay" Development Principle #10 warns about. The fixes above (an
  alive, reactive Pip; visible Influence tags; an always-on Goals list)
  are meant to make the first session legible *without* a scripted
  walkthrough — see "Biggest remaining gameplay problem" in the delivery
  report for whether that actually held up once tested in Studio.

## Development Principles

1. Prioritize a fun playable loop over feature count.
2. Build modular systems.
3. Keep data separate from logic.
4. Make future Critters easy to add.
5. Keep the server authoritative.
6. Make saving reliable.
7. Avoid unnecessary complexity.
8. Use clear naming.
9. Comment important architectural decisions (the *why*, not the *what*).
10. Do not create fake complexity just to make the project look bigger.
11. If a feature does not support discovery, progression, collection,
    social interaction, or player expression, question whether it belongs.
12. Do not add monetization until the core loop is fun.
