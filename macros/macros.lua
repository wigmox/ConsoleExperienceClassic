--[[
    ConsoleExperienceClassic - Macros Module
    
    Creates default macros for controller-friendly gameplay
    Macros are only created once on first load
]]

-- Create macros module namespace
ConsoleExperience.macros = ConsoleExperience.macros or {}
local Macros = ConsoleExperience.macros

-- Prefix for all CE macros (helps identify them)
local MACRO_PREFIX = "CE_"

-- Default macros to create
-- Each macro has: name, icon, body, actionSlot (optional - which action bar slot to assign)
Macros.DEFAULT_MACROS = {
    -- Interact with nearest target - assigned to LB button (slot 10)
    {
        name = "CE_Interact",
        icon = 83,  -- Crosshair/target icon
        body = "/run if InteractNearest then InteractNearest(1) else DEFAULT_CHAT_FRAME:AddMessage(\"Interact.dll is not properly loaded, falling back to TargetNearestEnemy()\", 1, 0, 0); TargetNearestEnemy() end",
        description = "Interact with nearest target",
        actionSlot = 10  -- LB button (key 0)
    },
}

-- Special bindings (not macros, but bound to WoW actions)
-- These will show icons on action bar but use WoW's native bindings
Macros.SPECIAL_BINDINGS = {
    [1] = {  -- Button A (slot 1, key "1")
        binding = "JUMP",
        icon = "Interface\\Icons\\Ability_Rogue_FleetFooted",
        name = "Jump"
    }
}

-- ============================================================================
-- Macro Creation
-- ============================================================================

function Macros:GetMacroByName(name)
    local index = GetMacroIndexByName(name)
    if index and index > 0 then
        return index
    end
    return nil
end

function Macros:CreateMacro(macroInfo)
    if not macroInfo or not macroInfo.name or not macroInfo.body then
        return false, nil
    end
    
    -- Check if macro already exists
    local existingIndex = self:GetMacroByName(macroInfo.name)
    if existingIndex then
        CE_Debug("Macro already exists: " .. macroInfo.name)
        return true, existingIndex
    end
    
    -- Check if we have room for more macros
    local numGlobal, numPerChar = GetNumMacros()
    if numGlobal >= 18 then
        CE_Debug("No room for more global macros (max 18)")
        return false, nil
    end
    
    -- Create the macro
    local index = CreateMacro(macroInfo.name, macroInfo.icon or 1, macroInfo.body, nil, nil)
    
    if index then
        CE_Debug("Created macro: " .. macroInfo.name)
        return true, index
    else
        CE_Debug("Failed to create macro: " .. macroInfo.name)
        return false, nil
    end
end

-- Place a macro on an action bar slot
function Macros:PlaceMacroOnActionBar(macroName, actionSlot)
    if not macroName or not actionSlot then return false end
    
    local macroIndex = self:GetMacroByName(macroName)
    if not macroIndex then
        CE_Debug("Cannot place macro - not found: " .. macroName)
        return false
    end
    
    -- Check if slot already has something
    if HasAction(actionSlot) then
        CE_Debug("Action slot " .. actionSlot .. " already has an action, skipping")
        return false
    end
    
    -- Pick up the macro and place it
    PickupMacro(macroIndex)
    PlaceAction(actionSlot)
    
    -- Clear cursor if anything is still on it
    ClearCursor()
    
    CE_Debug("Placed macro " .. macroName .. " on action slot " .. actionSlot)
    return true
end

function Macros:CreateDefaultMacros()
    -- Check if we've already created macros
    if ConsoleExperienceDB.macrosCreated then
        CE_Debug("Default macros already created previously")
        return
    end
    
    local created = 0
    local failed = 0
    local placed = 0
    
    for _, macroInfo in ipairs(self.DEFAULT_MACROS) do
        local success, index = self:CreateMacro(macroInfo)
        if success then
            created = created + 1
            
            -- Place on action bar if slot is specified
            if macroInfo.actionSlot then
                if self:PlaceMacroOnActionBar(macroInfo.name, macroInfo.actionSlot) then
                    placed = placed + 1
                end
            end
        else
            failed = failed + 1
        end
    end
    
    -- Mark as created so we don't do this again
    ConsoleExperienceDB.macrosCreated = true
    
    if created > 0 then
        local msg = "Created " .. created .. " default macros"
        if placed > 0 then
            msg = msg .. " and placed " .. placed .. " on action bar"
        end
        CE_Debug(msg .. ".")
    end
    
    if failed > 0 then
        CE_Debug(failed .. " macros could not be created (may already exist or macro limit reached)")
    end
end

-- ============================================================================
-- Initialize
-- ============================================================================

function Macros:Initialize()
    -- Create default macros on first load
    self:CreateDefaultMacros()
end

-- Reset all macros and place them on action bar (called from config menu)
function Macros:ResetMacrosToDefaults()
    -- Delete existing CE macros first
    for _, macroInfo in ipairs(self.DEFAULT_MACROS) do
        local index = self:GetMacroByName(macroInfo.name)
        if index then
            DeleteMacro(index)
        end
    end
    
    -- Clear the action slots used by macros
    for _, macroInfo in ipairs(self.DEFAULT_MACROS) do
        if macroInfo.actionSlot then
            PickupAction(macroInfo.actionSlot)
            ClearCursor()
        end
    end
    
    -- Reset the flag and recreate
    ConsoleExperienceDB.macrosCreated = false
    
    -- Create macros and place them
    local created = 0
    local placed = 0
    
    for _, macroInfo in ipairs(self.DEFAULT_MACROS) do
        local success, index = self:CreateMacro(macroInfo)
        if success then
            created = created + 1
            
            -- Place on action bar if slot is specified
            if macroInfo.actionSlot then
                if self:PlaceMacroOnActionBar(macroInfo.name, macroInfo.actionSlot) then
                    placed = placed + 1
                end
            end
        end
    end
    
    -- Mark as created
    ConsoleExperienceDB.macrosCreated = true
    
    return created, placed
end

