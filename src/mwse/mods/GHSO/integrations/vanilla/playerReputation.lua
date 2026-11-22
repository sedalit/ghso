local playerReputation = {}

function playerReputation.get()
    local mobile = tes3.mobilePlayer
    local actor = mobile and mobile.object
    if actor then
        return actor.reputation
    end
end

return playerReputation
