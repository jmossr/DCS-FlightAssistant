include("setupFuG16ZYRadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
  Gains are starting-point estimates — tune in-flight.
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3), 70)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.002, 0.015, 0.001, 2, -0.1, 0.2, 0.05)
local headingControl = createPDiController(0.5, 0.4, 0.05, 0.2, -0.12, 0.12, 0.04)
local rudderControl = createPDiController(1.5, 0.05, 0.02, 0.3, -0.3, 0.3, 0.15)
include("setupSCR522ARadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

-- FuG 16ZY radio channel selector: 4 positions I/II/III/IV (arg 81, values 0.0/0.1/0.2/0.3)
-- Argument IDs are identical to the FW-190A8.
-- Upward transitions
onDeviceArgument(0, 81).valueAbove(0.05).fireSignal('FUG_UP_II')
onDeviceArgument(0, 81).valueAbove(0.15).fireSignal('FUG_UP_III')
onDeviceArgument(0, 81).valueAbove(0.25).fireSignal('FUG_UP_IV')
-- Downward transitions
onDeviceArgument(0, 81).valueBelow(0.25).fireSignal('FUG_DN_III')
onDeviceArgument(0, 81).valueBelow(0.15).fireSignal('FUG_DN_II')
onDeviceArgument(0, 81).valueBelow(0.05).fireSignal('FUG_DN_I')
