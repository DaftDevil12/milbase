TOOL.Category = "Star Wars RP"
TOOL.Name = "#tool.mb_spawn_selector.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
	spawn_name = "Forward Spawn",
	factions = "",
	min_rank = "0",
	max_rank = "0",
	rank_groups = "",
	certs = "",
	require_all = "0",
	zone_size = "192",
}

if CLIENT then
	language.Add("tool.mb_spawn_selector.name", "Spawn Selector")
	language.Add("tool.mb_spawn_selector.desc", "Place player spawn selector points with faction, rank and spec access rules.")
	language.Add("tool.mb_spawn_selector.0", "Left-click adds a spawn. Right-click updates the nearest spawn. Reload removes the nearest spawn.")
end

local function canUseTool(ply)
	if game.SinglePlayer() then return true end
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	return MilBase and MilBase.SpawnSelectorCanConfigure and MilBase.SpawnSelectorCanConfigure(ply)
end

local function opts(tool)
	return {
		name = tool:GetClientInfo("spawn_name"),
		factions = tool:GetClientInfo("factions"),
		minRank = tool:GetClientNumber("min_rank"),
		maxRank = tool:GetClientNumber("max_rank"),
		rankGroups = tool:GetClientInfo("rank_groups"),
		certs = tool:GetClientInfo("certs"),
		requireAll = tool:GetClientNumber("require_all") > 0,
		zoneSize = tool:GetClientNumber("zone_size"),
	}
end

local function spawnPos(trace)
	return trace.HitPos + trace.HitNormal * 6
end

local function spawnAng(ply)
	local a = ply:EyeAngles()
	return Angle(0, a.y + 180, 0)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.SpawnSelectorAddSpawn(ply, spawnPos(trace), spawnAng(ply), opts(self)) == true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) or not trace.Hit then return false end
	return MilBase.SpawnSelectorUpdateNearest(ply, spawnPos(trace), spawnAng(ply), opts(self)) == true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local ply = self:GetOwner()
	if not canUseTool(ply) then return false end
	local pos = trace.HitPos
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "player" then pos = trace.Entity:GetPos() end
	return MilBase.SpawnSelectorRemoveNearest(ply, pos, 300) == true
end

function TOOL:DrawToolScreen(w, h)
	if not CLIENT then return end
	surface.SetDrawColor(18, 24, 32, 255)
	surface.DrawRect(0, 0, w, h)
	draw.SimpleText("SPAWN", "DermaLarge", w / 2, 38, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("SELECTOR", "DermaLarge", w / 2, 72, Color(120, 190, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LMB add", "DermaDefaultBold", w / 2, 126, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RMB update", "DermaDefaultBold", w / 2, 150, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("R reload remove", "DermaDefaultBold", w / 2, 174, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("Square zone", "DermaDefault", w / 2, 206, Color(170, 220, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function trim(s)
	return string.Trim(tostring(s or ""))
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
	local out = { { "No spec/cert requirement", "" } }
	if MilBase and MilBase.CertOrder then
		for _, id in ipairs(MilBase.CertOrder) do
			local cert = MilBase.Certs and MilBase.Certs[id]
			local name = (cert and cert.name) or id
			out[#out + 1] = { name .. "  [" .. id .. "]", id }
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
	for _, choice in ipairs(choices) do
		combo:AddChoice(choice[1], choice[2])
	end
	combo.OnSelect = function(_, _, _, data)
		selectedData = tostring(data or "")
	end

	local current = vgui.Create("DLabel", wrap)
	current:SetDark(true)
	current:SetText("Current: " .. cvarText(cvar))
	current.Think = function(self)
		local txt = "Current: " .. cvarText(cvar)
		if self:GetText() ~= txt then self:SetText(txt) end
	end

	local setBtn = vgui.Create("DButton", wrap)
	setBtn:SetText(allowMulti and "Set Only" or "Set")
	setBtn.DoClick = function()
		RunConsoleCommand(cvar, tostring(selectedData or ""))
	end

	local addBtn
	if allowMulti then
		addBtn = vgui.Create("DButton", wrap)
		addBtn:SetText("Add")
		addBtn.DoClick = function()
			addUniqueToken(cvar, selectedData)
		end
	end

	local clearBtn = vgui.Create("DButton", wrap)
	clearBtn:SetText("Any / Clear")
	clearBtn.DoClick = function()
		RunConsoleCommand(cvar, "")
	end

	wrap.PerformLayout = function(self, w, h)
		titleLabel:SetPos(0, 0)
		titleLabel:SetSize(w, 18)
		combo:SetPos(0, 22)
		combo:SetSize(w, 24)
		current:SetPos(0, 50)
		current:SetSize(w, 18)

		local gap = 6
		local clearW = 92
		local btnY = 74
		if allowMulti then
			local btnW = math.floor((w - clearW - gap * 2) / 2)
			setBtn:SetPos(0, btnY)
			setBtn:SetSize(btnW, 24)
			addBtn:SetPos(btnW + gap, btnY)
			addBtn:SetSize(btnW, 24)
			clearBtn:SetPos(btnW * 2 + gap * 2, btnY)
			clearBtn:SetSize(clearW, 24)
		else
			local btnW = math.floor((w - gap) / 2)
			setBtn:SetPos(0, btnY)
			setBtn:SetSize(btnW, 24)
			clearBtn:SetPos(btnW + gap, btnY)
			clearBtn:SetSize(btnW, 24)
		end
	end

	panel:AddItem(wrap)
	return wrap
end

if CLIENT then
	local function drawSquarePreview(pos, ang, size)
		size = math.max(0, tonumber(size or 0) or 0)
		if size <= 0 then return end

		local yaw = Angle(0, (ang and ang.y) or 0, 0)
		local half = size * 0.5
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
		local col = Color(90, 190, 255, 220)
		for i = 1, 4 do
			render.DrawLine(corners[i], corners[i % 4 + 1], col, true)
		end
		render.DrawLine(pos + lift, pos + fwd * half + lift, Color(255, 220, 90, 230), true)
	end

	function TOOL:DrawHUD()
		local ply = LocalPlayer()
		if not IsValid(ply) then return end
		local tr = ply:GetEyeTrace()
		if not tr or not tr.Hit then return end

		local pos = spawnPos(tr)
		local ang = spawnAng(ply)
		cam.Start3D(EyePos(), EyeAngles())
			drawSquarePreview(pos, ang, self:GetClientNumber("zone_size"))
		cam.End3D()
	end
end

function TOOL.BuildCPanel(panel)
	panel:Help("Spawn Selector")
	panel:Help("Left-click places a persistent spawn. Right-click updates the nearest spawn to your current settings. Reload removes the nearest spawn.")
	panel:TextEntry("Spawn name", "mb_spawn_selector_spawn_name")
	panel:NumSlider("Spawn square size", "mb_spawn_selector_zone_size", 0, 1024, 0)
	panel:Help("Players deploy at a random safe position inside this square. Use a larger square for busy areas so squads do not stack on top of each other.")

	addDropdownSelector(panel, "Faction/job access", "mb_spawn_selector_factions", factionChoices(), true,
		"Choose a faction from the dropdown. Leave clear for all factions/jobs. Use Add to allow several factions.")

	panel:NumSlider("Minimum rank index (0 = any)", "mb_spawn_selector_min_rank", 0, 20, 0)
	panel:NumSlider("Maximum rank index (0 = any)", "mb_spawn_selector_max_rank", 0, 20, 0)

	addDropdownSelector(panel, "Rank group access", "mb_spawn_selector_rank_groups", rankGroupChoices(), false,
		"Use rank indexes above for exact rank locks, or this dropdown for broad rank groups.")

	addDropdownSelector(panel, "Spec/cert access", "mb_spawn_selector_certs", certChoices(), true,
		"Choose specs/certs from the dropdown. Leave clear for no spec requirement. Use Add to require one of several specs.")

	panel:CheckBox("Require every listed spec/cert", "mb_spawn_selector_require_all")
end
