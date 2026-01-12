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
CursorKeys.originalBindings = {}
CursorKeys.cursorModeActive = false

-- ============================================================================
-- Binding Management
-- ============================================================================

function CursorKeys:SetupCursorBindings()
    if self.cursorModeActive then 
        CE_Debug("Cursor bindings already active")
        return 
    end
    
    CE_Debug("Setting up cursor bindings...")
    
    -- Save original bindings
    self:SaveOriginalBindings()
    
    -- Mark cursor mode as active
    self.cursorModeActive = true
    
    -- Apply base navigation bindings immediately so navigation works even before moving to a button
    -- These are the default bindings that always apply
    local Tooltip = ConsoleExperience.cursor.tooltip
    if Tooltip and Tooltip.GetBindings then
        -- Get default bindings (no button name = default)
        local bindings = Tooltip:GetBindings(nil)
        if bindings then
            self:ApplyContextBindings(bindings)
        end
    end
    
    CE_Debug("Cursor bindings activated!")
end

function CursorKeys:SaveOriginalBindings()
    -- Save current bindings for ALL keys that might be overridden by context bindings
    -- This includes navigation keys (5, 6, 7, 8) and action keys (1, 2, 3, 4)
    self.originalBindings = {}
    
    local keysToSave = {
        self.CURSOR_CONTROLS.up,      -- 7
        self.CURSOR_CONTROLS.down,    -- 5
        self.CURSOR_CONTROLS.left,    -- 6
        self.CURSOR_CONTROLS.right,   -- 8
        self.CURSOR_CONTROLS.confirm, -- 1
        self.CURSOR_CONTROLS.cancel,  -- 4
        "2",  -- X button (used for bind/send actions)
        "3",  -- Y button (used for delete/drop actions)
    }
    
    CE_Debug("Saving original bindings before cursor override:")
    for _, key in ipairs(keysToSave) do
        local action = GetBindingAction(key)
        if action and action ~= "" then
            self.originalBindings[key] = action
            CE_Debug("  Key " .. key .. " = " .. action)
        else
            CE_Debug("  Key " .. key .. " = (none)")
        end
    end
end

function CursorKeys:RestoreOriginalBindings()
    if not self.cursorModeActive then return end
    
    CE_Debug("RestoreOriginalBindings called, originalBindings contents:")
    for k, v in pairs(self.originalBindings) do
        CE_Debug("  originalBindings[" .. tostring(k) .. "] = " .. tostring(v))
    end
    
    -- Restore ALL original bindings exactly as they were saved
    -- This includes all keys that might have been overridden by context bindings
    local keysToRestore = {
        self.CURSOR_CONTROLS.up,      -- 7
        self.CURSOR_CONTROLS.down,    -- 5
        self.CURSOR_CONTROLS.left,    -- 6
        self.CURSOR_CONTROLS.right,   -- 8
        self.CURSOR_CONTROLS.confirm, -- 1
        self.CURSOR_CONTROLS.cancel,  -- 4
        "2",  -- X button
        "3",  -- Y button
    }
    
    for _, key in ipairs(keysToRestore) do
        local originalAction = self.originalBindings[key]
        CE_Debug("Checking key " .. key .. ": originalAction = " .. tostring(originalAction))
        if originalAction then
            -- Restore to whatever was bound before cursor mode
            SetBinding(key, originalAction)
            CE_Debug("Restored key " .. key .. " to: " .. originalAction)
        else
            -- No binding existed before, clear it
            SetBinding(key, nil)
            CE_Debug("Cleared key " .. key .. " (no original binding)")
        end
    end
    
    SaveBindings(1)
    
    self.cursorModeActive = false
    self.originalBindings = {}
    
    CE_Debug("Cursor bindings deactivated")
end

function CursorKeys:IsCursorModeActive()
    return self.cursorModeActive
end

-- Apply context-specific bindings based on hovered element
function CursorKeys:ApplyContextBindings(bindings, buttonName)
    if not self.cursorModeActive then return end
    if not bindings then return end
    
    -- Track if B button has a specific binding
    local hasBBinding = false
    
    -- Log all bindings being applied
    CE_Debug("Applying context bindings:")
    for _, binding in ipairs(bindings) do
        if binding.key and binding.action then
            CE_Debug("  Key " .. binding.key .. " = " .. binding.action)
        end
    end
    
    -- Apply all context bindings
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

