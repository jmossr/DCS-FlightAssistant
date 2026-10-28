include("setupFuG16ZYRadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
  Gains are starting-point estimates copied from the P-47D (similar heavy radial fighter) — tune in-flight.
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(3, 0.3, 0.1, 0.15, -1, 1, 3), 70)
local bankControl = createPDiController(1, 0.3, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)
local headingControl = createPDiController(2.5, 0.8, 0.1, 0.2, -0.4, 0.4, 0.1)

-- Simple rudder controller for sideslip nulling (only active in Heading mode)
local rudderControl = createPDiController(1.5, 0.4, 0.05, 0.3, -0.3, 0.3, 0.15)

include("setupRadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

-- C-30A radio channel selector: 4 positions (arg 88, values 0.0/0.33/0.66/0.99).
-- It is a rotary like the FuG 16ZY, so it reuses the FuG sequences: position I = 0.0 ... IV = 0.99.
-- Upward transitions
onDeviceArgument(0, 88).valueAbove(0.165).fireSignal('FUG_UP_II')
onDeviceArgument(0, 88).valueAbove(0.495).fireSignal('FUG_UP_III')
onDeviceArgument(0, 88).valueAbove(0.825).fireSignal('FUG_UP_IV')
-- Downward transitions
onDeviceArgument(0, 88).valueBelow(0.825).fireSignal('FUG_DN_III')
onDeviceArgument(0, 88).valueBelow(0.495).fireSignal('FUG_DN_II')
onDeviceArgument(0, 88).valueBelow(0.165).fireSignal('FUG_DN_I')
