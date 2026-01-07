--[[
    ConsoleExperienceClassic - Action Bars Module
    
    Button Layout (Key = Button ID):
    - 1 = A, 2 = X, 3 = Y, 4 = B  (Face buttons)
    - 5 = Down, 6 = Left, 7 = Up, 8 = Right  (D-Pad)
    - 9 = RB, 10 = LB  (Bumpers)
    
    Page System (based on modifier keys):
    - Page 1: No modifiers (default)
    - Page 2: Shift held
    - Page 3: Ctrl held
    - Page 4: Shift+Ctrl held
]]

-- Create the actionbars module namespace
if ConsoleExperience.actionbars == nil then
    ConsoleExperience.actionbars = {}
end

local ActionBars = ConsoleExperience.actionbars

-- ============================================================================
-- Constants
-- ============================================================================

ActionBars.NUM_BUTTONS = 10
ActionBars.NUM_PAGES = 4
ActionBars.TOOLTIP_UPDATE_TIME = 0.2
ActionBars.RANGE_CHECK_TIME = 0.2  -- Check range every 200ms (like pfUI)
ActionBars.FLASH_TIME = 0.4
ActionBars.MODIFIER_CHECK_TIME = 0.05  -- Check modifiers every 50ms

-- Color configurations for button states (matching pfUI defaults)
ActionBars.RANGE_COLOR = {1.0, 0.1, 0.1, 1.0}  -- Red for out of range
ActionBars.OOM_COLOR = {0.5, 0.5, 1.0, 1.0}    -- Blue for out of mana
ActionBars.NA_COLOR = {0.4, 0.4, 0.4, 1.0}     -- Gray for not usable
ActionBars.NORMAL_COLOR = {1.0, 1.0, 1.0, 1.0} -- White for normal

-- Event caching system (like pfUI)
ActionBars.eventCache = {}
ActionBars.updateCache = {}

-- Action slot offsets for each page (each page uses 10 consecutive action slots)
-- WoW 1.12 has 120 action slots total (12 action bar pages of 10 buttons each)
-- Using slots 1-40 (first 4 action bar pages)
ActionBars.PAGE_OFFSETS = {
    [1] = 0,    -- Page 1: slots 1-10 (no modifier)
    [2] = 10,   -- Page 2: slots 11-20 (Shift)
    [3] = 20,   -- Page 3: slots 21-30 (Ctrl)  
    [4] = 30,   -- Page 4: slots 31-40 (Shift+Ctrl)
}

-- Current active page
ActionBars.currentPage = 1

-- Controller button icon mapping (Button ID matches keyboard key)
-- Button 1-9 = keys 1-9, Button 10 = key 0
ActionBars.BUTTON_ICONS = {
    [1] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\a",      -- Key 1
    [2] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\x",      -- Key 2
    [3] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\y",      -- Key 3
    [4] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\b",      -- Key 4
    [5] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\down",   -- Key 5
    [6] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\left",   -- Key 6
    [7] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\up",     -- Key 7
    [8] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\right",  -- Key 8
    [9] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\rb",     -- Key 9
    [10] = "Interface\\AddOns\\ConsoleExperienceClassic\\img\\lb",    -- Key 0
}

-- ============================================================================
-- Module Initialization
-- ============================================================================

function ActionBars:Initialize()
    self:HideDefaultBars()
    self:CreateModifierFrame()
    self:UpdateAllButtons()
    self:InitializeBagBar()
    self:HookCooldownFrame()
end

-- Hook CooldownFrame_SetTimer to ensure cooldowns match button size
function ActionBars:HookCooldownFrame()
    if not self.cooldownHookSet then
        -- Store original function
        local originalSetTimer = CooldownFrame_SetTimer
        -- Replace with our version that calls original then resizes
        CooldownFrame_SetTimer = function(cooldown, start, duration, enable)
            -- Call original function first
            originalSetTimer(cooldown, start, duration, enable)
            
            -- Resize cooldown if it belongs to one of our action buttons
            if cooldown and cooldown:GetParent() then
                local parent = cooldown:GetParent()
                local parentName = parent:GetName() or ""
                if string.find(parentName, "ConsoleActionButton") then
                    -- Get button size (this is the actual button size from config)
                    local buttonWidth = parent:GetWidth()
                    -- Default cooldown size in WoW is typically 36
                    local defaultCooldownSize = 36
                    
                    -- Calculate scale factor to match button size
                    if buttonWidth > 0 then
                        local scaleFactor = buttonWidth / defaultCooldownSize
                        cooldown:SetScale(scaleFactor)
                        -- Use TOPLEFT/BOTTOMRIGHT to fill the button area
                        -- Small offsets to account for cooldown frame template behavior
                        cooldown:ClearAllPoints()
                        cooldown:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
                        cooldown:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
                    end
                end
            end
        end
        self.cooldownHookSet = true
    end
end

function ActionBars:OnPlayerEnteringWorld()
    -- Re-hide bars on login/reload/zone change
    self:HideDefaultBars()
    self:UpdateAllButtons()
end

-- ============================================================================
-- Modifier Key Checking (Page Switching)
-- ============================================================================

function ActionBars:CreateModifierFrame()
    -- Create a frame to check modifier keys on update
    if self.modifierFrame then return end
    
    self.modifierFrame = CreateFrame("Frame", "ConsoleExperienceModifierFrame", UIParent)
    self.modifierFrame.timeSinceLastUpdate = 0
    
    self.modifierFrame:SetScript("OnUpdate", function()
        this.timeSinceLastUpdate = this.timeSinceLastUpdate + arg1
        if this.timeSinceLastUpdate >= ActionBars.MODIFIER_CHECK_TIME then
            this.timeSinceLastUpdate = 0
            ActionBars:CheckModifiers()
        end
    end)
end

function ActionBars:GetCurrentModifierPage()
    local shift = IsShiftKeyDown()
    local ctrl = IsControlKeyDown()
    
    if shift and ctrl then
        return 4  -- Shift+Ctrl
    elseif ctrl then
        return 3  -- Ctrl only
    elseif shift then
        return 2  -- Shift only
    else
        return 1  -- No modifiers
    end
end

function ActionBars:CheckModifiers()
    local newPage = self:GetCurrentModifierPage()
    
    if newPage ~= self.currentPage then
        -- Clear all active states from previous page before switching
        -- This prevents buttons from showing glow/flash from actions on the old page
        for i = 1, self.NUM_BUTTONS do
            local button = getglobal("ConsoleActionButton"..i)
            if button then
                -- Stop flashing (red overlay) - reset state completely
                button.flashing = 0
                button.flashtime = 0
                local flash = getglobal(button:GetName().."Flash")
                if flash then
                    flash:Hide()
                end
                
                -- Force hide active glow/border when switching pages
                if button.activeFrame then
                    button.activeFrame.glow:Hide()
                    if button.activeFrame.border then
                        button.activeFrame.border:Hide()
                    end
                end
                
                -- Reset checked state
                button:SetChecked(0)
            end
        end
        
        self.currentPage = newPage
        -- Force full update of all buttons when page changes
        -- This ensures icons, cooldowns, states, etc. are all refreshed
        self:UpdateAllButtons()
        -- Debug message (optional)
        -- DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CE]|r Switched to page " .. newPage)
    end
end

function ActionBars:GetActionOffset()
    return self.PAGE_OFFSETS[self.currentPage] or self.PAGE_OFFSETS[1]
end

-- ============================================================================
-- Hide Default Action Bars
-- ============================================================================

function ActionBars:HideDefaultBars()
    -- Main action bar and related frames
    if MainMenuBar then MainMenuBar:Hide() end
    if MainMenuBarArtFrame then MainMenuBarArtFrame:Hide() end
    -- Hide exp bar
    if MainMenuExpBar then MainMenuExpBar:Hide() end
    if MainMenuBarMaxLevelBar then MainMenuBarMaxLevelBar:Hide() end
    -- Hide reputation bar
    if ReputationWatchBar then ReputationWatchBar:Hide() end
    if MainMenuBarPerformanceBarFrame then MainMenuBarPerformanceBarFrame:Hide() end
    
    -- Bottom left/right multi bars
    if MultiBarBottomLeft then MultiBarBottomLeft:Hide() end
    if MultiBarBottomRight then MultiBarBottomRight:Hide() end
    
    -- Side multi bars
    if MultiBarLeft then MultiBarLeft:Hide() end
    if MultiBarRight then MultiBarRight:Hide() end
    
    -- Bonus action bar (shapeshifting, stealth, etc)
    if BonusActionBarFrame then BonusActionBarFrame:Hide() end
    
    -- Shapeshift/stance bar
    if ShapeshiftBarFrame then ShapeshiftBarFrame:Hide() end
    
    -- Pet action bar
    if PetActionBarFrame then PetActionBarFrame:Hide() end
    
    -- Bag bar (will be shown/hidden dynamically when bags are opened)
    -- Don't hide here - managed by InitializeBagBar
    
    -- Micro menu buttons
    if CharacterMicroButton then CharacterMicroButton:Hide() end
    if SpellbookMicroButton then SpellbookMicroButton:Hide() end
    if TalentMicroButton then TalentMicroButton:Hide() end
    if QuestLogMicroButton then QuestLogMicroButton:Hide() end
    if SocialsMicroButton then SocialsMicroButton:Hide() end
    if WorldMapMicroButton then WorldMapMicroButton:Hide() end
    if MainMenuMicroButton then MainMenuMicroButton:Hide() end
    if HelpMicroButton then HelpMicroButton:Hide() end
end

-- ============================================================================
-- Action Button Functions
-- ============================================================================

function ActionBars:GetActionID(button)
    local id = button:GetID()
    if id == 0 then
        -- Extract ID from button name
        local name = button:GetName()
        id = tonumber(string.sub(name, 20)) -- "ConsoleActionButton" = 19 chars
    end
    return self:GetActionOffset() + id
end

function ActionBars:ButtonOnLoad(button)
    local id = button:GetID()
    if id == 0 then
        local name = button:GetName()
        id = tonumber(string.sub(name, 20))
        button:SetID(id)
    end
    
    -- Initialize button state
    button.flashing = 0
    button.flashtime = 0
    button.rangeTimer = nil
    button.updateTooltip = nil
    
    -- Vertex state tracking (like pfUI: 0=normal, 1=out of range, 2=oom, 3=not usable)
    button.vertexstate = 0
    button.outofrange = nil
    
    -- Create active state glow frame (for casting indicator)
    local activeFrameName = button:GetName().."Active"
    local activeFrame = getglobal(activeFrameName)
    if not activeFrame then
        activeFrame = CreateFrame("Frame", activeFrameName, button)
        activeFrame:SetAllPoints(button)
        activeFrame:SetFrameLevel(button:GetFrameLevel() + 1)
        
        -- Create colored border overlay (like pfUI's active indicator)
        local border = activeFrame:CreateTexture(nil, "OVERLAY")
        border:SetAllPoints(button)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:Hide()
        activeFrame.border = border
        
        -- Create glow overlay using CheckButtonHilight texture
        local glow = activeFrame:CreateTexture(nil, "OVERLAY")
        glow:SetAllPoints(button)
        glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.6)
        glow:Hide()
        activeFrame.glow = glow
        
        button.activeFrame = activeFrame
    end
    
    -- Create cooldown frame if it doesn't exist
    local cooldownName = button:GetName().."Cooldown"
    local cooldown = getglobal(cooldownName)
    if not cooldown then
        cooldown = CreateFrame("Model", cooldownName, button, "CooldownFrameTemplate")
        -- Cooldown will be sized in UpdateActionBarLayout to match button
        -- Use SetAllPoints to fill the button
        cooldown:SetAllPoints(button)
    end
    
    -- Set controller icon
    local controllerIcon = getglobal(button:GetName().."ControllerIcon")
    if controllerIcon and self.BUTTON_ICONS[id] then
        controllerIcon:SetTexture(self.BUTTON_ICONS[id])
    end
    
    -- Register for drag and click
    button:RegisterForDrag("LeftButton", "RightButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Register events
    button:RegisterEvent("PLAYER_ENTERING_WORLD")
    button:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    button:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    button:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
    button:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    button:RegisterEvent("PLAYER_ENTER_COMBAT")
    button:RegisterEvent("PLAYER_LEAVE_COMBAT")
    button:RegisterEvent("PLAYER_AURAS_CHANGED")
    button:RegisterEvent("PLAYER_TARGET_CHANGED")
    button:RegisterEvent("START_AUTOREPEAT_SPELL")
    button:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    button:RegisterEvent("UNIT_INVENTORY_CHANGED")
    button:RegisterEvent("UPDATE_INVENTORY_ALERTS")
end

function ActionBars:UpdateButton(button)
    local actionID = self:GetActionID(button)
    local buttonID = button:GetID()
    local icon = getglobal(button:GetName().."Icon")
    local cooldown = getglobal(button:GetName().."Cooldown")
    local texture = GetActionTexture(actionID)
    
    -- Check for special bindings (like JUMP for button A)
    -- Only show special binding icon if the config option is enabled
    local specialBinding = nil
    local useAForJump = false
    
    if self.currentPage == 1 and buttonID == 1 then
        -- Check if useAForJump is enabled in config
        useAForJump = true  -- Default
        if ConsoleExperience.config and ConsoleExperience.config.Get then
            useAForJump = ConsoleExperience.config:Get("useAForJump")
        elseif ConsoleExperienceDB and ConsoleExperienceDB.config and ConsoleExperienceDB.config.useAForJump ~= nil then
            useAForJump = ConsoleExperienceDB.config.useAForJump
        end
        
        CE_Debug("UpdateButton A: useAForJump=" .. tostring(useAForJump) .. ", hasTexture=" .. tostring(texture ~= nil))
        
        if useAForJump and ConsoleExperience.macros and ConsoleExperience.macros.SPECIAL_BINDINGS then
            specialBinding = ConsoleExperience.macros.SPECIAL_BINDINGS[buttonID]
        end
    end
    
    -- If useAForJump is enabled for button 1, ALWAYS show jump icon (priority over action slot)
    if specialBinding then
        icon:SetTexture(specialBinding.icon)
        icon:Show()
        button.rangeTimer = nil
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button.isSpecialBinding = specialBinding
        cooldown:Hide()
        -- Stop any flashing/glow effects since this is a special binding, not an action
        self:StopFlash(button)
        button:SetChecked(0)
    elseif texture then
        icon:SetTexture(texture)
        icon:Show()
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
        button.isSpecialBinding = nil
        
        -- Reset range state when updating button
        button.outofrange = nil
        button.vertexstate = 0
        
        self:UpdateButtonState(button)
        self:UpdateButtonUsable(button)
        self:UpdateButtonCooldown(button)
        self:UpdateButtonCount(button)
        self:UpdateButtonFlash(button)
        
        -- Initialize range timer for range checking (only if action has range)
        if HasAction(actionID) and ActionHasRange(actionID) then
            button.rangeTimer = self.RANGE_CHECK_TIME
        else
            button.rangeTimer = nil
        end
    else
        icon:Hide()
        cooldown:Hide()
        button.rangeTimer = nil
        button.isSpecialBinding = nil
        button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot")
    end
    
    -- Always keep button visible so we can drop actions onto it
    button:Show()
    
    -- Update equipped border (only if not a special binding)
    local border = getglobal(button:GetName().."Border")
    if border then
        if button.isSpecialBinding then
            -- Hide border for special bindings
            border:Hide()
        elseif IsEquippedAction(actionID) then
            border:SetVertexColor(0, 1.0, 0, 0.35)
            border:Show()
        else
            border:Hide()
        end
    end
    
    -- Update tooltip if shown
    if GameTooltip:IsOwned(button) then
        self:SetButtonTooltip(button)
    end
    
    -- Update macro name
    local macroName = getglobal(button:GetName().."Name")
    if macroName then
        if button.isSpecialBinding then
            macroName:SetText(button.isSpecialBinding.name)
        else
            macroName:SetText(GetActionText(actionID))
        end
    end
end

function ActionBars:UpdateButtonState(button)
    local actionID = self:GetActionID(button)
    local active = IsCurrentAction(actionID) or IsAutoRepeatAction(actionID)
    
    if active then
        button:SetChecked(1)
        
        -- Show active glow/border (casting indicator)
        if button.activeFrame then
            button.activeFrame.glow:Show()
            if button.activeFrame.border then
                -- Get class color for border (like pfUI)
                local _, class = UnitClass("player")
                local color = RAID_CLASS_COLORS[class]
                if color then
                    button.activeFrame.border:SetVertexColor(color.r, color.g, color.b, 1.0)
                else
                    button.activeFrame.border:SetVertexColor(1.0, 1.0, 0.5, 1.0) -- Default yellow
                end
                button.activeFrame.border:Show()
            end
        end
    else
        button:SetChecked(0)
        
        -- Hide active glow/border
        if button.activeFrame then
            button.activeFrame.glow:Hide()
            if button.activeFrame.border then
                button.activeFrame.border:Hide()
            end
        end
    end
end

function ActionBars:UpdateButtonUsable(button)
    local actionID = self:GetActionID(button)
    local icon = getglobal(button:GetName().."Icon")
    if not icon then return end
    
    local usable, oom = IsUsableAction(actionID)
    local newVertexState = 0
    
    -- Check range first (if out of range, show red)
    if button.outofrange then
        newVertexState = 1
        if button.vertexstate ~= 1 then
            icon:SetVertexColor(self.RANGE_COLOR[1], self.RANGE_COLOR[2], self.RANGE_COLOR[3], self.RANGE_COLOR[4])
            button.vertexstate = 1
        end
    -- Check out of mana
    elseif oom then
        newVertexState = 2
        if button.vertexstate ~= 2 then
            icon:SetVertexColor(self.OOM_COLOR[1], self.OOM_COLOR[2], self.OOM_COLOR[3], self.OOM_COLOR[4])
            button.vertexstate = 2
        end
    -- Check not usable
    elseif not usable then
        newVertexState = 3
        if button.vertexstate ~= 3 then
            icon:SetVertexColor(self.NA_COLOR[1], self.NA_COLOR[2], self.NA_COLOR[3], self.NA_COLOR[4])
            button.vertexstate = 3
        end
    -- Normal state
    else
        newVertexState = 0
        if button.vertexstate ~= 0 then
            icon:SetVertexColor(self.NORMAL_COLOR[1], self.NORMAL_COLOR[2], self.NORMAL_COLOR[3], self.NORMAL_COLOR[4])
            button.vertexstate = 0
        end
    end
end

function ActionBars:UpdateButtonCooldown(button)
    local actionID = self:GetActionID(button)
    local cooldown = getglobal(button:GetName().."Cooldown")
    local start, duration, enable = GetActionCooldown(actionID)
    CooldownFrame_SetTimer(cooldown, start, duration, enable)
    
    -- Ensure cooldown matches button size after timer is set
    -- The hook will also handle this, but we do it here too for immediate update
    if cooldown and button then
        local buttonSize = button:GetWidth()
        local defaultCooldownSize = 36
        if buttonSize > 0 then
            local scaleFactor = buttonSize / defaultCooldownSize
            cooldown:SetScale(scaleFactor)
            cooldown:ClearAllPoints()
            -- Use TOPLEFT/BOTTOMRIGHT to fill the button area
            cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
            cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        end
    end
end

function ActionBars:UpdateButtonCount(button)
    local actionID = self:GetActionID(button)
    local count = getglobal(button:GetName().."Count")
    if count then
        if IsConsumableAction(actionID) then
            count:SetText(GetActionCount(actionID))
        else
            count:SetText("")
        end
    end
end

function ActionBars:UpdateButtonFlash(button)
    local actionID = self:GetActionID(button)
    if (IsAttackAction(actionID) and IsCurrentAction(actionID)) or IsAutoRepeatAction(actionID) then
        self:StartFlash(button)
    else
        self:StopFlash(button)
    end
end

function ActionBars:StartFlash(button)
    button.flashing = 1
    button.flashtime = 0
    self:UpdateButtonState(button)
end

function ActionBars:StopFlash(button)
    button.flashing = 0
    local flash = getglobal(button:GetName().."Flash")
    if flash then
        flash:Hide()
    end
    self:UpdateButtonState(button)
end

function ActionBars:IsFlashing(button)
    return button.flashing == 1
end

-- ============================================================================
-- Event Handler
-- ============================================================================

function ActionBars:ButtonOnEvent(button, event)
    local actionID = self:GetActionID(button)
    
    -- Skip action-related updates if button has a special binding (like JUMP)
    local hasSpecialBinding = button.isSpecialBinding ~= nil
    
    if event == "PLAYER_ENTERING_WORLD" then
        self:UpdateButton(button)
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- Check if this slot change affects any of our pages
        local buttonID = button:GetID()
        for page = 1, self.NUM_PAGES do
            local pageActionID = self.PAGE_OFFSETS[page] + buttonID
            if arg1 == -1 or arg1 == pageActionID then
                if page == self.currentPage then
                    self:UpdateButton(button)
                end
                break
            end
        end
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        if not hasSpecialBinding then
            self:UpdateButtonState(button)
        end
    elseif event == "ACTIONBAR_UPDATE_USABLE" then
        if not hasSpecialBinding then
            self:UpdateButtonUsable(button)
        end
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "UPDATE_INVENTORY_ALERTS" then
        if not hasSpecialBinding then
            self:UpdateButtonCooldown(button)
        end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_AURAS_CHANGED" then
        self:UpdateButton(button)
        if not hasSpecialBinding then
            self:UpdateButtonState(button)
            self:UpdateButtonUsable(button)
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then
            self:UpdateButton(button)
        end
    elseif event == "PLAYER_ENTER_COMBAT" then
        if not hasSpecialBinding and IsAttackAction(actionID) then
            self:StartFlash(button)
        end
    elseif event == "PLAYER_LEAVE_COMBAT" then
        if not hasSpecialBinding and IsAttackAction(actionID) then
            self:StopFlash(button)
        end
    elseif event == "START_AUTOREPEAT_SPELL" then
        if not hasSpecialBinding and IsAutoRepeatAction(actionID) then
            self:StartFlash(button)
        end
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        if not hasSpecialBinding and self:IsFlashing(button) and not IsAttackAction(actionID) then
            self:StopFlash(button)
        end
    end
end

-- ============================================================================
-- Update Handler (for flashing, range checking, tooltips)
-- ============================================================================

function ActionBars:ButtonOnUpdate(button, elapsed)
    local actionID = self:GetActionID(button)
    
    -- Don't flash if button has a special binding (like JUMP)
    if button.isSpecialBinding then
        if self:IsFlashing(button) then
            self:StopFlash(button)
        end
    end
    
    -- Handle flashing (attack/auto-repeat) - skip if special binding
    if not button.isSpecialBinding and self:IsFlashing(button) then
        button.flashtime = button.flashtime - elapsed
        if button.flashtime <= 0 then
            local overtime = -button.flashtime
            if overtime >= self.FLASH_TIME then
                overtime = 0
            end
            button.flashtime = self.FLASH_TIME - overtime
            
            local flash = getglobal(button:GetName().."Flash")
            if flash then
                if flash:IsVisible() then
                    flash:Hide()
                else
                    flash:Show()
                end
            end
        end
    end
    
    -- Handle range checking (like pfUI)
    if button.rangeTimer then
        button.rangeTimer = button.rangeTimer - elapsed
        if button.rangeTimer <= 0 then
            -- Check if action has range and is out of range
            if HasAction(actionID) and ActionHasRange(actionID) then
                local inRange = IsActionInRange(actionID)
                if inRange == 0 then -- Out of range
                    if not button.outofrange then
                        button.outofrange = true
                        self:UpdateButtonUsable(button)
                    end
                else -- In range or nil (no target)
                    if button.outofrange then
                        button.outofrange = nil
                        self:UpdateButtonUsable(button)
                    end
                end
            else
                -- Action doesn't have range, clear out of range state
                if button.outofrange then
                    button.outofrange = nil
                    self:UpdateButtonUsable(button)
                end
            end
            
            -- Update hotkey color (legacy support)
            local hotkey = getglobal(button:GetName().."HotKey")
            if hotkey then
                if button.outofrange then
                    hotkey:SetVertexColor(1.0, 0.1, 0.1)
                else
                    hotkey:SetVertexColor(0.6, 0.6, 0.6)
                end
            end
            
            button.rangeTimer = self.RANGE_CHECK_TIME
        end
    end
    
    -- Handle tooltip updates
    if button.updateTooltip then
        button.updateTooltip = button.updateTooltip - elapsed
        if button.updateTooltip <= 0 then
            if GameTooltip:IsOwned(button) then
                self:SetButtonTooltip(button)
            else
                button.updateTooltip = nil
            end
        end
    end
end

-- ============================================================================
-- Click and Drag Handlers
-- ============================================================================

function ActionBars:ButtonOnClick(button, mouseButton)
    local actionID = self:GetActionID(button)
    local buttonID = button:GetID()
    
    -- Debug output
    if ConsoleExperience_DEBUG_KEYS then
        local texture = GetActionTexture(actionID) or "empty"
        local hasAction = HasAction(actionID)
        local iconName = texture
        if texture then
            iconName = string.gsub(texture, ".*\\", "")
        end
        local offset = self:GetActionOffset()
        CE_Debug("Click: Button " .. buttonID .. " | Offset " .. offset .. " | ActionSlot " .. actionID .. " | HasAction: " .. tostring(hasAction) .. " | Icon: " .. tostring(iconName))
    end
    
    if MacroFrame_SaveMacro then
        MacroFrame_SaveMacro()
    end
    
    -- UseAction with checkCursor=1 handles both using actions and placing from cursor
    UseAction(actionID, 1)
    self:UpdateButtonState(button)
end

function ActionBars:ButtonOnDragStart(button)
    local actionID = self:GetActionID(button)
    PickupAction(actionID)
    self:UpdateButton(button)
end

function ActionBars:ButtonOnReceiveDrag(button)
    local actionID = self:GetActionID(button)
    PlaceAction(actionID)
    button:SetChecked(0)
    self:UpdateButton(button)
end

-- ============================================================================
-- Tooltip
-- ============================================================================

function ActionBars:SetButtonTooltip(button)
    local actionID = self:GetActionID(button)
    
    if GetCVar("UberTooltips") == "1" then
        GameTooltip_SetDefaultAnchor(GameTooltip, button)
    else
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    end
    
    -- Check for special binding
    if button.isSpecialBinding then
        GameTooltip:SetText(button.isSpecialBinding.name, 1, 1, 1)
        GameTooltip:AddLine("Bound to: " .. button.isSpecialBinding.binding, 0.5, 0.5, 0.5)
        GameTooltip:Show()
        button.updateTooltip = nil
    elseif GameTooltip:SetAction(actionID) then
        button.updateTooltip = self.TOOLTIP_UPDATE_TIME
    else
        button.updateTooltip = nil
    end
end

function ActionBars:ButtonOnEnter(button)
    self:SetButtonTooltip(button)
end

-- ============================================================================
-- Utility: Update all buttons
-- ============================================================================

function ActionBars:UpdateAllButtons()
    for i = 1, self.NUM_BUTTONS do
        local button = getglobal("ConsoleActionButton"..i)
        if button then
            self:UpdateButton(button)
        end
    end
end

-- ============================================================================
-- Bag Bar Management
-- ============================================================================

function ActionBars:InitializeBagBar()
    -- Bag bar buttons
    local bagBarButtons = {
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
        KeyRingButton
    }
    
    -- Hide bag bar initially
    self:UpdateBagBarVisibility()
    
    -- Create update frame to periodically check bag state
    if not self.bagBarUpdateFrame then
        self.bagBarUpdateFrame = CreateFrame("Frame")
        self.bagBarUpdateFrame:RegisterEvent("BAG_UPDATE")
        self.bagBarUpdateFrame:SetScript("OnEvent", function()
            ActionBars:UpdateBagBarVisibility()
        end)
        
        -- Also check periodically
        self.bagBarUpdateFrame:SetScript("OnUpdate", function()
            this.updateTimer = (this.updateTimer or 0) + arg1
            if this.updateTimer >= 0.2 then  -- Check every 200ms
                this.updateTimer = 0
                ActionBars:UpdateBagBarVisibility()
            end
        end)
    end
    
    -- Hook ContainerFrame OnShow/OnHide to detect bag open/close
    -- Check up to 5 container frames (backpack + 4 bags)
    for i = 1, 5 do
        local containerFrame = getglobal("ContainerFrame" .. i)
        if containerFrame then
            local oldOnShow = containerFrame:GetScript("OnShow")
            local oldOnHide = containerFrame:GetScript("OnHide")
            
            containerFrame:SetScript("OnShow", function()
                if oldOnShow then oldOnShow() end
                ActionBars:UpdateBagBarVisibility()
            end)
            
            containerFrame:SetScript("OnHide", function()
                if oldOnHide then oldOnHide() end
                ActionBars:UpdateBagBarVisibility()
            end)
        end
    end
    
    -- Hook bag bar buttons for cursor navigation
    for _, button in ipairs(bagBarButtons) do
        if button then
            -- Enable drag and drop
            button:RegisterForDrag("LeftButton")
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            
            -- Hook for cursor navigation
            if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
                ConsoleExperience.hooks:HookDynamicFrame(button, "Bag Bar Button")
            end
        end
    end
end

function ActionBars:UpdateBagBarVisibility()
    -- Check if any bag is open (check up to 5 container frames)
    local anyBagOpen = false
    for i = 1, 5 do
        local containerFrame = getglobal("ContainerFrame" .. i)
        if containerFrame and containerFrame:IsVisible() then
            anyBagOpen = true
            break
        end
    end
    
    -- Also check using IsBagOpen if available
    if not anyBagOpen then
        for i = 0, 4 do
            if IsBagOpen and IsBagOpen(i) then
                anyBagOpen = true
                break
            end
        end
    end
    
    -- Show/hide and position bag bar at bottom right corner
    if anyBagOpen then
        -- Position bag bar at bottom right corner
        local buttonSize = 30  -- Approximate button size
        local spacing = 5  -- Spacing between buttons
        local bottomY = 20  -- Distance from bottom
        local rightX = 20  -- Distance from right
        
        -- Position buttons from right to left
        local currentX = rightX
        
        -- Backpack button (rightmost)
        if MainMenuBarBackpackButton then 
            MainMenuBarBackpackButton:SetParent(UIParent)
            MainMenuBarBackpackButton:ClearAllPoints()
            MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            MainMenuBarBackpackButton:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        -- Bag slots (right to left: bag 3, 2, 1, 0)
        if CharacterBag3Slot then 
            CharacterBag3Slot:SetParent(UIParent)
            CharacterBag3Slot:ClearAllPoints()
            CharacterBag3Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag3Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag2Slot then 
            CharacterBag2Slot:SetParent(UIParent)
            CharacterBag2Slot:ClearAllPoints()
            CharacterBag2Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag2Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag1Slot then 
            CharacterBag1Slot:SetParent(UIParent)
            CharacterBag1Slot:ClearAllPoints()
            CharacterBag1Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag1Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        if CharacterBag0Slot then 
            CharacterBag0Slot:SetParent(UIParent)
            CharacterBag0Slot:ClearAllPoints()
            CharacterBag0Slot:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            CharacterBag0Slot:Show()
            currentX = currentX + buttonSize + spacing
        end
        
        -- Keyring button (leftmost)
        if KeyRingButton then 
            KeyRingButton:SetParent(UIParent)
            KeyRingButton:ClearAllPoints()
            KeyRingButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -currentX, bottomY)
            KeyRingButton:Show()
        end
    else
        if MainMenuBarBackpackButton then MainMenuBarBackpackButton:Hide() end
        if CharacterBag0Slot then CharacterBag0Slot:Hide() end
        if CharacterBag1Slot then CharacterBag1Slot:Hide() end
        if CharacterBag2Slot then CharacterBag2Slot:Hide() end
        if CharacterBag3Slot then CharacterBag3Slot:Hide() end
        if KeyRingButton then KeyRingButton:Hide() end
    end
end

-- ============================================================================
-- Global wrapper functions for XML callbacks
-- These are required because WoW 1.12 XML uses 'this' keyword
-- ============================================================================

function ConsoleActionButton_OnLoad()
    ConsoleExperience.actionbars:ButtonOnLoad(this)
end

function ConsoleActionButton_OnEvent(event)
    ConsoleExperience.actionbars:ButtonOnEvent(this, event)
end

function ConsoleActionButton_OnUpdate(elapsed)
    ConsoleExperience.actionbars:ButtonOnUpdate(this, elapsed)
end

function ConsoleActionButton_OnClick(mouseButton)
    ConsoleExperience.actionbars:ButtonOnClick(this, mouseButton)
end

function ConsoleActionButton_OnDragStart()
    ConsoleExperience.actionbars:ButtonOnDragStart(this)
end

function ConsoleActionButton_OnReceiveDrag()
    ConsoleExperience.actionbars:ButtonOnReceiveDrag(this)
end

function ConsoleActionButton_OnEnter()
    ConsoleExperience.actionbars:ButtonOnEnter(this)
end
