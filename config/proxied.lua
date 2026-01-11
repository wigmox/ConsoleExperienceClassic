--[[
    ConsoleExperienceClassic - Proxied Actions Module
    
    Handles system bindings (JUMP, AUTORUN, etc.) that can be assigned to 
    controller buttons instead of action bar slots.
    
    When a button is assigned to a proxied action:
    - The WoW binding is set directly (e.g., key "1" -> "JUMP")
    - The action bar shows the proxied action's icon
    - The placement frame hides that slot
]]

-- Create the proxied module namespace
ConsoleExperience.proxied = ConsoleExperience.proxied or {}
local Proxied = ConsoleExperience.proxied

-- ============================================================================
-- Proxied Actions Definition
-- ============================================================================

-- Available proxied actions organized by category
-- Format: { id = "WOW_BINDING_ID", name = "Display Name", icon = "texture path" }
-- Note: id can be a native WoW binding (e.g., "JUMP") or a CE custom binding (e.g., "CE_INTERACT")
Proxied.ACTIONS = {
    -- Movement
    { header = "Movement" },
    { 
        id = "JUMP", 
        name = "Jump", 
        icon = "Interface\\Icons\\Ability_Rogue_FleetFooted",
        desc = "Jump"
    },
    { 
        id = "TOGGLEAUTORUN", 
        name = "Auto Run", 
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        desc = "Toggle auto-run"
    },
    { 
        id = "TOGGLERUN", 
        name = "Run/Walk", 
        icon = "Interface\\Icons\\Ability_Tracking",
        desc = "Toggle run/walk speed"
    },
    
    -- Targeting
    { header = "Targeting" },
    { 
        id = "CE_INTERACT", 
        name = "Interact", 
        icon = "Interface\\Icons\\Ability_Eyeoftheowl",
        desc = "Interact with nearest target (requires Interact.dll)"
    },
    { 
        id = "TARGETSELF", 
        name = "Target Self", 
        icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
        desc = "Target yourself"
    },
    { 
        id = "TARGETNEARESTENEMY", 
        name = "Target Nearest Enemy", 
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
        desc = "Target the nearest enemy"
    },
    { 
        id = "TARGETPREVIOUSENEMY", 
        name = "Target Previous Enemy", 
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
        desc = "Target the previous enemy"
    },
    { 
        id = "TARGETNEARESTFRIEND", 
        name = "Target Nearest Friend", 
        icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",
        desc = "Target the nearest friendly player"
    },
    { 
        id = "ASSISTTARGET", 
        name = "Assist Target", 
        icon = "Interface\\Icons\\Ability_Hunter_AspectOfTheViper",
        desc = "Target your target's target"
    },
    
    -- Interface
    { header = "Interface" },
    { 
        id = "OPENALLBAGS", 
        name = "Open Bags", 
        icon = "Interface\\Icons\\INV_Misc_Bag_08",
        desc = "Open all bags"
    },
    { 
        id = "TOGGLEGAMEMENU", 
        name = "Game Menu", 
        icon = "Interface\\Icons\\INV_Misc_Gear_01",
        desc = "Open the game menu"
    },
    { 
        id = "TOGGLEWORLDMAP", 
        name = "World Map", 
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        desc = "Toggle world map"
    },
    { 
        id = "TOGGLECHARACTER0", 
        name = "Character Panel", 
        icon = "Interface\\Icons\\INV_Shirt_Black_01",
        desc = "Toggle character info"
    },
    { 
        id = "TOGGLESPELLBOOK", 
        name = "Spellbook", 
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        desc = "Toggle spellbook"
    },
    { 
        id = "TOGGLETALENTS", 
        name = "Talents", 
        icon = "Interface\\Icons\\Ability_Marksmanship",
        desc = "Toggle talent window"
    },
    { 
        id = "TOGGLEQUESTLOG", 
        name = "Quest Log", 
        icon = "Interface\\Icons\\INV_Misc_Book_08",
        desc = "Toggle quest log"
    },
    { 
        id = "TOGGLESOCIAL", 
        name = "Social", 
        icon = "Interface\\Icons\\INV_Letter_02",
        desc = "Toggle friends list"
    },
    
    -- Camera
    { header = "Camera" },
    { 
        id = "CAMERAZOOMIN", 
        name = "Zoom In", 
        icon = "Interface\\Icons\\INV_Misc_SpyGlass_03",
        desc = "Zoom camera in"
    },
    { 
        id = "CAMERAZOOMOUT", 
        name = "Zoom Out", 
        icon = "Interface\\Icons\\INV_Misc_SpyGlass_02",
        desc = "Zoom camera out"
    },
    
    -- Combat
    { header = "Combat" },
    { 
        id = "ATTACKTARGET", 
        name = "Attack", 
        icon = "Interface\\Icons\\Ability_SteelMelee",
        desc = "Start auto-attack"
    },
    { 
        id = "PETATTACK", 
        name = "Pet Attack", 
        icon = "Interface\\Icons\\Ability_Hunter_Pet_Wolf",
        desc = "Command pet to attack"
    },
    { 
        id = "STOPATTACK", 
        name = "Stop Attack", 
        icon = "Interface\\Icons\\Spell_Frost_Stun",
        desc = "Stop attacking"
    },
}

-- Key slot mapping (maps slot numbers to key combinations)
-- Slot 1-10: No modifier (keys 1-0)
-- Slot 11-20: Shift (LT) + keys 1-0
-- Slot 21-30: Ctrl (RT) + keys 1-0
-- Slot 31-40: Shift+Ctrl (LT+RT) + keys 1-0
Proxied.SLOT_KEYS = {
    -- No modifier
    [1] = "1", [2] = "2", [3] = "3", [4] = "4", [5] = "5",
    [6] = "6", [7] = "7", [8] = "8", [9] = "9", [10] = "0",
    -- Shift (LT)
    [11] = "SHIFT-1", [12] = "SHIFT-2", [13] = "SHIFT-3", [14] = "SHIFT-4", [15] = "SHIFT-5",
    [16] = "SHIFT-6", [17] = "SHIFT-7", [18] = "SHIFT-8", [19] = "SHIFT-9", [20] = "SHIFT-0",
    -- Ctrl (RT)
    [21] = "CTRL-1", [22] = "CTRL-2", [23] = "CTRL-3", [24] = "CTRL-4", [25] = "CTRL-5",
    [26] = "CTRL-6", [27] = "CTRL-7", [28] = "CTRL-8", [29] = "CTRL-9", [30] = "CTRL-0",
    -- Ctrl+Shift (LT+RT)
    [31] = "CTRL-SHIFT-1", [32] = "CTRL-SHIFT-2", [33] = "CTRL-SHIFT-3", [34] = "CTRL-SHIFT-4", [35] = "CTRL-SHIFT-5",
    [36] = "CTRL-SHIFT-6", [37] = "CTRL-SHIFT-7", [38] = "CTRL-SHIFT-8", [39] = "CTRL-SHIFT-9", [40] = "CTRL-SHIFT-0",
}

-- Slot names for display (button names)
Proxied.SLOT_NAMES = {
    [1] = "A", [2] = "X", [3] = "Y", [4] = "B", [5] = "Down",
    [6] = "Left", [7] = "Up", [8] = "Right", [9] = "RB", [10] = "LB",
}

-- Modifier names for pages
Proxied.PAGE_MODIFIERS = {
    [1] = "",
    [2] = "LT + ",
    [3] = "RT + ",
    [4] = "LT + RT + ",
}

-- ============================================================================
-- Get Action Info
-- ============================================================================

-- Get action info by binding ID
function Proxied:GetActionByID(bindingID)
    for _, action in ipairs(self.ACTIONS) do
        if action.id == bindingID then
            return action
        end
    end
    return nil
end

-- Get all non-header actions
function Proxied:GetAllActions()
    local actions = {}
    for _, action in ipairs(self.ACTIONS) do
        if not action.header then
            table.insert(actions, action)
        end
    end
    return actions
end

-- ============================================================================
-- Slot/Key Management
-- ============================================================================

-- Get the key combination for a slot
function Proxied:GetKeyForSlot(slot)
    return self.SLOT_KEYS[slot]
end

-- Get display name for a slot
function Proxied:GetSlotDisplayName(slot)
    local page = math.floor((slot - 1) / 10) + 1
    local buttonIndex = math.mod(slot - 1, 10) + 1
    local modifier = self.PAGE_MODIFIERS[page] or ""
    local buttonName = self.SLOT_NAMES[buttonIndex] or ("Slot " .. buttonIndex)
    return modifier .. buttonName
end

-- ============================================================================
-- Database Access
-- ============================================================================

-- Get proxied action for a slot (returns binding ID or nil)
function Proxied:GetSlotBinding(slot)
    if ConsoleExperienceDB and ConsoleExperienceDB.proxiedActions then
        return ConsoleExperienceDB.proxiedActions[slot]
    end
    return nil
end

-- Set proxied action for a slot (bindingID or nil to clear)
function Proxied:SetSlotBinding(slot, bindingID)
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    if not ConsoleExperienceDB.proxiedActions then
        ConsoleExperienceDB.proxiedActions = {}
    end
    
    -- If assigning a proxied action, check if it's already bound to another slot
    -- and release that binding first (set back to CE_ACTION_X)
    local previousSlot = nil
    if bindingID then
        for existingSlot, existingBindingID in pairs(ConsoleExperienceDB.proxiedActions) do
            if existingBindingID == bindingID and existingSlot ~= slot then
                previousSlot = existingSlot
                break
            end
        end
        
        if previousSlot then
            CE_Debug("Proxied: Action " .. bindingID .. " was already on slot " .. previousSlot .. ", releasing it")
            ConsoleExperienceDB.proxiedActions[previousSlot] = nil
            -- Apply the binding change to restore CE_ACTION_X for the previous slot
            self:ApplySlotBinding(previousSlot)
        end
    end
    
    ConsoleExperienceDB.proxiedActions[slot] = bindingID
    
    -- Apply the binding change
    self:ApplySlotBinding(slot)
    
    -- Save bindings (1 = account-wide)
    SaveBindings(1)
    
    -- Update action bar display
    if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
        ConsoleExperience.actionbars:UpdateAllButtons()
    end
    
    -- Update placement frame if open
    if ConsoleExperience.placement and ConsoleExperience.placement.UpdateButtonVisibility then
        ConsoleExperience.placement:UpdateButtonVisibility()
    end
    
    -- Update config dropdowns if the config panel is open (to reflect the released slot)
    if previousSlot and ConsoleExperience.config and ConsoleExperience.config.bindingDropdowns then
        local previousDropdown = ConsoleExperience.config.bindingDropdowns[previousSlot]
        if previousDropdown then
            UIDropDownMenu_SetSelectedValue(previousDropdown, nil)
            local noneText = "None (Action Bar)"
            if Locale and Locale.T then
                noneText = Locale.T("None (Action Bar)")
            end
            UIDropDownMenu_SetText(noneText, previousDropdown)
        end
    end
end

-- Check if a slot has a proxied action
function Proxied:IsSlotProxied(slot)
    return self:GetSlotBinding(slot) ~= nil
end

-- Get the icon for a proxied slot (or nil if not proxied)
function Proxied:GetSlotIcon(slot)
    local bindingID = self:GetSlotBinding(slot)
    if bindingID then
        local action = self:GetActionByID(bindingID)
        if action then
            return action.icon
        end
    end
    return nil
end

-- Get the action info for a proxied slot (or nil if not proxied)
function Proxied:GetSlotActionInfo(slot)
    local bindingID = self:GetSlotBinding(slot)
    if bindingID then
        return self:GetActionByID(bindingID)
    end
    return nil
end

-- ============================================================================
-- Binding Application
-- ============================================================================

-- Apply binding for a single slot
function Proxied:ApplySlotBinding(slot)
    local key = self:GetKeyForSlot(slot)
    if not key then return end
    
    local bindingID = self:GetSlotBinding(slot)
    
    -- Target action to bind
    local targetAction = bindingID or ("CE_ACTION_" .. slot)
    
    -- Check if cursor mode is active
    local cursorModeActive = false
    if ConsoleExperience.cursor and ConsoleExperience.cursor.keybindings then
        cursorModeActive = ConsoleExperience.cursor.keybindings.cursorModeActive
    end
    
    -- Check if this key is managed by cursor mode (keys 1-8 are used for cursor navigation)
    -- Modifier keys (SHIFT-X, CTRL-X, etc.) are NOT managed by cursor mode
    local isCursorManagedKey = (slot >= 1 and slot <= 8)
    
    if cursorModeActive and isCursorManagedKey then
        -- For keys 1-8 during cursor mode: only update originalBindings
        -- Don't call SetBinding because cursor mode is using these keys for navigation
        -- The binding will be applied when cursor mode exits
        local cursorKeys = ConsoleExperience.cursor.keybindings
        if not cursorKeys.originalBindings then
            cursorKeys.originalBindings = {}
        end
        cursorKeys.originalBindings[key] = targetAction
        CE_Debug("Proxied: Updated cursor original binding for " .. key .. " to " .. targetAction .. " (will apply when cursor mode exits)")
    else
        -- For modifier keys (slots 9-40) OR when cursor mode is not active:
        -- Apply the binding immediately via SetBinding
        
        -- First, clear any existing binding on this key
        SetBinding(key, nil)
        
        -- Now set the new binding
        SetBinding(key, targetAction)
        
        -- Verify the binding was set by checking what action this key is now bound to
        local verifyAction = GetBindingAction(key)
        if verifyAction == targetAction then
            CE_Debug("Proxied: Set " .. key .. " to " .. targetAction .. " (verified)")
        elseif verifyAction then
            CE_Debug("Proxied: WARNING - " .. key .. " is bound to " .. verifyAction .. " instead of " .. targetAction)
        else
            CE_Debug("Proxied: WARNING - " .. key .. " has no binding after SetBinding call")
        end
    end
end

-- Apply all proxied bindings
function Proxied:ApplyAllBindings()
    CE_Debug("Proxied: Applying all bindings...")
    
    for slot = 1, 40 do
        self:ApplySlotBinding(slot)
    end
    
    -- Save bindings (1 = account-wide)
    SaveBindings(1)
    
    CE_Debug("Proxied: All bindings applied and saved")
end

-- ============================================================================
-- Initialization
-- ============================================================================

function Proxied:Initialize()
    -- Initialize DB if needed
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    if not ConsoleExperienceDB.proxiedActions then
        ConsoleExperienceDB.proxiedActions = {}
    end
    
    -- Check if this is a fresh install (no proxied actions set yet)
    local isFreshInstall = true
    for slot, _ in pairs(ConsoleExperienceDB.proxiedActions) do
        isFreshInstall = false
        break
    end
    
    -- Migrate from old useAForJump setting
    if ConsoleExperienceDB.config and ConsoleExperienceDB.config.useAForJump then
        -- If useAForJump was enabled, set slot 1 to JUMP
        if ConsoleExperienceDB.proxiedActions[1] == nil then
            ConsoleExperienceDB.proxiedActions[1] = "JUMP"
            CE_Debug("Proxied: Migrated useAForJump to proxied action JUMP on slot 1")
        end
    end
    
    -- Set defaults for fresh install
    if isFreshInstall then
        -- Default: JUMP on slot 1 (A button)
        ConsoleExperienceDB.proxiedActions[1] = "JUMP"
        CE_Debug("Proxied: Set default JUMP on slot 1")
        
        -- Default: CE_INTERACT on slot 30 (RT+LB = Ctrl+0)
        ConsoleExperienceDB.proxiedActions[30] = "CE_INTERACT"
        CE_Debug("Proxied: Set default CE_INTERACT on slot 30")
    end
    
    -- Apply all bindings
    self:ApplyAllBindings()
    
    CE_Debug("Proxied actions module initialized")
end

-- ============================================================================
-- Dropdown Options Generation
-- ============================================================================

-- Generate dropdown options for a slot (used in config UI)
function Proxied:GetDropdownOptions()
    local options = {}
    
    -- First option: None (use action bar)
    table.insert(options, { text = "None (Action Bar)", value = nil })
    
    -- Add separator
    table.insert(options, { text = "---", value = "SEPARATOR", disabled = true })
    
    -- Add all actions organized by headers
    local currentHeader = nil
    for _, action in ipairs(self.ACTIONS) do
        if action.header then
            currentHeader = action.header
            table.insert(options, { text = "-- " .. action.header .. " --", value = "HEADER_" .. action.header, disabled = true })
        else
            table.insert(options, { text = action.name, value = action.id })
        end
    end
    
    return options
end

CE_Debug("Proxied actions module loaded")
