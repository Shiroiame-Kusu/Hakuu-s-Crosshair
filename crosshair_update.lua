--[[
    Hakuu's Crosshair Mod - Update Module
    Main update loop and color interpolation
]]

if not CrosshairMod then return end

-- ============================================================================
-- Color Interpolation
-- ============================================================================

function CrosshairMod:lerp_color(from, to, t)
    if not from or not to then return to or from end
    
    t = math.max(0, math.min(1, t))
    
    local r = from.r + (to.r - from.r) * t
    local g = from.g + (to.g - from.g) * t
    local b = from.b + (to.b - from.b) * t
    
    return Color(r, g, b)
end

-- ============================================================================
-- Update Loop
-- ============================================================================

function CrosshairMod:update(t, dt)
    if not self.settings.enabled then
        if self._state.panel and alive(self._state.panel) then
            self._state.panel:set_visible(false)
        end
        return
    end
    
    -- Ensure panel exists
    if not self._state.panel or not alive(self._state.panel) then
        self:create_panel()
        if not self._state.panel then return end
    end
    
    self._state.panel:set_visible(true)
    
    -- Check if player exists
    if not managers.player then
        self._state.panel:set_visible(false)
        return
    end
    
    local player = managers.player:player_unit()
    if not player or not alive(player) then
        self._state.panel:set_visible(false)
        return
    end
    
    -- Update aiming state
    local movement = player:movement()
    if movement then
        local current_state = movement:current_state()
        if current_state then
            -- in_steelsight is a method, checks via _state_data.in_steelsight
            if current_state._state_data then
                self._state.in_steelsight = current_state._state_data.in_steelsight or false
            else
                self._state.in_steelsight = false
            end
        end
    end
    
    -- Update target color
    local target_type = self:get_target_type()
    self._state.last_target_type = target_type
    self._state.target_color = self:get_color_for_target(target_type)
    
    -- Smooth color transition
    local color_lerp_speed = 10
    self._state.current_color = self:lerp_color(
        self._state.current_color,
        self._state.target_color,
        dt * color_lerp_speed
    )
    self:update_crosshair_color(self._state.current_color)
    
    -- Update sway (disabled, always 0)
    self:update_sway(dt)
    
    -- Ensure sway_offset is initialized as table
    if not self._state.sway_offset then
        self._state.sway_offset = { x = 0, y = 0 }
    end
    
    -- Update dynamic gap
    local dynamic = self.settings.dynamic or {}
    local style = self.settings.style or {}
    local crosshair = style.crosshair or {}
    local base_gap = crosshair.gap or 6
    
    if dynamic.enabled then
        local time_since_fire = t - (self._state.last_fire_time or 0)
        if time_since_fire > 0.05 then
            self._state.target_dynamic_gap = base_gap
        end
        
        local recovery_speed = dynamic.recovery_speed or 15
        local gap_lerp = dt * recovery_speed
        self._state.dynamic_gap = self._state.dynamic_gap + (self._state.target_dynamic_gap - self._state.dynamic_gap) * gap_lerp
    else
        self._state.dynamic_gap = base_gap
    end
    
    -- Update positions and visibility
    self:update_crosshair_positions()
    self:update_crosshair_visibility()
end
