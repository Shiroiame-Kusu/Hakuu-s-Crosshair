--[[
    Hakuu's Crosshair Mod - Core Module
    Contains settings, state, and utility functions
]]

log("[Hakuu's Crosshair Core] Initializing CrosshairMod table...")

CrosshairMod = CrosshairMod or {}
CrosshairMod._initialized = CrosshairMod._initialized or false
CrosshairMod._mod_path = ModPath or CrosshairMod._mod_path or ""
CrosshairMod._save_path = SavePath or CrosshairMod._save_path or ""

log("[Hakuu's Crosshair Core] mod_path = " .. tostring(CrosshairMod._mod_path))
log("[Hakuu's Crosshair Core] save_path = " .. tostring(CrosshairMod._save_path))

-- ============================================================================
-- Configuration (preserve existing settings, allow menu to initialize first)
-- ============================================================================

CrosshairMod.settings = CrosshairMod.settings or {}
CrosshairMod.settings.enabled = CrosshairMod.settings.enabled ~= nil and CrosshairMod.settings.enabled or true

CrosshairMod.settings.style = CrosshairMod.settings.style or {}

-- Crosshair mode: "auto" = auto switch, "dot" = always dot, "cross" = always cross
CrosshairMod.settings.style.crosshair_mode = CrosshairMod.settings.style.crosshair_mode or "auto"

-- Hide crosshair when aiming down sights
CrosshairMod.settings.style.hide_when_ads = CrosshairMod.settings.style.hide_when_ads ~= nil and CrosshairMod.settings.style.hide_when_ads or true

CrosshairMod.settings.style.dot = CrosshairMod.settings.style.dot or {
    size = 4,
    alpha = 0.9,
}

CrosshairMod.settings.style.crosshair = CrosshairMod.settings.style.crosshair or {
    length = 8,
    thickness = 2,
    gap = 4,
    alpha = 0.9,
    outline = true,
    outline_thickness = 1,
}

CrosshairMod.settings.colors = CrosshairMod.settings.colors or {
    default = Color(1, 1, 1),
    enemy = Color(1, 0.2, 0.2),
    enemy_special = Color(1, 0.5, 0),
    civilian = Color(1, 1, 0),
    teammate = Color(0, 1, 0),
    hostage = Color(0.5, 0.5, 1),
    interactable = Color(0, 0.8, 1),
    camera = Color(1, 0, 1),
}

-- Laser follow settings
CrosshairMod.settings.sway = CrosshairMod.settings.sway or {
    enabled = true,
    multiplier = 1.0,
    smoothing = 0.15,
}

CrosshairMod.settings.hitmarker = CrosshairMod.settings.hitmarker or {
    enabled = true,
    size = 12,
    thickness = 2,
    duration = 0.15,
    normal = { color = Color(1, 1, 1) },
    headshot = { color = Color(1, 0.3, 0.3), scale = 1.2 },
    crit = { color = Color(1, 0.8, 0), scale = 1.3 },
    kill = { color = Color(1, 0, 0), scale = 1.4 },
}

-- 确保 hitmarker.normal 存在
if not CrosshairMod.settings.hitmarker.normal then
    log("[Hakuu's Crosshair Core] WARNING: hitmarker.normal was nil, creating default")
    CrosshairMod.settings.hitmarker.normal = { color = Color(1, 1, 1) }
end

CrosshairMod.settings.dynamic = CrosshairMod.settings.dynamic or {
    enabled = true,
    expansion_amount = 6,
    recovery_speed = 15,
}

-- ============================================================================
-- Internal State
-- ============================================================================

CrosshairMod._state = CrosshairMod._state or {
    panel = nil,
    crosshair_elements = {},
    current_color = nil,
    target_color = nil,
    sway_offset = nil,  -- Delayed init Vector3
    target_sway_offset = nil,  -- Delayed init Vector3
    in_steelsight = false,
    hitmarker_panel = nil,
    last_target_type = "default",
    dynamic_gap = 0,
    target_dynamic_gap = 0,
    last_fire_time = 0,
}

-- ============================================================================
-- Performance: FPS Tracking & Raycast Throttling
-- ============================================================================

CrosshairMod._perf = CrosshairMod._perf or {
    -- FPS tracking
    frame_times = {},           -- Ring buffer for frame times
    frame_time_index = 1,       -- Current index in ring buffer
    frame_time_count = 30,      -- Number of frames to average
    avg_fps = 60,               -- Calculated average FPS
    
    -- Raycast throttling
    frame_counter = 0,          -- Frame counter for throttling (resets periodically)
    raycast_interval = 2,       -- Frames between raycasts (dynamic)
    last_raycast_time = 0,      -- Last raycast timestamp
    
    -- Target cache
    cached_target_type = "default",
    cached_target_unit = nil,
    
    -- Laser hit cache
    cached_laser_hit = nil,
    cached_laser_offset = { x = 0, y = 0 },
}

-- Initialize frame times buffer (ensure it has correct size)
if #CrosshairMod._perf.frame_times ~= CrosshairMod._perf.frame_time_count then
    CrosshairMod._perf.frame_times = {}
    for i = 1, CrosshairMod._perf.frame_time_count do
        CrosshairMod._perf.frame_times[i] = 1/60
    end
    CrosshairMod._perf.frame_time_index = 1
end

-- Sway seeds for variation
CrosshairMod._sway_seed_x = CrosshairMod._sway_seed_x or (math.random() * math.pi * 2)
CrosshairMod._sway_seed_y = CrosshairMod._sway_seed_y or (math.random() * math.pi * 2)

-- ============================================================================
-- Settings Management
-- ============================================================================

function CrosshairMod:load_config()
    local config_path = self._save_path .. "crosshair_settings.json"
    local file = io.open(config_path, "r")
    
    if file then
        local content = file:read("*all")
        file:close()
        
        local success, loaded_data = pcall(function()
            return json.decode(content)
        end)
        
        if success and loaded_data then
            self:merge_settings(loaded_data)
        end
    end
end

function CrosshairMod:merge_settings(loaded)
    if not loaded then return end
    
    local function merge(base, new)
        for k, v in pairs(new) do
            if type(v) == "table" and type(base[k]) == "table" then
                merge(base[k], v)
            elseif type(v) == "table" and v.r and v.g and v.b then
                base[k] = Color(v.r, v.g, v.b)
            else
                base[k] = v
            end
        end
    end
    
    merge(self.settings, loaded)
end

function CrosshairMod:save_settings()
    if not self._save_path or self._save_path == "" then return end
    
    local config_path = self._save_path .. "crosshair_settings.json"
    
    local function prepare_for_save(t)
        local result = {}
        for k, v in pairs(t) do
            if type(v) == "userdata" then
                result[k] = {r = v.r, g = v.g, b = v.b}
            elseif type(v) == "table" then
                result[k] = prepare_for_save(v)
            else
                result[k] = v
            end
        end
        return result
    end
    
    local save_data = prepare_for_save(self.settings)
    
    local file = io.open(config_path, "w")
    if file then
        file:write(json.encode(save_data))
        file:close()
    end
end

function CrosshairMod:reset_to_defaults()
    self.settings = {
        enabled = true,
        style = {
            crosshair_mode = "auto",
            hide_when_ads = true,
            dot_when_hip = true,
            dot = { size = 4, alpha = 0.9 },
            crosshair = {
                length = 8, thickness = 2, gap = 6,
                alpha = 0.9, outline = true, outline_thickness = 1,
            },
        },
        colors = {
            default = Color(1, 1, 1),
            enemy = Color(1, 0.2, 0.2),
            enemy_special = Color(1, 0.5, 0),
            civilian = Color(1, 1, 0),
            teammate = Color(0, 1, 0),
            hostage = Color(0.5, 0.5, 1),
            interactable = Color(0, 0.8, 1),
            camera = Color(1, 0, 1),
        },
        sway = { enabled = true, multiplier = 1.0, smoothing = 0.15 },
        hitmarker = {
            enabled = true, size = 12, thickness = 2, duration = 0.15,
            normal = { color = Color(1, 1, 1) },
            headshot = { color = Color(1, 0.3, 0.3), scale = 1.2 },
            crit = { color = Color(1, 0.8, 0), scale = 1.3 },
            kill = { color = Color(1, 0, 0), scale = 1.4 },
        },
        dynamic = { enabled = true, expansion_amount = 8, recovery_speed = 15 },
    }
    
    self:save_settings()
    self:rebuild_crosshair()
end

function CrosshairMod:rebuild_crosshair()
    if self._initialized then
        self:destroy_panel()
        self:create_panel()
    end
end

-- Load config on startup
if CrosshairMod._save_path and CrosshairMod._save_path ~= "" then
    CrosshairMod:load_config()
end
