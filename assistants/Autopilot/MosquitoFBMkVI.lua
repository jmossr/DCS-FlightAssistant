include("setupSCR522ARadioTriggers",37)
include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPDiController(2, 0.1, 0.2, 0.15, -1, 1, 3)
local bankControl = createPDiController(3, 0.4, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.2, 0.05)

include("setupSCR522ARadioControlledAutoPilot", altitudeControl, pitchControl, bankControl)