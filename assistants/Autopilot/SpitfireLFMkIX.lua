include("setupSCR522ARadioTriggers",120)
include("setupSCR522ARadioAutopilotSequences")

--[[
  createPDiController(p, d, i, diCutOff, minOutput, maxOutput, maxOutputChangePerSecond)
]]--
local pitchControl = createPDiController(1.7, 0.4, 0.2, 0.15, -1, 1, 3)
local bankControl = createPDiController(1, 0.3, 0.5, 0.3, -1, 1, 3)
local altitudeControl = createPDiController(0.005, 0.015, 0.001, 2, -0.1, 0.3, 0.05)

include("setupSCR522ARadioControlledAutoPilot", altitudeControl, pitchControl, bankControl)