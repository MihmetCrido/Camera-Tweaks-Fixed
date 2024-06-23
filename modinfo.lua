name = "Camera Tweaks"
description = ""
author = "eXiGe, Dollgirl"
version = "1.020"
forumthread = ""
api_version_dst = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

folder_name = folder_name or "camera tweaks"
if not folder_name:find("workshop-") then
    name = name.." -dev"
end

local function BuildNumConfig(start_num, end_num, step)
    local num_table = {}
    local iterator = 1
    for i = start_num, end_num, step do
        num_table[iterator] = {description = i, data = i}
        iterator = iterator + 1
    end
    return num_table
end

local string = ""
local keys = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12","LAlt","RAlt","LCtrl","RCtrl","LShift","RShift","Tab","Capslock","Space","Minus","Equals","Backspace","Insert","Home","Delete","End","Pageup","Pagedown","Print","Scrollock","Pause","Period","Slash","Semicolon","Leftbracket","Rightbracket","Backslash","Up","Down","Left","Right"}
local keylist = {}
for i = 1, #keys do
    keylist[i] = {description = keys[i], data = "KEY_"..string.upper(keys[i])}
end
keylist[#keylist + 1] = {description = "MiddleMouse", data = "MOUSEBUTTON_MIDDLE"}
keylist[#keylist + 1] = {description = "Disabled", data = false}

local view_distances = BuildNumConfig(5, 150, 5)
local pitch_angles = BuildNumConfig(10, 90, 2)
pitch_angles[#pitch_angles].data = 89
local pitch_angle_method = {{description = "Variable", data = "variable"}, {description = "Hybrid", data = "hybrid"}}
local overhead_options = {{description = "90 pitch", data = 1}, {description = "Max distance", data = 2}, {description = "Both", data = 3}}
local boolean = {{description = "Yes", data = true}, {description = "No", data = false}}

local function AddConfig(label, name, options, default, hover)
    return {label = label, name = name, options = options, default = default, hover = hover or ""}
end

configuration_options = {
    AddConfig("Default view distance", "default_distance", view_distances, 40, "Camera default is 30"),
    AddConfig("Minimum view distance", "min_distance", view_distances, 5, "Camera default is 15"),
    AddConfig("Maximum view distance", "max_distance", view_distances, 80, "Camera default is 50"),
    AddConfig("Pitch angle method", "pitch_angle_method", pitch_angle_method, "variable", "Camera default is variable"),
    AddConfig("Minimum distance pitch", "min_distance_pitch", pitch_angles, 40, "Camera default is 30"),
    AddConfig("Maximum distance pitch", "max_distance_pitch", pitch_angles, 40, "Camera default is 60"),
    AddConfig("Zoom step amount", "zoom_amount", BuildNumConfig(1, 10, 1), 5, "Camera default is 4"),
    AddConfig("Overhead toggle options", "overhead_options", overhead_options, 2),
    AddConfig("Overhead toggle key", "overhead_key", keylist, "MOUSEBUTTON_MIDDLE"),
    AddConfig("Spectator toggle key", "spectator_key", keylist, "KEY_F11"),
    AddConfig("Enable partial rotation", "partial_rotation", boolean, false, "ALT + Q or E to rotate by 22.5 when enabled"),
}
