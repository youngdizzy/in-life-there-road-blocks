# Critterbound

A Roblox creature-raising game. Feed and play with Pip, influence what it
becomes, and find out.

**Start here:** [`GAME_DESIGN.md`](./GAME_DESIGN.md) is the design bible —
core loop, architecture, save schema, monetization philosophy, and what's
deliberately not built yet.

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
                       MutationItemConfig, EventConfig, HabitatThemeConfig
    Modules/        -- Remotes.lua (RemoteEvent/RemoteFunction accessor)
  ServerScriptService/
    Server/
      DataManager.lua          -- DataStore persistence
      HabitatBuilder.lua       -- procedurally builds the world
      HabitatManager.lua       -- assigns/releases habitats; VIP visual render
      CritterService.lua       -- Critter grant + procedural model builder
      CritterSlotService.lua   -- validated Critter-slot gate
      MilestoneService.lua     -- grants the second Critter (see Phase 2)
      CollectionService.lua    -- list/switch which Critter is active
      InventoryService.lua     -- generic item quantities (add/remove/check)
      CosmeticService.lua      -- attaches cosmetic effects to a model
      InfluenceService.lua     -- Feed / Play-at-Zone / Auto-Care
      GrowthService.lua        -- growth meter, stage, discovery hint,
                                   growth multiplier
      EvolutionService.lua     -- evolution outcome + transformation
      MutationItemService.lua  -- validates+consumes an item, nudges Influence
      MutationLabService.lua   -- gated qualitative Influence analysis
      LuckService.lua          -- centralized luck multiplier
      BoostService.lua         -- timed Growth/Luck boost tracking
      DiscoveryService.lua     -- luck-gated Rare Discovery roll (grants items)
      EventService.lua         -- event active-check + reward claim
      HabitatThemeService.lua  -- habitat theme ownership + selection
      MonetizationService.lua  -- gamepass ownership + dev product receipts
      MoodService.lua          -- Hungry/Tired/Growing/Excited/Happy/Curious
      DiscoveryLogService.lua  -- the Bestiary: which species have been seen
      GoalService.lua          -- small always-current "what's next" checklist
      StateService.lua         -- builds the client's read-only state view
      Init.server.lua          -- bootstraps everything, player lifecycle
  StarterPlayer/StarterPlayerScripts/Client/
    PipStatusUI.lua     -- name/stage/hunger/happiness/mood/hint/gems/boosts
    InteractionUI.lua   -- Feed button + food menu (tagged by Influence)
    CollectionUI.lua    -- view/switch owned Critters
    InventoryUI.lua     -- view/use owned Mutation Items
    DiscoveryLogUI.lua   -- the Bestiary panel
    GoalsUI.lua          -- always-visible goals checklist
    ShopUI.lua           -- Gamepasses/Boosts/Cosmetics/Currency/Habitat/Event
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

## System status

Every system, labeled honestly. **FUNCTIONAL** = real server logic, real
client display, fails safely without the entitlement, survives
leave/rejoin — actually play it. **PARTIALLY FUNCTIONAL** = the runtime
path is real but something about it is limited or waiting on external
setup (usually a real Gamepass/Product Id). **SCHEMA ONLY** = data exists,
no runtime reads it. **PLACEHOLDER** = not started.

| System | Status | Notes |
|---|---|---|
| Core loop (Feed/Play/Grow/Evolve) | **FUNCTIONAL** | Unaffected by anything below |
| Pip aliveness (idle bob, reactions, Mood) | **FUNCTIONAL** | `CritterService.PlayReaction`/`MoodService`; no Robux involved |
| Influence legibility (Feed/zone tags) | **FUNCTIONAL** | Feed menu and zone billboards show which Influence each affects |
| Evolution world effect | **FUNCTIONAL** | Light flash + particle burst at the pedestal, colored to the outcome |
| Bestiary (Discovery Log) | **FUNCTIONAL** | `DiscoveryLogService`/`DiscoveryLogUI`; 6 real entries, "???" until discovered |
| Goals checklist | **FUNCTIONAL** | `GoalService`; derived entirely from existing state, no new progression system |
| Second Critter (Mossy) acquisition | **FUNCTIONAL** | Deterministic: granted the moment Pip first reaches "Ready to Evolve" |
| Critter Collection (view/switch active) | **FUNCTIONAL** | `CollectionUI` |
| Extra Critter Slots | **PARTIALLY FUNCTIONAL** | Gate is real and enforced; base is 2 slots so the milestone Critter always fits; the gamepass's *extra* 3 slots have nothing to fill them with yet beyond Rare Discoveries (which grant items, not Critters) |
| Mutation Item inventory | **FUNCTIONAL** | `InventoryService`; acquired via Rare Discoveries (luck-gated), viewed/used in `InventoryUI` |
| Mutation Items affecting Influence | **FUNCTIONAL** | `MutationItemService`; consumes exactly one item, nudges real Influence, counts toward evolution |
| Mutation Lab | **FUNCTIONAL**, gated by a placeholder Gamepass Id | Logic and UI both work; needs a real `MutationLab` Gamepass Id to actually be purchasable in production |
| 2x Luck | **FUNCTIONAL** | Applies to the Rare Discovery roll (the only luck-gated mechanic in v1); gated by a placeholder Gamepass Id |
| Growth Boost (2x) | **FUNCTIONAL**, gated by a placeholder Gamepass Id | Verifiably changes real Growth Point math (see testing plan) |
| Temporary Growth Boost / Luck Potion | **FUNCTIONAL** | `BoostService`; timers are computed from a stored Unix timestamp, so they survive a rejoin correctly (see testing plan) |
| VIP Habitat visual + theme selection | **FUNCTIONAL**, gated by a placeholder Gamepass Id | Selection (not raw ownership) drives the visual; persists across sessions |
| Auto-Care | **FUNCTIONAL**, gated by a placeholder Gamepass Id | Tops up Hunger/Happiness on a timer; never grants Growth |
| Cosmetic effects (Sparkles, Golden Eyes) | **FUNCTIONAL** | Unlocked via the one Dev Product wired to a cosmetic; equip/unequip in `ShopUI` |
| Gem packs | **FUNCTIONAL**, gated by a placeholder Product Id | `ProcessReceipt` grants Gems idempotently |
| First Eclipse event | **FUNCTIONAL** | Manually toggled on (`EventConfig.Events.eclipse.Active`); applies a real Shadow Influence bonus and a one-time claimable reward |
| Event framework (beyond First Eclipse) | **SCHEMA ONLY** | `eclipse` is the one real event; `meteor`/`garden_festival`/`chaos_weekend` are still data-only stubs with `Active = false` |
| Premium habitat themes (beyond default/VIP) | **SCHEMA ONLY** | `neon_city`/`moon_base`/etc. have no render path in `HabitatBuilder` yet |
| Evolution reroll / second chance | **PLACEHOLDER** | `EvolutionHistory` snapshots exist (and now feed the Mutation Lab's "previously seen" hint) but nothing consumes them for a reroll |

## Testing this build (Studio)

Run these in order — each depends on the state the previous one left
behind. All of them work without spending real Robux (see "Monetization
setup" below for how purchases are simulated).

1. **New player joins.** Drops into an empty habitat with Pip on its pedestal.
2. **Player receives Pip.** Confirm via the status panel (top-left): name "Pip", stage "Baby".
3. **Player grows Pip.** Feed/Play repeatedly (respect the 20s cooldowns); Growth meter climbs, hint appears once one Influence pulls ahead.
4. **Player unlocks the second Critter.** Once Growth hits 90 ("Ready to Evolve"), a "🎉 New Critter unlocked" toast fires and `CollectionUI` shows two entries (Pip + Mossy).
5. **Player reaches the normal Critter slot limit.** With base slots at 2 and exactly Pip + Mossy owned, a further grant (there isn't one in v1 beyond this) would be rejected by `CritterSlotService.AddCritter` — verify from the command bar: `CritterSlotService.HasFreeSlot(profile)` should be `false` at this point.
6. **Extra Critter Slots entitlement increases capacity.** Command bar: set `profile.OwnedGamepasses.ExtraCritterSlots = true`, then re-check `CritterSlotService.GetMaxSlots(profile)` — should jump from 2 to 5.
7. **Growth Boost changes actual progression.** Note Pip's exact Growth Points after one Feed. Grant the gamepass (command bar or a real test purchase), feed the same food again, confirm the point gain roughly doubles (`GrowthService.GetGrowthMultiplier` → 2.0).
8. **2x Luck changes eligible luck calculations.** Command bar: compare `LuckService.GetMultiplier(profile)` before/after setting `profile.OwnedGamepasses.Luck2x = true` (1.0 → 2.0); over many Feed/Play actions the Rare Discovery rate should visibly climb.
9. **Temporary Growth Boost works.** Command bar: `BoostService.Grant(profile, "GrowthBoost", 900)`; the status panel should immediately show a "⚡ Growth Boost 14:59" countdown, and Growth Point gains should reflect it.
10. **Player leaves and rejoins while a boost is active.** Leave, rejoin within the boost window — the countdown should resume from roughly where it left off (it's computed from a stored `os.time()` expiry, not a live timer, so this survives a full server restart too, not just a rejoin).
11. **Temporary Luck Boost survives a rejoin correctly.** Same as above with `BoostService.Grant(profile, "LuckPotion", 1800)`.
12. **Mutation item is added to inventory.** Keep Feeding/Playing until a "✨ Rare discovery!" toast names an item; `InventoryUI` should show it.
13. **Mutation item is consumed exactly once.** Use it from `InventoryUI`; its quantity drops by exactly 1 (to 0 and disappears, if you only had one).
14. **Mutation item changes Critter influence.** Check `MutationLabUI` (requires the Mutation Lab gamepass — grant via command bar for testing) before/after using an item; the qualitative Influence level should visibly increase.
15. **Mutation Lab reflects current Critter state.** Confirm the breakdown updates after any Feed/Play/item use, and that it never states an exact number or a future outcome.
16. **Event can activate.** `EventConfig.Events.eclipse.Active` is `true` by default in this repo; open `ShopUI` → Event tab to see "First Eclipse" listed.
17. **Event progress saves.** Claim the First Eclipse reward, rejoin — the tab should show "Claimed" (not the claim button again), and the item/Gems shouldn't be re-granted.
18. **VIP habitat entitlement changes available habitat options.** Without the gamepass, `ShopUI` → Habitat tab shows "VIP Golden" locked with a "Get it" prompt button; grant `profile.OwnedGamepasses.VIPHabitat = true`, and it becomes selectable — selecting it renders the corner-post/badge visual, and the choice persists across a rejoin.
19. **Cosmetic effects apply correctly.** Command bar: `CosmeticService.Unlock(profile, "sparkles")`, then equip it from `ShopUI` → Cosmetics — Pip's model should visibly gain a sparkle trail.
20. **Invalid client requests are rejected by the server.** Try firing `UseMutationItem` for an item you don't own, `SetActiveCritter` with a fake uid, `EquipCosmetic` with a locked cosmetic id, or `SelectHabitatTheme("vip")` without the gamepass (all from a LocalScript / command bar) — every one should no-op or notify a warning, never silently succeed.

## Testing the core-loop feel (Studio)

Quick checks for the Phase 1-9 gameplay-feel work, separate from the
monetization plan above:

- **Idle/reactions.** Just watch Pip for a few seconds — it should bob
  gently even when you're not doing anything. Feed it: expect a warm
  color pulse + small particle burst, no hop. Play at a zone: expect a
  cooler pulse, a bigger burst, and a one-shot hop that doesn't fight the
  idle bob (it pauses, hops, then resumes).
- **Mood.** Check the status panel's stage line — it should show an emoji
  + word (e.g. "🍽️ Hungry") that changes as Hunger/Happiness/Growth
  change. Let Hunger drop below 30 (stop feeding) and confirm it switches
  to Hungry.
- **Influence tags.** Open the Feed menu — each food except Mystery
  Mushroom should show a 🔥/💧/🌿 tag matching its Influence; Mystery
  Mushroom shows "❓". Walk to a zone and check its floating label carries
  the same icon.
- **Evolution world effect.** Evolve a Critter — alongside the reveal
  popup, confirm a bright flash + particle burst plays at the pedestal,
  tinted to the new form's color.
- **Bestiary.** Open the Bestiary panel — Pip should show as discovered
  immediately on join; the rest show "???" until you evolve into them or
  unlock Mossy.
- **Goals.** Check the always-visible Goals panel under the status
  panel — items should tick from ⬜ to ✅ as you feed, play, reach
  Juvenile, unlock Mossy, evolve, and find a Mutation Item, with no
  action needed beyond normal play.
- **Habitat fence.** Confirm each habitat platform has a visible low
  fence around its edge (non-collide — you can still walk through it).

## Monetization setup

Every Gamepass and Developer Product Id in `MonetizationConfig.lua` is a
**placeholder (`0`) on purpose** — this repo does not invent fake Ids, and
every service already fails safely on `Id <= 0` (see `MonetizationService`:
`PromptGamePassPurchase`/`PromptProductPurchase` are never called with an
unset Id; the player gets a "not set up yet" notice instead).

### Where each real Id goes

All of them live in **`src/ReplicatedStorage/Config/MonetizationConfig.lua`**
— nowhere else in the codebase hardcodes an Id.

**Gamepasses** (`MonetizationConfig.Gamepasses`, one `Id` field each):

| Key | Name | What it needs |
|---|---|---|
| `Luck2x` | 2x Luck | A Gamepass |
| `GrowthBoost` | Growth Boost | A Gamepass |
| `VIPHabitat` | VIP Habitat | A Gamepass |
| `ExtraCritterSlots` | Extra Critter Slots | A Gamepass |
| `AutoCare` | Auto-Care | A Gamepass |
| `MutationLab` | Mutation Lab | A Gamepass |

**Developer Products** (`MonetizationConfig.DevProducts`, one `Id` field each):

| Key | Name | What it needs |
|---|---|---|
| `GemsSmall` / `GemsMedium` / `GemsLarge` | Gem packs | A Developer Product each |
| `GrowthBoost15Min` / `GrowthBoost1Hour` | Temporary Growth Boost | A Developer Product each |
| `LuckPotion30Min` | Temporary Luck Boost | A Developer Product |
| `SparkleTrailCosmetic` | Sparkle Trail | A Developer Product |

### Creating the real products

1. Go to the Creator Dashboard for this experience → **Monetization**.
2. Create a **Gamepass** for each row in the Gamepasses table above (name it
   whatever you like in the Dashboard; the in-game display name always
   comes from `MonetizationConfig`, not the Dashboard).
3. Create a **Developer Product** for each row in the Developer Products
   table (set whatever Robux price you want; this repo doesn't prescribe
   pricing).
4. Copy each new numeric Id into the matching `Id = 0` field in
   `MonetizationConfig.lua`. Nothing else needs to change — `ShopUI`,
   `MonetizationService`, and every gated system read from this one file.

### Testing purchases safely without spending Robux

- **In Studio, `MarketplaceService` purchase prompts don't charge real
  Robux** even with real Ids configured — Studio always simulates the
  purchase flow. This is the normal way to test `ProcessReceipt` and
  `PromptGamePassPurchaseFinished` end-to-end before publishing.
- **Without real Ids yet**, you can still exercise every gated behavior
  directly from the command bar (Studio → View → Command Bar), e.g.:

  ```lua
  local DataManager = require(game.ServerScriptService.Server.DataManager)
  local profile = DataManager.GetProfile(game.Players.SomePlayer)
  profile.OwnedGamepasses.Luck2x = true
  profile.Gems += 500
  ```

  This is exactly what the testing plan above does for each gated system.
- **Never** hardcode a real-looking Id "just for testing" — leave it `0`
  and use the command bar instead. A `0` Id fails safely everywhere; a
  guessed real-looking Id could accidentally reference someone else's
  actual product.

## Current scope

See `GAME_DESIGN.md` → "MVP Scope", "Making Pip Feel Alive", "Core Loop Fun
Audit", "Monetization Phase Status", and "Explicitly Not Built Yet". In
short: the free loop proves DISCOVER → RAISE → INFLUENCE → GROW → first
EVOLVE → COLLECT (two Critters), Pip now reads as an actual creature
(idle motion, reactions, Mood, a Bestiary, an always-visible Goals
checklist) rather than a model with a progress bar, and the monetization
systems layer on top of all of it without changing that loop. A shared
world hub, a scripted tutorial, multi-event scheduling, premium habitat
re-skins, and evolution reroll remain deliberately deprioritized,
schema-only, or not started — see "Core Loop Fun Audit" for the reasoning.
