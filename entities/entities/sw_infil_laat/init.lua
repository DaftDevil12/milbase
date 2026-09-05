AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

local fallbackEngineSound = "ambient/machines/thumper_amb.wav"

function ENT:Initialize()
    local requestedModel = self:GetVehicleModel()
    local model = requestedModel ~= "" and requestedModel or SWInfil.DefaultModel

    self:SetModel(model)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    self:DrawShadow(true)
    self:SetUseType(SIMPLE_USE)

    local idleSequence = self:LookupSequence("idle")
    if idleSequence and idleSequence >= 0 then
        self:ResetSequence(idleSequence)
    end

    local engineSound = file.Exists("sound/lvs/vehicles/laat/loop.wav", "GAME")
        and "lvs/vehicles/laat/loop.wav"
        or fallbackEngineSound

    self.EngineLoop = CreateSound(self, engineSound)
    if self.EngineLoop then
        self.EngineLoop:PlayEx(0.72, 94)
    end
end

function ENT:OpenDoors()
    if self:GetDoorsOpen() then return end

    self:SetDoorsOpen(true)

    if file.Exists("sound/lvs/vehicles/laat/door_large_open.wav", "GAME") then
        self:EmitSound("lvs/vehicles/laat/door_large_open.wav", 85, 100, 1)
    else
        self:EmitSound("doors/door_metal_large_open1.wav", 80, 100, 0.8)
    end
end

local friendlyNPCClasses = {
    npc_alyx = true,
    npc_barney = true,
    npc_citizen = true,
    npc_dog = true,
    npc_eli = true,
    npc_kleiner = true,
    npc_magnusson = true,
    npc_mossman = true,
    npc_vortigaunt = true
}

local function convarBool(name, fallback)
    local convar = GetConVar(name)
    if not convar then return fallback end
    return convar:GetBool()
end

local function convarFloat(name, fallback)
    local convar = GetConVar(name)
    if not convar then return fallback end
    return convar:GetFloat()
end

local function convarString(name, fallback)
    local convar = GetConVar(name)
    if not convar then return fallback end
    return convar:GetString()
end

local turretAttachmentCandidates = {
    [-1] = {
        "sw_infil_left_turret",
        "lvs_ballturret_left",
        "lvs_left_ballturret",
        "ballturret_left",
        "left_ballturret",
        "ball_turret_left",
        "left_ball_turret",
        "turret_left",
        "left_turret",
        "muzzle_left",
        "left_muzzle",
        "muzzle_l",
        "l_muzzle",
        "muzzle_l1",
        "gunner_left_muzzle",
        "left_gunner_muzzle",
        "laat_left_turret",
        "laat_l_turret"
    },
    [1] = {
        "sw_infil_right_turret",
        "lvs_ballturret_right",
        "lvs_right_ballturret",
        "ballturret_right",
        "right_ballturret",
        "ball_turret_right",
        "right_ball_turret",
        "turret_right",
        "right_turret",
        "muzzle_right",
        "right_muzzle",
        "muzzle_r",
        "r_muzzle",
        "muzzle_r1",
        "gunner_right_muzzle",
        "right_gunner_muzzle",
        "laat_right_turret",
        "laat_r_turret"
    }
}

local function trimText(text)
    return string.Trim(tostring(text or ""))
end

function ENT:LookupTurretAttachment(side)
    if not convarBool("sw_infil_turret_use_attachments", true) then return nil end

    side = side == -1 and -1 or 1
    self.SWInfilTurretAttachmentCache = self.SWInfilTurretAttachmentCache or {}

    local forcedName = trimText(convarString(side == -1 and "sw_infil_turret_left_attachment" or "sw_infil_turret_right_attachment", ""))
    local cacheKey = side .. ":" .. forcedName

    if self.SWInfilTurretAttachmentCache[cacheKey] ~= nil then
        return self.SWInfilTurretAttachmentCache[cacheKey]
    end

    local names = {}
    if forcedName ~= "" then
        names[#names + 1] = forcedName
    end

    for _, name in ipairs(turretAttachmentCandidates[side] or {}) do
        names[#names + 1] = name
    end

    local lowerNameToID = {}
    if self.GetAttachments then
        for _, attachment in ipairs(self:GetAttachments() or {}) do
            if attachment.name and attachment.id then
                lowerNameToID[string.lower(attachment.name)] = attachment.id
            end
        end
    end

    for _, name in ipairs(names) do
        local attachmentID = self:LookupAttachment(name)
        if (not attachmentID or attachmentID <= 0) and lowerNameToID[string.lower(name)] then
            attachmentID = lowerNameToID[string.lower(name)]
        end

        if attachmentID and attachmentID > 0 then
            self.SWInfilTurretAttachmentCache[cacheKey] = attachmentID
            return attachmentID
        end
    end

    self.SWInfilTurretAttachmentCache[cacheKey] = false
    return nil
end

function ENT:GetTurretOrigin(pos, ang, side)
    side = side == -1 and -1 or 1

    local attachmentID = self:LookupTurretAttachment(side)
    if attachmentID then
        local attachment = self:GetAttachment(attachmentID)
        if attachment and attachment.Pos then
            return attachment.Pos, attachment.Ang, true
        end
    end

    return pos + ang:Forward() * 80 + ang:Right() * side * 130 + ang:Up() * -8, ang, false
end

function ENT:IsHostileNPC(npc)
    if not IsValid(npc) or not npc:IsNPC() or (npc:Health() <= 0) then return false end
    if friendlyNPCClasses[string.lower(npc:GetClass() or "")] then return false end

    for occupant in pairs(self.SWInfilOccupants or {}) do
        if IsValid(occupant) and npc.Disposition then
            local disposition = npc:Disposition(occupant)
            if disposition == D_HT or disposition == D_FR then
                return true
            end
        end
    end

    return convarBool("sw_infil_turret_target_all_npcs", true)
end

function ENT:FindTurretTarget(origin, range)
    local bestTarget
    local bestDistance = range * range

    for _, candidate in ipairs(ents.FindInSphere(origin, range)) do
        if self:IsHostileNPC(candidate) then
            local targetPos = candidate:WorldSpaceCenter()
            local distance = origin:DistToSqr(targetPos)

            if distance < bestDistance then
                local trace = util.TraceLine({
                    start = origin,
                    endpos = targetPos,
                    filter = { self },
                    mask = MASK_SHOT
                })

                if not trace.Hit or trace.Entity == candidate then
                    bestDistance = distance
                    bestTarget = candidate
                end
            end
        end
    end

    return bestTarget
end

function ENT:FireTurretShot(origin, target)
    if not IsValid(target) then return end

    local targetPos = target:WorldSpaceCenter()
    local damage = convarFloat("sw_infil_turret_damage", 55)
    local attacker = IsValid(self:GetOccupant()) and self:GetOccupant() or self

    local info = DamageInfo()
    info:SetDamage(damage)
    info:SetAttacker(attacker)
    info:SetInflictor(self)
    info:SetDamageType(DMG_ENERGYBEAM)
    info:SetDamagePosition(targetPos)
    info:SetDamageForce((targetPos - origin):GetNormalized() * damage * 75)
    target:TakeDamageInfo(info)

    local effect = EffectData()
    effect:SetStart(origin)
    effect:SetOrigin(targetPos)
    effect:SetEntity(self)
    effect:SetScale(1)
    util.Effect("AR2Tracer", effect, true, true)

    self:EmitSound("weapons/ar2/fire1.wav", 82, math.random(118, 132), 0.45, CHAN_WEAPON)
end

function ENT:RunTurretDefense(now, pos, ang)
    if not convarBool("sw_infil_turrets_enabled", true) then return end

    local interval = math.max(convarFloat("sw_infil_turret_interval", 0.18), 0.05)
    if (self.NextTurretShot or 0) > now then return end

    local range = convarFloat("sw_infil_turret_range", 2600)
    local side = self.NextTurretSide == -1 and -1 or 1
    self.NextTurretSide = -side

    local origin = self:GetTurretOrigin(pos, ang, side)
    local target = self:FindTurretTarget(origin, range)
    if not IsValid(target) then
        origin = self:GetTurretOrigin(pos, ang, -side)
        target = self:FindTurretTarget(origin, range)
    end

    if IsValid(target) then
        self:FireTurretShot(origin, target)
        self.NextTurretShot = now + interval
    else
        self.NextTurretShot = now + math.min(interval, 0.25)
    end
end

function ENT:Think()
    local now = CurTime()
    local pos, ang = SWInfil.GetFlightTransform(self, now)
    self:SetPos(pos)
    self:SetAngles(ang)

    local occupants = self.SWInfilOccupants or {}
    for occupant, seat in pairs(occupants) do
        if IsValid(occupant) and occupant.SWInfilVehicle == self and occupant:GetNWBool("SWInfilActive") then
            occupant:SetPos(SWInfil.GetRideAnchor(self, now, seat, SWInfil.GetServerRideAnchorOffset and SWInfil.GetServerRideAnchorOffset() or nil))
            occupant:SetLocalVelocity(vector_origin)
        else
            SWInfil.RemoveVehicleOccupant(self, occupant)
        end
    end

    local phase = SWInfil.GetPhase(self, now)
    if phase == "approach" then
        self:RunTurretDefense(now, pos, ang)
    end

    if phase ~= "approach" then
        self:OpenDoors()
    end

    if phase == "departure" then
        local toRelease = {}
        for occupant in pairs(self.SWInfilOccupants or {}) do
            toRelease[#toRelease + 1] = occupant
        end

        for _, occupant in ipairs(toRelease) do
            if IsValid(occupant) then
                SWInfil.ReleasePlayer(occupant, self, false)
            end
        end
    end

    if phase == "finished" then
        self:Remove()
        return
    end

    if self.EngineLoop then
        local pitch = phase == "landed" and 82 or 98
        self.EngineLoop:ChangePitch(pitch, 0.25)
    end

    self:NextThink(now)
    return true
end

function ENT:OnRemove()
    if self.EngineLoop then
        self.EngineLoop:Stop()
    end

    local toRelease = {}
    for occupant in pairs(self.SWInfilOccupants or {}) do
        toRelease[#toRelease + 1] = occupant
    end

    for _, occupant in ipairs(toRelease) do
        if IsValid(occupant) and occupant.SWInfilVehicle == self then
            SWInfil.ReleasePlayer(occupant, self, true)
        end
    end
end
