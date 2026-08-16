# Changelog

## Unreleased

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
