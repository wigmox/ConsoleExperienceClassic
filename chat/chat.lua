--[[
    ConsoleExperienceClassic - Chat Frame Module
    
    Implements ShaguController-style chat frame management:
    - Moves ChatFrameEditBox to top center when visible
    - Scales and repositions ChatFrame1 based on edit box visibility
    - Creates clickable overlay on ChatFrame1 to toggle edit box
    - Hides/repositions chat frame buttons
]]

-- Create chat module namespace
ConsoleExperience.chat = ConsoleExperience.chat or {}
local Chat = ConsoleExperience.chat

-- State tracking
Chat.managePositionsHook = nil
Chat.oskHelper = nil
Chat.chatFrameOriginalState = {
    scale = nil,
    points = {},
    color = nil,
    alpha = nil
}

-- Save original chat frame state
function Chat:SaveChatFrameState()
    if not ChatFrame1 then return end
    
    self.chatFrameOriginalState.scale = ChatFrame1:GetScale()
    self.chatFrameOriginalState.points = {}
    
    for i = 1, ChatFrame1:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = ChatFrame1:GetPoint(i)
        table.insert(self.chatFrameOriginalState.points, {point, relativeTo, relativePoint, x, y})
    end
    
    -- Try to get current color/alpha if functions exist
    if ChatFrame1.GetBackdropColor then
        local r, g, b, a = ChatFrame1:GetBackdropColor()
        self.chatFrameOriginalState.color = {r, g, b, a}
    end
end

-- Restore original chat frame state
function Chat:RestoreChatFrameState()
    if not ChatFrame1 or not self.chatFrameOriginalState.scale then return end
    
    ChatFrame1:SetScale(self.chatFrameOriginalState.scale)
    ChatFrame1:ClearAllPoints()
    
    for _, pointData in ipairs(self.chatFrameOriginalState.points) do
        ChatFrame1:SetPoint(unpack(pointData))
    end
    
    if self.chatFrameOriginalState.color and FCF_SetWindowColor then
        FCF_SetWindowColor(ChatFrame1, unpack(self.chatFrameOriginalState.color))
    end
    
    if self.chatFrameOriginalState.alpha and FCF_SetWindowAlpha then
        FCF_SetWindowAlpha(ChatFrame1, self.chatFrameOriginalState.alpha)
    end
end

-- Get anchor frame for chat positioning (when edit box is hidden)
function Chat:GetChatAnchor()
    local anchor = MainMenuBarArtFrame
    
    if MultiBarBottomLeft and MultiBarBottomLeft:IsVisible() then
        anchor = MultiBarBottomLeft
    elseif MultiBarBottomRight and MultiBarBottomRight:IsVisible() then
        anchor = MultiBarBottomRight
    elseif ShapeshiftBarFrame and ShapeshiftBarFrame:IsVisible() then
        anchor = ShapeshiftBarFrame
    elseif PetActionBarFrame and PetActionBarFrame:IsVisible() then
        anchor = PetActionBarFrame
    end
    
    return anchor
end

-- Update chat layout based on action bar positions
-- forceUpdate: if true, update even if edit box is visible (used when transitioning from focused mode)
function Chat:UpdateChatLayout(forceUpdate)
    if not ChatFrame1 then return end
    
    -- Get config values
    local config = ConsoleExperience.config
    if not config then return end
    
    local chatWidth = config:Get("chatWidth") or 400
    local chatHeight = config:Get("chatHeight") or 150
    
    -- Only update if edit box is not visible, unless forced
    if not forceUpdate and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
        return
    end
    
    -- Calculate chat position (centered at bottom of screen)
    -- Chat is always centered at screen bottom, independent of action bar positions
    local chatBottomY = 20  -- Position 20 pixels from bottom of screen
    local halfWidth = chatWidth / 2
    
    -- Always restore to configured size and position
    ChatFrame1:SetScale(1)
    ChatFrame1:ClearAllPoints()
    -- Center horizontally using BOTTOM anchor, then set left/right edges relative to center
    ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -halfWidth, chatBottomY)
    ChatFrame1:SetPoint("TOPRIGHT", UIParent, "BOTTOM", halfWidth, chatBottomY + chatHeight)
    
    if FCF_SetWindowColor then
        FCF_SetWindowColor(ChatFrame1, 0, 0, 0)
    end
    if FCF_SetWindowAlpha then
        FCF_SetWindowAlpha(ChatFrame1, 0.6)  -- Darker background (0.6 alpha for semi-transparent dark)
    end
end

-- Manage chat frame positions (called from UIParent_ManageFramePositions hook)
function Chat:ManagePositions(a1, a2, a3)
    -- Run original function first
    if self.managePositionsHook then
        self.managePositionsHook(a1, a2, a3)
    end
    
    -- Save original state if not already saved
    if not self.chatFrameOriginalState.scale then
        self:SaveChatFrameState()
    end
    
    -- Move and resize ChatFrameEditBox
    if ChatFrameEditBox then
        local screenWidth = UIParent:GetWidth()
        ChatFrameEditBox:ClearAllPoints()
        ChatFrameEditBox:SetPoint("TOP", UIParent, "TOP", 0, -10)
        -- Scale edit box width based on screen width (15% of screen width, min 300, max 500)
        local editBoxWidth = math.max(300, math.min(500, screenWidth * 0.15))
        ChatFrameEditBox:SetWidth(editBoxWidth)
        ChatFrameEditBox:SetScale(2)
    end
    
    -- Create on-screen keyboard helper button if it doesn't exist
    if not self.oskHelper then
        self.oskHelper = CreateFrame("Button", nil, UIParent)
        self.oskHelper:SetFrameStrata("BACKGROUND")
        if ChatFrame1 then
            self.oskHelper:SetAllPoints(ChatFrame1)
        end
        self.oskHelper:SetScript("OnClick", function()
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:Hide()
            else
                if ChatFrameEditBox then
                    ChatFrameEditBox:Show()
                    ChatFrameEditBox:Raise()
                end
            end
        end)
        self.oskHelper.state = 0
        
        -- Set up OnUpdate script once
        local helper = self.oskHelper
        helper:SetScript("OnUpdate", function()
            if ChatFrameEditBox and ChatFrameEditBox:IsVisible() and helper.state ~= 1 then
                -- Edit box is visible - show full-screen chat (focused mode)
                if ChatFrame1 then
                    ChatFrame1:Show()
                    ChatFrame1:ClearAllPoints()
                    local screenHeight = UIParent:GetHeight()
                    local screenWidth = UIParent:GetWidth()
                    local chatHeight = screenHeight * 0.48  -- Use 48% of screen height
                    -- Edit box is at -10 from top, scaled 2x (height ~30px * 2 = 60px)
                    -- Scale offset based on screen height (roughly 9% of screen height, min 80px, max 120px)
                    local editBoxOffset = math.max(80, math.min(120, screenHeight * 0.09))
                    
                    -- Ensure chat frame is visible and on top BEFORE positioning
                    ChatFrame1:SetFrameStrata("DIALOG")
                    ChatFrame1:SetFrameLevel(100)
                    ChatFrame1:SetAlpha(1.0)
                    
                    -- Position from top, starting BELOW the edit box
                    -- Top edge starts below edit box, bottom edge at editBoxOffset + chatHeight from top
                    ChatFrame1:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -editBoxOffset)
                    ChatFrame1:SetPoint("BOTTOMRIGHT", UIParent, "TOPRIGHT", -10, -(editBoxOffset + chatHeight))
                    
                    -- Don't use scale - it makes the frame take more space than intended
                    -- ChatFrame1:SetScale(1.5)
                    
                    if FCF_SetWindowColor then
                        FCF_SetWindowColor(ChatFrame1, 0, 0, 0)
                    end
                    if FCF_SetWindowAlpha then
                        FCF_SetWindowAlpha(ChatFrame1, 0.7)  -- Reduced alpha so it's not too dark
                    end
                    
                    -- Disable fading so messages stay visible
                    if ChatFrame1.SetFadeDuration then
                        ChatFrame1:SetFadeDuration(0)
                    end
                    if ChatFrame1.SetFading then
                        ChatFrame1:SetFading(false)
                    end
                    
                    -- Scroll to bottom
                    if ChatFrame1.ScrollToBottom then
                        ChatFrame1:ScrollToBottom()
                    end
                end
                
                -- Show keyboard when edit box becomes visible (if enabled)
                local config = ConsoleExperience.config
                if config and config:Get("keyboardEnabled") then
                    if ConsoleExperience.keyboard and not ConsoleExperience.keyboard:IsVisible() then
                        ConsoleExperience.keyboard:Show()
                    end
                end
                
                helper.state = 1
            elseif (not ChatFrameEditBox or not ChatFrameEditBox:IsVisible()) and helper.state ~= 0 then
                -- Edit box is hidden - return to configured chat position and size (unfocused mode)
                -- Force update to ensure we restore the configured layout
                self:UpdateChatLayout(true)
                
                -- Don't hide keyboard here - keyboard handles its own visibility via UISpecialFrames
                -- Keyboard will hide itself when Escape is pressed or when ChatFrameEditBox is hidden via its OnHide hook
                
                helper.state = 0
            end
        end)
    end
    
    -- Update helper button to cover ChatFrame1
    if ChatFrame1 and self.oskHelper then
        self.oskHelper:ClearAllPoints()
        self.oskHelper:SetAllPoints(ChatFrame1)
    end
    
    -- Update chat layout if edit box is not visible
    if not ChatFrameEditBox or not ChatFrameEditBox:IsVisible() then
        self:UpdateChatLayout()
    end
    
    -- Move and hide some chat buttons
    if ChatFrameMenuButton then
        ChatFrameMenuButton:Hide()
        ChatFrameMenuButton.Show = function() return end
    end
    
    -- Reposition scroll buttons for all chat windows
    for i = 1, NUM_CHAT_WINDOWS do
        local downButton = _G["ChatFrame"..i.."DownButton"]
        local upButton = _G["ChatFrame"..i.."UpButton"]
        local bottomButton = _G["ChatFrame"..i.."BottomButton"]
        
        if downButton then
            downButton:ClearAllPoints()
            downButton:SetPoint("BOTTOMRIGHT", _G["ChatFrame"..i], "BOTTOMRIGHT", 0, -5)
        end
        
        if upButton then
            upButton:ClearAllPoints()
            upButton:SetPoint("RIGHT", downButton, "LEFT", 0, 0)
        end
        
        if bottomButton then
            bottomButton:Hide()
            bottomButton.Show = function() return end
        end
    end
end

-- Initialize the chat module
function Chat:Initialize()
    -- Wait for PLAYER_ENTERING_WORLD to hook into frame management
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:SetScript("OnEvent", function()
        -- Hook into UIParent_ManageFramePositions
        if UIParent_ManageFramePositions then
            self.managePositionsHook = UIParent_ManageFramePositions
            UIParent_ManageFramePositions = function(a1, a2, a3)
                Chat:ManagePositions(a1, a2, a3)
            end
        end
        
        -- Trigger initial position update
        if UIParent_ManageFramePositions then
            UIParent_ManageFramePositions()
        end
        
        -- Update chat layout after action bars are positioned
        self:UpdateChatLayout()
        
        initFrame:UnregisterAllEvents()
    end)
    
    -- Also set up a one-time update frame
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        if UIParent_ManageFramePositions then
            UIParent_ManageFramePositions()
        end
        -- Update chat layout
        self:UpdateChatLayout()
        updateFrame:Hide()
    end)
    
    CE_Debug("Chat frame module initialized")
end

