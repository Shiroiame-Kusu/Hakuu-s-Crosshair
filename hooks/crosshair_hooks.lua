--[[
    Hakuu's Crosshair Mod - Hooks Module
    All game hooks and event handlers
]]

if not CrosshairMod then return end

-- ============================================================================
-- HUD Manager Hooks (loaded via crosshair_mod.lua when hudmanagerpd2 is hooked)
-- ============================================================================

-- Hook into HUD layout creation
log("[Hakuu's Crosshair Hooks] Setting up HUDManager hooks...")
if HUDManager then
    log("[Hakuu's Crosshair Hooks] HUDManager exists, adding hooks")
    Hooks:PostHook(HUDManager, "_player_hud_layout", "ModernCrosshair_HUDLayout", function(self)
        log("[Hakuu's Crosshair Hooks] _player_hud_layout triggered")
        if CrosshairMod then
            log("[Hakuu's Crosshair Hooks] CrosshairMod exists, calling create_panel")
            CrosshairMod:create_panel()
        else
            log("[Hakuu's Crosshair Hooks] ERROR: CrosshairMod is nil!")
        end
    end)
    
    -- Hook into HUD update for crosshair updates
    Hooks:PostHook(HUDManager, "update", "ModernCrosshair_Update", function(self, t, dt)
        if CrosshairMod and CrosshairMod.update then
            CrosshairMod:update(t, dt)
        end
    end)
else
    log("[Hakuu's Crosshair Hooks] WARNING: HUDManager does not exist yet")
end

-- Hook into hit confirmation (for dynamic crosshair expansion)
if HUDHitConfirm then
    Hooks:PostHook(HUDHitConfirm, "on_hit_confirmed", "ModernCrosshair_HitConfirm", function(self)
        if CrosshairMod and CrosshairMod.on_weapon_fired then
            CrosshairMod:on_weapon_fired()
        end
    end)
end

-- ============================================================================
-- Player Standard Hooks (for weapon fire and steelsight detection)
-- ============================================================================

if PlayerStandard then
    -- Weapon fire detection
    Hooks:PostHook(PlayerStandard, "_fire", "ModernCrosshair_Fire", function(self)
        if CrosshairMod and CrosshairMod.on_weapon_fired then
            CrosshairMod:on_weapon_fired()
        end
    end)
    
    -- ADS state detection
    Hooks:PostHook(PlayerStandard, "_start_action_steelsight", "ModernCrosshair_StartADS", function(self, t)
        if CrosshairMod and CrosshairMod._state then
            CrosshairMod._state.in_steelsight = true
        end
    end)
    
    Hooks:PostHook(PlayerStandard, "_end_action_steelsight", "ModernCrosshair_EndADS", function(self, t)
        if CrosshairMod and CrosshairMod._state then
            CrosshairMod._state.in_steelsight = false
        end
    end)
else
    log("[Hakuu's Crosshair Hooks] WARNING: PlayerStandard does not exist yet")
end
