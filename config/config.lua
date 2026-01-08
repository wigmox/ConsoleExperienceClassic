--[[
    ConsoleExperienceClassic - Configuration Module
    
    Provides a configuration UI with sidebar navigation
]]

-- Create the config module namespace
ConsoleExperience.config = ConsoleExperience.config or {}
local Config = ConsoleExperience.config

-- ============================================================================
-- Default Configuration Values
-- ============================================================================

Config.DEFAULTS = {
    debugEnabled = false,
    -- Interface settings
    crosshairEnabled = true,
    crosshairX = 0,
    crosshairY = 50,
    crosshairSize = 24,
    crosshairType = "cross",  -- "cross" or "dot"
    crosshairColorR = 1.0,    -- Red component (0-1)
    crosshairColorG = 1.0,    -- Green component (0-1)
    crosshairColorB = 1.0,    -- Blue component (0-1)
    crosshairColorA = 0.8,    -- Alpha component (0-1)
    controllerType = "xbox",  -- "xbox" or "ps"
    -- Action Bar settings
    barButtonSize = 60,
    barXOffset = 0,
    barYOffset = 70,
    barPadding = 65,
    barStarPadding = 600,  -- Padding between left and right star centers
    barScale = 1.0,
    barAppearance = "classic",  -- "classic" or "modern"
    -- Chat settings
    chatWidth = 400,
    chatHeight = 150,
    chatBottomY = 20,  -- Y position from bottom (adjusted for XP/Rep bars)
    keyboardEnabled = true,  -- If true, show virtual keyboard when chat edit box is visible
    -- XP/Rep Bar settings
    xpBarWidth = nil,  -- nil = use chat width
    xpBarHeight = 20,  -- Default height (minimum is 20 for border texture)
    xpBarDisplay = "XP",  -- "XP", "PETXP", "REP", "FLEX", "XPFLEX"
    xpBarAlways = true,  -- XP bar visible by default
    xpBarTimeout = 5.0,  -- Seconds before bar fades out
    xpBarTextShow = true,
    xpBarTextMouse = false,
    xpBarTextOffsetY = 0,
    xpBarColor = "0.0,1.0,0.0,1.0",  -- WoW default green for XP
    xpBarRestColor = "0.0,0.5,1.0,1.0",  -- WoW default blue for rested
    xpBarDontOverlap = false,
    repBarWidth = nil,  -- nil = use chat width
    repBarHeight = 20,  -- Default height (minimum is 20 for border texture)
    repBarDisplay = "REP",  -- "REP", "FLEX"
    repBarAlways = false,  -- Rep bar hidden by default
    repBarTimeout = 5.0,  -- Seconds before bar fades out
    repBarTextShow = true,
    repBarTextMouse = false,
    repBarTextOffsetY = 0,
    -- Castbar settings
    castbarEnabled = true,  -- Castbar enabled by default
    castbarHeight = 20,     -- Default height
    castbarColorR = 0.0,    -- Blue by default
    castbarColorG = 0.5,
    castbarColorB = 1.0,
    -- Keybinding settings
    useAForJump = true,  -- If true, A button (key 1) is bound to JUMP instead of CE_ACTION_1
    -- Locale settings
    language = nil,  -- nil = use game locale, otherwise "enUS", "deDE", etc.
}

-- ============================================================================
-- Configuration Get/Set Functions
-- ============================================================================

function Config:InitializeDB()
    -- Ensure ConsoleExperienceDB exists
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    
    -- Initialize config section if it doesn't exist
    if not ConsoleExperienceDB.config then
        ConsoleExperienceDB.config = {}
    end
    
    -- Set defaults for any missing values
    for key, defaultValue in pairs(self.DEFAULTS) do
        if ConsoleExperienceDB.config[key] == nil then
            ConsoleExperienceDB.config[key] = defaultValue
        end
    end
    
    -- Initialize locale if available
    if ConsoleExperience.locale then
        ConsoleExperience.locale:Initialize()
    end
    
    -- Apply debug setting to global variable
    ConsoleExperience_DEBUG_KEYS = ConsoleExperienceDB.config.debugEnabled
    
    -- Apply crosshair setting
    self:UpdateCrosshair()
    
    -- Apply action bar layout
    self:UpdateActionBarLayout()
    
    -- Apply chat layout
    if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
        ConsoleExperience.chat:UpdateChatLayout()
    end
    
    -- Apply XP/Rep bar layout
    if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
        ConsoleExperience.xpbar:UpdateAllBars()
    end
    
    -- Apply castbar layout
    if ConsoleExperience.castbar and ConsoleExperience.castbar.ReloadConfig then
        ConsoleExperience.castbar:ReloadConfig()
    end
    
end

function Config:Get(key)
    if ConsoleExperienceDB and ConsoleExperienceDB.config then
        if ConsoleExperienceDB.config[key] ~= nil then
            return ConsoleExperienceDB.config[key]
        end
    end
    return self.DEFAULTS[key]
end

function Config:Set(key, value)
    if not ConsoleExperienceDB then
        ConsoleExperienceDB = {}
    end
    if not ConsoleExperienceDB.config then
        ConsoleExperienceDB.config = {}
    end
    ConsoleExperienceDB.config[key] = value
    
    -- Apply certain settings immediately
    if key == "debugEnabled" then
        ConsoleExperience_DEBUG_KEYS = value
    end
end

-- ============================================================================
-- Constants
-- ============================================================================

Config.FRAME_WIDTH = 520
Config.FRAME_HEIGHT = 420
Config.SIDEBAR_WIDTH = 120
Config.BUTTON_HEIGHT = 25
Config.PADDING = 10

-- Section definitions
Config.SECTIONS = {
    { id = "general", name = "General" },
    { id = "interface", name = "Interface" },
    { id = "keybindings", name = "Keybindings" },
    { id = "bars", name = "Action Bars" },
    { id = "chat", name = "Chat" },
    { id = "xpbar", name = "XP/Rep Bars" },
    { id = "castbar", name = "Cast Bar" },
}

-- ============================================================================
-- Main Config Frame
-- ============================================================================

function Config:CreateMainFrame()
    if self.frame then return self.frame end
    
    -- Main frame
    local frame = CreateFrame("Frame", "ConsoleExperienceConfigFrame", UIParent)
    frame:SetWidth(self.FRAME_WIDTH)
    frame:SetHeight(self.FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:Hide()
    
    -- Background
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Title bar for dragging (leave space for close button)
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -35, -5)  -- Leave room for close button
    titleRegion:SetHeight(25)
    titleRegion:EnableMouse(true)
    titleRegion:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleRegion:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Title text
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -15)
    -- Title will be set after locale is initialized, store reference
    frame.titleText = title
    
    -- Close button
    local closeButton = CreateFrame("Button", "ConsoleExperienceConfigCloseButton", frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 10)
    closeButton:SetScript("OnClick", function()
        ConsoleExperience.config.frame:Hide()
    end)
    closeButton:Show()
    
    -- Sidebar frame
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", self.PADDING + 5, -40)
    sidebar:SetWidth(self.SIDEBAR_WIDTH)
    sidebar:SetHeight(self.FRAME_HEIGHT - 60)
    sidebar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    sidebar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame.sidebar = sidebar
    
    -- Content frame (outer container with backdrop)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", self.PADDING, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, self.PADDING + 5)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    content:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    frame.content = content
    
    -- Create scroll frame using native ScrollFrame type (like pfUI)
    local scrollFrame = CreateFrame("ScrollFrame", nil, content)
    scrollFrame:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    scrollFrame:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -20, 5)  -- Leave room for buttons
    frame.scrollFrame = scrollFrame
    
    -- Create scroll child container
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(900)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild
    
    -- Create scroll up button (like quest frames)
    local scrollUpButton = CreateFrame("Button", nil, scrollFrame)
    scrollUpButton:SetWidth(24)
    scrollUpButton:SetHeight(24)
    scrollUpButton:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
    scrollUpButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
    scrollUpButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Down")
    scrollUpButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Disabled")
    scrollUpButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight")
    scrollUpButton:SetScript("OnClick", function()
        local current = scrollFrame:GetVerticalScroll()
        local new = current - 30
        if new < 0 then new = 0 end
        scrollFrame:SetVerticalScroll(new)
        scrollFrame:UpdateScrollState()
    end)
    frame.scrollUpButton = scrollUpButton
    
    -- Create scroll down button (like quest frames)
    local scrollDownButton = CreateFrame("Button", nil, scrollFrame)
    scrollDownButton:SetWidth(24)
    scrollDownButton:SetHeight(24)
    scrollDownButton:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
    scrollDownButton:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    scrollDownButton:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    scrollDownButton:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
    scrollDownButton:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    scrollDownButton:SetScript("OnClick", function()
        local current = scrollFrame:GetVerticalScroll()
        local max = scrollFrame:GetVerticalScrollRange()
        local new = current + 30
        if new > max then new = max end
        scrollFrame:SetVerticalScroll(new)
        scrollFrame:UpdateScrollState()
    end)
    frame.scrollDownButton = scrollDownButton
    
    -- Update scroll state function
    scrollFrame.UpdateScrollState = function()
        local range = scrollFrame:GetVerticalScrollRange()
        local current = scrollFrame:GetVerticalScroll()
        
        -- Enable/disable buttons based on scroll position
        if current <= 0 then
            scrollUpButton:Disable()
        else
            scrollUpButton:Enable()
        end
        
        if current >= range then
            scrollDownButton:Disable()
        else
            scrollDownButton:Enable()
        end
        
        -- Hide buttons if no scrolling needed
        if range <= 0 then
            scrollUpButton:Hide()
            scrollDownButton:Hide()
        else
            scrollUpButton:Show()
            scrollDownButton:Show()
        end
    end
    
    -- Scroll function (like pfUI)
    scrollFrame.Scroll = function(self, step)
        local step = step or 0
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local new = current - step
        
        if new >= max then
            self:SetVerticalScroll(max)
        elseif new <= 0 then
            self:SetVerticalScroll(0)
        else
            self:SetVerticalScroll(new)
        end
        
        self:UpdateScrollState()
    end
    
    -- Mouse wheel scrolling
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        this:Scroll(arg1 * 10)
    end)
    
    -- Update scroll child on frame show
    frame:SetScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        scrollFrame:UpdateScrollState()
    end)
    
    -- Update content reference
    frame.content = scrollChild
    
    -- Store reference
    self.frame = frame
    
    -- Set title text after locale is available
    if frame.titleText then
        local Locale = ConsoleExperience.locale
        local T = Locale and Locale.T or function(key) return key end
        frame.titleText:SetText(T("Console Experience"))
    end
    
    -- Add to special frames so Escape closes it
    table.insert(UISpecialFrames, "ConsoleExperienceConfigFrame")
    
    -- Create sidebar buttons
    self:CreateSidebarButtons()
    
    -- Create content sections
    self:CreateContentSections()
    
    -- Show first section by default
    self:ShowSection("general")
    
    -- Hook frame for cursor navigation
    if ConsoleExperience.hooks and ConsoleExperience.hooks.HookDynamicFrame then
        ConsoleExperience.hooks:HookDynamicFrame(frame, "Console Experience Config")
    end
    
    return frame
end

-- ============================================================================
-- Sidebar Buttons
-- ============================================================================

function Config:CreateSidebarButtons()
    local sidebar = self.frame.sidebar
    self.sidebarButtons = {}
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    for i, section in ipairs(self.SECTIONS) do
        local buttonName = "CEConfigSidebar" .. section.id
        local button = CreateFrame("Button", buttonName, sidebar)
        button:SetWidth(self.SIDEBAR_WIDTH - 10)
        button:SetHeight(self.BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 5, -5 - (i-1) * (self.BUTTON_HEIGHT + 2))
        
        -- Button background
        button:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        
        -- Button text (use translation)
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER", button, "CENTER", 0, 0)
        text:SetText(T(section.name))
        button.text = text
        
        -- Store section id
        button.sectionId = section.id
        
        -- Click handler
        button:SetScript("OnClick", function()
            Config:ShowSection(this.sectionId)
        end)
        
        -- Hover effects
        button:SetScript("OnEnter", function()
            if Config.currentSection ~= this.sectionId then
                this:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            end
        end)
        button:SetScript("OnLeave", function()
            if Config.currentSection ~= this.sectionId then
                this:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            end
        end)
        
        self.sidebarButtons[section.id] = button
    end
end

-- ============================================================================
-- Content Sections
-- ============================================================================

function Config:CreateContentSections()
    self.contentSections = {}
    
    -- Create General section
    self:CreateGeneralSection()
    
    -- Create Interface section
    self:CreateInterfaceSection()
    
    -- Create Keybindings section
    self:CreateKeybindingsSection()
    
    -- Create Bars section
    self:CreateBarsSection()
    
    -- Create Chat section
    self:CreateChatSection()
    
    -- Create XP/Rep Bar section
    self:CreateXPBarSection()
    
    -- Create Cast Bar section
    self:CreateCastBarSection()
    
    -- Update scroll child height based on content
    self:UpdateScrollChildHeight()
end

function Config:UpdateScrollChildHeight()
    if not self.frame or not self.frame.scrollChild or not self.frame.scrollFrame then return end
    
    -- Calculate maximum height needed for all sections
    -- Action Bars section is the tallest with all the controls
    local maxHeight = 900  -- Enough height for all sections including Action Bars
    
    -- Ensure scroll child width matches scroll frame width to prevent overflow
    self.frame.scrollChild:SetWidth(self.frame.scrollFrame:GetWidth())
    
    -- Set scroll child height to accommodate all content
    self.frame.scrollChild:SetHeight(maxHeight)
    
    -- Update scroll state using ScrollFrame's UpdateScrollState method
    if self.frame.scrollFrame.UpdateScrollState then
        self.frame.scrollFrame:UpdateScrollState()
    end
end

function Config:CreateGeneralSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("General Settings"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure general addon settings."))
    
    -- Debug checkbox (saved to DB)
    local debugCheck = self:CreateCheckbox(section, T("Enable Debug Output"), 
        function() return Config:Get("debugEnabled") end,
        function(checked)
            Config:Set("debugEnabled", checked)
            if checked then
                CE_Debug("Debug output ENABLED (saved)")
            else
                CE_Debug("Debug output DISABLED (saved)")
            end
        end)
    debugCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Language selector dropdown
    local langLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", debugCheck, "BOTTOMLEFT", 0, -20)
    langLabel:SetText(T("Language") .. ":")
    
    local langDropdown = CreateFrame("Frame", "CEConfigLanguageDropdown", section, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("LEFT", langLabel, "RIGHT", -15, -3)
    
    -- Initialize function for language dropdown
    local function InitializeLanguageDropdown()
        if not Locale then 
            CE_Debug("Language dropdown: Locale module not found")
            return 
        end
        
        local available = Locale:GetAvailableLanguages()
        CE_Debug("Language dropdown: Available languages count: " .. table.getn(available))
        
        if table.getn(available) == 0 then 
            -- Fallback: add at least English if no languages found
            local info = {}
            info.text = "English"
            info.value = "enUS"
            info.func = function()
                UIDropDownMenu_SetSelectedValue(langDropdown, "enUS")
                UIDropDownMenu_SetText("English", langDropdown)
                Locale:SetLanguage("enUS")
                StaticPopup_Show("CE_RELOAD_UI")
            end
            info.checked = 1
            UIDropDownMenu_AddButton(info)
            return
        end
        
        local selectedValue = UIDropDownMenu_GetSelectedValue(langDropdown) or (Config:Get("language") or GetLocale() or "enUS")
        local info
        
        for _, lang in ipairs(available) do
            info = {}
            info.text = Locale:GetLanguageName(lang)
            info.value = lang
            info.func = function()
                UIDropDownMenu_SetSelectedValue(langDropdown, lang)
                UIDropDownMenu_SetText(Locale:GetLanguageName(lang), langDropdown)
                Locale:SetLanguage(lang)
                -- Reload UI message
                StaticPopup_Show("CE_RELOAD_UI")
            end
            if info.value == selectedValue then
                info.checked = 1
            end
            UIDropDownMenu_AddButton(info)
        end
    end
    
    -- Store initialize function on the dropdown frame
    langDropdown.initialize = InitializeLanguageDropdown
    
    -- Initialize dropdown (this stores the function and sets initial state)
    UIDropDownMenu_Initialize(langDropdown, InitializeLanguageDropdown)
    UIDropDownMenu_SetWidth(120, langDropdown)
    local currentLang = Config:Get("language") or GetLocale() or "enUS"
    UIDropDownMenu_SetSelectedValue(langDropdown, currentLang)
    local langName = Locale and Locale:GetLanguageName(currentLang) or currentLang
    UIDropDownMenu_SetText(langName, langDropdown)
    
    -- Ensure dropdown button is navigable and properly set up (get it after initialization)
    local langDelayFrame = CreateFrame("Frame")
    langDelayFrame:SetScript("OnUpdate", function()
        langDelayFrame:Hide()
        local dropdownButton = getglobal("CEConfigLanguageDropdownButton")
        if dropdownButton then
            dropdownButton:Enable()
            dropdownButton:Show()
            
            -- Ensure the button calls ToggleDropDownMenu correctly
            local oldOnClick = dropdownButton:GetScript("OnClick")
            if not oldOnClick then
                dropdownButton:SetScript("OnClick", function()
                    ToggleDropDownMenu(1, nil, langDropdown)
                    PlaySound("igMainMenuOptionCheckBoxOn")
                end)
            end
            
            -- Refresh cursor navigation to detect the button
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end
    end)
    langDelayFrame:Show()
    
    -- Version info
    local version = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 15, 15)
    version:SetText(T("Version") .. ": 1.0")
    
    self.contentSections["general"] = section
end

function Config:CreateInterfaceSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("Interface Settings"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure interface elements."))
    
    -- Enable Crosshair checkbox
    local crosshairCheck = self:CreateCheckbox(section, T("Enable Crosshair"), 
        function() return Config:Get("crosshairEnabled") end,
        function(checked)
            Config:Set("crosshairEnabled", checked)
            Config:UpdateCrosshair()
            if checked then
                CE_Debug("Crosshair ENABLED")
            else
                CE_Debug("Crosshair DISABLED")
            end
        end)
    crosshairCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Crosshair X Position
    local xLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", crosshairCheck, "BOTTOMLEFT", 0, -20)
    xLabel:SetText(T("Crosshair X Offset") .. ":")
    
    local xEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairX")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairX", num)
            Config:UpdateCrosshair()
        end)
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    -- Update crosshair in real-time as user types
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairX", num)
        Config:UpdateCrosshair()
    end)
    
    -- Crosshair Y Position
    local yLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yLabel:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -15)
    yLabel:SetText(T("Crosshair Y Offset") .. ":")
    
    local yEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairY")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairY", num)
            Config:UpdateCrosshair()
        end)
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    -- Update crosshair in real-time as user types
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairY", num)
        Config:UpdateCrosshair()
    end)
    
    -- Crosshair Size
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -15)
    sizeLabel:SetText(T("Crosshair Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(section, 60, 
        function() return tostring(Config:Get("crosshairSize")) end,
        function(value)
            local num = tonumber(value) or 24
            if num < 4 then num = 4 end
            if num > 100 then num = 100 end
            Config:Set("crosshairSize", num)
            Config:UpdateCrosshair()
        end)
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    -- Update crosshair in real-time as user types
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 24
        if num < 4 then num = 4 end
        if num > 100 then num = 100 end
        Config:Set("crosshairSize", num)
        Config:UpdateCrosshair()
    end)
    
    -- Crosshair Type dropdown
    local typeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -20)
    typeLabel:SetText(T("Crosshair Type") .. ":")
    
    local typeDropdown = CreateFrame("Frame", "CEConfigCrosshairTypeDropdown", section, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", -15, -3)
    
    -- Ensure dropdown button is navigable with cursor
    local dropdownButton = getglobal("CEConfigCrosshairTypeDropdownButton")
    if dropdownButton then
        -- Make sure button is enabled and visible
        dropdownButton:Enable()
        dropdownButton:Show()
    end
    
    -- Initialize function for dropdown
    local function InitializeTypeDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(typeDropdown) or (Config:Get("crosshairType") or "cross")
        local info
        
        info = {}
        info.text = T("Cross")
        info.value = "cross"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(typeDropdown, "cross")
            UIDropDownMenu_SetText(T("Cross"), typeDropdown)
            Config:Set("crosshairType", "cross")
            Config:UpdateCrosshair()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = T("Dot")
        info.value = "dot"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(typeDropdown, "dot")
            UIDropDownMenu_SetText(T("Dot"), typeDropdown)
            Config:Set("crosshairType", "dot")
            Config:UpdateCrosshair()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    -- Initialize dropdown
    UIDropDownMenu_Initialize(typeDropdown, InitializeTypeDropdown)
    UIDropDownMenu_SetWidth(120, typeDropdown)
    local currentType = Config:Get("crosshairType") or "cross"
    UIDropDownMenu_SetSelectedValue(typeDropdown, currentType)
    UIDropDownMenu_SetText(currentType == "cross" and T("Cross") or T("Dot"), typeDropdown)
    
    -- Ensure dropdown button is navigable (get it after initialization)
    local delayFrame = CreateFrame("Frame")
    delayFrame:SetScript("OnUpdate", function()
        delayFrame:Hide()
        local dropdownButton = getglobal("CEConfigCrosshairTypeDropdownButton")
        if dropdownButton then
            dropdownButton:Enable()
            dropdownButton:Show()
            -- Refresh cursor navigation to detect the button
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end
    end)
    delayFrame:Show()
    
    -- Crosshair Color button
    local colorLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, -20)
    colorLabel:SetText(T("Crosshair Color") .. ":")
    
    local colorButton = CreateFrame("Button", "CEConfigCrosshairColor", section)
    colorButton:SetWidth(80)
    colorButton:SetHeight(22)
    colorButton:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    
    -- Color button backdrop
    colorButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    -- Color preview texture
    local colorPreview = colorButton:CreateTexture(nil, "OVERLAY")
    colorPreview:SetPoint("TOPLEFT", colorButton, "TOPLEFT", 2, -2)
    colorPreview:SetPoint("BOTTOMRIGHT", colorButton, "BOTTOMRIGHT", -2, 2)
    colorButton.colorPreview = colorPreview
    
    local function UpdateColorPreview()
        local r = Config:Get("crosshairColorR") or 1.0
        local g = Config:Get("crosshairColorG") or 1.0
        local b = Config:Get("crosshairColorB") or 1.0
        local a = Config:Get("crosshairColorA") or 0.8
        colorPreview:SetTexture(r, g, b, a)
        colorButton:SetBackdropColor(r, g, b, 1)
    end
    
    colorButton:SetScript("OnClick", function()
        local r = Config:Get("crosshairColorR") or 1.0
        local g = Config:Get("crosshairColorG") or 1.0
        local b = Config:Get("crosshairColorB") or 1.0
        local a = Config:Get("crosshairColorA") or 0.8
        
        -- Ensure ColorPickerFrame appears above config frame
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(2000)
        
        -- Ensure child buttons are also on top
        if ColorPickerOkayButton then
            ColorPickerOkayButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerOkayButton:SetFrameLevel(2001)
        end
        if ColorPickerCancelButton then
            ColorPickerCancelButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerCancelButton:SetFrameLevel(2001)
        end
        
        -- Show color picker
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            local newA = 1 - OpacitySliderFrame:GetValue()
            
            Config:Set("crosshairColorR", newR)
            Config:Set("crosshairColorG", newG)
            Config:Set("crosshairColorB", newB)
            Config:Set("crosshairColorA", newA)
            UpdateColorPreview()
            Config:UpdateCrosshair()
        end
        
        ColorPickerFrame.opacityFunc = function()
            local newA = 1 - OpacitySliderFrame:GetValue()
            Config:Set("crosshairColorA", newA)
            UpdateColorPreview()
            Config:UpdateCrosshair()
        end
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        OpacitySliderFrame:SetValue(1 - a)
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - a
        
        -- Use a small delay to ensure frame levels are set before showing
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    UpdateColorPreview()
    
    -- Controller Type dropdown
    local controllerTypeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    controllerTypeLabel:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -30)
    controllerTypeLabel:SetText(T("Controller Type") .. ":")
    
    local controllerTypeDropdown = CreateFrame("Frame", "CEConfigControllerTypeDropdown", section, "UIDropDownMenuTemplate")
    controllerTypeDropdown:SetPoint("LEFT", controllerTypeLabel, "RIGHT", -15, -3)
    
    -- Ensure dropdown button is navigable with cursor
    local controllerDropdownButton = getglobal("CEConfigControllerTypeDropdownButton")
    if controllerDropdownButton then
        controllerDropdownButton:Enable()
        controllerDropdownButton:Show()
    end
    
    -- Initialize function for dropdown
    local function InitializeControllerTypeDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(controllerTypeDropdown) or (Config:Get("controllerType") or "xbox")
        local info
        
        info = {}
        info.text = "Xbox"
        info.value = "xbox"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, "xbox")
            UIDropDownMenu_SetText("Xbox", controllerTypeDropdown)
            Config:Set("controllerType", "xbox")
            -- Reload action bars to apply new controller icons
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            -- Refresh placement frame icons if it exists
            if ConsoleExperience.placement and ConsoleExperience.placement.RefreshIcons then
                ConsoleExperience.placement:RefreshIcons()
            end
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = "PlayStation"
        info.value = "ps"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, "ps")
            UIDropDownMenu_SetText("PlayStation", controllerTypeDropdown)
            Config:Set("controllerType", "ps")
            -- Reload action bars to apply new controller icons
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
            -- Refresh placement frame icons if it exists
            if ConsoleExperience.placement and ConsoleExperience.placement.RefreshIcons then
                ConsoleExperience.placement:RefreshIcons()
            end
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(controllerTypeDropdown, InitializeControllerTypeDropdown)
    UIDropDownMenu_SetWidth(120, controllerTypeDropdown)
    
    local currentControllerType = Config:Get("controllerType") or "xbox"
    UIDropDownMenu_SetSelectedValue(controllerTypeDropdown, currentControllerType)
    UIDropDownMenu_SetText(currentControllerType == "xbox" and "Xbox" or "PlayStation", controllerTypeDropdown)
    
    -- Ensure dropdown button is navigable (get it after initialization)
    local delayFrame2 = CreateFrame("Frame")
    delayFrame2:SetScript("OnUpdate", function()
        delayFrame2:Hide()
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    delayFrame2:Show()
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", controllerTypeLabel, "BOTTOMLEFT", 0, -10)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText(T("X/Y offset from screen center. Use negative values to move left/down. Size: 4-100 pixels. Type: Cross shows lines, Dot shows only center dot."))
    
    self.contentSections["interface"] = section
end

function Config:CreateKeybindingsSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("Keybinding Settings"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(300)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure special keybindings for controller-style gameplay."))
    
    -- Use A for Jump checkbox
    local jumpCheck = self:CreateCheckbox(section, T("Use A button for Jump"), 
        function() return Config:Get("useAForJump") end,
        function(checked)
            Config:Set("useAForJump", checked)
            
            -- Determine the new binding for key 1
            local key = "1"
            local newBinding
            if checked then
                newBinding = "JUMP"
                CE_Debug("A button now bound to JUMP")
            else
                newBinding = "CE_ACTION_1"
                CE_Debug("A button now bound to Action Slot 1")
            end
            
            -- Check if cursor mode is active
            local cursorModeActive = false
            if ConsoleExperience.cursor and ConsoleExperience.cursor.keybindings then
                cursorModeActive = ConsoleExperience.cursor.keybindings.cursorModeActive
            end
            
            if cursorModeActive then
                -- Cursor mode is active - update the saved original binding
                local cursorKeys = ConsoleExperience.cursor.keybindings
                if not cursorKeys.originalBindings then
                    cursorKeys.originalBindings = {}
                end
                cursorKeys.originalBindings[key] = newBinding
                CE_Debug("Updated cursor original binding for key " .. key .. " to " .. newBinding)
            else
                -- Cursor mode not active, set binding directly
                SetBinding(key, newBinding)
                SaveBindings(1)
                CE_Debug("Set binding directly: key " .. key .. " to " .. newBinding)
            end
            
            -- Update action bar display
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
        end)
    jumpCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", jumpCheck, "BOTTOMLEFT", 0, -10)
    helpText:SetWidth(300)
    helpText:SetJustifyH("LEFT")
    helpText:SetText(T("When enabled, pressing the A button (key 1) will jump. When disabled, it will use whatever action is in slot 1 of the action bar."))
    
    -- Separator
    local separator = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    separator:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -25)
    separator:SetText(T("Reset Bindings"))
    
    -- Reset Default Bindings button
    local resetBindingsButton = CreateFrame("Button", "CEConfigResetBindings", section, "UIPanelButtonTemplate")
    resetBindingsButton:SetWidth(160)
    resetBindingsButton:SetHeight(24)
    resetBindingsButton:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -10)
    resetBindingsButton:SetText(T("Reset Default Bindings"))
    resetBindingsButton:SetScript("OnClick", function()
        -- Reset keybindings
        ConsoleExperienceKeybindings:ResetAllBindings()
        
        -- Reset macros and place them on action bar
        local macrosCreated, macrosPlaced = ConsoleExperience.macros:ResetMacrosToDefaults()
        
        -- Update action bar display
        if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
            ConsoleExperience.actionbars:UpdateAllButtons()
        end
        
        CE_Debug("Default bindings and macros have been reset!")
        CE_Debug("Macros created: " .. macrosCreated .. ", placed on action bar: " .. macrosPlaced)
    end)
    
    -- Reset help text
    local resetHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetHelp:SetPoint("TOPLEFT", resetBindingsButton, "BOTTOMLEFT", 0, -5)
    resetHelp:SetWidth(300)
    resetHelp:SetJustifyH("LEFT")
    resetHelp:SetText(T("Resets all keybindings to default (1-0 keys) and places default macros (Target) on the action bar."))
    
    -- Separator for Placement Frame
    local separator2 = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    separator2:SetPoint("TOPLEFT", resetHelp, "BOTTOMLEFT", 0, -25)
    separator2:SetText(T("Spell Placement"))
    
    -- Show Placement Frame button
    local showPlacementButton = CreateFrame("Button", "CEConfigShowPlacement", section, "UIPanelButtonTemplate")
    showPlacementButton:SetWidth(160)
    showPlacementButton:SetHeight(24)
    showPlacementButton:SetPoint("TOPLEFT", separator2, "BOTTOMLEFT", 0, -10)
    showPlacementButton:SetText(T("Show Placement Frame"))
    showPlacementButton:SetScript("OnClick", function()
        if ConsoleExperience.placement then
            -- Show placement frame and close config frame
            ConsoleExperience.placement:Show()
            Config:Hide()
        else
            CE_Debug("Placement module not loaded!")
        end
    end)
    
    -- Placement help text
    local placementHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    placementHelp:SetPoint("TOPLEFT", showPlacementButton, "BOTTOMLEFT", 0, -5)
    placementHelp:SetWidth(300)
    placementHelp:SetJustifyH("LEFT")
    placementHelp:SetText(T("Opens the spell placement frame where you can drag and drop spells, macros, and items onto action bar slots."))
    
    self.contentSections["keybindings"] = section
end

function Config:CreateBarsSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("Action Bar Settings"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure the gamepad-style action bar layout."))
    
    -- Appearance dropdown
    local appearanceLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    appearanceLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    appearanceLabel:SetText(T("Appearance") .. ":")
    
    local appearanceDropdown = CreateFrame("Frame", "CEConfigBarAppearanceDropdown", section, "UIDropDownMenuTemplate")
    appearanceDropdown:SetPoint("LEFT", appearanceLabel, "RIGHT", -15, -3)
    
    -- Ensure dropdown button is navigable with cursor
    local appearanceDropdownButton = getglobal("CEConfigBarAppearanceDropdownButton")
    if appearanceDropdownButton then
        appearanceDropdownButton:Enable()
        appearanceDropdownButton:Show()
    end
    
    -- Initialize function for dropdown
    local function InitializeAppearanceDropdown()
        local selectedValue = UIDropDownMenu_GetSelectedValue(appearanceDropdown) or (Config:Get("barAppearance") or "classic")
        local info
        
        info = {}
        info.text = T("Classic")
        info.value = "classic"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(appearanceDropdown, "classic")
            UIDropDownMenu_SetText(T("Classic"), appearanceDropdown)
            Config:Set("barAppearance", "classic")
            Config:UpdateActionBarLayout()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
        
        info = {}
        info.text = T("Modern")
        info.value = "modern"
        info.func = function()
            UIDropDownMenu_SetSelectedValue(appearanceDropdown, "modern")
            UIDropDownMenu_SetText(T("Modern"), appearanceDropdown)
            Config:Set("barAppearance", "modern")
            Config:UpdateActionBarLayout()
        end
        if info.value == selectedValue then
            info.checked = 1
        end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(appearanceDropdown, InitializeAppearanceDropdown)
    UIDropDownMenu_SetWidth(120, appearanceDropdown)
    
    local currentAppearance = Config:Get("barAppearance") or "classic"
    UIDropDownMenu_SetSelectedValue(appearanceDropdown, currentAppearance)
    UIDropDownMenu_SetText(currentAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
    
    -- Button Size
    local sizeLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sizeLabel:SetPoint("TOPLEFT", appearanceLabel, "BOTTOMLEFT", 0, -20)
    sizeLabel:SetText(T("Button Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barButtonSize")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 20 then num = 20 end
            if num > 80 then num = 80 end
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end)
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 40
        if num < 20 then num = 20 end
        if num > 80 then num = 80 end
        Config:Set("barButtonSize", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- Padding
    local paddingLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    paddingLabel:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -15)
    paddingLabel:SetText(T("Button Padding") .. ":")
    
    local paddingEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barPadding")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 0 then num = 0 end
            if num > 100 then num = 100 end
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end)
    paddingEditBox:SetPoint("LEFT", paddingLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    paddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 40
        if num < 0 then num = 0 end
        if num > 100 then num = 100 end
        Config:Set("barPadding", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- X Offset
    local xLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xLabel:SetPoint("TOPLEFT", paddingLabel, "BOTTOMLEFT", 0, -15)
    xLabel:SetText(T("X Offset") .. ":")
    
    local xEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barXOffset")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("barXOffset", num)
            Config:UpdateActionBarLayout()
        end)
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("barXOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- Y Offset
    local yLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yLabel:SetPoint("TOPLEFT", xLabel, "BOTTOMLEFT", 0, -15)
    yLabel:SetText(T("Y Offset") .. ":")
    
    local yEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barYOffset")) end,
        function(value)
            local num = tonumber(value) or 70
            Config:Set("barYOffset", num)
            Config:UpdateActionBarLayout()
        end)
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 70
        Config:Set("barYOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- Star Padding (between left and right sides)
    local starPaddingLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    starPaddingLabel:SetPoint("TOPLEFT", yLabel, "BOTTOMLEFT", 0, -15)
    starPaddingLabel:SetText(T("Star Padding") .. ":")
    
    local starPaddingEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barStarPadding")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end)
    starPaddingEditBox:SetPoint("LEFT", starPaddingLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    starPaddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 200
        if num < 50 then num = 50 end
        if num > 1000 then num = 1000 end
        Config:Set("barStarPadding", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- Scale
    local scaleLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("TOPLEFT", starPaddingLabel, "BOTTOMLEFT", 0, -15)
    scaleLabel:SetText(T("Scale") .. ":")
    
    local scaleEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("barScale")) end,
        function(value)
            local num = tonumber(value) or 1.0
            if num < 0.5 then num = 0.5 end
            if num > 2.0 then num = 2.0 end
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end)
    scaleEditBox:SetPoint("LEFT", scaleLabel, "RIGHT", 10, 0)
    -- Update action bars in real-time as user types
    scaleEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 1.0
        if num < 0.5 then num = 0.5 end
        if num > 2.0 then num = 2.0 end
        Config:Set("barScale", num)
        Config:UpdateActionBarLayout()
    end)
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", scaleLabel, "BOTTOMLEFT", 0, -25)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText(T("Size: 20-80, Padding: 0-100, Star Padding: 50-1000, Scale: 0.5-2.0. X/Y offset from bottom center."))
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", "CEConfigResetLayout", section, "UIPanelButtonTemplate")
    resetButton:SetWidth(120)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -15)
    resetButton:SetText(T("Reset Layout"))
    resetButton:SetScript("OnClick", function()
        Config:Set("barButtonSize", Config.DEFAULTS.barButtonSize)
        Config:Set("barPadding", Config.DEFAULTS.barPadding)
        Config:Set("barStarPadding", Config.DEFAULTS.barStarPadding)
        Config:Set("barXOffset", Config.DEFAULTS.barXOffset)
        Config:Set("barYOffset", Config.DEFAULTS.barYOffset)
        Config:Set("barScale", Config.DEFAULTS.barScale)
        Config:Set("barAppearance", Config.DEFAULTS.barAppearance)
        Config:UpdateActionBarLayout()
        -- Refresh edit boxes
        sizeEditBox:SetText(tostring(Config.DEFAULTS.barButtonSize))
        paddingEditBox:SetText(tostring(Config.DEFAULTS.barPadding))
        starPaddingEditBox:SetText(tostring(Config.DEFAULTS.barStarPadding))
        xEditBox:SetText(tostring(Config.DEFAULTS.barXOffset))
        yEditBox:SetText(tostring(Config.DEFAULTS.barYOffset))
        scaleEditBox:SetText(tostring(Config.DEFAULTS.barScale))
        -- Refresh dropdown
        local currentAppearance = Config.DEFAULTS.barAppearance or "classic"
        UIDropDownMenu_SetSelectedValue(appearanceDropdown, currentAppearance)
        UIDropDownMenu_SetText(currentAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
        CE_Debug("Action bar layout reset to defaults")
    end)
    
    self.contentSections["bars"] = section
end

function Config:CreateChatSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("Chat Settings"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure the chat frame position and size. The chat frame is centered at the bottom of the screen."))
    
    -- Chat Width
    local chatWidthLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatWidthLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -20)
    chatWidthLabel:SetText(T("Chat Width") .. ":")
    
    local chatWidthEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("chatWidth")) end,
        function(value)
            local num = tonumber(value) or 400
            if num < 100 then num = 100 end
            if num > 2000 then num = 2000 end
            Config:Set("chatWidth", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
            -- Update XP/Rep bars if they use chat width
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end)
    chatWidthEditBox:SetPoint("LEFT", chatWidthLabel, "RIGHT", 10, 0)
    
    -- Chat Height
    local chatHeightLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatHeightLabel:SetPoint("TOPLEFT", chatWidthLabel, "BOTTOMLEFT", 0, -15)
    chatHeightLabel:SetText(T("Chat Height") .. ":")
    
    local chatHeightEditBox = self:CreateEditBox(section, 50, 
        function() return tostring(Config:Get("chatHeight")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("chatHeight", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end)
    chatHeightEditBox:SetPoint("LEFT", chatHeightLabel, "RIGHT", 10, 0)
    
    -- Keyboard Enabled checkbox
    local keyboardCheck = CreateFrame("CheckButton", "CEConfigKeyboardEnabled", section, "UICheckButtonTemplate")
    keyboardCheck:SetPoint("TOPLEFT", chatHeightLabel, "BOTTOMLEFT", 0, -15)
    keyboardCheck:SetChecked(Config:Get("keyboardEnabled"))
    keyboardCheck:SetScript("OnClick", function()
        local checked = keyboardCheck:GetChecked() == 1
        Config:Set("keyboardEnabled", checked)
        CE_Debug("Virtual keyboard " .. (checked and "enabled" or "disabled"))
        -- If keyboard is disabled and currently visible, hide it immediately
        if not checked and ConsoleExperience.keyboard and ConsoleExperience.keyboard:IsVisible() then
            ConsoleExperience.keyboard:Hide()
        end
        -- If keyboard is disabled, ensure ChatFrameEditBox has proper focus and keyboard input
        if not checked and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
            ChatFrameEditBox:EnableKeyboard(true)
            -- Use a small delay to ensure focus is set
            local focusFrame = CreateFrame("Frame")
            focusFrame:SetScript("OnUpdate", function()
                this.elapsed = (this.elapsed or 0) + arg1
                if this.elapsed > 0.1 then
                    this:SetScript("OnUpdate", nil)
                    if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                        ChatFrameEditBox:SetFocus()
                    end
                end
            end)
        end
    end)
    
    -- Refresh checkbox state when section is shown
    section:SetScript("OnShow", function()
        keyboardCheck:SetChecked(Config:Get("keyboardEnabled"))
    end)
    
    local keyboardLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keyboardLabel:SetPoint("LEFT", keyboardCheck, "RIGHT", 5, 0)
    keyboardLabel:SetText(T("Enable Virtual Keyboard"))
    
    -- Keyboard help text
    local keyboardHelp = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    keyboardHelp:SetPoint("TOPLEFT", keyboardCheck, "BOTTOMLEFT", 0, -5)
    keyboardHelp:SetWidth(260)
    keyboardHelp:SetJustifyH("LEFT")
    keyboardHelp:SetText(T("When enabled, a virtual keyboard appears when typing in chat. Disable to use an external keyboard."))
    
    -- Help text
    local helpText = section:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    helpText:SetPoint("TOPLEFT", keyboardHelp, "BOTTOMLEFT", 0, -10)
    helpText:SetWidth(260)
    helpText:SetJustifyH("LEFT")
    helpText:SetText(T("Width: 100-2000, Height: 50-1000. The chat frame is centered at the bottom of the screen."))
    
    -- Reset to defaults button
    local resetButton = CreateFrame("Button", "CEConfigResetChat", section, "UIPanelButtonTemplate")
    resetButton:SetWidth(120)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -15)
    resetButton:SetText(T("Reset Chat"))
    resetButton:SetScript("OnClick", function()
        Config:Set("chatWidth", Config.DEFAULTS.chatWidth)
        Config:Set("chatHeight", Config.DEFAULTS.chatHeight)
        Config:Set("keyboardEnabled", Config.DEFAULTS.keyboardEnabled)
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        -- Refresh edit boxes and checkbox
        chatWidthEditBox:SetText(tostring(Config.DEFAULTS.chatWidth))
        chatHeightEditBox:SetText(tostring(Config.DEFAULTS.chatHeight))
        keyboardCheck:SetChecked(Config.DEFAULTS.keyboardEnabled)
        CE_Debug("Chat settings reset to defaults")
    end)
    
    self.contentSections["chat"] = section
end

function Config:CreateXPBarSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("XP/Reputation Bars"))
    
    -- Description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure experience and reputation bars. Bars appear below chat and fade out after timeout."))
    
    local yOffset = -20
    
    -- XP Bar Always Visible
    local xpAlwaysCheck = CreateFrame("CheckButton", "CEConfigXPBarAlways", section, "UICheckButtonTemplate")
    xpAlwaysCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    xpAlwaysCheck:SetChecked(Config:Get("xpBarAlways") or false)
    xpAlwaysCheck:SetScript("OnClick", function()
        local checked = xpAlwaysCheck:GetChecked() == 1
        Config:Set("xpBarAlways", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
            ConsoleExperience.xpbar.xpBar.always = checked
            if checked then
                ConsoleExperience.xpbar.xpBar:SetAlpha(1)
                ConsoleExperience.xpbar.xpBar:Show()
            end
        end
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
            ConsoleExperience.xpbar:UpdateAllBars()
        end
    end)
    local xpAlwaysLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpAlwaysLabel:SetPoint("LEFT", xpAlwaysCheck, "RIGHT", 5, 0)
    xpAlwaysLabel:SetText(T("XP Bar Always Visible"))
    
    yOffset = yOffset - 25
    
    -- XP Bar Width
    local xpWidthLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpWidthLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    xpWidthLabel:SetText(T("XP Bar Width") .. " (0 = Chat Width):")
    
    local xpWidthEditBox = self:CreateEditBox(section, 50,
        function() 
            local val = Config:Get("xpBarWidth")
            return val and tostring(val) or "0"
        end,
        function(value)
            local num = tonumber(value)
            if num == 0 then num = nil end
            if num and num < 50 then num = 50 end
            if num and num > 2000 then num = 2000 end
            Config:Set("xpBarWidth", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end)
    xpWidthEditBox:SetPoint("LEFT", xpWidthLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- XP Bar Height
    local xpHeightLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpHeightLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    xpHeightLabel:SetText(T("XP Bar Height") .. ":")
    
    local xpHeightEditBox = self:CreateEditBox(section, 50,
        function() return tostring(Config:Get("xpBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end  -- Minimum height for border texture
            if num > 100 then num = 100 end
            Config:Set("xpBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end)
    xpHeightEditBox:SetPoint("LEFT", xpHeightLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- XP Bar Timeout
    local xpTimeoutLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpTimeoutLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    xpTimeoutLabel:SetText(T("XP Bar Timeout") .. " (seconds):")
    
    local xpTimeoutEditBox = self:CreateEditBox(section, 50,
        function() return tostring(Config:Get("xpBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("xpBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
                ConsoleExperience.xpbar.xpBar.timeout = num
            end
        end)
    xpTimeoutEditBox:SetPoint("LEFT", xpTimeoutLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- XP Bar Text Show
    local xpTextShowCheck = CreateFrame("CheckButton", "CEConfigXPBarTextShow", section, "UICheckButtonTemplate")
    xpTextShowCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    local xpTextShowValue = Config:Get("xpBarTextShow")
    xpTextShowCheck:SetChecked(xpTextShowValue == nil and true or xpTextShowValue)
    xpTextShowCheck:SetScript("OnClick", function()
        local checked = xpTextShowCheck:GetChecked() == 1
        Config:Set("xpBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
            -- Reload config to update text_show
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.xpBar, "XP")
            -- Trigger an update to populate text if bar is always visible
            if ConsoleExperience.xpbar.xpBar.always then
                event = "PLAYER_XP_UPDATE"
                ConsoleExperience.xpbar.xpBar:GetScript("OnEvent")(ConsoleExperience.xpbar.xpBar)
            end
            -- Also update text visibility directly if text exists
            if ConsoleExperience.xpbar.xpBar.bar and ConsoleExperience.xpbar.xpBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.xpBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.xpBar.bar.text:Hide()
                end
            end
        end
    end)
    local xpTextShowLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xpTextShowLabel:SetPoint("LEFT", xpTextShowCheck, "RIGHT", 5, 0)
    xpTextShowLabel:SetText(T("XP Bar Text Show"))
    
    yOffset = yOffset - 25
    
    -- Rep Bar Always Visible
    local repAlwaysCheck = CreateFrame("CheckButton", "CEConfigRepBarAlways", section, "UICheckButtonTemplate")
    repAlwaysCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    repAlwaysCheck:SetChecked(Config:Get("repBarAlways") or false)
    repAlwaysCheck:SetScript("OnClick", function()
        local checked = repAlwaysCheck:GetChecked() == 1
        Config:Set("repBarAlways", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
            ConsoleExperience.xpbar.repBar.always = checked
            if checked then
                ConsoleExperience.xpbar.repBar:SetAlpha(1)
                ConsoleExperience.xpbar.repBar:Show()
            end
        end
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
            ConsoleExperience.xpbar:UpdateAllBars()
        end
    end)
    local repAlwaysLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repAlwaysLabel:SetPoint("LEFT", repAlwaysCheck, "RIGHT", 5, 0)
    repAlwaysLabel:SetText(T("Reputation Bar Always Visible"))
    
    yOffset = yOffset - 25
    
    -- Rep Bar Width
    local repWidthLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repWidthLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    repWidthLabel:SetText(T("Reputation Bar Width") .. " (0 = Chat Width):")
    
    local repWidthEditBox = self:CreateEditBox(section, 50,
        function() 
            local val = Config:Get("repBarWidth")
            return val and tostring(val) or "0"
        end,
        function(value)
            local num = tonumber(value)
            if num == 0 then num = nil end
            if num and num < 50 then num = 50 end
            if num and num > 2000 then num = 2000 end
            Config:Set("repBarWidth", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end)
    repWidthEditBox:SetPoint("LEFT", repWidthLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- Rep Bar Height
    local repHeightLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repHeightLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    repHeightLabel:SetText(T("Reputation Bar Height") .. ":")
    
    local repHeightEditBox = self:CreateEditBox(section, 50,
        function() return tostring(Config:Get("repBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end  -- Minimum height for border texture
            if num > 100 then num = 100 end
            Config:Set("repBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end)
    repHeightEditBox:SetPoint("LEFT", repHeightLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- Rep Bar Timeout
    local repTimeoutLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repTimeoutLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    repTimeoutLabel:SetText(T("Reputation Bar Timeout") .. " (seconds):")
    
    local repTimeoutEditBox = self:CreateEditBox(section, 50,
        function() return tostring(Config:Get("repBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("repBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
                ConsoleExperience.xpbar.repBar.timeout = num
            end
        end)
    repTimeoutEditBox:SetPoint("LEFT", repTimeoutLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 25
    
    -- Rep Bar Text Show
    local repTextShowCheck = CreateFrame("CheckButton", "CEConfigRepBarTextShow", section, "UICheckButtonTemplate")
    repTextShowCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    local repTextShowValue = Config:Get("repBarTextShow")
    repTextShowCheck:SetChecked(repTextShowValue == nil and true or repTextShowValue)
    repTextShowCheck:SetScript("OnClick", function()
        local checked = repTextShowCheck:GetChecked() == 1
        Config:Set("repBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
            ConsoleExperience.xpbar.repBar.text_show = checked
            -- Reload config to ensure text_show is updated
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.repBar, "REP")
            -- Trigger an update to populate text if bar is always visible
            if ConsoleExperience.xpbar.repBar.always then
                event = "UPDATE_FACTION"
                ConsoleExperience.xpbar.repBar:GetScript("OnEvent")(ConsoleExperience.xpbar.repBar)
            end
            -- Also update text visibility directly if text exists
            if ConsoleExperience.xpbar.repBar.bar and ConsoleExperience.xpbar.repBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.repBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.repBar.bar.text:Hide()
                end
            end
        end
    end)
    local repTextShowLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repTextShowLabel:SetPoint("LEFT", repTextShowCheck, "RIGHT", 5, 0)
    repTextShowLabel:SetText(T("Reputation Bar Text Show"))
    
    yOffset = yOffset - 25
    
    self.contentSections["xpbar"] = section
end

-- ============================================================================
-- Cast Bar Section
-- ============================================================================

function Config:CreateCastBarSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetAllPoints(content)
    section:Hide()
    
    -- Section title
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 15, -15)
    title:SetText(T("Cast Bar Settings"))
    
    -- Section description
    local desc = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(280)
    desc:SetJustifyH("LEFT")
    desc:SetText(T("Configure the custom cast bar that appears above chat."))
    
    local yOffset = -50
    
    -- Castbar Enabled
    local enabledCheck = CreateFrame("CheckButton", "CEConfigCastbarEnabled", section, "UICheckButtonTemplate")
    enabledCheck:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    enabledCheck:SetChecked(Config:Get("castbarEnabled"))
    enabledCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("castbarEnabled", checked)
        if ConsoleExperience.castbar and ConsoleExperience.castbar.ReloadConfig then
            ConsoleExperience.castbar:ReloadConfig()
        end
    end)
    local enabledLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enabledLabel:SetPoint("LEFT", enabledCheck, "RIGHT", 5, 0)
    enabledLabel:SetText(T("Enable Cast Bar"))
    
    yOffset = yOffset - 35
    
    -- Castbar Height
    local heightLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heightLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    heightLabel:SetText(T("Cast Bar Height") .. ":")
    
    local heightEditBox = self:CreateEditBox(section, 50,
        function() return tostring(Config:Get("castbarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("castbarHeight", num)
            if ConsoleExperience.castbar and ConsoleExperience.castbar.UpdatePosition then
                ConsoleExperience.castbar:UpdatePosition()
            end
        end)
    heightEditBox:SetPoint("LEFT", heightLabel, "RIGHT", 10, 0)
    
    yOffset = yOffset - 35
    
    -- Castbar Color
    local colorLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colorLabel:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, yOffset)
    colorLabel:SetText(T("Cast Bar Color") .. ":")
    
    -- Color preview button
    local colorBtn = CreateFrame("Button", "CEConfigCastbarColorBtn", section)
    colorBtn:SetWidth(40)
    colorBtn:SetHeight(20)
    colorBtn:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
    
    -- Create color preview texture
    local colorPreview = colorBtn:CreateTexture(nil, "BACKGROUND")
    colorPreview:SetAllPoints()
    
    local function UpdateColorPreview()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        colorPreview:SetTexture(r, g, b)
    end
    UpdateColorPreview()
    
    -- Border for color button
    colorBtn:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    colorBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    colorBtn:SetScript("OnClick", function()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        
        -- Ensure ColorPickerFrame appears above config frame
        ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        ColorPickerFrame:SetFrameLevel(2000)
        
        if ColorPickerOkayButton then
            ColorPickerOkayButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerOkayButton:SetFrameLevel(2001)
        end
        if ColorPickerCancelButton then
            ColorPickerCancelButton:SetFrameStrata("FULLSCREEN_DIALOG")
            ColorPickerCancelButton:SetFrameLevel(2001)
        end
        
        ColorPickerFrame.func = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            Config:Set("castbarColorR", newR)
            Config:Set("castbarColorG", newG)
            Config:Set("castbarColorB", newB)
            UpdateColorPreview()
            if ConsoleExperience.castbar and ConsoleExperience.castbar.UpdateColor then
                ConsoleExperience.castbar:UpdateColor()
            end
        end
        
        ColorPickerFrame:SetColorRGB(r, g, b)
        ColorPickerFrame.hasOpacity = false
        
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    
    self.contentSections["castbar"] = section
end

-- ============================================================================
-- UI Helpers
-- ============================================================================

-- Counter for generating unique names
Config.elementCounter = 0

function Config:GetNextElementName(prefix)
    self.elementCounter = self.elementCounter + 1
    return "CEConfig" .. prefix .. self.elementCounter
end

function Config:CreateCheckbox(parent, label, getFunc, setFunc)
    local name = self:GetNextElementName("Check")
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", check, "RIGHT", 5, 0)
    text:SetText(label)
    
    -- Store label for tooltip/debug
    check.label = label
    
    -- Set initial state
    check:SetChecked(getFunc())
    
    -- Click handler
    check:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        setFunc(checked)
    end)
    
    return check
end

function Config:CreateEditBox(parent, width, getFunc, setFunc)
    local name = self:GetNextElementName("Edit")
    local editBox = CreateFrame("EditBox", name, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    
    -- Background
    editBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Set initial value
    editBox:SetText(getFunc())
    
    -- Focus handlers
    editBox:SetScript("OnEscapePressed", function()
        this:ClearFocus()
        this:SetText(getFunc())
    end)
    
    editBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        setFunc(this:GetText())
    end)
    
    editBox:SetScript("OnEditFocusLost", function()
        setFunc(this:GetText())
    end)
    
    return editBox
end

-- ============================================================================
-- Section Management
-- ============================================================================

function Config:ShowSection(sectionId)
    -- Hide all sections
    for id, section in pairs(self.contentSections) do
        section:Hide()
    end
    
    -- Reset all sidebar button colors
    for id, button in pairs(self.sidebarButtons) do
        button:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
    end
    
    -- Show selected section
    if self.contentSections[sectionId] then
        self.contentSections[sectionId]:Show()
        -- Update scroll child height when showing section
        self:UpdateScrollChildHeight()
    end
    
    -- Highlight selected sidebar button
    if self.sidebarButtons[sectionId] then
        self.sidebarButtons[sectionId]:SetBackdropColor(0.4, 0.4, 0.6, 0.8)
    end
    
    self.currentSection = sectionId
    
    -- Refresh cursor navigation to detect dropdown buttons and other elements
    if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end)
        delayFrame:Show()
    end
end

-- ============================================================================
-- Toggle/Show/Hide
-- ============================================================================

function Config:Toggle()
    if not self.frame then
        self:CreateMainFrame()
    end
    
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function Config:Show()
    if not self.frame then
        self:CreateMainFrame()
    end
    self.frame:Show()
    
    -- Refresh cursor navigation to include dropdown buttons
    if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
                ConsoleExperience.cursor:RefreshFrame()
            end
        end)
        delayFrame:Show()
    end
end

function Config:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- ============================================================================
-- Game Menu Button
-- ============================================================================

function Config:CreateGameMenuButton()
    -- Don't create if already exists
    if GameMenuButtonConsoleExperience then return end
    
    -- Create button using GameMenuButtonTemplate
    local button = CreateFrame("Button", "GameMenuButtonConsoleExperience", GameMenuFrame, "GameMenuButtonTemplate")
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    button:SetText(T("Console Experience"))
    
    -- Position after UIOptions (Interface Options) button
    if GameMenuButtonUIOptions then
        button:SetPoint("TOP", GameMenuButtonUIOptions, "BOTTOM", 0, -1)
    elseif GameMenuButtonOptions then
        button:SetPoint("TOP", GameMenuButtonOptions, "BOTTOM", 0, -1)
    else
        button:SetPoint("TOP", GameMenuFrame, "TOP", 0, -30)
    end
    
    -- Click handler
    button:SetScript("OnClick", function()
        ConsoleExperience.config:Toggle()
        HideUIPanel(GameMenuFrame)
    end)
    
    -- Move buttons below us down
    if GameMenuButtonKeybindings then
        GameMenuButtonKeybindings:SetPoint("TOP", button, "BOTTOM", 0, -1)
    end
    
    -- Increase frame height
    GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)
end

-- Create the game menu button when the addon loads
Config:CreateGameMenuButton()

-- Create reload UI popup
StaticPopupDialogs["CE_RELOAD_UI"] = {
    text = "Language changed. Reload UI to apply?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- ============================================================================
-- Crosshair
-- ============================================================================

function Config:CreateCrosshair()
    if self.crosshairFrame then return self.crosshairFrame end
    
    local frame = CreateFrame("Frame", "ConsoleExperienceCrosshair", UIParent)
    frame:SetWidth(32)
    frame:SetHeight(32)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    
    -- Create crosshair texture (simple cross)
    local size = 24
    local thickness = 2
    
    -- Horizontal line
    local hLine = frame:CreateTexture(nil, "OVERLAY")
    hLine:SetTexture(1, 1, 1, 0.8)
    hLine:SetWidth(size)
    hLine:SetHeight(thickness)
    hLine:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.hLine = hLine
    
    -- Vertical line
    local vLine = frame:CreateTexture(nil, "OVERLAY")
    vLine:SetTexture(1, 1, 1, 0.8)
    vLine:SetWidth(thickness)
    vLine:SetHeight(size)
    vLine:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.vLine = vLine
    
    -- Center dot
    local dot = frame:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(1, 0.2, 0.2, 1)
    dot:SetWidth(4)
    dot:SetHeight(4)
    dot:SetPoint("CENTER", frame, "CENTER", 0, 0)
    frame.dot = dot
    
    frame:Hide()
    self.crosshairFrame = frame
    
    return frame
end

function Config:UpdateCrosshair()
    if not self.crosshairFrame then
        self:CreateCrosshair()
    end
    
    local enabled = self:Get("crosshairEnabled")
    local xOffset = self:Get("crosshairX") or 0
    local yOffset = self:Get("crosshairY") or 0
    local size = self:Get("crosshairSize") or 24
    local crosshairType = self:Get("crosshairType") or "cross"
    local r = self:Get("crosshairColorR") or 1.0
    local g = self:Get("crosshairColorG") or 1.0
    local b = self:Get("crosshairColorB") or 1.0
    local a = self:Get("crosshairColorA") or 0.8
    local thickness = math.max(2, math.floor(size / 12))
    
    -- Update position
    self.crosshairFrame:ClearAllPoints()
    self.crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset, yOffset)
    self.crosshairFrame:SetWidth(size + 8)
    self.crosshairFrame:SetHeight(size + 8)
    
    -- Update crosshair based on type
    if crosshairType == "dot" then
        -- Dot only - hide lines, show dot with configured color
        if self.crosshairFrame.hLine then
            self.crosshairFrame.hLine:Hide()
        end
        if self.crosshairFrame.vLine then
            self.crosshairFrame.vLine:Hide()
        end
        if self.crosshairFrame.dot then
            local dotSize = math.max(2, math.floor(size / 6))
            self.crosshairFrame.dot:SetWidth(dotSize)
            self.crosshairFrame.dot:SetHeight(dotSize)
            self.crosshairFrame.dot:SetTexture(r, g, b, a)
            self.crosshairFrame.dot:Show()
        end
    else
        -- Cross - show lines and dot (dot uses red tint for visibility in cross mode)
        if self.crosshairFrame.hLine then
            self.crosshairFrame.hLine:SetWidth(size)
            self.crosshairFrame.hLine:SetHeight(thickness)
            self.crosshairFrame.hLine:SetTexture(r, g, b, a)
            self.crosshairFrame.hLine:Show()
        end
        if self.crosshairFrame.vLine then
            self.crosshairFrame.vLine:SetWidth(thickness)
            self.crosshairFrame.vLine:SetHeight(size)
            self.crosshairFrame.vLine:SetTexture(r, g, b, a)
            self.crosshairFrame.vLine:Show()
        end
        if self.crosshairFrame.dot then
            local dotSize = math.max(2, math.floor(size / 6))
            self.crosshairFrame.dot:SetWidth(dotSize)
            self.crosshairFrame.dot:SetHeight(dotSize)
            -- Dot uses red tint for visibility when lines are present (original behavior)
            self.crosshairFrame.dot:SetTexture(r, g * 0.2, b * 0.2, a)
            self.crosshairFrame.dot:Show()
        end
    end
    
    if enabled then
        self.crosshairFrame:Show()
    else
        self.crosshairFrame:Hide()
    end
end

-- Initialize crosshair on load (will apply saved settings after VARIABLES_LOADED via InitializeDB)
Config:CreateCrosshair()

-- ============================================================================
-- Action Bar Layout
-- ============================================================================

-- Layout positions relative to star center (in units of padding)
-- Format: { buttonId, xMultiplier, yMultiplier }
Config.BUTTON_LAYOUT = {
    -- Left star (D-Pad) - center at negative X offset
    { id = 10, star = "left",  x = 0,  y = 0 },   -- LB (center)
    { id = 7,  star = "left",  x = 0,  y = 1 },   -- Up
    { id = 5,  star = "left",  x = 0,  y = -1 },  -- Down
    { id = 6,  star = "left",  x = -1, y = 0 },   -- Left
    { id = 8,  star = "left",  x = 1,  y = 0 },   -- Right
    -- Right star (Face buttons) - center at positive X offset
    { id = 9,  star = "right", x = 0,  y = 0 },   -- RB (center)
    { id = 3,  star = "right", x = 0,  y = 1 },   -- Y (top)
    { id = 1,  star = "right", x = 0,  y = -1 },  -- A (bottom)
    { id = 2,  star = "right", x = -1, y = 0 },   -- X (left)
    { id = 4,  star = "right", x = 1,  y = 0 },   -- B (right)
}

function Config:UpdateActionBarLayout()
    local buttonSize = self:Get("barButtonSize") or 60
    local padding = self:Get("barPadding") or 65
    local starPadding = self:Get("barStarPadding") or 200
    local xOffset = self:Get("barXOffset") or 0
    local yOffset = self:Get("barYOffset") or 70
    local scale = self:Get("barScale") or 1.0
    
    -- Calculate star center positions
    -- Stars are separated by starPadding (half on each side)
    local starSpacing = starPadding / 2  -- Distance from center to each star center
    
    -- Store star positions for chat positioning
    self.leftStarCenterX = -starSpacing + xOffset
    self.rightStarCenterX = starSpacing + xOffset
    self.starYOffset = yOffset
    
    for _, buttonInfo in ipairs(self.BUTTON_LAYOUT) do
        local button = getglobal("ConsoleActionButton" .. buttonInfo.id)
        if button and button:IsVisible() ~= nil then  -- Ensure button exists and is valid
            -- Calculate star center X position
            local starCenterX
            if buttonInfo.star == "left" then
                starCenterX = self.leftStarCenterX
            else
                starCenterX = self.rightStarCenterX
            end
            
            -- Calculate button position relative to star center
            local buttonX = starCenterX + (buttonInfo.x * padding)
            local buttonY = yOffset + (buttonInfo.y * padding)
            
            -- Apply position and scale
            button:ClearAllPoints()
            button:SetPoint("BOTTOM", UIParent, "BOTTOM", buttonX, buttonY)
            button:SetWidth(buttonSize)
            button:SetHeight(buttonSize)
            button:SetScale(scale)
            
            -- Update child elements to match new size
            local icon = getglobal(button:GetName() .. "Icon")
            if icon then
                -- For modern appearance, icon size will be adjusted below
                -- For classic, use full size minus padding
                local appearance = self:Get("barAppearance") or "classic"
                if appearance == "modern" then
                    -- Modern: Larger icon to better fill the circular overlay
                    -- Increase size slightly to eliminate gaps
                    icon:SetWidth(buttonSize * 0.70)  -- 70% of button size
                    icon:SetHeight(buttonSize * 0.70)  -- Square for better fit
                else
                    icon:SetWidth(buttonSize - 4)
                    icon:SetHeight(buttonSize - 4)
                end
            end
            
            local bg = getglobal(button:GetName() .. "Background")
            if bg then
                bg:SetWidth(buttonSize * 1.6)
                bg:SetHeight(buttonSize * 1.6)
            end
            
            local normalTex = getglobal(button:GetName() .. "NormalTexture")
            if normalTex then
                normalTex:SetWidth(buttonSize * 1.6)
                normalTex:SetHeight(buttonSize * 1.6)
            end
            
            -- Apply button appearance styling (delegated to actionbars module)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.ApplyButtonAppearance then
                ConsoleExperience.actionbars:ApplyButtonAppearance(button)
            end
            
            -- Update cooldown to match button size using scale
            -- Default cooldown size in WoW is typically 36 pixels
            -- Scale it to match buttonSize, then anchor it to fill the button
            local cooldown = getglobal(button:GetName() .. "Cooldown")
            if cooldown then
                local defaultCooldownSize = 36
                local scaleFactor = buttonSize / defaultCooldownSize
                
                -- Scale the cooldown to match button size
                cooldown:SetScale(scaleFactor)
                cooldown:ClearAllPoints()
                -- Use TOPLEFT/BOTTOMRIGHT to fill the button area
                cooldown:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                cooldown:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
    
    -- Update chat layout after action bars are positioned
    if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
        ConsoleExperience.chat:UpdateChatLayout()
    end
end

-- ============================================================================
-- Slash Command
-- ============================================================================

SLASH_CECONFIG1 = "/ce"
SLASH_CECONFIG2 = "/consoleexperience"
SlashCmdList["CECONFIG"] = function(msg)
    Config:Toggle()
end

