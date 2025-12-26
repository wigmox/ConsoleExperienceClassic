--[[
    ConsoleExperienceClassic
    A controller-style action bar for WoW 1.12
    
    Main entry point - creates the ConsoleExperience global frame
    that other modules attach to.
]]

_G = getfenv(0)

-- Create the main addon frame
ConsoleExperience = CreateFrame("Frame", nil, UIParent)
ConsoleExperience:RegisterEvent("ADDON_LOADED")
ConsoleExperience:RegisterEvent("VARIABLES_LOADED")
ConsoleExperience:RegisterEvent("PLAYER_ENTERING_WORLD")
ConsoleExperience:RegisterEvent("PLAYER_LOGOUT")

-- Configuration storage (saved variables)
ConsoleExperienceDB = ConsoleExperienceDB or {}

ConsoleExperience:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "ConsoleExperienceClassic" then
        -- Initialize configuration if it doesn't exist
        if ConsoleExperienceDB == nil then
            ConsoleExperienceDB = {}
        end
        
-- Addon loaded message (always show)
        
    elseif event == "VARIABLES_LOADED" then
        -- Initialize config DB with defaults
        if ConsoleExperience.config and ConsoleExperience.config.InitializeDB then
            ConsoleExperience.config:InitializeDB()
        end
        
        -- Initialize action bars after saved variables are loaded
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.Initialize then
            ConsoleExperience.actionbars:Initialize()
        end
        
        -- Initialize cursor tooltip module
        if ConsoleExperience.cursor and ConsoleExperience.cursor.tooltip and ConsoleExperience.cursor.tooltip.Initialize then
            ConsoleExperience.cursor.tooltip:Initialize()
        end
        
        -- Initialize frame hooks for cursor navigation
        if ConsoleExperience.hooks and ConsoleExperience.hooks.Initialize then
            ConsoleExperience.hooks:Initialize()
        end
        
        -- Initialize radial menu
        if ConsoleExperience.radial and ConsoleExperience.radial.Initialize then
            ConsoleExperience.radial:Initialize()
        end
        
        -- Initialize macros (creates default macros on first load)
        if ConsoleExperience.macros and ConsoleExperience.macros.Initialize then
            ConsoleExperience.macros:Initialize()
        end
        
        -- Initialize placement frame
        if ConsoleExperience.placement and ConsoleExperience.placement.Initialize then
            ConsoleExperience.placement:Initialize()
        end
        
        CE_Debug("ConsoleExperience loaded!")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-initialize action bars on zone changes/reloads
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.OnPlayerEnteringWorld then
            ConsoleExperience.actionbars:OnPlayerEnteringWorld()
        end
        
        -- Setup keybindings on PLAYER_ENTERING_WORLD (later than VARIABLES_LOADED)
        -- Only run once, not on every zone change
        if not ConsoleExperience.keybindingsInitialized then
            ConsoleExperience.keybindingsInitialized = true
            if ConsoleExperience.keybindings and ConsoleExperience.keybindings.Initialize then
                ConsoleExperience.keybindings:Initialize()
            end
        end
        
    elseif event == "PLAYER_LOGOUT" then
        -- Save configuration
        ConsoleExperienceDB = ConsoleExperienceDB
    end
end)

-- Debug function - only prints if debug is enabled in config
function ConsoleExperience:Debug(msg)
    if self.config and self.config:Get("debugEnabled") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r " .. tostring(msg))
    end
end

-- Global shortcut for debug
function CE_Debug(msg)
    if ConsoleExperience.config and ConsoleExperience.config:Get("debugEnabled") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r " .. tostring(msg))
    end
end

-- Print function - always prints (for important messages)
function ConsoleExperience:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CE]|r " .. tostring(msg))
end

function CE_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CE]|r " .. tostring(msg))
end
