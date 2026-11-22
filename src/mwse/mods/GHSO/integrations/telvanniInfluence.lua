local journalAwards = require("GHSO.integrations.journalAwards")

local telvanniInfluence = {}

function telvanniInfluence.getTotal()
    return journalAwards.getTotal("influenceAwards", "telvanni")
end

return telvanniInfluence
