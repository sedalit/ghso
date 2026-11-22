local playerGold = require("GHSO.integrations.vanilla.playerGold")
local playerReputation = require("GHSO.integrations.vanilla.playerReputation")
local playerFaction = require("GHSO.integrations.vanilla.playerFaction")
local dialogueContext = require("GHSO.integrations.vanilla.dialogueContext")
local telvanniInfluence = require("GHSO.integrations.telvanniInfluence")

local goldCheckDialogue = {}

local topic = "GHSO Gold Check"
local threshold = 100

local function unlockTopic()
    if tes3.addTopic({ topic = topic }) then
        mwse.log("[GHSO] Added dialogue topic: " .. topic)
    else
        mwse.log("[GHSO] Dialogue topic was not added (it may already be known): " .. topic)
    end
end

function goldCheckDialogue.register()
    event.register(tes3.event.loaded, unlockTopic)
end

local function describeTelvanni()
    local status = playerFaction.get("Telvanni")
    if not status then
        return "House Telvanni: unavailable."
    end

    local membership
    if status.expelled then
        membership = "expelled."
    elseif not status.joined then
        membership = "not a member."
    elseif status.rank == nil then
        membership = "member. Rank: unavailable."
    else
        local rank = tostring(status.rank)
        if status.rankName and status.rankName ~= "" then
            rank = ("%s (%d)"):format(status.rankName, status.rank)
        end
        membership = "member. Rank: " .. rank .. "."
    end

    return ("House Telvanni: %s Faction reputation: %d."):format(membership, status.reputation)
end

function goldCheckDialogue.respond(reference)
    local gold = playerGold.get()
    if gold == nil then
        mwse.log("[GHSO] Gold check skipped because the player is unavailable.")
        return
    end

    local reputation = tostring(playerReputation.get() or "unavailable")
    local goldMessage
    if gold >= threshold then
        goldMessage = "You carry at least %d gold."
    else
        goldMessage = "You carry less than %d gold."
    end

    local context = dialogueContext.read(reference)
    local playerDetails = ("Current gold: %d. General reputation: %s. %s GHSO Telvanni influence: %s."):format(
        gold, reputation, describeTelvanni(), tostring(telvanniInfluence.getTotal() or "unavailable"))
    local contextDetails = ("Race: %s. Region: %s. Disposition: %s."):format(
        context.raceName or "unavailable",
        context.regionName or "unavailable",
        tostring(context.disposition or "unavailable"))
    mwse.log("[GHSO] Gold check selected. %s %s", playerDetails, contextDetails)
    tes3.messageBox("[GHSO test] %s %s %s", goldMessage:format(threshold), playerDetails, contextDetails)
end

return goldCheckDialogue
