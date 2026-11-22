local gameTime = {}

function gameTime.isValidHour(hour)
    return type(hour) == "number" and hour >= 0 and hour < math.huge
end

function gameTime.getHour()
    local hour = tes3.getSimulationTimestamp()
    if gameTime.isValidHour(hour) then
        return hour
    end
end

return gameTime
