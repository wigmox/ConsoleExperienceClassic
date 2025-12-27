--[[
    ConsoleExperienceClassic - Virtual Keyboard Module
    
    A full QWERTY virtual keyboard that appears in the lower half of the screen
    when the chat edit box is visible
]]

-- Create keyboard module namespace
ConsoleExperience.keyboard = ConsoleExperience.keyboard or {}
local Keyboard = ConsoleExperience.keyboard

-- State
Keyboard.frame = nil
Keyboard.shiftMode = false
Keyboard.currentText = ""
Keyboard.targetEditBox = nil
Keyboard.fakeEditBox = nil
Keyboard.currentKey = nil  -- Currently selected key for cursor navigation
Keyboard.modifierFrame = nil  -- Frame to check modifiers
Keyboard.lastShiftState = false  -- Track previous shift state for toggle

-- Constants
local KEY_HEIGHT = 40
local KEY_SPACING = 4
local ROW_SPACING = 6

-- QWERTY keyboard layout (Full English International)
-- All rows have 12 keys for uniform grid layout
local KEYBOARD_LAYOUT = {
    -- Row 1: Numbers and symbols (12 keys)
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="},
    -- Row 2: Top letters and brackets (12 keys)
    {"q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"},
    -- Row 3: Middle letters and punctuation (12 keys - added apostrophe)
    {"a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "\\"},
    -- Row 4: Bottom letters and punctuation (12 keys - centered to match other rows)
    -- Keys positioned so b, n, m, , align with center keys of other rows (positions 5-8)
    {"z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "\\", "'"},
}

-- ============================================================================
-- Frame Creation
-- ============================================================================

function Keyboard:CreateFrame()
    if self.frame then return self.frame end
    
    -- Get screen dimensions
    -- UIParent dimensions are scaled based on UI scale setting, not physical resolution
    -- Physical resolution can be different (e.g., 1920x1200 physical vs 1228x768 UI scaled)
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    local uiScale = UIParent:GetScale() or 1
    local keyboardHeight = screenHeight * 0.48  -- Use 48% of screen height
    
    -- Debug: show UI scaling info
    if CE_Debug then
        -- Try to get physical resolution (may not be available in all WoW versions)
        local physicalWidth = screenWidth / uiScale
        local physicalHeight = screenHeight / uiScale
        CE_Debug(string.format("UI Dimensions - UIParent: %d x %d | UIScale: %.2f | Physical (calculated): %.0f x %.0f",
            screenWidth, screenHeight, uiScale, physicalWidth, physicalHeight))
    end
    
    -- Main keyboard frame (lower half)
    local frame = CreateFrame("Frame", "ConsoleExperienceKeyboard", UIParent)
    -- Position from bottom, taking exactly 48% of screen height
    -- Use explicit width to ensure full screen width
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
    frame:SetPoint("TOP", UIParent, "BOTTOM", 0, keyboardHeight)
    
    -- Debug: verify frame dimensions after creation
    if CE_Debug then
        local uiScale = UIParent:GetScale() or 1
        local effectiveWidth = screenWidth / uiScale
        CE_Debug(string.format("Frame Creation - Screen: %d x %d | UIScale: %.2f | Effective: %.0f x %.0f | Frame: %.0f x %.0f | KeyboardHeight: %.1f",
            screenWidth, screenHeight, uiScale, effectiveWidth, screenHeight / uiScale, frame:GetWidth(), frame:GetHeight(), keyboardHeight))
    end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(50)  -- Lower than chat frame (100)
    frame:EnableMouse(true)
    
    -- Hook OnHide to ensure cleanup when frame is hidden (e.g., by Escape key)
    frame:SetScript("OnHide", function()
        -- Only call Hide() if keyboard module exists and frame is actually being hidden
        if ConsoleExperience.keyboard and ConsoleExperience.keyboard.frame == this then
            -- Prevent infinite loop by checking if we're already hiding
            if not ConsoleExperience.keyboard._hiding then
                ConsoleExperience.keyboard._hiding = true
                -- Hide ChatFrameEditBox first - this will trigger chat module to restore normal chat
                if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                    ChatFrameEditBox:Hide()
                    ChatFrameEditBox:ClearFocus()
                end
                -- Call Hide() to clean up keyboard state
                -- Note: Hide() will also try to hide ChatFrameEditBox, but it's already hidden, so that's fine
                ConsoleExperience.keyboard:Hide()
                ConsoleExperience.keyboard._hiding = nil
            end
        end
    end)
    
    frame:Hide()
    
    -- Add to special frames for Escape to close (add once when created, like placement frame)
    if frame:GetName() then
        local frameName = frame:GetName()
        local alreadyAdded = false
        for _, specialFrame in ipairs(UISpecialFrames) do
            if specialFrame == frameName then
                alreadyAdded = true
                break
            end
        end
        if not alreadyAdded then
            table.insert(UISpecialFrames, frameName)
        end
    end
    
    -- Don't add ChatFrame1 to UISpecialFrames - the chat module handles its own visibility
    -- Only the keyboard frame should be in UISpecialFrames
    
    -- Background - translucent like chat frame
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    bg:SetVertexColor(0, 0, 0, 0.7)  -- Same alpha as chat frame
    frame.bg = bg
    
    -- Border
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Create keyboard keys container - fill the frame (accounting for backdrop insets)
    local keysContainer = CreateFrame("Frame", "CEKeyboardKeysContainer", frame)
    -- Account for backdrop insets - keys should be within the visible area
    -- Position with 4px insets, then explicitly set size to ensure exact dimensions
    keysContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    -- Calculate exact size: frame width - 8 (4px on each side)
    local frameWidth = frame:GetWidth()
    local frameHeight = frame:GetHeight()
    if frameWidth > 0 and frameHeight > 0 then
        keysContainer:SetWidth(frameWidth - 8)
        keysContainer:SetHeight(frameHeight - 8)
    end
    frame.keysContainer = keysContainer
    
    -- Create fake edit box at bottom of keyboard frame
    local fakeEditBox = CreateFrame("EditBox", "CEKeyboardFakeEditBox", frame)
    fakeEditBox:SetWidth(frameWidth - 20)
    fakeEditBox:SetHeight(30)
    fakeEditBox:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    fakeEditBox:SetFontObject("GameFontNormal")
    fakeEditBox:SetAutoFocus(false)
    fakeEditBox:SetText("")
    fakeEditBox:SetTextColor(1, 1, 1, 1)
    
    -- Background for edit box
    local editBoxBg = fakeEditBox:CreateTexture(nil, "BACKGROUND")
    editBoxBg:SetAllPoints(fakeEditBox)
    editBoxBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    editBoxBg:SetVertexColor(0, 0, 0, 0.8)
    fakeEditBox.bg = editBoxBg
    
    -- Border for edit box
    local editBoxBorder = CreateFrame("Frame", nil, fakeEditBox)
    editBoxBorder:SetPoint("TOPLEFT", fakeEditBox, "TOPLEFT", -2, 2)
    editBoxBorder:SetPoint("BOTTOMRIGHT", fakeEditBox, "BOTTOMRIGHT", 2, -2)
    editBoxBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    editBoxBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    -- Update text when typing
    fakeEditBox:SetScript("OnTextChanged", function()
        if this:GetText() then
            Keyboard.currentText = this:GetText()
        end
    end)
    
    -- Handle Enter key
    fakeEditBox:SetScript("OnEnterPressed", function()
        Keyboard:Confirm()
    end)
    
    frame.fakeEditBox = fakeEditBox
    self.fakeEditBox = fakeEditBox
    
    -- Create keyboard keys
    self:CreateKeys(keysContainer)
    
    self.frame = frame
    
    return frame
end

-- ============================================================================
-- Create Keyboard Keys
-- ============================================================================

function Keyboard:CreateKeys(parent)
    self.keys = {}
    
    -- Get width from parent container (keysContainer) - use actual GetWidth() as source of truth
    local frame = parent:GetParent()
    local frameWidth = frame and frame:GetWidth() or 0
    local frameHeight = frame and frame:GetHeight() or 0
    
    -- Use parent's actual width/height as the source of truth (it's already positioned correctly)
    -- Get actual dimensions directly from parent - this is the most accurate
    local containerWidth = parent:GetWidth() or 0
    local containerHeight = parent:GetHeight() or 0
    
    -- Fallback if parent width not available yet (shouldn't happen, but just in case)
    if containerWidth <= 0 then
        if frameWidth > 0 then
            containerWidth = frameWidth - 8  -- Account for 4px insets on each side
        else
            containerWidth = UIParent:GetWidth() - 8
        end
    end
    if containerHeight <= 0 then
        if frameHeight > 0 then
            containerHeight = frameHeight - 8  -- Account for 4px insets on each side
        else
            containerHeight = UIParent:GetHeight() * 0.48 - 8
        end
    end
    
    -- Get actual parent dimensions again to ensure accuracy (use these for calculations)
    local parentWidthActual = parent:GetWidth()
    local parentHeightActual = parent:GetHeight()
    
    -- Use actual parent dimensions (these are the source of truth) - ensure integers
    if parentWidthActual and parentWidthActual > 0 then
        containerWidth = math.floor(parentWidthActual + 0.5)  -- Round to nearest integer
    end
    if parentHeightActual and parentHeightActual > 0 then
        containerHeight = math.floor(parentHeightActual + 0.5)  -- Round to nearest integer
    end
    
    -- Debug to console using CE_Debug
    if CE_Debug then
        local screenWidth = UIParent:GetWidth()
        CE_Debug(string.format("Keyboard Dimensions - Screen: %d | Frame: %.0f x %.0f | Container: %.0f x %.0f | Parent Actual: %.0f x %.0f",
            screenWidth, frameWidth, frameHeight, containerWidth, containerHeight, parentWidthActual or 0, parentHeightActual or 0))
    end
    
    -- Calculate available height for keys (leave space for special keys row at bottom)
    local numRows = table.getn(KEYBOARD_LAYOUT)
    local specialKeysRowHeight = KEY_HEIGHT + ROW_SPACING
    local availableHeight = containerHeight - specialKeysRowHeight - 30 -- 30px padding
    local totalKeysHeight = (numRows * KEY_HEIGHT) + ((numRows - 1) * ROW_SPACING)
    
    -- Scale keys to fit height if needed
    local heightScale = 1.0
    local adjustedKeyHeight = KEY_HEIGHT
    local adjustedRowSpacing = ROW_SPACING
    if totalKeysHeight > availableHeight then
        heightScale = availableHeight / totalKeysHeight
        adjustedKeyHeight = KEY_HEIGHT * heightScale
        adjustedRowSpacing = ROW_SPACING * heightScale
    end
    
    -- Create regular keys - fill full width edge-to-edge
    -- No padding needed - container already accounts for border insets
    local keyPadding = 0  -- No padding - fill edge to edge
    local usableWidth = containerWidth  -- Use full container width
    
    -- All rows have the same number of keys (12), so calculate key width once
    local numKeysPerRow = 12  -- All rows have exactly 12 keys
    local totalSpacing = (numKeysPerRow - 1) * KEY_SPACING
    local keyWidth = (usableWidth - totalSpacing) / numKeysPerRow
    
    -- Position keys to fill from 0 to containerWidth
    -- First key's left edge at 0, center at keyWidth/2
    local firstKeyCenterX = keyWidth / 2
    
    for rowIndex, row in ipairs(KEYBOARD_LAYOUT) do
        local rowXOffset = 0
        
        -- All rows have 12 keys, so use the same keyWidth for all
        for keyIndex, char in ipairs(row) do
            -- Calculate X position: first key center + offset for each subsequent key
            -- This ensures keys fill from 0 to containerWidth with uniform spacing
            local x = firstKeyCenterX + (keyIndex - 1) * (keyWidth + KEY_SPACING) + rowXOffset
            local y = -30 - (rowIndex - 1) * (adjustedKeyHeight + adjustedRowSpacing) - (adjustedKeyHeight / 2)
            local key = self:CreateKey(parent, char, x, y, keyWidth, adjustedKeyHeight)
            -- Store row and column for navigation
            key.keyRow = rowIndex
            key.keyCol = keyIndex
            table.insert(self.keys, key)
        end
        
        -- Ensure last key of each row fills to containerWidth exactly (handle rounding errors)
        -- Since all rows have 12 keys, adjust the 12th key of each row
        local rowStartIndex = (rowIndex - 1) * numKeysPerRow + 1
        local rowEndIndex = rowStartIndex + numKeysPerRow - 1
        if rowEndIndex <= table.getn(self.keys) then
            local lastKeyInRow = self.keys[rowEndIndex]
            if lastKeyInRow then
                -- Calculate what the last key's right edge currently is
                local lastKeyCurrentRight = firstKeyCenterX + (numKeysPerRow - 1) * (keyWidth + KEY_SPACING) + (keyWidth / 2)
                local expectedRight = containerWidth  -- Should fill to container edge
                
                -- Always adjust the last key to fill exactly to container edge
                local adjustment = expectedRight - lastKeyCurrentRight
                local newWidth = keyWidth + adjustment
                
                -- Only adjust if there's a meaningful difference (more than 0.1 pixels)
                if math.abs(adjustment) > 0.1 then
                    if newWidth > keyWidth * 0.5 then  -- Ensure it's not too small
                        lastKeyInRow:SetWidth(newWidth)
                    end
                end
            end
        end
    end
    
    -- Add special keys row - at the beginning of row 5, same width as regular keys
    local specialKeysY = -30 - (table.getn(KEYBOARD_LAYOUT)) * (adjustedKeyHeight + adjustedRowSpacing) - (adjustedKeyHeight / 2)
    local specialKeyHeight = adjustedKeyHeight
    
    -- Special keys: SHIFT, SPACE, DEL, ENTER - all same width as regular keys
    local specialKeys = {"SHIFT", "SPACE", "DEL", "ENTER"}
    local specialKeyWidth = keyWidth  -- Same width as regular keys
    
    -- Command buttons: Guild, Party, Whisper, and Channel buttons (1-5)
    local commandButtons = {
        {label = "GUILD", command = "/g ", color = {0.2, 0.8, 0.2, 0.9}},  -- Green
        {label = "PARTY", command = "/p ", color = {0.2, 0.6, 0.9, 0.9}},   -- Blue
        {label = "WHISPER", command = "/w ", color = {0.9, 0.6, 0.2, 0.9}}, -- Orange
        {label = "CH1", command = "/1 ", color = {0.7, 0.7, 0.7, 0.9}},     -- Gray
        {label = "CH2", command = "/2 ", color = {0.7, 0.7, 0.7, 0.9}},     -- Gray
        {label = "CH3", command = "/3 ", color = {0.7, 0.7, 0.7, 0.9}},      -- Gray
        {label = "CH4", command = "/4 ", color = {0.7, 0.7, 0.7, 0.9}},     -- Gray
        {label = "CH5", command = "/5 ", color = {0.7, 0.7, 0.7, 0.9}},     -- Gray
    }
    
    -- Position special keys from left to right at the beginning of the row
    for keyIndex, keyLabel in ipairs(specialKeys) do
        local x = firstKeyCenterX + (keyIndex - 1) * (specialKeyWidth + KEY_SPACING)
        local y = specialKeysY
        
        if keyLabel == "SHIFT" then
            local shiftKey = self:CreateSpecialKey(parent, "SHIFT", x, y, specialKeyWidth, specialKeyHeight)
            shiftKey.action = function() Keyboard:ToggleShift() end
            shiftKey.keyRow = table.getn(KEYBOARD_LAYOUT) + 1  -- Special keys row
            shiftKey.keyCol = keyIndex
            self.shiftKey = shiftKey
            
            -- Add LT texture to shift key (top right corner)
            local ltTexture = shiftKey:CreateTexture(nil, "OVERLAY")
            ltTexture:SetWidth(24)
            ltTexture:SetHeight(24)
            ltTexture:SetPoint("TOPRIGHT", shiftKey, "TOPRIGHT", -2, -2)
            ltTexture:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\img\\lt")
            ltTexture:SetAlpha(0.8)
            shiftKey.ltTexture = ltTexture
        elseif keyLabel == "SPACE" then
            local spaceKey = self:CreateSpecialKey(parent, "SPACE", x, y, specialKeyWidth, specialKeyHeight)
            spaceKey.action = function() Keyboard:AddChar(" ") end
            spaceKey.keyRow = table.getn(KEYBOARD_LAYOUT) + 1  -- Special keys row
            spaceKey.keyCol = keyIndex
        elseif keyLabel == "DEL" then
            local deleteKey = self:CreateSpecialKey(parent, "DEL", x, y, specialKeyWidth, specialKeyHeight)
            deleteKey.action = function() Keyboard:DeleteChar() end
            deleteKey.keyRow = table.getn(KEYBOARD_LAYOUT) + 1  -- Special keys row
            deleteKey.keyCol = keyIndex
        elseif keyLabel == "ENTER" then
            local enterKey = self:CreateSpecialKey(parent, "ENTER", x, y, specialKeyWidth, specialKeyHeight)
            enterKey.action = function() Keyboard:Confirm() end
            enterKey:SetBackdropColor(0, 0.8, 0, 0.8)  -- Green for confirm
            enterKey.keyRow = table.getn(KEYBOARD_LAYOUT) + 1  -- Special keys row
            enterKey.keyCol = keyIndex
            self.enterKey = enterKey
            
            -- Add RT texture to enter key (top right corner)
            local rtTexture = enterKey:CreateTexture(nil, "OVERLAY")
            rtTexture:SetWidth(24)
            rtTexture:SetHeight(24)
            rtTexture:SetPoint("TOPRIGHT", enterKey, "TOPRIGHT", -2, -2)
            rtTexture:SetTexture("Interface\\AddOns\\ConsoleExperienceClassic\\img\\rt")
            rtTexture:SetAlpha(0.8)
            enterKey.rtTexture = rtTexture
        end
    end
    
    -- Add command buttons after the special keys
    local commandStartIndex = table.getn(specialKeys) + 1
    for cmdIndex, cmdInfo in ipairs(commandButtons) do
        local x = firstKeyCenterX + (commandStartIndex + cmdIndex - 2) * (specialKeyWidth + KEY_SPACING)
        local y = specialKeysY
        
        -- Capture cmdInfo in local variable to avoid closure issues
        local cmdLabel = cmdInfo.label
        local cmdCommand = cmdInfo.command
        local cmdColor = cmdInfo.color
        
        local cmdButton = self:CreateSpecialKey(parent, cmdLabel, x, y, specialKeyWidth, specialKeyHeight)
        cmdButton.action = function()
            -- Insert the command prefix into the current text
            -- Ensure currentText is initialized (not nil)
            if not Keyboard.currentText then
                Keyboard.currentText = ""
            end
            Keyboard.currentText = cmdCommand .. Keyboard.currentText
            if Keyboard.fakeEditBox then
                Keyboard.fakeEditBox:SetText(Keyboard.currentText)
            end
        end
        cmdButton:SetBackdropColor(unpack(cmdColor))
        cmdButton.keyRow = table.getn(KEYBOARD_LAYOUT) + 1  -- Special keys row
        cmdButton.keyCol = commandStartIndex + cmdIndex - 1
        
        -- Ensure self.keys exists before inserting
        if not self.keys then
            self.keys = {}
        end
        table.insert(self.keys, cmdButton)
    end
end

function Keyboard:CreateKey(parent, char, x, y, width, height)
    local button = CreateFrame("Button", "CEKeyboardKey" .. char .. x .. y, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint("CENTER", parent, "TOPLEFT", x, y)
    button:EnableMouse(true)  -- Enable mouse for cursor system
    button:EnableKeyboard(false)  -- Disable keyboard to prevent conflicts
    button:Show()  -- Ensure button is visible for cursor system
    
    -- Background - square shape
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    button.bg = button:GetBackdrop()
    
    -- Label
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", button, "CENTER", 0, 0)
    label:SetText(char)
    label:SetTextColor(1, 1, 1, 1)
    button.label = label
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(highlight)
    
    -- Store key info
    button.keyChar = char
    button.keyIndex = table.getn(self.keys) + 1
    button.keyRow = nil  -- Will be set when creating keys
    button.keyCol = nil  -- Will be set when creating keys
    
    -- Click handler - works with both mouse and cursor system
    button:SetScript("OnClick", function()
        Keyboard:AddChar(this.keyChar)
    end)
    
    -- Make button clickable via cursor system
    button.Click = function(self, mouseButton)
        if mouseButton == "LeftButton" or not mouseButton then
            Keyboard:AddChar(self.keyChar)
        end
    end
    
    return button
end

function Keyboard:CreateSpecialKey(parent, label, x, y, width, height)
    local button = CreateFrame("Button", "CEKeyboardSpecialKey" .. label, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint("CENTER", parent, "TOPLEFT", x, y)
    button:EnableMouse(true)  -- Enable mouse for cursor system
    button:EnableKeyboard(false)  -- Disable keyboard to prevent conflicts
    button:Show()  -- Ensure button is visible for cursor system
    
    -- Background - square shape
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    button:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
    button:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
    button.bg = button:GetBackdrop()
    
    -- Label
    local labelText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("CENTER", button, "CENTER", 0, 0)
    labelText:SetText(label)
    labelText:SetTextColor(1, 1, 1, 1)
    button.label = labelText
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(highlight)
    
    -- Click handler - works with both mouse and cursor system
    button:SetScript("OnClick", function()
        if this.action then
            this.action()
        end
    end)
    
    -- Make button clickable via cursor system
    button.Click = function(self, mouseButton)
        if mouseButton == "LeftButton" or not mouseButton then
            if self.action then
                self.action()
            end
        end
    end
    
    return button
end

-- ============================================================================
-- Text Input Functions
-- ============================================================================

function Keyboard:AddChar(char)
    if self.shiftMode then
        -- Handle uppercase - check if lowercase letter (Lua 5.0 compatible)
        if char >= "a" and char <= "z" then
            char = string.upper(char)
        -- Handle shift combinations for numbers and symbols
        elseif char == "1" then
            char = "!"
        elseif char == "2" then
            char = "@"
        elseif char == "3" then
            char = "#"
        elseif char == "4" then
            char = "$"
        elseif char == "5" then
            char = "%"
        elseif char == "6" then
            char = "^"
        elseif char == "7" then
            char = "&"
        elseif char == "8" then
            char = "*"
        elseif char == "9" then
            char = "("
        elseif char == "0" then
            char = ")"
        elseif char == "-" then
            char = "_"
        elseif char == "=" then
            char = "+"
        elseif char == "[" then
            char = "{"
        elseif char == "]" then
            char = "}"
        elseif char == ";" then
            char = ":"
        elseif char == "'" then
            char = '"'
        elseif char == "," then
            char = "<"
        elseif char == "." then
            char = ">"
        elseif char == "/" then
            char = "?"
        end
    end
    
    -- Add character to current text
    self.currentText = self.currentText .. char
    
    -- Update fake edit box (not the real one to avoid focus issues)
    if self.fakeEditBox then
        self.fakeEditBox:SetText(self.currentText)
    end
    
    -- Note: Shift mode stays active until toggled off (no auto-disable)
end

function Keyboard:DeleteChar()
    if string.len(self.currentText) > 0 then
        self.currentText = string.sub(self.currentText, 1, -2)
        
        -- Update fake edit box
        if self.fakeEditBox then
            self.fakeEditBox:SetText(self.currentText)
        end
    end
end

function Keyboard:ToggleShift()
    self.shiftMode = not self.shiftMode
    self:UpdateKeyLabels()
    
    -- Update shift key visual feedback
    if self.shiftKey then
        if self.shiftMode then
            self.shiftKey:SetBackdropColor(0.5, 0.5, 0.5, 0.9)  -- Highlighted when active
        else
            self.shiftKey:SetBackdropColor(0.3, 0.3, 0.3, 0.9)  -- Normal state
        end
    end
end

-- Check for modifier keys and update keyboard state
function Keyboard:CheckModifiers()
    if not self.frame or not self.frame:IsVisible() then
        return
    end
    
    -- Check for shift modifier (LT) - toggle on press, not hold
    local shiftPressed = IsShiftKeyDown()
    
    -- Toggle shift mode when shift goes from not pressed to pressed
    if shiftPressed and not self.lastShiftState then
        -- Shift was just pressed - toggle shift mode
        self.shiftMode = not self.shiftMode
        self:UpdateKeyLabels()
        
        -- Update shift key visual state
        if self.shiftKey then
            if self.shiftMode then
                self.shiftKey:SetBackdropColor(0.5, 0.5, 0.5, 0.9)
            else
                self.shiftKey:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
            end
        end
    end
    
    -- Update last shift state
    self.lastShiftState = shiftPressed
    
    -- Check for control modifier (RT) - send text if pressed
    local ctrlPressed = IsControlKeyDown()
    if ctrlPressed and string.len(self.currentText) > 0 then
        self:Confirm()
    end
end

-- Initialize cursor navigation for keyboard keys
function Keyboard:InitializeCursorNavigation()
    if not self.frame or not self.keys then
        return
    end
    
    -- Register keyboard frame with cursor system
    local Cursor = ConsoleExperience.cursor
    if Cursor and Cursor.navigationState then
        -- Add keyboard frame to active frames so cursor can navigate keys
        Cursor.navigationState.activeFrames[self.frame] = true
        
        -- Ensure cursor is on top
        if Cursor.EnsureOnTop then
            Cursor:EnsureOnTop(self.frame)
        end
        
        -- Refresh cursor system to collect keyboard buttons
        if Cursor.RefreshFrame then
            Cursor:RefreshFrame()
        end
        
        -- Set up cursor navigation bindings
        if ConsoleExperience.cursor.keybindings and ConsoleExperience.cursor.keybindings.SetupCursorBindings then
            ConsoleExperience.cursor.keybindings:SetupCursorBindings()
        end
        
        -- Move cursor to first key if available
        if self.keys and table.getn(self.keys) > 0 then
            local firstKey = self.keys[1]
            if firstKey then
                self.currentKey = firstKey
                -- Move cursor to first key
                if Cursor.MoveCursorToButton then
                    Cursor:MoveCursorToButton(firstKey)
                end
                -- Show cursor
                if Cursor.Show then
                    Cursor:Show()
                end
            end
        end
    end
end

function Keyboard:UpdateKeyLabels()
    if not self.keys then return end
    
    for _, key in ipairs(self.keys) do
        if key.label and key.keyChar then
            local char = key.keyChar
            -- Check if lowercase letter (Lua 5.0 compatible)
            if self.shiftMode and char >= "a" and char <= "z" then
                char = string.upper(char)
            -- Handle shift combinations for numbers and symbols
            elseif self.shiftMode and char == "1" then
                char = "!"
            elseif self.shiftMode and char == "2" then
                char = "@"
            elseif self.shiftMode and char == "3" then
                char = "#"
            elseif self.shiftMode and char == "4" then
                char = "$"
            elseif self.shiftMode and char == "5" then
                char = "%"
            elseif self.shiftMode and char == "6" then
                char = "^"
            elseif self.shiftMode and char == "7" then
                char = "&"
            elseif self.shiftMode and char == "8" then
                char = "*"
            elseif self.shiftMode and char == "9" then
                char = "("
            elseif self.shiftMode and char == "0" then
                char = ")"
            elseif self.shiftMode and char == "-" then
                char = "_"
            elseif self.shiftMode and char == "=" then
                char = "+"
            elseif self.shiftMode and char == "[" then
                char = "{"
            elseif self.shiftMode and char == "]" then
                char = "}"
            elseif self.shiftMode and char == ";" then
                char = ":"
            elseif self.shiftMode and char == "'" then
                char = '"'
            elseif self.shiftMode and char == "," then
                char = "<"
            elseif self.shiftMode and char == "." then
                char = ">"
            elseif self.shiftMode and char == "/" then
                char = "?"
            end
            key.label:SetText(char)
        end
    end
end

function Keyboard:Confirm()
    -- Send the message
    local textToSend = self.currentText or ""
    
    if string.len(textToSend) > 0 then
        local editBox = self.targetEditBox or ChatFrameEditBox
        
        if editBox == ChatFrameEditBox then
            -- Check if it's a command (starts with /)
            if string.sub(textToSend, 1, 1) == "/" then
                -- Parse command: extract command name and arguments
                local command = string.sub(textToSend, 2)  -- Remove the "/"
                local commandName = command
                local commandArgs = ""
                
                -- Find space to separate command name from arguments
                local spacePos = string.find(command, " ")
                if spacePos then
                    commandName = string.sub(command, 1, spacePos - 1)
                    commandArgs = string.sub(command, spacePos + 1)
                end
                
                -- Convert to lowercase for lookup
                commandName = string.lower(commandName)
                
                -- Check for numeric channel commands first (/1, /2, /3, etc.)
                local channelNumber = tonumber(commandName)
                local chatType = nil
                local whisperTarget = nil
                local commandHandled = false
                
                -- If it's a number, it's a channel command
                if channelNumber then
                    -- Numeric channel (e.g., /1, /2, /3)
                    if string.len(commandArgs) > 0 then
                        SendChatMessage(commandArgs, "CHANNEL", nil, channelNumber)
                        commandHandled = true
                    end
                -- Check for chat channel shortcuts (these aren't in SlashCmdList)
                elseif commandName == "g" or commandName == "guild" then
                    chatType = "GUILD"
                elseif commandName == "p" or commandName == "party" then
                    chatType = "PARTY"
                elseif commandName == "r" or commandName == "raid" then
                    chatType = "RAID"
                elseif commandName == "rw" or commandName == "raidwarning" then
                    chatType = "RAID_WARNING"
                elseif commandName == "o" or commandName == "officer" then
                    chatType = "GUILD_OFFICER"
                elseif commandName == "s" or commandName == "say" then
                    chatType = "SAY"
                elseif commandName == "y" or commandName == "yell" then
                    chatType = "YELL"
                elseif commandName == "e" or commandName == "emote" or commandName == "me" then
                    chatType = "EMOTE"
                elseif commandName == "w" or commandName == "whisper" or commandName == "tell" or commandName == "t" then
                    -- Whisper needs a target name
                    chatType = "WHISPER"
                    -- Extract target name from commandArgs (first word)
                    local targetSpacePos = string.find(commandArgs, " ")
                    if targetSpacePos then
                        whisperTarget = string.sub(commandArgs, 1, targetSpacePos - 1)
                        commandArgs = string.sub(commandArgs, targetSpacePos + 1)
                    else
                        -- No space found, entire args is the target
                        whisperTarget = commandArgs
                        commandArgs = ""
                    end
                end
                
                -- If it's a chat channel command, send via SendChatMessage
                if chatType then
                    commandHandled = true
                    if chatType == "WHISPER" then
                        if whisperTarget and string.len(whisperTarget) > 0 and string.len(commandArgs) > 0 then
                            SendChatMessage(commandArgs, chatType, nil, whisperTarget)
                        else
                            -- Invalid whisper format
                            if ChatFrame1 then
                                ChatFrame1:AddMessage("|cffff0000Usage: /w <name> <message>|r")
                            end
                        end
                    else
                        -- Regular chat channel
                        if string.len(commandArgs) > 0 then
                            SendChatMessage(commandArgs, chatType)
                        end
                        -- If no message, just switch to that channel (WoW will handle it)
                    end
                end
                
                -- Only check SlashCmdList if command hasn't been handled yet
                if not commandHandled then
                    -- Not a chat channel command, try to find it in SlashCmdList
                    local commandFound = false
                    
                    -- Search through SlashCmdList to find matching command
                    for cmdName, cmdFunc in pairs(SlashCmdList) do
                        if type(cmdFunc) == "function" then
                            -- Check all SLASH_* variables for this command (SLASH_CMDNAME1, SLASH_CMDNAME2, etc.)
                            local i = 1
                            while true do
                                local slashVar = "SLASH_" .. cmdName .. i
                                local cmdString = getglobal(slashVar)
                                if not cmdString then
                                    break
                                end
                                
                                -- Remove leading "/" and compare (case-insensitive)
                                local cmdStr = string.lower(string.sub(cmdString, 2))
                                if cmdStr == commandName then
                                    -- Found the command, execute it
                                    cmdFunc(commandArgs)
                                    commandFound = true
                                    break
                                end
                                
                                i = i + 1
                            end
                            
                            if commandFound then
                                break
                            end
                        end
                    end
                    
                    -- If command not found, display error message
                    if not commandFound then
                        if ChatFrame1 then
                            ChatFrame1:AddMessage("|cffff0000Unknown command:|r " .. textToSend)
                        end
                    end
                end
            else
                -- Regular chat message - use SendChatMessage
                SendChatMessage(textToSend, "SAY")
            end
        else
            -- For other edit boxes, try to set text safely
            if editBox and editBox.SetText then
                editBox:SetText(textToSend)
            end
        end
    end
    
    -- Clear text but keep keyboard visible
    self.currentText = ""
    if self.fakeEditBox then
        self.fakeEditBox:SetText("")
    end
    
    -- Don't hide keyboard - it stays visible until Escape is pressed
end

-- ============================================================================
-- Show/Hide/Toggle
-- ============================================================================

function Keyboard:Show(editBox)
    -- Check if keyboard is enabled in config
    local config = ConsoleExperience.config
    if config and not config:Get("keyboardEnabled") then
        return  -- Keyboard is disabled, don't show
    end
    
    if not self.frame then
        self:CreateFrame()
    end
    
    -- Store target EditBox
    self.targetEditBox = editBox
    
    -- Get current text from EditBox (safely handle nil)
    self.currentText = ""
    if editBox then
        -- Try GetText method if it exists
        if editBox.GetText then
            local success, text = pcall(function() return editBox:GetText() end)
            if success and text then
                self.currentText = text
            end
        end
    elseif ChatFrameEditBox then
        -- Try GetText method if it exists, but don't fail if it doesn't
        if ChatFrameEditBox.GetText then
            local success, text = pcall(function() return ChatFrameEditBox:GetText() end)
            if success and text then
                self.currentText = text
            end
        end
    end
    
    -- Frames are already in UISpecialFrames (added when created), no need to add again
    
    -- Remove focus from real edit box to allow D-pad movement
    if ChatFrameEditBox then
        ChatFrameEditBox:ClearFocus()
        -- Disable keyboard input on real edit box
        ChatFrameEditBox:EnableKeyboard(false)
    end
    if editBox and editBox.ClearFocus then
        editBox:ClearFocus()
        if editBox.EnableKeyboard then
            editBox:EnableKeyboard(false)
        end
    end
    
    -- Update fake edit box text
    if self.fakeEditBox then
        self.fakeEditBox:SetText(self.currentText)
    end
    
    if self.frame then
        -- Update size based on current screen dimensions
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        local keyboardHeight = screenHeight * 0.48
        
        self.frame:ClearAllPoints()
        -- Position from bottom, taking exactly 48% of screen height
        -- Use explicit width/height to ensure full width
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
        self.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)
        self.frame:SetPoint("TOP", UIParent, "BOTTOM", 0, keyboardHeight)
        
        -- Debug: verify frame dimensions
        if CE_Debug then
            local uiScale = UIParent:GetScale() or 1
            local effectiveWidth = screenWidth / uiScale
            CE_Debug(string.format("Frame Positioning - Screen: %d x %d | UIScale: %.2f | Effective: %.0f x %.0f | Frame After SetPoint: %.0f x %.0f | KeyboardHeight: %.1f",
                screenWidth, screenHeight, uiScale, effectiveWidth, screenHeight / uiScale, self.frame:GetWidth(), self.frame:GetHeight(), keyboardHeight))
        end
        
        -- Show frame first to ensure it's laid out and has correct dimensions
        self.frame:Show()
        
        -- Ensure keysContainer is properly positioned (accounting for backdrop insets)
        if self.frame.keysContainer then
            local frameW = self.frame:GetWidth()
            local frameH = self.frame:GetHeight()
            
            self.frame.keysContainer:ClearAllPoints()
            -- Position with 4px insets, then explicitly set size to ensure exact dimensions
            self.frame.keysContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 4, -4)
            -- Set exact size: frame - 8 (4px on each side)
            if frameW > 0 and frameH > 0 then
                self.frame.keysContainer:SetWidth(frameW - 8)
                self.frame.keysContainer:SetHeight(frameH - 8)
            end
            
            -- Debug: verify container fills frame correctly
            if CE_Debug then
                local containerW = self.frame.keysContainer:GetWidth()
                local containerH = self.frame.keysContainer:GetHeight()
                local expectedW = frameW - 8  -- 4px on each side
                local expectedH = frameH - 8
                CE_Debug(string.format("Container Check - Frame: %.0f x %.0f | Container: %.0f x %.0f | Expected: %.0f x %.0f | Diff: %.0f x %.0f",
                    frameW, frameH, containerW, containerH, expectedW, expectedH, containerW - expectedW, containerH - expectedH))
            end
        end
        
        -- Small delay to ensure frame is fully laid out before creating keys
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.05 then
                this:SetScript("OnUpdate", nil)
                
                -- Recreate keys with current frame dimensions
                if self.keys and self.frame.keysContainer then
                    -- Clear existing keys
                    for _, key in ipairs(self.keys) do
                        if key then
                            key:Hide()
                        end
                    end
                    self.keys = {}
                    
                    -- Recreate keys with current frame dimensions
                    self:CreateKeys(self.frame.keysContainer)
                end
                
                -- Hook keyboard frame into cursor system
                local Hooks = ConsoleExperience.hooks
                if Hooks then
                    -- Hook the frame first
                    if Hooks.HookDynamicFrame then
                        Hooks:HookDynamicFrame(self.frame, "ConsoleExperienceKeyboard")
                    end
                    
                    -- Trigger OnFrameShow to initialize cursor navigation
                    -- This will find buttons, set up bindings, and move cursor to first key
                    if Hooks.OnFrameShow then
                        Hooks:OnFrameShow(self.frame)
                    end
                end
            end
        end)
        
        -- Create modifier checking frame
        if not self.modifierFrame then
            self.modifierFrame = CreateFrame("Frame", "CEKeyboardModifierFrame", UIParent)
            self.modifierFrame:SetScript("OnUpdate", function()
                this.elapsed = (this.elapsed or 0) + arg1
                if this.elapsed >= 0.05 then  -- Check every 50ms
                    this.elapsed = 0
                    Keyboard:CheckModifiers()
                end
            end)
        end
        self.modifierFrame:Show()
    end
end

function Keyboard:Hide()
    -- Prevent recursive calls
    if self._hiding then
        return
    end
    self._hiding = true
    
    if self.frame then
        -- Only hide if not already hidden (to prevent recursive OnHide calls)
        if self.frame:IsVisible() then
            self.frame:Hide()
        end
        -- Don't remove from UISpecialFrames - frames stay in the list permanently (like placement frame)
    end
    
    -- Hide chat edit box - this will trigger chat module's OnUpdate to restore normal chat
    -- The chat module's OnUpdate script detects when ChatFrameEditBox is hidden and restores chat
    -- Note: Chat module's OnUpdate will also try to hide keyboard (line 222), but keyboard is already hidden, so that's fine
    if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
        ChatFrameEditBox:Hide()
        ChatFrameEditBox:ClearFocus()
    end
    
    -- Hide modifier frame
    if self.modifierFrame then
        self.modifierFrame:Hide()
    end
    
    -- Clear cursor navigation
    self.currentKey = nil
    
    -- Re-enable keyboard input on real edit box
    if ChatFrameEditBox then
        ChatFrameEditBox:EnableKeyboard(true)
    end
    if self.targetEditBox and self.targetEditBox.EnableKeyboard then
        self.targetEditBox:EnableKeyboard(true)
    end
    
    -- Remove keyboard frame from cursor system
    local Cursor = ConsoleExperience.cursor
    if Cursor and Cursor.navigationState and Cursor.navigationState.activeFrames then
        Cursor.navigationState.activeFrames[self.frame] = nil
        
        -- Process frame hide to handle cursor cleanup
        local Hooks = ConsoleExperience.cursor.hooks
        if Hooks and Hooks.ProcessFrameHide then
            Hooks:ProcessFrameHide(self.frame)
        end
    end
    
    self.currentText = ""
    self.targetEditBox = nil
    self.shiftMode = false
    
    -- Clear hiding flag
    self._hiding = nil
    self.lastShiftState = false  -- Reset shift state tracking
    if self.shiftKey then
        self.shiftKey:SetBackdropColor(0.3, 0.3, 0.3, 0.9)
    end
    if self.keys then
        self:UpdateKeyLabels()
    end
end

function Keyboard:Toggle()
    if self.frame and self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

function Keyboard:IsVisible()
    return self.frame and self.frame:IsVisible()
end

-- ============================================================================
-- Initialize
-- ============================================================================

function Keyboard:Initialize()
    self:CreateFrame()
    
    -- Hook ChatFrameEditBox to show/hide keyboard
    if ChatFrameEditBox then
        -- Hook OnShow to show keyboard
        local oldOnShow = ChatFrameEditBox:GetScript("OnShow")
        ChatFrameEditBox:SetScript("OnShow", function()
            if oldOnShow then
                oldOnShow()
            end
            -- Show keyboard when chat edit box is shown
            if ConsoleExperience.keyboard then
                ConsoleExperience.keyboard:Show(ChatFrameEditBox)
            end
        end)
        
        -- Hook OnHide to hide keyboard
        local oldOnHide = ChatFrameEditBox:GetScript("OnHide")
        ChatFrameEditBox:SetScript("OnHide", function()
            if oldOnHide then
                oldOnHide()
            end
            -- Hide keyboard when chat edit box is hidden
            if ConsoleExperience.keyboard then
                ConsoleExperience.keyboard:Hide()
            end
        end)
        
        -- Hook OnEscapePressed to hide keyboard and chat
        -- Note: UISpecialFrames will handle Escape key, so this is just a fallback
        local oldOnEscapePressed = ChatFrameEditBox:GetScript("OnEscapePressed")
        ChatFrameEditBox:SetScript("OnEscapePressed", function()
            -- Hide keyboard first
            if ConsoleExperience.keyboard then
                ConsoleExperience.keyboard:Hide()
            end
            -- Hide chat edit box (chat module's OnUpdate will handle restoring chat)
            if ChatFrameEditBox then
                ChatFrameEditBox:Hide()
            end
            -- Call original handler if it exists
            if oldOnEscapePressed then
                oldOnEscapePressed()
            end
        end)
    end
    
    CE_Debug("Virtual keyboard frame loaded")
end

-- Slash command
SLASH_CEKEYBOARD1 = "/cekeyboard"
SlashCmdList["CEKEYBOARD"] = function()
    Keyboard:Toggle()
end

-- Module loaded silently

