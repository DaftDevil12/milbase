TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_vehicle_requisition_spawn.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	spawn_name = "Vehicle Pad",
	vehicles = "",
	factions = "",
	min_rank = "0",
	max_rank = "0",
	rank_groups = "",
	certs = "",
	require_all = "0",
	active = "1",
}

if CLIENT then
	language.Add("tool.mb_vehicle_requisition_spawn.name", "Vehicle Requisition Spawn")
	language.Add("tool.mb_vehicle_requisition_spawn.desc", "Place vehicle requisition pads with vehicle, faction, rank and cert rules.")
	language.Add("tool.mb_vehicle_requisition_spawn.0", "Left-click adds a vehicle pad. Right-click updates the nearest pad. Reload removes the nearest pad.")
end

local function trim(s)
	return string.Trim(tostring(s or ""))
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.VehicleReq and MilBase.VehicleReq.CanStaffConfigure and MilBase.VehicleReq.CanStaffConfigure(ply)
end

local function opts(tool)
	return {
		name = tool:GetClientInfo("spawn_name"),
		vehicles = tool:GetClientInfo("vehicles"),
		factions = tool:GetClientInfo("factions"),
		minRank = tool:GetClientNumber("min_rank"),
		maxRank = tool:GetClientNumber("max_rank"),
		rankGroups = tool:GetClientInfo("rank_groups"),
		certs = tool:GetClientInfo("certs"),
		requireAll = tool:GetClientNumber("require_all") > 0,
		active = tool:GetClientNumber("active") > 0,
	}
end

local function spawnPos(trace)
	return trace.HitPos + trace.HitNormal * 8
end

local function spawnAng(ply)
	local a = ply:EyeAngles()
	return Angle(0, a.y + 180, 0)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.VehicleReq.AddSpawn(ply, spawnPos(trace), spawnAng(ply), opts(self)) == true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.VehicleReq.UpdateNearestSpawn(ply, spawnPos(trace), spawnAng(ply), opts(self)) == true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	local pos = trace.HitPos
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "player" then pos = trace.Entity:GetPos() end
	return MilBase.VehicleReq.RemoveNearestSpawn(ply, pos, 300) == true
end

function TOOL:DrawToolScreen(w, h)
	if not CLIENT then return end
	surface.SetDrawColor(18, 24, 32, 255)
	surface.DrawRect(0, 0, w, h)
	draw.SimpleText("VEHICLE", "DermaLarge", w / 2, 38, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("REQ PAD", "DermaLarge", w / 2, 72, Color(255, 198, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LMB add", "DermaDefaultBold", w / 2, 126, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RMB update", "DermaDefaultBold", w / 2, 150, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("R reload remove", "DermaDefaultBold", w / 2, 174, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("/vehreqconfig edits lists", "DermaDefault", w / 2, 206, Color(255, 218, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function splitTokens(value)
	local out = {}
	value = trim(value)
	if value == "" then return out end
	for part in string.gmatch(value, "([^,;|]+)") do
		part = trim(part)
		if part ~= "" then out[#out + 1] = part end
	end
	return out
end

local function addUniqueToken(cvar, token)
	token = trim(token)
	if token == "" then return end
	local convar = GetConVar(cvar)
	local cur = convar and convar:GetString() or ""
	local list = splitTokens(cur)
	local wanted = string.lower(token)
	for _, existing in ipairs(list) do
		if string.lower(existing) == wanted then return end
	end
	list[#list + 1] = token
	RunConsoleCommand(cvar, table.concat(list, ","))
end

local function cvarText(cvar)
	local convar = GetConVar(cvar)
	local value = convar and convar:GetString() or ""
	return trim(value) ~= "" and value or "Any"
end

local function factionChoices()
	local out = { { "Any faction/job", "" } }
	if MilBase and MilBase.FactionOrder then
		for _, id in ipairs(MilBase.FactionOrder) do
			local faction = MilBase.GetFaction and MilBase.GetFaction(id) or (MilBase.Factions and MilBase.Factions[id])
			local name = (faction and faction.name) or id
			out[#out + 1] = { name .. "  [" .. id .. "]", id }
		end
	end
	return out
end

local function certChoices()
	local out = { { "No cert requirement", "" } }
	if MilBase and MilBase.CertOrder then
		for _, id in ipairs(MilBase.CertOrder) do
			local cert = MilBase.Certs and MilBase.Certs[id]
			local name = (cert and cert.name) or id
			out[#out + 1] = { name .. "  [" .. id .. "]", id }
		end
	end
	return out
end

local function vehicleChoices()
	local out = { { "Any configured vehicle", "" } }
	if MilBase and MilBase.VehicleReq and MilBase.VehicleReq.Vehicles then
		for _, v in pairs(MilBase.VehicleReq.Vehicles) do
			out[#out + 1] = { (v.name or "Vehicle") .. "  [" .. tostring(v.id or "?") .. "]", tostring(v.id or "") }
		end
	end
	return out
end

local function rankGroupChoices()
	return {
		{ "Any rank group", "" },
		{ "Trooper / TRP", "trooper" },
		{ "NCO", "nco" },
		{ "Officer", "officer" },
		{ "Commander", "commander" },
	}
end

local function addDropdownSelector(panel, title, cvar, choices, allowMulti, help)
	if help and help ~= "" then panel:Help(help) end

	local wrap = vgui.Create("DPanel")
	wrap:SetTall(104)
	wrap.Paint = function() end

	local titleLabel = vgui.Create("DLabel", wrap)
	titleLabel:SetText(title)
	titleLabel:SetDark(true)
	titleLabel:SetFont("DermaDefaultBold")

	local combo = vgui.Create("DComboBox", wrap)
	combo:SetValue(choices[1] and choices[1][1] or "Select...")

	local selectedData = choices[1] and choices[1][2] or ""
	for _, choice in ipairs(choices) do combo:AddChoice(choice[1], choice[2]) end
	combo.OnSelect = function(_, _, _, data) selectedData = tostring(data or "") end

	local current = vgui.Create("DLabel", wrap)
	current:SetDark(true)
	current:SetText("Current: " .. cvarText(cvar))
	current.Think = function(self)
		local txt = "Current: " .. cvarText(cvar)
		if self:GetText() ~= txt then self:SetText(txt) end
	end

	local setBtn = vgui.Create("DButton", wrap)
	setBtn:SetText(allowMulti and "Set Only" or "Set")
	setBtn.DoClick = function() RunConsoleCommand(cvar, tostring(selectedData or "")) end

	local addBtn
	if allowMulti then
		addBtn = vgui.Create("DButton", wrap)
		addBtn:SetText("Add")
		addBtn.DoClick = function() addUniqueToken(cvar, selectedData) end
	end

	local clearBtn = vgui.Create("DButton", wrap)
	clearBtn:SetText("Any / Clear")
	clearBtn.DoClick = function() RunConsoleCommand(cvar, "") end

	wrap.PerformLayout = function(self, w, h)
		titleLabel:SetPos(0, 0); titleLabel:SetSize(w, 18)
		combo:SetPos(0, 22); combo:SetSize(w, 24)
		current:SetPos(0, 50); current:SetSize(w, 18)
		local gap = 6
		local clearW = 92
		local btnY = 74
		if allowMulti then
			local btnW = math.floor((w - clearW - gap * 2) / 2)
			setBtn:SetPos(0, btnY); setBtn:SetSize(btnW, 24)
			addBtn:SetPos(btnW + gap, btnY); addBtn:SetSize(btnW, 24)
			clearBtn:SetPos(btnW * 2 + gap * 2, btnY); clearBtn:SetSize(clearW, 24)
		else
			local btnW = math.floor((w - gap) / 2)
			setBtn:SetPos(0, btnY); setBtn:SetSize(btnW, 24)
			clearBtn:SetPos(btnW + gap, btnY); clearBtn:SetSize(btnW, 24)
		end
	end

	panel:AddItem(wrap)
	return wrap
end

if CLIENT then
	local function drawPadPreview(pos, ang)
		local yaw = Angle(0, (ang and ang.y) or 0, 0)
		local half = 88
		local fwd = yaw:Forward()
		local right = yaw:Right()
		local lift = Vector(0, 0, 4)
		local corners = {
			pos + fwd * half + right * half + lift,
			pos + fwd * half - right * half + lift,
			pos - fwd * half - right * half + lift,
			pos - fwd * half + right * half + lift,
		}
		render.SetColorMaterial()
		for i = 1, 4 do render.DrawLine(corners[i], corners[i % 4 + 1], Color(255, 198, 60, 235), true) end
		render.DrawLine(pos + lift, pos + fwd * half + lift, Color(120, 220, 255, 230), true)
	end

	function TOOL:DrawHUD()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local tr = ply:GetEyeTrace()
		if not tr or not tr.Hit then return end
		local pos = spawnPos(tr)
		local ang = spawnAng(ply)
		cam.Start3D(EyePos(), EyeAngles())
			drawPadPreview(pos, ang)
		cam.End3D()
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("Vehicle Requisition Spawn")
	panel:Help("Left-click places a persistent vehicle pad. Right-click updates the nearest pad. Reload removes the nearest pad.")
	panel:TextEntry("Spawn name", "mb_vehicle_requisition_spawn_spawn_name")
	panel:TextEntry("Allowed vehicles (ids, names, classes or categories)", "mb_vehicle_requisition_spawn_vehicles")

	addDropdownSelector(panel, "Allowed vehicles", "mb_vehicle_requisition_spawn_vehicles", vehicleChoices(), true,
		"Use Add to allow several configured vehicles. Leave clear for any vehicle.")

	addDropdownSelector(panel, "Faction/job access", "mb_vehicle_requisition_spawn_factions", factionChoices(), true,
		"Leave clear for all factions/jobs. Use Add to allow several factions.")

	panel:NumSlider("Minimum rank index (0 = any)", "mb_vehicle_requisition_spawn_min_rank", 0, 20, 0)
	panel:NumSlider("Maximum rank index (0 = any)", "mb_vehicle_requisition_spawn_max_rank", 0, 20, 0)

	addDropdownSelector(panel, "Rank group access", "mb_vehicle_requisition_spawn_rank_groups", rankGroupChoices(), false,
		"Use rank indexes above for exact locks, or this dropdown for broad rank groups.")

	addDropdownSelector(panel, "Cert access", "mb_vehicle_requisition_spawn_certs", certChoices(), true,
		"Choose certs from the dropdown. Leave clear for no cert requirement. Use Add to require one of several certs.")

	panel:CheckBox("Require every listed cert", "mb_vehicle_requisition_spawn_require_all")
	panel:CheckBox("Spawn active", "mb_vehicle_requisition_spawn_active")
	panel:Help("Vehicle list and OD rules are edited with /vehreqconfig.")
end
