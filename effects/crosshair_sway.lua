--[[
    Hakuu's Crosshair Mod - Laser Follow Module
    Crosshair follows gun barrel laser aim point
    
    Principle: Cast a ray from the muzzle, find the hit point, then convert
    that point to screen coordinates. Crosshair offsets to that position
    (relative to screen center).
]]

if not CrosshairMod then return end

-- ============================================================================
-- Laser Point Detection
-- ============================================================================

-- Slot mask for raycasting
CrosshairMod._laser_slotmask = nil

function CrosshairMod:init_laser_slotmask()
    if self._laser_slotmask then return end
    if not managers.slot then return end
    
    -- Use same slot mask as WeaponLaser
    self._laser_slotmask = managers.slot:get_mask("bullet_impact_targets")
end

function CrosshairMod:get_weapon_fire_ray()
    -- Get weapon fire ray origin and direction
    if not managers.player then
        return nil, nil
    end
    
    local player = managers.player:player_unit()
    if not player or not alive(player) then
        return nil, nil
    end
    
    local movement = player:movement()
    if not movement then
        return nil, nil
    end
    
    local current_state = movement:current_state()
    if not current_state then
        return nil, nil
    end
    
    -- Get equipped weapon
    local equipped_unit = current_state._equipped_unit
    if not equipped_unit or not alive(equipped_unit) then
        return nil, nil
    end
    
    local weapon_base = equipped_unit:base()
    if not weapon_base then
        return nil, nil
    end
    
    -- Check if weapon can aim (has fire_object)
    -- Exclude melee weapons and items without muzzle
    if not weapon_base.fire_object then
        return nil, nil
    end
    
    -- Get muzzle object
    local fire_obj = weapon_base:fire_object()
    if not fire_obj then
        return nil, nil
    end
    
    -- Get muzzle position and direction
    local from_pos = fire_obj:position()
    local direction = fire_obj:rotation():y()  -- Muzzle forward direction
    
    return from_pos, direction
end

-- Check if player is holding an aimable weapon
function CrosshairMod:is_holding_aimable_weapon()
    local from_pos, direction = self:get_weapon_fire_ray()
    return from_pos ~= nil and direction ~= nil
end

function CrosshairMod:get_laser_hit_point()
    -- Initialize slot mask
    self:init_laser_slotmask()
    if not self._laser_slotmask then
        return nil
    end
    
    local from_pos, direction = self:get_weapon_fire_ray()
    if not from_pos or not direction then
        return nil
    end
    
    -- Max ray distance (same as WeaponLaser)
    local max_distance = 3000
    local to_pos = from_pos + direction * max_distance
    
    -- Perform raycast
    local ray = World:raycast("ray", from_pos, to_pos, "slot_mask", self._laser_slotmask)
    
    if ray and ray.position then
        return ray.position
    end
    
    -- If nothing hit, return point at max distance
    return to_pos
end

function CrosshairMod:world_to_screen_offset(world_pos)
    -- Convert world coordinates to offset relative to screen center
    if not world_pos then
        return { x = 0, y = 0 }
    end
    
    if not managers.player then
        return { x = 0, y = 0 }
    end
    
    local player = managers.player:player_unit()
    if not player or not alive(player) then
        return { x = 0, y = 0 }
    end
    
    local camera = player:camera()
    if not camera then
        return { x = 0, y = 0 }
    end
    
    -- Check if point is in front of camera
    local cam_pos = camera:position()
    local cam_forward = camera:forward()
    local to_point = world_pos - cam_pos
    local dot = to_point:normalized():dot(cam_forward)
    
    if dot <= 0 then
        -- Point is behind camera, return zero offset
        return { x = 0, y = 0 }
    end
    
    -- Get HUD workspace
    if not managers.hud then
        return { x = 0, y = 0 }
    end
    
    local workspace = nil
    if managers.hud._workspace then
        workspace = managers.hud._workspace
    elseif managers.hud._saferect then
        workspace = managers.hud._saferect
    end
    
    if not workspace then
        return { x = 0, y = 0 }
    end
    
    -- Get camera object
    local cam_obj = nil
    if managers.viewport then
        cam_obj = managers.viewport:get_current_camera()
    end
    
    if not cam_obj then
        return { x = 0, y = 0 }
    end
    
    -- Convert world coordinates to screen coordinates
    local success, screen_pos = pcall(function()
        return workspace:world_to_screen(cam_obj, world_pos)
    end)
    
    if not success or not screen_pos then
        return { x = 0, y = 0 }
    end
    
    -- Get screen dimensions
    local panel = workspace:panel()
    if not panel then
        return { x = 0, y = 0 }
    end
    
    local screen_w, screen_h = panel:size()
    local center_x = screen_w / 2
    local center_y = screen_h / 2
    
    -- Calculate offset relative to screen center
    local offset_x = screen_pos.x - center_x
    local offset_y = screen_pos.y - center_y
    
    return { x = offset_x, y = offset_y }
end

-- ============================================================================
-- Sway Calculation (now renamed to laser follow)
-- ============================================================================

function CrosshairMod:calculate_sway()
    local sway_settings = self.settings.sway or {}
    if not sway_settings.enabled then
        return { x = 0, y = 0 }
    end
    
    -- Get laser hit point
    local hit_point = self:get_laser_hit_point()
    if not hit_point then
        return { x = 0, y = 0 }
    end
    
    -- Convert to screen offset
    local offset = self:world_to_screen_offset(hit_point)
    
    -- Apply multiplier
    local multiplier = sway_settings.multiplier or 1.0
    offset.x = offset.x * multiplier
    offset.y = offset.y * multiplier
    
    return offset
end

function CrosshairMod:update_sway(dt)
    if not self._state then return end
    
    local sway_settings = self.settings.sway or {}
    local smoothing = sway_settings.smoothing or 0.15
    
    -- Ensure sway_offset is initialized
    if not self._state.sway_offset then
        self._state.sway_offset = { x = 0, y = 0 }
    end
    
    local target_sway = self:calculate_sway()
    
    -- Use faster return speed when not holding weapon
    -- Use faster follow speed when holding weapon (0.4-0.5 is responsive)
    local current_smoothing = smoothing * 3  -- Increase base speed
    -- if current_smoothing > 0.6 then
    --     current_smoothing = 0.6  -- Limit max value to prevent jitter
    -- end
    
    if not self:is_holding_aimable_weapon() then
        current_smoothing = 0.5  -- Faster return to center
    end
    
    -- Smooth transition
    self._state.sway_offset.x = self._state.sway_offset.x + (target_sway.x - self._state.sway_offset.x) * current_smoothing
    self._state.sway_offset.y = self._state.sway_offset.y + (target_sway.y - self._state.sway_offset.y) * current_smoothing
end
