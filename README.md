# DCS-FlightAssistant

The goal of this project is to build aircraft specific assistants for
DCS world.
FlightAssistant hooks into DCS by installing it in
Saved Games\DCS\Scripts\FlightAssistant
and placing one file, FlightAssistantLoader.lua, in
Saved Games\DCS\Scripts\Hooks


## TF-51D/P-51D and Spitfire Autopilot

The first application and proof of concept is an autopilot for the
TF-51D/P-51D and the Spitfire.
When engaged, the autopilot will keep the plane in level flight by taking
control of the plane's control stick. Throttle and rudder are left for the
pilot to set and trim.


### Installation
Extract the files from the zip-archive into your
Saved Games\DCS\Scripts folder.

When ready, in Saved Games\DCS\Scripts you should see a folder
'FlightAssistant'.
Folder Saved Games\DCS\Scripts\Hooks should contain
FlightAssistantLoader.lua and maybe more files from other mods.


### Engaging The Autopilot
The autopilot can be engaged or disengaged by pressing a specific
sequence of buttons on the Radio Control Panel.
After pressing a sequence to command the autopilot, the radio can
be switched to any channel again.

- To engage level flight, press: *channel D, channel C, channel B*
- To engage alt and bank angle hold, press: *channel D, channel C, channel A*
- To disengage, press: *channel D, channel C, channel D*
- Pressing the radio 'off' button will also disengage the autopilot

All sequences start with channel D. If channel D is active before you want to
command the autopilot, you must first switch to another channel to be able to
start the sequence with channel D.

## Known Issues
- Autopilot only works in single player mode because DCS does not allow to take control in multiplayer mode.