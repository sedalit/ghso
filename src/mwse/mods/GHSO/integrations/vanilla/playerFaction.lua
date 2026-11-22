local playerFaction = {}

local function findFaction(factionId)
    if tes3.player then
        return tes3.getFaction(factionId)
    end
end

local function activeRank(faction, joined, expelled)
    if joined and not expelled then
        local rank = faction.playerRank
        if rank >= 0 and rank <= 9 then
            return rank
        end
    end
end

function playerFaction.get(factionId)
    local faction = findFaction(factionId)
    if not faction then
        return nil
    end

    local status = {
        joined = faction.playerJoined,
        expelled = faction.playerExpelled,
        reputation = faction.playerReputation,
    }
    status.rank = activeRank(faction, status.joined, status.expelled)
    if status.rank then
        status.rankName = faction:getRankName(status.rank)
    end

    return status
end

return playerFaction
