ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "LAAT Seat Editor Preview"
ENT.Author = "Codex"
ENT.Category = "Star Wars RP"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "VehicleModel")
end
