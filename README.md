# MilBase

**A milsim roleplay base gamemode for Garry's Mod — Helix-style immersion, DarkRP-style simplicity.**

Built for StarWarsRP, HaloRP, MilitaryRP and any regiment-based milsim server. Works out of
the box with **zero addons** (the example factions use HL2 assets), and any weapon pack
(TFA, ArcCW, CW2) drops straight into the loadout tables.

Every optional integration is guarded: if an addon isn't installed, the systems that depend
on it stay dormant and the rest of the gamemode is unaffected. Missing art falls back to
flat panels and blur, missing fonts to system defaults, missing sounds to stock GMod sounds.

| | |
|---|---|
| **Core** | 27 files — database, factions, inventory, certifications, progression, staff, UI |
| **Modules** | 128 drop-in gameplay modules across ~100 systems |
| **Config** | 23 config files; two of them cover most servers |
| **Storage** | SQLite by default, MySQL optional, automatic fallback |
| **Docs** | Per-system guides in the repository root |

---

## Contents

- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Features](#features)
  - [Characters, factions & progression](#characters-factions--progression)
  - [Inventory, gear & the quartermaster](#inventory-gear--the-quartermaster)
  - [Medical, injuries & disease](#medical-injuries--disease)
  - [Combat, mobility & fire support](#combat-mobility--fire-support)
  - [Engineering & ship operations](#engineering--ship-operations)
  - [Space, flight & the galaxy campaign](#space-flight--the-galaxy-campaign)
  - [Law, crime & imprisonment](#law-crime--imprisonment)
  - [Communications](#communications)
  - [Jedi Order & lightsabers](#jedi-order--lightsabers-optional)
  - [Events & game mastering](#events--game-mastering)
  - [Staff tools & moderation](#staff-tools--moderation)
  - [Interface & quality of life](#interface--quality-of-life)
  - [Performance & reliability](#performance--reliability)
- [Commands](#commands)
- [Keys](#keys)
- [Writing modules](#writing-modules)
- [Content & Workshop](#content--workshop)
- [Optional integrations](#optional-integrations)
- [Documentation index](#documentation-index)
- [Roadmap](#roadmap)

---

## Requirements

- Garry's Mod dedicated server (any `rp_` / `gm_` map)
- No mandatory addons — everything below runs on stock content
- Optional: MySQLOO binary module for MySQL storage; see [Configuration](#configuration)

## Quick start

1. Place this folder in `garrysmod/gamemodes/milbase/`
2. Set the gamemode: `gamemode milbase` in `server.cfg`, or via the host game menu
3. Start the server on any map
4. Make yourself Owner from the server console:
   ```
   mb_setstaff "YourName" owner
   ```

## Configuration

Most servers only ever edit two files:

| File | What it does |
|---|---|
| `gamemode/config/sh_config.lua` | Speeds, ranges, stamina, economy, respawn time, inventory size, injury tuning, admin lockdown |
| `gamemode/config/sh_factions.lua` | Your regiments, ranks, models, loadouts, standard-issue kits |

The rest, as you need them:

| File | What it does |
|---|---|
| `sh_items.lua` | Inventory items (meds, ammo, grenades, custom `onUse` items) |
| `sh_certs.lua` | Certifications (extra health/equipment, medic perks) |
| `sh_staff.lua` | Staff ranks (levels, colours, usergroup mapping) |
| `sh_species.lua` / `sh_languages.lua` | Playable species and their native languages |
| `sh_events.lua` / `sh_eventenemies.lua` | Event tool spawns and playable enemy classes |
| `sh_starcards.lua` / `sh_crates.lua` | Star cards and weighted crate loot tables |
| `sh_comms.lua` | Radio channels, roles and jamming |
| `sh_lscs.lua` | Jedi skill tree, trials, holocrons, alignment, workbench tuning |
| `sh_galaxy.lua` / `sh_living_universe.lua` | Galaxy encounters, raid balance, planet seeds, lore locks |
| `sh_naval_operations.lua` / `sh_prison.lua` / `sh_smuggling_inspections.lua` | Naval, prison and customs systems |
| `sh_jetpack.lua` / `sh_juggernaut.lua` / `sh_tether.lua` / `sh_massif.lua` | Individual equipment systems |

### Database

MilBase uses GMod's built-in SQLite by default — **zero setup**. To use MySQL/MariaDB
instead, install the MySQLOO binary module, create an empty schema, and enable it in config.
If MySQL cannot connect, MilBase falls back to SQLite so the server always starts.

> **Keep credentials server-side.** Files prefixed `sh_` are sent to every connecting
> client by the loader. Put database credentials in a `sv_`-prefixed config file so they
> never leave the server.

### Adding a regiment

```lua
MilBase.RegisterFaction("501st", {
    name = "501st Legion",
    color = Color(65, 105, 225),
    description = "Vader's Fist. Frontline assault legion.",
    models = { "models/player/yourpack/clone_501st.mdl" },
    loadout = { "tfa_dc15a" },
    ranks = {
        { name = "CT",             salary = 20 },
        { name = "Lance Corporal", salary = 25 },
        { name = "Sergeant",       salary = 40, canPromote = true },
        { name = "Lieutenant",     salary = 55, canPromote = true, loadout = { "tfa_dc17" } },
        { name = "Commander",      salary = 80, canPromote = true, models = { "models/player/yourpack/appo.mdl" } },
    },
})
```

The roster, assignment, promotions, loadouts and HUD all pick it up automatically.

---

## Features

### Characters, factions & progression

- **Factions & rank ladders** — one table per regiment with per-rank loadouts, salaries and models
- **In-game faction editor** — staff create database-backed factions or override file-defined ones from the F2 menu, including colours, logos, models, loadouts, issue kits and complete rank ladders ([guide](FACTION_EDITOR.md))
- **Assignment-based roles** — nobody picks a job from a menu; everyone starts as a Recruit and officers recruit, promote or discharge them. Assignments persist and reapply every spawn
- **Persistent characters** — RP name, faction, rank and money saved per player ([selector](CHARACTER_SELECTOR_REDESIGN.md))
- **Certifications** — qualifications granted with `/certify` that add max health, weapons and standard-issue kit; the Field Medic cert unlocks treating others ([guide](CERTIFICATIONS_AND_CHARACTERS.md))
- **Appearance customisation** — an APPEARANCE tab with rank-locked and equipment-locked parts, plus staff MODEL RULES
- **Species & languages** — playable species with native languages and a translator system ([guide](LANGUAGE_AND_TRANSLATOR_SYSTEM.md))
- **Unit naming** — four-digit clone numbering with collision checks, and separately managed medic ranks
- **Star cards** — Battlefront-style loadout cards granting weapons, gear or health, faction-specific or cert-locked, with rarities
- **Crates, boosters & XP** — spend credits on crates that unlock star cards, gear, credits and temporary XP/credit multipliers
- **Daily orders** — rotating daily objectives with rerolls and a DAILY ORDERS tab ([guide](DAILY_QUESTS_ARCCW_HUD.md))
- **New-player tutorial** — a first-join walkthrough, replayable with `/tutorial`

### Inventory, gear & the quartermaster

- **EFT-style GEAR screen** — weapon slots (two primaries, one holstered secondary) and equipment slots (headwear, body armour, backpack), a backpack grid, a stash grid and a drop zone; drag and drop between grids, rotate with R, stacks merge
- **Armour & equipment** — helmets and vests grant armour points and can swap playermodels or apply bodygroups; backpacks add a second storage grid ([armour editor](DAILY_F4_ARMOR_EDITOR.md))
- **Weapon carry limits** — two primaries plus one secondary; melee, grenades and tools exempt, issued loadouts bypass
- **Standard issue** — factions and ranks define `issue` kits; players are resupplied up to their kit every spawn, with no stockpiling
- **Quartermaster NPCs** — placed vendors where soldiers collect replacement armour and equipment
- **Item icons** — flat 2D icons for medical items, with model renders as fallback

### Medical, injuries & disease

- **Limb health** — seven body parts each with their own HP; bullets damage what they hit, falls hit the legs, explosions spread. Destroyed parts cause limping, weapon sway or slow stamina regen until a surgical kit restores them
- **HEALTH tab** — your playermodel with HP chips pinned to every limb; click a part, then a med from your supplies
- **Field treatment** — certified medics see the *patient's* body screen beside their own supplies
- **Injuries** — bleeding until bandaged, fractures until splinted, painkillers to suppress effects, timed heal channels that real damage interrupts
- **Wounded & revive** — lethal hits down you instead of killing you; teammates hold E to stabilise, spending one of *their* bandages, and medics revive faster
- **Disease & the Bio-Lab** — infections with escalating symptoms (blurred vision, voices, slowed movement) that spread between players; medics take bio samples from infected patients, research a cure at the Bio-Lab, and administer it in the field or vent it across an area

### Combat, mobility & fire support

- **Jetpacks** — flight with fuel management, locked out in vehicles, while restrained, jailed or incapacitated ([guide](JETPACK_README.md))
- **Juggernaut armour** — a heavy powered suit with its own movement handling and an ability wheel; incompatible with jetpacks and too heavy for the rescue tether ([guide](JUGGERNAUT_README.md))
- **Ordnance & orbital fire support** — grid-referenced strikes called from a console or scanner: orbital turbolaser, heavy bombardment, area-denial gas and gunship attack passes, with fallbacks when HBOMBS isn't installed
- **Dropship & armour call-ins** — permission-gated dropship deployments to defined drop zones with cooldowns, and AAT armour deployment with AI enabled
- **Weapon wheel** — replaces the stock GMod weapon selector
- **Squad pings** — a contextual ping wheel (enemy contact, advance, hold, rally, watch, need support) shared with your fireteam
- **Squads & fireteams** — `/squad` management, a fireteam HUD with member health and distance, overhead markers and squad radio
- **ArcCW integration** — weapon and attachment support with in-game editors ([guide](ARCCW_ATTACHMENTS_EDITORS.md))
- **LVS cockpit HUD** — hull, shields, fuel, live subsystem status, weapon heat, speed and altitude while flying
- **Vehicle requisition** — request vehicles through a configurable requisition system
- **Realistic fall damage**, respawn timers and a KIA screen

### Engineering & ship operations

- **LVS engineering & subsystems** — combat damage knocks out shields, engines or weapons independently; disabled engines can't restart, disabled weapons can't fire, disabled shields collapse. Engineers repair each subsystem with timed channels, rebuild wrecks and refuel
- **Engineering incidents** — admins place hull breaches and engineering terminals per map; they malfunction on a timer with a server-wide alert. Breaches are welded shut by tracing the seam with the repair tool; terminals are fixed with a code-typing minigame. Fixes pay credits
- **Sabotage** — saboteurs see a ship's weak points, plant visible detonation charges on them and detonate remotely, blowing weak points into hull breaches
- **Atmosphere & sealed suits** — an active breach vents the area; unprotected soldiers suffocate. Engineers seal their suit to breathe from a tank with an oxygen meter
- **Zero gravity & gravity zones** — disable gravity per map, then carve out gravity zones as boxes or by tracing a room's outline; magnetic boots lock you to the deck
- **Rescue tether** — recover players drifting in zero gravity, with target validation and weight limits ([guide](RESCUE_TETHER_README.md))
- **LVS hacking** — a slicer kit plus the code minigame commandeers an allowed, unoccupied vehicle, flipping it to the slicer's team
- **Keycards** — five clearance levels gating doors and areas
- **CCTV** — a monitor SWEP showing placed security cameras and live helmet cams from any helmeted player, with panning and fullscreen
- **DEFCON** — a server-wide alert state driving HUD display and system behaviour ([guide](DEFCON_SYSTEM.md))
- **Naval operations** — bridge stations, power consoles and ship-wide operations ([guide](NAVAL_OPERATIONS.md))
- **Fleet logistics** — supply and logistics tracking across the fleet

### Space, flight & the galaxy campaign

- **Galaxy Director** — a campaign layer populating hyperspace routes with patrols, civilians, pirates, distress calls and hostile contacts, with trade, intelligence, repairs and surrender demands. Major contacts escalate into staged assaults with bombardment, blast-door breaches, drop pods and boarding waves. Persistent planet opinion, pressure, lore locks, cooldowns and an audited control centre ([guide](GALAXY_DIRECTOR.md))
- **Living universe** — ambient traffic and events that keep space populated between set pieces ([guide](LIVING_UNIVERSE.md))
- **Deep space transit** — player-flown craft leave the skybox boundary into a managed deep-space lane, with capacity limits and size restrictions
- **Squadron space combat** — fighter screens and wave engagements around capital ships ([guide](SQUADRON_VULTURE_SKYBOX_FLIGHT.md))
- **Skybox remote flight** — flight assist, contacts and orders, ship size classes and combat handling for skybox-scale craft ([assist](SKYBOX_REMOTE_FLIGHT_ASSIST.md) · [contacts](SKYBOX_REMOTE_CONTACTS_AND_ORDERS.md) · [size classes](SKYBOX_SHIP_SIZE_CLASSES.md))
- **Realistic ship movement** — momentum-based handling for large craft ([guide](REALISTIC_SHIP_MOVEMENT.md))
- **Customs & smuggling inspections** — Republic customs stops, false-IFF cases, forced landings and physical cargo searches ([guide](SMUGGLING_AND_SHIP_INSPECTIONS.md) · [test harness](SMUGGLING_INSPECTION_TEST_HARNESS.md))
- **Cinematic flythroughs** — recorded keyframe camera tours for intros and set pieces
- **LAAT deployment** — named infiltration routes, passenger seat editing and a skybox fly-in before the real transport spawns

### Law, crime & imprisonment

- **Jail & criminal records** — arrest and records terminals, a configurable crime catalogue, charge lookup and a CRIMES tab
- **Military police** — cuffing and leash-dragging with a real velocity pull; cuffed soldiers lose weapons, walk slowly and can't use doors or items
- **Shipboard prison** — a full custodial system with cells, processing and prisoner handling ([guide](SHIPBOARD_PRISON_SYSTEM.md))
- **Prison operations** — hybrid guard navigation, physical guard commands, staged incidents, surveillance, alarms and safe lockdown control

### Communications

- **Voice & radio** — hold H to pick a channel; a dedicated radio push-to-talk transmits on it while the normal voice key stays local proximity
- **Channels** — Command, Regimental, Training, ATC, Joint Operations (two factions share comms until closed) and the encrypted Hostile Net
- **Encryption & interception** — friendly High Command and staff hear only static on the Hostile Net until they hack a relay; a Signals Intelligence cert lets a soldier slice a fallen enemy's body to tap the net until killed, warning the enemy their comms are compromised
- **Jamming** — jammers black out radio map-wide or in a radius, with local proximity voice always surviving
- **COMMS tab** — per-channel receive volume and muting
- **Enemy voice modulation** — event enemies get processed voice profiles

### Jedi Order & lightsabers (optional)

Requires the free [LSCS](https://steamcommunity.com/workshop/filedetails/?id=2837856621) addon. Without it these systems stay dormant.

- **Progression** — XP earns training points spent in a five-branch skill matrix (Force control, reserves, Light side, Dark side, saber forms) unlocking real LSCS powers, stances and passives
- **Gating** — nodes gate on Jedi rank, Light/Dark alignment that shifts from the powers you actually use, completed trials approved by a Master or staff, and discovered holocrons
- **Lightsaber Forge** — replaces the stock LSCS menu with an overview, skill matrix, per-hand saber assembly with live model preview, a four-slot Force loadout, a form library, trials, Master–Padawan mentorship and saveable presets
- **World objects** — persistent per-map Jedi workbenches and holocrons; loadout edits, respec and saber assembly require a workbench
- **Access control** — non-Jedi can never equip sabers or powers regardless of how they obtained the items
- **Staff tools** — Jedi management and LSCS admin tabs with a full audit log and one-click rollback of any profile change

### Events & game mastering

- **Game-master camera** — free-fly camera with a right-click context menu to create units, vehicles, effects and objects, and to move, attack, waypoint, set behaviour, heal, protect or delete the selection. Box-select, drag to reposition, and a spawn settings panel for team, squad size, health and stance
- **Objectives** — placeable attack, defend, hack, repair, intel, extraction, rally and breach markers shown on every player's HUD with distance and edge-clamped direction
- **Triggers & linked actions** — conditions (players enter/leave an area, timer ends, all enemies defeated, linked entity hacked/repaired/destroyed) wired to actions (announce, spawn wave, create or complete objective, toggle doors, explosion, alarm)
- **Playable event enemies** — recruit players into locked enemy classes with their own models, health, armour, weapons, speed and lives, plus temporary certifications and gear that vanish on reversion ([guide](EVENT_ENEMY_UPGRADES.md))
- **Build mode** — become an invisible flying god with the native spawn menu, toolgun and physgun, then flip back to commanding
- **Cinematic dialogue** — a reusable conversation system shared by customs and prison NPCs
- **Music** — staff-controlled track playback with per-player muting
- **Safeguards** — every spawn logged with who spawned it, and an entity cap to protect the server

### Staff tools & moderation

- **Staff ranks** — Trial Moderator through Owner, config-defined with authority levels; Admin and above map onto GMod's real usergroups
- **Staff mode** — noclip and damage immunity toggled per staff member
- **Moderation** — bans, jailing and targeting rules that prevent acting on equal or higher staff
- **Admin sits** — `/sit` pulls a player to a configured sit spot, with damage suppressed for the duration
- **Reports & alerts** — player reports with staff alert reminders ([guide](STAFF_ALERT_AT.md))
- **Staff F4 tabs** — STAFF and GIVE ITEMS for teleporting, freezing, kicking, rank changes and item grants
- **Contextual interactions** — hold C and right-click a soldier, or click them on the scoreboard, for one menu covering officer actions and staff actions by level

### Interface & quality of life

- **Battlefront-style UI** — F4 tabs drawn with chamfered corner-cut panels, thin golden edges, selection brackets, bright-edged stat bars, Bebas Neue and D-DIN typography, faction emblems and UI sounds
- **Battlefront 2017 HUD** — frameless clusters around the bottom centre: health with a segmented bar, armour and stamina strips, mirrored ammo cluster with magazine bar and low-ammo warning, credits, nameplates, squad cards with diamond world markers, and a compass with bearing readout
- **HUD customiser** — toggle and reposition individual HUD elements (ammo, daily orders, comms, DEFCON, chat, engine and ship damage)
- **Datapad** — an in-character device for personnel files, medical records and checkups, criminal records, charge lookup and DEFCON status ([landing UI](INSPECTION_UI_DATAPAD_AND_LANDING_UPGRADE.md))
- **Helix-style scoreboard** — centred column, regiment colour bands, character model portraits, rank subtitles, staff tags and ping, with kill and death stats; click a row to interact
- **Custom chatbox** — dark entry bar, word-wrapped fading lines, comms tabs per channel
- **Immersive chat** — ranged IC chat, whisper, yell, `/me`, `/it`, `/roll`, faction radio, PMs and global OOC
- **Gestures** — salute, halt, forward, group, wave and more with real animations
- **RP menu & self-menu** — radial menus for squad actions, gestures, rolls, and self actions such as sealing your suit, mag-boots, vehicle service and detonating charges
- **Third person** — toggleable and bindable, with an F4 tab ([guide](THIRDPERSON_BIND.md))
- **Spawn selector** — choose a deployment point with faction and specialisation requirements
- **Helix-style recognition** — no floating nametags; identify soldiers by aiming at them up close
- **Proximity voice**, injury desaturation and no killfeed
- **Sandbox locked to admins** — spawn menu, toolgun, physgun and noclip gated, with a skinned spawn menu for those who have it

### Performance & reliability

- **Unified database layer** — one API for the whole gamemode, SQLite by default, MySQL when configured, automatic fallback to SQLite if MySQL cannot connect
- **Ordered migrations** — MySQL work is processed in FIFO order so a `SELECT` can never overtake the `CREATE TABLE` it depends on while players connect during startup; the public API stays asynchronous
- **Live diagnostics** — `mb_performance_status` separates genuine server stalls from network round-trip time ([notes](PERFORMANCE_OPTIMISATION.md))
- **Collision handling** — player collision fixes with a debug mode
- **Graceful degradation** — every content reference has a fallback, so the gamemode stays playable with no workshop content mounted

---

## Commands

### Everyone

| Command | Description |
|---|---|
| `/me`, `/it`, `/roll` | Roleplay actions |
| `/w`, `/y` | Whisper / yell |
| `/r <msg>` | Faction radio |
| `/ooc <msg>` or `// <msg>` | Global OOC |
| `/pm <player> <msg>` | Private message |
| `/name <name>` | Set character name |
| `/squad <sub>` | `create`, `invite`, `accept`, `leave`, `kick`, `disband` |
| `/s <msg>` | Squad radio |
| `/datapad` | Open the datapad |
| `/daily`, `/quests` | Daily orders |
| `/tutorial` | Replay the new-player tutorial |
| `/jetpack`, `/juggernaut` | Toggle equipment you have been issued |
| `/salute` `/halt` `/forward` `/group` `/wave` `/agree` `/disagree` `/bow` | Animated gestures |

### Officers & admins

| Command | Description |
|---|---|
| `/promote`, `/demote <player>` | Move a soldier up or down one rank |
| `/setfaction <player> <id>` | Recruit into a regiment or discharge |
| `/certify`, `/decertify <player> <cert>` | Grant or revoke certifications |
| `/setrank <player> <rank>` | Set an exact rank |
| `/setclonenumber <player> <####>` | Assign a four-digit unit number |
| `/setmedicrank`, `/clearmedicrank` | Manage medic ranks |
| `/jointop <faction>`, `/jointopclose` | Open and close joint-operation comms |
| `/quartermaster` | Place or manage a quartermaster |
| `/ordscan`, `/ordconsole` | Fire-support scanner and console |
| `/jailrecords`, `/jailreload` | Criminal records |

### Staff

| Command | Description |
|---|---|
| `/setstaff <player> <rank>` | Set a staff rank (`user` removes it) |
| `mb_setstaff <name\|steamid> <rank>` | Same from console; the server console can set anyone, including offline by SteamID |
| `/staffmode` | Toggle staff mode |
| `/sit`, `/endsit`, `/sitadd`, `/sitspot` | Admin sits and sit locations |
| `/event`, `/announce <msg>`, `/eventclear` | Game-master tools |
| `/eventenemy <class> [player]`, `/eventenemyend`, `/eventenemyspawn` | Playable event enemies |
| `/engspot breach\|terminal\|break\|remove` | Engineering incident spots |
| `/gravity` | Map gravity settings and zero-g |
| `/cctv` | Spawn a CCTV camera |
| `/spawns`, `/spawnselector` | Deployment points |
| `/jediworkbench`, `/jediholocron <type>`, `/jediremoveworld`, `/jediclearworld` | Jedi world objects |
| `/prisonalarm`, `/prisonnav`, `/prisonlanguage <id>` | Prison control |
| `/inspectionanchor`, `/inspectionanchors`, `/inspectionclearanchors`, `/customstest` | Customs inspections |
| `/vehreqsetup`, `/vehreqconfig`, `/vehreqeasy` | Vehicle requisition |
| `/givejetpack`, `/givetether`, `/infect` | Issue equipment and seed infections |
| `/giveitem`, `/givecard`, `/givecredits` | Grants |
| `/massifname <name>` | Name a Massif |
| `/fixcollision` | Resolve a stuck player |

## Keys

| Key | Action |
|---|---|
| **F4** (or F1) | Personnel menu |
| **TAB** | Scoreboard — click a soldier to interact |
| **E** (hold) | Quick interactions: promote, push, check dogtags, treat, cuff, drag, take bio sample; stabilise a wounded soldier; pick up items; plant a charge on a weak point; slice a fallen enemy's comms |
| **G** (hold) | Self menu — seal suit, mag-boots, LVS service and hacking, comms jammer, detonate charges |
| **H** (hold) | Comms channel selector |
| **C** + right-click | Interact with a soldier |
| **B** | Build mode, in the game-master view |
| **SPACE** | Give up while wounded |
| Radio PTT | Bind once with `mb_radiobind <key>`; X stays local proximity voice |

In the inventory: drag to move, **R** rotates while dragging, double-click or right-click to use, drag to the drop zone to discard.

---

## Writing modules

Drop a file into `gamemode/modules/`. The filename prefix decides where it runs:
`sv_` server, `cl_` client, `sh_` shared. Shared and client files are sent to clients
automatically — never put secrets in them.

See `modules/sv_paychecks.lua` for a complete working example, and
`modules/cl_bodymenu.lua` for a module that adds its own F4 tab.

```lua
MilBase.AddMenuTab(name, order, buildFunc)
MilBase.RegisterChatCommand("salute", { help = "...", func = function(ply, args, rawText) ... end })
MilBase.RegisterItem("id", { name, desc, model, w, h, stack, onUse = ... })
MilBase.RegisterPlayerAction(...)      -- C-menu / scoreboard actions
MilBase.RegisterQuickInteraction(...)  -- hold-E actions
MilBase.RegisterSelfAction(...)        -- hold-G actions

ply:MBName(), ply:MBFaction(), ply:MBRank(), ply:MBRankIndex(), ply:MBMoney()
ply:MBAddMoney(n), MilBase.SetRank(ply, i), MilBase.SetFaction(ply, id)
MilBase.GiveItem(ply, id, n), MilBase.TakeItem(ply, id, n), MilBase.CountItem(ply, id)
MilBase.Notify(ply, text), MilBase.ChatMsg(target, ...), MilBase.TalkRanged(ply, range, ...)

MilBase.DB.Query(sql, onData, onError)  -- async; onData(rows)
MilBase.DB.Run(sql)                     -- fire-and-forget write
MilBase.SQLStr(value)                   -- escaped + quoted literal
```

## Content & Workshop

Players auto-download the content packs listed in `cfg.WorkshopContent` via
`resource.AddWorkshop`. Original workshop items are referenced, never re-uploaded.

- **Kraken's Scripts Main Content** (`3565959952`) — UI fonts, menu art, class icons, faction emblems, UI sounds
- **MilBase — Content** — a ready-to-publish addon with MilBase's own generated item icons; publish with gmpublisher and add the ID to `cfg.WorkshopContent`
- **[CGI] Civilian Pack** (`2997442699`) — prisoner, criminal and civilian models for customs and the prison language system
- **[CWRP] CGI HD Wookie Player Models** (`2825079448`) — the Wookiee profile

## Optional integrations

| Addon | Adds | Without it |
|---|---|---|
| [LSCS](https://steamcommunity.com/workshop/filedetails/?id=2837856621) | Jedi Order, lightsabers, Force powers | Jedi systems stay dormant |
| [lvs_base](https://github.com/SpaxscE/lvs_base) | Vehicle subsystems, engineering, hacking, vehicle orders | Vehicle systems disabled |
| Star Wars Universe | Hyperspace travel for the galaxy campaign | Campaign runs without hyperspace routes |
| ArcCW / TFA / CW2 | Weapon packs and attachment editors | Stock weapons only |
| HBOMBS | Bombardment effects | Ordnance falls back to built-in effects |
| MySQLOO | MySQL storage | Falls back to SQLite |

## Documentation index

**System guides** — [Galaxy Director](GALAXY_DIRECTOR.md) · [Living Universe](LIVING_UNIVERSE.md) · [Naval Operations](NAVAL_OPERATIONS.md) · [Shipboard Prison](SHIPBOARD_PRISON_SYSTEM.md) · [Smuggling & Inspections](SMUGGLING_AND_SHIP_INSPECTIONS.md) · [DEFCON](DEFCON_SYSTEM.md) · [Jetpack](JETPACK_README.md) · [Juggernaut](JUGGERNAUT_README.md) · [Rescue Tether](RESCUE_TETHER_README.md) · [Massif](MASSIF_README.md) · [Faction Editor](FACTION_EDITOR.md) · [Certifications & Characters](CERTIFICATIONS_AND_CHARACTERS.md) · [Languages & Translator](LANGUAGE_AND_TRANSLATOR_SYSTEM.md) · [ArcCW Attachment Editors](ARCCW_ATTACHMENTS_EDITORS.md) · [Daily Quests](DAILY_QUESTS_ARCCW_HUD.md) · [Armour Editor](DAILY_F4_ARMOR_EDITOR.md) · [Event Enemies](EVENT_ENEMY_UPGRADES.md) · [Character Selector](CHARACTER_SELECTOR_REDESIGN.md) · [Ship Movement](REALISTIC_SHIP_MOVEMENT.md) · [Ship Size Classes](SKYBOX_SHIP_SIZE_CLASSES.md) · [Flight Assist](SKYBOX_REMOTE_FLIGHT_ASSIST.md) · [Contacts & Orders](SKYBOX_REMOTE_CONTACTS_AND_ORDERS.md) · [Skybox Combat](SKYBOX_REMOTE_COMFORT_COMBAT_UPGRADE.md) · [Squadron Flight](SQUADRON_VULTURE_SKYBOX_FLIGHT.md) · [Inspection Test Harness](SMUGGLING_INSPECTION_TEST_HARNESS.md) · [Datapad & Landing UI](INSPECTION_UI_DATAPAD_AND_LANDING_UPGRADE.md) · [Performance](PERFORMANCE_OPTIMISATION.md) · [Third Person](THIRDPERSON_BIND.md) · [Staff Alerts](STAFF_ALERT_AT.md)

**Change notes** — [Character loading](CHARACTER_LOADING_DB_FIX.md) · [Galaxy ship retreat](GALAXY_SHIP_RETREAT_CHANGE.md) · [Inspection map recovery](INSPECTION_MAP_RECOVERY_AND_DOOR_FIX.md) · [Inspection model bounds](INSPECTION_MODEL_BOUNDS_COMPATIBILITY_FIX.md) · [Juggernaut loadout](JUGGERNAUT_AUTO_SLAM_LOADOUT_CHANGELOG.md) · [Juggernaut fall immunity](JUGGERNAUT_MODEL_FALL_IMMUNITY_CHANGELOG.md) · [LSCS integration](LSCS_INTEGRATION_FIX.md) · [Massif animation](MASSIF_PLAYER_ANIMATION_FIX.md) · [Naval screen duplication](NAVAL_SCREEN_DUPLICATION_FIX.md) · [Prison cell wizard](PRISON_CELL_WIZARD_AND_LOAD_FIX.md) · [Skybox nesting](SKYBOX_REMOTE_NESTING_FIX.md) · [Squadron launch safety](SQUADRON_LAUNCH_SAFETY_FIX.md) · [Startup & prison tool](STARTUP_ERROR_AND_PRISON_TOOL_FIX.md)

## Roadmap

- XP and time-based automatic promotion
- Objective timers and explicit fail conditions
- Editable-property RP entities, and save/load event templates
- Name format enforcement per faction (e.g. `CT-#### Name`)
- Armoury NPC and requisition points
- Persistent squads (currently per-session)
