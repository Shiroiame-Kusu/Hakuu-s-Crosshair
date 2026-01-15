--[[
    Hakuu's Crosshair Mod - Target Detection Module
    Handles raycast target detection and color determination
]]

if not CrosshairMod then return end

-- ============================================================================
-- Slot Masks (delayed init, World may not exist at load time)
-- ============================================================================

CrosshairMod.SLOT_MASKS = nil

function CrosshairMod:init_slot_masks()
    if self.SLOT_MASKS then return end
    if not World then return end
    
    -- Slot masks reference:
    -- Enemies: 12 (enemies), 33 (swat turrets)
    -- Civilians: 21
    -- Teammates: 3 (players), 16 (AI teammates)
    -- Hostages: 22
    -- Sentry guns: 25
    self.SLOT_MASKS = {
        ENEMIES = World:make_slot_mask(12, 33),
        CIVILIANS = World:make_slot_mask(21),
        TEAMMATES = World:make_slot_mask(3, 16),
        HOSTAGES = World:make_slot_mask(22),
        SENTRY = World:make_slot_mask(25),
        -- Only detect character type targets
        ALL_CHARACTERS = World:make_slot_mask(3, 12, 16, 21, 22, 25, 33),
    }
end

-- Special enemy types (these names appear in _tweak_table strings)
CrosshairMod.SPECIAL_ENEMIES = {
    "tank",
    "spooc",
    "taser",
    "shield",
    "medic",
    "sniper",
    "phalanx",
    "bulldozer",
    "cloaker",
}

-- ============================================================================
-- Target Detection
-- ============================================================================

function CrosshairMod:get_target_type()
    -- 确保 SLOT_MASKS 已初始化
    self:init_slot_masks()
    if not self.SLOT_MASKS then
        return "default"
    end
    
    if not managers.player then
        return "default"
    end
    
    local player = managers.player:player_unit()
    if not player or not alive(player) then
        return "default"
    end
    
    -- First check for interactable objects (using built-in interaction manager)
    if managers.interaction then
        local active_interact = managers.interaction:active_unit()
        if active_interact and alive(active_interact) then
            -- Has interactable object, check what type
            local interaction = active_interact:interaction()
            if interaction then
                return "interactable"
            end
        end
    end
    
    local camera = player:camera()
    if not camera then
        return "default"
    end
    
    local from = camera:position()
    local to = from + camera:forward() * 3000
    
    -- Raycast for character type targets
    local ray = World:raycast("ray", from, to, "slot_mask", self.SLOT_MASKS.ALL_CHARACTERS)
    
    if not ray or not ray.unit or not alive(ray.unit) then
        return "default"
    end
    
    local unit = ray.unit
    
    -- Check sentry guns
    if self:is_unit_in_slot(unit, self.SLOT_MASKS.SENTRY) then
        return "camera"  -- Use same color
    end
    
    -- Check enemies
    if self:is_unit_in_slot(unit, self.SLOT_MASKS.ENEMIES) then
        if self:is_special_enemy(unit) then
            return "enemy_special"
        end
        return "enemy"
    end
    
    -- Check civilians
    if self:is_unit_in_slot(unit, self.SLOT_MASKS.CIVILIANS) then
        return "civilian"
    end
    
    -- Check hostages
    if self:is_unit_in_slot(unit, self.SLOT_MASKS.HOSTAGES) then
        return "hostage"
    end
    
    -- Check teammates
    if self:is_unit_in_slot(unit, self.SLOT_MASKS.TEAMMATES) then
        return "teammate"
    end
    
    return "default"
end

function CrosshairMod:is_unit_in_slot(unit, slot_mask)
    if not unit or not alive(unit) then return false end
    
    -- Use unit:in_slot(mask) method to check if unit is in slot mask
    local success, result = pcall(function()
        return unit:in_slot(slot_mask)
    end)
    
    if success then
        return result
    end
    return false
end

function CrosshairMod:is_special_enemy(unit)
    if not unit or not alive(unit) then return false end
    
    -- First try to get _tweak_table from base (this is a string)
    local base = unit:base()
    if base and base._tweak_table then
        local tweak_name = base._tweak_table
        -- Ensure it's a string
        if type(tweak_name) == "string" then
            for _, special in ipairs(self.SPECIAL_ENEMIES) do
                if string.find(tweak_name, special) then
                    return true
                end
            end
        end
    end
    
    -- Fallback: check character_damage tweak_data_name
    local char_damage = unit:character_damage()
    if char_damage then
        -- Try to get tweak_data_name (if exists)
        if char_damage.tweak_data_name then
            local success, name = pcall(function() return char_damage:tweak_data_name() end)
            if success and type(name) == "string" then
                for _, special in ipairs(self.SPECIAL_ENEMIES) do
                    if string.find(name, special) then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

function CrosshairMod:get_color_for_target(target_type)
    return self.settings.colors[target_type] or self.settings.colors.default
end
