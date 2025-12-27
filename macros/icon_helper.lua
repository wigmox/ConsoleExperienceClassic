--[[
    ConsoleExperienceClassic - Macro Icon Helper
    
    Helper script to find macro icon indices
    Run this in-game with: /run ConsoleExperience.macros:ListIcons()
    
    Or use: /run ConsoleExperience.macros:FindIcon("target")
    to search for icons containing a keyword
]]

if not ConsoleExperience.macros then
    ConsoleExperience.macros = {}
end

local Macros = ConsoleExperience.macros

-- List all available macro icon indices (1-120 typically)
function Macros:ListIcons(startIndex, endIndex)
    startIndex = startIndex or 1
    endIndex = endIndex or 120
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Macro Icon List (" .. startIndex .. "-" .. endIndex .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Note: Creating test macros to read icon textures...")
    
    local found = 0
    local numGlobal, numPerChar = GetNumMacros()
    local maxMacros = 18
    
    -- Check if we have room for a test macro
    if numGlobal >= maxMacros then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[CE]|r Error: No room for test macro (need at least 1 free slot)")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Try using /ceicons common to see known icons")
        return
    end
    
    -- Create a temporary macro name
    local tempMacroName = "CE_ICON_TEST_TEMP"
    local tempMacroIndex = GetMacroIndexByName(tempMacroName)
    
    -- Delete temp macro if it exists
    if tempMacroIndex and tempMacroIndex > 0 then
        DeleteMacro(tempMacroIndex)
    end
    
    for i = startIndex, endIndex do
        -- Try to get icon info by creating a test macro
        local success = CreateMacro(tempMacroName, i, "/say test", nil, nil)
        if success then
            local macroName, macroTexture = GetMacroInfo(success)
            if macroTexture then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff00ff00%d|r: %s", i, macroTexture))
                found = found + 1
            end
            -- Delete the test macro
            DeleteMacro(success)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff9900[CE]|r Found %d icon(s)", found))
end

-- Search for icons containing a keyword
function Macros:FindIcon(keyword)
    keyword = string.lower(keyword or "")
    
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Searching for icons containing: " .. keyword)
    
    -- First check common icons
    local found = 0
    for index, texture in pairs(Macros.COMMON_ICONS) do
        local textureLower = string.lower(texture)
        if string.find(textureLower, keyword) then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff00ff00%d|r: %s", index, texture))
            found = found + 1
        end
    end
    
    -- Then try to search through all icons (slower)
    local numGlobal, numPerChar = GetNumMacros()
    if numGlobal < 18 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Searching all icons (this may take a moment)...")
        local tempMacroName = "CE_ICON_SEARCH_TEMP"
        local tempMacroIndex = GetMacroIndexByName(tempMacroName)
        if tempMacroIndex and tempMacroIndex > 0 then
            DeleteMacro(tempMacroIndex)
        end
        
        for i = 1, 120 do
            local success = CreateMacro(tempMacroName, i, "/say test", nil, nil)
            if success then
                local macroName, macroTexture = GetMacroInfo(success)
                if macroTexture then
                    local textureLower = string.lower(macroTexture)
                    if string.find(textureLower, keyword) then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff00ff00%d|r: %s", i, macroTexture))
                        found = found + 1
                    end
                end
                DeleteMacro(success)
            end
        end
    end
    
    if found == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  No icons found matching: " .. keyword)
    else
        DEFAULT_CHAT_FRAME:AddMessage("  Found " .. found .. " icon(s)")
    end
end

-- Get icon info for a specific index
function Macros:GetIconInfo(index)
    -- Check common icons first
    if Macros.COMMON_ICONS[index] then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff9900[CE]|r Icon %d: %s", index, Macros.COMMON_ICONS[index]))
        return Macros.COMMON_ICONS[index]
    end
    
    -- Try to get by creating a test macro
    local numGlobal, numPerChar = GetNumMacros()
    if numGlobal >= 18 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff9900[CE]|r Icon %d: Unknown (check common icons with /ceicons common)", index))
        return nil
    end
    
    local tempMacroName = "CE_ICON_TEST_" .. index
    local tempMacroIndex = GetMacroIndexByName(tempMacroName)
    if tempMacroIndex and tempMacroIndex > 0 then
        DeleteMacro(tempMacroIndex)
    end
    
    local success = CreateMacro(tempMacroName, index, "/say test", nil, nil)
    if success then
        local macroName, macroTexture = GetMacroInfo(success)
        if macroTexture then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff9900[CE]|r Icon %d: %s", index, macroTexture))
            DeleteMacro(success)
            return macroTexture
        end
        DeleteMacro(success)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff9900[CE]|r Icon %d: Not found", index))
    return nil
end

-- List common known icons
function Macros:ListCommonIcons()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Common Macro Icons:")
    for index, texture in pairs(Macros.COMMON_ICONS) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cff00ff00%d|r: %s", index, texture))
    end
end

-- Common icon indices reference (add more as you discover them)
Macros.COMMON_ICONS = {
    -- Combat/Targeting
    [1] = "Interface\\Icons\\INV_Sword_04",
    [23] = "Interface\\Icons\\Ability_Seal",  -- Crosshair/target icon
    [24] = "Interface\\Icons\\Ability_DualWield",
    
    -- Movement
    [25] = "Interface\\Icons\\Ability_Rogue_Sprint",
    [26] = "Interface\\Icons\\Ability_Mount_WhiteDireWolf",
    
    -- Items
    [27] = "Interface\\Icons\\INV_Misc_Bag_08",
    [28] = "Interface\\Icons\\INV_Misc_Coin_01",
    
    -- UI/Menu
    [29] = "Interface\\Icons\\INV_Misc_Gear_01",
    [30] = "Interface\\Icons\\INV_Misc_QuestionMark",
    
    -- Add more common icons as needed
}

-- Slash commands for easy access
SLASH_CEICONS1 = "/ceicons"
SlashCmdList["CEICONS"] = function(msg)
    local args = {}
    -- Parse arguments manually for Classic WoW compatibility
    local startPos = 1
    local endPos = string.len(msg)
    
    while startPos <= endPos do
        -- Skip whitespace
        while startPos <= endPos and string.find(msg, "^%s", startPos) do
            startPos = startPos + 1
        end
        
        if startPos > endPos then break end
        
        -- Find end of word
        local wordStart = startPos
        while startPos <= endPos and not string.find(msg, "^%s", startPos) do
            startPos = startPos + 1
        end
        
        if wordStart < startPos then
            local word = string.sub(msg, wordStart, startPos - 1)
            table.insert(args, word)
        end
    end
    
    if args[1] == "list" then
        local start = tonumber(args[2]) or 1
        local finish = tonumber(args[3]) or 120
        Macros:ListIcons(start, finish)
    elseif args[1] == "common" then
        Macros:ListCommonIcons()
    elseif args[1] == "find" then
        Macros:FindIcon(args[2] or "")
    elseif args[1] then
        local index = tonumber(args[1])
        if index then
            Macros:GetIconInfo(index)
        else
            Macros:FindIcon(args[1])
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[CE]|r Macro Icon Helper:")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00/ceicons common|r - List known common icons (fast)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00/ceicons list [start] [end]|r - List icons by creating test macros (slow)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00/ceicons find <keyword>|r - Search for icons")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00/ceicons <number>|r - Get info for specific icon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00ff00/ceicons <keyword>|r - Search for keyword")
    end
end

