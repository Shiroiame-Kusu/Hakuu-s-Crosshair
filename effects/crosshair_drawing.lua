--[[
    Hakuu's Crosshair Mod - Drawing Module
    Handles crosshair rendering and visual elements
]]

if not CrosshairMod then return end

-- ============================================================================
-- Panel Management
-- ============================================================================

function CrosshairMod:get_hud_panel()
    if managers.hud then
        local panel = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)
        if panel and panel.panel then
            return panel.panel
        end
        
        local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
        if hud and hud.panel then
            return hud.panel
        end
    end
    return nil
end

function CrosshairMod:create_panel()
    log("[Hakuu's Crosshair Drawing] create_panel() called")
    
    -- If panel already exists and is valid, don't recreate
    if self._state.panel and alive(self._state.panel) then
        log("[Hakuu's Crosshair Drawing] Panel already exists, returning")
        return
    end
    
    -- Clean up potentially stale invalid references
    if self._state.panel then
        self._state.panel = nil
        self._state.crosshair_elements = {}
        self._state.hitmarker_panel = nil
    end
    
    local hud_panel = self:get_hud_panel()
    if not hud_panel then
        log("[Hakuu's Crosshair Drawing] ERROR: hud_panel is nil")
        return
    end
    log("[Hakuu's Crosshair Drawing] Got hud_panel")
    
    if hud_panel:child("modern_crosshair_panel") then
        hud_panel:remove(hud_panel:child("modern_crosshair_panel"))
    end
    
    local screen_w, screen_h = hud_panel:size()
    local panel_size = 200
    
    self._state.panel = hud_panel:panel({
        name = "modern_crosshair_panel",
        x = (screen_w - panel_size) / 2,
        y = (screen_h - panel_size) / 2,
        w = panel_size,
        h = panel_size,
        layer = 100,
    })
    
    self._state.current_color = self.settings.colors.default
    self._state.target_color = self.settings.colors.default
    self._state.dynamic_gap = self.settings.style.crosshair.gap
    self._state.target_dynamic_gap = self.settings.style.crosshair.gap
    
    log("[Hakuu's Crosshair Drawing] Creating crosshair elements...")
    self:create_crosshair_elements()
    log("[Hakuu's Crosshair Drawing] Crosshair elements created")
    
    log("[Hakuu's Crosshair Drawing] Creating hitmarker panel...")
    log("[Hakuu's Crosshair Drawing] self.settings.hitmarker = " .. tostring(self.settings.hitmarker))
    if self.settings.hitmarker then
        log("[Hakuu's Crosshair Drawing] self.settings.hitmarker.normal = " .. tostring(self.settings.hitmarker.normal))
    end
    self:create_hitmarker_panel()
    log("[Hakuu's Crosshair Drawing] Hitmarker panel created")
    
    self._initialized = true
    log("[Hakuu's Crosshair Drawing] create_panel() completed successfully")
end

function CrosshairMod:destroy_panel()
    -- Stop hitmarker animation to prevent callback accessing destroyed panel
    if self._state.hitmarker_panel and alive(self._state.hitmarker_panel) then
        self._state.hitmarker_panel:stop()
    end
    
    if self._state.panel and alive(self._state.panel) then
        -- Stop all animations on main panel
        self._state.panel:stop()
        
        local parent = self._state.panel:parent()
        if parent then
            parent:remove(self._state.panel)
        end
    end
    
    self._state.panel = nil
    self._state.crosshair_elements = {}
    self._state.hitmarker_panel = nil
    self._initialized = false
end

-- ============================================================================
-- Crosshair Elements
-- ============================================================================

function CrosshairMod:create_crosshair_elements()
    if not self._state.panel or not alive(self._state.panel) then return end
    
    local panel = self._state.panel
    local center = panel:w() / 2
    
    -- 安全获取设置
    local style = self.settings.style or {}
    local settings = style.crosshair or {}
    local dot_settings = style.dot or {}
    local colors = self.settings.colors or {}
    local color = colors.default or Color(1, 1, 1)
    
    self._state.crosshair_elements = {}
    
    -- Center dot (使用圆形纹理)
    local dot_size = dot_settings.size or 4
    local dot_alpha = dot_settings.alpha or 0.9
    local dot = panel:bitmap({
        name = "dot",
        w = dot_size,
        h = dot_size,
        color = color,
        alpha = dot_alpha,
        layer = 2,
    })
    dot:set_center(center, center)
    self._state.crosshair_elements.dot = dot
    
    -- 获取准星参数
    local thickness = settings.thickness or 2
    local length = settings.length or 8
    local alpha = settings.alpha or 0.9
    local outline = settings.outline
    local outline_thickness = settings.outline_thickness or 1
    
    -- Outline elements
    if outline then
        local outline_offset = outline_thickness
        
        -- Top outline
        local top_outline = panel:rect({
            name = "top_outline",
            w = thickness + outline_offset * 2,
            h = length + outline_offset * 2,
            color = Color.black,
            alpha = alpha * 0.8,
            layer = 1,
        })
        self._state.crosshair_elements.top_outline = top_outline
        
        -- Bottom outline
        local bottom_outline = panel:rect({
            name = "bottom_outline",
            w = thickness + outline_offset * 2,
            h = length + outline_offset * 2,
            color = Color.black,
            alpha = alpha * 0.8,
            layer = 1,
        })
        self._state.crosshair_elements.bottom_outline = bottom_outline
        
        -- Left outline
        local left_outline = panel:rect({
            name = "left_outline",
            w = length + outline_offset * 2,
            h = thickness + outline_offset * 2,
            color = Color.black,
            alpha = alpha * 0.8,
            layer = 1,
        })
        self._state.crosshair_elements.left_outline = left_outline
        
        -- Right outline
        local right_outline = panel:rect({
            name = "right_outline",
            w = length + outline_offset * 2,
            h = thickness + outline_offset * 2,
            color = Color.black,
            alpha = alpha * 0.8,
            layer = 1,
        })
        self._state.crosshair_elements.right_outline = right_outline
    end
    
    -- Main crosshair lines
    local top = panel:rect({
        name = "top",
        w = thickness,
        h = length,
        color = color,
        alpha = alpha,
        layer = 2,
    })
    self._state.crosshair_elements.top = top
    
    local bottom = panel:rect({
        name = "bottom",
        w = thickness,
        h = length,
        color = color,
        alpha = alpha,
        layer = 2,
    })
    self._state.crosshair_elements.bottom = bottom
    
    local left = panel:rect({
        name = "left",
        w = length,
        h = thickness,
        color = color,
        alpha = alpha,
        layer = 2,
    })
    self._state.crosshair_elements.left = left
    
    local right = panel:rect({
        name = "right",
        w = length,
        h = thickness,
        color = color,
        alpha = alpha,
        layer = 2,
    })
    self._state.crosshair_elements.right = right
    
    self:update_crosshair_positions()
end

function CrosshairMod:update_crosshair_positions()
    if not self._state.panel or not alive(self._state.panel) then return end
    
    local panel = self._state.panel
    local center = panel:w() / 2
    
    -- 安全获取设置
    local style = self.settings.style or {}
    local settings = style.crosshair or {}
    local length = settings.length or 8
    
    -- 安全获取 sway offset
    local offset_x = 0
    local offset_y = 0
    if self._state.sway_offset then
        offset_x = self._state.sway_offset.x or 0
        offset_y = self._state.sway_offset.y or 0
    end
    
    local gap = self._state.dynamic_gap or 6
    
    local elements = self._state.crosshair_elements
    
    if elements.dot and alive(elements.dot) then
        elements.dot:set_center(center + offset_x, center + offset_y)
    end
    
    -- Position crosshair lines
    if elements.top and alive(elements.top) then
        elements.top:set_center(center + offset_x, center - gap - length / 2 + offset_y)
    end
    if elements.bottom and alive(elements.bottom) then
        elements.bottom:set_center(center + offset_x, center + gap + length / 2 + offset_y)
    end
    if elements.left and alive(elements.left) then
        elements.left:set_center(center - gap - length / 2 + offset_x, center + offset_y)
    end
    if elements.right and alive(elements.right) then
        elements.right:set_center(center + gap + length / 2 + offset_x, center + offset_y)
    end
    
    -- Position outlines
    local outline = settings.outline
    if outline then
        if elements.top_outline and alive(elements.top_outline) then
            elements.top_outline:set_center(center + offset_x, center - gap - length / 2 + offset_y)
        end
        if elements.bottom_outline and alive(elements.bottom_outline) then
            elements.bottom_outline:set_center(center + offset_x, center + gap + length / 2 + offset_y)
        end
        if elements.left_outline and alive(elements.left_outline) then
            elements.left_outline:set_center(center - gap - length / 2 + offset_x, center + offset_y)
        end
        if elements.right_outline and alive(elements.right_outline) then
            elements.right_outline:set_center(center + gap + length / 2 + offset_x, center + offset_y)
        end
    end
end

function CrosshairMod:update_crosshair_color(color)
    if not color then return end
    
    local elements = self._state.crosshair_elements
    
    if elements.dot and alive(elements.dot) then
        elements.dot:set_color(color)
    end
    if elements.top and alive(elements.top) then
        elements.top:set_color(color)
    end
    if elements.bottom and alive(elements.bottom) then
        elements.bottom:set_color(color)
    end
    if elements.left and alive(elements.left) then
        elements.left:set_color(color)
    end
    if elements.right and alive(elements.right) then
        elements.right:set_color(color)
    end
end

function CrosshairMod:update_crosshair_visibility()
    local elements = self._state.crosshair_elements or {}
    local is_aiming = self._state.in_steelsight
    local style = self.settings.style or {}
    
    -- 新设置: crosshair_mode ("auto", "dot", "cross") 和 hide_when_ads
    local crosshair_mode = style.crosshair_mode or "auto"
    local hide_when_ads = style.hide_when_ads
    if hide_when_ads == nil then hide_when_ads = true end
    
    -- 检测是否处于可射击状态（用于自动模式）
    local can_shoot = true
    
    if managers.player then
        local player = managers.player:player_unit()
        if player and alive(player) then
            local movement = player:movement()
            if movement then
                -- 使用 movement:in_clean_state() 检测潜入状态
                if movement.in_clean_state and movement:in_clean_state() then
                    can_shoot = false
                end
                
                local current_state = movement:current_state()
                if current_state then
                    -- 检测互动状态: _interact_expire_t ~= nil
                    if current_state._interact_expire_t then
                        can_shoot = false
                    end
                    
                    -- 检测近战状态
                    if current_state._state_data then
                        if current_state._state_data.meleeing or current_state._state_data.melee_expire_t then
                            can_shoot = false
                        end
                    end
                    
                    -- 检测使用物品状态
                    if current_state._use_item_expire_t then
                        can_shoot = false
                    end
                end
            end
        end
    end
    
    local show_dot = false
    local show_cross = false
    local hide_all = false
    
    -- 开镜时根据 hide_when_ads 设置决定是否隐藏
    if is_aiming and hide_when_ads then
        hide_all = true
    elseif crosshair_mode == "dot" then
        -- 手动圆点模式
        show_dot = true
    elseif crosshair_mode == "cross" then
        -- 手动十字模式
        show_cross = true
    elseif crosshair_mode == "auto" then
        -- 自动模式：
        -- - 开镜不显示（如果 hide_when_ads）
        -- - 腰射（可射击）= 十字
        -- - 非射击状态（潜入、互动、近战等）= 圆点
        if is_aiming then
            -- 开镜时如果不隐藏，显示十字
            show_cross = true
        elseif not can_shoot then
            -- 非射击状态显示圆点
            show_dot = true
        else
            -- 腰射可射击时显示十字
            show_cross = true
        end
    else
        -- 默认显示十字
        show_cross = true
    end
    
    -- 如果隐藏全部，则不显示任何元素
    if hide_all then
        show_dot = false
        show_cross = false
    end
    
    if elements.dot and alive(elements.dot) then
        elements.dot:set_visible(show_dot)
    end
    
    local cross_elements = {"top", "bottom", "left", "right", "top_outline", "bottom_outline", "left_outline", "right_outline"}
    for _, name in ipairs(cross_elements) do
        if elements[name] and alive(elements[name]) then
            elements[name]:set_visible(show_cross)
        end
    end
end

-- ============================================================================
-- Hitmarker Panel
-- ============================================================================

function CrosshairMod:create_hitmarker_panel()
    log("[Hakuu's Crosshair Drawing] create_hitmarker_panel() called")
    
    if not self._state.panel or not alive(self._state.panel) then
        log("[Hakuu's Crosshair Drawing] ERROR: panel is nil or not alive")
        return
    end
    
    local panel = self._state.panel
    local center = panel:w() / 2
    
    if panel:child("hitmarker_panel") then
        log("[Hakuu's Crosshair Drawing] Removing existing hitmarker_panel")
        panel:remove(panel:child("hitmarker_panel"))
    end
    
    local hit_panel = panel:panel({
        name = "hitmarker_panel",
        x = 0,
        y = 0,
        w = panel:w(),
        h = panel:h(),
        layer = 50,
        visible = false,
    })
    
    -- 安全获取 hitmarker 设置，提供默认值
    local hitmarker = self.settings.hitmarker or {}
    local size = hitmarker.size or 12
    local thickness = hitmarker.thickness or 2
    local normal_config = hitmarker.normal or {}
    local color = normal_config.color or Color(1, 1, 1)
    
    -- X shape (4 diagonal lines)
    local offset = size * 0.7
    
    -- Top-left to bottom-right
    hit_panel:rect({
        name = "hit_tl",
        w = thickness,
        h = size,
        rotation = 45,
        color = color,
        layer = 1,
    }):set_center(center - offset / 2, center - offset / 2)
    
    hit_panel:rect({
        name = "hit_br",
        w = thickness,
        h = size,
        rotation = 45,
        color = color,
        layer = 1,
    }):set_center(center + offset / 2, center + offset / 2)
    
    -- Top-right to bottom-left
    hit_panel:rect({
        name = "hit_tr",
        w = thickness,
        h = size,
        rotation = -45,
        color = color,
        layer = 1,
    }):set_center(center + offset / 2, center - offset / 2)
    
    hit_panel:rect({
        name = "hit_bl",
        w = thickness,
        h = size,
        rotation = -45,
        color = color,
        layer = 1,
    }):set_center(center - offset / 2, center + offset / 2)
    
    self._state.hitmarker_panel = hit_panel
end
