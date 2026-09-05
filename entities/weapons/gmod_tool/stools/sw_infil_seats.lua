TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.sw_infil_seats.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.sw_infil_seats.name", "LAAT Seat Editor")
    language.Add("tool.sw_infil_seats.desc", "Spawn a LAAT preview and place passenger seat ghosts.")
    language.Add("tool.sw_infil_seats.0", "Left-click ground to spawn/move preview LAAT. Right-click from your current position to add a seat. Reload removes the nearest seat.")
end

local function canUseTool(ply)
    return IsValid(ply) and (game.SinglePlayer() or ply:IsAdmin() or ply:IsSuperAdmin())
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    local height = GetConVar("sw_infil_seat_preview_height") and GetConVar("sw_infil_seat_preview_height"):GetFloat() or 120
    local hitPos = trace.Hit and trace.HitPos or (ply:GetPos() + ply:EyeAngles():Forward() * 300)
    local pos = hitPos + Vector(0, 0, height)
    local ang = Angle(0, ply:EyeAngles().y, 0)

    return SWInfil.SpawnSeatPreview(pos, ang, ply) ~= nil
end

function TOOL:RightClick()
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    return SWInfil.AddSeatFromPlayer(ply)
end

function TOOL:Reload()
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not canUseTool(ply) then return false end

    return SWInfil.RemoveNearestSeat(ply)
end

function TOOL.BuildCPanel(panel)
    panel:Help("LAAT Seat Editor")
    panel:Help("Left-click ground to spawn or move the transparent LAAT preview.")
    panel:Help("Noclip to a passenger position, look the way that passenger should face, then Right-click.")
    panel:Help("Reload removes the nearest seat ghost. Seats save per map.")

    panel:Button("Spawn preview here", "sw_infil_seats_preview_here")
    panel:Button("Add seat at my position", "sw_infil_seats_add_here")
    panel:Button("Remove nearest seat", "sw_infil_seats_remove_nearest")
    panel:Button("Restore LVS defaults", "sw_infil_seats_defaults")
    panel:Button("Clear all seats", "sw_infil_seats_clear")
    panel:Button("Remove preview LAAT", "sw_infil_seats_close_preview")
    panel:Button("Seat editor status", "sw_infil_seats_status")

    panel:CheckBox("Show passengers in LAAT", "sw_infil_show_passengers")
    panel:CheckBox("Share active LAAT seats", "sw_infil_share_laat")

    panel:NumSlider("Preview spawn height", "sw_infil_seat_preview_height", -256, 512, 0)
    panel:NumSlider("Passenger look left/right", "sw_infil_look_yaw", 25, 180, 0)
    panel:NumSlider("Passenger look up/down", "sw_infil_look_pitch", 15, 89, 0)
    panel:NumSlider("Body up/down", "sw_infil_anchor_up", -32, 128, 0)
    panel:NumSlider("Camera forward/back", "sw_infil_camera_forward", -80, 80, 0)
    panel:NumSlider("Camera left/right", "sw_infil_camera_right", -80, 80, 0)
    panel:NumSlider("Camera up/down", "sw_infil_camera_up", 24, 96, 0)

    panel:TextEntry("Ghost playermodel", "sw_infil_ghost_model")
    panel:TextEntry("LAAT model path", "sw_infil_model")
end
