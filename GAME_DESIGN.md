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

- `FeedCritter` and `PlayAtZone` remotes carry only *which food/zone* the
  player chose — the server looks up the effect from config, checks
  cooldowns and inventory server-side, and mutates the profile itself.
  The client cannot say "give me +50 Fire."
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
    Critters = { [uid] = {
        DefinitionId, Name, GrowthPoints, Stage,
        Influences = { Fire, Water, Nature, Shadow },
        Hunger, Happiness,
        EvolvedInto, -- nil until evolution happens
    } },
    ActiveCritterUid, -- the one Critter the player is raising in v1
    Inventory = { [foodId] = count },
    HabitatIndex,
    NextCritterUid,
}
```

Designed to expand: multiple simultaneous Critters later just means
iterating `Critters` instead of assuming one; `Inventory` already supports
arbitrary future item types; nothing here assumes a single evolution or a
single habitat forever.

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

## MVP Scope (v1 — what this repo currently implements)

- Player joins, is granted a starter Pip if they don't have one yet.
- Player is assigned a personal habitat plot with Pip's pedestal and four
  Environment Zones (Fire / Water / Nature / Shadow).
- Player can **feed** Pip from a small, purposeful food menu.
- Player can **play** with Pip at any Environment Zone.
- Both actions move hidden Influence values and a visible Growth meter,
  and are server-validated with cooldowns.
- UI shows Pip's name, growth stage, Hunger/Happiness, and a soft
  "mystery hint" about what Pip seems to be leaning toward once one
  Influence is clearly ahead — never exact numbers, never a spoiler.
- At the Growth threshold, Pip evolves into Blazebit / Mossy / Nox /
  Ripple / the Secret outcome based on accumulated Influence, with a
  rewarding reveal moment, and its habitat model updates permanently.
- All of the above persists through DataStore save/load, including quick
  leave/rejoin.

## Explicitly Not Built Yet

Per Development Principle #12 and the phased build plan, the following are
real future pillars but are **out of scope until the above loop is proven
fun**:

- Trading between players
- Large multiplayer live events
- Multiple currencies
- A large open world
- Combat
- A large Critter catalog (beyond the 5 fully-implemented + 4 stubs above)
- Monetization of any kind (gamepasses, dev products, cosmetics-for-cash)
- Battle passes
- A large quest system
- Complex crafting
- A large inventory/item system beyond the small starter food menu

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
