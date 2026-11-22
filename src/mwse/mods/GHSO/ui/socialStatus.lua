local telvanniInfluence = require("GHSO.integrations.telvanniInfluence")
local supplyClaims = require("GHSO.integrations.supplyClaims")
local supplyPrivileges = require("GHSO.data.telvanniSupplyPrivileges")
local supplyProviders = require("GHSO.data.telvanniSupplyProviders")

local socialStatus = {}

local function addWrappedLabel(container, text)
    local label = container:createLabel({ text = text })
    label.wrapText = true
    label.autoHeight = true
    label.widthProportional = 1.0
end

function socialStatus.register(suppliesPlugin)
    mwse.registerModConfig("GHSO", {
        onCreate = function(container)
            if not tes3.player then
                container:createLabel({ text = "Load a character to see GHSO status." })
                return
            end

            local influence = telvanniInfluence.getTotal()
            container:createLabel({ text = "House Telvanni influence: " .. tostring(influence or "unavailable") })

            if not tes3.isModActive(suppliesPlugin) then
                container:createLabel({ text = "Supplies: enable " .. suppliesPlugin })
                return
            end

            for _, privilege in ipairs(supplyPrivileges) do
                addWrappedLabel(container, privilege.label .. ": " .. supplyClaims.describeAvailability(privilege.id))
            end
            container:createLabel({ text = "Telvanni suppliers" })
            for _, provider in ipairs(supplyProviders) do
                addWrappedLabel(container, provider.name .. " - " .. provider.location)
            end
        end,
    })
end

return socialStatus
