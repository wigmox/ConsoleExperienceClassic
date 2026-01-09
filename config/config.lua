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
    autoRankEnabled = true,  -- Automatically update spells to highest rank
    -- Side Action Bars (touch screen)
    sideBarLeftEnabled = false,  -- Left side bar disabled by default
    sideBarRightEnabled = false,  -- Right side bar disabled by default
    sideBarLeftButtons = 3,  -- Number of buttons on left bar (1-5)
    sideBarRightButtons = 3,  -- Number of buttons on right bar (1-5)
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
    -- Bag settings
    openAllBagsAtVendor = true,  -- Open all bags when interacting with merchants/auction house
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

Config.FRAME_WIDTH = 900
Config.FRAME_HEIGHT = 650
Config.SIDEBAR_WIDTH = 150
Config.BUTTON_HEIGHT = 28
Config.PADDING = 15

-- Section definitions
Config.SECTIONS = {
    { id = "interface", name = "Interface" },
    { id = "bars", name = "Bars" },
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
    
    -- Title bar for dragging (full width like UIOptionsFrame)
    local titleRegion = CreateFrame("Frame", nil, frame)
    titleRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    titleRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -5)
    titleRegion:SetHeight(30)
    titleRegion:EnableMouse(true)
    titleRegion:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    titleRegion:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    
    -- Header texture (like DialogFrame - sits on top of the border)
    local headerTexture = frame:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerTexture:SetWidth(300)
    headerTexture:SetHeight(64)
    headerTexture:SetPoint("TOP", frame, "TOP", 0, 12)
    frame.headerTexture = headerTexture
    
    -- Title text (positioned on the header texture like UIOptionsFrame)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", headerTexture, "TOP", 0, -14)
    -- Title will be set after locale is initialized, store reference
    frame.titleText = title
    
    -- Footer height for buttons
    local footerHeight = 40
    
    -- Sidebar frame (adjusted to leave room for footer)
    local sidebar = CreateFrame("Frame", nil, frame)
    sidebar:SetPoint("TOPLEFT", frame, "TOPLEFT", self.PADDING + 5, -45)
    sidebar:SetWidth(self.SIDEBAR_WIDTH)
    sidebar:SetHeight(self.FRAME_HEIGHT - 45 - footerHeight - self.PADDING)
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
    
    -- Content frame (outer container with backdrop, leaves room for footer)
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", self.PADDING, 0)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, footerHeight + self.PADDING)
    content:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    content:SetBackdropColor(0.05, 0.05, 0.05, 0.3)
    frame.content = content
    
    -- Footer buttons (like UIOptionsFrame)
    -- Close button (right side, like UIOptionsFrame Cancel button)
    local closeButton = CreateFrame("Button", "ConsoleExperienceConfigCloseButton", frame, "GameMenuButtonTemplate")
    closeButton:SetWidth(96)
    closeButton:SetHeight(21)
    closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -self.PADDING - 5, self.PADDING)
    closeButton:SetText(CLOSE or "Close")
    closeButton:SetScript("OnClick", function()
        PlaySound("gsTitleOptionExit")
        ConsoleExperience.config.frame:Hide()
    end)
    frame.closeButton = closeButton
    
    -- Debug button (left side)
    local debugButton = CreateFrame("Button", "ConsoleExperienceConfigDebugButton", frame, "GameMenuButtonTemplate")
    debugButton:SetWidth(96)
    debugButton:SetHeight(21)
    debugButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", self.PADDING + 5, self.PADDING)
    
    -- Update debug button text based on current state
    local function UpdateDebugButtonText()
        local debugEnabled = Config:Get("debugEnabled")
        if debugEnabled then
            debugButton:SetText("Debug: ON")
        else
            debugButton:SetText("Debug: OFF")
        end
    end
    UpdateDebugButtonText()
    frame.UpdateDebugButtonText = UpdateDebugButtonText
    
    debugButton:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        local debugEnabled = Config:Get("debugEnabled")
        Config:Set("debugEnabled", not debugEnabled)
        UpdateDebugButtonText()
        if not debugEnabled then
            CE_Debug("Debug output ENABLED")
        else
            CE_Debug("Debug output DISABLED")
        end
    end)
    frame.debugButton = debugButton
    
    
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
    self:ShowSection("interface")
    
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
    
    -- Create Interface section
    self:CreateInterfaceSection()
    
    -- Create Bars section
    self:CreateBarsSection()
end

function Config:CreateInterfaceSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    -- Main section container (attached to content)
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== General Settings Box ====================
    local generalBox = self:CreateSectionBox(section, T("General"))
    generalBox:SetPoint("TOP", section, "TOP", 0, -25)
    
    -- Controller Type dropdown (left side)
    local controllerTypeLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    controllerTypeLabel:SetPoint("TOPLEFT", generalBox, "TOPLEFT", generalBox.contentLeft, generalBox.contentTop)
    controllerTypeLabel:SetText(T("Controller Type") .. ":")
    
    local controllerTypeDropdown = CreateFrame("Frame", "CEConfigControllerTypeDropdown", generalBox, "UIDropDownMenuTemplate")
    controllerTypeDropdown:SetPoint("LEFT", controllerTypeLabel, "RIGHT", -15, -3)
    
    -- Initialize function for controller type dropdown
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
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
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
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateAllButtons then
                ConsoleExperience.actionbars:UpdateAllButtons()
            end
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
    
    -- Language dropdown (center)
    local langLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    langLabel:SetPoint("TOP", generalBox, "TOP", -80, generalBox.contentTop)
    langLabel:SetText(T("Language") .. ":")
    
    local langDropdown = CreateFrame("Frame", "CEConfigLanguageDropdown", generalBox, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("LEFT", langLabel, "RIGHT", -15, -3)
    
    -- Initialize function for language dropdown
    local function InitializeLanguageDropdown()
        if not Locale then 
            CE_Debug("Language dropdown: Locale module not found")
            return 
        end
        
        local available = Locale:GetAvailableLanguages()
        
        if table.getn(available) == 0 then 
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
                StaticPopup_Show("CE_RELOAD_UI")
            end
            if info.value == selectedValue then
                info.checked = 1
            end
            UIDropDownMenu_AddButton(info)
        end
    end
    
    langDropdown.initialize = InitializeLanguageDropdown
    UIDropDownMenu_Initialize(langDropdown, InitializeLanguageDropdown)
    UIDropDownMenu_SetWidth(120, langDropdown)
    local currentLang = Config:Get("language") or GetLocale() or "enUS"
    UIDropDownMenu_SetSelectedValue(langDropdown, currentLang)
    local langName = Locale and Locale:GetLanguageName(currentLang) or currentLang
    UIDropDownMenu_SetText(langName, langDropdown)
    
    -- Open All Bags at Vendor checkbox (right side, same row)
    local openBagsLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    openBagsLabel:SetPoint("TOP", controllerTypeLabel, "TOP", 0, 0)
    openBagsLabel:SetPoint("RIGHT", generalBox, "RIGHT", -50, 0)
    openBagsLabel:SetText(T("Open all bags at vendor"))
    
    local openBagsCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), generalBox, "UICheckButtonTemplate")
    openBagsCheck:SetWidth(24)
    openBagsCheck:SetHeight(24)
    openBagsCheck:SetPoint("LEFT", openBagsLabel, "RIGHT", 5, 0)
    openBagsCheck.label = T("Open all bags at vendor")
    openBagsCheck.tooltipText = T("Automatically open all bags when interacting with merchants, auction house, or bank.")
    openBagsCheck:SetChecked(Config:Get("openAllBagsAtVendor"))
    openBagsCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("openAllBagsAtVendor", checked)
        if checked then
            CE_Debug("Open all bags at vendor ENABLED")
        else
            CE_Debug("Open all bags at vendor DISABLED")
        end
    end)
    
    -- Ensure dropdown buttons are navigable and have tooltips
    local generalDelayFrame = CreateFrame("Frame")
    generalDelayFrame:SetScript("OnUpdate", function()
        generalDelayFrame:Hide()
        local ctrlBtn = getglobal("CEConfigControllerTypeDropdownButton")
        if ctrlBtn then 
            ctrlBtn:Enable()
            ctrlBtn:Show()
            ctrlBtn.label = T("Controller Type")
            ctrlBtn.tooltipText = T("Select which controller button icons to display (Xbox or PlayStation style).")
        end
        local langBtn = getglobal("CEConfigLanguageDropdownButton")
        if langBtn then 
            langBtn:Enable()
            langBtn:Show()
            langBtn.label = T("Language")
            langBtn.tooltipText = T("Select the language for the addon interface. Requires a UI reload to take effect.")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    generalDelayFrame:Show()
    
    -- ==================== Crosshair Settings Box ====================
    local crosshairBox = self:CreateSectionBox(section, T("Crosshair"))
    crosshairBox:SetPoint("TOP", generalBox, "BOTTOM", 0, -30)
    
    -- ===== ROW 1: Enable, Type, Color (spread across width) =====
    
    -- Enable Crosshair checkbox (left)
    local crosshairCheck = self:CreateCheckbox(crosshairBox, T("Enable"), 
        function() return Config:Get("crosshairEnabled") end,
        function(checked)
            Config:Set("crosshairEnabled", checked)
            Config:UpdateCrosshair()
            if checked then
                CE_Debug("Crosshair ENABLED")
            else
                CE_Debug("Crosshair DISABLED")
            end
        end,
        T("Show a crosshair overlay in the center of the screen for easier targeting."))
    crosshairCheck:SetPoint("TOPLEFT", crosshairBox, "TOPLEFT", crosshairBox.contentLeft, crosshairBox.contentTop)
    
    -- Type dropdown (center)
    local typeLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeLabel:SetPoint("TOP", crosshairBox, "TOP", -80, crosshairBox.contentTop)
    typeLabel:SetText(T("Type") .. ":")
    
    local typeDropdown = CreateFrame("Frame", "CEConfigCrosshairTypeDropdown", crosshairBox, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", -15, -3)
    
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
    
    UIDropDownMenu_Initialize(typeDropdown, InitializeTypeDropdown)
    UIDropDownMenu_SetWidth(90, typeDropdown)
    local currentType = Config:Get("crosshairType") or "cross"
    UIDropDownMenu_SetSelectedValue(typeDropdown, currentType)
    UIDropDownMenu_SetText(currentType == "cross" and T("Cross") or T("Dot"), typeDropdown)
    
    -- Color button (right)
    local colorLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPRIGHT", crosshairBox, "TOPRIGHT", -100, crosshairBox.contentTop)
    colorLabel:SetText(T("Color") .. ":")
    
    local colorButton = CreateFrame("Button", "CEConfigCrosshairColor", crosshairBox)
    colorButton:SetWidth(60)
    colorButton:SetHeight(20)
    colorButton:SetPoint("LEFT", colorLabel, "RIGHT", 5, 0)
    colorButton.label = T("Crosshair Color")
    colorButton.tooltipText = T("Click to open the color picker and choose the crosshair color and opacity.")
    
    colorButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
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
        
        local delayFrame = CreateFrame("Frame")
        delayFrame:SetScript("OnUpdate", function()
            delayFrame:Hide()
            ColorPickerFrame:Show()
        end)
        delayFrame:Show()
    end)
    UpdateColorPreview()
    
    -- ===== ROW 2: Position controls (X, Y, Size) =====
    
    local xLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("TOPLEFT", crosshairCheck, "BOTTOMLEFT", 0, -15)
    xLabel:SetText(T("X Offset") .. ":")
    
    local xEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairX")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairX", num)
            Config:UpdateCrosshair()
        end,
        T("X Offset"),
        T("Horizontal offset from screen center. Negative values move left, positive values move right."))
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 5, 0)
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairX", num)
        Config:UpdateCrosshair()
    end)
    
    local yLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("LEFT", xEditBox, "RIGHT", 30, 0)
    yLabel:SetText(T("Y Offset") .. ":")
    
    local yEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairY")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("crosshairY", num)
            Config:UpdateCrosshair()
        end,
        T("Y Offset"),
        T("Vertical offset from screen center. Negative values move down, positive values move up."))
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 5, 0)
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("crosshairY", num)
        Config:UpdateCrosshair()
    end)
    
    local sizeLabel = crosshairBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("LEFT", yEditBox, "RIGHT", 30, 0)
    sizeLabel:SetText(T("Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(crosshairBox, 50, 
        function() return tostring(Config:Get("crosshairSize")) end,
        function(value)
            local num = tonumber(value) or 24
            if num < 4 then num = 4 end
            if num > 100 then num = 100 end
            Config:Set("crosshairSize", num)
            Config:UpdateCrosshair()
        end,
        T("Crosshair Size"),
        T("Size of the crosshair in pixels. Range: 4-100 pixels."))
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 5, 0)
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 24
        if num < 4 then num = 4 end
        if num > 100 then num = 100 end
        Config:Set("crosshairSize", num)
        Config:UpdateCrosshair()
    end)
    
    
    -- Ensure dropdown button is navigable and has tooltip
    local crosshairDelayFrame = CreateFrame("Frame")
    crosshairDelayFrame:SetScript("OnUpdate", function()
        crosshairDelayFrame:Hide()
        local dropdownButton = getglobal("CEConfigCrosshairTypeDropdownButton")
        if dropdownButton then
            dropdownButton:Enable()
            dropdownButton:Show()
            dropdownButton.label = T("Crosshair Type")
            dropdownButton.tooltipText = T("Choose the crosshair style: Cross shows a traditional + shape, Dot shows a single circular dot.")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    crosshairDelayFrame:Show()
    
    -- ==================== Keybindings Settings Box ====================
    local keybindingsBox = self:CreateSectionBox(section, T("Keybindings"))
    keybindingsBox:SetPoint("TOP", crosshairBox, "BOTTOM", 0, -30)
    
    -- Use A for Jump checkbox (top row)
    local jumpCheck = self:CreateCheckbox(keybindingsBox, T("Use A button for Jump"), 
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
        end,
        T("When enabled, pressing the A button (key 1) will jump. When disabled, it will use whatever action is in slot 1 of the action bar."))
    jumpCheck:SetPoint("TOPLEFT", keybindingsBox, "TOPLEFT", keybindingsBox.contentLeft, keybindingsBox.contentTop)
    
    -- Reset Default Bindings button (bottom left)
    local resetBindingsButton = CreateFrame("Button", "CEConfigResetBindings", keybindingsBox, "UIPanelButtonTemplate")
    resetBindingsButton:SetWidth(160)
    resetBindingsButton:SetHeight(24)
    resetBindingsButton:SetPoint("TOPLEFT", jumpCheck, "BOTTOMLEFT", 0, -15)
    resetBindingsButton:SetText(T("Reset Bindings"))
    resetBindingsButton.label = T("Reset Default Bindings")
    resetBindingsButton.tooltipText = T("Resets all keybindings to default (1-0 keys) and places default macros (Target) on the action bar.")
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
    
    -- Show Placement Frame button (bottom right, same row as reset button)
    local showPlacementButton = CreateFrame("Button", "CEConfigShowPlacement", keybindingsBox, "UIPanelButtonTemplate")
    showPlacementButton:SetWidth(160)
    showPlacementButton:SetHeight(24)
    showPlacementButton:SetPoint("TOP", resetBindingsButton, "TOP", 0, 0)
    showPlacementButton:SetPoint("RIGHT", keybindingsBox, "RIGHT", keybindingsBox.contentRight, 0)
    showPlacementButton:SetText(T("Spell Placement"))
    showPlacementButton.label = T("Show Placement Frame")
    showPlacementButton.tooltipText = T("Opens the spell placement frame where you can drag and drop spells, macros, and items onto action bar slots.")
    showPlacementButton:SetScript("OnClick", function()
        if ConsoleExperience.placement then
            -- Show placement frame and close config frame
            ConsoleExperience.placement:Show()
            Config:Hide()
        else
            CE_Debug("Placement module not loaded!")
        end
    end)
    
    -- ==================== Chat Settings Box ====================
    local chatBox = self:CreateSectionBox(section, T("Chat"))
    chatBox:SetPoint("TOP", keybindingsBox, "BOTTOM", 0, -30)
    
    -- Row 1: Width, Height inputs and Reset button
    local chatWidthLabel = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatWidthLabel:SetPoint("TOPLEFT", chatBox, "TOPLEFT", chatBox.contentLeft, chatBox.contentTop)
    chatWidthLabel:SetText(T("Width") .. ":")
    
    local chatWidthEditBox = self:CreateEditBox(chatBox, 50, 
        function() return tostring(Config:Get("chatWidth")) end,
        function(value)
            local num = tonumber(value) or 400
            if num < 100 then num = 100 end
            if num > 2000 then num = 2000 end
            Config:Set("chatWidth", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
        end,
        T("Chat Width"),
        T("Width of the chat frame in pixels. Range: 100-2000."))
    chatWidthEditBox:SetPoint("LEFT", chatWidthLabel, "RIGHT", 5, 0)
    
    local chatHeightLabel = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatHeightLabel:SetPoint("LEFT", chatWidthEditBox, "RIGHT", 30, 0)
    chatHeightLabel:SetText(T("Height") .. ":")
    
    local chatHeightEditBox = self:CreateEditBox(chatBox, 50, 
        function() return tostring(Config:Get("chatHeight")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("chatHeight", num)
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("Chat Height"),
        T("Height of the chat frame in pixels. Range: 50-1000."))
    chatHeightEditBox:SetPoint("LEFT", chatHeightLabel, "RIGHT", 5, 0)
    
    -- Reset Chat button (right side of row 1)
    local resetChatButton = CreateFrame("Button", "CEConfigResetChat", chatBox, "UIPanelButtonTemplate")
    resetChatButton:SetWidth(100)
    resetChatButton:SetHeight(24)
    resetChatButton:SetPoint("TOP", chatWidthLabel, "TOP", 0, 2)
    resetChatButton:SetPoint("RIGHT", chatBox, "RIGHT", chatBox.contentRight, 0)
    resetChatButton:SetText(T("Reset"))
    resetChatButton.label = T("Reset Chat Settings")
    resetChatButton.tooltipText = T("Reset chat width, height, and keyboard settings to defaults.")
    
    -- Row 2: Virtual Keyboard toggle
    local keyboardCheck = self:CreateCheckbox(chatBox, T("Enable Virtual Keyboard"), 
        function() return Config:Get("keyboardEnabled") end,
        function(checked)
            Config:Set("keyboardEnabled", checked)
            CE_Debug("Virtual keyboard " .. (checked and "enabled" or "disabled"))
            if not checked and ConsoleExperience.keyboard and ConsoleExperience.keyboard:IsVisible() then
                ConsoleExperience.keyboard:Hide()
            end
            if not checked and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:EnableKeyboard(true)
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
        end,
        T("When enabled, a virtual keyboard appears when typing in chat. Disable to use an external keyboard."))
    keyboardCheck:SetPoint("TOPLEFT", chatWidthLabel, "BOTTOMLEFT", 0, -15)
    resetChatButton:SetScript("OnClick", function()
        Config:Set("chatWidth", Config.DEFAULTS.chatWidth)
        Config:Set("chatHeight", Config.DEFAULTS.chatHeight)
        Config:Set("keyboardEnabled", Config.DEFAULTS.keyboardEnabled)
        if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
            ConsoleExperience.chat:UpdateChatLayout()
        end
        chatWidthEditBox:SetText(tostring(Config.DEFAULTS.chatWidth))
        chatHeightEditBox:SetText(tostring(Config.DEFAULTS.chatHeight))
        keyboardCheck:SetChecked(Config.DEFAULTS.keyboardEnabled)
        CE_Debug("Chat settings reset to defaults")
    end)
    
    self.contentSections["interface"] = section
end

function Config:CreateBarsSection()
    local content = self.frame.content
    local Locale = ConsoleExperience.locale
    local T = Locale and Locale.T or function(key) return key end
    
    local section = CreateFrame("Frame", nil, content)
    section:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -5)
    section:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -5, 5)
    section:Hide()
    
    -- ==================== General Action Bars Box ====================
    local generalBox = self:CreateSectionBox(section, T("General Action Bars"))
    generalBox:SetPoint("TOP", section, "TOP", 0, -25)
    
    -- Row 1: Appearance dropdown (left) and Auto-rank checkbox (right)
    local appearanceLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    appearanceLabel:SetPoint("TOPLEFT", generalBox, "TOPLEFT", generalBox.contentLeft, generalBox.contentTop)
    appearanceLabel:SetText(T("Appearance") .. ":")
    
    local appearanceDropdown = CreateFrame("Frame", "CEConfigBarAppearanceDropdown", generalBox, "UIDropDownMenuTemplate")
    appearanceDropdown:SetPoint("LEFT", appearanceLabel, "RIGHT", -15, -3)
    
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
        if info.value == selectedValue then info.checked = 1 end
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
        if info.value == selectedValue then info.checked = 1 end
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(appearanceDropdown, InitializeAppearanceDropdown)
    UIDropDownMenu_SetWidth(100, appearanceDropdown)
    local currentAppearance = Config:Get("barAppearance") or "classic"
    UIDropDownMenu_SetSelectedValue(appearanceDropdown, currentAppearance)
    UIDropDownMenu_SetText(currentAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
    
    -- Auto-rank label and checkbox (right side of row 1, label on left of toggle)
    local autoRankLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoRankLabel:SetPoint("TOP", appearanceLabel, "TOP", 0, 0)
    autoRankLabel:SetPoint("RIGHT", generalBox, "RIGHT", -50, 0)
    autoRankLabel:SetText(T("Auto-update spell ranks"))
    
    local autoRankCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), generalBox, "UICheckButtonTemplate")
    autoRankCheck:SetWidth(24)
    autoRankCheck:SetHeight(24)
    autoRankCheck:SetPoint("LEFT", autoRankLabel, "RIGHT", 5, 0)
    autoRankCheck.label = T("Auto-update spell ranks")
    autoRankCheck.tooltipText = T("When enabled, spells on action bars will automatically be updated to the highest rank when you learn a new spell rank.")
    autoRankCheck:SetChecked(Config:Get("autoRankEnabled"))
    autoRankCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("autoRankEnabled", checked)
    end)
    
    -- Row 2: Positioning options (Size, Pad, X, Y, Star, Scale) + Reset button
    local sizeLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("TOPLEFT", appearanceLabel, "BOTTOMLEFT", 0, -15)
    sizeLabel:SetText(T("Size") .. ":")
    
    local sizeEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barButtonSize")) end,
        function(value)
            local num = tonumber(value) or 40
            if num < 20 then num = 20 end
            if num > 80 then num = 80 end
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end,
        T("Button Size"),
        T("Size of action bar buttons in pixels. Range: 20-80."))
    sizeEditBox:SetPoint("LEFT", sizeLabel, "RIGHT", 5, 0)
    sizeEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 40
        if num >= 20 and num <= 80 then
            Config:Set("barButtonSize", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local padLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    padLabel:SetPoint("LEFT", sizeEditBox, "RIGHT", 10, 0)
    padLabel:SetText(T("Pad") .. ":")
    
    local paddingEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barPadding")) end,
        function(value)
            local num = tonumber(value) or 4
            if num < 0 then num = 0 end
            if num > 100 then num = 100 end
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end,
        T("Button Padding"),
        T("Space between buttons in pixels. Range: 0-100."))
    paddingEditBox:SetPoint("LEFT", padLabel, "RIGHT", 5, 0)
    paddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 4
        if num >= 0 and num <= 100 then
            Config:Set("barPadding", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local xLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xLabel:SetPoint("LEFT", paddingEditBox, "RIGHT", 10, 0)
    xLabel:SetText("X:")
    
    local xEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barXOffset")) end,
        function(value)
            local num = tonumber(value) or 0
            Config:Set("barXOffset", num)
            Config:UpdateActionBarLayout()
        end,
        T("X Offset"),
        T("Horizontal offset from screen center."))
    xEditBox:SetPoint("LEFT", xLabel, "RIGHT", 5, 0)
    xEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 0
        Config:Set("barXOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    local yLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLabel:SetPoint("LEFT", xEditBox, "RIGHT", 10, 0)
    yLabel:SetText("Y:")
    
    local yEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barYOffset")) end,
        function(value)
            local num = tonumber(value) or 70
            Config:Set("barYOffset", num)
            Config:UpdateActionBarLayout()
        end,
        T("Y Offset"),
        T("Vertical offset from screen bottom."))
    yEditBox:SetPoint("LEFT", yLabel, "RIGHT", 5, 0)
    yEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 70
        Config:Set("barYOffset", num)
        Config:UpdateActionBarLayout()
    end)
    
    local starLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    starLabel:SetPoint("LEFT", yEditBox, "RIGHT", 10, 0)
    starLabel:SetText(T("Gap") .. ":")
    
    local starPaddingEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barStarPadding")) end,
        function(value)
            local num = tonumber(value) or 200
            if num < 50 then num = 50 end
            if num > 1000 then num = 1000 end
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end,
        T("Center Gap"),
        T("Space between left and right button groups. Range: 50-1000."))
    starPaddingEditBox:SetPoint("LEFT", starLabel, "RIGHT", 5, 0)
    starPaddingEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 200
        if num >= 50 and num <= 1000 then
            Config:Set("barStarPadding", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    local scaleLabel = generalBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetPoint("LEFT", starPaddingEditBox, "RIGHT", 10, 0)
    scaleLabel:SetText(T("Scale") .. ":")
    
    local scaleEditBox = self:CreateEditBox(generalBox, 35,
        function() return tostring(Config:Get("barScale")) end,
        function(value)
            local num = tonumber(value) or 1.0
            if num < 0.5 then num = 0.5 end
            if num > 2.0 then num = 2.0 end
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end,
        T("Scale"),
        T("Overall scale of action bars. Range: 0.5-2.0."))
    scaleEditBox:SetPoint("LEFT", scaleLabel, "RIGHT", 5, 0)
    scaleEditBox:SetScript("OnTextChanged", function()
        local num = tonumber(this:GetText()) or 1.0
        if num >= 0.5 and num <= 2.0 then
            Config:Set("barScale", num)
            Config:UpdateActionBarLayout()
        end
    end)
    
    -- Row 3: Reset button (left) and Update Spell Ranks button (right)
    local resetButton = CreateFrame("Button", "CEConfigResetLayout", generalBox, "UIPanelButtonTemplate")
    resetButton:SetWidth(100)
    resetButton:SetHeight(22)
    resetButton:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -15)
    resetButton:SetText(T("Reset"))
    resetButton.label = T("Reset Layout")
    resetButton.tooltipText = T("Reset all action bar settings to defaults.")
    resetButton:SetScript("OnClick", function()
        Config:Set("barButtonSize", Config.DEFAULTS.barButtonSize)
        Config:Set("barPadding", Config.DEFAULTS.barPadding)
        Config:Set("barStarPadding", Config.DEFAULTS.barStarPadding)
        Config:Set("barXOffset", Config.DEFAULTS.barXOffset)
        Config:Set("barYOffset", Config.DEFAULTS.barYOffset)
        Config:Set("barScale", Config.DEFAULTS.barScale)
        Config:Set("barAppearance", Config.DEFAULTS.barAppearance)
        Config:UpdateActionBarLayout()
        sizeEditBox:SetText(tostring(Config.DEFAULTS.barButtonSize))
        paddingEditBox:SetText(tostring(Config.DEFAULTS.barPadding))
        starPaddingEditBox:SetText(tostring(Config.DEFAULTS.barStarPadding))
        xEditBox:SetText(tostring(Config.DEFAULTS.barXOffset))
        yEditBox:SetText(tostring(Config.DEFAULTS.barYOffset))
        scaleEditBox:SetText(tostring(Config.DEFAULTS.barScale))
        local defAppearance = Config.DEFAULTS.barAppearance or "classic"
        UIDropDownMenu_SetSelectedValue(appearanceDropdown, defAppearance)
        UIDropDownMenu_SetText(defAppearance == "classic" and T("Classic") or T("Modern"), appearanceDropdown)
        CE_Debug("Action bar layout reset to defaults")
    end)
    
    local updateRanksButton = CreateFrame("Button", "CEConfigUpdateRanks", generalBox, "UIPanelButtonTemplate")
    updateRanksButton:SetWidth(140)
    updateRanksButton:SetHeight(22)
    updateRanksButton:SetPoint("TOP", resetButton, "TOP", 0, 0)
    updateRanksButton:SetPoint("RIGHT", generalBox, "RIGHT", generalBox.contentRight, 0)
    updateRanksButton:SetText(T("Update Spell Ranks"))
    updateRanksButton.label = T("Update Spell Ranks")
    updateRanksButton.tooltipText = T("Manually update all spells on action bars to their highest learned rank.")
    updateRanksButton:SetScript("OnClick", function()
        if ConsoleExperience.autorank and ConsoleExperience.autorank.ManualUpdate then
            ConsoleExperience.autorank:ManualUpdate()
        end
    end)
    
    -- Ensure dropdown button is navigable
    local barsDelayFrame = CreateFrame("Frame")
    barsDelayFrame:SetScript("OnUpdate", function()
        barsDelayFrame:Hide()
        local btn = getglobal("CEConfigBarAppearanceDropdownButton")
        if btn then
            btn:Enable()
            btn:Show()
            btn.label = T("Appearance")
            btn.tooltipText = T("Choose the visual style of action bar buttons: Classic (traditional WoW look) or Modern (cleaner style).")
        end
        if ConsoleExperience.cursor and ConsoleExperience.cursor.RefreshFrame then
            ConsoleExperience.cursor:RefreshFrame()
        end
    end)
    barsDelayFrame:Show()
    
    -- ==================== Left Side Bar Box ====================
    local leftSideBox = self:CreateSectionBox(section, T("Left Action Bar (Touch)"))
    leftSideBox:ClearAllPoints()
    leftSideBox:SetPoint("TOPLEFT", generalBox, "BOTTOMLEFT", 0, -30)
    leftSideBox:SetPoint("RIGHT", section, "CENTER", -10, 0)
    leftSideBox:SetHeight(70)
    leftSideBox.heightCalculated = true  -- Don't auto-calculate
    
    local leftBarCheck = self:CreateCheckbox(leftSideBox, T("Enable"),
        function() return Config:Get("sideBarLeftEnabled") end,
        function(checked)
            Config:Set("sideBarLeftEnabled", checked)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
        end,
        T("Enable vertical action bar on the left edge of the screen for touch input."))
    leftBarCheck:SetPoint("TOPLEFT", leftSideBox, "TOPLEFT", leftSideBox.contentLeft, leftSideBox.contentTop)
    
    local leftCountLabel = leftSideBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    leftCountLabel:SetPoint("LEFT", leftBarCheck, "RIGHT", 60, 0)
    leftCountLabel:SetText(T("Buttons") .. ":")
    
    local leftCountEditBox = self:CreateEditBox(leftSideBox, 30,
        function() return tostring(Config:Get("sideBarLeftButtons") or 3) end,
        function(value)
            local num = tonumber(value) or 3
            if num < 1 then num = 1 end
            if num > 5 then num = 5 end
            Config:Set("sideBarLeftButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
        end,
        T("Left Bar Buttons"),
        T("Number of buttons on the left side bar. Range: 1-5."))
    leftCountEditBox:SetPoint("LEFT", leftCountLabel, "RIGHT", 5, 0)
    
    -- ==================== Right Side Bar Box ====================
    local rightSideBox = self:CreateSectionBox(section, T("Right Action Bar (Touch)"))
    rightSideBox:ClearAllPoints()
    rightSideBox:SetPoint("TOPRIGHT", generalBox, "BOTTOMRIGHT", 0, -30)
    rightSideBox:SetPoint("LEFT", section, "CENTER", 10, 0)
    rightSideBox:SetHeight(70)
    rightSideBox.heightCalculated = true  -- Don't auto-calculate
    
    local rightBarCheck = self:CreateCheckbox(rightSideBox, T("Enable"),
        function() return Config:Get("sideBarRightEnabled") end,
        function(checked)
            Config:Set("sideBarRightEnabled", checked)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
        end,
        T("Enable vertical action bar on the right edge of the screen for touch input."))
    rightBarCheck:SetPoint("TOPLEFT", rightSideBox, "TOPLEFT", rightSideBox.contentLeft, rightSideBox.contentTop)
    
    local rightCountLabel = rightSideBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rightCountLabel:SetPoint("LEFT", rightBarCheck, "RIGHT", 60, 0)
    rightCountLabel:SetText(T("Buttons") .. ":")
    
    local rightCountEditBox = self:CreateEditBox(rightSideBox, 30,
        function() return tostring(Config:Get("sideBarRightButtons") or 3) end,
        function(value)
            local num = tonumber(value) or 3
            if num < 1 then num = 1 end
            if num > 5 then num = 5 end
            Config:Set("sideBarRightButtons", num)
            if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
                ConsoleExperience.actionbars:UpdateSideBars()
            end
        end,
        T("Right Bar Buttons"),
        T("Number of buttons on the right side bar. Range: 1-5."))
    rightCountEditBox:SetPoint("LEFT", rightCountLabel, "RIGHT", 5, 0)
    
    -- ==================== XP Bar Box ====================
    local xpBox = self:CreateSectionBox(section, T("XP Bar"))
    xpBox:ClearAllPoints()
    xpBox:SetPoint("TOPLEFT", leftSideBox, "BOTTOMLEFT", 0, -30)
    xpBox:SetPoint("RIGHT", section, "CENTER", -10, 0)
    xpBox:SetHeight(95)
    xpBox.heightCalculated = true  -- Don't auto-calculate
    
    -- Row 1: Always Visible and Text checkboxes
    local xpAlwaysCheck = self:CreateCheckbox(xpBox, T("Always Visible"),
        function() return Config:Get("xpBarAlways") or false end,
        function(checked)
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
        end,
        T("When enabled, the XP bar is always visible instead of fading out."))
    xpAlwaysCheck:SetPoint("TOPLEFT", xpBox, "TOPLEFT", xpBox.contentLeft, xpBox.contentTop)
    
    local xpTextLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTextLabel:SetPoint("TOP", xpAlwaysCheck, "TOP", 0, 0)
    xpTextLabel:SetPoint("RIGHT", xpBox, "RIGHT", -50, 0)
    xpTextLabel:SetText(T("Text"))
    
    local xpTextShowCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), xpBox, "UICheckButtonTemplate")
    xpTextShowCheck:SetWidth(24)
    xpTextShowCheck:SetHeight(24)
    xpTextShowCheck:SetPoint("LEFT", xpTextLabel, "RIGHT", 5, 0)
    xpTextShowCheck.label = T("XP Text")
    xpTextShowCheck.tooltipText = T("Show XP text on the bar.")
    local xpTextValue = Config:Get("xpBarTextShow")
    xpTextShowCheck:SetChecked(xpTextValue == nil and true or xpTextValue)
    xpTextShowCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("xpBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.xpBar, "XP")
            if ConsoleExperience.xpbar.xpBar.always then
                event = "PLAYER_XP_UPDATE"
                ConsoleExperience.xpbar.xpBar:GetScript("OnEvent")(ConsoleExperience.xpbar.xpBar)
            end
            if ConsoleExperience.xpbar.xpBar.bar and ConsoleExperience.xpbar.xpBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.xpBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.xpBar.bar.text:Hide()
                end
            end
        end
    end)
    
    -- Row 2: Width, Height, Timeout
    local xpWidthLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpWidthLabel:SetPoint("TOPLEFT", xpAlwaysCheck, "BOTTOMLEFT", 0, -10)
    xpWidthLabel:SetText(T("Width") .. ":")
    
    local xpWidthEditBox = self:CreateEditBox(xpBox, 40,
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
        end,
        T("XP Bar Width"),
        T("Width of XP bar in pixels. Set to 0 to match chat width."))
    xpWidthEditBox:SetPoint("LEFT", xpWidthLabel, "RIGHT", 5, 0)
    
    local xpHeightLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpHeightLabel:SetPoint("LEFT", xpWidthEditBox, "RIGHT", 10, 0)
    xpHeightLabel:SetText(T("Height") .. ":")
    
    local xpHeightEditBox = self:CreateEditBox(xpBox, 30,
        function() return tostring(Config:Get("xpBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("xpBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("XP Bar Height"),
        T("Height of XP bar in pixels. Range: 20-100."))
    xpHeightEditBox:SetPoint("LEFT", xpHeightLabel, "RIGHT", 5, 0)
    
    local xpTimeoutLabel = xpBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    xpTimeoutLabel:SetPoint("LEFT", xpHeightEditBox, "RIGHT", 10, 0)
    xpTimeoutLabel:SetText(T("Timeout") .. ":")
    
    local xpTimeoutEditBox = self:CreateEditBox(xpBox, 30,
        function() return tostring(Config:Get("xpBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("xpBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.xpBar then
                ConsoleExperience.xpbar.xpBar.timeout = num
            end
        end,
        T("XP Bar Timeout"),
        T("Seconds before the bar fades out. Range: 0-60."))
    xpTimeoutEditBox:SetPoint("LEFT", xpTimeoutLabel, "RIGHT", 5, 0)
    
    -- ==================== Rep Bar Box ====================
    local repBox = self:CreateSectionBox(section, T("Rep Bar"))
    repBox:ClearAllPoints()
    repBox:SetPoint("TOPRIGHT", rightSideBox, "BOTTOMRIGHT", 0, -30)
    repBox:SetPoint("LEFT", section, "CENTER", 10, 0)
    repBox:SetHeight(95)
    repBox.heightCalculated = true  -- Don't auto-calculate
    
    -- Row 1: Always Visible and Text checkboxes
    local repAlwaysCheck = self:CreateCheckbox(repBox, T("Always Visible"),
        function() return Config:Get("repBarAlways") or false end,
        function(checked)
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
        end,
        T("When enabled, the Reputation bar is always visible instead of fading out."))
    repAlwaysCheck:SetPoint("TOPLEFT", repBox, "TOPLEFT", repBox.contentLeft, repBox.contentTop)
    
    local repTextLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repTextLabel:SetPoint("TOP", repAlwaysCheck, "TOP", 0, 0)
    repTextLabel:SetPoint("RIGHT", repBox, "RIGHT", -50, 0)
    repTextLabel:SetText(T("Text"))
    
    local repTextShowCheck = CreateFrame("CheckButton", self:GetNextElementName("Check"), repBox, "UICheckButtonTemplate")
    repTextShowCheck:SetWidth(24)
    repTextShowCheck:SetHeight(24)
    repTextShowCheck:SetPoint("LEFT", repTextLabel, "RIGHT", 5, 0)
    repTextShowCheck.label = T("Rep Text")
    repTextShowCheck.tooltipText = T("Show Reputation text on the bar.")
    local repTextValue = Config:Get("repBarTextShow")
    repTextShowCheck:SetChecked(repTextValue == nil and true or repTextValue)
    repTextShowCheck:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        Config:Set("repBarTextShow", checked)
        if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
            ConsoleExperience.xpbar.repBar.text_show = checked
            ConsoleExperience.xpbar:ReloadBarConfig(ConsoleExperience.xpbar.repBar, "REP")
            if ConsoleExperience.xpbar.repBar.always then
                event = "UPDATE_FACTION"
                ConsoleExperience.xpbar.repBar:GetScript("OnEvent")(ConsoleExperience.xpbar.repBar)
            end
            if ConsoleExperience.xpbar.repBar.bar and ConsoleExperience.xpbar.repBar.bar.text then
                if checked then
                    ConsoleExperience.xpbar.repBar.bar.text:Show()
                else
                    ConsoleExperience.xpbar.repBar.bar.text:Hide()
                end
            end
        end
    end)
    
    -- Row 2: Width, Height, Timeout
    local repWidthLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repWidthLabel:SetPoint("TOPLEFT", repAlwaysCheck, "BOTTOMLEFT", 0, -10)
    repWidthLabel:SetText(T("Width") .. ":")
    
    local repWidthEditBox = self:CreateEditBox(repBox, 40,
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
        end,
        T("Rep Bar Width"),
        T("Width of Reputation bar in pixels. Set to 0 to match chat width."))
    repWidthEditBox:SetPoint("LEFT", repWidthLabel, "RIGHT", 5, 0)
    
    local repHeightLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repHeightLabel:SetPoint("LEFT", repWidthEditBox, "RIGHT", 10, 0)
    repHeightLabel:SetText(T("Height") .. ":")
    
    local repHeightEditBox = self:CreateEditBox(repBox, 30,
        function() return tostring(Config:Get("repBarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("repBarHeight", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.UpdateAllBars then
                ConsoleExperience.xpbar:UpdateAllBars()
            end
            if ConsoleExperience.chat and ConsoleExperience.chat.UpdateChatLayout then
                ConsoleExperience.chat:UpdateChatLayout()
            end
        end,
        T("Rep Bar Height"),
        T("Height of Reputation bar in pixels. Range: 20-100."))
    repHeightEditBox:SetPoint("LEFT", repHeightLabel, "RIGHT", 5, 0)
    
    local repTimeoutLabel = repBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    repTimeoutLabel:SetPoint("LEFT", repHeightEditBox, "RIGHT", 10, 0)
    repTimeoutLabel:SetText(T("Timeout") .. ":")
    
    local repTimeoutEditBox = self:CreateEditBox(repBox, 30,
        function() return tostring(Config:Get("repBarTimeout") or 5.0) end,
        function(value)
            local num = tonumber(value) or 5.0
            if num < 0 then num = 0 end
            if num > 60 then num = 60 end
            Config:Set("repBarTimeout", num)
            if ConsoleExperience.xpbar and ConsoleExperience.xpbar.repBar then
                ConsoleExperience.xpbar.repBar.timeout = num
            end
        end,
        T("Rep Bar Timeout"),
        T("Seconds before the bar fades out. Range: 0-60."))
    repTimeoutEditBox:SetPoint("LEFT", repTimeoutLabel, "RIGHT", 5, 0)
    
    -- ==================== Cast Bar Box ====================
    local castBox = self:CreateSectionBox(section, T("Cast Bar"))
    castBox:ClearAllPoints()
    castBox:SetPoint("TOPLEFT", xpBox, "BOTTOMLEFT", 0, -30)
    castBox:SetPoint("RIGHT", section, "RIGHT", -5, 0)
    
    -- Row 1: Enable checkbox, Height, Color button
    local castEnabledCheck = self:CreateCheckbox(castBox, T("Enable"),
        function() return Config:Get("castbarEnabled") end,
        function(checked)
            Config:Set("castbarEnabled", checked)
            if ConsoleExperience.castbar and ConsoleExperience.castbar.ReloadConfig then
                ConsoleExperience.castbar:ReloadConfig()
            end
        end,
        T("Enable the custom cast bar that appears above chat."))
    castEnabledCheck:SetPoint("TOPLEFT", castBox, "TOPLEFT", castBox.contentLeft, castBox.contentTop)
    
    local castHeightLabel = castBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castHeightLabel:SetPoint("LEFT", castEnabledCheck, "RIGHT", 60, 0)
    castHeightLabel:SetText(T("Height") .. ":")
    
    local castHeightEditBox = self:CreateEditBox(castBox, 35,
        function() return tostring(Config:Get("castbarHeight") or 20) end,
        function(value)
            local num = tonumber(value) or 20
            if num < 20 then num = 20 end
            if num > 100 then num = 100 end
            Config:Set("castbarHeight", num)
            if ConsoleExperience.castbar and ConsoleExperience.castbar.UpdatePosition then
                ConsoleExperience.castbar:UpdatePosition()
            end
        end,
        T("Cast Bar Height"),
        T("Height of cast bar in pixels. Range: 20-100."))
    castHeightEditBox:SetPoint("LEFT", castHeightLabel, "RIGHT", 5, 0)
    
    local castColorLabel = castBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castColorLabel:SetPoint("LEFT", castHeightEditBox, "RIGHT", 20, 0)
    castColorLabel:SetText(T("Color") .. ":")
    
    local castColorBtn = CreateFrame("Button", self:GetNextElementName("ColorBtn"), castBox)
    castColorBtn:SetWidth(40)
    castColorBtn:SetHeight(20)
    castColorBtn:SetPoint("LEFT", castColorLabel, "RIGHT", 5, 0)
    castColorBtn.label = T("Cast Bar Color")
    castColorBtn.tooltipText = T("Click to choose the cast bar fill color.")
    
    local castColorPreview = castColorBtn:CreateTexture(nil, "BACKGROUND")
    castColorPreview:SetAllPoints()
    
    local function UpdateCastColorPreview()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        castColorPreview:SetTexture(r, g, b)
    end
    UpdateCastColorPreview()
    
    castColorBtn:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    castColorBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    castColorBtn:SetScript("OnClick", function()
        local r = Config:Get("castbarColorR") or 0.0
        local g = Config:Get("castbarColorG") or 0.5
        local b = Config:Get("castbarColorB") or 1.0
        
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
            UpdateCastColorPreview()
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
    
    self.contentSections["bars"] = section
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

-- Create a section box with title (like UIOptionsFrame's OptionFrameBoxTemplate)
-- If height is nil, call box:CalculateHeight() after adding all children
function Config:CreateSectionBox(parent, title, height)
    local name = self:GetNextElementName("Section")
    local box = CreateFrame("Frame", name, parent)
    box:SetHeight(height or 50)  -- Initial height, will be recalculated if needed
    
    -- Use anchor points for full width (5px padding on each side)
    box:SetPoint("LEFT", parent, "LEFT", 5, 0)
    box:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
    
    -- Backdrop (like OptionFrameBoxTemplate)
    box:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 1.0)
    box:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
    
    -- Title (positioned ABOVE the box, not overlapping the border)
    local titleText = parent:CreateFontString(name .. "Title", "OVERLAY", "GameFontNormal")
    titleText:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 5, 2)
    titleText:SetText(title)
    titleText:SetTextColor(1, 1, 1, 1)  -- White text
    box.title = titleText
    
    -- Content inset (area inside the box for controls)
    box.contentTop = -18  -- Y offset from box top for content (more padding)
    box.contentLeft = 15  -- X offset from box left for content
    box.contentRight = -15  -- X offset from box right for content
    box.bottomPadding = 15  -- Padding at the bottom of the box
    
    -- Method to calculate height based on children (call after layout settles)
    -- Only calculates once to prevent growing on repeated calls
    box.CalculateHeight = function(self)
        -- Only calculate once
        if self.heightCalculated then return end
        
        local boxTop = self:GetTop()
        if not boxTop then return end
        
        local lowestPoint = boxTop  -- Start at top
        
        -- Scan all child frames
        local children = {self:GetChildren()}
        for _, child in ipairs(children) do
            local bottom = child:GetBottom()
            if bottom and bottom < lowestPoint then
                lowestPoint = bottom
            end
        end
        
        -- Also scan font strings (they're not frames)
        local regions = {self:GetRegions()}
        for _, region in ipairs(regions) do
            if region.GetBottom then
                local bottom = region:GetBottom()
                if bottom and bottom < lowestPoint then
                    lowestPoint = bottom
                end
            end
        end
        
        -- Calculate needed height
        local neededHeight = (boxTop - lowestPoint) + self.bottomPadding
        if neededHeight < 40 then neededHeight = 40 end  -- Minimum height
        
        self:SetHeight(neededHeight)
        self.heightCalculated = true
    end
    
    return box
end

function Config:CreateCheckbox(parent, label, getFunc, setFunc, tooltipText)
    local name = self:GetNextElementName("Check")
    local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    
    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", check, "RIGHT", 5, 0)
    text:SetText(label)
    
    -- Store label for tooltip/debug
    check.label = label
    -- Store tooltip help text
    check.tooltipText = tooltipText
    
    -- Set initial state
    check:SetChecked(getFunc())
    
    -- Click handler
    check:SetScript("OnClick", function()
        local checked = this:GetChecked() == 1
        setFunc(checked)
    end)
    
    return check
end

function Config:CreateEditBox(parent, width, getFunc, setFunc, label, tooltipText)
    local name = self:GetNextElementName("Edit")
    local editBox = CreateFrame("EditBox", name, parent)
    editBox:SetWidth(width)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetJustifyH("CENTER")
    
    -- Store label and tooltip for cursor tooltip
    editBox.label = label or "Text Input"
    editBox.tooltipText = tooltipText
    
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
        
        -- Recalculate box heights after layout settles
        local calcFrame = CreateFrame("Frame")
        calcFrame.section = self.contentSections[sectionId]
        calcFrame:SetScript("OnUpdate", function()
            this:Hide()
            local section = this.section
            -- Find all boxes in this section and recalculate their heights
            local children = {section:GetChildren()}
            for _, child in ipairs(children) do
                if child.CalculateHeight then
                    child:CalculateHeight()
                end
            end
        end)
        calcFrame:Show()
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
    
    -- Update side action bars to match new settings
    if ConsoleExperience.actionbars and ConsoleExperience.actionbars.UpdateSideBars then
        ConsoleExperience.actionbars:UpdateSideBars()
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

