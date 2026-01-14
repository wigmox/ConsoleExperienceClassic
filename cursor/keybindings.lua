--[[
    ConsoleExperienceClassic - Cursor Keybindings Module
    
    Manages dynamic key bindings when cursor mode is active
]]

-- Create cursor keybindings module namespace
ConsoleExperience.cursor = ConsoleExperience.cursor or {}
ConsoleExperience.cursor.keybindings = ConsoleExperience.cursor.keybindings or {}
local CursorKeys = ConsoleExperience.cursor.keybindings

-- Default cursor control keys (matching the action bar layout)
-- D-pad keys for navigation
CursorKeys.CURSOR_CONTROLS = {
    up = "7",      -- D-pad Up
    down = "5",    -- D-pad Down
    left = "6",    -- D-pad Left
    right = "8",   -- D-pad Right
    confirm = "1", -- A button (confirm/click)
    cancel = "4",  -- B button (cancel/back)
}

-- Store original bindings to restore later
CursorKeys.originalBindings = {}  -- Stores D-pad bindings (always the same)
CursorKeys.originalActionBindings = {}  -- Stores original action button bindings (1, 2, 3, 4) before cursor mode
CursorKeys.currentButton = nil    -- Tracks which button we're currently on
CursorKeys.cursorModeActive = false

-- ============================================================================
-- Binding Management
-- ============================================================================

function CursorKeys:SetupCursorBindings()
    -- If already active, restore first to switch modes
    if self.cursorModeActive then 
        self:RestoreOriginalBindings()
    end
    
    CE_Debug("Setting up cursor bindings...")
    
    -- Save original D-pad bindings (movement keys)
    self:SaveOriginalBindings()
    
    -- Mark cursor mode as active
    self.cursorModeActive = true
    self.currentButton = nil
    
    -- Apply base navigation bindings immediately so navigation works even before moving to a button
    -- These are the default bindings that always apply (D-pad only at this point)
    local Tooltip = ConsoleExperience.cursor.tooltip
    if Tooltip and Tooltip.GetBindings then
        -- Get default bindings (no button name = default, which includes D-pad)
        local bindings = Tooltip:GetBindings(nil)
        if bindings then
            -- Apply only D-pad bindings for now (no button yet)
            for _, binding in ipairs(bindings) do
                if binding.key and binding.action then
                    -- Only apply D-pad keys (5, 6, 7, 8)
                    local key = binding.key
                    if key == "5" or key == "6" or key == "7" or key == "8" then
                        SetBinding(key, binding.action)
                    end
                end
            end
        end
    end
    
    CE_Debug("Cursor bindings activated!")
end

function CursorKeys:SaveOriginalBindings()
    -- Save D-pad bindings (movement) - these are always the same
    self.originalBindings = {}
    
    local dPadKeys = {
        self.CURSOR_CONTROLS.up,      -- 7
        self.CURSOR_CONTROLS.down,    -- 5
        self.CURSOR_CONTROLS.left,    -- 6
        self.CURSOR_CONTROLS.right,   -- 8
    }
    
    CE_Debug("Saving original D-pad bindings:")
    for _, key in ipairs(dPadKeys) do
        local action = GetBindingAction(key)
        if action and action ~= "" then
            self.originalBindings[key] = action
            CE_Debug("  Key " .. key .. " = " .. action)
        else
            CE_Debug("  Key " .. key .. " = (none)")
        end
    end
    
    -- Save original action button bindings (1, 2, 3, 4) - these are restored when leaving a button
    self.originalActionBindings = {}
    local actionKeys = {
        self.CURSOR_CONTROLS.confirm, -- 1
        "2",  -- X button
        "3",  -- Y button
        self.CURSOR_CONTROLS.cancel,  -- 4
    }
    
    CE_Debug("Saving original action button bindings:")
    for _, key in ipairs(actionKeys) do
        local action = GetBindingAction(key)
        if action and action ~= "" then
            self.originalActionBindings[key] = action
            CE_Debug("  Key " .. key .. " = " .. action)
        else
            CE_Debug("  Key " .. key .. " = (none)")
        end
    end
end

-- Restore action button bindings (1, 2, 3, 4) to their original state (before cursor mode)
function CursorKeys:RestoreActionButtonsToOriginal()
    local actionKeys = {
        self.CURSOR_CONTROLS.confirm, -- 1
        "2",  -- X button
        "3",  -- Y button
        self.CURSOR_CONTROLS.cancel,  -- 4
    }
    
    CE_Debug("Restoring action buttons to original state:")
    for _, key in ipairs(actionKeys) do
        local originalAction = self.originalActionBindings[key]
        if originalAction then
            SetBinding(key, originalAction)
            CE_Debug("  Restored key " .. key .. " to: " .. originalAction)
        else
            SetBinding(key, nil)
            CE_Debug("  Cleared key " .. key .. " (no original binding)")
        end
    end
end

function CursorKeys:RestoreOriginalBindings()
    if not self.cursorModeActive then return end
    
    -- Restore action buttons to original state first
    self:RestoreActionButtonsToOriginal()
    
    -- Restore D-pad bindings
    CE_Debug("Restoring original D-pad bindings:")
    local dPadKeys = {
        self.CURSOR_CONTROLS.up,      -- 7
        self.CURSOR_CONTROLS.down,    -- 5
        self.CURSOR_CONTROLS.left,    -- 6
        self.CURSOR_CONTROLS.right,   -- 8
    }
    
    for _, key in ipairs(dPadKeys) do
        local originalAction = self.originalBindings[key]
        if originalAction then
            SetBinding(key, originalAction)
            CE_Debug("  Restored key " .. key .. " to: " .. originalAction)
        else
            SetBinding(key, nil)
            CE_Debug("  Cleared key " .. key .. " (no original binding)")
        end
    end
    
    SaveBindings(1)
    
    self.cursorModeActive = false
    self.originalBindings = {}
    self.originalActionBindings = {}
    self.currentButton = nil
    
    CE_Debug("Cursor bindings deactivated")
end

function CursorKeys:IsCursorModeActive()
    return self.cursorModeActive
end

-- Apply context-specific bindings based on hovered element
-- This should be called with the button object and its bindings
function CursorKeys:ApplyContextBindings(bindings, button)
    if not self.cursorModeActive then return end
    if not bindings then return end
    
    -- If we're moving from one button to another, restore action buttons to original first
    if self.currentButton and self.currentButton ~= button then
        self:RestoreActionButtonsToOriginal()
    end
    
    -- Update current button
    if button then
        self.currentButton = button
    end
    
    -- Track if B button has a specific binding
    local hasBBinding = false
    
    -- Log all bindings being applied
    local buttonName = button and (button:GetName() or tostring(button)) or "unknown"
    CE_Debug("Applying context bindings for button: " .. buttonName)
    for _, binding in ipairs(bindings) do
        if binding.key and binding.action then
            CE_Debug("  Key " .. binding.key .. " = " .. binding.action)
        end
    end
    
    -- Apply all bindings (D-pad + action buttons)
    for _, binding in ipairs(bindings) do
        if binding.key and binding.action then
            SetBinding(binding.key, binding.action)
            
            if binding.key == self.CURSOR_CONTROLS.cancel then
                hasBBinding = true
            end
        end
    end
    
    -- If no B binding defined, default to close frame
    if not hasBBinding then
        SetBinding(self.CURSOR_CONTROLS.cancel, "CE_CURSOR_CLOSE")
        CE_Debug("  Key " .. self.CURSOR_CONTROLS.cancel .. " = CE_CURSOR_CLOSE (default)")
    end
    
    -- Note: Don't SaveBindings here - too frequent, will cause lag
end

-- Module loaded silently

