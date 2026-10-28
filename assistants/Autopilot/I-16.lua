include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
  Gains are starting-point estimates copied from the Bf-109K-4 — tune in-flight.
  The I-16 is short-coupled and twitchy in pitch; lower the pitch P first if it porpoises.
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3), 70)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.002, 0.015, 0.001, 2, -0.1, 0.2, 0.05)
local headingControl = createPDiController(0.5, 0.4, 0.05, 0.2, -0.12, 0.12, 0.04)
local rudderControl = createPDiController(1.5, 0.05, 0.02, 0.3, -0.3, 0.3, 0.15)
include("setupRadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

-- The I-16 has no radio channel panel, so four controls without effect in the sim stand in
-- for SCR-522A channels A-D. Any flip of a switch (either direction) counts as a press.
--   A = Clock heat switch (arg 23, not simulated)
--   B = Pitot heat switch (arg 24, not simulated)
--   C = Nav light test button (arg 32)
--   D = Radio switch (arg 28, not simulated)
onDeviceArgument(0, 23).valueAbove(0.5).fireSignal('RADIO_A')
onDeviceArgument(0, 23).valueBelow(0.5).fireSignal('RADIO_A')
onDeviceArgument(0, 24).valueAbove(0.5).fireSignal('RADIO_B')
onDeviceArgument(0, 24).valueBelow(0.5).fireSignal('RADIO_B')
onDeviceArgument(0, 32).valueAbove(0.5).fireSignal('RADIO_C')
onDeviceArgument(0, 28).valueAbove(0.5).fireSignal('RADIO_D')
onDeviceArgument(0, 28).valueBelow(0.5).fireSignal('RADIO_D')
