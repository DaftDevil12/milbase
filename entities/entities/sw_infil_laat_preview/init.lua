AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    local requestedModel = self:GetVehicleModel()
    local model = requestedModel ~= "" and requestedModel or SWInfil.DefaultModel

    self:SetModel(model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(120, 190, 255, 115))
    self:DrawShadow(false)

    local idleSequence = self:LookupSequence("idle")
    if idleSequence and idleSequence >= 0 then
        self:ResetSequence(idleSequence)
    end
end

function ENT:OnRemove()
    if SWInfil and SWInfil.SeatPreview == self then
        SWInfil.SeatPreview = nil
        SetGlobalEntity("SWInfilSeatPreview", NULL)
    end
end
