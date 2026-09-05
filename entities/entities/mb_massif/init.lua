AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local function cfg()
	return (MilBase.Config and MilBase.Config.Massif) or {}
end

local defaultAnimations = {
	idle = { "idle_all_01", "idle_all_02", "idle_all", "cidle_all", "idle", "stand_idle", "Idle01" },
	walk = { "walk_all", "walk", "Walk_ALL", "walk_lower", "menu_walk" },
	run = { "run_all", "run", "sprint", "Run_ALL", "run_lower" },
	crouchIdle = { "cidle_all", "crouch_idle", "crouchidle", "idle_crouch" },
	crouchWalk = { "cwalk_all", "crouch_walk", "crouchwalk", "walk_crouch" },
	attack = { "attack", "bite", "melee", "attack1", "gesture_melee_attack1", "range_melee" },
	sniff = { "sniff", "search", "gesture_item_place", "gesture_signal_forward" },
	death = { "death", "dead", "death_01", "ragdoll" },
}

-- The Massif content is a PLAYER model. Player models use ACT_HL2MP/ACT_MP
-- activities and 9-way move pose parameters, not the ACT_* set used by HL2 NPCs.
-- Keep all activity constants optional so this remains compatible with branches
-- that do not expose every ACT_MP alias.
local function activityList(...)
	local out = {}
	for i = 1, select("#", ...) do
		local activity = select(i, ...)
		if isnumber(activity) then out[#out + 1] = activity end
	end
	return out
end

local animationActivities = {
	idle = activityList(ACT_HL2MP_IDLE, ACT_HL2MP_IDLE_PASSIVE, ACT_HL2MP_IDLE_MELEE2, ACT_MP_STAND_IDLE),
	walk = activityList(ACT_HL2MP_WALK, ACT_HL2MP_WALK_PASSIVE, ACT_HL2MP_WALK_MELEE2, ACT_MP_WALK),
	run = activityList(ACT_HL2MP_RUN, ACT_HL2MP_RUN_FAST, ACT_HL2MP_RUN_PASSIVE, ACT_HL2MP_RUN_MELEE2, ACT_MP_RUN),
	crouchIdle = activityList(ACT_HL2MP_IDLE_CROUCH, ACT_HL2MP_IDLE_CROUCH_PASSIVE, ACT_HL2MP_IDLE_CROUCH_MELEE2, ACT_MP_CROUCH_IDLE),
	crouchWalk = activityList(ACT_HL2MP_WALK_CROUCH, ACT_HL2MP_WALK_CROUCH_PASSIVE, ACT_HL2MP_WALK_CROUCH_MELEE2, ACT_MP_CROUCHWALK),
	attack = activityList(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE, ACT_MELEE_ATTACK1, ACT_GMOD_GESTURE_MELEE_SHOVE_1HAND),
	sniff = activityList(ACT_GMOD_GESTURE_ITEM_PLACE, ACT_GMOD_GESTURE_SIGNAL_FORWARD),
	death = activityList(ACT_GMOD_DEATH, ACT_DIESIMPLE),
}

local locomotionStates = {
	idle = true,
	walk = true,
	run = true,
	crouchIdle = true,
	crouchWalk = true,
}

local animationHints = {
	idle = { include = { "idle" }, exclude = { "crouch", "gesture", "attack", "death" } },
	walk = { include = { "walk" }, exclude = { "crouch" } },
	run = { include = { "run" }, exclude = { "crouch" } },
	crouchIdle = { includeAny = { "cidle", "crouch_idle", "idle_crouch" } },
	crouchWalk = { includeAny = { "cwalk", "crouch_walk", "walk_crouch" } },
	attack = { includeAny = { "attack", "bite", "melee" } },
	sniff = { includeAny = { "sniff", "search" } },
	death = { includeAny = { "death", "dead", "ragdoll" } },
}

local function sequenceMatches(name, hint)
	name = string.lower(tostring(name or ""))
	for _, token in ipairs(hint.include or {}) do
		if not string.find(name, token, 1, true) then return false end
	end
	if hint.includeAny then
		local found = false
		for _, token in ipairs(hint.includeAny) do
			if string.find(name, token, 1, true) then found = true break end
		end
		if not found then return false end
	end
	for _, token in ipairs(hint.exclude or {}) do
		if string.find(name, token, 1, true) then return false end
	end
	return true
end

local function activitySequence(ent, state)
	for index, activity in ipairs(animationActivities[state] or {}) do
		local id
		if ent.SelectWeightedSequenceSeeded then
			id = ent:SelectWeightedSequenceSeeded(activity, index)
		else
			id = ent:SelectWeightedSequence(activity)
		end
		if isnumber(id) and id >= 0 then return id, "activity:" .. tostring(activity) end
	end
	return -1
end

local function namedSequence(ent, state)
	local configured = cfg().Animations or {}
	for _, name in ipairs(configured[state] or defaultAnimations[state] or {}) do
		local id = ent:LookupSequence(name)
		if isnumber(id) and id >= 0 then return id, "sequence:" .. tostring(name) end
	end

	local hint = animationHints[state]
	if hint and ent.GetSequenceList then
		for _, name in ipairs(ent:GetSequenceList() or {}) do
			if sequenceMatches(name, hint) then
				local id = ent:LookupSequence(name)
				if isnumber(id) and id >= 0 then return id, "fuzzy:" .. tostring(name) end
			end
		end
	end
	return -1
end

local function sequence(ent, state)
	ent.MassifSequenceCache = ent.MassifSequenceCache or {}
	if ent.MassifSequenceCache[state] ~= nil then
		return ent.MassifSequenceCache[state], ent.MassifSequenceSource and ent.MassifSequenceSource[state]
	end

	-- Player locomotion activities are authoritative. Direct names remain a
	-- fallback for unusually compiled models and for custom one-shot actions.
	local id, source
	if locomotionStates[state] and cfg().PreferPlayerActivities ~= false then
		id, source = activitySequence(ent, state)
		if id < 0 then id, source = namedSequence(ent, state) end
	else
		id, source = namedSequence(ent, state)
		if id < 0 then id, source = activitySequence(ent, state) end
	end

	ent.MassifSequenceCache[state] = id
	ent.MassifSequenceSource = ent.MassifSequenceSource or {}
	ent.MassifSequenceSource[state] = source or "missing"
	return id, source
end

function ENT:SetMassifPoseNormalized(name, amount)
	if not self.LookupPoseParameter or not self.GetPoseParameterRange then return false end
	local id = self:LookupPoseParameter(name)
	if not isnumber(id) or id < 0 then return false end
	local minimum, maximum = self:GetPoseParameterRange(id)
	if not isnumber(minimum) or not isnumber(maximum) then return false end
	amount = math.Clamp(tonumber(amount) or 0, -1, 1)
	local zero = math.Clamp(0, minimum, maximum)
	local value = amount >= 0 and Lerp(amount, zero, maximum) or Lerp(-amount, zero, minimum)
	self:SetPoseParameter(name, value)
	return true
end

function ENT:SetMassifPoseRaw(name, value)
	if not self.LookupPoseParameter or not self.GetPoseParameterRange then return false end
	local id = self:LookupPoseParameter(name)
	if not isnumber(id) or id < 0 then return false end
	local minimum, maximum = self:GetPoseParameterRange(id)
	self:SetPoseParameter(name, math.Clamp(tonumber(value) or 0, minimum, maximum))
	return true
end

function ENT:ApplyPlayerMovementPose(speed, crouching)
	local c = cfg()
	local referenceSpeed
	if crouching then
		referenceSpeed = c.ControlledCrouchSpeed or 125
	elseif speed > 285 then
		referenceSpeed = c.RunSpeed or 350
	else
		referenceSpeed = c.WalkSpeed or 190
	end
	local movement = speed > 1 and math.Clamp(speed / math.max(referenceSpeed, 1), 0, 1) or 0

	-- These are the standard GMod 9-way player movement parameters. Models that
	-- do not expose one simply ignore it.
	self:SetMassifPoseNormalized("move_x", movement)
	self:SetMassifPoseNormalized("move_y", 0)
	self:SetMassifPoseNormalized("move_scale", movement)
	self:SetMassifPoseRaw("move_yaw", 0)
	self:SetMassifPoseRaw("body_yaw", 0)
	self:SetMassifPoseRaw("aim_yaw", 0)
	self:SetMassifPoseRaw("aim_pitch", 0)
	self:SetMassifPoseRaw("head_yaw", 0)
	self:SetMassifPoseRaw("head_pitch", 0)
	if self.InvalidateBoneCache then self:InvalidateBoneCache() end
end

function ENT:PlayMassifAnimation(state, force, lockDuration)
	if self.MassifAnimationReady == false then return false end
	local id, source = sequence(self, state)
	if not isnumber(id) or id < 0 then return false end

	if force or self:GetSequence() ~= id then
		self:ResetSequence(id)
		self:ResetSequenceInfo()
		self:SetCycle(0)
	end

	self.MassifAnimationState = state
	self.MassifAnimationActiveSource = source
	self:SetPlaybackRate(math.max(0.01, tonumber(cfg().AnimationPlaybackScale) or 1))
	if lockDuration then
		local duration = tonumber(lockDuration) or 0
		if duration <= 0 then duration = self:SequenceDuration(id) end
		self.MassifAnimationLockedUntil = CurTime() + math.Clamp(duration, 0.2, 4)
	end
	return true
end

function ENT:Initialize()
	local c = cfg()
	local model = MilBase.ResolveMassifModel and MilBase.ResolveMassifModel() or c.FallbackModel
	self:SetModel(model or "models/antlion.mdl")
	if self.SetAutomaticFrameAdvance then self:SetAutomaticFrameAdvance(true) end
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(c.CollisionMins or Vector(-22, -18, 0), c.CollisionMaxs or Vector(22, 18, 45))
	self:SetCollisionGroup(COLLISION_GROUP_NPC)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(true)

	local hp = math.max(1, tonumber(c.Health) or 225)
	self:SetMassifMaxHealth(hp)
	self:SetMassifHealth(hp)
	self:SetHealth(hp)
	self:SetMaxHealth(hp)
	local handler = self:GetHandler()
	local chosenName = IsValid(handler) and handler:GetNWString("mb_massif_name", "") or ""
	self:SetMassifName(chosenName ~= "" and chosenName or (c.DefaultName or "Hound"))
	self:SetGuardPosition(self:GetPos())
	self:SetCommandState("follow")
	self:SetControlled(false)
	self:SetIncapacitated(false)
	self.LastMoveTime = CurTime()
	self.NextBite = 0
	self.NextTackle = 0
	self.NextSearch = 0
	self.StuckSince = 0
	self.LastPosition = self:GetPos()
	self.MassifAnimationLockedUntil = 0
	self.MassifAnimationState = nil
	self.MassifAnimationReady = false

	-- SetSequence/ResetSequence can fail in the same tick as SetModel. Build the
	-- activity map and start animation on the following tick instead.
	timer.Simple(0, function()
		if not IsValid(self) then return end
		self.MassifSequenceCache = {}
		self.MassifSequenceSource = {}
		self.MassifAnimationReady = true
		self:ApplyPlayerMovementPose(0, false)
		self:PlayMassifAnimation("idle", true)
	end)
end

function ENT:IsValidHandler()
	local handler = self:GetHandler()
	return IsValid(handler) and handler:IsPlayer() and handler:Alive()
end

function ENT:SetAnimationForSpeed(speed, crouching)
	speed = math.max(0, tonumber(speed) or 0)
	self:ApplyPlayerMovementPose(speed, crouching == true)
	if self.MassifAnimationReady == false then return end

	local now = CurTime()
	if now < (self.MassifAnimationLockedUntil or 0) then return end
	if now < (self.NextAnimationUpdate or 0) then return end
	self.NextAnimationUpdate = now + 0.06

	local state
	if self:GetIncapacitated() then
		state = "death"
	elseif crouching and speed > 25 then
		state = "crouchWalk"
	elseif crouching then
		state = "crouchIdle"
	elseif speed > 285 then
		state = "run"
	elseif speed > 25 then
		state = "walk"
	else
		state = "idle"
	end

	-- Some player models omit dedicated crouch activities. Fall back cleanly.
	if not self:PlayMassifAnimation(state, false) and crouching then
		state = speed > 25 and "walk" or "idle"
		self:PlayMassifAnimation(state, false)
	end

	local id = self:GetSequence()
	local rate = tonumber(cfg().AnimationPlaybackScale) or 1
	if speed > 25 and isnumber(id) and id >= 0 then
		local groundSpeed = self:GetSequenceGroundSpeed(id)
		if isnumber(groundSpeed) and groundSpeed > 1 then
			rate = rate * math.Clamp(speed / groundSpeed, 0.55, 2.25)
		elseif state == "run" then
			rate = rate * math.Clamp(speed / math.max(cfg().RunSpeed or 350, 1), 0.8, 1.8)
		elseif state == "walk" or state == "crouchWalk" then
			rate = rate * math.Clamp(speed / math.max(cfg().WalkSpeed or 190, 1), 0.75, 1.8)
		end
	end
	self:SetPlaybackRate(math.max(0.01, rate))
end

function ENT:CanTarget(target)
	if not IsValid(target) or target == self or target == self:GetHandler() then return false end
	if target:IsPlayer() then
		if not target:Alive() or target:GetNWBool("mb_wounded", false) then return false end
		if target:GetNWBool("mb_massif_protected", false) then return false end
		local c = cfg()
		if target.MBStaffLevel and target:MBStaffLevel() >= (c.StaffProtectionLevel or 4) then return false end
		if target:GetNWBool("mb_cuffed", false) then return false end
		if not c.AllowFriendlyApprehension then
			local handler = self:GetHandler()
			if IsValid(handler) and handler:Team() == target:Team() then return false end
		end
		return true
	end
	return target:IsNPC() or target:IsNextBot()
end

function ENT:HasLineOfSight(target)
	if not IsValid(target) then return false end
	local tr = util.TraceLine({
		start = self:WorldSpaceCenter(),
		endpos = target:WorldSpaceCenter(),
		filter = { self, self:GetHandler() },
		mask = MASK_SHOT,
	})
	return tr.Entity == target or not tr.Hit
end

function ENT:TryStep(desired, speed, dt)
	local c = cfg()
	local start = self:GetPos()
	local distance = math.max(0, speed * dt)
	if distance <= 0 then return false end

	local flat = desired - start
	flat.z = 0
	if flat:LengthSqr() < 4 then return false end
	flat:Normalize()

	local mins = c.CollisionMins or Vector(-22, -18, 0)
	local maxs = c.CollisionMaxs or Vector(22, 18, 45)
	local function traceDirection(direction, stepUp)
		local raised = start + Vector(0, 0, stepUp or 0)
		return util.TraceHull({
			start = raised,
			endpos = raised + direction * distance,
			mins = mins,
			maxs = maxs,
			filter = { self, self:GetHandler() },
			mask = MASK_PLAYERSOLID,
		})
	end

	local tr = traceDirection(flat, 0)
	local chosen = flat
	local raised = 0
	if tr.Hit then
		local right = flat:Angle():Right()
		local leftTrace = traceDirection((flat - right * 0.75):GetNormalized(), 0)
		local rightTrace = traceDirection((flat + right * 0.75):GetNormalized(), 0)
		if not leftTrace.Hit then
			tr, chosen = leftTrace, (flat - right * 0.75):GetNormalized()
		elseif not rightTrace.Hit then
			tr, chosen = rightTrace, (flat + right * 0.75):GetNormalized()
		else
			local stepTrace = traceDirection(flat, 22)
			if not stepTrace.Hit then tr, raised = stepTrace, 22 else return false end
		end
	end

	local nextPos = tr.HitPos + Vector(0, 0, raised)
	if not tr.Hit then nextPos = start + chosen * distance + Vector(0, 0, raised) end

	local floor = util.TraceHull({
		start = nextPos + Vector(0, 0, 36),
		endpos = nextPos - Vector(0, 0, 90),
		mins = Vector(mins.x, mins.y, 0),
		maxs = Vector(maxs.x, maxs.y, 4),
		filter = { self, self:GetHandler() },
		mask = MASK_PLAYERSOLID,
	})
	if floor.Hit and floor.HitNormal.z > 0.45 then nextPos.z = floor.HitPos.z end

	self:SetPos(nextPos)
	local targetYaw = chosen:Angle().y
	local ang = self:GetAngles()
	ang.p, ang.r = 0, 0
	ang.y = math.ApproachAngle(ang.y, targetYaw, (c.TurnRate or 8) * 60 * dt)
	self:SetAngles(ang)
	return true
end

function ENT:MoveToward(position, speed, dt, crouching)
	if not isvector(position) then return false end
	self.MassifMoveRequested = true
	local moved = self:TryStep(position, speed, dt)
	self:SetAnimationForSpeed(moved and speed or 0, crouching)
	return moved
end

function ENT:FollowHandler(dt)
	local handler = self:GetHandler()
	if not IsValid(handler) then return end
	local desired = handler:GetPos() - handler:GetForward() * (cfg().FollowDistance or 85) + handler:GetRight() * 42
	local dist = self:GetPos():Distance(desired)
	if dist < 48 then self:SetAnimationForSpeed(0) return end
	local speed = dist > 350 and (cfg().RunSpeed or 350) or (cfg().WalkSpeed or 190)
	self:MoveToward(desired, speed, dt)
end

function ENT:ControlledMove(dt)
	local handler = self:GetHandler()
	if not IsValid(handler) then return end
	local input = handler.mb_massifInput or {}
	local ang = input.angles or handler:EyeAngles()
	ang.p, ang.r = 0, 0
	local forward = ang:Forward()
	local right = ang:Right()
	local move = forward * (input.forward or 0) + right * (input.side or 0)
	move.z = 0
	local length = move:Length()
	local crouching = bit.band(input.buttons or 0, IN_DUCK) ~= 0
	if length > 0.05 then
		move:Normalize()
		local sprint = bit.band(input.buttons or 0, IN_SPEED) ~= 0 and not crouching
		local speed = crouching and (cfg().ControlledCrouchSpeed or 125)
			or (sprint and (cfg().ControlledSprintSpeed or 430) or (cfg().RunSpeed or 350))
		self:MoveToward(self:GetPos() + move * 300, speed * math.Clamp(length, 0, 1), dt, crouching)
		local face = self:GetAngles()
		face.y = math.ApproachAngle(face.y, ang.y, (cfg().TurnRate or 8) * 80 * dt)
		self:SetAngles(face)
	else
		self:SetAnimationForSpeed(0, crouching)
	end

	if self.ControlAttackRequested then
		self.ControlAttackRequested = false
		self:TryAttack(self:GetMarkedTarget())
	end
	if self.ControlPulseRequested then
		self.ControlPulseRequested = false
		self:DoScentPulse()
	end
end

function ENT:Tackle(target)
	if not target:IsPlayer() then return false end
	local now = CurTime()
	if now < self.NextTackle then return false end
	self.NextTackle = now + (cfg().TackleCooldown or 7)
	local duration = cfg().TackleDuration or 3.25
	target:SetNWFloat("mb_massif_pinned_until", now + duration)
	target:SetNWEntity("mb_massif_pinner", self)
	target:ViewPunch(Angle(8, math.random(-5, 5), 0))
	target:EmitSound("npc/antlion_guard/angry" .. math.random(1, 3) .. ".wav", 72, 118, 0.7)
	self:EmitSound("npc/antlion/attack_single" .. math.random(1, 3) .. ".wav", 74, 92, 0.8)
	if MilBase.Notify then
		MilBase.Notify(target, "A CG Massif has pinned you. You can move again shortly.", "warn")
		local handler = self:GetHandler()
		if IsValid(handler) then MilBase.Notify(handler, "Suspect apprehended — move in to restrain them.", "ok") end
	end
	if MilBase.LogMassif then MilBase.LogMassif(self:GetHandler(), "tackled", target) end
	return true
end

function ENT:TryAttack(target)
	if CurTime() < self.NextBite or not self:CanTarget(target) then return false end
	if self:GetPos():Distance(target:GetPos()) > (cfg().BiteRange or 105) then return false end
	if not self:HasLineOfSight(target) then return false end
	self.NextBite = CurTime() + (cfg().BiteCooldown or 0.9)
	self:PlayMassifAnimation("attack", true, 0.7)

	if target:IsPlayer() and self:Tackle(target) then return true end

	local damage = DamageInfo()
	damage:SetDamage(cfg().BiteDamage or 12)
	damage:SetDamageType(DMG_SLASH)
	damage:SetAttacker(IsValid(self:GetHandler()) and self:GetHandler() or self)
	damage:SetInflictor(self)
	damage:SetDamagePosition(target:WorldSpaceCenter())
	target:TakeDamageInfo(damage)
	self:EmitSound("npc/antlion/attack_single" .. math.random(1, 3) .. ".wav", 74, 92, 0.8)
	if MilBase.LogMassif then MilBase.LogMassif(self:GetHandler(), "bit", target) end
	return true
end

function ENT:DoScentPulse()
	local now = CurTime()
	if now < (self.NextScentPulse or 0) then return false end
	self.NextScentPulse = now + (cfg().ScentPulseCooldown or 4)
	self:SetScentPulseEnds(now + (cfg().ScentPulseDuration or 1.2))
	self:PlayMassifAnimation("sniff", true, 0.8)
	self:EmitSound("npc/antlion/idle1.wav", 66, 115, 0.65)
	return true
end

function ENT:ValidateOrderedTarget(requirePlayer)
	local target = self:GetMarkedTarget()
	if not self:CanTarget(target) or (requirePlayer and not target:IsPlayer()) then
		self:SetCommandState("follow")
		return nil
	end
	local distance = self:GetPos():Distance(target:GetPos())
	if distance > (cfg().LeashDistance or 2600) and not self:GetControlled() then
		local handler = self:GetHandler()
		if IsValid(handler) and MilBase.Notify then MilBase.Notify(handler, "Massif lost the scent and returned to heel.", "warn") end
		self:SetCommandState("follow")
		return nil
	end
	return target, distance
end

function ENT:FaceTarget(target, dt)
	if not IsValid(target) then return end
	local direction = target:GetPos() - self:GetPos()
	direction.z = 0
	if direction:LengthSqr() < 1 then return end
	local ang = self:GetAngles()
	ang.p, ang.r = 0, 0
	ang.y = math.ApproachAngle(ang.y, direction:Angle().y, (cfg().TurnRate or 8) * 60 * dt)
	self:SetAngles(ang)
end

-- Track is deliberately observational. It follows the marked scent but never
-- bites or tackles; Apprehend is the only autonomous attack order.
function ENT:TrackTarget(dt)
	local target, distance = self:ValidateOrderedTarget(false)
	if not IsValid(target) then return end
	local stopDistance = math.max(cfg().TrackStopDistance or 165, (cfg().TackleRange or 115) + 25)
	if distance <= stopDistance then
		self:FaceTarget(target, dt)
		self:SetAnimationForSpeed(0)
		return
	end
	self:MoveToward(target:GetPos(), cfg().RunSpeed or 350, dt)
end

function ENT:SearchTarget(dt)
	local target, distance = self:ValidateOrderedTarget(true)
	if not IsValid(target) then return end
	local searchRange = cfg().SearchRange or 180
	if distance <= searchRange then
		self:FaceTarget(target, dt)
		self:SetAnimationForSpeed(0)
		local handler = self:GetHandler()
		if IsValid(handler) and MilBase.MassifSearchPlayer and MilBase.MassifSearchPlayer(handler, self, true) then
			self:SetCommandState(cfg().SearchReturnCommand or "follow")
		end
		return
	end
	local speed = distance > 500 and (cfg().RunSpeed or 350) or (cfg().WalkSpeed or 190)
	self:MoveToward(target:GetPos(), speed, dt)
end

function ENT:ChaseTarget(dt)
	local target, distance = self:ValidateOrderedTarget(false)
	if not IsValid(target) then return end
	if distance <= (cfg().TackleRange or 115) then
		self:TryAttack(target)
		self:SetAnimationForSpeed(0)
		return
	end
	self:MoveToward(target:GetPos(), cfg().RunSpeed or 350, dt)
end

function ENT:Think()
	local now = CurTime()
	local dt = math.Clamp(now - (self.LastMoveTime or now), 0.01, 0.1)
	self.LastMoveTime = now

	if not self:IsValidHandler() then self:Remove() return end
	if self:GetIncapacitated() then self:SetAnimationForSpeed(0) self:NextThink(now + 0.2) return true end

	self.MassifMoveRequested = false
	local state = self:GetCommandState()
	if self:GetControlled() then
		if now >= self:GetPossessionEnds() then
			if MilBase.EndMassifControl then MilBase.EndMassifControl(self:GetHandler(), "Control time expired.") end
		else
			self:ControlledMove(dt)
		end
	else
		if state == "follow" or state == "return" then
			self:FollowHandler(dt)
		elseif state == "track" then
			self:TrackTarget(dt)
		elseif state == "search" then
			self:SearchTarget(dt)
		elseif state == "apprehend" then
			self:ChaseTarget(dt)
		elseif state == "guard" then
			-- Guard is positional and non-aggressive. It only returns to the
			-- recorded guard point; attacking requires Apprehend.
			if self:GetPos():Distance(self:GetGuardPosition()) > 45 then
				self:MoveToward(self:GetGuardPosition(), cfg().WalkSpeed or 190, dt)
			else
				self:SetAnimationForSpeed(0)
			end
		else
			self:SetAnimationForSpeed(0)
		end
	end

	local handler = self:GetHandler()
	local recoveryCommands = cfg().TeleportRecoveryCommands or { follow = true, ["return"] = true }
	local canRecoveryTeleport = not self:GetControlled() and recoveryCommands[state] == true
	if canRecoveryTeleport and IsValid(handler)
		and self:GetPos():DistToSqr(handler:GetPos()) > ((cfg().StuckTeleportDistance or 1800) ^ 2) then
		local pos = MilBase.FindMassifSpawnPosition and MilBase.FindMassifSpawnPosition(handler)
		if pos then
			self:SetPos(pos)
			self.LastPosition = pos
		end
	end

	-- Idle commands must never be mistaken for being stuck. Recovery only runs
	-- while Follow/Return actively requested movement and failed to make progress.
	if canRecoveryTeleport and self.MassifMoveRequested then
		if self:GetPos():DistToSqr(self.LastPosition or self:GetPos()) < 16 then
			self.StuckSince = self.StuckSince > 0 and self.StuckSince or now
		else
			self.StuckSince = 0
			self.LastPosition = self:GetPos()
		end
		if self.StuckSince > 0 and now - self.StuckSince > (cfg().StuckRecoveryDelay or 4) then
			local pos = MilBase.FindMassifSpawnPosition and MilBase.FindMassifSpawnPosition(handler)
			if pos then
				self:SetPos(pos)
				self.LastPosition = pos
			end
			self.StuckSince = 0
		end
	else
		self.StuckSince = 0
		self.LastPosition = self:GetPos()
	end

	self:NextThink(now)
	return true
end

function ENT:OnTakeDamage(dmg)
	if self:GetIncapacitated() then return end
	local newHealth = math.max(0, self:GetMassifHealth() - math.max(0, dmg:GetDamage()))
	self:SetMassifHealth(newHealth)
	self:SetHealth(newHealth)
	if newHealth <= 0 then self:Incapacitate(dmg:GetAttacker()) end
end

function ENT:Incapacitate(attacker)
	if self:GetIncapacitated() then return end
	self:SetIncapacitated(true)
	self:PlayMassifAnimation("death", true, 4)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	local handler = self:GetHandler()
	if IsValid(handler) and MilBase.EndMassifControl then MilBase.EndMassifControl(handler, "Your Massif was incapacitated.") end
	if IsValid(handler) then
		handler.mb_massifDeployAt = CurTime() + (cfg().IncapacitatedCooldown or 35)
		if MilBase.Notify then MilBase.Notify(handler, "Your Massif is incapacitated and must recover.", "warn") end
	end
	if MilBase.LogMassif then MilBase.LogMassif(handler, "incapacitated by", attacker) end
	timer.Simple(4, function() if IsValid(self) then self:Remove() end end)
end

function ENT:Use(activator)
	if not IsValid(activator) or not activator:IsPlayer() or self:GetIncapacitated() then return end
	local handler = self:GetHandler()
	local faction = activator.MBFaction and activator:MBFaction()
	if activator ~= handler and not (faction and faction.police) then return end
	self:EmitSound("npc/antlion/idle2.wav", 62, 125, 0.5)
	if MilBase.Notify then MilBase.Notify(activator, "You give " .. self:GetMassifName() .. " an approving pat.", "ok") end
end

function ENT:OnRemove()
	local handler = self:GetHandler()
	if IsValid(handler) then
		if handler:GetNWEntity("mb_massif") == self then handler:SetNWEntity("mb_massif", NULL) end
		if handler:GetNWEntity("mb_massif_control") == self and MilBase.EndMassifControl then MilBase.EndMassifControl(handler) end
	end
end
