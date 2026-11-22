local profile = require("GHSO.core.profile")
local goldCheckDialogue = require("GHSO.integrations.goldCheckDialogue")
local journalAwards = require("GHSO.integrations.journalAwards")
local supplyClaims = require("GHSO.integrations.supplyClaims")
local gameTime = require("GHSO.integrations.vanilla.gameTime")
local socialStatus = require("GHSO.ui.socialStatus")

local testPlugin = "GHSO Gold Check.esp"

local function onInitialized()
    mwse.log("[GHSO] Core initialized. Supported profile schema: %d. MWSE build date: %s.",
        profile.schemaVersion, tostring(mwse.buildDate))
    journalAwards.register()
    if tes3.isModActive(testPlugin) then
        goldCheckDialogue.register()
        supplyClaims.register()
    else
        mwse.log("[GHSO] Diagnostic plugin inactive: " .. testPlugin)
    end
end

local function onLoaded(e)
    local player = tes3.player
    if not player or not player.supportsLuaData then
        mwse.log("[GHSO] Skipped profile because player save data is unavailable.")
        return
    end

    local changed, message = profile.initialize(player.data, gameTime.getHour)
    if changed then
        player.modified = true
    end
    local saveName = e.newGame and "new game" or tostring(e.filename)
    mwse.log("[GHSO] %s (%s)", message, saveName)
    journalAwards.reconcile(player)
end

event.register(tes3.event.initialized, onInitialized)
event.register(tes3.event.loaded, onLoaded)
event.register(tes3.event.modConfigReady, function()
    socialStatus.register(testPlugin)
end)
