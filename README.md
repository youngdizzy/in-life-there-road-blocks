# Critterbound

A Roblox creature-raising game. Feed and play with Pip, influence what it
becomes, and find out.

**Start here:** [`GAME_DESIGN.md`](./GAME_DESIGN.md) is the design bible —
core loop, architecture, save schema, and what's deliberately not built yet.

## Project structure

This is a [Rojo](https://rojo.space/) project: every gameplay system is
real Luau source in this repo, synced into Roblox Studio rather than kept
in a binary `.rbxl`. The world itself (habitats, Pip's model, zone props)
is built procedurally by server code at runtime — there are no
Studio-authored assets to keep in sync.

```
src/
  ReplicatedStorage/
    Config/        -- pure data: CritterDefinitions, FoodConfig,
                       EnvironmentConfig, GrowthConfig, HabitatConfig,
                       MonetizationConfig, CosmeticConfig,
                       MutationItemConfig / EventConfig / HabitatThemeConfig
                       (the last three are Phase 5-7 schema stubs, unused)
    Modules/        -- Remotes.lua (RemoteEvent/RemoteFunction accessor)
  ServerScriptService/
    Server/
      DataManager.lua          -- DataStore persistence
      HabitatBuilder.lua       -- procedurally builds the world
      HabitatManager.lua       -- assigns/releases habitats; VIP visual
      CritterService.lua       -- starter Pip grant + procedural model
      CritterSlotService.lua   -- validated Critter-slot gate
      CosmeticService.lua      -- attaches cosmetic effects to a model
      InfluenceService.lua     -- Feed / Play-at-Zone / Auto-Care
      GrowthService.lua        -- growth meter, stage, discovery hint,
                                   growth multiplier
      EvolutionService.lua     -- evolution outcome + transformation
      LuckService.lua          -- centralized luck multiplier
      BoostService.lua         -- timed Growth/Luck boost tracking
      DiscoveryService.lua     -- luck-gated Rare Discovery roll
      MonetizationService.lua  -- gamepass ownership + dev product receipts
      MutationLabService.lua   -- gated qualitative Influence analysis
      StateService.lua         -- builds the client's read-only state view
      Init.server.lua          -- bootstraps everything, player lifecycle
  StarterPlayer/StarterPlayerScripts/Client/
    PipStatusUI.lua     -- name/stage/hunger/happiness/hint/gems/boosts panel
    InteractionUI.lua   -- Feed button + food menu
    ShopUI.lua           -- Gamepasses/Boosts/Cosmetics/Currency shop
    MutationLabUI.lua    -- gated Influence analysis panel
    EvolutionReveal.lua -- the evolution reveal popup
    Notifications.lua   -- toast messages
    Init.client.lua      -- wires up the above
```

## Setup

1. Install [Aftman](https://github.com/LPGhatguy/aftman) (manages Rojo's
   version for this project) if you don't have it, then from the repo
   root:

   ```
   aftman install
   ```

   This reads `aftman.toml` and installs the pinned Rojo version.

2. Install the **Rojo** plugin in Roblox Studio (Studio → Toolbox/Plugins
   → search "Rojo", or grab it from the
   [Creator Store](https://create.roblox.com/store/asset/13916111004/Rojo)).

3. Create (or open) an empty Roblox place in Studio.

4. From the repo root, start the Rojo server:

   ```
   rojo serve
   ```

5. In Studio, open the Rojo plugin panel and click **Connect**. Your
   place should immediately fill in with the baseplate, habitat grid, and
   all scripts.

6. Press **Play** (F5) in Studio to test.

## Testing the current build

- Joining should drop you into your own habitat with Pip standing on its
  pedestal.
- Click **Feed Pip** (bottom-right) and pick a food — Pip's Hunger bar
  should jump and, after a few varied feedings, the mystery hint in the
  status panel should start suggesting a direction.
- Walk to any of the four glowing Environment Zone pads around your
  habitat and hold the **Play** prompt.
- Keep feeding/playing until the Growth meter fills — Pip will evolve,
  play a reveal, and its model/name will permanently change.
- Leave and rejoin: your habitat assignment, Pip's stage, influences, and
  (if it happened) evolution should all still be there.

## Monetization setup

Every Gamepass and Developer Product Id in `MonetizationConfig.lua` is a
placeholder (`0`). To test real purchase flows:

1. In the Creator Dashboard for this experience, create a Gamepass or
   Developer Product matching each entry (see `MonetizationConfig.lua` for
   names/descriptions).
2. Paste the real numeric Id into that entry's `Id` field. Nothing else
   needs to change — every service reads Ids from this one file.
3. Until real Ids are set, `ShopUI` buttons for that item still render (so
   you can see the shop's layout) but pressing them shows a "not set up
   yet" notice instead of opening a purchase prompt.

Testing without spending real Robux: use Studio's `MarketplaceService`
test mode, or temporarily grant `profile.OwnedGamepasses[key] = true` /
call `BoostService.Grant` from the command bar to exercise the gated
behavior directly.

## Current scope

See `GAME_DESIGN.md` → "MVP Scope", "Monetization Phase Status", and
"Explicitly Not Built Yet". In short: the free loop proves
DISCOVER → RAISE → INFLUENCE → GROW → first EVOLVE, and Monetization
Phases 1-4 (Luck/Growth boosts, Extra Slots, VIP Habitat, Cosmetics,
Auto-Care, Mutation Lab, gem packs, timed boosts) are layered on top of it
without changing that loop. Trading, live events, mutation items, evolution
reroll, and premium habitat themes are schema-only stubs or not built yet.
