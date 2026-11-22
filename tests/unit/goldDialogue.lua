package.path = "src/mwse/mods/?.lua;" .. package.path

local gold = 0
local reads = 0
local displayed = {}
local logged = {}
local faction
local rankLookups = 0
local region

tes3 = {
    getRegion = function()
        return region
    end,
    getFaction = function(id)
        assert(id == "Telvanni")
        return faction
    end,
    getPlayerGold = function()
        reads = reads + 1
        return gold
    end,
    messageBox = function(format, ...)
        displayed[#displayed + 1] = format:format(...)
    end,
}
mwse = {
    log = function(format, ...)
        logged[#logged + 1] = format:format(...)
    end,
}

local playerGold = require("GHSO.integrations.vanilla.playerGold")
local playerReputation = require("GHSO.integrations.vanilla.playerReputation")
local playerFaction = require("GHSO.integrations.vanilla.playerFaction")
local dialogue = require("GHSO.integrations.goldCheckDialogue")

assert(playerGold.get() == nil)
assert(playerReputation.get() == nil)
assert(playerFaction.get("Telvanni") == nil)
dialogue.respond()
assert(reads == 0 and #displayed == 0)
assert(#logged == 1 and logged[1]:find("player is unavailable", 1, true))

tes3.player = {}
tes3.mobilePlayer = { object = { reputation = 0, race = { name = "Dark Elf" } } }
region = { name = "Bitter Coast" }
local fargoth = { mobile = { object = { disposition = 0 } } }
assert(playerGold.get() == 0 and reads == 1)
dialogue.respond(fargoth)
assert(reads == 2 and displayed[1]:find("Current gold: 0.", 1, true))
assert(displayed[1]:find("General reputation: 0.", 1, true))
assert(displayed[1]:find("House Telvanni: unavailable.", 1, true))
assert(displayed[1]:find("GHSO Telvanni influence: unavailable.", 1, true))
assert(displayed[1]:find("Race: Dark Elf. Region: Bitter Coast. Disposition: 0.", 1, true))

local rankNames = { [0] = "First rank", [1] = "Next rank" }
faction = {
    playerJoined = false,
    playerExpelled = false,
    playerRank = 0,
    playerReputation = 4,
    getRankName = function(self, rank)
        assert(self == faction and rank == faction.playerRank)
        rankLookups = rankLookups + 1
        return rankNames[rank]
    end,
}
gold = 99
dialogue.respond()
assert(reads == 3 and displayed[2]:find("less than 100 gold. Current gold: 99.", 1, true))
assert(displayed[2]:find("House Telvanni: not a member. Faction reputation: 4.", 1, true))
assert(rankLookups == 0)

gold = 100
tes3.mobilePlayer.object.reputation = 12
faction.playerJoined = true
faction.playerReputation = 0
tes3.player.supportsLuaData = true
tes3.player.data = {
    GHSO = {
        schemaVersion = 5,
        player = {
            influenceAwards = { telvanni = { ht_muck = 1 } },
            claimedPrivileges = {},
            regionalReputationAwards = { ["bitter coast region"] = { ms_fargothring = 1 } },
        },
    },
}
fargoth.mobile.object.disposition = 70
dialogue.respond(fargoth)
assert(reads == 4 and displayed[3]:find("at least 100 gold. Current gold: 100.", 1, true))
assert(displayed[3]:find("General reputation: 12.", 1, true))
assert(logged[#logged]:find("General reputation: 12. House Telvanni: member. Rank: First rank (0). Faction reputation: 0.", 1, true))
assert(displayed[3]:find("GHSO Telvanni influence: 1.", 1, true))
assert(not displayed[3]:find("GHSO Bitter Coast reputation", 1, true))
assert(logged[#logged]:find("Race: Dark Elf. Region: Bitter Coast. Disposition: 70.", 1, true))

gold = 42
tes3.mobilePlayer.object = nil
region = nil
faction.playerExpelled = true
dialogue.respond({})
assert(reads == 5 and displayed[4]:find("less than 100 gold. Current gold: 42.", 1, true))
assert(displayed[4]:find("General reputation: unavailable.", 1, true))
assert(displayed[4]:find("House Telvanni: expelled. Faction reputation: 0.", 1, true))
assert(displayed[4]:find("Race: unavailable. Region: unavailable. Disposition: unavailable.", 1, true))
assert(rankLookups == 1)

faction.playerExpelled = false
faction.playerRank = 1
faction.playerReputation = 7
dialogue.respond()
assert(displayed[5]:find("House Telvanni: member. Rank: Next rank (1). Faction reputation: 7.", 1, true))

local pluginActive = false
local callbacks = {}
local unlockAttempts = {}
tes3.event = {
    initialized = "initialized",
    loaded = "loaded",
    disposition = "disposition",
    journal = "journal",
    modConfigReady = "modConfigReady",
}
tes3.getJournalIndex = function()
    return nil
end
tes3.isModActive = function(filename)
    assert(filename == "GHSO Gold Check.esp")
    return pluginActive
end
tes3.addTopic = function(params)
    assert(params.topic == "GHSO Gold Check" or params.topic == "GHSO Claim Supplies")
    local count = (unlockAttempts[params.topic] or 0) + 1
    unlockAttempts[params.topic] = count
    return count == 1
end
event = {
    register = function(name, callback)
        assert(name ~= "disposition", "The diagnostic ESP must leave disposition calculations to the game")
        callbacks[name][#callbacks[name] + 1] = callback
    end,
}

local function boot()
    callbacks = { initialized = {}, loaded = {}, journal = {}, modConfigReady = {} }
    package.loaded["GHSO.main"] = nil
    require("GHSO.main")
    for _, callback in ipairs(callbacks.initialized) do
        callback()
    end
    assert(next(unlockAttempts) == nil, "Topics must wait until a game has loaded")
end

local function loadSave()
    tes3.player = { supportsLuaData = true, data = {} }
    for _, callback in ipairs(callbacks.loaded) do
        callback({ filename = "test save" })
    end
end

boot()
loadSave()
assert(next(unlockAttempts) == nil, "Core without the ESP must leave topics alone")

pluginActive = true
boot()
loadSave()
assert(unlockAttempts["GHSO Gold Check"] == 1)
assert(unlockAttempts["GHSO Claim Supplies"] == 1)
assert(logged[#logged]:find("Added dialogue topic", 1, true))
loadSave()
assert(unlockAttempts["GHSO Gold Check"] == 2)
assert(unlockAttempts["GHSO Claim Supplies"] == 2)
assert(#displayed == 5, "Unlocking the topic must not trigger the response")

print("Gold dialogue tests passed (" .. _VERSION .. ").")
