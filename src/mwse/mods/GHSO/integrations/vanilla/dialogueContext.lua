local dialogueContext = {}

function dialogueContext.read(reference)
    local player = tes3.mobilePlayer
    local playerActor = player and player.object
    local race = playerActor and playerActor.race
    local region = tes3.getRegion()
    local speaker = reference and reference.mobile
    local speakerActor = speaker and speaker.object

    return {
        raceName = race and race.name,
        regionName = region and region.name,
        disposition = speakerActor and speakerActor.disposition,
    }
end

return dialogueContext
