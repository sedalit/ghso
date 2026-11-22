package.path = "src/mwse/mods/?.lua;" .. package.path

local callbacks = {}
local messages = {}
local journalIndex
local otherJournals = {}
local gameHour = 1200
tes3 = {
    event = { initialized = "initialized", loaded = "loaded", journal = "journal", modConfigReady = "modConfigReady" },
    isModActive = function()
        return false
    end,
    getJournalIndex = function(params)
        assert(params.id ~= "MS_FargothRing", "The regional pilot is paused")
        if params.id == "HT_Muck" then
            return journalIndex
        end
        return otherJournals[params.id]
    end,
    getSimulationTimestamp = function()
        return gameHour
    end,
}
event = {
    register = function(name, callback)
        assert(callbacks[name] == nil)
        callbacks[name] = callback
    end,
}
mwse = {
    buildDate = 20261110,
    log = function(format, ...)
        messages[#messages + 1] = format:format(...)
    end,
}

require("GHSO.main")
local influence = require("GHSO.integrations.telvanniInfluence")
callbacks.initialized()
assert(messages[1]:find("Core initialized", 1, true))

local function loadProfile(data, saveName)
    local reference = { supportsLuaData = true, data = data, modified = false }
    tes3.player = reference
    callbacks.loaded({ filename = saveName, newGame = saveName == nil })
    return reference.modified
end

local firstSlot = {}
journalIndex = 10
assert(loadProfile(firstSlot, "A"))
assert(firstSlot.GHSO.schemaVersion == 5)
assert(type(firstSlot.GHSO.player) == "table")
assert(type(firstSlot.GHSO.player.claimedPrivileges) == "table")
assert(influence.getTotal() == 0)
firstSlot.GHSO.player.marker = "A"

local secondSlot = {}
journalIndex = nil
assert(loadProfile(secondSlot))
assert(messages[#messages]:find("new game", 1, true))
assert(secondSlot.GHSO.player.marker == nil)
secondSlot.GHSO.player.marker = "B"

assert(not loadProfile(firstSlot, "A"))
assert(firstSlot.GHSO.player.marker == "A")
tes3.player.modified = false
callbacks.journal({ topic = { id = "HT_Muck" }, index = 10 })
callbacks.journal({ topic = { id = "HT_Stronghold" }, index = 100 })
assert(not tes3.player.modified and influence.getTotal() == 0)
journalIndex = 100
callbacks.journal({ topic = { id = "HT_Muck" }, index = 100 })
assert(influence.getTotal() == 1 and tes3.player.modified)
assert(firstSlot.GHSO.player.influenceAwards.telvanni.ht_muck == 1)
tes3.player.modified = false
callbacks.journal({ topic = { id = "ht_muck" }, index = 100 })
assert(influence.getTotal() == 1 and not tes3.player.modified)
assert(not loadProfile(firstSlot, "A"))
assert(influence.getTotal() == 1)

journalIndex = 10
assert(not loadProfile(secondSlot, "B"))
assert(secondSlot.GHSO.player.marker == "B")
assert(influence.getTotal() == 0)

otherJournals.HT_BlackJinx = 100
otherJournals.HT_CureBlight = 100
otherJournals.HT_DaedraSkin = 10
journalIndex = 100
assert(loadProfile(firstSlot, "A with completed additional quests"))
assert(influence.getTotal() == 3)
local telvanni = firstSlot.GHSO.player.influenceAwards.telvanni
assert(telvanni.ht_muck == 1 and telvanni.ht_blackjinx == 1 and telvanni.ht_cureblight == 1)
assert(telvanni.ht_daedraskin == nil and telvanni.ht_sloadsoap == nil)
assert(not loadProfile(firstSlot, "A with completed additional quests"))
otherJournals.HT_DaedraSkin = 100
otherJournals.HT_SloadSoap = 100
callbacks.journal({ topic = { id = "ht_daedraskin" }, index = 100 })
callbacks.journal({ topic = { id = "HT_SloadSoap" }, index = 100 })
callbacks.journal({ topic = { id = "HT_SloadSoap" }, index = 100 })
assert(influence.getTotal() == 5)
assert(telvanni.ht_daedraskin == 1 and telvanni.ht_sloadsoap == 1)
assert(not loadProfile(firstSlot, "A with all awards recorded"))
assert(influence.getTotal() == 5)
otherJournals = {}

local completedLegacy = { GHSO = { schemaVersion = 1, player = { marker = "legacy-1" } } }
journalIndex = 100
assert(loadProfile(completedLegacy, "completed legacy"))
assert(completedLegacy.GHSO.schemaVersion == 5)
assert(completedLegacy.GHSO.player.marker == "legacy-1")
assert(influence.getTotal() == 1)
assert(not loadProfile(completedLegacy, "completed legacy"))

local savedAwards = { telvanni = { ht_muck = 1 } }
local versionTwo = { GHSO = { schemaVersion = 2, player = { marker = "legacy-2", influenceAwards = savedAwards } } }
assert(loadProfile(versionTwo, "schema 2"))
assert(versionTwo.GHSO.schemaVersion == 5 and versionTwo.GHSO.player.influenceAwards == savedAwards)
assert(versionTwo.GHSO.player.marker == "legacy-2")
assert(type(versionTwo.GHSO.player.claimedPrivileges) == "table")
assert(influence.getTotal() == 1)
assert(not loadProfile(versionTwo, "schema 2"))
journalIndex = nil

local versionThree = {
    GHSO = {
        schemaVersion = 3,
        player = { influenceAwards = savedAwards, claimedPrivileges = { telvanni_supplies = true, other = true } },
    },
}
gameHour = nil
assert(not loadProfile(versionThree, "schema 3 with no game clock"))
assert(versionThree.GHSO.schemaVersion == 3 and versionThree.GHSO.player.claimedPrivileges.telvanni_supplies == true)
assert(messages[#messages]:find("game time is unavailable", 1, true))
gameHour = 1200.5
assert(loadProfile(versionThree, "schema 3"))
assert(versionThree.GHSO.schemaVersion == 5 and versionThree.GHSO.player.claimedPrivileges.telvanni_supplies == 1200.5)
assert(versionThree.GHSO.player.claimedPrivileges.other == true and influence.getTotal() == 1)
gameHour = 1350
assert(not loadProfile(versionThree, "schema 5"))
assert(versionThree.GHSO.player.claimedPrivileges.telvanni_supplies == 1200.5)

local versionFour = {
    GHSO = {
        schemaVersion = 4,
        player = { influenceAwards = savedAwards, claimedPrivileges = { telvanni_supplies = 1200.5 } },
    },
}
assert(loadProfile(versionFour, "schema 4 with Fargoth's ring returned"))
assert(versionFour.GHSO.schemaVersion == 5 and versionFour.GHSO.player.claimedPrivileges.telvanni_supplies == 1200.5)
assert(versionFour.GHSO.player.influenceAwards == savedAwards and influence.getTotal() == 1)
assert(next(versionFour.GHSO.player.regionalReputationAwards) == nil)
assert(not loadProfile(versionFour, "schema 5 with Fargoth's ring returned"))
callbacks.journal({ topic = { id = "ms_fargothring" }, index = 100 })
assert(not tes3.player.modified and next(versionFour.GHSO.player.regionalReputationAwards) == nil)

local pilotData = versionFour.GHSO.player
pilotData.regionalReputationAwards["bitter coast region"] = { ms_fargothring = 1 }
pilotData.claimedPrivileges.bitter_coast_supplies = 1250
assert(not loadProfile(versionFour, "schema 5 with data from the regional pilot"))
assert(pilotData.regionalReputationAwards["bitter coast region"].ms_fargothring == 1)
assert(pilotData.claimedPrivileges.bitter_coast_supplies == 1250)
assert(pilotData.claimedPrivileges.telvanni_supplies == 1200.5 and influence.getTotal() == 1)

local missingPlayer = { GHSO = { schemaVersion = 0, marker = "legacy" } }
assert(loadProfile(missingPlayer, "legacy"))
assert(missingPlayer.GHSO.schemaVersion == 5)
assert(type(missingPlayer.GHSO.player) == "table")
assert(missingPlayer.GHSO.marker == "legacy")
assert(not loadProfile(missingPlayer, "legacy"))

local populatedLegacy = { GHSO = { schemaVersion = 0, player = { marker = "legacy" } } }
local legacyPlayer = populatedLegacy.GHSO.player
assert(loadProfile(populatedLegacy, "populated legacy"))
assert(populatedLegacy.GHSO.schemaVersion == 5)
assert(populatedLegacy.GHSO.player == legacyPlayer)
assert(legacyPlayer.marker == "legacy")

local future = setmetatable({ schemaVersion = 6, marker = "future" }, {
    __index = function()
        error("Core inspected a field from a newer schema")
    end,
    __newindex = function()
        error("Core wrote a field into a newer schema")
    end,
})
assert(not loadProfile({ GHSO = future }, "future"))
assert(future.schemaVersion == 6 and future.marker == "future")
assert(messages[#messages]:find("newer schema", 1, true))
callbacks.journal({ topic = { id = "HT_Muck" }, index = 100 })
assert(influence.getTotal() == nil)

for _, invalid in ipairs({
    false,
    { player = {} },
    { schemaVersion = 0, player = false },
    { schemaVersion = 1 },
    { schemaVersion = 2, player = {} },
    { schemaVersion = 3, player = { influenceAwards = {} } },
    { schemaVersion = 5, player = { influenceAwards = {}, claimedPrivileges = {} } },
    { schemaVersion = 3, player = { influenceAwards = {}, claimedPrivileges = { telvanni_supplies = false } } },
    { schemaVersion = 2, player = { influenceAwards = {}, claimedPrivileges = false } },
    { schemaVersion = 1, player = { influenceAwards = false } },
    { schemaVersion = 1.5, player = {} },
    { schemaVersion = math.huge, player = {} },
}) do
    local slot = { GHSO = invalid }
    assert(not loadProfile(slot, "invalid"))
    assert(slot.GHSO == invalid)
end

local invalidFaction = {
    GHSO = {
        schemaVersion = 5,
        player = { influenceAwards = { telvanni = false }, claimedPrivileges = {}, regionalReputationAwards = {} },
    },
}
journalIndex = 100
assert(not loadProfile(invalidFaction, "invalid faction"))
assert(invalidFaction.GHSO.player.influenceAwards.telvanni == false)
assert(influence.getTotal() == nil)
journalIndex = nil

tes3.player = nil
callbacks.loaded({ filename = "no player" })
assert(messages[#messages]:find("unavailable", 1, true))

tes3.player = setmetatable({ supportsLuaData = false }, {
    __index = function()
        error("Core accessed data for an unsupported reference")
    end,
})
callbacks.loaded({ filename = "unsupported player" })
assert(messages[#messages]:find("unavailable", 1, true))

print("Profile tests passed (" .. _VERSION .. ").")
