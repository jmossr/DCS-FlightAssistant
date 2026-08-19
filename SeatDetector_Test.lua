-- SeatDetector_Test.lua
-- Detects pilot vs navigator seat via group unit index. SP only (first pass).
-- Load via DO SCRIPT FILE on MISSION START (after MIST if used).
-- Check dcs.log for "SeatDetector" entries after testing.

local seatState = { seat = nil }

local function detectSeat(unit)
    if not unit or not unit:isExist() then return nil end
    local group = unit:getGroup()
    if not group then return nil end
    local units  = group:getUnits()
    local myName = unit:getName()
    if     units[1] and units[1]:getName() == myName then return "pilot"
    elseif units[2] and units[2]:getName() == myName then return "navigator"
    end
    return nil
end

local SeatHandler = {}
function SeatHandler:onEvent(event)
    if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT then
        local unit = event.initiator
        if not unit or not unit:isExist() then return end
        local seat = detectSeat(unit)
        seatState.seat = seat
        local msg = string.format("SeatDetector: seat=%s  unit=%s  type=%s",
            tostring(seat), unit:getName(), unit:getTypeName())
        trigger.action.outText(msg, 8)
        log.write("SeatDetector", log.DEBUG, msg)

    elseif event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT then
        log.write("SeatDetector", log.DEBUG, "Left unit – was: " .. tostring(seatState.seat))
        seatState.seat = nil
    end
end
world.addEventHandler(SeatHandler)

-- On load: dump all group/unit names so we can see how DCS names the Mosquito slots
timer.scheduleFunction(function(_, t)
    pcall(function()
        for _, coa in ipairs({ coalition.side.BLUE, coalition.side.RED }) do
            local groups = coalition.getGroups(coa, Group.Category.AIRPLANE)
            if groups then
                for _, grp in ipairs(groups) do
                    local units = grp:getUnits()
                    for i, u in ipairs(units) do
                        log.write("SeatDetector", log.DEBUG, string.format(
                            "Group: %-20s  slot[%d]: %-30s  type: %s",
                            grp:getName(), i, u:getName(), u:getTypeName()))
                    end
                end
            end
        end
    end)
    return nil
end, {}, timer.getTime() + 2)

trigger.action.outText("SeatDetector LOADED", 5)
