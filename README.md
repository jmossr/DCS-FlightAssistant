# DCS-FlightAssistant

The goal of this project is to build aircraft specific assistants for
DCS world.
FlightAssistant hooks into DCS by installing it in
Saved Games\DCS[.variant_suffix]\Scripts\FlightAssistant
and placing one file, FlightAssistantLoader.lua, in
Saved Games\DCS[.variant_suffix]\Scripts\Hooks


## TF-51D/P-51D Autopilot

The first application and proof of concept is an autopilot for the
TF-51D/P-51D.
When engaged, the autopilot will keep the plane in level flight by taking
control of the plane's control stick. Throttle and rudder are left for the
pilot to set and trim.


### Installation
Extract the files from the zip-archive into your
Saved Games\DCS[.variant_suffix]\Scripts folder.

When ready, in Saved Games\DCS[.variant_suffix]\Scripts you should see a folder
'FlightAssistant'.
Folder Saved Games\DCS[.variant_suffix]\Scripts\Hooks should contain
FlightAssistantLoader.lua and maybe more files from other mods.


### Engaging The Autopilot
For now the autopilot can be engaged or disengaged by pressing a specific
sequence of buttons on the SCR-522-A Radio Control Panel on the right side of
the cockpit. After pressing a sequence to command the autopilot, the radio can
be switched to any channel again.

- To engage level flight, press: *channel D, channel C, channel B*
- To engage alt and bank angle hold, press: *channel D, channel C, channel A*
- To disengage, press: *channel D, channel C, channel D*

All sequences start with channel D. If channel D is active before you want to
command the autopilot, you must first switch to another channel to be able to
start the sequence with channel D.


## Work In Progress
- testing and debugging
- documentation


## Open Issues
- multiplayer is currently not supported