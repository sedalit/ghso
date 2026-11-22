local profile = {
    schemaVersion = 5,
}

function profile.initialize(data, getGameHour)
    local root = data.GHSO
    if root == nil then
        -- MWSE save data requires nested tables to be initialized one level at a time.
        data.GHSO = {}
        root = data.GHSO
        root.player = {}
        root.player.influenceAwards = {}
        root.player.claimedPrivileges = {}
        root.player.regionalReputationAwards = {}
        root.schemaVersion = profile.schemaVersion
        return true, ("Created profile with schema %d."):format(profile.schemaVersion)
    end

    if type(root) ~= "table" then
        return false, "Skipped profile because the GHSO root is not a table."
    end

    local version = root.schemaVersion
    if type(version) ~= "number" or version < 0 or version % 1 ~= 0 then
        return false, "Skipped profile because schemaVersion is invalid."
    end

    if version > profile.schemaVersion then
        return false, ("Skipped profile with newer schema %s."):format(tostring(version))
    end

    local player = root.player
    if type(player) ~= "table" and not (version == 0 and player == nil) then
        return false, "Skipped profile because the player table is missing or invalid."
    end

    local awards = player and player.influenceAwards
    if (version >= 2 or awards ~= nil) and type(awards) ~= "table" then
        return false, "Skipped profile because the influence awards table is missing or invalid."
    end

    local claims = player and player.claimedPrivileges
    if (version >= 3 or claims ~= nil) and type(claims) ~= "table" then
        return false, "Skipped profile because the claimed privileges table is missing or invalid."
    end

    local regionalAwards = player and player.regionalReputationAwards
    if (version >= 5 or regionalAwards ~= nil) and type(regionalAwards) ~= "table" then
        return false, "Skipped profile because the regional reputation awards table is missing or invalid."
    end

    local migratedClaimHour
    local previousSupplyClaim = claims and claims.telvanni_supplies
    if version < 4 and previousSupplyClaim ~= nil then
        if previousSupplyClaim ~= true then
            return false, "Skipped profile because the old Telvanni supplies claim is invalid."
        end
        migratedClaimHour = getGameHour and getGameHour()
        if migratedClaimHour == nil then
            return false, "Skipped Telvanni supplies migration because game time is unavailable."
        end
    end

    if version == 0 then
        if player == nil then
            root.player = {}
            player = root.player
        end
        root.schemaVersion = 1
    end
    if root.schemaVersion == 1 then
        if awards == nil then
            player.influenceAwards = {}
        end
        root.schemaVersion = 2
    end
    if root.schemaVersion == 2 then
        if claims == nil then
            player.claimedPrivileges = {}
        end
        root.schemaVersion = 3
    end
    if root.schemaVersion == 3 then
        if migratedClaimHour ~= nil then
            claims.telvanni_supplies = migratedClaimHour
        end
        root.schemaVersion = 4
    end
    if root.schemaVersion == 4 then
        if regionalAwards == nil then
            player.regionalReputationAwards = {}
        end
        root.schemaVersion = 5
        return true, ("Migrated profile from schema %d to %d."):format(version, profile.schemaVersion)
    end

    return false, ("Loaded profile with schema %d."):format(version)
end

function profile.getPlayerData(data)
    local root = data.GHSO
    if type(root) == "table" and root.schemaVersion == profile.schemaVersion then
        local player = root.player
        if type(player) == "table" and type(player.influenceAwards) == "table"
            and type(player.claimedPrivileges) == "table" and type(player.regionalReputationAwards) == "table" then
            return player
        end
    end
end

return profile
