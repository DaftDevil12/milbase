include("shared.lua")

function ENT:Initialize()
	self.LastPhase = nil
	self.CarriedModelPath = nil
	self.CarriedModel = nil
end

function ENT:EnsureCarriedModel()
	local model = self:GetCarriedModel()
	if model == "" or self:GetVehicleDropped() then
		if IsValid(self.CarriedModel) then
			self.CarriedModel:Remove()
		end
		self.CarriedModel = nil
		self.CarriedModelPath = nil
		return nil
	end

	if IsValid(self.CarriedModel) and self.CarriedModelPath == model then
		return self.CarriedModel
	end

	if IsValid(self.CarriedModel) then
		self.CarriedModel:Remove()
	end

	self.CarriedModel = ClientsideModel(model, RENDERGROUP_BOTH)
	self.CarriedModelPath = model

	if IsValid(self.CarriedModel) then
		self.CarriedModel:SetNoDraw(true)
		return self.CarriedModel
	end
end

function ENT:DrawCarriedVehicle(pos, ang)
	local carried = self:EnsureCarriedModel()
	if not IsValid(carried) then return end

	local cpos, cang = LocalToWorld(self:GetCarryOffset(), angle_zero, pos, ang)
	carried:SetRenderOrigin(cpos)
	carried:SetRenderAngles(cang)
	carried:DrawModel()
	carried:SetRenderOrigin()
	carried:SetRenderAngles()
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

	self:DrawCarriedVehicle(pos, ang)
end

function ENT:OnRemove()
	if IsValid(self.CarriedModel) then
		self.CarriedModel:Remove()
	end
end
