--[[
    Hakuu's Crosshair Mod for PAYDAY 2
    Main Entry Point
    
    Features:
    - Modern FPS hitmarker feedback
    - Weapon sway synced with laser
    - Target-based color changing
    - Customizable appearance
    
    Author: Crosshair Mod
    Version: 1.0
]]

-- ============================================================================
-- Load All Modules
-- ============================================================================

local mod_path = ModPath or ""

log("[Hakuu's Crosshair] Loading modules from: " .. tostring(mod_path))

-- Core module (settings, state, utilities)
log("[Hakuu's Crosshair] Loading crosshair_core.lua...")
dofile(mod_path .. "crosshair_core.lua")
log("[Hakuu's Crosshair] crosshair_core.lua loaded")

-- Utils
log("[Hakuu's Crosshair] Loading utils/crosshair_target.lua...")
dofile(mod_path .. "utils/crosshair_target.lua")
log("[Hakuu's Crosshair] crosshair_target.lua loaded")

-- Effects
log("[Hakuu's Crosshair] Loading effects/crosshair_drawing.lua...")
dofile(mod_path .. "effects/crosshair_drawing.lua")
log("[Hakuu's Crosshair] crosshair_drawing.lua loaded")

log("[Hakuu's Crosshair] Loading effects/crosshair_sway.lua...")
dofile(mod_path .. "effects/crosshair_sway.lua")
log("[Hakuu's Crosshair] crosshair_sway.lua loaded")

log("[Hakuu's Crosshair] Loading effects/crosshair_hitmarker.lua...")
dofile(mod_path .. "effects/crosshair_hitmarker.lua")
log("[Hakuu's Crosshair] crosshair_hitmarker.lua loaded")

-- Update loop module
log("[Hakuu's Crosshair] Loading crosshair_update.lua...")
dofile(mod_path .. "crosshair_update.lua")
log("[Hakuu's Crosshair] crosshair_update.lua loaded")

-- Hooks
log("[Hakuu's Crosshair] Loading hooks/crosshair_hooks.lua...")
dofile(mod_path .. "hooks/crosshair_hooks.lua")
log("[Hakuu's Crosshair] crosshair_hooks.lua loaded")

-- ============================================================================
-- Module Loaded
-- ============================================================================

log("[Hakuu's Crosshair] ========================================")
log("[Hakuu's Crosshair] All modules loaded successfully!")
log("[Hakuu's Crosshair] Settings check:")
log("[Hakuu's Crosshair]   enabled = " .. tostring(CrosshairMod.settings.enabled))
log("[Hakuu's Crosshair]   style = " .. tostring(CrosshairMod.settings.style))
log("[Hakuu's Crosshair]   hitmarker = " .. tostring(CrosshairMod.settings.hitmarker))
log("[Hakuu's Crosshair] ========================================")
