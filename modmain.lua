local _G = GLOBAL
if _G.TheNet:IsDedicated() then
    return
end

local GetTime = _G.GetTime
local IsPaused = _G.IsPaused
local TheInput = _G.TheInput
local CONTROL_FORCE_INSPECT = _G.CONTROL_FORCE_INSPECT
local CONTROL_ROTATE_LEFT = _G.CONTROL_ROTATE_LEFT
local CONTROL_ROTATE_RIGHT = _G.CONTROL_ROTATE_RIGHT
local CONTROL_ZOOM_IN = _G.CONTROL_ZOOM_IN
local CONTROL_ZOOM_OUT = _G.CONTROL_ZOOM_OUT
local MOUSEBUTTON_MIDDLE = _G.MOUSEBUTTON_MIDDLE
local MOUSEBUTTON_SCROLLDOWN = _G.MOUSEBUTTON_SCROLLDOWN
local MOUSEBUTTON_SCROLLUP = _G.MOUSEBUTTON_SCROLLUP
local TheCamera
local ThePlayer

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

local default_distance = GetModConfigData("default_distance")
local zoom_amount = GetModConfigData("zoom_amount")
local pitch_angle_method = GetModConfigData("pitch_angle_method") or "variable"
local min_distance = GetModConfigData("min_distance")
local max_distance = GetModConfigData("max_distance")
local min_distance_pitch = GetModConfigData("min_distance_pitch")
local max_distance_pitch = GetModConfigData("max_distance_pitch")
local overhead_options = GetModConfigData("overhead_options")
local overhead_key = GetKeyFromConfig("overhead_key")
local partial_rotation = GetModConfigData("partial_rotation")

AddClassPostConstruct("cameras/followcamera", function(self)
    TheCamera = self

    local FollowCameraSetDefault = self.SetDefault
    self.SetDefault = function(self)
        FollowCameraSetDefault(self)
        self.distancetarget = default_distance
        self.zoomstep = zoom_amount
        self.distancegain = 3
        if pitch_angle_method == "variable" then
            self.mindist = min_distance
            self.maxdist = max_distance
            self.mindistpitch = min_distance_pitch
            self.maxdistpitch = max_distance_pitch
        end
    end

    self.ZoomIn = function(self, step)
        self.distancetarget = math.max(min_distance, self.distancetarget - (step or self.zoomstep))
    end
    -- these overrides are needed for hybrid_pitch_angle
    self.ZoomOut = function(self, step)
        self.distancetarget = math.min(max_distance, self.distancetarget + (step or self.zoomstep))
    end

    local overhead_toggle = false
    local overhead_maxdist = overhead_options > 1
    self.ToggleOverheadView = function(self)
        overhead_toggle = not overhead_toggle
        if overhead_maxdist then
            self.distancetarget = overhead_toggle and max_distance or default_distance
        end
    end

    local overhead_90pitch = overhead_options % 2 ~= 0
    local hybrid_pitch_angle = pitch_angle_method == "hybrid"
    local FollowCameraApply = self.Apply
    self.Apply = function(self)
        if overhead_90pitch and overhead_toggle then
            self.pitch = 89
        elseif hybrid_pitch_angle then
            self.pitch = math.max(min_distance_pitch, math.min(max_distance_pitch, self.pitch))
        end
        FollowCameraApply(self)
    end
end)

AddClassPostConstruct("screens/playerhud", function(self)
    self.UpdateClouds = function() --[[disabled]]
    end
end)

AddComponentPostInit("focalpoint", function(self, inst)
    self.StartFocusSource = function() --[[disabled]]
    end
end)

local function GetRotationAmount()
    return partial_rotation and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and 22.5 or 45
end

local lastrotatetime = 0
local function Rotate(time)
    if time - lastrotatetime < 0.2 then
        return
    end
    local rotateamount = 0
    if TheInput:IsControlPressed(CONTROL_ROTATE_LEFT) and not ThePlayer.HUD:HasInputFocus() then
        rotateamount = -GetRotationAmount()
    elseif TheInput:IsControlPressed(CONTROL_ROTATE_RIGHT) and not ThePlayer.HUD:HasInputFocus() then
        rotateamount = GetRotationAmount()
    end
    if rotateamount == 0 then
        return
    end
    lastrotatetime = time
    if not IsPaused() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() + rotateamount)
    elseif ThePlayer.HUD:IsMapScreenOpen() then
        TheCamera:SetHeadingTarget(TheCamera:GetHeadingTarget() + rotateamount)
        TheCamera:Snap()
    end
end

local lastzoomtime
local function NormalZoom(time)
    if lastzoomtime and time - lastzoomtime < 0.1 then
        return
    end
    if TheInput:IsControlPressed(CONTROL_ZOOM_IN) then
        TheCamera:ZoomIn()
        lastzoomtime = time
    elseif TheInput:IsControlPressed(CONTROL_ZOOM_OUT) then
        TheCamera:ZoomOut()
        lastzoomtime = time
    end
end

local function CanControl()
    return ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:IsCraftingOpen() and not ThePlayer.HUD:HasInputFocus() and
               TheCamera:CanControl()
end

local smooth_zoom = TheInput:GetControlIsMouseWheel(CONTROL_ZOOM_IN) and
                        TheInput:GetControlIsMouseWheel(CONTROL_ZOOM_OUT)
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= _G.ThePlayer then
        return
    end
    ThePlayer = _G.ThePlayer

    self.DoCameraControl = function(self)
        if not TheCamera:CanControl() or not ThePlayer.HUD then
            return
        end
        local time = GetTime()
        Rotate(time)
        if smooth_zoom or ThePlayer.HUD:IsCraftingOpen() then
            return
        end
        NormalZoom(time)
    end
end)

local mouse_middle_overhead = overhead_key == MOUSEBUTTON_MIDDLE
local mouse = {
    [MOUSEBUTTON_MIDDLE] = function()
        if mouse_middle_overhead then
            TheCamera:ToggleOverheadView()
        end
    end,
    [MOUSEBUTTON_SCROLLDOWN] = function()
        if smooth_zoom then
            TheCamera:ZoomOut()
        end
    end,
    [MOUSEBUTTON_SCROLLUP] = function()
        if smooth_zoom then
            TheCamera:ZoomIn()
        end
    end
}
TheInput:AddMouseButtonHandler(function(button, down)
    if down and mouse[button] and CanControl() then
        mouse[button]()
    end
end)

if not mouse_middle_overhead then
    TheInput:AddKeyUpHandler(overhead_key, function()
        if CanControl() then
            TheCamera:ToggleOverheadView()
        end
    end)
end

local spectator_toggle = false
TheInput:AddKeyUpHandler(GetKeyFromConfig("spectator_key"), function()
    if not CanControl() then
        return
    end
    spectator_toggle = not spectator_toggle
    if spectator_toggle then
        ThePlayer:Hide()
        ThePlayer.HUD:Hide()
        ThePlayer.DynamicShadow:Enable(false)
    else
        ThePlayer:Show()
        ThePlayer.HUD:Show()
        ThePlayer.DynamicShadow:Enable(true)
    end
end)

TheInput:AddControlMappingHandler(function()
    smooth_zoom = TheInput:GetControlIsMouseWheel(CONTROL_ZOOM_IN) and TheInput:GetControlIsMouseWheel(CONTROL_ZOOM_OUT)
end)