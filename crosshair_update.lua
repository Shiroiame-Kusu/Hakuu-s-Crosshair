--[[
    Hakuu's Crosshair Mod - Update Module
    Main update loop and color interpolation
]]

if not CrosshairMod then return end

-- ============================================================================
-- FPS Tracking & Throttle Control
-- ============================================================================

function CrosshairMod:update_fps_tracking(dt)
    local perf = self._perf
    if not perf then return end
    
    -- Store frame time in ring buffer
    perf.frame_times[perf.frame_time_index] = dt
    perf.frame_time_index = perf.frame_time_index + 1
    if perf.frame_time_index > perf.frame_time_count then
        perf.frame_time_index = 1
    end
    
    -- Calculate average FPS from frame times
    local total_time = 0
    for i = 1, perf.frame_time_count do
        total_time = total_time + perf.frame_times[i]
    end
    perf.avg_fps = perf.frame_time_count / total_time
    
    -- Adjust raycast interval based on FPS
    -- High FPS (60+): interval = floor((fps / 60) * 3), scales with framerate
    -- Medium FPS (30-60): every 2 frames (~15-30 raycasts/sec)
    -- Low FPS (<30): every frame (responsive at low FPS)
    -- This maintains ~20 raycasts/sec regardless of framerate
    if perf.avg_fps >= 60 then
        perf.raycast_interval = math.floor((perf.avg_fps / 60) * 3)
    elseif perf.avg_fps >= 30 then
        perf.raycast_interval = 2
    else
        perf.raycast_interval = 1
    end
    
    -- Increment frame counter (reset to avoid overflow)
    perf.frame_counter = perf.frame_counter + 1
    -- Reset counter when it gets too large (at a multiple of common intervals)
    -- 3600 = LCM of common intervals (1,2,3,4,5,6,7,8,9,10,12)
    if perf.frame_counter >= 3600 then
        perf.frame_counter = 0
    end
end

function CrosshairMod:should_update_raycast()
    local perf = self._perf
    if not perf then return true end
    
    return perf.frame_counter % perf.raycast_interval == 0
end

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
    
    -- Update FPS tracking and throttle control
    self:update_fps_tracking(dt)
    
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
    
    -- Update target color (with throttling)
    local target_type
    if self:should_update_raycast() then
        target_type = self:get_target_type()
        self._perf.cached_target_type = target_type
    else
        target_type = self._perf.cached_target_type or "default"
    end
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
