--[[
    ConsoleExperienceClassic - Hooks Module
    
    Hooks into UI frames to enable cursor navigation
]]

-- Create hooks module namespace
ConsoleExperience.hooks = ConsoleExperience.hooks or {}
local Hooks = ConsoleExperience.hooks

-- List of frames to hook
Hooks.frames = {
    {frame = "GameMenuFrame", name = "Main Menu"},
    {frame = "CharacterFrame", name = "Character Frame"},
    {frame = "SpellBookFrame", name = "Spellbook"},
    {frame = "TalentFrame", name = "Talents"},
    {frame = "SkillFrame", name = "Skills"},
    {frame = "FriendsFrame", name = "Social Frame"},
    {frame = "WorldMapFrame", name = "World Map"},
    {frame = "TaxiFrame", name = "Flight Path"},
    {frame = "QuestLogFrame", name = "Quest Log"},
    {frame = "QuestFrame", name = "Quest Frame"},
    {frame = "QuestFrameGreetingPanel", name = "Quest Greeting"},
    {frame = "QuestFrameDetailPanel", name = "Quest Details"},
    {frame = "QuestFrameProgressPanel", name = "Quest Progress"},
    {frame = "QuestFrameRewardPanel", name = "Quest Reward"},
    {frame = "StaticPopup1", name = "Dialog 1"},
    {frame = "StaticPopup2", name = "Dialog 2"},
    {frame = "StaticPopup3", name = "Dialog 3"},
    {frame = "StaticPopup4", name = "Dialog 4"},
    {frame = "GossipFrame", name = "Gossip"},
    {frame = "GossipGreetingScrollFrame", name = "Gossip Scroll"},
    {frame = "ItemTextFrame", name = "Item Text"},
    {frame = "MerchantFrame", name = "Merchant"},
    {frame = "AuctionFrame", name = "Auction House"},
    {frame = "TradeFrame", name = "Trade"},
    {frame = "TradeSkillFrame", name = "Profession"},
    {frame = "ClassTrainerFrame", name = "Trainer"},
    {frame = "ContainerFrame1", name = "Bag 1"},
    {frame = "ContainerFrame2", name = "Bag 2"},
    {frame = "ContainerFrame3", name = "Bag 3"},
    {frame = "ContainerFrame4", name = "Bag 4"},
    {frame = "ContainerFrame5", name = "Bag 5"},
    {frame = "ContainerFrame6", name = "Bank Bag 1"},
    {frame = "ContainerFrame7", name = "Bank Bag 2"},
    {frame = "ContainerFrame8", name = "Bank Bag 3"},
    {frame = "ContainerFrame9", name = "Bank Bag 4"},
    {frame = "ContainerFrame10", name = "Bank Bag 5"},
    {frame = "ContainerFrame11", name = "Bank Bag 6"},
    {frame = "ContainerFrame12", name = "Bank Bag 7"},
    {frame = "LootFrame", name = "Loot"},
    {frame = "MailFrame", name = "Mail"},
    {frame = "OpenMailFrame", name = "Open Mail"},
    {frame = "BankFrame", name = "Bank"},
    {frame = "GroupLootFrame1", name = "Roll 1"},
    {frame = "GroupLootFrame2", name = "Roll 2"},
    {frame = "GroupLootFrame3", name = "Roll 3"},
    {frame = "GroupLootFrame4", name = "Roll 4"},
    {frame = "ConsoleExperienceConfigFrame", name = "Console Experience Config"},
    {frame = "ConsoleExperienceRadialMenu", name = "Radial Menu"},
    {frame = "ConsoleExperiencePlacementFrame", name = "Spell Placement"},
    {frame = "MacroFrame", name = "Macros"},
    -- System Options Frames
    {frame = "VideoOptionsFrame", name = "Video Options"},
    {frame = "SoundOptionsFrame", name = "Sound Options"},
    {frame = "UIOptionsFrame", name = "Interface Options"},
    {frame = "OptionsFrame", name = "Options"},
    {frame = "KeyBindingFrame", name = "Key Bindings"},
    {frame = "HelpFrame", name = "Help"},
    {frame = "CinematicFrame", name = "Cinematic"},
    {frame = "LFTFrame", name = "Looking For Group"},
}

-- ============================================================================
-- Frame Hooking
-- ============================================================================

function Hooks:Initialize()
    -- Hook all existing frames
    local hookedCount = 0
    for _, frameInfo in ipairs(self.frames) do
        local frame = getglobal(frameInfo.frame)
        if frame then
            self:HookFrame(frame, frameInfo.name)
            hookedCount = hookedCount + 1
        end
    end
    
    -- Hook dropdown menus (DropDownList1, DropDownList2, etc.)
    self:HookDropdownMenus()
    
    -- Hook party/raid/player frames if healer mode is enabled
    self:HookPartyRaidFrames()
    
    -- Create event frame to hook load-on-demand frames
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("ADDON_LOADED")
        self.eventFrame:RegisterEvent("WORLD_MAP_UPDATE")
        self.eventFrame:RegisterEvent("TAXIMAP_OPENED")
        self.eventFrame:RegisterEvent("MAIL_SHOW")
        self.eventFrame:RegisterEvent("TRADE_SKILL_SHOW")
        self.eventFrame:RegisterEvent("TRAINER_SHOW")
        self.eventFrame:RegisterEvent("MERCHANT_SHOW")
        self.eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
        self.eventFrame:RegisterEvent("BANKFRAME_OPENED")
        -- Register events for party/raid frame updates (healer mode)
        self.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        self.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.eventFrame:SetScript("OnEvent", function()
            Hooks:TryHookPendingFrames()
            
            -- Open all bags when interacting with merchants, auction house, or bank
            if event == "MERCHANT_SHOW" or event == "AUCTION_HOUSE_SHOW" or event == "BANKFRAME_OPENED" then
                Hooks:OnVendorInteraction()
            end
            
            -- Hook party/raid frames when they change or on world enter (healer mode)
            if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                Hooks:HookPartyRaidFrames()
                -- Update action bar buttons (to hide/show D-pad buttons in healer mode)
                if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                    ConsoleExperience.actionbars:UpdateAllButtons()
                end
            end
        end)
    end
    
    CE_Debug("Hooks initialized for " .. hookedCount .. " frames.")
end

-- Hook dropdown menu frames (DropDownList1, DropDownList2, etc.)
function Hooks:HookDropdownMenus()
    -- Hook up to 10 dropdown lists (should be enough)
    for i = 1, 10 do
        local dropdownName = "DropDownList" .. i
        local dropdown = getglobal(dropdownName)
        if dropdown then
            self:HookDropdownFrame(dropdown)
        end
    end
    
    -- Also hook dynamically created dropdowns via OnUpdate check
    if not self.dropdownCheckFrame then
        self.dropdownCheckFrame = CreateFrame("Frame")
        self.dropdownCheckFrame:SetScript("OnUpdate", function()
            -- Check for dropdown lists every 0.1 seconds
            this.elapsed = (this.elapsed or 0) + arg1
            if this.elapsed > 0.1 then
                this.elapsed = 0
                Hooks:CheckForNewDropdowns()
            end
        end)
    end
end

-- Hook a specific dropdown frame
function Hooks:HookDropdownFrame(dropdown)
    if not dropdown or dropdown.ceHooked then return end
    
    local oldOnShow = dropdown:GetScript("OnShow")
    local oldOnHide = dropdown:GetScript("OnHide")
    
    dropdown:SetScript("OnShow", function()
        -- Run original OnShow first
        if oldOnShow then
            oldOnShow()
        end
        
        -- Add dropdown to active frames so its buttons are navigable
        local Cursor = ConsoleExperience.cursor
        Cursor.navigationState.activeFrames[dropdown] = true
        CE_Debug("Dropdown menu opened: " .. (dropdown:GetName() or "unnamed"))
        
        -- Ensure cursor appears above dropdown menu
        -- Get dropdown's frame level and set cursor higher
        local dropdownLevel = dropdown:GetFrameLevel()
        Cursor.frame:SetFrameLevel(dropdownLevel + 100)
        Cursor.highlight:SetFrameLevel(dropdownLevel + 99)
        
        -- Refresh button collection to include dropdown buttons
        Cursor:RefreshFrame()
        
        -- Move cursor to first dropdown button if available
        local firstButton = Cursor:FindFirstVisibleButton(dropdown)
        if firstButton then
            Cursor:MoveCursorToButton(firstButton)
        end
    end)
    
    dropdown:SetScript("OnHide", function()
        -- Run original OnHide first
        if oldOnHide then
            oldOnHide()
        end
        
        -- Remove dropdown from active frames
        local Cursor = ConsoleExperience.cursor
        Cursor.navigationState.activeFrames[dropdown] = nil
        CE_Debug("Dropdown menu closed: " .. (dropdown:GetName() or "unnamed"))
        
        -- Restore cursor frame levels to default
        Cursor.frame:SetFrameLevel(1001)
        Cursor.highlight:SetFrameLevel(1000)
        
        -- Refresh button collection
        Cursor:RefreshFrame()
        
        -- Move cursor back to the frame that opened the dropdown if available
        local mostRecentFrame = nil
        for activeFrame, _ in pairs(Cursor.navigationState.activeFrames) do
            if activeFrame:IsVisible() and activeFrame ~= dropdown then
                mostRecentFrame = activeFrame
                break
            end
        end
        
        if mostRecentFrame then
            local firstButton = Cursor:FindFirstVisibleButton(mostRecentFrame)
            if firstButton then
                Cursor:MoveCursorToButton(firstButton)
            end
        end
    end)
    
    dropdown.ceHooked = true
end

-- Check for newly created dropdown menus
function Hooks:CheckForNewDropdowns()
    for i = 1, 10 do
        local dropdownName = "DropDownList" .. i
        local dropdown = getglobal(dropdownName)
        if dropdown and not dropdown.ceHooked then
            self:HookDropdownFrame(dropdown)
        end
    end
end

-- Try to hook frames that weren't available at init time
function Hooks:TryHookPendingFrames()
    for _, frameInfo in ipairs(self.frames) do
        local frame = getglobal(frameInfo.frame)
        if frame and not frame.ceHooked then
            self:HookFrame(frame, frameInfo.name)
            CE_Debug("Late hook: " .. frameInfo.frame)
            
            -- If the frame is already visible, trigger OnShow
            if frame:IsVisible() then
                self:OnFrameShow(frame)
            end
        end
    end
    
    -- Try to hook party/raid frames if healer mode is enabled
    self:HookPartyRaidFrames()
    
    -- Special handling for WorldMapFrame - check if it's visible and not yet initialized
    local worldMap = getglobal("WorldMapFrame")
    if worldMap and worldMap:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[worldMap] then
            CE_Debug("WorldMapFrame detected visible, initializing cursor")
            self:OnFrameShow(worldMap)
        end
    end
    
    -- Special handling for TaxiFrame - check if it's visible and not yet initialized
    local taxiFrame = getglobal("TaxiFrame")
    if taxiFrame and taxiFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[taxiFrame] then
            CE_Debug("TaxiFrame detected visible, initializing cursor")
            self:OnFrameShow(taxiFrame)
        end
    end
    
    -- Special handling for OpenMailFrame - check if it's visible and not yet initialized
    local openMailFrame = getglobal("OpenMailFrame")
    if openMailFrame and openMailFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[openMailFrame] then
            CE_Debug("OpenMailFrame detected visible, initializing cursor")
            self:OnFrameShow(openMailFrame)
        end
    end
    
    -- Special handling for TradeSkillFrame - check if it's visible and not yet initialized
    local tradeSkillFrame = getglobal("TradeSkillFrame")
    if tradeSkillFrame and tradeSkillFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[tradeSkillFrame] then
            CE_Debug("TradeSkillFrame detected visible, initializing cursor")
            self:OnFrameShow(tradeSkillFrame)
        end
    end
    
    -- Special handling for ClassTrainerFrame - check if it's visible and not yet initialized
    local classTrainerFrame = getglobal("ClassTrainerFrame")
    if classTrainerFrame and classTrainerFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[classTrainerFrame] then
            CE_Debug("ClassTrainerFrame detected visible, initializing cursor")
            self:OnFrameShow(classTrainerFrame)
        end
    end
    
    -- Special handling for VideoOptionsFrame
    local videoOptionsFrame = getglobal("VideoOptionsFrame")
    if videoOptionsFrame and videoOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[videoOptionsFrame] then
            CE_Debug("VideoOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(videoOptionsFrame)
        end
    end
    
    -- Special handling for SoundOptionsFrame
    local soundOptionsFrame = getglobal("SoundOptionsFrame")
    if soundOptionsFrame and soundOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[soundOptionsFrame] then
            CE_Debug("SoundOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(soundOptionsFrame)
        end
    end
    
    -- Special handling for UIOptionsFrame
    local uiOptionsFrame = getglobal("UIOptionsFrame")
    if uiOptionsFrame and uiOptionsFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[uiOptionsFrame] then
            CE_Debug("UIOptionsFrame detected visible, initializing cursor")
            self:OnFrameShow(uiOptionsFrame)
        end
    end
    
    -- Special handling for KeyBindingFrame
    local keyBindingFrame = getglobal("KeyBindingFrame")
    if keyBindingFrame and keyBindingFrame:IsVisible() then
        local Cursor = ConsoleExperience.cursor
        if not Cursor.navigationState.activeFrames[keyBindingFrame] then
            CE_Debug("KeyBindingFrame detected visible, initializing cursor")
            self:OnFrameShow(keyBindingFrame)
        end
    end
end

function Hooks:HookFrame(frame, frameName)
    if not frame or frame.ceHooked then return end
    
    local oldOnShow = frame:GetScript("OnShow")
    local oldOnHide = frame:GetScript("OnHide")
    
    frame:SetScript("OnShow", function()
        -- Run original OnShow first
        if oldOnShow then
            oldOnShow()
        end
        
        -- Initialize cursor on this frame
        Hooks:OnFrameShow(frame)
    end)
    
    frame:SetScript("OnHide", function()
        -- Run original OnHide first
        if oldOnHide then
            oldOnHide()
        end
        
        -- Handle frame hide
        Hooks:OnFrameHide(frame)
    end)
    
    frame.ceHooked = true
end

function Hooks:OnFrameShow(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    CE_Debug("OnFrameShow: " .. frameName)
    
    local Cursor = ConsoleExperience.cursor
    
    -- Check if this is a party/raid/player frame (healer mode)
    local isPartyRaidFrame = self:IsPartyRaidFrame(frameName)
    
    -- Add to active frames (store as table to hold metadata for healer mode frames)
    if isPartyRaidFrame then
        Cursor.navigationState.activeFrames[frame] = { healerMode = true }
    else
        Cursor.navigationState.activeFrames[frame] = true
    end
    
    -- Special handling for WorldMapFrame - disable its keyboard capture
    if frameName == "WorldMapFrame" then
        frame:EnableKeyboard(false)
        CE_Debug("Disabled WorldMapFrame keyboard capture")
    end
    
    -- Special handling for TaxiFrame - disable its keyboard capture
    if frameName == "TaxiFrame" then
        frame:EnableKeyboard(false)
        CE_Debug("Disabled TaxiFrame keyboard capture")
    end
    
    -- Ensure cursor is on top
    Cursor:EnsureOnTop(frame)
    
    -- Find first visible button and move cursor to it
    local firstButton = Cursor:FindFirstVisibleButton(frame)
    
    -- Set up cursor navigation bindings first (before moving to button)
    -- Only setup if cursor mode is not already active (to avoid saving bindings multiple times)
    if ConsoleExperience.cursor.keybindings and not ConsoleExperience.cursor.keybindings:IsCursorModeActive() then
        ConsoleExperience.cursor.keybindings:SetupCursorBindings()
    end
    
    if firstButton then
        CE_Debug("Found button: " .. (firstButton:GetName() or "unnamed"))
        Cursor:MoveCursorToButton(firstButton)
    else
        CE_Debug("No buttons found in " .. frameName)
    end
end

function Hooks:OnFrameHide(frame)
    if not frame then return end
    
    local frameName = frame:GetName() or "Unknown"
    
    -- Use a short delay to check if the frame is really hidden
    -- This handles frames that do show/hide cycles during initialization
    local checkFrame = CreateFrame("Frame")
    checkFrame:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + arg1
        if this.elapsed > 0.1 then
            this:SetScript("OnUpdate", nil)
            
            -- Now check if frame is actually hidden
            if frame:IsVisible() then
                CE_Debug("OnFrameHide ignored (frame visible after delay): " .. frameName)
                return
            end
            
            CE_Debug("OnFrameHide confirmed: " .. frameName)
            Hooks:ProcessFrameHide(frame)
        end
    end)
end

function Hooks:ProcessFrameHide(frame)
    if not frame then return end
    
    local Cursor = ConsoleExperience.cursor
    
    -- Remove from active frames
    Cursor.navigationState.activeFrames[frame] = nil
    
    -- Find another active frame
    local mostRecentFrame = nil
    for activeFrame, frameInfo in pairs(Cursor.navigationState.activeFrames) do
        if activeFrame:IsVisible() then
            mostRecentFrame = activeFrame
            break
        end
    end
    
    if mostRecentFrame then
        -- Move cursor to the other active frame
        local firstButton = Cursor:FindFirstVisibleButton(mostRecentFrame)
        if firstButton then
            -- Set up cursor bindings
            if ConsoleExperience.cursor.keybindings then
                ConsoleExperience.cursor.keybindings:RestoreOriginalBindings()
                ConsoleExperience.cursor.keybindings:SetupCursorBindings()
            end
            
            Cursor:MoveCursorToButton(firstButton)
        end
    else
        -- No active frames, hide cursor and restore bindings
        Cursor:Hide()
        
        if GameTooltip then
            GameTooltip:Hide()
        end
        
        -- Restore original bindings
        if ConsoleExperience.cursor.keybindings then
            ConsoleExperience.cursor.keybindings:RestoreOriginalBindings()
        end
        
        -- Clear navigation state
        Cursor:ClearNavigationState()
    end
end

-- Manual hook for frames that are created dynamically
function Hooks:HookDynamicFrame(frame, frameName)
    if not frame then return end
    
    self:HookFrame(frame, frameName or "Dynamic Frame")
    
    -- If frame is already visible, initialize cursor
    if frame:IsVisible() then
        self:OnFrameShow(frame)
    end
end

-- Check if any hooked frames are visible
function Hooks:HasActiveFrames()
    local Cursor = ConsoleExperience.cursor
    for frame, _ in pairs(Cursor.navigationState.activeFrames) do
        if frame:IsVisible() then
            return true
        end
    end
    return false
end

-- ============================================================================
-- ============================================================================
-- Party/Raid Frame Hooking (Healer Mode)
-- ============================================================================

-- Check if a frame name is a party/raid/player frame (for healer mode)
function Hooks:IsPartyRaidFrame(frameName)
    if not frameName then return false end
    
    -- Player frame
    if frameName == "PlayerFrame" then
        return true
    end
    
    -- Party frames: PartyMemberFrame1, PartyMemberFrame2, etc.
    if string.find(frameName, "^PartyMemberFrame%d+$") then
        return true
    end
    
    -- Raid frames: RaidGroupButton1, RaidGroupButton2, etc. (WoW 1.12 uses RaidGroupButton)
    if string.find(frameName, "^RaidGroupButton%d+$") then
        return true
    end
    
    -- Also check for PartyFrame1, PartyFrame2 (alternative naming)
    if string.find(frameName, "^PartyFrame%d+$") then
        return true
    end
    
    return false
end

-- Unhook party and raid frames (when leaving party/raid or disabling healer mode)
function Hooks:UnhookPartyRaidFrames()
    CE_Debug("Hooks: Unhooking party/raid/player frames...")
    
    -- Unhook player frame (if it was hooked by healer mode)
    local playerFrame = getglobal("PlayerFrame")
    if playerFrame and playerFrame.ceHooked then
        local frameName = playerFrame:GetName() or ""
        -- Only unhook if it's a party/raid/player frame (healer mode frames)
        if frameName == "PlayerFrame" or self:IsPartyRaidFrame(frameName) then
            -- Restore original scripts
            playerFrame:SetScript("OnShow", nil)
            playerFrame:SetScript("OnHide", nil)
            playerFrame.ceHooked = nil
            CE_Debug("Hooks: Unhooked PlayerFrame")
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[playerFrame] = nil
            end
        end
    end
    
    -- Unhook party frames (PartyMemberFrame1-4)
    for i = 1, 4 do
        local frameName = "PartyMemberFrame" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
    
    -- Unhook raid frames (RaidGroupButton1-40)
    for i = 1, 40 do
        local frameName = "RaidGroupButton" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
    
    -- Unhook PartyFrame1-4 if they exist (alternative naming)
    for i = 1, 4 do
        local frameName = "PartyFrame" .. i
        local frame = getglobal(frameName)
        if frame and frame.ceHooked then
            -- Restore original scripts
            frame:SetScript("OnShow", nil)
            frame:SetScript("OnHide", nil)
            frame.ceHooked = nil
            CE_Debug("Hooks: Unhooked " .. frameName)
            
            -- Remove from active frames if present
            local Cursor = ConsoleExperience.cursor
            if Cursor and Cursor.navigationState then
                Cursor.navigationState.activeFrames[frame] = nil
            end
        end
    end
end

-- Hook party and raid frames when healer mode is enabled
function Hooks:HookPartyRaidFrames()
    -- Check if healer mode is enabled
    local config = ConsoleExperience.config
    if not config then
        -- Healer mode disabled or config not available - unhook if needed
        self:UnhookPartyRaidFrames()
        return
    end
    if not config.Get then
        self:UnhookPartyRaidFrames()
        return
    end
    
    local healerMode = config:Get("healerMode")
    if not healerMode then
        -- Healer mode disabled - unhook if needed
        self:UnhookPartyRaidFrames()
        return
    end
    
    -- Check if we're actually in a party or raid
    -- In WoW 1.12, GetNumPartyMembers() returns the number of party members (0-4)
    -- GetNumRaidMembers() returns the number of raid members (0-40)
    local numPartyMembers = GetNumPartyMembers and GetNumPartyMembers() or 0
    local numRaidMembers = GetNumRaidMembers and GetNumRaidMembers() or 0
    local inParty = numPartyMembers > 0
    local inRaid = numRaidMembers > 0
    
    -- If not in party/raid, unhook all party/raid/player frames
    if not inParty and not inRaid then
        CE_Debug("Hooks: Not in party/raid, unhooking all party/raid/player frames")
        self:UnhookPartyRaidFrames()
        return
    end
    
    CE_Debug("Hooks: Healer mode enabled, hooking party/raid/player frames...")
    
    -- Hook player frame
    local playerFrame = getglobal("PlayerFrame")
    if playerFrame then
        local wasAlreadyHooked = playerFrame.ceHooked
        self:HookFrame(playerFrame, "Player Frame")
        CE_Debug("Hooks: Hooked PlayerFrame")
        
        -- If frame is already visible, trigger OnFrameShow
        if playerFrame:IsVisible() then
            if not wasAlreadyHooked then
                CE_Debug("Hooks: Player frame is already visible, initializing cursor")
            else
                CE_Debug("Hooks: Player frame is already visible and hooked, re-initializing cursor")
            end
            self:OnFrameShow(playerFrame)
        end
    else
        CE_Debug("Hooks: PlayerFrame not found")
    end
    
    -- Hook party frames (PartyMemberFrame1-4)
    for i = 1, 4 do
        local frameName = "PartyMemberFrame" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Party Member " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        else
            CE_Debug("Hooks: Party frame " .. frameName .. " not found")
        end
    end
    
    -- Hook raid frames (RaidGroupButton1-40 in WoW 1.12)
    for i = 1, 40 do
        local frameName = "RaidGroupButton" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Raid Member " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Raid frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Raid frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        end
    end
    
    -- Also hook PartyFrame1-4 if they exist (alternative naming)
    for i = 1, 4 do
        local frameName = "PartyFrame" .. i
        local frame = getglobal(frameName)
        if frame then
            local wasAlreadyHooked = frame.ceHooked
            self:HookFrame(frame, "Party " .. i)
            CE_Debug("Hooks: Hooked " .. frameName)
            
            -- If frame is already visible, trigger OnFrameShow
            if frame:IsVisible() then
                if not wasAlreadyHooked then
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible, initializing cursor")
                else
                    CE_Debug("Hooks: Party frame " .. frameName .. " is already visible and hooked, re-initializing cursor")
                end
                self:OnFrameShow(frame)
            end
        end
    end
end

-- ============================================================================
-- Vendor/Auction House Bag Opening
-- ============================================================================

-- Open all bags when interacting with merchants, auction house, or bank
function Hooks:OnVendorInteraction()
    -- Check if the feature is enabled in config
    local Config = ConsoleExperience.config
    if Config and Config.Get then
        local enabled = Config:Get("openAllBagsAtVendor")
        if enabled == false then
            return
        end
    end
    
    -- Open all bags (OpenAllBags is a Blizzard API function)
    if OpenAllBags then
        OpenAllBags()
        CE_Debug("Opened all bags for vendor interaction")
    end
end

-- Module loaded silently

