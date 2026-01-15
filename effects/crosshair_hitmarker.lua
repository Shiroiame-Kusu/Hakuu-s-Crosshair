--[[
    Hakuu's Crosshair Mod - Hitmarker Module
    Handles hit confirmation visual feedback
]]

if not CrosshairMod then return end

-- ============================================================================
-- Hitmarker System
-- ============================================================================

function CrosshairMod:show_hitmarker(hit_type)
    local hitmarker = self.settings.hitmarker or {}
    if not hitmarker.enabled then return end
    if not self._state.hitmarker_panel or not alive(self._state.hitmarker_panel) then return end
    
    local hit_panel = self._state.hitmarker_panel
    local default_color = Color(1, 1, 1)
    local hit_config = hitmarker[hit_type] or hitmarker.normal or {}
    local color = hit_config.color or default_color
    local scale = hit_config.scale or 1.0
    
    -- Update hitmarker colors
    for _, child in ipairs(hit_panel:children()) do
        if alive(child) then
            child:set_color(color)
            -- Scale if needed
            if scale ~= 1.0 then
                local orig_w, orig_h = child:size()
                child:set_size(orig_w * scale, orig_h * scale)
            end
        end
    end
    
    -- Show and animate
    hit_panel:set_visible(true)
    hit_panel:set_alpha(1)
    
    -- Stop any existing animation
    hit_panel:stop()
    
    -- Animate fade out
    local duration = hitmarker.duration or 0.15
    hit_panel:animate(function(o)
        local t = 0
        while t < duration do
            t = t + coroutine.yield()
            local alpha = 1 - (t / duration)
            o:set_alpha(alpha)
        end
        o:set_visible(false)
        o:set_alpha(1)
        
        -- Reset scale
        if scale ~= 1.0 then
            local hm = CrosshairMod.settings.hitmarker or {}
            local base_size = hm.size or 12
            local base_thickness = hm.thickness or 2
            for _, child in ipairs(o:children()) do
                if alive(child) then
                    child:set_size(base_thickness, base_size)
                end
            end
        end
    end)
end

-- ============================================================================
-- Dynamic Gap (Fire Expansion)
-- ============================================================================

function CrosshairMod:on_weapon_fired()
    local dynamic = self.settings.dynamic or {}
    if not dynamic.enabled then return end
    
    local style = self.settings.style or {}
    local crosshair = style.crosshair or {}
    local gap = crosshair.gap or 6
    local expansion = dynamic.expansion_amount or 8
    
    self._state.target_dynamic_gap = gap + expansion
    self._state.last_fire_time = Application:time()
end
