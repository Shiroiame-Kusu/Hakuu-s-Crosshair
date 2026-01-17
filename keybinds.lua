--[[
    Hakuu's Crosshair Mod - Keybind Handlers
]]

-- Toggle crosshair visibility
if CrosshairMod and CrosshairMod.settings then
    CrosshairMod.settings.enabled = not CrosshairMod.settings.enabled
    
    if CrosshairMod._state and CrosshairMod._state.panel and alive(CrosshairMod._state.panel) then
        CrosshairMod._state.panel:set_visible(CrosshairMod.settings.enabled)
    end
    
    -- Show feedback message (bilingual)
    if managers.hud then
        local is_chinese = false
        if Idstring and SystemInfo then
            local sys_lang = SystemInfo:language()
            is_chinese = sys_lang == Idstring("schinese") or sys_lang == Idstring("tchinese")
        end
        
        local status
        if CrosshairMod.settings.enabled then
            status = is_chinese and "准星: 开启" or "Crosshair: ON"
        else
            status = is_chinese and "准星: 关闭" or "Crosshair: OFF"
        end
        
        -- Try different HUD message methods for compatibility
        if managers.hud.present_mid_text then
            pcall(function()
                managers.hud:present_mid_text({ text = status, time = 1.5 })
            end)
        elseif managers.hud.show_hint then
            pcall(function()
                managers.hud:show_hint({ text = status, time = 1.5 })
            end)
        end
    end
    
    -- Save the setting
    if CrosshairMod.save_settings then
        CrosshairMod:save_settings()
    end
end
