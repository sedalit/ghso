package.path = "src/mwse/mods/?.lua;" .. package.path

local supplies = require("GHSO.integrations.supplyClaims")
local claimId = "telvanni_supplies"
local levitationId = "telvanni_levitation_supplies"
local potion = {}
local levitationPotion = {}
local faction = {
    playerJoined = true,
    playerExpelled = false,
    playerRank = 0,
    playerReputation = 0,
    getRankName = function()
        return "First rank"
    end,
}
local supplier = { baseObject = { id = "Dalyne Arvel" } }
local tinaso = { baseObject = { id = "Tinaso Alan" } }
local garas = { baseObject = { id = "Garas Seloth" } }
local potionCount = 0
local levitationCount = 0
local gameHour = 1200
local lastMessage
local messageCount = 0
local addItem

tes3 = {
    getSimulationTimestamp = function()
        return gameHour
    end,
    getFaction = function(id)
        assert(id == "Telvanni")
        return faction
    end,
    getObject = function(id)
        if id == "p_levitation_s" then
            return levitationPotion
        end
        assert(id == "p_restore_magicka_s")
        return potion
    end,
    getItemCount = function(params)
        assert(params.reference == tes3.player)
        if params.item == levitationPotion then
            return levitationCount
        end
        assert(params.item == potion)
        return potionCount
    end,
    addItem = function(params)
        assert(params.reference == tes3.player and params.count == 1)
        return addItem(params.item)
    end,
    messageBox = function(format, ...)
        lastMessage = format:format(...)
        messageCount = messageCount + 1
    end,
}
mwse = { log = function() end }

local function useSave(awards, claims)
    local data = { influenceAwards = awards, claimedPrivileges = claims, regionalReputationAwards = {} }
    tes3.player = { supportsLuaData = true, data = { GHSO = { schemaVersion = 5, player = data } } }
end

local earned = { telvanni = { ht_muck = 1 } }
local claims = {}
useSave({}, claims)
supplies.claim(supplier)
assert(lastMessage:find("requires 1", 1, true) and not claims[claimId] and potionCount == 0)

useSave(earned, claims)
claims[claimId] = gameHour
supplies.claim(supplier)
assert(lastMessage:find("requires 3", 1, true) and not claims[levitationId])
claims[claimId] = nil

faction.playerJoined = false
supplies.claim(supplier)
assert(lastMessage:find("Only active members", 1, true) and not claims[claimId])
faction.playerJoined = true
faction.playerExpelled = true
supplies.claim(supplier)
assert(lastMessage:find("Only active members", 1, true) and not claims[claimId])
faction.playerExpelled = false
supplies.claim({ baseObject = { id = "fargoth" } })
assert(not claims[claimId])

addItem = function()
    return 0
end
supplies.claim(supplier)
assert(lastMessage:find("try again", 1, true) and not claims[claimId] and not tes3.player.modified)

addItem = function(item)
    assert(item == potion)
    assert(claims[claimId] == gameHour)
    local messagesBefore = messageCount
    supplies.claim(supplier)
    assert(messageCount == messagesBefore, "A nested claim must not produce a second receipt")
    potionCount = potionCount + 1
    return 1
end
supplies.claim(supplier)
assert(claims[claimId] == 1200 and potionCount == 1 and tes3.player.modified)
assert(lastMessage:find("received one", 1, true))
assert(earned.telvanni.ht_muck == 1)

local reloadedClaims = { [claimId] = claims[claimId] }
useSave(earned, reloadedClaims)
gameHour = 1367.5
supplies.claim(supplier)
assert(potionCount == 1 and lastMessage:find("1 game hour(s)", 1, true) and not tes3.player.modified)
gameHour = 1368
faction.playerExpelled = true
supplies.claim(supplier)
assert(lastMessage:find("Only active members", 1, true) and potionCount == 1)
faction.playerExpelled = false
addItem = function()
    return 0
end
supplies.claim(supplier)
assert(lastMessage:find("try again", 1, true) and reloadedClaims[claimId] == 1200)
addItem = function()
    potionCount = potionCount + 1
    return 1
end
supplies.claim(supplier)
assert(reloadedClaims[claimId] == 1368 and potionCount == 2)
supplies.claim(supplier)
assert(potionCount == 2 and lastMessage:find("168 game hour(s)", 1, true))

local otherSlot = {}
useSave(earned, otherSlot)
addItem = function()
    potionCount = potionCount + 1
    error("callback failed after delivery")
end
supplies.claim(supplier)
assert(otherSlot[claimId] == 1368 and potionCount == 3 and tes3.player.modified)
supplies.claim(supplier)
assert(potionCount == 3 and lastMessage:find("168 game hour(s)", 1, true))

earned.telvanni.ht_blackjinx = 1
earned.telvanni.ht_daedraskin = 1
gameHour = 1400
addItem = function(item)
    assert(item == levitationPotion)
    levitationCount = levitationCount + 1
    return 1
end
supplies.claim(supplier)
assert(otherSlot[claimId] == 1368 and otherSlot[levitationId] == 1400)
assert(potionCount == 3 and levitationCount == 1 and lastMessage:find("Standard Levitation potion", 1, true))
assert(lastMessage:find("136 game hour(s)", 1, true))

local bothReady = {}
useSave(earned, bothReady)
addItem = function(item)
    if item == potion then
        supplies.claim(supplier)
        assert(levitationCount == 1, "A nested claim must not deliver another supply type")
        potionCount = potionCount + 1
    else
        assert(item == levitationPotion)
        levitationCount = levitationCount + 1
    end
    return 1
end
local messagesBefore = messageCount
supplies.claim(tinaso)
assert(messageCount == messagesBefore + 1)
assert(bothReady[claimId] == 1400 and bothReady[levitationId] == 1400)
assert(potionCount == 4 and levitationCount == 2)
assert(lastMessage:find("Standard Restore Magicka potion", 1, true))
assert(lastMessage:find("Standard Levitation potion", 1, true))
supplies.claim(garas)
assert(potionCount == 4 and levitationCount == 2)
assert(lastMessage:find("Next supplies in 168", 1, true))

local partial = {}
useSave(earned, partial)
addItem = function(item)
    if item == potion then
        return 0
    end
    assert(item == levitationPotion)
    levitationCount = levitationCount + 1
    return 1
end
supplies.claim(garas)
assert(partial[claimId] == nil and partial[levitationId] == 1400)
assert(potionCount == 4 and levitationCount == 3)
assert(lastMessage:find("try again", 1, true) and lastMessage:find("Standard Levitation potion", 1, true))

local formerPilotClaims = { bitter_coast_supplies = 1200 }
useSave(earned, formerPilotClaims)
tes3.player.data.GHSO.player.regionalReputationAwards["bitter coast region"] = { ms_fargothring = 1 }
local messagesBeforeArrille = messageCount
supplies.claim({ baseObject = { id = "arrille" } })
assert(messageCount == messagesBeforeArrille and potionCount == 4 and levitationCount == 3)
assert(not tes3.player.modified and formerPilotClaims.bitter_coast_supplies == 1200)

print("Telvanni supplies tests passed (" .. _VERSION .. ").")
