--[[
    Hakuu's Crosshair Mod - Damage Hooks
    Kill and special hit confirmation
]]

-- Don't check CrosshairMod here, as it may not be initialized when this file loads as a hook
-- Check inside each hook callback instead

-- ============================================================================
-- Enemy Damage Hooks
-- ============================================================================

if RequiredScript == "lib/units/enemies/cop/copdamage" then
    
    -- Kill confirmation
    Hooks:PostHook(CopDamage, "die", "ModernCrosshair_EnemyDie", function(self, attack_data)
        if not CrosshairMod or not CrosshairMod.show_hitmarker then return end
        if not attack_data then return end
        
        local attacker_unit = attack_data.attacker_unit
        if not attacker_unit or not alive(attacker_unit) then return end
        
        local player = managers.player and managers.player:player_unit()
        if not player or not alive(player) then return end
        
        if attacker_unit == player then
            CrosshairMod:show_hitmarker("kill")
        end
    end)
    
    -- Hit detection (headshot, crit, normal)
    Hooks:PostHook(CopDamage, "damage_bullet", "ModernCrosshair_EnemyBullet", function(self, attack_data, result)
        if not CrosshairMod or not CrosshairMod.show_hitmarker then return end
        if not attack_data then return end
        
        local attacker_unit = attack_data.attacker_unit
        if not attacker_unit or not alive(attacker_unit) then return end
        
        local player = managers.player and managers.player:player_unit()
        if not player or not alive(player) then return end
        
        if attacker_unit == player then
            -- Check for headshot
            if attack_data.headshot or attack_data.hit_body_part == 1 then
                CrosshairMod:show_hitmarker("headshot")
                return
            end
            
            -- Check for crit
            if attack_data.critical then
                CrosshairMod:show_hitmarker("crit")
                return
            end
            
            -- Normal hit
            CrosshairMod:show_hitmarker("normal")
        end
    end)
    
    -- Melee hit detection
    Hooks:PostHook(CopDamage, "damage_melee", "ModernCrosshair_EnemyMelee", function(self, attack_data)
        if not CrosshairMod or not CrosshairMod.show_hitmarker then return end
        if not attack_data then return end
        
        local attacker_unit = attack_data.attacker_unit
        if not attacker_unit or not alive(attacker_unit) then return end
        
        local player = managers.player and managers.player:player_unit()
        if not player or not alive(player) then return end
        
        if attacker_unit == player then
            CrosshairMod:show_hitmarker("normal")
        end
    end)
    
end

-- ============================================================================
-- Civilian Damage Hooks
-- ============================================================================

if RequiredScript == "lib/units/civilians/civiliandamage" then
    
    Hooks:PostHook(CivilianDamage, "die", "ModernCrosshair_CivDie", function(self, attack_data)
        if not CrosshairMod or not CrosshairMod.show_hitmarker then return end
        if not attack_data then return end
        
        local attacker_unit = attack_data.attacker_unit
        if not attacker_unit or not alive(attacker_unit) then return end
        
        local player = managers.player and managers.player:player_unit()
        if not player or not alive(player) then return end
        
        if attacker_unit == player then
            CrosshairMod:show_hitmarker("kill")
        end
    end)
    
    Hooks:PostHook(CivilianDamage, "damage_bullet", "ModernCrosshair_CivBullet", function(self, attack_data)
        if not CrosshairMod or not CrosshairMod.show_hitmarker then return end
        if not attack_data then return end
        
        local attacker_unit = attack_data.attacker_unit
        if not attacker_unit or not alive(attacker_unit) then return end
        
        local player = managers.player and managers.player:player_unit()
        if not player or not alive(player) then return end
        
        if attacker_unit == player then
            CrosshairMod:show_hitmarker("normal")
        end
    end)
    
end
