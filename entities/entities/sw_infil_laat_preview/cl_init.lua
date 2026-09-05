include("shared.lua")

function ENT:Initialize()
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(120, 190, 255, 115))
end

function ENT:Draw()
    self:DrawModel()
end
