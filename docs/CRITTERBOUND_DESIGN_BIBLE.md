# Critterbound — Design Bible

**Status: North-star vision, ratified 2026-09-03.** This document is the
long-term source of truth for what Critterbound is meant to become. It is
**not** a description of what is built today — see
`FOUNDATION_ROADMAP.md` for current state and the reconciliation between
this vision and the existing codebase, and read its "Conflict With
Existing Scope" section before assuming any of this is already true in
the repo.

If a future instruction conflicts with this document, that conflict
should be raised explicitly before code changes are made, not resolved
silently in either direction.

---

## 1. Game Identity

**Game:** Critterbound
**Genre:** Open-world creature collection / exploration / adventure /
social Roblox game.

**Core fantasy:**

> Explore a huge living world, discover strange Critters, rescue them,
> raise them, evolve them, uncover secrets, build the ultimate habitat,
> trade with other players, and become one of the greatest Critterbound
> explorers.

The game should be fun, highly replayable, social, collectible,
mysterious, adventurous, peaceful at times, exciting at times, extremely
polished, monetizable, and **not pay-to-win** — designed specifically for
Roblox players, easy to understand but deep enough to hold attention for
months or years. The goal is one of the best creature-collection games on
Roblox. It must not feel like a generic simulator.

## 2. Core Design Philosophy

The core loop is not the raise-loop alone — it's the discovery loop that
wraps around everything else:

```
SEE → WONDER → EXPLORE → DISCOVER → REWARD → NEW MYSTERY → EXPLORE AGAIN
```

The world should constantly provoke: *What's over there? What is that?
How do I get that Critter? What does Pip become? Why did that happen? How
rare is that? How did that player get that? I've never seen that before.*

Mystery and discovery are gameplay systems, not flavor text. Do not
reveal everything. The world rewards curiosity.

## 3. Critters

Critters are the most important part of the game. Eventual target:
**300+ Critters** — cute, cool, funny, weird, magical, mysterious,
massive, legendary, mythic, extremely rare. Every Critter should feel
like an actual creature, not a collectible object, which means each one
needs (as the art/audio pipeline allows — see the Design Bible's own
technical-constraint note in the Roadmap): a unique model, unique
animations, unique sounds, a distinct personality, distinct behaviors, a
preferred habitat, favorite foods, growth, size variation, evolution,
environmental interactions, reactions to players, reactions to
weather/time, and reactions to other Critters.

## 4. Critter Size

Size is variable per individual, not fixed per species: Small / Normal /
Large / Very Large / a rare oversized spawn. Feeding is a primary growth
driver, but every species has a sane maximum — normal feeding should
never produce an absurdly oversized Critter. Some species naturally cap
higher than others. A rare spawn size can exceed a Critter's normal
maximum, which is itself part of the collector appeal. Size must be
visually obvious and comparable between two Critters standing together.

## 5. Critter Food

Species prefer specific foods (meat, steak, lamb, rabbit, fruits,
vegetables, other species-specific items). Food affects growth,
happiness/bond, potential development, and potential evolution paths.
Keep this legible — do not make feeding complicated for its own sake.

## 6. Evolution

Most Critters get roughly 2–4 evolution stages. Evolution can depend on
combinations of growth, food, environment, habitat, activities, bond,
weather, time, exploration, discoveries, and player choices. It should
read as *discovery*, not "reach level 10, press button." Some paths are
hidden; some have hints; some secrets are genuinely hard to figure out.
Evolution models must be visually distinct from each other, not recolors.

## 7. Pip

Pip is the face of Critterbound. The player first encounters Pip as an
**abandoned Critter** during the optional tutorial and must **rescue**
Pip — Pip is not simply handed over. Pip teaches the player how the game
works while becoming emotionally important along the way.

Pip is not a normal Critter, and the player should discover this
gradually, not be told upfront. Pip reacts to certain locations, ancient
symbols, secrets, strange events, certain other Critters, and certain
environmental conditions. Pip has its own evolution storyline, and its
eventual evolution can depend on how the player feeds it, where they take
it, its habitat, activities, player choices, environment, and
discoveries. The standing question for the whole playerbase should be:
**what is Pip going to become?**

## 8. World

The world must be **huge** — not merely "large." A player should not be
able to see the whole map from spawn. It should contain mountains,
forests, an oak biome, rivers, streams, waterfalls, caves, islands, open
fields, underwater areas, hidden areas, secret paths, strange locations,
and room for future biomes. Terrain should be stylized, detailed,
fantasy-inspired, semi-realistic, colorful, beautiful, and
Roblox-appropriate. Players should genuinely wonder what's behind that
mountain. The map is discovered through exploration, not handed over on
arrival.

## 9. Habitats

Every player gets a personal habitat that expands over time. Players
build houses, trees, gardens, ponds, waterfalls, bridges, Critter homes,
food areas, decorations, paths, fences, and special structures — but
cannot sculpt the base terrain (mountains/hills stay fixed). Critters
interact with the habitat they're placed in (a Water Critter swims in the
pond, a bird lands in trees, a rabbit eats the vegetables, a flying
Critter circles the flowers). Habitat can influence evolution. Rare
Critters can visually alter the habitat itself (a Fire Critter leaves
embers, a Water Critter brings aquatic effects, a Cosmic Critter brings
stars, an Ancient Critter brings magical vegetation).

Habitats are visitable, with privacy settings (Everyone / Friends /
Nobody / Invite Only), support Habitat Showcases and rankings, and their
decorations are tradeable. Robux-exclusive cosmetic habitat items can
exist.

## 10. Exploration

Players walk, swim, climb, dive, glide, ride, boat, and — eventually —
fly. Flying should be hard to obtain, since it can bypass exploration
entirely. Beginners should never be *artificially* walled out of hard
areas (no invisible level-gates); instead, reaching them without the
right ability/equipment/Critter should just be genuinely harder.

## 11. World Events

World events are a major feature. When a major Critter appears, **every
player on the server** gets an announcement (e.g. *"🚨 WILD CRITTER
ALERT — Something enormous has been spotted near Whispering River."*) —
without always revealing the exact location, so players have to rush to
find it. Event difficulty scales with the Critter: some need 2–3 players,
some 4–6, some 8–12+.

## 12. Team Rescues

Large Critter rescues split work across different players doing different
jobs — distract, track, care for, gather supplies, solve environmental
puzzles, clear obstacles, then rescue. Different Critters should use
different mechanics; never reduce every rescue to "press E."

## 13. Failed Rescues

Rescues can fail. On failure, the Critter can scream, panic, run, or
vanish — failure should feel dramatic, not just reset a progress bar.

## 14. Giant Critter World Events

Giant Critters can physically affect the world in the moment — trees
falling as one runs through a forest, players scattering, the environment
visibly reacting — with the world restoring itself shortly after. The
destruction is temporary, not permanent terrain damage.

## 15. Participation Rewards

Players who meaningfully participate in a successful rescue get rewarded
(a Critter Egg, Gems, Coins, Codex progress, an event achievement, a
special cosmetic). AFK exploitation must be actively prevented.

## 16. Event Rarity

Rarity tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic, **???**.
Rare events get significantly lower odds; the rarest encounters should
become genuine community moments, not routine.

## 17. One-Per-Server Critters

Some extremely rare Critters can exist **only one at a time per server**.
Once rescued, it's gone until a future event brings it back. Extremely
rare opportunities should surface roughly every 12 hours per server, with
probability weighted heavily toward more common outcomes — never
guarantee the rarest encounter.

## 18. Seasonal Events

Seasons run roughly 3 months and can bring new Critters, eggs, cosmetics,
NPCs, story, events, environmental changes, and secrets. Seasonal content
disappears when the season ends; some items become legacy collectibles;
some seasonal Critters/items should **never** return.

## 19. Once-Ever Events

Some events happen once — not once per server, not once per season, not
once per year, but once in Critterbound's entire history. These should
become legendary community history: players years later should be able
to say "I was there."

## 20. Social

Players can form parties, explore together, complete cooperative quests,
trade, gift, visit habitats, join guilds, build guild habitats, use
emotes, take photos, and celebrate events together. Party exploration
gives a 1.5× eligible reward bonus; friend systems can build up to a 2×
eligible reward bonus through progression. Playing together should be
rewarded, not incidental.

## 21. Guilds

Guilds have shared progression, quests, goals, roles, cosmetics, and
achievements, plus a shared habitat/base that should become a major
social space.

## 22. Trading

Everything tradeable runs through one secure trading system: Critters,
eggs, cosmetics, habitat decorations, limited items, Robux-exclusive
Critters, and legacy Critters — even ones no longer obtainable stay
tradeable. The trade UX needs strong confirmation and anti-scam
protection built in from day one, not bolted on later.

## 23. Trading Areas

Two kinds: (1) personal trading stalls attached to a player's habitat,
and (2) a dedicated Trading Plaza — a major social location with player
stalls, trading, rare-item displays, general social space, market
activity, and leaderboards.

## 24. Critter Provenance

Rare Critters can carry real history: name, limited/season tag, original
owner, first-hatched date, trade count. Extremely rare Critters can
record a world-first hatch, first owner, and discovery history — this is
collector-economy infrastructure, not decoration.

## 25. Codex

The Critter Codex is one of the most important menus in the game. Each
entry: 3D model, name, rarity, habitat, favorite foods, personality, size
range, evolution paths, variant information, sounds, lore, behavior,
preferred weather, preferred time, discovery location, bond, and player
records. Undiscovered Critters show as **???** with silhouettes/unknown
fields — never spoil something the player hasn't found yet.

## 26. CritterLink

The player's in-game device (working name **CritterLink**) combines the
Codex, map, lore, quests, weather, events, friends, messages, trading,
exploration info, camera, notifications, and achievements into one
interface. Visual style: magical technology — nature crossed with
futuristic device.

## 27. Map

The map starts mostly undiscovered and is revealed through exploration.
Discovered areas can surface live events (a giant Critter, a storm, a
traveling trader, a rare migration, a special event) on the map itself.
It should feel genuinely useful without spoiling every secret.

## 28. Audio

Every Critter has unique sounds, with individual personality able to
slightly color them. Music shifts with biome, time, weather, season,
events, and rare/legendary encounters — and sometimes drops out entirely,
letting natural ambience carry the moment. Rare audio events can act as
clues. Major discoveries get their own musical stinger; Legendary/Mythic
Critters get unique themes. Overall identity: peaceful nature + adventure
+ epic.

## 29. Art Direction

Player characters: modern Roblox proportions. Critters: a mix of cute,
cool, funny, weird, magical, epic. World: stylized, detailed,
semi-realistic fantasy, bright and colorful, and alive — moving trees and
grass, leaves, flowing water, birds, fish, butterflies, fireflies, moving
clouds, ambient environmental effects. Lighting shifts meaningfully across
day, sunset, night, rain, storms, seasons, and rare events. Critter
animation should be highly expressive.

## 30. Player Progression

Explorer ranks (Gen-Z-flavored, refinable later): Freshie → Critter
Chaser → Trailblazer → Wildbound → Unleashed → Worldwalker → Mythbound →
Legendary → Icon. Progression weighs Critters discovered, Critters
rescued, Codex completion, evolutions, secrets, quests, giant rescues,
events, exploration, rare discoveries, habitat, and lore. Endgame is
competitive, with leaderboards for total Critters, Codex, rare
discoveries, world firsts, eggs, evolutions, collection value, habitat,
exploration, events, and overall Explorer rank.

## 31–35. The Player Journey

- **First 5 minutes:** spawn in a beautiful central town; an optional,
  skippable tutorial introduces Pip, movement, interaction, exploration,
  Critter discovery, rescue, feeding, Codex, inventory, habitat, and
  quests; Pip is rescued; the player meets their first wild Critter.
- **First 30 minutes:** most foundational systems should have been
  touched — rescue Pip, find Critters, find a first egg, start the Codex,
  meet NPCs, complete quests, customize the habitat, experience weather,
  discover another area, learn evolution, experience an event, socialize,
  discover a first secret. Somewhere in this window there should be a
  genuine "oh — what was THAT" moment (ground shakes, trees move, Pip
  reacts, something huge moves through the forest that the player can't
  yet rescue, and the Codex just says ???).
- **First week:** players chase Critters, exploration, evolutions,
  habitat, trading, secrets, events, breeding, and flying — dedicated
  players might reach flying within the week, but it should stay hard.
- **One month:** a strong active player might have 30–60+ Critters,
  multiple rares, several evolutions, a large habitat, several secrets
  solved, breeding progress, trading experience, many events attended,
  and possibly flight. No single progression path should be forced.
- **Endgame:** log in → check events → hunt rares → explore → search for
  secrets → trade → breed → improve habitat → check leaderboards →
  discover something new. True 100% completion — **Critterbound
  Master** — requires every Critter, every evolution, every major
  secret, every biome, the major events, and the important lore.

## 36–41. Monetization

**Philosophy:** strong monetization without pay-to-win. Free players get
a genuinely great experience regardless. Levers: 2× Luck, 2× Coins, 2×
Gems, VIP, exclusive Critters, limited eggs, cosmetics, habitat items,
extra Critter storage, extra habitat space, a Season Pass, limited
bundles, a rotating shop, cosmetic evolution effects, and temporary
boosts.

- **VIP** is a one-time purchase: VIP status, 3 exclusive Critters, a
  6-hour 2× Coins window, a 6-hour 2× Gems window, exclusive cosmetics,
  and room for future perks. VIP Critters stay tradeable.
- **Luck** (2×) is deliberately valuable, with temporary durations from
  ~30 minutes to ~12 hours. It shifts odds on eligible random systems and
  must never guarantee a rare Critter outright.
- **Limited content:** some Robux-exclusive Critters exist; all Critters
  are tradeable regardless of origin; some limited items disappear
  forever — this is what makes the collector economy real.
- **Season Pass** progresses through exploring, discovering, quests,
  rescues, event participation, and activities — never combat. Rewards:
  cosmetics, habitat decorations, eggs, boosts, Gems, Coins, limited
  items, seasonal rewards.
- **Rotating shop** cycles limited items on windows from 30 minutes to 24
  hours. Desirability should come from being cool/rare, not from
  manufactured pressure.

## 42. Live Service

Target cadence: a major update every 2 weeks to a month, with smaller
updates (Critters, secrets, NPCs, items, events, balance, bug fixes)
in between. Major updates bring new biomes, major story, new systems, new
Critter families, and seasonal content.

## 43. Mysteries

Some mysteries should stay unsolved for weeks or months, and community
discovery is the point — don't rush to explain everything. Some updates
can just be **???**. Developers can trigger live world changes (a
glowing forest, a strange storm, a Critter migration, an ancient creature
waking up) as part of that mystery.

## 44. OG History

Early players get permanent recognition (OG Explorer, Day One, First
Generation, Founder, Original Explorer). Some titles should become
impossible to obtain later — that scarcity is the point.

## 45. Design Rules

1. Critters come first.
2. The world should feel alive.
3. Exploration should be rewarding.
4. Mystery is a feature.
5. Do not reveal everything.
6. Do not turn everything into a simulator button.
7. No filler content.
8. Avoid pay-to-win.
9. Make monetization desirable, not mandatory.
10. Every major system should connect to another system.
11. The game should feel polished before adding endless features.
12. Mobile, PC, and controller support should be considered from the
    start.
13. Performance matters.
14. Do not create systems that cannot scale.
15. Do not build 300 Critters immediately — build the architecture so
    300+ *can* eventually exist.

## 46. Foundation Development Order

Build in this order, and do not build a later phase before its
dependencies are stable:

1. Technical foundation
2. Player movement and character
3. Basic world/town
4. Critter framework
5. Pip + rescue tutorial
6. Critter following
7. Critter inventory/Codex
8. Food/growth/bond
9. Basic evolution framework
10. Habitat
11. Quests/NPCs
12. Exploration/world systems
13. Events/rescues
14. Trading/social
15. Economy
16. Monetization
17. Live-service systems
18. Polish/performance

See `FOUNDATION_ROADMAP.md` for how this order maps onto what already
exists in the repository today.

## 47–49. Technical, Data, and Testing Requirements

Use modular Luau architecture with clear boundaries between client,
server, shared, services, controllers, data, config, UI, and assets. The
server is authoritative for currency, inventory, Critter ownership,
trading, rewards, purchases, evolution, and progression — the client is
never trusted with a valuable state change. RemoteEvents/Functions need
real validation and anti-exploit checks, not happy-path-only handlers.

Player progress must persist: Critters, eggs, Coins, Gems, inventory,
habitat, progression, Codex, discoveries, quests, settings, achievements,
and Pip's own progression. Save/load must be robust against failed
saves, duplicate saves, data loss, server shutdown, a player leaving
mid-transaction, and a trade interrupted mid-flight — a trade or purchase
must never be able to corrupt player data.

Testing needs to cover a new player, a returning player, a player
leaving, a player reconnecting, multiple concurrent players, exploit
attempts, failed transactions, a full inventory, trading, events,
rescues, evolution, habitat, mobile UI, controller UI, and performance —
not just "it compiles."

## 50. Visual Quality

Placeholder-looking UI is not a permanent state. Final direction: modern
Roblox, Pokémon-inspired creature discovery, Pet Simulator–level
readability, fantasy nature, clean modern UI, magical technology — with
Critterbound's own distinct identity, never copying copyrighted
characters, assets, logos, or designs.

## 51–53. Workflow

Before major code changes: inspect the repository, then create/verify
this Design Bible, then `FOUNDATION_ROADMAP.md`, then
`TECHNICAL_ARCHITECTURE.md`, and only then begin implementation — in that
order. Do not attempt to build the entire game at once, and do not build
future-phase systems prematurely if the current foundation isn't stable.
The first playable vertical slice under this vision should prove:

```
PLAYER → TOWN → PIP → RESCUE → CRITTER FOLLOWS PLAYER → FIND WILD CRITTER
  → CODEX → FEED CRITTER → GROWTH → BASIC EVOLUTION → HABITAT → QUEST
  → SMALL WORLD EVENT → SAVE/LOAD
```

If that loop is fun, stable, and polished, expand outward from it.

---

**Final rule, restated:** every feature must answer *does this make
Critterbound more fun, more mysterious, more social, more collectible,
more replayable, or more polished?* If not, reconsider it. Build
Critterbound like a real Roblox game, not a prototype.
