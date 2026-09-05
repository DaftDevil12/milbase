AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Landed Inspection Vessel"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CaseID")
	self:NetworkVar("String", 1, "DisplayName")
	self:NetworkVar("String", 2, "InspectionStatus")
end

if SERVER then
	local function smoothStep(value)
		value = math.Clamp(value, 0, 1)
		return value * value * (3 - 2 * value)
	end

	function ENT:Initialize()
		if not util.IsValidModel(self:GetModel()) then
			self:SetModel("models/props_c17/oildrum001.mdl")
		end
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self:SetUseType(SIMPLE_USE)
	end

	function ENT:BeginInspectionLanding(path, speed, minimumDuration, maximumDuration, settleTime)
		if not istable(path) or #path < 2 then
			if MilBase.Inspections and MilBase.Inspections.CompletePhysicalLanding then
				MilBase.Inspections.CompletePhysicalLanding(self:GetCaseID(), self)
			end
			return
		end
		self.mb_landingPath = {}
		for _, point in ipairs(path) do
			if istable(point) and isvector(point.pos) then
				self.mb_landingPath[#self.mb_landingPath + 1] = {
					pos = point.pos,
					ang = isangle(point.ang) and point.ang or self:GetAngles(),
				}
			end
		end
		if #self.mb_landingPath < 2 then return end
		self.mb_landingSpeed = math.max(80, tonumber(speed) or 520)
		self.mb_landingMinDuration = math.max(0.25, tonumber(minimumDuration) or 1.2)
		self.mb_landingMaxDuration = math.max(self.mb_landingMinDuration, tonumber(maximumDuration) or 8)
		self.mb_landingSettleTime = math.max(0, tonumber(settleTime) or 0.8)
		self.mb_landingIndex = 1
		self:SetPos(self.mb_landingPath[1].pos)
		self:SetAngles(self.mb_landingPath[1].ang)
		self:StartLandingSegment()
		local inspections = MilBase.Config and MilBase.Config.SmugglingInspections or {}
		local soundName = tostring(inspections.InspectionApproachSound or "")
		if soundName ~= "" then
			self.mb_engineSound = CreateSound(self, soundName)
			if self.mb_engineSound then self.mb_engineSound:PlayEx(0.38, 96) end
		end
		self:NextThink(CurTime())
	end

	function ENT:StartLandingSegment()
		local path = self.mb_landingPath
		local index = tonumber(self.mb_landingIndex) or 1
		if not path or not path[index] or not path[index + 1] then
			self.mb_landingSettlesAt = CurTime() + (self.mb_landingSettleTime or 0)
			self:SetInspectionStatus("LANDING / SYSTEMS SETTLING")
			return
		end
		self.mb_segmentStartPos = self:GetPos()
		self.mb_segmentStartAng = self:GetAngles()
		self.mb_segmentTargetPos = path[index + 1].pos
		self.mb_segmentTargetAng = path[index + 1].ang
		self.mb_segmentStartedAt = CurTime()
		local distance = self.mb_segmentStartPos:Distance(self.mb_segmentTargetPos)
		self.mb_segmentDuration = math.Clamp(distance / math.max(1, self.mb_landingSpeed or 520),
			self.mb_landingMinDuration or 1.2, self.mb_landingMaxDuration or 8)
		self:SetInspectionStatus(index + 1 >= #path and "FINAL APPROACH / LANDING" or "APPROACHING INSPECTION BAY")
	end

	function ENT:FinishInspectionLanding()
		if self.mb_landingFinished then return end
		self.mb_landingFinished = true
		if self.mb_engineSound then self.mb_engineSound:FadeOut(0.35) self.mb_engineSound = nil end
		local inspections = MilBase.Config and MilBase.Config.SmugglingInspections or {}
		local landingSound = tostring(inspections.InspectionLandingSound or "")
		if landingSound ~= "" then self:EmitSound(landingSound, 72, 100, 0.7) end
		if MilBase.Inspections and MilBase.Inspections.CompletePhysicalLanding then
			MilBase.Inspections.CompletePhysicalLanding(self:GetCaseID(), self)
		end
	end

	function ENT:Think()
		if self.mb_landingFinished then
			self:NextThink(CurTime() + 0.5)
			return true
		end
		if self.mb_landingSettlesAt then
			if CurTime() >= self.mb_landingSettlesAt then self:FinishInspectionLanding() end
			self:NextThink(CurTime() + 0.05)
			return true
		end
		if not self.mb_segmentStartedAt then
			self:NextThink(CurTime() + 0.25)
			return true
		end
		local fraction = math.Clamp((CurTime() - self.mb_segmentStartedAt)
			/ math.max(0.01, self.mb_segmentDuration or 1), 0, 1)
		local eased = smoothStep(fraction)
		self:SetPos(LerpVector(eased, self.mb_segmentStartPos, self.mb_segmentTargetPos))
		self:SetAngles(LerpAngle(eased, self.mb_segmentStartAng, self.mb_segmentTargetAng))
		if fraction >= 1 then
			self:SetPos(self.mb_segmentTargetPos)
			self:SetAngles(self.mb_segmentTargetAng)
			self.mb_landingIndex = (self.mb_landingIndex or 1) + 1
			self:StartLandingSegment()
		end
		self:NextThink(CurTime() + 0.02)
		return true
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Inspections and MilBase.Inspections.OpenDatapad then
			MilBase.Inspections.OpenDatapad(activator, self:GetCaseID(), "ship", 0)
		end
	end

	function ENT:OnRemove()
		if self.mb_engineSound then self.mb_engineSound:Stop() self.mb_engineSound = nil end
		if MilBase.Inspections and MilBase.Inspections.OnPhysicalEntityRemoved then
			MilBase.Inspections.OnPhysicalEntityRemoved(self)
		end
	end
	return
end

function ENT:Draw()
	self:DrawModel()
	local ui = MilBase.UI
	local accent = ui and ui.accent or Color(80, 160, 240)
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(180, 190, 200)
	local pos = self:WorldSpaceCenter() + Vector(0, 0, math.max(52, self:BoundingRadius() * 0.5))
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	cam.Start3D2D(pos, ang, 0.08)
		surface.SetDrawColor(3, 9, 16, 225)
		surface.DrawRect(-190, -42, 380, 84)
		surface.SetDrawColor(accent)
		surface.DrawOutlinedRect(-190, -42, 380, 84, 2)
		draw.SimpleText(string.upper(self:GetDisplayName() ~= "" and self:GetDisplayName() or "INSPECTION VESSEL"),
			ui and "MB.Small" or "DermaDefaultBold", 0, -18, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.upper(self:GetInspectionStatus() ~= "" and self:GetInspectionStatus() or "USE DATAPAD: CUSTOMS CASES"),
			ui and "MB.Tiny" or "DermaDefault", 0, 14, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
