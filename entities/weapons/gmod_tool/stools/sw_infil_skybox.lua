TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.sw_infil_skybox.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.sw_infil_skybox.name", "LAAT Skybox Flight")
    language.Add("tool.sw_infil_skybox.desc", "Designate the tiny LAAT skybox fly-in path.")
    language.Add("tool.sw_infil_skybox.0", "Left-click saves your eye position as tiny LAAT start. Right-click saves your eye position as map-entry finish. Reload saves your eye position as curve/midpoint.")
end

local function canUseTool(ply)
    return IsValid(ply) and (game.SinglePlayer() or ply:IsAdmin() or ply:IsSuperAdmin())
end

local function skyboxPointFromEye(ply)
    local height = GetConVar("sw_infil_skybox_editor_height") and GetConVar("sw_infil_skybox_editor_height"):GetFloat() or 0
    return ply:EyePos() + Vector(0, 0, height)
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    return SWInfil.SetSkyboxPoint("start", skyboxPointFromEye(ply), Angle(0, ply:EyeAngles().y, 0), ply)
end

function TOOL:RightClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    return SWInfil.SetSkyboxPoint("finish", skyboxPointFromEye(ply), Angle(0, ply:EyeAngles().y, 0), ply)
end

function TOOL:Reload(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    return SWInfil.SetSkyboxPoint("mid", skyboxPointFromEye(ply), Angle(0, ply:EyeAngles().y, 0), ply)
end

function TOOL.BuildCPanel(panel)
    panel:Help("LAAT Skybox Flight")
    panel:Help("This edits the tiny LAAT fly-in before the real LAAT spawns.")
    panel:Help("Left-click: save your current eye position as start. Right-click: save your current eye position as finish/map-entry. Reload: save your current eye position as curve/midpoint.")

    panel:Button("Set start at eye position", "sw_infil_skybox_start_here")
    panel:Button("Set curve point at eye position", "sw_infil_skybox_mid_here")
    panel:Button("Set finish at eye position", "sw_infil_skybox_finish_here")
    panel:Button("Preview mini LAAT flight", "sw_infil_skybox_preview")
    panel:Button("Clear custom skybox flight", "sw_infil_skybox_clear")
    panel:Button("Skybox flight status", "sw_infil_skybox_status")
    panel:Button("Test on yourself", "sw_infil_test")

    panel:CheckBox("Tiny skybox fly-in enabled", "sw_infil_skybox_enabled")
    panel:NumSlider("Skybox fly-in seconds", "sw_infil_skybox_time", 0, 20, 1)
    panel:NumSlider("Skybox LAAT scale", "sw_infil_skybox_model_scale", 0.005, 0.25, 3)
    panel:NumSlider("Visible fallback LAAT scale", "sw_infil_skybox_world_fallback_scale", 0.005, 1.5, 3)
    panel:NumSlider("Map minimum visible scale", "sw_infil_skybox_map_min_scale", 0.005, 1.5, 3)
    panel:CheckBox("Draw map fallback through buildings", "sw_infil_skybox_map_ignore_z")
    panel:NumSlider("Editor height offset", "sw_infil_skybox_editor_height", -10000, 10000, 0)

    panel:Help("Flight feel")
    panel:NumSlider("Bank strength", "sw_infil_bank_strength", 0, 4, 2)
    panel:NumSlider("Max bank angle", "sw_infil_max_bank", 0, 60, 0)
    panel:NumSlider("Landing pitch flare", "sw_infil_landing_pitch", -20, 20, 0)
    panel:NumSlider("Turn look-ahead", "sw_infil_turn_lookahead", 0.01, 0.2, 3)

    panel:TextEntry("Skybox prompt", "sw_infil_skybox_prompt")
end
