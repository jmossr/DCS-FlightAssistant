# Seat Detector — status notes (for continuing on another PC)

> Carried over from `DCSgit/Scripts/FlightAssistant_1.9/` 2026-08-19 when that deployed copy was
> retired in favor of this repo. Paths below still use that copy's pre-reorg layout
> (`FlightAssistant/extensions/...`, `setupRadioControlledAutopilot.lua`) — in this repo those are
> `extensions/...` (no `FlightAssistant/` prefix) and `setupSCR522ARadioControlledAutopilot.lua`
> respectively. Left as originally written rather than rewritten, since the substance (the
> flag-based-engage design decision and open questions) is unchanged.

## Where it's at
- `SeatDetector_Test.lua` was moved here from `Scripts/NavigatorAI/` — it's a FlightAssistant concern, not
  a NavigatorAI one, and NavigatorAI had no other references to it.
- It still contains the **old approach**: mission-scripting-env code (`world.addEventHandler`,
  `coalition.getGroups`), loaded via `DO SCRIPT FILE`. That's a different Lua env than FlightAssistant
  itself (Export env — see `FlightAssistant/extensions/`).
- We tried to auto-detect the seat/state directly from the game and couldn't get a reliable read.
  **Decision: pivot to a flag-based approach** — a DCS mission flag is set via a Mission Editor trigger,
  and FlightAssistant reacts to that flag instead of a physical radio button sequence.

## Key finding — no new script needed
FlightAssistant already has everything required for flag-based autopilot engage/disengage:
- `FlightAssistant/extensions/flags.lua` gives every per-aircraft config `onFlag(flag)` /
  `onFlagValueChanged(flag, f)`. `flags` is already a required extension for Autopilot
  (`FlightAssistant/Autopilot/Autopilot-config.lua` → `requiredExtensions`).
- `FlightAssistant/extensions/autopilot.lua` + `FlightAssistant/Autopilot/setupRadioControlledAutopilot.lua`
  already expose `fireSignal('A/P_LVL_HDG')`, `fireSignal('A/P_LVL')`, `fireSignal('A/P_LVL_BNK')`,
  `fireSignal('A/P_OFF')` as engage/disengage entry points — currently wired to radio-knob sequences
  (`setupSCR522ARadioAutopilotSequences.lua` / FuG16ZY equivalent).

## Proposed next step (not implemented yet)
Add something like this to a shared setup script or per-aircraft config:
```lua
onFlagValueChanged('<FLAG_NAME>', function(newValue)
    if tonumber(newValue) ~= 0 then
        fireSignal('A/P_LVL_HDG')  -- or whichever mode makes sense
    else
        fireSignal('A/P_OFF')
    end
end)
```
Open questions to settle before implementing:
- Shared code (add to `setupRadioControlledAutopilot.lua` so all aircraft get it) vs. per-aircraft?
- Flag name convention?
- Does `SeatDetector_Test.lua` get rewritten to use this pattern, or retired once flags are wired directly
  into the autopilot configs?

## Repo state as of this note
Last push: commit `5b4fa91` on `main` — moved SeatDetector here, dropped superseded
`FlightAssistant_1.6`/`1.7`, added `GoldeneyeRecon` + `Splash_Damage`, gitignored `.luarc.json`.
