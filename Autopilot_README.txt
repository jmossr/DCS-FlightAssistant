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

  To engage heading hold    : Turn to I, click to II, return to I     (I -> II -> I)
  To engage level flight    : Turn to I, then sweep up to III         (I -> II -> III)
  To engage bank/alt hold   : Turn to IV, then sweep down to II       (IV -> III -> II)
  To disengage              : Turn to IV, click to III, return to IV  (IV -> III -> IV)

Important: the system detects knob movement, not position. If you are already sitting on
channel I when you want to engage heading hold or level flight, the sequence will not start
until you actually arrive at I by turning from somewhere else. If already on I, first turn
to II (or higher), and perform the sequence from there. The same
applies to channel IV - if already on IV, first turn to III before starting a IV-based sequence.

*********
v 1.6

Addition of new ap mode (AP Level Heading) current heading is captured at engagement and kept with bank.

- To engage level flight with heading hold, press: *channel D, channel A, channel B*

*********
v 1.7

Bug fix in autopilot.lua affecting all aircraft with heading hold:
The heading PID was being supplied the absolute desired heading as its target (instead of 0), and the bank
output sign was inverted. Together these caused the aircraft to spiral away from the target heading rather
than hold it. Both corrected - heading hold now functions as intended.

*********
v 1.8

Rudder coordination implemented for all aircraft types:
LoGetAngleOfSideSlip() proved unreliable in DCS, returning ~-7.7 rad consistently during
flight (physically impossible - maximum aerodynamic sideslip is ±π/2 rad ≈ ±1.57 rad). When used as
feedback it saturated the rudder at full deflection and caused uncontrolled turns.
Replaced with computed sideslip derived from consecutive position samples:
  slip = heading - track, where track = atan2(east delta, north delta)
This uses only data known to be correct (selfData.Position and selfData.Heading) and is robust across
all headings including the 0°/360° north wrap. Negative slip means nose is left of the velocity vector,
which in turn produces a positive (right) rudder output.
Rudder PDi controller: P=1.5, D=0.05, I=0.02, max ±0.3, ramp 0.15 rad/s.

*********
v 1.9

Axis aircraft support added: Bf-109K-4, FW-190A8, FW-190D9.

These aircraft use the FuG 16ZY radio as the autopilot control interface, which is a 4-position rotary
selector (positions I/II/III/IV) rather than the 4 separate push-buttons found on the Allied SCR-522.
Because the rotary must pass through intermediate positions when moving between non-adjacent channels,
engagement sequences are designed around adjacent single-step movements only.

Each click of the knob fires a directional signal depending on which way it moves:
  Moving up (toward IV):   step to II, step to III, step to IV
  Moving down (toward I):  step to III, step to II, step to I

Autopilot engagement sequences (complete within 2.5 seconds):

  To engage heading hold    : Turn to I, click to II, return to I     (I -> II -> I)
  To engage level flight    : Turn to I, then sweep up to III         (I -> II -> III)
  To engage bank/alt hold   : Turn to IV, then sweep down to II       (IV -> III -> II)
  To disengage              : Turn to IV, click to III, return to IV  (IV -> III -> IV)

All initial PID gains are starting-point estimates and will need in-flight tuning per aircraft type.

### Tuning the PID Gains

Each controller is created with:
  createPDiController(P, D, I, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)

P  - Proportional gain. Controls how strongly the autopilot reacts to the current error.
     Too low: sluggish response, drifts slowly. Too high: oscillates around the target.

D  - Derivative gain. Reacts to how fast the error is changing, damping overshoot.
     Raise D to stop oscillation. Too much D causes jerky, noisy output.

I  - Integral gain. Slowly corrects a persistent offset that P+D alone cannot eliminate.
     Only needed if the aircraft settles slightly off target. Keep small to avoid windup.

diCutOff - The rate-of-change threshold below which the I term is active.
     When the error is changing quickly (e.g. during a large correction), I is suppressed
     to prevent windup. Typically leave this unchanged unless I behaves erratically.

minOutput / maxOutput - Hard limits on the controller output.
     For heading control, this limits the maximum bank angle commanded (in radians).
     Reducing maxOutput limits how aggressively the autopilot banks into a turn.

maxOutputChangePerSecond - Slew rate limit. Controls how fast the output is allowed to change.
     Lower values give smoother, slower control inputs. Raise if response feels too sluggish.

Suggested tuning procedure:
  1. Set D=0 and I=0. Raise P until the aircraft responds, but before it starts oscillating.
  2. Raise D until oscillation stops and the response feels stable.
  3. If the aircraft settles with a small persistent error, add a small amount of I.
  4. If inputs feel abrupt, lower maxOutputChangePerSecond to smooth them out.

*********
v 1.9.1

Bug fix in autopilot.lua affecting all aircraft: the aircraft would pitch nose-down and dive on the
second (and every later) autopilot engagement, and after a mission restart/reload - only a full DCS
relaunch cleared it.
Cause: the low-speed pitch-override layer reset only its inner PID and left its own state
(overrideActive, referencePitch, targetPitch) stale between engagements. A stale nose-down target from a
prior session was replayed into the elevator on re-engage. Fixed by clearing that state on every reset.

*********
v 2.0
core cleanup - no added functionality
 - split FlightAssistant.lua -> FlightAssistant, actions, debugtools, extensions, logger, tools
 - enable FlightAssistant core to start in DCS "LuaExport" environment

*********
v 2.1

Multiplayer support:
Radio button presses in Allied aircraft were detected through mission scripting (a_start_listen_command
and user flags), which only exists on the machine hosting the mission. As a multiplayer client the
presses were never seen. Buttons are now detected from their cockpit animation arguments, read locally:
  P-47D / Spitfire LF Mk IX : OFF 115, A-D 116-119
  P-51D / TF-51D            : OFF 117, A-D 118-121
  Mosquito FB Mk VI         : OFF 32,  A-D 33-36
Axis aircraft already read the FuG 16ZY knob locally.
The autopilot never flew as a multiplayer client: the mod treated the sim as paused because a client
joining a server never receives the "simulation resumed" event. The pause state is now read from DCS
every frame.
In multiplayer, A/P status messages now appear as system chat messages, visible only to you.
Note: servers that disable ownship export (Export.LoIsOwnshipExportAllowed) still block the autopilot.

New aircraft (PID gains are untuned starting points):

F4U-1D Corsair - uses the C-30A radio channel knob with the same sequences as the FuG16ZY
  (Axis section above), with knob position 1 = I through position 4 = IV.

I-16 and La-7 - these have no radio channel panel, so four cockpit controls stand in for
  channels A-D and the Allied SCR522A sequences apply (D,C,B / D,C,A / D,C,D / D,A,B).
  Flipping a switch in either direction counts as one press.
              A                    B                   C                       D
  I-16 :  Clock heat switch    Pitot heat switch   Nav light test button   Radio switch
  La-7 :  Pitot heat switch    Gear signal switch  Voltmeter button        Fuelmeter switch

  The I-16 clock heat, pitot heat and radio switches are not simulated, so flipping them is harmless.

