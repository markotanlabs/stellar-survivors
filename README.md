> **Rolled back to v0.8.2** (Nov 24). The full armory, missile lock-on and Sons of Philip AI (v0.9.0 to v0.10.0) are parked in `Documents/Stellar Survivors Backups/v0.10.0 (broken, in progress)` and come back one update at a time.

## v0.9.241: Performance pass (asteroids)

- **Asteroids left the enemy-search list.** Every gun, Starbase and ship looks through the game's list of possible targets several times a second, and every asteroid in every system was on it (never hostile, so always thrown away). With the bigger belts that was hundreds of wasted checks per scan. Shots still hit rocks and you can still focus them.
- **Firing-line checks** (Starbase guns won't shoot through a valuable rock) now use one shared list of a system's rocks per frame and skip rocks nowhere near the line, instead of walking every object in the system for every check.
- **Asteroid drawing**: rocks redraw every other frame (spread across frames), every fourth when they're specks on screen, and when zoomed out they skip the glints, motes and twinkles. Rich rocks have fewer flecks to draw (up to 8, was up to 18).
- Rocks in systems you aren't looking at no longer animate their idle wobble.

## v0.9.240: Slower asteroid respawn

- Destroyed asteroids take **50% longer** to come back: a 4.5 to 15 s wait, then a 112.5 s drift in (was 3 to 10 s and 75 s). About **2 minutes** in all (a mining rock you shot: a little longer).

## v0.9.239: Asteroid belts

- **More asteroids, each leaner**: fields now hold 4 to 8 rocks (was 2 to 5), and a rock carries **1 to 8 Alloys** (8 is rare, about 1 rock in 90; 45% of rocks are plain). Overall income is about the same, but a fat rock is now a find.
- **Size shows the Alloys**: a rock's size follows its Alloys, from a small 1 to a big lump at 8. Plain rocks stay smallish; Gas rocks are unchanged.
- **Belts on the orbits**: asteroid groups now lie in arcs along the system's orbit rings (the faint circles at 35, 70 and 100), like stretches of a real belt, and the groups round planets, gas giants and the Rebels' giant rock arc around them too.
- **Alloy cards buffed** for the x5 economy: **Mining Corp +15** a day (was +5), **Deep Core Mining +10** per mining Starbase (was +5).
- Earth's starting rocks: 8 rocks giving 25 Alloys a day, on a short arc inside the first Starbase's reach.
- Fixed: a respawned asteroid came back 20% bigger every time.

## v0.9.238: Upkeep labels

- Upkeep no longer spells out the daily rate (it's implied): build cards show "UPKEEP -2", the Alloys tooltip says "FLEET UPKEEP" and "Total upkeep: N".

## v0.9.237: Alloys x5 (test)

- **Every Alloy number is 5x bigger**, so whole-number upkeep is a fair cost instead of a crushing one. Upkeep itself is unchanged (Corvette 1, Frigate 2, Destroyer 2, Cruiser 3, Carrier 4, Battleship 5 a day).
  - **Income x5**: asteroid yields (rock labels show the new numbers), desert-world pops (5 Alloys per 3 pops), Mining Corp (+5), Deep Core Mining (+5), shooting mining rocks.
  - **Prices x5**: ships (Corvette 15, Frigate 50, Destroyer 75, Cruiser 100, Carrier 125, Battleship 150, before scaling), Starbase 200, Shipyard 125, MAG Cannon 250, Colony Ship 50 (Colony Office takes 10 off).
  - **Start with 100 Alloys** (was 20).
  - Haulers carry 5 Alloys per container (still 5 containers), so the same number of trips.
- Earth's starting belt is back to its old size (now 25 Alloys a day); the extra rocks from v0.9.230 aren't needed any more.
- Gas and Credits are unchanged. Philip's fleet budget is unaffected.

## v0.9.236: No more lines on warp-in

- Fixed: when Rebels (or any ship) came out of a warp lane, its contrail drew a long white line across the screen from where it had been in the other system, and guns briefly led it wildly. Ships that jump now drop their old contrail and speed.

## v0.9.235: Upkeep retune

- **Upkeep** per day: Corvette 1 · Frigate 2 · Destroyer 2 · Cruiser 3 · Carrier 4 · Battleship 5.
- Upkeep is no longer shown in red anywhere (build cards, the Alloys tooltip, a negative daily Alloy figure).

## v0.9.234: Wider Starbase collection

- **Starbase collection range** (their orbit) is **30% bigger** by default (12 to 15.6 units): more rocks and gas giants in reach. Extended Orbits and Tractor Arrays still grow it from there.

## v0.9.233: Mini MAG Batteries text

- **Mini MAG Batteries** card text shortened to fit the card: "+1 Mini MAG on every Starbase. Max 3".

## v0.9.232: Build cards show upkeep

- Ship cards in the build menu show their **upkeep** under the price (UPKEEP, Alloy icon, -N/day).
- The build time in the corner is just the number now (e.g. "10s", not "BUILD 10s").

## v0.9.231: Upkeep breakdown

- Hovering **Alloys** in the top bar now also shows **FLEET UPKEEP**: each ship type you own, how many, its Alloys a day each, the line total, and the **total upkeep per day**.

## v0.9.230: Whole-number upkeep

- **Fleet upkeep is now whole Alloys per ship per day** (no fractions): **Corvette, Frigate, Destroyer 1 · Cruiser, Carrier 2 · Battleship 3**. The Kharkiv, fighters and civilian ships stay free.
- To cover the 3 starting Corvettes, **Earth's starting asteroid belt now gives 8 Alloys a day** (was 5), so you begin at the same net +5.

## v0.9.229: Fleet upkeep

- **The 30% Alloy cut from v0.9.228 is reverted**: Alloy sources pay their full amounts again. (Scaling ship prices and their slow ease-down stay.)
- **Fleet upkeep**: every warship you own costs **Alloys each day**, by tier: Corvette 0.1, Frigate 0.2, Destroyer 0.3, Cruiser 0.4, Carrier 0.5, Battleship 0.6. The Kharkiv, fighters and civilian ships are free. Fractions add up across days (10 Corvettes cost 1 Alloy a day). It's paid on payday after income, and never takes you below zero.
- The top bar's Alloy income is now **net of upkeep**, shown in red if your fleet costs more than you earn.

## v0.9.228: Tighter Alloys, stickier prices

- **Every source of Alloys pays 30% less**: planet pops, Mining Corp, Starbase mining (hauled), Deep Core Mining and shooting mining rocks. Fractions carry over between payouts, so small incomes still add up correctly. The income shown in the top bar and on the galaxy map is the reduced figure.
- **Ship prices come back down slowly**: after you lose ships, a type's price now eases down by one ship's worth every 45 seconds instead of dropping at once. Building more still raises it straight away.

## v0.9.227: Starbase limit 3

- The default **Starbase limit** is now **3** (was 5), so a run starts at **2 / 3**. Advanced Logistics and Logistics Hub still raise it by 1 each.

## v0.9.226: Shipwright Guild

- New planet building **Shipwright Guild**: **+1 Construction Ship**, so one more station can be built at the same time (one per planet; stack them across planets). It's **4x as likely to be offered at the start** of a run, fading to normal odds by 10:00.
- Construction now supports several Construction Ships: each takes the next station in line, launches from the nearest Shipyard (or Earth), builds it, and heads home to be recycled when there's nothing left. A lost one relaunches after 5 s as before.

## v0.9.225: Kharkiv refit cards

- New Fleet cards that bolt **one more gun onto the Kharkiv** per pick, one for every weapon type:
  - **Kharkiv Gatling**: +1 K9 Gatling Gun (up to 3)
  - **Kharkiv PDC**: +1 PDC (up to 3)
  - **Kharkiv Flak**: +1 Flak Cannon (up to 3)
  - **Kharkiv Mini MAG**: +1 Mini MAG (up to 2)
  - **Kharkiv Torpedo Tube**: +1 Torpedo (up to 2)
  - **Kharkiv Missile Pod**: +1 Swarm Missiles launcher (up to 2)
  - (MAGs already come from **Twin MAG Mount**.)
- Each has its own card art. The new guns fit to the Kharkiv straight away and work with the existing weapon cards (PDC Overdrive, Long-Range PDCs, Proximity Fuses, Shaped Warheads, Bigger Swarms, Hot-Loaded MAGs).

## v0.9.224: Title menu tidy

- Removed the **COMING SOON** tag from Faction Unlocks on the title menu.

## v0.9.223: Bigger asteroids, Rebel swarm balance pass

- **Asteroids are 20% bigger** (drawn and collided); their health is unchanged.
- **Rebel waves rebalanced**: a steady ramp instead of early doublings. Corvettes per wave are now **6, 10, 15, 21, 28, 36, 45...** (were 8, 16, 32, 44, 56...), and Frigates make up a quarter of that (**2, 3, 4, 5, 7, 9...**; were 3, 6, 11, 15, 20). By 10:00 that's about 80 Corvettes and 21 Frigates instead of 156 and 55. Timing is unchanged (every 2 minutes from 2:00).

## v0.9.222: Mini MAG Batteries fixed

- **Mini MAG Batteries** (planet building): the limit of 3 was counted **per planet**, but the guns go on every Starbase at once and cap at 3 total, so after 3 the card kept being offered on other planets and did nothing (wasting a building slot). It's now capped for the whole empire and stops appearing once all 3 Mini MAGs are fitted. Card text updated.
- The Starbase **Mini MAG mounts are now visible**: a small twin-rail turret that turns to track its target and fires from the muzzle (they used to be invisible until charging).

## v0.9.221: PDC reach

- **PDC** range up 50% (12 to 18 units), so the now-accurate PDCs engage sooner. With **Long-Range PDCs** they reach 36, a bit past a Gatling's 30.

## v0.9.220: Trait tooltips

- Hovering a planet **trait** now shows a small tooltip straight away (its name and what it does) just under the chip.

## v0.9.219: Planet traits, scaling ship prices

- **Earth's health is back to normal** (3000, like every planet). The fix for Earth's free shields from v0.9.218 stays.
- **Planet traits**: the planet window shows a new **TRAITS** row of little chips (hover for details). Planets will get unique traits later to make exploring more exciting; for now every planet has **Hard as Rock**: every hit on it does **50% less damage**, always (grey damage numbers).
- **Ship prices scale**: each ship of a type you own or have queued adds **+10%** to that type's Alloy and Gas cost (rounded up). Losing ships brings the price back down. The build menu shows the current price, in amber when it's above the base. Cancelling a queued ship refunds what you actually paid.

## v0.9.218: Tougher Earth, no free shields

- **Earth** has **double health** (6000; other planets 3000).
- Fixed: Earth started every run with 500 planetary shields (and recharged them) without the **Planetary Shields** card. It now gets shields only from that card, like your other planets.

## v0.9.217: Finer gas jets, a softer hiss

- The pressurised-gas jets (turning, braking and push-off) are **much smaller and narrower**: thin, tight streams close to the hull.
- The jet sound is now a short, airy **hiss** (a quick valve-release of gas) and **quieter** everywhere it plays.

## v0.9.216: Expanse-style turning thrusters

- **Turning** now fires RCS bursts the way ships handle in *The Expanse*: a sharp sideways jet from **right at the hull near each ship's nose** (on the outside of the turn, pushing the bow round), answered by a smaller jet at the **stern** on the other side. Each starts with a little nozzle flash and is short and tight. They follow each ship's own heading, so they sit on the actual model.
- **Right-click a notification** to dismiss it.

## v0.9.215: Daily totals on the galaxy map only

- The system's **total daily resources** no longer show in the system view; they're on each system's banner in the **galaxy map** only. Planet banners still show what each planet makes.

## v0.9.214: H goes home to Earth

- **H** in Fleet Mode now always sends the fleet **home to Earth** (boosting, through as many warps as it takes), parking just off the planet. It used to head for the nearest Starbase. Outside Fleet Mode H still jumps the camera to Earth.

## v0.9.213: Accurate PDCs

- **PDCs** are now fire-controlled and actually hit: rounds fly almost twice as fast (so the lead on moving targets is far more accurate), scatter is a fifth of what it was, and they skip the extra scatter other auto-firing guns get. Applies to every ship's PDCs.

## v0.9.212: Long-Range PDCs

- New Fleet card **Long-Range PDCs**: your ships' PDCs reach **twice as far** (one pick). Works on every ship with PDCs, including the Destroyers' PDC Nest, and stacks with the Cruiser's longer reach.

## v0.9.211: Extended Orbits buff

- **Extended Orbits** (Tech card): Starbase orbits now grow **60%** per pick (was 20%), so mining reach, repair zones and everything tied to the orbit gets much bigger. It can be taken **twice** (about 2.5x the base orbit) instead of without limit.

## v0.9.210: Growth notifications clear on pickup

- Picking up a planet's **Growth Reward** bubble now removes its "has a Growth Reward" notification, so there's no stale link left to click.

## v0.9.209: Xander always pauses

- Xander's **one-line advice now pauses the game** too, like his lessons. Play resumes when you click GOT IT (or X), unless something else is holding the pause (a card screen, the pause menu).

## v0.9.208: Warp fix

- Fixed v0.9.206 moving the warp points themselves outside the systems (ships arriving through them, like enemy waves, started outside the boundary). The warp points and their **blue whirlpools are back inside**; only the **green arrow** (with its chevrons and "TO …" label) is drawn **just outside the boundary ring**, with the dotted course line running from the whirlpool, under the arrow and on out.

## v0.9.207: Record wind-down on death

- When the **Kharkiv dies**, the loud scratch sample is gone. Instead **all game audio winds down like a record when the turntable is switched off**: speed and pitch fall slowly then faster, with a slight warped-vinyl wobble, grit creeping in and the top end closing, then it sinks away over about 3 seconds. Back to normal on a new run or the main menu.

## v0.9.206: Warp arrows outside the system

- **Warp arrows** (and their whirlpools) now sit **just outside the system's boundary ring**. Near an arrow the fleet can fly out past the ring to reach it; elsewhere the boundary holds as before. The dotted course line and the "TO …" label run on from the arrow, the label just past the chevrons. The RTS camera can pan a little further out so the arrows stay in view. Stations still can't be placed on a lane.

## v0.9.205: Gunmetal build menu is back

- The **build menu** is back to the gunmetal C&C sidebar from before v0.9.193, but keeps the **green wireframe icons** in its cameos.

## v0.9.204: Fly the warp lane (test)

- Jumping in **Fleet Mode** no longer cuts to the galaxy map or zooms. The camera stays on your fleet as it's **pulled out along the exit's dotted course line**, faster and faster, under a screen-wide warp of streaking stars; at the peak a flash carries you across, and the fleet **flies in along the next system's lane**, braking to a stop at the entry point. Same jump length as before.
- Jumps that start outside Fleet Mode still happen in the background (pressing F mid-jump now joins the ride the same way).

## v0.9.203: Liquid warp whirlpool

- The warp whirlpool is **smaller** (just big enough to hold the arrow), **turns much slower**, and looks like water: wavy layered discs rippling, wobbling spiral arms, wavy ripples drifting inward and slow specks. The warp charge still starts at the same distance as before.

## v0.9.202: In Progress panel

- The title screen's **Coming Features** panel is now **In Progress**, with the **[ENTER] for feedback** hint sitting on top of it (bottom right). It's no longer on the Start Run button.

## v0.9.201: Feedback hint beside Start Run

- **[ENTER] for feedback** now sits on the right end of the **Start Run** button, lined up over the COMING SOON tag, instead of on its own row.

## v0.9.200: Warp whirlpools

- The pull zone round each **warp exit** is now **blue** and works like a whirlpool: four spiral arms winding tighter as they fall into a dark eye and turning, specks sliding down them faster near the centre, and rings shrinking inward. The arrow and dotted course line stay green.

## v0.9.199: Galaxy map restyle, H boosts home

- The **galaxy map** now matches the rest of the UI: a faint tactical grid with gold corner brackets and a GALAXY MAP header; warp lanes as **marching green dotted lines** like the system map's warp exits (brighter from where you are); systems as dark-glass discs with a faction ring, glow and tick scale; four **gold brackets turning** round the current system; a gold ring on hover; names, faction/asteroid tags, daily income and Philip's waves on **dark pill banners** like the planet labels. The Flagship marker's label is a gold-edged pill.
- **H (home autopilot) always boosts** the whole way, the same as autopilot to a Growth Reward. Shift or WASD takes back control.

## v0.9.198: Shorter hotkey names

- Hotkey bar: **SPACE: Info** (was "Hold: info"), **H: Home** (no longer changes to "Return to Base" in Fleet Mode), **ALT: Secondary** (was "Fire Secondaries").

## v0.9.197: ENTER for feedback on the title screen

- The title menu shows an **[ENTER] for feedback** hint (a keycap like the in-game hotkeys) just above Faction Unlocks' COMING SOON tag. Clicking it opens the feedback panel too.

## v0.9.196: Feedback panel load fix

- Fixed: the feedback panel script failed to load ("Sfx"/"GD" not declared), so Enter did nothing.

## v0.9.195: Feedback button on the end screen

- The end-of-run screen (win or loss) has a **Send feedback** button in the bottom right, fading in with the score. Enter still works there too.

## v0.9.194: Send feedback from anywhere

- Press **Enter** at any time (in a run or on the title screen): the game pauses and a small **Send Feedback** panel opens. Write what happened, optionally tag it (Bug / Idea / Balance / Other) and rate the fun 1 to 5, then **Send** (or Ctrl+Enter). Esc closes it.
- The game attaches the **version, day, run time, system, view, FPS and OS** on its own.
- Notes go to the MarkoLabs feedback form. If you're offline they're **kept and sent next time** the game starts.

## v0.9.193: Tactical build menu, hotkeys for learners

- The **build menu** is restyled in the game's own look instead of gunmetal: dark navy glass with a gold edge and a faint tactical grid, flat grid cells with a thin border (gold on hover), and ships and stations drawn as **green wireframes** like the title screen's tactical display.
- With **Noob Mode off**, the hotkey reminders in the bottom left are hidden (they come back when it's on).

## v0.9.192: Warp lanes you can't miss

- **Warp exits** are bigger and brighter: a glowing green arrow with two pulsing chevrons, a **dotted course line marching out** of the system toward the next one, and the **"TO …" label riding along that line** (kept upright). Around each exit, a **warp-pull effect** the size of the zone that starts a charge: a faint disc, rings sliding inward and arcs swirling round it.
- Xander's "Rebels hide in the rocks" warning now plays in **Haven** only (it was Rebel Rocks).
- Smoother **Flagship Offline**: no more random hologram jumps or frame-to-frame spark flashing, smooth (anti-aliased) lines, steady sparks that cool over time, slower debris, and a gentler fade-in of the score panels.

## v0.9.191: The bleed-out

- When the **Kharkiv dies**, a **record scratch** cuts in, then *all* sound and music **slow down** to a quarter speed, sink under a closing muffle and **bleed away** over about five seconds. Everything is back to normal on a new run or the main menu.

## v0.9.190: Camera really holds still for Xander

- Fixed: during Xander's **lessons** (which pause the game) the camera could still be panned with WASD/arrows and planets clicked, through the paused-game controls. Those now wait until he's done too.

## v0.9.189: Overdrive Tanks nerf

- **Overdrive Tanks**: the boost meter still gets 50% bigger, but now refills **25% faster** (was twice as fast).

## v0.9.188: Flagship Offline

- Losing the Kharkiv now opens on a cinematic in the title screen's hologram style: the **flagship's red wireframe, cut in two by a MAG round**, the halves tumbling slowly apart with sparks spitting from the glowing cut and bits of hull drifting off, under a slowly breathing **F L A G S H I P   O F F L I N E**. After a few seconds the score and the last-10-seconds report fade in over it while the wreck keeps drifting.

## v0.9.187: What killed the Kharkiv

- When the **Kharkiv is lost**, the end screen now shows a **LAST 10 SECONDS** panel beside the score: the total damage it took, and each weapon that hit it (hits, the ships or stations they came from, and damage), biggest first, laid out like the WEAPONS block on the ship cards.
- Fixed stray **{ }** brackets around the credit icon on some cards (the word "credits" inside an icon was being turned into an icon again).

## v0.9.186: No more vanishing MAG rounds

- Fixed: on **auto-fire**, if a MAG's target was destroyed while it was charging, the gun flashed and boomed but **no round came out**. Now the slug still fires, at where the target last was (and can carry on through whatever's behind it).

## v0.9.185: Real flak

- **Flak bursts look like WW2 flak** instead of little explosions: a pin-prick flash, a spray of shrapnel streaks, and a lumpy **pale grey puff with a dark rim** that hangs in space, drifts and thins out over about a second and a half. Pale so it stands out against the black; shrapnel streaks fly well clear of the puff; quieter pop. Damage and blast size are unchanged.

## v0.9.184: MAG Cannon 50 Alloys

- The **MAG Cannon** now costs **50 Alloys + 10 Gas** (was 40 + 10).

## v0.9.183: Faster torpedoes

- **Frigate torpedoes** reload in **10 s** (was 14 s). This goes for Rebel and Sons Frigates too.

## v0.9.182: Pricier MAG Cannon

- The **MAG Cannon** now costs **40 Alloys + 10 Gas** (was 30 Alloys + 1 Gas): a Starbase's Alloys and twice a Battleship's Gas, for a system-wide, 800-damage piercing gun.

## v0.9.181: Camera holds still for Xander

- While a **Xander message or lesson** is on screen, the mouse wheel no longer zooms and the view can't be dragged or panned.

## v0.9.180: Boost feathering removed (for now)

- Took out v0.9.177's early-release boost refill and the orange recharging flash; Boost refills the old way again (2 s wait, then 2 s to full). To be revisited.

## v0.9.179: Shorter blink

- **Blink Drive** jumps **20% shorter** (40% of a full boost's distance, was 50%).

## v0.9.178: Closer Fleet Mode camera

- In **Fleet Mode** you can zoom out **20% less** than before (the RTS camera keeps the full zoom-out). Switching into Fleet Mode while zoomed further out snaps the camera in to the new limit.

## v0.9.177: Feathering the boost

- **Let go of Boost before the meter runs dry** and its cooldown is cut: it starts refilling after **0.4 s** (instead of 2 s), and refills 20% faster. Run it completely empty and you get the old, slower refill until it's full again. Short, well-timed bursts now beat holding Shift down.
- While the boost meter is **recharging** it **flashes orange**; it turns back to blue when it's full.

## v0.9.176: Xander warns about hidden Rebels

- The first time you warp into Rebel Rocks, Xander warns you: "Careful, Commander: Rebels hide in the rocks here. Fly too close and they'll jump you!"

## v0.9.175: Haven's Frigate den

- **Haven** has a second Rebel hideout: **3 Frigates** hidden in another asteroid cluster, alongside the 3 hidden Corvettes. Like them, they spring when you come close or launch a Colony Ship there.

## v0.9.174: Fortress Mars, Rebel ambushes

- **Mars is much tougher**: 3 more **Battleships** and 8 more **Destroyers**. The Battleships and 4 of the Destroyers are a new **home guard that never chases**: anchored round the planet, they turn to face you and fire but never leave their posts. The other 4 Destroyers guard the flanks and do give chase.
- **Rebel Rocks ambushes**: three packs of **3 Frigates** lie hidden in the outer asteroids and spring on any of your ships that come within 16 units (and call their pack in). To balance it, Rebel Rocks has **one** patrol pack of 3 Corvettes instead of two.
- Hidden Rebels anywhere (like Haven's) now also wake up when you get close, not only when shot.

## v0.9.173: Rebel waves come from the Rock

- Rebel waves no longer appear out of nowhere at Sol's lane. Each wave **launches from the Rebel Rock** (in groups a couple of seconds apart), **crosses Rebel Rocks** to the lane toward Sol, **jumps**, and comes out of the lane in Sol about 4 seconds later, then heads for Earth as before.
- The **Construction Ship** no longer always shows a "CS" tag: like other ships, it's only there with Abbreviated Ship Names on (full name while Info is held).
- You get a notice when a wave launches (click it to look at the Rock) and another when it comes out into Sol. If your fleet is in Rebel Rocks, you can catch them on the way.

## v0.9.172: Clearer Mini MAG card, tidy planet labels

- Starbases have **no Mini MAGs** until you take **Mini MAG Batteries** (that was already so); the card now says so plainly: "Arms every Starbase you own with a Mini MAG (+50% range). Take it again for a second and third."
- A damaged planet's **health bar and name** now sit **under** its name banner instead of on top of it.

## v0.9.171: The plinth

- The headless statue now stands on a **stone plinth** with a **gold plaque snapped off halfway: "MAR..."**, and its foot is buried in more scrap (a rusty barrel, a dented riveted plate) instead of ending in a flat edge.

## v0.9.170: The Thinker's remains

- The Arms Dealer's pile now holds what's left of the intro's statue: the **headless Thinker** half buried at the back left, draped with a canvas tarp and a chain hung over his raised hand, and his **stone head on the floor** by the pile, facing you with **X'd-out eyes**. (The wing fin made way for him.)

## v0.9.169: Card titles that fit

- Card names are now as **big as fits** on one line: up to 24 px for short names, shrinking for long ones so a title never pushes the card wider.

## v0.9.168: Hotter entry holes

- MAG hits now blow **white-hot ejecta, a small puff of fire and nearly twice the sparks** back out of the **entry hole** too, as well as out of the exit.

## v0.9.167: One asteroid warning

- Xander no longer gives his plain text warning when you order the fleet onto a resource asteroid; the animated **ASTEROIDS** lesson (when you break a rock worth mining) is the only one now.

## v0.9.166: Gold-framed tutorial buttons, bigger card text

- **Cards: bigger text and icons**: descriptions 17 px (was 15) with resource icons 60% bigger, prices 20 px (was 16) with a bigger coin, and the picked/rarity line 13 px.
- The start-of-run tutorial's **NEXT** and **GOT IT** buttons now have a **gold frame** like Xander's GOT IT: dark fill, gold border and text, glowing brighter on hover.

## v0.9.165: Shiny scrap

- The Arms Dealer's scrap pile **sparkles**: little four-point glints pop on rivets, plate edges, the gear, the pipe, the thruster and the crate, each on its own beat, and a sheen slides across the cracked canopy glass every few seconds.

## v0.9.164: Objectives

- Holding **Space (Info)** now shows the run's two **objectives** in the top left, in small text with check boxes: **Destroy the Rock Rebels** and **Retake Mars**. Each gets a green tick (and is struck through) when it's done.

## v0.9.163: MAG slugs go *through*

- A MAG slug now disappears while it's inside the hull it's punching through, and its bright streak **breaks at the entry hole and starts again at the exit hole** (no more line drawn across the outside of the ship). The impact effects sit on the real entry and exit points along the slug's path.

## v0.9.162: Resource icons on cards

- Card descriptions now show resources as their **icons**: "¢1" is the credit coin and 1, and the words Alloy(s), Gas and Credit(s) become the Alloy, Gas and Credit icons ("Gas Giants" stays a word).

## v0.9.161: MAG impacts with oomph

- Every MAG-family slug (Mini MAG, MAG, MAG Cannon, PD MAG) now **visibly punches through** what it hits: a flash and **sparks with torn metal** kicked back out of the entry hole, and a cone of **fire and white-hot ejecta** blown out of the exit hole along the slug's path, settling into smoke. Bigger slugs make a bigger mess. Only drawn when it's on screen.

## v0.9.160: Armored rock bases

- The **Tech Lab asteroid** and the **Rebel Rock** now have the same **3 rock armor** as every other asteroid: 3 less damage per hit, never below 1, with grey damage numbers. (Plain, Gas, Silver and Gold asteroids already had it.)

## v0.9.159: Pixel Arms Dealer, living logo

- The **Arms Dealer is now pixel art** like Xander (chunky 3x3 pixels, 1-pixel outlines), and the little ball on the antenna beside him **blinks green like a nav light**. His coin is bigger.
- The intro's **MARKOLABS** now moves like **SURVIVORS** on the title screen: a wave through the letters, a sweeping sheen, a soft glow, and a letter that flickers now and then like a damaged sign.

## v0.9.158: Meet the Arms Dealer

- The shop screen now shows **the Arms Dealer himself** on the left: a scrap goblin squatting on a pile of wrecked ship parts (a wing fin, a burnt-out thruster, a cracked canopy, pipes, a gear, a hazard-striped panel, a crate), wrench in one hand, flipping a coin with the other. He breathes, blinks and tilts his head. Drawn in code in the game's flat style.

## v0.9.157: Intro, straight to work

- The goblin no longer hops onto the statue's head: two jumps (the rock, then up onto his back), a quick wave, and he starts swinging. The intro is now about 7.5 s.
- **Atmosphere**: slow drifting smoke that glows where the spotlight cuts through it, dust motes falling in the beam, and the title screen's grit (film grain, faint scanlines, dark vignette).

## v0.9.156: Smoother, shorter intro

- The intro now renders at **full resolution with anti-aliasing** (was chunky 480x270 pixels), with thinner outlines.
- **No ladder**: the goblin hops up Mario-style (rock, back, onto the head, with a little *bwip* each jump), waves from the top of the head, drops behind it and gets to work.
- **About 2 seconds shorter** (8.3 s, was 10.3 s).
- Settings: the "F11 also switches fullscreen" line is gone; it's now the **Fullscreen** checkbox's mouse-over tip.
- Xander's window: **bigger GOT IT, X and other buttons**, easier to hit.
- On card screens, Xander's explanations now sit **at the very bottom of the screen** (over the Redraw button) instead of under the cards, so the cards stay put and are easier to read.

## v0.9.155: MarkoLabs developer intro

- A short **developer intro** now plays at launch, before the main menu: a statue thinking in a spotlight, a space goblin with a ladder and a pickaxe, three tinks and a rolling head. **MARKOLABS presents.**
- Drawn in code as chunky pixel art (no image files), with its own sound effects (`sounds/intro_*.wav`).
- **Any key or click skips it.** Settings has a new **Skip developer intro** toggle to turn it off for good.

## v0.9.154: System-wide MAG Cannon, shorter station Mini MAGs

- The **MAG Cannon now reaches its whole system** (was 90 units): it picks out the strongest enemy ship anywhere in the system.
- It also **starts charging the moment an enemy shows up** (it used to wait up to ~5 s first, a delay meant to keep stacked guns out of sync).
- **Starbase Mini MAGs reach +50%** further than a ship's (45 units), instead of double like the other station guns.

## v0.9.153: Redraw button lower

- The gold **Redraw** button now sits down near the bottom of the card screen instead of right under the cards.

## v0.9.152: Three notifications at most

- Notifications stack **up to 3** (was 5); a new one pushes the oldest out.

## v0.9.151: Planets can fall, Earth falling loses the run

- **Every settled planet has 3,000 health**, the same as a Starbase (Mars too, was 2,000). Enemy ships now shoot your planets, and they repair 2.5% a second once the fighting's over, like stations.
- A damaged planet shows a health bar: **green for yours**, red for theirs.
- **If one of your colonies falls**, its pops, Cities and buildings (and any PD MAG on it) are lost and it becomes an empty planet you can settle again.
- **If Earth falls, the run is over** ("EARTH HAS FALLEN"). Losing the Kharkiv still ends it too.
- Your planets under fire get a warning arrow and a notice; Earth's warns you it's game over if it falls, and Xander shouts the first time.
- Only Mars fires back (its PD MAG); your planets defend with PD MAG buildings and Starbases.

## v0.9.150: Narrower MAG slugs

- MAG-family slugs (Mini MAG, MAG, MAG Cannon, PD MAG) cut a **narrower path**: their hitbox is 1.5x a normal shot's (was 2x) and the splash off each hit reaches 1 unit (was 1.5). With the bigger ships they were catching too many Corvettes at once.

## v0.9.149: Rising +numbers on the top bar

- Whenever Alloys, Gas or Credits go up, a little green **+N floats up** from that number in the top bar and fades. Gains that land at the same moment add up into one number.

## v0.9.148: Bigger top bar icons, clearer credit coin

- The Alloys, Gas and Credits icons in the top bar are **25% bigger** (30 px, was 24).
- The credit coin's **C is bigger, bolder and darker**, and the line through it is thinner, so it reads as a C at a glance everywhere the coin shows.

## v0.9.147: Cleaner card screens

- Removed the "Click a card to take it. Hold SPACE for card numbers." line from under every card screen.

## v0.9.146: Credit sign everywhere

- Every **$** in the game's text is now **¢**, the credit sign (a C with a line through it, like the icon): floating "+¢1" pickups, colony costs, Xander's tips, Trade Networks and Customs Office cards, card art, the Arms Dealer and the City tag.

## v0.9.145: Rock armor

- **Asteroids have 3 armor**: every hit on a rock does 3 less damage, but **never less than 1** (a PDC's 4 does 1, a Gatling's 10 does 7, big hits barely notice). Their damage numbers show grey.
- The same floor now applies to ship Armor Hardening: a hit always does at least 1.

## v0.9.144: 20 starting Alloys

- You now **start with 20 Alloys** (was 10) to help early pacing.

## v0.9.143: Zoom back out, daily totals on the maps

- **Max zoom-out is back** to 0.25 (about 4x), as before v0.9.136.
- **Zoomed out in a system** (zoom 0.5 or less), a plate near the top of the system shows **everything it makes for you each day**, with resource icons ("PER DAY  {alloys}+12  {gas}+3  {credits}+8").
- **Galaxy view**: under each system's name, its daily take in green with icons.

## v0.9.142: Heavy guns take turns

- **Ships with several of the same heavy gun** (extra MAGs from cards and the like) now fire them **in turn** instead of all at once: each waits its share of the reload after the last one went (a ship with 2 MAGs fires one every ~3 s instead of both every 6 s).
- **Station guns** (Mini MAG Batteries, MAG Cannons, PD MAGs) start their reload at a random point, wait a random moment before opening up on a newly arrived enemy, and reload with a little jitter, so the guns on one station don't fire as a single volley.

## v0.9.141: Credit sign

- The **Credits icon** (gold coin) now shows a **C with a line through it** instead of a $, everywhere the icon appears (top bar, prices, Redraw button, tips).

## v0.9.140: Redraw card rewards

- Every card reward screen (Growth, Fleet and Tech rewards) has a gold **REDRAW** button under the cards showing its price in credits: pay it and the same reward deals **three fresh cards**.
- The first Redraw in a run costs **$50**, and the price **doubles** every time you use one ($50, $100, $200...). Greyed out when you can't afford it.

## v0.9.139: Clearer asteroid warning

- Xander's asteroid lines now say it plainly: shooting one, **you'll only get its resources once, instead of every day**; build a Starbase near the rocks to get them daily.

## v0.9.138: Green gas giant plumes

- Gas giant plumes are now **green** like the gas rocks' puffs, whatever colour the giant is.

## v0.9.137: Bigger stations, faster RTS camera with Shift

- **Space stations are 25% bigger**: Starbases, Shipyards and MAG Cannons (the platform and its huge gun) draw larger, their hitboxes and health bars grow to match, and their gun mounts spread out with them.
- **RTS Cam**: holding **Shift** pans the camera **60% faster**.

## v0.9.136: Bigger ships again, less zoom-out

- **Every ship is another 15% bigger**: Small 24.5, Medium 38.4, Large 54.9 px (were 21.3 / 33.4 / 47.7), the Kharkiv 68.8 (was 59.8), fighters 13.9 (was 12.1).
- **Maximum zoom-out reduced slightly**: 0.3 (was 0.25), so fully zoomed out shows about 3.3x instead of 4x.

## v0.9.135: Venting gas

- **Gas asteroids** now vent a soft green puff of gas from a random spot on their surface every 2-5 seconds.
- **Gas giants** vent big, slow tan plumes from their edge every couple of seconds.
- Puffs only spawn for rocks on screen (gas giants vent while you're in their system).

## v0.9.134: Boost key in the hotkey grid, with a meter

- The **SHIFT Boost** key moved from the bottom centre into the **hotkey grid** at the bottom left, same size as the others.
- A **little boost bar** sits under it: blue, brighter while boosting, darker while refilling.

## v0.9.133: Coloured damage numbers

- Damage numbers now say a bit more:
  - **Yellow**: the hit got a weapon's bonus against that ship type (Gatling +50% vs Small, Mini MAG +50% vs Medium and Large).
  - **Grey**: Armor Hardening or Shield Hardening cut the hit (your Battleships and Kharkiv, Philip's shield wall).
  - Hardened wins if both. Otherwise white for your hits and red for damage you take, as before.

## v0.9.132: Bigger shield wall, Battleships too, frontal arc only

- **Sons Destroyers: 600 shields** (was 300).
- **Sons Battleships get the same shield wall**: 600 shields, Shield Hardening 5 (50% off), MAGs punch through (halved while it's up).
- The shield now **only covers a 140-degree arc in front of the ship** (70 degrees either side of the nose). Hits from outside the arc skip the shield entirely and land on armor and hull at full damage (Destroyers in the line still take 150% from behind).
- Drawn as a bright curved plate across the front arc instead of a full bubble (replaces the old gold phalanx arc).

## v0.9.131: Philip's shield wall

- **Sons of Philip Destroyers** now carry **300 shields** (plus whatever Philip's shield cards add) with **Shield Hardening 5** (10% per point = **50% off**) against hits from the **front half**. Hits from the sides and behind aren't hardened, and hits from behind still do **150%**.
- **MAGs punch through** their shield: MAG, Mini MAG, MAG Cannon and PD MAG hits skip the shield and go straight into armor and hull, though the hardening still **halves** them from the front while the shield is up (a MAG from the front: 250; from behind: 750, a kill).
- The old phalanx rule (50% off all frontal damage) is replaced by the shield wall.

## v0.9.130: Coming features

- **"Working Card Rarities"** added to the Coming Features list on the title screen.

## v0.9.129: Mini MAG Batteries stack

- **Mini MAG Batteries** now adds **1 Mini MAG** to every Starbase of yours (was 2), and can be taken **up to 3 times**: 1, then 2, then 3 Mini MAGs per Starbase. Existing Starbases get the new gun the moment you take the card.

## v0.9.128: Simpler asteroid lines from Xander

- Xander's asteroid lines are plainer: shooting one gives you its resources right away and a new rock shows up later; for resources every day, build a Starbase near the rocks.

## v0.9.127: Alt fires the heavy weapons, Mini MAG Batteries

- **Alt (secondary fire) now covers every heavy weapon** in your fleet, not just MAGs. While Alt is held and you click:
  - **MAG / Mini MAG** (Kharkiv, Battleships, Destroyers): fire at the reticle, as before.
  - **Torpedoes** (Frigates): launch at the enemy ship nearest the reticle (they home in).
  - **Swarm Missiles** (Cruisers): the radar sweeps towards the reticle; nothing locked, the salvo fans out in an arc there.
  - **Fighters** (Carriers): unchanged.
  - **Gatlings, PDCs and Flak hold fire** while Alt is down.
  - The label under the reticle lists what's firing (e.g. "MAG + TORPEDOES + MISSILES + FIGHTERS").
- **New tech card: Mini MAG Batteries**: every Starbase of yours mounts **2 Mini MAGs** (double range like all station guns, +50% vs Medium and Large ships). Starbases you already have get theirs the moment you take it.

## v0.9.126: Heavier large ships, all-round Cruiser radar (test)

- **Large ships and the Kharkiv turn at half the rate** (Carriers, Battleships, the flagship; yours and the enemy's). In formation, Carriers and Battleships turn at 1.0 rad/s (was 1.6). Smaller ships are unchanged. Under test.
- **Cruiser radar** no longer only looks ahead: when you're not aiming by hand it sweeps a **180-degree half centred on the nearest enemy ship in range, whichever way it is**, behind included. When you aim by hand it still sweeps towards your aim.

## v0.9.125: City +5

- **City** now gives **+5 pop capacity** (was +6). Planets that already have a City keep the room they were given; new Cities give 5.

## v0.9.124: Station labels follow the ship-name setting

- **Starbases, Shipyards, MAG Cannons and the Arms Dealer** no longer show their short codes (SB, SY, MAG, AD $) all the time. Like ships: **full names while Info (Space) is held**, short codes only with **Settings > Abbreviated Ship Names**, otherwise no label. (The Rebel Rock's name and health stay.)

## v0.9.123: Shorter blinks, boost left over

- **Blinks cover half the distance** (half a full boost's flight, was a full one), with Blink Drive and Blink Drive II alike.
- **Blink Drive** still needs a full meter to blink, but now **leaves half the boost meter** afterwards (was empty), so you can boost straight out of a blink. Blink Drive II still costs no boost (5 s cooldown).

## v0.9.122: Main menu nudged left

- The **main menu** (logo, buttons and the Space 4 Dummies book that sits on it) moved **90 px further left** (200 → 110 px from the edge); the Settings panel that opens beside it moved with it.

## v0.9.121: Top bar tips on hover

- The plain-words descriptions for the top bar (Alloys, Gas, Credits, Space Stations, Fleet XP, Cards, Day) no longer appear as a strip while Space is held. Each now pops up **only while you hover that item**, in a small box just under it.

## v0.9.120: Battleship Armor Hardening, trait badge

- **Battleships get Armor Hardening +1**: every hit on their armor does 1 less damage (like the Kharkiv). Small, fast guns (Gatling 10, flak 6, PDC 4 per hit) lose a big share against them; big hits barely notice. Enemy Battleships too.
- **Ship info cards** (build menu and fleet panel, bottom right) show traits: Armor Hardening gets a **shiny shield badge** (polished steel, gold rim, a "+" plate and a glint sweeping across), its name in gold and a plain-words description beside it (also as a hover tooltip where the card can be hovered).

## v0.9.119: Even fighter wings fly a proper shape

- Fighter wings with an **even** number of fighters no longer fly a lopsided V: the odd one out sits **straight behind the lead**, closing the shape (a wing of 4 flies a **diamond**). Odd-numbered wings (e.g. 5 with a Wingmen card) still fly a full V.

## v0.9.118: One fighter wing per Carrier, wings of 4 everywhere

- **Carriers have one Fighter Bay** (was two), so 4 fighters instead of 6. Their damage per Alloy comes down from roughly double every other ship to in line with them.
- **Every fighter wing is now 4 fighters**, Carriers and Starbases alike, yours and the enemy's (was 3), so fighter weapon systems match between ships and stations.
- Rebuild time unchanged (15 s per lost fighter). Carrier description updated.

## v0.9.117: Cruisers need Gas

- **Cruisers now cost 20 Alloys + 2 Gas** (missile fuel). They're the first warship that needs Gas, so gas rocks near a Starbase, Gas Giant Siphons and ice worlds matter from mid-game, not just for Carriers and Battleships. Enemy Cruisers are unaffected.

## v0.9.116: Cruiser reach, fewer but bigger missiles

- **Cruisers reach 50% further with every weapon**: Gatling 45, Flak 31.5, Swarm Missiles and radar 45 (the radar was 66, reined in to match). Enemy Cruisers too.
- **Swarm salvos redesigned for performance**: **4 big missiles** instead of 10 small ones. Each hits for **62** (was 25), so a salvo still does about the same total, and the blast is much wider (**2.0** units, was 1.2: nearly 3x the area). Fuel 3.2 s to match the 45 range.
- **Bigger Swarms** (fleet card) now adds **+1** missile a salvo (was +2, which would be +50% now).
- Missiles leave a thinner smoke trail, none at all off screen, and don't redraw off screen.

## v0.9.115: Waves arrive in groups

- **Rebel waves now pour in through the lane in groups of 8, 2 seconds apart**, with the Frigates arriving together in the last group(s). Smoother than 40+ ships appearing on one frame, and it reads as a wave rolling in. (The groups wait while the game is paused, and stop if the run is over.)
- Xander's torpedo warning now comes when the Frigates actually arrive.

## v0.9.114: Performance with big waves

Aimed at the slowdown when 25+ ships are on the map:
- **Enemy AI looks for targets about 4 times a second** instead of every frame (staggered across the wave, and a target that dies or flies off is dropped at once). Each of those searches checks every ship, missile and station in the system, so with a big wave this was the main cost.
- **Ships off screen stop redrawing** and catch up the moment they come into view.
- **Ship-to-ship spacing and ramming checks** reject far-apart pairs with one cheap test first (this runs for every pair of ships, every frame).

## v0.9.113: Dud missiles

- About **1 Swarm Missile in 100 is a dud**: partway out its guidance fails, it **spins out of control** faster and faster trailing dark smoke, then **blows up** on its own a second or so later (any enemy caught in the blast still takes damage).

## v0.9.112: Bigger ships

- **Every ship is 15% bigger**: Small 21.3, Medium 33.4, Large 47.7 px (were 18.5 / 29 / 41.5), the Kharkiv 60 (was 52), fighters 12.1 (was 10.5). Hitboxes, health bars and labels grow with them.

## v0.9.111: No more "!" over enemy ships

- Enemy ships no longer show a red **"!"** when they charge at you (it flagged ships that had been shot and were coming for the attacker). With names on (Space or Abbreviated Ship Names) a charging enemy's label still turns red. The "!" on torpedoes heading for your Kharkiv and on armed mines stays.

## v0.9.110: Shooting mining rocks pays out

- **Shooting an Alloy or Gas asteroid now gives you its load instantly** (its Alloys and Gas, plus the usual $1), shown in the floating text.
- The catch: a mining rock **you** destroy takes **30% longer** to drift back in. (Asteroid Fields still never refill.)
- Xander's asteroid lines updated to match.

## v0.9.109: Destroyers hunt big ships

- **Mini MAG** (Destroyers): **+50% damage against Medium and Large ships** (375 a hit instead of 250), mirroring the Gatling's bonus against Small ships, and it **fires every 7 s** (was 10). Roughly 2.5x the damage it used to do to Cruisers, Carriers, Battleships and capital ships. Its description now calls it the Big-Ship Hunter.

## v0.9.108: Rebel waves: Frigates, not more Corvettes

- **Rebel waves keep their old Corvette counts** (8, 16, 32, 44, 56...). The firepower Corvettes lost (one Gatling now) is made up with **more Frigates** instead: **3, 6, 11, 15, 20...** (about a third of a Frigate per Corvette), flying at the back of the pack. Expect a lot more torpedoes: shoot them down or boost clear.

## v0.9.107: Cheap Corvettes, Frigates in Rebel waves

- **Corvette costs 3 Alloys** (was 5): a cheap swarm ship again now that it carries one Gatling.
- **Rebel waves are bigger and mixed**: 1.5x the Corvettes (12, 24, 48, 66, 84...) plus **Frigates at the back of the pack** (1, 2, 4, 5, 7...), so you meet torpedoes from the very first wave. The wave timer and the notice name both.
- **Xander** speaks up at the first wave with Frigates: they fire big, slow homing torpedoes, so shoot them down or **boost (SHIFT)** out of the way.

## v0.9.106: Leaner loadouts

- **Corvette**: one Gatling (was two). Its two sponsons still take turns firing.
- **Frigate**: Torpedo + **PDC** (was Torpedo + Gatling). The PDC is short-range and fast, good against fighters and incoming missiles.
- **Cruiser**: Swarm Missiles + Gatling + **one** Flak cannon (was three).
- These are shared loadouts, so **Rebel and Sons Corvettes, Frigates and Cruisers change the same way** (Rebel waves hit noticeably softer).
- Ship descriptions updated.

## v0.9.105: Damage per weapon

- Your ships' info cards (fleet panel, bottom right, or Space over the ship) now list **each weapon's damage dealt** on the right of its row in the WEAPONS block, in gold. Anything not from a weapon (rams, blasts) shows on an "Other" line if there is any. A Carrier's Fighter Bay row has no number: each fighter keeps its own record.

## v0.9.104: Long-range Cruiser missiles, snaking flight

- **Cruiser radar and Swarm Missile range more than doubled**: 66 units (was 30). Missile fuel raised to 4.2 s (was 2.8) so they can actually reach that far. AI Cruisers now also hold back further, using their missiles as a long-range weapon.
- **Swarm Missiles fly in a snake pattern**: each weaves side to side around its course, out of step with the others, and straightens out over the last few units so it still lands.
- **Manual fire with nothing locked** now fans the salvo out in an **even arc** across your aim (left to right, rippling out one after another) instead of a random spray. Each missile holds its line a moment, then hunts whatever it passes.

## v0.9.103: Louder planet gather

- The **bubbly gather sound** when a planet brings in resources is a bit louder: -4 dB (was -8). It still fades with distance like other world sounds.

## v0.9.102: Build queue badges and refunds

- **Build menu**: each ship button shows an **orange badge in its top-right corner** with how many of that ship are queued (across all your Shipyards).
- **Right-click a ship button** to take one back out of the queue for a **full refund** (Alloys and Gas). It takes the last one you queued, preferring one that's still waiting over one already being built. Works even if the button is greyed out because you can't afford another.

## v0.9.101: Xander's hello, second line

- Xander's hello now adds, on its own line: "I'm also around when you do something... creative."

## v0.9.100: Quieter notifications

- The **notification ping** is quieter: -15 dB (was -10), a bit under half as loud.

## v0.9.99: Shorter hello from Xander

- **Xander's first message** is now one short line: "Hi Commander, I'm Xander! SPACE is your best friend: hold it to see everything." (with the SPACE key). The blue tip text under it is gone.

## v0.9.98: Ship service records

- Hovering a ship in the **fleet panel** (bottom right), or holding Space over one of your ships, now shows its record in gold: **Kills** and **Damage dealt**, the effective damage it has actually landed on enemy ships (shields, armor and hull that came off, no overkill counted).

## v0.9.97: Earth's free Alloy removed

- **Earth no longer makes a free +1 Alloy** a day. It keeps its +$1 as the capital, plus $1 per 2 pops like any terran world. Alloys now come from asteroids, Mining Corps and desert worlds.

## v0.9.96: Card art retuned

- **Cards**: the picture frame is back to the drawing's own shape (no more paper bands above and below), and the drawing is **zoomed in further** so it fills the frame edge to edge. The **description text is bigger** again (15) and gets the room at the bottom.

## v0.9.95: Construction Ships are recycled

- With nothing left to build, the **Construction Ship flies back to the nearest Shipyard** (Earth, if you have no Shipyard) **and is recycled** when it gets there, instead of hanging around. The next station you place launches a fresh one straight away. If you place a new station while it's still heading home, it turns around and takes the job.

## v0.9.94: Colonize banner removed

- The big green **"[C] Colonize ..."** banner in the middle of the screen is gone. The **COLONIZE** button over the planet already says you can settle it.
- The banner now only appears when you **can't** colonize yet, as a smaller note just above the hotkey bar, saying what's missing (e.g. "Can't colonize Haven yet: needs a Starbase in this system").

## v0.9.93: Construction Ship fix, MAG Cannon nerf

- **Fixed: the Construction Ship vanishing.** If it got new orders while it was in the middle of a jump (heading home, then a new station was placed, or the other way round), it came out of warp invisible and stuck, so it looked deleted. Now the jump it's in always finishes, it always comes back out of warp visible, and its new route is planned from the system it's jumping to. A parked Construction Ship also keeps itself drawn.
- **Space MAG Cannon nerfed**: its splash now reaches about **25% less far** (2.4x a normal slug's blast instead of 3.2x) and does **40% of the hit** to everything else in it (was 50%). The direct hit is unchanged (800).

## v0.9.92: Cities grow planets, bigger card art, cruising engines

- **City** (planet card) now gives **+6 pop capacity** on its planet instead of +$1. **One City per planet.** A planet that falls loses its Cities and the room they made.
- **New tech card: Urban Sprawl**: no limit on Cities, so a planet can fill its slots with them.
- **Trade Networks** reworked to fit: each City gives **+$1 per day** (Cities pay nothing without it).
- **Fixed:** planet cards marked "no limit" (City, Mining Corp, Logistics Hub, Space Elevators, Orbital Drydocks, Construction Yards, Tractor Arrays, Bunker Foundry, Customs Office) **never showed up** in Growth Rewards. They do now.
- **Fixed:** Orbital Habitats gave dead worlds pop capacity. Only habitable worlds get the +2 now.
- **All cards**: the doodle art is **bigger** (taller and zoomed in, less empty paper), and the card name and text are **smaller**.
- **The hiss on tutorial pages is gone**: the card/page sound (it had a burst of white noise in it) is now a soft two-note wooden "tock".
- **Cruising engines**: a soft, low engine rumble that swells with the Kharkiv's speed when you fly normally. It drops out under the boost sound and goes silent when you stop or pause.

## v0.9.91: Menacing MAGs, Cruiser spray, info-mode top bar

- **MAG sounds redone** to sound like a railgun, not a laser: the shot is a hard supersonic crack, a sub-bass boom, a ringing barrel, electric crackle and a long rolling rumble (no more "pew" pitch sweep). The **charge** is now capacitors spinning up: a deep throbbing drone with rising hiss and sparks instead of a rising whine.
- **Cruiser radar sweep is half as fast** (1.2 s across the frontal 180 degrees, was 0.6 s).
- **Cruiser missiles with nothing locked**: when you aim by hand and the sweep finds nothing, the salvo still launches, **sprayed wide and at random** (ragged timing, weaving on the way out), and each missile then hunts whatever enemy it passes. Without hand-aiming, an empty sweep still holds fire.
- **Info mode (hold Space)** now puts a strip of plain-words descriptions under the top bar for everything up there: **Alloys, Gas and Credits say what they're spent on**, plus Space Stations, Fleet XP, Cards and the Day timer.

## v0.9.90: One planet window, prettier; reward screen tidied

- **Info mode (hold Space) over a planet** now shows the **same planet window** you get by clicking it: population track, status and income, and the six building slots (just to look at, no clicking).
- **The planet window got a makeover** to match the info cards and the card window: dark glass with a drop shadow and a top edge in the owner's colour, a **small spinning globe** beside the name, owner and world type ("Desert world · 1 Alloy per 3 pops"), a gold rule, and the population, status and buildings each in their own inset block. The population block says when the next income and reward come in.
- **Planet reward screen**: the cards are now **centred**, and the spinning planet with its details sits out on the **left edge** of the screen.
- **Xander's Growth Reward tip** is simpler: "Your planet grew! Pick a building. Grow it more to get more picks."

## v0.9.89: Desert worlds retuned, Growth Rewards follow the pop ratio

- **Desert worlds** now make **1 Alloy per 3 pops** (was per 2).
- **Growth Rewards follow the same count as a world's income**: every **2nd** pop on terran worlds (Earth included, so nothing changes there), every **3rd** pop on desert and ice worlds. The gold ticks on the planet panel's pop track move to match.
- Xander's growth and colonization tips and the growth infographic say so.

## v0.9.88: Planets put their pops to work

- Every colonised planet now earns from its **pops** each tick, by world type:
  - **Terran** (green and blue, Earth too): **$1 per 2 pops**
  - **Desert** (orange and tan, Mars): **1 Alloy per 2 pops**
  - **Ice** (purple): **1 Gas per 3 pops**
  - Dead and molten worlds make nothing from pops.
- This stacks with buildings (Cities, Mining Corps, Gas Refineries, Customs Office) and Earth's own +$1 / +1 Alloy.
- The **planet panel** says what the world makes and when the next unit kicks in (e.g. "Desert world: 1 Alloy per 2 pops · next at 4 pops").
- **Xander's colonization lesson** has a second page explaining what each kind of world makes.

## v0.9.87: Performance pass

- **Planets render far cheaper.** The pixel-planet shader used to run for every screen pixel of a planet (over a million on a big gas giant). It now runs once per planet *pixel* (180 or 240 square) in a small off-screen picture that's scaled up crisp, and skips planets that are off screen. Should look the same.
- **Idle guns** (ships and planet defences) look for targets a few times a second instead of every frame, and the target search checks distance first.
- **Lost torpedoes and swarm missiles** look for a new target ten times a second instead of every frame.
- **Asteroids, pickups, the Arms Dealer, shots, smoke and jet puffs** stop redrawing while they're off screen.
- **Starbases** check for nearby enemies twice a second instead of every frame; **planets** check whether their look changed twice a second.

## v0.9.86: Blink Drive II retuned

- **Blink Drive II**: recharge **5 s** (was 3 s) now that blinks cover a full boost's distance. It still costs no boost, so you can blink and then boost straight after. (Blink Drive I empties the meter, so it can blink about every 4 s but leaves you no boost.)

## v0.9.85: Cruiser radar fixed up (and the Frigate put back)

- The **Cruiser's Swarm Missile radar** now sweeps its whole **frontal 180 degrees** (it used to be a 70-degree wedge pointed at the nearest enemy), **twice as fast** (0.6 s) and much **fainter**. Every ship it locks gets **four bold, blinking corner brackets** that are easy to spot. It only sweeps when there's an enemy ship somewhere in front; aiming by hand still points it where you aim.
- **Frigates are back to how they were**: no front-only rule and no lock delay (v0.9.82 put those on the wrong ship). The big red **"!"** on torpedoes chasing your Kharkiv stays.

## v0.9.84: Longer blinks

- **Blink Drive** now jumps the fleet **as far as a full boost would have flown it** (boosted top speed for a whole meter, about 140 units for the Kharkiv, more with boost-capacity cards) instead of 12 units. It still stops at the system's edge. Card text updated.

## v0.9.83: Arms Dealer prices

- **Arms Dealer** cards now start at **$90** (Good), **$180** (Rare) and **$300** (ULTRA), up from 15 / 35 / 75. Prices still go up **50% after every purchase** (Trade Port still takes 20% off).

## v0.9.82: Frigate lock-on, torpedo "!"

- **Frigates** only lock torpedoes on ships in their **frontal 180 degrees**. Before launching they do a **quick, faint radar sweep** across the front (0.35 s), then a **big, bright four-bracket reticle** snaps shut on the target (easy to spot, and it blinks once locked) until the torpedo leaves the tube about 0.85 s after spotting it. Hand-aimed torpedoes fire straight away as before.
- A torpedo coming for **your Kharkiv** now carries a **huge, throbbing red "!"** with a glow, the same size on screen at any zoom.

## v0.9.81: Big ships cost more Gas

- **Carrier**: 25 Alloys + **5 Gas** (was 1). **Battleship**: 30 Alloys + **5 Gas** (was 1). Big ships are now a real Gas commitment. (The Sons of Philip's builds don't use Gas, so they're unaffected.)

## v0.9.80: A glowing PAUSED

- When you pause (P), **PAUSED** now shows big and gold (48 px) with "Press P to resume" under it, in a dark frame with a **glowing gold border that breathes** while the game is paused.

## v0.9.79: Can't-miss prompts

- The green prompt line (e.g. "Colonize Kruger III: needs a Starbase in this system") is much easier to see: **bigger** (22 → 28 px) and brighter, **higher up the screen** (about 300 px from the bottom instead of 150), on a **dark plate with a softly pulsing green border**. The plate only appears while there's a prompt.

## v0.9.78: Starbase first

- Xander's colonization lesson now leads with the Starbase: "Ooh, real estate! But first you need a Starbase in this system. Then fly into the rocket button to settle the planet." Tip: "No Starbase here, no colony. Settling costs 1 pop, Alloys and $."

## v0.9.77: Fresher card reward screens

- Every card reward screen is tidier: a slightly deeper backdrop with a soft band of the reward's colour behind the cards, a bolder outlined title, a short gold rule under it, more breathing room before the cards, and a quiet hint at the bottom ("Click a card to take it. Hold SPACE for card numbers.").
- **Growth Reward** screens now feature **the planet itself**, spinning and animated exactly as in space, on the left, with its details on a card in front of it (tinted to match).

## v0.9.76: Xander shows the SPACE key

- Xander's hello now shows a **3D SPACE keycap** (the same raised style as the key bar) under his line, tapping itself down every so often. Any of his lines can now show keycaps for the keys they mention.

## v0.9.75: The real Earth

- **Earth now has its real continents**, from a world map built into the planet shader: North and South America, Europe, Africa, Asia, Australia, Antarctica, Greenland, the UK and Ireland, Iceland, Japan, Indonesia, the Philippines, New Guinea, New Zealand, Madagascar, Cuba and more.
- Real terrain too: rainforests (Amazon, Congo, Southeast Asia), deserts (Sahara, Arabia, Iran, Gobi, Outback, Kalahari, US Southwest), cooler northern and southern lands, and ice caps. It spins west to east under drifting clouds with a blue atmosphere.

## v0.9.74: SPACE is your best friend

- Xander's first hello now ends with "And remember: SPACE is your best friend!", and his tip says to hold SPACE to see names, weapon ranges and info on everything.

## v0.9.73: Xander picks his battles, glistening rocks, sharper planets

- Xander's asteroid lesson now only triggers when you destroy a rock **worth mining** (Alloys or Gas), not plain rocks or silver/gold.
- **Resource asteroids glisten more**: a soft pulsing aura in their colour (purple for Alloys, green for Gas), a bright glint sliding round the rim, three motes of light circling them, and brighter, more frequent twinkles with 8-point sparkles.
- **Sharper planets**: a finer pixel grid (planets 100 → 180, gas giants 140 → 240) so they sit better with the crisp ship models.

## v0.9.72: Cleaner tutorial pages

- Removed the blue lines of text under the cards on both tutorial pages ("Stronger fleet, bigger economy..." and "Every other key is on the bar...").

## v0.9.71: Tutorial button works

- The title menu's **Tutorial** button is live (no more COMING SOON): it starts a normal run, which is effectively the tutorial for now. An Endless mode will come later.

## v0.9.70: Gather sound

- When resources come in at a planet (its daily income, or a Hauler delivering its cargo), a small, soft **bubbly "gather"** plays: three or four little rising bloops.
- It's a world sound like the others: loudest when you're looking at that planet, fading with distance, and silent for systems you aren't viewing.
- New sound file: `sounds/gather.wav` (Godot imports it when you open the project).

## v0.9.69: Boost sound fix

- Fixed: boosting into a Growth bubble (or anything that pauses the game mid-boost) left the **boost rush playing** through the card screen. The boost sound now goes quiet whenever the game is paused, and comes back if you're still holding boost when play resumes.

## v0.9.68: Read the book

- **Clicking the Space 4 Dummies book now opens the tutorial** (the same pages that play at the start of a run), right there on the title screen.
- Noob Mode moved to a **switch under the book**: a yellow "NOOB MODE" plate and a track that slides a knob across and turns **green (ON)** or **red (OFF)**. It stays in step with the Noob Mode box in Settings. The book's own ON/OFF stamp is gone; its cover now says "TUTORIAL INSIDE", and the hover card explains both.
- The book sits a little higher so the switch fits underneath it.

## v0.9.67: Patch notes in the menu

- The **PATCH NOTES** button moved into the title menu itself: the menu's **bottom-right corner**, on the same row as Quit.

## v0.9.66: Patch notes on the title screen

- A small gold **PATCH NOTES** button sits in the title screen's bottom-right corner, beside the version line. It opens a large, scrollable page with the **last three major revisions** (Planets & Big Guns, A Living Fleet, A Whole New Look), newest first. Close with the button, Esc, or a click outside the page.
- The notes live in `scripts/patch_notes.gd`, so they're easy to update when a big update lands.

## v0.9.65: Planet makeover

- Every **planet and gas giant** is now a slowly **spinning pixel-art sphere**, in the style of Deep-Fold's Pixel Planet Generator (our own shader, `planet_body.gd`):
  - noise-generated land and seas, **drifting clouds**, **polar caps**;
  - **dithered light bands**, lit from the system's centre, with a dark night side;
  - a glowing **atmosphere rim**, brighter on the sunlit side.
- Each world has its own look: **Earth** (blue seas, green continents, white clouds), **Haven** (lush), green worlds, **ocean worlds**, rusty and sandy **deserts**, **Mars** (rust with a thin pink haze), purple **ice** worlds, Haven II's **molten** crust with glowing lava pools, and banded **gas giants** (tan or blue) with turbulence and storms.
- Planetary **shields** now draw on top of the spheres. Banners, buttons and labels are unchanged.

## v0.9.64: A softer card sound

- The **card-appear sound** (card screens, the tutorial, Xander's lessons) was a burst of white noise that hissed, most noticeably on the quiet tutorial screen. It's now a **soft, quiet two-note chime** with no noise in it at all.

## v0.9.63: No more control-hint banner

- The Fleet Mode **control-hint banner** along the top ("FLEET MODE · WASD steer · ...") is gone for good.
- Noob Mode's note in Settings now just reads "Beginner help for new Commanders." Its tooltip and the Space 4 Dummies hover card no longer mention control hints. Noob Mode is now Xander and the start-of-run tutorial.

## v0.9.62: The MAG Cannon gets a real gun

- The **MAG Cannon** station is now the biggest gun in the game:
  - **Platform**: a massive octagonal emplacement (about 4 units across) with armour plates, hazard stripes, blinking warning beacons, a bolted turret ring, and **four bracing pylons** out to the diagonals carrying **capacitor banks** that pulse in turn.
  - **Gun**: an armoured turret block with a counterweight out the back, a faction stripe and a gunner's viewport, and **twin rails over 3 units long**. Nine coils between the rails **light up one by one as it charges**, the viewport glows with it, and a huge **muzzle brake** with side vents caps the end.
  - **Recoil**: when it fires, the whole barrel **kicks back** along its cradle and slowly runs out again.
- Its shots now leave from the end of the new, longer barrel.

## v0.9.61: A living formation

- Ships in formation **fly themselves to their slots** instead of being pinned to the Kharkiv:
  - **Own speed and acceleration**: small ships snap into place, big ones lumber after. A ship far behind gets up to **25% extra speed** to catch up.
  - **Own turn speed**: Corvette fastest, then Frigate, Destroyer/Cruiser, and Carrier/Battleship slowest. They face where they're flying, and the fleet's heading at rest.
  - **A forgiving slot bubble** (1.5 / 2 / 2.5 units for small / medium / large): inside it a ship stops correcting and just drifts, so no jitter.
  - **A bit of life**: each ship reacts a beat late (0.1 to 0.3 s, its own) and sways gently round its slot, so turns and boosts ripple through the fleet instead of moving in lockstep.
- Ships coming back from an escort order **rejoin as soon as they're near their bubble** and fly the last bit themselves, instead of easing onto an exact point.

## v0.9.60: Hauler tally clear of the cars

- A Hauler's green cargo tally now sits **clear behind its last container**, pushed out along the train by its own width plus a gap, so it never overlaps a car and stays readable whichever way the Hauler is heading.

## v0.9.59: A living logo

- The title logo moves now. **SURVIVORS** has a gentle wave running through its letters, a bright sheen sweeping across it every few seconds, and every 4 to 8 seconds one letter flickers like a damaged sign. **STELLAR** stays steady with a soft breathing glow.

## v0.9.58: Credit

- The title screen's bottom-right version line now reads "Prototype build v0.9.58  ·  created by tan da man".

## v0.9.57: Abbreviated Ship Names setting

- New setting, **Abbreviated Ship Names** (title Settings and the pause menu's Settings), **off by default**. Turn it on to bring back the short codes over ships all the time (C, F, D, CR, CA, B, K, and HL over Haulers). Holding **Space** shows full names either way.

## v0.9.56: Haulers show their cargo

- Travelling **Haulers** now always show what they're carrying, no Space needed: each container has its resource icon stencilled on it (Alloys or Gas), and a green tally (like "+Alloys 3  +Gas 1") trails behind the last container.
- The "HL" letters above Haulers are gone too; hold Space to see "Hauler".

## v0.9.55: A much bigger F

- Out of Fleet Mode, the glowing gold **F** key is now **twice the size** (still pulsing), growing up and to the right from the bottom-left corner. Its "Fleet Mode" label moves over to make room. It goes back to normal size in Fleet Mode.

## v0.9.54: Repair Kits fix the whole formation

- Picking up a **Repair Kit** now fully restores **every ship flying in your formation** (armor, hull and shields), not just the Kharkiv. Ships away escorting or returning home don't get it. Each repaired ship shows "+REPAIRED", and the Kharkiv shows "FLEET REPAIRED".

## v0.9.53: Notifications stay put behind Xander

- When Xander pops up, the **notifications no longer slide down** out of his way. They stay where they are and he draws **on top** of them. He still steps aside with them when the build sidebar opens.

## v0.9.52: Gun-barrel Destroyer, no letters over ships

- The **Destroyer** is now a ship bolted to a gun: a long armoured **barrel shroud** runs the full length of the ship with glowing coils down it, two heavy **collar bands** with bolts clamp it on, a **muzzle brake** at the tip, and a compact stern body with fins, bridge and twin engines. Its icon matches.
- **No more letter codes above ships.** Hold **Space** (info) to see their full names. A ship charging at you still shows its red **"!"**.

## v0.9.51: The whole title battle on the tactical display

- The title screen's **Starbase** is now a green wireframe too: glowing ring with windows travelling round it, spokes, an octagon core with a pulsing centre, and outlined solar wings.
- The **Kharkiv** (the flagship firing the MAG) is now a green wireframe of its real in-game silhouette, with its habitat ring and pulsing command core. Its MAG charge-up, slug and impact, and its engine plume triangles (now three, lined up with the model's engines) are unchanged.

## v0.9.50: The book follows Xander

- The **Space 4 Dummies** book on the title screen now shows **OFF** whenever Xander is switched off, including when you sent him away in a run (his X button, or the pause menu's Xander option). That way it's clear why he isn't popping up.
- **Clicking the book ON** turns Noob Mode on *and* brings Xander back, with all his warnings (including any you'd told him to drop).
- The Settings panel's Xander tick box stays in step with the book.

## v0.9.49: Title screen as a tactical sim

- The title screen's small ships now match the **fleet-status display**: glowing wireframe silhouettes with a faint fill, a spine and a cross-brace, flickering slightly. UNE Corvettes and the Cruiser are **green**, the Rebel Corvettes **red**, so the battle reads like a Commander watching a tactical simulation.
- The engine flames, Gatling tracer triangles, lasers, flak and missiles are unchanged. The Kharkiv stays as its full painted model.

## v0.9.48: The Arms Dealer's junkyard

- The **Arms Dealer** is now a big, rugged, lopsided station (about 10 units across) instead of a plain hexagon:
  - a main hull welded from **mismatched patch plates** with rivets, **hazard stripes** and a glowing **hangar door**;
  - the **wreck of an old freighter** bolted on, with a torn-off bow, exposed ribs, a rust streak and one dead porthole;
  - a long **cargo spine stacked with shipping containers** (some two high, some gaps where they've sold): he deals in bulk;
  - a **crane** swinging a container out over the stacks;
  - a **salvaged solar array** with dead cells and a bent wing;
  - **three gun turrets** sweeping slowly, blinking gold dock lights;
  - **scrap tumbling** round the yard side;
  - a neon **"BULK ARMS"** sign (the R is on the blink) with a pulsing green **$**.
- Shop orbit unchanged; the name label sits higher to clear the sign.

## v0.9.47: One-word star names

- Neutral systems now use **simple one-word names** of real nearby stars: Sirius, Vega, Altair, Procyon, Arcturus, Proxima, Barnard, Kapteyn, Wolf, Ross, Ceti, Eridani, Draconis and more (32 in all). Planets still get Roman numerals, like "Vega IV".

## v0.9.46: Real star names

- The two neutral systems are no longer "Neutral Reach" and "Neutral Drift". Each run picks two different **real star systems near Earth** (Tau Ceti, Wolf 359, Epsilon Eridani, Barnard's Star, Kapteyn's Star, Sigma Draconis, TRAPPIST-1 and 31 more).
- Their planets get Halo-style Roman numerals in orbit order from a random start, like "Tau Ceti IV" or "Wolf 359 II".

## v0.9.45: Readable colonize costs

- The cost under a planet's **colonize rocket button** (1 POP · Alloys · $) is much bigger: text 13 → 20 px, with the Alloy and $ icons scaling up with it, in a brighter grey. "COLONIZE" grows to match, and the cost line shown with Space held is 18 px.

## v0.9.44: Reload rings, fixed

- The **reload ring** now shows for every big single shot: MAG-family guns, **Torpedoes** and **Swarm Missiles** (Gatlings, PDCs and Flak stream, so they don't get one).
- Rings sit **off the ship's upper-right corner, clear of the hull** however the ship is turned, one per gun in a row.
- **Bigger**: a 17 px dark disc with a faint rim and a thicker fill arc, so it's easier to read.
- Rings fill accurately with Fleet card cooldown boosts (they use each shot's real reload time).

## v0.9.43: Afterburners

- **Boosting** now lights a big **afterburner** off the stern of every ship in your formation (Kharkiv included): a wide blue-white plume about 2.4x the ship's length, a hot orange flame and white core inside it, three shock diamonds down the plume, a heat glow round the engines, and a flicker. Contrails thicken while you boost.
- Engine flames (boosting or not) now start at the stern of the new ship models instead of under the hull.

## v0.9.42: Shots fly the right way from the first frame

- Gatling rounds, tracers and MAG slugs no longer show a streak poking **backwards** over the ship as they leave the barrel. The streak now grows out of the muzzle, only as long as the shot has actually flown, so the opening of a burst reads as firing forward.
- Corvettes: the hot-barrel glow now shows on both sponson barrel tips.

## v0.9.41: Corvette gun sponsons

- The **Corvette** now has an armoured **gun sponson on each side**: a blister with a turret and a forward-pointing barrel. Its shots come out of the sponson barrel tips, alternating left and right. (The bow turret is gone; a small sensor light sits on the bow instead.)

## v0.9.40: Gunboat Corvette, beefier Kharkiv, bigger ships

- **Corvette**: no more blade wings. It's a conventional little gunboat now: pointed bow, straight sides, square stern, side stripes, a bridge block aft and a gun turret on the bow.
- **Kharkiv**: much thicker and heavier: a broad armoured midship block under a bigger habitat ring, armoured stern sponsons round three engines, flank Gatling turrets and heavy plate seams.
- **All ships ~15% bigger**: Small 18.5 px, Medium 29, Large 41.5, the Kharkiv 52, fighters 10.5. Their hit areas grow with them.

## v0.9.39: New ship designs, clearer Asteroid Field arrival

- **Every ship class has its own model** in the Starbase's design language: armoured grey hulls tinted with the faction colour, ink outlines, a lit edge, plate seams, glowing faction windows, engine glow, a soft shadow and blinking red/green nav lights.
  - **Corvette**: a dagger with long swept blade wings.
  - **Frigate**: a tuning fork, twin torpedo tubes out front.
  - **Destroyer**: a spear, long and thin with a glowing spinal rail.
  - **Cruiser**: a missile barge, racks of missile cells on both flanks, flak turrets down the spine.
  - **Carrier**: a flat-top with a dashed runway, chasing launch lights, a hangar mouth and an island tower to starboard.
  - **Battleship**: an armoured brick with heavy sponsons, four turrets and a bridge block.
  - **Kharkiv**: a ring ship, with the Starbase's habitat ring (windows turning slowly) and its pulsing octagon core.
  - **Colony Ship**: a spine carrying three habitat drums with green windows.
  - The Sons of Philip's dark hulls glow gold; the Rebels' glow orange-red.
- Build-menu and fleet-status silhouettes now match the new models.
- **Arriving in an Asteroid Field system**: the fog lifts straight away, and Xander waits 1.5 seconds so you can see the rocks before he says: "Careful here Commander, destroyed rocks in Asteroid fields never respawn, but there's alot of'm!"

## v0.9.38: Growth tip inside the card window

- Xander's **Growth Rewards** explanation now appears **inside the card choice window** for your first Growth Reward: a strip under the three cards with his portrait, "A Growth Reward! Pick a building for this planet.", a short tip, and the animated growth diagram. Picking a card closes it with the window. It no longer pops up after the pick.
- DON'T WARN ME AGAIN in the strip retires it for good.

## v0.9.37: Big Xander in lessons

- In his lessons, Xander now sits in a **framed box in the top-left of the panel at twice the size** (his eyestalks, brows and bob all scale up), with his line and tip beside him and the animated diagram underneath.
- Quick one-liners (warnings, hello) keep the small side portrait.

## v0.9.36: MAG slugs fly further

- Every **MAG-family slug** (Mini MAG, MAG, MAG Cannon, PD MAG, the Rebel Rock's Mini MAG) now **flies twice as far** before it vanishes, so misses can still hit something further back.
- **Engagement range is unchanged**: guns and AI still start shooting from the same distance as before.

## v0.9.35: Shorter lessons, Growth after the card

- Xander's **Growth Rewards** lesson now pops up **after** your first Planet card has flown into your collection (and after any other queued card screens), not before the pick.
- All his lessons are **simpler**: one short line and one short tip each.
  - Asteroids: "Nice shot. But that rock was worth more alive." / Build a Starbase near rocks and they pay you every day. Shooting one only pays $1.
  - Asteroid Field system: "An Asteroid Field system. Lots of rocks, lots of money." / One Starbase here mines most of a field. No boosting in fields, and broken rocks don't come back.
  - Colonization: "Ooh, real estate! Fly into the rocket button to settle this planet." / Costs 1 pop, Alloys and $. You need a Starbase in this system.
  - Growth Rewards: "Your first Planet card. Nice!" / Planets grow over time. Every 2nd pop drops a gold bubble: fly in for another card.
- Philip warning tips trimmed too.

## v0.9.34: Xander's hello, trimmed

- Xander's opening tip is now just "X sends me away, SOUND mutes my voice." (dropped "I won't take it personally. Much.").

## v0.9.33: Keep it vague

- Xander's early-wake line no longer gives away the 10-minute mark: "You broke the Rebel Rock, so... Da— Philip is awake. The Sons are coming. Now."

## v0.9.32: Da— Philip

- Xander's early-wake line (when you break the Rebel Rock before 9:30) now dodges too: "You broke the Rebel Rock, so... Da— Philip is awake. The Sons are coming now, not at 10:00."

## v0.9.31: Xander changes the subject

- Xander's 9:30 warning now reads: "Heads up, Commander. In 30 seconds the Sons of Philip strike from Mars. Philip is...my...HEY! Let's focus on the more important things here!"

## v0.9.30: Xander warns about Dad

- **30 seconds before the Sons of Philip strike** (9:30), Xander warns you, in his red-eyed alert pose: Philip is his estranged dad, every wave doubles the last, dig in and take Mars to end it.
- If you **break the Rebel Rock before then**, Philip wakes early, so Xander warns you right then instead ("Dad's awake").
- Once per run, Noob Mode only; DON'T WARN ME AGAIN retires it.

## v0.9.29: Xander, in context

- Xander's lesson is split up so each part freezes the game **at the moment it matters**, with its animated diagram:
  - **Asteroids**: the first time you destroy a rock.
  - **Asteroid Field systems**: the first time your fleet arrives in one (one orbit covers most of a field, no boosting in fields, broken rocks never come back).
  - **Colonization**: the first time the Kharkiv is beside a planet you can settle.
  - **Growth Rewards**: when you fly into your first Growth bubble. The lesson plays first, then the Planet card pick opens.
- Each one shows once per run in Noob Mode; DON'T WARN ME AGAIN retires it. Switching Noob Mode off mid-lesson still opens the held-back card pick.

## v0.9.28: Xander's rock lesson

- The first time you **destroy any asteroid**, Xander pauses the game and teaches a **4-page lesson**, each page with its own **animated infographic**:
  1. **Asteroids**: a Starbase orbit mining an Alloy and a Gas rock, a Hauler flying the haul home, versus shooting a rock for $1 and waiting for a new one to drift in.
  2. **Asteroid Fields**: a Starbase orbit sweeping over most of a field, no boosting inside fields, and Asteroid Field systems where broken rocks are gone for good.
  3. **Colonization**: Earth reaching 2 pops, the Kharkiv flying into the rocket button, the slow Colony Ship, settling, and the costs.
  4. **Growth Rewards**: the growth bar filling a step a day, every 2nd pop (a new high) dropping a gold bubble, the Flagship grabbing it and a Planet card flipping out.
- Lesson pages have **< BACK** and **NEXT >** buttons with a page counter; his pop-up widens while teaching. The game unpauses when you finish (unless a card screen, the pause menu or your own pause is holding it).
- Once per run, Noob Mode only, and **DON'T WARN ME AGAIN** retires it for good.

## v0.9.27: Noob Mode settings box

- In **Settings** (title screen and pause menu), Noob Mode now has **its own gold-trimmed box at the bottom**: the **NOOB MODE** header with its On switch, a one-line note (Fleet Mode control hints come with it), and the **Xander** and **Tutorial** options inside. The options fade and lock while Noob Mode is off.
- The title screen's Settings panel sits a little higher so the taller box fits.

## v0.9.26: A chunkier Dummies book

- The **Space 4 Dummies** book is properly 3D now: a back cover and a lined page block along the right and bottom edges, a shaded spine with a crease, a glossy sheen, and a softer layered shadow.
- It **leans further to the right** (about 9° tucked in, up to 18° when it's out).
- **No more overlapping text**: every line on the cover shrinks to fit its space, and "NOOB MODE" and the ON/OFF stamp sit apart on the bottom row.

## v0.9.25: Space 4 Dummies

- The title screen's Noob Mode checkbox is now a **"Space 4 Dummies"** book peeking out from behind the menu's bottom-right corner: yellow cover, black title band, a doodled planet and rocket, a spinning **NEW!** starburst, and an **ON/OFF** stamp.
- **Click the book** to toggle Noob Mode. It slides further out and tips back when on, tucks in (and dims) when off, and pulls out more when you hover.
- **Xander peeks over the top of the book**: he pops up when Noob Mode is on, ducks down to just his eyestalks when it's off, and rises a little more when you hover.
- **Hovering** shows a card listing what Noob Mode switches on (Xander, Fleet Mode hints, the start tutorial) instead of text under the menu.

## v0.9.24: Noob Mode, Xander moves top right

- **Noob Mode** replaces "Beginner UI". It is one switch for all the beginner help: **Xander**, the **Fleet Mode control hints** and the **start-of-run tutorial**. Turn it off and all three stay away.
- Toggle it on the **title screen** (a big gold checkbox under Start Run), in **Settings**, or from the **pause menu's Settings**. Xander and the tutorial each still have their own sub-toggle underneath, greyed out while Noob Mode is off.
- **Xander** is now a compact strip in the **top-right corner**: a smaller portrait, 16 px text, and slim buttons. Notifications slide down under him while he talks, and both step aside when the build sidebar opens.

## v0.9.23: Easy-to-see tutorial checkbox

- The tutorial's **"Don't show this at the start"** checkbox is much easier to see: a big 26 px box with a bright border (gold with a dark tick when checked), larger brighter text, on a softly lit plate that glows gold on hover.

## v0.9.22: Long Range Defender

- The Destroyer's role line now reads **Long Range Defender** (capital D).

## v0.9.21: Xander (test)

- **Xander, Fleet Advisor**, Philip's lost, estranged son, now pops up in the **bottom-left corner**: his animated pixel portrait (bobbing jar, swaying eyestalks, crackling electric eyebrows; red-eyed and twitchy when he's warning you) beside a gold-trimmed dialogue box. His lines type out with little voice blips.
- Two lines to test him with: a **hello** six seconds into a run, and an **asteroid warning** the first time you order your fleet onto a resource rock ("Oh, sure, Commander, shoot the asteroid!...").
- **GOT IT** closes the line; **DON'T WARN ME ABOUT THIS** silences that warning for good; **SOUND/MUTED** mutes his voice; **X** turns him off. Each warning comes up at most once a run. The **Esc menu** has a "Xander, Fleet Advisor" checkbox to bring him back (which also brings back every silenced warning).

## v0.9.20: Calmer film grain

- The title screen's film grain is softer (about half as strong) and changes 10 times a second instead of every frame, so it no longer flickers.

## v0.9.19: Green stat bars, roomier info cards

- **Stat bars on ship cards are green** (one colour for every stat).
- **Info cards are more spread out**: more padding around the edges, more space between every line and section, looser line spacing in descriptions, and more room between stat bars and between weapon rows.

## v0.9.18: Weapons front and centre

- **Ship cards give weapons their own block**: a dark panel headed WEAPONS, one row per weapon with a big gold count (2x), the weapon's name in large type and a short note underneath (e.g. "rapid fire, +50% vs small"). Refit extras are included.
- **The stat bars are one neutral steel colour** instead of a colour per stat.

## v0.9.17: Segmented stat bars

- Ship card stats are now **segmented bars out of 10** (finer than 5 dots), styled like a MOBA health bar: a dark framed trough, filled segments with a light sheen and thin dividers. Each stat has its own colour: **Firepower** red, **Toughness** green, **Speed** blue, **Range** gold.

## v0.9.16: No captions under the top bar

- Holding **Space** no longer puts white caption text under the top bar items (Alloys, Gas, $, Starbases, XP, and so on).

## v0.9.15: Clearer ship cards

- **New, bigger role lines** under each ship's name: Corvette *Raider*, Frigate *Anti Large*, Destroyer *Long Range Defender*, Cruiser *Swarm Missiles & Flak*, Carrier *What do you think it does???*, Battleship *Tank & MAG*.
- **Dotted meters** on every warship card: **Firepower**, **Toughness**, **Speed** and **Range**, each out of five dots compared with the other warships (Firepower includes weapons added by refit cards).
- More spacing between the lines of every info card, for easier reading.

## v0.9.14: Your card collection

- **A little fan of three cards sits beside the Fleet XP bar.** Hover it and it lifts, spreads and tilts back with a gold glow (and a hand cursor); click it to open **YOUR CARDS**.
- **YOUR CARDS** shows every card you've picked this run, grouped into **Fleet**, **Tech** and **Planet Buildings** (all your planets' buildings together), each with how many copies you have, the card art, and its collector number while you hold Space. It scrolls if you have lots. The game pauses while it's open; **Close** or **Esc** shuts it.

## v0.9.13: Bigger build sidebar

- **The build sidebar is bigger** (336 px wide instead of 252): larger cameos (136 x 126), bigger silhouettes, names, costs and build times, a bigger BUILD title and close button, and larger section captions.

## v0.9.12: Smoother edges, sturdier text

- **2D anti-aliasing (4x MSAA) is on**: ship hulls, rings, lines and shapes have smooth edges instead of jaggies, everywhere in the game.
- **All text is a touch bolder**, so it stays crisp when the window scales the game down.
- **Hairline drawing is thicker**: about 50 of the thinnest lines (rings, outlines, beams, trails) went from 1 to 1.5 px and from 1.5 to 2 px.

## v0.9.11: No scrolling while picking cards

- **While any card screen is up** (Fleet, Tech and Growth Reward picks, the Arms Dealer, reward and end screens, and while a picked card flies away), the mouse wheel no longer zooms, right/middle-drag no longer moves the view, and WASD/arrow panning stays off.

## v0.9.10: A grittier title screen

- **The title scene is closer to where the game is heading**: a hard white sun with a long lens flare in the top-right corner; richer nebula clouds in three colours; bigger stars with little diffraction spikes; lit, cratered asteroids and smouldering wreckage drifting through.
- **Earth** has ragged coastlines, a desert and a polar cap, layered cloud streaks, a **night side with city lights**, and a bright atmosphere rim facing the sun.
- **A UNE Starbase** (the new ring model, with blinking lights) hangs in the middle distance.
- **The Kharkiv** is weathered (darker plating, plate seams, grime and scratches), with engine plumes and running lights, and its MAG now **charges, fires and hits** in a loop instead of a constant beam: power runs up the hull, the glow swells, a sparkle, the slug, the impact.
- **A UNE Cruiser** ripple-fires a Swarm Missile salvo that curves into the Rebels; Corvettes have engine flames; flak bursts around the Rebel ships; the lead Rebel ship burns and trails smoke; another Rebel is blown apart (and replaced) every few seconds.
- **Film grain, a faint scanline and a heavy vignette** over the whole scene give it a grittier, filmic look (the menus sit above it, unaffected).

## v0.9.09: Plain COMING SOON tags

- The title screen's **COMING SOON** tags no longer glow: just small and yellow.

## v0.9.08: Glowing COMING SOON tags

- On the title screen, **"COMING SOON"** on Faction Unlocks and Tutorial is now a small yellow tag on the right of the button that glows softly in and out.

## v0.9.07: Card collector numbers

- **Hold Space (Info) on any card screen** and every card shows its collector number in a little gold-ringed circle at the bottom, like a trading card: **F** for Fleet cards, **T** for Tech, **P** for planet buildings (e.g. F3, T12, P5). Handy for pointing at a specific card.

## v0.9.06: Refit and weapon-specialist Fleet cards

**Refits** bolt more weapons onto every ship of a type (the ones already flying too; Rare and ULTRA picks add 2 or 3 times as many):

- **Flak Retrofit**: +1 Flak Cannon on every Corvette.
- **Twin MAG Mount** (max 2): +1 MAG on the Kharkiv (extra barrels sit side by side with the first).
- **Broadside Battery**: +1 MAG on every Battleship.
- **Extra Torpedo Tubes**: +1 Torpedo on every Frigate.
- **PDC Nest**: +1 PDC on every Destroyer.
- **Missile Pods**: +1 Swarm Missiles launcher on every Cruiser.
- **Gun Deck**: +2 Gatlings on every Carrier.

**Weapon specialists**, for leaning into a build:

- **Hot-Loaded MAGs**: MAG and Mini MAG shots +20% damage.
- **Shaped Warheads**: Torpedoes +30% damage, 20% bigger blast.
- **Bigger Swarms**: +2 missiles in every Swarm salvo.
- **Proximity Fuses**: Flak +30% damage.
- **PDC Overdrive**: PDCs fire 25% faster.
- **Wingmen** (max 2): +1 fighter in every fighter wing.

All with scribble art. Also: **planet building slots show the building's animated card art** instead of a two-letter label, and hovering a slot (art or name) shows the full card.

## v0.9.05: Twelve new planet buildings

New Growth Reward buildings, each with its own scribble art:

- **Orbital Drydocks**: ships build 15% faster.
- **Construction Yards**: Construction Ships build stations 25% faster.
- **Repair Gantries** (1): Shipyard repair rings are 50% bigger and heal 50% faster.
- **Tractor Arrays**: Starbase orbits are 10% larger.
- **Bunker Foundry**: +15% Starbase health (existing Starbases too).
- **Drone Docks** (1): Starbases repair your ships inside their orbit.
- **Long-Range Batteries** (1): your station guns reach 25% further.
- **Hangar Crews** (1): Starbase fighters rebuild in 10 s instead of 15.
- **Customs Office**: +$1 per day for every Starbase you own.
- **Hauler Depot** (1): Haulers fly 30% faster.
- **Colony Office** (1): Colony Ships settle 30% faster and cost 2 fewer Alloys.
- **Trade Port** (1): Arms Dealer cards and paid pickups cost 20% less.

(1) = one copy per run. The others stack.

## v0.9.04: Game over screen matches the other menus

- **The end-of-run score screen now looks like the pause menu and the tutorial**: the same slate panel with a gold-trimmed border, rounded corners and a deep drop shadow (plus a red stripe across the top when the run is lost), a shadowed heading, the score rows set into a dark recessed tray, a shadowed TOTAL, and full-size menu buttons (Start a new run, Main menu) with click sounds.

## v0.9.03: Silver and gold stay a mystery

- **Silver and gold asteroids no longer show a "$N · CARD" label.** No value, no hint: shoot one and find out.

## v0.9.02: Coming Features on the title screen

- **Title screen, bottom right**: a "COMING FEATURES" panel listing Pop Happiness, Devastation, Government Types, Different Faction Unlocks, 3D Art & Lighting Engine, and Multiplayer OoOoooOOo 👀.

## v0.9.01: Info cards for everything

- **Hold Space and hover anything in a system** for a detailed card: every ship (yours or theirs, with live hull/armor and weapons), every station, and now **asteroids** (plain, Alloy and Gas rocks, with their daily yield), **planets** (Earth, Mars, your colonies, enemy worlds, empty and uninhabitable planets, with pops and buildings), **gas giants**, the **Rebel Rock**, **derelict Tech Labs**, **Haulers** (with their cargo), **Colony Ships**, **Construction Ships**, **mines**, the **Arms Dealer**, **Fleet card and Tech chip pickups** and **PD MAG fortresses**. Each has a role, a short description, live health where it has some, and its traits.
- **Silver and gold asteroids get no card.** Some things stay a mystery.

## v0.9.00: Cards that fit, calmer card animations, bigger resource icons

- **Every card's text fits its box now.** Twelve long descriptions are reworded shorter (same effects), e.g. *Ram Plating*: "Boosting into enemies damages them, more the faster you go. No crash damage", *Space Elevators*: "Every Shipyard builds one more ship at the same time". Cards also make more room for text: the art is a little shorter, the text is 15 px, and an Arms Dealer price sits on the same row as "New / Picked xN" instead of its own line.
- **Calmer card animations**: every little demo loops more slowly (4 s). The Shipyard's now shows a hull being built with a steady welding spark on one side and a ship being repaired in the green ring (with "+" signs rising) on the other, instead of a blinking green circle; the Starbase's rocks drift slowly round its orbit while a Hauler eases a load home.
- **Resource icons in space are bigger and easier to read**: asteroid labels have bigger icons (on a dark backing disc) and bigger numbers, field totals are larger, and the income icons on planet banners are bigger.

## v0.8.99: Station info cards

- **Hold Space (info) and hover a station** (Starbase, Shipyard, MAG Cannon; yours or the enemy's) for a detailed card beside the mouse, like the ship cards: what it is and whose, a description of what it does, its live health, its traits, and a tiny animation of it at work.

## v0.8.98: Calmer MAG line effects

- **About 30% less line clutter on a charging MAG**: the power rails and their pulses are fainter and thinner (and fewer pulses), 6 light rays instead of 8 and shorter, a shorter, fainter lens-flare streak, and a smaller pre-shot sparkle. The glow, halo, hull wash and flashes are unchanged.

## v0.8.97: PD MAG fortresses

- **Earth no longer gets a free MAG Cannon** (that was a misread). A planet only gets a MAG when you pick the **PD MAG** building for it.
- **A PD MAG now shows up on the planet**: a squat little military fortress on the planet's rim (eight-sided armoured walls with crenellations, four corner towers with firing slits, a tiny flag in your colour) with a turret and a turning MAG barrel on top. It charges at the muzzle and fires from the barrel's tip.
- The MAG Cannon station also fires from its barrel's tip now, and charges there.

## v0.8.96: MAG charge-ups that hit hard

- **Much bigger light on a charging MAG**: the glow washes over the whole ship, a big layered halo swells at the muzzle, light rays turn around it, a long lens-flare streak crosses the barrel, and the flicker speeds up as the charge builds. A white-hot flash fills the muzzle the instant before the shot.
- **Bigger muzzle flash** when it fires (it blooms and fades in a blink), on top of the side blasts.

## v0.8.95: Centred MAG barrels, Earth's MAG Cannon, planet guns that hit

- **MAG barrels sit on each ship's centreline**: out of the middle of the hull and through the nose (no more side mounts), and the shot leaves from the barrel's tip.
- **Earth has a MAG Cannon** on its rim (turret base and turning barrel): charges and fires an 800-damage piercing slug at the strongest enemy ship in reach (90 units), every 8 s.
- **Planet guns now lead moving ships properly.** They were reading a speed the ships don't have, so PD MAGs (and Starbase guns) always aimed where a ship *was*; against anything moving they mostly missed.
- MAG-type guns on planets and stations never waste a shot on a torpedo or missile.

## v0.8.94: Even roomier tutorial

- **Tutorial pages spread out more**: wider panel margins, more room between the heading, the step cards and the bottom line, wider gaps between the cards (and the arrows), more padding inside each card, more space between a card's picture, title and text, and looser line spacing in the card text and the bottom line.

## v0.8.93: Telegraphed MAG shots

- **Every ship with a MAG-family gun has a barrel**: a gunmetal tube sticking out past the nose with a muzzle brake on the end (Destroyers' Mini MAG, Battleships' and the Kharkiv's MAG). Shots now leave from the barrel tip.
- **Charging is much easier to read**: lines of power run up from the rear of the ship into the barrel (more and faster as the charge builds), the charge creeps up the barrel, the muzzle glow swells, and **a spinning sparkle flashes at the barrel just before the shot**.
- **Artillery-style muzzle blast**: when it fires, blasts of air puff out of both sides of the muzzle brake, plus a short flash forward (bigger for the full MAG).

## v0.8.92: C&C-style build sidebar

- **The build menu is now a sidebar that slides in from the top right** (B), Command & Conquer style: a gritty, worn gunmetal slab (speckle, scratches, grime, a few rivets) with a heavy shadow.
- **Compact cameos in a two-column grid**, set into dark recessed trays under **Stations** and **Ships** captions: a big silhouette, the name, the cost, and the build time small in the corner.
- **Hover cards open to the left** of the sidebar, level with the button.
- Notifications slide left out of the way while the sidebar is open.

## v0.8.91: Ship info cards, gunmetal build menu

- **Hover a ship in the fleet status panel** (bottom right): a small card with its class and name, role, a one-line description, live hull/armor (and shields), speed, its weapons and its traits.
- **Hover a build button**: a bigger card above it with the same details (with your Fleet card bonuses applied) plus a **tiny looping animation of how it fights**: Corvettes making attack runs, a Frigate's torpedo arcing in, a Destroyer charging its Mini MAG (and its PDC swatting a fighter), a Cruiser's radar sweep and missile salvo, a Carrier's fighter wing circling a target, Battleship MAG shots, a Starbase's Hauler run, a hull being built in the Shipyard, the MAG Cannon's big slug. Stations get cards too.
- **Gunmetal build menu**: a dark brushed-steel plate with a bevelled top edge, rivets and a hazard stripe; amber stencil "B U I L D" title; buttons are bevelled steel plates (amber edge on hover, pressed-in look when clicked), each with a small silhouette of the ship or station; **Stations** and **Ships** have their own captions. The long instruction line is gone ("hover for details" instead).

## v0.8.90: Cleaner card art, stronger card titles

- **Card art has almost no words now**: just the pictures, plus the odd sound effect (PEW, BONK, BOING, SKRRT, BRRRRRT, *slurp*, *poof*, plop...).
- **Card titles stand out more**: upper case, centred, a little bigger, with a dark outline, a soft glow and an underline in the card's rarity colour.

## v0.8.89: No pan/zoom hint

- The plain "Arrows/drag: pan · Wheel: zoom" text is gone from the key bar (panning and zooming still work the same).

## v0.8.88: Scribble card art

- **Every card has art now**: wacky felt-tip scribbles on cream paper, one silly doodle per card (Tech, planet buildings and Fleet cards), mostly sarcastic. A few: *Deep Core Mining* ("+1 ALLOY ... don't get excited"), *Gas Giant Siphons* (a ship slurping a gas giant through a straw), *Ram Plating* ("BONK"), *Tightened Logistics* ("FREE! ... terms apply"), *Hardened Plating* ("bolted on. good luck."), *Mine Layer* ("plop. plop. plop.").
- The lines "boil" (redraw with a fresh wobble a few times a second) like a hand-drawn cartoon.
- Any card without a drawing yet shows a "?" and "art pending".

## v0.8.87: Cleaner key bar, fleet status (prototype)

- **Key bar compressed into the bottom-left corner**: smaller keys in a two-row grid (Fleet Mode, Build, Galaxy, Home, Fire Secondaries, Info, Pause, plus the pan/zoom hint). **Esc and F11 are gone from the bar** (they still work).
- **Boost (Shift) sits on its own in the bottom middle**, full size.
- **Fleet status (prototype), bottom right**: every ship in your fleet as a wireframe silhouette, StarCraft style. Each shades **green to yellow to red** as it takes damage, flashes white when hit and pulses when it's nearly gone. When a ship is lost its slot turns red, reads **OFFLINE** and flickers out over about 2.5 s (with a blip). The Kharkiv comes first (gold frame), then the biggest ships. **12 ships to a page**; past that, **< 1/2 >** arrows page through. Fighters aren't listed. It hides while the build menu is open.

## v0.8.86: Starbases and Shipyards with some dignity

- **New Starbase model** (bigger and more imposing): a heavy armoured ring on four spokes around a lit octagonal command core, habitat windows in your colour, armour seams, solar wings either side, a slowly turning sensor dish, blinking red/green navigation lights and a soft shadow. Its guns and fighter bay sit on the ring.
- **New Shipyard model** (larger, 2.6 x 1.5 units): a drydock of two truss girders with a lit command block at the back, gold gantry cranes across the bay, guide lights and beacons at the open end. **While it's building**, a hull sits in the dock with welding sparks flickering along it and the cranes glide back and forth.
- **Tutorial**: the planet to colonize now looks habitable (ocean, green continents, clouds, a thin atmosphere), and the Starbase in the picture matches the new model.

## v0.8.85: Tutorial shows the real way to colonize

- **The tutorial no longer says "press C to colonize."** Step 2's picture now shows an empty planet with the **same rocket button that floats over it in-game**, and the Kharkiv flying into it; the text says to fly the Kharkiv into the rocket button. The **B (Build) key moved to the bottom** of the picture.
- The planet info panel for uncolonized planets says the same thing (it also used to say "press C").

## v0.8.84: Roomier tutorial with some depth

- **The start-of-run tutorial (both pages) is more spread out**: more room around the edges, between the heading, the steps and the buttons, between the steps themselves, and between lines of text.
- **Basic depth**: each step is its own raised card (rounded, lit top edge, darker bottom edge, soft shadow), its picture sits in a dark inset frame, the whole panel casts a drop shadow, and the headings, step titles and arrows have a subtle text shadow.

## v0.8.83: Radar sweep, first card sooner

- **Swarm Missiles' lock-on is a radar sweep**: a faint beam sweeps the wedge **from left to right** over **1.2 s** (was 0.6 s), with a short fading afterglow; anything it passes gets locked. The wedge is wider (**70°**, was 45°) and the whole thing is much fainter.
- **Missiles home in tighter the longer they fly** (so they don't circle a target until they run dry), and have a small **proximity fuse** (0.6 units beyond the hull).
- **A missile that misses** (out of fuel or shot down) leaves a small grey puff instead of an explosion, so hits and misses are easy to tell apart.
- **First Fleet card at 15 XP** (was 30), still doubling after (15, 30, 60...).

## v0.8.82: Swarm Missiles prototype

- **Cruisers carry Swarm Missiles** (plus their Gatling and 3 Flak), every faction. In the spirit of Fenix's Purification Salvo:
  - **Radar sweep first**: a 45° wedge pulses out towards the enemy, reaching 30 units over 0.6 s. Every enemy it touches gets a lock reticle (up to one per missile), with a soft blip.
  - **Then the salvo**: **10 missiles** ripple out of the tube, fan out to both sides, and curve in on their locks. Spare missiles go to the toughest locked targets.
  - **No lock, no salvo**: it sweeps again after 1.5 s.
  - **Reticles stay on until the missiles land**: green for yours, red for theirs.
- **Each missile**: 25 damage on contact (half to anything else within 1.2 units), every 6 s. Soft homing (fast, but wide turns), so a hard turn or a boost makes some miss. Runs out of fuel after 2.8 s and fizzles. One hit from anything shoots it down.
- Torpedoes and missiles now share one "ordnance" group: ship AI never chases them, and guns can shoot them down.

## v0.8.81: Torpedo prototype

- **Frigates carry a Torpedo** (plus their Gatling), every faction. One launch every **14 s**, reach 32 units.
- **Slow out of the tube, then a long chase**: it speeds up over 1.4 s to **21.5 units/s**, just under a boosted Kharkiv (23.4). It turns slowly, so a boost or a hard turn can shake it. Fuel lasts **9 s**, then it fizzles.
- **Lock-on warning**: a pulsing red reticle on the ship it's chasing, a faint line back to the torpedo, and a beep that speeds up as it closes in (when it's after your ships).
- **Explodes only on contact** with an enemy: **500 damage at the centre**, falling to 25% at the edge of a 5-unit blast. Out of fuel or shot down: a small pop, no damage.
- **It can be shot down**: 8 health, so Gatlings, PDCs and flak pick it off. Ship AI never chases torpedoes, only its guns shoot at them.

## v0.8.80: Destroyers drop the Gatling

- **Destroyers carry a Mini MAG and a PDC** (no Gatling), every faction.

## v0.8.79: MAG Cannon area damage

- **MAG Cannon slugs are much thicker** (1.8x, with an outer glow) with a **wider hitbox** (1.8x), and their **outer blast** reaches about 3.2x as far (4.9 units) and deals **50%** of the hit (400) to everything it touches (regular MAG slugs: 1.5 units, 30%).

## v0.8.78: Destroyer PDCs, MAG Cannon station

- **Destroyers carry a PDC** (Mini MAG, Gatling, PDC), every faction.
- **New station: MAG Cannon** (build menu, 30 Alloys + 1 Gas, 20 s, 1,500 health, uses a Space Station slot). One huge gun with a turning barrel: it charges for 2.5 s and fires an 800-damage **piercing** slug at the **strongest enemy ship** in reach, every 8 s. Reach 90 units (45, doubled like all station weapons); hold Space to see its range ring.

## v0.8.77: worked rock labels stay in the orbit

- **Info (Space) labels on worked rocks stay inside the Starbase's orbit**: if the usual spot under the rock would poke outside the ring, the label moves to the side of the rock facing the Starbase.
- The field totals go back to their usual spot under each field (they're no longer pulled into the ring).

## v0.8.76: easier-to-see checkboxes

- The **Settings panel** (main menu) and the **Esc menu panel** have a lighter slate background, so the checkboxes stand out.

## v0.8.75: Sol's gas giant on the left, icons in the guide

- **Sol's gas giant always sits at the far left** of the system (was a random spot).
- The **economy guide and gameplay-loop pictures** use the resource icons instead of "$", "ALLOYS" and "GAS".

## v0.8.74: cleaner Gatling fire, boost bar placement

- **Missed shots stop at 1.3x weapon range** (was 2.5x), so stray rounds no longer streak across the system (and no longer land far-off hits).
- **Fewer tracers**: one bright tracer in five Gatling rounds (was one in three), shorter streaks; only 8% of tracers fly on a little further (1.5x, was 35% flying 3.5x).
- Ordinary rounds fade out in 0.25 s (was 0.45).
- Applies to ship and Starbase Gatlings alike.
- The **boost bar always sits below the Flagship's health bar**, at any zoom (it could cover it when zoomed out).

## v0.8.72: icons instead of resource words

- **Resource words are replaced by icons** across the UI: asteroid field totals, the Colonize button and its cost, Hauler cargo, the placement ghost ("NEEDS" + icons), toasts (station and ship costs, refunds, pickup prices), the colonize prompt, the planet screen's colonize cost and income ("per day"), and the arms dealer (card prices, your $, the refresh button).
- **Worked field totals stay inside the Starbase's orbit ring** so they read clearly; unworked totals show grey with greyed icons.
- Any text can now use "{alloys}40", "{gas}1" or "{credits}20" to show an icon.

## v0.8.71: fewer, richer Alloy rocks

- **Alloy rocks are rarer but richer**, for clarity at a glance, with the same Alloys on average (0.73 per rock): 62% plain, 10% one Alloy, 21% two, 7% three (was 45 / 40 / 12 / 3).
- **Every field keeps at least one plain rock** (if all rolled Alloys, the poorest hands its Alloys to the others, same total).
- Sol's fixed 9 Alloys and Rebel Rocks' trim now favour 2s and 3s too: trimming takes from the poorest rocks first, topping up grows rocks that already have Alloys. Your first Starbase's rocks are now a 2 and a 3 among plain rocks (still 5 in all).

## v0.8.70: sparkling resources, smaller small hits

- **Alloy rocks** have brighter purple flecks with a soft glow, and the flecks **twinkle** now and then (a little 4-point sparkle).
- **Gas rocks** have glowing green vents that breathe and sparkle.
- **Smaller damage numbers are a bit smaller** (hits under 10: 15 pt, was 18; under 50: 19, was 22; under 200: 26, was 28). Big hits unchanged.

## v0.8.69: worked yields as icons

- Holding Space, each Alloy or Gas asteroid shows its yield as the **resource icon with the number above it**: **green** when a Starbase is collecting that rock, **grey** (icon greyed out too) when nobody is. Silver and gold rocks keep their "$ · CARD" text. Labels still step apart so they never overlap.
- Resource icons can now be drawn greyed out anywhere.

## v0.8.68: alloy ingots icon

- The **Alloys icon** is now stacked ingots (a pink bar on a teal bar, a small copper ingot behind), after the reference image.

## v0.8.67: icons in floating text and the build menu

- **Harvest and income pop-ups** ("+3 ALLOYS", "+1 GAS", "+$2") now show the resource icon and the number.
- **Build menu (B)**: each card shows the build time, the name, then its cost as resource icons with numbers. Cards you can't afford dim, icons included.

## v0.8.66: gas flame icon

- The **Gas icon** is now a green gas flame (tall leaning tip, small right lobe, dark round notch at the base), after the reference image.

## v0.8.65: gas wisp icon

- The **Gas icon** is now a curling green wisp of gas (an S-shaped plume with a smaller curl beside it) instead of bubbles.

## v0.8.64: top bar captions on Space

- Holding **Space** (info) shows a short caption under each top bar item: Alloys, Gas, $, Space Stations, Fleet XP, the system name, the day counter and the music player.

## v0.8.63: resource icons

- **Stellaris-style resource icons**: $ is a gold coin, Alloys a purple faceted crystal, Gas a cluster of green bubbles. Used in the top bar (icon + number, hover for the name), the income label under each of your planets ("+1" with an icon instead of "+1G"), and the planet screen's income stats.

## v0.8.62: Flak

- **New weapon: Flak Cannon.** Fires 3-shell bursts (6 damage each, 1 s cooldown, range 21) that **burst at the aim point** or on contact, hitting every enemy within 1.5 units. Bursts are explosions, so **fighters can't dodge them**.
- **Cruisers** now carry a Gatling and **3 Flak Cannons** (was a lone Gatling). **Carriers** get **1 Flak Cannon** alongside their Fighter Bays.
- Hand-aimed (left-click) Flak bursts at the reticle.

## v0.8.61: lighter Corvettes

- **Corvettes have 90 health** (30 hull, 60 armour; was 150), for every faction. Two Gatling bursts kill one.

## v0.8.60: Fleet level on a bigger XP bar

- The XP bar shows your **Fleet level** ("FLEET LEVEL 3 · XP 12 / 120"), which goes up each time the bar fills and a Fleet card is earned.
- The bar is bigger again: 380 x 18 px (was 260 x 12), with larger text.

## v0.8.59: Flagship marker on the galaxy map

- The **Flagship marker** on the galaxy map now sits above its system, is much bigger and glows (pulsing blue halo), with "FLAGSHIP · CLICK FOR FLEET MODE" over it. **Clicking it enters Fleet Mode** in that system.

## v0.8.58: no full health bars

- A **full health bar is never shown**. Starbases, Shipyards and besieged planets (Mars) used to show theirs while Space was held even at full health; now, like ships, rocks and bases, a bar only appears once something is damaged.

## v0.8.57: faster fighters

- **Fighters fly at 36 units/s** (was 24), about 60% faster than Corvettes; the V cruises at about 29.

## v0.8.56: Carrier fighters as secondaries

- **Carrier bays reach 80 units**, the same as Starbase bays (was 40).
- **Fighters are a secondary weapon on your Carriers**: hold Alt and click, and every fighter on board launches at the enemy ship nearest the reticle (within 15 units of it), and fighters already out (with ammo left) switch to it. The reticle reads "MAG + FIGHTERS" when a Carrier is in the fleet. Without Alt, Carrier fighters still launch on their own as before.

## v0.8.55: one bay per Starbase

- Starbases have **1 Fighter Bay** (one group of 3 fighters), down from 2. Carriers keep 2.

## v0.8.54: Starbase fighters back

- **Starbases launch fighters again** (2 Fighter Bays each), now with the V formation, 3-round bursts, ammo and evasion.

## v0.8.53: fleet fix

- Fixed: no ships at all since v0.8.50. A type error in the fighter V-formation code (ship.gd line 596) stopped ship.gd from compiling.

## v0.8.52: fleet fix (try)

- Fixed (likely): no ships at all in a run since v0.8.49. ship.gd and fighter_bay.gd loaded each other by fixed paths, which can stop ship.gd from compiling; ship.gd now loads the bay by a path in a variable.

## v0.8.51: fighters on Carriers only

- **Starbases no longer launch fighters** (`STARBASE_BAYS` = 0). Fighters are tested on Carriers only for now; Starbases keep their 2 Gatlings and 4 PDCs at double range.

## v0.8.50: fighters fly in a V

- **Fighter groups fly out in a V**: the lead at the point (at 80% speed), the two wingmen 1.5 units back and to either side, so it's clear there are 3. Within 10 units of the target they **split up** (wingmen to opposite sides) and make their own attack runs, so one explosion can't catch them all. They stay split for the rest of the sortie; if the lead dies on the way in, the wingmen break off at once.

## v0.8.49: Carrier Fighter Bays

- **Carriers carry 2 Fighter Bays** (2 groups of 3 VALK Zeros), launching at enemy ships within 40 units. The bays travel with the Carrier, including through warps; fighters land back on the Carrier wherever it is. If the Carrier dies, its fighters finish their sortie and break up.
- Applies to every faction, so the Sons' Carrier guarding Mars launches fighters too.

## v0.8.48: harder-hitting fighters

- VALK cannon rounds back to **20 damage** each: 60 per 3-round attack, up to 600 per 10-attack sortie. Fighters stay fragile (10 health, 50% dodge vs direct shots).

## v0.8.47: fighter bursts

- **VALK cannons fire 3-round bursts** (8 damage a round, 24 per attack; was a single 20-damage round). Ammo still counts attacks, so each sortie is 10 attacks = 30 rounds, up to 240 damage.

## v0.8.46: fighters evade

- **Fighters dodge half of all direct shots** (Gatlings, PDCs, MAG slugs, other fighters). Explosions always hit them: mine blasts and MAG slug splash (and Flak, once it's back).

## v0.8.45: Rebel Rock drops a pickup

- Destroying **Rebel Rock** drops one random pickup where it stood: 40% a Fleet Card (gold-rock rarity odds; costs $ like other Fleet Card pickups), 30% Tech, 20% a Repair Kit, 10% Secret Tech.

## v0.8.44: gentler first Rebel wave

- Rebel waves start at **8 Corvettes**, then double twice and add 12 a wave: 8, 16, 32, 44, 56, 68, 80...

## v0.8.43: normal starting economy

- Testing resources off: runs start with the normal 10 Alloys, 0 Gas, $0 again (`TEST_START` = 0; set it to 1000 to bring the test start back).

## v0.8.42: Philip at whichever comes first

- **Philip wakes and launches his first wave (24 points) at whichever comes first**: Rebel Rock falling, or the **10:00 mark**. If Rebel Rock still stands at 10:00, Rebel and Philip waves both keep coming. Then Philip doubles every 2 minutes.

## v0.8.41: Philip at 10:00

- Philip's first wave now leaves at the **10:00 mark** (was 9:00), in step with the 2-minute wave rhythm.

## v0.8.40: Philip's first wave at 9:00

- Philip's first wave (24 points) leaves at the **9:00 mark** of the run. If Rebel Rock falls before then, the Sons still wake up (expanding, building) and the wave pill counts down to 9:00; if it falls after 9:00, the wave leaves at once. Then it doubles every 2 minutes as before.

## v0.8.39: Philip as sudden death

- **Philip's first wave** is a fixed **24 points**, launched as soon as Rebel Rock falls (no longer tied to the last Rebel wave).
- **Each Philip's wave doubles** the one before: 24, 48, 96, 192... every 2 minutes, plus any ships his Shipyard built. Once the Rebels are broken, Philip is the clock.

## v0.8.38: Rebel waves double, then climb

- **Rebel waves**: 12 Corvettes at wave 1, doubling for waves 2 and 3 (24, 48), then +12 per wave (60, 72, 84, 96...). Replaces the x1.5 growth. Philip's first wave is still twice the last Rebel wave.

## v0.8.37: Rebel waves grow x1.5

- **Rebel waves grow by 1.5x each wave** (was +3): 6, 9, 14, 20, 30, 46, 68 Corvettes. Philip's first wave is still twice the last Rebel wave.

## v0.8.36: secondaries fire on click

- **Alt (Fire Secondaries)** no longer fires the MAGs by itself. Hold Alt to select them (the reticle shows "MAG"), then **click** to fire them at the reticle, like a normal attack. Alt held without clicking leaves your ships on their normal fire.

## v0.8.35: grab pickups by their glow

- Flying the Flagship into a pickup's glow picks it up (Fleet Cards, Tech, Repair Kits), not just the icon in the middle.

## v0.8.34: bigger Fleet XP bar

- The **Fleet XP bar** in the top bar is longer (260 px, was 150) and thicker (12 px, was 6), in a gold frame.
- When XP comes in, the newly filled stretch flashes bright and the frame glows, then fades.
- Every kill that earns XP pops a **"+1 XP"** (or more) out of the bar.

## v0.8.33: fighter ammo counts attacks

- Fighter ammo now counts **attacks**: each burst uses one, however many rounds it fires. (VALK cannons fire one round per attack today, so play is the same; it stays right if fighters get bursts later.)

## v0.8.32: fighter ammo

- **Fighters carry 10 shots** per sortie (20 damage each, up to 200 per sortie). When the ammo is spent they fly home, land and rearm; they also head home early if no enemy ship is within 25 units. The old 25 s sortie timer is now just a 40 s safety cap.

## v0.8.31: slower fighter rebuilds

- **Fighter Bays rebuild each lost fighter in 15 s** (was 5 s), one at a time, in or out of combat. Fighters that survive and land are still ready to relaunch at once.
- Room left for fighter cards later (faster rebuild, more groups, better fighters).

## v0.8.30: corvette attack runs on stations, 4 PDCs

- **Corvettes make attack runs on buildings** (Starbases, Shipyards, planets' defences) instead of orbiting them tightly at 4 units: they dive in firing, pass the target, peel out to about 2/3 of their range, swing round and come back from the other side. The long straight approaches let station guns lead them properly, and they spend part of each run out of their own range.
- **Starbases now carry 4 PDCs** (was 2), plus the 2 Gatlings and 2 Fighter Bays. Flak may replace the extra 2 PDCs once it's back.

## v0.8.29: Starbase Fighter Bays

- **Every Starbase has 2 Fighter Bays**, each holding a group of 3 VALK Zero fighters (tiny, fast, 10 health, 20-damage cannon). When an enemy ship comes within 80 units (bay range 40, doubled for Starbases), each bay launches its fighters at it. They hunt enemy ships for about 25 s, then fly home and land, ready to launch again. Each fighter lost is rebuilt at the bay in 5 s.
- If the Starbase is destroyed, its fighters fight on until their sortie ends, then break up.
- Applies to every faction's Starbases, so the Sons' Starbases launch fighters at you too (your PDCs and Gatlings get small targets to shoot).
- Fighters don't bump or ram other ships and carry no label or health bar.

## v0.8.28: feel tweaks

- **Low health**: the red screen glow when the Flagship is low is much stronger and wider, and pulses harder the closer it gets to dying.
- **Notification sound** is quieter and plays at most once every 3 s.
- **No sound when a ship is completed** at a Shipyard.
- **F key** is a plain key in Fleet Mode (no blue); outside Fleet Mode it still glows gold.
- **Growth Reward autopilot boosts** the whole way (runs the meter dry, waits for a full refill, boosts again). Pressing **Shift** cancels the autopilot; WASD still does too.

## v0.8.27: menu music

- The game always starts on **Whoa Whoa** at the main menu. After it ends (or you skip), the shuffled playlist carries on as before.

## v0.8.26: menu order

- Main menu: **Settings** now sits under Tutorial (Start Run, Faction Unlocks, Tutorial, Settings, then Quit).

## v0.8.25: F reads "RTS Cam"

- In Fleet Mode the F key on the hotkey bar reads **RTS Cam** (what pressing it does); outside Fleet Mode it reads Fleet Mode.

## v0.8.24: F glows hard

- Out of Fleet Mode, the **F key** on the hotkey bar now glows much more: bright gold tint, a big pulsing gold halo and border, and a slight swell.

## v0.8.23: quieter warp, XP pop-ups optional

- **Warp jump sound** is 30% quieter.
- **"+3 XP" pop-ups over ships** are off by default. Turn on **XP pop-ups on ships** in Settings (main menu or Esc) to see them. The Fleet XP bar in the top bar is unchanged.

## v0.8.22: Beginner UI setting

- The "FLEET MODE · WASD steer · hold left-click to fire · F to leave" hints along the top are hidden by default. Turn on **Beginner UI (control hints)** in Settings (main menu or the Esc menu) to show them again.

## v0.8.21: Starbase range ring

- Holding Space now shows one standard range ring on each Starbase (the same style as ships' rings, in the faction colour) for its longest-reaching weapon (Gatlings, 60 units). The separate gold Gatling and grey PDC rings and their labels are gone.

## v0.8.20: longer boost

- **Boost lasts twice as long** (6 s on a full meter, was 3) and **refills twice as fast** (2 s from empty, was 4). The 2 s pause before it starts refilling is unchanged.

## v0.8.19: Starbases as bastions

- **Starbase guns**: 2 Gatlings and 2 new PDCs (fast 4-round bursts of light rounds, +50% vs Small craft).
- **Double range** for every Starbase weapon: Gatlings reach 60 units (was 30), PDCs 24. Applies to every faction's Starbases.
- **Leading shots**: Starbase guns aim ahead of moving targets so long shots still land.
- **Hold Space** at a Starbase to see its Gatling and PDC range rings.
- Starbase repairs stay off (they'll come on a card).

## v0.8.18: test resources, quieter cards

- **Testing**: every run starts with 1,000 Alloys, Gas and $ (`TEST_START` in game_data.gd; set it to 0 for normal starts).
- **No toast after picking a card** (it used to say "X added" plus a tip).

## v0.8.17: patrol squadrons, "no" sound

- **Patrol squadrons**: all patrol ships in a system fly as one triangle (wedge) formation, biggest ship at the point; new ships take the next spot. The squadron circles the system's main colony (your planet with the most pops, e.g. Earth) at half speed, or loops your stations if there's no colony. When any enemy ship enters the system they break off at full speed and fight, then regroup. When your Flagship arrives they join the fleet at full speed.
- **"Can't do that" sound**: a low two-note "da-dunk" when an action fails: placing a station where it isn't allowed, not enough resources for a station, ship, pickup or dealer card, no Shipyard for ships, colonizing without what it needs, H with no Starbase to return to.

## v0.8.16: building rules, Tightened Logistics

- **Building anywhere**: Starbases and Shipyards can go in any system with no enemy stations or enemy-owned planets (Rebel Rock counts until it falls; Mars while the Sons hold it). Hidden Rebel tech labs don't block building.
- **Colonizing needs a Starbase**: you must have a finished Starbase in the planet's system. The prompt says "needs a Starbase in this system" otherwise.
- **Fleet Card pickups**: start at $20 and go up 25% each time (was $15, +10%).
- **New Fleet card: Tightened Logistics**: no boost drain while your fleet is in a system with your Starbase and no enemy ships or stations. The boost bar turns green while it's working.
- **Asteroid labels (Space)**: back to one label per rock, but labels that would overlap are pushed down a line (with a faint tick back to their rock). Plain rocks still don't show "$1".

## v0.8.15: Philip's waves climb faster

- Each Philip's wave is **6 points** stronger than the last (twice the Rebels' 3), to match the doubled start.

## v0.8.14: Philip strikes at once

- **First Philip's wave launches immediately** when Rebel Rock falls, at **twice the strength of the last Rebel wave** (e.g. last Rebel wave 12 Corvettes = 24 points). Later waves keep the 2-minute gap and grow by 3 points each, plus whatever the Sons' Shipyard built.

## v0.8.13: patrols fixed, orders spread

- **Patrols actually patrol** (in v0.8.12 your ships never ran the patrol AI, so they sat at the Shipyard). They now loop past the system's stations and **hunt any enemy ship that enters their system**, then go back to the loop. They ignore enemy stations, so they won't suicide into a Rebel Rock.
- **Orders are spread across Shipyards**: each ship you order goes to the Shipyard with the shortest queue (nearest to the fleet on a tie).

## v0.8.12: Shipyard patrols and queues

- **Patrols**: a ship finished at a Shipyard in a system without your fleet now patrols a loop past that system's Starbases and Shipyards (circling the station if there's only one). Enemies that come close get the normal ship AI; then it goes back to its route. When the Flagship arrives, it joins the fleet as before.
- **Queue sharing**: a newly built Shipyard takes waiting ships from busier Shipyards' queues until they're even. Ships already under construction stay put.
- **Build menu**: each button shows "BUILD 15s" above the name and cost, using your current build speed (cards included).

## v0.8.11: planet cycling off

- **Planet cycling removed for now** (no key, gone from the hotkey bar). The code stays for later.

## v0.8.10: controls and clean-up

- **Tab opens the Galaxy map** (was G). Planets cycling moved to G (outside Fleet Mode).
- **Alt** is labelled "Fire Secondaries" on the hotkey bar.
- **Ships fire while boosting**: the old hold-fire rule is gone, for your ships' own fire and your aimed fire (left-click focus, Alt).
- **"Flagship critical."** replaces "Kharkiv critical."
- **Growth Rewards**: the notification tells you to fly your Flagship into the gold bubble. Clicking it puts the Flagship on autopilot to that planet's bubble, through warp lanes if needed (WASD cancels).
- **No more "ship built" notifications** (the launch sound still plays).
- **Arms dealer**: each purchase now raises all dealer prices by 50% (was 25%).
- **Galaxy map**: a Flagship icon marks the system your fleet is in.
- **Asteroid info (Space)**: each field shows one combined label (e.g. "7 ALLOYS · 1 GAS") under the group instead of a label per rock, and plain rocks no longer show "$1". Silver and gold rocks still show their $ and CARD.

## v0.8.9: mines, gas giants, boost

- **Mines**: 3 out at a time at base (+2 per extra copy, up to 11). They activate from 10 units away (was 5), glow a much stronger red, and show a big "!" when they launch. Card text trimmed.
- **Gas Giants** pay as soon as a Starbase orbit touches the giant's edge (it used to need the centre inside), and show "+1 GAS" over the giant each day.
- **Boost**: when the meter runs dry it now recharges even while Shift is held; let go and press Shift again to boost. (Before, it kept spending each sliver of refill, so it never recovered, and your ships' fire flickered on and off with it.)
- Fixed: mine blasts could miss ships at the far edge of the 5-unit blast.

## v0.8.8: days and cleaner screens

- **Days**: the top bar shows "DAY n · NEXT 7s". Time survived is now counted in days: the end screen says "Survived 42 days", worth 50 points a day (same as before: a day is 10 s).
- **Music player** is smaller (tighter buttons, narrower title and volume slider).
- **Mine Layer** card text shortened to fit the card.
- **"COLLECTION" and "REPAIRS"** labels on Starbase and Shipyard rings only show while holding Space.
- **Card screens**: the heading sits a little higher, clear of the cards' glow.
- **Planet screen**: Stability hidden for now (still tracked; it comes back later).
- **"+1 POP"** now joins the planet's income text in one stack instead of drawing over it (any texts from the same spot at the same moment stack).

## v0.8.7: tuning and smoothness

- **Sol always has exactly 9 Alloys** in its asteroids (the 5 by your first Starbase are kept first), so you have to expand to grow. Rebel Rocks now holds about 18.
- **Gas Refineries**: a flat +1 Gas per tick (was +1 every 3 ticks).
- **Damage Control**: repairs 1% per second (was 2%).
- **Softer glow** behind Growth Reward bubbles and Colonize buttons.
- **Asteroid health bars** hide 5 s after the rock was last hit, even if it's still damaged.
- **No WASD panning** while a card choice or the arms dealer is open.
- **Arms dealer**: every purchase makes all dealer cards 25% more expensive (stacks for the run).
- **Stutter fix (try it)**: announcer lines now wait their turn instead of cutting each other off (interrupting the speech engine froze the game for a moment), and notification cards share one style.

## v0.8.6: Rebel Rock guns, live mines, gas packs

- **Mine Layer**: 5 mines out at a time (was 8; +2 per extra copy, up to 11). Armed mines pulse red so they don't look like debris. When an enemy comes within 5 units, the mine activates with a red "!" and launches itself at it (fast, up to 2.5 s), exploding on arrival.
- **No Shipyard?** The Construction Ship launches from Earth instead (as long as Earth is yours).
- **Gas asteroid packs**: always 1 Gas rock, sometimes 2, very rarely 3; the pack's other rocks can carry Alloys. Gas packs are also rarer overall.
- **Civilian ships' health bars are green** like your other ships (Haulers now show one too).
- **Rebel Rock** (was "Rebel base"): 8 Gatlings mounted around it stay silent until you attack it, then fire across the whole system.
- **Growth Reward bubbles and Colonize buttons glow from behind** (soft halo and turning rays), so they stand out.
- Space Elevators (Planet card, +1 ship built at once per Shipyard) was already in since v0.7.3.

## v0.8.5: Philip's waves

- **Philip's waves replace the Rebel waves** once the Rebel base falls: every 2 minutes, picking up the Rebels' wave strength (in points: Corvette 1, Frigate 2, Destroyer 3, Cruiser 4, Battleship 6) and growing each wave. The pill at the top shows "PHILIP'S WAVE n · STRENGTH · +BUILT · timer".
- **Built ships join**: every ship the Sons' Shipyard finished since the last wave goes out with it (this replaces the separate strikes). Leave Philip alone and the waves get bigger.
- **Mostly Battleships and Destroyers**: waves are built from about 30% Battleships and 55% Destroyers, and the Shipyard builds 35% Battleships, 45% Destroyers, then a few Frigates and Corvettes.
- **They travel**: a wave leaves Mars and crosses the map lane by lane (a few seconds in each lane). In each system it attacks your nearest station; once nothing of yours is left there, it heads for the nearest system with one of your stations, and finally Earth. Your fleet can catch it on the way. Entering a system where you have something: fleet warning and announcer line. The galaxy map shows a pulsing "PHILIP'S WAVE xN" over the system each wave is in.
- **Pike phalanx**: Sons Destroyers fly with their shields nearly touching, in waves and in the two Mars phalanx lines.

## v0.8.4: Hotkeys tutorial

- **Start-of-run guide, page 2 is now "Important Hotkeys"** (the boxes-and-arrows economy page is gone): three animated pictures in the same style as page 1. Hold SPACE for info (names and weapon ranges appear), F for Fleet Mode (the fleet flies with WASD, then the camera goes free), and hold Right Click to send ships (escorts fly to the reticle, then come home).
- **Galaxy map**: Mars is tagged "SONS OF PHILIP" in gold.

## v0.8.3: The Sons of Philip wake up

- **Sons of Philip AI**: dormant on Mars until you destroy the Rebel base. Then, once a day, they collect income (60 Alloys to start, +4 per planet, +3 per Starbase), build ships at their Mars Shipyard (mostly Destroyers), build Starbases on nearby asteroid fields (gold build sites, up to 4, never in Sol or where you have one), settle empty planets (gold "SONS OF PHILIP SETTLING" bar, you can race them), and strike your nearest planet or station once 6+ new ships are home. They earn cards from your ships they destroy plus one every 5 days, pick armor, hull and shield cards most, and every pick is announced. Their cards only buff Sons ships.
- **Mars garrison**: two phalanx lines (11 Destroyers), a Battleship, a Carrier, 2 Cruisers, 3 Frigates and 6 Corvettes around the Starbase. The garrison always stays home.
- **Rebel Rocks Alloys cut**: still lots of rocks, but their yields add up to about twice Sol's (they never respawn).
- **Title screen**: the menu is pinned to the bottom-left and grows upward, so Quit is never cut off.

# Stellar Survivors: prototype v0.8.0

## v0.8.2: Ready for testers

- **Test values removed**: the Kharkiv no longer starts with 100 shields, and Earth no longer starts with a 500-point planetary shield. Shields now come only from cards (Shield Emitters, Planetary Shields).
- **Every card in the pool now does something:**
  - Efficient Shipyards: -10% ship build time (stacks).
  - Long-Range Sensors: your Starbases sense enemies 2 jumps away instead of 1.
  - Warp Drive Tuning: +50% warp speed, so your fleet's jumps take a third less time.
  - Colony Pods: new colonies settle twice as fast.
  - Fortified Starbases: +25% Starbase health, for the ones you have and the ones you build.
  - Missile Racks and Drone Bay Expansion are out of the pool until missiles and drones exist.

## v0.8.1: Pause menu

- **Esc opens the pause menu** during a run (if a planet panel, the build menu or a station placement is open, Esc closes that first). It pauses the game and offers Resume, Settings, Restart run and Main menu. Esc again resumes.
- **Settings in the pause menu**: Music and Sound effects volume, Damage numbers, Fullscreen, and Show the tutorial at the start of runs. Saved between sessions, same as on the title screen.
- **Title screen Settings**: new "Show the tutorial at the start of runs" checkbox, to turn the start-of-run guide back on.
- ESC is on the hotkey bar.

## v0.8.0: Main menu

- **Title screen** (from the mockup): a live battle behind the menu. Earth on the left, the Kharkiv firing a MAG slug at a Rebel ship, Rebel lasers and UNE Gatling tracers trading fire, twinkling stars and drifting asteroids. The menu sits bottom left: Start Run, Unlocks (coming soon), Settings, Tutorial (coming soon), Quit. The version number is bottom right.
- **Settings** (from the title screen): Music and Sound effects volume, Damage numbers on/off, Fullscreen. They're saved between sessions, and the music slider in the top bar saves too.
- **Music carries on** from the title screen into a run and through restarts instead of starting over.
- **End screen**: "Main menu" next to "Start a new run".
- **Start-of-run guide, page 1: How a run works.** Three small animated pictures with arrows between them: Fly and Fight (WASD, aim, kill for XP, Fleet cards), Build and Expand (B for Starbases and Shipyards, Haulers bringing Alloys home, C to colonize), Grow and Conquer (pops and Growth Rewards, survive the waves, break the Rebel base, take Mars). "Next" goes to page 2, the economy guide.
- **Title screen**: "Faction Unlocks" (coming soon), F11 switches fullscreen, and a fullscreen hint sits in the bottom right.
- The game always opens on the title screen (pressing Play/F5 included), so there's nothing to change in Project Settings.

## Patch 7.4c

- **Damage Control** (Tech card) actually works now, and it's stronger: your ships repair 2% of their hull and armor every second once they haven't been hit for 5 seconds, anywhere in the galaxy, with green "+" signs. (Before, it did nothing.)

## Patch 7.4b

- Gatling overheating is off for now: back to bursts of 10 with a 1.8 s cooldown. (The heat code stays in, switched off: add "heat_rounds" and "overheat" to the Gatling's stats to turn it back on.)
- **Sustained Fire**: Gatling bursts last 0.5 seconds longer (about 22 rounds instead of 10).

## Patch 7.4

- **Gatlings overheat instead of cooling down.** No fixed cooldown: they fire a steady stream (20 rounds a second) while there's a target. Every round heats the barrels. After 20 rounds in a row (1 s) they overheat, vent, and must cool all the way down (2.5 s) before firing again. When they stop firing, they cool as they go. Hot barrels glow red at the tips, and overheated ones pulse. Applies to every ship, enemies included. Station Gatlings are unchanged.
- **Sustained Fire** now means cooler-running Gatlings: 1 more second (20 more rounds) before overheating.
- **Ships no longer retreat on low health**: they fight on until you call them back.
- **The starting Starbase and its asteroids** sit below the star, about halfway to the edge. The fleet starts between it and Earth.
- **Alt** is on the hotkey bar ("Hold: MAGs only") and lights up while held.
- **Station sounds**: zoomed in near any Starbase or Shipyard, you hear faint beeps, clanks and machinery.
- Fixed: an asteroid could fly across the system and snap back into place. A ship resting on a rock added a shove every frame; now it's one shove at a time, and rocks never get knocked more than 3 units.

## Patch 7.3

- **Economy guide**: a big card at the start of every run shows how the economy works in boxes and arrows: Earn (planets, asteroids and Haulers), Grow (pops, Growth Rewards, Tech), Fight (XP to Fleet cards) and Spend (Alloys and $). Tick "Don't show this at the start" to turn it off.
- **Right-click orders**: ships heading back to formation answer a new right-click straight away instead of ignoring it. Badly damaged ships still limp home.
- **F glows** whenever you're out of Fleet Mode.
- **New Tech card, Asteroid Force Fields**: asteroids with yields inside your Starbase orbits get a blue force field and can't be destroyed.
- **New Planet card, Space Elevators** (no limit): every Shipyard builds one more ship at the same time. The Shipyard label shows each ship in progress.
- **Mine blasts are much bigger**: blast radius 5 units (was 3.5), a big fireball, a shock ring and a heavier boom.
- **Thruster puffs** lost their hiss: low rumble only, a little quieter, so they stay out of the way of the hi-hats.

## Patch 7.2: Movement tech and Kharkiv weapons

New Tech cards (one copy each):
- **Blink Drive**: tap Boost while moving and the formation jumps 12 units, with a flash at both ends. Needs a full boost meter and empties it.
- **Blink Drive II** (needs Blink Drive): blinks are free (3 s cooldown), and holding Boost after a blink boosts as usual.
- **Afterimage** (needs Blink Drive): for 1 s after a blink, a ghost of the fleet stays behind. Nearby enemies turn on it, and shots that reach it are soaked up.
- **Slipstream**: while boosting, ships in formation take half damage from shots behind them.
- **Ram Plating**: boosting into enemy ships hits them for 10 damage per unit/s of fleet speed. No collision or asteroid-bump damage to you while boosting.
- **Afterburner Wake**: boosting leaves a burning trail behind the Kharkiv for 3 s. Enemy ships in it take 8 damage every 0.4 s.
- **Quick Spool**: warp charge time halved.
- **Hot Exit**: dropping out of warp sends a pulse that does 150 damage and slows enemy ships within 25 units by 50% for 4 s.
- **Overdrive Tanks**: boost meter 50% bigger, refills twice as fast.
- **Drift Thrusters**: the fleet keeps its speed through turns, and the formation swings round about 3x faster.

New Fleet cards:
- **Sustained Fire**: your Gatling bursts last 1 second longer (about 35 rounds instead of 10).
- **Mine Layer** (Kharkiv weapon): while moving, the Kharkiv drops a proximity mine every 2.5 s. Mines arm after 1 s, trigger when an enemy ship comes within 2.5 units, and do 150 damage to every enemy ship within 3.5 units. 8 mines out at once; past that, the oldest fizzles. Each extra copy: +2 mines (up to 14) and +25% damage.
- The Kharkiv can carry at most 4 different weapon types. Once it has 4, weapon cards it doesn't already have stop being offered.

Cards with a requirement or a copy limit only show up when they can actually be taken (in card choices and in Arms Dealer shops).

## Patch 7.1

- **Final score.** The end screen totals a score from the 7 stats that matter most, top to bottom: Victory (10,000 + 10 per second under 20:00), or time survived (5 per second) if you lost; enemy ships destroyed (100 each); systems conquered (2,500); planets held (750); peak population (200 per pop); stations built (300); damage dealt (1 per 10). Rows reveal one by one, the total counts up, and your best score is saved between runs.
- **Asteroid Fields.** Rebel Rocks is now an Asteroid Field (tagged on the galaxy map and top bar): about twice the asteroids, and nothing ever respawns there, not even rocks with yields.
- **MAG slugs pierce everything** in their path (ships, stations, asteroids) and keep flying to the end of their range. Splash still hits around each target.
- **Gatling damage numbers are separate again**, one per hit.
- **Rich asteroids** drop one thing: 25% a Repair Kit, otherwise a Fleet Card (Kits no longer drop alongside cards).
- **Shipyards are destructible** (500 health), for every faction. A destroyed station now disappears from the map right away (fixes the Rebel station that kept showing after it was destroyed).
- **Fixed: Shipyards not repairing.** Any non-UNE ship anywhere in the system (even a neutral one) switched repairs off. Now only hostile ships near the station stop them.
- Warp lane labels sit outside the system boundary instead of on the arrow.
- Sound: the boost rush is one long seamless sound that never restarts; the hull-hit "ding" is now a dull thunk at half the volume; warp charge and jump are a little quieter.

## Patch 7.0: Building

- **Build menu (B)**: Starbase (40 Alloys, 20 s), Shipyard (25 Alloys, 15 s), and every warship at its Alloy/Gas cost and build time.
- **Placing stations**: pick one and a ghost follows the mouse, showing its collection or repair ring. Blue means it fits, red means it doesn't, and the line above says why (not your system, too close to a planet, station, star, edge or warp lane, can't afford, station limit). Click to place (hold Shift to keep placing), right-click or Esc to stop. You pay when you place.
- **Construction Ship**: one at a time launches from your nearest Shipyard and builds ghosts in the order you placed them, warping between systems if it has to. Ghosts read "Waiting for construction ship (2nd)", "Construction ship ETA 0:14", then show a build bar with "Building 0:08". If it's destroyed, a new one launches 5 s later and picks up where it left off. With nothing to build, it parks at its Shipyard.
- **Cancel a ghost**: right-click it. Full refund before building starts, half after.
- **Shipyard queue**: ships you order are paid up front and built one by one at the Shipyard nearest your fleet. Its label shows what it's building, a bar, and how many more are waiting. A finished ship guards the Shipyard until the fleet is in that system, then flies into formation. The formation eases into its new shape instead of snapping.
- **Civilian ships**: Haulers, Colony Ships and Construction Ships now have Corvette toughness (50 hull + 100 armor) and keep their speeds. When any of them is hit: "Our civilian ships are under attack, commander!"
- MAG Cannon is out of the build menu until station guns exist.
- Alt always wins: with Alt held, only MAGs fire on every ship, even with the left mouse button down.

## Patch 6.5

- Enemies fight as a pack: hit one, and every ship of its group within 14 units joins in. No more picking them off from long range.
- MAG: 500 damage (was 650), cooldown 6.2 s (was 8), so damage per second is about the same. PD MAG on Mars is unchanged.
- Ticks are now **days**: the top bar shows NEXT DAY, and incomes read "per day".
- Clicking the top bar, panels or music player in Fleet Mode no longer fires your ships.
- Tooltips are on a dark panel, with key words in bold (Space Stations first; more to follow).
- Gatling damage numbers add up: small hits on one target in 0.35 s show as one total. MAG hits still pop at once.
- Fixed the music player skipping songs and jumping around after quick Next/Previous presses.

## Patch 6.4

- Planet shields now look like ship shields: a soft blue force field with a bright edge, fed by a small generator on the south pole, flaring where hits land.
- Day After Tomorrow is out of the playlist.
- Tab is hidden in Fleet Mode until a second fleet exists.
- Damage numbers are bigger and spread out more.
- The music player sits at the right end of the top bar.

## Patch 6.3

- Damage numbers only show damage you deal (damage you take is hidden; a Settings toggle comes later).
- Black Cat Magic is out of the playlist.
- Starbase guns hold fire rather than shoot through an asteroid worth resources.
- The Rebel base has 2,400 health.
- Gold asteroids have a 30% chance to drop a **Repair Kit** (green cross): fly into it to fully restore the Kharkiv.
- **Planetary Shields** (Tech card) now work: your planets get 500 shields, shown as a magnetic field thrown up by a ground generator at the planet's south pole. Besieged planets with shields soak hits on the shield first, flaring where they're struck.
- **Planet panel:** when a planet has Growth Rewards waiting, its next empty building slots glow gold. Click one to pick the building right there.

## Patch 6.2

- **Warps follow your mode.** If you're in Fleet Mode when the jump begins, the camera rides it as before (and you can't leave mid-jump). If you left Fleet Mode during the charge, the fleet jumps in the background and your camera stays put; a notification says when it arrives (click it, or press F). Pressing F during a background jump puts you into the ride.
- **Smoother jumps:** a quick blue-white flash covers the cut into and out of the warp view.
- **The warp view is zoomed in closer** on the fleet, settling in as the jump starts.

## Patch 6.1

- MAG charge-up sound at half volume; music starts at 50%.
- The boost rush is quieter and loops for as long as you boost.
- Starbases have 3,000 health.
- Automatic fire scatters 80% more; hand-aimed fire (left-click, Alt) is tighter, so taking the aim pays off.
- The wave countdown sits under the Fleet Mode banner instead of on top of it.
- Silver and gold asteroids are bigger and glow softly.
- Side jets puff from the outside of a turn.
- MAG slugs have double the hitbox.
- Every hit shows a damage number, sized by damage (small hits small, big hits big). A Settings toggle comes later.

## Milestone 6: sound (placeholders)

- **Generated sound effects** for Gatling bursts, MAG charge-ups and shots, hits on hulls and shields, explosions, boost, brake jets, warp charge and jump, pickups, Growth Rewards, cards (appear, pick, land), the shop, notifications, colonizing, pause and Fleet Mode. Every HUD button clicks and ticks on hover. Sounds are positional (louder near the camera) and throttled so big fights stay readable; systems you aren't looking at stay silent.
- **Space ambience:** a low, slow drone under the music.
- **Warning cues:** distinct alerts for incoming fleets, convoys under fire and stations under attack.
- **UNE announcer (placeholder):** your computer's text-to-speech voice, pitched low, reads key lines with cooldowns: "Small enemy fleet incoming, Commander." / "Large enemy presence detected." / "Our convoys are being raided." / "Space station under attack." / "Kharkiv critical." Real recorded lines come later.
- Sounds play on an SFX channel, separate from Music. The files are in `sounds/`; swap any of them for a real sound with the same name.

## Patch 5c

- **Alt fires secondary weapons.** In Fleet Mode, hold Alt and each ship's MAG-family guns fire at the reticle; the weapon name ("MAG") shows under the reticle. Left-click still fires everything.
- **Hardening.** Armor hardening takes a flat amount off every hit while armor holds (1 point = 1 damage). Shield hardening cuts damage 10% per point while shields are up. Starbases have 1 armor hardening.
- **Shields** show as a pink bar above the health bar (no more blue circles around ships).
- **MAG range** up 30% (42 to 55).
- **Fleet XP** is a small golden bar in the top bar.
- **Haven** gets a molten world (uninhabitable), a gas giant, more asteroid fields, and one silver and one gold asteroid.

## Patch 5b.2

- Starbases and planets repair themselves 5% of max health a second while no enemy ships are in the system.
- Planet banners: a one-line label under every planet (Total War style) with its name, a happiness face (green, yellow, red), pops and yield per tick. Click the banner to open the planet.
- Starbase orbits are labelled COLLECTION, like the Shipyard's REPAIRS.
- Enemies fight back the moment they're hit, instead of sitting in the open.
- Ships are about 13% bigger, so they're easier to hit.
- MAG-family guns reload 20% faster (Mini MAG 10 s, MAG and PD MAG 8 s), fire bigger slugs that are easier to land, and splash 30% damage onto anything close to the hit. A small ring beside the ship shows the reload.
- While paused (P), you can still click planets, read their panels, hold Space and pan the camera.

## Patch 5b.1

- The Kharkiv carries 1 MAG and 4 Gatlings.
- The derelict tech lab has 3 guard Corvettes, posted at the mouth of the Rebel Rocks warp lane, away from the lab.
- Ships repair only near a Shipyard; Starbases no longer repair (a future upgrade card can turn that on). The Shipyard sits further right so its ring doesn't overlap Earth.
- Starbases have 1 armor hardness: every hit on them does 1 less damage.
- Jets: one narrow stream out the nose when braking, one out the back when pushing off.
- Boost only affects ships in formation; escorts sent out with right-click keep fighting while you boost.
- Shots fly on to 2.5x their weapon range at full damage, so long shots still hit.
- Performance: fewer asteroid fields in Rebel Rocks, and shots only check targets near them.

## New in milestone 5b

- **Starbases can be destroyed.** 1,500 health with a health bar; Rebel waves stop to attack them. Sol's Starbase now sits in the lane from the Rebel warp point, so it takes the first hits. If it falls, its mining and repair zone are gone. Enemy Starbases can be destroyed too.
- **MAG charge-up.** Every MAG, Mini MAG and PD MAG (yours and the enemy's) glows for 2.5 seconds before it fires, so big shots are telegraphed. MAG-family rounds leave a bright streak that lingers for 1.5 seconds.
- **K9 Gatling, A-10 style:** 10 rounds per burst, fired twice as fast, 3 damage each, 1.8 s cooldown (same damage per second, much more lead in the air). Rounds fly faster (85).
- **The Kharkiv has 7 Gatlings** (3 more), mounted along both sides of the hull.
- **Colonize button:** a rocket-landing icon floats over every planet you can colonize. Fly the Kharkiv into it to launch a Colony Ship (C still works too). Grey means you can't afford it yet, and it shows the cost.
- **Silver and gold asteroids** pay $25 and $50.
- **Planet panel** moved to the left side; building cards pop out to its right.
- **Music player (beta)** in the top right: scrolling track name, previous / play-pause / next, a track list and a volume slider.
- **Cleaner top of the screen:** the wave countdown is a small pill under the top bar, toasts sit below it, notifications stack under the music player.

# Milestone 5 (the game loop)

## New in milestone 5

- **Rebel waves.** The first wave of 6 Rebel Corvettes warps into Sol at 2:00 (up to 20 s late, never early), then every 2 minutes, 3 Corvettes bigger each time. A countdown under the top bar turns red and flashes in the last 15 seconds. Waves stop once the Rebel base is destroyed.
- **Victory.** Mars can be besieged: it has 2,000 health and a PD MAG. When it falls, you win, with the same score screen as a loss.
- **Colonization.** In Fleet Mode, fly the Kharkiv close to an empty planet (Haven is right behind Earth) and press **C**. Once Earth has reached 2 pops, it costs 1 pop, 10 Alloys and $20. A Colony Ship (green pop head on its hull) launches from your nearest planet with 2+ pops and flies there, warping if needed. It can be shot down on the way, and then everything is lost. A back-arrow button beside it (outside Fleet Mode) turns it around and returns the pop. Once it lands, a green bar over the planet fills for 30 seconds, then the planet is yours with 1 pop. Marking Haven wakes the Rebels hiding there.
- **Growth Rewards only at new highs.** A planet that loses pops keeps the rewards it earned; regrowing to an old threshold pays nothing.
- **New planet panel.** A row of pop heads up to capacity with growth dots and a gold tick on every earned Growth Reward threshold; stats as small icons (hold Space for their names); six large building slots. Hover a building to see its card.
- **Off-screen warnings.** Incoming fleets, Haulers and Colony Ships under fire show a pulsing red icon at the screen edge, pointing toward the trouble. Click it to jump there.
- **Derelict tech lab fix.** Its guard sits 15 units away, and stray shots pass through the lab: only focus fire or free fire aimed at it breaks it.
- **Music.** Seven placeholder tracks play as a shuffled playlist with crossfades, even while paused.

# Milestone 4


## Patch 4d.1

- Hauler containers follow the Hauler's path like train cars instead of swaying like a snake.
- The Shipyard shows its repair radius (green dashed ring).
- Brake jets are tight, narrow, pressurised puffs.
- Hold Space: Hauler cargo shows in green under the Hauler.
- Right-click escorts each get their own spot around the reticle, and free-flying allies keep more room, so Corvettes don't bunch up.
- Corvettes circle rocks at 4 units again.

## New in milestone 4d

- **Starting fleet** waits halfway between Earth and the Starbase.
- **Shots can miss.** Ships fire straight at where the target is heading, with some scatter, instead of perfectly homing shots. Stray rounds hit whatever they run into, so asteroids work as cover.
- **K9 Gatling:** 25% more rounds (reload 1.5 to 1.2 s), 4 damage instead of 5 (same damage per second before misses), slower rounds (90 to 70) and wider scatter. About 1 tracer in 9 flies 3.5x as far, doing 1 damage past normal range.
- **Contrails and exhaust flames** on moving ships.
- **Small ships attacking rocks** circle about twice as far out, so their shots connect.
- **Haulers:** bigger, spaced-out containers on a swaying gravity chain. Hold Space to see their cargo.
- **Pursuit:** enemies fighting your fleet when you warp out follow you through about 2.5 seconds later, and a notification tells you.
- Only rocks your ships break pay $ (enemy stray shots don't).

# Milestone 4c

## New in milestone 4c

- **Starts in Fleet Mode.**
- **Shipyard by Earth.** It now orbits next to Earth. Ships repair near the Shipyard as well as inside a Starbase's orbit.
- **Derelict tech lab.** The hidden tech base in Sol is neutral: your ships won't shoot it automatically, but focus fire or free fire breaks it open for the Tech pickup. Its guard Corvette is still hostile.
- **K9 Gatling** range doubled (15 to 30). Every third round is a bright tracer; the others fade out in flight.
- **Mini MAG** shots leave smoke trails that drift and fade.
- **Damage effects.** Ships below 50% health trail smoke, and below 25% they burn as well. Below 20% Kharkiv health, the screen edges glow faintly red.
- **Growth Reward bubbles** can be claimed by flying the Kharkiv into them in Fleet Mode, as well as by clicking them outside it.
- **Yields (hold Space)** show green on rocks and fields your Starbases are mining. Zero yields are hidden.
- **Range rings (hold Space)** merge across the formation into one clean outline per weapon range.
- **Fighting rocks and bases:** no evasive moves against targets that can't shoot back. Corvettes circle tight, Frigates keep orbiting, bigger ships move in closer.
- **Small ships are 25% faster** (Corvettes and Frigates: 18 to 22.5).

# Milestone 4b

## New in milestone 4b

- **Free fire.** In Fleet Mode, hold left-click and every ship fires at the reticle, even into empty space. Aim starts spread out by each ship's place in the fleet and tightens over about a second while you hold steady (flank ships take longest). Sweeping the reticle loosens it again. A click on a target still sets focus fire. Free shots hit anything that isn't yours, asteroids included.
- **Ships avoid each other.** No more stacking on a right-click. If hostile ships actually collide, the bigger ship wins and the smaller loses 50% of its health (same size: both lose 25%). Ramming a Corvette with the Kharkiv works. Your own ships never hurt each other.
- **Formation turning** is slower and smoother, and each ship faces where it's actually going.
- **Asteroids pay $:** $1 per rock, $3 silver, $6 gold (silver and gold still drop their Fleet card pickup).
- **Growth Rewards** (renamed from Planet Rewards). Planets grow quickly at first and slow down: a new pop costs 3 + current pops ticks. Earth reaches 10 pops at about 12 minutes.
- **Notifications** in the top right: they stay 10 seconds, then blink and fade. Click one to jump the camera there. Growth Rewards use it for now.
- **Boost** lasts 3 seconds.
- **Repairs** show green "+" signs rising from ships healing at a Starbase.
- **Asteroid respawn** waits 3 to 10 seconds before the replacement starts drifting in.
- **Rebel Rocks** is packed with asteroid fields.
- **H autopilot** keeps flying home after you leave Fleet Mode. WASD in Fleet Mode or H again cancels it.
- **Alloy rocks** have purple specks. Hold Space to see every rock's yield.

# Milestone 4

## New in milestone 4

- **Planet reward bubbles.** Planet cards no longer pop up by themselves. A gold bubble with a count appears over the planet; click it (outside Fleet Mode) when you're ready to pick.
- **Pickups need a touch.** The Kharkiv has to fly over a pickup to collect it.
- **Fog of war.** Systems you've never had a ship in are dark until you visit (and show "?" on the galaxy map). Where you have ships or a Starbase, enemies are visible. One jump away, enemies show as breathing red dots. Enemies inside an asteroid field (within 6 units of its centre) or behind a planet from all your ships are hidden, and your ships won't target them.
- **Game over.** If the Kharkiv dies, the run ends with a score screen: time survived, systems conquered, planets colonized, enemy ships destroyed, your top ship by kills, peak population and total Alloys mined. "Start a new run" restarts.
- **Ship names and kill credit.** Every ship has a faction name (UNE, Rebel and Sons of Philip lists) and keeps its own kill count.
- **Hotkeys.** H: outside Fleet Mode, camera back to Earth; in Fleet Mode, autopilot to the nearest friendly Starbase, warps included (any WASD input cancels). Tab: outside Fleet Mode, cycle through your planets; in Fleet Mode it will switch fleets once Second Command exists. P: pause.
- **Strike-group formation.** Corvettes picket out front, Destroyers on the flanks, Frigates and Cruisers in an outer ring, big ships in the centre. The formation turns with the fleet, and returning escorts ease into their slots at fleet speed instead of braking.
- **Retreat (beta).** Escorts below 20% health stop fighting and pull back to the formation.
- **Fixed start and bigger worlds.** The starter field is always 5 rocks next to the Starbase. Planets are bigger (radius 9), gas giants 14, minimum spacing 40.
- **Mars phalanx.** The Sons of Philip Destroyers turn slowly, take half damage from the front and 150% from behind, and fire faster for every Destroyer near them (Phalanx Volley).
- **Smarter enemy flying.** Corvettes make attack runs, Frigates circle-strafe and break off, damaged ships retreat.

Not in yet: building more ships, so a second fleet isn't possible.

# Earlier milestones


Open this folder in Godot 4.7 (Project Manager, then Import, then pick `project.godot`) and press F5 to run.

## What's in this milestone

- The six-system tutorial map: Haven (colony system), Sol (Earth), Rebel Rocks, two neutral systems, and Mars.
- Galaxy view and system view, with a fixed-angle camera that pans and zooms.
- System generation by the brief's rules (planets, gas giants, asteroid fields, silver and gold asteroids, 30-unit spacing). Sol, Haven, Rebel Rocks and Mars are hand-placed.
- Map scale: 1 range unit = 32 px, system radius 120 units, zoom out to about 4x.
- Economy tick every 10 seconds: start with 10 Alloys; Earth gives $5 and 1 Alloy per tick; a Starbase collects whatever sits inside its orbit.
- Top bar with Alloys, Gas, $, Tech, Starbase count (1/5) and the next tick.
- Placeholder ships and structures with short codes: C, F, D, CR, CA, B, K (Kharkiv), CO, SB, SY.
- Starting setup: Earth (4 pops), a Starbase and Shipyard, the Kharkiv and 3 Corvettes.
- Enemies placed but not active yet: 3 Rebel Corvettes hiding in Haven's outer field, 12 Rebel Corvettes at the back of Rebel Rocks, 6 Sons of Philip Destroyers in a line at Mars.

## Controls

| Key | Action |
|---|---|
| F | Fleet Mode on/off: WASD steers the Kharkiv and its fleet, the camera follows |
| W A S D | Steer the fleet in Fleet Mode (pans the camera outside it) |
| Shift (hold) | Boost: x2 speed for up to 1.5 s, refills 2 s after you let go (not in asteroid fields) |
| B | Build menu (pops up from the bottom; placing comes next milestone) |
| G | Galaxy view on/off |
| Space (hold) | Info: full names instead of short codes, plus faint weapon range rings for every ship |
| H | Camera to Earth, or in Fleet Mode autopilot to the nearest Starbase |
| Tab | Cycle your planets (outside Fleet Mode) |
| P | Pause |
| F11 | Fullscreen on/off |
| Esc | Close the planet panel or build menu |
| Left-click (Fleet Mode) | Focus fire on anything under the reticle: ships, bases, any asteroid. Click empty space to clear |
| Hold right-click (Fleet Mode) | Send every ship except the Kharkiv to the reticle to fight; release to bring them back |
| Click a planet | Planet panel: population, growth, next Planet card, stability, health, income, 6 building slots |
| Arrows, right or middle drag | Pan the camera |
| Mouse wheel | Zoom |
| Click a system (galaxy view) | Look at it |

## Warp travel

Fly the fleet onto a green arrow at the system's edge. It charges for 3 seconds: for the first 1.5 you can still move away to cancel, then it locks in place for 1.5. Then the view switches to the galaxy map and the fleet flies the warplane for 3 seconds with the camera locked on it and a hyperspace streak effect, with no control, and arrives at the matching arrow in the next system with a flash.

## Combat (first pass)

Ships fire Gatlings, Mini MAGs and MAGs at the nearest hostile target in range (ranges x2, projectile speeds x3). Damage hits armour, then hull. Your fleet holds fire while boosting. Missiles, Torpedoes, Flak, PDCs, shields and fighters come later.

## Hidden tech base

In Sol, just before the warp lane to the Roid Rebels, an asteroid with glass-dome tech labs is guarded by one Rebel Corvette that attacks when your fleet comes close. Destroy the base for a Tech card choice (the game pauses). Earth no longer gives Tech: Tech comes from Tech Labs.

Every 10-second tick, each source of income shows a green "+3 ALLOYS"-style popup above it, owned planets grow 1 step toward their next pop (10 steps per pop), and the top bar shows each resource's income per tick.

Ship speeds are tripled (Small 18, Medium 14.4, Large 11.7 units per second).


## Cards and tempo

- Earth starts with 1 pop. A pop takes 5 growth steps (one per 10-second tick, or 1.5 with Cryo Medicals), so Earth reaches 2 pops at about 50 seconds.
- Every time a planet's pops reach an even number, the game pauses for a 3-card Planet choice, with the planet's details on the left. The pick becomes a building in one of its 6 slots.
- All 8 Planet buildings work: City, PD MAG, Fleet Academy, Tech Lab, Cryo Medicals, Logistics Hub, Mining Corp, Gas Refineries.
- Kills give Fleet XP equal to the ship's tier. The first Fleet card needs 30 XP, then 60, 120... The XP bar sits above the hotkeys.
- Fleet cards that work now: Hardened Plating, Reinforced Hulls, Shield Emitters (shields recharge 3/s after 10 s without damage), Overclocked Thrusters, Rapid Loaders. Missile Racks, Drone Bay Expansion and Efficient Shipyards wait for missiles, drones and ship building.
- Cards stack: each card shows how many times you've picked it.
- Weapon ranges are now x3: Gatling 15, Mini MAG 30, MAG 42, PD MAG 56.
- Enemies under fire they can't answer for 3 seconds show "!" and charge.
- While a fleet charges a warp, a wormhole tears open at the arrow.

## New in milestone 3

- Floaty movement: ships speed up and coast to a stop. Letting go of a direction fires counter-thrust jets from the noses.
- No planet clicking in Fleet Mode.
- About twice as many asteroids, many loosely circling planets and gas giants, with lower yields (mostly 0-1 each). Every asteroid is a real object.
- Regular asteroids only take damage from focus fire. A destroyed one is replaced by a rock with the same yield that drifts in from the system's edge over 75 seconds.
- Medium and Large fleet ships that hit an asteroid shake, flash red and lose 10% hull; the rock is knocked away and drifts back.
- Base $: Earth gives $1, and a Starbase orbiting a planet gives $1. Cities are the main $ source.
- Haulers: a Starbase's collected Alloys and Gas ride on a Hauler (one container per resource) to the nearest planet you own, warping between systems if needed, and only count on delivery. Destroyed Haulers lose their cargo.
- Silver and gold asteroids drop a Fleet Card pickup. Fly over it to buy it ($15, +10% each time). Gold pickups lean Rare and ULTRA; Rare cards count double, ULTRA triple.
- Arms Dealers in both neutral systems: fly into the orbit to shop. 6 Fleet and Tech cards of every rarity at $15 / $35 / $75, refresh for $100.
- Ships inside one of your Starbase orbits repair 10% armour and hull per second when no enemies are in the system.
- Rebel space: 2 patrol packs of 3 Corvettes; 4 interceptors come for you when you first arrive; hitting the giant asteroid base (1,200 health, Mini MAG) brings every Rebel in the system down on you.

## New in milestone 3b

- Rewards are physical: hidden tech bases drop a spinning blue Tech chip (free; a rare purple one is secret tech), silver and gold asteroids drop a spinning red Fleet Card ($). Fly within about 6 units to collect.
- A picked card pops, flies to whatever got it (the planet, the Kharkiv, or the TECH counter) and vanishes. The game stays paused until it lands. Arms Dealer purchases fly too.
- In Fleet Mode the camera always stays with the fleet, including after warps.
- Holding Space (info) now also shows faint weapon range rings for every ship.
- Weapon cooldowns are halved: Gatling 1.5 s, Mini MAG 12.5 s, MAG and PD MAG 10 s.

## New in milestone 3c

- No more passive Tech: Tech is no longer a resource. Tech cards come from Tech pickups (hidden tech bases) and Arms Dealers, and fly to Earth when picked.
- Tech Lab (limit 1 per planet): +1 option on every Tech card choice.
- Haulers move at half speed (9), are smaller, and carry at most 5 containers. Extra cargo waits at the Starbase for the next Hauler.
- The first Starbase and Shipyard now sit on the right side of Sol, facing the Rebel warp lane, with one clean asteroid group in orbit. The fleet starts beside them, and the Haulers' run back to Earth is your first visible supply line.
- Every Starbase has 2 stand-in Gatlings until PDCs and drones exist.

## Not yet

Placing structures and building ships, Rebel waves on a timer, colonization, the Sons of Philip's phalanx behaviour, game over and victory screens, cards, XP, colonization. These come in the next milestones, following the Tickets tab of the design brief.

## Files

- `scripts/game_data.gd`: all tuning numbers. Change balance here.
- `scripts/generator.gd`: builds the tutorial map.
- `scripts/main.gd`: views, camera, economy tick.
- `scripts/system_view.gd`, `scripts/galaxy_view.gd`: drawing.
- `scripts/ship.gd`: placeholder ship.
- `scripts/hud.gd`: top bar.
