ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Tactical Infil LAAT"
ENT.Author = "Codex"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "RouteStart")
    self:NetworkVar("Vector", 1, "RouteLand")
    self:NetworkVar("Vector", 2, "RouteDepart")

    self:NetworkVar("Angle", 0, "RouteStartAngle")
    self:NetworkVar("Angle", 1, "RouteLandAngle")

    self:NetworkVar("Float", 0, "SequenceStarted")
    self:NetworkVar("Float", 1, "ApproachDuration")
    self:NetworkVar("Float", 2, "HoldDuration")
    self:NetworkVar("Float", 3, "DepartureDuration")

    self:NetworkVar("Bool", 0, "DoorsOpen")
    self:NetworkVar("Entity", 0, "Occupant")
    self:NetworkVar("Int", 0, "SeatNumber")
    self:NetworkVar("String", 0, "VehicleModel")
end
