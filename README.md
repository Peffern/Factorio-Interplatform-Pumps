# Factorio-Interplatform-Pumps
Factorio Mod to allow space platforms to dock with each other and transfer fluid / items.

This is still under construction.

## Motivation
It's stupid and annoying to have every single spaceship need to manufacture its own fuel. I want to have a giant spaceborne gas station at each planet and have cargo ships refuel on fuel, ammo, repair packs. I also hate having to wait on the slow single cargo landing pad to drop off cargo, and I want to refuel at solar system edge / shattered planet instead of having to trek back to Aquilo. The obvious solution here is some kind of platform-to-platform transfer system.

This went through many revisions. I originally wanted to use cargo pods launched directly from one platform to another (theoretically possible using duplicated invisible rocket silos) but I realized that you can't transfer fuel that way since it can't even be barrelled. I could add the barrel recipe but cargo pods full of barrels of fuel is starting to strain the bounds of credibility. Some kind of docking pump is the real answer. I'm not talented enough to actually copy the platform from its own surface and allow literal docking, so an implied exporter pump that just connects to an importer on another surface is the best we're going to get at the moment.

## How it Works (planned)
This mod introduces the concept of distinct orbits around a planet (might come up with a better name for this). By default a platform launched or arriving at a planet is in a generic "high" or 0 orbit. On the space platform GUI there is an new panel for selecting a signal for the desired orbit. If this signal is set, the platform will read that signal to try to determine an orbit (positive integer) to go to.

In order to travel between orbits you need one or more Jets (name pending) on your platform. These consume thruster fuel/oxidizer although at a much lower rate than thrusters. They will automatically turn on/off when the platform determines it needs to change orbits.

If two platforms are in the same orbit, their importer/exporter pumps can link up. Importers / Exporters also have a GUI panel for picking a signal. This signal will be read to give each importer / exporter a numeric ID (value of the signal) and will look for a corresponding Exporter / Importer on another platform in the same orbit at the same planet to link to. This link persists as long as both platforms are in the same orbit at the same planet. If either changes orbits or leaves the planet, the link is broken.

While the link is active, fluid will be transferred from the exporter to the importer at a modest rate. Additional exporters / importers can speed up the transfer rate.

Items can be transferred by putting a palletizer in front of the exporter and a depalletizer in front of the importer. These don't take any signals, instead the importer will automatically detect its presence and transfer items instead of fluids.

Only two platforms can be in the same orbit at the same time. If a third platform tries to route there, it will until one of the other two leaves. The exception to this is the default high or 0 orbit which can have as many platforms as you want, but they cannot link there. Platforms in transit are considered to be in both locations until they arrive, to prevent deadlocks (this is subject to change).

## Future maybe-features
 - Interplatform signal transmit/receiver. This could be used to have a platform detect that its destination is full and go to an alternate destination instead, so you could have mutliple refueling platforms.
 - Actual graphics instead of recolored base sprites.
 - If theres's a way to swing it, some kind of animated hose / pipe extending out from the pump and into space would be cool to help sell the fantasy but I don't know how viable that is. I tried using the asteroid collector arm to simulate it but that doesn't have a very large API surface yet.

## Update progress
All of the prototypes should be placed to allow every component to be placeable. Currently the ports are just modified offshore pumps, that may have to change. All relevant GUIs exist although they are still basic.

The framework for the control script exists but the on_tick handler (where most of the work will be) is not done yet.

