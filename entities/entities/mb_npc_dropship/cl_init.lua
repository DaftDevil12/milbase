include("shared.lua")

function ENT:Initialize()
	self.LastPhase = nil
end

function ENT:Draw()
	local pos, ang = self:GetFlightTransform(CurTime())
	local phase = self:GetDropPhase(CurTime())

	if phase ~= self.LastPhase then
		self.LastPhase = phase
		local sequence = self:LookupSequence(phase == "landed" and "idle" or "fly")
		if sequence and sequence >= 0 then
			self:ResetSequence(sequence)
		end
	end

	self:FrameAdvance(FrameTime())
	self:SetRenderOrigin(pos)
	self:SetRenderAngles(ang)
	self:DrawModel()
	self:SetRenderOrigin()
	self:SetRenderAngles()
end
