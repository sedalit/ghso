package.path = "src/mwse/mods/?.lua;" .. package.path

local callbacks = {}
local modConfig
local pluginActive = false
local gameHour = 1200
local faction = {
    playerJoined = true,
    playerExpelled = false,
    playerRank = 0,
    getRankName = function()
        return "Rank"
    end,
}

tes3 = {
    event = { initialized = "initialized", loaded = "loaded", modConfigReady = "modConfigReady" },
    isModActive = function(filename)
        assert(filename == "GHSO Gold Check.esp")
        return pluginActive
    end,
    getFaction = function(id)
        assert(id == "Telvanni")
        return faction
    end,
    getSimulationTimestamp = function()
        return gameHour
    end,
    getObject = function(id)
        assert(id == "p_restore_magicka_s" or id == "p_levitation_s")
        return {}
    end,
}
event = {
    register = function(name, callback)
        assert(callbacks[name] == nil)
        callbacks[name] = callback
    end,
}
mwse = {
    registerModConfig = function(name, package)
        assert(name == "GHSO" and modConfig == nil)
        modConfig = package
    end,
}

require("GHSO.main")
assert(modConfig == nil)
callbacks.modConfigReady()

local function openPage()
    local labels = {}
    modConfig.onCreate({
        createLabel = function(_, params)
            labels[#labels + 1] = params.text
            return {}
        end,
    })
    return labels
end

assert(openPage()[1]:find("Load a character", 1, true))

local playerData = {
    influenceAwards = { telvanni = { ht_muck = 1, ht_blackjinx = 1 } },
    claimedPrivileges = { telvanni_supplies = 1200, telvanni_levitation_supplies = 1300, bitter_coast_supplies = 1250 },
    regionalReputationAwards = { ["bitter coast region"] = { ms_fargothring = 1 } },
}
tes3.player = {
    supportsLuaData = true,
    data = { GHSO = { schemaVersion = 5, player = playerData } },
}
local inactive = openPage()
assert(inactive[1] == "House Telvanni influence: 2")
assert(#inactive == 2 and inactive[2] == "Supplies: enable GHSO Gold Check.esp")

pluginActive = true
local waiting = openPage()
assert(waiting[2]:find("168 game hour(s)", 1, true))
assert(waiting[3]:find("requires 3 Telvanni influence.", 1, true))
playerData.influenceAwards.telvanni.ht_daedraskin = 1
gameHour = 1368
local ready = openPage()
assert(#ready == 7)
assert(ready[2] == "Magicka supplies: Available now.")
assert(ready[3] == "Levitation supplies: Next supplies in 100 game hour(s).")
assert(ready[4] == "Telvanni suppliers")
assert(ready[5] == "Dalyne Arvel - Sadrith Mora, Telvanni Council House entrance")
assert(ready[6] == "Tinaso Alan - Tel Mora, Tower Services")
assert(ready[7] == "Garas Seloth - Vivec, Telvanni Alchemist")
faction.playerExpelled = true
assert(openPage()[2]:find("Only active members", 1, true))
assert(playerData.claimedPrivileges.bitter_coast_supplies == 1250)
assert(playerData.claimedPrivileges.telvanni_supplies == 1200 and not tes3.player.modified)
assert(playerData.claimedPrivileges.telvanni_levitation_supplies == 1300)

print("GHSO social status menu tests passed (" .. _VERSION .. ").")
