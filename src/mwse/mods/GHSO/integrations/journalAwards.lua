local profile = require("GHSO.core.profile")
local awardLedger = require("GHSO.domain.awardLedger")

local journalAwards = {}
local groups = {
    {
        field = "influenceAwards",
        scope = "telvanni",
        label = "Telvanni influence",
        sources = require("GHSO.data.telvanniInfluenceSources"),
    },
}

local topics, topicsById = {}, {}
for _, group in ipairs(groups) do
    local seen = {}
    for _, source in ipairs(group.sources) do
        local key = source.journalId:lower()
        assert(not seen[key], "Duplicate GHSO journal source: " .. source.journalId)
        seen[key] = true

        local topic = topicsById[key]
        if not topic then
            topic = { id = source.journalId, key = key, rules = {} }
            topicsById[key] = topic
            topics[#topics + 1] = topic
        end
        topic.rules[#topic.rules + 1] = { group = group, source = source }
    end
end

local function getPlayerData(player)
    if player and player.supportsLuaData then
        return profile.getPlayerData(player.data)
    end
end

local function record(player, data, topic, index)
    for _, rule in ipairs(topic.rules) do
        local group, source = rule.group, rule.source
        if index == source.completion then
            local added, problem = awardLedger.award(data[group.field], group.scope, topic.key, source.points)
            if added then
                player.modified = true
                mwse.log("[GHSO] Recorded %s +%d (%s, journal %d).",
                    group.label, source.points, topic.id, index)
            elseif problem then
                mwse.log("[GHSO] Skipped %s (%s): %s.", group.label, topic.id, problem)
            end
        end
    end
end

function journalAwards.reconcile(player)
    local data = getPlayerData(player)
    if data then
        for _, topic in ipairs(topics) do
            record(player, data, topic, tes3.getJournalIndex({ id = topic.id }))
        end
    end
end

function journalAwards.getTotal(field, scope)
    local data = getPlayerData(tes3.player)
    if data then
        return awardLedger.getTotal(data[field], scope)
    end
end

function journalAwards.register()
    event.register(tes3.event.journal, function(e)
        local topic = e.topic and topicsById[e.topic.id:lower()]
        if topic then
            local player = tes3.player
            local data = getPlayerData(player)
            if data then
                record(player, data, topic, e.index)
            end
        end
    end)
end

return journalAwards
