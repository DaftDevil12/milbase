AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Inspection Crew Member"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "CaseID")
	self:NetworkVar("String", 1, "CrewName")
	self:NetworkVar("String", 2, "CrewRole")
	self:NetworkVar("String", 3, "SpeciesName")
	self:NetworkVar("String", 4, "LanguageName")
	self:NetworkVar("Int", 0, "CrewIndex")
	self:NetworkVar("Bool", 0, "Arrested")
end

if SERVER then
	function ENT:SelectInspectionIdle(force)
		if not force and (self.mb_nextIdleChange or 0) > CurTime() then return end
		local cfg = MilBase.Config and MilBase.Config.SmugglingInspections or {}
		local sequences = table.Copy(cfg.CrewIdleSequences or {
			"idle_all_01", "idle_subtle", "idle_passive", "idle",
		})
		local role = string.lower(tostring(self:GetCrewRole() or ""))
		if string.find(role, "captain", 1, true) then table.insert(sequences, 1, "idle_all_01") end
		if string.find(role, "engineer", 1, true) then table.insert(sequences, 1, "idle_subtle") end
		local valid = {}
		for _, name in ipairs(sequences) do
			local sequence = self:LookupSequence(tostring(name))
			if sequence and sequence >= 0 then valid[#valid + 1] = sequence end
		end
		if #valid > 0 then
			local sequence = valid[math.random(1, #valid)]
			self:ResetSequence(sequence)
			self:SetCycle(math.Rand(0, 0.85))
			self:SetPlaybackRate(math.Rand(0.88, 1.04))
		end
		self.mb_nextIdleChange = CurTime() + math.Rand(12, 24)
	end

	function ENT:Initialize()
		if not util.IsValidModel(self:GetModel()) then
			self:SetModel("models/Humans/Group03/male_07.mdl")
		end
		self:PhysicsInit(SOLID_BBOX)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionGroup(COLLISION_GROUP_NPC)
		self:SetUseType(SIMPLE_USE)
		self:DropToFloor()
		timer.Simple(0, function()
			if IsValid(self) then self:SelectInspectionIdle(true) end
		end)
	end

	function ENT:Think()
		self:SelectInspectionIdle(false)
		self:NextThink(CurTime() + 0.5)
		return true
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		if MilBase.Inspections and MilBase.Inspections.OpenCrewConversation then
			MilBase.Inspections.OpenCrewConversation(activator, self:GetCaseID(), self:GetCrewIndex())
		elseif MilBase.Inspections and MilBase.Inspections.OpenDatapad then
			MilBase.Inspections.OpenDatapad(activator, self:GetCaseID(), "crew", self:GetCrewIndex())
		end
	end

	function ENT:OnTakeDamage(dmg)
		if self:GetArrested() then return end
		if MilBase.Inspections and MilBase.Inspections.OnCrewAttacked then
			MilBase.Inspections.OnCrewAttacked(self, dmg)
		end
	end

	return
end

function ENT:Draw()
	self:DrawModel()
	local ui = MilBase.UI
	local accent = self:GetArrested() and Color(235, 175, 70)
		or (ui and ui.accent or Color(80, 160, 240))
	local text = ui and ui.text or color_white
	local dim = ui and ui.dim or Color(180, 190, 200)
	local pos = self:WorldSpaceCenter() + Vector(0, 0, 48)
	local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	cam.Start3D2D(pos, ang, 0.065)
		surface.SetDrawColor(3, 9, 16, 215)
		surface.DrawRect(-132, -32, 264, 70)
		surface.SetDrawColor(accent)
		surface.DrawOutlinedRect(-132, -32, 264, 70, 1)
		draw.SimpleText(self:GetCrewName(), ui and "MB.Tiny" or "DermaDefaultBold",
			0, -8, text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(self:GetArrested() and "DETAINED" or string.upper(self:GetCrewRole()),
			ui and "MB.Tiny" or "DermaDefault", 0, 11, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.upper(self:GetSpeciesName()) .. " / " .. string.upper(self:GetLanguageName()),
			ui and "MB.Tiny" or "DermaDefault", 0, 24, dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
