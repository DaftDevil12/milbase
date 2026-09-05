TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.sw_infil_route.name"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ClientConVar = {
    route_id = "main",
    route_name = "Main Landing Zone"
}

if CLIENT then
    language.Add("tool.sw_infil_route.name", "LAAT Infil Route")
    language.Add("tool.sw_infil_route.desc", "Set the cinematic LAAT spawn route for tactical infiltrations.")
    language.Add("tool.sw_infil_route.0", "Left-click ground for the landing zone. Right-click while standing/flying where the LAAT starts. Reload clears the route.")
end

local function canUseTool(ply)
    return IsValid(ply) and (game.SinglePlayer() or ply:IsAdmin() or ply:IsSuperAdmin())
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    local hover = GetConVar("sw_infil_hover_height") and GetConVar("sw_infil_hover_height"):GetFloat() or 120
    local hitPos = trace.Hit and trace.HitPos or ply:GetPos()
    local pos = hitPos + Vector(0, 0, hover)
    local ang = Angle(0, ply:EyeAngles().y, 0)

    return SWInfil.SetRoutePoint("land", pos, ang, ply, self:GetClientInfo("route_id"), self:GetClientInfo("route_name"))
end

function TOOL:RightClick()
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    local pos = ply:GetPos() + Vector(0, 0, 80)
    local ang = Angle(0, ply:EyeAngles().y, 0)

    return SWInfil.SetRoutePoint("start", pos, ang, ply, self:GetClientInfo("route_id"), self:GetClientInfo("route_name"))
end

function TOOL:Reload()
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    SWInfil.ClearRoute(ply, self:GetClientInfo("route_id"))
    return true
end

function TOOL.BuildCPanel(panel)
    panel:Help("Star Wars Tactical LAAT Infil")
    panel:Help("Set Spawn ID/Name first to create multiple deployment choices. Use IDs like main, city, base, hangar.")
    panel:TextEntry("Spawn ID", "sw_infil_route_route_id")
    panel:TextEntry("Spawn display name", "sw_infil_route_route_name")
    panel:Help("1) Noclip to where the LAAT should appear, then Right-click.")
    panel:Help("2) Aim at the landing zone and Left-click.")
    panel:Help("3) Run a test before enabling it for everyone.")

    panel:Button("Test on yourself", "sw_infil_test")
    panel:Button("Run for all players", "sw_infil_play_all")
    panel:Button("Clear active Spawn ID route", "sw_infil_route_clear")

    panel:CheckBox("Run when players spawn", "sw_infil_on_spawn")
    panel:CheckBox("Show deployment menu on spawn", "sw_infil_spawn_menu_enabled")
    panel:CheckBox("Allow SPACE skip", "sw_infil_allow_skip")
    panel:CheckBox("Share active LAAT seats", "sw_infil_share_laat")
    panel:CheckBox("Tiny skybox fly-in first", "sw_infil_skybox_enabled")
    panel:CheckBox("Ball turrets defend landing", "sw_infil_turrets_enabled")
    panel:CheckBox("Use LAAT/LVS turret attachments", "sw_infil_turret_use_attachments")

    panel:NumSlider("Approach seconds", "sw_infil_approach_time", 2, 30, 1)
    panel:NumSlider("Door-open seconds", "sw_infil_ground_time", 0.5, 20, 1)
    panel:NumSlider("Departure seconds", "sw_infil_departure_time", 1, 20, 1)
    panel:NumSlider("Skybox fly-in seconds", "sw_infil_skybox_time", 0, 20, 1)
    panel:NumSlider("Skybox LAAT scale", "sw_infil_skybox_model_scale", 0.005, 0.25, 3)
    panel:NumSlider("Skybox start distance", "sw_infil_skybox_distance", 500, 20000, 0)
    panel:NumSlider("Skybox height", "sw_infil_skybox_height", -2000, 8000, 0)
    panel:NumSlider("Landing hover height", "sw_infil_hover_height", 16, 512, 0)
    panel:NumSlider("Camera forward/back", "sw_infil_camera_forward", -80, 80, 0)
    panel:NumSlider("Camera left/right", "sw_infil_camera_right", -80, 80, 0)
    panel:NumSlider("Camera up/down", "sw_infil_camera_up", 24, 96, 0)
    panel:NumSlider("Turret range", "sw_infil_turret_range", 256, 12000, 0)
    panel:NumSlider("Turret damage", "sw_infil_turret_damage", 1, 500, 0)
    panel:NumSlider("Turret fire interval", "sw_infil_turret_interval", 0.05, 2, 2)
    panel:TextEntry("Left turret attachment", "sw_infil_turret_left_attachment")
    panel:TextEntry("Right turret attachment", "sw_infil_turret_right_attachment")
    panel:Button("Print LAAT model attachments", "sw_infil_turret_list_attachments")

    panel:TextEntry("LAAT model path", "sw_infil_model")
    panel:TextEntry("Skybox prompt", "sw_infil_skybox_prompt")
end
