# Changelog

## Version 2.0

### Added
- Level Heading autopilot mode (`A/P_LVL_HDG`): holds altitude and heading, and commands the
  rudder to null sideslip. Sideslip is computed from consecutive `Position` samples
  (heading vs. track) rather than `LoGetAngleOfSideSlip()`, which was observed returning
  values outside the physically possible range (~-7.7 rad) on the Mosquito.
- New aircraft: Bf 109 K-4, FW 190 A8, FW 190 D9, each engaged via the FuG 16ZY rotary radio
  selector (`setupFuG16ZYRadioAutopilotSequences.lua`), reusing the shared autopilot core.
- Heading hold wired up for the existing TF-51D, Spitfire LF Mk IX, P-47D and Mosquito FB Mk VI
  assistants (SCR-522 sequence: channel D, channel A, channel B).

### Fixed
- `assistants/Autopilot/*.lua` referenced the shared controller setup script as
  `setupSCR522ARadioControlledAutoPilot` (capital P) while the file on disk is
  `setupSCR522ARadioControlledAutopilot.lua` (lowercase p). Harmless on case-insensitive
  filesystems (Windows) but would fail to load on a case-sensitive one.

## Version 2.1
### Fixed
#### Multiplayer support:
Radio button presses in Allied aircraft were detected through mission scripting (a_start_listen_command
and user flags), which only exists on the machine hosting the mission. As a multiplayer client the
presses were never seen. Buttons are now detected from their cockpit animation arguments, read locally:
- P-47D / Spitfire LF Mk IX : OFF 115, A-D 116-119
- P-51D / TF-51D            : OFF 117, A-D 118-121
- Mosquito FB Mk VI         : OFF 32,  A-D 33-36

Axis aircraft already read the FuG 16ZY knob locally.

The autopilot never flew as a multiplayer client: the mod treated the sim as paused because a client
joining a server never receives the "simulation resumed" event. The pause state is now read from DCS
every frame.

In multiplayer, A/P status messages now appear as system chat messages, visible only to you.
Note: servers that disable ownship export (Export.LoIsOwnshipExportAllowed) still block the autopilot.

### Added
New aircraft (PID gains are untuned starting points):

**F4U-1D Corsair** - uses the C-30A radio channel knob with the same sequences as the FuG16ZY
(Axis section above), with knob position 1 = I through position 4 = IV.

**I-16** and **La-7** - these have no radio channel panel, so four cockpit controls stand in for
channels A-D and the Allied SCR522A sequences apply (D,C,B / D,C,A / D,C,D / D,A,B).
Flipping a switch in either direction counts as one press.

    aircraft     A                     B                     C                         D
    I-16:      Clock heat switch     Pitot heat switch     Nav light test button     Radio switch
    La-7:      Pitot heat switch     Gear signal switch    Voltmeter button          Fuelmeter switch

I-16: Clock heat, pitot heat and radio switches are not simulated, so flipping them is harmless.