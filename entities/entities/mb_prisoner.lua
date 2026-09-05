AddCSLuaFile()

ENT.Type = "nextbot"
ENT.Base = "base_nextbot"
ENT.PrintName = "Persistent Prisoner"
ENT.Category = "MilBase"
ENT.Spawnable = false
ENT.AdminOnly = true
ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "PrisonerID")
	self:NetworkVar("String", 1, "DisplayName")
	self:NetworkVar("String", 2, "PrisonerRole")
	self:NetworkVar("String", 3, "PrisonStatus")
	self:NetworkVar("String", 4, "CellID")
	self:NetworkVar("String", 5, "RiskLevel")
	self:NetworkVar("String", 6, "NeedSummary")
	self:NetworkVar("String", 7, "MovementState")
	self:NetworkVar("String", 8, "CommandPose")
	self:NetworkVar("String", 9, "LanguageID")
	self:NetworkVar("String", 10, "LanguageName")
	self:NetworkVar("String", 11, "SpeciesName")
	self:NetworkVar("Bool", 0, "Restrained")
	self:NetworkVar("Bool", 1, "Rioting")
end

if SERVER then
	local sequences = {
		idle = { "idle_all_01", "idle_subtle", "idle_passive", "idle" },
		walk = { "walk_all", "walk", "walk_towards" },
		run = { "run_all", "run", "run_protected" },
		attack = { "range_melee_shove_1hand", "meleeattack01", "attackA" },
		restrained = { "idle_suitcase", "idle_all_01", "idle" },
		kneel = { "idle_to_sit_ground", "sit_ground", "idle_all_01", "idle" },
		sit = { "sit", "sit_ground", "idle_all_01", "idle" },
		sleep = { "slump_a", "slump_b", "sit_ground", "idle_all_01", "idle" },
		wall = { "idle_suitcase", "idle_passive", "idle_all_01", "idle" },
		surrender = { "idle_suitcase", "idle_passive", "idle_all_01", "idle" },
	}

	function ENT:SelectPrisonActivity(kind, force)
		kind = tostring(kind or "idle")
		if self:GetRestrained() and kind == "idle" then kind = "restrained" end
		if not force and self.mb_activity == kind then
			if kind ~= "idle" and kind ~= "restrained" then return end
			if (self.mb_nextSequenceRefresh or 0) > CurTime() then return end
		end
		local valid = {}
		for _, name in ipairs(sequences[kind] or sequences.idle) do
			local seq = self:LookupSequence(name)
			if seq and seq >= 0 then valid[#valid + 1] = seq end
		end
		if #valid > 0 then
			self:ResetSequence(valid[math.random(1, #valid)])
			self:SetCycle((kind == "idle" or kind == "restrained") and math.Rand(0, 0.8) or 0)
			self:SetPlaybackRate(kind == "run" and 1.15 or math.Rand(0.93, 1.04))
		end
		self.mb_activity = kind
		self.mb_nextSequenceRefresh = CurTime()
			+ ((kind == "idle" or kind == "restrained") and math.Rand(10, 22) or 1.5)
	end

	function ENT:Initialize()
		if not util.IsValidModel(self:GetModel()) then
			self:SetModel("models/Humans/Group03/male_07.mdl")
		end
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionBounds(Vector(-14, -14, 0), Vector(14, 14, 72))
		self:SetCollisionGroup(COLLISION_GROUP_NPC)
		self:SetUseType(SIMPLE_USE)
		self:SetHealth(math.max(1, self:Health()))
		self:DropToFloor()
		local cfg = (MilBase.Config and MilBase.Config.Prison) or {}
		if self.loco then
			self.loco:SetDesiredSpeed(cfg.PrisonerWalkSpeed or 165)
			self.loco:SetAcceleration(cfg.PrisonerAcceleration or 850)
			self.loco:SetDeceleration(cfg.PrisonerDeceleration or 680)
			self.loco:SetStepHeight(cfg.PrisonerStepHeight or 22)
			self.loco:SetJumpHeight(0)
			self.loco:SetMaxYawRate(cfg.PrisonerTurnRate or 320)
			self.loco:SetJumpGapsAllowed(false)
			self.loco:SetClimbAllowed(false)
			self.loco:SetAvoidAllowed(true)
			self.loco:SetDeathDropHeight(80)
		end
		self.mb_lastThink = CurTime()
		self:SetMovementState("idle")
		self:SetCommandPose("")
		self:SetLanguageID("basic")
		self:SetLanguageName("Galactic Basic")
		self:SetSpeciesName("Human")
		self:SelectPrisonActivity("idle", true)
	end

	function ENT:RunBehaviour()
		while true do
			local now = CurTime()
			local dt = math.Clamp(now - (self.mb_lastThink or now), 0.01, 0.25)
			self.mb_lastThink = now
			if MilBase.Prison and MilBase.Prison.UpdatePrisonerEntity then
				MilBase.Prison.UpdatePrisonerEntity(self, dt)
			end
			coroutine.yield()
		end
	end

	function ENT:BodyUpdate()
		if self:LookupPoseParameter("move_x") >= 0
		and self:LookupPoseParameter("move_y") >= 0 then
			self:BodyMoveXY()
		else
			self:FrameAdvance()
		end
	end

	function ENT:HandleStuck()
		if MilBase.Prison and MilBase.Prison.HandlePrisonerStuck then
			MilBase.Prison.HandlePrisonerStuck(self)
		elseif self.loco then
			self.loco:ClearStuck()
		end
	end

	function ENT:Use(activator)
		if not IsValid(activator) or not activator:IsPlayer() then return end
		-- Holding use opens the quick-command wheel. A short tap still opens
		-- the full custody record after the key has been released.
		timer.Simple(0.24, function()
			if not IsValid(self) or not IsValid(activator)
			or activator:KeyDown(IN_USE) then return end
			if MilBase.Prison and MilBase.Prison.OpenCinematicInterview then
				MilBase.Prison.OpenCinematicInterview(activator, self:GetPrisonerID())
			elseif MilBase.Prison and MilBase.Prison.OpenDatapad then
				MilBase.Prison.OpenDatapad(activator, self:GetPrisonerID())
			end
		end)
	end

	function ENT:OnInjured(dmg)
		if MilBase.Prison and MilBase.Prison.OnPrisonerDamaged then
			MilBase.Prison.OnPrisonerDamaged(self, dmg)
		end
	end

	function ENT:OnKilled(dmg)
		self:SetHealth(0)
		if MilBase.Prison and MilBase.Prison.OnPrisonerDamaged then
			MilBase.Prison.OnPrisonerDamaged(self, dmg)
		end
	end

	function ENT:OnRemove()
		if MilBase.Prison and MilBase.Prison.OnPrisonerRemoved then
			MilBase.Prison.OnPrisonerRemoved(self)
		end
	end
	return
end

function ENT:Draw()
	self:DrawModel()
	local lp = LocalPlayer()
	if not IsValid(lp) or lp:GetPos():DistToSqr(self:GetPos()) > 850 * 850 then return end
	if MilBase.Prison and MilBase.Prison.CanUse and not MilBase.Prison.CanUse(lp) then return end
	local ui = MilBase.UI or {}
	local risk = self:GetRiskLevel()
	local accent = self:GetRioting() and (ui.danger or Color(220, 70, 60))
		or risk == "critical" and (ui.danger or Color(220, 70, 60))
		or risk == "high" and (ui.warn or Color(235, 175, 70))
		or (ui.accent or Color(80, 160, 240))
	local pos = self:WorldSpaceCenter() + Vector(0, 0, 48)
	local ang = Angle(0, lp:EyeAngles().y - 90, 90)
	cam.Start3D2D(pos, ang, 0.06)
		surface.SetDrawColor(3, 9, 16, 225)
		surface.DrawRect(-156, -42, 312, 84)
		surface.SetDrawColor(accent)
		surface.DrawOutlinedRect(-156, -42, 312, 84, 2)
		draw.SimpleText(self:GetDisplayName(), ui.text and "MB.Small" or "DermaDefaultBold",
			0, -20, ui.text or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(string.upper((MilBase.Prison and MilBase.Prison.StatusLabel
			and MilBase.Prison.StatusLabel(self:GetPrisonStatus())) or self:GetPrisonStatus()),
			ui.text and "MB.Tiny" or "DermaDefault", 0, 2, accent,
			TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText((self:GetCellID() ~= "" and string.upper(self:GetCellID()) .. "  •  " or "")
			.. self:GetNeedSummary(), ui.text and "MB.Tiny" or "DermaDefault", 0, 22,
			ui.dim or Color(180, 190, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end
