local playerGold = {}

function playerGold.get()
    if tes3.player then
        return tes3.getPlayerGold()
    end
end

return playerGold
