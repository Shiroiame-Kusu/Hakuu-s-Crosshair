--[[
    Hakuu's Crosshair Mod - Menu Module
    Options menu configuration
]]

log("[Hakuu's Crosshair Menu] Menu module loading...")

-- CrosshairMod may not be initialized when menu loads, use delayed initialization
CrosshairMod = CrosshairMod or {}
log("[Hakuu's Crosshair Menu] CrosshairMod table initialized")

-- Ensure complete settings structure exists
CrosshairMod.settings = CrosshairMod.settings or {}
CrosshairMod.settings.enabled = CrosshairMod.settings.enabled ~= nil and CrosshairMod.settings.enabled or true
CrosshairMod.settings.style = CrosshairMod.settings.style or {}
CrosshairMod.settings.style.crosshair_mode = CrosshairMod.settings.style.crosshair_mode or "auto"  -- "auto", "dot", "cross"
CrosshairMod.settings.style.hide_when_ads = CrosshairMod.settings.style.hide_when_ads ~= nil and CrosshairMod.settings.style.hide_when_ads or true
CrosshairMod.settings.style.dot = CrosshairMod.settings.style.dot or { size = 4, alpha = 0.9 }
CrosshairMod.settings.style.crosshair = CrosshairMod.settings.style.crosshair or { length = 8, thickness = 2, gap = 4, alpha = 0.9, outline = true, outline_thickness = 1 }
CrosshairMod.settings.sway = CrosshairMod.settings.sway or { enabled = true, multiplier = 1.0, smoothing = 0.15 }
CrosshairMod.settings.hitmarker = CrosshairMod.settings.hitmarker or { enabled = true, size = 12, thickness = 2, duration = 0.15 }
CrosshairMod.settings.dynamic = CrosshairMod.settings.dynamic or { enabled = true, expansion_amount = 6, recovery_speed = 15 }

-- Crosshair mode conversion functions (for MultipleChoice)
local crosshair_mode_values = { "auto", "dot", "cross" }
local function mode_to_index(mode)
    for i, v in ipairs(crosshair_mode_values) do
        if v == mode then return i end
    end
    return 1
end
local function index_to_mode(index)
    return crosshair_mode_values[index] or "auto"
end

Hooks:Add("LocalizationManagerPostInit", "ModernCrosshair_Localization", function(loc)
    -- Detect game language
    local lang = "en"
    if Idstring then
        local sys_lang = SystemInfo:language()
        if sys_lang == Idstring("schinese") or sys_lang == Idstring("tchinese") then
            lang = "zh"
        end
    end
    
    -- Load localization from external files using dofile
    local mod_path = CrosshairMod._mod_path or ModPath or ""
    local loc_file = lang == "zh" and "localization/chinese.lua" or "localization/english.lua"
    local full_path = mod_path .. loc_file
    
    local strings = nil
    local success, result = pcall(dofile, full_path)
    if success and type(result) == "table" then
        strings = result
    end
    
    -- Fallback to English if loading failed
    if not strings or not next(strings) then
        strings = {
            ["crosshair_mod_title"] = "Hakuu's Crosshair",
            ["crosshair_mod_desc"] = "Modern FPS crosshair mod settings",
            ["crosshair_enabled"] = "Enable Crosshair",
            ["crosshair_enabled_desc"] = "Toggle custom crosshair on/off",
            ["crosshair_mode"] = "Crosshair Mode",
            ["crosshair_mode_desc"] = "Auto: Hip-fire cross/Stealth-interact-melee dot | Dot: Always dot | Cross: Always cross",
            ["crosshair_mode_auto"] = "Auto",
            ["crosshair_mode_dot"] = "Dot",
            ["crosshair_mode_cross"] = "Cross",
            ["crosshair_hide_ads"] = "Hide When ADS",
            ["crosshair_hide_ads_desc"] = "Hide crosshair when using iron sight/scope",
            ["crosshair_sway_enabled"] = "Laser Follow",
            ["crosshair_sway_enabled_desc"] = "Crosshair follows gun barrel aim point",
            ["crosshair_sway_multiplier"] = "Follow Sensitivity",
            ["crosshair_sway_multiplier_desc"] = "Intensity of laser follow effect",
            ["crosshair_hitmarker_enabled"] = "Enable Hitmarker",
            ["crosshair_hitmarker_enabled_desc"] = "Show hit confirmation feedback",
            ["crosshair_dynamic_enabled"] = "Dynamic Expansion",
            ["crosshair_dynamic_enabled_desc"] = "Crosshair expands when firing",
            ["crosshair_length"] = "Crosshair Length",
            ["crosshair_length_desc"] = "Length of crosshair lines",
            ["crosshair_thickness"] = "Crosshair Thickness",
            ["crosshair_thickness_desc"] = "Thickness of crosshair lines",
            ["crosshair_gap"] = "Crosshair Gap",
            ["crosshair_gap_desc"] = "Center gap of crosshair",
            ["crosshair_dot_size"] = "Dot Size",
            ["crosshair_dot_size_desc"] = "Size of dot",
            ["crosshair_outline"] = "Outline",
            ["crosshair_outline_desc"] = "Show black outline",
        }
    end
    
    loc:add_localized_strings(strings)
end)

Hooks:Add("MenuManagerSetupCustomMenus", "ModernCrosshair_SetupMenus", function(menu_manager, nodes)
    MenuHelper:NewMenu("crosshair_mod_menu")
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "ModernCrosshair_PopulateMenus", function(menu_manager, nodes)
    
    -- Enable/Disable toggle
    MenuHelper:AddToggle({
        id = "crosshair_enabled",
        title = "crosshair_enabled",
        desc = "crosshair_enabled_desc",
        callback = "crosshair_toggle_enabled",
        value = CrosshairMod.settings.enabled,
        menu_id = "crosshair_mod_menu",
        priority = 100,
    })
    
    -- Crosshair mode selection (auto/dot/cross)
    MenuHelper:AddMultipleChoice({
        id = "crosshair_mode",
        title = "crosshair_mode",
        desc = "crosshair_mode_desc",
        callback = "crosshair_set_mode",
        items = { "crosshair_mode_auto", "crosshair_mode_dot", "crosshair_mode_cross" },
        value = mode_to_index(CrosshairMod.settings.style.crosshair_mode),
        menu_id = "crosshair_mod_menu",
        priority = 95,
    })
    
    -- Hide when ADS
    MenuHelper:AddToggle({
        id = "crosshair_hide_ads",
        title = "crosshair_hide_ads",
        desc = "crosshair_hide_ads_desc",
        callback = "crosshair_toggle_hide_ads",
        value = CrosshairMod.settings.style.hide_when_ads,
        menu_id = "crosshair_mod_menu",
        priority = 90,
    })
    
    -- Laser follow toggle
    MenuHelper:AddToggle({
        id = "crosshair_sway_enabled",
        title = "crosshair_sway_enabled",
        desc = "crosshair_sway_enabled_desc",
        callback = "crosshair_toggle_sway",
        value = CrosshairMod.settings.sway.enabled,
        menu_id = "crosshair_mod_menu",
        priority = 88,
    })
    
    -- Follow sensitivity
    MenuHelper:AddSlider({
        id = "crosshair_sway_multiplier",
        title = "crosshair_sway_multiplier",
        desc = "crosshair_sway_multiplier_desc",
        callback = "crosshair_set_sway_mult",
        value = CrosshairMod.settings.sway.multiplier,
        min = 0,
        max = 3,
        step = 0.1,
        show_value = true,
        menu_id = "crosshair_mod_menu",
        priority = 85,
    })
    
    -- Hitmarker toggle
    MenuHelper:AddToggle({
        id = "crosshair_hitmarker_enabled",
        title = "crosshair_hitmarker_enabled",
        desc = "crosshair_hitmarker_enabled_desc",
        callback = "crosshair_toggle_hitmarker",
        value = CrosshairMod.settings.hitmarker.enabled,
        menu_id = "crosshair_mod_menu",
        priority = 80,
    })
    
    -- Dynamic expansion toggle
    MenuHelper:AddToggle({
        id = "crosshair_dynamic_enabled",
        title = "crosshair_dynamic_enabled",
        desc = "crosshair_dynamic_enabled_desc",
        callback = "crosshair_toggle_dynamic",
        value = CrosshairMod.settings.dynamic.enabled,
        menu_id = "crosshair_mod_menu",
        priority = 75,
    })
    
    -- Outline toggle
    MenuHelper:AddToggle({
        id = "crosshair_outline",
        title = "crosshair_outline",
        desc = "crosshair_outline_desc",
        callback = "crosshair_toggle_outline",
        value = CrosshairMod.settings.style.crosshair.outline,
        menu_id = "crosshair_mod_menu",
        priority = 70,
    })
    
    -- Crosshair length
    MenuHelper:AddSlider({
        id = "crosshair_length",
        title = "crosshair_length",
        desc = "crosshair_length_desc",
        callback = "crosshair_set_length",
        value = CrosshairMod.settings.style.crosshair.length,
        min = 2,
        max = 30,
        step = 1,
        show_value = true,
        menu_id = "crosshair_mod_menu",
        priority = 65,
    })
    
    -- Crosshair thickness
    MenuHelper:AddSlider({
        id = "crosshair_thickness",
        title = "crosshair_thickness",
        desc = "crosshair_thickness_desc",
        callback = "crosshair_set_thickness",
        value = CrosshairMod.settings.style.crosshair.thickness,
        min = 1,
        max = 10,
        step = 1,
        show_value = true,
        menu_id = "crosshair_mod_menu",
        priority = 60,
    })
    
    -- Crosshair gap
    MenuHelper:AddSlider({
        id = "crosshair_gap",
        title = "crosshair_gap",
        desc = "crosshair_gap_desc",
        callback = "crosshair_set_gap",
        value = CrosshairMod.settings.style.crosshair.gap,
        min = 0,
        max = 20,
        step = 1,
        show_value = true,
        menu_id = "crosshair_mod_menu",
        priority = 55,
    })
    
    -- Dot size
    MenuHelper:AddSlider({
        id = "crosshair_dot_size",
        title = "crosshair_dot_size",
        desc = "crosshair_dot_size_desc",
        callback = "crosshair_set_dot_size",
        value = CrosshairMod.settings.style.dot.size,
        min = 1,
        max = 15,
        step = 1,
        show_value = true,
        menu_id = "crosshair_mod_menu",
        priority = 50,
    })
    
end)

Hooks:Add("MenuManagerBuildCustomMenus", "ModernCrosshair_BuildMenus", function(menu_manager, nodes)
    nodes["crosshair_mod_menu"] = MenuHelper:BuildMenu("crosshair_mod_menu", { back_callback = "crosshair_save_settings" })
    MenuHelper:AddMenuItem(nodes["blt_options"], "crosshair_mod_menu", "crosshair_mod_title", "crosshair_mod_desc")
end)

-- ============================================================================
-- Callbacks
-- ============================================================================

Hooks:Add("MenuManagerInitialize", "ModernCrosshair_MenuCallbacks", function(menu_manager)
    
    MenuCallbackHandler.crosshair_toggle_enabled = function(self, item)
        if CrosshairMod and CrosshairMod.settings then
            CrosshairMod.settings.enabled = item:value() == "on"
        end
    end
    
    MenuCallbackHandler.crosshair_set_mode = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style then
            CrosshairMod.settings.style.crosshair_mode = index_to_mode(item:value())
        end
    end
    
    MenuCallbackHandler.crosshair_toggle_hide_ads = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style then
            CrosshairMod.settings.style.hide_when_ads = item:value() == "on"
        end
    end
    
    MenuCallbackHandler.crosshair_toggle_sway = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.sway then
            CrosshairMod.settings.sway.enabled = item:value() == "on"
        end
    end
    
    MenuCallbackHandler.crosshair_set_sway_mult = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.sway then
            CrosshairMod.settings.sway.multiplier = item:value()
        end
    end
    
    MenuCallbackHandler.crosshair_toggle_hitmarker = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.hitmarker then
            CrosshairMod.settings.hitmarker.enabled = item:value() == "on"
        end
    end
    
    MenuCallbackHandler.crosshair_toggle_dynamic = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.dynamic then
            CrosshairMod.settings.dynamic.enabled = item:value() == "on"
        end
    end
    
    MenuCallbackHandler.crosshair_toggle_outline = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style and CrosshairMod.settings.style.crosshair then
            CrosshairMod.settings.style.crosshair.outline = item:value() == "on"
            if CrosshairMod.rebuild_crosshair then
                CrosshairMod:rebuild_crosshair()
            end
        end
    end
    
    MenuCallbackHandler.crosshair_set_length = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style and CrosshairMod.settings.style.crosshair then
            CrosshairMod.settings.style.crosshair.length = item:value()
            if CrosshairMod.rebuild_crosshair then
                CrosshairMod:rebuild_crosshair()
            end
        end
    end
    
    MenuCallbackHandler.crosshair_set_thickness = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style and CrosshairMod.settings.style.crosshair then
            CrosshairMod.settings.style.crosshair.thickness = item:value()
            if CrosshairMod.rebuild_crosshair then
                CrosshairMod:rebuild_crosshair()
            end
        end
    end
    
    MenuCallbackHandler.crosshair_set_gap = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style and CrosshairMod.settings.style.crosshair then
            CrosshairMod.settings.style.crosshair.gap = item:value()
            if CrosshairMod._state then
                CrosshairMod._state.dynamic_gap = item:value()
                CrosshairMod._state.target_dynamic_gap = item:value()
            end
        end
    end
    
    MenuCallbackHandler.crosshair_set_dot_size = function(self, item)
        if CrosshairMod and CrosshairMod.settings and CrosshairMod.settings.style and CrosshairMod.settings.style.dot then
            CrosshairMod.settings.style.dot.size = item:value()
            if CrosshairMod.rebuild_crosshair then
                CrosshairMod:rebuild_crosshair()
            end
        end
    end
    
    MenuCallbackHandler.crosshair_save_settings = function(self)
        if CrosshairMod and CrosshairMod.save_settings then
            CrosshairMod:save_settings()
        end
    end
    
end)
