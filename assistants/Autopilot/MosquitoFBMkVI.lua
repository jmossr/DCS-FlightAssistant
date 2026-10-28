include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPitchSpeedOverrideControl(createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3), 70)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.002, 0.015, 0.001, 2, -0.1, 0.2, 0.05)
-- Heading was oscillating ±5° on ~8s period with P=0.8 max=±0.2: classic underdamped loop.
-- Lower P and max bank, raise D to damp. Slower ramp rate gives the bank controller time to respond.
local headingControl = createPDiController(0.5, 0.4, 0.05, 0.2, -0.12, 0.12, 0.04)

-- Rudder: sideslip computed from heading - track (velocity vector), not LoGetAngleOfSideSlip().
-- LoGetAngleOfSideSlip() was returning ~-7.7 rad (impossible; max aerodynamic sideslip is ±π/2).
-- Negative slip = nose left of velocity = engine torque condition → positive error → right rudder. Correct.
local rudderControl = createPDiController(1.5, 0.05, 0.02, 0.3, -0.3, 0.3, 0.15)
include("setupRadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

-- SCR-522A push buttons (cockpit arguments go to 1 while pressed). Read locally, so this works in multiplayer.
onDeviceArgument(0, 32).valueAbove(0.5).fireSignal('A/P_OFF')
onDeviceArgument(0, 33).valueAbove(0.5).fireSignal('RADIO_A')
onDeviceArgument(0, 34).valueAbove(0.5).fireSignal('RADIO_B')
onDeviceArgument(0, 35).valueAbove(0.5).fireSignal('RADIO_C')
onDeviceArgument(0, 36).valueAbove(0.5).fireSignal('RADIO_D')

-- Channel lamps
onDeviceArgument(0, 37).valueAbove(0.1).fireSignal('RADIO_A_L')
onDeviceArgument(0, 38).valueAbove(0.1).fireSignal('RADIO_B_L')
onDeviceArgument(0, 39).valueAbove(0.1).fireSignal('RADIO_C_L')
onDeviceArgument(0, 40).valueAbove(0.1).fireSignal('RADIO_D_L')