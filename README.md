# DCS-FlightAssistant

The goal of this project is to build aircraft specific assistants for
DCS world.
FlightAssistant hooks into DCS by installing it in
Saved Games\DCS\Scripts\FlightAssistant
and placing one file, FlightAssistantLoader.lua, in
Saved Games\DCS\Scripts\Hooks


## Autopilot

The first application and proof of concept is an autopilot for WWII-era
warbirds. When engaged, the autopilot will keep the plane in level flight
by taking control of the plane's control stick. Throttle is left for the
pilot to set and trim.

Supported aircraft: TF-51D/P-51D, Spitfire LF Mk IX, P-47D, Mosquito FB Mk VI,
Bf 109 K-4, FW 190 A8, FW 190 D9.


### Installation
Extract the files from the zip-archive into your
Saved Games\DCS\Scripts folder.

When ready, in Saved Games\DCS\Scripts you should see a folder
'FlightAssistant'.
Folder Saved Games\DCS\Scripts\Hooks should contain
FlightAssistantLoader.lua and maybe more files from other mods.


### Engaging The Autopilot — SCR-522 radio (US/UK aircraft)
The autopilot can be engaged or disengaged by pressing a specific
sequence of buttons on the Radio Control Panel.
After pressing a sequence to command the autopilot, the radio can
be switched to any channel again.

- To engage level flight, press: *channel D, channel C, channel B*
- To engage alt and bank angle hold, press: *channel D, channel C, channel A*
- To engage alt and heading hold, press: *channel D, channel A, channel B*
- To disengage, press: *channel D, channel C, channel D*
- Pressing the radio 'off' button will also disengage the autopilot

All sequences start with channel D. If channel D is active before you want to
command the autopilot, you must first switch to another channel to be able to
start the sequence with channel D.

Heading hold also commands the rudder to null sideslip; the other modes leave
rudder to the pilot.

### Engaging The Autopilot — FuG 16ZY radio (German aircraft)
The Bf 109 K-4, FW 190 A8 and FW 190 D9 use the FuG 16ZY, a 4-position rotary
selector (I/II/III/IV) rather than separate buttons. Turn the knob through
the following adjacent steps within 2.5 seconds:

- To engage heading hold, turn: *I → II → I*
- To engage level flight, turn: *I → II → III*
- To engage alt and bank angle hold, turn: *IV → III → II*
- To disengage, turn: *IV → III → IV*

## Known Issues
- Autopilot only works in single player mode because DCS does not allow to take control in multiplayer mode.