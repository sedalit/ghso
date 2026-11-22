local awardLedger = {}

local function isValidPoints(points)
    return type(points) == "number" and points > 0 and points % 1 == 0
end

function awardLedger.getTotal(awards, scopeId)
    local entries = awards[scopeId]
    if entries == nil then
        return 0
    end
    if type(entries) ~= "table" then
        return nil
    end

    local total = 0
    for _, points in pairs(entries) do
        if not isValidPoints(points) then
            return nil
        end
        total = total + points
    end
    return total
end

function awardLedger.award(awards, scopeId, sourceId, points)
    if not isValidPoints(points) then
        return false, "invalid award points"
    end
    if awardLedger.getTotal(awards, scopeId) == nil then
        return false, "invalid saved awards"
    end

    local entries = awards[scopeId]
    if entries == nil then
        awards[scopeId] = {}
        entries = awards[scopeId]
    end
    if entries[sourceId] ~= nil then
        return false
    end

    entries[sourceId] = points
    return true
end

return awardLedger
