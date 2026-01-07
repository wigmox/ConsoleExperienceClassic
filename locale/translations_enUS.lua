--[[
    ConsoleExperienceClassic - English (US) Translations
]]

-- Initialize translation table if it doesn't exist
if not ConsoleExperience_translation then
    ConsoleExperience_translation = {}
end

ConsoleExperience_translation["enUS"] = {
    -- General
    ["General"] = "General",
    ["General Settings"] = "General Settings",
    ["Configure general addon settings."] = "Configure general addon settings.",
    ["Enable Debug Output"] = "Enable Debug Output",
    ["Version"] = "Version",
    
    -- Interface
    ["Interface"] = "Interface",
    ["Interface Settings"] = "Interface Settings",
    ["Configure interface elements."] = "Configure interface elements.",
    ["Enable Crosshair"] = "Enable Crosshair",
    ["Crosshair X Offset"] = "Crosshair X Offset",
    ["Crosshair Y Offset"] = "Crosshair Y Offset",
    ["Crosshair Size"] = "Crosshair Size",
    ["Crosshair Type"] = "Crosshair Type",
    ["Crosshair Color"] = "Crosshair Color",
    ["Cross"] = "Cross",
    ["Dot"] = "Dot",
    ["Controller Type"] = "Controller Type",
    ["X/Y offset from screen center. Use negative values to move left/down. Size: 4-100 pixels. Type: Cross shows lines, Dot shows only center dot."] = "X/Y offset from screen center. Use negative values to move left/down. Size: 4-100 pixels. Type: Cross shows lines, Dot shows only center dot.",
    
    -- XP/Rep Bars
    ["XP/Reputation Bars"] = "XP/Reputation Bars",
    ["Configure experience and reputation bars. Bars appear below chat and fade out after timeout."] = "Configure experience and reputation bars. Bars appear below chat and fade out after timeout.",
    ["XP Bar Always Visible"] = "XP Bar Always Visible",
    ["XP Bar Width"] = "XP Bar Width",
    ["XP Bar Height"] = "XP Bar Height",
    ["XP Bar Timeout"] = "XP Bar Timeout",
    ["XP Bar Text Show"] = "XP Bar Text Show",
    ["Reputation Bar Always Visible"] = "Reputation Bar Always Visible",
    ["Reputation Bar Width"] = "Reputation Bar Width",
    ["Reputation Bar Height"] = "Reputation Bar Height",
    ["Reputation Bar Timeout"] = "Reputation Bar Timeout",
    ["Reputation Bar Text Show"] = "Reputation Bar Text Show",
    
    -- Keybindings
    ["Keybindings"] = "Keybindings",
    ["Keybinding Settings"] = "Keybinding Settings",
    ["Configure special keybindings for controller-style gameplay."] = "Configure special keybindings for controller-style gameplay.",
    ["Use A button for Jump"] = "Use A button for Jump",
    ["When enabled, pressing the A button (key 1) will jump. When disabled, it will use whatever action is in slot 1 of the action bar."] = "When enabled, pressing the A button (key 1) will jump. When disabled, it will use whatever action is in slot 1 of the action bar.",
    ["Reset Bindings"] = "Reset Bindings",
    ["Reset Default Bindings"] = "Reset Default Bindings",
    ["Resets all keybindings to default (1-0 keys) and places default macros (Target) on the action bar."] = "Resets all keybindings to default (1-0 keys) and places default macros (Target) on the action bar.",
    ["Spell Placement"] = "Spell Placement",
    ["Show Placement Frame"] = "Show Placement Frame",
    ["Opens the spell placement frame where you can drag and drop spells, macros, and items onto action bar slots."] = "Opens the spell placement frame where you can drag and drop spells, macros, and items onto action bar slots.",
    
    -- Action Bars
    ["Action Bars"] = "Action Bars",
    ["Action Bar Settings"] = "Action Bar Settings",
    ["Configure the gamepad-style action bar layout."] = "Configure the gamepad-style action bar layout.",
    ["Button Size"] = "Button Size",
    ["Button Padding"] = "Button Padding",
    ["Appearance"] = "Appearance",
    ["Classic"] = "Classic",
    ["Modern"] = "Modern",
    ["X Offset"] = "X Offset",
    ["Y Offset"] = "Y Offset",
    ["Star Padding"] = "Star Padding",
    ["Scale"] = "Scale",
    ["Size: 20-80, Padding: 0-100, Star Padding: 50-1000, Scale: 0.5-2.0. X/Y offset from bottom center."] = "Size: 20-80, Padding: 0-100, Star Padding: 50-1000, Scale: 0.5-2.0. X/Y offset from bottom center.",
    ["Reset Layout"] = "Reset Layout",
    
    -- Chat
    ["Chat"] = "Chat",
    ["Chat Settings"] = "Chat Settings",
    ["Configure the chat frame position and size. The chat frame is centered at the bottom of the screen."] = "Configure the chat frame position and size. The chat frame is centered at the bottom of the screen.",
    ["Chat Width"] = "Chat Width",
    ["Chat Height"] = "Chat Height",
    ["Enable Virtual Keyboard"] = "Enable Virtual Keyboard",
    ["When enabled, a virtual keyboard appears when typing in chat. Disable to use an external keyboard."] = "When enabled, a virtual keyboard appears when typing in chat. Disable to use an external keyboard.",
    ["Width: 100-2000, Height: 50-1000. The chat frame is centered at the bottom of the screen."] = "Width: 100-2000, Height: 50-1000. The chat frame is centered at the bottom of the screen.",
    ["Reset Chat"] = "Reset Chat",
    
    -- Language
    ["Language"] = "Language",
    ["Select Language"] = "Select Language",
    
    -- Common actions
    ["Select"] = "Select",
    ["Pickup"] = "Pickup",
    ["Bind"] = "Bind",
    ["Use"] = "Use",
    ["Drop"] = "Drop",
    ["Unequip"] = "Unequip",
    ["Cast"] = "Cast",
    ["Learn"] = "Learn",
    ["Clear"] = "Clear",
    
    -- Title
    ["Console Experience"] = "Console Experience",
    -- Warrior Stances
    ["Battle Stance"] = "Battle Stance",
    ["Defensive Stance"] = "Defensive Stance",
    ["Berserker Stance"] = "Berserker Stance",
    
    -- Druid Forms
    ["Bear Form"] = "Bear Form",
    ["Dire Bear Form"] = "Dire Bear Form",
    ["Cat Form"] = "Cat Form",
    ["Travel Form"] = "Travel Form",
    ["Aquatic Form"] = "Aquatic Form",
    ["Moonkin Form"] = "Moonkin Form",
    
    -- Other Forms
    ["Stealth"] = "Stealth",
    ["Shadowform"] = "Shadowform",
    ["Ghost Wolf"] = "Ghost Wolf",
    
    -- Keyboard Emotes
    ["Emotes"] = "Emotes",
    ["Wave"] = "Wave",
    ["Hello"] = "Hello",
    ["Bye"] = "Bye",
    ["Bow"] = "Bow",
    ["Salute"] = "Salute",
    ["Cheer"] = "Cheer",
    ["Applaud"] = "Applaud",
    ["Thank"] = "Thank",
    ["Charge"] = "Charge",
    ["Flee"] = "Flee",
    ["Cower"] = "Cower",
    ["Ready"] = "Ready",
    ["Dance"] = "Dance",
    ["Laugh"] = "Laugh",
    ["Joke"] = "Joke",
    ["Roar"] = "Roar",
    ["Sit"] = "Sit",
    ["Stand"] = "Stand",
    ["Sleep"] = "Sleep",
    ["Kneel"] = "Kneel",
    ["Point"] = "Point",
    ["Shrug"] = "Shrug",
    ["Agree"] = "Agree",
    ["Disagree"] = "Disagree",
}

