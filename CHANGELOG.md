# Changelog

## Unreleased

## 2.0 - 2026-08-19

### Merged
- Consolidated with `FlightAssistant_1.9`, a separately deployed and locally-patched fork of an
  earlier vendored snapshot of this project (maintained in a private repo, not derived from this
  one's git history) — that fork is now retired in favor of this repo as the single source. Before
  retiring it, brought over what wasn't here yet: the stall-protection reset fix below (originally
  diagnosed and fixed in that fork 2026-07-27, predating this repo's `core`/`extensions`
  reorganization), and two files with no counterpart here — `SeatDetector_Test.lua` +
  `SeatDetector_NOTES.md`, design notes for pivoting autopilot engage/disengage to a mission-flag
  trigger instead of a radio-knob sequence (not yet implemented). A third file found in that fork,
  `me_coords_magvar.go`, turned out to be an unrelated stray duplicate of a file from a different
  project and was not carried over.

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
- `extensions/autopilot.lua`'s `createPitchSpeedOverrideControl` (the low-speed stall-protection
  layer wrapped around every aircraft's pitch control) returned `reset = baseControl.reset`,
  resetting only the inner PDi and leaving its own closure state (`overrideActive`,
  `referencePitch`, `targetPitch`, `vvReferencePitch`) stale between engagements. A stale
  nose-down `targetPitch` from a prior session got replayed into the elevator on re-engage,
  pitching hard nose-down / diving into the ground on the *second* autopilot engagement, and
  after a mission restart/reload (only a full DCS relaunch cleared it, since the loader keeps
  autopilot closures alive across those). Affects every aircraft, since they all share this
  wrapper. Fix: gave the wrapper a real `reset()` that nils its own transient state before
  delegating to `baseControl.reset()`. Originally diagnosed and fixed 2026-07-27 in a deployed
  fork (`FlightAssistant_1.9`) that predates this repo's `core`/`extensions` reorganization;
  ported forward 2026-08-19 when that fork was retired in favor of this repo.
