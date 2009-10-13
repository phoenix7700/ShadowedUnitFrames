local Highlight = {}
local goldColor, mouseColor
ShadowUF:RegisterModule(Highlight, "highlight", ShadowUFLocals["Highlight"])

-- Might seem odd to hook my code in the core manually, but HookScript is ~40% slower due to it being a secure hook
local function OnEnter(frame)
	if( ShadowUF.db.profile.units[frame.unitType].highlight.mouseover ) then
		frame.highlight.hasMouseover = true
		Highlight:Update(frame)
	end
		
	frame.highlight.OnEnter(frame)
end

local function OnLeave(frame)
	if( ShadowUF.db.profile.units[frame.unitType].highlight.mouseover ) then
		frame.highlight.hasMouseover = nil
		Highlight:Update(frame)
	end
		
	frame.highlight.OnLeave(frame)
end

function Highlight:OnEnable(frame)
	-- Ironically, I stole the border texture from agUF intending to use it as a border, but it looks good
	-- when it covers the entire unit frame, and thus I'll use it for that instead!
	if( not frame.highlight ) then
		frame.highlight = frame.highFrame:CreateTexture(nil, "ARTWORK")
		frame.highlight:SetBlendMode("ADD")
		frame.highlight:SetPoint("TOPLEFT", frame, ShadowUF.db.profile.backdrop.inset, -ShadowUF.db.profile.backdrop.inset)
		frame.highlight:SetPoint("BOTTOMRIGHT", frame, -ShadowUF.db.profile.backdrop.inset, ShadowUF.db.profile.backdrop.inset)
		frame.highlight:Hide()
	end
	
	if( ShadowUF.db.profile.units[frame.unitType].highlight.aggro ) then
		frame:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", self, "UpdateThreat")
		frame:RegisterUpdateFunc(self, "UpdateThreat")
	end
	
	if( ShadowUF.db.profile.units[frame.unitType].highlight.attention and frame.unitType ~= "target" and frame.unitType ~= "focus" ) then
		frame:RegisterNormalEvent("PLAYER_TARGET_CHANGED", self, "UpdateAttention")
		frame:RegisterNormalEvent("PLAYER_FOCUS_CHANGED", self, "UpdateAttention")
		frame:RegisterUpdateFunc(self, "UpdateAttention")
	end

	if( ShadowUF.db.profile.units[frame.unitType].highlight.debuff ) then
		frame:RegisterNormalEvent("UNIT_AURA", self, "UpdateAura")
		frame:RegisterUpdateFunc(self, "UpdateAura")
	end
	
	if( ShadowUF.db.profile.units[frame.unitType].highlight.mouseover and not frame.highlight.OnEnter ) then
		frame.highlight.OnEnter = frame:GetScript("OnEnter")
		frame.highlight.OnLeave = frame:GetScript("OnLeave")
		
		frame:SetScript("OnEnter", OnEnter)
		frame:SetScript("OnLeave", OnLeave)

		goldColor = {r = 0.75, g = 0.75, b = 0.35}
		mouseColor = {r = 0.75, g = 0.75, b = 0.50}
	end
end

function Highlight:OnLayoutApplied(frame)
	if( frame.visibility.highlight ) then
		self:OnDisable(frame)
		self:OnEnable(frame)
	end
end

function Highlight:OnDisable(frame)
	frame:UnregisterAll(self)
	
	frame.highlight.hasDebuff = nil
	frame.highlight.hasThreat = nil
	frame.highlight.hasAttention = nil
	frame.highlight.hasMouseover = nil
	frame.highlight:Hide()
end

function Highlight:Update(frame)
	local color
	if( frame.highlight.hasDebuff ) then
		color = DebuffTypeColor[frame.highlight.hasDebuff]

		frame.highlight:SetTexture("Interface\\AddOns\\ShadowedUnitFrames\\media\\textures\\highlight")
		frame.highlight:SetTexCoord(0, 0, 0, 0)
	elseif( frame.highlight.hasThreat ) then
		color = ShadowUF.db.profile.healthColors.red

		frame.highlight:SetTexture("Interface\\AddOns\\ShadowedUnitFrames\\media\\textures\\highlight")
		frame.highlight:SetTexCoord(0, 0, 0, 0)
	elseif( frame.highlight.hasAttention ) then
		color = goldColor

		frame.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		frame.highlight:SetTexCoord(1, 0, 1, 0)
	elseif( frame.highlight.hasMouseover ) then
		color = mouseColor

		frame.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		frame.highlight:SetTexCoord(1, 0, 1, 0)
	end
		
	if( color ) then
		frame.highlight:SetVertexColor(color.r, color.g, color.b, 1)
		frame.highlight:Show()
	else
		frame.highlight:Hide()
	end
end

function Highlight:UpdateThreat(frame)
	frame.highlight.hasThreat = UnitThreatSituation(frame.unit) == 3 or nil
	self:Update(frame)
end

function Highlight:UpdateAttention(frame)
	frame.highlight.hasAttention = UnitIsUnit(frame.unit, "target") or UnitIsUnit(frame.unit, "focus") or nil
	self:Update(frame)
end

function Highlight:UpdateAura(frame)
	-- In theory, we don't need aura scanning because the first debuff returned is always one we can cure... in theory
	frame.highlight.hasDebuff = UnitIsFriend(frame.unit, "player") and select(5, UnitDebuff(frame.unit, 1, "RAID")) or nil
	self:Update(frame)
end
