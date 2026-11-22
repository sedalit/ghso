local profile = require("GHSO.core.profile")
local playerFaction = require("GHSO.integrations.vanilla.playerFaction")
local telvanniInfluence = require("GHSO.integrations.telvanniInfluence")
local gameTime = require("GHSO.integrations.vanilla.gameTime")
local telvanniPrivileges = require("GHSO.data.telvanniSupplyPrivileges")
local telvanniProviders = require("GHSO.data.telvanniSupplyProviders")

local supplyClaims = {}
local topic = "GHSO Claim Supplies"
local claiming = false

local function telvanniDenial(privilege)
    local faction = playerFaction.get("Telvanni")
    if not faction or not faction.joined or faction.expelled then
        return "Only active members of House Telvanni may claim these supplies."
    end
    if (telvanniInfluence.getTotal() or 0) < privilege.requiredInfluence then
        return ("Claiming these supplies requires %d Telvanni influence."):format(privilege.requiredInfluence)
    end
end

local providersById = {}
for _, provider in ipairs(telvanniProviders) do
    assert(not providersById[provider.id], "Duplicate supply provider: " .. provider.id)
    providersById[provider.id] = true
end

local privilegesById = {}
for _, privilege in ipairs(telvanniPrivileges) do
    assert(not privilegesById[privilege.id], "Duplicate supply privilege: " .. privilege.id)
    privilegesById[privilege.id] = privilege
end

local statusMessages = {
    noProfile = "The supplies record is unavailable.",
    invalidTime = "The supplies schedule is unavailable.",
    missingItem = "The supplies are currently unavailable.",
    ready = "Available now.",
}

local function getClaims(player)
    if player and player.supportsLuaData then
        local data = profile.getPlayerData(player.data)
        return data and data.claimedPrivileges
    end
end

local function getAvailability(player, privilege)
    local claims = getClaims(player)
    if not claims then
        return { code = "noProfile" }
    end

    local denial = telvanniDenial(privilege)
    if denial then
        return { code = "ineligible", message = denial }
    end

    local now = gameTime.getHour()
    local previous = claims[privilege.id]
    if now == nil or (previous ~= nil and not gameTime.isValidHour(previous)) then
        return { code = "invalidTime" }
    end
    if previous ~= nil then
        local remaining = previous + privilege.renewalHours - now
        if remaining > 0 then
            return { code = "waiting", hours = math.ceil(remaining) }
        end
    end

    local item = tes3.getObject(privilege.item)
    if not item then
        return { code = "missingItem" }
    end

    return { code = "ready", claims = claims, now = now, item = item }
end

local function describe(availability)
    if availability.code == "waiting" then
        return ("Next supplies in %d game hour(s)."):format(availability.hours)
    end
    return availability.message or statusMessages[availability.code]
end

function supplyClaims.describeAvailability(privilegeId)
    local privilege = privilegesById[privilegeId]
    if not privilege then
        return statusMessages.missingItem
    end
    return describe(getAvailability(tes3.player, privilege))
end

local function deliver(player, claimId, availability)
    local claims, item, now = availability.claims, availability.item, availability.now
    local inventory = { reference = player, item = item }
    local before = tes3.getItemCount(inventory)

    -- Reserve the claim before addItem can fire callbacks from other mods.
    local previous = claims[claimId]
    claims[claimId] = now
    local ok, added = pcall(tes3.addItem, { reference = player, item = item, count = 1, showMessage = false })
    if ok and added == 1 then
        player.modified = true
        return true
    end

    -- Some callbacks may fail after the inventory has already changed.
    mwse.log("[GHSO] Supply delivery returned %s (%s, success: %s).", tostring(added), claimId, tostring(ok))
    local checked, after = pcall(tes3.getItemCount, inventory)
    if not checked then
        player.modified = true
        mwse.log("[GHSO] Supply delivery could not be verified (%s): %s.", claimId, tostring(after))
        return nil
    end
    if after > before then
        player.modified = true
        return true
    end

    claims[claimId] = previous
    return false
end

local function claimOne(player, privilege)
    local availability = getAvailability(player, privilege)
    if availability.code ~= "ready" then
        if availability.code == "invalidTime" then
            mwse.log("[GHSO] Supplies unavailable (%s): claim time is invalid.", privilege.id)
        elseif availability.code == "missingItem" then
            mwse.log("[GHSO] Supply item missing: " .. privilege.item)
        end
        return describe(availability)
    end

    local delivered = deliver(player, privilege.id, availability)
    if delivered then
        mwse.log("[GHSO] Claimed privilege: %s (game hour %.2f).", privilege.id, availability.now)
        return ("You received %s."):format(privilege.reward)
    end
    if delivered == false then
        return "The supplies could not be delivered. You may try again."
    end
    return "Delivery could not be verified. The claim has been recorded."
end

function supplyClaims.claim(reference)
    local speaker = reference and reference.baseObject
    if not speaker or not providersById[speaker.id:lower()] then
        mwse.log("[GHSO] Ignored a claim outside a supplier's dialogue.")
        return
    end
    if claiming then
        return
    end

    claiming = true
    local player = tes3.player
    local messages = {}
    for _, privilege in ipairs(telvanniPrivileges) do
        local ok, message = pcall(claimOne, player, privilege)
        if not ok then
            mwse.log("[GHSO] Supply claim failed (%s): %s.", privilege.id, tostring(message))
            message = "The claim could not be completed. See MWSE.log."
        end
        messages[#messages + 1] = privilege.label .. ": " .. message
    end
    claiming = false
    tes3.messageBox("[GHSO] %s", table.concat(messages, " "))
end

function supplyClaims.register()
    event.register(tes3.event.loaded, function()
        if tes3.addTopic({ topic = topic }) then
            mwse.log("[GHSO] Added dialogue topic: " .. topic)
        end
    end)
end

return supplyClaims
