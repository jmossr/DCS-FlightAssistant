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
include("setupSCR522ARadioControlledAutopilot", altitudeControl, pitchControl, bankControl, headingControl, rudderControl)

onCommand(24, 3001).fireSignal('A/P_OFF')
onCommand(24, 3002).fireSignal('RADIO_A')
onCommand(24, 3003).fireSignal('RADIO_B')
onCommand(24, 3004).fireSignal('RADIO_C')
onCommand(24, 3005).fireSignal('RADIO_D')

onDeviceArgument(0, 37).valueAbove(0.1).fireSignal('RADIO_A_L')
onDeviceArgument(0, 38).valueAbove(0.1).fireSignal('RADIO_B_L')
onDeviceArgument(0, 39).valueAbove(0.1).fireSignal('RADIO_C_L')
onDeviceArgument(0, 40).valueAbove(0.1).fireSignal('RADIO_D_L')
