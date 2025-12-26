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
    
    -- Set cursor movement bindings
    SetBinding(self.CURSOR_CONTROLS.up, "CE_CURSOR_MOVE_UP")
    SetBinding(self.CURSOR_CONTROLS.down, "CE_CURSOR_MOVE_DOWN")
    SetBinding(self.CURSOR_CONTROLS.left, "CE_CURSOR_MOVE_LEFT")
    SetBinding(self.CURSOR_CONTROLS.right, "CE_CURSOR_MOVE_RIGHT")
    
    -- Set action bindings
    SetBinding(self.CURSOR_CONTROLS.confirm, "CE_CURSOR_CLICK_LEFT")
    SetBinding(self.CURSOR_CONTROLS.cancel, "CE_CURSOR_CLOSE")
    
    -- Debug: show all cursor bindings
    CE_Debug("Cursor bindings configured:")
    CE_Debug("  UP (key " .. self.CURSOR_CONTROLS.up .. "): CE_CURSOR_MOVE_UP")
    CE_Debug("  DOWN (key " .. self.CURSOR_CONTROLS.down .. "): CE_CURSOR_MOVE_DOWN")
    CE_Debug("  LEFT (key " .. self.CURSOR_CONTROLS.left .. "): CE_CURSOR_MOVE_LEFT")
    CE_Debug("  RIGHT (key " .. self.CURSOR_CONTROLS.right .. "): CE_CURSOR_MOVE_RIGHT")
    CE_Debug("  CONFIRM (key " .. self.CURSOR_CONTROLS.confirm .. "): CE_CURSOR_CLICK_LEFT")
    CE_Debug("  CANCEL (key " .. self.CURSOR_CONTROLS.cancel .. "): CE_CURSOR_CLOSE")
    
    SaveBindings(1)
    
    self.cursorModeActive = true
    
    CE_Debug("Cursor bindings activated!")
end

function CursorKeys:SaveOriginalBindings()
    -- Save current bindings for the keys we're going to override
    self.originalBindings = {}
    
    local keysToSave = {
        self.CURSOR_CONTROLS.up,
        self.CURSOR_CONTROLS.down,
        self.CURSOR_CONTROLS.left,
        self.CURSOR_CONTROLS.right,
        self.CURSOR_CONTROLS.confirm,
        self.CURSOR_CONTROLS.cancel,
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
    local keysToRestore = {
        self.CURSOR_CONTROLS.up,
        self.CURSOR_CONTROLS.down,
        self.CURSOR_CONTROLS.left,
        self.CURSOR_CONTROLS.right,
        self.CURSOR_CONTROLS.confirm,
        self.CURSOR_CONTROLS.cancel,
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
function CursorKeys:ApplyContextBindings(bindings)
    if not self.cursorModeActive then return end
    if not bindings then return end
    
    -- Track if B button has a specific binding
    local hasBBinding = false
    
    -- Apply all context bindings
    for _, binding in ipairs(bindings) do
        if binding.key and binding.action then
            SetBinding(binding.key, binding.action)
            CE_Debug("Applied context binding: key " .. binding.key .. " = " .. binding.action)
            
            if binding.key == self.CURSOR_CONTROLS.cancel then
                hasBBinding = true
            end
        end
    end
    
    -- If no B binding defined, default to close frame
    if not hasBBinding then
        SetBinding(self.CURSOR_CONTROLS.cancel, "CE_CURSOR_CLOSE")
    end
    
    -- Note: Don't SaveBindings here - too frequent, will cause lag
end

-- Module loaded silently

